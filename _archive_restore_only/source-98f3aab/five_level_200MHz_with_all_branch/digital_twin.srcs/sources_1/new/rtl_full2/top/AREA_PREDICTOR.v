module    AREA_PREDICTOR   //局部预测器
#(
parameter              BTB_DEPTH         =   64  ,
parameter              BTB_VALID_DEPTH   =   64  ,
parameter              BTB_TAG_DEPTH     =   64  ,
parameter              BTB_WIDTH         =   32  ,
parameter              BTB_TAG_WIDTH     =   6   , //15 - log2)64)  =  7
parameter              PHT_DEPTH         =   64 ,
parameter              PHT_WIDTH         =   2   
)
(
input  wire            clk               ,
input  wire            rst               ,
input  wire            actual_jump_flag  ,
input  wire [31:0]     actual_jump_addr  ,
input  wire [31:0]     pc_from_if        ,   //用于推测下一个地址
input  wire [31:0]     pc_from_ex        ,   //用于更新BTB，PHT
input  wire            is_branch         ,

output wire            L_predict_taken     ,   //推测结果
output wire [31:0]     L_predict_target    
);
reg [BTB_WIDTH-1:0]  BTB[0:BTB_DEPTH-1] ;
reg [BTB_TAG_WIDTH-1 :0]  BTB_TAG[0:BTB_TAG_DEPTH-1] ;
reg [BTB_VALID_DEPTH-1 :0]  BTB_VALID   ;
reg [PHT_WIDTH-1:0] PHT[0:PHT_DEPTH-1]  ;
wire  [5:0]  expc  =  pc_from_ex[7:2]  ; 
wire  [5:0]  ifpc  =  pc_from_if[7:2]  ;
//初始化
integer i ;
//update 
always@(posedge clk or negedge rst)begin
if(~rst)begin
for(i = 0 ;i <BTB_DEPTH ; i = i +1)begin
BTB[i]        = 32'b0 ;
end
for(i = 0 ;i <BTB_TAG_DEPTH ; i = i +1)begin
BTB_TAG[i]    = 5'b0 ;
end
for(i = 0 ;i <BTB_VALID_DEPTH ; i = i +1)begin
BTB_VALID[i]  = 1'b0 ;
end
end
else if(actual_jump_flag)begin
BTB[expc] <= actual_jump_addr ;
BTB_TAG[expc] <= pc_from_ex[14:8] ;
BTB_VALID[expc] <= 1'b1 ;
end
end
always@(posedge clk or negedge rst)begin
if(~rst)begin
for(i = 0 ;i <PHT_DEPTH ; i = i +1)begin
PHT[i]  = 2'b1 ;     //起始状态为弱不跳转
end
end
else if(actual_jump_flag && (PHT[expc] < 2'b11) && is_branch)begin
PHT[expc] <= PHT[expc] + 1'b1 ;
end
else if(!actual_jump_flag && (PHT[expc] > 2'b0) && is_branch)begin
PHT[expc] <= PHT[expc] - 1'b1 ;
end
else begin
PHT[expc] <= PHT[expc] ;
end
end
//predict 
assign L_predict_taken = PHT[ifpc][1] & BTB_VALID[ifpc] &(BTB_TAG[ifpc]== pc_from_if[14:8]) ;
assign L_predict_target = BTB[ifpc]  ;

endmodule