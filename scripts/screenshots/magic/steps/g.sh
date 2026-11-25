# Guide and reference pages: the screenshots on docs/guide/*.md (copied in as
# ad104-g-<slug>.png), and the facts those pages quote that no lab page records.
#
#   RIG_DISPLAY=65 RIG_TIMEOUT=1500 scripts/screenshots/magic/shot.sh -o OUT \
#       scripts/screenshots/magic/steps/g.sh
#
# Shots (SCREEN=1600x1000, the rig's default):
#   g-magic-window   getting-started: both windows, Lab 04's hand-drawn inverter open
#   g-palette        drawing-in-magic: the palette scrolled down, the pointer on locali,
#                    its name in the title bar
#   g-text-dialog    drawing-in-magic: Edit > Text ... filled in (A, size 0.1, Port on)
#   g-drc-report     drc-is-a-conversation: drc_03 after DRC update, = and DRC report
# Evidence only (x-*.png and the log): where extraction writes its .ext files for a cell
# in the PDK's folder and for one in another writable folder, with and without
# `extract do local`; the caption for a cell opened from the PDK, and the Open window
# starting in the PDK's folder afterwards; a label made with the Text dialog over a
# subcell's shape, and the .subckt line it gives; two cells placed with Cell > Place
# Instance and saved; the capstone row under DRC Fast and DRC Complete; the ! key and a
# left click on a hidden swatch; the palette's rows; and Magic started with
# PDK=ihp-sg13g2 on a course cell, on a new cell, and in Lab 01's folder.
#
# fluxbox's "what." xmessage can pop up during a capture (scripts/screenshots/magic/
# README.md); look at each g-*.png before copying it in.
#
# Coordinates below are the shipped cells' (the rig may use them; the pages may not).

INV1=/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__inv_1.mag
L01=labs/lab-01-open-the-cell
L02=labs/lab-02-break-it-on-purpose
L04=labs/lab-04-buffer-and-and
CAP=labs/capstone-place-and-route
say() { echo "== $*" >&2; }
T0=$(date +%s)
stamp() { say "[t=$(( $(date +%s) - T0 ))s] $*"; }
show_readout() { say "readout: $(readout | tr '\n' '|')"; }
show_console() { say "console (last $1):"; console_tail "$1" >&2 || true; }
show_dir() { say "ls $1:"; ls -la "$1" >&2 || true; }
# Move the text dialog fully onto the screen (it opens at the layout window's right edge
# and widens when its layer field appears).
fit_texthelper() {
    local w r; w="$(find_window '^texthelper$' 5)"; r=($(win_rect "$w"))
    xdotool windowmove --sync "$w" $(( ${SCREEN%x*} - r[2] - 6 )) 23 2>/dev/null || true
    sleep 0.5
}

work $L01
work $L02
work $L04
work $CAP

# ---- Facts about the image that the pages state -------------------------------------------
stamp "image facts"
say "HOME=$HOME"
for f in "$HOME/.magicrc" /headless/.magicrc; do
    [ -f "$f" ] && { say "cat $f:"; cat "$f" >&2; }
done
say "PDK folder of inv_1:"; ls -ld "$(dirname "$INV1")" "$INV1" >&2 || true
[ -w "$(dirname "$INV1")" ] && say "PDK mag folder is writable" || say "PDK mag folder is not writable"
say "key bindings for ! ? f = y in the image's Magic setup files:"
grep -rnE "macro +(exclam|!|question|\?|f|equal|=|y)( |$)" \
    /foss/tools/magic/lib/magic/sys /foss/pdks/sky130A/libs.tech/magic 2>/dev/null >&2 || true

# ---- getting-started: the Magic window -------------------------------------------------------
stamp "g-magic-window"
magic_open $L04/mag my_inv
show_readout
show_console 12
capture g-magic-window layout console

