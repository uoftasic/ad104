# The rule set you are not running

Magic's SKY130 technology file defines the design rules in **variants**:

```
style drc variants (fast),(full),(routing)
```

The first one listed is the default, so unless you say otherwise you are
running **`fast`**. And `fast` leaves out a category of rules.

## What `full` adds

Three rules that matter to you, all of which are invisible in the default set:

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

Every one of them is about **well taps** — the connections that hold the body
of your transistors at a known voltage. They are excluded from the default set
because they are expensive to compute, and because on a cell in isolation they
are usually meaningless (see
[Anatomy of a standard cell](anatomy-of-a-standard-cell.md): the foundry's own
inverter fails all three).

## Why that is dangerous rather than merely inconvenient

A missing tap does not look like a mistake. It looks like nothing.

- The layout is visually complete.
- `drc check` says **0**.
- The cell extracts.
- It might even simulate, depending on what the floating body does.

Here is the capstone block before the tap cells go in, checked both ways:

```
      DRC, default rule set  0
      DRC, full rule set     32
```

Thirty-two violations, none of which the default check has an opinion about.
And what the missing taps actually cause on real silicon is **latch-up**: every
CMOS process contains parasitic bipolar transistors between the well, the
substrate and your diffusions, and if nothing holds the well and substrate
firmly, a transient can turn them on into a self-sustaining short from supply
to ground. The chip stops working until you cut the power, and sometimes after.

## The one-line rule

> **Before you believe a DRC count of zero, run it again with
> `drc style drc(full)`.**

Every lab in this course runs both and prints both, side by side, so you never
have to remember. When you are working in Magic by hand:

```tcl
drc style drc(full)
drc check
drc catchup
drc count
```

Switching back is `drc style drc(fast)`.

## A second opinion, from a different tool

The nice thing about the tap fault is that **two independent tools notice it**,
and neither of them says the word "tap".

Extract a block with no taps and look at the netlist:

```spice
.subckt datapath CLK D A B Y VGND VPWR
Xbuf0 buf0/A dff0/VGND VSUBS dff0/VPB dff0/VPWR Y sky130_fd_sc_hd__buf_1
```

The bulk terminals came out as **`VSUBS`** and **`dff0/VPB`** — invented node
names, because nothing connects those wells to a supply. Netgen then reports a
mismatch, because the schematic you are comparing against has them on VGND and
VPWR.

Put the taps in, and the same line becomes:

```spice
Xbuf0 buf0/A VGND VGND VPWR VPWR Y sky130_fd_sc_hd__buf_1
```

Two symptoms, one cause, and neither of them is a DRC error in the rule set
you were running. Lab 02's fifth cell is this fault at the scale of a single
inverter, so you meet it once where it is small.

## The general form

This is not really a lesson about taps. It is a lesson about checkers.

> **A checker that passes has told you that the rules it ran did not fire.
> It has not told you the design is right.**

The digital track hits the same shape of problem from a different direction:
in [DD103](https://uoftasic.com/dd103/) an entire chip hardens successfully in
the *wrong PDK*, behind three green ticks and a real `.gds`, because nothing in
the flow checks that you meant that PDK. Same failure, different tool. The
habit that saves you is the same one: know which checks you are running, and
ask what they are not looking at.
