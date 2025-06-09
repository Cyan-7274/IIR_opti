`timescale 1ns/1ps
// 高精度伺服IIR滤波器测试平台 (150MHz系统时钟/15MHz ADC)
// 适配当前顶层文件，严格匹配Q2.22格式与新采样配置
// 采样时钟为150MHz，ADC采样周期 = 66.67ns (10主时钟周期)

module tb_opti;
    reg clk, rst_n;
    reg signed [23:0] data_in;
    reg data_in_valid;
    wire signed [23:0] data_out;
    wire data_out_valid;

    // 顶层模块实例化（名称和端口请与实际一致）
opti_top u_top (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_in       (data_in),
        .valid_in  (data_in_valid),
        .data_out      (data_out),
        .valid_out (data_out_valid)
    );

    // ===== 参数与变量 =====
    localparam N = 2048;
    localparam SYS_CLK_PERIOD = 6.6667;       // ns (150MHz)
    localparam ADC_INTERVAL = 10;             // ADC每10周期采样一次，等效15MHz
    integer i, fd;
    reg [31:0] cycle_cnt;
    reg [31:0] sample_cnt, output_cnt;
    reg signed [23:0] test_vector [0:N-1];

    // ===== ADC输入时序控制 =====
    reg [3:0] adc_counter;
    reg [11:0] test_index;
    reg test_running;

    // ===== 时钟生成：150MHz =====
    always #(SYS_CLK_PERIOD/2) clk = ~clk;    // 6.6667ns周期

    // ===== ADC采样时序：每10拍 = 66.67ns = 15MHz =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adc_counter <= 0;
            test_index <= 0;
            test_running <= 1'b0;
            data_in <= 24'd0;
            data_in_valid <= 1'b0;
        end else if (test_running) begin
            if (adc_counter == ADC_INTERVAL - 1) begin
                adc_counter <= 0;
                if (test_index < N) begin
                    data_in <= test_vector[test_index];
                    data_in_valid <= 1'b1;
                    test_index <= test_index + 1;
                end else begin
                    data_in_valid <= 1'b0;
                    test_running <= 1'b0;  // 输入结束
                end
            end else begin
                adc_counter <= adc_counter + 1;
                data_in_valid <= 1'b0;
            end
        end
    end

    // ===== 计数器 =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt <= 0;
            sample_cnt <= 0;
            output_cnt <= 0;
        end else begin
            cycle_cnt <= cycle_cnt + 1;
            if (data_in_valid)
                sample_cnt <= sample_cnt + 1;
            if (data_out_valid)
                output_cnt <= output_cnt + 1;
        end
    end

    // ===== 仿真控制 =====
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        test_running = 1'b0;

        // 打开trace文件
        fd = $fopen("rtl_trace.txt", "w");
        $fwrite(fd, "cycle adc_cnt data_in data_in_valid data_out data_out_valid\n");

        // 读取测试向量
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);
        $display("测试向量加载完成，开始仿真...");
        $display("系统时钟：150MHz (6.67ns周期)");
        $display("ADC采样：15MHz (每%d拍 = 66.67ns)", ADC_INTERVAL);

        // 复位和启动
        #100; 
        rst_n = 1; 
        #50;
        test_running = 1'b1;
        $display("开始输入测试数据...");

        // 等待测试完成
        wait(!test_running);
        $display("数据输入完成，等待处理结束...");

        // 额外等待，确保所有数据处理完
        #20000;

        // 结果统计
        $fclose(fd);
        $display("\n=== 仿真完成统计 ===");
        $display("系统时钟频率: 150MHz");
        $display("总仿真周期: %d", cycle_cnt);
        $display("输入样本数: %d", sample_cnt);
        $display("输出样本数: %d", output_cnt);

        if (output_cnt > 0) begin
            $display("平均输出间隔: %.2f拍", (cycle_cnt * 1.0) / output_cnt);
            $display("等效处理频率: %.2f MHz", 150.0 * output_cnt / cycle_cnt);
            $display("吞吐率效率: %.1f%%", 100.0 * output_cnt / sample_cnt);
        end

        // 性能评估
        if (output_cnt >= sample_cnt * 0.95) begin
            $display("✅ 性能测试通过：吞吐率满足要求");
        end else begin
            $display("❌ 性能测试失败：存在数据积压");
        end

        $finish;
    end

    // ===== 数据采集 =====
    always @(posedge clk) begin
        $fwrite(fd, "%0d %0d %0d %0d %0d %0d\n",
            cycle_cnt,
            adc_counter,
            data_in, data_in_valid,
            data_out, data_out_valid
        );
    end

    // ===== 输出间隔监控 =====
    reg [31:0] last_output_time;
    reg [31:0] max_output_interval, min_output_interval;
    reg [31:0] interval;
    always @(posedge clk) begin
        if (data_out_valid) begin
            interval = cycle_cnt - last_output_time;
            if (output_cnt > 1) begin
                if (output_cnt == 2) begin
                    max_output_interval = interval;
                    min_output_interval = interval;
                end else begin
                    if (interval > max_output_interval) max_output_interval = interval;
                    if (interval < min_output_interval) min_output_interval = interval;
                end
                if (interval > ADC_INTERVAL + 2) begin
                    $display("WARNING @cycle %d: 输出间隔过大 (%d拍 > %d拍期望)", 
                             cycle_cnt, interval, ADC_INTERVAL);
                end
            end
            last_output_time = cycle_cnt;
        end
    end

    // ===== 周期性报告 =====
    always @(posedge clk) begin
        if (cycle_cnt % 20000 == 0 && cycle_cnt > 0 && test_running) begin
            $display("Progress: 周期%d, 输入%d, 输出%d", cycle_cnt, sample_cnt, output_cnt);
        end
    end

    // ===== 性能警告 =====
    always @(posedge clk) begin
        if (sample_cnt > 100 && output_cnt < sample_cnt * 0.8) begin
            $display("WARNING: 输出数量 (%d) 明显少于输入数量 (%d), 可能存在处理瓶颈", 
                     output_cnt, sample_cnt);
        end
    end

endmodule