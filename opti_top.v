module opti_top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire signed [23:0] data_in,
    input  wire         data_in_valid,
    output wire         filter_done,
    output wire [10:0]  addr,
    output wire signed [23:0] data_out,
    output wire         data_out_valid,
    output wire         stable_out,
    output wire signed [47:0] dbg_sum_b0_x_0,
    output wire signed [47:0] dbg_sum_b1_x_0,
    output wire signed [47:0] dbg_sum_b2_x_0,
    output wire signed [47:0] dbg_sum_a1_y_0,
    output wire signed [47:0] dbg_sum_a2_y_0
);

    wire pipeline_en;

    wire signed [23:0] sos_data0, sos_data1, sos_data2, sos_data3, sos_data4;
    wire sos_valid0, sos_valid1, sos_valid2, sos_valid3, sos_valid4;

    // 系数信号建议全显式声明
    wire signed [23:0] b0_0, b1_0, b2_0, a1_0, a2_0;
    wire signed [23:0] b0_1, b1_1, b2_1, a1_1, a2_1;
    wire signed [23:0] b0_2, b1_2, b2_2, a1_2, a2_2;
    wire signed [23:0] b0_3, b1_3, b2_3, a1_3, a2_3;

    assign sos_data0  = data_in;
    assign sos_valid0 = data_in_valid && pipeline_en;

    // 后续实例化与原代码一致...

    // ...省略，见上代码...

endmodule