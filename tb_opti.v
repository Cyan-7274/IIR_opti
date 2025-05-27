`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg signed [23:0] data_in;
    reg data_in_valid;
    wire filter_done, data_out_valid, stable_out;
    wire [10:0] addr;
    wire signed [23:0] data_out;

    integer sample_cnt;
    integer i;

    opti_top u_top (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in(data_in), .data_in_valid(data_in_valid),
        .filter_done(filter_done), .addr(addr),
        .data_out(data_out), .data_out_valid(data_out_valid),
        .stable_out(stable_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;
    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];
    initial $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);

    initial sample_cnt = 0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_cnt <= 0;
        else if (data_in_valid)
            sample_cnt <= sample_cnt + 1;
    end

    initial begin
        rst_n = 0; start = 0; data_in = 0; data_in_valid = 0;
        #100;
        rst_n = 1;
        #50;
        start = 1;
        #10;
        start = 0;
        for (i = 0; i < N; i = i + 1) begin
            @(negedge clk);
            data_in <= test_vector[i];
            data_in_valid <= 1'b1;
        end
        @(negedge clk);
        data_in_valid <= 1'b0;
    end

    integer debug_file;
    integer j;

    // 写表头
    initial begin
        debug_file = $fopen("D:/A_Hesper/IIRfilter/qts/sim/all_sos_full_pipeline.csv", "w");
        $fwrite(debug_file, "sample_cnt,data_in,sos0_data_out,sos0_data_valid_out");

        // x/y1/y2/valid管线
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_x_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_y1_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_y2_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_valid_pipe%d", j);

        // feedback寄存器和累加和
        $fwrite(debug_file, ",sos0_y1_reg,sos0_y2_reg,sos0_acc_sum");

        // 各乘法器关键信号（b0、b1、b2、a1、a2）
        // b0
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b0_a_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b0_b_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b0_acc_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b0_valid_pipe%d", j);
        $fwrite(debug_file, ",sos0_b0_p,sos0_b0_valid_out");
        // b1
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b1_a_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b1_b_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b1_acc_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b1_valid_pipe%d", j);
        $fwrite(debug_file, ",sos0_b1_p,sos0_b1_valid_out");
        // b2
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b2_a_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b2_b_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b2_acc_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_b2_valid_pipe%d", j);
        $fwrite(debug_file, ",sos0_b2_p,sos0_b2_valid_out");
        // a1
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a1_a_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a1_b_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a1_acc_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a1_valid_pipe%d", j);
        $fwrite(debug_file, ",sos0_a1_p,sos0_a1_valid_out");
        // a2
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a2_a_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a2_b_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a2_acc_pipe%d", j);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",sos0_a2_valid_pipe%d", j);
        $fwrite(debug_file, ",sos0_a2_p,sos0_a2_valid_out\n");
    end

    // 写数据
    always @(posedge clk) begin
        $fwrite(debug_file, "%0d,%0d,%0d,%0d",
            sample_cnt,
            data_in,
            u_top.u_sos0.data_out,
            u_top.u_sos0.data_valid_out
        );
        // x/y1/y2/valid管线
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.x_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.y1_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.y2_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.valid_pipe[j]);
        // feedback寄存器和累加和
        $fwrite(debug_file, ",%0d,%0d,%0d",
            u_top.u_sos0.y1_reg,
            u_top.u_sos0.y2_reg,
            u_top.u_sos0.acc_sum
        );
        // b0
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b0_x.a_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b0_x.b_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b0_x.acc_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b0_x.valid_pipe[j]);
        $fwrite(debug_file, ",%0d,%0d", u_top.u_sos0.mul_b0_x.p, u_top.u_sos0.mul_b0_x.valid_out);
        // b1
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b1_x.a_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b1_x.b_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b1_x.acc_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b1_x.valid_pipe[j]);
        $fwrite(debug_file, ",%0d,%0d", u_top.u_sos0.mul_b1_x.p, u_top.u_sos0.mul_b1_x.valid_out);
        // b2
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b2_x.a_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b2_x.b_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b2_x.acc_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_b2_x.valid_pipe[j]);
        $fwrite(debug_file, ",%0d,%0d", u_top.u_sos0.mul_b2_x.p, u_top.u_sos0.mul_b2_x.valid_out);
        // a1
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a1_y.a_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a1_y.b_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a1_y.acc_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a1_y.valid_pipe[j]);
        $fwrite(debug_file, ",%0d,%0d", u_top.u_sos0.mul_a1_y.p, u_top.u_sos0.mul_a1_y.valid_out);
        // a2
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a2_y.a_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a2_y.b_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a2_y.acc_pipe[j]);
        for (j=0; j<=12; j=j+1) $fwrite(debug_file, ",%0d", u_top.u_sos0.mul_a2_y.valid_pipe[j]);
        $fwrite(debug_file, ",%0d,%0d\n", u_top.u_sos0.mul_a2_y.p, u_top.u_sos0.mul_a2_y.valid_out);
    end

    initial begin
        #2000000;
        $display("SIM TIMEOUT.");
        $finish;
    end
endmodule