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
    output wire         stable_out
    // debug_sum相关端口全部去掉
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

    // 第1级
    opti_coeffs u_coeff0 (.sos_idx(2'd0), .b0(b0_0), .b1(b1_0), .b2(b2_0), .a1(a1_0), .a2(a2_0));
    opti_sos u_sos0 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid0),
        .data_in(sos_data0),
        .b0(b0_0), .b1(b1_0), .b2(b2_0), .a1(a1_0), .a2(a2_0),
        .data_valid_out(sos_valid1),
        .data_out(sos_data1)
        // debug_sum信号全部删除
    );
    // 第2级
    opti_coeffs u_coeff1 (.sos_idx(2'd1), .b0(b0_1), .b1(b1_1), .b2(b2_1), .a1(a1_1), .a2(a2_1));
    opti_sos u_sos1 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid1),
        .data_in(sos_data1),
        .b0(b0_1), .b1(b1_1), .b2(b2_1), .a1(a1_1), .a2(a2_1),
        .data_valid_out(sos_valid2),
        .data_out(sos_data2)
    );
    // 第3级
    opti_coeffs u_coeff2 (.sos_idx(2'd2), .b0(b0_2), .b1(b1_2), .b2(b2_2), .a1(a1_2), .a2(a2_2));
    opti_sos u_sos2 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid2),
        .data_in(sos_data2),
        .b0(b0_2), .b1(b1_2), .b2(b2_2), .a1(a1_2), .a2(a2_2),
        .data_valid_out(sos_valid3),
        .data_out(sos_data3)
    );
    // 第4级
    opti_coeffs u_coeff3 (.sos_idx(2'd3), .b0(b0_3), .b1(b1_3), .b2(b2_3), .a1(a1_3), .a2(a2_3));
    opti_sos u_sos3 (
        .clk(clk), .rst_n(rst_n),
        .data_valid_in(sos_valid3),
        .data_in(sos_data3),
        .b0(b0_3), .b1(b1_3), .b2(b2_3), .a1(a1_3), .a2(a2_3),
        .data_valid_out(sos_valid4),
        .data_out(sos_data4)
    );

    opti_control u_ctrl (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in_valid(data_in_valid),
        .sos_out_valid(sos_valid4),
        .sos_out_data(sos_data4),
        .filter_done(filter_done), .pipeline_en(pipeline_en),
        .addr(addr), .data_out(data_out),
        .data_out_valid(data_out_valid), .stable_out(stable_out)
    );

endmodule