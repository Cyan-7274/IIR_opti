module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [23:0] a, // Q2.22
    input  wire signed [23:0] b, // Q2.22
    input  wire         valid_in,
    output reg  signed [23:0] p, // Q2.22
    output reg          valid_out
);

    localparam N = 13;

    // Booth-4流水线寄存器
    reg  signed [24:0] a_pipe [0:N]; // a扩展位
    reg  signed [23:0] b_pipe [0:N];
    reg  signed [47:0] pp_pipe [0:N]; // 部分积
    reg  signed [47:0] acc_pipe [0:N]; // 累加
    reg                valid_pipe [0:N];

    integer i;

    // 0级输入采样
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            a_pipe[0]   <= 0;
            b_pipe[0]   <= 0;
            pp_pipe[0]  <= 0;
            acc_pipe[0] <= 0;
            valid_pipe[0] <= 0;
        end else begin
            a_pipe[0]   <= {a[23], a}; // 25位符号扩展
            b_pipe[0]   <= b;
            pp_pipe[0]  <= 0;
            acc_pipe[0] <= 0;
            valid_pipe[0] <= valid_in;
        end
    end

    // Booth-4流水线主推进
    genvar k;
    generate
        for(k=1; k<=N; k=k+1) begin: BOOTH_STAGE
            reg [2:0] booth_code;
            reg signed [47:0] booth_pp;
            always @(*) begin
                // 生成Booth-4编码
                if(k==1)
                    booth_code = {a_pipe[k-1][1:0], 1'b0}; // 第一组特殊
                else if(k==N)
                    booth_code = {a_pipe[k-1][24], a_pipe[k-1][24], a_pipe[k-1][23]};
                else
                    booth_code = a_pipe[k-1][2*k+1 -: 3];

                // 生成Booth-4部分积
                case(booth_code)
                    3'b000, 3'b111: booth_pp = 48'sd0;
                    3'b001, 3'b010: booth_pp = {{24{b_pipe[k-1][23]}}, b_pipe[k-1]};
                    3'b011:         booth_pp = {{23{b_pipe[k-1][23]}}, b_pipe[k-1], 1'b0}; // 2x
                    3'b100:         booth_pp = -{{23{b_pipe[k-1][23]}}, b_pipe[k-1], 1'b0};
                    3'b101, 3'b110: booth_pp = -{{24{b_pipe[k-1][23]}}, b_pipe[k-1]};
                    default:        booth_pp = 48'sd0;
                endcase

                // 左移
                booth_pp = booth_pp <<< (2*(k-1));
            end

            // 级联流水线
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    a_pipe[k]   <= 0;
                    b_pipe[k]   <= 0;
                    pp_pipe[k]  <= 0;
                    acc_pipe[k] <= 0;
                    valid_pipe[k] <= 0;
                end else begin
                    a_pipe[k]   <= a_pipe[k-1];
                    b_pipe[k]   <= b_pipe[k-1];
                    pp_pipe[k]  <= booth_pp;
                    acc_pipe[k] <= acc_pipe[k-1] + booth_pp;
                    valid_pipe[k] <= valid_pipe[k-1];
                end
            end
        end
    endgenerate

    // 输出
    wire signed [47:0] acc_final = acc_pipe[N];

    // Q4.44到Q2.22，取[45:22]，加舍入
    wire signed [23:0] prod_trunc;
    wire round_bit = acc_final[21];
    assign prod_trunc = acc_final[45:22] + round_bit;

    // 饱和
    localparam signed [23:0] Q22_MAX = 24'h3FFFFF;
    localparam signed [23:0] Q22_MIN = 24'hC00000;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            p <= 0;
            valid_out <= 0;
        end else begin
            if(acc_final[47:46]==2'b01)
                p <= Q22_MAX;
            else if(acc_final[47:46]==2'b10)
                p <= Q22_MIN;
            else
                p <= prod_trunc;
            valid_out <= valid_pipe[N];
        end
    end

endmodule