
# clock constraints,320MHz
create_clock -name clk -period 3.125 [get_ports clk]

# rst_n false path
set_false_path -form [get_ports rst_n]

# input_output delay
set_input_delay 0.2 -clock clk [remove_from_collection[all_inputs][get_ports clk]
set_output_delay 0.2 -clock clk [all_outputs]
