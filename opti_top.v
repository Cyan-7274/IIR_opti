// 修正版opti_top.v - 使用正确的SOS节点顺序并应用增益校正
// 保持原始模块名称，确保与项目兼容
module opti_top (
    input  wire        clk,             // 时钟
    input  wire        rst_n,           // 低电平有效复位
    input  wire        start,           // 开始处理信号
    input  wire [15:0] data_in,         // 输入数据 (Q2.13格式)
    input  wire        data_in_valid,   // 输入数据有效
    
    output wire        filter_done,     // 滤波器处理完成
    output wire [10:0] addr,            // 样本地址
    output wire [15:0] data_out,        // 输出数据
    output wire        data_out_valid,  // 输出数据有效
    output wire        stable_out       // 稳定输出标志
);

    // 内部连接信号
    wire        pipeline_en;            // 流水线使能信号
    wire [15:0] sos_data [0:6];         // SOS节点间的数据连接
    wire        sos_valid [0:6];        // SOS节点间的有效信号连接
    
    // 将输入连接到第一个SOS节点
    assign sos_data[0] = data_in;
    assign sos_valid[0] = data_in_valid && pipeline_en;
    
    // 实例化控制模块
    opti_control_pipeline u_control (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .data_in_valid (data_in_valid),
        .sos_out_valid (sos_valid[6]),
        .sos_out_data  (sos_data[6]),
        .filter_done   (filter_done),
        .pipeline_en   (pipeline_en),
        .addr          (addr),
        .data_out      (data_out),
        .data_out_valid(data_out_valid),
        .stable_out    (stable_out)
    );
    
    // 各SOS阶段的系数 - 按照MATLAB建议的顺序排列（从极点模大到小）
    
    // 注意：我们将SOS节点的顺序反转，以符合MATLAB分析建议
    // 原始顺序:
    // 1. b0=4088, b1=7325, b2=4088, a1=2842, a2=5981
    // 2. b0=4088, b1=-7325, b2=4088, a1=-2842, a2=5981
    // 3. b0=4088, b1=-5252, b2=4088, a1=-6551, a2=7225
    // 4. b0=4088, b1=5252, b2=4088, a1=6551, a2=7225
    // 5. b0=4088, b1=4623, b2=4088, a1=7896, a2=7963
    // 6. b0=4088, b1=-4623, b2=4088, a1=-7896, a2=7963
    
    // 反转后的顺序（从极点模大到小）:
    // 1. b0=4088, b1=-4623, b2=4088, a1=-7896, a2=7963 (原6)
    // 2. b0=4088, b1=4623, b2=4088, a1=7896, a2=7963 (原5)
    // 3. b0=4088, b1=5252, b2=4088, a1=6551, a2=7225 (原4)
    // 4. b0=4088, b1=-5252, b2=4088, a1=-6551, a2=7225 (原3)
    // 5. b0=4088, b1=-7325, b2=4088, a1=-2842, a2=5981 (原2)
    // 6. b0=4088, b1=7325, b2=4088, a1=2842, a2=5981 (原1)
    
    // 第1级SOS处理单元 (原第6级)
    opti_sos_stage sos_stage1 (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid_in  (sos_valid[0]),
        .data_in        (sos_data[0]),
        .is_last_stage  (1'b0),        // 不是最后一级，无需应用增益校正
        .b0             (16'h0FF8),    // 4088
        .b1             (16'hEDF1),    // -4623
        .b2             (16'h0FF8),    // 4088
        .a1             (16'hE128),    // -7896
        .a2             (16'h1F1B),    // 7963
        .data_valid_out (sos_valid[1]),
        .data_out       (sos_data[1])
    );
    
    // 第2级SOS处理单元 (原第5级)
    opti_sos_stage sos_stage2 (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid_in  (sos_valid[1]),
        .data_in        (sos_data[1]),
        .is_last_stage  (1'b0),        // 不是最后一级
        .b0             (16'h0FF8),    // 4088
        .b1             (16'h120F),    // 4623
        .b2             (16'h0FF8),    // 4088
        .a1             (16'h1ED8),    // 7896
        .a2             (16'h1F1B),    // 7963
        .data_valid_out (sos_valid[2]),
        .data_out       (sos_data[2])
    );
    
    // 第3级SOS处理单元 (原第4级)
    opti_sos_stage sos_stage3 (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid_in  (sos_valid[2]),
        .data_in        (sos_data[2]),
        .is_last_stage  (1'b0),        // 不是最后一级
        .b0             (16'h0FF8),    // 4088
        .b1             (16'h1484),    // 5252
        .b2             (16'h0FF8),    // 4088
        .a1             (16'h198B),    // 6551
        .a2             (16'h1C39),    // 7225
        .data_valid_out (sos_valid[3]),
        .data_out       (sos_data[3])
    );
    
    // 第4级SOS处理单元 (原第3级)
    opti_sos_stage sos_stage4 (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid_in  (sos_valid[3]),
        .data_in        (sos_data[3]),
        .is_last_stage  (1'b0),        // 不是最后一级
        .b0             (16'h0FF8),    // 4088
        .b1             (16'hEB7C),    // -5252
        .b2             (16'h0FF8),    // 4088
        .a1             (16'hE675),    // -6551
        .a2             (16'h1C39),    // 7225
        .data_valid_out (sos_valid[4]),
        .data_out       (sos_data[4])
    );
    
    // 第5级SOS处理单元 (原第2级)
    opti_sos_stage sos_stage5 (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid_in  (sos_valid[4]),
        .data_in        (sos_data[4]),
        .is_last_stage  (1'b0),        // 不是最后一级
        .b0             (16'h0FF8),    // 4088
        .b1             (16'hE363),    // -7325
        .b2             (16'h0FF8),    // 4088
        .a1             (16'hF4E6),    // -2842
        .a2             (16'h175D),    // 5981
        .data_valid_out (sos_valid[5]),
        .data_out       (sos_data[5])
    );
    
    // 第6级SOS处理单元 (原第1级) - 最后一级，应用增益校正
    opti_sos_stage sos_stage6 (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid_in  (sos_valid[5]),
        .data_in        (sos_data[5]),
        .is_last_stage  (1'b1),        // 是最后一级，需要应用增益校正
        .b0             (16'h0FF8),    // 4088
        .b1             (16'h1C9D),    // 7325
        .b2             (16'h0FF8),    // 4088
        .a1             (16'h0B1A),    // 2842
        .a2             (16'h175D),    // 5981
        .data_valid_out (sos_valid[6]),
        .data_out       (sos_data[6])
    );
    
endmodule