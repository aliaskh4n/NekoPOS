#!/usr/bin/env bash
# Установка Neko POS на macOS без предупреждений Gatekeeper.
#
# Почему это работает без "неизвестный разработчик" / "не удалось
# проверить": флаг карантина (com.apple.quarantine), из-за которого
# Gatekeeper вообще показывает предупреждение, ставят только приложения,
# использующие LSQuarantine API — браузеры, Почта, AirDrop. curl (и вообще
# всё, что скачивает файлы не через них) этот флаг не ставит, поэтому
# .app, установленный этим скриптом, macOS считает уже "проверенным" и
# просто открывает — оф. подпись Apple Developer тут ни при чём, это
# просто другой путь получения файла.
set -euo pipefail

REPO="aliaskh4n/NekoPOS"
ASSET="pos-darwin-arm64.zip"
APP_NAME="Neko POS.app"
DEST="/Applications"

if [ "$(uname -m)" != "arm64" ]; then
  echo "Сейчас есть сборка только под Apple Silicon (M1/M2/M3/...). Ваш Mac — Intel, эта сборка не подойдёт." >&2
  exit 1
fi

TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep -m1 '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
echo "Скачиваю Neko POS ${TAG}..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/${REPO}/releases/download/${TAG}/${ASSET}" -o "$TMP/app.zip"
curl -fsSL "https://github.com/${REPO}/releases/download/${TAG}/${ASSET}.sha256" -o "$TMP/app.zip.sha256" || true

if [ -s "$TMP/app.zip.sha256" ]; then
  EXPECTED=$(awk '{print $1}' "$TMP/app.zip.sha256")
  ACTUAL=$(shasum -a 256 "$TMP/app.zip" | awk '{print $1}')
  if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "Контрольная сумма не совпала — файл повреждён при скачивании, попробуйте ещё раз." >&2
    exit 1
  fi
fi

unzip -q "$TMP/app.zip" -d "$TMP"

if [ -d "$DEST/$APP_NAME" ]; then
  echo "Обновляю установленную версию..."
  rm -rf "$DEST/$APP_NAME"
fi

mv "$TMP/$APP_NAME" "$DEST/$APP_NAME"
# На всякий случай — если файл всё же прошёл через что-то, что ставит карантин.
xattr -dr com.apple.quarantine "$DEST/$APP_NAME" 2>/dev/null || true

echo "Готово: $DEST/$APP_NAME"
open "$DEST/$APP_NAME"
