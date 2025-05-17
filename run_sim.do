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

# ========== 级联各级数据/valid信号 ==========
add wave -radix decimal -divider {== 各级sos输入/输出 ==}
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

# ========== 控制模块关键信号 ==========
add wave -radix decimal -divider {== 控制信号 ==}
add wave -radix decimal sim:/tb_opti/u_top/u_ctrl/pipeline_en
add wave -radix decimal sim:/tb_opti/u_top/u_ctrl/filter_done
add wave -radix decimal sim:/tb_opti/u_top/u_ctrl/stable_out
add wave -radix decimal sim:/tb_opti/u_top/u_ctrl/addr
add wave -radix decimal sim:/tb_opti/u_top/u_ctrl/data_out
add wave -radix decimal sim:/tb_opti/u_top/u_ctrl/data_out_valid

# ========== 可选：乘法器/反馈内部节点（如进一步debug可解注释） ==========
# add wave -radix decimal sim:/tb_opti/u_top/sos1/s1
# add wave -radix decimal sim:/tb_opti/u_top/sos1/s2
# add wave -radix decimal sim:/tb_opti/u_top/sos2/s1
# add wave -radix decimal sim:/tb_opti/u_top/sos2/s2

# ========== 仿真运行 ==========
run 25us

# 如需更长仿真或更详细波形，可适当调整run时长或添加更深信号路径