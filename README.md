# MeterZone — сборки для Docker и Keenetic

Здесь только готовые сборки. Исходный код — в
[ognis163/MeterZone](https://github.com/ognis163/MeterZone).

Каждая сборка запускается автоматически при изменении исходников:

| Что | Где |
|---|---|
| Образ Docker (amd64, arm64) | `ghcr.io/ognis163/meterzone-dist:latest` |
| Бинарники | [Releases](https://github.com/ognis163/meterzone-dist/releases/latest) |

## Synology DSM 7 (Container Manager)

Ничего не компилируется и **никакие папки создавать не нужно**:
образ скачивается с GitHub, том данных Docker создаёт сам.

1. В File Station создайте `/volume1/docker/meterzone`
   и положите туда **только** [`docker-compose.yml`](docker-compose.yml).
2. Container Manager → **Проект** → **Создать**:
   имя `meterzone`, путь `/volume1/docker/meterzone`,
   источник — существующий `docker-compose.yml`.
3. Откройте `http://адрес-NAS:8099`.

База и резервные копии живут в томе `meterzone-data`. Скачать их
можно из интерфейса приложения: «Настройки» → «Резервные копии».

Если проект уже создавался с папкой `./data` и падал с ошибкой
`Bind mount failed: ... does not exist` — удалите проект и создайте
заново с этим файлом: зависимость от папки убрана.

### Перенос базы с роутера

1. На роутере остановите сервис, чтобы файл был целым:
   ```sh
   /opt/etc/init.d/S99meterzone stop
   ```
2. Заберите базу на компьютер:
   ```sh
   scp root@192.168.x.x:/opt/meterzone/data/meterzone.db ./meterzone.db
   ```
3. Положите файл на NAS, например в `/volume1/docker/meterzone/meterzone.db`,
   и скопируйте в том (контейнер должен быть уже создан):
   ```sh
   cd /volume1/docker/meterzone
   sudo docker compose stop
   sudo docker compose run --rm --entrypoint sh meterzone -c 'rm -f /data/meterzone.db*'
   sudo docker cp meterzone.db meterzone-meterzone-1:/data/meterzone.db
   sudo docker compose start
   ```

Проще, без SSH: запустите приложение с пустой базой и загрузите файл
через интерфейс — «Настройки» → «Импорт старой базы». На пустой базе
результат тот же.

### Обновление

```sh
cd /volume1/docker/meterzone
sudo docker compose pull
sudo docker compose up -d
```

В Container Manager то же самое: проект `meterzone` → **Действие** →
**Загрузить образ** и пересоздать. Том `meterzone-data` не затрагивается.

### Папка вместо тома

Если файлы базы нужны прямо в File Station, замените в `docker-compose.yml`

```yaml
    volumes:
      - meterzone-data:/data
```

на

```yaml
    volumes:
      - /volume1/docker/meterzone/data:/data
```

и **сначала создайте папку** `/volume1/docker/meterzone/data` в File Station:
Synology не создаёт её автоматически, и контейнер упадёт с
`Bind mount failed`. Строку `volumes: meterzone-data:` в конце файла
тогда можно удалить.

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

## Проверка образа вручную

```sh
docker run -d --name mz-test -p 8099:8099 -v mz-test-data:/data \
  ghcr.io/ognis163/meterzone-dist:latest
curl http://127.0.0.1:8099/healthz
docker rm -f mz-test
```

## Лицензия

MIT, как и у MeterZone.
