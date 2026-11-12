# The answer key

Five cells, each the same inverter with its one mistake undone. **Don't open these before you
have tried.** The value of this lab is in reading a rule name and working out what it protects; a
diff tells you what to type and teaches you nothing.

If you are stuck on one cell, do this before you look:

1. Run `make why C=3`. The rule name is the answer; read it as a sentence.
2. Look up that rule in
   [the DRC decoder](https://uoftasic.com/ad104/#/reference/drc-error-decoder).
3. In Magic, run `drc check`, put the cursor box over a white hatched area and type `drc why`.
   Magic names the same rule at that spot.

When you do look, look at **one** cell, fix it yourself, and go back.

`make solutions` regenerates these files from `tcl/make_fixed.tcl`, which is the same generator
as the broken cells with the five numbers put back.

## drc_05

`drc_05` is the only cell in this lab that the default rule set calls clean. Two independent
tools noticed the problem anyway: the full rule set reports `nwell.4`, and netgen says the
netlists do not match, because the PMOS body comes out on a node called `w_0_600#` instead of
`VPWR`.

It teaches more than the other four put together. A missing tap does not look like a mistake; it
looks like nothing.
