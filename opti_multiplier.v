module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [23:0] a, // Q2.22
    input  wire signed [23:0] b, // Q2.22
    input  wire         valid_in,
    output reg  signed [23:0] p, // Q2.22
    output reg          valid_out
);

    localparam STAGE_NUM = 13; // 需要13级处理25位(24+1个guard bit)

    // pipeline寄存器
    reg signed [24:0] a_ext_pipe [0:STAGE_NUM];  // 扩展1位作为guard
    reg signed [23:0] b_pipe [0:STAGE_NUM];
    reg signed [47:0] acc_pipe [0:STAGE_NUM];
    reg               valid_pipe [0:STAGE_NUM];

    // 临时变量
    reg [2:0] booth_code;
    reg signed [23:0] b_shifted;
    reg signed [47:0] booth_pp;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<=STAGE_NUM;i=i+1) begin
                a_ext_pipe[i] <= 25'sd0;
                b_pipe[i]     <= 24'sd0;
                acc_pipe[i]   <= 48'sd0;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            // 第一级：输入采样，a扩展1位作为guard bit
            a_ext_pipe[0] <= {a[23], a}; // 25位，符号扩展
            b_pipe[0] <= b;
            acc_pipe[0] <= 48'sd0;
            valid_pipe[0] <= valid_in;
            
            // Booth-4流水线处理
            for(i=0;i<STAGE_NUM;i=i+1) begin
                // Booth-4编码：需要3位，包括前一组的最低位
                if(i == 0) begin
                    // 第一组：最低位补0
                    booth_code[2] = a_ext_pipe[i][2];
                    booth_code[1] = a_ext_pipe[i][1];
                    booth_code[0] = a_ext_pipe[i][0];
                end else begin
                    // 其他组：正常取3位
                    booth_code[2] = (2*i+1 < 25) ? a_ext_pipe[i][2*i+1] : a_ext_pipe[i][24];
                    booth_code[1] = (2*i   < 25) ? a_ext_pipe[i][2*i]   : a_ext_pipe[i][24];
                    booth_code[0] = (2*i-1 >= 0) ? a_ext_pipe[i][2*i-1] : 1'b0;
                end
                
                // 根据Booth编码生成部分积
                case(booth_code)
                    3'b000, 3'b111: booth_pp = 48'sd0;                    // +0
                    3'b001, 3'b010: booth_pp = $signed(b_pipe[i]);       // +1*b
                    3'b011:         booth_pp = $signed(b_pipe[i]) <<< 1;  // +2*b
                    3'b100:         booth_pp = -($signed(b_pipe[i]) <<< 1); // -2*b
                    3'b101, 3'b110: booth_pp = -$signed(b_pipe[i]);      // -1*b
                    default:        booth_pp = 48'sd0;
                endcase
                
                // 移位到正确位置（每组处理2位，所以移位2*i）
                if(i > 0) begin
                    booth_pp = booth_pp <<< (2*i);
                end
                
                // 流水线推进
                a_ext_pipe[i+1] <= a_ext_pipe[i];
                b_pipe[i+1] <= b_pipe[i];
                acc_pipe[i+1] <= acc_pipe[i] + booth_pp;
                valid_pipe[i+1] <= valid_pipe[i];
            end
        end
    end

    // 输出处理
    wire signed [47:0] acc_final;
    assign acc_final = acc_pipe[STAGE_NUM];

    // Q2.22 × Q2.22 = Q4.44，取[45:22]回到Q2.22
    wire signed [23:0] prod_truncated;
    assign prod_truncated = acc_final[45:22];

    // 溢出检测：检查高位是否一致
    wire overflow_pos, overflow_neg;
    assign overflow_pos = (acc_final[47:46] == 2'b01); // 正溢出
    assign overflow_neg = (acc_final[47:46] == 2'b10); // 负溢出

    // 饱和处理
    localparam signed [23:0] Q22_MAX = 24'h3FFFFF;   // 最大正值
    localparam signed [23:0] Q22_MIN = 24'h400000;   // 最大负值(补码)
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            p <= 24'd0;
            valid_out <= 1'b0;
        end else begin
            if (overflow_pos)
                p <= Q22_MAX;
            else if (overflow_neg)
                p <= Q22_MIN;
            else
                p <= prod_truncated;
            valid_out <= valid_pipe[STAGE_NUM];
        end
    end

endmodule