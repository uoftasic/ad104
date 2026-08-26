# Lab 05 — What it costs

Writeup: [uoftasic.com/ad104 → Lab 05](https://uoftasic.com/ad104/#/labs/lab-05-what-it-costs-overview)

The same two transistors, drawn twice, priced.

## Run it

```bash
cd labs/lab-05-what-it-costs
make
```

**Two to three minutes** — 114 s and 182 s on two timed clean runs. Nearly all
of it is the two 31-stage ring oscillators.

By default it compares the **reference** Lab 03 inverter with the foundry's.
To use your own:

```bash
make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
make
```

## What it prints

```
                                       yours       foundry           ratio
  ------------------------------------------------------------------------
  cell area                               18         3.754 um2      4.80 x
     W (both devices)                                               1.00 x
     L (both devices)                                               1.00 x
     drain junction area                                            4.23 x

  DELAY, fan-out of 4
  average                              67.82         61.19 ps       1.11 x

  RING OSCILLATOR, 31 stages
  one stage                            43.88         34.48 ps       1.27 x
```

The `1.00 x` rows are the control: the transistors are identical down to the
model name, so everything else on the table is the drawing.

**11 % slower at fan-out 4, 27 % slower in a ring.** The disagreement is the
lesson, and the writeup explains it.

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
| `spice/fo4.spice` | both cells driving four copies of themselves, one deck |
| `src/mkring.py` | writes two 31-stage ring oscillators |
| `src/check.py` | reads everything and prints the comparison |

There is no wrong answer in this lab. It is a measurement, and if you ran
`make mine` it is a measurement of your cell.
