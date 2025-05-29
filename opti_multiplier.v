// Booth-4编码，12级流水线乘法器，Verilog-2001纯语法，常量指定级数
module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire signed [23:0] a, // Q2.22
    input  wire signed [23:0] b, // Q2.22
    output reg  signed [23:0] p, // Q2.22
    output reg          valid_out
);

    // Booth-4流水线级数
    // 不用parameter，直接常量
    // 12级流水线，每级2bit
    localparam STAGE_NUM = 12; // 24bit/2=12
    // pipeline寄存器
    reg signed [23:0] a_pipe [0:STAGE_NUM];
    reg signed [23:0] b_pipe [0:STAGE_NUM];
    reg signed [47:0] acc_pipe [0:STAGE_NUM];
    reg               valid_pipe [0:STAGE_NUM];

    // 临时变量
    reg [2:0] booth_code;
    reg signed [25:0] b_ext;
    reg signed [47:0] booth_pp;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<=STAGE_NUM;i=i+1) begin
                a_pipe[i]    <= 24'sd0;
                b_pipe[i]    <= 24'sd0;
                acc_pipe[i]  <= 48'sd0;
                valid_pipe[i]<= 1'b0;
            end
        end else begin
            // 第一级采样
            a_pipe[0] <= a;
            b_pipe[0] <= b;
            acc_pipe[0] <= 48'sd0;
            valid_pipe[0] <= valid_in;
            // Booth-4流水线推进
            for(i=0;i<STAGE_NUM;i=i+1) begin
                // 编码高位越界保护
                booth_code[2] = (2*i+2<24) ? a_pipe[i][2*i+2] : a_pipe[i][23];
                booth_code[1] = (2*i+1<24) ? a_pipe[i][2*i+1] : a_pipe[i][23];
                booth_code[0] = (2*i  <24) ? a_pipe[i][2*i  ] : a_pipe[i][23];
                // b符号扩展2bit，移位对齐
                b_ext = {b_pipe[i][23], b_pipe[i], 2'b00};
                // Booth部分积
                case(booth_code)
                    3'b000, 3'b111: booth_pp = 48'sd0;
                    3'b001, 3'b010: booth_pp = $signed(b_ext) <<< (2*i);
                    3'b011:         booth_pp = $signed(b_ext <<< 1) <<< (2*i);
                    3'b100:         booth_pp = -($signed(b_ext <<< 1) <<< (2*i));
                    3'b101,3'b110:  booth_pp = -($signed(b_ext) <<< (2*i));
                    default:        booth_pp = 48'sd0;
                endcase
                // pipeline推进
                a_pipe[i+1] <= a_pipe[i];
                b_pipe[i+1] <= b_pipe[i];
                acc_pipe[i+1] <= acc_pipe[i] + booth_pp;
                valid_pipe[i+1] <= valid_pipe[i];
            end
        end
    end

    // 输出部分
    wire signed [47:0] acc_final;
    assign acc_final = acc_pipe[STAGE_NUM];
    wire signed [25:0] prod_q22;
    assign prod_q22 = acc_final >>> 23; // Q2.22

    // 饱和处理
    localparam signed [23:0] Q22_MAX = 24'sh3FFFFF;
    localparam signed [23:0] Q22_MIN = -24'sd4194304;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            p <= 24'd0;
            valid_out <= 1'b0;
        end else begin
            if (prod_q22 > Q22_MAX)
                p <= Q22_MAX;
            else if (prod_q22 < Q22_MIN)
                p <= Q22_MIN;
            else
                p <= prod_q22[23:0];
            valid_out <= valid_pipe[STAGE_NUM];
        end
    end

endmodule