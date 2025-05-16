module opti_control_pipeline (
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
    localparam STABLE_TIME = 10'd237;
    localparam MAX_SAMPLES = 11'd2047;

    reg [9:0] stable_counter;
    reg filter_initialized;
    reg first_data_received;
    reg last_valid;

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
            last_valid <= 1'b0;
        end else begin
            if (start && !pipeline_en) begin
                pipeline_en <= 1'b1;
                addr <= 11'd0;
                stable_counter <= 10'd0;
                filter_initialized <= 1'b0;
                first_data_received <= 1'b0;
                filter_done <= 1'b0;
                data_out_valid <= 1'b0;
                stable_out <= 1'b0;
            end

            if (pipeline_en && data_in_valid && !first_data_received) begin
                first_data_received <= 1'b1;
            end

            // 输出数据处理
            if (pipeline_en && sos_out_valid) begin
                data_out <= sos_out_data;
                last_valid <= 1'b1;
                if (!filter_initialized) begin
                    if (stable_counter >= STABLE_TIME) begin
                        filter_initialized <= 1'b1;
                        stable_out <= 1'b1;
                        data_out_valid <= 1'b1;
                    end else if (first_data_received) begin
                        stable_counter <= stable_counter + 10'd1;
                        data_out_valid <= 1'b0;
                    end
                end else begin
                    data_out_valid <= 1'b1;
                    if (addr < MAX_SAMPLES)
                        addr <= addr + 11'd1;
                    else begin
                        filter_done <= 1'b1;
                        pipeline_en <= 1'b0;
                    end
                end
            end else if (last_valid) begin
                // 保持至少一拍
                data_out_valid <= 1'b0;
                last_valid <= 1'b0;
            end
        end
    end
endmodule