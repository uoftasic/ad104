# AD104 Lab 02 - read a DRC error and fix it
#
#   make          DRC and LVS all five cells and print a verdict   (~4 s)
#   make reset    throw your fixes away and rebuild the five broken cells
#   make solutions  write the answer key into solutions/
#   make clean    delete results/
#
# You open, check and fix the cells in Magic yourself (cd mag; magic -d X11 drc_03 &).
# This Makefile only checks them and prints a verdict.

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC  ?= magic
NETGEN ?= netgen
PYTHON ?= python3
SETUP  := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl
CELLS  := drc_01 drc_02 drc_03 drc_04 drc_05

# When you extract a cell in Magic yourself, it leaves its .ext file beside the cell in
# mag/. ext2spice reads that file before the fresh one the check writes in results/,
# so a leftover one would make the check grade the cell as it was when you last
# extracted it. The check deletes them first.

.PHONY: all check reset solutions clean

all: check

results:
	@mkdir -p results

results/report.txt: $(wildcard mag/*.mag) tcl/verify.tcl | results
	@echo "== magic: DRC and extract, all five cells"
	@rm -f mag/*.ext
	@$(MAGIC) -dnull -noconsole tcl/verify.tcl > results/magic.log 2>&1 || true
	@test -f $@ || { echo "   Magic wrote no report. Read results/magic.log"; exit 1; }

results/lvs.done: results/report.txt spice/inv_sch.spice
	@echo "== netgen: is each one still an inverter?"
	@for c in $(CELLS); do \
	  $(NETGEN) -batch lvs "results/$$c.lvs.spice $$c" \
	    "spice/inv_sch.spice my_inv" "$(SETUP)" results/$$c.lvs.report \
	    > results/netgen_$$c.log 2>&1 || true; \
	done
	@touch $@

check: results/lvs.done
	@$(PYTHON) src/check.py

reset:
	@mkdir -p results
	@rm -f mag/drc_0*.mag
	@$(MAGIC) -dnull -noconsole tcl/make_broken.tcl > results/reset.log 2>&1 || true
	@ls mag/drc_0*.mag >/dev/null 2>&1 || { echo "reset failed - read results/reset.log"; exit 1; }
	@echo "five broken cells rebuilt in mag/"

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"

solutions:
	@mkdir -p results solutions
	@rm -f solutions/drc_0*.mag
	@$(MAGIC) -dnull -noconsole tcl/make_fixed.tcl > results/solutions.log 2>&1 || true
	@ls solutions/drc_0*.mag >/dev/null 2>&1 || { echo "failed - read results/solutions.log"; exit 1; }
	@echo "wrote solutions/drc_0*.mag"
