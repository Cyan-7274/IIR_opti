// 转置二型IIR SOS节，高速定点Q2.22实现（Verilog-2001标准，声明规范，理想时序版）
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
    reg signed [23:0] x_delay1, x_delay2;
    reg signed [23:0] y1, y2;

    // valid流水线，使所有乘法器输入和输出严格对齐
    reg [2:0] valid_pipe;

    // x/y延迟流水线（严格与valid_pipe同步）
    reg signed [23:0] data_in_pipe [0:2];
    reg signed [23:0] y1_pipe [0:2];
    reg signed [23:0] y2_pipe [0:2];

    integer i;

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

    // ---- 乘法器输出与valid信号 ----
    wire signed [23:0] p_b0_x, p_b1_x, p_b2_x, p_a1_y, p_a2_y;
    wire v_b0_x, v_b1_x, v_b2_x, v_a1_y, v_a2_y;
    wire v_all_valid;
    assign v_all_valid = v_b0_x && v_b1_x && v_b2_x && v_a1_y && v_a2_y;

    // ---- 状态机及流水线推进 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<=2; i=i+1) begin
                data_in_pipe[i] <= 24'sd0;
                y1_pipe[i] <= 24'sd0;
                y2_pipe[i] <= 24'sd0;
            end
            x_delay1 <= 24'sd0;
            x_delay2 <= 24'sd0;
            y1 <= 24'sd0;
            y2 <= 24'sd0;
            valid_pipe <= 3'b0;
            data_out <= 24'sd0;
            data_valid_out <= 1'b0;
        end else begin
            // valid流水线推进
            valid_pipe <= {valid_pipe[1:0], data_valid_in};
            // data_in流水线推进
            data_in_pipe[0] <= data_in;
            data_in_pipe[1] <= data_in_pipe[0];
            data_in_pipe[2] <= data_in_pipe[1];
            // x延迟流水线推进
            x_delay1 <= data_in_pipe[0];
            x_delay2 <= x_delay1;
            // y状态流水线推进（与输出对齐）
            y1_pipe[0] <= y1;
            y1_pipe[1] <= y1_pipe[0];
            y1_pipe[2] <= y1_pipe[1];
            y2_pipe[0] <= y2;
            y2_pipe[1] <= y2_pipe[0];
            y2_pipe[2] <= y2_pipe[1];
            // y状态更新
            if (v_all_valid) begin
                y2 <= y1;
                y1 <= saturate_q22(acc_sum);
            end
            // 输出数据与valid推进
            if (v_all_valid) begin
                data_out <= saturate_q22(acc_sum);
                data_valid_out <= 1'b1;
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end

    // ---- 乘法器实例化 ----
    opti_multiplier mul_b0_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[2]), .a(b0), .b(data_in_pipe[2]),
        .p(p_b0_x), .valid_out(v_b0_x), .debug_sum(dbg_sum_b0_x)
    );
    opti_multiplier mul_b1_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[2]), .a(b1), .b(x_delay1),
        .p(p_b1_x), .valid_out(v_b1_x), .debug_sum(dbg_sum_b1_x)
    );
    opti_multiplier mul_b2_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[2]), .a(b2), .b(x_delay2),
        .p(p_b2_x), .valid_out(v_b2_x), .debug_sum(dbg_sum_b2_x)
    );
    opti_multiplier mul_a1_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[2]), .a(a1), .b(y1_pipe[2]),
        .p(p_a1_y), .valid_out(v_a1_y), .debug_sum(dbg_sum_a1_y)
    );
    opti_multiplier mul_a2_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[2]), .a(a2), .b(y2_pipe[2]),
        .p(p_a2_y), .valid_out(v_a2_y), .debug_sum(dbg_sum_a2_y)
    );

    // ---- 累加 ----
    wire signed [26:0] acc_sum;
    assign acc_sum = 
        {{3{p_b0_x[23]}}, p_b0_x} + 
        {{3{p_b1_x[23]}}, p_b1_x} + 
        {{3{p_b2_x[23]}}, p_b2_x} -
        {{3{p_a1_y[23]}}, p_a1_y} -
        {{3{p_a2_y[23]}}, p_a2_y};

endmodule