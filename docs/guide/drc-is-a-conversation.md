# DRC is a conversation

> **Ninety per cent of layout is messing stuff up.**
> — the team lead, and the reason this course is shaped the way it is

A design rule check is not an exam. It is the foundry telling you, in a
sentence, something specific about their equipment. Every rule has a physical
reason, every violation names the rule, and the rule name is the answer.

The skill this course is really teaching is: **read the name, understand the
constraint, change one thing, run it again.** That loop is fast — a second and
a half in Lab 02 — and it is the loop you will spend your layout career in.

## What it looks like

Magic checks continuously. Violations appear as white hatching over the
offending area and a count in the toolbar, and you ask about the one under the
box:

![A real violation, and the rule it broke](../assets/img/ad104-magic-drc-why.png)

*The toolbar says `DRC=14`. The white hatching sits around the poly contact.
Put the box over it, type `drc why`, and Magic names the rule twice — once for
the plain enclosure rule and once for the directional version of it.*

```
% drc why
poly overlap of poly contact < 0.05um (licon.8)
poly overlap of poly contact < 0.08um in one direction (licon.8a)
```

That is cell `drc_03` from [Lab 02](labs/lab-02-break-it-on-purpose-overview.md),
where the poly landing pad has been shrunk to 0.25 × 0.25 µm around a
0.17 µm cut, leaving 0.04 µm of poly on each side. The rule wants 0.05.

## The four commands

```tcl
drc check          ;# re-run the checker over the whole cell
drc catchup        ;# wait for it to finish (batch scripts need this)
drc count          ;# how many, by rule
drc why            ;# name the rules broken under the current box
```

`drc why` is the one that matters. `drc count` tells you how bad it is;
`drc why` tells you what it is.

## "In one direction" — the rule that reads wrong

You will meet this phrasing constantly:

```
Local interconnect overlap of poly contact < 0.08um in one direction (li.5)
Metal1 overlap of local interconnect contact < 0.06um in one direction (met1.5)
N-diffusion overlap of N-diffusion contact < 0.06um in one direction (licon.5c)
```

It does **not** mean "0.08 µm somewhere". It means: **pick an axis — x or y —
and on that axis the surrounding layer must extend past the contact by at least
that much on _both_ sides.**

So a contact centred in a shape that is generous vertically and tight
horizontally passes, because the y axis satisfies it. A contact tucked into a
corner fails, because neither axis has clearance on both sides.

This is why the reference inverter's li strips are 0.37 µm wide around a
0.17 µm contact — 0.10 µm of overhang left and right, and the x axis carries
the rule on its own.

It is also why the fix for one of these is almost never "make everything
bigger". It is "make it bigger *on one axis*", which is usually free.

## The shapes rules come in

Almost every SKY130 rule you will meet is one of four kinds:

| Kind | Reads like | Physically |
|---|---|---|
| **width** | `Local interconnect width < 0.17um (li.1)` | the printer cannot resolve a line thinner than this |
| **spacing** | `Metal1 spacing < 0.14um (met1.2)` | two features closer than this merge, or short |
| **enclosure / overlap** | `N-well overlap of P-Diffusion < 0.18um (diff/tap.8)` | the two masks do not align perfectly, so leave margin |
| **area** | `Local interconnect minimum area < 0.0561um^2 (li.6)` | a shape this small lifts off or does not fill |

Once you can classify a message into one of those four, you know what kind of
edit fixes it: make it fatter, move it away, make the thing *around* it
bigger, or make it bigger overall.

## The habit

The reference inverter in Lab 03 was not drawn correctly the first time. Its
first version had **62 violations across seven distinct rules** — contacts too
close to the edges of their diffusion, li exactly the size of the contacts
under it, a poly gate stripe narrower than the contact that was supposed to
land on it, taps with no overhang. The second version had zero.

Two iterations. Not because the first attempt was careless, but because
**you cannot hold thirty enclosure rules in your head and you are not supposed
to.** You draw the thing that is obviously right, the checker names the six
places you were wrong, and each name tells you the number to change.

That is why Lab 02 comes before Lab 03. You will meet five real violations on
somebody else's layout, where being wrong costs you nothing, before you meet
them on your own.

## Fix by rule, not by nudging

The single worst habit in layout is moving shapes a bit at a time until the
white dots go away. It works, it takes ten times as long, and it teaches you
nothing — and the layout it produces is usually right by accident, one edit
away from being wrong again.

`drc why` gives you a rule name and a number. Look up the number. Change the
geometry to satisfy it by a comfortable margin. Re-run.

The [DRC error decoder](reference/drc-error-decoder.md) lists every rule
this course can make you hit, with the number and the fix.
