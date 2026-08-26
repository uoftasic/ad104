# LVS asks a different question

DRC asks: *can this be manufactured?*

LVS asks: *is this the circuit you meant?*

They are completely independent. A layout can be perfectly manufacturable and
be a short circuit. A layout can be the right circuit and be unbuildable. You
need both answers, and they come from different tools.

## The tool

**netgen** compares two SPICE netlists as graphs. It does not care about
coordinates, port order, or what anything is called; it walks the two circuits
and asks whether there is a one-to-one correspondence between devices and
between nets.

```bash
netgen -batch lvs \
  "results/my_inv.lvs.spice my_inv" \
  "spice/my_inv_sch.spice my_inv" \
  "$PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl" \
  results/lvs.report
```

Four arguments: your layout netlist and the cell in it, the schematic netlist
and the cell in it, the PDK's setup file, and where to write the report.

The setup file matters more than it looks. It tells netgen that
`sky130_fd_pr__nfet_01v8` has interchangeable source and drain, which W and L
to compare and with what tolerance, and which properties to ignore. Without it
every symmetric device is a mismatch.

## The answer you want

```
Final result: Circuits match uniquely.
```

"Uniquely" is doing work in that sentence. It means netgen found exactly one
correspondence. A symmetric circuit can have several, and netgen will say so.

## The two failures worth recognising

### 1. "Netlists match uniquely" *and* "failed pin matching"

This is the confusing one, and it is worth meeting on purpose — `make swapped`
in Lab 04 does exactly that:

```
Netlists match uniquely.

Subcircuit pins:
Circuit 1: my_nand2         |Circuit 2: my_nand2
----------------------------|----------------------------
VPWR                        |VPWR
Y                           |Y
VGND                        |VGND
B                           |A **Mismatch**
A                           |B **Mismatch**

Final result: Top level cell failed pin matching.
```

Read it as two separate statements:

- **The topology is right.** Four devices, wired exactly as the schematic says.
- **Two names are on the wrong shapes.** Netgen had to swap `A` and `B` to make
  the match work.

A NAND is symmetric in its inputs, so the circuit is functionally fine and
*nothing else in the flow will ever notice*. Simulation passes. DRC passes.
And then the timing model is wrong, because in a series NMOS stack the input
nearest the output is measurably faster than the one nearest ground.

**Fix:** swap the two labels in the layout. Not the schematic.

### 2. Device or net counts differ

```
Circuit 1 contains 4 devices, Circuit 2 contains 5 devices.
```

Something is genuinely absent. In this course it is almost always one of:

- **a wire that does not land.** Your li or metal wire is 0.02 µm short of the
  pin it was supposed to touch. The layout side then has one more net than the
  schematic and one input floating.
- **a missing label.** No label, no port, no comparison.
- **a missing tap**, which turns the bulk terminals into invented nodes —
  see [the rule set you are not running](the-rule-set-you-are-not-running.md).
- **the wrong device flavour** — `pfet_01v8` where the schematic says
  `pfet_01v8_hvt`. Netgen reports this as a device class that has no partner.

**Read the report from the bottom.** The last table before `Final result:` names
the specific device or net that could not be matched, and that name is the
answer.

## Where the schematic netlist comes from

In this course, from a file. Each lab ships a small `.spice` with the circuit
written out by hand, because that is unambiguous and it runs in a bare
container:

```spice
.subckt my_inv A Y VPWR VGND
XM1 Y A VGND VGND sky130_fd_pr__nfet_01v8     w=0.65 l=0.15
XM2 Y A VPWR VPWR sky130_fd_pr__pfet_01v8_hvt w=1    l=0.15
.ends
```

In a real project it comes from your schematic editor. From the XSchem you
used in AD103 that is `xschem -n -s -q -x file.sch`, and there is one trap
worth knowing about now so it does not eat an afternoon later:

> **Netlisting a schematic on its own emits its devices at the top level with
> no `.subckt` around them**, and netgen then says `Cannot find cell my_inv`.
> Netlist a *wrapper* schematic that **instantiates** your symbol instead, so
> the netlist has a subcircuit in it to compare.

## Why LVS is the check that actually saves you

DRC failures are loud, local and cheap. LVS failures are quiet and global.

The wire that stops 0.02 µm short looks perfect at any zoom you would normally
use. It passes DRC — nothing about a gap violates a rule. It extracts without
complaint. The only thing in the entire flow that notices is netgen, which
counts nets and finds one too many.

That is the whole reason this course makes you run LVS in every lab, including
Lab 02, where the point is that **erasing the shape that broke a DRC rule is
not a fix** — the DRC goes to zero and LVS immediately tells you the cell is no
longer an inverter.
