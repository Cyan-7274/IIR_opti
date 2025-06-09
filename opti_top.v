`timescale 1ns/1ps

module opti_top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed  [23:0] data_in,
    input  wire         valid_in,
    output wire signed  [23:0] data_out,
    output wire         valid_out
);

    // --- ROM系数读取信号 ---
    wire signed [23:0] b0_0, b1_0, b2_0, a1_0, a2_0;
    wire signed [23:0] b0_1, b1_1, b2_1, a1_1, a2_1;
    wire signed [23:0] b0_2, b1_2, b2_2, a1_2, a2_2;
    wire signed [23:0] b0_3, b1_3, b2_3, a1_3, a2_3;

    opti_coeffs u_coeffs_0(.addr(5'd0),  .coeff(b0_0));
    opti_coeffs u_coeffs_1(.addr(5'd1),  .coeff(b1_0));
    opti_coeffs u_coeffs_2(.addr(5'd2),  .coeff(b2_0));
    opti_coeffs u_coeffs_3(.addr(5'd3),  .coeff(a1_0));
    opti_coeffs u_coeffs_4(.addr(5'd4),  .coeff(a2_0));
    opti_coeffs u_coeffs_5(.addr(5'd5),  .coeff(b0_1));
    opti_coeffs u_coeffs_6(.addr(5'd6),  .coeff(b1_1));
    opti_coeffs u_coeffs_7(.addr(5'd7),  .coeff(b2_1));
    opti_coeffs u_coeffs_8(.addr(5'd8),  .coeff(a1_1));
    opti_coeffs u_coeffs_9(.addr(5'd9),  .coeff(a2_1));
    opti_coeffs u_coeffs_10(.addr(5'd10),.coeff(b0_2));
    opti_coeffs u_coeffs_11(.addr(5'd11),.coeff(b1_2));
    opti_coeffs u_coeffs_12(.addr(5'd12),.coeff(b2_2));
    opti_coeffs u_coeffs_13(.addr(5'd13),.coeff(a1_2));
    opti_coeffs u_coeffs_14(.addr(5'd14),.coeff(a2_2));
    opti_coeffs u_coeffs_15(.addr(5'd15),.coeff(b0_3));
    opti_coeffs u_coeffs_16(.addr(5'd16),.coeff(b1_3));
    opti_coeffs u_coeffs_17(.addr(5'd17),.coeff(b2_3));
    opti_coeffs u_coeffs_18(.addr(5'd18),.coeff(a1_3));
    opti_coeffs u_coeffs_19(.addr(5'd19),.coeff(a2_3));

    // --- 中间信号 ---
    wire signed [23:0] sos_out [0:4];
    wire sos_valid [0:4];

    assign sos_out[0] = data_in;
    assign sos_valid[0] = valid_in;

    // --- 四级级联 ---
    opti_sos u_sos0 (
        .clk(clk), .rst_n(rst_n),
        .data_in(sos_out[0]), .valid_in(sos_valid[0]),
        .b0(b0_0), .b1(b1_0), .b2(b2_0), .a1(a1_0), .a2(a2_0),
        .data_out(sos_out[1]), .valid_out(sos_valid[1])
    );
    opti_sos u_sos1 (
        .clk(clk), .rst_n(rst_n),
        .data_in(sos_out[1]), .valid_in(sos_valid[1]),
        .b0(b0_1), .b1(b1_1), .b2(b2_1), .a1(a1_1), .a2(a2_1),
        .data_out(sos_out[2]), .valid_out(sos_valid[2])
    );
    opti_sos u_sos2 (
        .clk(clk), .rst_n(rst_n),
        .data_in(sos_out[2]), .valid_in(sos_valid[2]),
        .b0(b0_2), .b1(b1_2), .b2(b2_2), .a1(a1_2), .a2(a2_2),
        .data_out(sos_out[3]), .valid_out(sos_valid[3])
    );
    opti_sos u_sos3 (
        .clk(clk), .rst_n(rst_n),
        .data_in(sos_out[3]), .valid_in(sos_valid[3]),
        .b0(b0_3), .b1(b1_3), .b2(b2_3), .a1(a1_3), .a2(a2_3),
        .data_out(sos_out[4]), .valid_out(sos_valid[4])
    );

    assign data_out = sos_out[4];
    assign valid_out = sos_valid[4];

endmodule