# ---- drawing-in-magic: the palette ------------------------------------------------------------
stamp "g-palette"
xy="$(probe '::rigprobe::palette locali')"
# shellcheck disable=SC2086
xdotool mousemove --sync $xy; sleep 1
show_readout
capture g-palette "tk:[::rigprobe::frame].titlebar.message" "tk:[::rigprobe::frame].toolbar"
# Every row of the palette, top to bottom, by the name the palette shows (the layer map's
# Palette column comes from this list).
say "palette rows: $(probe 'set o {}; foreach c [winfo children [::rigprobe::frame].toolbar.canvas.frame] {lappend o [string range [winfo name $c] 1 end]}; set o' || true)"

# ---- drawing-in-magic: the Text dialog --------------------------------------------------------
stamp "g-text-dialog"
hover_center
box_um 1.30 2.40 1.55 2.65
menu Edit 'Text ...'
fill_entry 'Text string:' A .texthelper
fill_entry 'Size (um):' 0.1 .texthelper
click_button enable .texthelper
fit_texthelper
capture g-text-dialog tk:.texthelper
click_button Cancel .texthelper
pause 1

# getting-started: a cell opened from the PDK's folder, then your own cell again.
stamp "NOT BEING EDITED"
hover_center
menu File 'Open...'
type_text "$INV1"; key Return; pause 2
show_readout
show_console 4
capture x-open-inv1 layout
# Back to my_inv by name: does the Open window remember the last folder it showed?
hover_center
menu File 'Open...'; pause 1
capture x-open-dialog-again win:'^Open$'
type_text my_inv.mag; key Return; pause 2
say "windows after typing my_inv.mag:"; windows >&2 || true
capture x-open-my-inv-by-name screen
show_readout
magic_quit

# ---- drc-is-a-conversation: DRC report on drc_03 --------------------------------------------------
stamp "g-drc-report"
magic_open $L02/mag drc_03
show_readout
menu Drc 'DRC update'; pause 2
show_readout
hover_center
key equal; pause 1
show_readout
menu Drc 'DRC report'; pause 1
show_readout
show_console 10
capture g-drc-report layout console
magic_quit

