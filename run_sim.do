# 仿真设置脚本 - 保持原始文件名
# 兼容当前项目结构，适用于修改后的流水线架构

# 创建工作库
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# 编译设计文件 - 保持原有的文件路径
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos_stage.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_control_pipeline.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# 启动仿真
vsim -novopt work.tb_opti

# 设置关键监控信号
# 基本控制信号
add wave -divider "基本控制"
add wave -radix binary /tb_opti/clk
add wave -radix binary /tb_opti/rst_n
add wave -radix binary /tb_opti/start
add wave -radix binary /tb_opti/filter_done

# 数据流关键路径
add wave -divider "数据流"
add wave -radix decimal /tb_opti/data_in
add wave -radix binary /tb_opti/data_in_valid
add wave -radix decimal /tb_opti/data_out
add wave -radix binary /tb_opti/data_out_valid
add wave -radix binary /tb_opti/stable_out
add wave -radix unsigned /tb_opti/addr

# 控制模块状态
add wave -divider "控制模块状态"
add wave -radix binary /tb_opti/dut/pipeline_en
add wave -radix unsigned /tb_opti/dut/u_control/stable_counter
add wave -radix binary /tb_opti/dut/u_control/filter_initialized
add wave -radix binary /tb_opti/dut/u_control/first_data_received

# SOS级联数据
add wave -divider "SOS级联数据"
add wave -radix decimal -label "输入数据" /tb_opti/dut/sos_data(0)
add wave -radix decimal -label "SOS1输出" /tb_opti/dut/sos_data(1)
add wave -radix decimal -label "SOS2输出" /tb_opti/dut/sos_data(2)
add wave -radix decimal -label "SOS3输出" /tb_opti/dut/sos_data(3)
add wave -radix decimal -label "SOS4输出" /tb_opti/dut/sos_data(4)
add wave -radix decimal -label "SOS5输出" /tb_opti/dut/sos_data(5)
add wave -radix decimal -label "SOS6输出" /tb_opti/dut/sos_data(6)

# 增益校正监控
add wave -divider "增益校正监控"
add wave -radix binary -label "是否最后级" /tb_opti/dut/sos_stage6/is_last_stage
add wave -radix unsigned -label "乘法选择" /tb_opti/dut/sos_stage6/mult_sel
add wave -radix decimal -label "增益校正值" /tb_opti/dut/sos_stage6/GAIN_CORRECTION
add wave -radix decimal -label "增益校正结果" /tb_opti/dut/sos_stage6/gain_result
add wave -radix decimal -label "校正后输出" /tb_opti/dut/sos_stage6/y_gain_corrected

# 第6级SOS的详细信号(最终级)
add wave -divider "SOS6状态(最终级)"
add wave -radix decimal -label "S1寄存器" /tb_opti/dut/sos_stage6/s1_reg
add wave -radix decimal -label "S2寄存器" /tb_opti/dut/sos_stage6/s2_reg
add wave -radix decimal -label "Y寄存器" /tb_opti/dut/sos_stage6/y_reg
add wave -radix binary -label "处理中" /tb_opti/dut/sos_stage6/processing

# 运行仿真
run 300 ns
echo "复位完成 @ 300ns"

run 1 us
echo "流水线启动 @ 1.3us"

run 20 us
echo "稳定期结束 @ ~21.3us"

run 30 us
echo "数据处理中..."

# 缩放波形显示
wave zoom full