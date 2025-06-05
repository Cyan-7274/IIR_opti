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
add wave    -decimal    sim:/tb_opti/data_in
add wave    -decimal    sim:/tb_opti/data_in_valid
add wave    -decimal    sim:/tb_opti/data_out
add wave    -decimal    sim:/tb_opti/data_out_valid

add wave -divider "SOS0"
add wave    -decimal    sim:/tb_opti/u_top/u_sos0/data_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos0/data_valid_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos0/w0
add wave    -decimal    sim:/tb_opti/u_top/u_sos0/w1
add wave    -decimal    sim:/tb_opti/u_top/u_sos0/w2

add wave    -decimal    sim:/tb_opti/u_top/u_sos0/data_out
add wave    -decimal    sim:/tb_opti/u_top/u_sos0/data_valid_out

# 乘法信号（第一节）
add wave -divider "SOS0_STATE"

# sos0 五个乘法器 a、b、p
add wave -noupdate tb_opti.u_top.u_sos0.u_mul_b0/valid_in
add wave -noupdate tb_opti.u_top.u_sos0.u_mul_b0/valid_out
add wave -noupdate tb_opti.u_top.u_sos0.u_mul_b0/a  tb_opti.u_top.u_sos0.u_mul_b0/b  tb_opti.u_top.u_sos0.u_mul_b0/p
add wave -noupdate tb_opti.u_top.u_sos0.u_mul_b1/a  tb_opti.u_top.u_sos0.u_mul_b1/b  tb_opti.u_top.u_sos0.u_mul_b1/p
add wave -noupdate tb_opti.u_top.u_sos0.u_mul_b2/a  tb_opti.u_top.u_sos0.u_mul_b2/b  tb_opti.u_top.u_sos0.u_mul_b2/p
add wave -noupdate tb_opti.u_top.u_sos0.u_mul_a1/a  tb_opti.u_top.u_sos0.u_mul_a1/b  tb_opti.u_top.u_sos0.u_mul_a1/p
add wave -noupdate tb_opti.u_top.u_sos0.u_mul_a2/a  tb_opti.u_top.u_sos0.u_mul_a2/b  tb_opti.u_top.u_sos0.u_mul_a2/p

add wave -divider "SOS_CHAIN"
add wave    -decimal    sim:/tb_opti/u_top/u_sos1/data_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos1/data_valid_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos1/data_out
add wave    -decimal    sim:/tb_opti/u_top/u_sos1/data_valid_out

add wave    -decimal    sim:/tb_opti/u_top/u_sos2/data_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos2/data_valid_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos2/data_out
add wave    -decimal    sim:/tb_opti/u_top/u_sos2/data_valid_out

add wave    -decimal    sim:/tb_opti/u_top/u_sos3/data_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos3/data_valid_in
add wave    -decimal    sim:/tb_opti/u_top/u_sos3/data_out
add wave    -decimal    sim:/tb_opti/u_top/u_sos3/data_valid_out



run 22us