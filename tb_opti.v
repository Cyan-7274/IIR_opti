`timescale 1ns/1ps

module tb_opti;
    // 信号声明区
    reg clk, rst_n, start;
    reg signed [23:0] data_in;
    reg data_in_valid;
    wire filter_done, data_out_valid, stable_out;
    wire [10:0] addr;
    wire signed [23:0] data_out;

    integer sample_cnt;
    integer i, j;
    integer fd;
    reg [31:0] cycle_cnt;

    // 输入激励
    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];

    // DUT实例
    opti_top u_top (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in(data_in), .data_in_valid(data_in_valid),
        .filter_done(filter_done), .addr(addr),
        .data_out(data_out), .data_out_valid(data_out_valid),
        .stable_out(stable_out)
    );

    // 统一流程
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0; 
        start = 0; 
        data_in = 0; 
        data_in_valid = 0;
        sample_cnt = 0;
        cycle_cnt = 0;
        i = 0;
        j = 0;

        // 打开文件并写表头
        fd = $fopen("D:/A_Hesper/IIRfilter/qts/tb/rtl_trace.txt", "w");
        if (fd == 0) $display("File open failed!");
        $fwrite(fd, "cycle data_in data_in_valid data_out data_out_valid mul_b0_x_a mul_b0_x_b mul_b0_x_p mul_b1_x_a mul_b1_x_b mul_b1_x_p mul_b2_x_a mul_b2_x_b mul_b2_x_p mul_a1_y_a mul_a1_y_b mul_a1_y_p mul_a2_y_a mul_a2_y_b mul_a2_y_p x_pipe0 x_pipe6 x_pipe12 y1_pipe0 y1_pipe6 y1_pipe12 y2_pipe0 y2_pipe6 y2_pipe12 valid_pipe0 valid_pipe6 valid_pipe12\n");


        // 载入激励
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);

        // 上电复位
        #100;
        rst_n = 1;
        #50;
        start = 1;
        #10;
        start = 0;
        // 激励输入
        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            data_in <= test_vector[i];
            data_in_valid <= 1'b1;
        end
        @(posedge clk);
        data_in_valid <= 1'b0;

        // 仿真超时自动关闭
        #2000000
        $fclose(fd);
        $display("SIM TIMEOUT.");
        $finish;
    end

    // 时钟
    always #5 clk = ~clk;

    // cycle计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_cnt <= 0;
        else
            cycle_cnt <= cycle_cnt + 1;
    end

    // 采样计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_cnt <= 0;
        else if (data_in_valid)
            sample_cnt <= sample_cnt + 1;
    end

    // 信号保存
    always @(posedge clk) begin
        $fwrite(fd, "%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",
            cycle_cnt,
            data_in, data_in_valid,
            data_out, data_out_valid,
            u_top.u_sos0.mul_b0_x.a,
            u_top.u_sos0.mul_b0_x.b,
            u_top.u_sos0.mul_b0_x.p,
            u_top.u_sos0.mul_b1_x.a,
            u_top.u_sos0.mul_b1_x.b,
            u_top.u_sos0.mul_b1_x.p,
            u_top.u_sos0.mul_b2_x.a,
            u_top.u_sos0.mul_b2_x.b,
            u_top.u_sos0.mul_b2_x.p,
            u_top.u_sos0.mul_a1_y.a,
            u_top.u_sos0.mul_a1_y.b,
            u_top.u_sos0.mul_a1_y.p,
            u_top.u_sos0.mul_a2_y.a,
            u_top.u_sos0.mul_a2_y.b,
            u_top.u_sos0.mul_a2_y.p,
            u_top.u_sos0.x_pipe[0],
            u_top.u_sos0.x_pipe[6],
            u_top.u_sos0.x_pipe[12],
            u_top.u_sos0.y1_pipe[0],
            u_top.u_sos0.y1_pipe[6],
            u_top.u_sos0.y1_pipe[12],
            u_top.u_sos0.y2_pipe[0],
            u_top.u_sos0.y2_pipe[6],
            u_top.u_sos0.y2_pipe[12],
            u_top.u_sos0.valid_pipe[0],
            u_top.u_sos0.valid_pipe[6],
            u_top.u_sos0.valid_pipe[12]
        );
    end

endmodule