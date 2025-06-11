module opti_sos(
    input clk,
    input rst_n,
    input [23:0] data_in,
    input        valid_in,
    input [23:0] b0, b1, b2,
    input [23:0] a1, a2,
    output reg [23:0] data_out,
    output reg        valid_out
);

    // 前馈延迟线
    reg [23:0] data_in_d, x_z1, x_z2;

    // 反馈延迟线
    reg [23:0] y_z1, y_z2;

    // valid信号
    reg        valid_in_d;
    reg        valid_b0_d; // 延迟一拍，用于反馈延迟线推进
    wire       valid_b0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_d  <= 1'b0;
            valid_b0_d  <= 1'b0;
        end else begin
            valid_in_d  <= valid_in;
            valid_b0_d  <= valid_b0;
        end
    end

    // 前馈延迟线推进（采样点脉冲）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_d <= 24'd0;
            x_z1      <= 24'd0;
            x_z2      <= 24'd0;
            y_z1      <= 24'd0;
            y_z2      <= 24'd0;
        end else if (valid_in) begin
            data_in_d <= data_in;
            x_z2      <= x_z1;
            x_z1      <= data_in_d;
            y_z2      <= y_z1;
            y_z1      <= data_out;
        end
    end



    // 乘法器
    wire [23:0] mult0_p, mult1_p, mult2_p, mult3_p, mult4_p;

    opti_multiplier u_mult0 (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (b0),
        .b        (data_in_d),
        .valid_in (valid_in_d),
        .p        (mult0_p),
        .valid_out(valid_b0)
    );
    opti_multiplier u_mult1 (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (b1),
        .b        (x_z1),
        .valid_in (valid_in_d),
        .p        (mult1_p),
        .valid_out()
    );
    opti_multiplier u_mult2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (b2),
        .b        (x_z2),
        .valid_in (valid_in_d),
        .p        (mult2_p),
        .valid_out()
    );
    opti_multiplier u_mult3 (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (a1),
        .b        (y_z1),
        .valid_in (valid_in_d),
        .p        (mult3_p),
        .valid_out()
    );
    opti_multiplier u_mult4 (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (a2),
        .b        (y_z2),
        .valid_in (valid_in_d),
        .p        (mult4_p),
        .valid_out()
    );

    // 累加输出（乘法器ready时）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 24'd0;
            valid_out <= 1'b0;
        end else if (valid_b0) begin
            data_out  <= mult0_p + mult1_p + mult2_p - mult3_p - mult4_p;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule