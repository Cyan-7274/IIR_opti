module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [23:0] a, // Q2.22
    input  wire signed [23:0] b, // Q2.22
    input  wire         valid_in,
    output reg  signed [23:0] p, // Q2.22
    output reg          valid_out
);

    localparam STAGE_NUM = 13; // 需要13级处理25位

    // pipeline寄存器 - 保持原始信号名
    reg signed [24:0] a_ext_pipe [0:STAGE_NUM];
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
            // 第一级：输入采样
            a_ext_pipe[0] <= {a[23], a}; // 25位，符号扩展
            b_pipe[0] <= b;
            acc_pipe[0] <= 48'sd0;
            valid_pipe[0] <= valid_in;
            
            // 流水线推进（先推进，再计算当前级）
            for(i=1;i<=STAGE_NUM;i=i+1) begin
                a_ext_pipe[i] <= a_ext_pipe[i-1];
                b_pipe[i] <= b_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
            
            // 分别计算每一级的Booth部分积
            for(i=0;i<STAGE_NUM;i=i+1) begin
                // Booth-4编码
                case(i)
                    0: booth_code = {a_ext_pipe[0][1:0], 1'b0}; // 第一组，补0
                    1: booth_code = a_ext_pipe[1][3:1];
                    2: booth_code = a_ext_pipe[2][5:3];
                    3: booth_code = a_ext_pipe[3][7:5];
                    4: booth_code = a_ext_pipe[4][9:7];
                    5: booth_code = a_ext_pipe[5][11:9];
                    6: booth_code = a_ext_pipe[6][13:11];
                    7: booth_code = a_ext_pipe[7][15:13];
                    8: booth_code = a_ext_pipe[8][17:15];
                    9: booth_code = a_ext_pipe[9][19:17];
                    10: booth_code = a_ext_pipe[10][21:19];
                    11: booth_code = a_ext_pipe[11][23:21];
                    12: booth_code = {a_ext_pipe[12][24], a_ext_pipe[12][24], a_ext_pipe[12][23]}; // 最后一组
                    default: booth_code = 3'b000;
                endcase
                
                // 根据Booth编码生成部分积
                case(booth_code)
                    3'b000, 3'b111: booth_pp = 48'sd0;                    // +0
                    3'b001, 3'b010: booth_pp = {{24{b_pipe[i][23]}}, b_pipe[i]};       // +1*b
                    3'b011:         booth_pp = {{23{b_pipe[i][23]}}, b_pipe[i], 1'b0};  // +2*b
                    3'b100:         booth_pp = -{{23{b_pipe[i][23]}}, b_pipe[i], 1'b0}; // -2*b
                    3'b101, 3'b110: booth_pp = -{{24{b_pipe[i][23]}}, b_pipe[i]};      // -1*b
                    default:        booth_pp = 48'sd0;
                endcase
                
                // 移位到正确位置
                booth_pp = booth_pp <<< (2*i);
                
                // 累加到对应级
                if(i == 0) begin
                    acc_pipe[1] <= acc_pipe[0] + booth_pp;
                end else begin
                    acc_pipe[i+1] <= acc_pipe[i] + booth_pp;
                end
            end
        end
    end

    // 输出处理 - 保持原始逻辑
    wire signed [47:0] acc_final;
    assign acc_final = acc_pipe[STAGE_NUM];

    // Q2.22 × Q2.22 = Q4.44，取[45:22]回到Q2.22，添加舍入
    wire signed [23:0] prod_truncated;
    wire round_bit = acc_final[21];
    assign prod_truncated = acc_final[45:22] + round_bit;

    // 溢出检测
    wire overflow_pos, overflow_neg;
    assign overflow_pos = (acc_final[47:46] == 2'b01); 
    assign overflow_neg = (acc_final[47:46] == 2'b10); 

    // 饱和处理
    localparam signed [23:0] Q22_MAX = 24'h3FFFFF;   
    localparam signed [23:0] Q22_MIN = 24'h400000;   
    
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