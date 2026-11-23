# Magic screenshot rig

This folder takes the screenshots of Magic's GUI for the course pages. It runs Magic in
the workbench image under a virtual screen, drives it with real mouse clicks and key
presses from a step file, and writes PNGs. It was built for the AD104 GUI spike in
November 2026.

It runs on `asic-edu/gui-rig:2026.08`, which is `hpretl/iic-osic-tools:2026.08` plus
fluxbox, xterm, the X11 utilities and ImageMagick. Magic is 8.3.681.

## Running it

From the root of the repo, or of your worktree:

```bash
scripts/screenshots/magic/shot.sh -o /tmp/shots-l03 scripts/screenshots/magic/steps/l03.sh
RIG_DISPLAY=66 scripts/screenshots/magic/shot.sh -o /tmp/shots-l01 \
    scripts/screenshots/magic/steps/l01.sh scripts/screenshots/magic/steps/l02.sh
```

| Option | Meaning | Default |
|---|---|---|
| `-s SRC` | folder mounted read-only at `/src`; `work` copies from it | the repo or worktree that holds this folder |
| `-o OUT` | where the PNGs, a `.txt` next to each PNG, and `rig.log` go. Keep it outside the repo, and copy only the PNGs a page uses into `docs/assets/img/` | `./out` |
| `-i IMAGE` | the image | `asic-edu/gui-rig:2026.08` |

Environment: `SCREEN` (default `1600x1000`), `RIG_DISPLAY` (X display number inside the
container, a bare number such as `66`, default `57`; the KLayout rig wants `:66`),
`RIG_TIMEOUT` (seconds before the container is killed, default 900), `RIG_DOCKER_ARGS`
(default `--cpus 2 --memory 3g`), `LAYOUT_GEOM` and `CONSOLE_GEOM` (window placement, see
below). `shot.sh` passes `SCREEN`, `RIG_DISPLAY`,
`LAYOUT_GEOM` and `CONSOLE_GEOM` into the container; the last two only when they are set.
For the workbench's own screen size, run with `SCREEN=1280x800`.

All step files given to one `shot.sh` call run in one container, one after another. The
container runs as you, mounts this folder read-only at `/rig`, and is removed when the run
ends or times out. Magic only ever writes to `/tmp/work` inside the container, so the
source repo is never touched; `keep FILE` copies a file Magic wrote into `OUT/files/`.

Step files go in `steps/`: one per lab (`l01.sh`, `l02.sh`, …, `cap.sh`) and one for the
guide pages (`g.sh`). Every screenshot on a page comes from a committed step file, so it
can be taken again after a change. Run all of a lab's shots in one call. In the spike, ten
step files ran in one container in 26 minutes, most of it in the pauses after each click
and menu item.

## Files

| File | What it is |
|---|---|
| `shot.sh` | host side: starts the container and runs `rig.sh` in it |
| `rig.sh` | container side: Xvfb, fluxbox, the functions step files use, then sources each step file |
| `probe.tcl` | a back channel into Magic's Tcl interpreter (below) |
| `fluxbox-init` | fluxbox settings: no toolbar, click-to-focus |
| `steps/` | the course's step files, one per lab |

## Writing a step file

A step file is bash, sourced by `rig.sh` under `set -euo pipefail`. Any command that fails
(a `grep` that matches nothing, a probe that errors, `head` closing a pipe) ends the run
and leaves `failed.png`, a picture of the screen at that moment. Guard commands that may
fail with `|| true`.

```bash
work labs/lab-03-draw-an-inverter                    # copy from /src to /tmp/work
magic_open labs/lab-03-draw-an-inverter/mag my_inv   # magic -d X11 my_inv, in mag/
box_um 0.40 1.30 2.60 1.95                           # left click, right click
palette ndiffusion 2                                 # middle-click the swatch: paint
capture paint-ndiff layout
menu Drc 'DRC update'
capture drc-after-update screen
magic_quit
```

| Function | Does |
|---|---|
| `work FOLDER` | copies `/src/FOLDER` to `/tmp/work/FOLDER` |
| `keep PATH...` | copies files from `/tmp/work` to `OUT/files/` |
| `magic_open FOLDER ARG...` | starts `magic -d X11 ARG...` in `/tmp/work/FOLDER`, waits until it answers, places its two windows, clicks the layout window's title strip to give it the focus |
| `magic_quit` | ends Magic without saving: asks it to quit, then kills the process `magic_open` started, by its pid. Magic's GUI process is `wish` (the `magic` script execs `tkcon.tcl`), so `pkill -x magic` would find nothing, and `pkill -f magic` also killed the rig itself when a step file's name contained "magic" |
| `box_um X1 Y1 X2 Y2` | sets the box with the mouse: left click at (X1, Y1), right click at (X2, Y2), in microns; reads the box back and retries |
| `click_um X Y [BUTTON]` | clicks the layout at (X, Y) microns; 1 left, 2 middle, 3 right |
| `hover_um X Y` | moves the pointer over (X, Y) microns |
| `hover_center` | moves the pointer to the middle of the drawing area |
| `drag_um BUTTON X1 Y1 X2 Y2` | press, move, release |
| `key KEY...` | presses keys, in xdotool names (`v`, `shift+z`, `ctrl+z`, `equal`, `comma`, `Return`) |
| `type_text TEXT` | types into whatever has the focus |
| `console TEXT` | clicks into tkcon, types the command, presses Return, checks it ran |
| `focus_layout` | clicks the layout window's caption strip, the way a student clicks a title bar on a click-to-focus desktop. Call it after `console` and before the next `key`: without it the key goes into tkcon (`% b`) |
| `focus_console` | clicks in the console, below its last line |
| `palette LAYER [BUTTON]` | clicks a layer's swatch in the palette, scrolling the palette to it first. Uses the palette's own names (`ndiffusion`, `polysilicon`, `locali`, `metal1`). Default button 2, which paints |
| `menu MENU ITEM` | clicks a title-bar menu, then the item, by their labels (`menu Drc 'DRC update'`) |
| `menu_open MENU` | opens a menu and leaves it open, for a screenshot of it |
| `click_button TEXT [TOPLEVEL]` | clicks a Tk button by its label (`click_button 'Create and Close' .params`) |
| `fill_entry LABEL TEXT [TOPLEVEL]` | replaces the text of the entry next to a label (`fill_entry 'Width (um)' 0.65 .params`) |
| `click_tree TREE TEXT [double]` | clicks a row in the Cell, Library or DRC Manager (`.cellmgr.box.view`, `.libmgr.box.view`, `.drcmgr.box.view`) |
| `move_window TITLE_REGEX X Y` | moves a window, for dialogs that open partly off the screen |
| `terminal [TITLE]` | opens an xterm to type shell commands into (netgen, `cat`) |
| `capture NAME [WHAT...]` | waits for the screen to stop changing, then writes `NAME.png` cropped to WHAT, and `NAME.txt` with the title bar as text and the end of the console |
| `probe TCL` | evaluates Tcl inside Magic and prints the result |
| `readout`, `box_values`, `view_um`, `console_tail [N]` | the title bar, the box and the view in microns, and the end of the console, as text |
| `windows` | lists the visible windows with their positions |
| `pause SECONDS` | waits |

`WHAT` in `capture` is any mix of `screen`, `layout` (the layout window without its frame),
`console`, `tk:PATH` (any Tk window in Magic, such as `tk:.params`), `menu:MENU` (an open
title-bar menu), `win:TITLE_REGEX` (any X window, such as `win:'^lvs-terminal$'`) and
`X,Y,W,H`. The crop is the smallest rectangle holding all of them, so
`capture drc-menu layout menu:Drc` shows the window with its menu open.

## Window layout

On a screen at least 1000 px tall (the default `SCREEN=1600x1000`), `magic_open` puts the
layout window's client area at (1, 45), 1200 × 750, which is the size Magic gives it, and
the tkcon console under it at (1, 823), 1200 × 200. On a shorter screen both shrink so the
console stays on it: with `SCREEN=1280x800` the layout window's client area is at (1, 45),
1200 × 540, and the console's at (1, 623), 1200 × 170. Before this default, tkcon landed at
y = 823 on a 1280 × 800 screen, off the bottom, and `console` typed into the layout window,
where the letters ran as key macros. Change either with `LAYOUT_GEOM` and `CONSOLE_GEOM`
("X Y W H"). Magic opens its other windows at the right
edge of the layout window, x = 1203: the text dialog (352 × 244), the device dialog
(566 to 626 wide), the Cell Manager (427 wide), and the Library and DRC Managers (513
wide). All but the text dialog then run past the right edge of a 1600-pixel screen, so
move them with `move_window` before clicking in them or capturing them. A button off the
screen can't be clicked: the device dialog's `Close` stayed out of reach. Under the
workbench's XFCE desktop, windows open in other places, which matters only for full-screen
shots.

The screen behind the windows is painted flat grey. fluxbox's default style tries to set a
wallpaper, finds no image, and opens an `xmessage` reading "what." near the right edge; the
rig closes it at start and before every capture, because it comes back.

## The probe

`probe.tcl` polls a folder every 100 ms for a file holding a Tcl command, runs it in
Magic's interpreter, and writes the result back. The rig uses it to read what the screen
shows only as pixels (the box, the DRC count, the title bar), to find where things are
(menu items, palette swatches, dialog buttons, tree rows), and to convert microns to screen
pixels. It is never used to change the layout: every screenshot step does its work with
the mouse and keys. Keep probe commands quiet. `box values` returns a value; `box` prints
into the console, and the console is in the screenshots.

The probe is loaded from a `.magicrc` that `magic_open` adds to the start folder in the
work copy. Passing it on Magic's command line also works, but then Magic prints
`Handling file entry /rig/probe.tcl extension .tcl` in the console.

## Pitfalls

Each of these happened in this image during the spike.

- **Keys act where the pointer is.** Magic's layout keys work only while the pointer is
  over the drawing area. A key pressed with the pointer over the scrollbar or the title
  bar left Magic with no current window: until the pointer moved back over the drawing,
  window commands failed with an empty error, and Window → Set grid 0.05um raised an
  "Application Error" box whose message is just "Error:". Call `hover_um` or
  `hover_center` before every `key`. The same happened after a dialog closed with the
  pointer still where its button had been.
- **Pixels and the snap grid.** Magic snaps a click to its snap grid, lambda (0.01 µm) by
  default. At the view Magic opens Lab 03's 3 × 6 µm cell with, one pixel is about
  0.0104 µm, so some lambda values cannot be clicked at all (y = 1.40 came out as 1.39).
  `hover_um` reads back where Magic thinks the pointer is and nudges it a pixel at a time;
  when it cannot get there it logs `pointer is at internal …, wanted …`. Zoom in on the
  part you are drawing (box, then `ctrl+z`) before drawing to exact numbers. On the
  capstone row, 14 µm wide, y = 0 could not be hit at the default view.
- **Snap after Snap-to-grid off.** Window → Snap-to-grid off sets the snap to internal
  units (0.005 µm), not back to lambda, so clicks then land on values like 0.405.
  Restart Magic, or don't use that menu item in a step file.
- **Units.** Window → Report micron units (and the other Report items) changes the units
  some commands answer in, including `view get`. `probe.tcl` asks for internal units
  itself, so the pixel conversion survives it.
- **A stale pointer.** Before the probe called `update`, it sometimes ran before Tk had
  read the pointer move that xdotool had just made, and `cursor` reported the old
  position. The probe now handles pending events first; keep that if you change it.
- **Ignored clicks.** In about 200 `box_um` calls, Magic ignored both clicks four times.
  Three of the four were the first box set after the first paint of the session (the
  paint after which the console prints `Loading DRC CIF style.`); we did not find the
  cause. A right click 0.4 s after a left click is not it: gaps of 0.1 to 1.0 s all worked
  in a controlled test. `box_um` reads the box back and retries after a 2 s pause, which
  worked each time; check the log for `box_um: box is still`. That message also appears
  when the zoom can't reach the target (see "Pixels and the snap grid").
- **Lost Return in the console.** The first Return after typing into a freshly focused
  console was sometimes not taken, and the next command was appended to the same line
  (`extract allext2spice lvs`). `console` checks that the command line is empty
  afterwards and presses Return again.
- **The first key after the palette.** Once, the first `s` after right-clicking two
  palette swatches selected nothing; with a `,` pressed first it worked. Press a harmless
  key first in that spot.
- **Menus are Tk menubuttons.** Open them by clicking. `menu` finds the button and the item
  through the probe, so a step file names labels, not pixels. Labels with extra spaces
  must be written exactly: `'Up   hierarchy'`, `'Lock   Cell'`, `'Mirror   Up/Down'`,
  `'Unlock  Base Layers'`, `'Text ...'`.
- **The Tk file dialog** (File → Open..., Cell → Place Instance, File → Write GDS) opens
  with the focus in "File name:", so `type_text name.mag; key Return` works. A full path
  works too.
- **Entries.** `fill_entry` selects an entry's text with a triple click and types over it.
  Don't press `ctrl+a` first: in a Tk entry it moves to the start of the line and drops the
  selection.
- **Console text in screenshots.** Some time after the first change (within the few
  minutes a step file ran), Magic writes `Created database crash recovery file /tmp/MAG….`
  in the console.
  A selected top cell is drawn with its name and the words "Topmost cell in the window"
  across it.
- **Timing.** Magic answered the probe about 1 s after starting. `capture` waits until two
  grabs 0.4 s apart are identical (at most 15 s), which took about 0.5 s on a still
  screen; the console's text cursor did not keep it waiting.
- **Captures** use `import -window root`, which got Magic's toolbar, menus and dialogs
  right. `xwd` was not tried.
- **Container limits.** Run one `shot.sh` at a time on a shared machine. The rig kills Magic,
  netgen, xterm, fluxbox and Xvfb when it ends (by exact process name: `wish`,
  `magicexec`, `magicdnull`, `netgenexec`, `xterm`; never `pkill -f`), and `shot.sh`
  kills the container on a timeout or Ctrl-C.
