# The DRC error decoder

Every rule this course can make you hit, what it is protecting, and what to
change. Values are from
`$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech` on the pinned workbench
image — you can `grep` any rule name in that file and read the line yourself.

**"in one direction"** means: pick an axis, x or y, and on that axis the
surrounding layer must extend past the inner one by at least that much on
**both** sides. A shape that is generous vertically and flush horizontally
passes.

## Contacts — `licon`

| Message | Value | What to do |
|---|---|---|
| `... contact width < 0.17um (licon.1)` | 0.17 | A single cut is **exactly** 0.17 × 0.17 µm. Make the painted contact region that size, or a multiple with gaps. |
| `Diffusion contact spacing < 0.17um (licon.2)` | 0.17 | Two cuts too close. Move one. |
| `N-diffusion overlap of N-diffusion contact < 0.06um in one direction (licon.5c)` | 0.06 | The plain diffusion has to extend past the contact. Widen the diffusion, or move the contact inward. |
| `N-tap overlap of N-tap contact < 0.12um in one direction (licon.7)` | 0.12 | Same, for taps, and the margin is twice as big. |
| `poly overlap of poly contact < 0.05um (licon.8)` | 0.05 | You landed a contact on a bare gate stripe. A 0.15 µm poly stripe cannot hold a 0.17 µm cut — draw a wider landing pad. |
| `poly overlap of poly contact < 0.08um in one direction (licon.8a)` | 0.08 | The directional half of the same rule. Usually fires together with `licon.8`. |
| `Diffusion contact to standard cell gate < 0.05um (licon.11)` | 0.05 | A source/drain contact too close to the poly. Move it away from the gate. |
| `poly contact spacing to diffusion < 0.19um (licon.14)` | 0.19 | The poly landing pad's contact is too near the diffusion. Move the pad out into the gap between the two diffusions. |
| `All taps must be contacted (licon.16)` | — | **Full rule set only.** A tap with no contact on it does nothing. |

## Local interconnect — `li`

| Message | Value | What to do |
|---|---|---|
| `Local interconnect width < 0.17um (li.1)` | 0.17 | A wire thinner than the process can print. Widen it. |
| `Local interconnect spacing < 0.17um (li.3)` | 0.17 | Two li shapes on different nets too close. Move one, or narrow it. |
| `Local interconnect overlap of ... contact < 0.08um in one direction (li.5)` | 0.08 | li has to overhang the contact under it. Paint the li **first**, a bit bigger, then the contact inside it. |
| `Local interconnect minimum area < 0.0561um^2 (li.6)` | 0.0561 | A patch too small to survive processing. 0.17 × 0.33 µm is the smallest legal rectangle. |

## Metal1 and its via — `met1`, `mcon`, `via`

| Message | Value | What to do |
|---|---|---|
| `mcon.width < 0.17um (mcon.1)` | 0.17 | Exactly 0.17 square, like every other cut. |
| `mcon.spacing < 0.19um (mcon.2)` | 0.19 | Two mcons too close. |
| `Metal1 width < 0.14um (met1.1)` | 0.14 | Widen the wire. |
| `Metal1 spacing < 0.14um (met1.2)` | 0.14 | **The most common routing error.** Usually a signal wire too near a supply rail. In this course's cells the legal band between the rails is y = 0.38 to 2.34 µm. |
| `Metal1 overlap of local interconnect contact < 0.03um (met1.4)` | 0.03 | The metal1 pad has to cover the mcon on every side. |
| `Metal1 overlap of local interconnect contact < 0.06um in one direction (met1.5)` | 0.06 | ...and by 0.06 on both sides of one axis. A 0.29 µm pad around a 0.17 µm cut does it. |
| `Metal1 minimum area < 0.083um^2 (met1.6)` | 0.083 | A pad that is legal by enclosure and still too small overall. 0.29 × 0.29 µm is 0.0841 — just enough. |
| `Via1 width < 0.26um (via.1a + 2 * via.4a)` | 0.26 | A drawn via1 tile is bigger than an mcon. |
| `Metal2 width < 0.14um (met2.1)` / `spacing (met2.2)` | 0.14 | Same numbers as metal1. |

## Diffusion and poly

| Message | Value | What to do |
|---|---|---|
| `Diffusion width < 0.15um (diff/tap.1)` | 0.15 | Your W is below minimum. |
| `Diffusion spacing < 0.27um (diff/tap.3)` | 0.27 | Two diffusion strips too close. This is the rule that decides how tall a cell has to be. |
| `poly width < 0.15um (poly.1a)` | 0.15 | Your L is below minimum. 0.15 µm **is** minimum L in SKY130. |
| `poly spacing < 0.21um (poly.2)` | 0.21 | Two gates too close. Sets the pitch of a series stack. |
| `poly spacing to Diffusion < 0.075um (poly.4)` | 0.075 | A poly landing pad crowding a diffusion it is not supposed to be a gate for. |
| `N-Diffusion overhang of nFET < 0.25um (poly.7)` | 0.25 | The diffusion has to extend past the gate on both sides — that is where source and drain are. |
| `poly overhang of transistor < 0.13um (poly.8)` | 0.13 | The gate stripe has to run past the edge of the diffusion, or the channel leaks round the end. |

## Wells and taps

| Message | Value | What to do |
|---|---|---|
| `N-well width < 0.84um (nwell.1)` | 0.84 | |
| `N-well spacing < 1.27um (nwell.2a)` | 1.27 | Two separate wells have to be far apart. Touching is fine — they merge. |
| `N-well overlap of P-Diffusion < 0.18um (diff/tap.8)` | 0.18 | The well has to extend past the PMOS diffusion all round. |
| `N-Diffusion spacing to N-well < 0.34um (diff/tap.9)` | 0.34 | Your NMOS is too close to the well above it. |
| `P-tap spacing to N-well < 0.13um (diff/tap.11)` | 0.13 | |
| `N-tap minimum area < 0.07011um^2 (nsd.10b)` | 0.07011 | The tap strip is too small to be worth making. |

## The four that only exist in the full rule set

These are **not checked by default**. See
[The rule set you are not running](guide/the-rule-set-you-are-not-running.md).

| Message | What to do |
|---|---|
| `All nwells must contain metal-connected N+ taps (nwell.4)` | Your n-well is floating. Add an `ntap` + `ntapc` + li + mcon to VPWR, or a `tapvpwrvgnd` cell in the row. |
| `All taps must be contacted (licon.16)` | You drew the tap diffusion and no contact on it. |
| `N-diff distance to P-tap must be < 15.0um (LU.2)` | Latch-up. Somewhere within 15 µm of every NMOS there has to be a substrate tap. |
| `P-diff distance to N-tap must be < 15.0um (LU.3)` | Latch-up, the other polarity. |

The foundry's own standard cells fail three of these when checked alone, on
purpose — the taps come from a separate cell in the row.

## How to look a rule up yourself

```bash
grep -n 'met1.5' $PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech
```

The numbers in that file are in nanometres, so `140` is 0.14 µm. The authority
above it is SkyWater's published rule deck; Magic's tech file is one
implementation of it and is occasionally more conservative.
