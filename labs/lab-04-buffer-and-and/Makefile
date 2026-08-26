# AD104 Lab 04 - a buffer and an AND gate, out of cells you drew
#
#   make           DRC + LVS both blocks, then simulate the AND    (~1 min)
#   make layout    just the DRC and LVS part
#   make edit CELL=my_buf     open a block in Magic
#   make cells     rebuild mag/my_inv.mag and mag/my_nand2.mag
#   make scaffold  throw your work away, back to two placed cells
#   make ref       build solutions/buf_ref.mag and solutions/and_ref.mag
#   make refcheck  run every check against the reference blocks
#   make swapped   LVS the NAND against a netlist with A and B exchanged
#   make clean     delete results/

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC   ?= magic
NETGEN  ?= netgen
NGSPICE ?= ngspice
PYTHON  ?= python3
SETUP   := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl
CELL    ?= my_buf

.PHONY: all check layout sim edit cells scaffold ref refcheck swapped clean

all: check

results:
	@mkdir -p results

results/report.txt: mag/my_buf.mag mag/my_and2.mag tcl/verify.tcl | results
	@echo "== magic: DRC and extract   (my_buf, my_and2)"
	@$(MAGIC) -dnull -noconsole tcl/verify.tcl > results/magic.log 2>&1 || true
	@test -f $@ || { echo "   Magic wrote no report. Read results/magic.log"; exit 1; }

results/lvs.done: results/report.txt spice/cells_sch.spice
	@echo "== netgen: are they the circuits you meant?"
	@for c in my_buf my_and2; do \
	  $(NETGEN) -batch lvs "results/$$c.lvs.spice $$c" \
	    "spice/cells_sch.spice $$c" "$(SETUP)" results/$$c.lvs.report \
	    > results/netgen_$$c.log 2>&1 || true; \
	done
	@touch $@

# The simulation is skipped, without failing the build, when the block is not
# finished yet - check.py then reports the layout problems instead of ngspice
# reporting a missing port.
results/and2.log: results/lvs.done src/mktb.py
	@echo "== ngspice: the four rows of the truth table"
	@$(PYTHON) src/mktb.py > results/mktb.log 2>&1 || \
	  echo "   (skipped: $$(tail -1 results/mktb.log))"
	@if [ -f results/and2_tb.spice ]; then \
	  cat results/mktb.log; \
	  cd results && $(NGSPICE) -b and2_tb.spice </dev/null > and2.log 2>&1 || true; \
	else touch $@; fi

layout: results/lvs.done
	@$(PYTHON) src/check.py --layout-only

check: results/and2.log
	@$(PYTHON) src/check.py

sim: results/and2.log
	@grep -E '^x(00|01|10|11)' results/and2.log

edit:
	@cd mag && $(MAGIC) -d X11 $(CELL) &

cells: | results
	@rm -f mag/my_inv.mag mag/my_nand2.mag
	@$(MAGIC) -dnull -noconsole tcl/inv.tcl   > results/cells.log 2>&1 || true
	@$(MAGIC) -dnull -noconsole tcl/nand2.tcl >> results/cells.log 2>&1 || true
	@test -f mag/my_nand2.mag || { echo "nand2.tcl failed - read results/cells.log"; exit 1; }
	@test -f mag/my_inv.mag   || { echo "inv.tcl failed - read results/cells.log"; exit 1; }
	@echo "wrote mag/my_inv.mag and mag/my_nand2.mag"

scaffold: | results
	@rm -f mag/my_buf.mag mag/my_and2.mag
	@$(MAGIC) -dnull -noconsole tcl/scaffold.tcl > results/scaffold.log 2>&1 || true
	@test -f mag/my_buf.mag || { echo "scaffold.tcl failed - read results/scaffold.log"; exit 1; }
	@echo "mag/my_buf.mag and mag/my_and2.mag reset to two placed cells"

ref: | results
	@rm -f solutions/buf_ref.mag solutions/and_ref.mag
	@$(MAGIC) -dnull -noconsole tcl/compose.tcl > results/ref.log 2>&1 || true
	@test -f solutions/and_ref.mag || { echo "compose.tcl failed - read results/ref.log"; exit 1; }
	@echo "wrote solutions/buf_ref.mag and solutions/and_ref.mag"

refcheck: | results
	@echo "== the reference blocks, not yours"
	@AD104_CELLS="buf_ref and_ref" AD104_SRC=../solutions \
	  $(MAGIC) -dnull -noconsole tcl/verify.tcl > results/magic_ref.log 2>&1 || true
	@$(NETGEN) -batch lvs "results/buf_ref.lvs.spice buf_ref" \
	   "spice/cells_sch.spice my_buf" "$(SETUP)" results/buf_ref.lvs.report \
	   > results/netgen_buf_ref.log 2>&1 || true
	@$(NETGEN) -batch lvs "results/and_ref.lvs.spice and_ref" \
	   "spice/cells_sch.spice my_and2" "$(SETUP)" results/and_ref.lvs.report \
	   > results/netgen_and_ref.log 2>&1 || true
	@$(PYTHON) src/check.py --layout-only --suffix _ref

swapped: results/report.txt
	@echo "== netgen: the NAND against a netlist with A and B exchanged"
	@$(NETGEN) -batch lvs "results/my_and2.lvs.spice my_nand2" \
	   "spice/swapped_sch.spice my_nand2" "$(SETUP)" results/swapped.report \
	   > results/netgen_swapped.log 2>&1 || true
	@sed -n '/Subcircuit pins:/,/^Final result/p' results/swapped.report | tail -20
	@echo
	@echo "Read that carefully. 'Netlists match uniquely' means the topology is"
	@echo "right - four devices wired exactly as the schematic says. 'failed pin"
	@echo "matching' means netgen had to swap two names to make it work, so the"
	@echo "labels A and B are on the wrong poly. A NAND is symmetric in its"
	@echo "inputs, so nothing else in the flow will ever notice."

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
