// 转置二型IIR SOS节，高速定点Q2.14实现，流水线Booth-4乘法器
module opti_sos (
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

    // 转置二型状态寄存器
    reg signed [31:0] s1, s2; // Q4.28，保证累加不溢出

    // 延迟数据有效信号，与流水线乘法器对齐
    reg data_valid_in_d [0:2];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0;i<3;i=i+1) data_valid_in_d[i] <= 1'b0;
        end else begin
            data_valid_in_d[0] <= data_valid_in;
            for (i=1;i<3;i=i+1)
                data_valid_in_d[i] <= data_valid_in_d[i-1];
        end
    end

    // ----- 乘法部分 -----
    // Q2.14 * Q2.14 => Q4.28
    wire [31:0] p_b0_x, p_b1_x, p_b2_x, p_a1_y, p_a2_y;
    wire        v_b0_x, v_b1_x, v_b2_x, v_a1_y, v_a2_y;

    // 输入x延迟，与流水线乘积对齐
    reg [15:0] x_delay [0:2];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0;i<3;i=i+1) x_delay[i] <= 0;
        end else begin
            x_delay[0] <= data_in;
            for (i=1;i<3;i=i+1)
                x_delay[i] <= x_delay[i-1];
        end
    end

    // y(n-1)、y(n-2)保存，加法做Q4.28
    reg signed [31:0] y1, y2;

    // 前馈部分
    opti_multiplier mul_b0_x(
        .clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(b0), .b(data_in), .p(p_b0_x), .valid_out(v_b0_x)
    );
    opti_multiplier mul_b1_x(
        .clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(b1), .b(x_delay[1]), .p(p_b1_x), .valid_out(v_b1_x)
    );
    opti_multiplier mul_b2_x(
        .clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(b2), .b(x_delay[2]), .p(p_b2_x), .valid_out(v_b2_x)
    );

    // 反馈部分
    opti_multiplier mul_a1_y(
        .clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(a1), .b(y1[29:14]), .p(p_a1_y), .valid_out(v_a1_y)
    );
    opti_multiplier mul_a2_y(
        .clk(clk), .rst_n(rst_n), .valid_in(data_valid_in), .a(a2), .b(y2[29:14]), .p(p_a2_y), .valid_out(v_a2_y)
    );

    // --- 累加输出 ---
    // Q4.28 = sum(前馈) - sum(反馈)
    wire signed [33:0] acc_sum = 
        {{2{p_b0_x[31]}}, p_b0_x} + 
        {{2{p_b1_x[31]}}, p_b1_x} + 
        {{2{p_b2_x[31]}}, p_b2_x} -
        {{2{p_a1_y[31]}}, p_a1_y} -
        {{2{p_a2_y[31]}}, p_a2_y};

    // Q4.28 -> Q2.14，取高位（含符号扩展），用于输出和反馈
    wire signed [19:0] q2_14_val = acc_sum[33:14];

    // 饱和处理
    reg [15:0] y_q2_14;
    always @(*) begin
        if (q2_14_val[19:15] == {5{q2_14_val[19]}})
            y_q2_14 = q2_14_val[15:0];
        else if (q2_14_val[19] == 1'b0)
            y_q2_14 = 16'h7FFF;
        else
            y_q2_14 = 16'h8000;
    end

    // --- 状态更新 ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y1 <= 0; y2 <= 0;
            data_out <= 0;
            data_valid_out <= 1'b0;
        end else if (v_b0_x & v_b1_x & v_b2_x & v_a1_y & v_a2_y) begin
            // 输出
            data_out <= y_q2_14;
            data_valid_out <= 1'b1;
            // 状态寄存器更新（保持Q4.28格式）
            y2 <= y1;
            y1 <= { {18{y_q2_14[15]}}, y_q2_14 }; // Q2.14 -> Q4.28符号扩展
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule