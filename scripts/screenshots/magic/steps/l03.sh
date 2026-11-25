# Lab 03: draw an inverter, the way the writeup tells a student to.
#
# Shots for docs/labs/lab-03-draw-an-inverter-overview.md (copied in as
# ad104-l03-NN-slug.png), and the make output after every save (make-*.txt in the output
# folder), which the page quotes. Run from the repo root or a worktree:
#
#   RIG_DISPLAY=62 RIG_TIMEOUT=1800 scripts/screenshots/magic/shot.sh -o OUT \
#       scripts/screenshots/magic/steps/l03.sh
#
# The cell drawn here meets the page's spec tables but does not copy the reference's
# coordinates (tcl/inverter.tcl): its diffusions sit 0.05 um lower and its stripe 0.05 um
# further left, so its DRC counts and ad= values are a student's, not the reference's.
# Every shape is set with the mouse (box_um, click_um) and painted from the palette. The
# only typed Magic commands are `box size` for the contacts and the extraction; netgen and
# grep are typed in a terminal. Shots: l03-01 ... l03-10; x-* captures are evidence only.

LAB=labs/lab-03-draw-an-inverter
W=/tmp/work/$LAB
say() { echo "== $*" >&2; }
T0=$(date +%s)
stamp() { say "[t=$(( $(date +%s) - T0 ))s] $*"; }

# make in the lab folder, as the student runs it; it fails until Part 8, so ignore its status.
run_make() {
    local name="$1"; shift
    ( cd "$W" && make "$@" ) > "$OUT/make-$name.txt" 2>&1 || true
    say "make $* ($name):"; cat "$OUT/make-$name.txt" >&2
}
# A rough box with two clicks (no read-back), then ctrl+z: zoom on an area.
rough_box() { click_um "$1" "$2" 1; click_um "$3" "$4" 3; }
zoom_to() { hover_center; key v; rough_box "$@"; hover_center; key ctrl+z; }
# File > Save..., then write in the dialog.
save_cell() {
    menu File 'Save...'; pause 1
    click_button write; pause 1
    say "saved: $(console_tail 2 | tr '\n' '|')"
}
show_b() { hover_center; key b; say "b: $(console_tail 6 | grep microns || true)"; }
drc_count() { say "DRC button: $(readout | sed -n 2p)"; }
# The xterm the student types netgen, grep and cat into, moved below Magic's title bar.
# Raise it first: once Magic's windows have been clicked they cover it, and a click at its
# centre would land in the layout window, where the typed letters run as Magic's keys. Stop
# if the xterm still doesn't have the focus.
term_type() {
    xdotool windowraise "$TERM_WIN" 2>/dev/null || true
    xdotool windowactivate --sync "$TERM_WIN" 2>/dev/null || true
    local r; r=($(win_rect "$TERM_WIN"))
    xdotool mousemove --sync $((r[0] + r[2] / 2)) $((r[1] + r[3] / 2)) click 1; sleep 0.3
    [ "$(xdotool getactivewindow 2>/dev/null)" = "$TERM_WIN" ] || {
        log "term_type: the terminal does not have the focus; not typing '$1'"; return 1; }
    type_text "$1"; key Return
}
# capture_term NAME ROWS: the top ROWS text rows of the terminal (17 px a row).
capture_term() {
    local r; r=($(win_rect "$TERM_WIN"))
    capture "$1" "${r[0]},${r[1]},${3:-760},$(( $2 * 17 + 6 ))"
}
# Move the text dialog so that all of it is on the screen (it widens when the layer field
# appears, and opens at the right edge of the layout window).
fit_texthelper() {
    local w r; w="$(find_window '^texthelper$' 5)"; r=($(win_rect "$w"))
    xdotool windowmove --sync "$w" $(( ${SCREEN%x*} - r[2] - 6 )) 23 2>/dev/null || true
    sleep 0.5
}
NETGEN_LVS='netgen -batch lvs "my_inv.spice my_inv" "../spice/my_inv_sch.spice my_inv" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'

work $LAB

