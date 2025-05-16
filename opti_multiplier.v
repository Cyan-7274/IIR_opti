module booth_multiplier_pipe(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [15:0] a,   // Q2.14
    input  wire [15:0] b,   // Q2.14
    output reg  [31:0] p,
    output reg         valid
);
    reg busy;
    reg [4:0] count;
    reg [33:0] acc;         // accumulator, 2 guard bits
    reg [33:0] acc_next;
    reg [17:0] b_ext;       // 16位b扩展2位
    reg [17:0] b_ext_neg;
    reg [34:0] a_buf;       // Booth编码用（a移位并补零）
    reg [2:0] booth_code;
    reg [33:0] booth_term;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc   <= 0;
            count <= 0;
            busy  <= 0;
            valid <= 0;
            p     <= 0;
            a_buf <= 0;
        end else begin
            if (start && !busy) begin
                acc   <= 0;
                count <= 0;
                busy  <= 1;
                valid <= 0;
                // a_buf拼接两位0，便于Booth-4编码
                a_buf <= {a, 2'b00};
            end else if (busy) begin
                // 取当前编码3位
                booth_code = a_buf[2:0];
                // 生成booth_term
                case (booth_code)
                    3'b000, 3'b111: booth_term = 0;
                    3'b001, 3'b010: booth_term =  b_ext;
                    3'b101, 3'b110: booth_term = -b_ext;
                    3'b011:         booth_term =  b_ext << 1;
                    3'b100:         booth_term = -b_ext << 1;
                    default:        booth_term = 0;
                endcase
                // 积分累加
                acc <= $signed(acc) + ($signed(booth_term) <<< (2*count));
                // a_buf算术右移2位
                a_buf <= {a_buf[34], a_buf[34:2]};
                count <= count + 1;
                if (count == 7) begin
                    p     <= acc[31:0];
                    valid <= 1;
                    busy  <= 0;
                end
            end else begin
                valid <= 0;
            end
        end
    end

    // b_ext/b_ext_neg在每次start时准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_ext     <= 0;
        end else if (start && !busy) begin
            b_ext     <= {b[15], b, 1'b0}; // 有符号扩展
        end
    end

endmodule