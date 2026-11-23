# KLayout screenshot rig

Drives KLayout's Qt GUI in a throwaway container: Xvfb, fluxbox, KLayout, a
file of xdotool steps, and PNGs out. It was built for the AD104-K spike in
November 2026 and takes the course's KLayout screenshots.

| File | What it is |
|---|---|
| `run_rig.sh` | Host side. Starts one container, runs a steps file, tears everything down. |
| `rig.sh` | Container side. Starts Xvfb and fluxbox, launches KLayout, runs steps. |
| `env.sh` | Goes into the workspace folder (below). Switches the PDK to sky130A, puts the plugin on `KLAYOUT_PATH` and sets `KMP_PDKS=sky130A`. |
| `steps/` | The course's steps files, one per lab (`l01.steps`, …). Every KLayout screenshot on a page comes from one of them. |
| `examples/klayout_demo.steps` | End-to-end example: open a GDS with sky130A, Run DRC (Full), place a `sky130_magic` nfet. |
| `examples/start_with_tech.steps` | Start-up check for `klayout -e -n sky130A file.gds`. |

## The workspace folder

The container mounts a host folder at `/w`, standing in for the workspace's
`/foss/designs`, and sources its `env.sh` before starting KLayout.
`run_rig.sh` takes it from `RIG_WS` and stops if that is not set. From the
root of the repo, make one outside it:

```bash
WS=/tmp/kws                       # any scratch folder
mkdir -p "$WS/work"
cp scripts/screenshots/klayout/env.sh "$WS/"
```

Shots that use the klayout-magic-pcells plugin also need a copy of it. Take
a `git archive` of one commit, so the plugin's own checkout is only read, and
write the commit down:

```bash
c=$(git -C /path/to/klayout-magic-pcells rev-parse HEAD)
mkdir -p "$WS/klayout/salt/klayout-magic-pcells"
git -C /path/to/klayout-magic-pcells archive "$c" | tar -x -C "$WS/klayout/salt/klayout-magic-pcells"
echo "$c" > "$WS/klayout/PLUGIN_COMMIT"
```

Inside the container KLayout sees only `/w` and the image, so copy the
course files a steps file opens into `$WS/work/` first. Files in the image,
such as the PDK's GDS libraries, open by their path. The two examples open
`/w/work/rig/my_inv.gds`.

## Running it

From the root of the repo:

```bash
RIG_WS=/tmp/kws RIG_DISPLAY=:66 scripts/screenshots/klayout/run_rig.sh \
    scripts/screenshots/klayout/examples/start_with_tech.steps /tmp/kshots \
    -e -n sky130A /w/work/rig/my_inv.gds
```

Arguments after the output folder go to `klayout`. The demo was run with
`-nn /foss/pdks/sky130A/libs.tech/klayout/tech/sky130A.lyt`, which registers a
second copy of the technology (the toolbar shows `sky130A[1]`) because
`KLAYOUT_PATH` already has it; `-e -n sky130A file.gds` picks the registered
one and is what `examples/start_with_tech.steps` checks. The PNGs go to the
output folder and the logs (Xvfb, fluxbox, KLayout, the rig's own) to its
`logs/` subfolder. Keep the output folder outside the repo, and copy only the
PNGs a page uses into `docs/assets/img/`.

The demo run took 45 s in the spike. Each container is started with
`--cpus 2 --memory 3g` and wrapped in `timeout 900`, and the rig kills
KLayout, fluxbox and Xvfb before the container exits, so nothing is left
running even when a step fails. A failed step writes `FAILED-line<n>.png` and
stops the run.

For exploring, start a container that sleeps, run `rig.sh start -e ...` in it
with `docker exec`, and send single steps the same way (`rig.sh key r`,
`rig.sh shot name`). That is how the spike's 109 numbered shots were taken.
Stop it with `rig.sh stop` and `docker stop`.

## Step language

One step per line; `#` starts a comment. Arguments are split like a shell
command line, so quote anything with spaces or glob characters
(`type '*nfet_01v8*'`).

| Step | Does |
|---|---|
| `wait REGEX [S]` | Wait up to S seconds (default 30) for a visible window whose title matches. |
| `gone REGEX [S]` | Wait for it to close. |
| `activate REGEX` | Raise and focus it. |
| `ifwin REGEX STEP...` | Run STEP only if that window is up now (first-start dialogs). |
| `maximize REGEX` | Move to (0, 22) and size to the screen minus fluxbox's title bar and toolbar. |
| `click X Y [BUTTON]`, `dclick X Y`, `move X Y` | Pointer, absolute screen coordinates. |
| `wheel X Y N` | N wheel clicks down (negative N scrolls up). |
| `drag X1 Y1 X2 Y2` | Press, move in two steps, release. |
| `wclick REGEX DX DY` | Click relative to a window (see the geometry pitfall below). |
| `key KEYS...` | xdotool key names: `Return`, `ctrl+a`, `shift+f`, `Down`. |
| `type TEXT` | Type a string. |
| `shot NAME` | Whole screen to `NAME.png`. |
| `shotwin REGEX NAME` | One window only (good for dialogs). |
| `crop NAME WxH+X+Y NEW` | Cut a region out of an earlier shot. |
| `waitfile PATH [S]` | Wait for a non-empty file (a DRC report, say). |
| `since LABEL` | Log the seconds since KLayout was started. |
| `sleep S`, `sh CMD`, `log TEXT`, `windows` | `windows` lists visible windows with geometry. |

## Coordinates used by the demo

With the main window maximised at 1680x1050: the menu bar is at y = 30, the
toolbar at y = 70 (Select x = 150, Box 436, Text 477, Path 520, Instance 576,
Partial 637, technology button 889 with its arrow at 930), File at x = 20,
Edit 56, View 97, Tools 280, Efabless sky130 457. In that menu Run DRC (Full)
is at y = 118 and Run LVS at y = 161. Everything else (dialog fields, tabs,
list rows) depends on dock widths and dialog sizes, so check against a fresh
`shot` before relying on a number from the spike.

## Pitfalls met in the spike

- **First-start "Tip" dialog.** A fresh container shows a modal *Tip* about
  showing only the top cell. Return presses its default button, Yes (show the
  full hierarchy). `ifwin '^Tip$' key Return` handles it.
- **fluxbox background popup.** On the first run fluxbox's `fbsetbg` opened an
  `xmessage` (`fbsetbg: Something we…`, cut off in the spike's first shot)
  that lands in every screenshot. `rig.sh start` writes a style overlay with
  `background: none` and kills any `xmessage` left over.
- **Initial window size.** KLayout opens at 800x600. `maximize` fixes it;
  without it every coordinate shifts.
- **`xdotool mousemove --sync` can hang.** It waits for a motion event, and
  blocks forever when the pointer is already at the target. The rig skips the
  move in that case and wraps every xdotool call in `timeout 10`.
- **Window geometry is off by the title bar.** Under fluxbox,
  `xdotool getwindowgeometry` reported the Tip dialog's y as 329 while its
  title bar was drawn at about 286 and its Yes button at y = 615. Prefer
  absolute coordinates read off a screenshot over `wclick`.
- **Dialogs remember their size.** After a PCell instance was opened in
  *Object Properties* the dialog came back at 1026x641 instead of 828x567 for
  a plain box, and clicks aimed at the small layout's fields landed in the
  wrong ones. Take a `shot` after opening a dialog before clicking in it.
- **Edits in Object Properties apply at once.** Typing a value and pressing
  Tab changes the shape; Escape and Cancel do not undo it. Use `u` (undo)
  afterwards.
- **Undo includes view changes.** Hiding or showing layers in the Layers panel
  is an undo step, so `u` may undo a visibility change instead of the edit you
  meant.
- **Non-modal browsers go behind the main window.** Activating the main window
  hides the Marker or Netlist Database Browser, and the next click lands on
  whatever is under it (in the spike, a Tool Options checkbox). `activate` the
  browser before clicking in it.
- **Return in a filter box presses the default button.** In the Marker
  Database Browser, Return in the Category filter opened *Configure*.
- **Tooltips need about 2 s of hover.** `move` then `sleep 2.5` before the
  `shot`.
- **Narrow docks.** The left dock opens 183 px wide, too narrow for the PCell
  form and the Instance options. `drag 187 600 640 600` widens it.
- **Hidden layers in a new layout.** The image's `klayoutrc` sets
  `hide-empty-layers`, so a new, empty layout shows an empty Layers panel.
- **Typed box size.** While drawing a box, Tab moves focus into the `w:` field
  that KLayout shows at the top left of the canvas; type, Tab, type, Return.
- **Timing.** In the rig, KLayout took 10 to 11 s from launch to a window with
  the layout loaded (`since` lines in the rig log). Under `klayout -zz` the same
  start-up took about 5 s, of which the PDK's efabless PCell autorun is about
  2.3 s and the plugin about 0.5 s. In batch, a PCell variant that is not
  cached took 31 ms (Magic generates it) and a cached one 3 ms; the plugin
  starts its Magic process at start-up. The GUI placement was not timed
  separately; in the demo the ghost appeared within the step's 2 s wait.
  Later, on the machine shared with other jobs, the same start took 26 s, so
  keep `wait` timeouts long (the examples use 120 s). Wait for the window
  title to show the file name, not just for the window.
- **High DPI.** Not tried. Xvfb runs at 96 dpi; the coordinates above are for
  that and for 1680x1050.
- **Screen size.** 1680x1050 is the image's own default `VNC_RESOLUTION`, not
  the workbench's: `workspace/scripts/start_vnc.sh` (line 10) starts the
  student desktop at 1280x800 unless `VNC_RESOLUTION` is set. The rig's
  default stays 1680x1050 because every coordinate here was measured at it;
  set `RIG_GEOM=1280x800` to see what a student sees, and take a `shot`
  before relying on any coordinate.
- **Display number.** `:57` by default. Give it with the colon
  (`RIG_DISPLAY=:66`); the Magic rig takes the bare number. Each container has
  its own `/tmp/.X11-unix`, so it only has to be unique among rigs in one
  container.
- **One container at a time.** The machine is shared; `run_rig.sh` runs one
  and removes it.
