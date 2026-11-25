# Lab 04 - check the generated inverter, for `make gen`.
#
# Loads mag/my_inv_gen.mag and lets Magic find the device cells it uses. Their
# names come from a hash of each device's parameters and change whenever an
# option changes, so this script never names them. DRC under both rule sets,
# then extraction. Nothing here modifies your layout.
set cell my_inv_gen
if {[info exists env(AD104_CELL)]} { set cell $env(AD104_CELL) }
set src ../mag
if {[info exists env(AD104_SRC)]} { set src $env(AD104_SRC) }

cd results
addpath $src
set fp [open gen_report.txt w]
drc euclidean on
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
close $fp
puts "verify_gen.tcl finished"
quit -noprompt
