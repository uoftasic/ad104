# Lab 02 (AD104-M): the Magic screenshots on docs/labs/lab-02-break-it-on-purpose-overview.md,
# taken while doing the whole lab through the GUI, in the page's order. Run from the repo root:
#
#   RIG_DISPLAY=61 scripts/screenshots/magic/shot.sh -o OUT scripts/screenshots/magic/steps/l02.sh
#
# Shots whose name starts with l02- go on the page; ev-l02-* and the l02-make-*.txt files are
# evidence for its "You should see" lines and stay in OUT. Coordinates are microns on the
# shipped cells. The page gives none of them: the fixes below are one student's choices,
# made from the rule values, and the hints on the page only give sizes.

L02=labs/lab-02-break-it-on-purpose
M=/tmp/work/$L02
work $L02

# make, run in the package folder from the terminal. Its output goes to OUT/NAME.txt.
lab_make() { (cd "$M" && make) > "$OUT/$1.txt" 2>&1 || true; log "$1: $(grep -E '^(PASS|FAIL)' "$OUT/$1.txt" || true)"; }

# Open a cell the way the page does it in Part 4: File -> Open..., the name, Return, then
# `v` and a left click in the drawing. Until that click the box still belongs to the cell
# that was open before, and DRC update does nothing.
open_cell() {
    hover_center
    menu File 'Open...'; pause 1.5
    type_text "$1.mag"
    [ -z "${2:-}" ] || capture "$2" win:'^Open$'
    key Return; pause 2
    hover_center; key v; pause 0.5
    xdotool click 1; pause 1
}

# Save with File -> Save..., then `write` in the dialog.
save_write() { hover_center; menu File 'Save...'; pause 1; click_button write; pause 1; }

# --- Part 1: the checker on the cells as shipped ------------------------------------------------
lab_make l02-make-shipped

# --- Part 2: read one violation in Magic ----------------------------------------------------------
magic_open $L02/mag drc_03
# Magic sometimes keeps the view it computed before the rig resized its window, with the
# cell small in a corner; `v` fits it, as the page has the student do.
hover_center; key v
capture l02-01-open-clean layout
menu Drc 'DRC update'; pause 2
capture l02-02-drc-update-14 layout console
hover_center; key equal; pause 2
capture l02-03-equal-key layout console
# The box over the whole pad, then DRC report.
box_um 1.25 2.35 1.60 2.70
menu Drc 'DRC report'; pause 1
capture l02-04-drc-report layout console
menu Options 'DRC Manager'; pause 2
move_window '^drcmgr$' 1000 23
click_tree .drcmgr.box.view '268 520 280 522'
capture l02-05-drc-manager tk:.drcmgr
click_button Zoom .drcmgr; pause 2
capture ev-l02-drc-manager-zoom layout tk:.drcmgr
move_window '^drcmgr$' 1210 23
hover_center; key comma

# --- Part 3: measure, then fix drc_03 (click recipe) --------------------------------------------
hover_center; key v
box_um 1.10 2.20 1.80 2.90
hover_center; key ctrl+z
box_um 1.30 2.40 1.55 2.65
hover_center; key b
capture l02-06-measure-pad layout console
box_um 1.34 2.44 1.51 2.61
hover_center; key b
capture ev-l02-contact-b console
# A pad 0.33 wide and 0.27 tall round the 0.17 cut: 0.08 both sides in x, 0.05 in y.
box_um 1.26 2.39 1.59 2.66
palette polysilicon 2
menu Drc 'DRC update'; pause 2
# The pointer over the drawing, so the title bar shows the pointer rather than the new pad's
# corners (the page keeps the pad's size in a collapsed hint).
hover_center
capture l02-07-pad-painted layout
menu Drc 'DRC Complete'
menu Drc 'DRC update'; pause 2
capture ev-l02-drc03-full layout
menu Drc 'DRC Fast'
hover_center; menu File 'Save...'; pause 1
capture l02-08-save-dialog win:'^Dialog$'
click_button write; pause 1
lab_make l02-make-after-drc03

# --- Part 4: drc_01, drc_02 and drc_04 -----------------------------------------------------------
# drc_01 (diff/tap.8): more n-well under the PMOS diffusion.
open_cell drc_01 l02-09-open-dialog
menu Drc 'DRC update'; pause 2
capture ev-l02-drc01-update layout console
hover_center; key equal; pause 2
menu Drc 'DRC report'; pause 1
capture ev-l02-drc01-report console
hover_center; key v
box_um 0.00 3.30 3.00 3.40
palette nwell 2
menu Drc 'DRC update'; pause 2
capture ev-l02-drc01-fixed layout
save_write

