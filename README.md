# Comedor Rosita

Proyecto de cátedra, **Fase 3**: clúster de tres nodos Express/TypeScript detrás de un balanceador Nginx con terminación HTTPS, redirección desde HTTP, balanceo Round Robin y tolerancia a fallos.

## Arquitectura de Fase 3

~~~mermaid
flowchart LR
    navegador["Navegador / cliente"] -->|"HTTP :80 (301 -> HTTPS) / HTTPS :443"| lb["Nginx · lb"]
    lb -->|"Round Robin · :4000"| nodo1["nodo1 · 172.30.21.11"]
    lb -->|"Round Robin · :4000"| nodo2["nodo2 · 172.30.21.12"]
    lb -->|"Round Robin · :4000"| nodo3["nodo3 · 172.30.21.13"]
~~~

El servicio `lb` publica los puertos `80` (redirige `301` a HTTPS) y `443` (TLS). Los tres nodos escuchan en el puerto `4000` dentro de la red Docker `clusternet` (`172.30.21.0/24`); sus direcciones son `172.30.21.11`, `.12` y `.13`, y la del balanceador es `172.30.21.10`. Nginx usa Round Robin por defecto, marca un nodo como no disponible tras `max_fails=1` durante `fail_timeout=15s` y reintenta ante errores de conexión (`proxy_connect_timeout 1s`), timeout, HTTP 502 o 503.

Si existen certificados locales confiables de `mkcert` en `infra/apache/certs/` (`rosita.local.pem` y `rosita.local-key.pem`), Nginx los carga automáticamente; si no existen, genera un certificado autofirmado al iniciar para `rosita.local`, `localhost` y `127.0.0.1`.

## Ejecutar el clúster

Requiere Git, Docker Desktop con Docker Compose y PowerShell (con los puertos `80` y `443` libres). Clona el repositorio original:

```powershell
git clone https://github.com/IsviCastillo/comedor-rosita.git
cd comedor-rosita
```

En [`.env.example`](.env.example), `ADMIN_TOKEN` contiene un valor de ejemplo. Cópialo a `.env` y reemplázalo por un token privado antes de ejecutar el clúster:

```powershell
Copy-Item .env.example .env
notepad .env
docker compose up --build -d --wait
docker compose ps
```

Compose usa `token-secreto-rosita` como valor predeterminado de `ADMIN_TOKEN` solo cuando la variable no está definida en el entorno ni en `.env`. No uses ese valor predeterminado para un despliegue real. Abre [el sitio por HTTPS](https://127.0.0.1) (o [https://rosita.local](https://rosita.local) si tienes `127.0.0.1 rosita.local` en `hosts` y los certificados de `mkcert` generados como indica [`docs/FASE_2.md`](docs/FASE_2.md)). Usar `127.0.0.1` o `rosita.local` evita conflictos si Apache en WSL está escuchando en IPv6 `[::1]`.

El `Dockerfile` configura para cada nodo un healthcheck que consulta `/health` cada 30 segundos, con timeout de 3 segundos, periodo inicial de 5 segundos y 3 reintentos. Compose espera a que los tres nodos estén saludables antes de iniciar `lb`.

Para verificar la redirección HTTP → HTTPS y observar Round Robin, consulta `/health` varias veces y revisa el campo `nodo`:

```powershell
curl.exe -sSI http://127.0.0.1/health
1..6 | ForEach-Object { curl.exe -sk -w " HTTP %{http_code}`n" https://127.0.0.1/health }
```

Con los tres nodos saludables, la secuencia recorre `nodo1`, `nodo2`, `nodo3` y vuelve a empezar.

Para comprobar el failover, detén `nodo2` y repite las solicitudes. El balanceador seguirá obteniendo respuestas `HTTP 200` de los otros dos nodos sin interrupción. Al terminar, vuelve a iniciarlo y revisa los logs de Nginx:

```powershell
docker compose stop nodo2
1..6 | ForEach-Object { curl.exe -sk -w " HTTP %{http_code}\n" https://127.0.0.1/health }
docker compose logs --tail=30 lb
docker compose start nodo2
docker compose ps
```

Para consultar los registros o detener el clúster:

```powershell
docker compose logs
docker compose down
```

Las evidencias de las pruebas están en [`docs/evidencias/`](docs/evidencias/).

## Persistencia

El menú, las existencias y los pedidos viven en memoria en cada proceso Express. No hay base de datos ni almacenamiento persistente: al reiniciar un nodo se pierden sus cambios. Los tres nodos tampoco comparten estado, así que el inventario y los pedidos pueden diferir según qué nodo atienda la solicitud.

## API

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/health` | Estado del nodo; incluye su nombre de host. |
| `GET` | `/api/menu` | Menú con precios, disponibilidad e inventario actual del nodo. |
| `POST` | `/api/pedidos` | Registra un pedido y reserva las unidades disponibles en ese nodo. |
| `GET` | `/api/pedidos` | Lista los pedidos pendientes. Requiere `Authorization: Bearer <ADMIN_TOKEN>`. |

Ejemplo de cuerpo para `POST /api/pedidos`:

```json
{
  "cliente": "Ana López",
  "telefono": "7777-1234",
  "platoId": 1,
  "cantidad": 1,
  "horaRetiro": "12:00"
}
```

La API valida los campos, el horario permitido y las existencias antes de aceptar cada pedido. El inventario se descuenta solo cuando el pedido queda registrado.

## Desarrollo sin Docker

Con Node.js y npm instalados, ejecuta desde la carpeta del proyecto:

```powershell
npm ci
$env:ADMIN_TOKEN = "elige-un-token-local"
npm run dev
```

Abre [el servidor de desarrollo](http://127.0.0.1:4000). La página y la API se sirven juntas. Para detenerlo, presiona `Ctrl+C`.

Los comandos de comprobación y compilación son:

```powershell
npm run typecheck
npm run build
```

Para ejecutar la compilación, primero ejecuta `npm run build`; luego `npm start` inicia `dist/index.js`.

## Fase 2: Apache y HTTPS

La guía completa de Apache y `mkcert` para WSL2/Ubuntu está en [`docs/FASE_2.md`](docs/FASE_2.md). La configuración Docker de esa fase está en [`docker-compose.fase2.yml`](docker-compose.fase2.yml), con su complemento HTTPS en [`docker-compose.https.yml`](docker-compose.https.yml). Esa configuración usa [http://localhost:8080](http://localhost:8080) para HTTP y [https://rosita.local](https://rosita.local) para HTTPS; estos puertos y direcciones corresponden únicamente a Fase 2.
