# Instances and hierarchy

After Lab 03 you have drawn an inverter. You are not going to draw a million of them.

From here on the work is **instancing**: placing copies of finished cells next to each other and
wiring between them. The rest of a chip is built this way, and it is possible because the hard
part, the transistors, is drawn once. You compose your first two blocks this way in
[Lab 04](../labs/lab-04-buffer-and-and-overview.md).

## Placing an instance

In Magic, from the console:

```tcl
addpath ../mag                    ;# where to look for cells
box 3um 0um 3um 0um               ;# a zero-size box at the spot you want
getcell my_inv                    ;# drop a copy with its origin there
identify inv2                     ;# give this copy a name
```

`getcell` places an **instance**, not a copy of the geometry. The `.mag` file records it in three
lines:

```
use my_inv  inv2 ../mag
transform 1 0 300 0 1 0
box -19 -24 249 296
```

Edit `my_inv.mag` and every instance changes. That is the reason to use instances, and it is why
Lab 04's blocks are only a few lines long.

## Abutment

Both of Lab 04's cells, `my_inv` and `my_nand2`, are **6.00 µm tall**, with their VGND rail at
y = 0.00–0.40 and their VPWR rail at y = 5.60–6.00. Put the second cell at x = the width of the
first, and:

- the two VGND rails become one continuous strip,
- the two VPWR rails become one continuous strip,
- the wells touch and merge,
- and the second cell has power without you drawing anything.

That is what makes a cell a **standard cell**: it agrees to a fixed height and a fixed rail
position, so that placement is just arithmetic.

The foundry library agrees to 2.72 µm and a 0.46 µm site width, so every cell in it is a
multiple of 0.46 µm wide. In the capstone you place four of them at x = 0, 7.36, 9.66 and 11.96,
a running total of their widths, and the rails line up on their own.

## Hierarchy

In outline, Lab 04's buffer is:

```tcl
load my_buf
place my_inv inv1 0.0
place my_inv inv2 3.0
paint li from inv1/Y across to inv2/A
label A, label X, label VGND, label VPWR
```

Extract it and you get:

```spice
.subckt my_buf A X VGND VPWR
Xinv1 A inv2/A VPWR VGND my_inv
Xinv2 inv2/A X VPWR VGND my_inv
.ends
```

Two instances and a net, and no devices at this level at all. The devices are inside `my_inv`,
which is written out separately in the same file. netgen compares hierarchically, so in one run
it checks that `my_buf` is two `my_inv` in series *and* that `my_inv` is the inverter it is
supposed to be.

The AND gate is the same idea with a different pair: `my_nand2` feeding `my_inv`. An AND gate has
six transistors and you draw none of them.

## Three common mistakes

**1. A label on a subcell's geometry belongs to the subcell.**

You place two cells and abut them, and the rails connect. Then you put the box over a rail and
type `label VGND`. The rail belongs to `inv1`, so the label belongs to `inv1`, and *your* cell
comes out of extraction with no supply ports at all. Netgen then reports a pin-matching failure on
a block that is otherwise perfect.

The fix is to give the top cell geometry of its own to name. Paint a metal1 rectangle over the
row (it is the same net, so it changes nothing electrically) and put the label on that. Every
composed block in this course does this, and the solutions READMEs for Lab 04 and the capstone
explain it as a decision you can break on purpose to see what happens.

**2. The layers above a cell are not always empty.**

`and2_0` and `buf_1` contain metal1 only in their rails. **`dfxtp_1` does not**: the flip-flop
has internal metal1 straps at y = 1.415–1.645 and 1.755–1.985 running most of its width. Route
metal1 across the flip-flop without knowing that, and you get `met1.2` spacing violations from
geometry you did not draw.

This is why real routers carry a blockage map for every cell, and why the capstone's `D` pin
takes its via at an unexpected place. Before routing over a cell, read the `<< metal1 >>` section
of its `.mag` file; the capstone has you do this.

**3. The path recorded in the `.mag` file is relative to where you saved it.**

`use my_inv inv2 ../mag` means "look in `../mag` from wherever you are". Move the file, or run
Magic from a different directory, and the instance cannot be found: you get an empty box with a
name in it. The labs avoid this by always changing to a known directory first and setting
`addpath` after. That order is worth copying: **`cd` first, `addpath` second.**

## What a place-and-route tool does

Placement and routing were automated first and most thoroughly, because the job is enormous and
it is arithmetic. A real flow:

1. picks a cell for each gate in the netlist, choosing drive strengths,
2. finds legal positions in rows for every one of them,
3. inserts tap cells and filler,
4. routes hundreds of thousands of nets on five metal layers,
5. and then checks its own work with the same DRC and LVS you are running.

In [DD103](https://uoftasic.com/dd103/) that whole flow runs in **about a minute** on a small
design; its own pages time it at 57 s for the vending machine and 59 s for the elevator. Placing
four cells and routing three wires by hand in the capstone does not replace that tool. It shows
you what the tool's output is a picture of.
