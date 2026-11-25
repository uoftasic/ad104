# Lab 04 (AD104-M): the screenshots on docs/labs/lab-04-buffer-and-and-overview.md, taken
# while the rig does the lab the way the page tells a student to, and `make` run on the
# cells it built. Run with shot.sh at the default SCREEN=1600x1000, with
# CONSOLE_GEOM="0 800 1200 170" so the console's last line is on the screen; every capture is
# a crop. l05.sh can run after it in the same call and reuses the my_inv_gen it builds. The
# two together took about 23 minutes, past shot.sh's default timeout:
#   RIG_TIMEOUT=2400 CONSOLE_GEOM="0 800 1200 170" scripts/screenshots/magic/shot.sh -o OUT \
#       scripts/screenshots/magic/steps/l04.sh scripts/screenshots/magic/steps/l05.sh
#
# Coordinates in microns are the reference's (tcl/compose.tcl) or this file's own choice for
# the generated inverter; the page gives none of them. Everything is done with the mouse,
# keys, menus and dialogs, except what the page has the student type: extraction in tkcon,
# `box size`, netgen and make in a terminal. Captures named x-... are not on the page; they
# record what the page's text says (netgen's output, the DRC report, the erased rails). The
# make output goes to OUT/make/.
say() { echo "== $*" >&2; }
D=labs/lab-04-buffer-and-and
W=/tmp/work/$D
M=/out/make
mkdir -p "$M"

# run_make NAME TARGET: run make in the work copy, as the student does in a terminal, and keep
# the output in /out/make/NAME.txt.
run_make() { ( cd "$W" && make $2 ) > "$M/$1.txt" 2>&1 || true; say "make $2 -> $(grep -E '^(PASS|FAIL)' "$M/$1.txt" | head -1)"; }

# Tcl helpers for reading dialog state (they only read). Defined after each magic_open.
define_helpers() {
    probe 'proc ::l04_desc {w} { set r [list $w]; foreach c [winfo children $w] { lappend r {*}[::l04_desc $c] }; return $r }' >/dev/null
    probe 'proc ::l04_check {top text} { foreach w [::l04_desc $top] { if {[winfo class $w] eq "Checkbutton" && ![catch {$w cget -text} t] && $t eq $text} { return [uplevel #0 [list set [$w cget -variable]]] } }; return {} }' >/dev/null
    # the check box on the same grid row as a label in the device dialog
    probe 'proc ::l04_gencheck {label} { foreach w [winfo children .params.body.area.edits] { if {[winfo class $w] eq {Label} && [string trim [$w cget -text]] eq $label} { set row [dict get [grid info $w] -row]; foreach s [winfo children .params.body.area.edits] { if {[winfo class $s] eq {Checkbutton} && ![catch {grid info $s} gi] && [dict get $gi -row] == $row} { return $s } } } }; return {} }' >/dev/null
}
selbb() { probe 'set cu [units list]; units microns noprint; set b [select bbox]; units {*}$cu; list [what -list] $b' 2>&1 | tr '\n' ' '; }
kids() { probe "set r {}; foreach c [cellname list children $1] {lappend r [list \$c [dict filter [cellname list property \$c parameters] key w l nf botc topc]]}; set r" 2>&1; }
drc_count() { probe 'drc list count total' 2>&1; }

# wait_gone TITLE_REGEX [SECONDS]: wait until no visible window has that title.
wait_gone() {
    local i
    for i in $(seq 1 $(( ${2:-10} * 4 ))); do
        xdotool search --onlyvisible --name "$1" >/dev/null 2>&1 || return 0
        sleep 0.25
    done
    log "window '$1' is still open"; return 1
}

