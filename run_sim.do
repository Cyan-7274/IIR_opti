# run_sim.do -- ModelSim/QuestaSim batch simulation script for opti IIR项目

# 1. 清理旧库
if {[file exists work]} {
    vdel -all
}
vlib work

# 2. 编译RTL和testbench
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"
# 3. 启动仿真
vsim work.tb_opti

# 输入信号
add wave -noupdate -radix signed tb_opti/u_top/data_in

# 第一级sos的五路乘法器（完全按你的树状图路径）
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b0_x/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b1_x/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b1_x/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b1_x/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b1_x/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b2_x/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b2_x/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b2_x/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b2_x/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a1_y/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a1_y/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a1_y/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_a1_y/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a2_y/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a2_y/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a2_y/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_a2_y/valid_out

# 如需观察中间debug_sum信号
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/debug_sum
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b1_x/debug_sum
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b2_x/debug_sum
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a1_y/debug_sum
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a2_y/debug_sum

run 22 us

# quit -force