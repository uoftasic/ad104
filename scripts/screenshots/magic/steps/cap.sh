# cap.sh - the capstone (Place and route), done once through Magic's GUI.
#
# Run from the repo root (it took about 16 minutes, so raise the rig's timeout):
#   RIG_TIMEOUT=2400 RIG_DISPLAY=64 scripts/screenshots/magic/shot.sh -o OUT \
#       scripts/screenshots/magic/steps/cap.sh
#
# It does what the page asks a student to do, in order, with the mouse, keys, menus and
# dialogs, and the typed commands the page allows (`box size`, `select top cell`,
# `port makeall`, extraction, netgen). It writes the page's shots as cap-NN-*.png (copied
# into docs/assets/img/ as ad104-cap-NN-*.png), logs what Magic printed at each step to
# rig.log, runs `make layout` and `make` on the block it built, and keeps the block
# (`OUT/files/datapath.mag`) and the GDS files it wrote.
#
# The coordinates below are the rig's, chosen on Magic's 0.01 um click grid; the page gives
# none of them.

say() { echo "== $*" >&2; }
st() { echo "   readout: $(readout 2>/dev/null | tr '\n' '|')" >&2; }
ct() { echo "   console:" >&2; console_tail "${1:-4}" >&2 || true; echo >&2; }
T0=$(date +%s); tm() { echo "   [t=$(( $(date +%s) - T0 ))s] $*" >&2; }
# drcwait: wait until the DRC button's text stops changing, and log it.
drcwait() {
    local p="" c i
    for i in $(seq 1 30); do
        c="$(readout 2>/dev/null | grep 'drc button' || true)"
        [ -n "$c" ] && [ "$c" = "$p" ] && break
        p="$c"; sleep 1
    done
    echo "   $c" >&2
}
# zoom_to X1 Y1 X2 Y2: a rough box round an area, then ctrl+z (the box need not be exact).
zoom_to() { click_um "$1" "$2" 1; click_um "$3" "$4" 3; hover_center; key ctrl+z; pause 1; }
# via_first X Y: left-click a pin's lower-left corner, type the size, check it with b,
# middle-click viali. via_next X Y: the box keeps its size, so a left click moves it.
via_first() {
    click_um "$1" "$2" 1
    console 'box size 0.17um 0.17um'
    focus_layout; hover_center; key b; pause 0.5
    palette viali 2; pause 0.5
}
via_next() { click_um "$1" "$2" 1; palette viali 2; pause 0.5; }
# metal X1 Y1 X2 Y2: the click recipe, then middle-click metal1.
metal() { box_um "$@"; palette metal1 2; pause 0.5; }
drc_check() { hover_center; menu Drc 'DRC update'; drcwait; ct 3; }
# dialog_text: the text of Magic's save dialog(s) on screen, if any.
dialog_text() {
    probe 'set m {}; foreach w [winfo children .] {
        if {[winfo toplevel $w] ne $w || ![winfo ismapped $w]} continue
        if {[catch {wm title $w} tt] || $tt ne "Dialog"} continue
        set todo [winfo children $w]
        while {[llength $todo]} {
            set c [lindex $todo 0]; set todo [lrange $todo 1 end]
            if {[winfo class $c] in {Label Message} && ![catch {$c cget -text} t]} { append m "$t " }
            set todo [concat $todo [winfo children $c]]
        }
    }; string trim $m' 2>/dev/null || true
}
# save_block [SHOT]: File > Save..., then answer each dialog the way the page says: skip a
# foundry cell (its .mag is in the PDK and read-only), write datapath. Logs every dialog.
save_block() {
    local shot="${1:-}" i msg
    hover_center; menu File 'Save...'; pause 1.5
    for i in 1 2 3 4 5 6; do
        msg="$(dialog_text)"
        [ -n "$msg" ] || break
        echo "   save dialog $i: $msg" >&2
        if [ -n "$shot" ] && [ "$i" = 1 ]; then capture "$shot" win:'^Dialog$'; fi
        case "$msg" in
            sky130_fd_sc_hd__*) click_button skip ;;
            *) click_button write ;;
        esac
        pause 1.5
    done
    if xdotool search --onlyvisible --name '^Dialog$' >/dev/null 2>&1; then
        log "save_block: a Dialog is still open"; return 1
    fi
    ct 3
    echo "   $(ls -l --time-style=+%T /tmp/work/$CAP/mag/datapath.mag)" >&2
}
run_make() { ( cd "/tmp/work/$CAP" && TIMEFORMAT="   TIME make $* %R s" && time make "$@" ) >&2 || true; }

