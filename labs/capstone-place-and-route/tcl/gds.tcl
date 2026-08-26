# Capstone — write the thing a foundry would actually accept.
#
# GDSII is the handoff format. Everything before this point - .mag files, DRC,
# LVS, the extracted netlist - is you convincing yourself. This file is the
# part that leaves the building.
cd results
addpath ../mag
addpath $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/mag
load datapath
select top cell
gds write datapath.gds
puts "wrote results/datapath.gds"
quit -noprompt