# ---- extraction page: where extraction writes for a cell in the PDK's folder ---------------
stamp "extraction of inv_1"
magic_open $L01 "$INV1"
show_readout
console 'extract all'; pause 2
show_console 6
show_dir /tmp/work/$L01
ls "$(dirname "$INV1")"/*.ext 2>/dev/null >&2 && say "an .ext file is in the PDK folder" || say "no .ext in the PDK folder"
console 'ext2spice lvs'
console 'ext2spice'; pause 1
show_console 6
show_dir /tmp/work/$L01
rm -f /tmp/work/$L01/*.ext /tmp/work/$L01/*.spice
# The same cell from a folder Magic may write to, which is not the one it started in.
mkdir -p /tmp/work/elsewhere
cp "$INV1" /tmp/work/elsewhere/inv_copy.mag
hover_center
menu File 'Open...'
type_text /tmp/work/elsewhere/inv_copy.mag; key Return; pause 2
show_readout
console 'extract all'; pause 2
show_console 6
show_dir /tmp/work/elsewhere
show_dir /tmp/work/$L01
rm -f /tmp/work/elsewhere/*.ext /tmp/work/$L01/*.ext
console 'extract do local'
console 'extract all'; pause 2
show_console 8
show_dir /tmp/work/elsewhere
show_dir /tmp/work/$L01
magic_quit

# ---- cells-are-lego: a label over a subcell's shape, made with the Text dialog -------------
stamp "label over a subcell"
magic_open $L04/mag my_buf
box_um 1.30 2.40 1.55 2.65
menu Edit 'Text ...'
fill_entry 'Text string:' A .texthelper
fill_entry 'Size (um):' 0.1 .texthelper
click_button enable .texthelper
click_button Okay .texthelper; pause 1
show_console 6
say "label under the box: $(probe 'select area labels; set r [what -list]; select clear; set r' || true)"
capture x-label-to-space layout console
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice'; pause 1
say "my_buf.spice after a Text-dialog label A over inv1's pin:"
grep -n 'subckt my_buf' -A3 /tmp/work/$L04/mag/my_buf.spice >&2 || true
magic_quit

# ---- cells-are-lego: Cell > Place Instance, then the saved file ----------------------------------
stamp "Place Instance"
magic_open $L04/mag place_demo
show_console 6
hover_center
menu Cell 'Place Instance'
type_text my_inv.mag; key Return; pause 2
show_console 6
hover_center; key v; pause 1
click_um 2 -0.5 1; click_um 4 0.5 3
hover_center; key ctrl+z; pause 1
click_um 3 0 1
say "box before the second instance: $(box_values)"
hover_center
menu Cell 'Place Instance'
type_text my_inv.mag; key Return; pause 2
show_console 6
hover_center; key v; pause 1
capture x-place-instance layout
menu File 'Save...'; pause 1
click_button write; pause 1
show_console 4
say "place_demo.mag:"; cat /tmp/work/$L04/mag/place_demo.mag >&2 || true
magic_quit

# ---- the rule-set page and routing-by-hand: the capstone row ------------------------------------
stamp "capstone row"
magic_open $CAP/mag datapath
show_console 6
hover_center; key v; pause 1
box_um -0.50 -0.50 14.00 3.00
hover_center; key x; pause 2
capture x-cap-expanded layout
menu Drc 'DRC update'; pause 3
show_readout
menu Drc 'DRC Complete'; pause 1
menu Drc 'DRC update'; pause 5
show_readout
capture x-cap-drc-complete layout
menu Drc 'DRC Fast'; pause 1
menu Drc 'DRC update'; pause 3
show_readout
hover_center; key exclam; pause 2
show_console 4
capture x-cap-bang layout
# Getting the other layers back: a left click on a hidden layer's swatch shows it again.
palette locali 1; pause 1
hover_center
capture x-cap-bang-locali-shown layout
magic_quit

# ---- getting-started: Magic started with the image's default PDK -------------------------------
# Last, because Magic may not come up as the rig expects; nothing after this matters.
stamp "PDK=ihp-sg13g2 in a mag/ folder"
export PDK=ihp-sg13g2
if magic_open $L04/mag my_inv; then
    say "tech name: $(probe 'tech name' || true)"
    show_readout
    show_console 30
    capture x-ihp-mag layout console
    magic_quit
else
    say "Magic did not come up with PDK=ihp-sg13g2 in mag/"; tail -40 /tmp/magic.log >&2 || true
    magic_quit
fi
stamp "PDK=ihp-sg13g2, a new cell in a mag/ folder"
if magic_open $L04/mag ihp_new_cell; then
    say "tech name: $(probe 'tech name' || true)"
    show_readout
    show_console 12
    capture x-ihp-newcell layout console
fi
magic_quit
stamp "PDK=ihp-sg13g2 in Lab 01's folder (it has a .magicrc)"
# The folder's .magicrc stops at its error, so the probe it sources at its end never
# loads: no magic_open here, only the screen after a wait.
( cd /tmp/work/$L01 && exec magic -d X11 "$INV1" ) >/tmp/magic-ihp.log 2>&1 &
IHP_PID=$!
sleep 15
lw="$(find_window '^layout1$' 20 || true)"
cw="$(find_window '^tkcon' 20 || true)"
if [ -n "$lw" ] && [ -n "$cw" ]; then
    xdotool windowmove --sync "$lw" 0 22 2>/dev/null || true; sleep 1
    capture x-ihp-lab01-layout win:'^layout1$'
    xdotool windowmove --sync "$lw" 1500 900 2>/dev/null || true
    xdotool windowmove --sync "$cw" 0 0 2>/dev/null || true
    xdotool windowsize --sync "$cw" 1600 1000 2>/dev/null || true
    xdotool windowraise "$cw" 2>/dev/null || true; sleep 1
    capture x-ihp-lab01-console screen
fi
kill "$IHP_PID" 2>/dev/null || true; sleep 1
export PDK=sky130A
stamp "done"
