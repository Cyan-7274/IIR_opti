// 流水线乘法器 - 更高效的定点乘法处理
module opti_multiplier (
    input  wire        clk,    // 时钟
    input  wire        rst_n,  // 低电平有效复位
    input  wire        en,     // 使能信号
    input  wire [15:0] a,      // 16位有符号乘数 (Q2.13格式)
    input  wire [15:0] b,      // 16位有符号被乘数 (Q2.13格式)
    output reg  [31:0] p,      // 32位乘积结果 (Q4.26格式，需要右移13位变回Q2.13)
    output reg         valid   // 输出有效标志
);
    // 流水线阶段标识
    localparam STAGE1 = 0;  // 初始准备阶段
    localparam STAGE2 = 1;  // 乘法计算阶段
    localparam STAGE3 = 2;  // 结果处理阶段

    // 流水线寄存器
    reg [15:0] a_pipe1, a_pipe2;     // 乘数a的流水线寄存器
    reg [15:0] b_pipe1, b_pipe2;     // 被乘数b的流水线寄存器
    reg        en_pipe1, en_pipe2;   // 使能信号的流水线寄存器
    reg [31:0] partial_product;      // 部分积
    reg        a_sign, b_sign;       // 符号位记录
    reg [1:0]  pipe_stage;           // 流水线状态
    
    // 检查输入是否为最小负值-32768 (0x8000)
    function is_min_negative;
        input [15:0] value;
        begin
            is_min_negative = (value[15] && value[14:0] == 15'b0); // 0x8000
        end
    endfunction
    
    // 三级流水线乘法器实现
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
            // 流水线处理
            case (pipe_stage)
                STAGE1: begin
                    // 第一级流水线：输入寄存
                    if (en) begin
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
                    // 第二级流水线：乘法计算
                    if (en_pipe1) begin
                        a_pipe2 <= a_pipe1;
                        b_pipe2 <= b_pipe1;
                        
                        // 保存符号信息
                        a_sign <= a_pipe1[15];
                        b_sign <= b_pipe1[15];
                        
                        // 判断是否有最小负值的特殊情况
                        if (is_min_negative(a_pipe1) || is_min_negative(b_pipe1)) begin
                            // 特殊处理最小负值情况
                            if (is_min_negative(a_pipe1) && is_min_negative(b_pipe1)) begin
                                // -32768 * -32768 = 1073741824 (溢出处理)
                                partial_product <= 32'h40000000;
                            end else if (a_pipe1 == 16'd0 || b_pipe1 == 16'd0) begin
                                // 任何数 * 0 = 0
                                partial_product <= 32'd0;
                            end else begin
                                // -32768 * 其他数，可能溢出，使用最小负值
                                partial_product <= 32'h80000000;
                            end
                        end else begin
                            // 正常乘法情况 - 使用绝对值相乘
                            partial_product <= $signed(a_pipe1[15] ? (~a_pipe1 + 1'b1) : a_pipe1) * 
                                              $signed(b_pipe1[15] ? (~b_pipe1 + 1'b1) : b_pipe1);
                        end
                        
                        en_pipe2 <= 1'b1;
                        pipe_stage <= STAGE3;
                    end else begin
                        en_pipe2 <= 1'b0;
                    end
                end
                
                STAGE3: begin
                    // 第三级流水线：结果处理
                    if (en_pipe2) begin
                        if (is_min_negative(a_pipe2) || is_min_negative(b_pipe2)) begin
                            // 使用第二级已计算的特殊值结果
                            p <= partial_product;
                        end else begin
                            // 正常情况 - 根据乘数符号确定结果符号
                            if (a_sign ^ b_sign) begin
                                // 异号，结果应为负数
                                p <= ~partial_product + 1'b1;
                            end else begin
                                // 同号，结果为正数
                                p <= partial_product;
                            end
                        end
                        
                        valid <= 1'b1;
                        pipe_stage <= STAGE1; // 回到初始状态，准备下一次乘法
                    end else begin
                        valid <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule