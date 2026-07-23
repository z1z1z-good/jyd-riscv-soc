module arbitration (
    input  btb_hit,            // BTB是否命中
    input  prediction,         // PHT预测结果
    input  [31:0] btb_addr,    // BTB预测地址
    input  [31:0] pc,   // 默认下一条地址
    output [31:0] next_pc      // 最终预测地址
);
    assign next_pc = (btb_hit && prediction) ? btb_addr : pc;
endmodule