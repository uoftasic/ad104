# Lab 02 — DRC and extract all five cells.
set out results
cd $out
addpath ../mag
set fp [open report.txt w]
drc euclidean on
foreach cell {drc_01 drc_02 drc_03 drc_04 drc_05} {
    load $cell
    select top cell
    drc style drc(fast)
    drc check ; drc catchup
    puts $fp "$cell FAST [drc list count total]"
    drc style drc(full)
    drc check ; drc catchup
    puts $fp "$cell FULL [drc list count total]"
    foreach v [drc listall why] {
        if {[string index $v 0] ne "\{"} { puts $fp "$cell WHY $v" }
    }
    extract do local
    extract all
    ext2spice lvs
    ext2spice -o $cell.lvs.spice
}
close $fp
puts "verify.tcl finished"
quit -noprompt
