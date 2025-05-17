`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg [15:0] data_in;
    reg data_in_valid;
    wire filter_done, data_out_valid, stable_out;
    wire [10:0] addr;
    wire [15:0] data_out;

    // 顶层实例
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
    reg [15:0] test_vector [0:N-1];
    reg [15:0] ref_vector  [0:N-1];

    // 输出采集
    reg [15:0] out_vector  [0:N-1];
    integer out_cnt = 0;

    // 输入激励
    integer i;
    initial begin
        $readmemh("test_signal.hex", test_vector);
        $readmemh("reference_output.hex", ref_vector);

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

    // 输出采集与比对
    integer err_cnt = 0;
    integer max_err = 0;
    reg [15:0] ref_val, out_val;
    initial begin
        out_cnt = 0;
        wait(rst_n == 1);
        wait(stable_out == 1); // 等待稳定输出开始
        @(posedge clk); // 避免和stable_out同拍
        forever begin
            @(posedge clk);
            if (data_out_valid) begin
                out_vector[out_cnt] = data_out;
                ref_val = ref_vector[out_cnt];
                out_val = data_out;
                if (out_val !== ref_val) begin
                    $display("ERROR @%d: DUT=%h, REF=%h, DIFF=%d", out_cnt, out_val, ref_val, $signed(out_val) - $signed(ref_val));
                    err_cnt = err_cnt + 1;
                    if ($signed(out_val) - $signed(ref_val) > max_err)
                        max_err = $signed(out_val) - $signed(ref_val);
                    if ($signed(ref_val) - $signed(out_val) > max_err)
                        max_err = $signed(ref_val) - $signed(out_val);
                end
                out_cnt = out_cnt + 1;
                if (out_cnt == N) begin
                    $display("------ Compare End ------");
                    $display("Total Output: %d, Error Count: %d, Max Diff: %d", out_cnt, err_cnt, max_err);
                    $finish;
                end
            end
        end
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

    // 监控信号（可选，建议保留以便debug）
    initial begin
        $display("      T    addr   data_in   data_out   dout_valid filter_done pipeline_en stable_out");
        $display("--------------------------------------------------------------------------");
        forever begin
            @(posedge clk);
            $display("%8t %4h   %4h   %4h    %b       %b        %b         %b",
                $time, addr, data_in, data_out, data_out_valid, filter_done, u_top.u_ctrl.pipeline_en, stable_out);

            $display("  [VLD] %b %b %b %b %b %b %b",
                u_top.sos_valid0, u_top.sos_valid1, u_top.sos_valid2, u_top.sos_valid3,
                u_top.sos_valid4, u_top.sos_valid5, u_top.sos_valid6);
            $display("  [DIN] %h %h %h %h %h %h %h",
                u_top.sos_data0, u_top.sos_data1, u_top.sos_data2, u_top.sos_data3,
                u_top.sos_data4, u_top.sos_data5, u_top.sos_data6);
        end
    end
endmodule