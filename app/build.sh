#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
APP="$ROOT/Interruptor.app"
BIN="$APP/Contents/MacOS/Interruptor"
PLIST="$APP/Contents/Info.plist"
RES="$APP/Contents/Resources"
ICON_SRC="$ROOT/Icon.svg"
VERSION_FILE="$REPO/VERSION"

VERSION="${1:-$(tr -d '[:space:]' < "$VERSION_FILE")}"
BUILD="${2:-$(git -C "$REPO" rev-list --count HEAD 2>/dev/null || echo 1)}"

mkdir -p "$APP/Contents/MacOS" "$RES"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$PLIST"

log() { [[ "${INTERRUPTOR_QUIET:-}" == "1" ]] || echo "$@"; }

log "⚡ Interruptor v${VERSION} (${BUILD})"
log "→ Compilando…"
swiftc -parse-as-library \
  -O \
  -whole-module-optimization \
  -target arm64-apple-macosx14.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework CoreGraphics \
  -framework IOKit \
  -framework Carbon \
  -o "$BIN" \
  "$ROOT"/Sources/*.swift

chmod +x "$BIN"

log "→ Ícone…"
BUILD_DIR="$ROOT/.build"
ICONSET="$BUILD_DIR/AppIcon.iconset"
rm -rf "$BUILD_DIR"
mkdir -p "$ICONSET"
qlmanage -t -s 1024 -o "$BUILD_DIR" "$ICON_SRC" >/dev/null 2>&1
BASE="$BUILD_DIR/Icon.svg.png"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$BASE" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  s2=$((size * 2))
  sips -z "$s2" "$s2" "$BASE" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RES/AppIcon.icns"

log "→ Assinando…"
if [[ "${INTERRUPTOR_QUIET:-}" == "1" ]]; then
  codesign --force --deep --sign - "$APP" 2>/dev/null
else
  codesign --force --deep --sign - "$APP"
fi
codesign --verify --deep --strict "$APP" 2>/dev/null

log "✓ $APP"
