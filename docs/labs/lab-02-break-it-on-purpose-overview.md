# Lab 02 — Break it on purpose

**Package:** [`labs/lab-02-break-it-on-purpose/`](https://github.com/uoftasic/ad104/tree/main/labs/lab-02-break-it-on-purpose)

Five copies of the same inverter. Each one has exactly one number changed, and
each change breaks exactly one real SKY130 design rule. Your job is to find
and fix all five.

You have not drawn anything yet. That is deliberate: **the best time to read
your first DRC error is on a layout you have no attachment to.**

## Prerequisites

[DRC is a conversation](guide/drc-is-a-conversation.md) ·
[The rule set you are not running](guide/the-rule-set-you-are-not-running.md) ·
[Drawing in Magic](guide/drawing-in-magic.md)

## Objectives

- Read a real DRC message and turn it into an edit
- Meet the four shapes a rule comes in — width, spacing, enclosure, area
- Understand "in one direction", which reads wrong until someone explains it
- Discover a violation the **default rule set does not report at all**
- Learn why deleting the offending shape is not a fix

## Run it

```bash
cd labs/lab-02-break-it-on-purpose
make
```

About **4 seconds** (3.97 s and 4.40 s on two timed clean runs). As shipped:

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
```

## Look at that table before you touch anything

Two rows are doing something the other three are not.

**`drc_03` has 14 violations from one mistake.** A single contact that is
0.01 µm short of its enclosure produces fourteen error tiles, because Magic
reports each edge of the offending region separately. **The violation count is
not the number of mistakes.** Beginners assume 14 errors means an afternoon;
it means one number.

**`drc_05` is clean under the default rule set and wrong anyway.** Zero
violations, and netgen says the netlists do not match. That is the cell worth
more than the other four put together — see below.

## The loop

For each cell:

```bash
make why C=3      # every violation in cell 3, with its rule name
make edit C=3     # open it in Magic
```

Magic opens with a green `☑ DRC` in the toolbar and **no white hatching anywhere**, on a
cell that has three violations. That is not a clean cell — Magic's background checker only
re-checks tiles you have *edited*, and loading a file from disk edits nothing, so it has
never looked. Ask it to look:

```tcl
drc check
```

The toolbar goes red with a count and the white hatching appears. (`Drc → DRC update` on
the menu bar does the same thing with the mouse.) Now put the cursor box over one of the
white hatched areas and type:

```tcl
drc why
```

![What that looks like](../assets/img/ad104-magic-drc-why.png)

*Cell `drc_03`. `DRC=14` in the toolbar, white hatching around the poly
contact, and `drc why` naming the rule twice — once plainly and once in its
"in one direction" form.*

Then look the rule up in the
[DRC error decoder](reference/drc-error-decoder.md), work out what it is
protecting, and change the geometry to satisfy it. Save (`save`), and run
`make` again.

## The five

Do not read this section until you have tried. If you are stuck, read only
the row you are stuck on.

| Cell | Rule | Category | The idea |
|---|---|---|---|
| `drc_01` | `diff/tap.8` | enclosure | An implant mask has to extend past what it is implanting, because two masks never align perfectly. |
| `drc_02` | `li.5` | enclosure | A wire has to overhang the contact under it. Paint the wire first, bigger, and put the contact inside it. |
| `drc_03` | `licon.8` / `licon.8a` | enclosure | A 0.15 µm poly stripe cannot hold a 0.17 µm contact. Gates get a landing pad. |
| `drc_04` | `li.3` | spacing | Two wires on different nets, too close. |
| `drc_05` | `nwell.4`, `LU.3` | context | **Invisible to the default rule set.** |

## "In one direction"

Two of the five use this phrasing and it does not mean what it looks like.

> Pick an axis, x or y. On that axis the surrounding layer must extend past
> the inner one by at least that much **on both sides**.

So a contact sitting in a shape that is generous vertically and flush
horizontally is legal, because the y axis satisfies the rule on its own. A
contact tucked into a corner is not, because neither axis has clearance both
ways.

This is why the fix is often free: you do not need to make everything bigger,
only one axis.

## `drc_05`, and why it is the one to remember

It was reported clean by the default checker from the very first run, and it
was wrong the whole time. The n-well tap has no contact on it, so nothing ties
the well to VPWR.

**Two independent tools notice, and neither says the word "tap".**

The full rule set:

```
All nwells must contain metal-connected N+ taps (nwell.4)
P-diff distance to N-tap must be < 15.0um (LU.3)
```

And netgen, which reports a mismatch because the extracted netlist has:

```spice
X1 Y A VPWR w_0_600# sky130_fd_pr__pfet_01v8_hvt w=1 l=0.15
```

`w_0_600#` is the PMOS body, sitting on an invented node instead of on VPWR.

The habit to take away is one line:

> **Before you believe a DRC count of zero, run `drc style drc(full)`.**

Everything in this course runs both and shows you both, so you never have to
remember. Everything outside this course will not.

## The other trap: erasing is not fixing

You can take every one of these cells to zero violations by deleting the
shape that broke the rule. Try it on `drc_04` — erase the A pad and the li
spacing error is gone.

`make` then says:

```
  Note: drc_04 is clean and no longer an inverter.
  Erasing the shape that broke the rule is not a fix. Move it, resize it,
  or add the thing it needed - the circuit has to survive.
```

That is why this lab runs LVS on all five as well as DRC. **A layout has two
jobs and satisfying one at the expense of the other is not progress.**

## Expected results

- [ ] all five cells at 0 violations under **both** rule sets
- [ ] all five still `match` in LVS
- [ ] `make` ends in `PASS`
- [ ] you can say, without looking, what "in one direction" means

## Reset and answers

```bash
make reset        # throw your fixes away, rebuild the five broken cells
make solutions    # write the answer key into solutions/
```

`tcl/make_broken.tcl` is the generator, and it is commented with each `BREAK`.
It is the answer key too — read it after, not before.

## Files

| Path | What it is |
|---|---|
| `mag/drc_0*.mag` | the five broken cells, the ones you edit |
| `tcl/make_broken.tcl` | how they were broken, one `BREAK` comment each |
| `tcl/make_fixed.tcl` | the same generator with the five numbers put back |
| `tcl/verify.tcl` | DRC both ways and extract, for all five |
| `spice/inv_sch.spice` | what an inverter is supposed to be, for LVS |
| `solutions/README.md` | how to get unstuck without reading the answer |
