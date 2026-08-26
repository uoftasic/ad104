# Lab 04 — DRC, extract and PEX-extract both blocks.
set cells {my_buf my_and2}
if {[info exists env(AD104_CELLS)]} { set cells $env(AD104_CELLS) }
set src ../mag
if {[info exists env(AD104_SRC)]} { set src $env(AD104_SRC) }

cd results
addpath $src
addpath ../mag
set fp [open report.txt w]
drc euclidean on
foreach cell $cells {
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
    ext2spice cthresh 0
    ext2spice -o $cell.pex.spice
    ext2spice cthresh infinite
}
close $fp
puts "verify.tcl finished"
quit -noprompt
