module opti_sos_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid_in,
    input  wire [15:0] data_in,   // Q2.14
    input  wire [15:0] b0,
    input  wire [15:0] b1,
    input  wire [15:0] b2,
    input  wire [15:0] a1,
    input  wire [15:0] a2,
    output reg         data_valid_out,
    output reg  [15:0] data_out    // Q2.14
);

    // Q2.14格式的历史寄存器
    reg [15:0] w1, w2;
    reg [15:0] data_in_d;
    reg        data_valid_in_d;

    // 打拍保存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_d <= 0;
            data_valid_in_d <= 0;
        end else begin
            data_in_d <= data_in;
            data_valid_in_d <= data_valid_in;
        end
    end

    // ==== feedback term multiplication ====
    wire [31:0] p_a1_w1, p_a2_w2;
    wire        v_a1_w1, v_a2_w2;
    booth_multiplier_pipe mul_a1_w1(
        .clk(clk), .rst_n(rst_n), .start(data_valid_in), .a(a1), .b(w1), .valid(v_a1_w1), .p(p_a1_w1)
    );
    booth_multiplier_pipe mul_a2_w2(
        .clk(clk), .rst_n(rst_n), .start(data_valid_in), .a(a2), .b(w2), .valid(v_a2_w2), .p(p_a2_w2)
    );

    // ==== w_new = data_in - a1*w1 - a2*w2, 保持Q2.14 ====
    reg [15:0] w_new_q14;
    reg        wnew_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wnew_valid <= 0;
            w_new_q14  <= 0;
        end else begin
            wnew_valid <= v_a1_w1 & v_a2_w2;
            if (v_a1_w1 & v_a2_w2) begin
                w_new_q14 <= $signed(data_in_d)
                           - $signed(p_a1_w1[29:14])
                           - $signed(p_a2_w2[29:14]);
            end
        end
    end

    // ==== 前馈项乘法 ====
    wire [31:0] p_b0_wnew, p_b1_w1, p_b2_w2;
    wire        v_b0_wnew, v_b1_w1, v_b2_w2;
    booth_multiplier_pipe mul_b0_wnew(
        .clk(clk), .rst_n(rst_n), .start(wnew_valid), .a(b0), .b(w_new_q14), .valid(v_b0_wnew), .p(p_b0_wnew)
    );
    booth_multiplier_pipe mul_b1_w1(
        .clk(clk), .rst_n(rst_n), .start(wnew_valid), .a(b1), .b(w1), .valid(v_b1_w1), .p(p_b1_w1)
    );
    booth_multiplier_pipe mul_b2_w2(
        .clk(clk), .rst_n(rst_n), .start(wnew_valid), .a(b2), .b(w2), .valid(v_b2_w2), .p(p_b2_w2)
    );

    // ==== 累加Q4.28 ====
    // 注意：符号扩展到34位
    wire [33:0] acc_sum = {{2{p_b0_wnew[31]}}, p_b0_wnew} +
                          {{2{p_b1_w1[31]}},  p_b1_w1}  +
                          {{2{p_b2_w2[31]}},  p_b2_w2};

    // ==== Q4.28 -> Q2.14：右移14位 ====
    wire [19:0] shifted = acc_sum[33:14]; // 20位，最高位符号

    // ==== 饱和处理 ====
    reg [15:0] sat_q2_14;
    always @(*) begin
        if (shifted[19:15] == {5{shifted[19]}})
            sat_q2_14 = shifted[15:0];
        else if (shifted[19] == 1'b0)
            sat_q2_14 = 16'h7FFF;
        else
            sat_q2_14 = 16'h8000;
    end

    // ==== 输出与状态 ====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w1 <= 0;
            w2 <= 0;
            data_out <= 0;
            data_valid_out <= 0;
        end else if (v_b0_wnew & v_b1_w1 & v_b2_w2) begin
            w2 <= w1;
            w1 <= w_new_q14;
            data_out <= sat_q2_14;
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end
endmodule