# The full DRC rule set

Magic's SKY130 technology file defines the design rules in **variants**:

```
style drc variants (fast),(full),(routing)
```

The first one listed is the default, so unless you say otherwise you are running **`fast`**, and
`fast` leaves out a whole category of rules.

## What `full` adds

Four rules matter to you, and none of them are in the default set:

```
variants (full)
 cifmaxwidth nwell_missing_tap 0 bend_illegal
        "All nwells must contain metal-connected N+ taps (nwell.4)"
 cifmaxwidth tap_missing_licon 0 bend_illegal
        "All taps must be contacted (licon.16)"
 cifmaxwidth ptap_missing 0 bend_illegal
        "N-diff distance to P-tap must be < 15.0um (LU.2)"
 cifmaxwidth ntap_missing 0 bend_illegal
        "P-diff distance to N-tap must be < 15.0um (LU.3)"
```

Every one of them is about **well taps**, the connections that hold the body of your transistors
at a known voltage. They are left out of the default set because they are expensive to compute,
and because on a cell by itself they usually mean nothing: the foundry's own inverter fails three
of them (see [Anatomy of a standard cell](guide/anatomy-of-a-standard-cell.md)).

## Why a missing tap is dangerous

A missing tap does not look like a mistake. It looks like nothing at all:

- The layout is visually complete.
- `drc check` says **0**.
- The cell extracts.
- It might even simulate, depending on what the floating body does.

Here is the block you build in the capstone, a row of four standard cells called `datapath`,
checked both ways before its tap cells go in:

```
      DRC, default rule set  0
      DRC, full rule set     32
```

That is thirty-two violations that the default check does not report. On real silicon, missing
taps cause **latch-up**. Every CMOS process contains parasitic bipolar transistors between the
well, the substrate and your diffusions. If nothing holds the well and substrate firmly at their
supplies, a transient can turn those transistors on into a self-sustaining short from supply to
ground. The chip stops working until you cut the power, and sometimes after that too.

## The rule of thumb

> **Before you believe a DRC count of zero, run it again with `drc style drc(full)`.**

Every lab in this course runs both rule sets and prints both counts side by side, so you never
have to remember. When you work in Magic by hand, the sequence is:

```tcl
drc style drc(full)
drc check
drc catchup
drc count total
```

`drc style drc(fast)` switches back.

## The same fault in the netlist

**Two independent tools notice a missing tap**, and neither of them uses the word "tap".

Extract a block with no taps and look at the netlist:

```spice
.subckt datapath CLK D A B Y VGND VPWR
Xbuf0 buf0/A dff0/VGND VSUBS dff0/VPB dff0/VPWR Y sky130_fd_sc_hd__buf_1
```

The bulk terminals came out as **`VSUBS`** and **`dff0/VPB`**. These are invented node names,
because nothing connects those wells to a supply. Netgen then reports a mismatch, because the
schematic you compare against has them on VGND and VPWR.

Put the taps in, and the same line becomes:

```spice
Xbuf0 buf0/A VGND VGND VPWR VPWR Y sky130_fd_sc_hd__buf_1
```

That is two symptoms of one cause, and neither is a DRC error in the rule set you were running.
Lab 02's fifth cell has this fault at the scale of a single inverter, so you meet it first where
it is small.

## Checkers in general

The lesson is about checkers more than taps:

> **A checker that passes has told you that the rules it ran did not fire. It has not told you the
> design is right.**

The digital track meets the same problem from a different direction. In
[DD103](https://uoftasic.com/dd103/) an entire chip hardens successfully in the *wrong PDK*,
behind three green ticks and a real `.gds`, because nothing in the flow checks that you meant
that PDK. The habit that protects you is the same in both tracks: know which checks you are
running, and ask what they are not looking at.
