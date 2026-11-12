# Comedor Rosita

Proyecto de cátedra, **Fase 2**. El sitio muestra el menú del día y permite reservar platos para recogerlos en el comedor.

## Contenido

- [Arquitectura](#arquitectura)
- [Qué se actualizó](#qué-se-actualizó)
- [Formas de ejecutar el proyecto](#formas-de-ejecutar-el-proyecto)
- [Opción A: Docker (recomendada)](#opción-a-docker-recomendada)
- [Opción B: desarrollo sin Docker](#opción-b-desarrollo-sin-docker)
- [Opción C: Apache con HTTPS en WSL2/Ubuntu (entrega)](#opción-c-apache-con-https-en-wsl2ubuntu-entrega)
- [API](#api)
- [Comprobaciones](#comprobaciones)
- [Evidencias de la entrega](#evidencias-de-la-entrega)

## Arquitectura

```text
[ Navegador del cliente ]
          |
          | HTTPS (rosita.local:443)  o  HTTP (localhost:8080 con Docker)
          v
[ Servidor web Apache ]
          |
          | ProxyPass /api/
          v
[ API Express / Node.js (puerto 4000) ]
          |
          v
[ Lógica del negocio y gestión de inventario ]
```

## Qué se actualizó

- **Menú:** muestra precios y existencias. El formulario permite elegir un plato, la cantidad y la hora de retiro.
- **API:** está hecha con Express y TypeScript. Valida el pedido, descuenta las unidades reservadas y permite consultar los pedidos pendientes con un token de administrador.
- **Docker Compose:** levanta el sitio en Apache y la API en Express en dos contenedores, para que cada compañero los ejecute en su computadora.
- **HTTPS:** la configuración de Apache para HTTPS sigue disponible para la entrega. Guarda las capturas en `docs/evidencias/`.

## Formas de ejecutar el proyecto

| Opción | Cuándo usarla | Dirección del sitio |
|---|---|---|
| A. Docker | Para probar el proyecto completo sin instalar Apache ni Node.js | `http://localhost:8080` |
| B. Sin Docker | Para desarrollar y depurar el código | `http://127.0.0.1:4000` |
| C. Apache + HTTPS | Para la entrega y las evidencias | `https://rosita.local` |

> **Importante:** el inventario y los pedidos viven en memoria. Cada equipo tiene sus propios datos de prueba y se reinician cada vez que se reinicia la API.

## Opción A: Docker (recomendada)

**Requisitos:** Git y Docker Desktop abierto.

1. Clona el repositorio y crea tu archivo `.env`. En PowerShell:

   ```powershell
   git clone https://github.com/IsviCastillo/comedor-rosita.git
   cd comedor-rosita
   Copy-Item .env.example .env
   notepad .env
   ```

2. En `.env`, reemplaza `ADMIN_TOKEN` por un valor privado y guarda el archivo.

3. Construye e inicia los contenedores:

   ```powershell
   docker compose up --build -d
   ```

4. Abre <http://localhost:8080>, haz un pre-pedido y usa el mismo token en el panel de cocina para comprobar que aparece.

### Si ya tenías el proyecto clonado

```powershell
git pull
```

Luego, si **no** tienes un archivo `.env`, créalo con `Copy-Item .env.example .env` y define tu token. Si ya tienes uno, conserva tu token y no lo sobrescribas.

### Comandos útiles

```powershell
docker compose ps       # estado de los contenedores
docker compose logs     # registros
docker compose down     # detener y eliminar los contenedores
```

## Opción B: desarrollo sin Docker

**Requisitos:** Node.js 20 o superior.

Desde la carpeta del proyecto, en PowerShell:

```powershell
npm ci
$env:ADMIN_TOKEN = "elige-un-token-local"
npm run dev
```

Deja esa terminal abierta y visita <http://127.0.0.1:4000>. La página y la API se sirven juntas en el puerto `4000`. El panel de cocina usa el token que definiste en `ADMIN_TOKEN`.

Para detener el servidor, vuelve a la terminal y presiona `Ctrl+C`.

## Opción C: Apache con HTTPS en WSL2/Ubuntu (entrega)

Ejecuta todo desde la raíz del proyecto, en una terminal de Ubuntu.

### 1. Inicia el backend

En una terminal de esa misma distribución:

```bash
npm ci
export ADMIN_TOKEN='elige-un-token-local'
npm run dev
```

Deja esa terminal abierta: Apache necesita acceder a la API en `127.0.0.1:4000`.

### 2. Instala Apache y habilita los módulos

```bash
sudo apt update
sudo apt install apache2 libnss3-tools
sudo a2enmod ssl proxy proxy_http
```

Instala también `mkcert` siguiendo su [guía oficial](https://github.com/FiloSottile/mkcert#installation).

### 3. Copia el sitio estático

Copia el contenido de `public/` a `/var/www/rosita.local/` y dale permisos de lectura a Apache:

```bash
sudo mkdir -p /var/www/rosita.local
sudo cp -r public/. /var/www/rosita.local/
sudo chown -R www-data:www-data /var/www/rosita.local
```

### 4. Genera un certificado local de confianza

Instala la CA de mkcert en el almacén de confianza del sistema y del navegador, y guarda la llave privada **fuera del repositorio**:

```bash
mkcert -install
mkdir -p "$HOME/.local/share/rosita-certs"
(cd "$HOME/.local/share/rosita-certs" && mkcert rosita.local)
sudo mkdir -p /etc/apache2/ssl/rosita.local
sudo install -m 644 "$HOME/.local/share/rosita-certs/rosita.local.pem" /etc/apache2/ssl/rosita.local/rosita.local.pem
sudo install -m 600 "$HOME/.local/share/rosita-certs/rosita.local-key.pem" /etc/apache2/ssl/rosita.local/rosita.local-key.pem
```

> Si el navegador está en Windows y Apache en WSL, asegúrate también de que el certificado raíz de mkcert sea de confianza en Windows.
> **Nunca copies ni publiques la llave privada.**

### 5. Activa los sitios de Apache

```bash
sudo cp infra/apache/rosita.local.conf /etc/apache2/sites-available/
sudo cp infra/apache/rosita.local-ssl.conf /etc/apache2/sites-available/
sudo a2ensite rosita.local.conf rosita.local-ssl.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

`apache2ctl configtest` debe responder `Syntax OK` antes de recargar.

### 6. Configura el archivo `hosts`

Añade esta línea al archivo `hosts` del sistema donde abres el navegador:

```text
127.0.0.1 rosita.local
```

En Windows el archivo está en `C:\Windows\System32\drivers\etc\hosts` y necesitas abrirlo como administrador. En WSL, confirma que Apache sea accesible desde Windows por `localhost`; si tu red de WSL está configurada de otra forma, usa la dirección que corresponda.

### 7. Verifica

Abre <https://rosita.local> y la API en <https://rosita.local/api/menu>. Para probar el proxy y el backend desde WSL:

```bash
curl -i https://rosita.local/api/menu
curl -i https://rosita.local/health
curl -i http://127.0.0.1:4000/health
```

Apache redirige HTTP a HTTPS. Si quieres probar sin Apache, consulta <http://127.0.0.1:4000/api/menu>.

## API

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/menu` | Menú con precios, disponibilidad e inventario actual. |
| `POST` | `/api/pedidos` | Registra un pre-pedido y reserva las unidades disponibles. |
| `GET` | `/api/pedidos` | Lista los pedidos pendientes. Requiere `Authorization: Bearer <ADMIN_TOKEN>`. |
| `GET` | `/health` | Estado básico del backend. |

### Ejemplo de pre-pedido

```json
{
  "cliente": "Ana López",
  "telefono": "7777-1234",
  "platoId": 1,
  "cantidad": 1,
  "horaRetiro": "12:00"
}
```

El servidor valida los campos, el horario permitido y las existencias antes de aceptar cada pedido. El inventario solo se descuenta cuando el pedido queda registrado.

### Ejemplo de consulta administrativa

```powershell
curl.exe -H "Authorization: Bearer TU_TOKEN" http://localhost:8080/api/pedidos
```

Cambia `TU_TOKEN` por el valor de `ADMIN_TOKEN` y ajusta la URL según la opción que estés usando.

## Comprobaciones

1. Abre el sitio ([Docker](http://localhost:8080) o [HTTPS](https://rosita.local)) y confirma que el menú muestra los platos y sus existencias.
2. Haz un pedido de prueba con una unidad de un plato disponible. Comprueba que se confirma y que el plato queda con una unidad menos.
3. Ingresa el token en el panel de administración y comprueba que aparece el pedido.
4. Verifica que el código compila sin errores:

   ```powershell
   npm run typecheck
   npm run build
   ```

