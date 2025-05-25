// 精准同步、状态机健壮的控制模块
module opti_control (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire         data_in_valid,
    input  wire         sos_out_valid,       // 最后一级sos输出数据有效
    input  wire signed [23:0] sos_out_data,  // 最后一级sos输出数据
    output reg          filter_done,
    output reg          pipeline_en,
    output reg  [10:0]  addr,
    output reg  signed [23:0] data_out,
    output reg          data_out_valid,
    output reg          stable_out
);

    // 状态定义
    localparam IDLE  = 2'd0;
    localparam RUN   = 2'd1;
    localparam DONE  = 2'd2;

    reg [1:0] state, state_nxt;
    localparam N = 2048;

    reg [10:0] in_cnt;    // 输入计数器
    reg [10:0] out_cnt;   // 输出计数器

    // ====== 状态机 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= state_nxt;
    end

    always @(*) begin
        case (state)
            IDLE:  state_nxt = start ? RUN : IDLE;
            RUN:   state_nxt = (out_cnt == N) ? DONE : RUN;
            DONE:  state_nxt = IDLE;
            default: state_nxt = IDLE;
        endcase
    end

    // ====== pipeline_en控制 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pipeline_en <= 1'b0;
        else
            pipeline_en <= (state == RUN);
    end

    // ====== 输入计数器 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_cnt <= 11'd0;
        else if (state == IDLE)
            in_cnt <= 11'd0;
        else if ((state == RUN) && data_in_valid && (in_cnt < N))
            in_cnt <= in_cnt + 1'b1;
    end

    // ====== 输出地址&计数器 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_cnt <= 11'd0;
        else if (state == IDLE)
            out_cnt <= 11'd0;
        else if ((state == RUN) && sos_out_valid && (out_cnt < N))
            out_cnt <= out_cnt + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            addr <= 11'd0;
        else if (state == IDLE)
            addr <= 11'd0;
        else if ((state == RUN) && sos_out_valid && (addr < N))
            addr <= addr + 1'b1;
    end

    // ====== 输出数据与valid ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= 24'sd0;
            data_out_valid <= 1'b0;
        end else if ((state == RUN) && sos_out_valid && (out_cnt < N)) begin
            data_out       <= sos_out_data;
            data_out_valid <= 1'b1;
        end else begin
            data_out_valid <= 1'b0;
        end
    end

    // ====== filter_done信号 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            filter_done <= 1'b0;
        else if ((state == RUN) && (out_cnt == N))
            filter_done <= 1'b1;
        else if (state == IDLE)
            filter_done <= 1'b0;
    end

    // ====== stable_out信号（输出开始后一直为1） ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stable_out <= 1'b0;
        else if ((state == RUN) && (out_cnt == 0) && sos_out_valid)
            stable_out <= 1'b1;
        else if (state == IDLE)
            stable_out <= 1'b0;
    end

    // ====== ASIC友好调试辅助：建议仿真时加$display ======
    // synthesis translate_off
    always @(posedge clk) begin
        if (state == RUN && in_cnt < N && data_in_valid)
            $display("INJECT: in_cnt=%0d", in_cnt);
        if (state == RUN && sos_out_valid && out_cnt < N)
            $display("OUTPUT: out_cnt=%0d data_out=%h valid=%b", out_cnt, sos_out_data, data_out_valid);
        if (filter_done)
            $display("FILTER DONE at time %0t", $time);
    end
    // synthesis translate_on

endmodule