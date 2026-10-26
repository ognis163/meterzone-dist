# MeterZone — сборки для Docker и Keenetic

Здесь только готовые сборки. Исходный код — в
[ognis163/MeterZone](https://github.com/ognis163/MeterZone).

Каждая сборка запускается автоматически при изменении исходников:

| Что | Где |
|---|---|
| Образ Docker (amd64, arm64) | `ghcr.io/ognis163/meterzone-dist:latest` |
| Бинарники | [Releases](https://github.com/ognis163/meterzone-dist/releases/latest) |

## Synology DSM 7 (Container Manager)

Ничего компилировать не нужно — образ скачивается с GitHub.

1. В File Station создайте `/volume1/docker/meterzone`
   и положите туда **только** [`docker-compose.yml`](docker-compose.yml).
2. Container Manager → **Проект** → **Создать**:
   имя `meterzone`, путь `/volume1/docker/meterzone`,
   источник — существующий `docker-compose.yml`.
3. Откройте `http://адрес-NAS:8099`.

Папку `data` создавать не надо: Docker создаст её при первом запуске,
а внутри окажутся база и резервные копии.

### Перенос базы с роутера

1. На роутере остановите сервис, чтобы файл был целым:
   ```sh
   /opt/etc/init.d/S99meterzone stop
   ```
2. Заберите базу:
   ```sh
   scp root@192.168.x.x:/opt/meterzone/data/meterzone.db ./meterzone.db
   ```
3. Положите её в `/volume1/docker/meterzone/data/meterzone.db`
   **до** первого запуска контейнера.

### Обновление

Container Manager → проект `meterzone` → **Действие** → **Загрузить образ**
(или «Скачать» / «Обновить»). База в `data/` не затрагивается.

Либо по SSH:

```sh
cd /volume1/docker/meterzone && sudo docker compose pull && sudo docker compose up -d
```

## Keenetic (Entware)

```sh
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh | sh
```

Нужен Keenetic Hopper (aarch64) с Entware. Скрипт скачает
`meterzone-linux-arm64`, поставит в `/opt/meterzone` и настроит автозапуск.

Порт по умолчанию 8099, другой:

```sh
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh | PORT=8090 sh
```

## Проверка образа

```sh
docker run --rm -p 8099:8099 -v /tmp/mz:/data ghcr.io/ognis163/meterzone-dist:latest
curl http://127.0.0.1:8099/healthz
```

## Лицензия

MIT, как и у MeterZone.
