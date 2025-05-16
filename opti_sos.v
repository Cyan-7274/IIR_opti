// 修复版 opti_sos_stage.v - 包含增益校正和正确的节点顺序
module opti_sos_stage (
    input  wire        clk,         // 时钟
    input  wire        rst_n,       // 低电平有效复位
    input  wire        data_valid_in, // 输入数据有效
    input  wire [15:0] data_in,     // 输入数据 (Q2.13格式)
    input  wire        is_last_stage, // 是否为最后一个SOS阶段，用于应用增益校正
    input  wire [15:0] gain_correction, // 参数化增益校正系数
    
    // 固定系数输入 - 每个SOS阶段的系数是固定的
    input  wire [15:0] b0,          // 前馈系数b0
    input  wire [15:0] b1,          // 前馈系数b1
    input  wire [15:0] b2,          // 前馈系数b2
    input  wire [15:0] a1,          // 反馈系数a1
    input  wire [15:0] a2,          // 反馈系数a2
    
    output reg         data_valid_out, // 输出数据有效
    output reg  [15:0] data_out     // 输出数据 (Q2.13格式)
);

    // 定点格式常量
    localparam FRAC_BITS = 13;      // 小数位数 - Q2.13格式

    // 状态变量寄存器 - 转置II型IIR结构
    reg [15:0] s1_reg, s2_reg;     // 延迟状态寄存器

    // 乘法器接口信号
    reg  [2:0]  mult_sel;          // 乘法器选择 (哪个乘法正在进行)
    reg         mult_en;           // 乘法器使能
    reg  [15:0] mult_a, mult_b;    // 乘法器输入
    wire [31:0] mult_p;            // 乘法器输出
    wire        mult_valid;        // 乘法器输出有效

    // 流水线数据传递寄存器
    reg [15:0] x_reg;             // 输入值寄存
    reg [15:0] y_reg;             // 输出值寄存
    reg [15:0] y_gain_corrected;  // 应用增益校正后的输出值

    // 乘法结果寄存器
    reg [31:0] b0x_result;        // b0*x结果
    reg [31:0] b1x_result;        // b1*x结果
    reg [31:0] b2x_result;        // b2*x结果
    reg [31:0] a1y_result;        // a1*y结果
    reg [31:0] a2y_result;        // a2*y结果
    reg [31:0] gain_result;       // 增益校正结果

    // 流水线控制信号
    reg [2:0] pipe_stage;         // 流水线阶段计数
    reg       processing;         // 处理中标志
    reg       apply_gain_correction; // 是否需要应用增益校正

    // 乘法器选择常量
    localparam MULT_B0X = 3'd0;   // 计算b0*x
    localparam MULT_B1X = 3'd1;   // 计算b1*x
    localparam MULT_B2X = 3'd2;   // 计算b2*x
    localparam MULT_A1Y = 3'd3;   // 计算a1*y
    localparam MULT_A2Y = 3'd4;   // 计算a2*y
    localparam MULT_GAIN = 3'd5;  // 计算增益校正

    // 实例化流水线乘法器
    opti_multiplier u_multiplier (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (mult_en),
        .a      (mult_a),
        .b      (mult_b),
        .p      (mult_p),
        .valid  (mult_valid)
    );

    // 检查是否为极值
    function is_extreme_value;
        input [15:0] value;
        begin
            is_extreme_value = (value == 16'h7FFF || value == 16'h8000 || value == 16'h8001);
        end
    endfunction

    // 饱和函数 - 将32位Q4.26结果转换为16位Q2.13
    function [15:0] sat16;
        input [31:0] value;
        begin
            if (value[31]) begin
                // 负数处理
                if (value[31:29] != 3'b111) begin
                    sat16 = 16'h8000; // 负溢出限制为最小负值
                end else begin
                    sat16 = (value + (1 << (FRAC_BITS-1))) >> FRAC_BITS;
                end
            end else begin
                // 正数处理
                if (value[31:29] != 3'b000) begin
                    sat16 = 16'h7FFF; // 正溢出限制为最大正值
                end else begin
                    sat16 = (value + (1 << (FRAC_BITS-1))) >> FRAC_BITS;
                end
            end
        end
    endfunction

    // 乘法器控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_sel <= MULT_B0X;
            mult_en <= 1'b0;
            mult_a <= 16'd0;
            mult_b <= 16'd0;
            processing <= 1'b0;
            pipe_stage <= 3'd0;
            data_valid_out <= 1'b0;
            data_out <= 16'd0;
            y_reg <= 16'd0;
            y_gain_corrected <= 16'd0;
            apply_gain_correction <= 1'b0;
            s1_reg <= 16'd0;
            s2_reg <= 16'd0;
        end else begin
            // 检测新输入数据
            if (data_valid_in && !processing) begin
                // 开始一个新计算周期
                x_reg <= data_in;
                processing <= 1'b1;
                pipe_stage <= 3'd0;
                apply_gain_correction <= is_last_stage; // 只有最后一个阶段需要增益校正
                
                // 启动第一个乘法：b0*x
                mult_sel <= MULT_B0X;
                mult_a <= b0;
                mult_b <= data_in;
                mult_en <= 1'b1;
            end
            
            // 在乘法器输出有效时，处理结果并启动下一个乘法
            if (mult_valid && processing) begin
                case (mult_sel)
                    MULT_B0X: begin
                        b0x_result <= mult_p;     // 保存 b0*x 结果
                        mult_sel <= MULT_B1X;     // 启动 b1*x
                        mult_a <= b1;
                        mult_b <= x_reg;
                        mult_en <= 1'b1;
                    end
                    
                    MULT_B1X: begin
                        b1x_result <= mult_p;     // 保存 b1*x 结果
                        mult_sel <= MULT_A1Y;     // 启动 a1*y
                        mult_a <= a1;
                        mult_b <= y_reg;
                        mult_en <= 1'b1;
                    end

                    MULT_A1Y: begin
                        a1y_result <= mult_p;     // 保存 a1*y 结果
                        mult_sel <= MULT_B2X;     // 启动 b2*x
                        mult_a <= b2;
                        mult_b <= x_reg;
                        mult_en <= 1'b1;
                    end

                    MULT_B2X: begin
                        b2x_result <= mult_p;     // 保存 b2*x 结果
                        mult_sel <= MULT_A2Y;     // 启动 a2*y
                        mult_a <= a2;
                        mult_b <= y_reg;
                        mult_en <= 1'b1;
                    end

                    MULT_A2Y: begin
                        a2y_result <= mult_p;     // 保存 a2*y 结果
                        if (apply_gain_correction) begin
                            mult_sel <= MULT_GAIN; // 增益校正
                            mult_a <= y_reg;
                            mult_b <= gain_correction;
                            mult_en <= 1'b1;
                        end else begin
                            data_out <= sat16(mult_p);
                            data_valid_out <= 1'b1;
                            processing <= 1'b0;
                        end
                    end

                    MULT_GAIN: begin
                        gain_result <= mult_p;    // 保存增益校正结果
                        data_out <= sat16(mult_p);
                        data_valid_out <= 1'b1;
                        processing <= 1'b0;
                    end

                endcase
            end
            
            // 清除有效信号
            if (data_valid_out && !mult_valid)
                data_valid_out <= 1'b0;
        end
    end

endmodule