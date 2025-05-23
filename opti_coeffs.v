module opti_coeffs (
    input  wire [1:0] sos_idx,
    output reg signed [23:0] b0, b1, b2, a1, a2
);

    reg signed [23:0] coeff_mem [0:19];

    initial begin
        if ($readmemh("D:/A_Hesper/IIRfilter/qts/sim/iir_coeffs.hex", coeff_mem) !== 1)
            $display("ERROR: Could not read coefficients file! Check path and permissions.");
    end

    always @(*) begin
        case (sos_idx)
            2'd0: begin
                b0 = coeff_mem[0];  b1 = coeff_mem[1];  b2 = coeff_mem[2];
                a1 = coeff_mem[3];  a2 = coeff_mem[4];
            end
            2'd1: begin
                b0 = coeff_mem[5];  b1 = coeff_mem[6];  b2 = coeff_mem[7];
                a1 = coeff_mem[8];  a2 = coeff_mem[9];
            end
            2'd2: begin
                b0 = coeff_mem[10]; b1 = coeff_mem[11]; b2 = coeff_mem[12];
                a1 = coeff_mem[13]; a2 = coeff_mem[14];
            end
            2'd3: begin
                b0 = coeff_mem[15]; b1 = coeff_mem[16]; b2 = coeff_mem[17];
                a1 = coeff_mem[18]; a2 = coeff_mem[19];
            end
            default: begin
                b0 = 24'sd0; b1 = 24'sd0; b2 = 24'sd0; a1 = 24'sd0; a2 = 24'sd0;
            end
        endcase
    end

endmodule