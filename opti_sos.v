module opti_sos_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid_in,
    input  wire [15:0] data_in,
    input  wire [15:0] b0,
    input  wire [15:0] b1,
    input  wire [15:0] b2,
    input  wire [15:0] a1,
    input  wire [15:0] a2,
    output reg         data_valid_out,
    output reg  [15:0] data_out
);

    // 状态寄存器
    reg [31:0] w1, w2;
    reg [15:0] data_in_d;
    reg        data_valid_in_d;

    // 保存一拍的输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_d <= 0;
            data_valid_in_d <= 0;
        end else begin
            data_in_d <= data_in;
            data_valid_in_d <= data_valid_in;
        end
    end

    // --- Booth乘法器实例 ---
    // 1. b0 * w_new（w_new需提前算好，见下）
    reg [31:0] w_new;
    wire [31:0] p_b0_wnew, p_b1_w1, p_b2_w2, p_a1_w1, p_a2_w2;
    wire        v_b0_wnew, v_b1_w1, v_b2_w2, v_a1_w1, v_a2_w2;

    // 先计算a1*w1, a2*w2（老w1/w2）
    booth_multiplier_pipe mul_a1_w1(
        .clk(clk), .rst_n(rst_n), .start(data_valid_in), .a(a1), .b(w1[27:12]), .valid(v_a1_w1), .p(p_a1_w1)
    );
    booth_multiplier_pipe mul_a2_w2(
        .clk(clk), .rst_n(rst_n), .start(data_valid_in), .a(a2), .b(w2[27:12]), .valid(v_a2_w2), .p(p_a2_w2)
    );

    // w_new = data_in左移14位 - a1*w1 - a2*w2（需等待a1*w1和a2*w2都valid）
    // pipeline控制
    reg        wnew_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wnew_valid <= 0;
        end else begin
            wnew_valid <= v_a1_w1 & v_a2_w2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_new <= 0;
        end else if (v_a1_w1 & v_a2_w2) begin
            w_new <= $signed({data_in_d,14'd0}) - (p_a1_w1>>>14) - (p_a2_w2>>>14);
            // 注意data_in_d与w1/w2配对
        end
    end

    // b0*w_new, b1*w1, b2*w2（此时输入为新w_new、w1、w2）
    booth_multiplier_pipe mul_b0_wnew(
        .clk(clk), .rst_n(rst_n), .start(wnew_valid), .a(b0), .b(w_new[27:12]), .valid(v_b0_wnew), .p(p_b0_wnew)
    );
    booth_multiplier_pipe mul_b1_w1(
        .clk(clk), .rst_n(rst_n), .start(wnew_valid), .a(b1), .b(w1[27:12]), .valid(v_b1_w1), .p(p_b1_w1)
    );
    booth_multiplier_pipe mul_b2_w2(
        .clk(clk), .rst_n(rst_n), .start(wnew_valid), .a(b2), .b(w2[27:12]), .valid(v_b2_w2), .p(p_b2_w2)
    );

    // 输出累加，valid信号对齐
    wire [31:0] sos_out_full = (p_b0_wnew>>>14) + (p_b1_w1>>>14) + (p_b2_w2>>>14);

    // 饱和函数
    function [15:0] sat16;
        input [31:0] value;
        begin
            if (value[31:30] == 2'b01)      sat16 = 16'sh7FFF;
            else if (value[31:30] == 2'b10) sat16 = 16'sh8000;
            else                            sat16 = value[27:12];
        end
    endfunction

    // 状态寄存器与输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w1 <= 0;
            w2 <= 0;
            data_out <= 0;
            data_valid_out <= 0;
        end else if (v_b0_wnew & v_b1_w1 & v_b2_w2) begin
            // 只有全部乘法结果都valid时才输出
            w2 <= w1;
            w1 <= w_new;
            data_out <= sat16(sos_out_full);
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end
endmodule