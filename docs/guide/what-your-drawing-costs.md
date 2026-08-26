# What your drawing costs

Here is the experiment this whole course is built around.

Take **the same two transistors** — same width, same length, same device
flavours, down to the model name. Draw them twice. Once the way the foundry
did, packed to the last 0.005 µm. Once the way you will in Lab 03, with room
to move.

Everything that differs after that is *the drawing*.

![Yours on the left, the foundry's on the right, at the same scale](../assets/img/ad104-magic-side-by-side.png)

*Both cells are one NMOS at W = 0.65 µm and one high-Vt PMOS at W = 1 µm,
L = 0.15 µm for both. Same devices. 4.8 times the area.*

## The numbers

These come out of [Lab 05](../labs/lab-05-what-it-costs-overview.md), which
runs the extraction and both simulations and prints this table:

| | yours | the foundry's | ratio |
|---|---|---|---|
| cell width | 3.00 µm | 1.38 µm | 2.17 × |
| cell height | 6.00 µm | 2.72 µm | 2.21 × |
| **cell area** | **18.00 µm²** | **3.7536 µm²** | **4.80 ×** |
| NMOS W / L | 0.65 / 0.15 | 0.65 / 0.15 | 1.00 × |
| PMOS W / L | 1 / 0.15 | 1 / 0.15 | 1.00 × |
| NMOS drain junction area | 0.715 µm² | 0.169 µm² | 4.23 × |
| PMOS drain junction area | 1.1 µm² | 0.26 µm² | 4.23 × |
| extracted capacitance, total | 2.024 fF | 1.563 fF | 1.29 × |
| **FO4 delay, average** | **67.82 ps** | **61.19 ps** | **1.11 ×** |
| **ring-oscillator stage delay** | **43.88 ps** | **34.48 ps** | **1.27 ×** |

Read the two delay rows twice. **They disagree, and the disagreement is the
lesson.**

## Why the same cell is 11 % slower in one test and 27 % slower in the other

A gate's delay is (roughly) how long its transistors take to charge whatever is
hanging off the output. That load has two parts:

- **the load you are driving** — the gate capacitance of the cells downstream
- **the load you brought with you** — your own drain junctions and your own
  wiring, which have to be charged whether anything is connected or not

The second part is the part your layout controls, and it is close to a fixed
number of femtofarads.

**Fan-out of 4** means the output drives four copies of the same cell. The
downstream gate capacitance dominates, and it is identical in both cases
because W and L are identical. Your extra junction area is a minority
shareholder, so you come out 11 % behind.

**A ring oscillator** is each stage driving exactly one copy of itself and
nothing else. Now the self-load is a much bigger fraction of the total, and
your 4.23 × junction area shows up properly: 27 % behind.

> **Layout parasitics are approximately a fixed additive load. They vanish
> into the noise when a gate drives something big and they dominate when it
> drives something small.**

And most gates in a real chip drive something small. This is why the foundry
packs cells to the last nanometre even though "it is only a few femtofarads".

## Where the femtofarads come from

Look at what `ext2spice cthresh 0` pulls out of each cell:

```
yours                         the foundry's
C0 A Y       0.02936f         C0 VGND VPB  0.01319f
C1 Y VPWR    0.06727f         C1 Y VPWR    0.12759f
C2 A VPWR    0.10808f         C2 A VPB     0.04506f
C3 Y VGND    0.20685f         C3 VGND Y    0.09986f
C4 A VGND    0.27253f         C4 A Y       0.04760f
C5 VPWR VGND 1.33952f         ... 15 in total
```

Your total is higher, but notice the row Lab 05 prints as *"of it on the
output"*: **0.3035 fF for yours against 0.3889 fF for theirs.** By that
measure the foundry cell is *worse*.

That is not a mistake, and it is worth sitting with. The extracted capacitors
are **wire-to-wire** coupling. The foundry cell has more of it on the output
because everything in it is crammed together. What the extracted capacitor
list does *not* contain is the **junction capacitance** of the source and
drain diffusions — that lives inside the device model, computed from the `ad`,
`as`, `pd` and `ps` parameters, and yours are 4.23 × theirs.

So the honest accounting is:

- wire coupling: roughly a wash, slightly against the foundry
- junction capacitance: badly against you, by a factor of four
- and junction capacitance is the bigger number

You cannot read this off the parasitic netlist. You have to simulate it, which
is exactly why Lab 05 does.

## The other axis: area is not a vanity metric

18 µm² against 3.75 µm² sounds like an academic difference until you multiply.

A modest open-source SoC has a few hundred thousand standard cells. At the
foundry's density that is about 1.5 mm² of logic; at yours it is 7 mm². Die
cost goes roughly with area, and yield goes *down* with area, so the finished
chip is several times more expensive per unit and you get fewer good ones per
wafer. That is the entire commercial argument for a standard-cell library, and
it is why a library is drawn once, by someone very patient, and then instanced
a million times.

## What you should take away

Not "your layout is bad". Your layout is deliberately roomy so that it is
drawable by hand in an afternoon, and Lab 05's job is to price that choice
honestly.

Take away this instead:

1. **Identical transistors do not give identical circuits.** Everything not in
   the schematic is in the layout.
2. **The cost of a loose layout is small per gate and enormous per chip.**
3. **You can measure it.** The gap between your cell and the foundry's is four
   commands and ninety seconds, not an argument.
