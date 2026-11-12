# Extraction

You drew rectangles. Extraction is Magic reading those rectangles and working out **what circuit
they actually form**, which is not necessarily the circuit you meant. That is the point: an
extractor that reported your intentions would be useless.

## The commands

```tcl
extract do local          ;# extract this cell's own geometry
extract all               ;# ...and every subcell in it
ext2spice lvs             ;# format the result for netgen
ext2spice -o my_inv.spice
```

`extract` writes a `.ext` file, which is Magic's own format and not very readable. `ext2spice`
turns it into SPICE. The `lvs` argument is a preset that turns off what netgen does not want: no
parasitic resistors, hierarchical subcircuits, and no `.include` of the models.

## Reading the netlist

From the inverter you draw in Lab 03:

```spice
.subckt my_inv A Y VPWR VGND
X0 Y A VGND VGND sky130_fd_pr__nfet_01v8     ad=0.715 pd=3.5 as=0.6175 ps=3.2 w=0.65 l=0.15
X1 Y A VPWR VPWR sky130_fd_pr__pfet_01v8_hvt ad=1.1   pd=4.2 as=0.95   ps=3.9 w=1    l=0.15
.ends
```

Every field comes from a rectangle you drew:

| Field | Where it came from |
|---|---|
| `.subckt my_inv A Y VPWR VGND` | the four labels you placed, promoted by `port makeall` |
| `X0 Y A VGND VGND` | drain, gate, source, bulk, worked out from what touches what |
| `w=0.65` | the **height** of the n-diffusion under the poly |
| `l=0.15` | the **width** of the poly stripe where it crosses |
| `ad=0.715` | the area of the drain diffusion, in µm² |
| `pd=3.5` | the perimeter of the drain diffusion, in µm |
| `sky130_fd_pr__pfet_01v8_hvt` | the device flavour, decided by which implant layer you painted |

Nobody expects `ad` and `pd`, and they matter a great deal. Every square micron of drain
diffusion is a reverse-biased junction to the well, and a reverse-biased junction is a capacitor.
Your inverter's drain area is **4.2 times** the foundry's; Lab 05 measures what that costs.

## Node names you did not choose

Extract a NAND and you get a node called something like `a_300_260#`:

```spice
X0 a_300_260# A VGND VGND sky130_fd_pr__nfet_01v8 w=0.65 l=0.15
X3 Y B a_300_260# VGND     sky130_fd_pr__nfet_01v8 w=0.65 l=0.15
```

That node is the shared diffusion between the two series NMOS, the piece of silicon with no
contact on it. You never labelled it, so Magic named it after its coordinates and added a `#` to
mark it as internal. Seeing that name confirms that the two devices share one strip of diffusion,
which is what you drew them to do.

A node name with a `#` is fine. A node *you* labelled showing up with a `#` means the label did
not land on the geometry you thought it did.

## PMOS flavours

The two PMOS models are not interchangeable:

```
sky130_fd_pr__pfet_01v8        # regular threshold
sky130_fd_pr__pfet_01v8_hvt    # high threshold
```

Which one you get depends on whether the `pfethvt` implant layer covers the gate region. The
foundry's standard cells all use the **hvt** PMOS. If you draw a PMOS and forget the implant,
you get the regular one, and:

- **DRC never mentions it.** Both are legal devices.
- The layout looks identical apart from one hatched rectangle.
- LVS fails with a device-class mismatch, which is the good outcome.
- Without LVS you would ship a chip with the wrong threshold voltages everywhere.

Lab 03's checker names this mistake if you make it.

## Two kinds of extraction

The same geometry, extracted two ways, gives two different netlists:

```tcl
ext2spice lvs             ;# devices only. This is what LVS wants.
ext2spice cthresh 0       ;# ...and every parasitic capacitance as well
```

`cthresh` is a threshold in femtofarads below which capacitances are thrown away. The default
drops the small ones, and most of them are small. Set it to `0` and Magic keeps everything it
found:

```spice
.subckt my_inv A Y VPWR VGND
X0 Y A VGND VGND sky130_fd_pr__nfet_01v8     ...
X1 Y A VPWR VPWR sky130_fd_pr__pfet_01v8_hvt ...
C0 A Y      0.02936f
C1 Y VPWR   0.06727f
C2 A VPWR   0.10808f
C3 Y VGND   0.20685f
C4 A VGND   0.27253f
C5 VPWR VGND 1.33952f
.ends
```

That is six capacitors nobody drew. Any two conductors near each other form a capacitor, and a
layout is conductors near each other.

**Use the `lvs` netlist for LVS and the `cthresh 0` one for simulation.** Every lab in this course
writes both. Comparing a parasitic netlist against a schematic in netgen only produces noise.

## What extraction does not know

- **It does not know what you meant.** Checking that is LVS's job, on the
  [next page](guide/lvs-asks-a-different-question.md).
- **It does not model resistance by default.** `ext2spice` can extract resistors too, but the
  flow gets much slower and this course does not need it. Keep in mind that li is about
  12.8 Ω per square while metal1 is 0.125, so a long li wire is a real resistor that this
  course's numbers leave out.
- **It does not model the third dimension beyond the layer stack.** It is a 2.5-D extractor:
  good enough that its answers are useful, not good enough for sign-off.
