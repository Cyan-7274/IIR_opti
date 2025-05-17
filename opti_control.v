module opti_control (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        data_in_valid,
    input  wire        sos_out_valid,
    input  wire [15:0] sos_out_data,
    output reg         filter_done,
    output reg         pipeline_en,
    output reg  [10:0] addr,
    output reg  [15:0] data_out,
    output reg         data_out_valid,
    output reg         stable_out
);
    localparam S_IDLE   = 2'd0;
    localparam S_STABLE = 2'd1;
    localparam S_RUN    = 2'd2;
    localparam S_DONE   = 2'd3;

    localparam STABLE_TIME = 10'd237;
    localparam MAX_SAMPLES = 11'd2047;

    reg [1:0] state, next_state;
    reg [9:0] stable_counter;
    reg [10:0] sample_counter;

    // 状态转移
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // 下一个状态逻辑
    always @(*) begin
        case (state)
            S_IDLE:    next_state = (start)                        ? S_STABLE : S_IDLE;
            S_STABLE:  next_state = (stable_counter >= STABLE_TIME)? S_RUN    : S_STABLE;
            S_RUN:     next_state = (sample_counter >= MAX_SAMPLES)? S_DONE   : S_RUN;
            S_DONE:    next_state = S_IDLE;
            default:   next_state = S_IDLE;
        endcase
    end

    // 输出和寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_en    <= 1'b0;
            filter_done    <= 1'b0;
            stable_out     <= 1'b0;
            data_out       <= 16'd0;
            data_out_valid <= 1'b0;
            addr           <= 11'd0;
            stable_counter <= 10'd0;
            sample_counter <= 11'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    pipeline_en    <= 1'b0;
                    filter_done    <= 1'b0;
                    stable_out     <= 1'b0;
                    data_out_valid <= 1'b0;
                    addr           <= 11'd0;
                    stable_counter <= 10'd0;
                    sample_counter <= 11'd0;
                end
                S_STABLE: begin
                    pipeline_en    <= 1'b1;
                    data_out_valid <= 1'b0;
                    if (sos_out_valid)
                        stable_counter <= stable_counter + 10'd1;
                    if (stable_counter >= STABLE_TIME)
                        stable_out <= 1'b1;
                    else
                        stable_out <= 1'b0;
                end
                S_RUN: begin
                    pipeline_en    <= 1'b1;
                    stable_out     <= 1'b1;
                    if (sos_out_valid) begin
                        data_out       <= sos_out_data;
                        data_out_valid <= 1'b1;
                        addr           <= addr + 11'd1;
                        sample_counter <= sample_counter + 11'd1;
                    end else begin
                        data_out_valid <= 1'b0;
                    end
                end
                S_DONE: begin
                    pipeline_en    <= 1'b0;
                    filter_done    <= 1'b1;
                    stable_out     <= 1'b1;
                    data_out_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule