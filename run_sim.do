# ==================== run_sim.do - ModelSim仿真脚本 ====================
# 适配 opi_xxx 命名风格，tb_opti 顶层，波形输出所有关键信号
# 编译路径已按需填写，tb_opti为仿真顶层

# --- 编译所有RTL和Testbench ---
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_multiplier.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_coeffs.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_sos.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/rtl/optimized/opti_top.v"
vlog -work work "D:/A_Hesper/IIRfilter/qts/tb/tb_opti.v"

# --- 仿真并启动波形 ---
vsim work.tb_opti

# --- 添加顶层及全部关键信号到波形窗口 ---
# 顶层信号
add wave -divider "=== TB Top ==="
add wave -hex  sim:/tb_opti/clk
add wave -hex  sim:/tb_opti/rst_n
add wave -hex  sim:/tb_opti/data_in
add wave -hex  sim:/tb_opti/data_in_valid
add wave -hex  sim:/tb_opti/data_out
add wave -hex  sim:/tb_opti/data_out_valid

add wave -divider "=== DUT Internal: opti_top ==="
add wave -hex  sim:/tb_opti/u_top/clk
add wave -hex  sim:/tb_opti/u_top/rst_n
add wave -hex  sim:/tb_opti/u_top/data_in
add wave -hex  sim:/tb_opti/u_top/valid_in
add wave -hex  sim:/tb_opti/u_top/data_out
add wave -hex  sim:/tb_opti/u_top/valid_out

# ---- 关键中间节点（可根据opti_top内部信号名增减） ----
# 以下为常见信号名，如有不同请根据实际RTL调整
add wave -divider "=== SOS Stages & Nodes ==="
add wave -hex  sim:/tb_opti/u_top/sos_out
add wave -hex  sim:/tb_opti/u_top/sos_valid

add wave -divider "=== SOS0内部 ==="
add wave -hex  sim:/tb_opti/u_top/u_sos0/x_z1
add wave -hex  sim:/tb_opti/u_top/u_sos0/x_z2
add wave -hex  sim:/tb_opti/u_top/u_sos0/y_z1
add wave -hex  sim:/tb_opti/u_top/u_sos0/y_z2
add wave -hex  sim:/tb_opti/u_top/u_sos0/data_out
add wave -hex  sim:/tb_opti/u_top/u_sos0/acc_b
add wave -hex  sim:/tb_opti/u_top/u_sos0/acc_b2
add wave -hex  sim:/tb_opti/u_top/u_sos0/acc_a

add wave -divider "=== SOS1内部 ==="
add wave -hex  sim:/tb_opti/u_top/u_sos1/x_z1
add wave -hex  sim:/tb_opti/u_top/u_sos1/x_z2
add wave -hex  sim:/tb_opti/u_top/u_sos1/y_z1
add wave -hex  sim:/tb_opti/u_top/u_sos1/y_z2
add wave -hex  sim:/tb_opti/u_top/u_sos1/data_out

add wave -divider "=== SOS2内部 ==="
add wave -hex  sim:/tb_opti/u_top/u_sos2/x_z1
add wave -hex  sim:/tb_opti/u_top/u_sos2/x_z2
add wave -hex  sim:/tb_opti/u_top/u_sos2/y_z1
add wave -hex  sim:/tb_opti/u_top/u_sos2/y_z2
add wave -hex  sim:/tb_opti/u_top/u_sos2/data_out

add wave -divider "=== SOS3内部 ==="
add wave -hex  sim:/tb_opti/u_top/u_sos3/x_z1
add wave -hex  sim:/tb_opti/u_top/u_sos3/x_z2
add wave -hex  sim:/tb_opti/u_top/u_sos3/y_z1
add wave -hex  sim:/tb_opti/u_top/u_sos3/y_z2
add wave -hex  sim:/tb_opti/u_top/u_sos3/data_out

# --- 关键乘法器节点（可选，若层级较深可用“add wave -r”递归添加） ---
add wave -divider "=== 乘法器/有效信号 ==="
add wave -hex  sim:/tb_opti/u_top/u_sos0/mult0_p
add wave -hex  sim:/tb_opti/u_top/u_sos0/mult1_p
add wave -hex  sim:/tb_opti/u_top/u_sos0/mult2_p
add wave -hex  sim:/tb_opti/u_top/u_sos0/mult3_p
add wave -hex  sim:/tb_opti/u_top/u_sos0/mult4_p
add wave -hex  sim:/tb_opti/u_top/u_sos0/valid_out

# --- 可根据实际RTL结构继续添加其他信号 ---
# 例如 add wave -hex  sim:/tb_opti/u_top/u_sos0/u_mult0/p

# --- 启动仿真并设置常用时间窗口 ---
run 40us     ;# 典型仿真时间，可根据测试向量长度调整

# --- 可选：设置波形窗口显示格式 ---
configure wave -signalnamewidth 2
configure wave -timelineunits ns
configure wave -starttime 1ns -endtime 30us