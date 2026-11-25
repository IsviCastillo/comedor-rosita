#!/bin/sh
set -eu

CERT_DIR="/etc/nginx/certs"
CUSTOM_DIR="/etc/nginx/custom-certs"
CERT_FILE="$CERT_DIR/rosita.local.pem"
KEY_FILE="$CERT_DIR/rosita.local-key.pem"

mkdir -p "$CERT_DIR"

if [ -f "$CUSTOM_DIR/rosita.local.pem" ] && [ -f "$CUSTOM_DIR/rosita.local-key.pem" ]; then
  cp "$CUSTOM_DIR/rosita.local.pem" "$CERT_FILE"
  cp "$CUSTOM_DIR/rosita.local-key.pem" "$KEY_FILE"
  chmod 600 "$KEY_FILE"
  echo "[nginx-tls] Usando certificados locales de $CUSTOM_DIR"
elif [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/CN=rosita.local" \
    -addext "subjectAltName=DNS:rosita.local,DNS:localhost,IP:127.0.0.1" >/dev/null
  chmod 600 "$KEY_FILE"
  echo "[nginx-tls] Certificado autofirmado generado para rosita.local y localhost"
fi
