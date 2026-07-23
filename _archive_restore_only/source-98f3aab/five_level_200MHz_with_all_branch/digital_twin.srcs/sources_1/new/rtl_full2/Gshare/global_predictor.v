module global_predictor 
#(parameter N=8 ,
  parameter BTB_DEPTH = 256
//2^8 = 256

) (
    input  clk, reset,
    input  [31:0] pc,            // 当前指令地址
    input  [31:0] pc_from_ex ,
    input  actual_taken,         // 实际分支结果
    input  [31:0] actual_target, // 实际目标地址
    output pred_taken,          // 预测是否跳转
    output [31:0] pred_target   // 预测目标地址
);
    // 模块实例化
    wire [N-1:0] ghr_value;
    ghr  #(N) u_ghr (clk, reset, actual_taken, ghr_value);
    pht  #(N) u_pht (clk, reset, ghr_value, actual_taken, pred_taken);
    btb  #(BTB_DEPTH)   u_btb (clk, pc, pc_from_ex ,actual_target, actual_taken, pred_target, btb_hit);
    arbitration u_arb (btb_hit, pred_taken, pred_target, pc, next_pc);

endmodule