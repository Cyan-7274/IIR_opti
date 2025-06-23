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
            5'd0  : coeff = 16'sh10E1; // b0_1
            5'd1  : coeff = 16'sh1177; // b1_1
            5'd2  : coeff = 16'sh0000; // b2_1
            5'd3  : coeff = 16'shDCD0; // a1_1
            5'd4  : coeff = 16'sh0000; // a2_1

            5'd5  : coeff = 16'sh10E1; // b0_2
            5'd6  : coeff = 16'sh22A5; // b1_2
            5'd7  : coeff = 16'sh11C9; // b2_2
            5'd8  : coeff = 16'shC57E; // a1_2
            5'd9  : coeff = 16'sh1802; // a2_2

            5'd10 : coeff = 16'sh10E1; // b0_3
            5'd11 : coeff = 16'sh21F1; // b1_3
            5'd12 : coeff = 16'sh1115; // b2_3
            5'd13 : coeff = 16'shDEE4; // a1_3
            5'd14 : coeff = 16'sh22AD; // a2_3

            5'd15 : coeff = 16'sh10E1; // b0_4
            5'd16 : coeff = 16'sh20B0; // b1_4
            5'd17 : coeff = 16'sh0FD4; // b2_4
            5'd18 : coeff = 16'shF606; // a1_4
            5'd19 : coeff = 16'sh2E81; // a2_4

            5'd20 : coeff = 16'sh10E1; // b0_5
            5'd21 : coeff = 16'sh212D; // b1_5
            5'd22 : coeff = 16'sh1050; // b2_5
            5'd23 : coeff = 16'sh0338; // a1_5
            5'd24 : coeff = 16'sh3A02; // a2_5

            default: coeff = 16'sd0;
        endcase
    end
endmodule
