// 流水线控制模块 - 保持原始命名
module opti_control_pipeline (
    input  wire        clk,             // 时钟
    input  wire        rst_n,           // 低电平有效复位
    input  wire        start,           // 开始处理信号
    input  wire        data_in_valid,   // 输入数据有效
    input  wire        sos_out_valid,   // 最终SOS输出有效
    input  wire [15:0] sos_out_data,    // 最终SOS输出数据
    
    output reg         filter_done,     // 滤波器处理完成
    output reg         pipeline_en,     // 流水线使能
    output reg  [10:0] addr,            // 样本地址
    output reg  [15:0] data_out,        // 输出数据
    output reg         data_out_valid,  // 输出数据有效
    output reg         stable_out       // 稳定输出标志
);

    // 常量定义
    localparam STABLE_TIME = 10'd237;   // 稳定时间 - 使用MATLAB的建议值
    localparam MAX_SAMPLES = 11'd2047;  // 最大样本数
    
    // 内部控制寄存器
    reg [9:0]  stable_counter;          // 稳定计数器
    reg        filter_initialized;      // 滤波器初始化标志
    reg        first_data_received;     // 第一个数据接收标志
    
    // 流水线控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_done <= 1'b0;
            pipeline_en <= 1'b0;
            addr <= 11'd0;
            data_out <= 16'd0;
            data_out_valid <= 1'b0;
            stable_out <= 1'b0;
            stable_counter <= 10'd0;
            filter_initialized <= 1'b0;
            first_data_received <= 1'b0;
        end else begin
            // 启动控制
            if (start && !pipeline_en) begin
                // 开始处理
                pipeline_en <= 1'b1;
                addr <= 11'd0;
                stable_counter <= 10'd0;
                filter_initialized <= 1'b0;
                first_data_received <= 1'b0;
                filter_done <= 1'b0;
                data_out_valid <= 1'b0;
                stable_out <= 1'b0;
            end
            
            // 检测第一个输入数据
            if (pipeline_en && data_in_valid && !first_data_received) begin
                first_data_received <= 1'b1;
            end
            
            // 输出数据处理
            if (pipeline_en && sos_out_valid) begin
                // 记录SOS输出数据
                data_out <= sos_out_data;
                
                // 稳定期处理
                if (!filter_initialized) begin
                    // 如果还在稳定期
                    if (stable_counter >= STABLE_TIME) begin
                        // 稳定期结束
                        filter_initialized <= 1'b1;
                        stable_out <= 1'b1;
                        // 现在可以输出有效数据
                        data_out_valid <= 1'b1;
                    end else if (first_data_received) begin
                        // 已接收到第一个数据，开始稳定计数
                        stable_counter <= stable_counter + 10'd1;
                        data_out_valid <= 1'b0; // 稳定期内不输出
                    end
                end else begin
                    // 稳定期后，所有输出都有效
                    data_out_valid <= 1'b1;
                    
                    // 地址计数
                    if (addr < MAX_SAMPLES) begin
                        addr <= addr + 11'd1;
                    end else begin
                        // 所有样本处理完成
                        filter_done <= 1'b1;
                        pipeline_en <= 1'b0; // 停止流水线
                    end
                end
            end else if (!sos_out_valid) begin
                // 无SOS输出时，关闭输出有效信号
                data_out_valid <= 1'b0;
            end
        end
    end
    
endmodule