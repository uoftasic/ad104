# Capstone — Place and route

Writeup: [uoftasic.com/ad104 → Capstone](https://uoftasic.com/ad104/#/labs/capstone-place-and-route-overview)

Four standard cells in a row. Three wires. Then a number for how fast you can
clock it.

```
   Q  = DFF(CLK, D)          sky130_fd_sc_hd__dfxtp_1
   n1 = Q  AND A             sky130_fd_sc_hd__and2_0
   n2 = n1 AND B             sky130_fd_sc_hd__and2_0
   Y  = BUF(n2)              sky130_fd_sc_hd__buf_1
```

## Run it

```bash
cd labs/capstone-place-and-route
make scaffold     # four cells placed, nothing wired
make edit
make layout       # DRC + LVS only, about 1.4 s
make              # ...and the timing, about a minute
```

## What PASS looks like

```
      outline                14.64 x 3.20 um   =  46.85 um2
      cells in the row       and2_0, buf_1, dfxtp_1, tapvpwrvgnd_1
      ports                  CLK D A B Y VGND VPWR
      DRC, default rule set  0
      DRC, full rule set     0
      LVS                    match

  HOW FAST CAN YOU CLOCK IT

      CLK rise -> Y rise        601.05 ps
      D setup at the flop       103.32 ps    (sky130_fd_sc_hd__tt_025C_1v80.lib)
      shortest legal period     704.37 ps
      f_max                    1419.71 MHz
```

## The stage everybody gets stuck on

Route everything correctly and you will see:

```
      DRC, default rule set  0
      DRC, full rule set     32
```

Thirty-two violations the default checker has no opinion about, all of them
about **well taps**. The fix is a cell, not a shape — place a
`sky130_fd_sc_hd__tapvpwrvgnd_1` at each end of the row. The checker tells you
so in words, and Lab 01 showed you why the library cells have no taps of their
own.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC both ways, LVS, then the timing |
| `make layout` | just DRC and LVS, about 1.4 s — the loop to use while routing |
| `make edit` | open your block in Magic |
| `make scaffold` | **throw your routing away**, back to four placed cells |
| `make ref` / `make refcheck` | build and check the reference block |
| `make gds` | write `results/datapath.gds` — about 25 kB |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/datapath.mag` | **your block** |
| `tcl/place.tcl` | the placement, four `getcell` calls |
| `tcl/route_ref.tcl` | the reference: every wire, every via, with the reason for each coordinate |
| `tcl/verify.tcl` | DRC both ways, extract, PEX-extract |
| `tcl/gds.tcl` | write GDSII |
| `spice/datapath_sch.spice` | the netlist you were given, for LVS |
| `src/mktiming.py` | builds the testbench around your port order, and reads the setup time out of the Liberty file |
| `solutions/README.md` | the decisions in the reference, and what to break to see why |

`spice/datapath_sch.spice` includes the library's own SPICE by absolute path
(`/foss/pdks/...`), which is `$PDK_ROOT` in the workbench image. If your
`PDK_ROOT` is somewhere else, edit that one line.
