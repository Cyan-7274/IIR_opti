// 转置二型IIR SOS节，高速定点Q2.22实现（Verilog-2001标准，声明规范）
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
    output reg  signed [23:0] data_out,    // Q2.22
    // 调试端口：乘法器48位中间值
    output wire signed [47:0] dbg_sum_b0_x,
    output wire signed [47:0] dbg_sum_b1_x,
    output wire signed [47:0] dbg_sum_b2_x,
    output wire signed [47:0] dbg_sum_a1_y,
    output wire signed [47:0] dbg_sum_a2_y
);

    // 状态寄存器，保存y(n-1), y(n-2)（Q2.22格式）
    reg signed [23:0] y1, y2;
    reg signed [23:0] x_delay1, x_delay2;

    // 反馈输出延迟，与乘法器对齐
    reg signed [23:0] y1_delay, y2_delay;

    // 乘法器输出
    wire signed [23:0] p_b0_x, p_b1_x, p_b2_x, p_a1_y, p_a2_y;
    wire v_b0_x, v_b1_x, v_b2_x, v_a1_y, v_a2_y;

    // valid流水线
    reg [2:0] valid_pipe;

    // 累加
    wire signed [26:0] acc_sum;

    // ---- Q2.22饱和函数 ----
    function signed [23:0] saturate_q22;
        input signed [26:0] value;
        begin
            if (value > 27'sh3FFFFF)
                saturate_q22 = 24'sh3FFFFF; // 最大+3.999...
            else if (value < -27'sd4194304)
                saturate_q22 = -24'sd4194304; // 最小-4.0
            else
                saturate_q22 = value[23:0];
        end
    endfunction

    // ---- 状态机 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_delay1 <= 24'sd0;
            x_delay2 <= 24'sd0;
            y1 <= 24'sd0;
            y2 <= 24'sd0;
            y1_delay <= 24'sd0;
            y2_delay <= 24'sd0;
            data_out <= 24'sd0;
            data_valid_out <= 1'b0;
            valid_pipe <= 3'b0;
        end else begin
            // x延迟
            if (data_valid_in) begin
                x_delay2 <= x_delay1;
                x_delay1 <= data_in;
            end
            // valid流水线
            valid_pipe <= {valid_pipe[1:0], data_valid_in};

            // 输出与状态更新
            if (v_b0_x && v_b1_x && v_b2_x && v_a1_y && v_a2_y) begin
                data_out <= saturate_q22(acc_sum);
                data_valid_out <= 1'b1;
                y2 <= y1;
                y1 <= saturate_q22(acc_sum);
                y2_delay <= y1_delay;
                y1_delay <= data_out;
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end

    // ---- 乘法器实例化 ----
    opti_multiplier mul_b0_x(.clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(b0), .b(data_in), .p(p_b0_x), .valid_out(v_b0_x), .debug_sum(dbg_sum_b0_x));
    opti_multiplier mul_b1_x(.clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(b1), .b(x_delay1), .p(p_b1_x), .valid_out(v_b1_x), .debug_sum(dbg_sum_b1_x));
    opti_multiplier mul_b2_x(.clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(b2), .b(x_delay2), .p(p_b2_x), .valid_out(v_b2_x), .debug_sum(dbg_sum_b2_x));
    opti_multiplier mul_a1_y(.clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(a1), .b(y1), .p(p_a1_y), .valid_out(v_a1_y), .debug_sum(dbg_sum_a1_y));
    opti_multiplier mul_a2_y(.clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(a2), .b(y2), .p(p_a2_y), .valid_out(v_a2_y), .debug_sum(dbg_sum_a2_y));

    // ---- 累加 ----
    assign acc_sum = 
        {{3{p_b0_x[23]}}, p_b0_x} + 
        {{3{p_b1_x[23]}}, p_b1_x} + 
        {{3{p_b2_x[23]}}, p_b2_x} -
        {{3{p_a1_y[23]}}, p_a1_y} -
        {{3{p_a2_y[23]}}, p_a2_y};

endmodule