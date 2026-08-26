# Lab 03 — check whatever is in mag/my_inv.mag right now.
#
# Loads your cell, runs DRC under both rule sets, extracts it, and writes a
# SPICE netlist for netgen. Nothing here modifies your layout.

set out results
cd $out
addpath ../mag
load my_inv

set fp [open report.txt w]

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
ext2spice -o my_inv.lvs.spice

# and again with every parasitic capacitance kept, for Lab 05
ext2spice cthresh 0
ext2spice -o my_inv.pex.spice

close $fp
puts "verify.tcl finished"
quit -noprompt
