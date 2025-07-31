# Script file for constraining the top file

set design "opti_top"
set rpt_file "./report.rpt"

current_design $design


# -- Synthesis --
compile_ultra -timing

# -- Import gate netlist and SDF
write -format verilog -hierarchy -output ./netlist/opti_top_syn.v
write_sdf ./netlist/opti_top_syn.sdf

# -- Report --
source ./scripts/report.tcl
