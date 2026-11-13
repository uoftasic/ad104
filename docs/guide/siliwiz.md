# SiliWiz

**<https://app.siliwiz.com/>** needs no account and no install; it runs in a browser tab.

SiliWiz lets you paint layout layers and then shows you the **cross-section** of the silicon you
described, and simulates it. It is not the SKY130 process and it is not a production tool. It is
the quickest way to turn "poly over diffusion makes a transistor" from a sentence you have read
into something you have seen. You can spend twenty minutes in it in the optional last part of Lab 01,
[Part 7](labs/lab-01-open-the-cell-overview.md#part-7-explore-siliwiz-optional).

![SiliWiz with the inverter preset loaded](../assets/img/ad104-siliwiz.png)

*The layer palette down the left, the layout you are painting in the middle, and on the right
either the cross-section or, as here, a simulation of what you drew. The black horizontal line
across the layout is the cross-section cut; drag the blue slider beside it and the picture on the
right changes.*

## The interface

- **LESSONS**, top right, links to short written walkthroughs at
  <https://tinytapeout.com/siliwiz/>: *introduction*, *resistors*, *capacitors*, *nmos*, *pmos*,
  *inverter*, *cmosinverter*, *divider* and *parasitics*.
- The **Preset** dropdown above the drawing area loads a finished example.
- The right-hand panel has two tabs: **CROSS SECTION & DRC** and **SIMULATION**.
- The **vertical blue slider** to the right of the layout moves the cross-section cut line. It is
  the control that matters most; the rest of the interface supports it.

## Where SiliWiz differs from a real process

It is a teaching model, and it helps to know where it is simplified:

- **The process is invented.** The layer names line up with SKY130's (`n well`, `p diffusion`,
  `polysilicon`, `metal1`, `metal2`, `p tap`, `n tap`), but the dimensions, the rules and the
  device models do not. Do not carry a number from SiliWiz into Magic.
- **It has no LVS.** Nothing checks that what you drew is what you meant, and that turns out to
  be the harder half; see [Layout versus schematic (LVS)](guide/lvs-asks-a-different-question.md).
- **The cross-section is schematic.** Real doping profiles are gradients, not the flat-topped
  blocks in the picture.

None of that matters for what you use it for. SiliWiz is the only tool in this course that shows
you the inside of the wafer, which Magic never does.

## Why it is in this course

SiliWiz comes from the TinyTapeout project. The team has put the TinyTapeout **shuttle** out of
scope for these courses (no submissions, no tiles, no deadlines), but that decision was about the
shuttle, not about their teaching material, and this tool is good. Nothing in AD104 depends on
it, so skipping it costs you only intuition.