# ---- Part 2: start from the frame ------------------------------------------------------
stamp "Part 2"
run_make scaffold scaffold
run_make p2
magic_open $LAB/mag my_inv
say "view at open: $(view_um)"
menu Window 'Set grid 0.05um'
hover_center
say "after Set grid: $(readout | tail -1)"
capture l03-01-grid layout
# Read the frame: the pointer on the n-well's bottom edge, then a box on the p-tap and b.
hover_um 1.50 3.00; pause 0.5
say "pointer on the n-well edge: $(readout | sed -n 3p)"
capture x-frame-readout layout
zoom_to 0.10 0.10 2.90 1.10
box_um 0.40 0.35 2.60 0.85
show_b
capture x-ptap-b layout console

# ---- Part 3: the two diffusions -----------------------------------------------------------
stamp "Part 3"
zoom_to 0.20 1.00 2.80 2.20
box_um 0.40 1.25 2.60 1.90
say "box readout: $(readout | sed -n 3p)"
capture l03-02-box-readout layout
show_b
capture x-box-b layout console
palette ndiffusion 2
pause 1
capture l03-03-ndiff-painted layout
zoom_to 0.20 3.20 2.80 4.70
box_um 0.40 3.45 2.60 4.45
show_b
palette pdiffusion 2
pause 1
hover_center; key v
capture x-pdiff-painted layout
save_cell
run_make p3

# ---- Part 4: the gate ----------------------------------------------------------------------
stamp "Part 4"
zoom_to 0.90 0.90 1.90 4.90
box_um 1.30 1.05 1.45 4.70
show_b
palette polysilicon 2
pause 1
hover_center; key v
capture l03-04-poly layout
menu Drc 'DRC update'
pause 2
drc_count
say "console after DRC update: $(console_tail 3 | tr '\n' '|')"
save_cell
run_make p4

# ---- Part 5: the contacts ------------------------------------------------------------------
stamp "Part 5"
zoom_to 0.30 1.20 2.70 4.30
# NMOS source: click the corner, type the size, title bar, check with b, paint.
click_um 0.55 1.45 1
console 'box size 0.17um 0.17um'
focus_layout
show_b
capture l03-05-contact-b layout console
palette ndcontact 2
# The next ones: a left click moves the box and keeps its size.
click_um 2.25 1.45 1; show_b; palette ndcontact 2
click_um 0.55 3.85 1; show_b; palette pdcontact 2
click_um 2.25 3.85 1; show_b; palette pdcontact 2
# The gate's landing pad (click recipe), then its contact (typed size again: the box is
# the pad's size now).
box_um 1.15 2.25 1.60 2.70
show_b
palette polysilicon 2
click_um 1.29 2.39 1
show_b
console 'box size 0.17um 0.17um'
focus_layout
show_b
palette pcontact 2
pause 1
hover_center; key v
capture x-contacts-painted layout
menu Drc 'DRC update'
pause 2
drc_count
hover_center; key equal
pause 1
menu Drc 'DRC report'
pause 1
say "after = and DRC report: $(console_tail 8 | tr '\n' '|')"
capture l03-06-li5-report layout console
save_cell
run_make p5

# ---- Part 6: wire it in li -------------------------------------------------------------------
stamp "Part 6"
hover_center; key v
zoom_to 0.10 -0.10 2.90 2.90
box_um 0.45 0.05 0.82 1.72; palette locali 2      # VGND: the tap's li down over the NMOS source
box_um 1.19 2.29 1.56 2.66; palette locali 2      # A: a patch over the gate contact
zoom_to 0.10 1.20 2.90 4.30
box_um 2.15 1.35 2.52 4.12; palette locali 2      # Y: NMOS drain to PMOS drain
zoom_to 0.10 3.10 2.90 6.10
box_um 0.45 3.75 0.82 5.95; palette locali 2      # VPWR: PMOS source up to the tap's li
hover_center; key v
menu Drc 'DRC update'
pause 2
drc_count
capture l03-07-li-wired layout
menu Drc 'DRC Complete'
menu Drc 'DRC update'
pause 3
drc_count
say "after DRC Complete: $(console_tail 3 | tr '\n' '|')"
capture x-drc-complete layout
menu Drc 'DRC Fast'
save_cell
run_make p6

