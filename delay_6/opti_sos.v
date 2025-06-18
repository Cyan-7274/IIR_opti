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

    // 前馈、反馈pipeline寄存器
    reg [23:0] data_in_d, x_z1, x_z2, y_z1, y_z2;

    // 采样点脉冲打一拍，统一喂乘法器
    reg valid_in_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_d <= 1'b0;
        end else begin
            valid_in_d <= valid_in;
        end
    end


    // 延迟线全部T0推进，作为下一个采样点的输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_d <= 24'd0;
            x_z1 <= 24'd0;
            x_z2 <= 24'd0;
            y_z1 <= 24'd0;
            y_z2 <= 24'd0;
        end else if (valid_in) begin
            data_in_d <= data_in;
            x_z2 <= x_z1;
            x_z1 <= data_in_d;
            y_z2 <= y_z1;
            y_z1 <= data_out; // feedback用上一个输出
        end
    end

    // 喂乘法器的输入全部用pipeline寄存器
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

    // 累加输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 24'd0;
            y_z1      <= 24'd0;
            y_z2      <= 24'd0;
            // ... 其它寄存器初始化
            valid_out <= 1'b0;
        end else if (valid_b0) begin  // 乘法器输出ready
            data_out  <= mult0_p + mult1_p + mult2_p - mult3_p - mult4_p;
            valid_out <= 1'b1;
            // 延迟线推进，反馈用“刚算出来的本采样点输出”
            y_z2      <= y_z1;
            y_z1      <= data_out; // 注意：这里用的上一拍结果，乘法器延迟一拍
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule