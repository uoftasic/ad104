# Reading DRC errors

> **Ninety per cent of layout is messing stuff up.**
> — the team lead, and the reason this course is shaped the way it is

A design rule check (DRC) tells you, one sentence per problem, something specific about what the
foundry's equipment can and cannot make. Every rule has a physical reason, every violation names
its rule, and the rule name tells you what to fix.

The skill this course teaches is a loop: **read the rule name, understand the constraint, change
one thing, and run the check again.** In Lab 02 one pass of that loop takes about four seconds,
and you'll spend a lot of your layout time in it.

## What a violation looks like

Magic checks continuously. Violations appear as white hatching over the offending area, with a
count in the toolbar, and you ask about the one under the box:

![A real violation, and the rule it broke](../assets/img/ad104-magic-drc-why.png)

*The toolbar says `DRC=14`. The white hatching sits around the poly contact. With the box over
it, `drc why` names the rule twice: once for the plain enclosure rule and once for the
directional version of it.*

```
% drc why
poly overlap of poly contact < 0.05um (licon.8)
poly overlap of poly contact < 0.08um in one direction (licon.8a)
```

That is cell `drc_03` from [Lab 02](labs/lab-02-break-it-on-purpose-overview.md). Its poly
landing pad has been shrunk to 0.25 × 0.25 µm around a 0.17 µm cut, which leaves 0.04 µm of poly
on each side. The rule wants 0.05.

## The four DRC commands

```tcl
drc check          ;# re-run the checker over the whole cell
drc catchup        ;# wait for it to finish (batch scripts need this)
drc count total    ;# how many violations
drc why            ;# name the rules broken under the current box
```

`drc why` is the one you'll use most. `drc count total` tells you how many violations there are;
`drc why` tells you what they are. Use `drc count total` rather than plain `drc count`, whose last
line is a hierarchical total that reads 0 on a cell with no subcells.

## "In one direction"

You will see this phrasing often:

```
Local interconnect overlap of poly contact < 0.08um in one direction (li.5)
Metal1 overlap of local interconnect contact < 0.06um in one direction (met1.5)
N-diffusion overlap of N-diffusion contact < 0.06um in one direction (licon.5c)
```

It does **not** mean "0.08 µm somewhere". It means: **pick an axis, x or y, and on that axis the
surrounding layer must extend past the contact by at least that much on _both_ sides.**

So a contact centred in a shape that is generous vertically and tight horizontally passes,
because the y axis satisfies the rule. A contact tucked into a corner fails, because neither axis
has clearance on both sides.

That is why the reference inverter's li strips are 0.37 µm wide around a 0.17 µm contact: 0.10 µm
of overhang on the left and right, so the x axis satisfies the rule by itself.

It is also why the fix for one of these is rarely "make everything bigger". Usually it is "make
it bigger *on one axis*", which often costs no area at all.

## The four kinds of rule

Almost every SKY130 rule you'll meet is one of four kinds:

| Kind | Reads like | Physically |
|---|---|---|
| **width** | `Local interconnect width < 0.17um (li.1)` | the printer cannot resolve a line thinner than this |
| **spacing** | `Metal1 spacing < 0.14um (met1.2)` | two features closer than this merge, or short |
| **enclosure / overlap** | `N-well overlap of P-Diffusion < 0.18um (diff/tap.8)` | the two masks do not align perfectly, so leave margin |
| **area** | `Local interconnect minimum area < 0.0561um^2 (li.6)` | a shape this small lifts off or does not fill |

Once you can sort a message into one of those four, you know what kind of edit fixes it: make
the shape wider, move it away, make the shape *around* it bigger, or make it bigger overall.

## Iterating to a clean layout

The reference inverter in Lab 03 was not drawn correctly the first time. Its first version had
**62 violations across seven distinct rules**: contacts too close to the edges of their
diffusion, li exactly the size of the contacts under it, a poly gate stripe narrower than the
contact meant to land on it, and taps with no overhang. The second version had zero.

That took two iterations, and not because the first attempt was careless. **Nobody can hold
thirty enclosure rules in their head, and you are not expected to.** You draw what is obviously
right, the checker names the places you were wrong, and each name tells you which number to
change.

That is why Lab 02 comes before Lab 03. You meet five real violations on somebody else's layout,
where being wrong costs you nothing, before you meet them on your own.

## Fixing by rule

The worst habit in layout is nudging shapes a little at a time until the white hatching goes
away. It works eventually, it takes ten times as long, and it teaches you nothing. The layout it
produces is usually right by accident, one edit away from being wrong again.

Instead, take the rule name and number from `drc why`, look the number up, change the geometry
to satisfy it with a comfortable margin, and re-run.

The [DRC error decoder](reference/drc-error-decoder.md) lists every rule this course can make you
hit, with its number and the fix.
