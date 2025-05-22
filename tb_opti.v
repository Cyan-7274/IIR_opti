`timescale 1ns/1ps

module tb_opti;
    reg clk;
    reg rst_n;
    reg start;
    reg data_in_valid;
    reg signed [23:0] data_in;
    wire filter_done;
    wire data_out_valid;
    wire signed [23:0] data_out;

    // 输入参数
    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];
    reg signed [23:0] ref_vector  [0:N-1];
    integer in_cnt = 0, out_cnt = 0;
    integer err_cnt = 0;
    integer max_err = 0;
    integer delay = 61; // 用你仿真测得的延迟
    integer skip = 0;
    integer out_file;

    // 导入输入激励和参考输出
    initial begin
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/est_signal.hex", test_vector);
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/reference_output.hex", ref_vector);
    end

    // 时钟与复位
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        rst_n = 0;
        start = 0;
        data_in_valid = 0;
        data_in = 0;
        #100;
        rst_n = 1;
        #20;
        start = 1;
        #10;
        start = 0;
    end

    // DUT例化（请根据你的顶层端口名自行调整）
    opti_top u_top (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .data_in_valid  (data_in_valid),
        .data_in        (data_in),
        .filter_done    (filter_done),
        .data_out_valid (data_out_valid),
        .data_out       (data_out)
    );

    // 输入激励
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            in_cnt <= 0;
            data_in_valid <= 0;
            data_in <= 0;
        end else if(start && in_cnt < N) begin
            data_in <= test_vector[in_cnt];
            data_in_valid <= 1'b1;
            in_cnt <= in_cnt + 1;
        end else begin
            data_in_valid <= 1'b0;
        end
    end

    // 输出采集与比对
    initial begin
        out_file = $fopen("D:/A_Hesper/IIRfilter/qts/sim/tb_dut_output.hex", "w");
        out_cnt = 0;
        err_cnt = 0;
        max_err = 0;
        // 等待复位与启动
        wait(rst_n == 1);
        wait(start == 1);
        // 跳过delay个有效输出（严格对齐）
        while (skip < delay) begin
            @(posedge clk);
            if (data_out_valid) skip = skip + 1;
        end
        // 采集和对比
        forever begin
            @(posedge clk);
            if (data_out_valid) begin
                $fdisplay(out_file, "%06X", data_out & 24'hFFFFFF);
                if (out_cnt < N) begin
                    if (data_out !== ref_vector[out_cnt]) begin
                        $display("ERROR @%0d: DUT=%0h (DEC=%0d), REF=%0h (DEC=%0d), DIFF=%0d",
                            out_cnt, data_out, $signed(data_out), ref_vector[out_cnt], $signed(ref_vector[out_cnt]), $signed(data_out) - $signed(ref_vector[out_cnt]));
                        err_cnt = err_cnt + 1;
                        if ($signed(data_out) - $signed(ref_vector[out_cnt]) > max_err)
                            max_err = $signed(data_out) - $signed(ref_vector[out_cnt]);
                        if ($signed(ref_vector[out_cnt]) - $signed(data_out) > max_err)
                            max_err = $signed(ref_vector[out_cnt]) - $signed(data_out);
                    end
                end
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

    // 仿真波形监控（可选：VCD/FSDB/SAIF等）
    initial begin
        $dumpfile("tb_opti.vcd");
        $dumpvars(0, tb_opti);
        $dumpvars(0, u_top);
        // 可加: $dumpvars(0, u_top.gen_coeff_sos[0].u_sos); 视你的generate结构而定
    end

endmodule