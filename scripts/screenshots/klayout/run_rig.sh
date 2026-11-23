#!/bin/bash
# Host side of the KLayout screenshot rig: one fresh container, Xvfb + fluxbox
# + KLayout, a steps file, PNGs out, everything torn down at the end.
#
#   run_rig.sh STEPS_FILE OUT_DIR [klayout args...]
#
# Environment (host):
#   RIG_WS     folder mounted at /w, standing in for the workspace's /foss/designs
#              (required; README.md says how to make one). If it has env.sh, that is
#              sourced first (PDK switch, KLAYOUT_PATH with the plugin, KMP_PDKS).
#   RIG_IMAGE  default asic-edu/gui-rig:2026.08 (hpretl/iic-osic-tools:2026.08 + fluxbox,
#              xterm, x11 utils, ImageMagick)
#   RIG_DISPLAY, RIG_GEOM, RIG_DPI as in rig.sh (RIG_DISPLAY with its colon: ":66")
#
# Example, from the root of the repo:
#   RIG_WS=/tmp/kws scripts/screenshots/klayout/run_rig.sh \
#       scripts/screenshots/klayout/examples/start_with_tech.steps /tmp/kshots \
#       -e -n sky130A /w/work/rig/my_inv.gds
set -euo pipefail
[ $# -ge 2 ] || { sed -n '2,18p' "$0"; exit 2; }
[ -n "${RIG_WS:-}" ] || { echo "run_rig.sh: set RIG_WS to a workspace folder (README.md)" >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
steps=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); shift
out=$1; shift; mkdir -p "$out"; out=$(cd "$out" && pwd)
ws=$(cd "$RIG_WS" && pwd)
image=${RIG_IMAGE:-asic-edu/gui-rig:2026.08}
name=klayout-rig-$$
# timeout: the container can never outlive a hung step by more than 15 minutes
exec timeout 900 docker run --rm --name "$name" --cpus 2 --memory 3g \
  --user "$(id -u):$(id -g)" \
  -v "$ws":/w -v "$here":/rig:ro -v "$out":/out -v "$steps":/steps.txt:ro -w /w \
  -e RIG_OUT=/out -e RIG_DISPLAY="${RIG_DISPLAY:-:57}" -e RIG_GEOM="${RIG_GEOM:-1680x1050}" -e RIG_DPI="${RIG_DPI:-96}" \
  "$image" --skip bash -lc '
    [ -f /w/env.sh ] && . /w/env.sh
    /rig/rig.sh start "$@"
    rc=0; /rig/rig.sh steps /steps.txt || rc=$?
    /rig/rig.sh stop
    exit $rc' rig "$@"
