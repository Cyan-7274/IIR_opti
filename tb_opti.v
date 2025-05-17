`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg [15:0] data_in;
    reg data_in_valid;
    wire filter_done, data_out_valid, stable_out;
    wire [10:0] addr;
    wire [15:0] data_out;

    // 实例化顶层设计
    opti_top u_top (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in(data_in), .data_in_valid(data_in_valid),
        .filter_done(filter_done), .addr(addr),
        .data_out(data_out), .data_out_valid(data_out_valid),
        .stable_out(stable_out)
    );

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // 激励信号
    integer cycle;
    reg [15:0] test_vector [0:2047];
    initial begin
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);
        rst_n = 0; start = 0; data_in = 0; data_in_valid = 0;
        #100;
        rst_n = 1;
        #50;
        start = 1;
        #10;
        start = 0;

        for (cycle = 0; cycle < 2048; cycle = cycle + 1) begin
            @(negedge clk);
            data_in <= test_vector[cycle];
            data_in_valid <= 1'b1;
        end
        @(negedge clk);
        data_in_valid <= 1'b0;
    end

    // 波形文件输出
    initial begin
        $dumpfile("tb_opti.vcd");
        $dumpvars(0, tb_opti);
    end

    // 监控信号打印
    initial begin
        $display("      T    addr   data_in   data_out   dout_valid filter_done pipeline_en stable_out");
        $display("--------------------------------------------------------------------------");
        forever begin
            @(posedge clk);
            $display("%8t %4h   %4h   %4h    %b       %b        %b         %b",
                $time, addr, data_in, data_out, data_out_valid, filter_done, u_top.u_ctrl.pipeline_en, stable_out);

            // 各级级联状态信号
            $display("  [VLD] %b %b %b %b %b %b %b",
                u_top.sos_valid0, u_top.sos_valid1, u_top.sos_valid2, u_top.sos_valid3,
                u_top.sos_valid4, u_top.sos_valid5, u_top.sos_valid6);
            $display("  [DIN] %h %h %h %h %h %h %h",
                u_top.sos_data0, u_top.sos_data1, u_top.sos_data2, u_top.sos_data3,
                u_top.sos_data4, u_top.sos_data5, u_top.sos_data6);
        end
    end
endmodule