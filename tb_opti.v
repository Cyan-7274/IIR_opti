`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg signed [23:0] data_in;
    reg data_in_valid;
    wire data_out_valid;
    wire signed [23:0] data_out;
    integer i, fd;
    reg [31:0] cycle_cnt;
    reg [31:0] sample_cnt;

    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];

    // ---- 级联4级sos，每级sos_idx不同 ----
    wire [1:0] sos_idx0 = 2'd0, sos_idx1 = 2'd1, sos_idx2 = 2'd2, sos_idx3 = 2'd3;
    wire signed [23:0] y0, y1, y2, y3;
    wire vld0, vld1, vld2, vld3;
    wire signed [23:0] w0_0, w1_0, w2_0; // trace sos0内部
    // 例化
    opti_sos u_sos0 (
        .clk(clk), .rst_n(rst_n),
        .data_in(data_in),
        .data_valid_in(data_in_valid),
        .sos_idx(sos_idx0),
        .data_valid_out(vld0),
        .data_out(y0),
        .w0(w0_0), .w1(w1_0), .w2(w2_0)
    );
    opti_sos u_sos1 (
        .clk(clk), .rst_n(rst_n),
        .data_in(y0),
        .data_valid_in(vld0),
        .sos_idx(sos_idx1),
        .data_valid_out(vld1),
        .data_out(y1),
        .w0(), .w1(), .w2()
    );
    opti_sos u_sos2 (
        .clk(clk), .rst_n(rst_n),
        .data_in(y1),
        .data_valid_in(vld1),
        .sos_idx(sos_idx2),
        .data_valid_out(vld2),
        .data_out(y2),
        .w0(), .w1(), .w2()
    );
    opti_sos u_sos3 (
        .clk(clk), .rst_n(rst_n),
        .data_in(y2),
        .data_valid_in(vld2),
        .sos_idx(sos_idx3),
        .data_valid_out(vld3),
        .data_out(y3),
        .w0(), .w1(), .w2()
    );
    assign data_out = y3;
    assign data_out_valid = vld3;

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
        $fwrite(fd, "u_sos0_w0 u_sos0_w1 u_sos0_w2\n");

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
        // sos0链路
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos0.data_in, u_sos0.data_valid_in, u_sos0.data_out, u_sos0.data_valid_out);
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos1.data_in, u_sos1.data_valid_in, u_sos1.data_out, u_sos1.data_valid_out);
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos2.data_in, u_sos2.data_valid_in, u_sos2.data_out, u_sos2.data_valid_out);
        $fwrite(fd, "%0d %0d %0d %0d ", u_sos3.data_in, u_sos3.data_valid_in, u_sos3.data_out, u_sos3.data_valid_out);
        $fwrite(fd, "%0d %0d ", data_out, data_out_valid);
        $fwrite(fd, "%0d %0d %0d\n", w0_0, w1_0, w2_0);
    end
endmodule