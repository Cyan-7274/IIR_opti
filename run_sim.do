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
add wave -radix decimal -position insertpoint sim:/clk
add wave -radix decimal -position insertpoint sim:/cycle_cnt
add wave -radix decimal -position insertpoint sim:/rst_n
add wave -radix decimal -position insertpoint sim:/start
add wave -radix decimal -position insertpoint sim:/u_top/data_in
add wave -radix decimal -position insertpoint sim:/u_top/data_in_valid
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/data_in
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/data_valid_in

add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b2_x/valid_in
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b1_x/valid_in
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b0_x/valid_in
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b2_x/b
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b1_x/b
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b0_x/b

add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b2_x/p
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b1_x/p
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b0_x/p
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b2_x/valid_out
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b1_x/valid_out
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_b0_x/valid_out

add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/acc_sum
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/data_valid_out
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/data_out  

add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a1_y/valid_in
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a2_y/valid_in

add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a1_y/b
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a2_y/b

add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a1_y/p
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a2_y/p
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a1_y/valid_out
add wave -radix decimal -position insertpoint sim:/u_top/u_sos0/mul_a2_y/valid_out


run 25 us
