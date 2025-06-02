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
    output reg signed [23:0]  w2,

    // 便于trace的b0乘法器信号（可选）
    output wire signed [23:0] b0_a,
    output wire signed [23:0] b0_b,
    output wire signed [23:0] b0_p,
    output wire               b0_valid_in,
    output wire               b0_valid_out
);

    // === 系数接口 ===
    wire signed [23:0] b0_coef, b1_coef, b2_coef, a1_coef, a2_coef;

    opti_coeffs u_coeffs (
        .sos_idx(sos_idx),
        .b0(b0_coef), .b1(b1_coef), .b2(b2_coef),
        .a1(a1_coef), .a2(a2_coef)
    );

    // === 乘法器输出提前声明 ===
    wire signed [23:0] p_a1_w1, p_a2_w2, p_b0_w0, p_b1_w1, p_b2_w2;

    // === 状态寄存器 ===
    reg signed [23:0] w0_reg, w1_reg, w2_reg;

    // === 反馈链w0_next的组合计算 ===
    wire signed [26:0] acc_sum_w0;
    wire signed [23:0] w0_next;
    assign acc_sum_w0 = { {3{data_in[23]}}, data_in }
                      - { {3{p_a1_w1[23]}}, p_a1_w1 }
                      - { {3{p_a2_w2[23]}}, p_a2_w2 };
    assign w0_next = (acc_sum_w0 > 27'sd4194303) ? 24'sd4194303 :
                     (acc_sum_w0 < -27'sd4194304) ? -24'sd4194304 :
                     acc_sum_w0[23:0];

    // === 状态推进 ===
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            w0_reg <= 0; w1_reg <= 0; w2_reg <= 0;
        end else if(data_valid_in) begin
            w2_reg <= w1_reg;
            w1_reg <= w0_reg;
            w0_reg <= w0_next; // w0_next为本拍反馈链组合输出
        end
    end

    // 便于trace的b0乘法器信号
    assign b0_a = b0_coef;
    assign b0_b = w0_reg;
    assign b0_valid_in = data_valid_in;

    // === 乘法器实例 ===
    opti_multiplier u_mul_a1_w1 (
        .clk(clk), .rst_n(rst_n),
        .a(a1_coef), .b(w1_reg), .valid_in(data_valid_in), .p(p_a1_w1), .valid_out()
    );
    opti_multiplier u_mul_a2_w2 (
        .clk(clk), .rst_n(rst_n),
        .a(a2_coef), .b(w2_reg), .valid_in(data_valid_in), .p(p_a2_w2), .valid_out()
    );
    opti_multiplier u_mul_b0_w0 (
        .clk(clk), .rst_n(rst_n),
        .a(b0_coef), .b(w0_reg), .valid_in(data_valid_in), .p(p_b0_w0), .valid_out(b0_valid_out)
    );
    opti_multiplier u_mul_b1_w1 (
        .clk(clk), .rst_n(rst_n),
        .a(b1_coef), .b(w1_reg), .valid_in(data_valid_in), .p(p_b1_w1), .valid_out()
    );
    opti_multiplier u_mul_b2_w2 (
        .clk(clk), .rst_n(rst_n),
        .a(b2_coef), .b(w2_reg), .valid_in(data_valid_in), .p(p_b2_w2), .valid_out()
    );

    // === 前馈链输出计算 ===
    wire signed [26:0] acc_sum;
    assign acc_sum = { {3{p_b0_w0[23]}}, p_b0_w0 }
                   + { {3{p_b1_w1[23]}}, p_b1_w1 }
                   + { {3{p_b2_w2[23]}}, p_b2_w2 };

    // === 输出同步采样 ===
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out       <= 0;
            data_valid_out <= 0;
            w0 <= 0; w1 <= 0; w2 <= 0;
        end else begin
            if(b0_valid_out) begin
                if(acc_sum > 27'sd4194303)
                    data_out <= 24'h3FFFFF;
                else if(acc_sum < -27'sd4194304)
                    data_out <= 24'hC00000;
                else
                    data_out <= acc_sum[23:0];
                data_valid_out <= 1'b1;
            end else begin
                data_valid_out <= 1'b0;
            end
            // trace输出
            w0 <= w0_reg;
            w1 <= w1_reg;
            w2 <= w2_reg;
        end
    end

    // === 便于trace的b0乘法器输出 ===
    assign b0_p = p_b0_w0;

endmodule