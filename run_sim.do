# -------------------------------------------------
# run_ -hex sim.do : IIR DF2T SOS 全流水线仿真批处理脚本
# -------------------------------------------------
# 编译RTL和testbench

vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# 清理上次仿真
if {[file exists work] == 0} {
    vlib work
}
# 重新elab
vsim -novopt -t 1ns work.tb_opti

# 添加关键信号到波形窗口
add wave -divider "SOS0"

add wave    -decimal    sim:/tb_opti/cycle_cnt
add wave    -decimal    sim:/tb_opti/sample_cnt
add wave    -decimal    sim:/tb_opti/u_top/data_in
add wave    -decimal    sim:/tb_opti/u_top/data_in_valid

# 顶层输入输出
add wave -divider "TOP"
add wave    -hex    sim:/tb_opti/data_in
add wave    -hex    sim:/tb_opti/data_in_valid
add wave    -hex    sim:/tb_opti/data_out
add wave    -hex    sim:/tb_opti/data_out_valid

# SOS0链路
add wave -divider "SOS0"
add wave    -hex    sim:/tb_opti/u_top/u_sos0/data_in
add wave    -hex    sim:/tb_opti/u_top/u_sos0/data_valid_in
add wave    -hex    sim:/tb_opti/u_top/u_sos0/x_pipe(0)
add wave    -hex    sim:/tb_opti/u_top/u_sos0/w0
add wave    -hex    sim:/tb_opti/u_top/u_sos0/w1
add wave    -hex    sim:/tb_opti/u_top/u_sos0/w2
add wave    -hex    sim:/tb_opti/u_top/u_sos0/w0_next
add wave    -hex    sim:/tb_opti/u_top/u_sos0/acc_sum_w0
add wave    -hex    sim:/tb_opti/u_top/u_sos0/p_b0_w0
add wave    -hex    sim:/tb_opti/u_top/u_sos0/p_b1_w1
add wave    -hex    sim:/tb_opti/u_top/u_sos0/p_b2_w2
add wave    -hex    sim:/tb_opti/u_top/u_sos0/p_a1_w1
add wave    -hex    sim:/tb_opti/u_top/u_sos0/p_a2_w2
add wave    -hex    sim:/tb_opti/u_top/u_sos0/vld_pipe

# 级联信号
add wave    -hex    sim:/tb_opti/u_top/u_sos1/data_in
add wave    -hex    sim:/tb_opti/u_top/u_sos1/data_valid_in
add wave    -hex    sim:/tb_opti/u_top/u_sos1/data_out
add wave    -hex    sim:/tb_opti/u_top/u_sos1/data_valid_out

add wave    -hex    sim:/tb_opti/u_top/u_sos2/data_in
add wave    -hex    sim:/tb_opti/u_top/u_sos2/data_valid_in
add wave    -hex    sim:/tb_opti/u_top/u_sos2/data_out
add wave    -hex    sim:/tb_opti/u_top/u_sos2/data_valid_out

add wave    -hex    sim:/tb_opti/u_top/u_sos3/data_in
add wave    -hex    sim:/tb_opti/u_top/u_sos3/data_valid_in
add wave    -hex    sim:/tb_opti/u_top/u_sos3/data_out
add wave    -hex    sim:/tb_opti/u_top/u_sos3/data_valid_out



# 跑仿真
run 22us
