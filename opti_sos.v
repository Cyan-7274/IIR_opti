// opti_sos_stage.v - Verilog-95兼容版，无增益校正
module opti_sos_stage (
    input         clk,
    input         rst_n,
    input         data_valid_in,
    input  [15:0] data_in,     // Q2.14
    input  [15:0] b0,
    input  [15:0] b1,
    input  [15:0] b2,
    input  [15:0] a1,
    input  [15:0] a2,
    output reg    data_valid_out,
    output reg [15:0] data_out
);

    // 状态变量
    reg [15:0] s1_reg, s2_reg;
    reg [15:0] x_reg, y_reg;
    reg [31:0] b0x_result, b1x_result, b2x_result, a1y_result, a2y_result;
    reg [2:0]  pipe_stage;
    reg        processing;
    reg [2:0]  mult_sel;
    reg        mult_en;
    reg [15:0] mult_a, mult_b;
    wire [31:0] mult_p;
    wire        mult_valid;

    // 乘法器选择
    parameter MULT_B0X = 3'd0;
    parameter MULT_B1X = 3'd1;
    parameter MULT_B2X = 3'd2;
    parameter MULT_A1Y = 3'd3;
    parameter MULT_A2Y = 3'd4;
    parameter FRAC_BITS = 14;

    // 实例化乘法器
    opti_multiplier u_multiplier (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (mult_en),
        .a      (mult_a),
        .b      (mult_b),
        .p      (mult_p),
        .valid  (mult_valid)
    );

    // 饱和函数 - Q2.14输出
    function [15:0] sat16;
        input [31:0] value;
        begin
            if (value[31]) begin
                if (value[31:29] != 3'b111)
                    sat16 = 16'h8001;
                else begin
                    sat16 = ((value + (1 << (FRAC_BITS-1))) >>> FRAC_BITS);
                    if (sat16 == 16'h8000) sat16 = 16'h8001;
                end
            end else begin
                if (value[31:29] != 3'b000)
                    sat16 = 16'h7FFF;
                else
                    sat16 = ((value + (1 << (FRAC_BITS-1))) >> FRAC_BITS);
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_sel <= MULT_B0X;
            mult_en <= 1'b0;
            mult_a <= 16'd0;
            mult_b <= 16'd0;
            processing <= 1'b0;
            pipe_stage <= 3'd0;
            data_valid_out <= 1'b0;
            data_out <= 16'd0;
            y_reg <= 16'd0;
            s1_reg <= 16'd0;
            s2_reg <= 16'd0;
        end else begin
            if (data_valid_in && !processing) begin
                x_reg <= data_in;
                processing <= 1'b1;
                pipe_stage <= 3'd0;
                mult_sel <= MULT_B0X;
                mult_a <= b0;
                mult_b <= data_in;
                mult_en <= 1'b1;
            end
            if (mult_valid && processing) begin
                case (mult_sel)
                    MULT_B0X: begin
                        b0x_result <= mult_p;
                        mult_sel <= MULT_B1X;
                        mult_a <= b1;
                        mult_b <= x_reg;
                        mult_en <= 1'b1;
                    end
                    MULT_B1X: begin
                        b1x_result <= mult_p;
                        y_reg <= sat16(b0x_result + {s1_reg, {FRAC_BITS{1'b0}}});
                        mult_sel <= MULT_A1Y;
                        mult_a <= a1;
                        mult_b <= y_reg;
                        mult_en <= 1'b1;
                    end
                    MULT_A1Y: begin
                        a1y_result <= mult_p;
                        mult_sel <= MULT_B2X;
                        mult_a <= b2;
                        mult_b <= x_reg;
                        mult_en <= 1'b1;
                    end
                    MULT_B2X: begin
                        b2x_result <= mult_p;
                        mult_sel <= MULT_A2Y;
                        mult_a <= a2;
                        mult_b <= y_reg;
                        mult_en <= 1'b1;
                    end
                    MULT_A2Y: begin
                        a2y_result <= mult_p;
                        s1_reg <= sat16(b1x_result - a1y_result + {s2_reg, {FRAC_BITS{1'b0}}});
                        s2_reg <= sat16(b2x_result - a2y_result);
                        data_out <= y_reg;
                        data_valid_out <= 1'b1;
                        processing <= 1'b0;
                        mult_en <= 1'b0;
                    end
                    default: mult_en <= 1'b0;
                endcase
                pipe_stage <= pipe_stage + 3'd1;
            end
            if (data_valid_out && !mult_valid)
                data_valid_out <= 1'b0;
        end
    end
endmodule