// 流水线乘法器 - 支持Q2.13格式，优化绝对值计算和溢出处理
module opti_multiplier (
    input  wire        clk,    // 时钟
    input  wire        rst_n,  // 低电平有效复位
    input  wire        en,     // 使能信号
    input  wire [15:0] a,      // 16位有符号乘数 (Q2.13格式)
    input  wire [15:0] b,      // 16位有符号被乘数 (Q2.13格式)
    output reg  [31:0] p,      // 32位乘积结果 (Q4.26格式，需要右移13位变回Q2.13)
    output reg         valid,  // 输出有效标志
    input  wire        ready   // 下游模块准备好接收数据的握手信号
);

    // 流水线阶段标识
    localparam STAGE1 = 2'd0;  // 初始准备阶段
    localparam STAGE2 = 2'd1;  // 乘法计算阶段
    localparam STAGE3 = 2'd2;  // 结果处理阶段

    // 流水线寄存器
    reg [15:0] a_pipe1, a_pipe2;     // 乘数a的流水线寄存器
    reg [15:0] b_pipe1, b_pipe2;     // 被乘数b的流水线寄存器
    reg        en_pipe1, en_pipe2;   // 使能信号的流水线寄存器
    reg [31:0] partial_product;      // 部分积
    reg        a_sign, b_sign;       // 符号位记录
    reg [1:0]  pipe_stage;           // 流水线状态

    // 饱和函数 - 将32位Q4.26结果转换为16位Q2.13
    function [15:0] sat16;
        input [31:0] value;
        reg [15:0] result;
        begin
            // 注意：Q4.26格式需要右移13位得到Q2.13
            if (value[31]) begin
                // 负数
                if (value[31:29] != 3'b111) begin
                    // 负溢出
                    result = 16'h8000; // 最小负值
                end else begin
                    // 正常负数，右移并四舍五入
                    result = (value + (1 << 12)) >>> 13;
                end
            end else begin
                // 正数
                if (value[31:29] != 3'b000) begin
                    // 正溢出
                    result = 16'h7FFF; // 最大正值
                end else begin
                    // 正常正数，右移并四舍五入
                    result = (value + (1 << 12)) >>> 13;
                end
            end
            sat16 = result;
        end
    endfunction

    // 流水线实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            a_pipe1 <= 16'd0;
            b_pipe1 <= 16'd0;
            a_pipe2 <= 16'd0;
            b_pipe2 <= 16'd0;
            en_pipe1 <= 1'b0;
            en_pipe2 <= 1'b0;
            pipe_stage <= STAGE1;
            valid <= 1'b0;
            p <= 32'd0;
            partial_product <= 32'd0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
        end else begin
            case (pipe_stage)
                STAGE1: begin
                    if (en) begin
                        // 记录输入数据
                        a_pipe1 <= a;
                        b_pipe1 <= b;
                        en_pipe1 <= 1'b1;
                        pipe_stage <= STAGE2;
                        valid <= 1'b0;
                    end else begin
                        en_pipe1 <= 1'b0;
                    end
                end

                STAGE2: begin
                    if (en_pipe1) begin
                        a_pipe2 <= a_pipe1;
                        b_pipe2 <= b_pipe1;

                        // 记录符号位
                        a_sign <= a_pipe1[15];
                        b_sign <= b_pipe1[15];

                        // 计算绝对值乘积
                        partial_product <= $signed(a_pipe1[15] ? -a_pipe1 : a_pipe1) *
                                           $signed(b_pipe1[15] ? -b_pipe1 : b_pipe1);

                        en_pipe2 <= 1'b1;
                        pipe_stage <= STAGE3;
                    end else begin
                        en_pipe2 <= 1'b0;
                    end
                end

                STAGE3: begin
                    if (en_pipe2) begin
                        // 恢复符号
                        if (a_sign ^ b_sign) begin
                            // 结果为负
                            p <= ~partial_product + 1'b1;
                        end else begin
                            // 结果为正
                            p <= partial_product;
                        end

                        // 标记输出有效
                        valid <= 1'b1;
                        if (ready) begin
                            valid <= 1'b0; // 等待下游模块握手
                        end

                        // 回到初始阶段
                        pipe_stage <= STAGE1;
                    end
                end
            endcase
        end
    end
endmodule