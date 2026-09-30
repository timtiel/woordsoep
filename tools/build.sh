#!/usr/bin/env bash
# Bouwt dist/woordspel (manifest.json, icon.png, resources.rcc) uit app/.
# Gebruik: RCC=/pad/naar/rcc ./tools/build.sh   (of laat RCC weg als rcc in PATH staat)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RCC="${RCC:-}"
if [ -z "$RCC" ]; then
    RCC="$(find "$ROOT/.qt" -name rcc -type f 2>/dev/null | head -n1 || true)"
fi
if [ -z "$RCC" ]; then
    RCC="$(command -v rcc || true)"
fi
if [ -z "$RCC" ]; then
    echo "rcc niet gevonden. Zet RCC=<pad naar rcc> of installeer Qt tools." >&2
    exit 1
fi

APP="$ROOT/app"
DIST="$ROOT/dist/woordspel"

rm -rf "$DIST"
mkdir -p "$DIST"

cp "$APP/manifest.json" "$DIST"

if [ ! -f "$APP/icon.png" ]; then
    python3 "$ROOT/tools/make_icon.py"
fi
cp "$APP/icon.png" "$DIST"

(cd "$APP" && "$RCC" --binary -o "$DIST/resources.rcc" application.qrc)

echo "Klaar: $DIST"
ls -l "$DIST"
