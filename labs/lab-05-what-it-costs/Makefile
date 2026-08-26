# AD104 Lab 05 - what your drawing costs
#
#   make          extract both cells with parasitics and compare them  (~2 min)
#   make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
#                 copy YOUR Lab 03 cell in and compare that instead
#   make pex      just the extraction
#   make table    re-print the comparison from results already on disk
#   make caps     print both parasitic netlists side by side
#   make clean    delete results/

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC   ?= magic
NGSPICE ?= ngspice
PYTHON  ?= python3
MAG     ?=

.PHONY: all check pex sim table caps mine clean

all: check

results:
	@mkdir -p results

results/geom.txt: mag/my_inv.mag tcl/pex.tcl | results
	@echo "== magic: extract both cells, every capacitance kept"
	@$(MAGIC) -dnull -noconsole tcl/pex.tcl > results/magic.log 2>&1 || true
	@test -f $@ || { echo "   Magic wrote no report. Read results/magic.log"; exit 1; }

results/fo4.log: results/geom.txt spice/fo4.spice
	@echo "== ngspice: fan-out-of-4 delay, both cells, one deck"
	@cp spice/fo4.spice results/fo4.spice
	@cd results && $(NGSPICE) -b fo4.spice </dev/null > fo4.log 2>&1 || true

results/ring.log: results/geom.txt src/mkring.py
	@echo "== ngspice: two 31-stage ring oscillators"
	@$(PYTHON) src/mkring.py
	@cd results && $(NGSPICE) -b ring.spice </dev/null > ring.log 2>&1 || true

pex: results/geom.txt

check: results/fo4.log results/ring.log
	@$(PYTHON) src/check.py

table:
	@$(PYTHON) src/check.py

caps: results/geom.txt
	@echo "--- yours ---"       && cat results/my_inv.pex.spice
	@echo "--- the foundry's ---" && cat results/sky130_fd_sc_hd__inv_1.pex.spice

mine:
	@test -n "$(MAG)" || { echo "usage: make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag"; exit 2; }
	@test -f "$(MAG)" || { echo "no such file: $(MAG)"; exit 2; }
	@cp "$(MAG)" mag/my_inv.mag
	@sed -i '1,6s/^\([a-zA-Z_][a-zA-Z0-9_]*\)$$/my_inv/' mag/my_inv.mag 2>/dev/null || true
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "copied $(MAG) into mag/my_inv.mag - now run make"

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
