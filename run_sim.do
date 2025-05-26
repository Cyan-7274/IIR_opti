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

# 只关注最关键的信号
add wave -divider "Global Control"
add wave -noupdate -radix hex tb_opti/clk
add wave -noupdate -radix hex tb_opti/rst_n

add wave -divider "Input"
add wave -noupdate -radix signed tb_opti/u_top/data_in

add wave -divider "mul_b0_x pipeline"
# 12级流水线和输出
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/a_pipe
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/b_pipe
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/acc_pipe
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b0_x/valid_pipe
add wave -noupdate -radix signed tb_opti/u_top/u_sos0/mul_b0_x/p
add wave -noupdate -radix hex    tb_opti/u_top/u_sos0/mul_b0_x/valid_out

# 如需其它信号，请告知

run 22 us