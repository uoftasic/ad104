# Lab 02: Break it on purpose

In this lab you'll fix five copies of the same inverter. We put one mistake in each copy, and each
mistake breaks a real SKY130 design rule (two of them break two rules at once, as Part 1 shows).
You'll do the work in Magic, the way a layout engineer does: find each violation with the `Drc`
menu, read its rule, measure the shapes with the box, and paint or erase until DRC is clean, then
extract the last cell and run LVS on it yourself. We've put this lab before you draw anything of
your own on purpose, because the best time to read your first DRC errors is on a layout you have
no attachment to.

Package: [`labs/lab-02-break-it-on-purpose/`](https://github.com/uoftasic/ad104-m/tree/main/labs/lab-02-break-it-on-purpose)

## Before you start

- Finish [Lab 01](../labs/lab-01-open-the-cell-overview.md), so the course is loaded, your tools
  check out, and you know the click recipe from its Part 3.
- Read [Drawing in Magic](../guide/drawing-in-magic.md),
  [Reading DRC errors](../guide/drc-is-a-conversation.md) and
  [The full DRC rule set](../guide/the-rule-set-you-are-not-running.md).
- Keep the [DRC error decoder](../reference/drc-error-decoder.md) open in another tab.

**Time:** about 2.5 hours, an estimate. Each `make` takes about 4 seconds (we timed two clean runs
at 3.51 s and 3.58 s).

## Part 1: Run the checker on all five cells

What does each cell break, as the checker sees it?

1. Go into the lab package and run it:

   ```bash
   cd labs/lab-02-break-it-on-purpose
   make
   ```

   As shipped, it prints:

   ```
     FIVE CELLS, FIVE MISTAKES

     cell      DRC default  DRC full   LVS
     -------------------------------   ------------------------
        drc_01           3         3   match
        drc_02           2         2   match
        drc_03          14        14   match
        drc_04           2         2   match
        drc_05           0         1   Netlists do not match

     drc_01 still breaks:
         N-well overlap of P-Diffusion < 0.18um (diff/tap.8)
     drc_02 still breaks:
         Local interconnect overlap of poly contact < 0.08um in one direction (li.5)
     drc_03 still breaks:
         poly overlap of poly contact < 0.08um in one direction (licon.8a)
         poly overlap of poly contact < 0.05um (licon.8)
     drc_04 still breaks:
         Local interconnect spacing < 0.17um (li.3)
     drc_05 still breaks:
         All nwells must contain metal-connected N+ taps (nwell.4)
         P-diff distance to N-tap must be < 15.0um (LU.3)

   FAIL  Still to fix: drc_01, drc_02, drc_03, drc_04, drc_05

         Open a cell in Magic (`cd mag; magic -d X11 drc_01 &`), run
         Drc > DRC update, and read the rule with Drc > DRC report or
         Options > DRC Manager. If the DRC button shows no count, choose
         Drc > DRC Complete and run Drc > DRC update again.
   ```

2. Before you touch anything, look at the `drc_03` row. It reports 14 violations, even though we
   changed only one number in that cell. How can one mistake produce fourteen?

   <details>
   <summary>Answer</summary>

   A single contact that is 0.01 µm short of its enclosure produces fourteen error tiles, because
   Magic reports each edge of the offending region separately. So the violation count tells you
   how many tiles Magic flagged rather than how many mistakes there are, and fourteen errors can
   mean a single number to change.

   </details>

3. Now look at the `drc_05` row. It has zero violations under the default rule set, yet netgen
   says the netlists do not match, so the cell passes the default check and is still the wrong
   circuit. You'll come back to it in Part 5.

**You should see** `FAIL` and all five cells listed under "Still to fix".

## Part 2: Read one violation in Magic

How do you get Magic to show you a violation and name its rule? Work through `drc_03` once with
these steps; Parts 4 to 6 repeat them for the other cells.

1. Open the cell in Magic, from the `mag/` folder:

   ```bash
   cd mag
   magic -d X11 drc_03 &
   ```

   Press `v` with the pointer over the drawing to fit the cell in the window. The `DRC` button
   has a green tick and no count, and there is no white hatching anywhere, even though this cell
   has fourteen violations. Why does it look clean?

   ![`drc_03` just after it opens: the `DRC` button shows no count and the drawing has no hatching.](../assets/img/ad104-l02-01-open-clean.png){fig-alt="Magic's layout window with the inverter drc_03: n-well at the top, diffusions, a red poly stripe with a small pad, blue local-interconnect wires and two purple rails. The DRC button at the top has a green tick and reads just DRC."}

   <details>
   <summary>Answer</summary>

   It looks clean because Magic hasn't checked it yet. Its background checker only re-checks
   tiles you have *edited*, and loading a file from disk doesn't edit anything, so nothing in the
   cell has been checked since you opened it.

   </details>

2. Choose `Drc → DRC update`. The button turns red and reads `DRC=14`, and white hatching appears
   where the violations are. The console prints `No errors found.`, for the reason you met in
   Lab 01: the report covers only what is inside the box.

   ![After `DRC update`: the button reads `DRC=14`.](../assets/img/ad104-l02-02-drc-update-14.png){fig-alt="Magic's layout window and console. The DRC button reads DRC=14 on red; small white hatched areas show round the poly pad. The console ends with Loading DRC CIF style and No errors found."}

3. With the pointer over the drawing, press `=`. The box jumps to the next error, the view zooms
   in round it, and the console names the rule broken there.

   ![After `=`: the view zoomed on the poly pad, the box on one error, the rule `licon.8a` in the console.](../assets/img/ad104-l02-03-equal-key.png){fig-alt="Magic zoomed in on the poly pad and its contact, a square with a cross, with white hatched error strips round it. The console shows Error area and the line poly overlap of poly contact less than 0.08um in one direction (licon.8a)."}

4. Set the box over the whole poly pad (left-click below and to the left of it, right-click above
   and to the right) and choose `Drc → DRC report`. It names every rule broken inside the box:

   ```
   poly overlap of poly contact < 0.08um in one direction (licon.8a)
   poly overlap of poly contact < 0.05um (licon.8)
   ```

   ![`DRC report` with the box over the pad: both rules in the console.](../assets/img/ad104-l02-04-drc-report.png){fig-alt="Magic zoomed on the poly pad with the white box drawn round the whole pad. The console lists poly overlap of poly contact less than 0.08um in one direction (licon.8a) and poly overlap of poly contact less than 0.05um (licon.8)."}

5. Choose `Options → DRC Manager` for the same list sorted by rule. Click the triangle at the
   start of a rule's row to list its errors, click one, and press `Zoom` to move the view onto
   it. Press `,` over the drawing afterwards: the manager leaves the whole cell selected, with
   its name written across the drawing.

   ![The DRC Manager with the `licon.8` row open and one of its errors selected.](../assets/img/ad104-l02-05-drc-manager.png){fig-alt="The drcmgr window. Buttons Update, Last, Next, Save, Zoom. Under the DRC Rule heading, the row poly overlap of poly contact less than 0.05um (licon.8) is open, with error rows of four numbers each below it; the first, 268 520 280 522, is highlighted."}

6. Look up `licon.8` in the [DRC error decoder](../reference/drc-error-decoder.md) and work out
   what it protects.

**You should see** `DRC=14` on the button after `DRC update`, and `licon.8` and `licon.8a` named.

## Part 3: Measure and fix drc_03

How big is the pad, and how big does the rule say it has to be?

1. Press `v`, set a rough box round the poly pad and press `ctrl+z` to zoom on it.

2. Measure the pad with the click recipe from Lab 01: left-click its lower-left corner,
   right-click its upper-right corner, and press `b`. Then measure the contact cut, the square
   with the cross in it, the same way.

   ![The box on the poly pad's corners and `b`'s output: `microns: 0.250 x 0.250`.](../assets/img/ad104-l02-06-measure-pad.png){fig-alt="Magic zoomed on the poly pad, with the white box exactly on the pad's outline. The console shows microns 0.250 x 0.250 with corners 1.300, 2.400 and 1.550, 2.650."}

   ```
   microns:   0.250 x 0.250   ( 1.300,  2.400), ( 1.550,  2.650)  0.062
   microns:   0.170 x 0.170   ( 1.340,  2.440), ( 1.510,  2.610)  0.029
   ```

3. Work out the margin of poly round the cut on each side, and compare it with what `licon.8` and
   `licon.8a` ask for in the decoder. Decide how big the new pad has to be, and check in the
   decoder that a pad that size stays clear of the diffusions above and below it (`licon.14`,
   `poly.4`).

   <details>
   <summary>Hint: the pad's size</summary>

   The margin is 0.04 µm on every side. `licon.8` wants 0.05 all round and `licon.8a` wants 0.08
   on both sides of one axis, so the pad has to be at least 0.27 µm square and at least 0.33 µm on
   one axis, centred on the cut.

   </details>

4. Draw the new pad: set the box on its corners with the click recipe, scroll the palette to
   `polysilicon` and middle-click it. Painting adds poly to what is already there, so the old pad
   and the cut stay as they were inside the new one.

   ![The new, larger poly pad painted round the cut, and `DRC=0` on the button.](../assets/img/ad104-l02-07-pad-painted.png){fig-alt="Magic zoomed on the gate: a wider red poly pad round the contact cut, the white box on the pad's outline, no hatching, and the DRC button reading DRC=0."}

5. Choose `Drc → DRC update`. If the button still shows a count, press `=` and choose
   `Drc → DRC report` again to see what is left.

6. Save the cell: choose `File → Save...`, then click `write` in the dialog. Magic's caption
   doesn't show that a cell has unsaved changes, and `make` reads the file, so save before every
   `make`. Never use `Cell → Save as...` here: it saves a copy under a new name, and `make`
   checks only `drc_03.mag`.

   ![The save dialog: `drc_03 : write, autowrite, flush, skip, or abort command?`](../assets/img/ad104-l02-08-save-dialog.png){fig-alt="A small dialog asking drc_03 : write, autowrite, flush, skip, or abort command? with five buttons: write, flush, skip, abort and autowrite."}

7. In the terminal, go back up to the package folder and run the checker:

   ```bash
   cd ..
   make
   ```

**You should see** `drc_03` at `0` in both DRC columns and `match` in LVS.

## Part 4: Fix drc_01, drc_02 and drc_04

What does each rule protect, and what change satisfies it? Work on one cell at a time, starting
with `drc_01`.

1. Open the cell in the Magic you already have: choose `File → Open...`, type `drc_01.mag` in
   `File name:`, and press Return.

   ![The Open dialog with `drc_01.mag` typed in `File name:`.](../assets/img/ad104-l02-09-open-dialog.png){fig-alt="Tk's Open dialog listing drc_01.mag to drc_05.mag, with drc_01.mag typed in the File name field, Files of type set to Magic (*.mag), and Open and Cancel buttons."}

2. Press `v` over the drawing, then left-click anywhere in it. Until you click, the box still
   belongs to the cell you had open before, and `Drc → DRC update` doesn't check the new cell:
   the console says `The box is not in the same coordinate system as the window.`

3. Find the violation with the Part 2 steps: `Drc → DRC update`, `=`, `Drc → DRC report`. Look the
   rule up in the [DRC error decoder](../reference/drc-error-decoder.md) and work out what it
   protects.

4. Measure the shapes the rule names with the click recipe, and decide what to change. Work from
   what the rule asks for with a comfortable margin, rather than nudging shapes until the
   hatching disappears.

   The rules that two of the five cells break use the phrase "in one direction". As
   [Reading DRC errors](../guide/drc-is-a-conversation.md#in-one-direction) explains with
   examples, it means that you pick an axis, x or y, and on that axis the outer layer must extend
   past the inner one by at least the rule's amount **on both sides**. Only one axis needs to be
   generous, which is why the fix often costs you nothing.

5. Change the geometry. To add a layer, set the box and middle-click the layer in the palette,
   as in Part 3. To remove a layer, set the box over what has to go and hold shift while you
   middle-click the layer in the palette: Magic erases that layer, and only that layer, inside
   the box. Don't middle-click in the drawing itself. Over empty space that erases every layer in
   the box, wells included.

   ![After a shift + middle-click on `locali`: the li inside the box is gone, and the rest of the pad stays.](../assets/img/ad104-l02-10-erase-shift-middle.png){fig-alt="Magic zoomed on drc_04's gate: the red poly pad with its contact on the left, the A pad's blue li round the contact, and to its right the empty white box where the li was erased. The Y wire runs down the right side. The DRC button reads DRC=0."}

6. Choose `Drc → DRC update` until the button shows no count, then save with `File → Save...` and
   `write`.

7. Repeat steps 1 to 6 for `drc_02` and `drc_04`, then run `make` in the package folder.

If you get stuck, open the hint for that cell only, and only after you have tried.

<details>
<summary>Hint for drc_01</summary>

`diff/tap.8` is an enclosure rule. An implant mask has to extend past what it is implanting,
because two masks never align perfectly. Here the n-well has to reach further below the
p-diffusion: paint more `nwell` under it. Then check `diff/tap.9` in the decoder, so the well
doesn't come too close to the n-diffusion below.

</details>

<details>
<summary>Hint for drc_02</summary>

`li.5` is an enclosure rule: a wire has to overhang the contact under it. Paint a bigger
`locali` patch over the poly contact, generous on one axis, and keep it clear of the Y wire
(`li.3`).

</details>

<details>
<summary>Hint for drc_04</summary>

`li.3` is a spacing rule, so this violation means that two wires on different nets are too close
together. Erase the part of the A pad that reaches toward the Y wire (shift + middle-click on
`locali`), and keep enough li round the contact for `li.5`.

</details>

[`solutions/README.md`](https://github.com/uoftasic/ad104-m/tree/main/labs/lab-02-break-it-on-purpose/solutions)
in the package explains how to get unstuck without reading the answer.

**You should see** `drc_01` to `drc_04` at `0` in both DRC columns, still `match` in LVS.

## Part 5: drc_05 under the full rule set and LVS

The default checker has reported `drc_05` clean since your first run, yet the cell is wrong.
Which tools notice, and what are they telling you?

1. Open `drc_05` the way Part 4 did (`File → Open...`, `drc_05.mag`, then `v` and a left click in
   the drawing), and choose `Drc → DRC update`. The button reads `DRC=0`.

2. Choose `Drc → DRC Complete`, then `Drc → DRC update`. The button reads `DRC=1`. Press `=`,
   press `v` if the cell has shrunk to a speck, and choose `Drc → DRC report`:

   ```
   P-diff distance to N-tap must be < 15.0um (LU.3)
   All nwells must contain metal-connected N+ taps (nwell.4)
   ```

   ![`drc_05` under `DRC Complete`: `DRC=1`, and `LU.3` and `nwell.4` in the console.](../assets/img/ad104-l02-11-drc-complete-1.png){fig-alt="Magic's layout window with drc_05 and the white box over the n-well. The DRC button reads DRC=1. The console lists P-diff distance to N-tap must be less than 15.0um (LU.3) and All nwells must contain metal-connected N+ taps (nwell.4)."}

   Both are context rules, which a cell can satisfy only with help from what is placed around it
   ([Anatomy of a standard cell](../guide/anatomy-of-a-standard-cell.md#why-the-cell-has-no-well-tap)
   explains why).

3. Extract the cell yourself. Click in the console and type the three lines from Lab 01 Part 6;
   plain `ext2spice` names the netlist after the cell, `drc_05.spice`, in `mag/`:

   ```tcl
   extract all
   ext2spice lvs
   ext2spice
   ```

4. In the terminal, go into `mag/` and run netgen on the netlist. The schematic is
   `../spice/inv_sch.spice`, and the inverter in it is called `my_inv`:

   ```bash
   cd mag
   netgen -batch lvs "drc_05.spice drc_05" "../spice/inv_sch.spice my_inv" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl
   ```

   ![netgen on `drc_05`: 5 nets against 4, and `Netlists do not match.`](../assets/img/ad104-l02-12-netgen-mismatch.png){fig-alt="A terminal with netgen's output. Both circuits contain 2 devices; Circuit 1 contains 5 nets and Circuit 2 contains 4 nets, marked MISMATCH. The final result reads Netlists do not match."}

   The two circuits have the same two devices, but your layout has five nets where the
   schematic has four. netgen reports the mismatch without ever using the word "tap".

5. To find the extra net, print the PMOS line of your netlist:

   ```bash
   grep pfet drc_05.spice
   ```

   ```spice
   X1 Y A VPWR w_0_600# sky130_fd_pr__pfet_01v8_hvt ad=1.1 pd=4.2 as=0.95 ps=3.9 w=1 l=0.15
   ```

   netgen reports the same name near the end of `comp.out`, as a net with `(no matching net)`.
   What is `w_0_600#`, and why is the PMOS body on it?

   <details>
   <summary>Answer</summary>

   `w_0_600#` is the PMOS body. It's an invented node name, and the body is on it instead of on
   VPWR because the n-well tap has no contact on it, so nothing ties the well to VPWR.

   </details>

**You should see** `DRC=0` under `DRC Fast` and `DRC=1` under `DRC Complete`, the rules `LU.3`
and `nwell.4`, `Netlists do not match.` from netgen, and the PMOS body on `w_0_600#`.

## Part 6: Fix drc_05

What does the cell need, and how do you draw a contact exactly 0.17 µm square?

1. Click the layout window's title bar. After you type in the console the keyboard stays there,
   and without this click your next key press goes into the console instead of the drawing. (A
   click in the drawing would move the box.)

2. Work out what is missing and where it goes, from the rule names and the PMOS line. Every cut
   in SKY130 is exactly 0.17 × 0.17 µm (`licon.1` in the decoder), and it has to sit inside the
   shapes it joins with the margins the decoder gives.

   <details>
   <summary>Hint: what to draw</summary>

   The n-well tap, the green strip near the top of the n-well, needs a contact under the li wire
   that runs down from the VPWR rail. In the palette that contact is `nsubstratencontact`, and
   `licon.7` sets how far the tap has to extend past it.

   </details>

3. Draw the contact with a **typed size**, which is quicker and more exact than clicking two
   corners on a square this small:
   1. Zoom in on where the contact goes (a rough box, then `ctrl+z`).
   2. Left-click where its lower-left corner goes.
   3. Click in the console and type `box size 0.17um 0.17um`. It sets the box's size and keeps
      the corner you clicked.
   4. Click the layout window's title bar, then press `b` over the drawing to check:
      `microns:   0.170 x 0.170`.
   5. Middle-click `nsubstratencontact` in the palette.

   ![After `box size 0.17um 0.17um` and `b`: the console reads `microns:   0.170 x 0.170`.](../assets/img/ad104-l02-13-box-size.png){fig-alt="Magic zoomed in, with a small square white box in the middle of the drawing. The console under it shows the typed command box size 0.17um 0.17um, then the output of b: microns 0.170 x 0.170."}

4. Choose `Drc → DRC update`, still under `DRC Complete`. The button shows no count.

5. Extract again (the same three lines in the console) and run the same netgen command again in
   the terminal. It now ends in `Final result: Circuits match uniquely.`

6. Choose `Drc → DRC Fast` and save with `File → Save...` and `write`. In the terminal, go back
   up to the package folder (`cd ..`) and run `make`.

7. If you had only run the default rule set, what would have told you about this cell?

   <details>
   <summary>Answer</summary>

   Netgen would have. LVS reported `Netlists do not match` on a cell that the default rule set
   called clean.

   </details>

The habit to take from this part is the rule of thumb from
[The full DRC rule set](../guide/the-rule-set-you-are-not-running.md#the-rule-of-thumb):
**before you believe an empty DRC button, choose `Drc → DRC Complete` and update.** The labs'
checkers show you both counts, but tools outside this course won't do that for you.

**You should see** `drc_05` at `0` under both rule sets and `match` in LVS, and `make` ending in
`PASS`.

## Part 7: Erase instead of fix

What happens if you make a violation go away by deleting the shape that broke the rule? You
could take every one of these cells to zero violations that way, so try it once, on `drc_04`.

1. Open `drc_04` (`File → Open...`, then `v` and a left click in the drawing). Set the box over
   the whole `A` pad, the li square round the gate's contact, and erase its li with a shift +
   middle-click on `locali` in the palette. The li and the contact inside it disappear, and the
   poly pad stays.

2. Choose `Drc → DRC update`; the button shows no count. Save with `File → Save...` and `write`,
   and before you run `make`, predict what it will show in the DRC and LVS columns for `drc_04`.

3. Run `make`. The cell is clean under both rule sets, the LVS column says
   `Top level cell failed pin matching`, and `make` adds:

   ```
     Note: drc_04 is clean and no longer an inverter.
     Erasing the shape that broke the rule is not a fix. Move it, resize it,
     or add the thing it needed - the circuit has to survive.
   ```

   Why does this lab run LVS on all five cells, and not only on `drc_05`?

   <details>
   <summary>Answer</summary>

   Because a change that satisfies DRC can break the circuit, as erasing the pad just did. A
   layout has two jobs, passing the rules and being the right circuit, and a change that does one
   at the expense of the other hasn't moved you forward.

   </details>

4. Put the pad back: press `u` with the pointer over the drawing to undo the erase. Save again,
   and run `make` again.

**You should see** the note in step 3, and then `drc_04` back to `match` and `make` ending in
`PASS`.

## Finishing

You're done when `make` ends in `PASS`, with all five of your fixed cells at 0 violations under
both rule sets and `match` in LVS.

Questions:

- What does "in one direction" mean in a rule name? Part 4, step 4 explains it.
- Which cell would you have shipped broken if you had only run the default rule set, and what
  would have warned you? Part 6, step 7 answers it.

Submit: nothing for this lab.

## Going further (optional)

To start again or check your answers:

```bash
make reset        # throw your fixes away and rebuild the five broken cells
make solutions    # write the answer key into solutions/
```

`tcl/make_broken.tcl` generates the broken cells and has one `BREAK` comment for each change, so
it doubles as the answer key. Read it after you finish, not before.

Next on the Course path: read [Stick diagrams](../guide/stick-diagrams.md),
[Extraction](../guide/extraction-is-reverse-engineering.md) and
[Layout versus schematic (LVS)](../guide/lvs-asks-a-different-question.md), then do
[Lab 03: Draw an inverter](../labs/lab-03-draw-an-inverter-overview.md).
