// opti_top.v - Verilog-95兼容版顶层，手动实例化每级
module opti_top (
    input         clk,
    input         rst_n,
    input         start,
    input  [15:0] data_in,
    input         data_in_valid,
    output        filter_done,
    output [10:0] addr,
    output [15:0] data_out,
    output        data_out_valid,
    output        stable_out
);

    wire        pipeline_en;
    wire [15:0] sos_data0, sos_data1, sos_data2, sos_data3, sos_data4, sos_data5, sos_data6;
    wire        sos_valid0, sos_valid1, sos_valid2, sos_valid3, sos_valid4, sos_valid5, sos_valid6;

    wire [15:0] b0_0, b1_0, b2_0, a1_0, a2_0;
    wire [15:0] b0_1, b1_1, b2_1, a1_1, a2_1;
    wire [15:0] b0_2, b1_2, b2_2, a1_2, a2_2;
    wire [15:0] b0_3, b1_3, b2_3, a1_3, a2_3;
    wire [15:0] b0_4, b1_4, b2_4, a1_4, a2_4;
    wire [15:0] b0_5, b1_5, b2_5, a1_5, a2_5;

    assign sos_data0 = data_in;
    assign sos_valid0 = data_in_valid && pipeline_en;

    // 控制模块
    opti_control_pipeline u_control (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .data_in_valid (data_in_valid),
        .sos_out_valid (sos_valid6),
        .sos_out_data  (sos_data6),
        .filter_done   (filter_done),
        .pipeline_en   (pipeline_en),
        .addr          (addr),
        .data_out      (data_out),
        .data_out_valid(data_out_valid),
        .stable_out    (stable_out)
    );

    // 各级系数ROM
    opti_coeffs_fixed u_coeffs0 (.stage_index(3'd0), .b0(b0_0), .b1(b1_0), .b2(b2_0), .a1(a1_0), .a2(a2_0));
    opti_coeffs_fixed u_coeffs1 (.stage_index(3'd1), .b0(b0_1), .b1(b1_1), .b2(b2_1), .a1(a1_1), .a2(a2_1));
    opti_coeffs_fixed u_coeffs2 (.stage_index(3'd2), .b0(b0_2), .b1(b1_2), .b2(b2_2), .a1(a1_2), .a2(a2_2));
    opti_coeffs_fixed u_coeffs3 (.stage_index(3'd3), .b0(b0_3), .b1(b1_3), .b2(b2_3), .a1(a1_3), .a2(a2_3));
    opti_coeffs_fixed u_coeffs4 (.stage_index(3'd4), .b0(b0_4), .b1(b1_4), .b2(b2_4), .a1(a1_4), .a2(a2_4));
    opti_coeffs_fixed u_coeffs5 (.stage_index(3'd5), .b0(b0_5), .b1(b1_5), .b2(b2_5), .a1(a1_5), .a2(a2_5));

    // 6级流水线
    opti_sos_stage u_stage0 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid0), .data_in(sos_data0),
        .b0(b0_0), .b1(b1_0), .b2(b2_0), .a1(a1_0), .a2(a2_0),
        .data_valid_out(sos_valid1), .data_out(sos_data1)
    );
    opti_sos_stage u_stage1 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid1), .data_in(sos_data1),
        .b0(b0_1), .b1(b1_1), .b2(b2_1), .a1(a1_1), .a2(a2_1),
        .data_valid_out(sos_valid2), .data_out(sos_data2)
    );
    opti_sos_stage u_stage2 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid2), .data_in(sos_data2),
        .b0(b0_2), .b1(b1_2), .b2(b2_2), .a1(a1_2), .a2(a2_2),
        .data_valid_out(sos_valid3), .data_out(sos_data3)
    );
    opti_sos_stage u_stage3 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid3), .data_in(sos_data3),
        .b0(b0_3), .b1(b1_3), .b2(b2_3), .a1(a1_3), .a2(a2_3),
        .data_valid_out(sos_valid4), .data_out(sos_data4)
    );
    opti_sos_stage u_stage4 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid4), .data_in(sos_data4),
        .b0(b0_4), .b1(b1_4), .b2(b2_4), .a1(a1_4), .a2(a2_4),
        .data_valid_out(sos_valid5), .data_out(sos_data5)
    );
    opti_sos_stage u_stage5 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid5), .data_in(sos_data5),
        .b0(b0_5), .b1(b1_5), .b2(b2_5), .a1(a1_5), .a2(a2_5),
        .data_valid_out(sos_valid6), .data_out(sos_data6)
    );

endmodule