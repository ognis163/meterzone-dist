# Установка MeterZone на Keenetic (Entware)

Полная инструкция. Нужен Keenetic с поддержкой Entware и архитектурой
**aarch64** — например, Hopper. Компилировать ничего не нужно:
скачивается готовый бинарник из Releases.

## Что нужно

| Требование | Как проверить |
|---|---|
| Keenetic с Entware | в веб-интерфейсе роутера «Управление» → «Пакеты» |
| Архитектура aarch64 | по SSH: `uname -m` → должно быть `aarch64` |
| Доступ по SSH | «Управление» → «Система» → «SSH-сервер» |
| Доступ в интернет | нужен для скачивания бинарника |

На x86/armv7-моделях бинарник не запустится — для них сборки нет.

## Установка одной командой

По SSH под root:

```sh
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh | sh
```

Если на роутере нет `curl`:

```sh
wget -qO- https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh | sh
```

Скрипт:

1. проверит root и архитектуру;
2. скачает `meterzone-linux-arm64` и проверит размер;
3. остановит прежнюю версию, если она была;
4. поставит бинарник в `/opt/meterzone`, сохранив прежнюю копию в `meterzone.prev`;
5. настроит автозапуск `/opt/etc/init.d/S99meterzone`;
6. запустит сервис и дождётся ответа `/healthz`;
7. напечатает адрес и ответ сервера.

В конце вы увидите что-то вроде:

```
Готово. MeterZone установлен и запущен.
Откройте: http://192.168.1.1:8099
База: /opt/meterzone/data/meterzone.db (существующая база не удаляется)
Ответ сервера: {"ok":true,"version":"1.5",...}
```

Существующая база не удаляется: перед обновлением рядом создаётся
копия `meterzone.db.before-update`.

## Свой порт и часовой пояс

```sh
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh \
  | PORT=8090 APP_TZ=Europe/Moscow sh
```

| Переменная | По умолчанию | Что задаёт |
|---|---|---|
| `PORT` | 8099 | порт веб-интерфейса |
| `APP_TZ` | системный | часовой пояс |

При повторной установке порт берётся из текущего автозапуска, чтобы
приложение не «переехало» на другой адрес.

## Ручная установка

Если скрипт не подошёл — те же шаги руками:

```sh
mkdir -p /opt/meterzone/data
cd /tmp
curl -fsSL -o meterzone https://github.com/ognis163/meterzone-dist/releases/latest/download/meterzone-linux-arm64
chmod 755 meterzone
mv meterzone /opt/meterzone/meterzone

PORT=8099 HOST=0.0.0.0 \
  APP_DB=/opt/meterzone/data/meterzone.db \
  APP_BACKUP_DIR=/opt/meterzone/data/backups \
  /opt/meterzone/meterzone
```

Для автозапуска скачайте [`S99meterzone`](../S99meterzone) из этого
репозитория, положите в `/opt/etc/init.d/`, при необходимости поправьте
внутри `PORT` и выполните:

```sh
chmod 755 /opt/etc/init.d/S99meterzone
/opt/etc/init.d/S99meterzone start
```

## Проверка

```sh
/opt/etc/init.d/S99meterzone status     # running
curl http://127.0.0.1:8099/healthz
tail -n 30 /opt/var/log/meterzone.log
```

Ответ `/healthz`:

```json
{"ok":true,"version":"1.5","uptime":"20s","db":"/opt/meterzone/data/meterzone.db"}
```

## Где что лежит

| Что | Где |
|---|---|
| Программа | `/opt/meterzone/meterzone` |
| База | `/opt/meterzone/data/meterzone.db` |
| Резервные копии | `/opt/meterzone/data/backups/` (14 последних) |
| Лог | `/opt/var/log/meterzone.log` |
| Автозапуск | `/opt/etc/init.d/S99meterzone` |
| Порт | 8099 |

## Управление сервисом

```sh
/opt/etc/init.d/S99meterzone start
/opt/etc/init.d/S99meterzone stop
/opt/etc/init.d/S99meterzone restart
/opt/etc/init.d/S99meterzone status
```

## Обновление

Просто повторите установку — скрипт сам остановит старую версию,
сохранит базу и запустит новую:

```sh
curl -fsSL https://github.com/ognis163/meterzone-dist/releases/latest/download/install-keenetic.sh | sh
```

Вручную:

```sh
/opt/etc/init.d/S99meterzone stop
curl -fsSL -o /opt/meterzone/meterzone \
  https://github.com/ognis163/meterzone-dist/releases/latest/download/meterzone-linux-arm64
chmod 755 /opt/meterzone/meterzone
/opt/etc/init.d/S99meterzone start
```

База в `/opt/meterzone/data/` при обновлении не затрагивается.

## Переезд на Synology DSM

1. Остановите сервис, чтобы база была целой:
   ```sh
   /opt/etc/init.d/S99meterzone stop
   ```
2. Заберите файл базы:
   ```sh
   scp root@192.168.x.x:/opt/meterzone/data/meterzone.db ./meterzone.db
   ```
3. Дальше — раздел «Перенос базы с роутера» в
   [инструкции для DSM](INSTALL_DSM.md).

## Диагностика

| Проблема | Решение |
|---|---|
| `не найден /opt` | не установлен Entware |
| `поддерживается только aarch64` | модель не подходит, сборки нет |
| `скачался файл неверного размера` | нет выхода в интернет или GitHub недоступен |
| Сервис не ответил | `tail -n 30 /opt/var/log/meterzone.log` |
| Порт занят | задайте другой: `PORT=8090 ... sh` |

```sh
pidof meterzone                    # процесс жив?
netstat -tlnp | grep 8099          # кто слушает порт
ps | grep meterzone | grep -v grep
```

## Удаление

```sh
/opt/etc/init.d/S99meterzone stop
rm -f /opt/etc/init.d/S99meterzone
rm -rf /opt/meterzone
```

Перед удалением скачайте резервную копию из приложения
(«Настройки» → «Резервные копии»), если данные нужны.
