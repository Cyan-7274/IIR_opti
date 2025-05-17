// Q2.14*Q2.14 全流水线Booth-4乘法器
module opti_multiplier (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a, // Q2.14
    input  wire [15:0] b, // Q2.14
    output wire [31:0] p, // Q4.28
    output wire        valid_out
);

    // 4-bit Booth编码，每4位a，对应一次部分积
    localparam STAGE = 8; // 16位=>8组Booth-4
    reg [15:0] a_pipe [0:STAGE];
    reg [15:0] b_pipe [0:STAGE];
    reg        valid_pipe [0:STAGE];

    reg signed [31:0] pp [0:STAGE-1];
    reg signed [31:0] sum_pipe [0:STAGE];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<=STAGE;i=i+1) begin
                a_pipe[i] <= 0;
                b_pipe[i] <= 0;
                valid_pipe[i] <= 0;
                sum_pipe[i] <= 0;
            end
        end else begin
            // 输入数据移入管线
            a_pipe[0] <= a;
            b_pipe[0] <= b;
            valid_pipe[0] <= valid_in;
            sum_pipe[0] <= 0;
            // 流水线移位
            for(i=1;i<=STAGE;i=i+1) begin
                a_pipe[i] <= a_pipe[i-1];
                b_pipe[i] <= b_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
                sum_pipe[i] <= sum_pipe[i-1] + pp[i-1];
            end
        end
    end

    // 生成部分积：Booth-4编码
    genvar k;
    generate
        for(k=0;k<STAGE;k=k+1) begin: booth_stage
            wire [2:0] booth_bits = {a_pipe[k][2*k+2], a_pipe[k][2*k+1], a_pipe[k][2*k]};
            wire signed [17:0] b_ext = {b_pipe[k][15], b_pipe[k], 1'b0}; // sign-extend+1位0
            reg signed [31:0] booth_pp;
            always @(*) begin
                case(booth_bits)
                    3'b000, 3'b111: booth_pp = 0;
                    3'b001, 3'b010: booth_pp = b_ext <<< (2*k);
                    3'b011:         booth_pp = (b_ext << 1) <<< (2*k);
                    3'b100:         booth_pp = -(b_ext << 1) <<< (2*k);
                    3'b101, 3'b110: booth_pp = -b_ext <<< (2*k);
                    default:        booth_pp = 0;
                endcase
            end
            always @(posedge clk) pp[k] <= booth_pp;
        end
    endgenerate

    assign p = sum_pipe[STAGE];
    assign valid_out = valid_pipe[STAGE];

endmodule