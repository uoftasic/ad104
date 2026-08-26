# Drawing in Magic

Magic has one idea, and once you have it the rest is vocabulary.

**There is a box. You move the box. You tell a layer to fill the box.**

That is painting. Everything else — contacts, labels, ports, zooming — is done
to the box or with the box.

## The three mouse buttons

| | |
|---|---|
| **Left** | move the **lower-left** corner of the box to the cursor |
| **Right** | move the **upper-right** corner of the box to the cursor |
| **Middle** | **paint** the box with the layer under the cursor, or **erase** if the cursor is over empty space |

So drawing a rectangle is: left-click one corner, right-click the other,
middle-click on a swatch of the layer you want in the palette down the right
side. There is no click-and-drag. The first hour is annoying and then it is
faster than dragging.

If you have no middle button, or you would rather be exact — and in this
course you would rather be exact — type it instead.

## The console is the real interface

Magic opens a second window, `tkcon`. Everything below is typed there.

```tcl
box 0.4um 1.3um 2.6um 1.95um     ;# put the box at these micron coordinates
paint ndiff                      ;# fill it with n-diffusion
erase ndiff                      ;# or take it away again
```

**Use the `um` suffix.** Without it Magic interprets numbers in *lambda*
(0.01 µm here), and the difference is a factor of a hundred with no error
message. Every command in every lab in this course writes `um`, and so should
you.

Two more you will use constantly:

```tcl
box values                       ;# what is the box now? (in internal units, 0.005 um)
findbox zoom                     ;# zoom the view to the box
```

`box values` **reads back in internal units of 0.005 µm** even though it
*sets* in lambda. That inconsistency has cost people afternoons. Set with
`box ... um`, and treat the numbers `box values` returns as 200-per-micron.

## The layer names you need

The palette on the right shows the display names; the console takes short
aliases. These are the ones this course uses:

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

`tech layers` prints all of them and their aliases, if you want the full list.

## Contacts are a layer, not an object

This is the piece of Magic that surprises everyone.

You do not place a contact. You **paint the contact layer over an area**, and
Magic understands that region as the whole stack — diffusion *and* the cut
*and* the local interconnect on top, all at once. `paint ndc` over a
0.17 × 0.17 µm box gives you one properly formed n-diffusion contact.

Consequences worth knowing before you are confused by them:

- The contact region must be **exactly 0.17 µm** in each direction for a
  single cut (`licon.1`). Bigger and Magic generates an array of cuts.
- The plain layers around it still have to surround it. Diffusion has to
  extend past the contact, and li has to extend past it, and the rules for
  those are `licon.5c` and `li.5` respectively — two of the five in Lab 02.
- Erasing `li` from a contact does not remove the contact; it demotes it.

## Naming things

A shape with no name is invisible to LVS. Two commands:

```tcl
box 1.30um 2.40um 1.55um 2.65um
label A c li          ;# put the label "A", centred, on the li layer here

select top cell
port makeall          ;# promote every label in the cell to a port
```

`label` names a piece of geometry. `port makeall` says "these names are the
cell's terminals" and is what makes the extracted netlist come out as
`.subckt my_inv A Y VPWR VGND` instead of a subcircuit with no pins. Every lab
in this course calls `port makeall` for you; if you build a cell by hand and
netgen says the pin lists are empty, this is why.

**A label lands on whatever geometry is under the box in the current cell.** If
the shape belongs to a subcell, the label belongs to the subcell, not to you.
That is why the blocks in Lab 04 and the capstone paint their own small patch
of `li` or `m1` before labelling it.

## Saving, and the file

```tcl
save my_inv           ;# writes my_inv.mag in the current directory
```

`.mag` is plain text and worth opening in an editor once. It is a list of
layer sections and rectangles:

```
<< ndiff >>
rect 80 260 520 390
```

**Read the header before you trust those numbers.** A `.mag` file's unit is set
by its `magscale` line, and the two kinds of cell you will meet in this course
disagree:

| Cell | Header | One unit is | `rect 80 260 520 390` means |
|---|---|---|---|
| A foundry cell from the PDK | `magscale 1 2` | 0.005 µm | 0.40 → 2.60 µm |
| Anything this course draws | *no `magscale` line* | 0.01 µm | 0.80 → 5.20 µm |

So the rectangle above is 0.40 → 2.60 µm horizontally **in a foundry cell**. In
`mag/my_inv.mag` the same 0.40 → 2.60 µm diffusion is stored as tiles spanning
`40 130` to `260 195` — Magic splits a painted shape into several `rect` lines,
so read the extent, not one line. Apply the foundry rule to a cell you drew and
you will read every dimension
as half its real size, silently — which is exactly the kind of factor-of-two this
page warns about two sections earlier. Magic tells you which one you have on
every load (`Scaled magic input cell my_inv geometry by factor of 2`), and
`box values` always reports in 0.005 µm units whichever file you are in.

When a lab tells you a shipped cell has a particular dimension, that is where the
number comes from and you can check it with `grep`.

## The commands this course actually runs

Each of these gets a page of its own later. Together they are the whole flow:

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

The [Magic cheat sheet](reference/magic-cheatsheet.md) has these with the
keyboard equivalents and about a dozen more.
