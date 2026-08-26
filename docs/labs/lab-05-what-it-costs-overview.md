# Lab 05 — What it costs

**Package:** [`labs/lab-05-what-it-costs/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-05-what-it-costs)

The same two transistors, drawn twice, priced.

## Prerequisites

Lab 03 passing. [What your drawing costs](guide/what-your-drawing-costs.md) ·
[Extraction is reverse engineering](guide/extraction-is-reverse-engineering.md)

## Objectives

- Extract a layout with **every** parasitic capacitance kept
- Measure a gate delay two different ways and understand why they disagree
- Build a ring oscillator and get a real number for one gate delay in SKY130
- Put a price on the layout choice you made in Lab 03

## Run it

```bash
cd labs/lab-05-what-it-costs
make
```

**Two to three minutes** — 114 s and 182 s on two timed clean runs, depending
on what else the machine is doing. Nearly all of it is the two ring
oscillators: 62 extracted subcircuits, 20 ns of transient, and ngspice reading
the whole SKY130 model library twice.

By default it compares the **reference** Lab 03 inverter against the foundry's.
To use your own:

```bash
make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
make
```

## What it prints

```
  THE SAME TWO TRANSISTORS, DRAWN TWICE

                                       yours       foundry           ratio
  ------------------------------------------------------------------------
  cell width                               3          1.38 um       2.17 x
  cell height                              6          2.72 um       2.21 x
  cell area                               18         3.754 um2      4.80 x

  NMOS: sky130_fd_pr__nfet_01v8
     W                                  0.65          0.65 um       1.00 x
     L                                  0.15          0.15 um       1.00 x
     drain junction area               0.715         0.169 um2      4.23 x
     drain junction perim                3.5          1.82 um       1.92 x
  PMOS: sky130_fd_pr__pfet_01v8_hvt
     W                                     1             1 um       1.00 x
     L                                  0.15          0.15 um       1.00 x
     drain junction area                 1.1          0.26 um2      4.23 x
     drain junction perim                4.2          2.52 um       1.67 x

  extracted capacitance, total         2.024         1.563 fF       1.29 x
       ... of it on the output        0.3035        0.3889 fF       0.78 x

  DELAY, fan-out of 4
  t_pHL                                40.21         35.98 ps       1.12 x
  t_pLH                                95.44          86.4 ps       1.10 x
  average                              67.82         61.19 ps       1.11 x

  RING OSCILLATOR, 31 stages, nothing but the cell driving itself
  period                                2720          2138 ps       1.27 x
  frequency                            367.6         467.8 MHz      0.79 x
  one stage                            43.88         34.48 ps       1.27 x
```

Every `1.00 x` in the W and L rows is the control. The transistors are
identical, down to the model name. **Everything else on that table is the
drawing.**

## Read the two delay rows twice

**11 % slower at fan-out 4. 27 % slower in a ring.** Same two cells.

A gate's delay is how long it takes to charge whatever hangs off its output,
and that load has two parts: what you are driving, and what you brought with
you. The second is your own drain junctions and wiring, and it is roughly a
fixed number of femtofarads.

At **fan-out 4** the four downstream gates dominate, and their input
capacitance is identical because W and L are identical. Your extra baggage is
a minority of the total.

In a **ring** each stage drives one gate and nothing else. Now your 4.23 ×
junction area is a big share of the total, and it shows.

> Layout parasitics behave like a fixed additive load. They disappear when a
> gate drives something big and they dominate when it drives something small —
> which is most of a chip.

## The row that looks backwards

```
  extracted capacitance, total         2.024         1.563 fF       1.29 x
       ... of it on the output        0.3035        0.3889 fF       0.78 x
```

By the second measure the foundry's cell is *worse*. That is real, and it is
worth understanding rather than explaining away.

The extracted `C` elements are **wire-to-wire coupling**, and the foundry cell
has more of it on the output precisely because everything in it is crammed
together. What that list does **not** contain is the **junction capacitance**
of the source and drain diffusions — that lives inside the device model,
computed from the `ad`, `as`, `pd` and `ps` parameters on each device line.
Yours are 4.23 × theirs.

You cannot read the answer off the parasitic netlist. You have to simulate it.
That is why this lab does.

```bash
make caps    # both parasitic netlists, side by side
```

## The ring oscillator, and where the 34 ps comes from

An odd number of inverters in a loop cannot settle: whatever it decides, it
disagrees with itself one lap later. So it oscillates, with period
$2 N t_p$, and that makes it the cleanest possible measurement of a single
gate delay — no source, no load, nothing but the cell driving one copy of
itself.

31 stages, the foundry's cell, extracted with parasitics:

```
period 2137.8 ps  ->  467.8 MHz  ->  34.48 ps per stage
```

**34 picoseconds is the floor** for this process at 1.8 V. Every timing number
in the capstone is a multiple of it, and the whole of
[Why the clock cannot go faster](guide/why-the-clock-cannot-go-faster.md)
is built on it.

`src/mkring.py` writes both rings; open it, it is thirty lines.

## Expected results

- [ ] `make` ends in `PASS` — there is no wrong answer here, only a measurement
- [ ] your W and L rows read `1.00 x`; if they do not, your cell is not the one
      Lab 03 asked for and the comparison is not isolating the drawing
- [ ] you can explain why FO4 and the ring disagree
- [ ] you can say where junction capacitance lives, and why it is not in the
      `C` lines

## Targets

| Command | What it does |
|---|---|
| `make` | extract both, simulate both, print the table |
| `make mine MAG=...` | copy your own Lab 03 cell in and compare that |
| `make pex` | just the extraction, about 4 s |
| `make caps` | both parasitic netlists, side by side |
| `make table` | re-print from results already on disk, instantly |
| `make clean` | delete `results/` |
