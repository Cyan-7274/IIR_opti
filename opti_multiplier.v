module opti_multiplier(
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [15:0] a, // Q2.14
    input  wire signed [15:0] b, // Q2.14
    input  wire         valid_in,
    output reg  signed [15:0] p, // Q2.14
    output reg          valid_out
);

    // ========== 声明 ==========
    reg signed [33:0] fa1_s0_r, fa1_c0_r, fa1_s1_r, fa1_c1_r, fa1_s2_r, fa1_c2_r;
    reg               valid_r;
    wire signed [18:0] a_ext;
    wire signed [33:0] pp [0:8];
    wire signed [33:0] fa1_s0, fa1_c0, fa1_s1, fa1_c1, fa1_s2, fa1_c2;
    wire signed [33:0] fa2_s, fa2_c, fa3_s, fa3_c, fa4_s, fa4_c, fa5_s, fa5_c;
    wire signed [33:0] sum_final;
    wire [4:0] sat_hi;
    wire signed [15:0] result_sat;

    // ========== Booth-4编码 ==========
    assign a_ext = {a[15], a[15], a, 1'b0};
    genvar j;
    generate
        for (j = 0; j < 9; j = j + 1) begin : gen_pp
            wire [2:0] booth_code = {a_ext[2*j+2], a_ext[2*j+1], a_ext[2*j]};
            assign pp[j] = (booth_code == 3'b000 || booth_code == 3'b111) ? 34'sd0 :
                           (booth_code == 3'b001 || booth_code == 3'b010) ? ($signed(b) <<< (2*j)) :
                           (booth_code == 3'b011) ? ($signed(b) <<< (2*j+1)) :
                           (booth_code == 3'b100) ? -($signed(b) <<< (2*j+1)) :
                           (booth_code == 3'b101 || booth_code == 3'b110) ? -($signed(b) <<< (2*j)) :
                           34'sd0;
        end
    endgenerate

    fa34 fa1_0 (.a(pp[0]), .b(pp[1]), .cin(pp[2]), .sum(fa1_s0), .cout(fa1_c0));
    fa34 fa1_1 (.a(pp[3]), .b(pp[4]), .cin(pp[5]), .sum(fa1_s1), .cout(fa1_c1));
    fa34 fa1_2 (.a(pp[6]), .b(pp[7]), .cin(pp[8]), .sum(fa1_s2), .cout(fa1_c2));

    // ========== T0: Wallace一级结果寄存 ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fa1_s0_r <= 34'd0; fa1_c0_r <= 34'd0;
            fa1_s1_r <= 34'd0; fa1_c1_r <= 34'd0;
            fa1_s2_r <= 34'd0; fa1_c2_r <= 34'd0;
            valid_r  <= 1'b0;
        end else begin
            fa1_s0_r <= fa1_s0; fa1_c0_r <= fa1_c0;
            fa1_s1_r <= fa1_s1; fa1_c1_r <= fa1_c1;
            fa1_s2_r <= fa1_s2; fa1_c2_r <= fa1_c2;
            valid_r  <= valid_in;
        end
    end

    // ========== T1: Wallace树最终累加 ==========
    fa34 fa2_0 (.a(fa1_s0_r), .b(fa1_c0_r <<< 1), .cin(fa1_s1_r), .sum(fa2_s), .cout(fa2_c));
    fa34 fa3_0 (.a(fa1_c1_r <<< 1), .b(fa1_s2_r), .cin(fa1_c2_r <<< 1), .sum(fa3_s), .cout(fa3_c));
    fa34 fa4_0 (.a(fa2_s), .b(fa2_c <<< 1), .cin(fa3_s), .sum(fa4_s), .cout(fa4_c));
    fa34 fa5_0 (.a(fa3_c <<< 1), .b(fa4_c <<< 1), .cin(fa4_s), .sum(fa5_s), .cout(fa5_c));
    assign sum_final = fa5_s + (fa5_c <<< 1);

    // ========== Q2.14定点截位和饱和 ==========
    // Q2.14输出对应sum_final[29:14]，溢出时输出最大/最小
    assign sat_hi = sum_final[33:29];
    assign result_sat = (sat_hi == 5'b00000 || sat_hi == 5'b11111) ? sum_final[29:14] :
                        (sum_final[33] ? 16'h8000 : 16'h7FFF);

    // ========== T1: 输出同步 ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 16'd0;
            valid_out <= 1'b0;
        end else begin
            p <= result_sat;
            valid_out <= valid_r;
        end
    end

endmodule

module fa34(
    input  wire signed [33:0] a,
    input  wire signed [33:0] b,
    input  wire signed [33:0] cin,
    output wire signed [33:0] sum,
    output wire signed [33:0] cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule