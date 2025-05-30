module opti_sos (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               data_valid_in,
    input  wire signed [23:0] data_in,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b0,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg                data_valid_out,
    output reg signed [23:0]  data_out
);

    localparam MULT_PIPE = 13;
    integer i;

    // 1. 输入数据流水线
    reg signed [23:0] x_pipe [0:MULT_PIPE-1];
    reg valid_pipe [0:MULT_PIPE-1];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<MULT_PIPE; i=i+1) begin
                x_pipe[i] <= 24'd0;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            for (i=MULT_PIPE-1; i>0; i=i-1) begin
                x_pipe[i] <= x_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
            x_pipe[0] <= data_in;
            valid_pipe[0] <= data_valid_in;
        end
    end

    // 2. 状态寄存器
    reg signed [23:0] w0_reg, w1, w2;
    reg valid_fb0, valid_fb1, valid_fb2;

    // 3. 反馈乘法器（使用当前状态）
    wire signed [23:0] mul_a1_w1_a, mul_a1_w1_b, mul_a2_w2_a, mul_a2_w2_b;
    assign mul_a1_w1_a = a1;
    assign mul_a1_w1_b = w1;
    assign mul_a2_w2_a = a2;
    assign mul_a2_w2_b = w2;

    wire signed [23:0] p_a1_w1, p_a2_w2;
    wire v_a1_w1, v_a2_w2;
    
    opti_multiplier mul_a1_w1(
        .clk(clk), .rst_n(rst_n),
        .valid_in(data_valid_in), // 与输入同步
        .a(mul_a1_w1_a), .b(mul_a1_w1_b),
        .p(p_a1_w1), .valid_out(v_a1_w1)
    );
    
    opti_multiplier mul_a2_w2(
        .clk(clk), .rst_n(rst_n),
        .valid_in(data_valid_in), // 与输入同步
        .a(mul_a2_w2_a), .b(mul_a2_w2_b),
        .p(p_a2_w2), .valid_out(v_a2_w2)
    );

    wire feedback_mult_ready;
    assign feedback_mult_ready = v_a1_w1 & v_a2_w2;

    // 4. w0计算
    wire signed [26:0] acc_sum_w0;
    assign acc_sum_w0 =
        { {3{x_pipe[MULT_PIPE-1][23]}}, x_pipe[MULT_PIPE-1]} -
        { {3{p_a1_w1[23]}}, p_a1_w1 } -
        { {3{p_a2_w2[23]}}, p_a2_w2 };
        
    wire signed [23:0] w0_next;
    assign w0_next =
        (acc_sum_w0 > 27'sd4194303) ? 24'sd4194303 :
        (acc_sum_w0 < -27'sd4194304) ? -24'sd4194304 :
        acc_sum_w0[23:0];

    // 5. 状态更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w0_reg <= 24'd0;
            w1 <= 24'd0;
            w2 <= 24'd0;
            valid_fb0 <= 1'b0;
            valid_fb1 <= 1'b0;
            valid_fb2 <= 1'b0;
        end else if (feedback_mult_ready) begin
            w2 <= w1;
            w1 <= w0_reg;
            w0_reg <= w0_next;
            valid_fb2 <= valid_fb1;
            valid_fb1 <= valid_fb0;
            valid_fb0 <= valid_pipe[MULT_PIPE-1];
        end
    end

    // 6. 输出乘法器输入
    wire signed [23:0] mul_b0_w0_a, mul_b0_w0_b;
    wire signed [23:0] mul_b1_w1_a, mul_b1_w1_b;
    wire signed [23:0] mul_b2_w2_a, mul_b2_w2_b;
    
    assign mul_b0_w0_a = b0;
    assign mul_b0_w0_b = w0_reg;
    assign mul_b1_w1_a = b1;
    assign mul_b1_w1_b = w1;
    assign mul_b2_w2_a = b2;
    assign mul_b2_w2_b = w2;

    // 7. 输出乘法器（关键修正：使用状态更新信号启动）
    wire signed [23:0] p_b0_w0, p_b1_w1, p_b2_w2;
    wire v_b0_w0, v_b1_w1, v_b2_w2;
    
    opti_multiplier mul_b0_w0(
        .clk(clk), .rst_n(rst_n),
        .valid_in(feedback_mult_ready), // 关键修正：状态更新时启动
        .a(mul_b0_w0_a), .b(mul_b0_w0_b),
        .p(p_b0_w0), .valid_out(v_b0_w0)
    );
    
    opti_multiplier mul_b1_w1(
        .clk(clk), .rst_n(rst_n),
        .valid_in(feedback_mult_ready), // 关键修正：状态更新时启动
        .a(mul_b1_w1_a), .b(mul_b1_w1_b),
        .p(p_b1_w1), .valid_out(v_b1_w1)
    );
    
    opti_multiplier mul_b2_w2(
        .clk(clk), .rst_n(rst_n),
        .valid_in(feedback_mult_ready), // 关键修正：状态更新时启动
        .a(mul_b2_w2_a), .b(mul_b2_w2_b),
        .p(p_b2_w2), .valid_out(v_b2_w2)
    );

    wire output_mult_ready;
    assign output_mult_ready = v_b0_w0 & v_b1_w1 & v_b2_w2;

    // 8. 输出计算
    wire signed [26:0] acc_sum_y;
    assign acc_sum_y =
        { {3{p_b0_w0[23]}}, p_b0_w0 } +
        { {3{p_b1_w1[23]}}, p_b1_w1 } +
        { {3{p_b2_w2[23]}}, p_b2_w2 };
        
    wire signed [23:0] acc_sum_y_sat;
    assign acc_sum_y_sat =
        (acc_sum_y > 27'sd4194303) ? 24'sd4194303 :
        (acc_sum_y < -27'sd4194304) ? -24'sd4194304 :
        acc_sum_y[23:0];

    // 9. 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 24'd0;
            data_valid_out <= 1'b0;
        end else if (output_mult_ready) begin
            data_out <= acc_sum_y_sat;
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule