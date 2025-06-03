// Verilog-2001, zero-latency, full-pipeline, direct-form II transposed IIR SOS
module opti_sos (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [23:0] data_in,         // 输入数据
    input  wire               data_valid_in,   // 输入数据有效
    input  wire [1:0]         sos_idx,         // 系数选择
    output reg  signed [23:0] data_out,        // 输出数据
    output reg                data_valid_out,  // 输出数据有效

    // trace信号
    output wire signed [23:0] trace_data_in,
    output wire               trace_data_valid_in,
    output wire signed [23:0] trace_data_out,
    output wire               trace_data_valid_out,
    output wire signed [23:0] trace_w0,
    output wire signed [23:0] trace_w1,
    output wire signed [23:0] trace_w2,
    output wire signed [23:0] trace_b0_p,
    output wire signed [23:0] trace_b1_p,
    output wire signed [23:0] trace_b2_p,
    output wire signed [23:0] trace_a1_p,
    output wire signed [23:0] trace_a2_p,
    output wire [14:0]        trace_valid_pipe
);

    // ==== 系数 ====
    wire signed [23:0] b0, b1, b2, a1, a2;
    opti_coeffs u_coeffs (
        .sos_idx(sos_idx),
        .b0(b0), .b1(b1), .b2(b2),
        .a1(a1), .a2(a2)
    );

    // ==== 延迟线 ====
    reg signed [23:0] w0, w1, w2;

    // ==== 乘法器输出 ====
    wire signed [23:0] p_b0, p_b1, p_b2, p_a1, p_a2;
    wire               valid_b0, valid_b1, valid_b2, valid_a1, valid_a2;

    // ==== 有效信号延迟线 ====
    reg [14:0] valid_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_pipe <= 15'd0;
        else
            valid_pipe <= {valid_pipe[13:0], data_valid_in};
    end

    // ==== 差分方程关键量 ====
    wire signed [26:0] w0_next, p_b1_ext, p_b2_ext, p_a1_ext, p_a2_ext;
    assign p_b1_ext = { {3{p_b1[23]}}, p_b1 };
    assign p_b2_ext = { {3{p_b2[23]}}, p_b2 };
    assign p_a1_ext = { {3{p_a1[23]}}, p_a1 };
    assign p_a2_ext = { {3{p_a2[23]}}, p_a2 };
    assign w0_next = { {3{data_in[23]}}, data_in } - p_a1_ext - p_a2_ext;


    // ==== 延迟线推进 ====
    reg               data_valid_in_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w0 <= 24'sd0;
            w1 <= 24'sd0;
            w2 <= 24'sd0;
            data_valid_in_d <= 1'b0;
        end else begin
            data_valid_in_d <= data_valid_in;
            if(data_valid_in) begin
                w2 <= w1;
                w1 <= w0;
                w0 <= (w0_next > 27'sd4194303) ? 24'sd4194303 :
                      (w0_next < -27'sd4194304) ? -24'sd4194304 :
                      w0_next[23:0];
            end
        end
    end

    // ==== 乘法器实例 ====
    // 注意“b”输入：采样的永远是本拍w*，即新推进前的状态
    opti_multiplier u_mul_b0 (.clk(clk), .rst_n(rst_n), .a(b0), .b(w0), .valid_in(data_valid_in_d), .p(p_b0), .valid_out(valid_b0));
    opti_multiplier u_mul_b1 (.clk(clk), .rst_n(rst_n), .a(b1), .b(w1), .valid_in(data_valid_in_d), .p(p_b1), .valid_out(valid_b1));
    opti_multiplier u_mul_b2 (.clk(clk), .rst_n(rst_n), .a(b2), .b(w2), .valid_in(data_valid_in_d), .p(p_b2), .valid_out(valid_b2));
    opti_multiplier u_mul_a1 (.clk(clk), .rst_n(rst_n), .a(a1), .b(w1), .valid_in(data_valid_in_d), .p(p_a1), .valid_out(valid_a1));
    opti_multiplier u_mul_a2 (.clk(clk), .rst_n(rst_n), .a(a2), .b(w2), .valid_in(data_valid_in_d), .p(p_a2), .valid_out(valid_a2));

    // ==== 前馈链求和 ====
    wire signed [26:0] y_sum;
    assign y_sum = { {3{p_b0[23]}}, p_b0 } + p_b1_ext + p_b2_ext;

    // ==== 输出同步 ====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 24'sd0;
            data_valid_out <= 1'b0;
        end else begin
            if (valid_pipe[14]) begin
                if (y_sum > 27'sd4194303)
                    data_out <= 24'sd4194303;
                else if (y_sum < -27'sd4194304)
                    data_out <= -24'sd4194304;
                else
                    data_out <= y_sum[23:0];
                data_valid_out <= 1'b1;
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end

    // ==== trace信号赋值 ====
    assign trace_data_in         = data_in;
    assign trace_data_valid_in   = data_valid_in;
    assign trace_data_out        = data_out;
    assign trace_data_valid_out  = data_valid_out;
    assign trace_w0              = w0;
    assign trace_w1              = w1;
    assign trace_w2              = w2;
    assign trace_b0_p            = p_b0;
    assign trace_b1_p            = p_b1;
    assign trace_b2_p            = p_b2;
    assign trace_a1_p            = p_a1;
    assign trace_a2_p            = p_a2;
    assign trace_valid_pipe      = valid_pipe;

endmodule