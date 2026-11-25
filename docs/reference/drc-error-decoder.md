# DRC error decoder

This page lists every DRC rule you can run into in this course, with what each one protects and
what to change in your layout when Magic reports it. The values come from
`$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech` on the pinned workbench image, so you can `grep`
for any rule name in that file and read the line yourself.

Several messages include the words **"in one direction"**. That means you pick an axis, x or y, and on
that axis the surrounding layer has to extend past the inner one by at least the given amount on
**both** sides. The other axis doesn't matter, so a shape that is generous vertically and flush
horizontally still passes.

## Contacts (`licon`)

| Message | Value | What to do |
|---|---|---|
| `... contact width < 0.17um (licon.1)` | 0.17 | A single cut is **exactly** 0.17 × 0.17 µm, so make the painted contact region that size, or a multiple of it with gaps between the cuts. |
| `Diffusion contact spacing < 0.17um (licon.2)` | 0.17 | Two cuts are too close together. Move one of them. |
| `N-diffusion overlap of N-diffusion contact < 0.06um in one direction (licon.5c)` | 0.06 | The plain diffusion has to extend past the contact. Widen the diffusion, or move the contact inward. |
| `N-tap overlap of N-tap contact < 0.12um in one direction (licon.7)` | 0.12 | This is the same rule for taps, and the margin is twice as big. |
| `poly overlap of poly contact < 0.05um (licon.8)` | 0.05 | You've landed a contact on a bare gate stripe. A 0.15 µm poly stripe is too narrow to hold a 0.17 µm cut, so draw a wider landing pad for the contact. |
| `poly overlap of poly contact < 0.08um in one direction (licon.8a)` | 0.08 | This is the directional half of the same rule, and it usually fires together with `licon.8`. |
| `Diffusion contact to standard cell gate < 0.05um (licon.11)` | 0.05 | A source or drain contact is too close to the poly. Move it away from the gate. |
| `poly contact spacing to diffusion < 0.19um (licon.14)` | 0.19 | The contact on the poly landing pad is too near the diffusion. Move the pad out into the gap between the two diffusions. |
| `All taps must be contacted (licon.16)` | — | **Full rule set only**, and on the pinned image it never fires (see [Full rule set only](#full-rule-set-only) below). A tap with no contact on it isn't connected to anything, so it does nothing. |

## Local interconnect (`li`)

| Message | Value | What to do |
|---|---|---|
| `Local interconnect width < 0.17um (li.1)` | 0.17 | The wire is thinner than the process can print. Widen it. |
| `Local interconnect spacing < 0.17um (li.3)` | 0.17 | Two li shapes on different nets are too close together. Move one of them, or make it narrower. |
| `Local interconnect overlap of ... contact < 0.08um in one direction (li.5)` | 0.08 | The li has to overhang the contact under it. Paint the li **first**, a bit bigger than you need, and then paint the contact inside it. |
| `Local interconnect minimum area < 0.0561um^2 (li.6)` | 0.0561 | The patch is too small to survive processing. The smallest legal rectangle is 0.17 × 0.33 µm. |

## Metal1 and its via (`met1`, `mcon`, `via`)

| Message | Value | What to do |
|---|---|---|
| `mcon.width < 0.17um (mcon.1)` | 0.17 | An mcon is exactly 0.17 µm square, like every other cut. |
| `mcon.spacing < 0.19um (mcon.2)` | 0.19 | Two mcons are too close together. |
| `Metal1 width < 0.14um (met1.1)` | 0.14 | Widen the wire. |
| `Metal1 spacing < 0.14um (met1.2)` | 0.14 | **This is the most common routing error.** It's usually a signal wire too near a supply rail. In the capstone's row of foundry cells the legal band between the rails runs from y = 0.38 to 2.34 µm. |
| `Metal1 overlap of local interconnect contact < 0.03um (met1.4)` | 0.03 | The metal1 pad has to cover the mcon on every side. |
| `Metal1 overlap of local interconnect contact < 0.06um in one direction (met1.5)` | 0.06 | On top of `met1.4`, the pad has to extend 0.06 µm past the mcon on both sides of one axis. A 0.29 µm pad around a 0.17 µm cut does it. |
| `Metal1 minimum area < 0.083um^2 (met1.6)` | 0.083 | The pad meets the enclosure rules but is still too small overall. A 0.29 × 0.29 µm pad is 0.0841 µm², which is just enough. |
| `Via1 width < 0.26um (via.1a + 2 * via.4a)` | 0.26 | A drawn via1 tile has to be at least 0.26 µm wide, which makes it bigger than an mcon. |
| `Metal2 width < 0.14um (met2.1)` / `spacing (met2.2)` | 0.14 | Metal2 has the same width and spacing as metal1. |

## Diffusion and poly

| Message | Value | What to do |
|---|---|---|
| `Diffusion width < 0.15um (diff/tap.1)` | 0.15 | Your W is below the minimum. |
| `Diffusion spacing < 0.27um (diff/tap.3)` | 0.27 | Two diffusion strips are too close together. This is the rule that decides how tall a cell has to be. |
| `poly width < 0.15um (poly.1a)` | 0.15 | Your L is below the minimum, which in SKY130 is 0.15 µm. |
| `poly spacing < 0.21um (poly.2)` | 0.21 | Two gates are too close together. This rule sets the pitch of a series stack. |
| `poly spacing to Diffusion < 0.075um (poly.4)` | 0.075 | A poly landing pad is crowding a diffusion that it isn't meant to be a gate for. |
| `N-Diffusion overhang of nFET < 0.25um (poly.7)` | 0.25 | The diffusion has to extend past the gate on both sides, because that is where the source and drain are. |
| `poly overhang of transistor < 0.13um (poly.8)` | 0.13 | The gate stripe has to run past the edge of the diffusion, or the channel leaks round the end of the gate. |

## Wells and taps

| Message | Value | What to do |
|---|---|---|
| `N-well width < 0.84um (nwell.1)` | 0.84 | |
| `N-well spacing < 1.27um (nwell.2a)` | 1.27 | Two separate wells have to be far apart. Wells that touch are fine, because they merge into one. |
| `N-well overlap of P-Diffusion < 0.18um (diff/tap.8)` | 0.18 | The well has to extend past the PMOS diffusion all the way round. |
| `N-Diffusion spacing to N-well < 0.34um (diff/tap.9)` | 0.34 | Your NMOS is too close to the well above it. |
| `P-tap spacing to N-well < 0.13um (diff/tap.11)` | 0.13 | |
| `N-tap minimum area < 0.07011um^2 (nsd.10b)` | 0.07011 | The tap strip is too small to be worth making. |

## Full rule set only

The default DRC run doesn't check these four rules.
[The full DRC rule set](../guide/the-rule-set-you-are-not-running.md) explains why they matter
and how to run them.

| Message | What to do |
|---|---|
| `All nwells must contain metal-connected N+ taps (nwell.4)` | Your n-well is floating. Connect it to VPWR with an `ntap` + `ntapc` + li + mcon, or put a `tapvpwrvgnd` cell in the row. |
| `All taps must be contacted (licon.16)` | This rule is meant for a tap diffusion with no contact on it, but on the pinned image it never fires, even on exactly that mistake. Lab 02's `drc_05` has an n-tap with no contact, and the full rule set reports `nwell.4` and `LU.3` for it instead. If you see those two, check that every tap has its contact. |
| `N-diff distance to P-tap must be < 15.0um (LU.2)` | This rule guards against latch-up. Every NMOS needs a substrate tap somewhere within 15 µm of it. |
| `P-diff distance to N-tap must be < 15.0um (LU.3)` | This is the same latch-up rule for the other polarity. |

The foundry's own standard cells fail three of these rules when you check a single cell on its own.
That's on purpose, because in a real row the taps come from a separate cell.

## Looking up a rule yourself

In Magic, put the box on a white-hatched error (the `=` key does that, with the pointer over the
drawing) and choose `Drc → DRC report`: the console prints the message for every rule broken
inside the box, and you can find it in the tables above. `Options → DRC Manager` lists every rule
the cell breaks, one row per rule, with the errors under each. The
[Magic cheat sheet](magic-cheatsheet.md#the-drc-menu) has both.

To read a rule's value in the technology file, `grep` for its name:

```bash
grep -n 'met1.5' $PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech
```

The numbers in that file are in nanometres, so `140` means 0.14 µm. The final authority
is SkyWater's published rule deck. Magic's tech file is one implementation of that deck, and
occasionally it's more conservative than the deck itself.
