// 已按照MATLAB排序和g分配硬编码
module opti_coeffs_fixed (
    input  wire [2:0]  stage_index,    // 0~5
    output wire [15:0] b0, b1, b2, a1, a2
);
    reg [15:0] b0_reg, b1_reg, b2_reg, a1_reg, a2_reg;
    always @(*) begin
        case (stage_index)
            // 节点0: 排序后第1节（原始节点6）
            3'd0: begin
                b0_reg = 16'h4000;
                b1_reg = 16'hB7A2;
                b2_reg = 16'h4000;
                a1_reg = 16'h4000;
                a2_reg = 16'hC250;
            end
            // 节点1: 排序后第2节（原始节点5）
            3'd1: begin
                b0_reg = 16'h4000;
                b1_reg = 16'h485E;
                b2_reg = 16'h4000;
                a1_reg = 16'h4000;
                a2_reg = 16'h3DB0;
            end
            // 节点2: 排序后第3节（原始节点4）
            3'd2: begin
                b0_reg = 16'h4000;
                b1_reg = 16'h5236;
                b2_reg = 16'h4000;
                a1_reg = 16'h4000;
                a2_reg = 16'h332E;
            end
            // 节点3: 排序后第4节（原始节点3）
            3'd3: begin
                b0_reg = 16'h4000;
                b1_reg = 16'hADCA;
                b2_reg = 16'h4000;
                a1_reg = 16'h4000;
                a2_reg = 16'hCCD2;
            end
            // 节点4: 排序后第5节（原始节点2）
            3'd4: begin
                b0_reg = 16'h4000;
                b1_reg = 16'h8D55;
                b2_reg = 16'h4000;
                a1_reg = 16'h4000;
                a2_reg = 16'hE9CB;
            end
            // 节点5: 排序后第6节（原始节点1，已乘以g）
            3'd5: begin
                b0_reg = 16'h00FD;
                b1_reg = 16'h01C6;
                b2_reg = 16'h00FD;
                a1_reg = 16'h00FD;
                a2_reg = 16'h0058;
            end
            default: begin
                b0_reg = 16'h4000; b1_reg = 16'h0000; b2_reg = 16'h4000; a1_reg = 16'h0000; a2_reg = 16'h0000;
            end
        endcase
    end
    assign b0 = b0_reg; assign b1 = b1_reg; assign b2 = b2_reg; assign a1 = a1_reg; assign a2 = a2_reg;
endmodule