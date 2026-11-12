# Lab 05 — What it costs

You'll extract the Lab 03 inverter and the foundry's `inv_1` with every parasitic capacitance
kept, simulate both, and put a price on the drawing: the same two transistors, drawn twice,
measured for area and delay.

Package: [`labs/lab-05-what-it-costs/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-05-what-it-costs)

## Before you start

- Get [Lab 03](labs/lab-03-draw-an-inverter-overview.md) to `PASS`.
- Read [Area, parasitics and delay](guide/what-your-drawing-costs.md). This lab also uses
  [Extraction](guide/extraction-is-reverse-engineering.md).

**Time:** about 1 hour, most of it reading the results. Each full `make` takes two to three
minutes (114 s and 182 s on two timed clean runs, depending on what else the machine is doing).
Nearly all of that is the two ring oscillators: 62 extracted subcircuits, 20 ns of transient, and
ngspice reading the whole SKY130 model library twice.

## Part 1: Run the comparison

1. Go into the lab package and run it:

   ```bash
   cd labs/lab-05-what-it-costs
   make
   ```

   By default it compares the **reference** Lab 03 inverter with the foundry's. Part 5 (optional)
   swaps in your own. It prints:

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

2. Find the four `1.00 x` rows for W and L. They are the control: the transistors are identical,
   down to the model name, so **everything else on the table comes from the drawing.**

**You should see** `1.00 x` on every W and L row, and `make` ending in `PASS`. There is no wrong
answer in this lab, only a measurement.

## Part 2: Compare the two delay rows

1. Find the two delay ratios: **1.11 x at fan-out 4, 1.27 x in the ring.** Your cell is 11 %
   slower in one test and 27 % slower in the other.

2. Explain the difference before you read on. Hint: a gate's delay is how long it takes to charge
   whatever hangs off its output, and that load has two parts, what you are driving and what you
   brought with you.

[Area, parasitics and delay](guide/what-your-drawing-costs.md#fo4-delay-and-ring-oscillator-delay)
has the full explanation. In short: at fan-out 4 the four downstream gates dominate the load, and
their input capacitance is identical for both cells. In the ring each stage drives one gate and
nothing else, so your 4.23 × junction area is a large share of the total.

**You should see** that the self-loaded test (the ring) shows the bigger penalty.

## Part 3: Look at the capacitors

1. Print both parasitic netlists side by side:

   ```bash
   make caps
   ```

2. Compare the two rows that seem to disagree:

   ```
     extracted capacitance, total         2.024         1.563 fF       1.29 x
          ... of it on the output        0.3035        0.3889 fF       0.78 x
   ```

   By the second measure the foundry's cell is *worse*. That is real. The extracted `C` elements
   are **wire-to-wire coupling**, and the foundry cell has more of it on the output because
   everything in it is packed close together.

3. Answer for yourself: where does the **junction capacitance** of the source and drain
   diffusions live, and why is it not in the `C` lines? (It is inside the device model, computed
   from the `ad`, `as`, `pd` and `ps` parameters on each device line, and yours are 4.23 ×
   theirs.)

You cannot read the answer off the parasitic netlist. You have to simulate, which is why this lab
does.

**You should see** the `C` lines for both cells, with no junction capacitance among them.

## Part 4: Read the ring oscillator

An odd number of inverters in a loop cannot settle: whatever value it holds, it contradicts
itself one lap later. So it oscillates, with period $2 N t_p$, which makes it the cleanest
measurement of a single gate delay: no source and no external load, just the cell driving one copy
of itself.

1. Open `src/mkring.py`, which writes both 31-stage rings. It is under fifty lines.

2. Check the foundry cell's numbers from Part 1 against the formula:

   ```
   period 2137.8 ps  ->  467.8 MHz  ->  34.48 ps per stage
   ```

**34 picoseconds is the floor** for this process at 1.8 V. The capstone's timing numbers are
multiples of it, and [What sets the clock frequency](guide/why-the-clock-cannot-go-faster.md)
builds on it.

**You should see** 2137.8 ps divided by $2 \times 31$ come out at about 34.48 ps.

## Part 5: Measure your own cell (optional)

1. Copy your Lab 03 cell in and run the comparison again:

   ```bash
   make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
   make
   ```

2. Check the W and L rows. If they do not read `1.00 x`, your cell is not the one Lab 03 asked
   for, and the comparison is no longer isolating the drawing.

> **Known problem:** if `make` stops with `results/my_inv.pex.spice is missing - extraction did
> not run.`, `make mine` has damaged the copied file. Put the reference cell back with
> `git checkout mag/my_inv.mag`, run `make` again, and say so in
> [Discord](https://discord.gg/hrJnP5UsGz).

**You should see** `1.00 x` on the W and L rows.

## Finishing

You are done when:

- [ ] `make` ends in `PASS`
- [ ] your W and L rows read `1.00 x`
- [ ] you can explain why FO4 and the ring disagree
- [ ] you can say where junction capacitance lives, and why it is not in the `C` lines

`make table` re-prints the comparison from results already on disk, instantly. `make pex` runs
only the extraction, in about 4 s.
