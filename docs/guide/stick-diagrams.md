# Stick diagrams

Do not open Magic yet. Get a pen.

A stick diagram is a layout with all the dimensions thrown away. Coloured
lines for the layers, crosses for the contacts, no measurements at all. It
answers the only question that is expensive to get wrong — **what order are
things in?** — and it answers it in ninety seconds instead of an hour.

## The convention

Four colours, one rule each:

| | |
|---|---|
| **Green** | n-diffusion. Runs horizontally. Anything it touches is at NMOS level. |
| **Yellow / brown** | p-diffusion. Also horizontal, up in the n-well. |
| **Red** | polysilicon. Runs **vertically**. Every red line crossing a diffusion is one transistor. |
| **Blue** | metal (or li). Runs wherever it likes; it is above everything. |
| **×** | a contact: a connection between two of the above. |

And two conventions that make every cell in a library look alike:

- **Power at the top, ground at the bottom**, in horizontal metal, spanning
  the full width of the cell.
- **PMOS above, NMOS below.** PMOS is in the n-well and the n-well is tied to
  the positive rail, so this is not an aesthetic choice.

## The inverter, in one minute

```
   VDD  ═══════════════════════════════
                    ×
        ┌───────────╫───────────┐
   pdiff│           ║           │        (in the n-well)
        └───────────╫───────────┘
                    ║  ×────────────── Y
        ┌───────────╫───────────┐
   ndiff│           ║           │
        └───────────╫───────────┘
                    ×
   GND  ═══════════════════════════════
                    ║
                    A   (poly, vertical)
```

One red stripe. It crosses the p-diffusion once and the n-diffusion once, so
it makes two transistors, and because it is one stripe their gates are already
connected. **That is the whole reason a CMOS inverter is compact**: the shared
gate is free, and you get it by drawing one rectangle instead of two plus a
wire.

Now compare that to your AD103 schematic, which needed an explicit wire from
one gate to the other. The layout is *simpler* than the schematic here. It
will not be again.

## The NAND, and the one idea worth the pen

A 2-input NAND is two NMOS **in series** and two PMOS **in parallel**.

Series means: the drain of one is the source of the other. On a schematic
that is a wire. On silicon, "the drain of one is the source of the other"
means **they are the same piece of diffusion**. Draw one strip, put two poly
stripes across it, and the region between them *is* the shared node. It needs
no contact, no wire, and no space.

```
   VDD  ══════════════════════════════════════
              ×             ×            ×
        ┌─────╫─────────────╫────────────┐
   pdiff│     ║             ║            │      two PMOS, parallel
        └─────╫──────×──────╫────────────┘
              ║      └──────╫─────────────── Y
        ┌─────╫─────────────╫────────────┐
   ndiff│     ║             ║            │      two NMOS, series
        └─────╫─────────────╫──────×─────┘
              ║             ║      └───────────┘
              ×             ║
   GND  ══════════════════════════════════════
              A             B
```

Count the contacts on the n-diffusion: **two**, at the two ends. The middle of
that strip carries current and has nothing on it. A contact there would cost
you area, add junction capacitance to an internal node, and buy nothing.

![The NAND2 you get from that sketch](../assets/img/ad104-magic-nand2.png)

*The same drawing, drawn. Two red poly stripes. The green n-diffusion runs
under both of them with contacts only at the far left and far right — the
region between the gates has none. The orange p-diffusion above has three
contacts, because parallel devices alternate source, drain, source.*

## Why order is the expensive decision

For a 2-input gate the order barely matters. For anything bigger it decides
whether the cell is one strip of diffusion or three, and each break in the
strip costs you a contact, a gap, and roughly a quarter of a micron of width.

The rule of thumb, and it is genuinely all you need at this level: **arrange
the inputs so that consecutive transistors in the series chain share a
terminal.** If you write the gate as a chain of source–drain pairs and no pair
repeats an ordering, you can draw it as one unbroken strip. (Formally this is
asking whether the transistor graph has an Euler path; informally it is
"can I walk through all of them without lifting the pen".)

You will not need to do this in AD104. You will need to recognise, when you
look at the foundry's `and2_0` in Lab 04 and see a single unbroken diffusion
strip with two gates on it, that someone had this thought first.

## Do this before Lab 03

On paper:

1. Draw the inverter stick diagram from memory. Not copied — from memory.
2. Mark **where the two well taps go** and which rail each one connects to.
   (They are not in the sketch above. That omission is the most common bug in
   a first layout, and drawing them by hand once is cheap insurance.)
3. Decide which side of the cell the input is on and which side the output is
   on, and why.

Then go and play with [SiliWiz](guide/siliwiz.md) for twenty minutes, which will let
you build roughly that and watch a cross-section of it appear.
