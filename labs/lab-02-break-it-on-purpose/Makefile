# AD104 Lab 02 - read a DRC error and fix it
#
#   make          DRC and LVS all five cells and print a verdict   (~4 s)
#   make edit C=1 open mag/drc_01.mag in Magic  (C=1..5)
#   make why  C=1 print every violation in cell C, with its rule name
#   make reset    throw your fixes away and rebuild the five broken cells
#   make clean    delete results/

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC  ?= magic
NETGEN ?= netgen
PYTHON ?= python3
SETUP  := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl
CELLS  := drc_01 drc_02 drc_03 drc_04 drc_05
C      ?= 1

.PHONY: all check edit why reset solutions clean

all: check

results:
	@mkdir -p results

results/report.txt: $(wildcard mag/*.mag) tcl/verify.tcl | results
	@echo "== magic: DRC and extract, all five cells"
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

why: results/report.txt
	@grep "^drc_0$(C) " results/report.txt || echo "no such cell - use C=1..5"

edit:
	@cd mag && $(MAGIC) -d X11 drc_0$(C) &

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
