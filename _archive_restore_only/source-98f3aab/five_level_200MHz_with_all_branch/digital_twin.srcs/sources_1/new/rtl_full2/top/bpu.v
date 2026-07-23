module bpu(
    input  wire             clk                 ,
    input  wire             rst                 ,
    input  wire             actual_jump_flag    ,
    input  wire [31:0]      actual_jump_addr    ,
    input  wire [31:0]      pc_from_if          ,   //用于推测下一个地址
    input  wire [31:0]      pc_from_ex          ,   //用于更新BTB，PHT
    input  wire             is_branch           ,
    output wire             predict_taken      ,  
    output wire [31:0]      predict_target      
);

wire            G_predict_taken ;
wire            L_predict_taken ;
reg            G_taken ;
reg            L_taken ;
wire            G_taken_1 ;
wire            L_taken_1 ;
reg            G_taken_2 ;
reg            L_taken_2 ;
wire            G_taken_reg ;
wire            L_taken_reg ;
wire    [5:0]   ifpcindex_o     ;
wire    [5:0]   expcindex_o     ;
wire            CPT_predict     ;
wire    [31:0]  G_predict_target     ;
wire    [31:0]  L_predict_target     ;


always@(posedge clk or negedge rst) begin
    if (~rst) begin
        G_taken <= 'd0;
        L_taken    <= 'd0;
    end
    else begin
        G_taken <= G_predict_taken;
        L_taken    <= L_predict_taken;
    end
end

assign G_taken_1 = G_taken;
assign L_taken_1    = L_taken;

always@(posedge clk or negedge rst) begin
    if (~rst) begin
        G_taken_2 <= 'd0;
        L_taken_2    <= 'd0;
    end
    else begin
        G_taken_2 <= G_taken_1;
        L_taken_2    <= L_taken_1;
    end
end

assign G_taken_reg = G_taken_2;
assign L_taken_reg    = L_taken_2;



CPT u_CPT(
.clk                   (clk),
.rst                   (rst),
.actual_jump_flag      (actual_jump_flag),
.GLOBAL                (G_taken_reg),
.AREA                  (L_taken_reg),
.GPT_index             (ifpcindex_o),
.GPT_index_update      (expcindex_o),
.is_branch             (is_branch),
.pc_from_ex            (pc_from_ex),

.CPT_predict           (CPT_predict)
);

GLOBAL_PREDICTOR u_GLOBAL_PREDICTOR(  //局部预测器
.clk                  (clk),
.rst                  (rst),
.actual_jump_flag     (actual_jump_flag),
.actual_jump_addr     (actual_jump_addr),
.pc_from_if           (pc_from_if),   //用于推测下一个地址
.pc_from_ex           (pc_from_ex),   //用于更新BTB，PHT
.is_branch            (is_branch),

.expcindex_o          (expcindex_o),   //推测结果
.ifpcindex_o          (ifpcindex_o),   //推测结果
.G_predict_taken      (G_predict_taken),   //推测结果
.G_predict_target     (G_predict_target)
);

AREA_PREDICTOR u_AREA_PREDICTOR(  //局部预测器
.clk                  (clk),
.rst                  (rst),
.actual_jump_flag     (actual_jump_flag),
.actual_jump_addr     (actual_jump_addr),
.pc_from_if           (pc_from_if),   //用于推测下一个地址
.pc_from_ex           (pc_from_ex),   //用于更新BTB，PHT
.is_branch            (is_branch),

.L_predict_taken      (L_predict_taken),   //推测结果
.L_predict_target     (L_predict_target)
);

assign predict_target = CPT_predict ?G_predict_target:L_predict_target;
assign predict_taken = CPT_predict ?G_predict_taken:L_predict_taken;




endmodule