# text_label NAME: Edit > Text ... with the box where it is: Text string NAME, Size 0.1,
# Port enable ticked (only clicked if it is not ticked already). text_okay clicks Okay.
text_label() {
    menu Edit 'Text ...'; find_window '^texthelper$' 10 >/dev/null; pause 0.5
    fill_entry 'Text string:' "$1" .texthelper
    fill_entry 'Size (um):' 0.1 .texthelper
    [ "$(probe '::l04_check .texthelper enable')" = 1 ] || click_button enable .texthelper
    say "text dialog: $1, port $(probe '::l04_check .texthelper enable'), port number field $(probe '.texthelper.port.tent get' 2>&1)"
}
text_okay() {
    click_button Okay .texthelper; wait_gone '^texthelper$' 10 || { click_button Okay .texthelper; wait_gone '^texthelper$' 10; }
    pause 0.5; hover_center
}
# text_label_fresh NAME: the same, but first untick and tick Port enable, which sets the
# number beside it to the next free port number of the cell being edited.
text_label_fresh() {
    menu Edit 'Text ...'; find_window '^texthelper$' 10 >/dev/null; pause 0.5
    fill_entry 'Text string:' "$1" .texthelper
    fill_entry 'Size (um):' 0.1 .texthelper
    say "port number field before: $(probe '.texthelper.port.tent get' 2>&1), enable $(probe '::l04_check .texthelper enable')"
    [ "$(probe '::l04_check .texthelper enable')" = 1 ] && { click_button enable .texthelper; pause 0.5; }
    click_button enable .texthelper; pause 0.5
    say "text dialog: $1, port $(probe '::l04_check .texthelper enable'), port number field $(probe '.texthelper.port.tent get' 2>&1)"
}
saved_ports() { say "labels and ports in the saved $1.mag: $(grep -A1 -E '^[fr]label' "$W/mag/$1.mag" | grep -v '^--' | tr '\n' ' ')"; }

# save_with BUTTON: File > Save... and BUTTON (write or autowrite) in each dialog that comes
# up, logging what each one asks, until none is left.
save_with() {
    menu File 'Save...'
    local i msg
    for i in 1 2 3 4; do
        find_window '^Dialog$' 5 >/dev/null 2>&1 || break
        pause 0.5
        msg="$(probe '.dialog.msg cget -text' 2>&1)"
        say "save dialog $i: $msg"
        click_button "$1" .dialog
        wait_gone '^Dialog$' 10 || true
        pause 1
    done
    hover_center
}

# open_file NAME: File > Open..., type NAME, Return, and wait for the caption to change.
open_file() {
    menu File 'Open...'; find_window '^Open$' 10 >/dev/null; pause 0.5
    type_text "$1"; key Return
    wait_gone '^Open$' 10
    pause 1.5; hover_center
    say "after opening $1: $(readout | head -1)"
}

# erase_swatch LAYER: shift + middle click on a palette swatch, which erases that layer
# from the box.
erase_swatch() {
    local xy; xy="$(probe "::rigprobe::palette $1")"
    # shellcheck disable=SC2086
    xdotool mousemove --sync $xy keydown shift click 2 keyup shift; sleep 1
}

# zoom_to X1 Y1 X2 Y2: fit the cell (v), set a rough box, zoom to it (ctrl+z). The rough
# box does not have to land exactly.
zoom_to() { hover_center; key v; box_um "$1" "$2" "$3" "$4"; hover_center; key ctrl+z; }

# typed_size X Y: the page's typed-size recipe. Left-click the lower-left corner, type
# `box size 0.17um 0.17um` in tkcon, click the layout window's title bar, press b.
typed_size() {
    click_um "$1" "$2" 1
    console 'box size 0.17um 0.17um'
    focus_layout; hover_center; key b
    say "typed size at $1 $2: box $(box_values)"
}

work $D

############################################################################ Part 1
say "Part 1: make cells, make scaffold"
run_make p1-cells cells
run_make p1-scaffold scaffold
magic_open $D/mag my_nand2
define_helpers
# hide the wells, point at the diffusion between the two gates, s three times
palette nwell 3; palette pwell 3
# The first key after clicks on the palette is sometimes lost (scripts/screenshots/magic/
# README.md, Pitfalls), so check that something is selected and press again if not.
for try in 1 2 3; do
    hover_um 1.97 1.62; key comma; key s; key s; key s
    sel="$(selbb)"
    case "$sel" in *ndiff*) break ;; esac
    say "s s s selected nothing (try $try); again"; pause 1
done
say "s s s on the series node: $sel"
capture l04-01-series-node layout
key comma
palette nwell 1; palette pwell 1
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice'
focus_layout
say "my_nand2.spice:"; grep -E '^\.subckt|^X' "$W/mag/my_nand2.spice" >&2 || true

