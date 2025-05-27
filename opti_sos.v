module opti_sos (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         data_valid_in,
    input  wire signed [23:0] data_in,   // Q2.22
    input  wire signed [23:0] b0,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg          data_valid_out,
    output reg  signed [23:0] data_out    // Q2.22
);

    // === Pipeline 参数 ===
    localparam MULT_PIPE = 12;
    localparam PIPE_DEPTH = MULT_PIPE;

    reg signed [23:0] x_pipe [0:PIPE_DEPTH];
    reg signed [23:0] y1_pipe [0:PIPE_DEPTH];
    reg signed [23:0] y2_pipe [0:PIPE_DEPTH];
    reg               valid_pipe [0:PIPE_DEPTH];

    // feedback寄存器
    reg signed [23:0] y1_reg, y2_reg;

    // 乘法器结果
    wire signed [23:0] p_b0_x, p_b1_x, p_b2_x, p_a1_y, p_a2_y;
    wire               v_b0_x, v_b1_x, v_b2_x, v_a1_y, v_a2_y;
    wire               v_all_valid;
    assign v_all_valid = v_b0_x & v_b1_x & v_b2_x & v_a1_y & v_a2_y;

    // 多位累加和
    wire signed [26:0] acc_sum;
    assign acc_sum =
        { {3{p_b0_x[23]}}, p_b0_x } +
        { {3{p_b1_x[23]}}, p_b1_x } +
        { {3{p_b2_x[23]}}, p_b2_x } -
        { {3{p_a1_y[23]}}, p_a1_y } -
        { {3{p_a2_y[23]}}, p_a2_y };

    // 饱和函数
    function [23:0] saturate_q22;
        input signed [26:0] value;
        begin
            if (value > 27'sd4194303)
                saturate_q22 = 24'sd4194303;
            else if (value < -27'sd4194304)
                saturate_q22 = -24'sd4194304;
            else
                saturate_q22 = value[23:0];
        end
    endfunction

    integer i;
    // === 同步pipeline推进与反馈 ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<=PIPE_DEPTH; i=i+1) begin
                x_pipe[i]      <= 0;
                y1_pipe[i]     <= 0;
                y2_pipe[i]     <= 0;
                valid_pipe[i]  <= 0;
            end
            y1_reg <= 0;
            y2_reg <= 0;
            data_out <= 0;
            data_valid_out <= 0;
        end else begin
            // pipeline推进
            x_pipe[0]     <= data_in;
            y1_pipe[0]    <= y1_reg;
            y2_pipe[0]    <= y2_reg;
            valid_pipe[0] <= data_valid_in;
            for (i=1; i<=PIPE_DEPTH; i=i+1) begin
                x_pipe[i]     <= x_pipe[i-1];
                y1_pipe[i]    <= y1_pipe[i-1];
                y2_pipe[i]    <= y2_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end

            // 在当前输出有效时，更新feedback寄存器
            if (v_all_valid) begin
                // 输出和feedback严格同步
                data_out <= saturate_q22(acc_sum);
                data_valid_out <= 1'b1;
                // feedback历史
                y2_reg <= y1_reg;
                y1_reg <= saturate_q22(acc_sum);
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end

    // === 乘法器实例 ===
    opti_multiplier mul_b0_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[PIPE_DEPTH]), .a(b0), .b(x_pipe[PIPE_DEPTH]),
        .p(p_b0_x), .valid_out(v_b0_x)
    );
    opti_multiplier mul_b1_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[PIPE_DEPTH]), .a(b1), .b(x_pipe[PIPE_DEPTH-1]),
        .p(p_b1_x), .valid_out(v_b1_x)
    );
    opti_multiplier mul_b2_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[PIPE_DEPTH]), .a(b2), .b(x_pipe[PIPE_DEPTH-2]),
        .p(p_b2_x), .valid_out(v_b2_x)
    );
    opti_multiplier mul_a1_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[PIPE_DEPTH]), .a(a1), .b(y1_pipe[PIPE_DEPTH]),
        .p(p_a1_y), .valid_out(v_a1_y)
    );
    opti_multiplier mul_a2_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[PIPE_DEPTH]), .a(a2), .b(y2_pipe[PIPE_DEPTH]),
        .p(p_a2_y), .valid_out(v_a2_y)
    );

    // === 便于调试的信号直接输出（可注释/保留）===
    assign debug_x_pipe = x_pipe[PIPE_DEPTH];
    assign debug_y1_pipe = y1_pipe[PIPE_DEPTH];
    assign debug_y2_pipe = y2_pipe[PIPE_DEPTH];
    assign debug_y1_reg = y1_reg;
    assign debug_y2_reg = y2_reg;
    assign debug_acc_sum = acc_sum;

endmodule