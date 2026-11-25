# Lab 04 - the reference generated inverter, for `make ref`.
#
# Writes solutions/inv_gen_ref.mag and the two device cells it uses. The
# transistors come from Magic's own device generator, called from Tcl with the
# parameters a student types into the Devices 1 dialog:
#
#   magic::gencell sky130::<device> <instance> <parameter> <value> ...
#
# places one device with its abutment box's lower-left corner at the box, the
# same as the dialog's Create button does. The generator names each device cell
# after a hash of its parameters (sky130_fd_pr__nfet_01v8_HFW449), so this
# script never types those names.
#
# The options are the ones the lab ends with: the nmos without its bottom gate
# contact and the pmos without its top one, because the inverter uses only the
# two pads that face each other. An unused pad is a lone 0.29 x 0.23 um piece of
# metal1, below metal1's minimum area (met1.6).
#
# The wiring, with the device centres at (1.4, 1.4) and (1.4, 4.6):
#   A     metal1 from the nmos gate pad up to the pmos gate pad
#   Y     the two drains (the left strips) joined in metal1 round the left side
#   S     each source (the right strip) tied to its guard ring in li
#   rails an mcon on each guard ring's outer li strip, under a metal1 rail
# Every label sits on metal1 drawn in this cell, because a label over a
# subcell's shape names nothing (Part 3 of the lab).

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }

cd solutions
load inv_gen_ref -force

# The nmos abutment box is 1.58 x 1.91 um and the pmos's 1.58 x 2.31 um, so
# these corners put the device centres at (1.4, 1.4) and (1.4, 4.6).
box 0.61um 0.445um 0.61um 0.445um
magic::gencell sky130::sky130_fd_pr__nfet_01v8 n0 w 0.65 l 0.15 nf 1 botc 0
box 0.61um 3.445um 0.61um 3.445um
magic::gencell sky130::sky130_fd_pr__pfet_01v8_hvt p0 w 1 l 0.15 nf 1 topc 0

p m1   1.255 1.910 1.545 3.895    ;# A: nmos gate pad up to pmos gate pad
p m1   0.000 1.145 1.295 1.345    ;# Y: from the nmos drain strip to the left
p m1   0.000 1.145 0.230 4.880    ;#    up the left side
p m1   0.000 4.680 1.295 4.880    ;#    and into the pmos drain strip
p li   1.535 1.145 2.275 1.345    ;# nmos source strip to its guard ring
p li   1.535 4.680 2.275 4.880    ;# pmos source strip to its guard ring
p mcon 2.000 0.360 2.170 0.530    ;# on the nmos ring's bottom li strip
p m1   0.000 0.155 2.800 0.605    ;# VGND rail
p mcon 2.000 5.670 2.170 5.840    ;# on the pmos ring's top li strip
p m1   0.000 5.620 2.800 6.070    ;# VPWR rail

lab m1 1.300 2.800 1.500 3.000 A
lab m1 0.015 2.900 0.215 3.100 Y
lab m1 0.200 0.280 0.400 0.480 VGND
lab m1 0.200 5.720 0.400 5.920 VPWR
select top cell
port makeall

# writeall, not save: the two device cells are new as well
writeall force
puts "wrote solutions/inv_gen_ref.mag and its device cells"
quit -noprompt
