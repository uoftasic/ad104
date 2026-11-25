# Drawing in Magic

Magic is built around one idea, and once you have it the rest is mostly vocabulary: **there is a
box, you move the box, and you tell a layer to fill the box.** Magic calls that painting, and
everything else you do, including contacts, labels, ports and zooming, is done either to the box
or with it.

This page explains how you do that with the mouse, the keys and the menus. You fix your first
shapes this way in [Lab 02](../labs/lab-02-break-it-on-purpose-overview.md) and draw your first
cell in [Lab 03](../labs/lab-03-draw-an-inverter-overview.md). The
[Magic cheat sheet](../reference/magic-cheatsheet.md) lists every key and menu item on one page,
with the console command that does the same thing.

## The box and the mouse

| Mouse, in the drawing | Does |
|---|---|
| **Left** click | moves the box so that its **lower-left** corner is at the pointer, keeping its size |
| **Right** click | moves the box's **upper-right** corner to the pointer |
| **Middle** click | **paints** every layer under the pointer into the box, or, over empty space, **erases** every layer in the box |

So to draw a rectangle you left-click one corner, right-click the opposite corner, and then
middle-click a layer in the palette down the right side of the window. There is no
click-and-drag. If you right-click below or to the left of the box, Magic swaps the corners for
you. The first hour of working this way is annoying, but after that it's faster than dragging
would be.

Use the middle button in the drawing with care: over existing shapes it paints *all* of them into
the box, wells included, and over empty space it erases everything in the box, wells included.
Middle-clicking a layer in the palette is the safe way to paint.

The right-hand end of the title bar tells you where things are. After the box changes it shows
the box's corners, such as `box (+0 +0) to (+0.01 +0.01) microns` for the 0.01 µm box Magic
starts with. While you move the pointer it shows the pointer's position and then its offset from
the box's lower-left corner, such as `(+1.52 +3.03) +0.22 +0.63 microns`, which is how you
measure a distance. Press `b` with the pointer over the drawing to print the box in the console.
For that starting box the report reads:

```
Root cell box:
           width x height  (   llx,  lly  ), (   urx,  ury  )  area (units^2)

microns:   0.010 x 0.010   ( 0.000,  0.000), ( 0.010,  0.010)  0.000
lambda:     1.00 x 1.00    (  0.00,  0.00 ), (  1.00,  1.00 )  1.00
internal:      2 x 2       (     0,  0    ), (     2,  2    )  4
```

Read the `microns:` line. The `internal:` line is in Magic's internal unit, 0.005 µm, so its
numbers are 200 to the micron.

Clicks snap to 0.01 µm. At the view Magic opens Lab 03's cell with, one pixel on the screen is a
little more than 0.01 µm, so some values can't be clicked at all (aiming for y = 1.40 gives 1.39).
Zoom in before you draw to an exact number.

## The palette

The palette down the right side of the window has one row per layer, a swatch and the layer's
name. With the box set:

- **Middle-click a swatch** to paint that layer into the box. Painting adds to what is already
  there.
- **Shift + middle-click a swatch** to erase only that layer from the box.
- With the pointer over a row, **`p`** paints that layer and **`e`** erases it.
- **Point at a row** and the layer's name appears in the title bar. That is the only place the
  window names a layer before you paint it, so check it.
- **Right-click a swatch** to hide that layer, and **left-click** it to show it again.

The palette shows only its top part at first. `polysilicon`, `locali`, `viali` and `metal1`, the
layers you use most, are below that, so scroll the palette with the mouse wheel.

![The palette scrolled down to `locali`, with the pointer on its row](../assets/img/ad104-g-palette.png){fig-alt="The right-hand part of Magic's layout window. The brown title bar at the top shows the word locali next to the box readout. Below it the palette lists layers, each with a swatch, from mvndiodec at the top through locali, viali, metal1, m2contact and metal2 down to comment at the bottom."}

*With the pointer on the `locali` row, the title bar names the layer. This is the lower part of
the palette, which you reach with the mouse wheel; `viali`, `metal1` and `m2contact` are just
below `locali`.*

