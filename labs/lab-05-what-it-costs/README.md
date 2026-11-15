# Lab 05 — What it costs

Writeup: [uoftasic.com/ad104 → Lab 05](https://uoftasic.com/ad104/labs/lab-05-what-it-costs-overview.html)

This package extracts the Lab 03 inverter and the foundry's `inv_1` with every parasitic
capacitance kept, simulates both, and prints a table comparing their area, junction area,
capacitance and delay.

## Run it

```bash
cd labs/lab-05-what-it-costs
make
```

A clean run takes two to three minutes (114 s and 182 s on the two we timed), and nearly all of
that time goes into simulating the two 31-stage ring oscillators.

By default it compares the reference Lab 03 inverter, in `mag/my_inv.mag`, with the foundry's.
To compare your own cell instead, copy it in with `make mine` and then run `make`:

```bash
make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
make
```

There is a known bug here: `make mine` currently damages the file as it copies it, so the next
`make` fails with `results/my_inv.pex.spice is missing - extraction did not run.` You can
restore the reference cell with `git checkout mag/my_inv.mag`, and the writeup's Part 6
describes the problem.

## Targets

| Command | What it does |
|---|---|
| `make` | extract both cells with parasitics, simulate both, print the table |
| `make mine MAG=...` | copy your own Lab 03 cell in and compare that |
| `make pex` | just the extraction, about 4 s |
| `make caps` | both parasitic netlists, side by side |
| `make table` | re-print from results already on disk, instantly |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/my_inv.mag` | the cell being compared. `make mine` replaces it. |
| `tcl/pex.tcl` | extracts both cells with `ext2spice cthresh 0` |
| `spice/fo4.spice` | both cells driving four copies of themselves, in one deck |
| `src/mkring.py` | writes two 31-stage ring oscillators |
| `src/check.py` | reads everything and prints the comparison |
