# Capstone — the placement, and nothing else.
#
# `make scaffold` runs this and overwrites mag/datapath.mag, throwing away your
# routing. Four standard cells in one row, rails abutted, no wires.
#
# The circuit:      Q  = DFF(CLK, D)
#                   n1 = Q  AND A
#                   n2 = n1 AND B
#                   Y  = BUF(n2)
#
# Cell widths come out of each cell's own FIXED_BBOX property, in units of
# 0.005 um: dfxtp_1 is 1472 (7.36 um), and2_0 is 460 (2.30), buf_1 is 276
# (1.38). Put each cell at the running total and the VGND and VPWR rails line
# up into two continuous strips.

proc place {cell inst x} { box ${x}um 0um ${x}um 0um; getcell $cell; identify $inst }

cd mag
addpath $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/mag
load datapath -force

place sky130_fd_sc_hd__dfxtp_1 dff0   0.00
place sky130_fd_sc_hd__and2_0  and1   7.36
place sky130_fd_sc_hd__and2_0  and2   9.66
place sky130_fd_sc_hd__buf_1   buf0  11.96

select top cell
save datapath
puts "wrote mag/datapath.mag"
quit -noprompt
