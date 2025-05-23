`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n, start;
    reg signed [23:0] data_in;      // Q2.22输入
    reg data_in_valid;
    wire filter_done, data_out_valid, stable_out;
    wire [10:0] addr;
    wire signed [23:0] data_out;    // Q2.22输出

    // debug_sum信号观测（仅第一级sos，例子）
    wire signed [47:0] dbg_sum_b0_x_0, dbg_sum_b1_x_0, dbg_sum_b2_x_0, dbg_sum_a1_y_0, dbg_sum_a2_y_0;

    // 顶层IIR实例
    opti_top u_top (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in(data_in), .data_in_valid(data_in_valid),
        .filter_done(filter_done), .addr(addr),
        .data_out(data_out), .data_out_valid(data_out_valid),
        .stable_out(stable_out),
        // debug_sum信号连线
        .dbg_sum_b0_x_0(dbg_sum_b0_x_0),
        .dbg_sum_b1_x_0(dbg_sum_b1_x_0),
        .dbg_sum_b2_x_0(dbg_sum_b2_x_0),
        .dbg_sum_a1_y_0(dbg_sum_a1_y_0),
        .dbg_sum_a2_y_0(dbg_sum_a2_y_0)
    );

    // 时钟
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // 测试数据
    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];
    reg signed [23:0] ref_vector  [0:N-1];

    // 输出采集
    reg signed [23:0] out_vector  [0:N-1];
    integer out_cnt = 0;

    // 输入激励
    integer i;
    initial begin
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/reference_output.hex", ref_vector);

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

    // 输出采集与比对，并写文件（RTL输出HEX）
    integer err_cnt = 0;
    integer max_err = 0;
    reg signed [23:0] ref_val, out_val;
    integer out_file;
    initial begin
        out_file = $fopen("D:/A_Hesper/IIRfilter/qts/sim/tb_dut_output.hex", "w");
        out_cnt = 0;
        wait(rst_n == 1);
        wait(stable_out == 1);
        @(posedge clk);
        forever begin
            @(posedge clk);
            if (data_out_valid) begin
                out_vector[out_cnt] = data_out;
                ref_val = ref_vector[out_cnt];
                out_val = data_out;
                // 改进：显示十进制和16进制，直观对比
                if (out_val !== ref_val) begin
                    $display("ERROR @%0d: DUT=%0h (DEC=%0d), REF=%0h (DEC=%0d), DIFF=%0d", out_cnt, out_val, $signed(out_val), ref_val, $signed(ref_val), $signed(out_val) - $signed(ref_val));
                    err_cnt = err_cnt + 1;
                    if ($signed(out_val) - $signed(ref_val) > max_err)
                        max_err = $signed(out_val) - $signed(ref_val);
                    if ($signed(ref_val) - $signed(out_val) > max_err)
                        max_err = $signed(ref_val) - $signed(out_val);
                end
                // 写24bit补码HEX
                $fdisplay(out_file, "%06X", data_out & 24'hFFFFFF);
                out_cnt = out_cnt + 1;
                if (out_cnt == N) begin
                    $fclose(out_file);
                    $display("------ RTL Output Saved ------");
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
endmodule