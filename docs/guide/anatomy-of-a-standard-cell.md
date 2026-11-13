# Anatomy of a standard cell

Before you draw a cell, read one. The SKY130 high-density library ships **446 cells** in
`$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/`, and the smallest of them is the inverter you
are about to draw yourself, `sky130_fd_sc_hd__inv_1`. In Lab 01 you open it and get four checks to
agree about it. This page tells you what to look for.

## The constraints every cell obeys

A standard cell is a transistor-level layout that follows a few constraints, so that a machine
can place thousands of them without thinking:

| Constraint | `sky130_fd_sc_hd` |
|---|---|
| Every cell is the same **height** | **2.72 µm** |
| Every cell's **width** is a multiple of one site | 0.46 µm |
| Power rails sit at the same y in every cell, in metal1 | VGND straddles y = 0, VPWR straddles y = 2.72 |
| Rails span the full width, so abutting cells connect them | yes |
| Pins are on **li1**, reachable from above | yes |

`inv_1` is **1.38 µm × 2.72 µm = 3.7536 µm²**, which Lab 01 prints. The `FIXED_BBOX` property
in the `.mag` file says `0 0 276 544`, in units of 0.005 µm; multiply by 0.005 and you get those
two dimensions.

Because the rails straddle the cell boundary, two cells placed side by side share half a rail
each, and the supply runs continuously along the row with no wire drawn. Flip a cell vertically
and put it above, and the rails are shared again. That one decision is why chips are built out of
rows.

## What is inside `inv_1`

When you open it in
[Lab 01, Part 2](labs/lab-01-open-the-cell-overview.md#part-2-look-at-the-cell-in-magic), you
will find:

- **an n-well** across the top half, with p-diffusion inside it: the PMOS
- **n-diffusion** in the bottom half: the NMOS
- **one poly stripe** crossing both. Lab 01 reads `w=0.65 l=0.15` for the NMOS and
  `w=1 l=0.15` for the PMOS back out of the geometry.
- **six ports**: `A`, `Y`, `VPWR`, `VGND`, and two you might not expect, **`VPB`** and
  **`VNB`**, the p-bulk and n-bulk. The cell exposes its own well and substrate as terminals.

The last two are there because of something the cell leaves out.

## Why the cell has no well tap

Run the full design-rule check on the foundry's own inverter and it fails. Lab 01 does exactly
that, and prints:

```
  ok  DRC violations, default style                 0   (reference 0)
  ok  DRC violations, full style                    3   (reference 3)
  ...
  THE THREE THINGS THE FULL RULE SET COMPLAINS ABOUT
      All nwells must contain metal-connected N+ taps (nwell.4)
      P-diff distance to N-tap must be < 15.0um (LU.3)
      N-diff distance to P-tap must be < 15.0um (LU.2)
```

That is three violations in a cell shipped by the foundry, from a library that has been taped out
hundreds of times.

All three come from the same omission: **there is no tap in this cell.** The n-well is not tied
to VPWR and the substrate is not tied to VGND, which is why `VPB` and `VNB` are ports instead of
being wired inside the cell.

This is deliberate. Taps cost area, and a tap every 1.38 µm is far more than any process needs:
the latch-up rule only asks for one within 15 µm. So the library puts them in a **separate
cell**, `sky130_fd_sc_hd__tapvpwrvgnd_1`, 0.46 µm wide, and the flow drops a few into each row.
You will do that by hand in the capstone.

The same idea applies beyond taps:

> **A cell is DRC clean only in a context.** Some rules can only be satisfied by a cell's
> neighbours, and a checker run on one cell by itself will always report them.

It is much cheaper to learn this on the foundry's cell in the first lab than on your own cell in
the third, where you would assume you had broken something.

## Drive strength

```
sky130_fd_sc_hd__inv_1   inv_2   inv_4   inv_6   inv_8   inv_12   inv_16
sky130_fd_sc_hd__and2_0  and2_1  and2_2  and2_4
```

The number after the last underscore is the drive strength. Each step up is the same logic
function with wider transistors, so more current, more area and more input capacitance.
`and2_0` is the *weakest* AND in the library, and `and2_4` has roughly four times its drive.
Choosing between them is most of what a synthesis tool spends its time on. In the capstone you
are handed `and2_0` on purpose, so you can see what the cheapest choice costs in delay.

## Who drew these cells

The `.mag` file answers that. Near the end of `sky130_fd_sc_hd__inv_1.mag`, among its
properties:

```
string GDS_END 2272374
string GDS_FILE $PDKPATH/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
string GDS_START 2268880
```

That is not a layout. It is a **byte range in the foundry's GDS file**. The `.mag` file was
produced by `open_pdks` reading SkyWater's released GDSII back into Magic so the cells could be
used in an open flow, and it keeps a pointer to where it came from. When you write GDS from a
design that uses these cells, Magic does not regenerate their geometry; it copies those bytes
straight through. Writing the capstone's reference block, Magic logs:

```
   Copying output for cell sky130_fd_sc_hd__and2_0 from $PDKPATH/.../sky130_fd_sc_hd.gds
   Generating output for cell datapath_ref
```

So **the foundry drew them, in a commercial tool, and shipped GDSII.** Magic reads them; it did
not create them.

## Why this course uses Magic

That raises a practical question: is Magic the right tool for *you* to draw a minimum-size cell
in? It is rough. Magic thinks in tiles, in a "corner-stitched" plane model that makes
some edits behave in ways that surprise people used to a polygon editor, and packing a cell to the
last 0.005 µm in it is a fight. KLayout is a nicer polygon editor.

This course uses Magic anyway, for reasons that are about the *flow* rather than the editor:

- Magic has a **live design-rule checker**. Errors appear as white hatching while you draw, with
  a count in the toolbar. That feedback is what teaches you the rules, and KLayout does not have
  it.
- Magic **extracts**. It turns geometry back into a SPICE netlist, with parasitics, in one
  command. Labs 01, 03, 04, 05 and the capstone all rely on that.
- The open SKY130 ecosystem (netgen's setup file, `open_pdks`, LibreLane's sign-off) is wired to
  Magic's output formats.

This course also never asks you to draw a *minimum-size* cell. Your inverter in Lab 03 is
deliberately roomy, and Lab 05 measures what that roominess cost, which teaches you more than an
afternoon fighting the editor would.

Use KLayout for **looking**. It renders GDS well and has a proper layer browser, and you open your
finished capstone block in it.
