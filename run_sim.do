# 编译RTL和testbench
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

if {[file exists work] == 0} {
    vlib work
}
vsim -novopt -t 1ns work.tb_opti

# -------------------------------------------------
# run_sim.do : IIR DF2T SOS 全流水线仿真批处理脚本【新版】
# -------------------------------------------------
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

if {[file exists work] == 0} {
    vlib work
}
vsim -novopt -t 1ns work.tb_opti


# 时钟/计数
add wave -divider "STATE"
add wave    -decimal    sim:/tb_opti/cycle_cnt
add wave    -decimal    sim:/tb_opti/sample_cnt

add wave -divider "TOP"
add wave    -hex    sim:/tb_opti/data_in
add wave    -hex    sim:/tb_opti/data_in_valid
add wave    -hex    sim:/tb_opti/data_out
add wave    -hex    sim:/tb_opti/data_out_valid

add wave -divider "SOS0"
add wave    -hex    sim:/tb_opti/u_sos0/data_in
add wave    -hex    sim:/tb_opti/u_sos0/data_valid_in
add wave    -hex    sim:/tb_opti/u_sos0/w0
add wave    -hex    sim:/tb_opti/u_sos0/w1
add wave    -hex    sim:/tb_opti/u_sos0/w2
add wave    -hex    sim:/tb_opti/u_sos0/data_out
add wave    -hex    sim:/tb_opti/u_sos0/data_valid_out

# 乘法信号（第一节）
add wave -divider "SOS0_STATE"
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b0_w0/b
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b1_w1/b
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b2_w2/b
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b0_w0/p
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b1_w1/p
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b2_w2/p
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b0_w0/a
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b1_w1/a
add wave    -hex    sim:/tb_opti/u_sos0/u_mul_b2_w2/a

add wave -divider "SOS_CHAIN"
add wave    -hex    sim:/tb_opti/u_sos1/data_in
add wave    -hex    sim:/tb_opti/u_sos1/data_valid_in
add wave    -hex    sim:/tb_opti/u_sos1/data_out
add wave    -hex    sim:/tb_opti/u_sos1/data_valid_out

add wave    -hex    sim:/tb_opti/u_sos2/data_in
add wave    -hex    sim:/tb_opti/u_sos2/data_valid_in
add wave    -hex    sim:/tb_opti/u_sos2/data_out
add wave    -hex    sim:/tb_opti/u_sos2/data_valid_out

add wave    -hex    sim:/tb_opti/u_sos3/data_in
add wave    -hex    sim:/tb_opti/u_sos3/data_valid_in
add wave    -hex    sim:/tb_opti/u_sos3/data_out
add wave    -hex    sim:/tb_opti/u_sos3/data_valid_out



run 22us




run 22us