// opti_sos.v - 单节IIR SOS(二阶段)模块，适配opti_multiplier（Q2.22）
// Verilog-2001标准，所有声明前置，无parameter、无#实例化、无SV/VHDL语法
// 输入输出数据均为Q2.22格式
// 支持流水线滤波结构，乘累加全用乘法器模块

`timescale 1ns/1ps

module opti_sos (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [23:0] data_in,         // 输入数据 Q2.22
    input  wire         valid_in,
    input  wire signed [23:0] b0,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg  signed [23:0] data_out,        // 输出数据 Q2.22
    output reg          valid_out
);

    // -------- 内部寄存器 --------
    reg signed [23:0] x_z1, x_z2; // 输入延迟
    reg signed [23:0] y_z1, y_z2; // 输出延迟
    reg valid_d1, valid_d2, valid_d3, valid_d4;

    // -------- 级联流水线：输入缓存 --------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_z1 <= 24'd0; x_z2 <= 24'd0;
            y_z1 <= 24'd0; y_z2 <= 24'd0;
            valid_d1 <= 1'b0; valid_d2 <= 1'b0; valid_d3 <= 1'b0; valid_d4 <= 1'b0;
        end else begin
            x_z1 <= data_in;
            x_z2 <= x_z1;
            y_z1 <= data_out;
            y_z2 <= y_z1;
            valid_d1 <= valid_in;
            valid_d2 <= valid_d1;
            valid_d3 <= valid_d2;
            valid_d4 <= valid_d3;
        end
    end

    // -------- 并行乘法：输入与系数 --------
    // 级联5个乘法器实例，流水线结构
    wire signed [23:0] mult0_p, mult1_p, mult2_p, mult3_p, mult4_p;
    wire mult0_valid, mult1_valid, mult2_valid, mult3_valid, mult4_valid;

    opti_multiplier u_mult0 (
        .clk(clk), .rst_n(rst_n),
        .a(b0), .b(data_in), .valid_in(valid_in),
        .p(mult0_p), .valid_out(mult0_valid)
    );
    opti_multiplier u_mult1 (
        .clk(clk), .rst_n(rst_n),
        .a(b1), .b(x_z1), .valid_in(valid_d1),
        .p(mult1_p), .valid_out(mult1_valid)
    );
    opti_multiplier u_mult2 (
        .clk(clk), .rst_n(rst_n),
        .a(b2), .b(x_z2), .valid_in(valid_d2),
        .p(mult2_p), .valid_out(mult2_valid)
    );
    opti_multiplier u_mult3 (
        .clk(clk), .rst_n(rst_n),
        .a(a1), .b(y_z1), .valid_in(valid_d1),
        .p(mult3_p), .valid_out(mult3_valid)
    );
    opti_multiplier u_mult4 (
        .clk(clk), .rst_n(rst_n),
        .a(a2), .b(y_z2), .valid_in(valid_d2),
        .p(mult4_p), .valid_out(mult4_valid)
    );

    // -------- 累加运算 --------
    // 级联数据对齐，保证同步
    reg signed [23:0] acc_b, acc_a;
    reg valid_b, valid_a;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_b <= 24'd0;
            valid_b <= 1'b0;
        end else begin
            // b0*x[n] + b1*x[n-1]
            if (mult0_valid && mult1_valid)
                acc_b <= mult0_p + mult1_p;
            else
                acc_b <= 24'd0;
            valid_b <= mult2_valid;
        end
    end

    reg signed [23:0] acc_b2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_b2 <= 24'd0;
        end else begin
            // (b0*x[n]+b1*x[n-1])+b2*x[n-2]
            if (valid_b && mult2_valid)
                acc_b2 <= acc_b + mult2_p;
            else
                acc_b2 <= 24'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_a <= 24'd0;
            valid_a <= 1'b0;
        end else begin
            // a1*y[n-1] + a2*y[n-2]
            if (mult3_valid && mult4_valid)
                acc_a <= mult3_p + mult4_p;
            else
                acc_a <= 24'd0;
            valid_a <= mult4_valid;
        end
    end

    // -------- 主输出：差分结构 --------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 24'd0;
            valid_out <= 1'b0;
        end else begin
            // y[n] = b0*x[n]+b1*x[n-1]+b2*x[n-2] - (a1*y[n-1]+a2*y[n-2])
            // 数据对齐：acc_b2和acc_a应同步到同一拍
            if (valid_a)
                data_out <= acc_b2 - acc_a;
            else
                data_out <= 24'd0;
            valid_out <= valid_a;
        end
    end

endmodule