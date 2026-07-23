`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/16 16:05:52
// Design Name: 
// Module Name: MEM_UNIT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../core/defines.v"
module MEM_UNIT
(
	
	//from EX_UNIT 
	//1、访存相�? 2、写入相�?
	//写入相关
	input	wire                    clk                 ,
	input	wire                    rst_n               ,
    input   wire[`INST_REG_DATA]    reg2_rd_data_i      ,
	output  wire[`INST_REG_DATA]    reg2_rd_data_o      ,
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,//还要接给gpr模块
	input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
    input   wire                    reg_wr_en_i         ,
    output  reg                     reg_wr_en_o         ,
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  reg [`INST_REG_DATA]    reg_wr_data_o       ,
	output  wire                    reg_wr_en_to_gpr    ,
	output  wire[2:0]               funct3_o            ,
	input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
	output  wire[`INST_ADDR_BUS]    mem_rd_addr_o       ,
	input	wire                    is_load_i           ,
	input	wire                    is_save_i           ,
	output  wire                    is_load_o           ,
	output  wire                    is_save_o           ,
	input	wire                    keep_flag_i         ,
	output	wire[`INST_REG_DATA]    reg_wr_data_first_o ,
    input   wire[`INST_DATA_BUS]    ins_i               
);

wire	[2:0]	funct3;
reg 			keep_flag_control_wr = 0;
reg				keep_flag_control_wr_reg1 = 0;
wire                    reg_wr_en_to_wb      ;
wire[`INST_REG_ADDR]    reg_wr_addr_to_wb    ;
wire[`INST_REG_DATA]    reg_wr_data_to_wb    ;
assign reg_wr_data_first_o = (reg_wr_en_to_wb)?reg_wr_data_to_wb:32'b0;
//提前送达寄存器组
always@(posedge clk or negedge rst_n)begin
	if(~rst_n)begin
		keep_flag_control_wr <= 1'b0;
		keep_flag_control_wr_reg1 <= 1'b0;
	end
	else begin
		keep_flag_control_wr <= keep_flag_i;
		keep_flag_control_wr_reg1 <= keep_flag_control_wr;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(~rst_n)begin
		reg_wr_en_o    <= 1'b0 ;
		reg_wr_addr_o  <= 5'b0 ;
		reg_wr_data_o  <= 32'b0 ;
	end
	else begin
		reg_wr_en_o    <= reg_wr_en_to_wb   ;
		reg_wr_addr_o  <= reg_wr_addr_to_wb ;
		reg_wr_data_o  <= reg_wr_data_to_wb ;
	end
end
assign funct3 = ins_i[14:12];
assign reg_wr_en_to_gpr = reg_wr_en_to_wb;
mem mem_inst
(
.reg2_rd_data_i      (reg2_rd_data_i),
.reg2_rd_data_o      (reg2_rd_data_o),
.reg_wr_addr_i       (reg_wr_addr_i),
.reg_wr_data_i       (reg_wr_data_i),
.reg_wr_en_i         (reg_wr_en_i),
.reg_wr_en_o         (reg_wr_en_to_wb),
.reg_wr_addr_o       (reg_wr_addr_to_wb),
.reg_wr_data_o       (reg_wr_data_to_wb),
.funct3_i            (funct3),
.funct3_o            (funct3_o),
.is_load_i			(is_load_i),
.is_save_i			(is_save_i),
.is_load_o           (is_load_o),
.is_save_o           (is_save_o),
.keep_flag_control	(keep_flag_control_wr_reg1),
.mem_rd_addr_i       (mem_rd_addr_i),
.mem_rd_addr_o       (mem_rd_addr_o)

);
/* mem mem_inst
(
.reg2_rd_data_i      (reg2_rd_data_i),

.reg_wr_addr_i       (reg_wr_addr_i ),
.reg_wr_data_i       (reg_wr_data_i),
.reg_wr_en_i         (reg_wr_en_i  ),
.reg_wr_en_o         (reg_wr_en_to_wb   ),
.reg_wr_addr_o       (reg_wr_addr_to_wb ),
.reg_wr_data_o       (reg_wr_data_to_wb ),

.funct3_i            (funct3         ),
.is_load_i			 (is_load_i		),
.is_save_i			 (is_save_i		),
.keep_flag_control   (keep_flag_control_wr_reg1),//�?
.mem_rd_addr_i       (mem_rd_addr_i    ),
.mem_rd_data_i       (mem_rd_data_i    ),
.mem_wr_rib_req_o    (mem_wr_rib_req_o ),
.mem_wr_en_o         (mem_wr_en_o      ),
.mem_wr_addr_o       (mem_wr_addr_o    ),
.mem_wr_data_o       (mem_wr_data_o    )
); */

endmodule