// Q2.22*Q2.22 全流水线Booth-4乘法器（无parameter，Verilog-2001标准，位宽安全）
module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire signed [23:0] a, // Q2.22
    input  wire signed [23:0] b, // Q2.22
    output reg  signed [23:0] p, // Q2.22
    output reg          valid_out,
    // 调试用输出：最终48位累加和（溢出前）
    output reg  signed [47:0] debug_sum
);

    // ----------- 固定常数定义（无parameter） -----------
    // 24位输入，Booth-4组数为12
    // 管线寄存器、部分积、累加器
    reg signed [23:0] a_pipe [0:12];
    reg signed [23:0] b_pipe [0:12];
    reg               valid_pipe [0:12];
    reg signed [47:0] pp   [0:11];
    reg signed [47:0] sum_pipe [0:12];

    // booth_bits安全提取
    reg [2:0] booth_bits [0:11];
    integer i;
    integer j;

    // ----------- 管线推进 -----------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<=12;i=i+1) begin
                a_pipe[i] <= 24'sd0;
                b_pipe[i] <= 24'sd0;
                valid_pipe[i] <= 1'b0;
                sum_pipe[i] <= 48'sd0;
            end
        end else begin
            a_pipe[0] <= a;
            b_pipe[0] <= b;
            valid_pipe[0] <= valid_in;
            sum_pipe[0] <= 48'sd0;
            for(i=1;i<=12;i=i+1) begin
                a_pipe[i] <= a_pipe[i-1];
                b_pipe[i] <= b_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
                sum_pipe[i] <= sum_pipe[i-1] + pp[i-1];
            end
        end
    end

    // ----------- booth_bits安全提取 -----------
    always @(*) begin
        for (j = 0; j < 12; j = j + 1) begin
            booth_bits[j][2] = (2*j+2 < 24) ? a_pipe[j][2*j+2] : 1'b0;
            booth_bits[j][1] = (2*j+1 < 24) ? a_pipe[j][2*j+1] : 1'b0;
            booth_bits[j][0] = (2*j   < 24) ? a_pipe[j][2*j  ] : 1'b0;
        end
    end

    // ----------- Booth-4部分积生成 -----------
    genvar k;
    generate
        for(k=0;k<12;k=k+1) begin: booth_stage
            reg signed [47:0] booth_pp;
            wire signed [25:0] b_ext;
            assign b_ext = {b_pipe[k][23], b_pipe[k], 1'b0, 1'b0};
            always @(*) begin
                case(booth_bits[k])
                    3'b000, 3'b111: booth_pp = 48'sd0;
                    3'b001, 3'b010: booth_pp = b_ext <<< (2*k);
                    3'b011:         booth_pp = (b_ext << 1) <<< (2*k);
                    3'b100:         booth_pp = -(b_ext << 1) <<< (2*k);
                    3'b101, 3'b110: booth_pp = -b_ext <<< (2*k);
                    default:        booth_pp = 48'sd0;
                endcase
            end
            always @(posedge clk) pp[k] <= booth_pp;
        end
    endgenerate

    // ----------- 输出部分：Q2.22饱和 -----------
    wire signed [47:0] mult_res = sum_pipe[12];
    wire signed [23:0] p_q22 = mult_res[45:22];
    // Q2.22最大最小
    localparam signed [23:0] Q22_MAX = 24'sh3FFFFF; // +3.999...
    localparam signed [23:0] Q22_MIN = -24'sd4194304; // -4.0, 0xC00000

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            p <= 24'sd0;
            valid_out <= 1'b0;
            debug_sum <= 48'sd0;
        end else begin
            valid_out <= valid_pipe[12];
            if(mult_res[47:46]==2'b01) begin
                p <= Q22_MAX;
            end else if(mult_res[47:46]==2'b10) begin
                p <= Q22_MIN;
            end else begin
                p <= p_q22;
            end
            debug_sum <= sum_pipe[12];
        end
    end
endmodule