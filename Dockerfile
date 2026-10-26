# Образ MeterZone.
# Собирается в GitHub Actions из уже готового бинарника, поэтому внутри
# нет Go и нечего компилировать: слой только копирует файл.

FROM alpine:3.20

# ca-certificates — для SMTP через SSL/STARTTLS.
# tzdata — для корректного часового пояса.
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# TARGETARCH подставляет buildx: amd64 или arm64.
ARG TARGETARCH
COPY bin/meterzone-linux-${TARGETARCH} /app/meterzone
RUN chmod 755 /app/meterzone

# PORT_FIXED=1: в контейнере порт меняется только в docker-compose.yml,
# иначе приложение уехало бы на порт, который наружу не проброшен.
ENV HOST=0.0.0.0 \
    PORT=8099 \
    APP_DB=/data/meterzone.db \
    APP_BACKUP_DIR=/data/backups \
    PORT_FIXED=1

VOLUME ["/data"]
EXPOSE 8099

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8099/healthz || exit 1

ENTRYPOINT ["/app/meterzone"]
