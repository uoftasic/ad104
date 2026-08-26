# Cells are Lego

You have drawn an inverter. You are not going to draw a million of them.

Everything from here is **instancing**: putting copies of finished cells next
to each other and wiring between them. The rest of a chip is this, and the
reason a chip is possible at all is that the hard part — the transistors — is
done once.

## Placing

In Magic, from the console:

```tcl
addpath ../mag                    ;# where to look for cells
box 3um 0um 3um 0um               ;# a zero-size box at the spot you want
getcell my_inv                    ;# drop a copy with its origin there
identify inv2                     ;# give this copy a name
```

`getcell` places an **instance**, not a copy of the geometry. The `.mag` file
records one line:

```
use my_inv  inv2 ../mag
transform 1 0 300 0 1 0
box -19 -24 249 296
```

Edit `my_inv.mag` and every instance changes. That is the whole point, and it
is also why Lab 04's blocks are three lines long.

## Abutment: the rails do the work

Both cells you drew in this course are **6.00 µm tall**, with their VGND rail
at y = 0.00–0.40 and their VPWR rail at y = 5.60–6.00. So if you put the
second cell at x = the width of the first:

- the two VGND rails become one continuous strip,
- the two VPWR rails become one continuous strip,
- the wells touch and merge,
- and you have connected power to a second cell without drawing anything.

That is what a standard cell **is**: a layout that has agreed to a fixed height
and a fixed rail position so that placement is just arithmetic.

The foundry library agrees to 2.72 µm and a 0.46 µm site width, so every cell
in it is a multiple of 0.46 wide. In the capstone you place four of them at
x = 0, 7.36, 9.66 and 11.96 — a running total of their widths — and the rails
line up on their own.

## Hierarchy: a buffer has no transistors

```tcl
load my_buf
place my_inv inv1 0.0
place my_inv inv2 3.0
paint li from inv1/Y across to inv2/A
label A, label X, label VGND, label VPWR
```

Extract that and you get:

```spice
.subckt my_buf A X VGND VPWR
Xinv1 A inv2/A VPWR VGND my_inv
Xinv2 inv2/A X VPWR VGND my_inv
.ends
```

Two instances and a net. No devices at this level at all — they are inside
`my_inv`, which is written out separately in the same file. netgen compares
hierarchically, so it checks that `my_buf` is two `my_inv` in series *and*
that `my_inv` is the inverter it is supposed to be, in one run.

The AND gate is the same trick with a different pair: `my_nand2` feeding
`my_inv`. An AND gate has six transistors and you draw none of them.

## The three things that bite

**1. A label on a subcell's geometry belongs to the subcell.**

You place two cells, abut them, and the rails connect. Now put the box over the
rail and type `label VGND`. Nothing you wanted happens: the rail belongs to
`inv1`, so the label belongs to `inv1`, and *your* cell comes out of extraction
with no supply ports at all. Netgen then reports a pin-matching failure on a
block that is otherwise perfect.

The fix is to give the top cell its own geometry to name. Paint a metal1
rectangle over the row — electrically redundant, it is the same net — and put
the label on that. Every composed block in this course does it, and the
solutions README explains it as a decision you can go and break on purpose.

**2. Not every layer above a cell is free.**

`and2_0` and `buf_1` contain metal1 only in their rails. **`dfxtp_1` does
not** — the flip-flop has internal metal1 straps at y = 1.415–1.645 and
1.755–1.985 running most of its width. Route metal1 across the flip-flop
without knowing that and you get `met1.2` spacing violations from geometry you
did not draw.

This is why real routers carry a blockage map for every cell, and why the
capstone's `D` pin has to take its via at an unexpected place. `grep` the
`<< metal1 >>` section of a cell's `.mag` before routing over it.

**3. The path recorded in the `.mag` is relative to where you saved it.**

`use my_inv inv2 ../mag` means "look in `../mag` from wherever you are". Move
the file, or run Magic from a different directory, and the instance is
unresolvable — you get an empty box with a name in it. The labs handle this
by always `cd`-ing to a known directory first and setting `addpath` after,
which is a rule worth copying: **`cd` first, `addpath` second.**

## What the machine does instead

Placement and routing is the thing that got automated first and hardest,
because it is enormous and it is arithmetic. A real flow:

1. picks a cell for each gate in the netlist, choosing drive strengths,
2. finds legal positions in rows for every one of them,
3. inserts tap cells and filler,
4. routes hundreds of thousands of nets on five metal layers,
5. and then checks its own work with the same DRC and LVS you are running.

In [DD103](https://uoftasic.com/dd103/) that whole flow runs in **54 seconds**
on a small design. Doing four cells and three wires by hand in the capstone is
not a substitute for it. It is so that when you look at the tool's output you
know what it is a picture of.
