# Lab 02: Break it on purpose

Writeup: [uoftasic.com/ad104-m → Lab 02](https://uoftasic.com/ad104-m/labs/lab-02-break-it-on-purpose-overview.html)

This package holds five copies of the same inverter. Each one has a single mistake in it that
breaks a real SKY130 rule, and your job is to fix all five.

## Run it

```bash
cd labs/lab-02-break-it-on-purpose
make
```

A run takes about 4 seconds (3.51 s and 3.58 s on two timed clean runs). On the cells as shipped
it ends in `FAIL` and lists all five as still to fix.

To fix a cell, open it in Magic from the `mag/` folder:

```bash
cd mag
magic -d X11 drc_03 &
```

In Magic, choose `Drc → DRC update`, then read the rule with `Drc → DRC report` (with the box on
an error; the `=` key puts it there) or `Options → DRC Manager`. Look the rule up in the
[DRC error decoder](https://uoftasic.com/ad104-m/reference/drc-error-decoder.html), change the
geometry, save with `File → Save...` and `write`, and run `make` again from the package folder.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC both ways + LVS on all five, verdict |
| `make reset` | **throw your fixes away** and rebuild the broken cells |
| `make solutions` | write the answer key into `solutions/` |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/drc_0*.mag` | the five broken cells; these are what you edit |
| `tcl/make_broken.tcl` | how they were broken, with one `BREAK` comment per cell, so this is the answer key |
| `tcl/make_fixed.tcl` | the same generator with the five numbers put back |
| `tcl/verify.tcl` | DRC both ways and extract, for all five |
| `spice/inv_sch.spice` | what an inverter is supposed to be, for LVS |
| `solutions/README.md` | how to get unstuck without reading the answer |
