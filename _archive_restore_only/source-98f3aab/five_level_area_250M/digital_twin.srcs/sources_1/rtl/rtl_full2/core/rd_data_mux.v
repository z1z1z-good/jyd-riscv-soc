module rd_data_mux //用来减少save-load型指令的延迟，包含在WB_UNIT 
(
input wire        clk        ,
input wire [31:0] wr_addr_i  ,
input wire [31:0] wr_data_i  ,
input wire [31:0] rd_addr_i  ,
input wire [31:0] rd_data_i  ,
input wire        wr_en_i    ,
output reg[31:0] rd_data_o 
);
//存储
reg [31:0] wr_data_buffer[0:1] ; //基于当前设计写的二级fifo
reg [31:0] wr_addr_buffer[0:1] ;
//fifo的更�?
always@(posedge clk )begin
wr_data_buffer[1] <= wr_data_buffer[0];
wr_addr_buffer[1] <= wr_addr_buffer[0];
end //意味�?buffer[1]是�?�数据，因此有效�?测buffer{0]
//buffer的存�?
always@(*)begin
if(wr_en_i)begin
wr_data_buffer[0] = wr_data_i;
wr_addr_buffer[0] = wr_addr_i;
end
else begin
wr_data_buffer[0] = 32'b0;
wr_addr_buffer[0] = 32'b0;
end
end
//数据的提�?(通过比较)
always@(*)begin
if(wr_addr_buffer[0] == rd_addr_i )begin
rd_data_o = wr_data_buffer[0] ; 
end
else if(wr_addr_buffer[1] == rd_addr_i)begin
rd_data_o = wr_data_buffer[1] ; 
end
else begin
rd_data_o = rd_data_i; 
end
end

endmodule