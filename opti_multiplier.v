// 标准有符号乘法器，输出Q4.28格式，ready握手
module opti_multiplier (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [31:0] p,
    output reg         valid,
    input  wire        ready
);
    reg en_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 32'd0;
            valid <= 1'b0;
            en_r <= 1'b0;
        end else begin
            en_r <= en;
            // 单周期乘法
            if (en) begin
                p <= $signed(a) * $signed(b);
                valid <= 1'b1;
            end else if (valid && ready) begin
                valid <= 1'b0;
            end
        end
    end
endmodule