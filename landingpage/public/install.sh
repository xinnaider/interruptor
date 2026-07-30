#!/usr/bin/env bash
set -euo pipefail

REPO="${INTERRUPTOR_REPO:-https://github.com/xinnaider/interruptor.git}"
DIR="${INTERRUPTOR_DIR:-$HOME/.local/src/interruptor}"
APP="$DIR/app/Interruptor.app"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
die() { printf '✗ %s\n' "$*" >&2; exit 1; }

[[ "$(uname)" == "Darwin" ]] || die "Interruptor só roda no macOS."
[[ "$(uname -m)" == "arm64" ]] || die "Interruptor só roda em Apple Silicon."

command -v git >/dev/null || die "git não encontrado."
command -v swiftc >/dev/null || die "Xcode Command Line Tools necessários: xcode-select --install"

bold "Interruptor — instalando…"

if [[ ! -d "$DIR/.git" ]]; then
  mkdir -p "$(dirname "$DIR")"
  git clone "$REPO" "$DIR"
else
  git -C "$DIR" pull --ff-only
fi

"$DIR/build.sh"
[[ -d "$APP" ]] || die "Build falhou: $APP não encontrado."

if [[ "${INSTALL_TO_APPLICATIONS:-}" == "1" ]]; then
  cp -R "$APP" /Applications/Interruptor.app
  bold "Copiado para /Applications/Interruptor.app"
  open -a /Applications/Interruptor.app
else
  bold "Pronto: $APP"
  open "$APP"
fi
