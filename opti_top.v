module opti_top (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [23:0] data_in,
    input  wire               data_valid_in,
    input  wire [1:0]         sos0_idx,
    input  wire [1:0]         sos1_idx,
    input  wire [1:0]         sos2_idx,
    input  wire [1:0]         sos3_idx,
    output wire signed [23:0] data_out,
    output wire               data_valid_out,
    // 只暴露sos0的trace
    output wire signed [23:0] trace_w0,
    output wire signed [23:0] trace_w1,
    output wire signed [23:0] trace_w2,
    output wire signed [23:0] trace_data_in,
    output wire signed [23:0] trace_data_out,
    output wire               trace_data_valid_in,
    output wire               trace_data_valid_out,
    output wire signed [23:0] trace_b0_p,
    output wire signed [23:0] trace_b1_p,
    output wire signed [23:0] trace_b2_p,
    output wire signed [23:0] trace_a1_p,
    output wire signed [23:0] trace_a2_p
);

    wire signed [23:0] d0_out, d1_out, d2_out, d3_out;
    wire v0_out, v1_out, v2_out, v3_out;

    opti_sos u_sos0 (
        .clk(clk), .rst_n(rst_n),
        .data_in(data_in),
        .data_valid_in(data_valid_in),
        .sos_idx(sos0_idx),
        .data_out(d0_out),
        .data_valid_out(v0_out),
        .trace_w0(trace_w0), .trace_w1(trace_w1), .trace_w2(trace_w2),
        .trace_data_in(trace_data_in), .trace_data_out(trace_data_out),
        .trace_data_valid_in(trace_data_valid_in), .trace_data_valid_out(trace_data_valid_out),
        .trace_b0_p(trace_b0_p), .trace_b1_p(trace_b1_p), .trace_b2_p(trace_b2_p),
        .trace_a1_p(trace_a1_p), .trace_a2_p(trace_a2_p)
    );
    opti_sos u_sos1 (
        .clk(clk), .rst_n(rst_n),
        .data_in(d0_out),
        .data_valid_in(v0_out),
        .sos_idx(sos1_idx),
        .data_out(d1_out),
        .data_valid_out(v1_out),
        .trace_w0(), .trace_w1(), .trace_w2(),
        .trace_data_in(), .trace_data_out(),
        .trace_data_valid_in(), .trace_data_valid_out(),
        .trace_b0_p(), .trace_b1_p(), .trace_b2_p(),
        .trace_a1_p(), .trace_a2_p()
    );
    opti_sos u_sos2 (
        .clk(clk), .rst_n(rst_n),
        .data_in(d1_out),
        .data_valid_in(v1_out),
        .sos_idx(sos2_idx),
        .data_out(d2_out),
        .data_valid_out(v2_out),
        .trace_w0(), .trace_w1(), .trace_w2(),
        .trace_data_in(), .trace_data_out(),
        .trace_data_valid_in(), .trace_data_valid_out(),
        .trace_b0_p(), .trace_b1_p(), .trace_b2_p(),
        .trace_a1_p(), .trace_a2_p()
    );
    opti_sos u_sos3 (
        .clk(clk), .rst_n(rst_n),
        .data_in(d2_out),
        .data_valid_in(v2_out),
        .sos_idx(sos3_idx),
        .data_out(d3_out),
        .data_valid_out(v3_out),
        .trace_w0(), .trace_w1(), .trace_w2(),
        .trace_data_in(), .trace_data_out(),
        .trace_data_valid_in(), .trace_data_valid_out(),
        .trace_b0_p(), .trace_b1_p(), .trace_b2_p(),
        .trace_a1_p(), .trace_a2_p()
    );

    assign data_out = d3_out;
    assign data_valid_out = v3_out;

endmodule