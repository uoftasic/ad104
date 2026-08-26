# Lab 02 — Break it on purpose

Writeup: [uoftasic.com/ad104 → Lab 02](https://uoftasic.com/ad104/#/labs/lab-02-break-it-on-purpose-overview)

Five copies of the same inverter. Each one has exactly one number changed, and
each change breaks exactly one real SKY130 rule. Fix all five.

## Run it

```bash
cd labs/lab-02-break-it-on-purpose
make
```

**About 4 seconds** (3.97 s and 4.40 s on two timed clean runs). As shipped:

```
  cell      DRC default  DRC full   LVS
  -------------------------------   ------------------------
     drc_01           3         3   match
     drc_02           2         2   match
     drc_03          14        14   match
     drc_04           2         2   match
     drc_05           0         1   Netlists do not match
```

Two rows are worth staring at before you start. `drc_03` has **14 violations
from one mistake** — the count is not the number of errors. `drc_05` is
**clean under the default rule set and wrong anyway**.

## The loop

```bash
make why C=3      # every violation in cell 3, with its rule name
make edit C=3     # open it in Magic
```

In Magic: put the cursor box over a white error dot, type `drc why`, look the
rule up in the
[DRC error decoder](https://uoftasic.com/ad104/#/reference/drc-error-decoder),
change the geometry, `save`, and run `make` again.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC both ways + LVS on all five, verdict |
| `make why C=1..5` | every violation in one cell |
| `make edit C=1..5` | open one cell in Magic |
| `make reset` | **throw your fixes away** and rebuild the broken cells |
| `make solutions` | write the answer key into `solutions/` |
| `make clean` | delete `results/` |

## Why LVS is in a DRC lab

Because you can take every one of these cells to zero violations by deleting
the shape that broke the rule, and that is not a fix. The checker will notice:

```
  Note: drc_04 is clean and no longer an inverter.
```

## Files

| Path | What it is |
|---|---|
| `mag/drc_0*.mag` | the five broken cells — these are what you edit |
| `tcl/make_broken.tcl` | how they were broken, one `BREAK` comment each. The answer key. |
| `tcl/make_fixed.tcl` | the same generator with the five numbers put back |
| `tcl/verify.tcl` | DRC both ways and extract, for all five |
| `spice/inv_sch.spice` | what an inverter is supposed to be |
| `solutions/README.md` | how to get unstuck without reading the answer |
