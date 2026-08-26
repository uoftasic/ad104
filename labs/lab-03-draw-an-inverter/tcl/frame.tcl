# Lab 03 — the frame you start from.
#
# `make scaffold` runs this and overwrites mag/my_inv.mag. It draws everything
# that is not a transistor: the two wells, the two supply rails, and the two
# well taps that tie the wells to those rails. Your job is the middle.
#
# Every command here is one you can type into Magic's tkcon console. `box`
# takes microns when you write the unit; `paint` fills the box with a layer.

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }

cd mag
load my_inv -force

# --- the two wells --------------------------------------------------------
# nwell is where PMOS lives. Everything below it is p-substrate.
p nwell 0.00 3.00 3.00 6.00
p pwell 0.00 0.00 3.00 3.00

# --- the supply rails, in metal1 ------------------------------------------
p m1 0.00 0.00 3.00 0.40
p m1 0.00 5.60 3.00 6.00

# --- the well taps --------------------------------------------------------
# A tap is a heavily doped contact to the well itself, so the well sits at a
# known voltage instead of floating. ptap ties the p-substrate to VGND;
# ntap ties the nwell to VPWR. Without them the transistor bodies float and
# the full DRC rule set says so (nwell.4, LU.2, LU.3).
p ptap  0.40 0.35 2.60 0.85
p ptapc 0.55 0.52 0.72 0.69
p ntap  0.40 5.05 2.60 5.55
p ntapc 0.55 5.22 0.72 5.39

# --- li stubs and the vias up to the rails --------------------------------
# li (local interconnect) is the lowest wiring layer. mcon is the via from li
# up to metal1. You will extend both li strips towards the middle of the cell.
p li   0.45 0.05 0.82 0.95
p mcon 0.55 0.13 0.72 0.30
p li   0.45 5.05 0.82 5.95
p mcon 0.55 5.70 0.72 5.87

lab m1 1.20 0.05 1.45 0.30 VGND
lab m1 1.20 5.70 1.45 5.95 VPWR

select top cell
port makeall
save my_inv
puts "wrote mag/my_inv.mag"
quit -noprompt
