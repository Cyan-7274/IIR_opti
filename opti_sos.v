module opti_sos_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid_in,
    input  wire [15:0] data_in,      // Q2.14格式
    input  wire [15:0] b0, b1, b2,   // Q2.14
    input  wire [15:0] a1, a2,       // Q2.14
    output reg         data_valid_out,
    output reg  [15:0] data_out      // Q2.14格式
);

    // 状态寄存器，z^-1和z^-2
    reg signed [15:0] x_1, x_2;
    reg signed [15:0] y_1, y_2;

    // 输入缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_1 <= 16'd0;
            x_2 <= 16'd0;
            y_1 <= 16'd0;
            y_2 <= 16'd0;
        end else if (data_valid_in) begin
            x_2 <= x_1;
            x_1 <= data_in;
            y_2 <= y_1;
            y_1 <= data_out;
        end
    end

    // 乘法与累加
    // b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    // 每步均Q2.14格式，乘法结果Q4.28，需做溢出保护和格式转换

    // 乘法结果
    wire signed [31:0] mult_b0 = $signed(b0) * $signed(data_in); // Q4.28
    wire signed [31:0] mult_b1 = $signed(b1) * $signed(x_1);     // Q4.28
    wire signed [31:0] mult_b2 = $signed(b2) * $signed(x_2);     // Q4.28
    wire signed [31:0] mult_a1 = $signed(a1) * $signed(y_1);     // Q4.28
    wire signed [31:0] mult_a2 = $signed(a2) * $signed(y_2);     // Q4.28

    // 格式转换和溢出保护函数
    function automatic [15:0] q428_to_q214;
        input signed [31:0] in32;
        reg signed [31:0] shifted;
        reg pos_overflow, neg_overflow;
        reg signed [15:0] Q2_14_MAX, Q2_14_MIN;
        begin
            shifted      = in32 >>> 14;
            Q2_14_MAX    = 16'sb0111_1111_1111_1111;
            Q2_14_MIN    = 16'sb1000_0000_0000_0000;
            // 溢出判断：高位不是全符号扩展，且方向一致
            pos_overflow = (shifted[31:17] != {15{shifted[16]}}) && (shifted[16] == 0);
            neg_overflow = (shifted[31:17] != {15{shifted[16]}}) && (shifted[16] == 1);
            if (pos_overflow)
                q428_to_q214 = Q2_14_MAX;
            else if (neg_overflow)
                q428_to_q214 = Q2_14_MIN;
            else
                q428_to_q214 = shifted[16:1];
        end
    endfunction

    // 各项溢出保护
    wire signed [15:0] term_b0 = q428_to_q214(mult_b0);
    wire signed [15:0] term_b1 = q428_to_q214(mult_b1);
    wire signed [15:0] term_b2 = q428_to_q214(mult_b2);
    wire signed [15:0] term_a1 = q428_to_q214(mult_a1);
    wire signed [15:0] term_a2 = q428_to_q214(mult_a2);

    // 累加
    wire signed [17:0] sum_b = $signed(term_b0) + $signed(term_b1) + $signed(term_b2); // 多两位，防止溢出
    wire signed [17:0] sum_a = $signed(term_a1) + $signed(term_a2);

    wire signed [17:0] y_temp = sum_b - sum_a;

    // 最终溢出保护
    wire signed [15:0] Q2_14_MAX = 16'sb0111_1111_1111_1111;
    wire signed [15:0] Q2_14_MIN = 16'sb1000_0000_0000_0000;
    wire pos_overflow_final = (y_temp > Q2_14_MAX);
    wire neg_overflow_final = (y_temp < Q2_14_MIN);

    wire signed [15:0] y_q2_14 = pos_overflow_final ? Q2_14_MAX :
                                 neg_overflow_final ? Q2_14_MIN :
                                 y_temp[15:0];

    // 输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'd0;
            data_valid_out <= 1'b0;
        end else if (data_valid_in) begin
            data_out <= y_q2_14;
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule