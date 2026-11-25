FROM nginx:alpine

RUN apk add --no-cache openssl curl

COPY 10-ensure-certs.sh /docker-entrypoint.d/10-ensure-certs.sh
RUN sed -i 's/\r$//' /docker-entrypoint.d/10-ensure-certs.sh \
    && chmod +x /docker-entrypoint.d/10-ensure-certs.sh

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -fsSk https://127.0.0.1/health >/dev/null || exit 1
