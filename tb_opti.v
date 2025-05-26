`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg signed [23:0] data_in;      // Q2.22输入
    reg data_in_valid;
    wire filter_done, data_out_valid, stable_out;
    wire [10:0] addr;
    wire signed [23:0] data_out;    // Q2.22输出

    // 顶层IIR实例
    opti_top u_top (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in(data_in), .data_in_valid(data_in_valid),
        .filter_done(filter_done), .addr(addr),
        .data_out(data_out), .data_out_valid(data_out_valid),
        .stable_out(stable_out)
    );

    // 时钟
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // 测试数据
    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];
    initial $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);

    // sample_cnt：采样点计数，仅前20点导出
    integer sample_cnt = 0;

    // 激励输入
    integer i;
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

    // sample_cnt随data_in_valid累加
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_cnt <= 0;
        else if (data_in_valid)
            sample_cnt <= sample_cnt + 1;
    end



integer debug_file;
integer j;
initial begin
    debug_file = $fopen("all_sos_full_pipeline.csv", "w");
    $fwrite(debug_file, "sample_cnt,data_in,sos0_data_out,sos0_data_valid_out");
    for (j=0;j<=12;j=j+1) begin
        $fwrite(debug_file, ",sos0_b0_a_pipe"); $fwrite(debug_file, "%0d", j);
        $fwrite(debug_file, ",sos0_b0_b_pipe"); $fwrite(debug_file, "%0d", j);
        $fwrite(debug_file, ",sos0_b0_acc_pipe"); $fwrite(debug_file, "%0d", j);
        $fwrite(debug_file, ",sos0_b0_valid_pipe"); $fwrite(debug_file, "%0d", j);
    end
    $fwrite(debug_file, ",sos0_b0_p,sos0_b0_valid_out\n");
end


    // 自动仿真超时保护
    initial begin
        #2000000;
        $display("SIM TIMEOUT.");
        $finish;
    end

    // 波形输出
    initial begin
        $dumpfile("tb_opti.vcd");
        $dumpvars(0, tb_opti);
    end
endmodule