# Lab 04 — the two blocks you are going to finish.
#
# `make scaffold` runs this and overwrites mag/my_buf.mag and mag/my_and2.mag,
# throwing away your work. Each one contains the two cells already abutted and
# the block's own power rails. What is missing is the wire between them and the
# labels that turn shapes into ports.

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }
proc place {cell inst x} { box ${x}um 0um ${x}um 0um; getcell $cell; identify $inst }

cd mag
addpath .

load my_buf -force
place my_inv inv1 0.0
place my_inv inv2 3.0
p m1 0.00 0.00 6.00 0.40
p m1 0.00 5.60 6.00 6.00
lab m1 2.60 0.05 2.85 0.30 VGND
lab m1 2.60 5.70 2.85 5.95 VPWR
select top cell
port makeall
save my_buf

load my_and2 -force
place my_nand2 nd0 0.0
place my_inv   in0 4.0
p m1 0.00 0.00 7.00 0.40
p m1 0.00 5.60 7.00 6.00
lab m1 3.60 0.05 3.85 0.30 VGND
lab m1 3.60 5.70 3.85 5.95 VPWR
select top cell
port makeall
save my_and2

puts "wrote mag/my_buf.mag and mag/my_and2.mag"
quit -noprompt
