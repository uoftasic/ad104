# AD104 Lab 04 - a buffer and an AND gate, out of cells you drew
#
#   make           DRC + LVS both blocks, then simulate the AND    (~15 s)
#   make layout    just the DRC and LVS part
#   make gen       DRC + LVS the generated inverter, mag/my_inv_gen.mag
#   make cells     rebuild mag/my_inv.mag and mag/my_nand2.mag
#   make scaffold  throw your work away, back to two placed cells
#   make ref       build the reference blocks and the reference generated
#                  inverter in solutions/
#   make refcheck  run every check against the references
#   make clean     delete results/
#
# You open the cells yourself: cd mag, then magic -d X11 my_buf &

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC   ?= magic
NETGEN  ?= netgen
NGSPICE ?= ngspice
PYTHON  ?= python3
SETUP   := $(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl

# When you extract in Magic yourself, it leaves .ext files beside your cells in mag/.
# ext2spice reads a cell's .ext from beside its .mag before the fresh one the check
# writes in results/, so a leftover one would make the check report the layout as it
# was when you last extracted it. Every check deletes them first.
STALE   := mag/*.ext solutions/*.ext

.PHONY: all check layout gen cells scaffold ref refcheck clean

all: check

results:
	@mkdir -p results

results/report.txt: mag/my_buf.mag mag/my_and2.mag tcl/verify.tcl | results
	@echo "== magic: DRC and extract   (my_buf, my_and2)"
	@rm -f $(STALE)
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

# The generated inverter. Magic reruns every time, because the device cells
# beside my_inv_gen.mag change name whenever a device option changes.
gen: | results
	@test -f mag/my_inv_gen.mag || { echo "mag/my_inv_gen.mag does not exist yet. You start it in Part 7 of the lab and save it in Part 9."; exit 1; }
	@rm -f results/gen_report.txt results/my_inv_gen.lvs.spice results/my_inv_gen.lvs.report
	@echo "== magic: DRC and extract   (my_inv_gen)"
	@rm -f $(STALE)
	@$(MAGIC) -dnull -noconsole tcl/verify_gen.tcl > results/magic_gen.log 2>&1 || true
	@test -f results/gen_report.txt || { echo "   Magic wrote no report. Read results/magic_gen.log"; exit 1; }
	@echo "== netgen: is it the inverter?"
	@$(NETGEN) -batch lvs "results/my_inv_gen.lvs.spice my_inv_gen" \
	   "spice/my_inv_gen_sch.spice my_inv_gen" "$(SETUP)" results/my_inv_gen.lvs.report \
	   > results/netgen_gen.log 2>&1 || true
	@$(PYTHON) src/check_gen.py

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
	@rm -f solutions/inv_gen_ref.mag solutions/sky130_fd_pr__*.mag
	@$(MAGIC) -dnull -noconsole tcl/inv_gen.tcl > results/ref_gen.log 2>&1 || true
	@test -f solutions/inv_gen_ref.mag || { echo "inv_gen.tcl failed - read results/ref_gen.log"; exit 1; }
	@echo "wrote solutions/inv_gen_ref.mag and its device cells"

refcheck: | results
	@echo "== the reference blocks, not yours"
	@rm -f $(STALE)
	@AD104_CELLS="buf_ref and_ref" AD104_SRC=../solutions \
	  $(MAGIC) -dnull -noconsole tcl/verify.tcl > results/magic_ref.log 2>&1 || true
	@$(NETGEN) -batch lvs "results/buf_ref.lvs.spice buf_ref" \
	   "spice/cells_sch.spice my_buf" "$(SETUP)" results/buf_ref.lvs.report \
	   > results/netgen_buf_ref.log 2>&1 || true
	@$(NETGEN) -batch lvs "results/and_ref.lvs.spice and_ref" \
	   "spice/cells_sch.spice my_and2" "$(SETUP)" results/and_ref.lvs.report \
	   > results/netgen_and_ref.log 2>&1 || true
	@$(PYTHON) src/check.py --layout-only --suffix _ref
	@echo "== the reference generated inverter, not yours"
	@rm -f $(STALE)
	@rm -f results/gen_report.txt results/inv_gen_ref.lvs.spice results/inv_gen_ref.lvs.report
	@AD104_CELL=inv_gen_ref AD104_SRC=../solutions \
	  $(MAGIC) -dnull -noconsole tcl/verify_gen.tcl > results/magic_gen_ref.log 2>&1 || true
	@$(NETGEN) -batch lvs "results/inv_gen_ref.lvs.spice inv_gen_ref" \
	   "spice/my_inv_gen_sch.spice my_inv_gen" "$(SETUP)" results/inv_gen_ref.lvs.report \
	   > results/netgen_gen_ref.log 2>&1 || true
	@$(PYTHON) src/check_gen.py --cell inv_gen_ref

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
