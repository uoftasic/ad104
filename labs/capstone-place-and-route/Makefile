# AD104 Capstone - place and route it yourself
#
#   make           DRC both ways, LVS, then time the path            (~15 s)
#   make layout    just the DRC and LVS part                          (~1.4 s)
#   make scaffold  throw your routing away, back to four placed cells
#   make ref       build solutions/datapath_ref.mag
#   make refcheck  run every check against the reference block
#   make clean     delete results/

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC   ?= magic
NETGEN  ?= netgen
NGSPICE ?= ngspice
PYTHON  ?= python3
SETUP   := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl

.PHONY: all check layout scaffold ref refcheck clean

all: check

results:
	@mkdir -p results

results/report.txt: mag/datapath.mag tcl/verify.tcl | results
	@echo "== magic: DRC (both rule sets) and extract"
	@$(MAGIC) -dnull -noconsole tcl/verify.tcl > results/magic.log 2>&1 || true
	@test -f $@ || { echo "   Magic wrote no report. Read results/magic.log"; exit 1; }

results/lvs.report: results/report.txt spice/datapath_sch.spice
	@echo "== netgen: is it the netlist you were given?"
	@$(NETGEN) -batch lvs "results/datapath.lvs.spice datapath" \
	   "spice/datapath_sch.spice datapath" "$(SETUP)" $@ > results/netgen.log 2>&1 || true
	@test -f $@ || { echo "   netgen wrote no report. Read results/netgen.log"; exit 1; }

# The timing run is skipped, without failing the build, when the layout is not
# finished yet - check.py then reports the layout problems instead of ngspice
# reporting a missing port.
results/timing.log: results/lvs.report src/mktiming.py
	@echo "== ngspice: clock edge to output, on the extracted layout"
	@$(PYTHON) src/mktiming.py > results/mktiming.log 2>&1 || \
	  echo "   (skipped: $$(tail -1 results/mktiming.log))"
	@if [ -f results/timing.spice ]; then \
	  cat results/mktiming.log; \
	  cd results && $(NGSPICE) -b timing.spice </dev/null > timing.log 2>&1 || true; \
	else touch $@; fi

layout: results/lvs.report
	@$(PYTHON) src/check.py --layout-only

check: results/timing.log
	@$(PYTHON) src/check.py

scaffold: | results
	@rm -f mag/datapath.mag
	@$(MAGIC) -dnull -noconsole tcl/place.tcl > results/place.log 2>&1 || true
	@test -f mag/datapath.mag || { echo "place.tcl failed - read results/place.log"; exit 1; }
	@echo "mag/datapath.mag reset to four placed cells, no wires"

ref: | results
	@rm -f solutions/datapath_ref.mag
	@$(MAGIC) -dnull -noconsole tcl/route_ref.tcl > results/ref.log 2>&1 || true
	@test -f solutions/datapath_ref.mag || { echo "route_ref.tcl failed - read results/ref.log"; exit 1; }
	@echo "wrote solutions/datapath_ref.mag"

refcheck: | results
	@echo "== the reference block, not yours"
	@AD104_CELL=datapath_ref AD104_SRC=../solutions \
	  $(MAGIC) -dnull -noconsole tcl/verify.tcl > results/magic_ref.log 2>&1 || true
	@$(NETGEN) -batch lvs "results/datapath_ref.lvs.spice datapath_ref" \
	   "spice/datapath_sch.spice datapath" "$(SETUP)" results/lvs.report \
	   > results/netgen_ref.log 2>&1 || true
	@$(PYTHON) src/check.py --layout-only --cell datapath_ref

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
