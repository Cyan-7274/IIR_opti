# 清理旧库
if {[file exists work]} {
    vdel -all
}
vlib work

# 编译
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# 启动仿真
vsim work.tb_opti

# ====== 全局与顶层IO ======
add wave -divider "Global Control"
add wave -noupdate -radix hex tb_opti/clk
add wave -noupdate -radix hex tb_opti/rst_n
add wave -noupdate -radix hex tb_opti/u_top/start
add wave -noupdate -radix hex tb_opti/u_top/data_in_valid
add wave -noupdate -radix hex tb_opti/u_top/pipeline_en

add wave -divider "Top I/O"
add wave -noupdate -radix signed tb_opti/u_top/data_in
add wave -noupdate -radix signed tb_opti/u_top/data_out
add wave -noupdate -radix hex tb_opti/u_top/data_out_valid
add wave -noupdate -radix hex tb_opti/u_top/filter_done

# ====== u_sos0端口级信号 ======
add wave -divider "SOS0 Pipe/Delay"
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/valid_pipe
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/y1_pipe
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/y2_pipe

# ====== 乘法器端口信号（全部为module端口） ======
add wave -divider "First SOS Multipliers"
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b0_x/valid_in
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b0_x/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b1_x/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b1_x/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b1_x/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b1_x/valid_in
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b1_x/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b2_x/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b2_x/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b2_x/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b2_x/valid_in
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b2_x/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a1_y/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a1_y/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a1_y/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_a1_y/valid_in
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_a1_y/valid_out

add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a2_y/a
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a2_y/b
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_a2_y/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_a2_y/valid_in
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_a2_y/valid_out

add wave -position insertpoint sim:/tb_opti/u_top/u_sos0/acc_sum
add wave -position insertpoint sim:/tb_opti/u_top/u_sos0/data_out
add wave -position insertpoint sim:/tb_opti/u_top/u_sos0/data_valid_out
add wave -position insertpoint sim:/tb_opti/u_top/u_sos0/y1
add wave -position insertpoint sim:/tb_opti/u_top/u_sos0/y2

# ====== 运行 ======
run 22 us