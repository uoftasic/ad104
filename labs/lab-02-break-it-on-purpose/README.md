# Lab 02 — Break it on purpose

Writeup: [uoftasic.com/ad104 → Lab 02](https://uoftasic.com/ad104/#/labs/lab-02-break-it-on-purpose-overview)

Five copies of the same inverter, each with one number changed so that it breaks one real SKY130
rule. You fix all five.

## Run it

```bash
cd labs/lab-02-break-it-on-purpose
make
```

It takes about 4 seconds (3.97 s and 4.40 s on two timed clean runs). As shipped it ends in
`FAIL` and lists all five cells as still to fix.

The fix loop for one cell:

```bash
make why C=3      # every violation in cell 3, with its rule name
make edit C=3     # open it in Magic
```

In Magic, run `drc check`, put the cursor box over a white hatched area, type `drc why`, look the
rule up in the [DRC error decoder](https://uoftasic.com/ad104/#/reference/drc-error-decoder),
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

## Files

| Path | What it is |
|---|---|
| `mag/drc_0*.mag` | the five broken cells; these are what you edit |
| `tcl/make_broken.tcl` | how they were broken, one `BREAK` comment each. The answer key. |
| `tcl/make_fixed.tcl` | the same generator with the five numbers put back |
| `tcl/verify.tcl` | DRC both ways and extract, for all five |
| `spice/inv_sch.spice` | what an inverter is supposed to be, for LVS |
| `solutions/README.md` | how to get unstuck without reading the answer |
