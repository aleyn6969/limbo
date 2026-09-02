#!/bin/bash
# Install aftman + WindUI toolchain (darklua, rojo, lune)
set -u

TOOLS_DIR="$HOME/.aftman/bin"
TMP="$LOCALAPPDATA/Temp/aftman-install"
mkdir -p "$TMP"

echo "=== 1. Detect existing ==="
for t in aftman rokit darklua rojo lune; do
  printf "%-8s : " "$t"
  command -v "$t" >/dev/null 2>&1 && echo "found -> $(command -v $t)" || echo "missing"
done

echo ""
echo "=== 2. Fetch latest aftman release URL ==="
API="https://api.github.com/repos/LPGhatguy/aftman/releases/latest"
URL=$(curl -sL "$API" | grep -oE '"browser_download_url": *"[^"]*windows[^"]*\.zip"' | grep -oE 'https://[^"]*' | head -1)
echo "URL: ${URL:-NONE}"

if [ -z "${URL:-}" ]; then
  echo "!! could not resolve aftman windows asset"
  exit 1
fi

echo ""
echo "=== 3. Download ==="
curl -sL -o "$TMP/aftman.zip" "$URL" || { echo "download failed"; exit 1; }
ls -la "$TMP/aftman.zip"

echo ""
echo "=== 4. Unzip ==="
cd "$TMP" && rm -f aftman.exe && unzip -o aftman.zip >/dev/null && ls -la

echo ""
echo "=== 5. Self-install ==="
mkdir -p "$TOOLS_DIR"
"$TMP/aftman.exe" self-install 2>&1 | tail -5

echo ""
echo "=== 6. Verify aftman bin dir ==="
ls -la "$TOOLS_DIR" 2>/dev/null
