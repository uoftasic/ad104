# Lab 04: A buffer and an AND gate

You'll build two more cells without drawing a single new transistor. A buffer is two of your
inverters. An AND gate is a NAND gate and one of your inverters. The work is placing, abutting,
wiring and naming, which is what the rest of a chip is made of.

Package: [`labs/lab-04-buffer-and-and/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-04-buffer-and-and)

## Before you start

- Get [Lab 03](labs/lab-03-draw-an-inverter-overview.md) to `PASS`.
- Read [Instances and hierarchy](guide/cells-are-lego.md). This lab also uses
  [Stick diagrams](guide/stick-diagrams.md) and
  [Layout versus schematic (LVS)](guide/lvs-asks-a-different-question.md).

**Time:** about 2 hours. The full `make` takes about a minute (53, 63 and 74 s on three timed
clean runs), nearly all of it ngspice reading the SKY130 model library for the truth-table
simulation. `make layout` runs only the DRC and LVS part, in about 2 s; use it while you are
wiring.

## Part 1: Look at the NAND

1. Go into the lab package and build the starting cells:

   ```bash
   cd labs/lab-04-buffer-and-and
   make cells        # (re)build mag/my_inv.mag and mag/my_nand2.mag
   make scaffold     # two blocks, each with its two cells already placed
   ```

   `mag/my_inv.mag` is the Lab 03 reference inverter, so this lab works on its own. `make
   scaffold` **throws away your work in `my_buf` and `my_and2`**; use it again only to start
   over.

2. The NAND comes finished, and `tcl/nand2.tcl` is how it was drawn, commented line by line. Open
   it:

   ```bash
   make edit CELL=my_nand2
   ```

   ![The NAND2](../assets/img/ad104-magic-nand2.png)

   *Two red poly stripes crossing one strip of green n-diffusion, with contacts at the far left
   and far right only and nothing between the gates. The two NMOS are in **series**, which on
   silicon means the drain of one and the source of the other are the same piece of doped
   silicon.*

   The PMOS above are in **parallel**: three contacts, alternating source, drain, source, with
   the middle one going to `Y`.

3. Run the layout checks once, so that Magic extracts the blocks:

   ```bash
   make layout
   ```

   It fails, because nothing is wired or named yet. Open `results/my_and2.lvs.spice` and find the
   `my_nand2` subcircuit. Its two NMOS lines share a node you never named:

   ```spice
   X0 a_300_260# A VGND VGND sky130_fd_pr__nfet_01v8 ... w=0.65 l=0.15
   X3 Y B a_300_260# VGND sky130_fd_pr__nfet_01v8 ... w=0.65 l=0.15
   ```

   `a_300_260#` is the shared diffusion. Magic named it after its coordinates.

Answer for yourself: why is there no contact on the shared node between the two NMOS?
([Stick diagrams](guide/stick-diagrams.md#the-nand) has the answer if you need it.)

**You should see** the NAND's single n-diffusion strip under both gates, and `a_300_260#` in the
netlist.

## Part 2: Wire the buffer

1. Open the buffer:

   ```bash
   make edit CELL=my_buf
   ```

   `make scaffold` gave you `my_buf` containing two `my_inv` instances, at x = 0 and x = 3.0, with
   the block's own metal1 rails painted over the row and already labelled `VGND` and `VPWR`.
   Both cells are 6.00 µm tall with their rails at the same heights, so the rails already abut
   into two continuous strips and the wells have merged. **You have not drawn anything, and power
   is connected.**

2. What is missing is the signal. `inv1`'s output `Y` is an li shape at x = 2.18–2.55, and
   `inv2`'s input `A` is at x = 3 + 1.24 = 4.24–4.61, both around y = 2.4. One li rectangle joins
   them:

   ```tcl
   box 2.18um 2.40um 4.61um 2.65um
   paint li
   ```

**You should see** a single li rectangle running from `inv1`'s output to `inv2`'s input. That is
the buffer.

## Part 3: Name the buffer's pins

1. Label the input and output, turn the labels into ports, and save:

   ```tcl
   box 1.30um 2.40um 1.55um 2.65um ; paint li ; label A c li
   box 5.20um 2.42um 5.45um 2.67um ; paint li ; label X c li
   select top cell
   port makeall
   save my_buf
   ```

   Both label lines paint a small patch of `li` first. **A label lands on geometry belonging to
   the current cell.** The input pin you want to name belongs to `inv1`, so a label placed on it
   would belong to `inv1`. Painting your own 0.25 µm patch on top (same net, electrically
   nothing) gives the top cell something of its own to name. The scaffold's metal1 rails exist
   for the same reason: they give `VGND` and `VPWR` top-cell geometry to sit on.

2. Run the layout checks:

   ```bash
   make layout
   ```

3. Optional: erase the block's two metal1 rail rectangles, `save`, and run `make layout` again to
   watch the block come out with no supply ports at all. It is a good failure to have met. Undo
   the erase (`u`) and `save` before you go on.

**You should see** the `my_buf` row read `ok`, `0`, `0`, `match`. The `my_and2` row still fails
until Part 4.

## Part 4: Build the AND gate

1. Open the AND gate:

   ```bash
   make edit CELL=my_and2
   ```

   It has `my_nand2` (instance `nd0`) at x = 0 and `my_inv` (instance `in0`) at x = 4.0, with the
   rails painted and labelled as in `my_buf`.

2. `nd0`'s output is at x = 3.20–3.53, and `in0`'s input is at 4 + 1.24 = 5.24–5.61. Join them:

   ```tcl
   box 3.20um 2.40um 5.61um 2.65um
   paint li
   ```

3. Paint li patches and label them: `A` and `B` over the NAND's two inputs, and `X` over the
   inverter's output. Work out the coordinates yourself. The NAND's input li runs are the `A` and
   `B` lines in `tcl/nand2.tcl`, and the inverter's output is the same `Y` run you used in
   Part 2, now 4.0 µm from the block's origin instead of 3.0.

4. `select top cell`, `port makeall`, `save my_and2`, and run `make layout`.

**You should see** both rows read `ok`, with `0`, `0` and `match`, and
`PASS  Both blocks are clean under both rule sets`.

## Part 5: Simulate the AND gate

1. Run the full check:

   ```bash
   make
   ```

   It extracts both blocks, LVSes them against `spice/cells_sch.spice`, and then simulates the AND
   gate's truth table on the **extracted layout, with parasitics**:

   ```
     TWO BLOCKS, BUILT OUT OF CELLS

     block      DRC default  DRC full   LVS                       contains
     --------------------------------   ------------------------  ----------------
     ok my_buf            0         0   match                     my_inv, my_inv
     ok my_and2           0         0   match                     my_inv, my_nand2

     THE AND GATE, SIMULATED

         ok  A=0  B=0   X = 0.000000 V   (expected 0.0)
         ok  A=0  B=1   X = 0.000000 V   (expected 0.0)
         ok  A=1  B=0   X = 0.000001 V   (expected 0.0)
         ok  A=1  B=1   X = 1.800000 V   (expected 1.8)

   PASS  A buffer and an AND gate, both clean under both rule sets, both
         matching their schematics, and the AND gate really does AND.
   ```

That AND gate has six transistors, and you drew none of them in this lab.

The testbench is generated by `src/mktb.py` **around your netlist's own port order**, instead of
assuming one. Magic numbers a cell's ports in the order the labels were created, so if you
labelled `X` before `A`, your `.subckt` line differs from the reference's. A testbench with the
terminals in the wrong order would give a wrong answer without any error.

**You should see** all four truth-table rows marked `ok`, and `PASS`.

## Part 6: Meet the pin-swap message

1. LVS your NAND against a netlist with `A` and `B` exchanged:

   ```bash
   make swapped
   ```

   ```
   Netlists match uniquely.

   Subcircuit pins:
   Circuit 1: my_nand2         |Circuit 2: my_nand2
   ----------------------------|----------------------------
   VPWR                        |VPWR
   Y                           |Y
   VGND                        |VGND
   B                           |A **Mismatch**
   A                           |B **Mismatch**

   Final result: Top level cell failed pin matching.
   ```

2. Read it as two statements. They do not contradict each other:

   - **the topology is right**: four devices wired exactly as the schematic says
   - **two names are on the wrong shapes**: netgen had to swap `A` and `B` to make the match work

Answer for yourself: why will nothing else in the flow ever notice this? (A NAND is symmetric in
its inputs, so simulation passes and DRC passes. The timing model is still wrong, because in a
series stack the input nearer the output is faster than the one nearer ground.)

**The fix is to swap the labels in the layout, not in the schematic.**

**You should see** `Netlists match uniquely` and `failed pin matching` in the same report.

## Finishing

You are done when:

- [ ] both blocks are at 0 violations under both rule sets
- [ ] both `match` in LVS
- [ ] all four rows of the truth table are correct, and `make` ends in `PASS`
- [ ] you can explain why the shared node in the NAND has no contact
- [ ] you have run `make swapped` and can read its output

`make ref` and `make refcheck` build and check the reference blocks. The package's
[`solutions/README.md`](https://github.com/uoftasic/ad104/tree/main/labs/lab-04-buffer-and-and/solutions)
discusses three decisions in them.
