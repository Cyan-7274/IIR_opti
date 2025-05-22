# 编译所有RTL与tb文件（绝对路径保留）
vlib work
vmap work work

vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# 启动仿真
vsim -novopt work.tb_opti

# ========== 顶层主要信号（十进制） ==========
add wave -radix decimal -divider {== 顶层输入输出 ==}
add wave -radix decimal sim:/tb_opti/clk
add wave -radix decimal sim:/tb_opti/rst_n
add wave -radix decimal sim:/tb_opti/start
add wave -radix decimal sim:/tb_opti/data_in
add wave -radix decimal sim:/tb_opti/data_in_valid
add wave -radix decimal sim:/tb_opti/filter_done
add wave -radix decimal sim:/tb_opti/addr
add wave -radix decimal sim:/tb_opti/data_out
add wave -radix decimal sim:/tb_opti/data_out_valid
add wave -radix decimal sim:/tb_opti/stable_out

add wave -radix decimal sim:/tb_opti/data_in
add wave -radix decimal sim:/tb_opti/data_out


# ========== 仿真运行 ==========
run 25us

# 仿真结束后tb_dut_output.hex将用于matlab比对