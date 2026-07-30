#!/usr/bin/env bash
set -euo pipefail

REPO="${INTERRUPTOR_REPO:-https://github.com/xinnaider/interruptor.git}"
DIR="${INTERRUPTOR_DIR:-$HOME/.local/src/interruptor}"
SRC_APP="$DIR/app/Interruptor.app"
DEST_APP="/Applications/Interruptor.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

die() { printf '\n%s\n' "$1" >&2; exit 1; }

[[ "$(uname)" == "Darwin" ]] || die "Interruptor: só macOS."
[[ "$(uname -m)" == "arm64" ]] || die "Interruptor: só Apple Silicon."
command -v git >/dev/null || die "Interruptor: git não encontrado."
command -v swiftc >/dev/null || die "Interruptor: instale Xcode Command Line Tools."

printf 'Interruptor…'

if [[ ! -d "$DIR/.git" ]]; then
  mkdir -p "$(dirname "$DIR")"
  git clone --quiet --depth 1 "$REPO" "$DIR" 2>/dev/null || die "Interruptor: não foi possível baixar."
else
  git -C "$DIR" pull --quiet --ff-only 2>/dev/null || true
fi

INTERRUPTOR_QUIET=1 "$DIR/build.sh" >/dev/null 2>&1 || die "Interruptor: não foi possível compilar."
[[ -d "$SRC_APP" ]] || die "Interruptor: app não encontrado."

rm -rf "$DEST_APP"
ditto "$SRC_APP" "$DEST_APP"
[[ -x "$LSREGISTER" ]] && "$LSREGISTER" -f "$DEST_APP" >/dev/null 2>&1 || true

printf '\rInterruptor instalado.\n'
open -a "$DEST_APP"