## Moving round

| Key | Does |
|---|---|
| `z` / `Z` | zoom in / out by 2, about the centre of the window |
| mouse wheel | zoom in / out a little |
| `ctrl+z` | zoom to the box (`Window → Zoom Box`) |
| `v` | fit the whole cell in the window (`Window → Full View`) |
| arrow keys | pan by a tenth of the window; with shift, by a whole window |

**Keys act only while the pointer is over the drawing.** A key pressed with the pointer over the
scrollbars, the title bar or the palette leaves Magic without a current window, and until you
move the pointer back over the drawing the next menu item may fail with an `Application Error`
box that says only `Error:`.

The desktop gives the keyboard to the window you last clicked. After you type in the console,
click the layout window's **title bar** before you press a key, or the key goes into the console.
Don't click in the drawing to do it: a left click there moves the box.

## The grid and snapping

`Window → Set grid 0.05um` puts a dot every 0.05 µm over the drawing, which makes it easier to see
where you are. Clicks still snap to 0.01 µm. Leave the `Snap-to-grid` items alone:
`Snap-to-grid on` snaps clicks to the dots, and `Snap-to-grid off` then makes them snap to
0.005 µm instead of the 0.01 µm they started with, and no menu item undoes that.

## Exact small shapes {#exact-small-shapes}

A contact is exactly 0.17 × 0.17 µm, and drawing it by eye doesn't work. The labs use two
recipes, and later labs refer to them by these names.

**Click recipe.** Keep the default snap. Set a rough box around the area and press `ctrl+z` to
zoom in on it. Left-click the shape's lower-left corner and right-click its upper-right corner,
then read the size in the title bar, or press `b` and read the `microns:` line. Lab 01 uses this
recipe to measure and Lab 02 to draw.

**Typed size.** Zoom in, then left-click the shape's lower-left corner. Click in the console and
type

```tcl
box size 0.17um 0.17um
```

which sets the box's size and keeps the corner you clicked. Then click the layout window's title
bar and press `b` over the drawing to check that the `microns:` line says `0.170 x 0.170`. From
Lab 02 on, the labs draw contacts and vias this way, because hitting a 0.17 µm square to the pixel
is too hard even zoomed in.

## Select, move and copy

| Key | Does |
|---|---|
| `s` | selects the piece of paint under the pointer; press it again for everything connected to it, and a third time for the whole net |
| `a` | selects everything visible in the box (`Edit → Select Area` selects everything in it) |
| `,` | clears the selection (`Edit → Select Clear`) |
| `m` / `c` | moves / copies the selection |
| `M` | stretches: moves the selection and fills the space it leaves behind |
| `d` | deletes the selection (`Edit → Delete`) |
| `u` / `U` | undo / redo (`Edit → Undo`, `Edit → Redo`) |

`m` and `c` move the selection by the distance from the box's lower-left corner to the pointer.
So you left-click a reference point on the selection first, then point at where that point should
go and press the key.

With the wells showing, `s` picks the well first, and pressing it again swaps between the well and
the wire. Hide the wells first, by right-clicking the `nwell` and `pwell` swatches.

## Layer names

The palette shows each layer's long name, and the console and Magic's messages use short
aliases. `/` with the pointer over the drawing prints the layers under the box by their console
names. These are the ones this course uses:

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

`tech layers`, typed in the console, prints the full list with every alias.

## Contact layers

Contacts surprise everyone who is new to Magic, because you don't place a contact as an object.
Instead you **paint the contact layer over an area**, and Magic treats that region as the whole
stack at once: the diffusion, the cut, and the local interconnect on top. So painting
`ndcontact` into a 0.17 × 0.17 µm box gives you one properly formed n-diffusion contact.

That has a few consequences, and it's worth knowing them before they confuse you:

- For a single cut, the contact region must be **exactly 0.17 µm** in each direction (rule
  `licon.1`). If you make it bigger, Magic generates an array of cuts instead.
