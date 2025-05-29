// 全流水线 IIR 二阶节（SOS）修正版
module opti_sos (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              data_valid_in,
    input  wire signed [23:0] data_in,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b0,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg               data_valid_out,
    output reg signed [23:0] data_out
);

    // 乘法器流水线级数
    localparam MULT_PIPE = 12;

    // x[n], x[n-1], x[n-2]历史
    reg signed [23:0] x_pipe [0:2];
    // feedback历史 y[n-1], y[n-2]
    reg signed [23:0] y_pipe [0:1];
    // valid流水线
    reg valid_pipe [0:MULT_PIPE+2];

    integer i;

    // x_pipe与valid_pipe推进
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<3; i=i+1) x_pipe[i] <= 24'd0;
            for (i=0; i<=MULT_PIPE+2; i=i+1) valid_pipe[i] <= 1'b0;
        end else begin
            x_pipe[2] <= x_pipe[1];
            x_pipe[1] <= x_pipe[0];
            x_pipe[0] <= data_in;
            for (i=MULT_PIPE; i>0; i=i-1)
                valid_pipe[i] <= valid_pipe[i-1];
            valid_pipe[0] <= data_valid_in;
        end
    end

    // feedback推进，与valid_pipe推进一致
    // 保证反馈历史与x_pipe、valid_pipe同级对齐
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_pipe[0] <= 24'd0;
            y_pipe[1] <= 24'd0;
        end else if (valid_pipe[MULT_PIPE+2]) begin
            y_pipe[1] <= y_pipe[0];
            y_pipe[0] <= data_out; // 注意：此处用data_out推进，保证反馈为上一个输出
        end
    end

    // 乘法器输入数据与valid全部对齐
    wire signed [23:0] mult_b2_x_a = b2;
    wire signed [23:0] mult_b2_x_b = x_pipe[2];
    wire signed [23:0] mult_b1_x_a = b1;
    wire signed [23:0] mult_b1_x_b = x_pipe[1];
    wire signed [23:0] mult_b0_x_a = b0;
    wire signed [23:0] mult_b0_x_b = x_pipe[0];
    wire signed [23:0] mult_a1_y_a = a1;
    wire signed [23:0] mult_a1_y_b = y_pipe[0];
    wire signed [23:0] mult_a2_y_a = a2;
    wire signed [23:0] mult_a2_y_b = y_pipe[1];
    wire               mult_valid_in = valid_pipe[2];

    // 五路乘法器，输入valid完全同步
    wire signed [23:0] p_b2_x, p_b1_x, p_b0_x, p_a1_y, p_a2_y;
    wire v_b2_x, v_b1_x, v_b0_x, v_a1_y, v_a2_y;
    opti_multiplier mul_b2_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(mult_valid_in), .a(mult_b2_x_a), .b(mult_b2_x_b),
        .p(p_b2_x), .valid_out(v_b2_x)
    );
    opti_multiplier mul_b1_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(mult_valid_in), .a(mult_b1_x_a), .b(mult_b1_x_b),
        .p(p_b1_x), .valid_out(v_b1_x)
    );
    opti_multiplier mul_b0_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(mult_valid_in), .a(mult_b0_x_a), .b(mult_b0_x_b),
        .p(p_b0_x), .valid_out(v_b0_x)
    );
    opti_multiplier mul_a1_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(mult_valid_in), .a(mult_a1_y_a), .b(mult_a1_y_b),
        .p(p_a1_y), .valid_out(v_a1_y)
    );
    opti_multiplier mul_a2_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(mult_valid_in), .a(mult_a2_y_a), .b(mult_a2_y_b),
        .p(p_a2_y), .valid_out(v_a2_y)
    );

    // 统一推进点，乘法器输出会自动延迟MULT_PIPE拍
    // 输出信号严格与valid_pipe[MULT_PIPE+2]对齐

    // 五路乘法器输出全部ready
    wire mult_ready = v_b2_x & v_b1_x & v_b0_x & v_a1_y & v_a2_y;

    // acc_sum组合
    wire signed [26:0] acc_sum;
    assign acc_sum =
        { {3{p_b2_x[23]}}, p_b2_x } +
        { {3{p_b1_x[23]}}, p_b1_x } +
        { {3{p_b0_x[23]}}, p_b0_x } -
        { {3{p_a1_y[23]}}, p_a1_y } -
        { {3{p_a2_y[23]}}, p_a2_y };

    // 饱和
    wire signed [23:0] acc_sum_sat;
    assign acc_sum_sat =
        (acc_sum > 27'sd4194303) ? 24'sd4194303 :
        (acc_sum < -27'sd4194304) ? -24'sd4194304 :
        acc_sum[23:0];

    // 输出推进——与feedback推进点一致（唯一推进点）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 24'd0;
            data_valid_out <= 1'b0;
        end else if (mult_ready) begin
            data_out       <= acc_sum_sat;
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule