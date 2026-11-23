#!/usr/bin/env bash
# Take Magic GUI screenshots: run one or more step files in the workbench image, under a
# virtual screen, and write the PNGs to an output folder.
#
#   shot.sh [-s SRC] [-o OUT] [-i IMAGE] STEP_FILE...
#
#   -s SRC    folder mounted read-only at /src, that `work` copies from
#             (default: the repo or worktree this script is in, three folders up)
#   -o OUT    where PNGs, .txt readouts and rig.log go (default: ./out)
#   -i IMAGE  default asic-edu/gui-rig:2026.08 (hpretl/iic-osic-tools:2026.08 plus fluxbox,
#             xterm, x11 utilities and ImageMagick)
#
# All step files run in one container, one after the other, so they share the screen and
# /tmp/work. The container gets 2 CPUs and 3 GB, runs as you (so the PNGs are yours), and is
# killed after RIG_TIMEOUT seconds (default 900). SCREEN, RIG_DISPLAY, LAYOUT_GEOM and
# CONSOLE_GEOM are passed into the container (the last two only when set).
set -euo pipefail

RIG_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$RIG_DIR/../../.." && pwd)"
OUT=./out
IMAGE=asic-edu/gui-rig:2026.08
while getopts "s:o:i:" opt; do
    case "$opt" in
        s) SRC="$OPTARG" ;;
        o) OUT="$OPTARG" ;;
        i) IMAGE="$OPTARG" ;;
        *) sed -n '2,16p' "$0"; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -ge 1 ] || { sed -n '2,16p' "$0"; exit 2; }

STEPS_DIR="$(cd "$(dirname "$1")" && pwd)"
args=()
for f in "$@"; do
    [ "$(cd "$(dirname "$f")" && pwd)" = "$STEPS_DIR" ] || {
        echo "shot.sh: all step files must be in one folder ($STEPS_DIR)" >&2; exit 2; }
    args+=("/steps/$(basename "$f")")
done
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
SRC="$(cd "$SRC" && pwd)"

NAME="magic-shot-$$"
trap 'docker kill "$NAME" >/dev/null 2>&1 || true' EXIT INT TERM
timeout "${RIG_TIMEOUT:-900}" docker run --rm --name "$NAME" \
    ${RIG_DOCKER_ARGS:---cpus 2 --memory 3g} \
    --user "$(id -u):$(id -g)" \
    -e RIG_DISPLAY="${RIG_DISPLAY:-57}" -e SCREEN="${SCREEN:-1600x1000}" \
    -e LAYOUT_GEOM -e CONSOLE_GEOM \
    -v "$RIG_DIR":/rig:ro -v "$SRC":/src:ro -v "$STEPS_DIR":/steps:ro -v "$OUT":/out \
    -w /tmp "$IMAGE" --skip bash -c 'bash /rig/rig.sh "$@" 2>&1 | tee /out/rig.log' rig "${args[@]}" \
    | grep -v '^\[INFO\]'
