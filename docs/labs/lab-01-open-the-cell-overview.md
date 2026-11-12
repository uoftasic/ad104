# Lab 01 — Open a cell you did not draw

You'll set up the workbench, then load the foundry's own inverter, `sky130_fd_sc_hd__inv_1`,
into Magic and get four checks to agree about it: DRC under two rule sets, extraction, and LVS.
If they agree, your toolchain works, and every problem after this lab is a drawing problem.

Package: [`labs/lab-01-open-the-cell/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-01-open-the-cell)

## Before you start

- Read [Getting started](guide/getting-started.md),
  [What a layout is](guide/what-a-layout-actually-is.md), [SiliWiz](guide/siliwiz.md) and
  [Anatomy of a standard cell](guide/anatomy-of-a-standard-cell.md).
- Finish [IC101](https://uoftasic.com/ic101/): you need the `workspace` clone and the noVNC
  desktop.
- Keep the [Magic cheat sheet](reference/magic-cheatsheet.md) open in another tab.

**Time:** about 1.5 hours, including 20 minutes for the optional SiliWiz part. `make` itself
takes about a second and a half.

## Part 1: Explore SiliWiz (optional)

This part runs in your browser and needs no setup. Do it before you open Magic for the first
time; it is the cheapest twenty minutes in the course.

1. Open **<https://app.siliwiz.com/>**. [SiliWiz](guide/siliwiz.md) describes the interface.
   Load the inverter from the **Preset** dropdown above the drawing area to see a finished
   example.
2. Open **LESSONS** (top right) and do the *nmos* lesson. Drag the cross-section cut line with the
   blue slider so that it passes through the middle of the poly stripe, and look at the
   cross-section: substrate, a thin oxide, poly on top, and doped regions on either side.
3. Drag the cut so that it misses the poly. The cross-section becomes two doped regions with
   nothing joining them. **The transistor exists only where the poly crosses.**
4. Move a contact until it hangs off the edge of the diffusion it sits on, and open the
   **CROSS SECTION & DRC** tab. SiliWiz's rules are not SKY130's, but the shape of the
   complaint, "this thing does not surround that thing by enough", is the shape of half the
   errors you'll fix in Lab 02.
5. Do the *parasitics* lesson. Stretch a metal wire longer and watch what happens to the
   simulated waveform. That is the argument of Lab 05, in two minutes.

**You should see** the transistor appear and disappear in the cross-section as the cut moves on
and off the poly, and a DRC complaint as soon as the contact leaves its diffusion.

## Part 2: Set up the workbench

1. Start the noVNC desktop the way [IC101](https://uoftasic.com/ic101/) showed you, open
   `http://localhost` in a browser, and open a terminal on that desktop. Type every command from
   here on in that terminal, not on your laptop.

2. Load the course environment. Do this in every new terminal; it does not carry over.

   ```bash
   . /foss/designs/common/.designinit
   ```

3. Check the PDK:

   ```bash
   echo $PDK
   ```

   It must print `sky130A`. If it prints `ihp-sg13g2`, the image's default, step 2 did not run in
   this terminal.

4. Get the course files. `mod` is a command that `.designinit` defines.

   ```bash
   mod add ad104     # first time only
   mod ad104         # puts you in the course folder
   ```

5. Check the Magic version:

   ```bash
   magic --version
   ```

   ```
   8.3.681
   ```

| What you see | What it means |
|---|---|
| `.designinit: No such file or directory` | The workspace was not set up. Finish IC101. You can still run `make` in a lab: every lab package pins its own PDK. |
| `couldn't read Username for 'https://github.com'` on `mod add ad104` | The repo did not answer anonymously. That is our problem, not yours; say so in [Discord](https://discord.gg/hrJnP5UsGz). |

**You should see** `sky130A` from step 3 and `8.3.681` from step 5.

## Part 3: Run the check

1. From the course folder, go into the lab package and run it:

   ```bash
   cd labs/lab-01-open-the-cell
   make
   ```

   The `Makefile` sets `PDK=sky130A` itself, so this works even if `.designinit` failed for you.
   It takes about a second and a half (1.35, 1.46 and 1.60 s on three timed clean runs) and
   prints:

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

2. Look at the full-rule-set count. **The foundry's own cell fails the full rule set**, and that
   is the expected answer. (Magic calls a rule set a DRC *style*, which is why the output says
   `default style` and `full style`.) Before you read on, answer for yourself: why does the full
   rule set find three violations in a cell that has been taped out hundreds of times?

3. Check your answer. All three violations come from one omission: the cell has no well tap,
   because the library puts taps in a separate cell
   ([Anatomy of a standard cell](guide/anatomy-of-a-standard-cell.md#why-the-cell-has-no-well-tap)
   explains why).

**You should see** `PASS`, `0` under the default rule set and `3` under the full one.

## Part 4: Look at the cell in Magic

1. Open the cell:

   ```bash
   make gui
   ```

   (`make edit` does the same, and is the name every other lab uses.) Magic opens with the cell
   loaded, and the terminal comes back to you while Magic stays open.

2. Using [Anatomy of a standard cell](guide/anatomy-of-a-standard-cell.md) as a map, find:

   - the n-well across the top, and the p-diffusion inside it
   - the n-diffusion in the bottom half
   - the **single** poly stripe crossing both, which is why the two gates are connected without a
     wire
   - the two metal1 rails, straddling y = 0 and y = 2.72
   - the contacts, every one of them 0.17 µm square

3. Now look for something that is *not* there: a well tap.

**You should see** every item in step 2, and no tap anywhere in the cell. Leave Magic open for
Part 6.

## Part 5: Read the extracted netlist

1. In the terminal, print the netlist Magic extracted from the geometry:

   ```bash
   make netlist
   ```

   ```spice
   * NGSPICE file created from sky130_fd_sc_hd__inv_1.ext - technology: sky130A

   .subckt sky130_fd_sc_hd__inv_1 A VGND VNB VPB VPWR Y
   X0 Y A VGND VNB sky130_fd_pr__nfet_01v8 ad=0.169 pd=1.82 as=0.169 ps=1.82 w=0.65 l=0.15
   X1 Y A VPWR VPB sky130_fd_pr__pfet_01v8_hvt ad=0.26 pd=2.52 as=0.26 ps=2.52 w=1 l=0.15
   .ends
   ```

2. Count the ports. There are six, and two of them, `VNB` and `VPB`, are the bulk terminals. The
   cell exposes its own substrate and well as pins because it does not tie them to anything
   itself.

3. Find `w=0.65` and `w=1`. Nobody typed those numbers; Magic measured the height of two
   rectangles. Answer for yourself: which rectangle's height is `w=0.65`?
   ([What a layout is](guide/what-a-layout-actually-is.md#where-the-transistor-is) has the rule
   if you need it.)

4. Find `pfet_01v8_hvt`. The PMOS is the high-threshold flavour, and you'll need to remember that
   in Lab 03.

**You should see** two devices, six ports, and `w=0.65 l=0.15` on the NMOS.

## Part 6: Run the flow by hand

Everything Magic did for `make` in Part 3 is a short list of commands you can type yourself.
This is the flow for every remaining lab in the course, and it is worth running once with your
own fingers.

1. In the `tkcon` console (the Tcl console window that opened with Magic in Part 4), type these
   one at a time:

   ```tcl
   select top cell
   drc euclidean on
   drc check
   drc catchup
   drc count total
   drc style drc(full)
   drc check
   drc catchup
   drc count total
   drc why
   extract do local
   extract all
   ext2spice lvs
   ext2spice -o /tmp/inv.spice
   ```

2. Watch the count change when the rule set does: the first `drc count total` prints
   `Total DRC errors found: 0`, and the second prints `Total DRC errors found: 3`. `drc why` then
   names the three rules.

Three of those lines are easy to leave out and matter:

- **`select top cell`**: `drc why` only reports on what is inside the cursor box, and a freshly
  opened cell has no box worth speaking of. Without it you get `No errors found.` on a cell with
  three violations.
- **`drc catchup`**: `drc check` queues the re-check, and `drc catchup` waits for it to finish.
  Count too early and you count nothing.
- **`drc count total`**, not `drc count`. Plain `drc count` prints two lines,
  `Cell sky130_fd_sc_hd__inv_1 has 3 error tiles.` and then `Total DRC errors found: 0`. The
  second number is the *hierarchical* total across subcells, which is always 0 on a flat cell, so
  if you read the last line of `drc count` the number never seems to change.

**You should see** `0`, then `3`, then the same three rule names as in Part 3.

## Part 7: Browse the library

1. Count the cells in the library and list the inverters:

   ```bash
   ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/ | wc -l
   ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/ | grep __inv_
   ```

   The first prints `446`. The second lists seven inverters: `inv_1`, `inv_2`, `inv_4`, `inv_6`,
   `inv_8`, `inv_12` and `inv_16`. They are the same logic with increasing drive strength.

2. Open the whole library GDS in KLayout, which is a much better viewer than Magic and cannot
   edit anything, so it is safe to browse:

   ```bash
   make klayout
   ```

3. Open `inv_8` next to `inv_1` and see where the factor of eight went.

**You should see** 446 cells, seven inverters, and an `inv_8` that is visibly wider than `inv_1`.

## Finishing

You are done when:

- [ ] `make` ends in `PASS`
- [ ] you can point at the n-well, the two diffusions, the poly stripe and the two rails in the
      Magic window
- [ ] you can say why the full rule set finds three violations in a cell that has been taped out
      hundreds of times
- [ ] you know which rectangle's height `w=0.65` in the extracted netlist is

## If something goes wrong

| What you see | What it means |
|---|---|
| `DRC violations, default style` is not 0 | The technology did not load. Check that `$PDK_ROOT` points at the PDKs (`/foss/pdks` in the workbench image) and that `.magicrc` is in the folder you ran `make` from. |
| `results/report.txt is missing` | Magic did not finish. Read `results/magic.log`. |
| `LVS: netgen wrote no report` | Read `results/netgen.log`. The cause is usually `$PDK_ROOT` again. |
| `magic: command not found` | You are not in the workbench container. |
