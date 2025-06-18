// opti_coeffs.v
// Q2.14格式，16位有符号补码，Cheby1型10阶5节IIR滤波器，顺序为[b0 b1 b2 a1 a2]循环
// 对应MATLAB导出HEX, 支持addr=0~24
// Verilog-2001标准

module opti_coeffs (
    input  wire [4:0] addr,           // 0~24
    output reg signed [15:0] coeff
);
    always @(*) begin
        case (addr)
            5'd0  : coeff = 16'sh0E29; // b0_1
            5'd1  : coeff = 16'sh1DB3; // b1_1
            5'd2  : coeff = 16'sh0F93; // b2_1
            5'd3  : coeff = 16'shB7BC; // a1_1
            5'd4  : coeff = 16'sh16FD; // a2_1

            5'd5  : coeff = 16'sh0E29; // b0_2
            5'd6  : coeff = 16'sh1D26; // b1_2
            5'd7  : coeff = 16'sh0F06; // b2_2
            5'd8  : coeff = 16'shCA90; // a1_2
            5'd9  : coeff = 16'sh1DCB; // a2_2

            5'd10 : coeff = 16'sh0E29; // b0_3
            5'd11 : coeff = 16'sh1C4A; // b1_3
            5'd12 : coeff = 16'sh0E2B; // b2_3
            5'd13 : coeff = 16'shE373; // a1_3
            5'd14 : coeff = 16'sh27A1; // a2_3

            5'd15 : coeff = 16'sh0E29; // b0_4
            5'd16 : coeff = 16'sh1AFD; // b1_4
            5'd17 : coeff = 16'sh0CDD; // b2_4
            5'd18 : coeff = 16'shF793; // a1_4
            5'd19 : coeff = 16'sh318F; // a2_4

            5'd20 : coeff = 16'sh0E29; // b0_5
            5'd21 : coeff = 16'sh1B79; // b1_5
            5'd22 : coeff = 16'sh0D59; // b2_5
            5'd23 : coeff = 16'sh029F; // a1_5
            5'd24 : coeff = 16'sh3B16; // a2_5

            default: coeff = 16'sd0;
        endcase
    end
endmodule