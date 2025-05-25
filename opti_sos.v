module opti_sos (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         data_valid_in,
    input  wire signed [23:0] data_in,   // Q2.22
    input  wire signed [23:0] b0,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg          data_valid_out,
    output reg  signed [23:0] data_out    // Q2.22
    // debug_sum相关端口全部去掉
);

    localparam MULT_PIPE = 12;
    localparam DLY = 2 + MULT_PIPE;

    reg signed [23:0] y1, y2;
    reg signed [23:0] x_pipe [0:DLY];
    reg signed [23:0] y1_pipe [0:DLY];
    reg signed [23:0] y2_pipe [0:DLY];
    reg               valid_pipe [0:DLY];
    wire v_b0_x, v_b1_x, v_b2_x, v_a1_y, v_a2_y;
    wire signed [23:0] p_b0_x, p_b1_x, p_b2_x, p_a1_y, p_a2_y;
    wire v_all_valid;
    wire signed [26:0] acc_sum;

    assign v_all_valid = v_b0_x & v_b1_x & v_b2_x & v_a1_y & v_a2_y;
    assign acc_sum =
        {{3{p_b0_x[23]}}, p_b0_x} +
        {{3{p_b1_x[23]}}, p_b1_x} +
        {{3{p_b2_x[23]}}, p_b2_x} -
        {{3{p_a1_y[23]}}, p_a1_y} -
        {{3{p_a2_y[23]}}, p_a2_y};

    integer i;

    function signed [23:0] saturate_q22;
        input signed [26:0] value;
        begin
            if (value > 27'sh3FFFFF)
                saturate_q22 = 24'sh3FFFFF;
            else if (value < -27'sd4194304)
                saturate_q22 = -24'sd4194304;
            else
                saturate_q22 = value[23:0];
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<=DLY; i=i+1) begin
                x_pipe[i]   <= 0;
                y1_pipe[i]  <= 0;
                y2_pipe[i]  <= 0;
                valid_pipe[i] <= 1'b0;
            end
            y1 <= 0;
            y2 <= 0;
            data_out <= 0;
            data_valid_out <= 1'b0;
        end else begin
            x_pipe[0]      <= data_in;
            y1_pipe[0]     <= y1;
            y2_pipe[0]     <= y2;
            valid_pipe[0]  <= data_valid_in;
            for(i=1;i<=DLY;i=i+1) begin
                x_pipe[i]     <= x_pipe[i-1];
                y1_pipe[i]    <= y1_pipe[i-1];
                y2_pipe[i]    <= y2_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
            if (v_all_valid) begin
                y2 <= y1;
                y1 <= saturate_q22(acc_sum);
            end
            if (v_all_valid) begin
                data_out <= saturate_q22(acc_sum);
                data_valid_out <= 1'b1;
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end

    // ---- 乘法器输入严格同步 ----
    opti_multiplier mul_b0_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[DLY]), .a(b0), .b(x_pipe[DLY]),
        .p(p_b0_x), .valid_out(v_b0_x)
    );
    opti_multiplier mul_b1_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[DLY]), .a(b1), .b(x_pipe[DLY-1]),
        .p(p_b1_x), .valid_out(v_b1_x)
    );
    opti_multiplier mul_b2_x(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[DLY]), .a(b2), .b(x_pipe[DLY-2]),
        .p(p_b2_x), .valid_out(v_b2_x)
    );
    opti_multiplier mul_a1_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[DLY]), .a(a1), .b(y1_pipe[DLY]),
        .p(p_a1_y), .valid_out(v_a1_y)
    );
    opti_multiplier mul_a2_y(
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_pipe[DLY]), .a(a2), .b(y2_pipe[DLY]),
        .p(p_a2_y), .valid_out(v_a2_y)
    );

endmodule