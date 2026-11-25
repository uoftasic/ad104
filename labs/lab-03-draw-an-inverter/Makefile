# AD104 Lab 03 - draw a CMOS inverter
#
# Runs in a bare hpretl/iic-osic-tools:2026.08 container with no environment
# setup: it pins PDK itself, because the image ships with PDK=ihp-sg13g2.
#
#   make            check YOUR cell: DRC, extract, LVS, and a verdict  (~1 s)
#   make scaffold   throw your cell away and start again from the frame
#   make ref        rebuild solutions/inv_ref.mag from tcl/inverter.tcl
#   make refcheck   run the same checks against the reference cell
#   make clean      delete results/

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC  ?= magic
NETGEN ?= netgen
PYTHON ?= python3
SETUP  := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl

.PHONY: all check scaffold ref refcheck clean

all: check

results:
	@mkdir -p results

results/report.txt: mag/my_inv.mag tcl/verify.tcl | results
	@echo "== magic: DRC and extract   (mag/my_inv.mag)"
	@$(MAGIC) -dnull -noconsole tcl/verify.tcl > results/magic.log 2>&1 || true
	@test -f $@ || { echo "   Magic wrote no report. Read results/magic.log"; exit 1; }

results/lvs.report: results/report.txt spice/my_inv_sch.spice
	@echo "== netgen: your layout vs the schematic"
	@$(NETGEN) -batch lvs "results/my_inv.lvs.spice my_inv" \
	   "spice/my_inv_sch.spice my_inv" "$(SETUP)" $@ > results/netgen.log 2>&1 || true
	@test -f $@ || { echo "   netgen wrote no report. Read results/netgen.log"; exit 1; }

check: results/lvs.report
	@$(PYTHON) src/check.py

scaffold:
	@rm -f mag/my_inv.mag
	@$(MAGIC) -dnull -noconsole tcl/frame.tcl > results/frame.log 2>&1 || true
	@test -f mag/my_inv.mag || { echo "frame.tcl failed - read results/frame.log"; exit 1; }
	@echo "mag/my_inv.mag reset to the empty frame"

ref: | results
	@rm -f solutions/inv_ref.mag
	@$(MAGIC) -dnull -noconsole tcl/inverter.tcl > results/ref.log 2>&1 || true
	@test -f solutions/inv_ref.mag || { echo "inverter.tcl failed - read results/ref.log"; exit 1; }
	@echo "wrote solutions/inv_ref.mag"

refcheck: | results
	@echo "== the reference cell, not yours"
	@$(MAGIC) -dnull -noconsole tcl/verify_ref.tcl > results/magic_ref.log 2>&1 || true
	@$(NETGEN) -batch lvs "results/inv_ref.lvs.spice inv_ref" \
	   "spice/my_inv_sch.spice my_inv" "$(SETUP)" results/lvs_ref.report > results/netgen_ref.log 2>&1 || true
	@$(PYTHON) src/check.py --cell inv_ref

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