############################################################################ Part 2
say "Part 2: File > Open... my_buf.mag"
hover_center
menu File 'Open...'; find_window '^Open$' 10 >/dev/null; pause 1
type_text my_buf.mag
capture l04-02-open-buf win:'^Open$'
key Return; wait_gone '^Open$' 10; pause 1.5
hover_center; key v
say "caption: $(readout | head -1)"
# the instances open unexpanded: box over the whole block, x
box_um -0.20 -0.20 6.20 6.20; hover_center; key x; pause 1
# inv1's Y and inv2's A, read off the screen by pointing: the rig points at the reference's
hover_um 2.36 2.52; say "pointing at inv1 Y: $(readout | tr '\n' ' ')"
hover_um 4.42 2.52; say "pointing at inv2 A: $(readout | tr '\n' ' ')"
# zoom on the gap, then one li rectangle that overlaps both pins
zoom_to 1.60 1.60 5.20 3.40
box_um 2.18 2.40 4.61 2.65
palette locali 2
menu Drc 'DRC update'; pause 1
say "DRC after the wire: $(drc_count); $(readout | tr '\n' ' ')"
hover_center; key v
zoom_to 1.00 1.20 5.90 3.80
capture l04-03-buf-wire layout

############################################################################ Part 3
say "Part 3: the label straight on inv1's A pin first"
zoom_to 0.60 1.80 2.40 3.20
box_um 1.30 2.40 1.55 2.65
text_label A
text_okay
say "console after the label on inv1's pin:"; console_tail 2 >&2
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice'
say "my_buf.spice with A on space:"; grep -E '^\.subckt|^X' "$W/mag/my_buf.spice" >&2 || true
focus_layout
# the patch under the label, same box
hover_center
palette locali 2
say "console after the patch:"; console_tail 2 >&2
capture l04-04-label-moved layout console
console 'extract all'
console 'ext2spice'
say "my_buf.spice with A on the patch:"; grep -E '^\.subckt|^X' "$W/mag/my_buf.spice" >&2 || true
focus_layout
hover_center; key v
zoom_to 4.70 2.00 5.70 3.00
box_um 5.20 2.42 5.45 2.67
palette locali 2
text_label X
text_okay
say "console after X:"; console_tail 2 >&2
hover_center; key v
menu Drc 'DRC update'; pause 1
say "DRC my_buf: $(drc_count)"
save_with autowrite
saved_ports my_buf
run_make p3-layout layout
mkdir -p /out/p3 && cp "$W"/results/my_buf.lvs.spice "$W"/results/magic.log /out/p3/ 2>/dev/null || true

############################################################################ Part 4
say "Part 4: my_and2"
open_file my_and2.mag
hover_center; key v
box_um -0.20 -0.20 7.20 6.20; hover_center; key x; pause 1
hover_um 3.36 2.52; say "pointing at nd0 Y: $(readout | tr '\n' ' ')"
hover_um 5.42 2.52; say "pointing at in0 A: $(readout | tr '\n' ' ')"
zoom_to 2.60 1.60 6.20 3.40
box_um 3.20 2.40 5.61 2.65
palette locali 2
hover_center; key v
for spec in "A 1.30 2.40 1.55 2.65" "B 2.40 2.40 2.65 2.65" "X 6.20 2.42 6.45 2.67"; do
    set -- $spec
    zoom_to "$(awk -v a="$2" 'BEGIN{print a-0.5}')" "$(awk -v a="$3" 'BEGIN{print a-0.4}')" \
            "$(awk -v a="$4" 'BEGIN{print a+0.5}')" "$(awk -v a="$5" 'BEGIN{print a+0.4}')"
    box_um "$2" "$3" "$4" "$5"
    palette locali 2
    if [ "$1" = A ]; then text_label_fresh "$1"; else text_label "$1"; fi
    text_okay
    say "console after $1:"; console_tail 2 >&2
    hover_center; key v
done
menu Drc 'DRC update'; pause 1
say "DRC my_and2: $(drc_count)"
save_with autowrite
saved_ports my_and2
run_make p4-layout layout

############################################################################ Part 5
say "Part 5: extract my_and2, netgen, make"
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice'
focus_layout
say "my_and2.spice:"; grep -E '^\.subckt|^X' "$W/mag/my_and2.spice" >&2 || true
terminal lvs-terminal
type_text "cd $W/mag"; key Return
type_text 'clear'; key Return
type_text 'netgen -batch lvs "my_and2.spice my_and2" "../spice/cells_sch.spice my_and2" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'
key Return; pause 8
capture x-netgen-and2 win:'^lvs-terminal$'
cp "$W/mag/comp.out" /out/comp-and2.out 2>/dev/null || true
run_make p5-make ''

############################################################################ Part 6
say "Part 6: netgen on the NAND against swapped_sch.spice"
type_text 'clear'; key Return
type_text 'netgen -batch lvs "my_and2.spice my_nand2" "../spice/swapped_sch.spice my_nand2" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'
key Return; pause 8
capture x-netgen-swapped-stdout win:'^lvs-terminal$'
type_text 'clear'; key Return
type_text 'cat comp.out'; key Return; pause 1
capture l04-05-netgen-swapped win:'^lvs-terminal$'
cp "$W/mag/comp.out" /out/comp-swapped.out 2>/dev/null || true
xdotool windowkill "$TERM_WIN" 2>/dev/null || true; sleep 0.5

