#!/usr/bin/env bash
set -euo pipefail

REPO="${INTERRUPTOR_REPO:-https://github.com/xinnaider/interruptor.git}"
DIR="${INTERRUPTOR_DIR:-$HOME/.local/src/interruptor}"
SRC_APP="$DIR/app/Interruptor.app"
DEST_APP="/Applications/Interruptor.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
TOTAL_STEPS=3
BAR_WIDTH=24

R=$'\033[0m'
B=$'\033[1m'
D=$'\033[2m'
K=$'\033[90m'
O=$'\033[38;5;214m'
G=$'\033[32m'

STEP=0
ANIM_PID=""
STEP_FLAG=""

version_ge() {
  [[ "$(printf '%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]
}

cleanup() {
  [[ -n "$ANIM_PID" ]] && kill "$ANIM_PID" 2>/dev/null || true
  [[ -n "$STEP_FLAG" ]] && rm -f "$STEP_FLAG"
}
trap cleanup EXIT

die() {
  cleanup
  printf '\n  %s✗ %s%s\n\n' "$O" "$1" "$R" >&2
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
  printf '\n'
  printf '  %s╭──────────────╮%s\n' "$O" "$R"
  printf '  %s│%s  ┌────────┐   %s│%s\n' "$O" "$R" "$O" "$R"
  printf '  %s│%s  │ %s║%s      │   %s│%s\n' "$O" "$R" "$B" "$R" "$O" "$R"
  printf '  %s│%s  └────────┘   %s│%s\n' "$O" "$R" "$O" "$R"
  printf '  %s╰──────────────╯%s\n' "$O" "$R"
  printf '\n  %sInterruptor%s\n' "$B" "$R"
  printf '  %sDesligue o monitor sem puxar o cabo.%s\n\n' "$D" "$R"
}

bar_string() {
  local step=$1
  local mode=${2:-done}
  local base=$(( (step - 1) * BAR_WIDTH / TOTAL_STEPS ))
  local cap=$(( step * BAR_WIDTH / TOTAL_STEPS ))
  local span=$(( cap - base ))
  local head=-1

  if [[ "$mode" != "done" ]] && (( span > 0 )); then
    head=$(( base + mode % span ))
  fi

  local out="  ${K}[${R}"
  local i
  for ((i = 0; i < BAR_WIDTH; i++)); do
    if (( i < base )); then
      out+="${O}█${K}"
    elif [[ "$mode" == "done" ]] && (( i < cap )); then
      out+="${O}█${K}"
    elif [[ "$mode" != "done" ]] && (( i == head )); then
      out+="${O}█${K}"
    else
      out+='░'
    fi
  done
  out+="${K}]${D} ${step}/${TOTAL_STEPS}${R}"
  printf '%s' "$out"
}

render_active_line() {
  local frame=$1
  local label=$2
  local spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local s=${spin[$((frame % 10))]}
  printf '\r  %s %s%-20s%s  %s' "$s" "$B" "$label" "$R" "$(bar_string "$STEP" "$frame")"
}

start_line_animation() {
  local label=$1
  STEP_FLAG="$(mktemp "${TMPDIR:-/tmp}/interruptor-step.XXXXXX")"
  (
    frame=0
    while [[ -f "$STEP_FLAG" ]]; do
      render_active_line "$frame" "$label"
      frame=$((frame + 1))
      sleep 0.09
    done
  ) &
  ANIM_PID=$!
}

stop_line_animation() {
  local label=$1
  local ok=$2
  rm -f "$STEP_FLAG"
  STEP_FLAG=""
  [[ -n "$ANIM_PID" ]] && wait "$ANIM_PID" 2>/dev/null || true
  ANIM_PID=""

  if (( ok == 0 )); then
    printf '\r  %s✓%s %-20s  %s\n' "$G" "$R" "$label" "$(bar_string "$STEP" done)"
  else
    printf '\r  %s✗%s %-20s\n' "$O" "$R" "$label"
  fi
}

run_step() {
  local label=$1
  shift
  STEP=$((STEP + 1))
  start_line_animation "$label"
  set +e
  "$@" >/dev/null 2>&1
  local status=$?
  set -e
  stop_line_animation "$label" "$status"
  (( status == 0 )) || die "Falhou em: $label"
}

check_requirements
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

printf '  %sPronto.%s Clique no ícone na barra de menus.\n\n' "$B" "$R"
open -g -a "$DEST_APP" 2>/dev/null || true
