# Lab 01 — Open a cell you did not draw

Writeup: [uoftasic.com/ad104 → Lab 01](https://uoftasic.com/ad104/#/labs/lab-01-open-the-cell-overview)

Before you draw anything, get four tools to agree about somebody else's
layout.

## Run it

```bash
cd labs/lab-01-open-the-cell
make
```

No environment setup needed. The `Makefile` pins `PDK=sky130A` itself, so this
runs in a bare container even if `.designinit` failed you.

**About 1.5 seconds** (1.35, 1.46 and 1.60 s on three timed clean runs). It ends in
`PASS` and prints, among other things:

```
  ok  cell width                              1.38 um   (reference 1.38)
  ok  cell height                             2.72 um   (reference 2.72)
  ok  DRC violations, default style                 0   (reference 0)
  ok  DRC violations, full style                    3   (reference 3)
  ok  devices extracted                             2   (reference 2)
```

**Three violations is the expected answer.** The foundry's own cell fails the
full rule set, because it contains no well tap — that is deliberate, and it is
the lesson. The writeup explains it.

## Targets

| Command | What it does |
|---|---|
| `make` | load, DRC both ways, extract, LVS, verdict |
| `make gui` | open the cell in Magic |
| `make klayout` | open the whole library GDS in KLayout |
| `make netlist` | print the netlist Magic extracted from the geometry |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `.magicrc` | the two lines that load SKY130 into Magic |
| `tcl/inspect.tcl` | what `make` runs — the same commands you would type |
| `src/check.py` | reads the results and renders the verdict |

Nothing here is editable in an interesting way. That is the point: this lab is
about your toolchain, not your layout.
