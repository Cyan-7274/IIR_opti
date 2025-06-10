// opti_sos.v - 主流DF-II IIR SOS，高效安全无latch无trunc警告
`timescale 1ns/1ps

module opti_sos (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [23:0] data_in,
    input  wire         valid_in,
    input  wire signed [23:0] b0,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg  signed [23:0] data_out,
    output reg          valid_out
);

    // 输入/延迟线
    reg signed [23:0] x_z1, x_z2;
    reg signed [23:0] y_z1, y_z2;

    // 乘法器输出
    wire signed [47:0] mult0_p, mult1_p, mult2_p, mult3_p, mult4_p;
    wire mult0_valid, mult1_valid, mult2_valid, mult3_valid, mult4_valid;

    opti_multiplier u_mult0 (.clk(clk), .rst_n(rst_n), .a(b0), .b(data_in), .valid_in(valid_in), .p(mult0_p), .valid_out(mult0_valid));
    opti_multiplier u_mult1 (.clk(clk), .rst_n(rst_n), .a(b1), .b(x_z1),    .valid_in(valid_in), .p(mult1_p), .valid_out(mult1_valid));
    opti_multiplier u_mult2 (.clk(clk), .rst_n(rst_n), .a(b2), .b(x_z2),    .valid_in(valid_in), .p(mult2_p), .valid_out(mult2_valid));
    opti_multiplier u_mult3 (.clk(clk), .rst_n(rst_n), .a(a1), .b(y_z1),    .valid_in(valid_in), .p(mult3_p), .valid_out(mult3_valid));
    opti_multiplier u_mult4 (.clk(clk), .rst_n(rst_n), .a(a2), .b(y_z2),    .valid_in(valid_in), .p(mult4_p), .valid_out(mult4_valid));

    wire all_mult_valid = mult0_valid & mult1_valid & mult2_valid & mult3_valid & mult4_valid;

    reg signed [47:0] sum_b, sum_a;
    reg signed [23:0] w_n;
    reg valid_out_r;

    // 差分方程累加
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_b <= 0; sum_a <= 0; w_n <= 0;
            data_out <= 0; valid_out_r <= 0;
        end else if (all_mult_valid) begin
            sum_b <= mult0_p + mult1_p + mult2_p;
            sum_a <= mult3_p + mult4_p;
            // Q4.44 -> Q2.22
            w_n <= ((mult0_p + mult1_p + mult2_p) - (mult3_p + mult4_p)) >>> 22;
            data_out <= ((mult0_p + mult1_p + mult2_p) - (mult3_p + mult4_p)) >>> 22;
            valid_out_r <= 1'b1;
        end else begin
            valid_out_r <= 1'b0;
        end
    end

    assign valid_out = valid_out_r;

    // 输入侧延迟线采样点推进
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_z1 <= 0; x_z2 <= 0;
        end else if (valid_in) begin
            x_z2 <= x_z1;
            x_z1 <= data_in;
        end
    end

    // 反馈延迟线：乘法器输出ready那拍推进
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_z1 <= 0; y_z2 <= 0;
        end else if (all_mult_valid) begin
            y_z2 <= y_z1;
            y_z1 <= w_n; // w_n已安全右移
        end else begin
            y_z1 <= y_z1;
            y_z2 <= y_z2;
        end
    end

endmodule