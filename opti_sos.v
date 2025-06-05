// 标准DF2T SOS子模块，所有主RTL信号名100%不变，仅trace为观测副本
module opti_sos (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [23:0] data_in,
    input  wire               data_valid_in,
    input  wire [1:0]         sos_idx,
    output reg  signed [23:0] data_out,
    output reg                data_valid_out,
    // 观测用trace信号
    output reg signed [23:0] trace_w0,
    output reg signed [23:0] trace_w1,
    output reg signed [23:0] trace_w2,
    output reg signed [23:0] trace_data_in,
    output reg signed [23:0] trace_data_out,
    output reg               trace_data_valid_in,
    output reg               trace_data_valid_out,
    output reg signed [23:0] trace_b0_p,
    output reg signed [23:0] trace_b1_p,
    output reg signed [23:0] trace_b2_p,
    output reg signed [23:0] trace_a1_p,
    output reg signed [23:0] trace_a2_p
);

    localparam MUL_PIPE = 14;

    // 系数ROM
    wire signed [23:0] b0, b1, b2, a1, a2;
    opti_coeffs u_coeffs (
        .sos_idx(sos_idx),
        .b0(b0), .b1(b1), .b2(b2),
        .a1(a1), .a2(a2)
    );

    // 主RTL信号，名称不变
    reg signed [23:0] w0, w1, w2;
    reg signed [23:0] data_in_pipe [0:MUL_PIPE-1];
    reg [MUL_PIPE-1:0] valid_pipe;
    integer i;

    // 采样移位寄存器推进
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<MUL_PIPE; i=i+1)
                data_in_pipe[i] <= 0;
            valid_pipe <= 0;
            w0 <= 0; w1 <= 0; w2 <= 0;
        end else if (data_valid_in) begin
            data_in_pipe[0] <= data_in;
            for (i=1; i<MUL_PIPE; i=i+1)
                data_in_pipe[i] <= data_in_pipe[i-1];
            valid_pipe <= {valid_pipe[MUL_PIPE-2:0], data_valid_in};
            w2 <= w1;
            w1 <= w0;
            // w0在反馈时推进
        end
    end

    // 乘法器采样w0/w1/w2，不依赖反馈
    wire signed [23:0] p_b0, p_b1, p_b2, p_a1, p_a2;
    wire valid_mul;
    opti_multiplier u_mul_b0 (.clk(clk), .rst_n(rst_n), .a(b0), .b(w0), .valid_in(data_valid_in), .p(p_b0), .valid_out(valid_mul));
    opti_multiplier u_mul_b1 (.clk(clk), .rst_n(rst_n), .a(b1), .b(w1), .valid_in(data_valid_in), .p(p_b1));
    opti_multiplier u_mul_b2 (.clk(clk), .rst_n(rst_n), .a(b2), .b(w2), .valid_in(data_valid_in), .p(p_b2));
    opti_multiplier u_mul_a1 (.clk(clk), .rst_n(rst_n), .a(a1), .b(w1), .valid_in(data_valid_in), .p(p_a1));
    opti_multiplier u_mul_a2 (.clk(clk), .rst_n(rst_n), .a(a2), .b(w2), .valid_in(data_valid_in), .p(p_a2));

    // 求和与饱和
    wire signed [26:0] p_b0_ext = { {3{p_b0[23]}}, p_b0 };
    wire signed [26:0] p_b1_ext = { {3{p_b1[23]}}, p_b1 };
    wire signed [26:0] p_b2_ext = { {3{p_b2[23]}}, p_b2 };
    wire signed [26:0] p_a1_ext = { {3{p_a1[23]}}, p_a1 };
    wire signed [26:0] p_a2_ext = { {3{p_a2[23]}}, p_a2 };

    wire signed [26:0] w0_next = { {3{data_in_pipe[MUL_PIPE-1][23]}}, data_in_pipe[MUL_PIPE-1] } - p_a1_ext - p_a2_ext;
    wire signed [26:0] y_sum   = p_b0_ext + p_b1_ext + p_b2_ext;

    // w0反馈推进，只有在乘法器输出valid时更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w0 <= 0;
        end else if (valid_mul) begin
            if (w0_next > 27'sd4194303)
                w0 <= 24'sd4194303;
            else if (w0_next < -27'sd4194304)
                w0 <= -24'sd4194304;
            else
                w0 <= w0_next[23:0];
        end
    end

    // 输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            data_valid_out <= 0;
        end else if (valid_mul) begin
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

    // ==== trace信号（仅作观测，主信号名不变） ====
    always @(posedge clk) begin
        trace_w0 <= w0;
        trace_w1 <= w1;
        trace_w2 <= w2;
        trace_data_in <= data_in;
        trace_data_out <= data_out;
        trace_data_valid_in <= data_valid_in;
        trace_data_valid_out <= data_valid_out;
        trace_b0_p <= p_b0;
        trace_b1_p <= p_b1;
        trace_b2_p <= p_b2;
        trace_a1_p <= p_a1;
        trace_a2_p <= p_a2;
    end

endmodule