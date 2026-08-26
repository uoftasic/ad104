# Anatomy of a standard cell

Before you draw one, read one. The SKY130 high-density library ships **446
cells** in `$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/`, and the smallest
of them is the inverter you are about to reinvent.

Lab 01 opens `sky130_fd_sc_hd__inv_1` and gets four tools to agree about it.
This page is what to look at while you are in there.

## The shape of the deal

A standard cell is a transistor-level layout that has agreed to obey a few
constraints so that a machine can place thousands of them without thinking:

| Constraint | `sky130_fd_sc_hd` |
|---|---|
| Every cell is the same **height** | **2.72 µm** |
| Every cell's **width** is a multiple of one site | 0.46 µm |
| Power rails sit at the same y in every cell, in metal1 | VGND straddles y = 0, VPWR straddles y = 2.72 |
| Rails span the full width, so abutting cells connect them | yes |
| Pins are on **li1**, reachable from above | yes |

`inv_1` is **1.38 µm × 2.72 µm = 3.7536 µm²**, which Lab 01 prints. The
`FIXED_BBOX` property in the `.mag` file says `0 0 276 544`, in units of
0.005 µm — multiply by 0.005 and you get exactly those two numbers.

Because the rails straddle the boundary, two cells side by side share half a
rail each and the supply is continuous across the row with no wire drawn.
Flip a cell vertically and put it above, and the rails are shared again. That
single decision is why chips are built out of rows.

## The parts, in `inv_1`

Open it (`make gui` in Lab 01) and find:

- **an n-well** across the top half, with p-diffusion inside it — the PMOS
- **n-diffusion** in the bottom half — the NMOS
- **one poly stripe** crossing both. `w=0.65 l=0.15` for the NMOS and
  `w=1 l=0.15` for the PMOS, which Lab 01 reads back out of the geometry
- **six ports**: `A`, `Y`, `VPWR`, `VGND`, and two you would not have guessed:
  **`VPB`** and **`VNB`**, the p-bulk and n-bulk. The cell exposes its own well
  and substrate as terminals.

That last one is the interesting part.

## The cell has no well tap, and that is deliberate

Run the full design-rule check on the foundry's own inverter and it fails.
Lab 01 does exactly that and prints:

```
      DRC, default rule set  0
      DRC, full rule set     3

      All nwells must contain metal-connected N+ taps (nwell.4)
      P-diff distance to N-tap must be < 15.0um (LU.3)
      N-diff distance to P-tap must be < 15.0um (LU.2)
```

Three violations, in a cell shipped by the foundry, in a library that has been
taped out hundreds of times.

They are all the same omission: **there is no tap in this cell.** The n-well is
not tied to VPWR and the substrate is not tied to VGND, which is why `VPB` and
`VNB` are ports rather than being wired internally.

This is not a bug and it is not sloppiness. Taps cost area, and a tap every
1.38 µm is far more than any process needs — the latch-up rule only asks for
one within 15 µm. So the library puts them in a **separate cell**,
`sky130_fd_sc_hd__tapvpwrvgnd_1`, 0.46 µm wide, and the flow drops a handful
into each row. You will do that by hand in the capstone.

The lesson generalises past taps:

> **"DRC clean" is not a property of a cell. It is a property of a cell in a
> context.** Some rules can only be satisfied by a cell's neighbours, and a
> checker run on one cell in isolation will report them as failures forever.

Meeting this on the foundry's cell, in the first lab, is much cheaper than
meeting it on your own cell in the third one and assuming you broke something.

## Drive strength is the number after the underscore

```
sky130_fd_sc_hd__inv_1   inv_2   inv_4   inv_6   inv_8   inv_12   inv_16
sky130_fd_sc_hd__and2_0  and2_1  and2_2  and2_4
```

Same logic function, wider transistors, more current, more area, more input
capacitance. `and2_0` is the *weakest* AND in the library; `and2_4` is roughly
four times the drive. Choosing between them is most of what a synthesis tool
does with its afternoon, and in the capstone you will be handed `and2_0`
specifically so you can see what the cheapest choice costs in delay.

## Who drew these, and with what?

A fair question, and the `.mag` file answers it. At the bottom of
`sky130_fd_sc_hd__inv_1.mag`:

```
string GDS_FILE $PDKPATH/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
string GDS_START 2268880
string GDS_END 2272374
```

That is not a layout. It is a **byte range in the foundry's GDS file**. The
`.mag` you are looking at was produced by `open_pdks` reading SkyWater's
released GDSII back into Magic so the cells could be used in an open flow, and
it keeps a pointer home. When you write GDS from a design that instantiates
these cells, Magic does not re-generate their geometry at all — it copies
those bytes straight through. You can watch it say so:

```
   Copying output for cell sky130_fd_sc_hd__and2_0 from $PDKPATH/.../sky130_fd_sc_hd.gds
   Generating output for cell datapath_ref
```

So: **the foundry drew them, in a commercial tool, and shipped GDSII.** Magic
is the reader, not the author.

Which raises the practical question — is Magic the right tool for *you* to
draw a minimum-size cell in? Honestly: it is rough. Magic thinks in tiles and
in a "corner-stitched" plane model that makes some edits behave in ways that
surprise people from a polygon editor, and packing a cell to the last 0.005 µm
in it is a fight. KLayout is a nicer polygon editor.

This course uses Magic anyway, for reasons that are about the *flow*, not the
editor:

- Magic has a **live design-rule checker**. Errors appear as white hatching as
  you draw, with a count in the toolbar. That feedback loop is the thing that
  teaches you the rules, and KLayout does not have it.
- Magic **extracts**. It turns geometry back into a SPICE netlist, with
  parasitics, in one command. That is Labs 01, 03, 04, 05 and the capstone.
- The whole open SKY130 ecosystem — netgen's setup file, `open_pdks`,
  LibreLane's sign-off — is wired to Magic's output formats.

And this course never asks you to draw a *minimum-size* cell. Your inverter in
Lab 03 is deliberately roomy. Lab 05 then measures exactly what that roominess
cost, which is a better lesson than fighting the editor for an afternoon.

Use KLayout for **looking**: it renders GDS beautifully, it has a proper layer
browser, and the capstone opens your finished block in it.
