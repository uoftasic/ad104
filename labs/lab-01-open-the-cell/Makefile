# AD104 Lab 01 - open a cell you did not draw
#
# Runs in a bare hpretl/iic-osic-tools:2026.08 container with no environment
# setup: it pins PDK itself, because the image ships with PDK=ihp-sg13g2 and
# every SKY130 layer silently disappears if you leave it that way.
#
#   make          inspect the foundry inverter and print a verdict  (~1.5 s)
#   make gui      open the same cell in Magic, on the noVNC desktop
#   make klayout  open the library GDS in KLayout
#   make netlist  just print the extracted netlist
#   make clean    delete results/

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC  ?= magic
NETGEN ?= netgen
PYTHON ?= python3

CELL     := sky130_fd_sc_hd__inv_1
MAGFILE  := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/mag/$(CELL).mag
PDKSPICE := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice
SETUP    := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl

.PHONY: all check gui edit klayout netlist clean

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

netlist: results/report.txt
	@cat results/$(CELL).lvs.spice

# Every other lab in this course, and getting-started's "What the labs give you"
# table, call this target `edit`. Keep both names here.
gui edit:
	@$(MAGIC) -d X11 $(MAGFILE) &

klayout:
	@klayout -nn $(PDK_ROOT)/sky130A/libs.tech/klayout/tech/sky130A.lyt \
	  $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds &

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
