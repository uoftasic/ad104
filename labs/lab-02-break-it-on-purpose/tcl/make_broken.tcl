# Lab 02 — build the five broken cells.
#
# `make reset` runs this and overwrites mag/drc_0*.mag, throwing away your
# fixes. Each cell is the Lab 03 reference inverter with exactly one number
# changed, and the change is marked BREAK below.
#
# Read this file after you have found all five yourself. It is the answer key.

proc p {layer x1 y1 x2 y2} { box ${x1}um ${y1}um ${x2}um ${y2}um; paint $layer }
proc lab {layer x1 y1 x2 y2 name} { box ${x1}um ${y1}um ${x2}um ${y2}um; label $name c $layer }
proc pr {layer r} { p $layer [lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3] }

# base  nwell-rect  poly-pad-rect  A-li-rect  have-ntap-contact
proc base {nw pad lia tapc} {
    pr nwell $nw
    p pwell 0.00 0.00 3.00 3.00
    p m1 0.00 0.00 3.00 0.40
    p m1 0.00 5.60 3.00 6.00
    p ptap  0.40 0.35 2.60 0.85
    p ptapc 0.55 0.52 0.72 0.69
    p ntap  0.40 5.05 2.60 5.55
    if {$tapc} { p ntapc 0.55 5.22 0.72 5.39 }
    p mcon 0.55 0.13 0.72 0.30
    p mcon 0.55 5.70 0.72 5.87

    p ndiff 0.40 1.30 2.60 1.95
    p ndc   0.55 1.55 0.72 1.72
    p ndc   2.28 1.55 2.45 1.72
    p pdiff 0.40 3.50 2.60 4.50
    p pdc   0.55 3.90 0.72 4.07
    p pdc   2.28 3.90 2.45 4.07
    p pfethvt 1.35 3.50 1.50 4.50

    p poly 1.35 1.05 1.50 4.75
    pr poly $pad
    p pc   1.34 2.44 1.51 2.61

    p li 0.45 0.05 0.82 1.82
    p li 2.18 1.45 2.55 4.17
    p li 0.45 3.80 0.82 5.95
    pr li $lia

    lab li [expr {[lindex $lia 0]+0.02}] [expr {[lindex $lia 1]+0.02}] \
           [expr {[lindex $lia 0]+0.15}] [expr {[lindex $lia 1]+0.15}] A
    lab li 2.25 2.60 2.50 2.85 Y
    lab m1 1.20 5.70 1.45 5.95 VPWR
    lab m1 1.20 0.05 1.45 0.30 VGND
    select top cell
    port makeall
}

set NW   {0.00 3.00 3.00 6.00}
set PAD  {1.20 2.30 1.65 2.75}
set LIA  {1.24 2.34 1.61 2.71}

cd mag

# 1 -- BREAK: the nwell bottom edge raised to 3.40, so it clears the PMOS
#     diffusion by only 0.10 um.  Correct is 3.00.
load drc_01 -force
base {0.00 3.40 3.00 6.00} $PAD $LIA 1
save drc_01

# 2 -- BREAK: the li over the poly contact shifted so it lines up with the
#     cut on two sides instead of overhanging it.  Correct is the LIA above.
load drc_02 -force
base $NW $PAD {1.34 2.44 1.60 2.75} 1
save drc_02

# 3 -- BREAK: the poly landing pad shrunk to 0.25 x 0.25, leaving 0.04 um of
#     poly around the cut.  Correct is the PAD above.
load drc_03 -force
base $NW {1.30 2.40 1.55 2.65} $LIA 1
save drc_03

# 4 -- BREAK: the A pad widened to 2.08 until it nearly touches the Y wire,
#     which starts at 2.18.  Correct right edge is 1.61.
load drc_04 -force
base $NW $PAD {1.24 2.34 2.08 2.71} 1
save drc_04

# 5 -- BREAK: the nwell tap has no contact on it, so nothing ties the well to
#     VPWR.  This one is invisible to the default rule set.
load drc_05 -force
base $NW $PAD $LIA 0
save drc_05

puts "wrote five broken cells"
quit -noprompt
