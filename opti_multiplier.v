// opti_multiplier.v
// Verilog-2001标准，Q2.22定点24位输入，Booth-4 + Wallace树乘法器，6级流水，输出数据保持型，valid为脉冲型

`timescale 1ns/1ps

module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [23:0] a,        // Q2.22
    input  wire signed [23:0] b,        // Q2.22
    input  wire         valid_in,
    output reg  signed [23:0] p,        // Q2.22  (保持型)
    output reg          valid_out       // (脉冲型)
);

    reg signed [24:0] a_ext_s1;
    reg signed [23:0] b_s1;
    reg               valid_s1;
    wire [2:0] booth_code [0:11];
    wire signed [47:0] pp [0:11];
    reg signed [47:0] pp_s2 [0:11];
    reg               valid_s2;
    wire signed [47:0] sum1 [0:3], carry1 [0:3];
    reg signed [47:0] sum1_s3 [0:3], carry1_s3 [0:3];
    reg               valid_s3;
    wire signed [47:0] sum2 [0:1], carry2 [0:1], pass2 [0:1];
    reg signed [47:0] sum2_s4 [0:1], carry2_s4 [0:1], pass2_s4 [0:1];
    reg               valid_s4;
    wire signed [47:0] sum3 [0:1], carry3 [0:1];
    reg signed [47:0] sum3_s5 [0:1], carry3_s5 [0:1];
    reg               valid_s5;
    wire signed [47:0] final_sum;
    wire round_bit;
    wire signed [47:0] final_sum_rounded;
    wire signed [24:0] temp_result_signed;
    integer j;
    genvar i;

    reg valid_pipe [0:4]; // 6级流水，有5级valid延迟

    wire signed [23:0] Q22_MAX, Q22_MIN;
    assign Q22_MAX = 24'sh3FFFFF;
    assign Q22_MIN = 24'shC00000;

    // Stage 1: 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_ext_s1 <= 25'd0;
            b_s1 <= 24'd0;
            valid_s1 <= 1'b0;
        end else begin
            a_ext_s1 <= {a[23], a, 1'b0};
            b_s1     <= b;
            valid_s1 <= valid_in;
        end
    end

    // Stage 2: Booth编码 & 部分积
    generate
        for (i = 0; i < 12; i = i + 1) begin: BOOTH_CODE
            assign booth_code[i] = a_ext_s1[2*i+2:2*i];
        end
    endgenerate
    generate
        for (i = 0; i < 12; i = i + 1) begin: BOOTH_PP
            wire [2:0] code;
            wire signed [47:0] pos_b, pos_2b, neg_b, neg_2b;
            assign code    = booth_code[i];
            assign pos_b   = {{24{b_s1[23]}}, b_s1} << (2*i);
            assign pos_2b  = {{23{b_s1[23]}}, b_s1, 1'b0} << (2*i);
            assign neg_b   = -pos_b;
            assign neg_2b  = -pos_2b;
            assign pp[i] = (code == 3'b000 || code == 3'b111) ? 48'd0 :
                           (code == 3'b001 || code == 3'b010) ? pos_b  :
                           (code == 3'b011)                   ? pos_2b :
                           (code == 3'b100)                   ? neg_2b :
                           (code == 3'b101 || code == 3'b110) ? neg_b  :
                           48'd0;
        end
    endgenerate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s2 <= 1'b0;
            for (j = 0; j < 12; j = j + 1) pp_s2[j] <= 48'd0;
        end else begin
            valid_s2 <= valid_s1;
            for (j = 0; j < 12; j = j + 1) pp_s2[j] <= pp[j];
        end
    end

    // Stage 3: Wallace树层1
    generate
        for (i = 0; i < 4; i = i + 1) begin: W1
            assign sum1[i]   = pp_s2[3*i] ^ pp_s2[3*i+1] ^ pp_s2[3*i+2];
            assign carry1[i] = ((pp_s2[3*i] & pp_s2[3*i+1]) |
                                (pp_s2[3*i] & pp_s2[3*i+2]) |
                                (pp_s2[3*i+1] & pp_s2[3*i+2])) << 1;
        end
    endgenerate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s3 <= 1'b0;
            for (j = 0; j < 4; j = j + 1) begin
                sum1_s3[j]   <= 48'd0;
                carry1_s3[j] <= 48'd0;
            end
        end else begin
            valid_s3 <= valid_s2;
            for (j = 0; j < 4; j = j + 1) begin
                sum1_s3[j]   <= sum1[j];
                carry1_s3[j] <= carry1[j];
            end
        end
    end

    // Stage 4: Wallace树层2
    assign sum2[0]   = sum1_s3[0] ^ carry1_s3[0] ^ sum1_s3[1];
    assign carry2[0] = ((sum1_s3[0] & carry1_s3[0]) | (sum1_s3[0] & sum1_s3[1]) | (carry1_s3[0] & sum1_s3[1])) << 1;
    assign sum2[1]   = carry1_s3[1] ^ sum1_s3[2] ^ carry1_s3[2];
    assign carry2[1] = ((carry1_s3[1] & sum1_s3[2]) | (carry1_s3[1] & carry1_s3[2]) | (sum1_s3[2] & carry1_s3[2])) << 1;
    assign pass2[0]  = sum1_s3[3];
    assign pass2[1]  = carry1_s3[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s4 <= 1'b0;
            sum2_s4[0] <= 48'd0; sum2_s4[1] <= 48'd0;
            carry2_s4[0] <= 48'd0; carry2_s4[1] <= 48'd0;
            pass2_s4[0] <= 48'd0; pass2_s4[1] <= 48'd0;
        end else begin
            valid_s4 <= valid_s3;
            sum2_s4[0] <= sum2[0]; sum2_s4[1] <= sum2[1];
            carry2_s4[0] <= carry2[0]; carry2_s4[1] <= carry2[1];
            pass2_s4[0] <= pass2[0]; pass2_s4[1] <= pass2[1];
        end
    end

    // Stage 5: Wallace树层3
    assign sum3[0]   = sum2_s4[0] ^ carry2_s4[0] ^ sum2_s4[1];
    assign carry3[0] = ((sum2_s4[0] & carry2_s4[0]) | (sum2_s4[0] & sum2_s4[1]) | (carry2_s4[0] & sum2_s4[1])) << 1;
    assign sum3[1]   = carry2_s4[1] ^ pass2_s4[0] ^ pass2_s4[1];
    assign carry3[1] = ((carry2_s4[1] & pass2_s4[0]) | (carry2_s4[1] & pass2_s4[1]) | (pass2_s4[0] & pass2_s4[1])) << 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s5 <= 1'b0;
            sum3_s5[0] <= 48'd0; sum3_s5[1] <= 48'd0;
            carry3_s5[0] <= 48'd0; carry3_s5[1] <= 48'd0;
        end else begin
            valid_s5 <= valid_s4;
            sum3_s5[0] <= sum3[0]; sum3_s5[1] <= sum3[1];
            carry3_s5[0] <= carry3[0]; carry3_s5[1] <= carry3[1];
        end
    end

    // Stage 6: 最终加法器/输出
    assign final_sum = sum3_s5[0] + carry3_s5[0] + sum3_s5[1] + carry3_s5[1];
    assign round_bit = final_sum[21];
    assign final_sum_rounded = final_sum + (round_bit << 22);
    assign temp_result_signed = final_sum_rounded[47:22];

    // valid延迟线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < 5; j = j + 1) valid_pipe[j] <= 1'b0;
        end else begin
            valid_pipe[0] <= valid_s1;
            valid_pipe[1] <= valid_pipe[0];
            valid_pipe[2] <= valid_pipe[1];
            valid_pipe[3] <= valid_pipe[2];
            valid_pipe[4] <= valid_pipe[3];
        end
    end

    // 输出保持型：p保持，valid_out脉冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 24'd0;
            valid_out <= 1'b0;
        end else begin
            if (valid_s5) begin
                valid_out <= 1'b1;
                if      (temp_result_signed > Q22_MAX)
                    p <= Q22_MAX;
                else if (temp_result_signed < Q22_MIN)
                    p <= Q22_MIN;
                else
                    p <= temp_result_signed[23:0];
            end else begin
                valid_out <= 1'b0;
                // p保持
            end
        end
    end

endmodule