CAP=labs/capstone-place-and-route
work "$CAP"
( cd "/tmp/work/$CAP" && make scaffold ) >&2

# ---- Part 1: look at the placement ---------------------------------------------------------
say "Part 1: open"
magic_open "$CAP/mag" datapath
ct 14; st
capture cap-01-unexpanded layout console
say "box round the row, x"
hover_center; key v; pause 1
click_um -0.30 -0.40 1; click_um 13.70 3.10 3
hover_center; key x; pause 1; ct 3
say "readout at the right-hand end of the rails"
hover_um 13.34 0.10; st
hover_um 0 0.10; st
say "DRC update (DRC Fast)"
drc_check
say "DRC Complete, DRC update"
menu Drc 'DRC Complete'; pause 1
drc_check
menu Options 'DRC Manager'; pause 2
move_window '^drcmgr$' 1000 23
probe '::rigprobe::treerows .drcmgr.box.view' 2>/dev/null | grep -v '^  ' >&2 || true
echo "   error rows: $(probe '::rigprobe::treerows .drcmgr.box.view' 2>/dev/null | grep -c '^  ' || true)" >&2
capture cap-02-drc-complete-32 layout tk:.drcmgr
probe 'wm withdraw .drcmgr' >/dev/null || true   # the student closes it with its close button
hover_center; key comma
say "back to DRC Fast for routing"
menu Drc 'DRC Fast'; pause 1
drc_check
say "make layout on the placement"
run_make layout
tm "Part 1"

# ---- Part 2: what is above each cell -------------------------------------------------------
say "Part 2: zoom on dff0, press !"
zoom_to 0.00 0.05 7.40 2.75
hover_center; key exclam; pause 1
capture cap-03-bang-metal1 layout
for y in 1.41 1.42 1.64 1.65 1.75 1.76 1.98 1.99; do hover_um 3.00 "$y"; echo "   y=$y: $(readout | grep '^readout')" >&2; done
say "9 shows every layer again"
hover_center; key 9; pause 1
echo "   see after 9: $(probe 'see' 2>/dev/null | head -c 300 || true)" >&2
tm "Part 2"

# ---- Part 3: route the three nets ----------------------------------------------------------
say "Part 3, net Q: dff0/Q to and1/A"
hover_center; key v
zoom_to 6.60 0.25 7.90 2.15
via_first 6.95 0.43
st; ct 6
capture cap-04-mcon layout console
via_next 7.51 1.78
drc_check
metal 6.89 0.40 7.18 1.98
metal 6.89 1.75 7.74 1.98
drc_check
capture cap-05-net-routed layout
hover_center; key equal; pause 1; ct 3
menu Drc 'DRC report'; pause 1; ct 3
tm "net Q"
say "net n1: and1/X to and2/A"
hover_center; key v
zoom_to 9.00 1.55 10.30 2.45
via_first 9.35 2.13
via_next 9.81 1.78
metal 9.29 1.75 9.58 2.33
metal 9.29 1.75 10.04 1.98
drc_check
tm "net n1"
say "net n2: and2/X to buf0/A"
hover_center; key v
zoom_to 11.30 0.95 12.60 2.45
via_first 11.65 2.13
via_next 12.11 1.11
metal 11.59 1.08 11.88 2.33
metal 11.59 1.08 12.34 1.31
drc_check
hover_center; key equal; pause 1; ct 3
tm "net n2"
say "save, make layout"
save_block cap-06-save-foundry-cell
run_make layout
tm "Part 3"

# ---- Part 4: bring out the pins ------------------------------------------------------------
# label NAME X1 Y1 X2 Y2: the box on the shape, Edit > Text ..., the name, Size 0.1, Port
# left unticked, Okay.
label() {
    local name="$1"; shift
    box_um "$@"
    hover_center; menu Edit 'Text ...'; pause 1
    fill_entry 'Text string:' "$name" .texthelper
    fill_entry 'Size (um):' 0.1 .texthelper
    echo "   port check box: $(probe 'set v {}; set todo [winfo children .texthelper]; while {[llength $todo]} { set c [lindex $todo 0]; set todo [lrange $todo 1 end]; if {[winfo class $c] eq "Checkbutton" && [$c cget -text] eq "enable"} { set var [$c cget -variable]; set v [set ::$var] }; set todo [concat $todo [winfo children $c]] }; set v' 2>/dev/null || true)" >&2
    if [ "$name" = CLK ]; then capture cap-07-text-no-port tk:.texthelper; fi
    click_button Okay .texthelper; pause 1; ct 3
}
say "Part 4, CLK: via, a 0.29 x 0.23 pad first"
hover_center; key v
zoom_to -0.20 0.85 0.80 1.65
via_first 0.15 1.11
metal 0.09 1.08 0.38 1.31
drc_check
hover_center; key equal; pause 1; ct 3
menu Drc 'DRC report'; pause 1; ct 3
say "CLK: the pad made 0.31 x 0.31"
metal 0.08 1.04 0.39 1.35
drc_check
label CLK 0.15 1.11 0.32 1.28
say "D, at the spot from Part 2"
hover_center; key v
zoom_to 1.10 0.55 1.90 1.25
via_first 1.40 0.80
metal 1.33 0.74 1.64 1.03
label D 1.40 0.80 1.57 0.97
say "A, on and1's B pin"
hover_center; key v
zoom_to 8.10 1.20 8.90 1.90
via_first 8.42 1.44
metal 8.35 1.37 8.66 1.68
label A 8.42 1.44 8.59 1.61
say "B, on and2's B pin"
hover_center; key v
zoom_to 10.40 1.20 11.20 1.90
via_first 10.72 1.44
metal 10.65 1.37 10.96 1.68
label B 10.72 1.44 10.89 1.61
say "Y, on buf0's X pin"
hover_center; key v
zoom_to 12.70 1.50 13.50 2.20
via_first 13.02 1.79
metal 12.95 1.72 13.26 2.03
label Y 13.02 1.79 13.19 1.96
drc_check
tm "five pins"
say "rails: read the bottom rail's edges, click its lower-left corner, box size"
hover_center; key v
zoom_to -0.40 -0.45 1.00 0.55
for p in "0 -0.24" "0 0.24" "0.50 -0.24" "0.50 0.24"; do hover_um $p; echo "   at $p: $(readout | grep '^readout')" >&2; done
click_um 0 -0.24 1
console 'box size 13.34um 0.48um'
focus_layout; hover_center; key b; pause 0.5; ct 6
palette metal1 2; pause 0.5
hover_center; key v
zoom_to -0.40 2.25 1.00 3.20
for p in "0 2.48" "0 2.96"; do hover_um $p; echo "   at $p: $(readout | grep '^readout')" >&2; done
click_um 0 2.48 1
console 'box size 13.34um 0.48um'
focus_layout; palette metal1 2; pause 0.5
say "rail labels"
hover_center; key v
zoom_to 2.60 -0.45 3.80 0.55
label VGND 3.00 -0.20 3.30 0.20
hover_center; key v
zoom_to 2.60 2.25 3.80 3.20
label VPWR 3.00 2.52 3.30 2.92
probe 'wm withdraw .texthelper' >/dev/null || true
hover_center; key v
drc_check
say "save, make layout: labels but no ports"
save_block
run_make layout
say "select top cell, port makeall"
console 'select top cell'
console 'port makeall'
ct 4
focus_layout; hover_center; key comma
save_block
run_make layout
tm "Part 4"

