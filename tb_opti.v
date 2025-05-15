// 修改版测试平台 - 完全兼容原始模块名称
// 包含流水线架构高速处理的支持
`timescale 1ns / 1ps

module tb_opti ();

    // 定义测试信号
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
    
    // 测试数据存储
    reg [15:0] test_data [0:2047];
    reg [15:0] exp_data [0:2047];
    integer data_index;
    
    // 用于波形显示的信号
    reg        data_loaded;    // 数据加载完成标志
    integer    i;              // 循环计数器
    integer    errors;         // 错误计数
    integer    first_correct;  // 第一个正确样本索引
    
    // 结果存储
    reg [15:0] result_data [0:2047];
    
    // 实例化被测设备 - 确保使用原始模块名称
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
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz时钟
    end
    
    // 输出结果保存
    always @(posedge clk) begin
        if (data_out_valid && stable_out) begin
            // 保存结果到当前地址位置
            result_data[addr] <= data_out;
            
            // 调试输出 - 每100个样本显示一次
            if (addr % 100 == 0) begin
                $display("结果保存: addr=%d, data=%d (0x%h)", 
                          addr, $signed(data_out), data_out);
            end
        end
    end
    
    // 结果验证任务
    task check_results;
        begin
            errors = 0;
            first_correct = -1;
            
            $display("开始验证结果...");
            
            for (i = 0; i < 2048; i = i + 1) begin
                if (result_data[i] != exp_data[i]) begin
                    if (i > 237 && errors < 10) begin // 忽略稳定前的样本
                        $display("错误: addr=%d, 实际=%d (0x%h), 期望=%d (0x%h)",
                                i, $signed(result_data[i]), result_data[i],
                                $signed(exp_data[i]), exp_data[i]);
                    end
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
    
    // 主测试流程 - 流水线架构高速处理
    initial begin
        // 初始化变量
        rst_n = 0;
        start = 0;
        data_in = 16'd0;
        data_in_valid = 0;
        data_index = 0;
        data_loaded = 0;
        i = 0;
        errors = 0;
        first_correct = -1;
        
        // 复位监控
        $display("测试平台: 开始复位 - rst_n = %b", rst_n);
        
        // 加载测试数据 - 使用原始路径
        $display("测试开始: 加载测试数据...");
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_data);
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/ref_output.hex", exp_data);
        
        // 测试数据加载检查
        if (test_data[0] === 16'hx) begin
            $display("错误: 测试数据加载失败! 尝试备选路径...");
            // 尝试相对路径
            $readmemh("./test_signal.hex", test_data);
            $readmemh("./ref_output.hex", exp_data);
            
            // 再次检查
            if (test_data[0] === 16'hx) begin
                // 创建简单测试数据
                $display("创建简单测试数据代替...");
                for (i = 0; i < 2048; i = i + 1) begin
                    test_data[i] = (i < 100) ? 16'h0100 : 16'h0000;
                    exp_data[i] = 16'h0000;
                end
            end
        end
        
        data_loaded = 1;
        $display("测试数据加载完成: 首个样本值为 %h (%d)", test_data[0], $signed(test_data[0]));
        
        // 打印部分样本值
        $display("测试样本预览:");
        for (i = 0; i < 10; i = i + 1) begin
            $display("  样本 %d: 输入=%h (%d), 期望输出=%h (%d)", 
                      i, test_data[i], $signed(test_data[i]), 
                      exp_data[i], $signed(exp_data[i]));
        end
        
        // 保持复位一段时间
        #200;
        
        // 释放复位
        rst_n = 1;
        $display("测试平台: 复位释放 - rst_n = %b", rst_n);
        #100;
        
        // 发送开始信号
        start = 1;
        #20 start = 0;
        
        // 等待初始化完成
        #100;
        
        // 流水线处理 - 高速发送数据，每个时钟周期发送一个
        $display("开始流水线高速数据处理...");
        
        for (data_index = 0; data_index < 2048; data_index = data_index + 1) begin
            @(posedge clk);
            data_in = test_data[data_index];
            data_in_valid = 1;
            
            // 每500个样本打印一次状态
            if (data_index % 500 == 0) begin
                $display("发送样本 %d/%d", data_index, 2048);
            end
        end
        
        // 关闭输入有效信号
        @(posedge clk);
        data_in_valid = 0;
        
        // 等待滤波器处理完成
        $display("等待滤波器处理完成...");
        wait(filter_done);
        
        // 额外等待一些时间确保所有输出都已保存
        #1000;
        
        // 验证结果
        check_results();
        
        // 结束测试
        $display("测试完成");
        $finish;
    end

endmodule