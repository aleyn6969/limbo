#!/bin/bash
# Manual install rojo + lune (aftman download timed out on these)
set -u
BIN="$HOME/.aftman/bin"
TMP="$LOCALAPPDATA/Temp/tool-dl"
mkdir -p "$TMP" "$BIN"

fetch_tool () {
  NAME="$1"; REPO="$2"; TAG="$3"; ASSET="$4"
  URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"
  echo "--- $NAME <- $URL"
  curl -sL --retry 3 --retry-delay 2 -m 240 -o "$TMP/$NAME.zip" "$URL"
  SZ=$(wc -c < "$TMP/$NAME.zip" 2>/dev/null || echo 0)
  echo "    size: $SZ bytes"
  if [ "$SZ" -lt 100000 ]; then echo "    !! too small, likely failed"; head -c 200 "$TMP/$NAME.zip"; echo; return 1; fi
  rm -rf "$TMP/$NAME" && mkdir -p "$TMP/$NAME"
  unzip -o -q "$TMP/$NAME.zip" -d "$TMP/$NAME" || { echo "    !! unzip failed"; return 1; }
  EXE=$(find "$TMP/$NAME" -name "$NAME.exe" | head -1)
  if [ -z "$EXE" ]; then echo "    !! $NAME.exe not found"; find "$TMP/$NAME" -type f | head; return 1; fi
  cp "$EXE" "$BIN/$NAME.exe" && echo "    OK -> $BIN/$NAME.exe"
}

fetch_tool rojo rojo-rbx/rojo v7.3.0 rojo-7.3.0-windows-x86_64.zip
fetch_tool lune filiptibell/lune v0.7.6 lune-0.7.6-windows-x86_64.zip

echo ""
echo "=== FINAL VERIFY ==="
export PATH="$BIN:$PATH"
for t in aftman darklua rojo lune; do
  printf "%-8s : " "$t"
  if [ -f "$BIN/$t.exe" ]; then "$BIN/$t.exe" --version 2>&1 | head -1; else echo "MISSING"; fi
done