############################################################################ Part 7
say "Part 7: a new cell, my_inv_gen, and the device generator"
magic_quit
magic_open $D/mag my_inv_gen
define_helpers
hover_center
for i in 1 2 3 4 5 6 7 8; do key shift+z; done
say "view after Z x8: $(view_um)"
menu_open 'Devices 1'
capture l04-06-devices-menu layout menu:'Devices 1'
key Escape; pause 0.5
hover_center
# zoom so that clicks land on the 0.01 um grid, then the nmos's corner
box_um -0.50 -0.50 2.00 1.50; hover_center; key ctrl+z
box_um 0.61 0.45 0.61 0.45
menu 'Devices 1' 'nmos (MOSFET)'; pause 3
say "params opened at $(probe '::rigprobe::rect .params')"
move_window '^params$' 1000 23
fill_entry 'Width (um)' 0.65 .params
fill_entry 'Length (um)' 0.15 .params
fill_entry 'Fingers' 1 .params
capture l04-07-nmos-dialog win:'^params$'
click_button 'Create and Close' .params; pause 3
hover_center
say "console after the nmos:"; console_tail 3 >&2
say "children: $(kids my_inv_gen)"
key v; key shift+z; key shift+z
say "view before the pmos: $(view_um)"
box_um -0.50 2.50 2.00 4.20; hover_center; key ctrl+z
box_um 0.61 3.45 0.61 3.45
menu 'Devices 1' 'pmos (MOSFET)'; pause 3
move_window '^params$' 1000 23
MB=$(probe 'set r {}; foreach w [winfo children .params.body.area.edits] { if {[winfo class $w] eq {Menubutton}} {set r $w} }; set r')
say "Device type shows $(probe "$MB cget -text")"
xy=$(probe "::rigprobe::center $MB"); click_xy $xy 1; pause 1
MN=$(probe "$MB cget -menu")
say "Device type choices: $(probe "set r {}; for {set i 0} {\$i <= [$MN index end]} {incr i} {catch {lappend r [$MN entrycget \$i -label]}}; set r")"
HV=$(probe "set y {}; for {set i 0} {\$i <= [$MN index end]} {incr i} {if {![catch {$MN entrycget \$i -label} l] && \$l eq {sky130_fd_pr__pfet_01v8_hvt}} {set y [list [expr {[winfo rootx $MN]+40}] [expr {[winfo rooty $MN]+[$MN yposition \$i]+8}]]}}; set y")
click_xy $HV 1; pause 2
say "Device type now $(probe "$MB cget -text")"
fill_entry 'Width (um)' 1 .params
fill_entry 'Length (um)' 0.15 .params
fill_entry 'Fingers' 1 .params
capture l04-08-pmos-dialog win:'^params$'
click_button 'Create and Close' .params; pause 3
hover_center
say "console after the pmos:"; console_tail 3 >&2
say "children: $(kids my_inv_gen)"
key v

