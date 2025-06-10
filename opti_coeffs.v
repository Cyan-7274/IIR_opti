// opti_coeffs.v
// Q2.22格式，24位有符号补码，Chebyshev II型8阶4节IIR滤波器，顺序为[b0 b1 b2 a1 a2]循环
// 对应Matlab导出 HEX, 支持addr=0~19
// 适用: 高精度伺服AA抗混叠滤波器 ASIC实现
// Verilog-2001标准，无SystemVerilog/VHDL特性

`timescale 1ns/1ps

module opti_coeffs (
    input  wire       [4:0] addr,     // 输入: 系数地址 0~19
    output reg signed [23:0] coeff    // 输出: Q2.22格式 24位有符号系数
);
    always @(*) begin
        case (addr)
            5'd0  : coeff = 24'sh25EA25; // b0_1
            5'd1  : coeff = 24'sh4B38E9; // b1_1
            5'd2  : coeff = 24'sh25EA25; // b2_1
            5'd3  : coeff = 24'sh32FD14; // a1_1
            5'd4  : coeff = 24'sh0AD744; // a2_1
            5'd5  : coeff = 24'sh25EA25; // b0_2
            5'd6  : coeff = 24'sh470B14; // b1_2
            5'd7  : coeff = 24'sh25EA25; // b2_2
            5'd8  : coeff = 24'sh33BC62; // a1_2
            5'd9  : coeff = 24'sh109A47; // a2_2
            5'd10 : coeff = 24'sh25EA25; // b0_3
            5'd11 : coeff = 24'sh41835C; // b1_3
            5'd12 : coeff = 24'sh25EA25; // b2_3
            5'd13 : coeff = 24'sh36A26E; // a1_3
            5'd14 : coeff = 24'sh1CBBC1; // a2_3
            5'd15 : coeff = 24'sh25EA25; // b0_4
            5'd16 : coeff = 24'sh3DD8F8; // b1_4
            5'd17 : coeff = 24'sh25EA25; // b2_4
            5'd18 : coeff = 24'sh3EB56E; // a1_4
            5'd19 : coeff = 24'sh31375C; // a2_4
            default: coeff = 24'sd0;
        endcase
    end
endmodule