# 编译设计文件 - 路径和文件名均为实际文件名
vlib work
vmap work work

vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# 仿真
vsim -novopt work.tb_opti

# 添加信号监控
add wave -divider {== 顶层信号 ==}
add wave -hex    sim:/tb_opti/clk
add wave -hex    sim:/tb_opti/rst_n
add wave -decimal        sim:/tb_opti/start
add wave -decimal    sim:/tb_opti/data_in
add wave         sim:/tb_opti/data_in_valid
add wave         sim:/tb_opti/filter_done
add wave -decimal        sim:/tb_opti/addr
add wave -decimal    sim:/tb_opti/data_out
add wave         sim:/tb_opti/data_out_valid
add wave         sim:/tb_opti/stable_out


add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_data0
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_data1
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_data2
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_data3
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_data4
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_data5
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_data6

add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_valid0
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_valid1
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_valid2
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_valid3
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_valid4
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_valid5
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos_valid6

# 以及每级w1/w2
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos1/w1
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos1/w2
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos2/w1
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos2/w2
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos3/w1
add wave -position insertpoint -radix decimal sim:/tb_opti/u_top/sos3/w2


run 0
run 1000ns
run 21us

echo "== 仿真已运行至2ms，波形已加载，请观察wave窗口 =="