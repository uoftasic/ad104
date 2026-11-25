# Magic cheat sheet

This page lists what you do in Magic in this course: the mouse, the keys, the menus and their
dialogs, and the few commands you type. Where a key or a menu item has a console form, the
console form is given beside it. You need those only to read the lab scripts in `tcl/`, or if you
would rather type.

## Starting

```bash
cd labs/lab-03-draw-an-inverter/mag    # the folder that holds the cell
magic -d X11 my_inv &                  # opens layout1 and the tkcon console
magic -dnull -noconsole script.tcl     # batch, with no windows, which is what make does
```

Lab 01 starts Magic in its lab folder and gives it the full path of the foundry's cell instead.
`-d X11` selects the X11 display driver, which is the one that works in this container. The
`-d XR` driver can fail with a `BadAlloc` error and leave you looking at a black window, so stick
with X11.

Magic reads the image's `~/.magicrc`, which loads whichever PDK `$PDK` names, and then a
`.magicrc` in the folder you start it in, if there is one. Each lab package has one at its top
level, and it loads SKY130 only if nothing has loaded it yet:

```tcl
if {[tech name] eq "sky130A"} {
    # Already loaded by ~/.magicrc. Nothing to do.
} elseif {[info exists env(PDK_ROOT)]} {
    source $env(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc
} else {
    puts stderr "PDK_ROOT is not set. Try:  export PDK_ROOT=/foss/pdks"
}
```

