# Lab 05 (AD104-M): the screenshots on docs/labs/lab-05-what-it-costs-overview.md, taken while
# the rig measures and extracts both cells the way the page tells a student to, then `make`.
# Run with shot.sh at the default SCREEN=1600x1000, with CONSOLE_GEOM="0 800 1200 170" so the
# console's last line is on the screen; every capture is a crop.
say() { echo "== $*" >&2; }
D=labs/lab-05-what-it-costs
W=/tmp/work/$D
M=/out/make
mkdir -p "$M"
INV1=/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__inv_1.mag
# wait_gone TITLE_REGEX [SECONDS]: wait until no visible window has that title.
wait_gone() {
    local i
    for i in $(seq 1 $(( ${2:-10} * 4 ))); do
        xdotool search --onlyvisible --name "$1" >/dev/null 2>&1 || return 0
        sleep 0.25
    done
    log "window '$1' is still open"; return 1
}
run_make() { ( cd "$W" && make $2 ) > "$M/$1.txt" 2>&1 || true; say "make $2 -> $(grep -E '^(PASS|FAIL)' "$M/$1.txt" | head -1)"; }

work $D

############################################################################ Part 2
say "Part 2: measure and extract the Lab 03 reference cell"
magic_open $D/mag my_inv
hover_center; key v
# the rails' outer corners are the cell's corners
box_um 0.00 0.00 3.00 6.00
hover_center; key b
say "b on my_inv:"; console_tail 6 >&2
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice cthresh 0'
console 'ext2spice -o my_inv_pex.spice'
capture l05-01-pex-console console
focus_layout
say "my_inv_pex.spice:"; cat "$W/mag/my_inv_pex.spice" >&2 || true
say "C lines: $(grep -c '^C' "$W/mag/my_inv_pex.spice")"

############################################################################ Part 3
say "Part 3: measure and extract inv_1"
hover_center
menu File 'Open...'; find_window '^Open$' 10 >/dev/null; pause 1
type_text "$INV1"; key Return; wait_gone '^Open$' 10; pause 1.5
hover_center; key v
say "caption: $(readout | head -1)"
hover_um 0.69 0.00; say "pointing at the bottom rail's middle: $(readout | tr "\n" " ")"
hover_um 0.69 2.72; say "pointing at the top rail's middle: $(readout | tr "\n" " ")"
box_um 0.00 -0.24 1.38 0.24
hover_center; key b
say "b on the VGND rail:"; console_tail 6 >&2
box_um 0.00 0.00 1.38 2.72
hover_center; key b
say "b rail centre to rail centre:"; console_tail 6 >&2
capture l05-02-inv1-width layout console
console 'extract do local'
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice cthresh 0'
console 'ext2spice -o inv_1_pex.spice'
focus_layout
say "inv_1_pex.spice:"; cat "$W/mag/inv_1_pex.spice" >&2 || true
say "C lines: $(grep -c '^C' "$W/mag/inv_1_pex.spice")"
ls -la "$W/mag" >&2
magic_quit

############################################################################ Part 4
say "Part 4: make"
run_make p4-make ''
cat "$M/p4-make.txt" >&2

############################################################################ Part 9 (optional)
say "Part 9: the generated inverter from Lab 04, with every capacitance"
L4=labs/lab-04-buffer-and-and
# Run after l04.sh in the same container, this uses the my_inv_gen that l04.sh built through
# the GUI. Run alone, it uses the reference under the student's cell name instead.
if [ ! -f /tmp/work/$L4/mag/my_inv_gen.mag ]; then
    work $L4
    cp /tmp/work/$L4/solutions/inv_gen_ref.mag /tmp/work/$L4/mag/my_inv_gen.mag
    cp /tmp/work/$L4/solutions/sky130_fd_pr__*.mag /tmp/work/$L4/mag/
    say "my_inv_gen: the reference, copied in"
else
    say "my_inv_gen: the one l04.sh built"
fi
magic_open $L4/mag my_inv_gen
console 'extract all'
console 'ext2spice lvs'
console 'ext2spice cthresh 0'
console 'ext2spice -o my_inv_gen_pex.spice'
focus_layout
say "my_inv_gen_pex.spice:"; cat "/tmp/work/$L4/mag/my_inv_gen_pex.spice" >&2 || true
magic_quit
