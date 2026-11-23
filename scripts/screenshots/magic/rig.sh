#!/usr/bin/env bash
# Runs inside asic-edu/gui-rig:2026.08 (started by shot.sh). Starts a virtual screen with a
# window manager, then sources one or more step files, which drive Magic's GUI with the
# functions below and write PNGs into /out.
#
#   rig.sh STEP_FILE...
#
# Mounts (set up by shot.sh):
#   /rig    this folder, read-only (rig.sh, probe.tcl, fluxbox-init)
#   /src    the course repo (or any folder), read-only; `work` copies from it
#   /steps  the folder holding the step files, read-only
#   /out    where PNGs, .txt readouts and the log go
#
# Everything Magic writes (.mag saves, .ext, .spice, .gds) lands in /tmp/work inside the
# container and disappears with it, unless a step copies it to /out with `keep`.
set -euo pipefail

export DISPLAY=":${RIG_DISPLAY:-57}"
SCREEN="${SCREEN:-1600x1000}"
export PDK=sky130A PDK_ROOT=/foss/pdks
export RIG_PROBE_DIR=/tmp/rig-probe
OUT="${OUT:-/out}"
mkdir -p "$RIG_PROBE_DIR" "$OUT" /tmp/work

log() { echo "rig: $*" >&2; }

# --- A virtual screen with a window manager -----------------------------------------------
# fluxbox, with its toolbar hidden and click-to-focus, which is the focus model of the
# workbench's XFCE desktop (xfwm4 click_to_focus=true). Without a window manager Tk's menus,
# dialogs and focus changes misbehave.
mkdir -p "$HOME/.fluxbox"
cp /rig/fluxbox-init "$HOME/.fluxbox/init"
Xvfb "$DISPLAY" -screen 0 "${SCREEN}x24" -nolisten tcp >/tmp/xvfb.log 2>&1 &
XVFB_PID=$!
for _ in $(seq 1 50); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.1; done
fluxbox >/tmp/fluxbox.log 2>&1 &
FLUXBOX_PID=$!
sleep 1.5
# fluxbox's default style tries to set a wallpaper and, finding no image, pops up an
# xmessage reading "what." near the right edge of the screen, at start and sometimes again
# later. Close it here and before every capture, and paint the root window a flat grey.
pkill -x xmessage 2>/dev/null || true
xsetroot -solid '#5a5a5a'

