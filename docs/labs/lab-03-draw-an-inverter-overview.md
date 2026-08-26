# Lab 03 — Draw an inverter

**Package:** [`labs/lab-03-draw-an-inverter/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-03-draw-an-inverter)

AD103's capstone was a CMOS inverter you could simulate. This is the same
circuit as geometry: two transistors, one shared gate, DRC clean under both
rule sets, and proved by netgen to be what you meant.

## Prerequisites

Lab 02 finished. [Drawing in Magic](guide/drawing-in-magic.md) ·
[Stick diagrams](guide/stick-diagrams.md) ·
[Extraction is reverse engineering](guide/extraction-is-reverse-engineering.md) ·
[LVS asks a different question](guide/lvs-asks-a-different-question.md)

## Objectives

- Draw a transistor as rectangles and have a tool read $W$ and $L$ back out of it
- Get to zero violations under the **full** rule set
- Get `Circuits match uniquely` out of netgen
- Meet a mistake that DRC cannot see and LVS can

## The sizes, and why these ones

**Wn = 0.65 µm, Wp = 1.00 µm, L = 0.15 µm.**

Those are exactly `sky130_fd_sc_hd__inv_1`'s numbers, which you read in Lab 01.
That is deliberate: in [Lab 05](labs/lab-05-what-it-costs-overview.md) you put your
cell next to the foundry's and measure the difference, and holding the
transistors identical means **the only thing left to compare is the drawing**.

L = 0.15 µm is the SKY130 minimum (`poly.1a`). Your cell will still be nearly
five times the foundry's area, because area is about packing, not about $L$.

## Run it

```bash
cd labs/lab-03-draw-an-inverter
make scaffold     # lay down the frame (also: start over)
make edit         # open it in Magic
make              # check what you have, about 1.1 s
```

On the bare scaffold, `make` says:

```
  WHAT MAGIC FOUND IN my_inv.mag

      transistors            0   (0 n, 0 p)

      ports                  VGND VPWR

      DRC, default rule set  0
      DRC, full rule set     0

      LVS                    Top level cell failed pin matching.

FAIL  No transistors at all. A transistor is the place where a poly stripe
      crosses a diffusion. If Magic sees no crossing, either the poly does
      not overlap the diffusion, or one of them is not the layer you think
      it is - check the layer name in the title bar as you paint.
```

Every failure in this lab is reported like that: in words, naming the layer or
the rule. Fix one thing, run `make` again.

## What the frame already contains

![The frame you start from](../assets/img/ad104-magic-frame.png)

*Everything except the transistors. The n-well is the grey hatch across the
top half and the p-substrate the orange hatch below it; the green strip is the
n-well tap and the brown one the substrate tap, each with a contact and a
short li run up to a purple metal1 rail. The middle is yours.*

`make scaffold` gives you everything that is not a transistor:

- the n-well (y = 3.00 to 6.00) and the p-well below it
- the two metal1 supply rails, with `VGND` and `VPWR` already labelled
- both **well taps**, contacted, with li up to the rails through `mcon`

So the tap trap from Lab 02 is already handled. What is missing is the middle
of the cell.

## Procedure

### L1 — Sketch it first

On paper. The stick diagram from
[Stick diagrams](guide/stick-diagrams.md): PMOS above, NMOS below, one
vertical poly stripe crossing both, output on the right, input on the gate.
Ninety seconds, and it will save you an hour.

### L2 — The two diffusions

In the tkcon console, or by painting:

```tcl
box 0.40um 1.30um 2.60um 1.95um
paint ndiff                        ;# 0.65 um tall. The height IS W.

box 0.40um 3.50um 2.60um 4.50um
paint pdiff                        ;# 1.00 um tall, inside the nwell
```

The n-well already extends from 3.00, so the PMOS diffusion clears it by
0.50 µm — comfortably over the 0.18 µm `diff/tap.8` needs.

### L3 — The gate

```tcl
box 1.35um 1.05um 1.50um 4.75um
paint poly
```

**0.15 µm wide — that width is L.** It runs from below the NMOS diffusion to
above the PMOS one, overhanging each by 0.25 µm, because a gate that stops
inside the diffusion leaves a leakage path round its end (`poly.8`).

Save, then run `make`:

```tcl
save my_inv
```

`make` reads `mag/my_inv.mag` off the disk. Painting in Magic changes what is on
your screen, not what is in that file, so until you `save` every `make` reports
on the last version you wrote — the output does not change and nothing tells you
why. Save before every `make` from here on. (L6 sets the labels and ports; the
`save` is needed long before that.)

Two transistors should appear, with the right W and L, and `drc` should still be
at zero.

### L4 — Contacts

Four of them, each **exactly 0.17 × 0.17 µm**:

```tcl
box 0.55um 1.55um 0.72um 1.72um ; paint ndc     ;# NMOS source
box 2.28um 1.55um 2.45um 1.72um ; paint ndc     ;# NMOS drain
box 0.55um 3.90um 0.72um 4.07um ; paint pdc     ;# PMOS source
box 2.28um 3.90um 2.45um 4.07um ; paint pdc     ;# PMOS drain
```

The gate needs one too, and it cannot go on the 0.15 µm stripe — `licon.8`
wants 0.05 µm of poly around a 0.17 µm cut, which needs 0.27 µm of stripe. So
draw a landing pad in the gap between the diffusions:

```tcl
box 1.20um 2.30um 1.65um 2.75um ; paint poly
box 1.34um 2.44um 1.51um 2.61um ; paint pc
```

### L5 — Wire it in li

Four runs. Each has to overhang its contacts by 0.08 µm **on both sides of one
axis** (`li.5`), which is what the 0.37 µm width is for:

```tcl
box 0.45um 0.05um 0.82um 1.82um ; paint li    ;# VGND: tap -> NMOS source
box 2.18um 1.45um 2.55um 4.17um ; paint li    ;# Y: NMOS drain -> PMOS drain
box 0.45um 3.80um 0.82um 5.95um ; paint li    ;# VPWR: PMOS source -> tap
box 1.24um 2.34um 1.61um 2.71um ; paint li    ;# A: the gate
```

### L6 — Name it

```tcl
box 1.30um 2.40um 1.55um 2.65um ; label A c li
box 2.25um 2.60um 2.50um 2.85um ; label Y c li
select top cell
port makeall
save my_inv
```

Run `make`. You should now have four ports and two transistors.

### L7 — The one DRC will never tell you

Run `make` and read the device line:

```
  X1   sky130_fd_pr__pfet_01v8      W=1  L=0.15
```

`pfet_01v8`, not `pfet_01v8_hvt`. **You have built the wrong transistor.**

The foundry's PMOS is the high-threshold flavour, and which one you get is
decided by an implant mask that nothing in the drawing suggests. DRC has no
opinion — both are legal devices. LVS catches it, which is the whole argument
for running LVS.

```tcl
box 1.35um 3.50um 1.50um 4.50um
paint pfethvt
```

## What PASS looks like

```
  WHAT MAGIC FOUND IN my_inv.mag

      transistors            2   (1 n, 1 p)
        X0   sky130_fd_pr__nfet_01v8          W=0.65  L=0.15
        X1   sky130_fd_pr__pfet_01v8_hvt      W=1  L=0.15

      ports                  A Y VPWR VGND

      DRC, default rule set  0
      DRC, full rule set     0

      LVS                    Circuits match uniquely.

PASS  Two transistors, the right flavours, the right W and L, four ports,
      zero DRC violations under both rule sets, and netgen agrees your
      geometry is the schematic.
```

![The finished cell](../assets/img/ad104-magic-my-inv.png)

## Expected results

- [ ] `make` ends in `PASS`
- [ ] `make netlist` shows two devices, `w=0.65` and `w=1`, both at `l=0.15`
- [ ] you can point at the rectangle whose height is `w=0.65`

## About being wrong the first time

The reference cell in `solutions/` was not right first time either. Its first
version had **62 violations across seven rules** — contacts too close to the
edges of their diffusion, li exactly the size of the contacts under it, a
0.15 µm gate stripe with a 0.17 µm contact on it, taps with no overhang. The
second version had zero.

Two iterations, because you cannot hold thirty enclosure rules in your head
and are not expected to. Draw the thing that is obviously right, let the
checker name the places you were wrong, change those numbers.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC both ways, extract, LVS, verdict |
| `make edit` | open your cell in Magic |
| `make scaffold` | **throw your cell away** and start from the frame |
| `make netlist` | print what Magic extracted from your geometry |
| `make ref` | rebuild `solutions/inv_ref.mag` from `tcl/inverter.tcl` |
| `make refcheck` | run every check against the reference instead of yours |
| `make clean` | delete `results/` |

`tcl/inverter.tcl` is the reference cell drawn command by command, with a
comment on every line explaining the number. Read it **after** yours works.
