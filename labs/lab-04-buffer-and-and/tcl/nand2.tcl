# Lab 04 — the 2-input NAND, drawn the same way you drew the inverter.
#
# `make cells` runs this and writes mag/my_nand2.mag (and re-writes
# mag/my_inv.mag from the Lab 03 reference). Read it: the one idea that is not
# in the inverter is the shared diffusion between the two NMOS devices.
#
#   NMOS in series : two poly stripes crossing ONE strip of ndiff. The middle
#                    region between them is the internal node. It gets no
#                    contact at all - the two devices share the silicon.
#   PMOS in parallel: two poly stripes crossing ONE strip of pdiff, with the
#                    middle region contacted and taken to Y.
#
# That is the whole trick of full-custom layout: series devices abut, parallel
# devices alternate, and a contact you do not place is area and capacitance you
# do not pay for.

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }

cd mag
load my_nand2 -force

p nwell 0.00 3.00 4.00 6.00
p pwell 0.00 0.00 4.00 3.00

# --- NMOS pair, in series: W = 0.65, L = 0.15 -----------------------------
# One diffusion strip, two gates. Contacts only at the two ends.
p ndiff 0.40 1.30 3.60 1.95
p ndc   0.55 1.55 0.72 1.72     ;# left end  -> VGND
p ndc   3.28 1.55 3.45 1.72     ;# right end -> Y
#   ... and deliberately nothing between 1.50 and 2.45.

# --- PMOS pair, in parallel: W = 1.00, L = 0.15 ---------------------------
p pdiff 0.40 3.50 3.60 4.50
p pdc   0.55 3.90 0.72 4.07     ;# source -> VPWR
p pdc   1.87 3.90 2.04 4.07     ;# shared drain -> Y
p pdc   3.28 3.90 3.45 4.07     ;# source -> VPWR
p pfethvt 1.35 3.50 1.50 4.50
p pfethvt 2.45 3.50 2.60 4.50

# --- the two gates --------------------------------------------------------
p poly 1.35 1.05 1.50 4.75
p poly 1.20 2.30 1.65 2.75
p pc   1.34 2.44 1.51 2.61
p poly 2.45 1.05 2.60 4.75
p poly 2.30 2.30 2.75 2.75
p pc   2.44 2.44 2.61 2.61

# --- taps -----------------------------------------------------------------
p ptap  0.40 0.35 3.60 0.85
p ptapc 0.55 0.52 0.72 0.69
p ntap  0.40 5.05 3.60 5.55
p ntapc 0.55 5.22 0.72 5.39
p ntapc 3.28 5.22 3.45 5.39

# --- local interconnect ---------------------------------------------------
p li 0.45 0.05 0.82 1.82        ;# VGND
p li 0.45 3.80 0.82 5.95        ;# VPWR, left
p li 3.18 3.80 3.55 5.49        ;# VPWR, right
p li 1.79 2.95 2.12 4.17        ;# Y: down from the shared PMOS drain
p li 1.79 2.95 3.53 3.28        ;# Y: across
p li 3.20 1.45 3.53 3.28        ;# Y: down to the NMOS drain
p li 1.24 2.34 1.61 2.71        ;# A
p li 2.34 2.34 2.71 2.71        ;# B

# --- rails ----------------------------------------------------------------
p m1   0.00 0.00 4.00 0.40
p m1   0.00 5.60 4.00 6.00
p mcon 0.55 0.13 0.72 0.30
p mcon 0.55 5.70 0.72 5.87

lab li 1.30 2.40 1.55 2.65 A
lab li 2.40 2.40 2.65 2.65 B
lab li 3.25 2.00 3.48 2.25 Y
lab m1 1.60 5.70 1.85 5.95 VPWR
lab m1 1.60 0.05 1.85 0.30 VGND

select top cell
port makeall
save my_nand2
puts "wrote mag/my_nand2.mag"
quit -noprompt