############################################################################ Part 8
say "Part 8: DRC on the placed devices"
menu Drc 'DRC update'; pause 2
say "DRC with both devices at their defaults: $(drc_count)"
hover_center; key equal; pause 1
menu Drc 'DRC report'; pause 1
say "DRC report:"; console_tail 3 >&2
hover_center; key v
capture x-gen-defaults-drc layout console
# untick the nmos's bottom gate contact: point at it, i, q
hover_um 1.40 1.50; key comma; key i; pause 0.5
say "i over the nmos: $(selbb)"
key q; pause 3
move_window '^params$' 1000 23
say "edit dialog title line and buttons: $(probe 'set out {}; foreach w [winfo children .params.buttons] {lappend out [$w cget -text]}; set out')"
CB=$(probe '::l04_gencheck {Add bottom gate contact}')
xy=$(probe "::rigprobe::center $CB"); click_xy $xy 1
say "Add bottom gate contact now $(probe '::l04_check .params {Add bottom gate contact}')"
capture l04-09-edit-untick win:'^params$'
click_button Okay .params; pause 3
hover_center
say "console after Okay:"; console_tail 3 >&2
hover_um 1.40 1.40; key comma; key i; pause 0.5
say "nmos after the untick: $(selbb)"
hover_um 1.40 4.60; key comma; key i; pause 0.5
say "i over the pmos: $(selbb)"
key q; pause 3
move_window '^params$' 1000 23
CB=$(probe '::l04_gencheck {Add top gate contact}')
xy=$(probe "::rigprobe::center $CB"); click_xy $xy 1
say "Add top gate contact now $(probe '::l04_check .params {Add top gate contact}')"
click_button Okay .params; pause 3
hover_center; key comma
hover_um 1.40 4.60; key i; pause 0.5
say "pmos after the untick: $(selbb)"
key comma
say "children: $(kids my_inv_gen)"
menu Drc 'DRC update'; pause 2
say "DRC after both unticks: $(drc_count)"
# The wiring. nmos centre (1.40, 1.405), pmos centre (1.40, 4.605) after the unticks.
hover_center; key v
for spec in \
    "metal1 1.26 1.80 1.54 4.00" \
    "metal1 0.00 1.15 1.29 1.35" \
    "metal1 0.00 1.15 0.23 4.89" \
    "metal1 0.00 4.69 1.29 4.89" \
    "locali 1.54 1.15 2.27 1.35" \
    "locali 1.54 4.69 2.27 4.89" \
    "metal1 0.00 0.16 2.80 0.60" \
    "metal1 0.00 5.62 2.80 6.06"; do
    set -- $spec
    box_um "$2" "$3" "$4" "$5"
    palette "$1" 2
done
# the two mcons on the guard rings, by typed size
zoom_to 1.50 0.00 2.60 0.90
typed_size 2.00 0.36
palette viali 2
hover_center; key v
zoom_to 1.50 5.30 2.60 6.10
typed_size 2.00 5.68
palette viali 2
hover_center; key v
# labels on top-level metal1
for spec in "A 1.30 2.80 1.50 3.00" "Y 0.02 2.90 0.21 3.10" "VGND 0.20 0.28 0.40 0.48" "VPWR 0.20 5.72 0.40 5.92"; do
    set -- $spec
    box_um "$2" "$3" "$4" "$5"
    text_label "$1"
    text_okay
    say "console after $1:"; console_tail 2 >&2
done
hover_center; key v
menu Drc 'DRC update'; pause 2
say "DRC after wiring (fast): $(drc_count)"
menu Drc 'DRC Complete'; menu Drc 'DRC update'; pause 3
say "DRC after wiring (full): $(drc_count)"
menu Drc 'DRC Fast'
hover_center; key v
capture l04-10-gen-wired layout
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice'
focus_layout
say "my_inv_gen.spice:"; cat "$W/mag/my_inv_gen.spice" >&2 || true
terminal gen-terminal
type_text "cd $W/mag"; key Return
type_text 'clear'; key Return
type_text 'netgen -batch lvs "my_inv_gen.spice my_inv_gen" "../spice/my_inv_gen_sch.spice my_inv_gen" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl'
key Return; pause 8
capture l04-11-gen-netgen win:'^gen-terminal$'
cp "$W/mag/comp.out" /out/comp-gen.out 2>/dev/null || true
xdotool windowkill "$TERM_WIN" 2>/dev/null || true; sleep 0.5
hover_center
save_with autowrite
say "console after autowrite:"; console_tail 4 >&2
ls -la "$W/mag" >&2
run_make p8-gen gen
keep $D/mag/my_inv_gen.mag
for f in "$W"/mag/sky130_fd_pr__*.mag; do keep "$D/mag/$(basename "$f")"; done

############################################################################ Part 9
say "Part 9: take the buffer's rails away"
open_file my_buf.mag
hover_center; key v
box_um 0.00 0.00 6.00 0.40
erase_swatch metal1
box_um 0.00 5.60 6.00 6.00
erase_swatch metal1
hover_center
capture x-rails-erased layout
save_with autowrite
saved_ports my_buf
run_make p9-layout-norails layout
box_um 0.00 0.00 6.00 0.40
palette metal1 2
box_um 0.00 5.60 6.00 6.00
palette metal1 2
box_um 2.60 0.05 2.85 0.30
text_label_fresh VGND
text_okay
box_um 2.60 5.70 2.85 5.95
text_label VPWR
text_okay
hover_center
menu Drc 'DRC update'; pause 1
say "DRC my_buf after the rails came back: $(drc_count)"
save_with autowrite
saved_ports my_buf
run_make p9-layout-rails layout
run_make p9-make ''
keep $D/mag/my_buf.mag $D/mag/my_and2.mag
magic_quit
