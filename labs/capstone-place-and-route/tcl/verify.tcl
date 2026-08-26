# Capstone — DRC both ways, extract, and extract again with parasitics.
set cell datapath
if {[info exists env(AD104_CELL)]} { set cell $env(AD104_CELL) }
set src ../mag
if {[info exists env(AD104_SRC)]} { set src $env(AD104_SRC) }

cd results
addpath $src
addpath $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/mag
load $cell
select top cell

set fp [open report.txt w]
set b [box values]
puts $fp "BBOX_UM [expr {([lindex $b 2]-[lindex $b 0])*0.005}] [expr {([lindex $b 3]-[lindex $b 1])*0.005}]"
puts $fp "CELL $cell"
foreach c [cellname list children $cell] { puts $fp "CHILD $c" }

drc euclidean on
drc style drc(fast)
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
ext2spice -o $cell.lvs.spice
ext2spice cthresh 0
ext2spice -o $cell.pex.spice
close $fp
puts "verify.tcl finished"
quit -noprompt
