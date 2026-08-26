# Lab 05 — extract both inverters twice: once for the devices, once with
# every parasitic capacitance kept.
#
# `ext2spice cthresh 0` is the whole lab. Without it Magic throws away the
# small coupling capacitances and the two netlists come out looking almost
# identical, which is the wrong lesson.

set mine my_inv
if {[info exists env(AD104_CELL)]} { set mine $env(AD104_CELL) }

cd results
addpath ../mag
set fp [open geom.txt w]

foreach {cell src} [list $mine ../mag \
        sky130_fd_sc_hd__inv_1 $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/mag] {
    addpath $src
    load $cell
    select top cell
    set fb [property FIXED_BBOX]
    if {$fb eq ""} {
        set b [box values]
        set fb [list [lindex $b 0] [lindex $b 1] [lindex $b 2] [lindex $b 3]]
    }
    puts $fp "$cell FIXED_BBOX $fb"
    extract do local
    extract all
    ext2spice lvs
    ext2spice cthresh 0
    ext2spice -o $cell.pex.spice
}
close $fp
puts "pex.tcl finished"
quit -noprompt
