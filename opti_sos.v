// 严格全流水线 IIR 二阶节（SOS），Verilog-2001语法、反馈推进点唯一、数据/valid完全对齐。
// 依赖外部乘法器opti_multiplier，建议12级流水线。feedback仅用acc_sum推进，不混用data_out。
// 所有输入输出信号和pipe信号严格对齐。

module opti_sos (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              data_valid_in,
    input  wire signed [23:0] data_in,
    input  wire signed [23:0] b0,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg               data_valid_out,
    output reg signed [23:0] data_out
);

    // 乘法器流水线级数，直接常量
    localparam MULT_PIPE = 12;

    // x[n], x[n-1], x[n-2]历史
    reg signed [23:0] x_pipe [0:2];
    // feedback历史 y[n-1], y[n-2]
    reg signed [23:0] y_pipe [0:1];
    // valid管线（用于乘法器/同步输出）
    reg valid_pipe [0:MULT_PIPE+2];

    integer i;

    // x_pipe与valid_pipe推进
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<3; i=i+1) x_pipe[i] <= 24'd0;
            for (i=0; i<=MULT_PIPE+2; i=i+1) valid_pipe[i] <= 1'b0;
        end else begin
            // x_pipe：新数据推进
            x_pipe[2] <= x_pipe[1];
            x_pipe[1] <= x_pipe[0];
            x_pipe[0] <= data_in;
            // valid_pipe推进
            for (i=MULT_PIPE+2; i>0; i=i-1)
                valid_pipe[i] <= valid_pipe[i-1];
            valid_pipe[0] <= data_valid_in;
        end
    end

    // ===== 乘法器实例，输入数据和valid严格对齐 =====
    wire signed [23:0] p_b0_x, p_b1_x, p_b2_x, p_a1_y, p_a2_y;
    wire v_b0_x, v_b1_x, v_b2_x, v_a1_y, v_a2_y;

    opti_multiplier mul_b0_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE+2]), .a(b0), .b(x_pipe[2]),
        .p(p_b0_x), .valid_out(v_b0_x)
    );
    opti_multiplier mul_b1_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE+1]), .a(b1), .b(x_pipe[1]),
        .p(p_b1_x), .valid_out(v_b1_x)
    );
    opti_multiplier mul_b2_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE]), .a(b2), .b(x_pipe[0]),
        .p(p_b2_x), .valid_out(v_b2_x)
    );
    opti_multiplier mul_a1_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE]), .a(a1), .b(y_pipe[0]),
        .p(p_a1_y), .valid_out(v_a1_y)
    );
    opti_multiplier mul_a2_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE+1]), .a(a2), .b(y_pipe[1]),
        .p(p_a2_y), .valid_out(v_a2_y)
    );

    // ===== 乘法器所有输出有效ready判断（严格全流水线） =====
    wire mult_valid_all;
    assign mult_valid_all = v_b0_x & v_b1_x & v_b2_x & v_a1_y & v_a2_y;

    // ===== acc_sum组合与饱和 =====
    wire signed [26:0] acc_sum;
    assign acc_sum =
        { {3{p_b0_x[23]}}, p_b0_x } +
        { {3{p_b1_x[23]}}, p_b1_x } +
        { {3{p_b2_x[23]}}, p_b2_x } -
        { {3{p_a1_y[23]}}, p_a1_y } -
        { {3{p_a2_y[23]}}, p_a2_y };

    wire signed [23:0] acc_sum_sat;
    assign acc_sum_sat =
        (acc_sum > 27'sd4194303) ? 24'sd4194303 :
        (acc_sum < -27'sd4194304) ? -24'sd4194304 :
        acc_sum[23:0];

    // feedback历史值推进（仅用acc_sum推进，推进点唯一！）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_pipe[0] <= 24'd0;
            y_pipe[1] <= 24'd0;
        end else if (mult_valid_all) begin
            y_pipe[1] <= y_pipe[0];
            y_pipe[0] <= acc_sum_sat;
        end
    end

    // ===== 输出同步，严格与acc_sum推进对齐 =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 24'd0;
            data_valid_out <= 1'b0;
        end else if (mult_valid_all) begin
            data_out       <= acc_sum_sat;
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule