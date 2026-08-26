# Lab 01 — inspect a cell you did not draw.
#
# Run by `make`. Everything here is a command you can also type by hand into
# Magic's tkcon console, in this order.

set cellpath $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__inv_1.mag
set out      results

cd $out
load $cellpath
select top cell

set fp [open report.txt w]

# --- how big is it? -------------------------------------------------------
# box values returns internal units. One internal unit is 0.005 um.
set b [box values]
set w [expr {([lindex $b 2] - [lindex $b 0]) * 0.005}]
set h [expr {([lindex $b 3] - [lindex $b 1]) * 0.005}]
puts $fp "BBOX_UM $w $h"

# FIXED_BBOX is the cell's real placement outline, without the well overhang.
set fb [property FIXED_BBOX]
puts $fp "FIXED_BBOX $fb"

# --- design rule check, both ways ------------------------------------------
drc euclidean on

drc check
drc catchup
puts $fp "DRC_FAST [drc list count total]"

drc style drc(full)
drc check
drc catchup
puts $fp "DRC_FULL [drc list count total]"
foreach v [drc listall why] { puts $fp "DRC_WHY $v" }

# --- extraction: turn geometry back into a circuit -------------------------
extract do local
extract all
ext2spice lvs
ext2spice -o sky130_fd_sc_hd__inv_1.lvs.spice
puts $fp "EXTRACTED sky130_fd_sc_hd__inv_1.lvs.spice"

close $fp
puts "inspect.tcl finished"
quit -noprompt
