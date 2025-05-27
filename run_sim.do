# 清理
if {[file exists work]} { vdel -all }
vlib work

# 编译RTL与tb（路径根据实际情况调整）
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# 仿真
vsim work.tb_opti


# 加入输入及三个乘法器的p、valid信号
add wave -position insertpoint sim:/u_top/u_sos0/data_in
add wave -position insertpoint sim:/u_top/u_sos0/data_out  
add wave -position insertpoint sim:/u_top/u_sos0/y1_pipe
add wave -position insertpoint sim:/u_top/u_sos0/y2_pipe
add wave -position insertpoint sim:/u_top/u_sos0/acc_sum
add wave -position insertpoint sim:/u_top/u_sos0/mul_a1_y/a
add wave -position insertpoint sim:/u_top/u_sos0/mul_a2_y/a
add wave -position insertpoint sim:/u_top/u_sos0/mul_a1_y/b
add wave -position insertpoint sim:/u_top/u_sos0/mul_a2_y/b
add wave -position insertpoint sim:/u_top/u_sos0/mul_a1_y/p
add wave -position insertpoint sim:/u_top/u_sos0/mul_a2_y/p
add wave -position insertpoint sim:/u_top/u_sos0/mul_a1_y/valid_out
add wave -position insertpoint sim:/u_top/u_sos0/mul_a2_y/valid_out
add wave -position insertpoint sim:/u_top/u_sos0/data_in
add wave -position insertpoint sim:/u_top/u_sos0/data_valid_in


# 若模块有更复杂pipeline，可继续补充


run 30 us
