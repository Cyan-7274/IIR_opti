// Q2.14 signed multiplier with Booth-4 encoding, vertical Wallace tree (列压缩) with 4:2 compressors, and CLA adder
// 3-stage pipeline: T0 - input latch and Booth encoding; T1 - Wallace tree; T2 - CLA and output

module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [15:0] a,       // Q2.14
    input  wire signed [15:0] b,       // Q2.14
    input  wire         valid_in,
    output reg  signed [15:0] p,       // Q2.14
    output reg          valid_out
);

    // Stage T0: Input latch and Booth encoding
    reg  signed [15:0] b_s1;
    reg                valid_s1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_s1     <= 16'd0;
            valid_s1 <= 1'b0;
        end else if (valid_in) begin
            b_s1     <= b;
            valid_s1 <= 1'b1;
        end else begin
            valid_s1 <= 1'b0;
        end
    end

    // Booth-4编码
    wire [18:0] a_ext = {{2{a[15]}}, a, 1'b0};
    wire [2:0] booth_code [0:8];
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : BOOTH_CODE
            assign booth_code[i] = a_ext[2*i+2 : 2*i];
        end
    endgenerate

    wire signed [33:0] pp [0:8];
    genvar j;
    generate
        for (j = 0; j < 9; j = j + 1) begin : BOOTH_PP
            wire [2:0] code = booth_code[j];
            wire signed [33:0] pos_b   = {{18{b_s1[15]}}, b_s1} <<< (2*j);
            wire signed [33:0] pos_2b  = {{17{b_s1[15]}}, b_s1, 1'b0} <<< (2*j);
            wire signed [33:0] neg_b   = -pos_b;
            wire signed [33:0] neg_2b  = -pos_2b;
            assign pp[j] = (code == 3'b000 || code == 3'b111) ? 34'd0 :
                           (code == 3'b001 || code == 3'b010) ? pos_b  :
                           (code == 3'b011)                   ? pos_2b :
                           (code == 3'b100)                   ? neg_2b :
                           (code == 3'b101 || code == 3'b110) ? neg_b  :
                           34'd0;
        end
    endgenerate

    // ----------- 垂直4:2压缩，直到两行 -----------
    // 第一层：9行pp -> 3行(sum, carry, cout)，
    // 第二层：3行->sum2/carry2/cout2，再压到两行（sum_final/carry_final）

    // 1. 第一层4:2压缩，按列展开
    wire [33:0] sum1, carry1, cout1;
    genvar k;
    generate
        for (k = 0; k < 34; k = k + 1) begin : COMPRESS_L1
            compressor_4_2 vert42_1 (
                .a(pp[0][k]),
                .b(pp[1][k]),
                .c(pp[2][k]),
                .d(pp[3][k]),
                .cin(1'b0), // 第一层cin为0
                .sum(sum1[k]),      // 本列
                .carry(carry1[k]),  // k+1
                .cout(cout1[k])     // k+2
            );
        end
    endgenerate

    // 2. 第二层4:2压缩，将sum1、carry1、cout1和pp[4]~pp[7]纵向压缩
    // 纵向推进，输入为sum1[k], carry1[k-1], cout1[k-2], pp[4][k]
    wire [33:0] sum2, carry2, cout2;
    generate
        for (k = 0; k < 34; k = k + 1) begin : COMPRESS_L2
            compressor_4_2 vert42_2 (
                .a(sum1[k]),
                .b((k>=1)? carry1[k-1] : 1'b0),
                .c((k>=2)? cout1[k-2]  : 1'b0),
                .d(pp[4][k]),
                .cin(1'b0), // 第二层cin为0
                .sum(sum2[k]),
                .carry(carry2[k]),
                .cout(cout2[k])
            );
        end
    endgenerate

    // 3. 第三层4:2压缩，将sum2、carry2、cout2和pp[5]~pp[8]纵向压缩
    wire [33:0] sum3, carry3, cout3;
    generate
        for (k = 0; k < 34; k = k + 1) begin : COMPRESS_L3
            compressor_4_2 vert42_3 (
                .a(sum2[k]),
                .b((k>=1)? carry2[k-1] : 1'b0),
                .c((k>=2)? cout2[k-2]  : 1'b0),
                .d(pp[5][k]),
                .cin(1'b0), // 第三层cin为0
                .sum(sum3[k]),
                .carry(carry3[k]),
                .cout(cout3[k])
            );
        end
    endgenerate

    // 4. 第四层4:2压缩，将sum3、carry3、cout3和pp[6][k]纵向压缩
    wire [33:0] sum4, carry4, cout4;
    generate
        for (k = 0; k < 34; k = k + 1) begin : COMPRESS_L4
            compressor_4_2 vert42_4 (
                .a(sum3[k]),
                .b((k>=1)? carry3[k-1] : 1'b0),
                .c((k>=2)? cout3[k-2]  : 1'b0),
                .d(pp[6][k]),
                .cin(1'b0), // 第四层cin为0
                .sum(sum4[k]),
                .carry(carry4[k]),
                .cout(cout4[k])
            );
        end
    endgenerate

    // 5. 第五层4:2压缩，将sum4、carry4、cout4和pp[7][k]纵向压缩
    wire [33:0] sum5, carry5, cout5;
    generate
        for (k = 0; k < 34; k = k + 1) begin : COMPRESS_L5
            compressor_4_2 vert42_5 (
                .a(sum4[k]),
                .b((k>=1)? carry4[k-1] : 1'b0),
                .c((k>=2)? cout4[k-2]  : 1'b0),
                .d(pp[7][k]),
                .cin(1'b0), // 第五层cin为0
                .sum(sum5[k]),
                .carry(carry5[k]),
                .cout(cout5[k])
            );
        end
    endgenerate

    // 6. 第六层4:2压缩，将sum5、carry5、cout5和pp[8][k]纵向压缩
    wire [33:0] sum6, carry6, cout6;
    generate
        for (k = 0; k < 34; k = k + 1) begin : COMPRESS_L6
            compressor_4_2 vert42_6 (
                .a(sum5[k]),
                .b((k>=1)? carry5[k-1] : 1'b0),
                .c((k>=2)? cout5[k-2]  : 1'b0),
                .d(pp[8][k]),
                .cin(1'b0), // 第六层cin为0
                .sum(sum6[k]),
                .carry(carry6[k]),
                .cout(cout6[k])
            );
        end
    endgenerate

    // 7. 最终只剩两行（sum6, carry6），直接加法收尾
    wire signed [33:0] product_full = sum6 + (carry6 << 1) + (cout6 << 2);

    // ------- Q点对齐与舍入 -------
    wire round_bit = product_full[13]; // 第14位小数
    wire signed [33:0] product_rounded = product_full + (round_bit << 14);
    wire signed [15:0] result = product_rounded[29:14];

    wire signed [15:0] Q14_MAX = 16'sh7FFF;
    wire signed [15:0] Q14_MIN = -16'sh8000;
    wire signed [15:0] result_sat = (result > Q14_MAX) ? Q14_MAX :
                                    (result < Q14_MIN) ? Q14_MIN :
                                    result;

    // ------- 输出寄存 -------
    reg valid_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p         <= 16'd0;
            valid_out <= 1'b0;
            valid_s2  <= 1'b0;
        end else if (valid_s1) begin
            p         <= result_sat;
            valid_out <= 1'b1;
            valid_s2  <= 1'b1;
        end else begin
            valid_out <= 1'b0;
            valid_s2  <= 1'b0;
        end
    end

endmodule

// ----------------- 4:2 Compressor (vertical/垂直结构，向上进位) -----------------
module compressor_4_2 (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire d,
    input  wire cin,
    output wire sum,    // 本列
    output wire carry,  // k+1列
    output wire cout    // k+2列
);
    wire [2:0] tmp;
    assign tmp = a + b + c + d + cin;
    assign sum   = tmp[0];
    assign carry = tmp[1];
    assign cout  = tmp[2];
endmodule