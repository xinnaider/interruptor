#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(tr -d '[:space:]' < "$ROOT/VERSION")}"
APP="$ROOT/app/Interruptor.app"
OUT="$ROOT/dist"
ZIP="$OUT/Interruptor-${VERSION}.zip"

"$ROOT/app/build.sh" "$VERSION"

rm -rf "$OUT"
mkdir -p "$OUT"

echo "Empacotando ${ZIP}..."
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

# appcast consumido pelo updater no Mac
cat > "$OUT/appcast.json" <<EOF
{
  "version": "${VERSION}",
  "shortVersion": "${VERSION}",
  "downloadURL": "https://github.com/xinnaider/interruptor/releases/download/v${VERSION}/Interruptor-${VERSION}.zip",
  "releasePage": "https://github.com/xinnaider/interruptor/releases/tag/v${VERSION}",
  "minimumSystemVersion": "14.0"
}
EOF

cp "$OUT/appcast.json" "$ROOT/landingpage/public/appcast.json"

echo "Artefatos em $OUT"
ls -lh "$OUT"
