# Lab 01 — Open a cell you did not draw

**Package:** [`labs/lab-01-open-the-cell/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-01-open-the-cell)

Before you draw anything, get four tools to agree about somebody else's
layout. If they do, your toolchain is correct and everything that goes wrong
from here is a drawing problem — which is a far better problem to have.

## Prerequisites

[Getting started](guide/getting-started.md) ·
[What a layout actually is](guide/what-a-layout-actually-is.md) ·
[Anatomy of a standard cell](guide/anatomy-of-a-standard-cell.md)

## Objectives

- Load a real foundry standard cell into Magic
- Run the design rule check under **both** rule sets and understand why they
  disagree
- Extract the geometry back into a SPICE netlist and read every field of it
- Get netgen to confirm that netlist is what the foundry says the cell is

## Run it

```bash
cd labs/lab-01-open-the-cell
make
```

No environment setup needed. The `Makefile` pins `PDK=sky130A` itself, so this
runs in a bare container even if `.designinit` failed you.

Expected, in about **one and a half seconds** (1.35, 1.46 and 1.60 s on three
timed clean runs):

```
== magic: load, DRC, extract   (sky130_fd_sc_hd__inv_1)
== netgen: layout vs the foundry's own netlist

  THE FOUNDRY'S INVERTER, MEASURED BY YOUR TOOLS

  ok  cell width                              1.38 um   (reference 1.38)
  ok  cell height                             2.72 um   (reference 2.72)
  ok  DRC violations, default style                 0   (reference 0)
  ok  DRC violations, full style                    3   (reference 3)
  ok  devices extracted                             2   (reference 2)

      cell area  1.38 x 2.72 = 3.7536 um^2

  THE TWO TRANSISTORS IT FOUND
      X0  sky130_fd_pr__nfet_01v8          W=0.65  L=0.15   drain area 0.169 um^2
      X1  sky130_fd_pr__pfet_01v8_hvt      W=1  L=0.15   drain area 0.26 um^2

  LVS: Circuits match uniquely

  THE THREE THINGS THE FULL RULE SET COMPLAINS ABOUT
      All nwells must contain metal-connected N+ taps (nwell.4)
      P-diff distance to N-tap must be < 15.0um (LU.3)
      N-diff distance to P-tap must be < 15.0um (LU.2)
      ...

PASS  Magic read the foundry's own layout, found zero violations under the
      default rule set and the three expected context rules under the full
      one, pulled two transistors out of the geometry, and netgen agreed
      they are the circuit the foundry says the cell is.
```

## The three violations are the point of the lab

**The foundry's own cell fails the full rule set.** Read that again before you
assume you broke something.

All three are the same omission: this cell has no well tap, so the n-well is
not tied to VPWR and the substrate is not tied to VGND. That is deliberate —
taps cost area and a tap every 1.38 µm is far more than the process needs, so
the library puts them in a separate cell (`sky130_fd_sc_hd__tapvpwrvgnd_1`,
0.46 µm wide) and the flow drops a few into each row.

> **"DRC clean" is not a property of a cell. It is a property of a cell in a
> context.**

Meeting that here, on a cell you cannot possibly have damaged, is much cheaper
than meeting it in the capstone and assuming you did.

## Procedure

### L1 — Look at it

```bash
make gui
```

Magic opens with the cell loaded. Find, using
[Anatomy of a standard cell](guide/anatomy-of-a-standard-cell.md) as a map:

- the n-well across the top, and the p-diffusion inside it
- the n-diffusion in the bottom half
- the **single** poly stripe crossing both — that is why the two gates are
  connected without a wire
- the two metal1 rails, straddling y = 0 and y = 2.72
- the contacts, every one of them 0.17 µm square

Then find something that is *not* there: a well tap.

### L2 — Read the netlist

```bash
make netlist
```

```spice
.subckt sky130_fd_sc_hd__inv_1 A VGND VNB VPB VPWR Y
X0 Y A VGND VNB sky130_fd_pr__nfet_01v8     ad=0.169 pd=1.82 as=0.169 ps=1.82 w=0.65 l=0.15
X1 Y A VPWR VPB sky130_fd_pr__pfet_01v8_hvt ad=0.26  pd=2.52 as=0.26  ps=2.52 w=1    l=0.15
.ends
```

Six ports, and two of them are `VNB` and `VPB` — the bulk terminals. The cell
exposes its own substrate and well as pins, precisely *because* it does not
tie them to anything itself.

Note `w=0.65` and `w=1`. Nobody typed those. Magic measured the height of two
rectangles.

Note `pfet_01v8_hvt`. The PMOS is the high-threshold flavour, and you will
have to remember that in Lab 03.

### L3 — Do it by hand

Everything `make` just did is nine commands you can type. In the tkcon console:

```tcl
drc euclidean on
drc check
drc count
drc style drc(full)
drc check
drc count
drc why
extract do local
extract all
ext2spice lvs
ext2spice -o /tmp/inv.spice
```

Type them. Watch the count change when the rule set does. This is the flow for
every remaining lab in this course and it is worth having run it once with
your own fingers.

### L4 — Look at the library

```bash
ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/ | wc -l     # 446
ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/ | grep __inv_
```

Seven inverters: `inv_1 inv_2 inv_4 inv_6 inv_8 inv_12 inv_16`. Same logic,
increasing drive strength. Open `inv_8` next to `inv_1` and see where the
factor of eight went.

```bash
make klayout
```

opens the whole library GDS in KLayout, which is a much better viewer than
Magic and cannot edit anything, so it is safe to browse.

## Expected results

- [ ] `make` ends in `PASS`
- [ ] you can point at the n-well, the two diffusions, the poly stripe and the
      two rails in the Magic window
- [ ] you can say why the full rule set finds three violations in a cell that
      has been taped out hundreds of times
- [ ] you know what `w=0.65` in the extracted netlist is the height of

## Files

| Path | What it is |
|---|---|
| `.magicrc` | the two lines that load SKY130 into Magic |
| `tcl/inspect.tcl` | the Magic script `make` runs, in the order you would type it |
| `src/check.py` | reads what Magic and netgen produced and prints the verdict |

## If it fails

| What you see | What it is |
|---|---|
| `DRC violations, default style` is not 0 | The technology did not load. Check `$PDK_ROOT` is set and that `.magicrc` is in the directory you ran `make` from. |
| `results/report.txt is missing` | Magic did not finish. `cat results/magic.log`. |
| `LVS: netgen wrote no report` | `cat results/netgen.log`. Usually `$PDK_ROOT` again. |
| `magic: command not found` | You are not in the workbench container. |
