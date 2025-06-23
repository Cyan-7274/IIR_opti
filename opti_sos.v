module opti_sos(
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [15:0] data_in,  // Q2.14
    input  wire         valid_in,
    input  wire signed [15:0] b0, b1, b2,
    input  wire signed [15:0] a1, a2,
    output reg  signed [15:0] data_out, // Q2.14
    output reg          valid_out
);

    // 历史线与寄存器
    reg signed [15:0] x_z1, x_z2;
    reg signed [15:0] y_z1, y_z2;
    reg signed [15:0] x_new, x_reg1, x_reg2;
    reg valid_T1, valid_T2, valid_T3;

    // 乘法器输出
    wire signed [15:0] p_b0, p_b1, p_b2, p_a1, p_a2;

    // 累加与饱和处理
    wire signed [18:0] acc_sum_wire;
    wire overflow_pos, overflow_neg;
    wire signed [15:0] acc_sum_clip;

    // T0历史线推进、前馈锁存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_z1 <= 16'd0; x_z2 <= 16'd0;
            y_z1 <= 16'd0; y_z2 <= 16'd0;
            x_new <= 16'd0; x_reg1 <= 16'd0; x_reg2 <= 16'd0;
            valid_T1 <= 1'b0;
        end else begin
            if (valid_in) begin
                x_new <= data_in;
                x_reg1 <= x_z1;
                x_reg2 <= x_z2;
                x_z2 <= x_z1;
                x_z1 <= data_in;
                y_z2 <= y_z1;
                y_z1 <= data_out;
            end
            valid_T1 <= valid_in;
        end
    end

    // valid流水
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_T2 <= 1'b0;
            valid_T3 <= 1'b0;
        end else begin
            valid_T2 <= valid_T1;
            valid_T3 <= valid_T2;
        end
    end

    // 乘法器实例化
    opti_multiplier mul_b0(.clk(clk), .rst_n(rst_n), .a(b0), .b(x_new),   .valid_in(valid_T1), .p(p_b0), .valid_out());
    opti_multiplier mul_b1(.clk(clk), .rst_n(rst_n), .a(b1), .b(x_reg1),  .valid_in(valid_T1), .p(p_b1), .valid_out());
    opti_multiplier mul_b2(.clk(clk), .rst_n(rst_n), .a(b2), .b(x_reg2),  .valid_in(valid_T1), .p(p_b2), .valid_out());
    opti_multiplier mul_a1(.clk(clk), .rst_n(rst_n), .a(a1), .b(y_z1),    .valid_in(valid_T1), .p(p_a1), .valid_out());
    opti_multiplier mul_a2(.clk(clk), .rst_n(rst_n), .a(a2), .b(y_z2),    .valid_in(valid_T1), .p(p_a2), .valid_out());

    // ----------- T3：累加和饱和判断、一次性输出 -----------
    assign acc_sum_wire = $signed(p_b0) + $signed(p_b1) + $signed(p_b2)
                        - $signed(p_a1) - $signed(p_a2);

    assign overflow_pos = (acc_sum_wire > 19'sd32767);
    assign overflow_neg = (acc_sum_wire < -19'sd32768);
    assign acc_sum_clip = overflow_pos ? 16'sh7FFF :
                          overflow_neg ? 16'sh8000 :
                          acc_sum_wire[15:0]; // 正确截位，无舍入

    // 输出锁存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'd0;
            valid_out <= 1'b0;
        end else begin
            if (valid_T3) begin
                data_out <= acc_sum_clip;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
