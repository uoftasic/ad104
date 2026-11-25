# AD104 Lab 01 - open a cell you did not draw
#
# Runs in a bare hpretl/iic-osic-tools:2026.08 container with no environment
# setup: it pins PDK itself, because the image ships with PDK=ihp-sg13g2 and
# every SKY130 layer silently disappears if you leave it that way.
#
#   make          inspect the foundry inverter and print a verdict  (~1 s)
#   make clean    delete results/
#
# The lab has you open the cell in Magic, check it, extract it and run netgen
# yourself. This Makefile checks the same things in batch and prints a verdict.

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC  ?= magic
NETGEN ?= netgen
PYTHON ?= python3

CELL     := sky130_fd_sc_hd__inv_1
PDKSPICE := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice
SETUP    := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl

.PHONY: all check clean

all: check

results:
	@mkdir -p results

results/report.txt: tcl/inspect.tcl | results
	@echo "== magic: load, DRC, extract   ($(CELL))"
	@$(MAGIC) -dnull -noconsole tcl/inspect.tcl > results/magic.log 2>&1 || true
	@test -f $@ || { echo "   Magic wrote no report. Read results/magic.log"; exit 1; }

results/lvs.report: results/report.txt
	@echo "== netgen: layout vs the foundry's own netlist"
	@$(NETGEN) -batch lvs \
	  "results/$(CELL).lvs.spice $(CELL)" \
	  "$(PDKSPICE) $(CELL)" \
	  "$(SETUP)" $@ > results/netgen.log 2>&1 || true
	@test -f $@ || { echo "   netgen wrote no report. Read results/netgen.log"; exit 1; }

check: results/lvs.report
	@$(PYTHON) src/check.py

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
