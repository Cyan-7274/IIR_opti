`timescale 1ns/1ps

module tb_opti;
    reg clk;
    reg rst_n;
    reg signed [15:0] data_in;
    reg data_in_valid;
    wire data_out_valid;
    wire signed [15:0] data_out;

    integer fd, fd_hex;
    reg [31:0] cycle_cnt, input_idx;
    reg signed [15:0] test_vector [0:2047];
    reg [2:0] gap_cnt; // 0~4, 5拍一采样

    initial clk = 0;
    always #1.5625 clk = ~clk;

    opti_top u_top (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_in),
        .valid_in (data_in_valid),
        .data_out (data_out),
        .valid_out(data_out_valid)
    );

    initial begin
        rst_n = 0;
        data_in = 16'sd0;
        data_in_valid = 1'b0;
        cycle_cnt = 32'd0;
        input_idx = 32'd0;
        gap_cnt = 3'd0;
        fd = $fopen("D:/A_Hesper/IIRfilter/qts/tb/rtl_trace.txt", "w");
        fd_hex = $fopen("D:/A_Hesper/IIRfilter/qts/tb/rtl_output.hex", "w");
        $fwrite(fd, "cycle data_in data_in_valid data_out data_out_valid\n");
        $readmemh("D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex", test_vector);

        #100; rst_n = 1;
        repeat(10) @(posedge clk);

        while (input_idx < 2048) begin
            @(posedge clk);
            if (gap_cnt == 3'd0) begin
                data_in <= test_vector[input_idx];
                data_in_valid <= 1'b1;
                input_idx <= input_idx + 1;
            end else begin
                data_in_valid <= 1'b0;
                data_in <= 16'sd0;
            end
            gap_cnt <= gap_cnt + 1'b1;
            if (gap_cnt == 3'd3)
                gap_cnt <= 3'd0;
        end

        @(posedge clk);
        data_in_valid <= 1'b0;
        data_in <= 16'sd0;
        repeat(100) @(posedge clk);
        $fclose(fd);
        $fclose(fd_hex);
        $display("SIM DONE.");
        $finish;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_cnt <= 32'd0;
        else
            cycle_cnt <= cycle_cnt + 1;
    end

    always @(posedge clk) begin
        if (data_in_valid || data_out_valid) begin
            $fwrite(fd, "%0d %0d %0d %0d %0d\n",
                cycle_cnt, data_in, data_in_valid, data_out, data_out_valid);
        end
        if (data_out_valid) begin
            if (data_out < 0)
                $fwrite(fd_hex, "%04X\n", data_out + 16'h10000);
            else
                $fwrite(fd_hex, "%04X\n", data_out);
        end
    end
endmodule