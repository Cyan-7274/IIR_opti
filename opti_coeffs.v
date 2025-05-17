// 自动生成：Q2.14格式滤波器系数模块（每行5个16位补码HEX，顺序[b0 b1 b2 a1 a2]）
module opti_coeffs (
    input  wire       stage,    // SOS节编号（0/1）
    output reg [15:0] b0, b1, b2, a1, a2
);
    always @(*) begin
        case(stage)
            1'b0: begin
                b0 = 16'h0A64;
                b1 = 16'hF802;
                b2 = 16'h0A64;
                a1 = 16'hABB8;
                a2 = 16'h3721;
            end
            1'b1: begin
                b0 = 16'h0A64;
                b1 = 16'h0783;
                b2 = 16'h0A64;
                a1 = 16'hA7F9;
                a2 = 16'h23AD;
            end
            default: begin
                b0 = 16'h0000; 
                b1 = 16'h0000; 
                b2 = 16'h0000; 
                a1 = 16'h0000; 
                a2 = 16'h0000;
            end
        endcase
    end
endmodule