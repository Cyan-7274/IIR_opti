module opti_top (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [23:0] data_in,
    input  wire               data_valid_in,
    output wire signed [23:0] data_out,
    output wire               data_valid_out,

    // 便于trace的信号（全部output，供tb采集）
    output wire signed [23:0] u_sos0_data_in,
    output wire               u_sos0_data_valid_in,
    output wire signed [23:0] u_sos0_data_out,
    output wire               u_sos0_data_valid_out,
    output wire signed [23:0] u_sos1_data_in,
    output wire               u_sos1_data_valid_in,
    output wire signed [23:0] u_sos1_data_out,
    output wire               u_sos1_data_valid_out,
    output wire signed [23:0] u_sos2_data_in,
    output wire               u_sos2_data_valid_in,
    output wire signed [23:0] u_sos2_data_out,
    output wire               u_sos2_data_valid_out,
    output wire signed [23:0] u_sos3_data_in,
    output wire               u_sos3_data_valid_in,
    output wire signed [23:0] u_sos3_data_out,
    output wire               u_sos3_data_valid_out,

    // sos0内部trace信号
    output wire signed [23:0] u_sos0_w0,
    output wire signed [23:0] u_sos0_w1,
    output wire signed [23:0] u_sos0_w2,
    output wire signed [23:0] u_sos0_b0_p,
    output wire signed [23:0] u_sos0_b1_p,
    output wire signed [23:0] u_sos0_b2_p,
    output wire signed [23:0] u_sos0_a1_p,
    output wire signed [23:0] u_sos0_a2_p,
    output wire [14:0]        u_sos0_valid_pipe
);

    wire signed [23:0] y0, y1, y2, y3;
    wire vld0, vld1, vld2, vld3;
    wire [1:0] sos_idx0 = 2'd0, sos_idx1 = 2'd1, sos_idx2 = 2'd2, sos_idx3 = 2'd3;

    // --- sos0 ---
    wire signed [23:0] sos0_w0, sos0_w1, sos0_w2;
    wire signed [23:0] sos0_b0_p, sos0_b1_p, sos0_b2_p, sos0_a1_p, sos0_a2_p;
    wire [14:0]        sos0_valid_pipe;

    wire signed [23:0] sos0_data_in, sos0_data_out;
    wire               sos0_data_valid_in, sos0_data_valid_out;

    opti_sos u_sos0 (
        .clk(clk), .rst_n(rst_n),
        .data_in(data_in),
        .data_valid_in(data_valid_in),
        .sos_idx(sos_idx0),
        .data_out(y0),
        .data_valid_out(vld0),
        // trace
        .trace_data_in(sos0_data_in),
        .trace_data_valid_in(sos0_data_valid_in),
        .trace_data_out(sos0_data_out),
        .trace_data_valid_out(sos0_data_valid_out),
        .trace_w0(sos0_w0),
        .trace_w1(sos0_w1),
        .trace_w2(sos0_w2),
        .trace_b0_p(sos0_b0_p),
        .trace_b1_p(sos0_b1_p),
        .trace_b2_p(sos0_b2_p),
        .trace_a1_p(sos0_a1_p),
        .trace_a2_p(sos0_a2_p),
        .trace_valid_pipe(sos0_valid_pipe)
    );
    // --- sos1 ---
    wire signed [23:0] sos1_data_in, sos1_data_out;
    wire               sos1_data_valid_in, sos1_data_valid_out;

    opti_sos u_sos1 (
        .clk(clk), .rst_n(rst_n),
        .data_in(y0),
        .data_valid_in(vld0),
        .sos_idx(sos_idx1),
        .data_out(y1),
        .data_valid_out(vld1),
        .trace_data_in(sos1_data_in),
        .trace_data_valid_in(sos1_data_valid_in),
        .trace_data_out(sos1_data_out),
        .trace_data_valid_out(sos1_data_valid_out),
        .trace_w0(), .trace_w1(), .trace_w2(),
        .trace_b0_p(), .trace_b1_p(), .trace_b2_p(),
        .trace_a1_p(), .trace_a2_p(),
        .trace_valid_pipe()
    );
    // --- sos2 ---
    wire signed [23:0] sos2_data_in, sos2_data_out;
    wire               sos2_data_valid_in, sos2_data_valid_out;

    opti_sos u_sos2 (
        .clk(clk), .rst_n(rst_n),
        .data_in(y1),
        .data_valid_in(vld1),
        .sos_idx(sos_idx2),
        .data_out(y2),
        .data_valid_out(vld2),
        .trace_data_in(sos2_data_in),
        .trace_data_valid_in(sos2_data_valid_in),
        .trace_data_out(sos2_data_out),
        .trace_data_valid_out(sos2_data_valid_out),
        .trace_w0(), .trace_w1(), .trace_w2(),
        .trace_b0_p(), .trace_b1_p(), .trace_b2_p(),
        .trace_a1_p(), .trace_a2_p(),
        .trace_valid_pipe()
    );
    // --- sos3 ---
    wire signed [23:0] sos3_data_in, sos3_data_out;
    wire               sos3_data_valid_in, sos3_data_valid_out;

    opti_sos u_sos3 (
        .clk(clk), .rst_n(rst_n),
        .data_in(y2),
        .data_valid_in(vld2),
        .sos_idx(sos_idx3),
        .data_out(y3),
        .data_valid_out(vld3),
        .trace_data_in(sos3_data_in),
        .trace_data_valid_in(sos3_data_valid_in),
        .trace_data_out(sos3_data_out),
        .trace_data_valid_out(sos3_data_valid_out),
        .trace_w0(), .trace_w1(), .trace_w2(),
        .trace_b0_p(), .trace_b1_p(), .trace_b2_p(),
        .trace_a1_p(), .trace_a2_p(),
        .trace_valid_pipe()
    );

    assign data_out = y3;
    assign data_valid_out = vld3;

    // 分别输出每级数据/valid（便于tb采集）
    assign u_sos0_data_in = sos0_data_in;
    assign u_sos0_data_valid_in = sos0_data_valid_in;
    assign u_sos0_data_out = sos0_data_out;
    assign u_sos0_data_valid_out = sos0_data_valid_out;

    assign u_sos1_data_in = sos1_data_in;
    assign u_sos1_data_valid_in = sos1_data_valid_in;
    assign u_sos1_data_out = sos1_data_out;
    assign u_sos1_data_valid_out = sos1_data_valid_out;

    assign u_sos2_data_in = sos2_data_in;
    assign u_sos2_data_valid_in = sos2_data_valid_in;
    assign u_sos2_data_out = sos2_data_out;
    assign u_sos2_data_valid_out = sos2_data_valid_out;

    assign u_sos3_data_in = sos3_data_in;
    assign u_sos3_data_valid_in = sos3_data_valid_in;
    assign u_sos3_data_out = sos3_data_out;
    assign u_sos3_data_valid_out = sos3_data_valid_out;

    assign u_sos0_w0 = sos0_w0;
    assign u_sos0_w1 = sos0_w1;
    assign u_sos0_w2 = sos0_w2;

    assign u_sos0_b0_p = sos0_b0_p;
    assign u_sos0_b1_p = sos0_b1_p;
    assign u_sos0_b2_p = sos0_b2_p;
    assign u_sos0_a1_p = sos0_a1_p;
    assign u_sos0_a2_p = sos0_a2_p;
    assign u_sos0_valid_pipe = sos0_valid_pipe;

endmodule