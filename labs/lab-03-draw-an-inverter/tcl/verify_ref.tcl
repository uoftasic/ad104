# Lab 03 — the same checks, run against the reference cell instead of yours.
#
# `make refcheck` uses this. It is tcl/verify.tcl with solutions/inv_ref
# substituted for mag/my_inv, and it writes to different result files so that
# running it never invalidates the check on your own cell.

set out results
cd $out
addpath ../solutions
load inv_ref

set fp [open report_ref.txt w]

select top cell
set b [box values]
puts $fp "BBOX $b"

drc euclidean on
drc check ; drc catchup
puts $fp "DRC_FAST [drc list count total]"
drc style drc(full)
drc check ; drc catchup
puts $fp "DRC_FULL [drc list count total]"
foreach v [drc listall why] {
    if {[string index $v 0] ne "\{"} { puts $fp "DRC_WHY $v" }
}

extract do local
extract all
ext2spice lvs
ext2spice -o inv_ref.lvs.spice

# and again with every parasitic capacitance kept, for Lab 05
ext2spice cthresh 0
ext2spice -o inv_ref.pex.spice

close $fp
puts "verify.tcl finished"
quit -noprompt
