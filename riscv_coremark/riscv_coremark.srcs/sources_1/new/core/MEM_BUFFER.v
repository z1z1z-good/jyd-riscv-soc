`include "defines.v"
//此模块作用在于将从主存返回的数据打拍后传给MEM_UNIT
module MEM_BUFFER
(
input   wire                    clk                 ,
input   wire                    rst_n               ,
input   wire[31:0]              reg2_rd_data_i      ,
output  reg [31:0]              reg2_rd_data_o      ,
input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,//还要接给gpr模块
input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
input   wire                    reg_wr_en_i         ,
output  reg                     reg_wr_en_o         ,
output  reg [`INST_REG_ADDR]    reg_wr_addr_o       ,
output  reg [`INST_REG_DATA]    reg_wr_data_o       ,
//访存相关
input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
output  reg [`INST_ADDR_BUS]    mem_rd_addr_o       ,

input	wire					is_load_i			,
input	wire					is_save_i			,
output  wire                    not_mem             ,
input   wire[2:0]               funct3_i            ,
output  reg                     is_load_o           ,
output  reg                     is_save_o           ,
output  reg [2:0]               funct3_o            ,
//数据前递相关
output  wire[31:0]              reg_wr_data_hypass  ,
output  wire[4:0]               reg_wr_addr_hypass  ,
output  wire                    reg_wr_en_hypass    

);
assign reg_wr_data_hypass   =  reg_wr_data_i ;
assign reg_wr_addr_hypass   =  reg_wr_addr_i ;
assign reg_wr_en_hypass     =  reg_wr_en_i   ;
assign not_mem              = ~(is_load_i|is_save_i);
always@(posedge clk or negedge rst_n)begin
	if(~rst_n)begin
		reg_wr_en_o    <= 1'b0 ;
		reg_wr_addr_o  <= 5'b0 ;
		reg_wr_data_o  <= 32'b0 ;
		reg2_rd_data_o <= 32'b0 ;
		mem_rd_addr_o  <= 32'b0 ;
		is_load_o      <= 1'b0  ;
		is_save_o      <= 1'b0  ;
		funct3_o       <= 3'b0  ;
	end
	else begin
		reg_wr_en_o    <= reg_wr_en_i   ;
		reg_wr_addr_o  <= reg_wr_addr_i ;
		reg_wr_data_o  <= reg_wr_data_i ;
		reg2_rd_data_o <= reg2_rd_data_i ;
		mem_rd_addr_o  <= mem_rd_addr_i  ;
		is_load_o      <= is_load_i  ;
		is_save_o      <= is_save_i  ;
		funct3_o       <= funct3_i   ;
	end
end

endmodule
