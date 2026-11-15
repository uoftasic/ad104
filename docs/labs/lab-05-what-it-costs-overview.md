# Lab 05: What it costs

In this lab you compare two layouts of the same two transistors, your Lab 03 inverter and the
foundry's `inv_1`, to see what the drawing costs in area and in delay. You start by working out
the area price from numbers you already have. Then you extract both cells with every parasitic
capacitance kept, simulate them, and check your arithmetic against the measurement.

Package: [`labs/lab-05-what-it-costs/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-05-what-it-costs)

## Before you start

- Get [Lab 03](../labs/lab-03-draw-an-inverter-overview.md) to `PASS`.
- Read [Area, parasitics and delay](../guide/what-your-drawing-costs.md). This lab also uses
  [Extraction](../guide/extraction-is-reverse-engineering.md).
- Have paper or a text file ready for the numbers you work out in Parts 1 and 5.

**Time:** about 1 hour, not counting the optional Part 6. Each full `make` takes two to three
minutes (114 s and 182 s on two timed clean runs, depending on what else the machine is doing).
Nearly all of that time goes on the two ring oscillators, which between them have 62 extracted
subcircuits to simulate for 20 ns of transient, with ngspice reading the whole SKY130 model
library twice.

## Part 1: Predict the price

How much does the drawing cost in area, judging only from numbers you have already seen?

1. The Lab 03 cell is 3.00 × 6.00 µm, and Lab 01 measured `inv_1` at 1.38 × 2.72 µm. Work out
   how many times bigger the Lab 03 cell is, and write it down.

2. The extracted netlists give each transistor's drain junction area as `ad=`: 0.715 µm² for the
   Lab 03 NMOS and 1.1 µm² for its PMOS (Lab 03, Part 9), against 0.169 µm² and 0.26 µm² for
   `inv_1` (Lab 01, Part 5). Work out both ratios and write them down.

3. Guess how much slower the Lab 03 cell will be. Is it closer to the area ratio, the junction
   ratio, or much less than either? Write down a number, because Part 3 compares it with the
   measurement.

**You should see** three ratios and a guess in your notes. Part 2 checks the ratios against the
table.

## Part 2: Run the comparison

Does the measurement agree with your arithmetic?

1. Go into the lab package and run it:

   ```bash
   cd labs/lab-05-what-it-costs
   make
   ```

   By default it compares the **reference** Lab 03 inverter, in `mag/my_inv.mag`, with the
   foundry's. The reference uses the same transistor and wiring coordinates as Lab 03's steps, so
   if you followed those steps, the `yours` column describes the cell you drew. Part 6 (optional)
   swaps in your own file instead. The run prints:

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

2. Find the four `1.00 x` rows for W and L. They're the control in this experiment: the
   transistors in the two cells are identical, down to the model name, so every other difference
   in the table comes from the way they were drawn.

3. Compare the `cell area` row and the two `drain junction area` rows with the ratios you worked
   out in Part 1.

**You should see** `1.00 x` on every W and L row, `4.80 x` for the cell area and `4.23 x` on both
drain junction area rows, matching your Part 1 ratios to rounding, and `make` ending in `PASS`.

## Part 3: Compare the two delay rows

Why does the same drawing cost more delay in one test than in the other?

1. Find the two delay ratios in your table: the fan-out 4 `average` row and the ring
   `one stage` row. On this page they are 1.11 x at fan-out 4 and 1.27 x in the ring, so the
   cell is 11 % slower in one test and 27 % slower in the other. Compare yours with the guess you
   wrote down in Part 1.

2. Work out why the two ratios differ before you read the `WHAT TO TAKE FROM THIS` block at the
   end of your `make` output, because that block gives the answer. Hint: a gate's delay is how
   long it takes to charge whatever hangs off its output, and that load has two parts: what you
   are driving, and what you brought with you.

   <details>
   <summary>Answer</summary>

   At fan-out 4 most of the load is the four downstream gates, and their input capacitance is the
   same whichever cell is driving them. In the ring each stage drives one gate and nothing else,
   so your 4.23 × junction area makes up a large share of the total load.
   [Area, parasitics and delay](../guide/what-your-drawing-costs.md#fo4-delay-and-ring-oscillator-delay)
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

   On the second row the foundry's cell comes out *worse*, and that is a real result. As
   [Area, parasitics and delay](../guide/what-your-drawing-costs.md#where-the-femtofarads-come-from)
   explains, the extracted `C` elements are wire-to-wire coupling capacitance, and the foundry
   cell has more of it on its output because everything in it is packed close together.

3. Where does the junction capacitance of the source and drain diffusions live, and why isn't it
   in the `C` lines?

   <details>
   <summary>Answer</summary>

   It's inside the device model, which computes it from the `ad`, `as`, `pd` and `ps` parameters
   on each device line, and your drain areas are 4.23 × theirs. Because it lives in the model, you
   can't read it off the parasitic netlist; the only way to see its effect is to simulate, which
   is why this lab does.

   </details>

**You should see** the `C` lines for both cells, with no junction capacitance among them.

## Part 5: Read the ring oscillator

How long does one gate take when it drives nothing but a copy of itself?

A loop of an odd number of inverters can't settle, because whatever value a node holds comes back
inverted one lap later. So the loop oscillates, with period $2 N t_p$ for $N$ stages of delay
$t_p$ each. That makes it the cleanest way to measure a single gate delay, because there is no
source and no external load, only the cell driving one copy of itself.

1. Open `src/mkring.py`, which writes both 31-stage rings. It is under fifty lines, and `N = 31`
   near the top sets the number of stages.

2. From the `period` row of your table, work out the delay of one stage for each cell,
   $t_p = T / (2 \times 31)$, and write both down. Then compare them with the `one stage` row.

   <details>
   <summary>Answer</summary>

   For the table on this page: 2720.4 ps / 62 = 43.88 ps for your cell, and
   2137.8 ps / 62 = 34.48 ps for the foundry's. The table rounds the periods to 2720 and 2138,
   which is why dividing the rounded numbers gives 43.87 and 34.48.

   </details>

The foundry's 34 picoseconds is the floor for this process at 1.8 V: it's the delay of one gate
driving nothing but a copy of itself. The capstone's timing numbers are multiples of it, and
[What sets the clock frequency](../guide/why-the-clock-cannot-go-faster.md) builds on it.

**You should see** your two stage delays agree with the `one stage` row, to rounding.

## Part 6: Measure your own cell (optional)

1. Copy your Lab 03 cell in and run the comparison again:

   ```bash
   make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
   make
   ```

   A cell drawn by following Lab 03 lists its ports as `VGND VPWR A Y`, because the frame you
   started from already had `VGND` and `VPWR` labelled, while the reference lists them as
   `A Y VPWR VGND`. So `make` reads the order out of your extracted netlist, wires both decks
   around it, and prints it on its `wrote results/fo4.spice` line. If your cell is missing a
   port, `make` stops there instead and names the ports it found.

2. Check the W and L rows. If they don't read `1.00 x`, your transistors aren't the ones Lab 03
   asked for, so the comparison no longer isolates the effect of the drawing.

To go back to the reference cell afterwards, run `git checkout mag/my_inv.mag` and then `make`.

**You should see** `1.00 x` on the W and L rows. If you used Lab 03's coordinates exactly, the
whole table is the same as the reference's.

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

`make table` prints the comparison again from the results already on disk, so it returns
instantly. `make pex` runs only the extraction, which takes about 4 s.

Next on the Course path: read [Routing by hand](../guide/routing-by-hand.md) and
[What sets the clock frequency](../guide/why-the-clock-cannot-go-faster.md), then do the
[Capstone: Place and route](../labs/capstone-place-and-route-overview.md).