- The plain layers still have to surround the contact. The diffusion has to extend past the
  contact, and so does the li. The rules for those are `licon.5c` and `li.5`, and `li.5` is one
  of the five rules you fix in Lab 02.
- Erasing li from a contact doesn't remove the contact; Magic demotes it instead.

## Labels and ports

As far as LVS is concerned, a cell has no terminals until you name them. To name a shape, set the
box on it and choose `Edit → Text ...`. In the window that opens:

- type the name in `Text string:`,
- set `Size (um):` to about 0.1, because at the default of 1 the letters cover a third of a
  3 µm cell,
- tick `enable` next to `Port:` to make the label one of the cell's terminals, a **port**,
- and click `Okay`.

![`Edit → Text ...` filled in for a port named A](../assets/img/ad104-g-text-dialog.png){fig-alt="A small window headed New label. Text string: A. Font: FreeSans. Size (um): 0.1. Justification: center. Rotation: 0. Offset from reference: 0 0. Attach to layer: default ticked, sticky not ticked. Port: enable ticked, with the number 5 beside it. Buttons Apply, Okay and Cancel along the bottom."}

*`Text string:` is `A`, `Size (um):` is 0.1, and `enable` next to `Port:` is ticked. The number
beside it is the port's number, which Magic fills in.*

