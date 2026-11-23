#!/bin/bash
# KLayout screenshot rig: Xvfb + fluxbox + KLayout + xdotool steps -> PNGs.
#
# Runs INSIDE the asic-edu/gui-rig:2026.08 container (or any IIC-OSIC-TOOLS
# image with Xvfb, fluxbox, xdotool and ImageMagick). The host-side wrapper
# is run_rig.sh next to this file; README.md documents the step language.
#
#   rig.sh start  [klayout args...]   Xvfb + fluxbox, then klayout in the background
#   rig.sh steps  FILE                run a steps file (see README.md)
#   rig.sh <step> [args...]           run one step (for docker exec sessions)
#   rig.sh stop                       kill klayout, fluxbox and Xvfb
#
# Environment:
#   RIG_DISPLAY  display number (default :57; pick one nobody else uses)
#   RIG_GEOM     screen size (default 1680x1050, the image's default VNC_RESOLUTION;
#                the workbench's start_vnc.sh uses 1280x800)
#   RIG_DPI      X DPI (default 96)
#   RIG_OUT      where PNGs go (default ./out); logs go to $RIG_OUT/logs

set -u
export DISPLAY="${RIG_DISPLAY:-:57}"
GEOM="${RIG_GEOM:-1680x1050}"
DPI="${RIG_DPI:-96}"
OUT="${RIG_OUT:-$PWD/out}"
LOGD="$OUT/logs"
mkdir -p "$OUT" "$LOGD"
LOG="$LOGD/rig.log"

say() { echo "[rig $(date +%H:%M:%S)] $*" | tee -a "$LOG" >&2; }

# ---- pointer helpers --------------------------------------------------------
# "xdotool mousemove --sync X Y" waits for a motion event and blocks forever
# when the pointer is already at X Y, so: skip the move if it is already
# there, and put a timeout on every xdotool call that can wait.
X() { timeout 10 xdotool "$@"; }
to() {            # to X Y : move the pointer, without hanging
  eval "$(xdotool getmouselocation --shell 2>/dev/null)"
  if [ "${X:-}" != "$1" ] || [ "${Y:-}" != "$2" ]; then
    X mousemove --sync "$1" "$2" || X mousemove "$1" "$2"
  fi
}

# ---- window helpers ---------------------------------------------------------

# First visible window whose title matches an extended regex.
win() { xdotool search --onlyvisible --name "$1" 2>/dev/null | head -1; }

wait_window() {   # wait_window REGEX [TIMEOUT_S]
  local re="$1" t="${2:-30}" w="" i=0
  while [ $i -lt $((t * 4)) ]; do
    w=$(win "$re"); [ -n "$w" ] && { echo "$w"; return 0; }
    sleep 0.25; i=$((i + 1))
  done
  say "TIMEOUT waiting ${t}s for window /$re/"; return 1
}

wait_gone() {     # wait_gone REGEX [TIMEOUT_S]
  local re="$1" t="${2:-30}" i=0
  while [ $i -lt $((t * 4)) ]; do
    [ -z "$(win "$re")" ] && return 0
    sleep 0.25; i=$((i + 1))
  done
  say "TIMEOUT waiting ${t}s for /$re/ to close"; return 1
}

geom() {          # geom WINID -> "X Y W H"
  eval "$(xdotool getwindowgeometry --shell "$1")"; echo "$X $Y $WIDTH $HEIGHT"
}

# ---- steps ------------------------------------------------------------------

