module mem_wr_buffer //把写数据寄存在这里，打一拍后再发出
//读地址应该在ex阶段不应该在mem阶段
(
input wire        clk        ,
input wire [31:0] wr_addr_i  ,
input wire [31:0] wr_data_i  ,
output wire[31:0] wr_addr_o  ,
output wire[31:0] wr_data_o  ,
output wire       wr_en_o    ,
input wire [31:0] rd_addr_i  ,
input wire [31:0] rd_data_i  ,
input wire        wr_en_i    ,
output reg[31:0]  rd_data_o  
);
//存储
reg [31:0] wr_data_buffer = 0; //基于当前设计写的二级fifo
reg [31:0] wr_addr_buffer = 0;
reg        wr_en_buffer   = 0;
//fifo的更斿
//buffer的存傿
always@(posedge clk)begin
if(wr_en_i)begin
wr_data_buffer <= wr_data_i;
wr_addr_buffer <= wr_addr_i;
wr_en_buffer   <= wr_en_i  ;
end
else begin
wr_data_buffer <= 32'b0;
wr_addr_buffer <= 32'b0;
wr_en_buffer   <= 1'b0 ;
end
end
assign wr_addr_o   =  wr_addr_buffer   ;
assign wr_data_o   =  wr_data_buffer   ;
assign wr_en_o     =  wr_en_buffer     ;
wire [29:0] wr_addr = wr_addr_buffer[31:2] ;
wire [29:0] rd_addr = rd_addr_i[31:2] ;
wire equal_wr_rd_buffer = (wr_addr == rd_addr );
//数据的提便(通过比较)
always@(posedge clk)begin
if((wr_addr_i[31:2] == rd_addr_i[31:2]) & wr_en_i )begin
rd_data_o = wr_data_i  ; 
end
else if(equal_wr_rd_buffer & wr_en_buffer)begin
rd_data_o = wr_data_buffer ;
end
else begin
rd_data_o = rd_data_i; 
end
end

endmodule