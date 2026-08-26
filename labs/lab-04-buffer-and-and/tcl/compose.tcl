# Lab 04 — the reference buffer and AND, for `make ref`.
#
# Writes solutions/buf_ref.mag and solutions/and_ref.mag. Both are two cells
# placed side by side and one li wire between them. That is the whole job.
#
# Abutment works because both my_inv and my_nand2 are 6.00 um tall with their
# VGND rail at y = 0.00..0.40 and their VPWR rail at y = 5.60..6.00. Put the
# second cell at x = (width of the first) and the rails line up into one
# continuous strip, the wells merge, and you have not drawn a single via.

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }
proc place {cell inst x} { box ${x}um 0um ${x}um 0um; getcell $cell; identify $inst }

cd solutions
addpath ../mag

# ---------------------------------------------- BUFFER = INV -> INV
load buf_ref -force
place my_inv inv1 0.0
place my_inv inv2 3.0
p li 2.18 2.40 4.61 2.65     ;# inv1/Y across to inv2/A
p m1 0.00 0.00 6.00 0.40     ;# the block's own rails, over the row
p m1 0.00 5.60 6.00 6.00
p li 1.30 2.40 1.55 2.65     ;# a patch to hang the A label on
p li 5.20 2.42 5.45 2.67     ;# and one for X
lab li 1.30 2.40 1.55 2.65 A
lab li 5.20 2.42 5.45 2.67 X
lab m1 2.60 0.05 2.85 0.30 VGND
lab m1 2.60 5.70 2.85 5.95 VPWR
select top cell
port makeall
save buf_ref

# ---------------------------------------------- AND = NAND2 -> INV
load and_ref -force
place my_nand2 nd0 0.0
place my_inv   in0 4.0
p li 3.20 2.40 5.61 2.65     ;# nd0/Y across to in0/A
p m1 0.00 0.00 7.00 0.40
p m1 0.00 5.60 7.00 6.00
p li 1.30 2.40 1.55 2.65
p li 2.40 2.40 2.65 2.65
p li 6.20 2.42 6.45 2.67
lab li 1.30 2.40 1.55 2.65 A
lab li 2.40 2.40 2.65 2.65 B
lab li 6.20 2.42 6.45 2.67 X
lab m1 3.60 0.05 3.85 0.30 VGND
lab m1 3.60 5.70 3.85 5.95 VPWR
select top cell
port makeall
save and_ref

puts "wrote solutions/buf_ref.mag and solutions/and_ref.mag"
quit -noprompt