step() {
  local cmd="$1"; shift
  case "$cmd" in
    sleep)        sleep "$1" ;;
    wait)         wait_window "$1" "${2:-30}" >/dev/null ;;
    gone)         wait_gone "$1" "${2:-30}" ;;
    activate)     local w; w=$(wait_window "$1" "${2:-10}") || return 1
                  X windowactivate --sync "$w" 2>/dev/null || X windowfocus --sync "$w"
                  sleep 0.3 ;;
    key)          X key --delay 80 "$@"; sleep 0.3 ;;
    type)         X type --delay 40 -- "$*"; sleep 0.2 ;;
    click)        to "$1" "$2"; X click "${3:-1}"; sleep 0.4 ;;
    wheel)        # wheel X Y N : N clicks down (negative: up)
                  to "$1" "$2"; local b=5 n="$3"; [ "$n" -lt 0 ] && { b=4; n=$(( -n )); }
                  X click --repeat "$n" --delay 60 "$b"; sleep 0.3 ;;
    dclick)       to "$1" "$2"; X click --repeat 2 --delay 120 1; sleep 0.4 ;;
    move)         to "$1" "$2"; sleep 0.3 ;;
    wclick)       # wclick REGEX DX DY [BUTTON]: click relative to a window's top-left
                  local w g; w=$(wait_window "$1" 10) || return 1; g=($(geom "$w"))
                  to $((g[0] + $2)) $((g[1] + $3)); X click "${4:-1}"; sleep 0.4 ;;
    drag)         # drag X1 Y1 X2 Y2: press at 1, move in steps, release at 2
                  to "$1" "$2"; X mousedown 1; sleep 0.2
                  to $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 )); sleep 0.2
                  to "$3" "$4"; sleep 0.2
                  X mouseup 1; sleep 0.4 ;;
    shot)         import -window root "$OUT/$1.png" && say "shot $1.png" ;;
    crop)         # crop NAME WxH+X+Y NEWNAME : cut a region out of an earlier shot
                  convert "$OUT/$1.png" -crop "$2" +repage "$OUT/$3.png" && say "crop $3.png" ;;
    shotwin)      # shotwin REGEX NAME: just that window (dialogs)
                  local w; w=$(wait_window "$1" 10) || return 1
                  import -window "$w" "$OUT/$2.png" && say "shot $2.png ($1)" ;;
    windows)      xdotool search --onlyvisible --name '.' 2>/dev/null | while read -r w; do
                    echo "$w $(geom "$w") $(xdotool getwindowname "$w")"; done ;;
    ifwin)        # ifwin REGEX STEP... : only if that window is up now, raise it and run STEP
                  local re="$1"; shift; local w; w=$(win "$re")
                  if [ -n "$w" ]; then X windowactivate --sync "$w" 2>/dev/null; sleep 0.3; step "$@"
                  else say "ifwin: no /$re/, skipped"; fi ;;
    maximize)     # maximize REGEX : fill the screen below fluxbox's title bar, above its toolbar
                  local w; w=$(wait_window "$1" 10) || return 1
                  local sw=${GEOM%x*} sh=${GEOM#*x}
                  X windowmove "$w" 0 22; X windowsize "$w" "$sw" $(( sh - 50 )); sleep 1 ;;
    waitfile)     # waitfile PATH [TIMEOUT_S]
                  local i=0 t="${2:-60}"; while [ ! -s "$1" ] && [ $i -lt $((t * 4)) ]; do sleep 0.25; i=$((i + 1)); done
                  [ -s "$1" ] || { say "TIMEOUT waiting for $1"; return 1; } ;;
    sh)           bash -c "$*" ;;
    log)          say "$*" ;;
    since)        # since LABEL : seconds since klayout was started (for timing)
                  local t0; t0=$(cat "$LOGD/klayout.t0" 2>/dev/null || echo 0)
                  say "$1: $(echo "$(date +%s.%N) - $t0" | bc) s after klayout started" ;;
    *)            say "unknown step: $cmd"; return 2 ;;
  esac
}

start() {
  say "Xvfb $DISPLAY ${GEOM}x24 dpi $DPI"
  Xvfb "$DISPLAY" -screen 0 "${GEOM}x24" -dpi "$DPI" -nolisten tcp >"$LOGD/xvfb.log" 2>&1 &
  echo $! >"$LOGD/xvfb.pid"
  for _ in $(seq 1 40); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.25; done
  # fluxbox's default style runs fbsetbg, which pops up an xmessage
  # ("Something went wrong while setting the background") that lands in every
  # screenshot. An overlay with "background: none" stops it.
  mkdir -p "$LOGD/fluxbox"
  printf 'background: none\n' >"$LOGD/fluxbox/overlay"
  printf 'session.styleOverlay: %s\n' "$LOGD/fluxbox/overlay" >"$LOGD/fluxbox/init"
  fluxbox -rc "$LOGD/fluxbox/init" >"$LOGD/fluxbox.log" 2>&1 &
  echo $! >"$LOGD/fluxbox.pid"
  sleep 1.5
  pkill -x xmessage 2>/dev/null || true
  xsetroot -solid '#3b4252' 2>/dev/null || true
  if [ $# -gt 0 ]; then
    say "klayout $*"
    RIG_T0=$(date +%s.%N); export RIG_T0
    klayout "$@" >"$LOGD/klayout.log" 2>&1 &
    echo $! >"$LOGD/klayout.pid"
    echo "$RIG_T0" >"$LOGD/klayout.t0"
  fi
}

stop() {
  for p in klayout fluxbox xvfb; do
    [ -f "$LOGD/$p.pid" ] && kill "$(cat "$LOGD/$p.pid")" 2>/dev/null
    rm -f "$LOGD/$p.pid"
  done
  sleep 0.5
  pkill -x klayout 2>/dev/null; pkill -x fluxbox 2>/dev/null; pkill -x Xvfb 2>/dev/null
  say "stopped"
}

steps() {
  local file="$1" n=0 line
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    line="${line%%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    eval "set -- $line"
    if ! step "$@"; then say "FAILED at $file:$n: $line"; step shot "FAILED-line$n"; return 1; fi
  done <"$file"
}

case "${1:-}" in
  start) shift; start "$@" ;;
  stop)  stop ;;
  steps) shift; steps "$1" ;;
  "")    sed -n '2,20p' "$0" ;;
  *)     step "$@" ;;
esac
