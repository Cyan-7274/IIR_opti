module opti_sos (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire signed [15:0] data_in,     // Q2.14
    input  wire signed [15:0] b0, b1, b2,  // Q2.14
    input  wire signed [15:0] a1, a2,      // Q2.14
    output reg  signed [15:0] data_out,    // Q2.14
    output reg          valid_out
);
    // ---- 有效信号流水线 ----
    reg [4:0] valid_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_pipe <= 5'b0;
        else
            valid_pipe <= {valid_pipe[3:0], valid_in};
    end

    // ---- 状态寄存器 ----
    reg signed [15:0] w1, w2;

    // ---- 乘法器输出 ----
    wire signed [15:0] mul_b0, mul_b1, mul_b2, mul_a1, mul_a2;
    wire valid_b0, valid_b1, valid_b2, valid_a1, valid_a2;
    wire valid_mul;

    opti_multiplier u_b0 (.clk(clk), .rst_n(rst_n), .a(b0), .b(data_in), .valid_in(valid_in), .p(mul_b0), .valid_out(valid_b0));
    opti_multiplier u_b1 (.clk(clk), .rst_n(rst_n), .a(b1), .b(data_in), .valid_in(valid_in), .p(mul_b1), .valid_out(valid_b1));
    opti_multiplier u_b2 (.clk(clk), .rst_n(rst_n), .a(b2), .b(data_in), .valid_in(valid_in), .p(mul_b2), .valid_out(valid_b2));
    opti_multiplier u_a1 (.clk(clk), .rst_n(rst_n), .a(a1), .b(data_in), .valid_in(valid_in), .p(mul_a1), .valid_out(valid_a1));
    opti_multiplier u_a2 (.clk(clk), .rst_n(rst_n), .a(a2), .b(data_in), .valid_in(valid_in), .p(mul_a2), .valid_out(valid_a2));

    assign valid_mul = valid_b0 & valid_b1 & valid_b2 & valid_a1 & valid_a2;

    // ---- w1/w2流水线寄存器 ----
    reg signed [15:0] w1_pipe[0:2], w2_pipe[0:2];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<3;i=i+1) begin
                w1_pipe[i] <= 16'd0;
                w2_pipe[i] <= 16'd0;
            end
        end else if(valid_mul) begin
            w1_pipe[0] <= w1_pipe[1];
            w1_pipe[1] <= w1_pipe[2];
            w1_pipe[2] <= w1;
            w2_pipe[0] <= w2_pipe[1];
            w2_pipe[1] <= w2_pipe[2];
            w2_pipe[2] <= w2;
        end
    end

    // ---- w1/w2寄存器的推进 ----
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            w1 <= 16'd0;
            w2 <= 16'd0;
        end else if(valid_mul) begin
            w2 <= mul_b2 - mul_a2;
            w1 <= mul_b1 + w2_pipe[2] - mul_a1;
        end
    end

    // ---- 输出 y[n] = mul_b0 + w1[n-1] ----
    wire signed [16:0] y_raw = $signed({1'b0, mul_b0}) + $signed({1'b0, w1_pipe[2]});
    wire signed [15:0] y_sat = (y_raw > 17'sh07FFF) ? 16'sh7FFF :
                               (y_raw < -17'sh08000) ? -16'sh8000 : y_raw[15:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 16'd0;
            valid_out <= 1'b0;
        end else if (valid_mul) begin
            data_out  <= y_sat;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
