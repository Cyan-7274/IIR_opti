// opti_top.v
// 顶层IIR滤波器模块：5节流水线二阶节 (SOS)，Q2.14定点，16位输入/输出
// 依赖：opti_sos.v、opti_multiplier.v、opti_coeffs.v
// Verilog-2001标准

`timescale 1ns/1ps

module opti_top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [15:0] data_in,     // Q2.14 输入数据
    input  wire         valid_in,
    output wire signed [15:0] data_out,    // Q2.14 输出数据
    output wire         valid_out
);

    // ------------ 参数定义 --------------
    localparam NUM_SECTIONS = 5;
    localparam COEFFS_PER_SECTION = 5;
    localparam TOTAL_COEFFS = NUM_SECTIONS * COEFFS_PER_SECTION;

    // ------------ 系数ROM --------------
    // 5节，每节5个系数，全部Q2.14格式
    wire signed [15:0] coeff_rom [0:TOTAL_COEFFS-1];

    genvar ci;
    generate
        for (ci = 0; ci < TOTAL_COEFFS; ci = ci + 1) begin: COEFF_ROM_GEN
            opti_coeffs coeff_inst (
                .addr (ci[4:0]),
                .coeff(coeff_rom[ci])
            );
        end
    endgenerate

    // ------------ SOS流水线实例化 -----------
    wire signed [15:0] sos_data   [0:NUM_SECTIONS];
    wire               sos_valid  [0:NUM_SECTIONS];

    // -- 初始化输入
    assign sos_data[0]  = data_in;
    assign sos_valid[0] = valid_in;

    genvar s;
    generate
        for (s = 0; s < NUM_SECTIONS; s = s + 1) begin: SOS_CHAIN
            opti_sos u_sos (
                .clk      (clk),
                .rst_n    (rst_n),
                .data_in  (sos_data[s]),
                .valid_in (sos_valid[s]),
                .b0       (coeff_rom[s*COEFFS_PER_SECTION+0]),
                .b1       (coeff_rom[s*COEFFS_PER_SECTION+1]),
                .b2       (coeff_rom[s*COEFFS_PER_SECTION+2]),
                .a1       (coeff_rom[s*COEFFS_PER_SECTION+3]),
                .a2       (coeff_rom[s*COEFFS_PER_SECTION+4]),
                .data_out (sos_data[s+1]),
                .valid_out(sos_valid[s+1])
            );
        end
    endgenerate

    // ------------ 输出 --------------
    assign data_out  = sos_data[NUM_SECTIONS];
    assign valid_out = sos_valid[NUM_SECTIONS];

endmodule