# Agent guide — UofT ASIC course repos

You are working in a **course repository** for the UofT ASIC Team (`uoftasic`): pedagogical materials for IC / RTL / FPGA / open-source ASIC flows. The site under `docs/` is built with Quarto and published on GitHub Pages by `.github/workflows/site.yml`. Runnable work lives outside `docs/`.

Optimize for **clear student learning paths**, not template maintenance. Prefer concrete labs and notes students can follow end-to-end over meta documentation.

## Goals

- Teach IC development skills: RTL (SystemVerilog/Verilog), simulation, synthesis, FPGA bring-up, and/or open ASIC flows (e.g. Yosys, LibreLane, SKY130) as the course requires.
- Keep each lab **self-contained**, in the [lab writeup shape](#lab-writeup-shape) below.
- Keep guide pages (`docs/guide/`) **reading only**: concepts, figures, worked examples. Commands and activities belong in the lab writeups; a guide page points to the lab part where the student does it.
- Keep the **Course path** table on `docs/index.md` (alternating Read and Do rows, in the [Course path format](#course-path-format) below), the sidebar in `docs/_quarto.yml` and the chapter list in `docs/_quarto-pdf.yml` in the same order.
- Separate **what students read** (`docs/`) from **what they run** (`labs/`, `scripts/`, `notebooks/`).
- Never publish grades, solution keys, or PII under `docs/`. Put keys in `labs/**/solutions/` and gitignore them on student forks when policy requires.

## Layout (do not fight this)

| Path | Published? | Put here |
|------|------------|----------|
| `docs/` | Yes | Guides, lab writeups, figures for the site |
| `docs/guide/` | Yes | Conceptual notes (flows, tools, theory) |
| `docs/labs/` | Yes | Lab writeups only (`lab-NN-*-overview.md`) |
| `docs/assets/img/` | Yes | Small diagrams / waveforms for docs |
| `labs/<lab-id>/` | No | HDL, Python, testbenches, local data, graders |
| `scripts/` | No | Course utilities / automation |
| `notebooks/` | No | Exploratory or assignment notebooks |
| `data/`, `figures/` | No | Shared datasets / source figures |

Site wiring: `docs/_quarto.yml` (site, sidebar, navbar, per-page PDFs), `docs/_quarto-pdf.yml` (the whole course as one PDF) and `docs/_filters/course.lua` (turns `<details>` answers into collapsible callouts, and in PDFs moves them to an Answers section at the end of each page). The home page is `docs/index.md`. Math: `$inline$`, `$$display$$`.

## Lab writeup shape

Every `docs/labs/*-overview.md` follows this order:

1. What you'll build or measure, in two or three lines, and a link to the package.
2. **Before you start**: the guide pages to read first, and any setup.
3. **Time**: an estimate that leaves out optional parts, or gives their time separately.
4. Numbered parts. Each part opens with the one question it answers, has numbered steps (split or trim a part that runs past about eight), and ends in a "You should see" check with the numbers or output the student should get.
   - At least one required part has the student produce something: edit a file or a layout, draw a cell, or work out a number and write it down before a later step checks it.
   - Where the student can reasonably predict a result, have them write the prediction down before they run the command.
   - When a check would also explain *why*, ask the why as a question at that step and put the answer in a collapsed block directly under it. Keep the blank lines:

     ```html
     <details>
     <summary>Answer</summary>

     The answer, with Markdown and $math$ as usual.

     </details>
     ```

   - Optional parts go after the required ones, with "(optional)" in the header. No required part may depend on one.
5. **Finishing**, with three things in this order:
   - "You're done when": one checkable line about the student's own work, not about the shipped package passing.
   - "Questions", if any: ones the student answers from their own work, each with a collapsed answer or a pointer to the step that answers it.
   - "Submit": what to submit, or "nothing for this lab".
6. **Going further (optional)**, if there is any.
7. A last line: "Next on the Course path: read …, then do …".

The page title is `# Lab NN: Title` (`# Capstone: Title` for the capstone), and the sidebar entry uses the same words.

Lab 01's Part 1 is "Load the course". It links [IC101 Lab 03](https://uoftasic.com/ic101/labs/lab-03-launch-the-workbench-overview.html) for the workbench itself, then loads `.designinit`, runs `mod add`, and checks the tool versions the course's printed outputs depend on. Its troubleshooting lists only the rows IC101 does not cover, and links IC101's [Troubleshooting](https://uoftasic.com/ic101/reference/troubleshooting.html) page for the rest.

## GUI-first labs

AD104's labs teach Magic the way layout engineers use it: with the mouse, keys, menus and dialogs. The student draws, checks and fixes in the tool; `make` only grades the work and resets the starting files. Check every lab step against these rules.

- **No finished geometry.** No step gives a rectangle's coordinates, a `box` position, a script, or a list of commands to paste. Absolute positions belong in `tcl/` and `solutions/` only.
- **Targets, not coordinates.** A drawing step says what the shape must achieve: its size where the size is the lesson (W = 0.65 µm, L = 0.15 µm, a 0.17 × 0.17 µm contact), the rule values it must meet (`li.5`, an overhang ≥ 0.08 µm on both sides of one axis), and where it sits relative to shapes already on screen. The student picks the coordinates.
- **Name the tool action.** Every step that changes, checks or saves the layout names the menu path with its exact label (`Drc → DRC update`), the key (`z`), the mouse action (a middle click on a palette swatch) or the dialog and its fields.
- **Show it once.** The first time the course uses an action, its step has a screenshot: the menu open, the dialog filled in, or the result on screen. Later uses get none.
- **Type only what engineers type.** The student types these, each as a numbered step that says what it does, and nothing else:
  - `magic -d X11 <cell> &`, from the cell's folder;
  - in tkcon, the operations Magic has no menu for: `extract all`, `ext2spice lvs`, `ext2spice`, `ext2spice -o FILE`, `ext2spice cthresh 0`; `box size W H` (a size, never a position, typed after clicking the lower-left corner); and in the capstone, `select top cell` and `port makeall`, once;
  - netgen's `lvs` in a terminal;
  - `cat`, `grep`, `head`, `ls`, `diff` or a text editor, to read files;
  - the `make` targets below.

  The first page that uses an extraction or netgen command shows it in full and explains each argument; later labs name the command and the arguments the student supplies. Console forms that have a GUI path (`drc why`, `drc check`, `drc style`, `paint`, `erase`, `label`, `save`, `load`, `getcell`, `box` with coordinates) appear only on the reference page.
- **`make` checks and starts over.** Every check that extracts deletes `mag/*.ext` first: a student's own extraction leaves `.ext` files beside the cells in `mag/`, and `ext2spice` reads those before the fresh ones the check writes in `results/`, so the check would grade the layout as it was at the last extraction. Pages use `make`, `make layout`, `make gen`, `make scaffold`, `make reset`, `make cells`, `make mine`, `make table` and `make clean`, and mention `make ref`, `make refcheck` and `make solutions` only under Going further. No page uses `make gui`, `make edit`, `make why`, `make netlist`, `make klayout`, `make swapped`, `make pex`, `make caps`, `make sim` or `make gds`. The student does that work in the tool, or types the command.
- **A full loop in the tool.** In each lab the student changes the layout, runs DRC in Magic, fixes what it reports, extracts, runs LVS and reads the result, and only then runs `make`. Labs 01 and 05 have no drawing step.
- **"You should see" can't depend on the student's coordinates.** Give counts only for fixed cells: Lab 01's foundry cell, Lab 02's cells before any fix, the capstone's bare placement and Lab 05's reference cell. Elsewhere give verdict lines, device lines, port lists and rule names.
- **Save before every check.** Magic's caption doesn't show unsaved changes. Put a save step just before each `make`: `File → Save...`, then `write` in the dialog. Magic opens one dialog for each cell it counts as changed, so say which button each one gets: `autowrite` where every changed cell is the student's (Lab 04, where `Drc → DRC update` marks a block's subcells as changed and the device generator makes new cells), and `skip` for the foundry's cells, which are read-only in the PDK, with `write` for the student's block (the capstone). Never `Cell → Save as...` for a file `make` checks.
- **Keep the goals, numbers, checkers and solutions.** The widths and lengths (W = 0.65 and 1.00 µm, L = 0.15 µm), the rule names and values, the reference cells, `solutions/` and the PASS/FAIL logic of each `src/check.py` stay. `labs/lab-03-draw-an-inverter/solutions/inv_ref.mag`, `tcl/inverter.tcl` and `spice/my_inv_sch.spice` are frozen: IC102-A vendors `inv_ref.mag` (at commit `b89a8b8`) and copies `my_inv_sch.spice`.
- **Every output on a page comes from a run.** Counts, messages and screenshots come from doing the step in the workbench image, never from memory or a design note.

Magic habits every lab shares:

- Keys act only while the pointer is over the drawing. The first lab that uses a key says so.
- Two recipes for an exact small shape, which later labs refer to by name:
  - **Click recipe** (Lab 01 Part 3 for measuring, Lab 02 Part 3 for drawing): keep the default snap (never `Snap-to-grid off`), box the area roughly and press `ctrl+z`, left-click the lower-left corner, right-click the upper-right, then read the size in the title bar, or press `b` and read the `microns:` line in tkcon.
  - **Typed size** (contacts and vias from Lab 02 Part 6 on): zoom in, left-click the lower-left corner, click in tkcon and type `box size 0.17um 0.17um`, click the layout window's title bar, and press `b` over the drawing to check. The desktop is click-to-focus, so without the title-bar click the `b` goes into tkcon; a click in the drawing would move the box.
- The foundry's cells are drawn on a 0.005 µm grid and clicks snap to 0.01 µm, so a box clicked onto a foundry cell's edge can land 0.005 µm inside or outside it (Lab 01 Part 4). Measure a foundry cell by edges that sit on the 0.01 µm grid, such as `inv_1`'s rails, or quote the layout file.
- After `File → Open...`, the box still belongs to the cell that was open before, and `Drc → DRC update` answers `The box is not in the same coordinate system as the window.` until the student left-clicks in the new cell's drawing. Lab 02 Part 4 teaches `v` and a left click; a later step that opens a cell this way has the student click or set the box before checking.
- The workbench desktop is 1280 × 800 by default. There the device dialog (opened from `Devices 1`, and its `Edit device:` form) opens with its buttons below the screen. Lab 04 Part 7, the first page that opens it, tells the student to double-click the window's title bar, which fills the screen and brings the buttons up. Getting-started repeats this in its problems table and mentions `VNC_RESOLUTION=1680x1050 ./scripts/start_vnc.sh` for a larger desktop.
- Lab 01's troubleshooting table has `PDK=sky130A magic -d X11 <cell> &` for a student whose `.designinit` failed. Other labs don't repeat it.

Screenshots are PNG crops named `docs/assets/img/ad104-<lab>-<nn>-<slug>.png` (`<lab>` is `l01` to `l05` or `cap`; guide images are `ad104-g-<slug>.png`), each with alt text and a caption that says what to look at. Each one comes from a committed step file in `scripts/screenshots/magic/steps/` or `scripts/screenshots/klayout/steps/`, run with the rigs described in `scripts/README.md`. Lab times on the pages and in the Course path are estimates, and the pages say so.

## Course path format

```
| # | | What | Time |
|---|---|---|---|
| 1 | Read | [Page](guide/page.md) · [Page](guide/page.md) | 45 min |
| 2 | Do | [Lab 01: Title](labs/lab-01-...-overview.md). One sentence on what you'll do. | 1.5 h |
```

- Read and Do are plain text. Lab titles use a colon and match the lab page's title and its sidebar entry.
- Every Do row ends with one sentence on what you'll do.
- The row times add up to the course total on the home page. Optional parts are not counted.

## Adding a lab (preferred unit of coursework)

Lab IDs: `lab-NN-short-name` (e.g. `lab-02-counter-sv`).

1. Create `labs/<lab-id>/` with at least:
   - `README.md` — points at the writeup on the site and how to run
   - `src/` — HDL / Python / entrypoints
   - `data/` — small inputs (large binaries → Git LFS or external)
   - `requirements.txt` or tool notes when needed
2. Add `docs/labs/<lab-id>-overview.md` in the [lab writeup shape](#lab-writeup-shape).
3. Add a Do row for it to the Course path table in `docs/index.md` in the [Course path format](#course-path-format), update the course total, and add the writeup to the sidebar in `docs/_quarto.yml` and the chapters in `docs/_quarto-pdf.yml` in the same position (and to the navbar in `_quarto.yml` only if it belongs in top nav).
4. Cross-link: writeup → GitHub `labs/<lab-id>/`; package README → `docs/labs/<lab-id>-overview.md`.

Writeups explain and packages run, so don't paste long HDL into site pages; reference the files under `labs/` instead.

## Adding a guide page

1. Add kebab-case Markdown under `docs/guide/` (e.g. `yosys-synth.md`). Reading only: no required commands.
2. Add it to the right Read row of the Course path in `docs/index.md`, and add it to the sidebar in `docs/_quarto.yml` and the chapters in `docs/_quarto-pdf.yml` in the same position.
3. Images under `docs/assets/img/`, linked with paths relative to the page you are writing in (`../assets/img/x.png` from a guide or lab page).
4. Link between pages with paths relative to the page you are writing in (`../guide/x.md` from a lab), which is how Quarto resolves them; use GitHub URLs for `labs/` and `scripts/`.

## Pedagogy checklist (use when authoring)

- State **learning objectives** in student language (“You will synthesize a counter and inspect the netlist”).
- Assume a clone of this repo and the course’s documented workbench; do not bundle Docker in every lab unless the course already does.
- For EDA-heavy work (LibreLane / SKY130 / IIC-OSIC-TOOLS), use the **team workbench** that IC101 sets up. Link IC101 Lab 03 rather than repeating its setup, and don't invent a one-off container story.
- Keep procedures copy-pasteable (`cd`, install, simulate/synth, check artifact), except drawing and checking in a layout tool, which follow [GUI-first labs](#gui-first-labs).
- Define **expected results** (printout, waveform check, area/timing ballpark, golden hash) so students know they succeeded.
- Progress difficulty across labs; reuse naming and directory conventions so later labs feel familiar.
- Prefer small, inspectable designs over opaque blobs; when using IP or PDK artifacts, keep secrets and huge binaries out of git.

## Tooling norms

- Python helpers and graders: under `labs/<id>/src/` or `scripts/`; list entry points in the nearest `README.md`.
- SystemVerilog/Verilog: under `labs/<id>/src/` (or `rtl/`, `tb/` if you split; stay consistent within the course).
- Heavy outputs (GDS, large FSDB/VCD, PDK caches): local `results/` or LFS, never under `docs/`.
- Preview docs locally: `quarto preview docs` → http://localhost:4200

## What not to do

- Do not add maintainer-only pages to the published site (contributing guides, template notes, notation stubs “for debugging”).
- Do not put solution keys or rubrics in `docs/`.
- Do not replace student-facing content with template/bootstrap instructions; point humans at `CONTRIBUTING.md` / `TEMPLATE.md` only when they are bootstrapping or changing repo conventions.
- Do not change org assumptions: GitHub org is `uoftasic`; course id matches the repo name.

## Quick references

- Repo conventions: `CONTRIBUTING.md`
- Bootstrap tokens / Pages checklist: `TEMPLATE.md`
- Sample lab shape: `labs/lab-01-open-the-cell/` + `docs/labs/lab-01-open-the-cell-overview.md`
