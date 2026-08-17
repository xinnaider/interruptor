#!/usr/bin/env bash
set -euo pipefail

REPO="${INTERRUPTOR_REPO:-https://github.com/xinnaider/interruptor.git}"
DIR="${INTERRUPTOR_DIR:-$HOME/.local/src/interruptor}"
SRC_APP="$DIR/app/Interruptor.app"
DEST_APP="/Applications/Interruptor.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
INTERACTIVE=0
if [[ -t 1 && -z "${NO_COLOR+x}" ]]; then INTERACTIVE=1; fi

R=""
B=""
D=""
O=""
G=""
if (( INTERACTIVE )); then
  R=$'\033[0m'
  B=$'\033[1m'
  D=$'\033[2m'
  O=$'\033[38;5;214m'
  G=$'\033[32m'
fi

ANIM_PID=""
STEP_FLAG=""
STEP_LOG=""

version_ge() {
  [[ "$(printf '%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]
}

cleanup() {
  local status=$?
  [[ -n "$ANIM_PID" ]] && kill "$ANIM_PID" 2>/dev/null || true
  [[ -n "$STEP_FLAG" ]] && rm -f "$STEP_FLAG" || true
  [[ -n "$STEP_LOG" ]] && rm -f "$STEP_LOG" || true
  (( INTERACTIVE )) && printf '\033[?25h%s' "$R"
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

die() {
  printf '\n  %s✗%s %s\n\n' "$O" "$R" "$1" >&2
  exit 1
}

check_requirements() {
  [[ "$(uname)" == "Darwin" ]] || die "Só macOS."
  [[ "$(uname -m)" == "arm64" ]] || die "Só Apple Silicon."

  local macos_version
  macos_version="$(sw_vers -productVersion 2>/dev/null || echo 0)"
  version_ge "$macos_version" "14.0" || die "Requer macOS 14 ou superior (detectado: $macos_version)."

  command -v git >/dev/null || die "git não encontrado."
  command -v swiftc >/dev/null || die "Instale Xcode Command Line Tools (xcode-select --install)."
}

header() {
  printf '\n  %sINTERRUPTOR%s\n' "$B" "$R"
  printf '  %sInstalador para macOS%s\n\n' "$D" "$R"
}

start_line_animation() {
  local label=$1
  if (( ! INTERACTIVE )); then
    printf '  · %s...\n' "$label"
    return
  fi

  STEP_FLAG="$(mktemp "${TMPDIR:-/tmp}/interruptor-step.XXXXXX")"
  printf '\033[?25l'
  (
    local frame=0
    local spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    while [[ -f "$STEP_FLAG" ]]; do
      printf '\r\033[2K  %s%s%s %s' "$O" "${spin[$((frame % 10))]}" "$R" "$label"
      frame=$((frame + 1))
      sleep 0.08
    done
  ) &
  ANIM_PID=$!
}

stop_line_animation() {
  local label=$1
  local status=$2
  local elapsed=$3

  if (( INTERACTIVE )); then
    rm -f "$STEP_FLAG"
    STEP_FLAG=""
    [[ -n "$ANIM_PID" ]] && wait "$ANIM_PID" 2>/dev/null || true
    ANIM_PID=""
    printf '\r\033[2K'
  fi

  if (( status == 0 )); then
    printf '  %s✓%s %-20s %s%ss%s\n' "$G" "$R" "$label" "$D" "$elapsed" "$R"
  else
    printf '  %s✗%s %s\n' "$O" "$R" "$label" >&2
  fi
}

print_step_error() {
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '    %s\n' "$line" >&2
  done < "$STEP_LOG"
}

run_step() {
  local label=$1
  shift
  local started status elapsed
  started=$(date +%s)
  STEP_LOG="$(mktemp "${TMPDIR:-/tmp}/interruptor-log.XXXXXX")"
  start_line_animation "$label"
  set +e
  "$@" >"$STEP_LOG" 2>&1
  status=$?
  set -e
  elapsed=$(( $(date +%s) - started ))
  stop_line_animation "$label" "$status" "$elapsed"
  if (( status != 0 )); then
    print_step_error
    exit "$status"
  fi
  rm -f "$STEP_LOG"
  STEP_LOG=""
}

check_requirements
header

run_step "Baixando código" bash -c '
  if [[ ! -d "'"$DIR"'/.git" ]]; then
    mkdir -p "'$(dirname "$DIR")'"
    git clone --quiet --depth 1 "'"$REPO"'" "'"$DIR"'"
  else
    git -C "'"$DIR"'" checkout -- app/Interruptor.app/Contents/Info.plist
    git -C "'"$DIR"'" pull --quiet --ff-only
  fi
'

run_step "Compilando app" bash -c 'INTERRUPTOR_QUIET=1 "'"$DIR"'/build.sh"'

run_step "Instalando" bash -c '
  [[ -d "'"$SRC_APP"'" ]] || exit 1
  rm -rf "'"$DEST_APP"'"
  ditto "'"$SRC_APP"'" "'"$DEST_APP"'"
  [[ -x "'"$LSREGISTER"'" ]] && "'"$LSREGISTER"'" -f "'"$DEST_APP"'" || true
'

printf '  %sPronto.%s Clique no ícone na barra de menus.\n\n' "$B" "$R"
open -g -a "$DEST_APP" 2>/dev/null || true
