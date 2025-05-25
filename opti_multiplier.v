// Q2.22*Q2.22 Booth-4全流水线乘法器（Verilog-2001标准，无块内声明，每拍一结果）
module opti_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire signed [23:0] a, // Q2.22
    input  wire signed [23:0] b, // Q2.22
    output reg  signed [23:0] p, // Q2.22
    output reg          valid_out
);

    localparam STAGE_NUM = 12;
    reg signed [23:0] a_pipe [0:STAGE_NUM];
    reg signed [23:0] b_pipe [0:STAGE_NUM];
    reg signed [47:0] acc_pipe [0:STAGE_NUM];
    reg               valid_pipe [0:STAGE_NUM];

    // 临时变量全部声明在模块头部
    reg [2:0] booth_code;
    reg signed [25:0] b_ext;
    reg signed [47:0] booth_pp;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<=STAGE_NUM;i=i+1) begin
                a_pipe[i] <= 24'sd0;
                b_pipe[i] <= 24'sd0;
                acc_pipe[i] <= 48'sd0;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            a_pipe[0] <= a;
            b_pipe[0] <= b;
            acc_pipe[0] <= 48'sd0;
            valid_pipe[0] <= valid_in;
                    
            for(i=0;i<STAGE_NUM;i=i+1) begin
                // Booth-4编码
                if(2*i+2 < 24)
                    booth_code[2] = a_pipe[i][2*i+2];
                else
                    booth_code[2] = a_pipe[i][23];
                if(2*i+1 < 24)
                    booth_code[1] = a_pipe[i][2*i+1];
                else
                    booth_code[1] = a_pipe[i][23];
                if(2*i < 24)
                    booth_code[0] = a_pipe[i][2*i];
                else
                    booth_code[0] = a_pipe[i][23];

                b_ext = {b_pipe[i][23], b_pipe[i], 2'b00};

                if(booth_code == 3'b000 || booth_code == 3'b111)
                    booth_pp = 48'd0;
                else if(booth_code == 3'b001 || booth_code == 3'b010)
                    booth_pp = $signed(b_ext) <<< (2*i);
                else if(booth_code == 3'b011)
                    booth_pp = $signed(b_ext << 1) <<< (2*i);
                else if(booth_code == 3'b100)
                    booth_pp = -($signed(b_ext << 1) <<< (2*i));
                else if(booth_code == 3'b101 || booth_code == 3'b110)
                    booth_pp = -($signed(b_ext) <<< (2*i));
                else
                    booth_pp = 48'd0;

                a_pipe[i+1] <= a_pipe[i];
                b_pipe[i+1] <= b_pipe[i];
                acc_pipe[i+1] <= acc_pipe[i] + booth_pp;
                valid_pipe[i+1] <= valid_pipe[i];
            end

        end
    end

    wire signed [23:0] p_q22;
    assign p_q22 = acc_pipe[STAGE_NUM][45:22];
    localparam signed [23:0] Q22_MAX = 24'sh3FFFFF;
    localparam signed [23:0] Q22_MIN = -24'sd4194304;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            p <= 24'd0;
            valid_out <= 1'b0;
        end else begin
            if (acc_pipe[STAGE_NUM][47:46] == 2'b01)
                p <= Q22_MAX;
            else if (acc_pipe[STAGE_NUM][47:46] == 2'b10)
                p <= Q22_MIN;
            else
                p <= p_q22;
            valid_out <= valid_pipe[STAGE_NUM];
        end
    end
endmodule