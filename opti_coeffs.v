// 流水线架构的IIR滤波器 - opti_coeffs_fixed.v
// 固定系数模块：硬编码每个SOS阶段的系数
module opti_coeffs_fixed (
    input  wire [2:0]  stage_index,    // SOS阶段索引(0-5)
    output wire [15:0] b0,             // 前馈系数b0
    output wire [15:0] b1,             // 前馈系数b1
    output wire [15:0] b2,             // 前馈系数b2
    output wire [15:0] a1,             // 反馈系数a1
    output wire [15:0] a2              // 反馈系数a2
);
    // 系数寄存器
    reg [15:0] b0_reg, b1_reg, b2_reg, a1_reg, a2_reg;
    
    // 基于阶段索引分配系数
    always @(*) begin
        case (stage_index)
            // 第1级SOS系数
            3'd0: begin
                b0_reg = 16'h0FF8; // 4088
                b1_reg = 16'h1C9D; // 7325
                b2_reg = 16'h0FF8; // 4088
                a1_reg = 16'h0B1A; // 2842
                a2_reg = 16'h175D; // 5981
            end
            
            // 第2级SOS系数
            3'd1: begin
                b0_reg = 16'h0FF8; // 4088
                b1_reg = 16'hE363; // -7325
                b2_reg = 16'h0FF8; // 4088
                a1_reg = 16'hF4E6; // -2842
                a2_reg = 16'h175D; // 5981
            end
            
            // 第3级SOS系数
            3'd2: begin
                b0_reg = 16'h0FF8; // 4088
                b1_reg = 16'hEB7C; // -5252
                b2_reg = 16'h0FF8; // 4088
                a1_reg = 16'hE675; // -6551
                a2_reg = 16'h1C39; // 7225
            end
            
            // 第4级SOS系数
            3'd3: begin
                b0_reg = 16'h0FF8; // 4088
                b1_reg = 16'h1484; // 5252
                b2_reg = 16'h0FF8; // 4088
                a1_reg = 16'h198B; // 6551
                a2_reg = 16'h1C39; // 7225
            end
            
            // 第5级SOS系数
            3'd4: begin
                b0_reg = 16'h0FF8; // 4088
                b1_reg = 16'h120F; // 4623
                b2_reg = 16'h0FF8; // 4088
                a1_reg = 16'h1ED8; // 7896
                a2_reg = 16'h1F1B; // 7963
            end
            
            // 第6级SOS系数
            3'd5: begin
                b0_reg = 16'h0FF8; // 4088
                b1_reg = 16'hEDF1; // -4623
                b2_reg = 16'h0FF8; // 4088
                a1_reg = 16'hE128; // -7896
                a2_reg = 16'h1F1B; // 7963
            end
            
            default: begin
                // 默认系数 - 可以是第一级的系数或全零
                b0_reg = 16'h0FF8; // 4088
                b1_reg = 16'h1C9D; // 7325
                b2_reg = 16'h0FF8; // 4088
                a1_reg = 16'h0B1A; // 2842
                a2_reg = 16'h175D; // 5981
            end
        endcase
    end
    
    // 输出赋值
    assign b0 = b0_reg;
    assign b1 = b1_reg;
    assign b2 = b2_reg;
    assign a1 = a1_reg;
    assign a2 = a2_reg;
    
endmodule