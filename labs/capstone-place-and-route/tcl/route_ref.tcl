# Capstone — the reference: the same four cells, routed.
#
# `make ref` runs this and writes solutions/datapath_ref.mag.
#
# Three nets to route, all on metal1, all in the band between the two rails.
# The rails occupy y = -0.24..0.24 and y = 2.48..2.96, and met1 has to keep
# 0.14 um from anything it is not connected to, so every wire here lives
# between y = 0.38 and y = 2.34.
#
# Each connection is: an `mcon` on the cell's li pin, a metal1 pad around it,
# and metal1 from there to the next pad. A metal1 pad has to surround its mcon
# by 0.03 um everywhere and by 0.06 um on both sides of at least one axis
# (met1.4 and met1.5), which is why every pad below is 0.29 um wide for a
# 0.17 um cut.
#
# The pin coordinates are the flabel rectangles in each cell's .mag file, plus
# the x offset the cell was placed at.

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }
proc place {cell inst x} { box ${x}um 0um ${x}um 0um; getcell $cell; identify $inst }

cd solutions
addpath $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/mag
load datapath_ref -force

place sky130_fd_sc_hd__dfxtp_1 dff0   0.00
place sky130_fd_sc_hd__and2_0  and1   7.36
place sky130_fd_sc_hd__and2_0  and2   9.66
place sky130_fd_sc_hd__buf_1   buf0  11.96

# --- net Q : dff0/Q -> and1/A ---------------------------------------------
p mcon 6.950 0.425 7.120 0.595
p mcon 7.505 1.785 7.675 1.955
p m1   6.890 0.395 7.180 1.985
p m1   6.890 1.755 7.735 1.985

# --- net n1 : and1/X -> and2/A --------------------------------------------
p mcon 9.345 2.125 9.515 2.295
p mcon 9.805 1.785 9.975 1.955
p m1   9.285 1.755 9.575 2.325
p m1   9.285 1.755 10.035 1.985

# --- net n2 : and2/X -> buf0/A --------------------------------------------
p mcon 11.645 2.125 11.815 2.295
p mcon 12.105 1.105 12.275 1.275
p m1   11.585 1.075 11.875 2.325
p m1   11.585 1.075 12.335 1.305

# --- the block's own pins --------------------------------------------------
# CLK and D come off the flip-flop's li pins. D is the awkward one: the
# flip-flop has its own metal1 straps at y = 1.415..1.645 and 1.755..1.985,
# so a pad at the D label would be 0.07 um from one of them. The D pin's li
# runs all the way down to y = 0.715, so the mcon goes down there instead.
p mcon 0.145 1.105 0.315 1.275
p m1   0.075 1.035 0.385 1.345
p mcon 1.400 0.800 1.570 0.970
p m1   1.330 0.740 1.640 1.030
p mcon 8.425 1.445 8.595 1.615
p m1   8.355 1.375 8.665 1.685
p mcon 10.725 1.445 10.895 1.615
p m1   10.655 1.375 10.965 1.685
p mcon 13.015 1.785 13.185 1.955
p m1   12.945 1.715 13.255 2.025

# --- well taps, one at each end of the row ---------------------------------
place sky130_fd_sc_hd__tapvpwrvgnd_1 tapL -0.46
place sky130_fd_sc_hd__tapvpwrvgnd_1 tapR 13.34

# --- the block's own rails, so VGND and VPWR are ports of THIS cell --------
p m1 -0.46 -0.24 13.80 0.24
p m1 -0.46  2.48 13.80 2.96

lab m1  0.10 1.10  0.36 1.30 CLK
lab m1  1.36 0.79  1.61 0.99 D
lab m1  8.38 1.44  8.64 1.64 A
lab m1 10.68 1.44 10.94 1.64 B
lab m1 12.97 1.78 13.23 1.98 Y
lab m1  3.00 -0.20 3.30 0.20 VGND
lab m1  3.00  2.52 3.30 2.92 VPWR

select top cell
port makeall
save datapath_ref
puts "wrote solutions/datapath_ref.mag"
quit -noprompt
