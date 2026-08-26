# Lab 03 — the reference inverter, drawn command by command.
#
# `make ref` runs this and writes mag/my_inv.mag. Read it after you
# have drawn yours, not before. Every line is a command you could type into
# Magic's tkcon console, in this order.
#
# Sizes: Wn = 0.65 um, Wp = 1.00 um, L = 0.15 um. Those are the foundry's own
# sky130_fd_sc_hd__inv_1 numbers, on purpose: in Lab 05 you compare your cell
# against theirs, and holding the transistors identical means the only thing
# left to compare is the drawing.

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }

cd mag
load my_inv -force

# ---------------------------------------------------------------- the frame
p nwell 0.00 3.00 3.00 6.00
p pwell 0.00 0.00 3.00 3.00
p m1 0.00 0.00 3.00 0.40
p m1 0.00 5.60 3.00 6.00
p ptap  0.40 0.35 2.60 0.85
p ptapc 0.55 0.52 0.72 0.69
p ntap  0.40 5.05 2.60 5.55
p ntapc 0.55 5.22 0.72 5.39
p mcon 0.55 0.13 0.72 0.30
p mcon 0.55 5.70 0.72 5.87

# ------------------------------------------------------------------- NMOS
# 2.20 um of diffusion, 0.65 um tall. The height IS W.
p ndiff 0.40 1.30 2.60 1.95
# Two contacts, each exactly 0.17 x 0.17 (licon.1 says so), inset far enough
# that diffusion surrounds each one by at least 0.06 um (licon.5c).
p ndc   0.55 1.55 0.72 1.72
p ndc   2.28 1.55 2.45 1.72

# ------------------------------------------------------------------- PMOS
# 1.00 um tall, and inside the nwell with room to spare.
p pdiff 0.40 3.50 2.60 4.50
p pdc   0.55 3.90 0.72 4.07
p pdc   2.28 3.90 2.45 4.07
# The foundry's PMOS is the high-Vt flavour. Painting pfethvt over the gate
# region is what turns sky130_fd_pr__pfet_01v8 into ..._pfet_01v8_hvt.
p pfethvt 1.35 3.50 1.50 4.50

# ------------------------------------------------------ the gate: one stripe
# 0.15 um wide - the width of this stripe IS L - crossing both diffusions and
# overhanging each by 0.25 um so the channel cannot leak round the end.
p poly 1.35 1.05 1.50 4.75
# A landing pad, because a poly contact needs 0.17 um of cut plus 0.05 um of
# poly around it (licon.8) and the gate stripe is only 0.15 um wide.
p poly 1.20 2.30 1.65 2.75
p pc   1.34 2.44 1.51 2.61

# -------------------------------------------------------- local interconnect
p li 0.45 0.05 0.82 1.82   ;# VGND : tap -> NMOS source
p li 2.18 1.45 2.55 4.17   ;# Y    : NMOS drain -> PMOS drain
p li 0.45 3.80 0.82 5.95   ;# VPWR : PMOS source -> tap
p li 1.24 2.34 1.61 2.71   ;# A    : the gate

# ------------------------------------------------------------------- labels
lab li 1.30 2.40 1.55 2.65 A
lab li 2.25 2.60 2.50 2.85 Y
lab m1 1.20 5.70 1.45 5.95 VPWR
lab m1 1.20 0.05 1.45 0.30 VGND

select top cell
port makeall
save my_inv
puts "wrote mag/my_inv.mag"
quit -noprompt
