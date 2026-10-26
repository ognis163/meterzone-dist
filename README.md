# MeterZone — сборки для Docker и Keenetic

Здесь только готовые сборки. Исходный код — в
[ognis163/MeterZone](https://github.com/ognis163/MeterZone).

Каждая сборка запускается автоматически при изменении исходников:

| Что | Где |
|---|---|
| Образ Docker (amd64, arm64) | `ghcr.io/ognis163/meterzone-dist:latest` |
| Бинарники | [Releases](https://github.com/ognis163/meterzone-dist/releases/latest) |

## Synology DSM 7 (Container Manager)

Образ скачивается с GitHub, компилировать нечего. Папка для данных
должна существовать заранее — Synology её не создаёт.

1. В File Station создайте `/volume1/docker/meterzone` и **внутри неё
   папку `data`**. Без неё контейнер упадёт с
   `Bind mount failed: '/volume1/docker/meterzone/data' does not exist`.
2. Положите в `/volume1/docker/meterzone`
   файл [`docker-compose.yml`](docker-compose.yml) — рядом с папкой `data`.
3. Container Manager → **Проект** → **Создать**:
   имя `meterzone`, путь `/volume1/docker/meterzone`,
   источник — существующий `docker-compose.yml`.
4. Откройте `http://адрес-NAS:8099`.

Итоговая структура:

```
/volume1/docker/meterzone/
├── docker-compose.yml
└── data/                  ← создать заранее
    └── backups/           ← появится само
```

База и резервные копии лежат в `data/` и видны в File Station.
Скачать копию можно и из интерфейса: «Настройки» → «Резервные копии».

### Перенос базы с роутера

1. На роутере остановите сервис, чтобы файл был целым:
   ```sh
   /opt/etc/init.d/S99meterzone stop
   ```
2. Заберите базу на компьютер:
   ```sh
   scp root@192.168.x.x:/opt/meterzone/data/meterzone.db ./meterzone.db
   ```
3. Скопируйте файл в папку данных на NAS (приложение при этом остановлено):
   ```sh
   cd /volume1/docker/meterzone
   sudo docker compose stop
   rm -f data/meterzone.db data/meterzone.db-wal data/meterzone.db-shm
   cp meterzone.db data/meterzone.db
   sudo docker compose start
   ```

Без SSH то же самое делается в File Station: остановите проект,
удалите файлы `meterzone.db*` из папки `data`, положите туда
скачанный `meterzone.db` и запустите проект.

Если проще — запустите приложение с пустой базой и загрузите файл
через интерфейс: «Настройки» → «Импорт старой базы».
На пустой базе результат тот же.

### Обновление

```sh
cd /volume1/docker/meterzone
sudo docker compose pull
sudo docker compose up -d
```

В Container Manager то же самое: проект `meterzone` → **Действие** →
**Загрузить образ** и пересоздать. Папка `data` не затрагивается.

### Если папку создать не получается

Можно жить на именованном томе, который Docker создаёт сам: замените

```yaml
    volumes:
      - ./data:/data
```

на

```yaml
    volumes:
      - meterzone-data:/data
```

и добавьте в конец файла

```yaml
volumes:
  meterzone-data:
```

Тогда папку готовить не нужно, но база будет лежать внутри Docker
(`/volume1/@docker/volumes/meterzone-data`), а не в File Station.

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
