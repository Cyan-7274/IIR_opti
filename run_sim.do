# 编译所有RTL与tb文件
vlib work
vmap work work

vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# 仿真tb
vsim -novopt work.tb_opti

# 添加常用信号观察
add wave -radix decimal -radix decimal -divider {== 顶层信号 ==}
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

# 观测顶层级联信号
add wave -radix decimal sim:/tb_opti/u_top/sos_data0
add wave -radix decimal sim:/tb_opti/u_top/sos_data1
add wave -radix decimal sim:/tb_opti/u_top/sos_data2
add wave -radix decimal sim:/tb_opti/u_top/sos_data3
add wave -radix decimal sim:/tb_opti/u_top/sos_data4
add wave -radix decimal sim:/tb_opti/u_top/sos_data5
add wave -radix decimal sim:/tb_opti/u_top/sos_data6

add wave -radix decimal sim:/tb_opti/u_top/sos_valid0
add wave -radix decimal sim:/tb_opti/u_top/sos_valid1
add wave -radix decimal sim:/tb_opti/u_top/sos_valid2
add wave -radix decimal sim:/tb_opti/u_top/sos_valid3
add wave -radix decimal sim:/tb_opti/u_top/sos_valid4
add wave -radix decimal sim:/tb_opti/u_top/sos_valid5
add wave -radix decimal sim:/tb_opti/u_top/sos_valid6

add wave -radix decimal sim:/tb_opti/u_top/u_ctrl/pipeline_en

run 22us

# 如需观察更底层信号，可再补充路径