# drc_02 (li.5): a wider li patch over the poly contact.
open_cell drc_02
menu Drc 'DRC update'; pause 2
hover_center; key equal; pause 2
menu Drc 'DRC report'; pause 1
capture ev-l02-drc02-report layout console
hover_center; key v
box_um 1.26 2.44 1.59 2.61
palette locali 2
menu Drc 'DRC update'; pause 2
capture ev-l02-drc02-fixed layout
save_write

# drc_04 (li.3): erase the part of the A pad that reaches toward the Y wire.
open_cell drc_04
menu Drc 'DRC update'; pause 2
hover_center; key equal; pause 2
menu Drc 'DRC report'; pause 1
capture ev-l02-drc04-report layout console
hover_center; key v
box_um 1.00 1.90 2.60 3.00
hover_center; key ctrl+z
box_um 1.70 2.34 2.08 2.71
xy="$(probe '::rigprobe::palette locali')"
# shellcheck disable=SC2086
xdotool mousemove --sync $xy; pause 0.3
xdotool keydown shift click 2 keyup shift; pause 1
hover_center
capture l02-10-erase-shift-middle layout
menu Drc 'DRC update'; pause 2
capture ev-l02-drc04-fixed layout
save_write
lab_make l02-make-after-part4

# --- Part 5: drc_05, the full rule set and your own LVS --------------------------------------------
open_cell drc_05
menu Drc 'DRC update'; pause 2
capture ev-l02-drc05-fast layout console
menu Drc 'DRC Complete'
menu Drc 'DRC update'; pause 3
hover_center; key equal; pause 2
hover_center; key v
menu Drc 'DRC report'; pause 1
capture l02-11-drc-complete-1 layout console
console 'extract all'; pause 2
console 'ext2spice lvs'
console 'ext2spice'; pause 2
capture ev-l02-drc05-extract console
keep $L02/mag/drc_05.spice
cp "$M/mag/drc_05.spice" "$OUT/ev-l02-drc05-before.spice"
terminal lvs-terminal
type_text "cd $M/mag && clear"; key Return; pause 1
type_text 'netgen -batch lvs "drc_05.spice drc_05" "../spice/inv_sch.spice my_inv" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'
key Return; pause 10
capture l02-12-netgen-mismatch win:'^lvs-terminal$'
cp "$M/mag/comp.out" "$OUT/ev-l02-drc05-comp-before.out"
pkill -x xterm || true
# The fix: a 0.17 x 0.17 nsubstratencontact on the n-tap, under the li. Typed size.
focus_layout
hover_center; key v
click_um 0.30 4.90 1; click_um 1.10 5.70 3
hover_center; key ctrl+z
click_um 0.55 5.22 1
console 'box size 0.17um 0.17um'
focus_layout
hover_center; key b
capture l02-13-box-size layout console
palette nsubstratencontact 2
menu Drc 'DRC update'; pause 3
capture ev-l02-drc05-fixed layout console
console 'extract all'; pause 2
console 'ext2spice lvs'
console 'ext2spice'; pause 2
cp "$M/mag/drc_05.spice" "$OUT/ev-l02-drc05-after.spice"
terminal lvs-terminal
type_text "cd $M/mag && clear"; key Return; pause 1
type_text 'netgen -batch lvs "drc_05.spice drc_05" "../spice/inv_sch.spice my_inv" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'
key Return; pause 10
capture ev-l02-netgen-match win:'^lvs-terminal$'
cp "$M/mag/comp.out" "$OUT/ev-l02-drc05-comp-after.out"
pkill -x xterm || true
focus_layout
menu Drc 'DRC Fast'
save_write
lab_make l02-make-after-part5
keep $L02/mag/drc_01.mag $L02/mag/drc_02.mag $L02/mag/drc_03.mag $L02/mag/drc_04.mag $L02/mag/drc_05.mag

# --- Part 6: erase instead of fix, on drc_04 -------------------------------------------------------
open_cell drc_04
box_um 1.24 2.34 1.70 2.71
xy="$(probe '::rigprobe::palette locali')"
# shellcheck disable=SC2086
xdotool mousemove --sync $xy; pause 0.3
xdotool keydown shift click 2 keyup shift; pause 1
menu Drc 'DRC update'; pause 2
capture ev-l02-drc04-erased layout console
save_write
lab_make l02-make-erased
hover_center; key u; pause 1
capture l02-14-undo layout
save_write
lab_make l02-make-final
magic_quit
