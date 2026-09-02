#!/bin/bash
# Install WindUI toolchain via aftman (rojo, darklua, lune) + npm deps
set -u
export PATH="$HOME/.aftman/bin:$PATH"
cd "C:/Users/maula/Desktop/Limbo UI" || exit 1

echo "=== aftman version ==="
aftman --version

echo ""
echo "=== aftman install (trusts tools from aftman.toml) ==="
aftman install --no-trust-check 2>&1 | tail -25

echo ""
echo "=== bin dir after install ==="
ls -la "$HOME/.aftman/bin"

echo ""
echo "=== verify tools ==="
for t in darklua rojo lune; do
  printf "%-8s : " "$t"
  "$HOME/.aftman/bin/$t.exe" --version 2>&1 | head -1 || echo "FAIL"
done
