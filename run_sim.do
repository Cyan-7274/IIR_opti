# ==========================================================
# run_sim.do - Modelsim仿真脚本（信号顺序与清理优化）
# 适配最新版RTL与tb_opti，含关键节点信号波形观测
# ==========================================================

# ========== 清理与创建work库 ==========
if {[file exists work]} {
    file delete -force work
}
vlib work
vmap work work

# 编译RTL和Testbench
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

vsim work.tb_opti

# 1. 时钟/计数类信号
add wave -divider "==== Testbench Clocks & 计数 ===="
add wave -radix dec /tb_opti/clk
add wave -radix dec /tb_opti/rst_n
add wave -radix dec /tb_opti/sample_cnt
add wave -radix dec /tb_opti/cycle_cnt
add wave -radix dec /tb_opti/samp_cnt
add wave -radix dec /tb_opti/input_idx

# 2. 第一节SOS输入/输出/valid（推荐最先关注）
add wave -divider "==== SOS_STAGE0 输入输出 ===="
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/data_in
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/valid_in
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/data_out
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/valid_out



# 4. 第一节SOS五个乘法器（a、b、p、valid，名称请根据RTL实际补全）
add wave -divider "==== SOS_STAGE0 乘法器 ===="

add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_b0/valid_in
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_b0/a
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_b0/b_s1

add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_b0/p
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_b1/p
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_b2/p
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_a1/p
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/u_a2/p
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/w1
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/w2
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[0\]/u_sos/data_out


# 5. 其余SOS节输入/输出/valid（便于级联观察）
add wave -divider "==== SOS_STAGE1 输入输出 ===="
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[1\]/u_sos/data_in
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[1\]/u_sos/valid_in
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[1\]/u_sos/data_out
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[1\]/u_sos/valid_out

add wave -divider "==== SOS_STAGE2 输入输出 ===="
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[2\]/u_sos/data_in
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[2\]/u_sos/valid_in
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[2\]/u_sos/data_out
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[2\]/u_sos/valid_out

add wave -divider "==== SOS_STAGE3 输入输出 ===="
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[3\]/u_sos/data_in
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[3\]/u_sos/valid_in
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[3\]/u_sos/data_out
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[3\]/u_sos/valid_out

add wave -divider "==== SOS_STAGE4 输入输出 ===="
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[4\]/u_sos/data_in
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[4\]/u_sos/valid_in
add wave -radix dec /tb_opti/u_top/SOS_CHAIN\[4\]/u_sos/data_out
add wave -radix bin /tb_opti/u_top/SOS_CHAIN\[4\]/u_sos/valid_out

# run
run 22 us
wave zoom range 130ns 230ns