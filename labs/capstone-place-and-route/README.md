# Capstone: Place and route

Writeup: [uoftasic.com/ad104 → Capstone](https://uoftasic.com/ad104/labs/capstone-place-and-route-overview.html).
The writeup has the steps, the expected output and the explanations; this file is a quick
reference.

You place four standard cells in a row, route the three wires between them by hand, and then run
a timing simulation of the extracted layout. The four cells make this circuit:

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
make              # ...and the timing, about 15 s
```

`spice/datapath_sch.spice` includes the cell library's own SPICE by absolute path
(`/foss/pdks/...`), because that is where `$PDK_ROOT` points in the workbench image. If your
`PDK_ROOT` is somewhere else, edit that one line.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC both ways, LVS, then the timing |
| `make layout` | just DRC and LVS, about 1.4 s; the loop to use while routing |
| `make edit` | open your block in Magic |
| `make scaffold` | **throw your routing away**, back to four placed cells |
| `make ref` / `make refcheck` | build and check the reference block |
| `make gds` | write `results/datapath.gds`, about 25 kB |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/datapath.mag` | **your block** |
| `tcl/place.tcl` | the placement, four `getcell` calls |
| `tcl/route_ref.tcl` | the reference: every wire and every via, with the reason for each coordinate |
| `tcl/verify.tcl` | DRC both ways, extract, PEX-extract |
| `tcl/gds.tcl` | write GDSII |
| `spice/datapath_sch.spice` | the netlist you were given, for LVS |
| `src/mktiming.py` | builds the testbench around your port order, and reads the setup time out of the Liberty file |
| `solutions/README.md` | the decisions in the reference, and what to break to see why |