# ---- Part 5: the tap cells -----------------------------------------------------------------
say "Part 5: extract before the taps"
console 'extract all'; console 'ext2spice lvs'; console 'ext2spice'; pause 2; ct 16
( cd "/tmp/work/$CAP/mag" && ls && grep -n 'Xbuf0\|^\.subckt datapath' datapath.spice ) >&2 || true
# Opening the Library Manager runs Magic's `path` command, and once the DRC Manager has been
# opened in the session (Part 1), that also moves the box onto the whole block. So the manager
# is opened first and the box set afterwards (rig logs of Nov 24, tapu.sh and tapt.sh).
say "Library Manager: open it, open the library's folder, click the tap"
focus_layout; hover_center; key v
menu Options 'Library Manager'; pause 2
move_window '^libmgr$' 1000 23
echo "   box after opening the manager: $(box_values)" >&2
probe 'set o {}; foreach i [.libmgr.box.view children {}] { lappend o "[.libmgr.box.view item $i -text] open=[.libmgr.box.view item $i -open] rows=[llength [.libmgr.box.view children $i]]" }; join $o \n' >&2 || true; echo >&2
# Open the library's folder the way a student does: double-click its row.
xy="$(probe 'set r {}; foreach i [.libmgr.box.view children {}] { if {[string match *sky130_fd_sc_hd/* [.libmgr.box.view item $i -text]]} { .libmgr.box.view see $i; update idletasks; lassign [.libmgr.box.view bbox $i] x y w h; set r [list [expr {[winfo rootx .libmgr.box.view] + $x + 40}] [expr {[winfo rooty .libmgr.box.view] + $y + $h / 2}]]; break } }; if {$r eq {}} { error "no sky130_fd_sc_hd folder" }; set r')"
# shellcheck disable=SC2086
xdotool mousemove --sync $xy click --repeat 2 --delay 120 1; sleep 1
click_tree .libmgr.box.view sky130_fd_sc_hd__tapvpwrvgnd_1
capture cap-08-library-manager tk:.libmgr
# place_tap X: zoom on the spot, left-click where the tap's lower-left corner goes (the box
# keeps the zoom box's size; only its lower-left corner matters), bring the manager forward
# (a student clicks its title bar), Place. Magic then sets the box round the new instance.
place_tap() {
    focus_layout; hover_center; key v
    zoom_to "$(awk -v x="$1" 'BEGIN{print x - 0.40}')" -0.30 "$(awk -v x="$1" 'BEGIN{print x + 0.80}')" 0.60
    click_um "$1" 0 1
    echo "   box before: $(box_values)" >&2
    xdotool windowactivate --sync "$(find_window '^libmgr$')" 2>/dev/null || true; sleep 0.5
    click_button Place .libmgr; pause 2; ct 3
    local got want
    got="$(box_values)"
    want="$(awk -v x="$1" 'BEGIN{printf "%g -0.24 %g 2.96", x - 0.19, x + 0.65}')"
    echo "   box after (the new instance): $got" >&2
    [ "$got" = "$want" ] || { log "place_tap $1: the tap is at $got, wanted $want"; return 1; }
}
say "left tap"
place_tap -0.46
say "right tap"
place_tap 13.34
echo "   children: $(probe 'cellname list children datapath' 2>/dev/null || true)" >&2
probe 'wm withdraw .libmgr' >/dev/null || true   # the student closes it with its close button
focus_layout; hover_center; key v; pause 1
say "DRC Complete with the taps"
menu Drc 'DRC Complete'; pause 1
drc_check
capture cap-09-taps-placed layout
say "extract after the taps, netgen in a terminal"
console 'extract all'; console 'ext2spice lvs'; console 'ext2spice'; pause 2; ct 4
( cd "/tmp/work/$CAP/mag" && grep -n 'Xbuf0\|^\.subckt datapath' datapath.spice ) >&2 || true
terminal lvs-terminal
type_text "cd /tmp/work/$CAP/mag"; key Return
type_text 'netgen -batch lvs "datapath.spice datapath" "../spice/datapath_sch.spice datapath" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'
key Return; pause 15
type_text 'tail -3 comp.out'; key Return; pause 1
( cd "/tmp/work/$CAP/mag" && echo "   comp.out:" && tail -25 comp.out ) >&2 || true
xdotool windowkill "$TERM_WIN" 2>/dev/null || true
say "save, make layout"
focus_layout
save_block
run_make layout
tm "Part 5"

# ---- Part 6: time it ------------------------------------------------------------------------
say "Part 6: make"
( cd "/tmp/work/$CAP" && make clean >/dev/null ) || true
run_make
tm "Part 6"

# ---- Part 7: write the GDS ------------------------------------------------------------------
say "Part 7: File > Write GDS"
focus_layout; hover_center
menu File 'Write GDS'; pause 1.5
type_text datapath.gds; pause 0.5
capture cap-10-write-gds win:'^Save As'
key Return; pause 2; ct 4
( cd "/tmp/work/$CAP/mag" && ls -l datapath.gds ) >&2
keep "$CAP/mag/datapath.mag" "$CAP/mag/datapath.gds"
magic_quit
tm "Part 7"

# ---- The reference block's GDS, written the same way ---------------------------------------
say "reference: File > Write GDS"
mkdir -p /tmp/work/ref && cp -a "/src/$CAP/." /tmp/work/ref/
cp /tmp/work/ref/solutions/datapath_ref.mag /tmp/work/ref/mag/datapath.mag
magic_open ref/mag datapath
hover_center; menu File 'Write GDS'; pause 1.5
type_text datapath.gds; key Return; pause 2; ct 3
( cd /tmp/work/ref/mag && ls -l datapath.gds && mv datapath.gds datapath_ref.gds ) >&2
keep ref/mag/datapath_ref.gds
magic_quit
tm "done"
