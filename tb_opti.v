`timescale 1ns/1ps

module tb_opti;
    reg clk, rst_n;
    reg signed [23:0] data_in;
    reg data_in_valid;
    wire data_out_valid;
    wire signed [23:0] data_out;

    integer i, fd;
    reg [31:0] cycle_cnt, sample_cnt;
    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];

    // 实例化顶层
    opti_top u_top (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(data_in_valid),
        .data_out(data_out),
        .valid_out(data_out_valid)
    );

    // 150MHz主时钟（6.666ns周期，3.333ns半周期）
    always #3.333 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        data_in_valid = 0;
        cycle_cnt = 0;
        sample_cnt = 0;
        i = 0;
        fd = $fopen("rtl_trace.txt", "w");
        $fwrite(fd, "cycle data_in data_in_valid data_out data_out_valid\n");
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);

        #100; rst_n = 1;
        // 多等几拍，确保复位稳定
        repeat(10) @(posedge clk);

        // 主激励循环
        for (i = 0; i < N; i = i + 1) begin
            // 9拍无效
            repeat(9) begin
                @(posedge clk);
                data_in_valid <= 0;
                data_in <= 24'd0;
            end
            @(posedge clk);
            data_in <= test_vector[i];
            data_in_valid <= 1;
            @(posedge clk);
            data_in_valid <= 0; // 只保持一拍
            data_in <= 24'd0;
        end
        data_in_valid <= 0;
        data_in <= 24'd0;
        // 多等几十拍，确保流水线完全排空
        repeat(100) @(posedge clk);
        $fclose(fd);
        $display("SIM DONE.");
        $finish;
    end

    // 统计周期数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_cnt <= 0;
        else
            cycle_cnt <= cycle_cnt + 1;
    end
    // 统计采样数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_cnt <= 0;
        else if (data_in_valid)
            sample_cnt <= sample_cnt + 1;
    end

    // Trace输出（只输出有效输入或输出）
    always @(posedge clk) begin
        if (data_in_valid || data_out_valid) begin
            $fwrite(fd, "%0d %0d %0d %0d %0d\n",
                cycle_cnt, data_in, data_in_valid, data_out, data_out_valid);
        end
    end
endmodule