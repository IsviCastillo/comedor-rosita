# Evidencias de Fase 3

Pruebas ejecutadas en Docker Desktop con Nginx (HTTPS en puerto `443` + redirección `301` desde HTTP `:80`) y 3 nodos Express/TypeScript.

- `fase3-cluster-activo.png` / `.txt`: `docker compose ps` con `nodo1`, `nodo2`, `nodo3` y `lb` en estado `healthy` y puertos `80`/`443`.
- `fase3-balanceo-nginx.png` / `.txt`: redirección `HTTP 301` de `http://127.0.0.1/health` hacia `https://127.0.0.1/health` y seis respuestas `HTTP 200` en Round-Robin (`nodo3`, `nodo2`, `nodo1`, `nodo3`, `nodo2`, `nodo1`).
- `fase3-failover.png` / `.txt`: `nodo2` detenido manualmente y seis respuestas consecutivas `HTTP 200` atendidas por `nodo1` y `nodo3` sin interrupción.
- `fase3-nginx-logs.png` / `.txt`: salida real de `docker compose logs lb` mostrando `upstream=172.30.21.11:4000` / `.12:4000` / `.13:4000`, la detección de timeout al detener `nodo2` (`upstream server temporarily disabled` / `upstream timed out`) y el reintento transparente (`upstream_status=504, 200`).
- `fase3-recuperacion.txt`: `nodo2` reiniciado (`healthy`) y volviendo a recibir tráfico en Round-Robin.

Las imágenes `fase3-*.png` se generaron a partir de las salidas reales capturadas en los archivos `.txt`. También se conservan las capturas previas de Fase 2 con `mkcert` (`Frontend con Candado HTTPS.png`, `httpsrosita.localapimenu.png`, `El ProxyPass y el Candado HTTPS*.png`).