# On a failure, leave a picture of the screen as it was (failed.png) before tearing down.
# Step files run under `set -euo pipefail`, so any command in them that fails (a grep that
# matches nothing, a probe that errors) ends the run here.
cleanup() {
    local rc=$?
    if [ "$rc" != 0 ]; then
        log "stopped with status $rc; screen saved as failed.png"
        import -window root "$OUT/failed.png" 2>/dev/null || true
    fi
    # Exact process names, never `pkill -f`: a pattern matched against whole command lines
    # also matches this script's own command line when a step file's name contains it
    # (`/steps/c-magic2.sh`). Magic's GUI and netgen's console run as `wish` (tkcon.tcl),
    # batch netgen as `netgenexec`.
    if [ -n "${MAGIC_PID:-}" ]; then kill "$MAGIC_PID" 2>/dev/null || true; fi
    local p
    for p in wish magicexec magicdnull netgenexec xterm; do pkill -x "$p" 2>/dev/null || true; done
    kill "$FLUXBOX_PID" "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT

# --- Small helpers --------------------------------------------------------------------------
pause() { sleep "$1"; }

# work FOLDER: copy FOLDER of /src to /tmp/work/FOLDER, where Magic may write.
work() {
    mkdir -p "/tmp/work/$1"
    cp -a "/src/$1/." "/tmp/work/$1/"
}

# keep PATH...: copy files from /tmp/work into /out/files/ (to look at what Magic wrote).
keep() {
    mkdir -p "$OUT/files"
    local f
    for f in "$@"; do cp -a "/tmp/work/$f" "$OUT/files/" && log "kept $f"; done
}

# --- The probe: a back channel into Magic's Tcl interpreter (see probe.tcl) ----------------
# probe TCL: evaluate TCL in the running Magic and print the result. Fails if the Tcl errors.
# Use it to read state and widget positions, never to change the layout: a screenshot step
# has to do its work with the mouse and keys, as a student would.
probe() {
    local d="$RIG_PROBE_DIR" i rc
    rm -f "$d/out"
    printf '%s' "$*" > "$d/cmd.tmp" && mv "$d/cmd.tmp" "$d/cmd"
    for i in $(seq 1 400); do [ -f "$d/out" ] && break; sleep 0.05; done
    if [ ! -f "$d/out" ]; then log "probe timed out: $*"; return 2; fi
    rc="$(head -n 1 "$d/out")"
    tail -n +2 "$d/out"
    [ "$rc" = 0 ]
}

# wait_probe [SECONDS]: wait until Magic answers probes (it has finished starting).
wait_probe() {
    local limit="${1:-60}" i
    for i in $(seq 1 "$limit"); do
        if [ "$(probe 'expr 1' 2>/dev/null)" = 1 ]; then log "Magic answers after ${i}s"; return 0; fi
        sleep 1
    done
    log "Magic never answered; its output:"; cat /tmp/magic.log >&2 || true
    return 1
}

# --- Windows ---------------------------------------------------------------------------------
# find_window TITLE_REGEX [SECONDS]: print the id of the newest visible window whose title
# matches, waiting for it to appear.
find_window() {
    local title="$1" limit="${2:-30}" i w
    for i in $(seq 1 $((limit * 2))); do
        w="$(xdotool search --onlyvisible --name "$title" 2>/dev/null | tail -n 1 || true)"
        if [ -n "$w" ]; then echo "$w"; return 0; fi
        sleep 0.5
    done
    log "no window matching '$title' after ${limit}s; windows open:"; windows >&2
    return 1
}

windows() {
    local w n
    for w in $(xdotool search --onlyvisible --name '.+' 2>/dev/null); do
        n="$(xdotool getwindowname "$w" 2>/dev/null || true)"
        [ -n "$n" ] && echo "  $w  [$n]  $(win_rect "$w")"
    done
}

# win_rect WINDOW_ID: "X Y W H" of a window's client area on the screen.
win_rect() {
    xwininfo -id "$1" | awk '/Absolute upper-left X/{x=$4} /Absolute upper-left Y/{y=$4}
                             /^  Width/{w=$2} /^  Height/{h=$2} END{print x, y, w, h}'
}

# place WINDOW_ID X Y W H: move and resize a top-level window (X Y is its client corner).
place() {
    xdotool windowsize --sync "$1" "$4" "$5" 2>/dev/null || xdotool windowsize "$1" "$4" "$5"
    xdotool windowmove --sync "$1" "$2" "$3" 2>/dev/null || xdotool windowmove "$1" "$2" "$3"
    sleep 0.3
}

# --- Magic ------------------------------------------------------------------------------------
LAYOUT_WIN="" CONSOLE_WIN="" MAGIC_PID=""
# Where magic_open puts the two windows (client areas). On a screen at least 1000 px tall
# the layout window keeps Magic's own default size, 1200 x 750, and the console goes under
# it. On a shorter screen (the workbench's 1280 x 800) both shrink so that the console's
# bottom edge stays on the screen: at 1280 x 800 the layout window is 1200 x 540 and the
# console 1200 x 170 at y = 623, which is where the critique's 1280 x 800 runs put them.
# LAYOUT_GEOM and CONSOLE_GEOM ("X Y W H") override both.
_screen_h="${SCREEN#*x}"
if [ "$_screen_h" -ge 1000 ]; then
    LAYOUT_GEOM="${LAYOUT_GEOM:-0 22 1200 750}"
    CONSOLE_GEOM="${CONSOLE_GEOM:-0 800 1200 200}"
else
    LAYOUT_GEOM="${LAYOUT_GEOM:-0 22 1200 $((_screen_h - 260))}"
    CONSOLE_GEOM="${CONSOLE_GEOM:-0 $((_screen_h - 200)) 1200 170}"
fi

# magic_open FOLDER ARG...: start Magic in /tmp/work/FOLDER the way a student does
# (`magic -d X11 ARG...`), wait for it, and place its windows. ARG is usually a cell name.
magic_open() {
    local dir="$1"; shift
    rm -f "$RIG_PROBE_DIR"/*
    # The probe is sourced from a .magicrc in the start folder (Magic reads ./.magicrc after
    # ~/.magicrc), not passed on the command line: a .tcl argument makes Magic print
    # "Handling file entry /rig/probe.tcl extension .tcl" in the console, where it would
    # show in screenshots. The work copy is thrown away, so changing its .magicrc is safe.
    grep -q 'rig/probe.tcl' "/tmp/work/$dir/.magicrc" 2>/dev/null ||
        echo 'source /rig/probe.tcl' >> "/tmp/work/$dir/.magicrc"
    ( cd "/tmp/work/$dir" && exec magic -d X11 "$@" ) >/tmp/magic.log 2>&1 &
    # `magic` is a shell script that execs tkcon.tcl under wish, so this pid is Magic's GUI
    # process (`wish`) for its whole life; magic_quit kills exactly this pid.
    MAGIC_PID=$!
    wait_probe 60
    LAYOUT_WIN="$(find_window '^layout1$' 30)"
    CONSOLE_WIN="$(find_window '^tkcon' 30)"
    # shellcheck disable=SC2086
    place "$LAYOUT_WIN" $LAYOUT_GEOM
    # shellcheck disable=SC2086
    place "$CONSOLE_WIN" $CONSOLE_GEOM
    focus_layout
    settle
}

# move_window TITLE_REGEX X Y: move a dialog (its client corner) to X Y, for dialogs that
# open half off the screen, like the device generator's.
move_window() { local w; w="$(find_window "$1" 10)"; xdotool windowmove --sync "$w" "$2" "$3" 2>/dev/null || xdotool windowmove "$w" "$2" "$3"; sleep 0.5; }

# magic_quit: end Magic without saving (nothing is lost: the work copy is thrown away).
# Kills only the pid magic_open started. `pkill -f magic` also killed this rig whenever a
# step file's path contained "magic", and `pkill -x magic` finds nothing, because the
# process is called `wish`.
magic_quit() {
    probe 'after 100 {quit -noprompt}' >/dev/null 2>&1 || true
    local i
    for i in $(seq 1 15); do
        [ -n "$MAGIC_PID" ] && kill -0 "$MAGIC_PID" 2>/dev/null || break
        sleep 0.2
    done
    if [ -n "$MAGIC_PID" ] && kill -0 "$MAGIC_PID" 2>/dev/null; then
        kill "$MAGIC_PID" 2>/dev/null; sleep 0.5
        kill -0 "$MAGIC_PID" 2>/dev/null && kill -9 "$MAGIC_PID" 2>/dev/null
    fi
    wait "$MAGIC_PID" 2>/dev/null || true
    MAGIC_PID="" LAYOUT_WIN="" CONSOLE_WIN=""
    rm -f "$RIG_PROBE_DIR"/*
    sleep 0.5
}

# focus_layout: give the layout window the keyboard focus the way a student does on a
# click-to-focus desktop: click its title bar (the sienna caption strip, which has no
# binding of its own), then park the pointer over the drawing.
focus_layout() {
    local xy
    xy="$(probe '::rigprobe::center [::rigprobe::frame].titlebar.caption')"
    # shellcheck disable=SC2086
    xdotool mousemove --sync $xy click 1
    sleep 0.3
}

# focus_console: click in the console's text, below the last line.
focus_console() {
    local r; r=($(win_rect "$CONSOLE_WIN"))
    xdotool mousemove --sync $((r[0] + r[2] / 2)) $((r[1] + r[3] - 12)) click 1
    sleep 0.3
}

# --- Mouse and keys ---------------------------------------------------------------------------
# click_xy X Y [BUTTON]: click at a screen position (BUTTON 1 left, 2 middle, 3 right).
click_xy() { xdotool mousemove --sync "$1" "$2" click "${3:-1}"; sleep "${CLICK_PAUSE:-1}"; }

# um_xy X Y: the screen pixel for layout position (X, Y) in microns, in the current view.
um_xy() { probe "::rigprobe::um2px $1 $2"; }

# hover_um X Y: put the pointer over layout position (X, Y) microns. At a zoom where one
# pixel is about one snap step, the computed pixel can land one step off, so this reads
# back where Magic thinks the pointer is (`cursor`, snapped like a click) and nudges the
# pointer a pixel at a time until it agrees, or gives up after 6 tries (the readout then
# says where it really is; zoom in for finer positioning).
hover_um() {
    local xy px py i c cx cy tx ty
    xy=($(um_xy "$1" "$2")); px=${xy[0]}; py=${xy[1]}
    local w; w=($(probe '::rigprobe::rect [lindex [magic::windownames layout] 0]'))
    if [ "$px" -lt "${w[0]}" ] || [ "$py" -lt "${w[1]}" ] ||
       [ "$px" -ge $((w[0] + w[2])) ] || [ "$py" -ge $((w[1] + w[3])) ]; then
        log "hover_um $1 $2: that point is outside the window's view ($(view_um)); zoom or pan first"
        return 1
    fi
    tx=$(awk -v v="$1" 'BEGIN{printf "%d", (v >= 0 ? v * 200 + 0.5 : v * 200 - 0.5)}')
    ty=$(awk -v v="$2" 'BEGIN{printf "%d", (v >= 0 ? v * 200 + 0.5 : v * 200 - 0.5)}')
    for i in 1 2 3 4 5 6; do
        xdotool mousemove --sync "$px" "$py"; sleep 0.25
        c=($(probe '[lindex [magic::windownames layout] 0] cursor internal'))
        cx=${c[0]}; cy=${c[1]}
        [ "$cx" -eq "$tx" ] && [ "$cy" -eq "$ty" ] && return 0
        [ "$cx" -lt "$tx" ] && px=$((px + 1)); [ "$cx" -gt "$tx" ] && px=$((px - 1))
        [ "$cy" -lt "$ty" ] && py=$((py - 1)); [ "$cy" -gt "$ty" ] && py=$((py + 1))
    done
    log "hover_um $1 $2: pointer is at internal $cx $cy, wanted $tx $ty"
}

# hover_center: put the pointer in the middle of the drawing area. Magic's layout keys act
# at the pointer, and a key pressed while the pointer is anywhere else (a scrollbar, the
# title bar, a dialog that just closed) leaves Magic with no current window: until the
# pointer comes back over the drawing, window commands fail with an empty error, and menu
# items raise an "Application Error" box. So hover before every key.
hover_center() {
    local w; w=($(probe '::rigprobe::rect [lindex [magic::windownames layout] 0]'))
    xdotool mousemove --sync $((w[0] + w[2] / 2)) $((w[1] + w[3] / 2)); sleep 0.3
}

# click_um X Y [BUTTON]: click the layout at (X, Y) microns. Left (1) moves the box's
# lower-left corner there, right (3) moves its upper-right corner, middle (2) paints the
# layer under the pointer into the box (or erases, over empty space).
# Magic ignored a second click that came less than about half a second after the first
# (a right click 0.4 s after a left click left the box unchanged), so every click is
# followed by CLICK_PAUSE seconds (default 1).
click_um() { hover_um "$1" "$2"; xdotool click "${3:-1}"; sleep "${CLICK_PAUSE:-1}"; }

# box_values: the box in microns, "llx lly urx ury".
box_values() { probe 'set cu [units list]; units microns noprint; set b [box values]; units {*}$cu; set b'; }

# box_um X1 Y1 X2 Y2: set the box with the mouse: left-click (X1,Y1), right-click (X2,Y2).
# Reads the box back and, if it isn't there, moves the pointer out of the drawing, waits
# 2 s and clicks again (twice at most), logging each retry. In about 150 box_um calls, two
# had both clicks ignored by Magic for no reason we could find; a retry after a pause
# worked. A box that is still wrong after that is usually a target the zoom can't reach
# (one pixel is more than one snap step: zoom in) and is only logged.
box_um() {
    local want got i
    want="$(awk -v a="$1" -v b="$2" -v c="$3" -v d="$4" 'BEGIN{printf "%g %g %g %g", a, b, c, d}')"
    click_um "$1" "$2" 1; click_um "$3" "$4" 3
    got="$(box_values)"
    for i in 1 2; do
        [ "$got" = "$want" ] && return 0
        log "box_um: box is $got, wanted $want; retry $i"
        focus_layout; sleep 2
        click_um "$1" "$2" 1; click_um "$3" "$4" 3
        got="$(box_values)"
    done
    [ "$got" = "$want" ] || log "box_um: box is still $got"
}

# drag_um BUTTON X1 Y1 X2 Y2: press BUTTON at (X1,Y1), move to (X2,Y2), release.
drag_um() {
    local a b; a="$(um_xy "$2" "$3")"; b="$(um_xy "$4" "$5")"
    # shellcheck disable=SC2086
    xdotool mousemove --sync $a mousedown "$1"; sleep 0.3
    # shellcheck disable=SC2086
    xdotool mousemove --sync $b; sleep 0.3
    xdotool mouseup "$1"; sleep "${CLICK_PAUSE:-1}"
}

# key KEY...: press keys (xdotool names: v, z, shift+z, ctrl+z, Return, Escape) in whatever
# has the focus. Magic's layout window takes keys while the pointer is over it.
key() { xdotool key --clearmodifiers "$@"; sleep "${KEY_PAUSE:-0.5}"; }

# type_text TEXT: type text into whatever has the focus.
type_text() { xdotool type --delay 40 -- "$1"; sleep 0.3; }

# console TEXT: type a command into the tkcon console and press Return. The first Return
# after typing into a freshly focused console was sometimes lost (the next command then got
# appended to the line: "extract allext2spice lvs"), so this checks that the command line is
# empty afterwards and presses Return again if it isn't.
console() {
    focus_console; type_text "$1"; sleep 0.3; key Return; sleep "${CONSOLE_PAUSE:-0.5}"
    local i
    for i in 1 2 3; do
        [ -z "$(probe '::rigprobe::console_input' 2>/dev/null)" ] && return 0
        log "console: Return not taken for '$1'; pressing it again"
        focus_console; key Return; sleep 1
    done
}

# palette LAYER [BUTTON]: click a layer's button in the layer palette (default middle =
# paint into the box). LAYER is the palette's name for it: ndiffusion, polysilicon, locali...
palette() {
    local xy; xy="$(probe "::rigprobe::palette $1")"
    [ -n "$xy" ] || { log "no palette button for $1"; return 1; }
    # shellcheck disable=SC2086
    click_xy $xy "${2:-2}"
}

# menu_open MENU: click a menu button on Magic's title bar (File, Edit, Cell, Window,
# Layers, Drc, Options, Devices 1, Devices 2), leaving the menu open.
menu_open() {
    local xy; xy="$(probe "::rigprobe::menubutton {$1}")"
    # shellcheck disable=SC2086
    click_xy $xy 1; sleep 0.3
}

# menu MENU ITEM: open a title-bar menu and click one of its items, by their labels.
menu() {
    menu_open "$1"
    local xy; xy="$(probe "::rigprobe::menuitem {$1} {$2}")"
    # shellcheck disable=SC2086
    click_xy $xy 1; sleep 0.5
}

# view_um: the part of the layout the window shows, in microns, "llx lly urx ury".
view_um() { probe 'set v [[lindex [magic::windownames layout] 0] view get]; set o {}; foreach c $v {lappend o [magic::i2u $c]}; set o'; }

# click_button TEXT [TOPLEVEL]: click a Tk button by its label (Okay, Apply, Create and
# Close, Update, Next...), in any of Magic's windows or only in TOPLEVEL (.params, .drcmgr).
click_button() { local xy; xy="$(probe "::rigprobe::button {$1} {${2:-}}")"; click_xy $xy 1; }

# click_tree TREE TEXT [double]: click (or double-click) the row of a manager's tree whose
# text starts with TEXT. TREE is the treeview: .cellmgr.box.view, .libmgr.box.view,
# .drcmgr.box.view.
click_tree() {
    local xy; xy=($(probe "::rigprobe::treeitem $1 {$2}"))
    if [ "${3:-}" = double ]; then
        xdotool mousemove --sync "${xy[@]}" click --repeat 2 --delay 120 1; sleep 1
    else
        click_xy "${xy[@]}" 1
    fi
}

# fill_entry LABEL TEXT [TOPLEVEL]: click the entry next to LABEL, select what is in it,
# and type TEXT over it (for the device dialog's "Width (um)", the text dialog's
# "Text string:" ...).
fill_entry() {
    local xy; xy="$(probe "::rigprobe::entry {$1} {${3:-.}}")"
    # shellcheck disable=SC2086
    # A triple click selects everything in a Tk entry; typing then replaces it. (Don't
    # use ctrl+a: in a Tk entry it moves to the start of the line and drops the selection.)
    xdotool mousemove --sync $xy click --repeat 3 --delay 80 1; sleep 0.3
    type_text "$2"
}

# terminal [TITLE]: open an xterm (the workbench desktop has terminals too) and make it the
# current window for type_text/key. TERM_WIN holds its id.
TERM_WIN=""
terminal() {
    local title="${1:-terminal}"
    xterm -T "$title" -geometry 120x30+0+0 -fa 'DejaVu Sans Mono' -fs 10 \
          -bg white -fg black -e bash --norc -i >/tmp/xterm.log 2>&1 &
    TERM_WIN="$(find_window "^$title\$" 20)"
    sleep 1
    xdotool windowactivate --sync "$TERM_WIN" 2>/dev/null || true
    xdotool mousemove --sync 300 200 click 1; sleep 0.3
}

# --- Reading the screen as text ---------------------------------------------------------------
# readout: what the title bar says now (caption, DRC button, box/cursor readout).
readout() { probe '::rigprobe::readout'; }

# console_tail [N]: the last N lines of the tkcon console (default 15).
console_tail() { probe "::rigprobe::console_tail ${1:-15}"; }

# --- Capturing ---------------------------------------------------------------------------------
grab() { import -window root "$1" 2>/dev/null; }

# settle: wait until two grabs 0.4 s apart are identical (at most 15 s).
settle() {
    local prev="" cur i
    for i in $(seq 1 38); do
        cur="$( (grab rgb:- || date +%N) | md5sum)"
        [ "$cur" = "$prev" ] && return 0
        prev="$cur"; sleep 0.4
    done
    log "screen still changing after 15 s; capturing anyway"
}

# region WHAT...: "X Y W H" covering the union of WHATs, each one of
#   screen | layout | console | tk:PATH (a Tk widget in Magic) | win:TITLE_REGEX |
#   menu:MENU (an open title-bar menu) | X,Y,W,H
region() {
    local x0=99999 y0=99999 x1=0 y1=0 r w
    for w in "$@"; do
        case "$w" in
            screen)   r="0 0 ${SCREEN%x*} ${SCREEN#*x}" ;;
            layout)   r="$(probe '::rigprobe::rect .layout1')" ;;
            console)  r="$(win_rect "$CONSOLE_WIN")" ;;
            tk:*)     r="$(probe "::rigprobe::rect ${w#tk:}")" ;;
            menu:*)   r="$(probe "::rigprobe::menurect {${w#menu:}}")" ;;
            win:*)    r="$(win_rect "$(find_window "${w#win:}" 5)")" ;;
            *,*,*,*)  r="${w//,/ }" ;;
            *) log "region: unknown '$w'"; return 1 ;;
        esac
        set -- $r
        [ "$1" -lt "$x0" ] && x0=$1
        [ "$2" -lt "$y0" ] && y0=$2
        [ $(($1 + $3)) -gt "$x1" ] && x1=$(($1 + $3))
        [ $(($2 + $4)) -gt "$y1" ] && y1=$(($2 + $4))
    done
    [ "$x0" -lt 0 ] && x0=0
    [ "$y0" -lt 0 ] && y0=0
    echo "$x0 $y0 $((x1 - x0)) $((y1 - y0))"
}

# capture NAME [WHAT...]: settle, then write /out/NAME.png cropped to the union of WHAT
# (default: the whole screen), and /out/NAME.txt with the title-bar readout and the end of
# the console. PNGs carry no timestamps, so the same screen gives the same file.
capture() {
    local name="$1"; shift
    [ $# -gt 0 ] || set -- screen
    pkill -x xmessage 2>/dev/null || true
    xsetroot -solid '#5a5a5a' 2>/dev/null || true
    settle
    local r; r=($(region "$@"))
    grab /tmp/capture.miff
    convert /tmp/capture.miff -crop "${r[2]}x${r[3]}+${r[0]}+${r[1]}" +repage -strip \
        -define png:exclude-chunks=date,time "png:$OUT/$name.png"
    {
        echo "# $name.png  (${r[2]}x${r[3]} at ${r[0]},${r[1]})"
        readout 2>/dev/null || true
        echo
        echo "# console, last lines:"
        console_tail 12 2>/dev/null || true
    } > "$OUT/$name.txt"
    log "wrote $name.png (${r[2]}x${r[3]})"
}

# --- The step files -----------------------------------------------------------------------------
for STEP_FILE in "$@"; do
    log "=== $STEP_FILE"
    # shellcheck source=/dev/null
    . "$STEP_FILE"
done
