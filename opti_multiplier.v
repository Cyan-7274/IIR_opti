module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [23:0] a, // Q2.22
    input  wire signed [23:0] b, // Q2.22
    input  wire         valid_in,
    output reg  signed [23:0] p, // Q2.22
    output reg          valid_out
);

    // === 参数 ===
    localparam N = 13;            // 24位输入，Booth-4每2位一组，ceil(24/2)=12组，补1组，共13组
    localparam A_WIDTH = 24;      // 输入a位宽
    localparam B_WIDTH = 24;      // 输入b位宽
    localparam EXT_WIDTH = 27;    // 被乘数扩展到2*N+1=27位
    localparam PP_WIDTH = 48;     // 部分积宽度，足够累加不溢出

    // === 管脚/寄存器声明 ===
    reg  signed [EXT_WIDTH-1:0] a_pipe [0:N];
    reg  signed [B_WIDTH-1:0]   b_pipe [0:N];
    reg  signed [PP_WIDTH-1:0]  pp_pipe [0:N];
    reg  signed [PP_WIDTH-1:0]  acc_pipe [0:N];
    reg                         valid_pipe [0:N];

    reg  [2:0]                  booth_code [0:N-1];
    reg  signed [PP_WIDTH-1:0]  booth_pp   [0:N-1];

    integer i;

    // === 0级采样 ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_pipe[0]   <= 0;
            b_pipe[0]   <= 0;
            pp_pipe[0]  <= 0;
            acc_pipe[0] <= 0;
            valid_pipe[0] <= 1'b0;
        end else begin
            a_pipe[0]   <= { {3{a[23]}}, a }; // [26:3]=符号扩展, [2:0]=a
            b_pipe[0]   <= b;
            pp_pipe[0]  <= 0;
            acc_pipe[0] <= 0;
            valid_pipe[0] <= valid_in;
        end
    end

    // === Booth-4流水线推进 ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                a_pipe[i+1]   <= 0;
                b_pipe[i+1]   <= 0;
                pp_pipe[i+1]  <= 0;
                acc_pipe[i+1] <= 0;
                valid_pipe[i+1] <= 1'b0;
                booth_code[i] <= 0;
                booth_pp[i]   <= 0;
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                // Booth窗口编码
                booth_code[i] = { a_pipe[i][2*i+1], a_pipe[i][2*i], (2*i-1 >= 0) ? a_pipe[i][2*i-1] : 1'b0 };
                // Booth查表
                case (booth_code[i])
                    3'b000, 3'b111: booth_pp[i] = {PP_WIDTH{1'b0}};
                    3'b001, 3'b010: booth_pp[i] = {{(PP_WIDTH-B_WIDTH){b_pipe[i][B_WIDTH-1]}}, b_pipe[i]};
                    3'b011:         booth_pp[i] = {{(PP_WIDTH-B_WIDTH-1){b_pipe[i][B_WIDTH-1]}}, b_pipe[i], 1'b0}; // +2b
                    3'b100:         booth_pp[i] = -{{(PP_WIDTH-B_WIDTH-1){b_pipe[i][B_WIDTH-1]}}, b_pipe[i], 1'b0}; // -2b
                    3'b101, 3'b110: booth_pp[i] = -{{(PP_WIDTH-B_WIDTH){b_pipe[i][B_WIDTH-1]}}, b_pipe[i]};
                    default:        booth_pp[i] = {PP_WIDTH{1'b0}};
                endcase
                // 左移
                booth_pp[i] = booth_pp[i] <<< (2*i);

                // 流水线推进
                a_pipe[i+1]   <= a_pipe[i];
                b_pipe[i+1]   <= b_pipe[i];
                pp_pipe[i+1]  <= booth_pp[i];
                acc_pipe[i+1] <= acc_pipe[i] + booth_pp[i];
                valid_pipe[i+1] <= valid_pipe[i];
            end
        end
    end

    // === 输出 ===
    wire signed [PP_WIDTH-1:0] acc_final = acc_pipe[N];

    // Q4.44到Q2.22，取[45:22]，加舍入
    wire signed [23:0] prod_trunc;
    wire round_bit = acc_final[21];
    assign prod_trunc = acc_final[45:22] + round_bit;

    // 饱和
    localparam signed [23:0] Q22_MAX = 24'sh3FFFFF;
    localparam signed [23:0] Q22_MIN = -24'sh400000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 0;
            valid_out <= 1'b0;
        end else begin
            // 饱和判断：acc_final[47:46] == 01/10
            if (acc_final[47:46] == 2'b01)
                p <= Q22_MAX;
            else if (acc_final[47:46] == 2'b10)
                p <= Q22_MIN;
            else
                p <= prod_trunc;
                valid_out <= valid_pipe[N];
        end
    end

endmodule