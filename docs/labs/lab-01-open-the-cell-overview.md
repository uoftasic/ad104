# Lab 01: Open a cell you did not draw

You'll load this course into the workbench, open the foundry's own inverter,
`sky130_fd_sc_hd__inv_1`, in Magic, and measure it and its two transistors with Magic's box.
Then you'll check the cell yourself, in the tools: DRC under two rule sets in Magic, extraction
in Magic's console, and LVS with netgen. `make` runs the same checks at the end, and when its
numbers match yours you know your toolchain works, so any problem you run into after this lab
is a problem in your drawing.

Package: [`labs/lab-01-open-the-cell/`](https://github.com/uoftasic/ad104-m/tree/main/labs/lab-01-open-the-cell)

## Before you start

- Read [Getting started](../guide/getting-started.md),
  [What a layout is](../guide/what-a-layout-actually-is.md), [SiliWiz](../guide/siliwiz.md) and
  [Anatomy of a standard cell](../guide/anatomy-of-a-standard-cell.md).
- Finish [IC101](https://uoftasic.com/ic101/): you need the `workspace` clone and the noVNC
  desktop.
- Keep the [Magic cheat sheet](../reference/magic-cheatsheet.md) open in another tab.
- Have paper or a text file ready for the numbers you measure in Parts 3 and 4.

The steps write Magic's menus as `Menu → Item`: click the menu's button along the top of the
layout window, then the item.

**Time:** about 1.5 hours (an estimate), plus 20 minutes for the optional SiliWiz part. `make`
itself takes about a second.

## Part 1: Load the course

If you haven't set up the workbench yet, do
[IC101 Lab 03](https://uoftasic.com/ic101/labs/lab-03-launch-the-workbench-overview.html) first.

1. Start the noVNC desktop the way IC101 showed you, and open a terminal on it. Type every
   command in this lab in that terminal, not on your laptop.

2. Check the PDK. A new terminal on the desktop has already loaded the course environment, and
   running the first line again does no harm.

   ```bash
   . /foss/designs/common/.designinit
   echo $PDK
   ```

   `echo $PDK` must print `sky130A`. If it prints `ihp-sg13g2`, which is the image's default,
   the first line didn't run in this terminal.

3. Get the course files with `mod`, a command that `.designinit` defines.

   ```bash
   mod add ad104-m     # first time only
   mod ad104-m         # puts you in the course folder
   ```

4. Check the versions of the three tools whose output this course prints:

   ```bash
   magic --version
   netgen -batch quit | grep '^Netgen'
   ngspice --version | grep ngspice-
   ```

   ```
   8.3.681
   Netgen 1.5.323 compiled on Tue Aug 25 11:33:45 AM CEST 2026
   ** ngspice-47 : Circuit level simulation program
   ```

   If you have a different version, your outputs may not match the ones printed in these labs.

| What you see | What it means |
|---|---|
| `.designinit: No such file or directory` | The workspace isn't set up, so do IC101 Lab 03. Until then you can still run `make` in any lab, because every lab package pins its own PDK. |
| `echo $PDK` still prints `ihp-sg13g2` and you can't fix `.designinit` now | Start Magic with the PDK set on the same line, `PDK=sky130A magic -d X11 <cell> &`, wherever a lab has you start Magic. |
| `couldn't read Username for 'https://github.com'` on `mod add ad104-m` | The repo didn't answer an anonymous request. That's a problem on our side rather than anything you did, so please tell us in [Discord](https://discord.gg/hrJnP5UsGz). |
| You already have `modules/ad104` from before the course was renamed AD104-M | It's this course under its old name. Use `mod ad104` where this page says `mod ad104-m`, or run `mod add ad104-m` to get a second copy under the new name. |

For anything else, see IC101's [Troubleshooting](https://uoftasic.com/ic101/reference/troubleshooting.html)
page.

**You should see** `sky130A` from step 2 and the three versions from step 4.

## Part 2: Open the cell in Magic

What does Magic show you, and how do you move round it?

1. From the course folder, go into the lab package and start Magic on the foundry's cell:

   ```bash
   cd labs/lab-01-open-the-cell
   magic -d X11 $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__inv_1.mag &
   ```

   The `&` gives you the terminal back while Magic stays open. Magic opens two windows:
   `layout1`, which shows the drawing, and `tkcon 2.3 Main`, a Tcl console where you can type
   Magic commands. If the console covers part of `layout1`, drag it out of the way by its title bar.

   ![Magic's two windows: `layout1` with the inverter, and the `tkcon 2.3 Main` console under it.](../assets/img/ad104-l01-01-two-windows.png){fig-alt="Two windows on a grey desktop. The upper one, layout1, has a row of menu buttons from File to Devices 2, a DRC button with a tick, a brown caption bar, the inverter's layout in the middle and a list of layers down the right side. The lower one, tkcon 2.3 Main, shows Magic's start-up messages in blue."}

2. Find the parts of `layout1`. Along the top are the menu buttons (`File`, `Edit`, `Cell`,
   `Window`, `Layers`, `Drc`, `Options`, `Devices 1`, `Devices 2`) and the `DRC` button. The
   caption starts `Loaded: sky130_fd_sc_hd__inv_1` and is cut off when the window is narrow, and
   the right end of the title bar shows where the box is, or where the pointer is once you move
   it. Down the right side is the layer palette. The cell's file belongs to the PDK, and you
   can't write to it, so Magic opens it without letting you edit it. Nothing in this lab changes
   the layout.

3. Point at a row of the palette, without clicking. The layer's name appears in the title bar.
   Then scroll the palette with the mouse wheel: `polysilicon`, `locali` and `metal1`, the
   layers you'll paint most in this course, are below the part you can see at first.

   ![The pointer over the `ndiffusion` row of the palette: the title bar shows `ndiffusion`.](../assets/img/ad104-l01-02-palette-hover.png){fig-alt="Magic's layout window with the inverter. In the brown caption bar, between the cell name and the box readout, the word ndiffusion appears; down the right side, the palette lists layers such as nwell, pwell, ndiffusion and pdiffusion."}

4. Move round the cell. Keys act only while the pointer is over the drawing, so keep it there.
   Press `v` to fit the whole cell in the window, `z` and `Z` to zoom in and out, and the arrow
   keys to pan. The mouse wheel over the drawing zooms too.

**You should see** the whole cell after `v`, with `sky130_fd_sc_hd__inv_1` in the caption.

## Part 3: Find the parts

What is in the foundry's inverter, and what is missing from it?

1. Using [Anatomy of a standard cell](../guide/anatomy-of-a-standard-cell.md) as a map, find
   these on screen. The figure in
   [What a layout is](../guide/what-a-layout-actually-is.md#the-layers-bottom-to-top) shows which
   colour is which layer.

   - the n-well across the top, and the p-diffusion inside it
   - the n-diffusion in the bottom half
   - the one poly stripe that crosses both diffusions, which is why the two gates are connected
     without a wire
   - the two metal1 rails, one along the bottom and one along the top
   - the contacts, the small squares with a cross in them, each 0.17 µm square

2. Ask Magic what is somewhere. Magic's **box** is the rectangle it draws with a white outline.
   A left click in the drawing moves the box so that its lower-left corner is where you clicked,
   and a right click moves its upper-right corner. Set a small box inside the bottom transistor's
   channel, where the poly crosses the n-diffusion, then press `/` with the pointer over the
   drawing. The console lists the layers under the box.

   ![The box over the NMOS channel, and the console listing `pwell` and `scnmos` after `/`.](../assets/img/ad104-l01-03-what-under-box.png){fig-alt="Magic's layout window with a small white box over the poly stripe where it crosses the lower diffusion, and the console under it listing Selected mask layers: pwell and scnmos, each marked Topmost cell in the window."}

   Magic stores the channel, where poly crosses diffusion, as a layer of its own: `scnmos` here,
   and `scpmoshvt` for the PMOS above it.

3. Measure the bottom rail. This is the **click recipe**, which you'll use for measuring and
   drawing in every lab:
   1. Set a rough box round the rail and press `ctrl+z` (`Window → Zoom Box` does the same).
      The view zooms to the box. Clicks snap to a 0.01 µm grid, and zoomed in there are several
      pixels to each 0.01 µm, so you can put a click on exactly the point you want.
   2. Left-click the rail's lower-left corner and right-click its upper-right corner.
   3. Press `b` with the pointer over the drawing. `b` prints the box in the console, and the
      `microns:` line is the one to read: the box's width and height, then its lower-left and
      upper-right corners.

   ![The box on the bottom metal1 rail, and the console after `b`: `microns: 1.380 x 0.480`.](../assets/img/ad104-l01-04-rail-b.png){fig-alt="Magic's layout window zoomed on the bottom rail, with the white box exactly on the rail's outline. The console under it shows the output of b: a header line, then microns 1.380 x 0.480 with corners 0.000, -0.240 and 1.380, 0.240, then the same box in lambda and internal units."}

   ```
   microns:   1.380 x 0.480   ( 0.000, -0.240), ( 1.380,  0.240)  0.662
   ```

   The rail runs from y = −0.24 to +0.24 µm, so it straddles y = 0, and it is as wide as the
   cell, 1.38 µm. Press `v`, and measure the top rail the same way.

4. Now look for something the cell doesn't have, a well tap. A tap is a contacted strip of
   `ptap` or `ntap` (the palette calls them `psubstratepdiff` and `nsubstratendiff`), which is
   silicon doped the *same* type as the well under it and tied to a rail. Source and drain
   contacts don't count as taps, because their diffusion is the opposite type to the well.
   ([What a layout is](../guide/what-a-layout-actually-is.md#diffusion-as-a-wire-and-tying-the-wells)
   explains what a tap is for.)

**You should see** every item in step 1, the bottom rail from y = −0.24 to 0.24 µm and the top
one from 2.48 to 2.96 µm (both centred on the cell's edges, y = 0 and y = 2.72), and no tap
anywhere in the cell.

## Part 4: Measure the transistors

How wide and how long are the two transistors? You can work this out yourself, before any tool
extracts it for you.

1. Zoom on the NMOS channel (a rough box round it, then `ctrl+z`). Set the box on the channel's
   corners with the click recipe and press `b`. The box's width is the transistor's length L,
   and its height is the width W. Write both down.

2. Do the same for the PMOS channel above it.

3. Your L reads 0.150 for both. Your W may read 0.01 µm off, for example
   `microns:   0.150 x 0.640` on the NMOS. Zoom in on the top or bottom end of the channel: the
   box's edge sits a little inside or outside the diffusion's edge, and no click puts it exactly
   on the edge. Why?

   <details>
   <summary>Answer</summary>

   The foundry drew this cell on a 0.005 µm grid, and Magic's clicks snap to a 0.01 µm grid. The
   channel's left and right edges happen to sit on the 0.01 µm grid, so L comes out exact. Its
   top and bottom edges sit halfway between two snap points, so each click lands 0.005 µm inside
   or outside the edge, and W comes out as 0.64, 0.65 or 0.66 depending on which way each corner
   went. The layout file gives the exact numbers, which is the next step. Lab 02's cells are drawn
   on the 0.01 µm grid, so there your boxes land exactly on the edges.

   </details>

4. Read the two channels from the layout file. In the terminal, print the file's header and its
   two transistor layers:

   ```bash
   F=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__inv_1.mag
   head -4 $F
   grep -A1 -e '<< scnmos >>' -e '<< scpmoshvt >>' $F
   ```

   ```
   magic
   tech sky130A
   magscale 1 2
   timestamp 1785844050
   << scnmos >>
   rect 120 47 150 177
   << scpmoshvt >>
   rect 120 297 150 497
   ```

   These are the two layers `/` named in Part 3. Each `rect` line is one rectangle, given as
   `x1 y1 x2 y2`, and it covers the patch of diffusion under the poly stripe, which is the
   transistor's channel
   ([What a layout is](../guide/what-a-layout-actually-is.md#where-the-transistor-is)).

5. The header says `magscale 1 2`, so one unit in the file is 0.005 µm
   ([Drawing in Magic](../guide/drawing-in-magic.md#the-mag-file)). For each rectangle, work out
   its height and its width in µm, and write them down. The height is W and the width is L.

**You should see** two `rect` lines and four numbers in your notes, W and L for each
transistor. L matches what you measured with the box, and W is within 0.01 µm of it. Part 8
checks your numbers against what the tools measure.

## Part 5: DRC under two rule sets

Does the foundry's cell pass DRC, and does the answer depend on the rule set?

1. Press `v`, then left-click once in the empty grey area to the right of the cell. The box
   moves there and keeps its size, so none of the cell is under it.

2. Choose `Drc → DRC update`. Magic checks the whole cell under its default rule set, which the
   `Drc` menu calls `DRC Fast`. The `DRC` button reads `DRC=0`, and the console prints
   `No errors found.`

3. Choose `Drc → DRC Complete` to switch to the full rule set, then `Drc → DRC update` again.
   Switching rule sets doesn't recount anything; only `DRC update` does. The button now reads
   `DRC=3`, and the console still prints `No errors found.` Why both at once?

   ![After `DRC Complete` and `DRC update`: the button reads `DRC=3`, the console `No errors found.`](../assets/img/ad104-l01-05-drc-complete-3.png){fig-alt="Magic's layout window with the inverter and white error hatching over the n-well. The DRC button at the top reads DRC=3 on a red background. The console below shows DRC style is now drc(full), then No errors found."}

   <details>
   <summary>Answer</summary>

   `DRC update` does two things. It checks the whole cell, which sets the count on the `DRC`
   button, and then it reports the rules broken inside the box. The box is on empty space, so
   there is nothing inside it to report.

   </details>

4. Set the box over the whole cell (left-click below and to the left of it, right-click above and
   to the right) and choose `Drc → DRC report`. The console names three rules:

   ```
   N-diff distance to P-tap must be < 15.0um (LU.2)
   P-diff distance to N-tap must be < 15.0um (LU.3)
   All nwells must contain metal-connected N+ taps (nwell.4)
   ```

   ![`Drc → DRC report` with the box round the whole cell: the three rules in the console.](../assets/img/ad104-l01-06-drc-report.png){fig-alt="Magic's layout window with the white box drawn round the whole inverter and the DRC button reading DRC=3. The console under it ends with three lines: N-diff distance to P-tap must be less than 15.0um (LU.2), P-diff distance to N-tap must be less than 15.0um (LU.3), and All nwells must contain metal-connected N+ taps (nwell.4)."}

5. Choose `Options → DRC Manager`, whose window lists one row per rule broken. Click the triangle
   at the start of a row to list that rule's errors (their corners are in Magic's internal
   units), click one, and press `Zoom` to move the view to it. While you use the manager, Magic
   selects the whole cell and writes its name across the drawing; press `,` over the drawing to
   clear the selection, and `v` to see the whole cell again.

   ![The DRC Manager beside the layout: one row each for `nwell.4`, `LU.3` and `LU.2`.](../assets/img/ad104-l01-07-drc-manager.png){fig-alt="Magic's layout window on the left and the drcmgr window on the right. The drcmgr window has buttons Update, Last, Next, Save and Zoom, and a list headed DRC Rule with three rows: All nwells must contain metal-connected N+ taps, P-diff distance to N-tap must be less than 15.0um (LU.3), and N-diff distance to P-tap must be less than 15.0um (LU.2). In the layout, the cell's name and the words Topmost cell in the window are drawn across the inverter."}

6. The foundry's own cell fails the full rule set, and that's the answer we expect. (Magic calls a
   rule set a DRC *style*, which is why `make` later prints `default style` and `full style`.)
   Why does the full rule set find three violations in a cell that has been taped out hundreds
   of times?

   <details>
   <summary>Answer</summary>

   All three come from the same omission. The cell has no well tap, because the library puts its
   taps in a separate cell, and
   [Anatomy of a standard cell](../guide/anatomy-of-a-standard-cell.md#why-the-cell-has-no-well-tap)
   explains why it's done that way. `make` prints the same explanation under the three rule names
   in Part 8, where its output below shows `...`.

   </details>

7. Choose `Drc → DRC Fast` and `Drc → DRC update` to go back to the default rule set.

**You should see** `DRC=0` under `DRC Fast`, `DRC=3` under `DRC Complete`, and the three rules
`nwell.4`, `LU.3` and `LU.2`.

## Part 6: Extract the cell

What circuit does Magic pull out of the geometry?

1. Magic has no menu for extraction; layout engineers type it in the console. Click in the
   console and type these three lines, one at a time:

   ```tcl
   extract all
   ext2spice lvs
   ext2spice -o inv_1.spice
   ```

   - `extract all` reads the geometry, finds the devices and the nets that join them, and writes
     them in Magic's own format to `sky130_fd_sc_hd__inv_1.ext`, in the folder you started Magic
     from.
   - `ext2spice lvs` sets up the next command to write a netlist for LVS. It prints nothing.
   - `ext2spice -o inv_1.spice` turns the `.ext` file into a SPICE netlist called `inv_1.spice`.

   ![The console after the three commands: `Extracting sky130_fd_sc_hd__inv_1 into sky130_fd_sc_hd__inv_1.ext:` and `exttospice finished.`](../assets/img/ad104-l01-08-extract-console.png){fig-alt="Magic's tkcon console. Lines: % extract all, Extracting sky130_fd_sc_hd__inv_1 into sky130_fd_sc_hd__inv_1.ext:, Processing sky130_fd_sc_hd__inv_1, % ext2spice lvs, % ext2spice -o inv_1.spice, exttospice finished."}

2. Print the netlist in the terminal:

   ```bash
   cat inv_1.spice
   ```

   ```spice
   * NGSPICE file created from sky130_fd_sc_hd__inv_1.ext - technology: sky130A

   .subckt sky130_fd_sc_hd__inv_1 A VGND VNB VPB VPWR Y
   X0 Y A VGND VNB sky130_fd_pr__nfet_01v8 ad=0.169 pd=1.82 as=0.169 ps=1.82 w=0.65 l=0.15
   X1 Y A VPWR VPB sky130_fd_pr__pfet_01v8_hvt ad=0.26 pd=2.52 as=0.26 ps=2.52 w=1 l=0.15
   .ends
   ```

3. Count the ports; there are six. `A` and `Y` are the input and output, and `VPWR` and `VGND`
   are the supplies. What are `VNB` and `VPB`, and why are they pins?

   <details>
   <summary>Answer</summary>

   They're the bulk terminals, the fourth terminal on each device line. `VNB` is the NMOS body
   (the p-substrate) and `VPB` the PMOS body (the n-well). The cell exposes them as pins because
   it doesn't tie them to anything itself, since it has no well tap, as you found in Part 3.

   </details>

4. Find `w=0.65` and `w=1`. Nobody typed those numbers in; Magic got them by measuring the same
   two rectangles you read from the file in Part 4.

5. Find `pfet_01v8_hvt`. It tells you the PMOS is the high-threshold flavour, which you'll need
   to remember in Lab 03.

**You should see** two devices, six ports, and `w=0.65 l=0.15` on the NMOS.

## Part 7: LVS with netgen

Is the circuit Magic extracted the circuit the foundry says this cell is?

1. In the terminal, still in the lab folder, compare your netlist with the foundry's:

   ```bash
   netgen -batch lvs "inv_1.spice sky130_fd_sc_hd__inv_1" "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice sky130_fd_sc_hd__inv_1" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl
   ```

   `-batch lvs` runs one comparison and exits. It takes three arguments:
   - your layout netlist and the cell in it, in one pair of quotes;
   - the foundry's netlist, which holds the whole library in one file, and the cell in it;
   - the PDK's setup file, which tells netgen how to compare SKY130's devices: that a
     transistor's source and drain can swap, and which properties to compare.

   netgen prints its comparison and writes the same text to `comp.out`.
   [Layout versus schematic (LVS)](../guide/lvs-asks-a-different-question.md) explains how it
   compares two netlists.

2. Read the last lines of the report:

   ```bash
   tail -3 comp.out
   ```

   ![The terminal after netgen and `tail -3 comp.out`: `Final result: Circuits match uniquely.`](../assets/img/ad104-l01-09-netgen-terminal.png){fig-alt="A terminal window. netgen's output ends with Circuit 1 contains 2 devices, Circuit 2 contains 2 devices, both with 6 nets, then Final result: Circuits match uniquely, and LVS Done. Below it, the command tail -3 comp.out prints Final result: Circuits match uniquely."}

**You should see** `Final result: Circuits match uniquely.`

## Part 8: Run the checker

Do the tools, run in batch, measure the cell the way you did?

1. Run the lab's checker:

   ```bash
   make
   ```

   The `Makefile` sets `PDK=sky130A` itself, so this works even if `.designinit` failed for you.
   It takes about a second (1.07, 0.99 and 1.00 s on three timed clean runs) and prints:

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

   If it stops or a number differs:

   | What you see | What it means |
   |---|---|
   | `DRC violations, default style` is not 0 | The technology did not load. Check that `$PDK_ROOT` points at the PDKs (`/foss/pdks` in the workbench image) and that `.magicrc` is in the folder you ran `make` from. |
   | `results/report.txt is missing` | Magic didn't finish, so read `results/magic.log`. |
   | `LVS: netgen wrote no report` | Read `results/netgen.log`. The cause is usually `$PDK_ROOT` again. |
   | `magic: command not found` | You're not in the workbench container. |

2. Compare the two transistor lines with the W and L you worked out from the file in Part 4, the
   cell width with your rail, the two DRC counts with Part 5, and the LVS line with Part 7.

**You should see** `PASS`, and numbers that match yours: `W=0.65 L=0.15` and `W=1 L=0.15`, `0`
under the default rule set and `3` under the full one.

## Part 9: Browse the library

How does the library offer more drive strength for the same logic?

1. Count the cells in the library and list the inverters:

   ```bash
   ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/ | wc -l
   ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/ | grep __inv_
   ```

   The first prints `446`. The second lists seven inverters: `inv_1`, `inv_2`, `inv_4`, `inv_6`,
   `inv_8`, `inv_12` and `inv_16`. They all have the same logic, and the drive strength goes up
   from each one to the next.

2. Open the whole library in KLayout, which is a better viewer for a file this size than Magic:

   ```bash
   klayout -nn $PDK_ROOT/sky130A/libs.tech/klayout/tech/sky130A.lyt $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds &
   ```

   `-nn` loads SKY130's layer names and colours for the file that follows. KLayout opens the
   file as a viewer, with no drawing tools in its toolbar. Wait until the file name shows in
   the window's title bar. If a `Tip` window asks about showing the full hierarchy, click
   `Yes`. Then maximise the window by double-clicking its title bar.

3. The `Cells` panel at the top left lists every cell in the file, but at the workbench's
   screen size it is only two rows tall. Close the `Libraries` and `Tool Options` panels under it
   with the × at the right end of their title bars; `Cells` then fills the left column. Drag the
   column's right edge to the right until the cell names fit.

4. Show `inv_1`. Click in the cell list and type `sky130_fd_sc_hd__inv_1`: a search field opens
   above the list, and the list jumps to the cell. Press Return, right-click the highlighted row
   and choose `Show As New Top`. KLayout draws the cell to fill the window.

   ![The Cells panel with `sky130_fd_sc_hd__inv_1` highlighted and its right-click menu open at `Show As New Top`.](../assets/img/ad104-l01-10-klayout-menu.png){fig-alt="The left part of KLayout. The Cells panel fills the left column with a long list of sky130_fd_sc_hd cell names; sky130_fd_sc_hd__inv_1 is highlighted near the bottom, and a menu beside it lists Flat Cell List, Split Mode, Sorting, User Properties, Show As New Top, Hide, Show, Show All, Where am I? and Save Selected Cells As."}

5. Point at the top-right corner of the magenta outline, which is the cell's boundary, and read
   the `xy` numbers at the bottom right of the window. They're the pointer's position in µm,
   and the cell's lower-left corner is at 0, 0.

6. Before you look at `inv_8`, write down a prediction: is it taller than `inv_1`, wider, or
   both? Then show `sky130_fd_sc_hd__inv_8` the same way and read its corner. KLayout fits each
   cell to the window, so compare the numbers rather than the size on screen.

   ![`inv_8` in KLayout, with the pointer on its top-right corner: `xy` reads about 4.14 and 2.72.](../assets/img/ad104-l01-11-klayout-inv8.png){fig-alt="KLayout, maximised. On the left, the Cells panel lists the library's cells with sky130_fd_sc_hd__inv_8 highlighted in bold. In the middle, the inv_8 layout: a wide cell with many poly fingers between two blue rails, inside a magenta outline. On the right, the Layers panel. In the status bar at the bottom, xy reads 4.13840 and 2.72068."}

   <details>
   <summary>Answer</summary>

   It's only wider. `inv_8` is about 4.14 µm wide against 1.38 for `inv_1`, and both are
   2.72 µm tall. Every cell in the library is 2.72 µm tall, and each step up in drive strength
   is the same logic with wider transistors
   ([Anatomy of a standard cell](../guide/anatomy-of-a-standard-cell.md#drive-strength)), so the
   extra area has to go sideways.

   </details>

**You should see** 446 cells, seven inverters, and the top-right corners at about 1.38, 2.72 for
`inv_1` and about 4.14, 2.72 for `inv_8`: the same height, and three times as wide.

## Part 10: Explore SiliWiz (optional)

This part runs in your browser and needs no setup. It takes about twenty minutes.

1. Open **<https://app.siliwiz.com/>**. [SiliWiz](../guide/siliwiz.md) describes the interface.
   Load the inverter from the **Preset** dropdown above the drawing area to see a finished
   example.
2. Open **LESSONS** (top right) and do the *nmos* lesson. Drag the cross-section cut line with the
   blue slider so that it passes through the middle of the poly stripe, and look at the
   cross-section: substrate, a thin oxide, poly on top, and doped regions on either side.
3. Now drag the cut so that it misses the poly. The cross-section becomes two doped regions with
   nothing joining them, because the transistor exists only where the poly crosses.
4. Move a contact until it hangs off the edge of the diffusion it sits on, and open the
   **CROSS SECTION & DRC** tab. SiliWiz's rules aren't SKY130's, but its complaint, "this thing
   does not surround that thing by enough", has the same shape as half the errors you'll fix in
   Lab 02.
5. Do the *parasitics* lesson. Stretch a metal wire longer and watch what happens to the
   simulated waveform. That's the argument of Lab 05, made in two minutes.

**You should see** the transistor appear and disappear in the cross-section as the cut moves on
and off the poly, and a DRC complaint as soon as the contact leaves its diffusion.

## Finishing

You're done when your own netgen run in Part 7 ended in `Circuits match uniquely.`, and the W and
L you worked out from the `.mag` file in Part 4 match the `W=` and `L=` that `make` prints for
both transistors.

Questions:

- Why does the box give a W that is 0.01 µm off when the file says 0.65? Part 4, step 3
  answers it.
- Why did `Drc → DRC update` print `No errors found.` while the `DRC` button showed a count?
  Part 5, step 3 answers it.
- Why does the full rule set find three violations in a cell that has been taped out hundreds of
  times? Part 5, step 6 answers it.

Submit: nothing for this lab.

Next on the Course path: read [Drawing in Magic](../guide/drawing-in-magic.md),
[Reading DRC errors](../guide/drc-is-a-conversation.md) and
[The full DRC rule set](../guide/the-rule-set-you-are-not-running.md), then do
[Lab 02: Break it on purpose](../labs/lab-02-break-it-on-purpose-overview.md).
