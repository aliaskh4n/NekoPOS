#!/usr/bin/env bash
# Установка Neko POS на Linux — скачивает актуальный релиз, кладёт в
# ~/.local/share/nekopos (без sudo) и сама создаёт ярлык в меню приложений
# с уже правильным путём (раньше путь в .desktop-файле приходилось
# прописывать руками — теперь скрипт знает его сам).
set -euo pipefail

REPO="aliaskh4n/NekoPOS"
ASSET="pos-linux-amd64.tar.gz"
INSTALL_DIR="$HOME/.local/share/nekopos"

if [ "$(uname -m)" != "x86_64" ]; then
  echo "Сейчас есть сборка только под x86_64 (amd64). Ваша архитектура: $(uname -m)." >&2
  exit 1
fi

TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep -m1 '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
echo "Скачиваю Neko POS ${TAG}..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/${REPO}/releases/download/${TAG}/${ASSET}" -o "$TMP/app.tar.gz"
curl -fsSL "https://github.com/${REPO}/releases/download/${TAG}/${ASSET}.sha256" -o "$TMP/app.tar.gz.sha256" || true

if [ -s "$TMP/app.tar.gz.sha256" ]; then
  EXPECTED=$(awk '{print $1}' "$TMP/app.tar.gz.sha256")
  ACTUAL=$(sha256sum "$TMP/app.tar.gz" | awk '{print $1}')
  if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "Контрольная сумма не совпала — файл повреждён при скачивании, попробуйте ещё раз." >&2
    exit 1
  fi
fi

mkdir -p "$TMP/extracted"
tar -C "$TMP/extracted" -xzf "$TMP/app.tar.gz"

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp "$TMP/extracted/pos-linux-amd64" "$INSTALL_DIR/nekopos"
cp "$TMP/extracted/nekopos.png" "$INSTALL_DIR/nekopos.png"
chmod +x "$INSTALL_DIR/nekopos"

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/nekopos.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Neko POS
Comment=Касса ресторана
Exec=${INSTALL_DIR}/nekopos
Icon=${INSTALL_DIR}/nekopos.png
Terminal=false
Categories=Office;
EOF

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" || true

echo "Готово: ${INSTALL_DIR}/nekopos (ярлык — в меню приложений, «Neko POS»)"
"$INSTALL_DIR/nekopos" </dev/null >/dev/null 2>&1 &
disown