The `mag/` folders have no `.magicrc`, so start Magic there from a terminal where `echo $PDK`
prints `sky130A`. [Getting started](../guide/getting-started.md#where-magic-gets-the-technology)
says what goes wrong when it doesn't.

## Mouse

In the drawing:

| Mouse | Does | Console |
|---|---|---|
| left click | moves the box so its lower-left corner is at the pointer, keeping its size | `box <x1>um <y1>um <x2>um <y2>um` sets both corners |
| right click | moves the box's upper-right corner to the pointer; below or left of the box, the corners swap | |
| middle click over shapes | paints every layer under the pointer into the box, wells included | |
| middle click over empty space | erases every layer in the box, wells included | `erase` |

There is no click-and-drag, and clicks snap to 0.01 µm. On the palette:

| Mouse or key | Does | Console |
|---|---|---|
| middle click on a swatch | paints that layer into the box | `paint <layer>` |
| shift + middle click on a swatch | erases that layer from the box | `erase <layer>` |
| `p` / `e` with the pointer over a row | paints / erases that layer | |
| pointer over a row | the layer's name shows in the title bar | |
| right click / left click on a swatch | hides / shows that layer | |
| mouse wheel | scrolls the palette, which shows only its top part at first | |

## Keys

Keys act only while the pointer is over the drawing. After you type in tkcon, click the layout
window's title bar first, or the key goes into tkcon.

| Key | Does | Console or menu |
|---|---|---|
| `z` / `Z` | zoom in / out ×2, about the window's centre | `Window → Zoom In` / `Zoom Out` |
| mouse wheel | zoom in / out by about 1.41 | |
| shift + wheel, ctrl + wheel | pan | |
| `ctrl+z` | zoom to the box | `Window → Zoom Box`, `findbox zoom` |
| `v` | fit the cell in the window | `Window → Full View`, `view` |
| arrows, shift + arrows | pan a tenth of the window, a whole window | |
| `g` | grid on and off | `Window → Grid on` / `Grid off` |
| `b` | print the box in microns, lambda and internal units | `box`, `Window → Measure box` |
| `/` | print the layers under the box | `select area; what; select clear` |
| `s`, `s s`, `s s s` | select the tile under the pointer, the region connected to it, the whole net (hide the wells first) | `select` |
| `a` | select everything visible in the box | `select area`, `Edit → Select Area` |
| `,` | clear the selection | `select clear`, `Edit → Select Clear` |
| `m` / `c` | move / copy the selection by the pointer's offset from the box's lower-left corner | `move` / `copy` |
| `M` | stretch: move the selection and fill the space it leaves | `Edit → Stretch Right` and the others stretch by 0.01 µm |
| `d` | delete the selection | `delete`, `Edit → Delete` |
| `u` / `U` | undo / redo | `undo` / `redo`, `Edit → Undo` / `Redo` |
| `i` | select the instance under the pointer | `Cell → Select` |
| `x` / `X` | expand / unexpand subcells, so they draw in full or as outlines; `x` expands the ones under the box | `Cell → Expand` / `Unexpand`, `expand` |
| `q` | edit the selected generated device in the device dialog (Lab 04) | |
| `=` | put the box on the next DRC error and zoom out far enough to see it | `drc find; findbox zoom; zoom 16` |
| `y` | check the cell and report the rules broken in the box | `drc check; drc why`, like `Drc → DRC update` |
| `w` | the save dialog | `File → Save...` |
| `f` | in this image, the same as `v` | `view` |
| `!` | in this image, show only mcon, metal1 and via1; left-click a layer's swatch to show it again | |
| `?` | in this image, select the area in the box and print its layers | `select area; what` |
| `k` | a ruler that reports **half** the real distance in this image; don't use it | |
| `l` | puts `label ` on the console line but leaves the keys in the layout window; use `Edit → Text ...` instead | |

## Menus

The layout window's menus, with every item. The tables after this one describe the items the
course uses.

| Menu | Items |
|---|---|
| `File` | Open..., Save..., Flush changes, Import SPICE, Read GDS, Write GDS, Save All and Quit, Quit |
| `Edit` | Delete, Select Area, Select Clear, Undo, Redo, Rotate 90 degree, Mirror Up/Down, Mirror Left/Right, Move Right/Left/Up/Down, Stretch Right/Left/Up/Down, Text ... |
| `Cell` | New..., Save as..., Select, Place Instance, Down hierarchy, Up hierarchy, Edit, Delete, Expand Toggle, Expand, Unexpand, Lock Cell, Unlock Cell |
| `Window` | Clone, New, Set Editable, Close, Full View, Redraw, Zoom Out, Zoom In, Zoom Box, Grid on, Grid off, Snap-to-grid on, Snap-to-grid off, Measure box, Report internal / lambda / micron / grid units, Display units, Set grid 0.05um to Set grid 10.0um |
| `Layers` | Protect Base Layers, Unlock Base Layers, Clear Feedback, Reorder layers |
| `Drc` | DRC update, DRC report, DRC Find next error, DRC Fast, DRC Complete, DRC Routing |
| `Options` | Toolbar, Toolbar Hide Locked, Cell Manager, Library Manager, Tech Manager, DRC Manager, Netlist Window, Colormap Window, 3D Display, Window Command Entry, Crosshair, Maze Router |
| `Devices 1` | `nmos (MOSFET)`, `pmos (MOSFET)`, LDNMOS and LDPMOS, diodes, a varactor, bipolars, inductors, substrate contacts and guard rings, deep n-well and n-well regions, `mcon`, `via1` to `via4` |
| `Devices 2` | resistors (diffusion, poly, p-well, metal), MiM capacitors, vpp capacitors |

No menu runs extraction, `ext2spice` or LVS; you type those (below).

### Files, cells and windows

| Menu item | Does | Console |
|---|---|---|
| `File → Open...` | opens a `.mag` file; a full path in `File name:` works too | `load <cell>` |
| `File → Save...` | the save dialog (below) | `save <cell>` |
| `File → Write GDS` | writes the cell and everything under it as GDS | `gds write <file>.gds` |
| `Cell → Place Instance` | places a `.mag` file you choose at the box | `getcell <cell>` |
| `Options → Library Manager`, then `Place` | places a library cell at the box | |
| `Cell → Edit` | edits inside the selected instance, in place, which changes every instance of that cell; `Window → Set Editable` goes back | |
| `Cell → Down hierarchy`, `Cell → Up   hierarchy` | opens the selected instance's cell in the window, and back | |
| `Window → Set grid 0.05um` | a dot grid every 0.05 µm; clicks still snap to 0.01 µm | |
| `Edit → Text ...` | the label dialog (below) | `label <text> c <layer>` |

### The Drc menu

| Menu item | Same as | Does |
|---|---|---|
| `Drc → DRC update` | `drc check; drc why` | checks the whole cell, sets the count on the `DRC` button, then reports the rules broken inside the box (`No errors found.` when the box is on empty space) |
| `Drc → DRC report` | `drc why` | the rules broken by the errors inside the box |
| `Drc → DRC Find next error` | `drc find; findbox zoom` | the box on the next error, zoomed to a view about 0.1 µm wide; the `=` key is the same, then zooms out |
| `Drc → DRC Fast` / `DRC Complete` | `drc style drc(fast)` / `drc style drc(full)` | the default / the full rule set; the count changes at the next `DRC update` |
| `Drc → DRC Routing` | `drc style drc(routing)` | not used in this course |
| the `DRC` button | `drc on` / `drc off` | turns the background checker off and on; the count stays |
| `Options → DRC Manager` | | every rule broken, one row per rule, with its errors under it in internal units; `Zoom` goes to the selected error |

Magic checks only what you change. A cell you have just opened shows a green `DRC` and no count
until you run `Drc → DRC update`, even when it has errors.

## Dialogs

| Window title | Opened by | What's in it |
|---|---|---|
| `Open` | `File → Open...`, `Cell → Place Instance` | `File name:` has the focus; type a name in the folder shown, or a full path, and press Return. It starts in the last folder it showed, so after you have opened a PDK cell, a bare name fails with `... does not exist.` |
| `Save As` | `File → Write GDS` | the same, for the GDS file's name |
| `Dialog` | `File → Save...`, `w` | `<cell> : write, autowrite, flush, skip, or abort command?`. `write` saves this cell; `autowrite` saves every changed cell, which you need after the device generator has made new cells (Lab 04) |
| `dialog` | `Cell → Save as...` | `Cell name:`. Afterwards the window edits the copy, so don't use it on a file `make` checks |
| `texthelper` | `Edit → Text ...` | `Text string:`, `Size (um):` (set 0.1; the default 1 covers a third of a small cell), `Justification:`, `Rotation:`, `Attach to layer:`, and `Port:` with `enable`, which makes the label a port. `Okay` puts the label at the box, on the layer under it. With a label selected it edits that label |
| `params` | `Devices 1 → nmos (MOSFET)`, `pmos (MOSFET)`; `i` then `q` on a placed device | `Width (um)`, `Length (um)`, `Fingers`, `M`, `Device type`, contact coverages, check boxes such as `Add top gate contact`, `Add bottom gate contact` and `Add guard ring`; `Create and Close` (new) or `Okay` (edit) |
| `drcmgr` | `Options → DRC Manager` | `Update`, `Last`, `Next`, `Save`, `Zoom`, and the tree of rules and errors |
| `libmgr` | `Options → Library Manager` | `./` and the libraries on Magic's path, `sky130_fd_sc_hd` among them; `Place` |
| `cellmgr` | `Options → Cell Manager` | the cell tree; `Zoom`, `Edit`, `Load`, `Expand`, `Place`, `Refresh` |

The device dialog (`params`) is taller than the workbench's default 1280 × 800 desktop, so its
buttons start below the bottom of the screen. Double-click its title bar: the window fills the
screen and the buttons appear along its bottom edge.

## Traps

The traps you meet while drawing (keys and the pointer, middle clicks, `s` and the wells,
`Snap-to-grid off`, the rebound keys, the label size, the palette, the DRC counts) are listed in
[Drawing in Magic](../guide/drawing-in-magic.md#traps). The others:

- **`Cell → Save as...` switches the window to the copy**, so later saves don't reach the file
  `make` checks.
- **A generated `nmos` with its default options shows DRC errors on its own**: `DRC=6`, and the
  rule `DRC report` names is `met1.6`, metal1 minimum area. Lab 04 deals with it.
- **`Timestamp mismatches found in these cells: ...`** when the capstone's cell opens. It names
  the foundry's cells, and you can ignore it.
- **The DRC Manager selects the top cell**, which draws the cell's name and `Topmost cell in the
  window` across the layout. Press `,` over the drawing to clear the selection.
- **`ext2spice` without `ext2spice lvs` first** writes a netlist with no `.subckt` line around the
  devices.

## Typed commands

### Commands the labs use

```tcl
extract all            ;# geometry -> circuit, this cell and every subcell (.ext files)
extract do local       ;# write the .ext files in the folder Magic started in
ext2spice lvs          ;# preset: devices only, hierarchical, for netgen (prints nothing)
ext2spice              ;# write <cell>.spice
ext2spice -o out.spice ;# or choose the file name
ext2spice cthresh 0    ;# keep every parasitic capacitance (Lab 05)
ext2spice cthresh infinite   ;# back to none

box size 0.17um 0.17um ;# set the box's size, keeping its lower-left corner

select top cell        ;# select the whole cell (capstone)
port makeall           ;# turn every label in the cell into a port (capstone)
```

`box size` takes sizes only. Left-click the shape's lower-left corner first, then type it, then
click the layout window's title bar before you press `b` to check. This is the **Typed size**
recipe in [Drawing in Magic](../guide/drawing-in-magic.md#exact-small-shapes).

### The box by numbers

```tcl
box 0.4um 1.3um 2.6um 1.95um ;# put the box at these micron coordinates
box values             ;# read it back, in internal units of 0.005 um
box width              ;# the box's width (box height for its height)
findbox zoom           ;# zoom the view to the box
snap lambda            ;# clicks back to 0.01 um, after Window -> Snap-to-grid off
```

**Always write `um`.** Without it, Magic reads a number as lambda, which is 0.01 µm in this
technology, so a box you meant in microns comes out a hundred times too small, with no error
message. And `box values` **reads the box back in internal units of 0.005 µm**, although a plain
number you give to `box` sets it in lambda. That inconsistency has cost people whole afternoons:
set the box with `um`, and read the numbers `box values` returns as 200 to the micron.

### Painting and labels

```tcl
paint ndiff            ;# fill the box with a layer (console names; see Drawing in Magic)
erase ndiff            ;# take one layer away
erase                  ;# clear every layer in the box
label A c li           ;# label "A", centred, on the li under the box
port <name> index <n>  ;# set a port's number, if order matters to you
tech layers            ;# every layer name and alias
```

The console names of the layers this course uses (the palette names are in
[Drawing in Magic](../guide/drawing-in-magic.md#layer-names)):

```
nwell pwell            ndiff pdiff            ntap ptap
ndc pdc                ntapc ptapc            pc
poly                   li                     mcon
m1 m2                  via1                   pfethvt
```

`ndc`, `pdc`, `pc`, `ntapc`, `ptapc` and `mcon` are **contact types**, which means that painting
one fills the whole stack (the lower layer, the cut and the upper layer) in one step. For a single
contact, the cut has to be exactly 0.17 µm square.

A typed label goes into the cell you're editing, like one from the Text dialog. If the only shape
under the box belongs to a subcell, the label lands on empty space, where it names nothing. Typed
with a layer, as above, Magic says so (`Moving label "A" from locali to space`); from the Text
dialog it says nothing.

### DRC

```tcl
drc check              ;# re-run
drc catchup            ;# wait for it to finish (batch scripts need this)
drc count total        ;# how many violations: the number you want
drc count              ;# careful: prints "Cell X has 3 error tiles." and then
                       ;#   "Total DRC errors found: 0" - that second line is a
                       ;#   hierarchical total and reads 0 on a flat cell
drc why                ;# name the rules broken under the box (set one first:
                       ;#   with no box, 'select top cell')
drc listall why        ;# every violation in the cell, with rule text
drc euclidean on       ;# measure corners properly rather than as squares
drc style drc(full)    ;# the rule set that catches missing well taps
drc style drc(fast)    ;# back to the default
```

### Hierarchy

```tcl
addpath ../mag         ;# where to find cells (set it AFTER any cd)
getcell my_inv         ;# place an instance with its origin at the box
identify inv2          ;# rename the selected instance
array 2 1              ;# make the selected instance an array, 2 by 1
expand                 ;# draw subcells properly instead of as outlines
flatten -nolabels flat ;# copy the whole hierarchy into one cell
cellname list children ;# what is instanced in this cell
```

### Files

```tcl
load <cell>            ;# read cell.mag and make it the edit cell
load <cell> -force     ;# start a new empty cell with that name
save <cell>            ;# write cell.mag
cd <dir>               ;# Magic has its own working directory
gds write out.gds      ;# the file a foundry would take
property FIXED_BBOX    ;# a cell's placement outline, if it has one
```

## Batch scripts

The lab scripts in `tcl/` drive Magic with no windows, and `make` runs them with
`magic -dnull -noconsole thatfile.tcl`. They follow this pattern:

```tcl
cd results
addpath ../mag
load my_inv
select top cell
drc euclidean on
drc check ; drc catchup
puts "DRC [drc list count total]"
extract do local ; extract all
ext2spice lvs
ext2spice -o my_inv.spice
quit -noprompt
```

Put `cd` **before** `addpath`, because `addpath` stores the path exactly as you typed it and
doesn't re-resolve it, so a relative path like `../mag` given before a `cd` points at the wrong
place afterwards.

## netgen (LVS)

Typed in a terminal, in the folder that holds your extracted netlist:

```bash
netgen -batch lvs "my_inv.spice my_inv" "../spice/my_inv_sch.spice my_inv" \
  $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl
```

The three arguments are the layout netlist and its cell, the schematic netlist and its cell, and
the PDK's setup file. netgen writes its report to `comp.out` in that folder; a fourth argument
names a different report file, which is what `make` does. Look for `Circuits match uniquely.`,
which means the layout and the schematic agree. If you get anything else, read the report from
the bottom up.

## KLayout (viewing)

```bash
klayout -nn $PDK_ROOT/sky130A/libs.tech/klayout/tech/sky130A.lyt out.gds
```

`-nn` loads the SKY130 technology, so the layers are named and coloured properly.
