# Agent guide — UofT ASIC course repos

You are working in a **course repository** for the UofT ASIC Team (`uoftasic`): pedagogical materials for IC / RTL / FPGA / open-source ASIC flows. The site under `docs/` is published on GitHub Pages (Docsify, zero build). Runnable work lives outside `docs/`.

Optimize for **clear student learning paths**, not template maintenance. Prefer concrete labs and notes students can follow end-to-end over meta documentation.

## Goals

- Teach IC development skills: RTL (SystemVerilog/Verilog), simulation, synthesis, FPGA bring-up, and/or open ASIC flows (e.g. Yosys, LibreLane, SKY130) as the course requires.
- Keep each lab **self-contained**, in the [lab writeup shape](#lab-writeup-shape) below.
- Keep guide pages (`docs/guide/`) **reading only**: concepts, figures, worked examples. Commands and activities belong in the lab writeups; a guide page points to the lab part where the student does it.
- Keep the **Course path** table on `docs/README.md` (alternating Read and Do rows, in the [Course path format](#course-path-format) below) and `docs/_sidebar.md` in the same order.
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

Site wiring: `docs/index.html`, `docs/_sidebar.md`, `docs/_navbar.md`. Math: `$inline$`, `$$display$$`.

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
   - `README.md` — points at the Docsify writeup and how to run
   - `src/` — HDL / Python / entrypoints
   - `data/` — small inputs (large binaries → Git LFS or external)
   - `requirements.txt` or tool notes when needed
2. Add `docs/labs/<lab-id>-overview.md` in the [lab writeup shape](#lab-writeup-shape).
3. Add a Do row for it to the Course path table in `docs/README.md` in the [Course path format](#course-path-format), update the course total, and link the writeup from `docs/_sidebar.md` in the same position (and from `_navbar.md` only if it belongs in top nav).
4. Cross-link: writeup → GitHub `labs/<lab-id>/`; package README → `docs/labs/<lab-id>-overview.md`.

**Writeups teach; packages execute.** Do not dump long HDL into Docsify pages; reference files under `labs/`.

## Adding a guide page

1. Add kebab-case Markdown under `docs/guide/` (e.g. `yosys-synth.md`). Reading only: no required commands.
2. Add it to the right Read row of the Course path in `docs/README.md`, and link it from `docs/_sidebar.md` in the same position.
3. Images under `docs/assets/img/` with paths relative to `docs/`.
4. Prefer relative Docsify links between pages; use GitHub URLs for `labs/` and `scripts/`.

## Pedagogy checklist (use when authoring)

- State **learning objectives** in student language (“You will synthesize a counter and inspect the netlist”).
- Assume a clone of this repo and the course’s documented workbench; do not bundle Docker in every lab unless the course already does.
- For EDA-heavy work (LibreLane / SKY130 / IIC-OSIC-TOOLS), use the **team workbench** that IC101 sets up. Link IC101 Lab 03 rather than repeating its setup, and don't invent a one-off container story.
- Keep procedures copy-pasteable (`cd`, install, simulate/synth, check artifact).
- Define **expected results** (printout, waveform check, area/timing ballpark, golden hash) so students know they succeeded.
- Progress difficulty across labs; reuse naming and directory conventions so later labs feel familiar.
- Prefer small, inspectable designs over opaque blobs; when using IP or PDK artifacts, keep secrets and huge binaries out of git.

## Tooling norms

- Python helpers and graders: under `labs/<id>/src/` or `scripts/`; list entry points in the nearest `README.md`.
- SystemVerilog/Verilog: under `labs/<id>/src/` (or `rtl/`, `tb/` if you split; stay consistent within the course).
- Heavy outputs (GDS, large FSDB/VCD, PDK caches): local `results/` or LFS, never under `docs/`.
- Preview docs locally: `npx docsify-cli serve docs` → http://localhost:3000

## What not to do

- Do not add maintainer-only pages to the published site (contributing guides, template notes, notation stubs “for debugging”).
- Do not put solution keys or rubrics in `docs/`.
- Do not replace student-facing content with template/bootstrap instructions; point humans at `CONTRIBUTING.md` / `TEMPLATE.md` only when they are bootstrapping or changing repo conventions.
- Do not change org assumptions: GitHub org is `uoftasic`; course id matches the repo name.

## Quick references

- Repo conventions: `CONTRIBUTING.md`
- Bootstrap tokens / Pages checklist: `TEMPLATE.md`
- Sample lab shape: `labs/lab-01-open-the-cell/` + `docs/labs/lab-01-open-the-cell-overview.md`
