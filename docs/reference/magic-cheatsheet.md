# Magic cheat sheet

Every Magic command this course uses. You can type all of them into the `tkcon` console; the
keyboard column is what works in the layout window.

## Starting

```bash
cd <a directory with a .magicrc in it>
magic -d X11 <cellname>          # opens layout1 + tkcon
magic -dnull -noconsole script.tcl   # batch, which is what the labs do
```

`-d X11` is the driver that works in this container. `-d XR` can fail with `BadAlloc` and give
you a black window.

The image's `~/.magicrc` loads whichever PDK `$PDK` names. Each lab package also has a
`.magicrc`, read from the directory you start Magic in, that loads SKY130 only if nothing has
loaded it yet:

```tcl
if {[tech name] eq "sky130A"} {
    # Already loaded by ~/.magicrc. Nothing to do.
} elseif {[info exists env(PDK_ROOT)]} {
    source $env(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc
} else {
    puts stderr "PDK_ROOT is not set. Try:  export PDK_ROOT=/foss/pdks"
}
```

## The box

| Console | Keyboard / mouse | |
|---|---|---|
| `box <x1>um <y1>um <x2>um <y2>um` | left-click, then right-click | set the box |
| `box values` | | read it back — **in units of 0.005 µm** |
| `box width`, `box height` | | dimensions |
| `findbox zoom` | | zoom the view to the box |
| | `z` / `Z` | zoom in / out |
| | `v` | view everything |

**Always write `um`.** Numbers without a unit are lambda (0.01 µm here), and there is no
warning.

## Painting

| Console | Keyboard | |
|---|---|---|
| `paint <layer>` | middle-click on a layer swatch | fill the box |
| `erase <layer>` | middle-click on empty space | clear the box |
| `erase` | | clear every layer in the box |
| `copy` / `move` | | on the current selection |
| `select` | `s` | select what is under the cursor |
| `select area` | `a` | select everything in the box |
| `select top cell` | | select the whole cell |
| `undo` / `redo` | `u` / `U` | |
| `tech layers` | | print every layer name and alias |

## Layers used in this course

```
nwell pwell            ndiff pdiff            ntap ptap
ndc pdc                ntapc ptapc            pc
poly                   li                     mcon
m1 m2                  via1                   pfethvt
```

`ndc`, `pdc`, `pc`, `ntapc`, `ptapc` and `mcon` are **contact types**: painting one fills the
whole stack (lower layer + cut + upper layer) at once. For a single contact, the cut must be
exactly 0.17 µm square.

## Labels and ports

```tcl
box 1.30um 2.40um 1.55um 2.65um
label A c li           ;# name the geometry under the box, on layer li
select top cell
port makeall           ;# turn every label in the cell into a terminal
port <name> index <n>  ;# set a port's number, if order matters to you
```

A label lands on geometry **belonging to the current cell**. Placed over a subcell's shape, it
becomes the subcell's label, not yours.

## DRC

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

The `Drc` menu on the layout window does the same things with the mouse:

| Menu | Same as |
|---|---|
| **Drc → DRC update** | `drc check`. Use it when a freshly opened cell shows a green `☑ DRC` and no hatching. |
| **Drc → DRC report** | `drc listall why`, and it needs no cursor box |
| **Drc → DRC Find next error** | boxes *and zooms to* the next violating tile; the fastest way to find a hatched area you cannot see. It has no console equivalent worth typing. |
| **Drc → DRC Complete** / **DRC Fast** | `drc style drc(full)` / `drc style drc(fast)` |

**Magic does not check a cell you have only opened.** Its background checker re-checks tiles
you *edit*, and loading a `.mag` from disk edits nothing, so a cell with real violations opens
showing a green `☑ DRC` and no white hatching. Run `drc check` (or `Drc → DRC update`) first,
every time.

## Extraction

```tcl
extract do local       ;# this cell
extract all            ;# and every subcell
ext2spice lvs          ;# preset: devices only, hierarchical, for netgen
ext2spice -o out.spice
ext2spice cthresh 0    ;# keep every parasitic capacitance
ext2spice cthresh infinite   ;# back to none
```

## Hierarchy

```tcl
addpath ../mag         ;# where to find cells (set it AFTER any cd)
box 3um 0um 3um 0um
getcell my_inv         ;# place an instance with its origin at the box
identify inv2          ;# name this instance
expand                 ;# draw subcells properly instead of as outlines
flatten -nolabels flat ;# copy the whole hierarchy into one cell
cellname list children ;# what is instanced in this cell
```

## Files

```tcl
load <cell>            ;# read cell.mag and make it the edit cell
load <cell> -force     ;# start a new empty cell with that name
save <cell>            ;# write cell.mag
cd <dir>               ;# Magic has its own working directory
gds write out.gds      ;# the file a foundry would take
property FIXED_BBOX    ;# a cell's placement outline, if it has one
```

## Batch scripts

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

This is the shape the lab scripts use. Run it with `magic -dnull -noconsole thatfile.tcl`. Put
`cd` **before** `addpath`, because `addpath` stores what you typed and does not re-resolve it.

## netgen (LVS)

```bash
netgen -batch lvs \
  "layout.spice cellname" \
  "schematic.spice cellname" \
  "$PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl" \
  report.txt
```

Look for `Circuits match uniquely.` For anything else, read the report from the bottom.

## KLayout (viewing)

```bash
klayout -nn $PDK_ROOT/sky130A/libs.tech/klayout/tech/sky130A.lyt out.gds
```

`-nn` loads the SKY130 technology, so the layers are named and coloured properly.
