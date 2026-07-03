`include "../core/defines.v"

module IF2_UNIT
(
input wire            clk         ,
input wire            rst_n       ,

input wire  [2:0]     hold_flag_i ,  
input wire            keep_flag_i ,

input wire  [31:0]    ins_i       ,
input wire  [31:0]    ins_addr_i  ,

output reg  [31:0]    ins_o       ,
output reg  [31:0]    ins_addr_o 
);
always@(posedge clk or negedge rst_n)begin
if(~rst_n)begin
ins_o <=  32'b0 ;
ins_addr_o <= 32'b0 ;
end
else if(hold_flag_i >= `HOLD_IF_ID)begin
ins_o <=  32'b0 ;
ins_addr_o <= 32'b0 ;
end
else if(keep_flag_i)begin
ins_o <=  ins_o ;
ins_addr_o <= ins_addr_o ;
end
else begin 
ins_o <=  ins_i ;
ins_addr_o <= ins_addr_i ;
end
end

endmodule