# 高速IIR滤波器时序约束文件（Q1.14/80MHz适配）

# 主时钟周期=12.5ns，80MHz
create_clock -name clk -period 12.5 [get_ports clk]

# 复位为异步false path
set_false_path -from [get_ports rst_n]

# 输入/输出延迟（1ns，适应通用板级IO时序）
set_input_delay 1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1.0 -clock clk [all_outputs]

# 可选：乘法器、流水线多周期路径约束（如有明显慢路径可指定cell名，否则建议综合后用时序报告微调）
# set_multicycle_path -setup 3 -from [get_cells -hierarchical *mul*] -to [get_cells -hierarchical *sos*] 
# set_multicycle_path -hold 2 -from [get_cells -hierarchical *mul*] -to [get_cells -hierarchical *sos*]

# 典型综合流程建议：先用基本时钟/IO约束，后续根据实际时序报告再补充多周期/例外路径。