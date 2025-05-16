// Verilog-95兼容版 testbench
`timescale 1ns / 1ps

module tb_opti ();

    reg         clk;
    reg         rst_n;
    reg         start;
    reg  [15:0] data_in;
    reg         data_in_valid;

    wire        filter_done;
    wire [10:0] addr;
    wire [15:0] data_out;
    wire        data_out_valid;
    wire        stable_out;

    reg [15:0] test_data [0:2047];
    reg [15:0] exp_data [0:2047];
    integer data_index;
    reg        data_loaded;
    integer    i;
    integer    errors;
    integer    first_correct;
    reg [15:0] result_data [0:2047];

    opti_top dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .data_in       (data_in),
        .data_in_valid (data_in_valid),
        .filter_done   (filter_done),
        .addr          (addr),
        .data_out      (data_out),
        .data_out_valid(data_out_valid),
        .stable_out    (stable_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (data_out_valid && stable_out)
            result_data[addr] <= data_out;
    end

    task check_results;
        begin
            errors = 0;
            first_correct = -1;
            $display("开始验证结果...");
            for (i = 0; i < 2048; i = i + 1) begin
                if (result_data[i] != exp_data[i]) begin
                    if (i > 237 && errors < 10)
                        $display("错误: addr=%d, 实际=%d (0x%h), 期望=%d (0x%h)",
                                i, $signed(result_data[i]), result_data[i],
                                $signed(exp_data[i]), exp_data[i]);
                    errors = errors + 1;
                end else if (first_correct == -1 && i > 0 && result_data[i] !== 16'hx) begin
                    first_correct = i;
                    $display("首个正确样本: addr=%d, 值=%d (0x%h)",
                             i, $signed(result_data[i]), result_data[i]);
                end
            end
            $display("验证完成: 总样本数=2048, 错误数=%d, 首个正确样本=%d", errors, first_correct);
            if (errors == 0)
                $display("测试通过! 所有样本都与期望值匹配。");
            else if (first_correct != -1 && first_correct <= 300)
                $display("测试部分通过: 在样本%d后开始有正确结果，但仍有错误。", first_correct);
            else
                $display("测试失败: 大多数样本不匹配。");
        end
    endtask

    initial begin
        rst_n = 0;
        start = 0;
        data_in = 16'd0;
        data_in_valid = 0;
        data_index = 0;
        data_loaded = 0;
        i = 0;
        errors = 0;
        first_correct = -1;
        $display("测试平台: 开始复位 - rst_n = %b", rst_n);

        $display("测试开始: 加载测试数据...");
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_data);
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/ref_output.hex", exp_data);

        if (test_data[0] === 16'hx) begin
            $display("错误: 测试数据加载失败! 尝试备选路径...");
            $readmemh("./test_signal.hex", test_data);
            $readmemh("./ref_output.hex", exp_data);
            if (test_data[0] === 16'hx) begin
                $display("创建简单测试数据代替...");
                for (i = 0; i < 2048; i = i + 1) begin
                    test_data[i] = (i < 100) ? 16'h0100 : 16'h0000;
                    exp_data[i] = 16'h0000;
                end
            end
        end
        data_loaded = 1;
        $display("测试数据加载完成: 首个样本值为 %h (%d)", test_data[0], $signed(test_data[0]));
        $display("测试样本预览:");
        for (i = 0; i < 10; i = i + 1) begin
            $display("  样本 %d: 输入=%h (%d), 期望输出=%h (%d)",
                      i, test_data[i], $signed(test_data[i]),
                      exp_data[i], $signed(exp_data[i]));
        end
        #200;
        rst_n = 1;
        $display("测试平台: 复位释放 - rst_n = %b", rst_n);
        #100;
        start = 1;
        #20 start = 0;
        #100;

        $display("开始流水线高速数据处理...");
        for (data_index = 0; data_index < 2048; data_index = data_index + 1) begin
            @(posedge clk);
            data_in = test_data[data_index];
            data_in_valid = 1;
            if (data_index % 500 == 0)
                $display("发送样本 %d/%d", data_index, 2048);
        end
        @(posedge clk);
        data_in_valid = 0;
        $display("等待滤波器处理完成...");
        wait(filter_done);
        #1000;
        check_results();
        $display("测试完成");
        $finish;
    end

endmodule