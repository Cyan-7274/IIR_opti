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

# ========== 监控sos级联之间的输入输出 ==========
add wave -radix decimal -divider {== SOS级联信号 ==}
add wave -radix decimal sim:/tb_opti/u_top/sos_data
add wave -radix decimal sim:/tb_opti/u_top/sos_valid

# ========== 监控每一级SOS内部关键信号 ==========
add wave -radix decimal -divider {== SOS0内部反馈 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/y1
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/y2
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/x_delay
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/x_delay[0]
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/x_delay[1]

add wave -radix decimal -divider {== SOS1内部反馈 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/y1
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/y2
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/x_delay
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/x_delay[0]
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/x_delay[1]

add wave -radix decimal -divider {== SOS2内部反馈 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/y1
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/y2
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/x_delay
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/x_delay[0]
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/x_delay[1]

add wave -radix decimal -divider {== SOS3内部反馈 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/y1
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/y2
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/x_delay
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/x_delay[0]
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/x_delay[1]

# ========== 监控每一级SOS的乘法器输出 ==========
add wave -radix decimal -divider {== SOS0乘法器输出 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/p_b0_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/p_b1_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/p_b2_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/p_a1_y
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/p_a2_y

add wave -radix decimal -divider {== SOS1乘法器输出 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/p_b0_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/p_b1_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/p_b2_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/p_a1_y
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/p_a2_y

add wave -radix decimal -divider {== SOS2乘法器输出 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/p_b0_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/p_b1_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/p_b2_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/p_a1_y
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/p_a2_y

add wave -radix decimal -divider {== SOS3乘法器输出 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/p_b0_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/p_b1_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/p_b2_x
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/p_a1_y
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/p_a2_y

# ========== 监控每级SOS的累加输出 ==========
add wave -radix decimal -divider {== SOS累加输出 ==}
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(0).u_sos/acc_sum
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(1).u_sos/acc_sum
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(2).u_sos/acc_sum
add wave -radix decimal sim:/tb_opti/u_top/gen_coeff_sos(3).u_sos/acc_sum

# ========== 仿真运行 ==========
run 25us

# 仿真结束后tb_dut_output.hex将用于matlab比对