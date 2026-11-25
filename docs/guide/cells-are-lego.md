# Instances and hierarchy

By the end of Lab 03 you have drawn an inverter by hand, and you aren't going to draw a million
more of them that way.

From here on the work is **instancing**: you place copies of finished cells next to each other
and draw the wires between them. The rest of a chip is built the same way, and that's possible
because the hard part, the transistors, is drawn only once. You'll compose your first two blocks
this way in [Lab 04](../labs/lab-04-buffer-and-and-overview.md).

## Placing an instance

In Magic you place an instance with the box and a menu. Left-click where the new instance should
go, which moves the box there, then choose `Cell → Place Instance` and pick the cell's `.mag` file
in the `Open` window. For a cell from the foundry's library, open `Options → Library Manager`
instead, select the cell and press `Place`. Either way the instance goes in at the box.

Once the DRC Manager has been open in a Magic session, opening the Library Manager moves the box
onto your whole cell, and `Cell → Place Instance` puts the instance in the wrong place as well. So
open the Library Manager first and set the box after it, as the capstone's
[Part 5](../labs/capstone-place-and-route-overview.md#part-5-add-the-tap-cells) does.

Magic names each new instance after its cell: `my_inv_0`, `my_inv_1`, and so on. LVS ignores
instance names, so you can leave them as they are. If you want a name of your own, select the
instance with `i` and type `identify` and the new name in the console.

An instance refers to `my_inv` rather than copying its geometry. Here is a new cell with two
instances of `my_inv` placed that way, at x = 0 and x = 3 µm, saved in `mag/` next to
`my_inv.mag`. The `.mag` file records each instance in four lines:

```
use my_inv  my_inv_0
timestamp 1787733743
transform 1 0 0 0 1 0
box 0 0 300 600
use my_inv  my_inv_1
timestamp 1787733743
transform 1 0 300 0 1 0
box 0 0 300 600
```

The `use` line names the cell and the instance. The `timestamp` is a copy of the one at the top
of `my_inv.mag`, `transform` puts the second cell's origin at x = 300, which is 3 µm in this
file's 0.01 µm units, and `box` is the outline of `my_inv` in its own coordinates. When the cell
is in another folder, the `use` line also names the folder to look in, and Magic writes it only on
the first `use` of each cell in a file: in Lab 04's `solutions/buf_ref.mag` the line for `inv1`
ends in `../mag` and the line for `inv2` doesn't. When the cell is in the same folder as the file
that uses it, as here and in Lab 04's `mag/my_buf.mag`, none of the `use` lines has a path.

Because every instance refers back to `my_inv.mag`, editing that one file changes all of them.
That's the reason to use instances, and it's also why Lab 04's blocks are only a few lines long.

## Abutment

Both of Lab 04's cells, `my_inv` and `my_nand2`, are **6.00 µm tall**, with their VGND rail at
y = 0.00–0.40 and their VPWR rail at y = 5.60–6.00. When you put the second cell at an x equal
to the width of the first, the two cells touch edge to edge, and:

- the two VGND rails become one continuous strip,
- the two VPWR rails become one continuous strip,
- the wells touch and merge,
- and the second cell has power without you drawing anything.

That is what makes a cell a **standard cell**: it keeps to a fixed height and fixed rail
positions, so that placing cells is just arithmetic.

The foundry's library keeps to a height of 2.72 µm and a site width of 0.46 µm, so every cell in
it is a multiple of 0.46 µm wide. The capstone's four cells sit at x = 0, 7.36, 9.66 and 11.96,
each one the running total of the widths of the cells before it, so their rails line up with
nothing more drawn.

## Hierarchy

In outline, Lab 04's buffer is two instances of `my_inv`, `inv1` at x = 0 and `inv2` at x = 3 µm,
one li wire from `inv1`'s output to `inv2`'s input, and four labels: A, X, VGND and VPWR. When you
extract it, you get this netlist:

```spice
.subckt my_buf A X VGND VPWR
Xinv1 A inv2/A VPWR VGND my_inv
Xinv2 inv2/A X VPWR VGND my_inv
.ends
```

At this level there are two instances and the net between them, and no devices at all. The
devices are inside `my_inv`, which is written out separately in the same file. netgen compares
hierarchically, so in one run it checks that `my_buf` is two `my_inv` in series *and* that
`my_inv` is the inverter it's supposed to be.

The AND gate uses the same idea with a different pair of cells, `my_nand2` feeding `my_inv`. An
AND gate has six transistors, and you don't draw any of them.

## Three common mistakes

**1. A label over a subcell's geometry names nothing.**

Say you have placed two inverters, and you want the block's input `A` on `inv1`'s input. You set
the box on `inv1`'s A pin, open `Edit → Text ...`, type `A`, tick `Port:` and click `Okay`. A label
always goes into the cell you're editing, so it lands in your cell, but the li under it is
geometry inside `inv1`, and your cell has nothing of its own there. So Magic puts the label on
empty space, without a word in the console, and a label on space isn't attached to any net. In
Lab 04's `my_buf`, extracting after that mistake gives `.subckt my_buf VGND VPWR`, with no `A`.
The same happens to a VGND or VPWR label put on a rail that belongs to the cells: your cell then comes out of extraction with no supply ports, and netgen
reports a pin-matching failure on a block that is otherwise perfect.

The fix is to give the top cell some geometry of its own to put the name on. Paint a small `li`
patch over the pin, or a metal1 rectangle over a rail (it's the same net, so it changes nothing
electrically), and put the label on that. Every composed block in this course does this, and the
solutions READMEs for Lab 04 and the capstone explain it as a decision you can break on purpose to
see what happens.

**2. The layers above a cell are not always empty.**

`and2_0` and `buf_1` contain metal1 only in their rails, but the flip-flop `dfxtp_1` also has
internal metal1 straps at y = 1.415–1.645 and 1.755–1.985, running most of its width. If you
route metal1 across the flip-flop without knowing that, you get `met1.2` spacing violations from
geometry you didn't draw.

That's why real routers carry a blockage map for every cell, and it's also why the capstone's `D`
pin takes its via at an unexpected place. Before you route over a cell, look at the metal1 it
already has, on screen or in the `<< metal1 >>` section of its `.mag` file; the capstone has you
do this.

**3. The path recorded in the `.mag` file is relative to where you saved it.**

`use my_inv  inv1 ../mag` means "look in `../mag`, starting from the folder this `.mag` file is
in", rather than from the folder you started Magic in. That's why Lab 04's
`solutions/buf_ref.mag` still finds `my_inv` in the lab's `mag/`. If you move the file to a folder
with no `../mag` next to it, though, Magic can't find the cell: it prints a `couldn't be read`
error for `my_inv.mag`, and the instance shows up as an empty box with a name in it. The lab
scripts in `tcl/` have a related trap with `addpath`, which the
[Magic cheat sheet](../reference/magic-cheatsheet.md#batch-scripts) explains.

## What a place-and-route tool does

Placement and routing were the first parts of layout to be automated, and they are the most
thoroughly automated, because the job is enormous and it's arithmetic. In a real flow,

1. synthesis picks a cell for each gate in the netlist, choosing drive strengths,
2. the place-and-route tool finds legal positions in rows for every one of them,
3. inserts tap cells and filler,
4. routes hundreds of thousands of nets on five metal layers,
5. and then checks its own work with the same DRC and LVS you are running.

In [DD103](https://uoftasic.com/dd103/) that whole flow runs in **about a minute** on a small
design, and DD103's own pages time it at 57 s for the vending machine and 59 s for the elevator.
Placing four cells and routing three wires by hand in the capstone is no substitute for that
tool, but it does show you what the tool's output is a picture of.
