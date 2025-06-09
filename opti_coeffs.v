`timescale 1ns/1ps

module opti_coeffs (
    input  wire  [4:0] addr,    // 0~19
    output reg signed [23:0] coeff
);
    always @(*) begin
        case (addr)
            5'd0  : coeff = 24'sh25EA25;
            5'd1  : coeff = 24'sh4B38E9;
            5'd2  : coeff = 24'sh25EA25;
            5'd3  : coeff = 24'sh32FD14;
            5'd4  : coeff = 24'sh0AD744;
            5'd5  : coeff = 24'sh25EA25;
            5'd6  : coeff = 24'sh470B14;
            5'd7  : coeff = 24'sh25EA25;
            5'd8  : coeff = 24'sh33BC62;
            5'd9  : coeff = 24'sh109A47;
            5'd10 : coeff = 24'sh25EA25;
            5'd11 : coeff = 24'sh41835C;
            5'd12 : coeff = 24'sh25EA25;
            5'd13 : coeff = 24'sh36A26E;
            5'd14 : coeff = 24'sh1CBBC1;
            5'd15 : coeff = 24'sh25EA25;
            5'd16 : coeff = 24'sh3DD8F8;
            5'd17 : coeff = 24'sh25EA25;
            5'd18 : coeff = 24'sh3EB56E;
            5'd19 : coeff = 24'sh31375C;
            default: coeff = 24'd0;
        endcase
    end
endmodule