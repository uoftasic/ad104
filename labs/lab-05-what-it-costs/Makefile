# AD104 Lab 05 - what your drawing costs
#
#   make          extract both cells with parasitics and compare them  (~30 s)
#   make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
#                 copy YOUR Lab 03 cell in and compare that instead
#   make table    re-print the comparison from results already on disk
#   make clean    delete results/
#
# You run the same extraction yourself in Magic (Parts 2 and 3 of the lab). That leaves
# .ext files in mag/, and ext2spice would read those before the fresh ones in results/,
# so the extraction here deletes them first.

export PDK      := sky130A
export PDK_ROOT ?= /foss/pdks

MAGIC   ?= magic
NGSPICE ?= ngspice
PYTHON  ?= python3
MAG     ?=

.PHONY: all check table mine clean

all: check

results:
	@mkdir -p results

results/geom.txt: mag/my_inv.mag tcl/pex.tcl | results
	@echo "== magic: extract both cells, every capacitance kept"
	@rm -f mag/*.ext
	@$(MAGIC) -dnull -noconsole tcl/pex.tcl > results/magic.log 2>&1 || true
	@test -f $@ || { echo "   Magic wrote no report. Read results/magic.log"; exit 1; }

results/fo4.log: results/geom.txt spice/fo4.spice src/mkfo4.py src/ports.py
	@echo "== ngspice: fan-out-of-4 delay, both cells, one deck"
	@$(PYTHON) src/mkfo4.py
	@cd results && $(NGSPICE) -b fo4.spice </dev/null > fo4.log 2>&1 || true

results/ring.log: results/geom.txt src/mkring.py src/ports.py
	@echo "== ngspice: two 31-stage ring oscillators"
	@$(PYTHON) src/mkring.py
	@cd results && $(NGSPICE) -b ring.spice </dev/null > ring.log 2>&1 || true

check: results/fo4.log results/ring.log
	@$(PYTHON) src/check.py

table:
	@$(PYTHON) src/check.py

mine:
	@test -n "$(MAG)" || { echo "usage: make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag"; exit 2; }
	@test -f "$(MAG)" || { echo "no such file: $(MAG)"; exit 2; }
	@cp "$(MAG)" mag/my_inv.mag
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "copied $(MAG) into mag/my_inv.mag - now run make"

clean:
	@rm -rf results && mkdir -p results && touch results/.gitkeep
	@echo "cleaned"
