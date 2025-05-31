module opti_sos (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [23:0] data_in,
    input  wire               data_valid_in,
    input  wire signed [23:0] b2,
    input  wire signed [23:0] b1,
    input  wire signed [23:0] b0,
    input  wire signed [23:0] a1,
    input  wire signed [23:0] a2,
    output reg                data_valid_out,
    output reg signed [23:0]  data_out
);

    // ====== 参数定义 ======
    integer i;
    // 假定乘法器流水线延迟
    // 如果你的乘法器延迟不同，请替换
    // 不用parameter，直接写常量
    // MULT_LATENCY = 13
    reg signed [23:0] x_pipe [0:12];
    reg               vld_pipe [0:12];

    // 状态寄存器
    reg signed [23:0] w1, w2;

    // ---- 反馈路径 ----
    // 反馈结果流水线
    reg signed [23:0] fbk_a1_pipe [0:12];
    reg signed [23:0] fbk_a2_pipe [0:12];
    reg               fbk_vld_pipe [0:12];

    // ---- 前馈/输出路径 ----
    // 前馈结果流水线
    reg signed [23:0] ff_b0_pipe [0:12];
    reg signed [23:0] ff_b1_pipe [0:12];
    reg signed [23:0] ff_b2_pipe [0:12];
    reg               ff_vld_pipe [0:12];

    // w0流水线
    reg signed [23:0] w0_pipe [0:12];

    // 累加输出流水线（27位）
    reg signed [26:0] acc_y_pipe [0:12];

    // ====== 数据/valid主流水线推进 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1) begin
                x_pipe[i]   <= 24'd0;
                vld_pipe[i] <= 1'b0;
            end
        end else begin
            x_pipe[0]   <= data_in;
            vld_pipe[0] <= data_valid_in;
            for (i=1; i<13; i=i+1) begin
                x_pipe[i]   <= x_pipe[i-1];
                vld_pipe[i] <= vld_pipe[i-1];
            end
        end
    end

    // ====== 状态推进：严格用data_valid_in推进历史 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w1 <= 24'd0;
            w2 <= 24'd0;
        end else if (data_valid_in) begin
            w2 <= w1;
            w1 <= w0_pipe[12]; // 注意：w0_pipe[12]是上一个周期的输出
        end
    end

    // ====== 反馈乘法链 ======
    // a1*w1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1)
                fbk_a1_pipe[i] <= 24'd0;
        end else begin
            fbk_a1_pipe[0] <= a1 * w1;
            for (i=1; i<13; i=i+1)
                fbk_a1_pipe[i] <= fbk_a1_pipe[i-1];
        end
    end
    // a2*w2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1)
                fbk_a2_pipe[i] <= 24'd0;
        end else begin
            fbk_a2_pipe[0] <= a2 * w2;
            for (i=1; i<13; i=i+1)
                fbk_a2_pipe[i] <= fbk_a2_pipe[i-1];
        end
    end
    // valid流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fbk_vld_pipe <= '{default:1'b0};
        else begin
            fbk_vld_pipe[0] <= data_valid_in;
            for (i=1; i<13; i=i+1)
                fbk_vld_pipe[i] <= fbk_vld_pipe[i-1];
        end
    end

    // ====== w0计算 ======
    // w0 = x[n] - a1*w1[n-1] - a2*w2[n-2]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1)
                w0_pipe[i] <= 24'd0;
        end else begin
            // 只有最后一级才用反馈结果
            w0_pipe[0] <= x_pipe[0] - fbk_a1_pipe[12] - fbk_a2_pipe[12];
            for (i=1; i<13; i=i+1)
                w0_pipe[i] <= w0_pipe[i-1];
        end
    end

    // ====== 前馈乘法链 ======
    // b0*w0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1)
                ff_b0_pipe[i] <= 24'd0;
        end else begin
            ff_b0_pipe[0] <= b0 * w0_pipe[12];
            for (i=1; i<13; i=i+1)
                ff_b0_pipe[i] <= ff_b0_pipe[i-1];
        end
    end
    // b1*w1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1)
                ff_b1_pipe[i] <= 24'd0;
        end else begin
            ff_b1_pipe[0] <= b1 * w1;
            for (i=1; i<13; i=i+1)
                ff_b1_pipe[i] <= ff_b1_pipe[i-1];
        end
    end
    // b2*w2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1)
                ff_b2_pipe[i] <= 24'd0;
        end else begin
            ff_b2_pipe[0] <= b2 * w2;
            for (i=1; i<13; i=i+1)
                ff_b2_pipe[i] <= ff_b2_pipe[i-1];
        end
    end
    // valid流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ff_vld_pipe <= '{default:1'b0};
        else begin
            ff_vld_pipe[0] <= data_valid_in;
            for (i=1; i<13; i=i+1)
                ff_vld_pipe[i] <= ff_vld_pipe[i-1];
        end
    end

    // ====== 输出累加和饱和 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<13; i=i+1)
                acc_y_pipe[i] <= 27'd0;
        end else begin
            acc_y_pipe[0] <= { {3{ff_b0_pipe[12][23]}}, ff_b0_pipe[12] }
                           + { {3{ff_b1_pipe[12][23]}}, ff_b1_pipe[12] }
                           + { {3{ff_b2_pipe[12][23]}}, ff_b2_pipe[12] };
            for (i=1; i<13; i=i+1)
                acc_y_pipe[i] <= acc_y_pipe[i-1];
        end
    end

    // ====== 输出寄存器 ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 24'd0;
            data_valid_out <= 1'b0;
        end else begin
            // 饱和
            if (acc_y_pipe[12] > 27'sd4194303)
                data_out <= 24'sd4194303;
            else if (acc_y_pipe[12] < -27'sd4194304)
                data_out <= -24'sd4194304;
            else
                data_out <= acc_y_pipe[12][23:0];
            data_valid_out <= ff_vld_pipe[12];
        end
    end

endmodule