# ---- Part 7: name the pins ---------------------------------------------------------------------
stamp "Part 7"
zoom_to 0.10 1.20 2.90 4.30
# A: a box over the patch that also covers part of the gate contact, as a student would
# draw it; the layer field below makes that safe.
box_um 1.25 2.35 1.50 2.60
hover_center; key comma
menu Edit 'Text ...'; pause 1.5
fill_entry 'Text string:' A .texthelper
fill_entry 'Size (um):' 0.1 .texthelper
say "Attach default at open: $(probe 'set ::typedflt')"
[ "$(probe 'set ::typedflt')" = 0 ] || click_button default .texthelper
pause 0.5
fill_entry 'Attach to layer:' locali .texthelper
say "Attach default now: $(probe 'set ::typedflt'), layer field: $(probe '.texthelper.layer.tent get')"
say "Port enable at open: $(probe 'set ::typeport')"
[ "$(probe 'set ::typeport')" = 1 ] || click_button enable .texthelper
pause 0.5
say "Port enable now: $(probe 'set ::typeport'), port number: $(probe '.texthelper.port.tent get')"
fit_texthelper
capture l03-08-text-dialog layout tk:.texthelper
click_button Okay .texthelper; pause 1
say "after A: $(console_tail 3 | tr '\n' '|')"
box_um 2.20 2.60 2.45 2.85
hover_center; key comma
menu Edit 'Text ...'; pause 1.5
say "second open: default $(probe 'set ::typedflt'), layer field '$(probe '.texthelper.layer.tent get')', port $(probe 'set ::typeport') number $(probe '.texthelper.port.tent get'), size $(probe '.texthelper.size.tent get')"
fit_texthelper
capture x-text-dialog-second tk:.texthelper
fill_entry 'Text string:' Y .texthelper
[ "$(probe 'set ::typeport')" = 1 ] || click_button enable .texthelper
click_button Okay .texthelper; pause 1
say "after Y: $(console_tail 3 | tr '\n' '|')"
hover_center; key v
capture x-labels layout console
save_cell
run_make p7

# ---- Part 8: extract, netgen, the hvt fix ---------------------------------------------------------
stamp "Part 8"
console 'extract all'
pause 1
console 'ext2spice lvs'
console 'ext2spice'
pause 1
capture l03-09-extract-console console
say "my_inv.spice:"; cat $W/mag/my_inv.spice >&2
terminal lvs-terminal
xdotool windowmove --sync "$TERM_WIN" 360 300 2>/dev/null || true
sleep 0.5
term_type "cd $W/mag"
term_type "$NETGEN_LVS"
pause 8
capture x-netgen-run win:'^lvs-terminal$'
term_type clear
term_type 'grep -A 8 "Subcircuit summary" comp.out'
pause 1
capture_term l03-10-netgen-hvt 11
term_type clear
term_type 'tail -25 comp.out'
pause 1
capture x-netgen-tail win:'^lvs-terminal$'
cp $W/mag/comp.out "$OUT/comp-before.out"
# Paint pfethvt on the PMOS channel: the click recipe on the corners where the stripe
# crosses the p-diffusion, then the palette's pfethvt swatch.
focus_layout
zoom_to 1.00 3.30 1.80 4.60
box_um 1.30 3.45 1.45 4.45
show_b
palette pfethvt 2
pause 1
say "after pfethvt: $(console_tail 3 | tr '\n' '|')"
capture x-pfethvt layout console
menu Drc 'DRC update'
pause 2
drc_count
console 'extract all'
pause 1
console 'ext2spice lvs'
console 'ext2spice'
pause 1
say "my_inv.spice after pfethvt:"; cat $W/mag/my_inv.spice >&2
term_type clear
term_type "$NETGEN_LVS"
pause 8
capture x-netgen-match win:'^lvs-terminal$'
term_type clear
term_type 'tail -4 comp.out'
pause 1
capture_term x-netgen-match-tail 6
cp $W/mag/comp.out "$OUT/comp-after.out"
focus_layout
save_cell
run_make p8

# ---- Part 9: read what you drew -------------------------------------------------------------------
stamp "Part 9"
term_type 'cd ..'
term_type clear
term_type 'cat mag/my_inv.spice'
pause 1
capture_term x-cat-spice 8 900
focus_layout
zoom_to 1.00 1.10 1.80 2.00
box_um 1.30 1.25 1.45 1.90
show_b
capture x-channel-b layout console
say "ndiff section:"; sed -n '/<< ndiff >>/,/<</p' $W/mag/my_inv.mag >&2
say "magscale line: $(grep -c magscale $W/mag/my_inv.mag || true)"
keep $LAB/mag/my_inv.mag $LAB/mag/my_inv.spice $LAB/mag/comp.out
stamp "done drawing"
magic_quit
run_make refcheck refcheck
stamp "end"
