#!/usr/bin/env bash
set -euo pipefail

REPO="${INTERRUPTOR_REPO:-https://github.com/xinnaider/interruptor.git}"
DIR="${INTERRUPTOR_DIR:-$HOME/.local/src/interruptor}"
SRC_APP="$DIR/app/Interruptor.app"
DEST_APP="/Applications/Interruptor.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
TOTAL_STEPS=3

R=$'\033[0m'
B=$'\033[1m'
D=$'\033[2m'
K=$'\033[90m'
O=$'\033[38;5;214m'
G=$'\033[32m'

STEP=0
SPIN_PID=""

cleanup() {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null || true
}
trap cleanup EXIT

die() {
  cleanup
  printf '\n  %s✗ %s%s\n\n' "$O" "$1" "$R" >&2
  exit 1
}

header() {
  printf '\n'
  printf '  %s╭────────────╮%s\n' "$O" "$R"
  printf '  %s│%s ┌────────┐ %s│%s\n' "$O" "$R" "$O" "$R"
  printf '  %s│%s │ %s▐%s%s▌%s    │ %s│%s\n' "$O" "$R" "$B" "$R" "$B" "$R" "$O" "$R"
  printf '  %s│%s └────────┘ %s│%s\n' "$O" "$R" "$O" "$R"
  printf '  %s╰────────────╯%s\n' "$O" "$R"
  printf '\n  %sInterruptor%s\n' "$B" "$R"
  printf '  %sDesligue o monitor sem puxar o cabo.%s\n\n' "$D" "$R"
}

progress_bar() {
  local width=28
  local filled=$(( STEP * width / TOTAL_STEPS ))
  local empty=$(( width - filled ))
  local i
  printf '  %s[' "$K"
  for ((i = 0; i < filled; i++)); do printf '%s█%s' "$O" "$K"; done
  for ((i = 0; i < empty; i++)); do printf '░'; done
  printf ']%s %d/%d%s\n\n' "$D" "$STEP" "$TOTAL_STEPS" "$R"
}

start_spinner() {
  local label=$1
  (
    while true; do
      for frame in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do
        printf '\r  %s %s%-18s%s' "$frame" "$B" "$label" "$R"
        sleep 0.09
      done
    done
  ) &
  SPIN_PID=$!
}

stop_spinner() {
  local label=$1
  local ok=$2
  cleanup
  SPIN_PID=""
  if (( ok == 0 )); then
    printf '\r  %s✓%s %-18s\n' "$G" "$R" "$label"
  else
    printf '\r  %s✗%s %-18s\n' "$O" "$R" "$label"
  fi
}

run_step() {
  local label=$1
  shift
  STEP=$((STEP + 1))
  start_spinner "$label"
  set +e
  "$@" >/dev/null 2>&1
  local status=$?
  set -e
  stop_spinner "$label" "$status"
  (( status == 0 )) || die "Falhou em: $label"
  progress_bar
}

[[ "$(uname)" == "Darwin" ]] || die "Só macOS."
[[ "$(uname -m)" == "arm64" ]] || die "Só Apple Silicon."
command -v git >/dev/null || die "git não encontrado."
command -v swiftc >/dev/null || die "Instale Xcode Command Line Tools."

header

run_step "Baixando código" bash -c '
  if [[ ! -d "'"$DIR"'/.git" ]]; then
    mkdir -p "'$(dirname "$DIR")'"
    git clone --quiet --depth 1 "'"$REPO"'" "'"$DIR"'"
  else
    git -C "'"$DIR"'" pull --quiet --ff-only || true
  fi
'

run_step "Compilando app" bash -c 'INTERRUPTOR_QUIET=1 "'"$DIR"'/build.sh"'

run_step "Instalando" bash -c '
  [[ -d "'"$SRC_APP"'" ]] || exit 1
  rm -rf "'"$DEST_APP"'"
  ditto "'"$SRC_APP"'" "'"$DEST_APP"'"
  [[ -x "'"$LSREGISTER"'" ]] && "'"$LSREGISTER"'" -f "'"$DEST_APP"'" || true
'

printf '  %sPronto.%s Interruptor está em Aplicativos.\n\n' "$B" "$R"
open -a "$DEST_APP"
