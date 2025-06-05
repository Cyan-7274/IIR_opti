`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg signed [23:0] data_in;
    reg data_in_valid;
    wire data_out_valid;
    wire signed [23:0] data_out;

    reg [1:0] sos0_idx = 2'd0, sos1_idx = 2'd1, sos2_idx = 2'd2, sos3_idx = 2'd3;

    // trace信号
    wire signed [23:0] w0_0, w1_0, w2_0, b0p_0, b1p_0, b2p_0, a1p_0, a2p_0;
    wire signed [23:0] data_in0, data_out0;
    wire data_valid_in0, data_valid_out0;

    integer i, fd;
    reg [31:0] cycle_cnt;
    reg [31:0] sample_cnt;

    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];

    // 实例化顶层top模块
    opti_top u_top (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid_in(data_in_valid),
        .sos0_idx(sos0_idx),
        .sos1_idx(sos1_idx),
        .sos2_idx(sos2_idx),
        .sos3_idx(sos3_idx),
        .data_out(data_out),
        .data_valid_out(data_out_valid),
        .trace_w0(w0_0), .trace_w1(w1_0), .trace_w2(w2_0),
        .trace_data_in(data_in0), .trace_data_out(data_out0),
        .trace_data_valid_in(data_valid_in0), .trace_data_valid_out(data_valid_out0),
        .trace_b0_p(b0p_0), .trace_b1_p(b1p_0), .trace_b2_p(b2p_0), .trace_a1_p(a1p_0), .trace_a2_p(a2p_0)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        data_in = 0;
        data_in_valid = 0;
        cycle_cnt = 0;
        sample_cnt = 0;
        i = 0;
        fd = $fopen("rtl_trace.txt", "w");
        $fwrite(fd, "cycle data_in data_in_valid w0_0 w1_0 w2_0 data_out data_out_valid b0p_0 b1p_0 b2p_0 a1p_0 a2p_0\n");

        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);

        #100; rst_n = 1; #50; start = 1; #10; start = 0;
        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            data_in <= test_vector[i];
            data_in_valid <= 1'b1;
        end
        @(posedge clk);
        data_in_valid <= 1'b0;
        #2000000
        $fclose(fd);
        $display("SIM TIMEOUT.");
        $finish;
    end

    always #5 clk = ~clk;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_cnt <= 0;
        else
            cycle_cnt <= cycle_cnt + 1;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_cnt <= 0;
        else if (data_in_valid)
            sample_cnt <= sample_cnt + 1;
    end

    always @(posedge clk) begin
        $fwrite(fd, "%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",
            cycle_cnt, data_in, data_in_valid, w0_0, w1_0, w2_0, data_out, data_out_valid, b0p_0, b1p_0, b2p_0, a1p_0, a2p_0);
    end
endmodule