Magic counts port numbers on from the last label you made, even one in another cell, and two
ports with the same number in one cell clash, so one of them stops being a port. When you start
labelling a different cell, untick `enable` and tick it again: the number becomes that cell's
next free one
([Lab 04, Part 4](../labs/lab-04-buffer-and-and-overview.md#part-4-build-the-and-gate)).

The label goes on the layer under the box, and the console says so:
`Moving label "A" from space to locali in cell my_inv.` With `default` ticked under
`Attach to layer:`, Magic picks a layer that covers the whole box. If the box touches a contact,
that can be the well underneath rather than the li you meant, so untick `default` and type the
layer's name, as
[Lab 03, Part 7](../labs/lab-03-draw-an-inverter-overview.md#part-7-name-the-pins) does. A label names a net, and the `Port:` box
makes it a terminal of the cell. That second step is what makes the extracted netlist come out as
`.subckt my_inv A Y VPWR VGND` rather than as a subcircuit with no pins. If netgen ever says a
cell's pin list is empty, a label without `Port:` ticked is the first thing to check. (In the
capstone you make the block's labels without ticking it, then make them all ports at once by
typing `select top cell` and `port makeall` in the console.)

**A label always goes into the cell you're editing, on that cell's own geometry under the
box.** If the only shape under the box belongs to a subcell, the label still lands in your cell,
but on empty space, and the console says nothing about it. A label on space isn't attached to any
net, so it never becomes a pin on the extracted `.subckt` line, even with `Port:` ticked. That's why the blocks in Lab 04 and the capstone
paint their own small patch of `li` or `metal1` before labelling it.

Don't use the `l` key for labels. It writes `label ` on the console's command line but leaves the
keys in the layout window, so the letters you type next run Magic's one-key commands instead.

## Saving

Choose `File → Save...` (or press `w`). A small window asks
`my_inv : write, autowrite, flush, skip, or abort command?`. Click `write` to save the cell
you're editing, or `autowrite` to save every cell that has changed, which you need in Lab 04 after
Magic's device generator has made new cells.

Nothing in the window shows that a cell has unsaved changes, and `make` reads the file, not the
screen. So save before every `make`.

Don't use `Cell → Save as...` on a cell that `make` checks. It saves a copy under a new name and
then switches the window to the copy, so your later saves go to the copy and never reach the file
`make` reads.

## Traps

Each of these happens in the workbench image:

1. **`k` measures half the distance.** Its ruler reads `1.1 um` across a 2.2 µm box. Measure with
   the box and the title bar instead.
2. **Keys work only with the pointer over the drawing**, and after you type in the console they
   go to the console until you click the layout window's title bar.
3. **A middle click in the drawing paints every layer under the pointer**, wells included, and
   over empty space it erases every layer in the box, wells included.
4. **`s` picks the well first.** Hide the wells before you select a wire or a net.
5. **`Window → Snap-to-grid off` makes clicks snap to 0.005 µm**, not back to 0.01 µm, and no menu
   item undoes it. Save, close Magic and start it again (the cheat sheet has the console command
   that undoes it).
6. **`Drc → DRC update` prints `No errors found.`** while the `DRC` button shows a count, because
   it reports only on the box. And a cell you have just opened shows a green `DRC` and no count
   until something triggers a check.
7. **`Drc → DRC Complete` and `Drc → DRC Fast` don't recount.** The count changes only at the
   next `Drc → DRC update`.
8. **`Drc → DRC Find next error` zooms in to about 0.1 µm**, too close to see where you are. The
   `=` key finds the next error and zooms out 16 times.
9. **`!`, `?` and `f` do something else in this image** than Magic's own documentation says: `!`
   shows only mcon, metal1 and via1, `?` selects the area in the box and lists its layers, and `f`
   fits the cell like `v`.
10. **The `l` key** puts `label ` on the console line and leaves the keys in the layout window.
11. **The Text dialog's default size of 1 µm** draws a label that covers a third of a 3 µm cell.
12. **The palette hides most of the layers you use** (polysilicon, locali, viali, metal1) below
    its visible part. Scroll it with the wheel.
13. **The title bar is cut off** at the window's default width, so `Technology: sky130A`, and
    sometimes the tool name, are hidden.

## The `.mag` file {#the-mag-file}

When you save, Magic writes the cell to its `.mag` file, `my_inv.mag` for the cell `my_inv`.
A `.mag` file is plain text, made up of one section per layer, each listing that layer's
rectangles:

```
<< ndiff >>
rect 80 260 520 390
```

**Check the header before you trust those numbers.** The unit a `.mag` file uses is set by its
`magscale` line, and the two kinds of cell in this course use different units:

| Cell | Header | One unit is | `rect 80 260 520 390` means |
|---|---|---|---|
| A foundry cell from the PDK | `magscale 1 2` | 0.005 µm | 0.40 → 2.60 µm |
| Anything this course draws | *no `magscale` line* | 0.01 µm | 0.80 → 5.20 µm |

So the rectangle above spans 0.40 → 2.60 µm horizontally if it's **in a foundry cell**. In
Lab 03's frame, which uses the course's unit, the p-tap from 0.40 to 2.60 µm is stored in its
`<< psubdiff >>` section as four `rect` lines whose x values run from 40 to 260, split around its
contact. Magic splits a painted shape into several `rect` lines like that, so read the extent of
the whole shape rather than any one line. If you apply the foundry cell's unit to a cell you drew,
you'll read every dimension as half its real size, and nothing will warn you. Magic does tell you
which kind of cell you have every time it loads one
(`Scaled magic input cell my_inv geometry by factor of 2`), and the `internal:` line that `b`
prints is always in 0.005 µm units, whichever kind of file you're in.

When a lab says that a shipped cell has a particular dimension, the number comes from the cell's
`.mag` file, so you can check it yourself with `grep`. In
[Lab 03, Part 9](../labs/lab-03-draw-an-inverter-overview.md#part-9-read-what-you-drew) you open
your own `.mag` file in a text editor.

## Commands you type

Magic has no menu for extraction, so you type it in the console, and netgen runs in a terminal.
[Extraction](extraction-is-reverse-engineering.md) and
[Layout versus schematic](lvs-asks-a-different-question.md) explain them:

```tcl
extract all               ;# geometry -> circuit
ext2spice lvs             ;# write it in a form netgen understands
ext2spice                 ;# into <cell>.spice
ext2spice cthresh 0       ;# ...and keep every parasitic capacitance (Lab 05)
```

Apart from those, you type `magic -d X11 <cell> &` in a terminal to start Magic, `box size` for
exact small shapes, and in the capstone `select top cell` and `port makeall`. The
[Magic cheat sheet](../reference/magic-cheatsheet.md) has the console form of everything else on
this page, which is what the lab scripts in `tcl/` use.
