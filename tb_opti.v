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
    integer i;
    integer fd;
    reg [31:0] cycle_cnt;

    // 输入激励
    localparam N = 2048;
    reg signed [23:0] test_vector [0:N-1];

    // DUT实例（4级sos，sos0内部信号，sos1~sos3仅外部信号）
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

        $fwrite(fd, "cycle ");                      // cycle
        $fwrite(fd, "data_in ");                    // x_in
        $fwrite(fd, "data_in_valid ");              // x_valid
        $fwrite(fd, "u_sos0_data_in ");             // sos0_x
        $fwrite(fd, "u_sos0_data_valid_in ");       // sos0_x_valid
        $fwrite(fd, "u_sos0_data_out ");            // sos0_y
        $fwrite(fd, "u_sos0_data_valid_out ");      // sos0_y_valid
        $fwrite(fd, "u_sos1_data_in ");             // sos1_x
        $fwrite(fd, "u_sos1_data_valid_in ");       // sos1_x_valid
        $fwrite(fd, "u_sos1_data_out ");            // sos1_y
        $fwrite(fd, "u_sos1_data_valid_out ");      // sos1_y_valid
        $fwrite(fd, "u_sos2_data_in ");             // sos2_x
        $fwrite(fd, "u_sos2_data_valid_in ");       // sos2_x_valid
        $fwrite(fd, "u_sos2_data_out ");            // sos2_y
        $fwrite(fd, "u_sos2_data_valid_out ");      // sos2_y_valid
        $fwrite(fd, "u_sos3_data_in ");             // sos3_x
        $fwrite(fd, "u_sos3_data_valid_in ");       // sos3_x_valid
        $fwrite(fd, "u_sos3_data_out ");            // sos3_y
        $fwrite(fd, "u_sos3_data_valid_out ");      // sos3_y_valid
        $fwrite(fd, "data_out ");                   // y_out
        $fwrite(fd, "data_out_valid ");             // y_out_valid
        $fwrite(fd, "u_sos0_w0 u_sos0_w1 u_sos0_w2 "); // sos0_w0 sos0_w1 sos0_w2
        $fwrite(fd, "\n");

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
        $fwrite(fd, "%0d %0d %0d ",
            (^cycle_cnt === 1'bx)        ? 0 : cycle_cnt,
            (^data_in === 1'bx)          ? 0 : data_in,
            (^data_in_valid === 1'bx)    ? 0 : data_in_valid
        );
        // --------- sos0输入 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos0.data_in === 1'bx)           ? 0 : u_top.u_sos0.data_in,
            (^u_top.u_sos0.data_valid_in === 1'bx)     ? 0 : u_top.u_sos0.data_valid_in
        );
        // --------- sos0输出 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos0.data_out === 1'bx)          ? 0 : u_top.u_sos0.data_out,
            (^u_top.u_sos0.data_valid_out === 1'bx)    ? 0 : u_top.u_sos0.data_valid_out
        );
        // --------- sos1输入 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos1.data_in === 1'bx)           ? 0 : u_top.u_sos1.data_in,
            (^u_top.u_sos1.data_valid_in === 1'bx)     ? 0 : u_top.u_sos1.data_valid_in
        );
        // --------- sos1输出 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos1.data_out === 1'bx)          ? 0 : u_top.u_sos1.data_out,
            (^u_top.u_sos1.data_valid_out === 1'bx)    ? 0 : u_top.u_sos1.data_valid_out
        );
        // --------- sos2输入 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos2.data_in === 1'bx)           ? 0 : u_top.u_sos2.data_in,
            (^u_top.u_sos2.data_valid_in === 1'bx)     ? 0 : u_top.u_sos2.data_valid_in
        );
        // --------- sos2输出 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos2.data_out === 1'bx)          ? 0 : u_top.u_sos2.data_out,
            (^u_top.u_sos2.data_valid_out === 1'bx)    ? 0 : u_top.u_sos2.data_valid_out
        );
        // --------- sos3输入 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos3.data_in === 1'bx)           ? 0 : u_top.u_sos3.data_in,
            (^u_top.u_sos3.data_valid_in === 1'bx)     ? 0 : u_top.u_sos3.data_valid_in
        );
        // --------- sos3输出 ---------
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos3.data_out === 1'bx)          ? 0 : u_top.u_sos3.data_out,
            (^u_top.u_sos3.data_valid_out === 1'bx)    ? 0 : u_top.u_sos3.data_valid_out
        );
        // --------- 顶层输出 ---------
        $fwrite(fd, "%0d %0d ",
            (^data_out === 1'bx)         ? 0 : data_out,
            (^data_out_valid === 1'bx)   ? 0 : data_out_valid
        );
        // --------- sos0内部关键信号 ---------

        // --------- sos0内部关键信号 ---------
        $fwrite(fd, "%0d %0d %0d ",
            (^u_top.u_sos0.w0 === 1'bx)            ? 0 : u_top.u_sos0.w0,
            (^u_top.u_sos0.w1 === 1'bx)            ? 0 : u_top.u_sos0.w1,
            (^u_top.u_sos0.w2 === 1'bx)            ? 0 : u_top.u_sos0.w2
        );
        $fwrite(fd, "%0d %0d ",
            (^u_top.u_sos0.w0_next === 1'bx)       ? 0 : u_top.u_sos0.w0_next,
            (^u_top.u_sos0.acc_sum_w0 === 1'bx)    ? 0 : u_top.u_sos0.acc_sum_w0
        );
        // 若你要trace x_pipe[0]
        $fwrite(fd, "%0d ",
            (^u_top.u_sos0.x_pipe[0] === 1'bx)     ? 0 : u_top.u_sos0.x_pipe[0]
        );

        // 若要trace乘法器输出
        $fwrite(fd, "%0d %0d %0d %0d %0d ",
            (^u_top.u_sos0.p_b0_w0 === 1'bx)       ? 0 : u_top.u_sos0.p_b0_w0,
            (^u_top.u_sos0.p_b1_w1 === 1'bx)       ? 0 : u_top.u_sos0.p_b1_w1,
            (^u_top.u_sos0.p_b2_w2 === 1'bx)       ? 0 : u_top.u_sos0.p_b2_w2,
            (^u_top.u_sos0.p_a1_w1 === 1'bx)       ? 0 : u_top.u_sos0.p_a1_w1,
            (^u_top.u_sos0.p_a2_w2 === 1'bx)       ? 0 : u_top.u_sos0.p_a2_w2
        );

        // 若要trace valid_in
        $fwrite(fd, "%0d ",
            (^u_top.u_sos0.data_valid_in === 1'bx) ? 0 : u_top.u_sos0.data_valid_in
        );
        // 若要trace valid_pipe，可只保留前几级（如0、1、2）
        $fwrite(fd, "%0d %0d %0d ",
            (^u_top.u_sos0.vld_pipe[0] === 1'bx)   ? 0 : u_top.u_sos0.vld_pipe[0],
            (^u_top.u_sos0.vld_pipe[1] === 1'bx)   ? 0 : u_top.u_sos0.vld_pipe[1],
            (^u_top.u_sos0.vld_pipe[2] === 1'bx)   ? 0 : u_top.u_sos0.vld_pipe[2]
        );

        $fwrite(fd, "\n");
    end
endmodule