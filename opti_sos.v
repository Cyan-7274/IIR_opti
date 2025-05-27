module opti_sos (
    input wire clk,
    input wire rst_n,
    input wire data_valid_in,
    input wire signed [23:0] data_in,
    input wire signed [23:0] b0, b1, b2, a1, a2,
    output reg data_valid_out,
    output reg signed [23:0] data_out
);
    // 乘法器流水级数
    localparam MULT_PIPE = 12;

    // 差分历史长度
    reg signed [23:0] x_pipe [0:2];
    reg signed [23:0] y1_pipe;
    reg signed [23:0] y2_pipe;

    // data/valid主同步
    reg [MULT_PIPE:0] valid_pipe;

    // feedback寄存器
    reg signed [23:0] y1_reg, y2_reg;

    // 乘法器输出
    wire signed [23:0] p_b0_x, p_b1_x, p_b2_x, p_a1_y, p_a2_y;
    wire v_b0_x, v_b1_x, v_b2_x, v_a1_y, v_a2_y;
    wire v_all_valid;
    assign v_all_valid = v_b0_x & v_b1_x & v_b2_x & v_a1_y & v_a2_y;

    wire signed [26:0] acc_sum;
    assign acc_sum =
        { {3{p_b0_x[23]}}, p_b0_x } +
        { {3{p_b1_x[23]}}, p_b1_x } +
        { {3{p_b2_x[23]}}, p_b2_x } -
        { {3{p_a1_y[23]}}, p_a1_y } -
        { {3{p_a2_y[23]}}, p_a2_y };

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
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_pipe[0] <= 0; x_pipe[1] <= 0; x_pipe[2] <= 0;
            y1_pipe <= 0; y2_pipe <= 0;
            valid_pipe <= 0;
            y1_reg <= 0; y2_reg <= 0;
            data_out <= 0; data_valid_out <= 0;
        end else begin
            // 推进历史pipe
            x_pipe[2] <= x_pipe[1];
            x_pipe[1] <= x_pipe[0];
            x_pipe[0] <= data_in;
            y2_pipe <= y1_pipe;
            y1_pipe <= y1_reg;

            // valid信号推进，与乘法器流水线同步
            valid_pipe <= {valid_pipe[MULT_PIPE-1:0], data_valid_in};

            // 输出/反馈更新
            if (v_all_valid) begin
                data_out <= saturate_q22(acc_sum);
                data_valid_out <= 1'b1;
                y2_reg <= y1_reg;
                y1_reg <= saturate_q22(acc_sum);
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end

    // 乘法器输入直接取pipe末端
    opti_multiplier mul_b0_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE]), .a(b0), .b(x_pipe[2]), // x[n-2]
        .p(p_b0_x), .valid_out(v_b0_x)
    );
    opti_multiplier mul_b1_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE]), .a(b1), .b(x_pipe[1]), // x[n-1]
        .p(p_b1_x), .valid_out(v_b1_x)
    );
    opti_multiplier mul_b2_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE]), .a(b2), .b(x_pipe[0]), // x[n]
        .p(p_b2_x), .valid_out(v_b2_x)
    );
    opti_multiplier mul_a1_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE]), .a(a1), .b(y1_pipe),   // y[n-1]
        .p(p_a1_y), .valid_out(v_a1_y)
    );
    opti_multiplier mul_a2_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[MULT_PIPE]), .a(a2), .b(y2_pipe),   // y[n-2]
        .p(p_a2_y), .valid_out(v_a2_y)
    );
endmodule