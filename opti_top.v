// 顶层模块，适配Q2.22格式和新课题参数，4级Chebyshev II IIR滤波器（Verilog-2001标准，声明规范）
module opti_top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire signed [23:0] data_in,        // Q2.22格式
    input  wire         data_in_valid,
    output wire         filter_done,
    output wire [10:0]  addr,
    output wire signed [23:0] data_out,       // Q2.22
    output wire         data_out_valid,
    output wire         stable_out
);

    // 声明全部在前面（Verilog-2001规范）
    wire signed [23:0] sos_data [0:4];
    wire sos_valid [0:4];
    wire signed [23:0] b0 [0:3], b1 [0:3], b2 [0:3], a1 [0:3], a2 [0:3];
    wire pipeline_en;

    assign sos_data[0]  = data_in;
    assign sos_valid[0] = data_in_valid && pipeline_en;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_coeff_sos
            opti_coeffs u_coeff (
                .sos_idx(i[1:0]),
                .b0(b0[i]), .b1(b1[i]), .b2(b2[i]), .a1(a1[i]), .a2(a2[i])
            );
            opti_sos u_sos (
                .clk(clk), .rst_n(rst_n),
                .data_valid_in(sos_valid[i]),
                .data_in(sos_data[i]),
                .b0(b0[i]), .b1(b1[i]), .b2(b2[i]), .a1(a1[i]), .a2(a2[i]),
                .data_valid_out(sos_valid[i+1]),
                .data_out(sos_data[i+1])
            );
        end
    endgenerate

    opti_control u_ctrl (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in_valid(data_in_valid),
        .sos_out_valid(sos_valid[4]),
        .sos_out_data(sos_data[4]),
        .filter_done(filter_done), .pipeline_en(pipeline_en),
        .addr(addr), .data_out(data_out),
        .data_out_valid(data_out_valid), .stable_out(stable_out)
    );

endmodule