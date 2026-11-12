# Layout versus schematic (LVS)

DRC asks: *can this be manufactured?*

LVS asks: *is this the circuit you meant?*

The two questions are independent. A layout can be perfectly manufacturable and be a short
circuit, and a layout can be the right circuit and be impossible to build. You need both answers,
and they come from different tools.

## netgen

**netgen** compares two SPICE netlists as graphs. It ignores coordinates, port order and names;
it walks the two circuits and asks whether there is a one-to-one correspondence between their
devices and between their nets.

```bash
netgen -batch lvs \
  "results/my_inv.lvs.spice my_inv" \
  "spice/my_inv_sch.spice my_inv" \
  "$PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl" \
  results/lvs.report
```

There are four arguments: your layout netlist and the cell in it, the schematic netlist and the
cell in it, the PDK's setup file, and where to write the report.

The setup file matters more than it looks. It tells netgen that `sky130_fd_pr__nfet_01v8` has
interchangeable source and drain, which W and L to compare and with what tolerance, and which
properties to ignore. Without it, every symmetric device is a mismatch.

## A match

```
Final result: Circuits match uniquely.
```

"Uniquely" matters here. It means netgen found exactly one correspondence. A symmetric circuit
can have several, and netgen says so when it does.

## Two failures to recognise

### "Netlists match uniquely" with "failed pin matching"

This is the confusing one, and
[Lab 04](labs/lab-04-buffer-and-and-overview.md#part-6-meet-the-pin-swap-message) has you
produce it on purpose with `make swapped`:

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
- **Two names are on the wrong shapes.** Netgen had to swap `A` and `B` to make the match work.

A NAND is symmetric in its inputs, so the circuit works and *nothing else in the flow will ever
notice*. Simulation passes and DRC passes. The timing model is still wrong, because in a series
NMOS stack the input nearest the output is measurably faster than the one nearest ground.

**The fix:** swap the two labels in the layout, not in the schematic.

### Different device or net counts

```
Circuit 1 contains 4 devices, Circuit 2 contains 5 devices.
```

Something is missing. In this course it is almost always one of these:

- **A wire that does not land.** Your li or metal wire stops 0.02 µm short of the pin it was
  meant to touch. The layout then has one more net than the schematic, and one input floats.
- **A missing label.** No label, no port, nothing to compare.
- **A missing tap**, which turns the bulk terminals into invented nodes; see
  [The full DRC rule set](guide/the-rule-set-you-are-not-running.md).
- **The wrong device flavour**: `pfet_01v8` where the schematic says `pfet_01v8_hvt`. Netgen
  reports this as a device class with no partner.

**Read the report from the bottom.** The last table before `Final result:` names the device or
net that could not be matched, and that name points you at the problem.

## Where the schematic netlist comes from

In this course, from a file. Each lab ships a small `.spice` file with the circuit written out by
hand, because that is unambiguous and runs in a bare container:

```spice
.subckt my_inv A Y VPWR VGND
XM1 Y A VGND VGND sky130_fd_pr__nfet_01v8     w=0.65 l=0.15
XM2 Y A VPWR VPWR sky130_fd_pr__pfet_01v8_hvt w=1    l=0.15
.ends
```

In a real project it comes from your schematic editor. From the XSchem you used in AD103 that is
`xschem -n -s -q -x file.sch`, and there is one trap worth knowing about now so it does not cost
you an afternoon later:

> **Netlisting a schematic on its own emits its devices at the top level with no `.subckt`
> around them**, and netgen then says `Cannot find cell my_inv`. Netlist a *wrapper* schematic
> that **instantiates** your symbol instead, so the netlist has a subcircuit in it to compare.

## Why every lab runs LVS

DRC failures are loud, local and cheap to fix. LVS failures are quiet and can be anywhere.

A wire that stops 0.02 µm short looks perfect at any zoom you would normally use. It passes DRC,
because a gap does not violate any rule, and it extracts without complaint. The only tool in the
flow that notices is netgen, which counts the nets and finds one too many.

That is why every lab in this course runs LVS, including Lab 02. There the point is that
**erasing the shape that broke a DRC rule is not a fix**: the DRC count drops to zero, and LVS
immediately reports that the cell is no longer an inverter.
