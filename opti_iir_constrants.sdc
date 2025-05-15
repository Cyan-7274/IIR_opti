# 高速IIR滤波器时序约束文件
# 简化版 - 移除可能导致语法问题的约束

# 基本时钟定义
create_clock -name clk -period 8.138 [get_ports clk]

# 复位路径约束
set_false_path -from [get_ports rst_n]

# 输入/输出延迟约束
set_input_delay 1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1.0 -clock clk [all_outputs]

# 简化的多周期路径约束 - 使用更通用的路径表达式
set_multicycle_path -setup 3 -from [get_cells -hierarchical *pipe0*] -to [get_cells -hierarchical *result*] 
set_multicycle_path -hold 2 -from [get_cells -hierarchical *pipe0*] -to [get_cells -hierarchical *result*]