module pht #(parameter N=8) (
    input  clk, reset,
    input  [N-1:0] ghr,
    input  actual_taken,    // 实际分支结果
    output prediction       // 预测结果（高�?=1则跳转）
);
    reg [1:0] pht [0:(1<<N)-1];  // 2^N�?2-bit计数�?
    integer i;                    // Verilog-2001兼容的循环变�?

    always @(posedge clk) begin
        if (~reset) begin  // 复位有效时初始化
            for (i=0; i<(1<<N); i=i+1) pht[i] <= 2'b01;  // 初始弱不跳转
        end else begin
            // 更新计数器：饱和加减
            if (actual_taken && pht[ghr] < 2'b11) pht[ghr] <= pht[ghr] + 1;
            else if (!actual_taken && pht[ghr] > 2'b00) pht[ghr] <= pht[ghr] - 1;
        end
    end

    assign prediction = pht[ghr][1];  // 高位为预测位
endmodule