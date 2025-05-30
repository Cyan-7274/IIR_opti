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
        // 表头字段，适配当前opti_sos（DF2T单寄存器状态变量w1/w2）
        $fwrite(fd, "cycle data_in data_in_valid data_out data_out_valid u_sos0_data_out u_sos0_data_valid_out w0_reg w1 w2 mul_b0_w0_a mul_b0_w0_b mul_b0_w0_p mul_b1_w1_a mul_b1_w1_b mul_b1_w1_p mul_b2_w2_a mul_b2_w2_b mul_b2_w2_p mul_a1_w1_a mul_a1_w1_b mul_a1_w1_p mul_a2_w2_a mul_a2_w2_b mul_a2_w2_p valid_pipe0 valid_pipe1 valid_pipe2 acc_sum_w0 acc_sum_y\n");

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

    // 信号保存（字段与表头顺序严格一致，DF2T结构w1/w2单寄存器！）
    always @(posedge clk) begin
        $fwrite(fd,
            "%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",
            (^cycle_cnt === 1'bx)        ? 0 : cycle_cnt,
            (^data_in === 1'bx)          ? 0 : data_in,
            (^data_in_valid === 1'bx)    ? 0 : data_in_valid,
            (^data_out === 1'bx)         ? 0 : data_out,
            (^data_out_valid === 1'bx)   ? 0 : data_out_valid,
            (^u_top.u_sos0.data_out === 1'bx)           ? 0 : u_top.u_sos0.data_out,
            (^u_top.u_sos0.data_valid_out === 1'bx)     ? 0 : u_top.u_sos0.data_valid_out,
            (^u_top.u_sos0.w0_reg === 1'bx)             ? 0 : u_top.u_sos0.w0_reg,
            (^u_top.u_sos0.w1 === 1'bx)                 ? 0 : u_top.u_sos0.w1,
            (^u_top.u_sos0.w2 === 1'bx)                 ? 0 : u_top.u_sos0.w2,
            (^u_top.u_sos0.mul_b0_w0_a === 1'bx)        ? 0 : u_top.u_sos0.mul_b0_w0_a,
            (^u_top.u_sos0.mul_b0_w0_b === 1'bx)        ? 0 : u_top.u_sos0.mul_b0_w0_b,
            (^u_top.u_sos0.p_b0_w0 === 1'bx)            ? 0 : u_top.u_sos0.p_b0_w0,
            (^u_top.u_sos0.mul_b1_w1_a === 1'bx)        ? 0 : u_top.u_sos0.mul_b1_w1_a,
            (^u_top.u_sos0.mul_b1_w1_b === 1'bx)        ? 0 : u_top.u_sos0.mul_b1_w1_b,
            (^u_top.u_sos0.p_b1_w1 === 1'bx)            ? 0 : u_top.u_sos0.p_b1_w1,
            (^u_top.u_sos0.mul_b2_w2_a === 1'bx)        ? 0 : u_top.u_sos0.mul_b2_w2_a,
            (^u_top.u_sos0.mul_b2_w2_b === 1'bx)        ? 0 : u_top.u_sos0.mul_b2_w2_b,
            (^u_top.u_sos0.p_b2_w2 === 1'bx)            ? 0 : u_top.u_sos0.p_b2_w2,
            (^u_top.u_sos0.mul_a1_w1_a === 1'bx)        ? 0 : u_top.u_sos0.mul_a1_w1_a,
            (^u_top.u_sos0.mul_a1_w1_b === 1'bx)        ? 0 : u_top.u_sos0.mul_a1_w1_b,
            (^u_top.u_sos0.p_a1_w1 === 1'bx)            ? 0 : u_top.u_sos0.p_a1_w1,
            (^u_top.u_sos0.mul_a2_w2_a === 1'bx)        ? 0 : u_top.u_sos0.mul_a2_w2_a,
            (^u_top.u_sos0.mul_a2_w2_b === 1'bx)        ? 0 : u_top.u_sos0.mul_a2_w2_b,
            (^u_top.u_sos0.p_a2_w2 === 1'bx)            ? 0 : u_top.u_sos0.p_a2_w2,
            (^u_top.u_sos0.valid_pipe[0] === 1'bx)      ? 0 : u_top.u_sos0.valid_pipe[0],
            (^u_top.u_sos0.valid_pipe[1] === 1'bx)      ? 0 : u_top.u_sos0.valid_pipe[1],
            (^u_top.u_sos0.valid_pipe[2] === 1'bx)      ? 0 : u_top.u_sos0.valid_pipe[2],
            (^u_top.u_sos0.acc_sum_w0 === 1'bx)         ? 0 : u_top.u_sos0.acc_sum_w0,
            (^u_top.u_sos0.acc_sum_y === 1'bx)          ? 0 : u_top.u_sos0.acc_sum_y
        );
    end

endmodule