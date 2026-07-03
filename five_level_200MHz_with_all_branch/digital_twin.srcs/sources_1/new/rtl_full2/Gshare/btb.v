module btb #(parameter ENTRIES=256) (
    input  clk,
    input  [31:0] pc,          // 当前指令地址  //此处pc来自ex模块
    input  [31:0] pc_from_ex  ,
    input  [31:0] target_addr, // 实际目标地址（更新用）
    input  update_en,         // 更新使能
    output [31:0] pred_addr,   // 预测目标地址
    output hit                 // BTB命中标志
);
    reg [31:0] target_ram [0:ENTRIES-1];
    reg [ENTRIES-1:0] valid;
    // 查询逻辑
    assign hit = valid[pc[7:0]];
    assign pred_addr = target_ram[pc[7:0]];
    // 更新逻辑
	integer i ;
	initial begin
	for(i = 0;i<256 ; i=i+1)begin
	    valid[i] = 1'b0 ;
	end
	end
    always @(posedge clk) begin
        if (update_en) begin
            target_ram[pc[7:0]] <= target_addr;
            valid[pc[7:0]] <= 1'b1;
        end
    end
endmodule