# Lab 05: What it costs

You'll put a price on the drawing: the same two transistors, drawn twice, compared for area and
delay. First you work out the area price from numbers you already have. Then you extract the
Lab 03 inverter and the foundry's `inv_1` with every parasitic capacitance kept, simulate both,
and check your arithmetic against the measurement.

Package: [`labs/lab-05-what-it-costs/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-05-what-it-costs)

## Before you start

- Get [Lab 03](labs/lab-03-draw-an-inverter-overview.md) to `PASS`.
- Read [Area, parasitics and delay](guide/what-your-drawing-costs.md). This lab also uses
  [Extraction](guide/extraction-is-reverse-engineering.md).
- Have paper or a text file ready for the numbers you work out in Parts 1 and 5.

**Time:** about 1 hour, not counting the optional Part 6. Each full `make` takes two to three
minutes (114 s and 182 s on two timed clean runs, depending on what else the machine is doing).
Nearly all of that is the two ring oscillators: 62 extracted subcircuits, 20 ns of transient, and
ngspice reading the whole SKY130 model library twice.

## Part 1: Predict the price

What does the drawing cost in area, from numbers you have already seen?

1. The Lab 03 cell is 3.00 × 6.00 µm, and Lab 01 measured `inv_1` at 1.38 × 2.72 µm. Work out
   how many times bigger the Lab 03 cell is, and write it down.

2. The extracted netlists give each transistor's drain junction area as `ad=`: 0.715 µm² for the
   Lab 03 NMOS and 1.1 µm² for its PMOS (Lab 03, Part 9), against 0.169 µm² and 0.26 µm² for
   `inv_1` (Lab 01, Part 5). Work out both ratios and write them down.

3. Guess how much slower the Lab 03 cell will be. Is it closer to the area ratio, the junction
   ratio, or much less than either? Write down a number; Part 3 compares it with the measurement.

**You should see** three ratios and a guess in your notes. Part 2 checks the ratios.

## Part 2: Run the comparison

Does the measurement agree with your arithmetic?

1. Go into the lab package and run it:

   ```bash
   cd labs/lab-05-what-it-costs
   make
   ```

   By default it compares the **reference** Lab 03 inverter, in `mag/my_inv.mag`, with the
   foundry's. The reference uses the same transistor and wiring coordinates as Lab 03's steps, so
   the `yours` column is the cell you drew if you followed them. Part 6 (optional) swaps in your
   own file. It prints:

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
     ...

   PASS  Both cells extracted with parasitics, both simulated, and the
         comparison is above. There is no wrong answer here - it is a
         measurement, and yours is yours.
   ```

2. Find the four `1.00 x` rows for W and L. They are the control: the transistors are identical,
   down to the model name, so **everything else on the table comes from the drawing.**

3. Compare the `cell area` row and the two `drain junction area` rows with the ratios you worked
   out in Part 1.

**You should see** `1.00 x` on every W and L row, `4.80 x` for the cell area and `4.23 x` on both
drain junction area rows, matching your Part 1 ratios to rounding, and `make` ending in `PASS`.

## Part 3: Compare the two delay rows

Why does the same drawing cost more delay in one test than in the other?

1. Find the two delay ratios: **1.11 x at fan-out 4, 1.27 x in the ring.** Your cell is 11 %
   slower in one test and 27 % slower in the other. Compare them with your guess from Part 1.

2. Explain the difference. Hint: a gate's delay is how long it takes to charge whatever hangs off
   its output, and that load has two parts, what you are driving and what you brought with you.

   <details>
   <summary>Answer</summary>

   At fan-out 4 the four downstream gates dominate the load, and their input capacitance is
   identical for both cells. In the ring each stage drives one gate and nothing else, so your
   4.23 × junction area is a large share of the total.
   [Area, parasitics and delay](guide/what-your-drawing-costs.md#fo4-delay-and-ring-oscillator-delay)
   has the full explanation.

   </details>

**You should see** that the self-loaded test (the ring) shows the bigger penalty.

## Part 4: Look at the capacitors

Where does the extra capacitance live?

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

3. Where does the **junction capacitance** of the source and drain diffusions live, and why is it
   not in the `C` lines?

   <details>
   <summary>Answer</summary>

   It is inside the device model, computed from the `ad`, `as`, `pd` and `ps` parameters on each
   device line, and yours are 4.23 × theirs. You cannot read it off the parasitic netlist. You
   have to simulate, which is why this lab does.

   </details>

**You should see** the `C` lines for both cells, with no junction capacitance among them.

## Part 5: Read the ring oscillator

How long does one gate take when it drives nothing but a copy of itself?

An odd number of inverters in a loop cannot settle: whatever value it holds, it contradicts
itself one lap later. So it oscillates, with period $2 N t_p$ for $N$ stages of delay $t_p$ each.
That makes it the cleanest measurement of a single gate delay: no source and no external load,
just the cell driving one copy of itself.

1. Open `src/mkring.py`, which writes both 31-stage rings. It is under fifty lines, and `N = 31`
   near the top sets the number of stages.

2. From the `period` row of your table, work out the delay of one stage for each cell,
   $t_p = T / (2 \times 31)$, and write both down. Then compare them with the `one stage` row.

   <details>
   <summary>Answer</summary>

   For the table on this page: 2720.4 ps / 62 = 43.88 ps for your cell, and
   2137.8 ps / 62 = 34.48 ps for the foundry's. The table rounds the periods to 2720 and 2138, so
   dividing those gives 43.87 and 34.48.

   </details>

**34 picoseconds is the floor** for this process at 1.8 V. The capstone's timing numbers are
multiples of it, and [What sets the clock frequency](guide/why-the-clock-cannot-go-faster.md)
builds on it.

**You should see** your two stage delays agree with the `one stage` row, to rounding.

## Part 6: Measure your own cell (optional)

> **Known problem:** `make mine` currently damages the file it copies (it overwrites the
> `magic` line at the top), so the `make` after it stops with
> `results/my_inv.pex.spice is missing - extraction did not run.` Skip this part until it is
> fixed. If you have already run it, put the reference cell back with
> `git checkout mag/my_inv.mag` and run `make` again.

1. Copy your Lab 03 cell in and run the comparison again:

   ```bash
   make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
   make
   ```

2. Check the W and L rows. If they do not read `1.00 x`, your cell is not the one Lab 03 asked
   for, and the comparison is no longer isolating the drawing.

**You should see** `1.00 x` on the W and L rows.

## Finishing

You're done when the area and drain-area ratios you worked out in Part 1 match the table's
`cell area` and `drain junction area` rows, and the stage delays you worked out in Part 5 match
its `one stage` row.

Questions:

- Why does the ring show a bigger penalty than fan-out 4? Part 3 answers it.
- Where does junction capacitance live, and why is it not in the `C` lines? Part 4, step 3
  answers it.

Submit: nothing for this lab.

## Going further (optional)

`make table` re-prints the comparison from results already on disk, instantly. `make pex` runs
only the extraction, in about 4 s.

Next on the Course path: read [Routing by hand](guide/routing-by-hand.md) and
[What sets the clock frequency](guide/why-the-clock-cannot-go-faster.md), then do the
[Capstone: Place and route](labs/capstone-place-and-route-overview.md).
