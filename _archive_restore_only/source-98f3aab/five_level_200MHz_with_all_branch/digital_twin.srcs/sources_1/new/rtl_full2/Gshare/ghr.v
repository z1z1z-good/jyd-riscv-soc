module ghr #(parameter N=8) ( //一个移位寄存器的实现方法
    input  clk, reset,
    input  branch_taken,    // 当前分支实际结果
    output [N-1:0] ghr_out  // 全局历史向量
);
    reg [N-1:0] ghr = 0;
    always @(posedge clk or negedge reset) begin
        if (~reset) ghr <= 0;
        else       ghr <= {ghr[N-2:0], branch_taken};
    end
    assign ghr_out = ghr;
endmodule