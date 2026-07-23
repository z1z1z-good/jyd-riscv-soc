module    GLOBAL_PREDICTOR   //�?部预测器
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

input  wire [31:0]     pc_from_if        ,   //用于推测下一个地�?
input  wire [31:0]     pc_from_ex        ,   //用于更新BTB，PHT

input  wire            is_branch         ,

output wire            predict_taken     ,   //推测结果
output wire [31:0]     predict_target    
);
reg [BTB_WIDTH-1:0]         BTB         [0:BTB_DEPTH-1] ;
reg [BTB_TAG_WIDTH-1 :0]    BTB_TAG     [0:BTB_TAG_DEPTH-1] ;
reg [BTB_VALID_DEPTH-1 :0]  BTB_VALID   ;
reg [PHT_WIDTH-1:0]         PHT         [0:PHT_DEPTH-1]  ;
wire  [5:0]  expc  =  pc_from_ex[7:2]  ; 
wire  [5:0]  ifpc  =  pc_from_if[7:2]  ;

reg  [9:0] GBHR, GBHR_reg1, GBHR_reg2; // 1D array
wire [9:0] GBHR_old;

wire  [5:0]  expcindex  =  pc_from_ex[7:2] ^ GBHR_old ; 
wire  [5:0]  ifpcindex  =  pc_from_if[7:2] ^ GBHR ;

//初始�?
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
            BTB[expc]       <= actual_jump_addr ;
            BTB_TAG[expc]   <= pc_from_ex[14:8] ;
            BTB_VALID[expc] <= 1'b1 ;
        end
    end
    
//全局分支历史寄存�?
    always @(posedge clk or negedge rst)begin
		if(~rst)
			GBHR <= 9'b0;	
		else if((pc_from_ex[1:0] == 2'b00) && (actual_jump_flag))
			GBHR <= {GBHR_old[8:0], is_branch};
		else 
			GBHR <= GBHR;
    end
    
//分支历史表打两拍（不知道为啥
    always @(posedge clk) begin
	   GBHR_reg1 <= GBHR; 
    end
    always @(posedge clk) begin
	   GBHR_reg2 <= GBHR_reg1; 
    end
    assign  GBHR_old = GBHR_reg2;

always@(posedge clk or negedge rst)begin
    if(~rst)begin
        for(i = 0 ;i <PHT_DEPTH ; i = i +1)begin
            PHT[i]  = 2'b1 ;     //起始状�?�为弱不跳转
        end
    end
    else if(actual_jump_flag && (PHT[expcindex] < 2'b11) && is_branch)begin
            PHT[expcindex] <= PHT[expcindex] + 1'b1 ;
        end
    else if(!actual_jump_flag && (PHT[expcindex] > 2'b0) && is_branch)begin
        PHT[expcindex] <= PHT[expcindex] - 1'b1 ;
        end
    else begin
        PHT[expcindex] <= PHT[expcindex] ;
    end
end
//predict 
assign predict_taken = PHT[ifpcindex][1] & BTB_VALID[ifpc] &(BTB_TAG[ifpc]== pc_from_if[14:8]) ;
assign predict_target = BTB[ifpc]  ;

endmodule