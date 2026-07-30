#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
APP="$ROOT/Interruptor.app"
BIN="$APP/Contents/MacOS/Interruptor"
PLIST="$APP/Contents/Info.plist"
VERSION_FILE="$REPO/VERSION"

VERSION="${1:-$(tr -d '[:space:]' < "$VERSION_FILE")}"
BUILD="${2:-$(git -C "$REPO" rev-list --count HEAD 2>/dev/null || echo 1)}"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD" "$PLIST"

echo "→ Compilando Interruptor v${VERSION} (${BUILD})…"
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
echo "✓ Pronto: $APP"
