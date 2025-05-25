module opti_coeffs (
    input  wire [1:0] sos_idx,
    output reg signed [23:0] b0, b1, b2, a1, a2
);

    always @(*) begin
        case (sos_idx)
            2'd0: begin
                b0 = 24'sh1B0F47;
                b1 = 24'sh010CC5;
                b2 = 24'sh1B0F47;
                a1 = 24'shE08C0C;
                a2 = 24'sh31A0FF;
            end
            2'd1: begin
                b0 = 24'sh1B0F47;
                b1 = 24'sh09E05D;
                b2 = 24'sh1B0F47;
                a1 = 24'shEDDA8D;
                a2 = 24'sh1B7A91;
            end
            2'd2: begin
                b0 = 24'sh1B0F47;
                b1 = 24'sh1C9720;
                b2 = 24'sh1B0F47;
                a1 = 24'shFC035E;
                a2 = 24'sh0B0A64;
            end
            2'd3: begin
                b0 = 24'sh1B0F47;
                b1 = 24'sh32269C;
                b2 = 24'sh1B0F47;
                a1 = 24'sh05A195;
                a2 = 24'sh017AD4;
            end
            default: begin
                b0 = 24'sd0;
                b1 = 24'sd0;
                b2 = 24'sd0;
                a1 = 24'sd0;
                a2 = 24'sd0;
            end
        endcase
    end

endmodule