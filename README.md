# MeterZone — установка в Docker и на Keenetic

[![build](https://github.com/ognis163/meterzone-dist/actions/workflows/build.yml/badge.svg)](https://github.com/ognis163/meterzone-dist/actions/workflows/build.yml)

Готовые сборки [MeterZone](https://github.com/ognis163/MeterZone) — учёта показаний
счётчиков, начислений и оплат. Здесь **ничего не нужно компилировать**:
образ берётся готовым с GitHub, бинарник лежит в Releases.

| Что | Где |
|---|---|
| Образ Docker (amd64 + arm64) | `ghcr.io/ognis163/meterzone-dist:latest` |
| Бинарники и установщик | [Releases](https://github.com/ognis163/meterzone-dist/releases/latest) |
| Исходный код | [ognis163/MeterZone](https://github.com/ognis163/MeterZone) |

## Куда ставим

**Synology DSM 7** — нужен пакет Container Manager, около 5 минут
→ [подробная инструкция](docs/INSTALL_DSM.md)

**Keenetic (Entware)** — нужен Hopper (aarch64) с Entware, одна команда
→ [подробная инструкция](docs/INSTALL_KEENETIC.md)

## Synology DSM — коротко

1. File Station → создайте папку `/volume1/docker/meterzone`,
   а внутри неё — **папку `data`**.
2. Положите в `/volume1/docker/meterzone` файл
   [`docker-compose.yml`](docker-compose.yml).
3. Container Manager → **Проект** → **Создать**: имя `meterzone`,
   путь `/volume1/docker/meterzone`, источник — существующий `docker-compose.yml`.
4. Откройте `http://адрес-NAS:8099`.

```
/volume1/docker/meterzone/
├── docker-compose.yml
└── data/                  ← должна существовать до запуска
```

> **Самая частая ошибка.** Synology не создаёт папку для монтирования сама.
> Без `data` контейнер упадёт: `Bind mount failed: '/volume1/docker/meterzone/data' does not exist`.

## Keenetic — коротко

По SSH под root, на роутере с Entware:

```sh
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh | sh
```

Скрипт скачает бинарник, поставит в `/opt/meterzone`, настроит автозапуск
и запустит сервис. Адрес и ответ сервера он покажет в конце.

Другой порт или часовой пояс:

```sh
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh \
  | PORT=8090 APP_TZ=Europe/Moscow sh
```

## После установки

Откройте `http://адрес-устройства:8099` — это и есть приложение.
Проверить, что сервис жив, можно без браузера:

```sh
curl http://127.0.0.1:8099/healthz
# {"ok":true,"version":"1.5","uptime":"5s","db":"/data/meterzone.db"}
```

Дальше: создайте объект (дом, магазин, офис), добавьте к нему счётчики —
и вводите показания. На iPhone сайт добавляется на экран «Домой» и
открывается как приложение.

## Где лежат данные

| Платформа | База | Резервные копии |
|---|---|---|
| Docker | `/volume1/docker/meterzone/data/meterzone.db` | `.../data/backups/` |
| Keenetic | `/opt/meterzone/data/meterzone.db` | `/opt/meterzone/data/backups/` |

Копия создаётся автоматически раз в месяц, хранятся последние 14.
Скачать их и восстановить можно из интерфейса: **Настройки** → **Резервные копии**.

## Обновление

```sh
# Docker на DSM
cd /volume1/docker/meterzone
sudo docker compose pull && sudo docker compose up -d

# Keenetic — просто повторите установку, база сохранится
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh | sh
```

Сборка запускается сама при изменении кода в
[MeterZone](https://github.com/ognis163/MeterZone), так что `pull` приносит
уже свежую версию. Папка `data` при обновлении не затрагивается.

## Частые проблемы

| Симптом | Причина и решение |
|---|---|
| `Bind mount failed: ... does not exist` | Нет папки `data`. Создайте её и пересоздайте проект |
| `port is already allocated` | Порт 8099 занят. Поменяйте `"8099:8099"` и `PORT` в compose на другой |
| «Доступ разрешён только из локальной сети» | Открываете по внешнему адресу. Раскомментируйте `ALLOW_PUBLIC: "1"` в compose |
| Контейнер перезапускается | Смотрите журнал: Container Manager → проект → **Журнал** |
| В настройках нет смены порта | Так и задумано: в контейнере порт задаётся в compose |

Полные инструкции: [DSM](docs/INSTALL_DSM.md) · [Keenetic](docs/INSTALL_KEENETIC.md)

## Лицензия

MIT — как и у [MeterZone](https://github.com/ognis163/MeterZone).
