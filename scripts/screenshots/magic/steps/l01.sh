# Lab 01 (AD104-M): the Magic screenshots on docs/labs/lab-01-open-the-cell-overview.md,
# taken in the order the page does the steps. Run from the repo root:
#
#   RIG_DISPLAY=61 scripts/screenshots/magic/shot.sh -o OUT scripts/screenshots/magic/steps/l01.sh
#
# Shots whose name starts with l01- go on the page; ev-l01-* are evidence for the page's
# "You should see" lines (their .txt files hold the console text) and stay in OUT.
# Coordinates are microns on sky130_fd_sc_hd__inv_1. The page gives none of them: it names
# the shape and the student clicks its corners.

INV1=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__inv_1.mag
L01=labs/lab-01-open-the-cell
work $L01

# --- Part 2: open the cell and find your way round Magic -------------------------------------
magic_open $L01 "$INV1"
# Magic sometimes keeps the view it computed before the rig resized its window, with the
# cell small in a corner; `v` fits it, as the page's Part 2 has the student do.
hover_center; key v
capture l01-01-two-windows screen

# The layer's name shows in the title bar while the pointer is over its palette row.
xy="$(probe '::rigprobe::palette ndiffusion')"
# shellcheck disable=SC2086
xdotool mousemove --sync $xy; pause 1
capture l01-02-palette-hover layout

# --- Part 3: find the parts ------------------------------------------------------------------
# The box over the NMOS channel only (where the poly crosses the n-diffusion), then `/`.
hover_center; key v
box_um 0.62 0.30 0.71 0.80
hover_center; key slash
capture l01-03-what-under-box layout console

# Click recipe on the VGND rail: rough box, ctrl+z, then the rail's corners, then b.
hover_center; key v
box_um -0.30 -0.40 1.70 0.40
hover_center; key ctrl+z
box_um 0.00 -0.24 1.38 0.24
hover_center; key b
capture l01-04-rail-b layout console

# The VPWR rail, for the page's numbers only.
hover_center; key v
box_um -0.30 2.30 1.70 3.10
hover_center; key ctrl+z
box_um 0.00 2.48 1.38 2.96
hover_center; key b
capture ev-l01-vpwr-b console

# --- Part 4: measure the transistors -----------------------------------------------------------
# NMOS channel. Its y edges (0.235, 0.885) sit between two 0.01 um snap points; a click just
# inside each corner lands on 0.24 and 0.88. The x edges (0.60, 0.75) are on the snap grid.
hover_center; key v
box_um 0.40 0.10 0.95 1.00
hover_center; key ctrl+z
box_um 0.60 0.24 0.75 0.88
hover_center; key b
capture ev-l01-nmos-b layout console
box_um 0.60 0.23 0.75 0.88
hover_center; key b
capture ev-l01-nmos-b-mixed console
# PMOS channel: y edges 1.485 and 2.485.
hover_center; key v
box_um 0.40 1.30 0.95 2.70
hover_center; key ctrl+z
box_um 0.60 1.49 0.75 2.48
hover_center; key b
capture ev-l01-pmos-b layout console

# --- Part 5: DRC in Magic, under two rule sets -------------------------------------------------
# A left click in the empty area right of the cell moves the box there (it keeps its size),
# so the box is on nothing when DRC update runs its report.
hover_center; key v
click_um 2.60 0.20 1
menu Drc 'DRC update'; pause 2
capture ev-l01-drc-fast layout console
menu Drc 'DRC Complete'
menu Drc 'DRC update'; pause 3
capture l01-05-drc-complete-3 layout console
# The box over the whole cell, then DRC report.
box_um -0.20 -0.30 1.60 3.00
menu Drc 'DRC report'; pause 1
capture ev-l01-drc-report layout console
# The DRC Manager opens at the layout window's right edge in this rig; move it on screen.
menu Options 'DRC Manager'; pause 2
move_window '^drcmgr$' 1000 23
capture l01-06-drc-manager layout tk:.drcmgr
probe '::rigprobe::treerows .drcmgr.box.view' > "$OUT/ev-l01-drc-manager-rows.txt"
rows="$(cat "$OUT/ev-l01-drc-manager-rows.txt")"
row="$(printf '%s\n' "$rows" | awk '/^  / && !d {sub(/^  +/, ""); sub(/ +$/, ""); print; d = 1}')"
log "first error row: $row"
click_tree .drcmgr.box.view "$row"
click_button Zoom .drcmgr; pause 2
capture ev-l01-drc-manager-zoom layout tk:.drcmgr
# Out of the layout window's crop for the rest of the run.
move_window '^drcmgr$' 1210 23
hover_center; key comma
menu Drc 'DRC Fast'
menu Drc 'DRC update'; pause 2
capture ev-l01-drc-fast-again layout console

# --- Part 6: extract the cell ------------------------------------------------------------------
console 'extract all'; pause 2
console 'ext2spice lvs'
console 'ext2spice -o inv_1.spice'; pause 2
capture l01-07-extract-console console
keep $L01/inv_1.spice $L01/sky130_fd_sc_hd__inv_1.ext
focus_layout

# --- Part 7: LVS with netgen, in a terminal ------------------------------------------------------
terminal lvs-terminal
type_text "cd /tmp/work/$L01 && clear"; key Return; pause 1
type_text 'netgen -batch lvs "inv_1.spice sky130_fd_sc_hd__inv_1" "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice sky130_fd_sc_hd__inv_1" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'
key Return; pause 10
type_text 'tail -3 comp.out'; key Return; pause 1
capture l01-08-netgen-terminal win:'^lvs-terminal$'
keep $L01/comp.out
pkill -x xterm || true
magic_quit

# --- Part 8: the checker, on a fresh copy (the work copy's .magicrc loads the rig's probe) ----
cp -a /src/$L01 /tmp/l01-make
(cd /tmp/l01-make && make) > "$OUT/ev-l01-make.txt" 2>&1 || true
log "make: $(tail -n 6 "$OUT/ev-l01-make.txt" | head -n 1)"
