`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg signed [23:0] data_in;
    reg data_in_valid;
    wire data_out_valid;
    wire signed [23:0] data_out;

    // trace信号
    wire signed [23:0] u_sos0_data_in, u_sos0_data_out, u_sos1_data_in, u_sos1_data_out;
    wire signed [23:0] u_sos2_data_in, u_sos2_data_out, u_sos3_data_in, u_sos3_data_out;
    wire u_sos0_data_valid_in, u_sos0_data_valid_out, u_sos1_data_valid_in, u_sos1_data_valid_out;
    wire u_sos2_data_valid_in, u_sos2_data_valid_out, u_sos3_data_valid_in, u_sos3_data_valid_out;
    wire signed [23:0] u_sos0_w0, u_sos0_w1, u_sos0_w2;
    wire signed [23:0] u_sos0_b0_a, u_sos0_b0_b, u_sos0_b0_p;
    wire u_sos0_b0_valid_in, u_sos0_b0_valid_out;

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
        .data_out(data_out),
        .data_valid_out(data_out_valid),

        .u_sos0_data_in(u_sos0_data_in),
        .u_sos0_data_valid_in(u_sos0_data_valid_in),
        .u_sos0_data_out(u_sos0_data_out),
        .u_sos0_data_valid_out(u_sos0_data_valid_out),
        .u_sos1_data_in(u_sos1_data_in),
        .u_sos1_data_valid_in(u_sos1_data_valid_in),
        .u_sos1_data_out(u_sos1_data_out),
        .u_sos1_data_valid_out(u_sos1_data_valid_out),
        .u_sos2_data_in(u_sos2_data_in),
        .u_sos2_data_valid_in(u_sos2_data_valid_in),
        .u_sos2_data_out(u_sos2_data_out),
        .u_sos2_data_valid_out(u_sos2_data_valid_out),
        .u_sos3_data_in(u_sos3_data_in),
        .u_sos3_data_valid_in(u_sos3_data_valid_in),
        .u_sos3_data_out(u_sos3_data_out),
        .u_sos3_data_valid_out(u_sos3_data_valid_out),

        .u_sos0_w0(u_sos0_w0), .u_sos0_w1(u_sos0_w1), .u_sos0_w2(u_sos0_w2),
        .u_sos0_b0_a(u_sos0_b0_a), .u_sos0_b0_b(u_sos0_b0_b), .u_sos0_b0_p(u_sos0_b0_p),
        .u_sos0_b0_valid_in(u_sos0_b0_valid_in), .u_sos0_b0_valid_out(u_sos0_b0_valid_out)
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
        fd = $fopen("D:/A_Hesper/IIRfilter/qts/tb/rtl_trace.txt", "w");
        $fwrite(fd, "cycle data_in data_in_valid ");
        $fwrite(fd, "u_sos0_data_in u_sos0_data_valid_in u_sos0_data_out u_sos0_data_valid_out ");
        $fwrite(fd, "u_sos1_data_in u_sos1_data_valid_in u_sos1_data_out u_sos1_data_valid_out ");
        $fwrite(fd, "u_sos2_data_in u_sos2_data_valid_in u_sos2_data_out u_sos2_data_valid_out ");
        $fwrite(fd, "u_sos3_data_in u_sos3_data_valid_in u_sos3_data_out u_sos3_data_valid_out ");
        $fwrite(fd, "data_out data_out_valid ");
        $fwrite(fd, "u_sos0_w0 u_sos0_w1 u_sos0_w2 ");
        $fwrite(fd, "u_sos0_b0_a u_sos0_b0_b u_sos0_b0_p u_sos0_b0_valid_in u_sos0_b0_valid_out\n");

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
        $fwrite(fd, "%0d %0d %0d ", cycle_cnt, data_in, data_in_valid);
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos0_data_in, u_sos0_data_valid_in, u_sos0_data_out, u_sos0_data_valid_out);
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos1_data_in, u_sos1_data_valid_in, u_sos1_data_out, u_sos1_data_valid_out);
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos2_data_in, u_sos2_data_valid_in, u_sos2_data_out, u_sos2_data_valid_out);
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos3_data_in, u_sos3_data_valid_in, u_sos3_data_out, u_sos3_data_valid_out);
        $fwrite(fd, "%0d %0d ", data_out, data_out_valid);
        $fwrite(fd, "%0d %0d %0d ", u_sos0_w0, u_sos0_w1, u_sos0_w2);
        $fwrite(fd, "%0d %0d %0d %0d %0d\n", u_sos0_b0_a, u_sos0_b0_b, u_sos0_b0_p, u_sos0_b0_valid_in, u_sos0_b0_valid_out);
    end
endmodule