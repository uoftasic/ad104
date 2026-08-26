# The answer key

Five cells, each the same inverter with the one mistake undone. **Do not open
these before you have tried.** The whole value of this lab is in reading a rule
name and working out what it is protecting; a diff tells you what to type and
teaches you nothing.

If you are stuck on one cell, do this before you look:

1. `make why C=3` — the rule name is the answer. Read it as a sentence.
2. Look up that rule in
   [the DRC decoder](https://uoftasic.com/ad104/#/reference/drc-error-decoder).
3. In Magic, put the cursor box over a white error dot and type `drc why`.
   Magic will name the same rule, at that spot.

When you do look, look at **one** cell, fix it yourself, and go back.

`make solutions` regenerates these from `tcl/make_fixed.tcl`, which is the same
generator as the broken ones with five numbers put back.

## The one to argue about

`drc_05` is the only cell in this lab that the default rule set calls clean.
Two independent tools noticed it anyway: the full rule set says
`nwell.4`, and netgen says the netlists do not match, because the PMOS body
comes out on a node called `w_0_600#` instead of `VPWR`.

That is worth more than the other four put together. A missing tap does not
look like a mistake, it looks like nothing.
