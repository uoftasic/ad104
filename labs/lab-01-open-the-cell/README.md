# Lab 01: Open a cell you did not draw

Writeup: [uoftasic.com/ad104-m → Lab 01](https://uoftasic.com/ad104-m/labs/lab-01-open-the-cell-overview.html)

In this lab you open the foundry's own inverter, `sky130_fd_sc_hd__inv_1`, in Magic, measure it,
run DRC under both rule sets, extract it and run LVS against the foundry's netlist. This package
checks the same things and prints a verdict.

## Run it

Open the cell in Magic from this folder:

```bash
cd labs/lab-01-open-the-cell
magic -d X11 $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__inv_1.mag &
```

When you've done the lab's checks in Magic and netgen, run the checker:

```bash
make
```

`make` needs no environment setup. The `Makefile` sets `PDK=sky130A` itself, so it runs in a
bare container even if `.designinit` failed. It takes about a second (1.07, 0.99 and 1.00 s on
three timed clean runs) and ends in `PASS`. The full rule set reports three violations on the
foundry's cell, which is what it should report, and the writeup explains why.

## Targets

| Command | What it does |
|---|---|
| `make` | load, DRC both ways, extract, LVS, verdict |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `.magicrc` | loads SKY130 into Magic |
| `tcl/inspect.tcl` | what `make` runs: the checks you do in Magic, as batch commands |
| `src/check.py` | reads the results and prints the verdict |

There is nothing to edit in this lab. The cell is the foundry's, so what the lab checks is your
toolchain and not a layout of your own. The extraction and netgen steps in the writeup write
`sky130_fd_sc_hd__inv_1.ext`, `inv_1.spice` and `comp.out` into this folder, and the repo's
`.gitignore` keeps them out of `git status`.
