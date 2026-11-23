# Sourced by run_rig.sh when it sits in RIG_WS as env.sh. A stand-in for what the
# workspace's common/.designinit would add; the workspace is /w here, /foss/designs for
# students.
# 1) the workspace's own PDK switch (same as common/.designinit does)
_f=$-; set +eu; . sak-pdk-script.sh sky130A >/dev/null 2>&1 || true
case "$_f" in *e*) set -e;; esac; case "$_f" in *u*) set -u;; esac; unset _f
export PDK=sky130A
# 2) the plugin: a Salt package under <entry>/salt/ of a KLAYOUT_PATH entry
export KMP_WS=${KMP_WS:-/w}
export KLAYOUT_PATH="/headless/.klayout:$PDK_ROOT/sky130A/libs.tech/klayout:$KMP_WS/klayout"
export KMP_PDKS=sky130A
