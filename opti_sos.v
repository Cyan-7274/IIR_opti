module opti_sos (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [23:0] data_in,
    input  wire               data_valid_in,
    input  wire [1:0]         sos_idx,
    output reg                data_valid_out,
    output reg signed [23:0]  data_out,
    output reg signed [23:0]  w0,
    output reg signed [23:0]  w1,
    output reg signed [23:0]  w2
);

    // === 系数接口 ===
    wire signed [23:0] b0, b1, b2, a1, a2;

    opti_coeffs u_coeffs (
        .sos_idx(sos_idx),
        .b0(b0), .b1(b1), .b2(b2),
        .a1(a1), .a2(a2)
    );

    // --- 状态推进 ---（只依赖data_valid_in！）
    reg signed [23:0] w0_reg, w1_reg, w2_reg;
    reg signed [23:0] w0_next;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            w0_reg <= 0; w1_reg <= 0; w2_reg <= 0;
        end else if(data_valid_in) begin
            w2_reg <= w1_reg;
            w1_reg <= w0_reg;
            w0_reg <= w0_next;
        end
    end

    // --- 乘法器 ---
    wire signed [23:0] p_a1_w1, p_a2_w2, p_b0_w0, p_b1_w1, p_b2_w2;
    wire valid_b0;
    opti_multiplier u_mul_a1_w1 (
        .clk(clk), .rst_n(rst_n), .a(a1), .b(w1_reg), .valid_in(data_valid_in), .p(p_a1_w1), .valid_out()
    );
    opti_multiplier u_mul_a2_w2 (
        .clk(clk), .rst_n(rst_n), .a(a2), .b(w2_reg), .valid_in(data_valid_in), .p(p_a2_w2), .valid_out()
    );
    opti_multiplier u_mul_b0_w0 (
        .clk(clk), .rst_n(rst_n), .a(b0), .b(w0_reg), .valid_in(data_valid_in), .p(p_b0_w0), .valid_out(valid_b0)
    );
    opti_multiplier u_mul_b1_w1 (
        .clk(clk), .rst_n(rst_n), .a(b1), .b(w1_reg), .valid_in(data_valid_in), .p(p_b1_w1), .valid_out()
    );
    opti_multiplier u_mul_b2_w2 (
        .clk(clk), .rst_n(rst_n), .a(b2), .b(w2_reg), .valid_in(data_valid_in), .p(p_b2_w2), .valid_out()
    );

    // --- w0_next ---
    wire signed [26:0] acc_sum_w0;
    assign acc_sum_w0 = { {3{data_in[23]}}, data_in }
                      - { {3{p_a1_w1[23]}}, p_a1_w1 }
                      - { {3{p_a2_w2[23]}}, p_a2_w2 };
    always @(*) begin
        if      (acc_sum_w0 > 27'sd4194303) w0_next = 24'sd4194303;
        else if (acc_sum_w0 < -27'sd4194304) w0_next = -24'sd4194304;
        else w0_next = acc_sum_w0[23:0];
    end
reg signed [26:0] acc_sum_reg;
    // --- 累加输出（输出采样只依赖valid_b0） ---
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out       <= 0;
            data_valid_out <= 0;
            w0 <= 0; w1 <= 0; w2 <= 0;
        end else begin
            if(valid_b0) begin
                
                acc_sum_reg = { {3{p_b0_w0[23]}}, p_b0_w0 }
                            + { {3{p_b1_w1[23]}}, p_b1_w1 }
                            + { {3{p_b2_w2[23]}}, p_b2_w2 };
                if(acc_sum_reg > 27'sd4194303)
                    data_out <= 24'sd4194303;
                else if(acc_sum_reg < -27'sd4194304)
                    data_out <= -24'sd4194304;
                else
                    data_out <= acc_sum_reg[23:0];
                data_valid_out <= 1'b1;
            end else begin
                data_valid_out <= 1'b0;
            end
            w0 <= w0_reg; w1 <= w1_reg; w2 <= w2_reg;
        end
    end

endmodule