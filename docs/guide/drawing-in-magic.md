# Drawing in Magic

Magic is built around one idea, and once you have it the rest is vocabulary: **there is a box,
you move the box, and you tell a layer to fill the box.** That is painting. Everything else,
including contacts, labels, ports and zooming, is done to the box or with it.

This page explains the commands you'll use from Lab 02 onwards. You draw your first cell with
them in [Lab 03](../labs/lab-03-draw-an-inverter-overview.md).

## The mouse

| | |
|---|---|
| **Left** | move the **lower-left** corner of the box to the cursor |
| **Right** | move the **upper-right** corner of the box to the cursor |
| **Middle** | **paint** the box with the layer under the cursor, or **erase** if the cursor is over empty space |

So you draw a rectangle by left-clicking one corner, right-clicking the other, and middle-clicking
a swatch of the layer you want in the palette down the right side. There is no click-and-drag.
The first hour is annoying, and after that it is faster than dragging.

If you have no middle button, or you want exact coordinates, type the command instead. In this
course you always want exact coordinates.

## The console

Magic's second window, `tkcon`, is where you type commands. Everything below is typed there.

```tcl
box 0.4um 1.3um 2.6um 1.95um     ;# put the box at these micron coordinates
paint ndiff                      ;# fill it with n-diffusion
erase ndiff                      ;# or take it away again
```

**Use the `um` suffix.** Without it Magic reads numbers in *lambda* (0.01 µm here), and the
difference is a factor of a hundred with no error message. Every command in every lab writes
`um`, and so should you.

Two more you'll use constantly:

```tcl
box values                       ;# what is the box now? (in internal units, 0.005 um)
findbox zoom                     ;# zoom the view to the box
```

`box values` **reads back in internal units of 0.005 µm**, even though plain numbers *set* the
box in lambda. That inconsistency has cost people afternoons. Set the box with `um`, and read the
numbers `box values` returns as 200 per micron.

## Layer names

The palette on the right shows display names; the console takes short aliases. These are the
ones this course uses:

| Console name | Palette | What it is |
|---|---|---|
| `nwell`, `pwell` | nwell, pwell | the wells |
| `ndiff`, `pdiff` | ndiffusion, pdiffusion | source/drain silicon |
| `ntap`, `ptap` | nsubstratendiff, psubstratepdiff | well and substrate taps |
| `ndc`, `pdc` | ndcontact, pdcontact | contact from diffusion up to li |
| `ntapc`, `ptapc` | nsubstratencontact, psubstratepcontact | contact from a tap up to li |
| `poly` | polysilicon | the gate layer |
| `pc` | pcontact | contact from poly up to li |
| `li` | locali | local interconnect |
| `mcon` | viali | contact from li up to metal1 |
| `m1`, `m2` | metal1, metal2 | wiring |
| `via1` | m2contact | metal1 to metal2 |
| `pfethvt` | pfethvt | makes a PMOS the high-threshold flavour |

`tech layers` prints the full list with every alias.

## Contact layers

This surprises everyone who is new to Magic. You don't place a contact as an object. You
**paint the contact layer over an area**, and Magic treats that region as the whole stack:
diffusion, the cut, and the local interconnect on top, all at once. `paint ndc` over a
0.17 × 0.17 µm box gives you one properly formed n-diffusion contact.

Some consequences, before they confuse you:

- The contact region must be **exactly 0.17 µm** in each direction for a single cut
  (`licon.1`). Make it bigger and Magic generates an array of cuts.
- The plain layers around it still have to surround it. Diffusion has to extend past the
  contact, and so does li; the rules for those are `licon.5c` and `li.5`, two of the five you
  fix in Lab 02.
- Erasing `li` from a contact does not remove the contact; it demotes it.

## Labels and ports

A shape with no name is invisible to LVS. Two commands name things:

```tcl
box 1.30um 2.40um 1.55um 2.65um
label A c li          ;# put the label "A", centred, on the li layer here

select top cell
port makeall          ;# promote every label in the cell to a port
```

`label` names a piece of geometry. `port makeall` declares those names to be the cell's
terminals, which is what makes the extracted netlist come out as `.subckt my_inv A Y VPWR VGND`
instead of a subcircuit with no pins. Every lab step that adds labels ends with `port makeall`. If
netgen ever says a cell's pin list is empty, a missing `port makeall` is the first thing to check.

**A label lands on whatever geometry is under the box in the current cell.** If that shape
belongs to a subcell, the label belongs to the subcell, not to you. That is why the blocks in
Lab 04 and the capstone paint their own small patch of `li` or `m1` before labelling it.

## The `.mag` file

```tcl
save my_inv           ;# writes my_inv.mag in the current directory
```

A `.mag` file is plain text: a list of layer sections, each with its rectangles:

```
<< ndiff >>
rect 80 260 520 390
```

**Check the header before you trust those numbers.** A `.mag` file's unit is set by its
`magscale` line, and the two kinds of cell in this course disagree:

| Cell | Header | One unit is | `rect 80 260 520 390` means |
|---|---|---|---|
| A foundry cell from the PDK | `magscale 1 2` | 0.005 µm | 0.40 → 2.60 µm |
| Anything this course draws | *no `magscale` line* | 0.01 µm | 0.80 → 5.20 µm |

So the rectangle above is 0.40 → 2.60 µm horizontally **in a foundry cell**. In `mag/my_inv.mag`
the same 0.40 → 2.60 µm diffusion is stored as tiles spanning `40 130` to `260 195`. Magic splits
a painted shape into several `rect` lines, so read the extent, not one line. If you apply the
foundry rule to a cell you drew, you read every dimension as half its real size, with no
warning: the same kind of factor-of-two trap as `box values`. Magic tells you which kind you have
on every load (`Scaled magic input cell my_inv geometry by factor of 2`), and `box values` always
reports in 0.005 µm units, whichever file you are in.

When a lab says a shipped cell has a particular dimension, that is where the number comes from,
and you can check it with `grep`. In
[Lab 03, Part 9](../labs/lab-03-draw-an-inverter-overview.md#part-9-read-what-you-drew) you open
your own `.mag` file in a text editor.

## The commands the labs run

Later guide pages cover each of these. Together they are the whole flow:

```tcl
drc check                 ;# find rule violations
drc why                   ;# name the rule broken under the box
drc style drc(full)       ;# switch to the rule set that catches taps

extract do local          ;# geometry -> circuit
extract all
ext2spice lvs             ;# write it in a form netgen understands
ext2spice -o my_inv.spice

ext2spice cthresh 0       ;# ...and keep every parasitic capacitance
gds write my_inv.gds      ;# the file a foundry would take
```

The [Magic cheat sheet](../reference/magic-cheatsheet.md) lists these with their keyboard
equivalents, plus about a dozen more.
