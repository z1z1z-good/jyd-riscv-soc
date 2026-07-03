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
	input	wire					clk					,
	input	wire					rst_n				,
	
    input   wire[`INST_REG_DATA]    reg2_rd_data_i      ,
	
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,//还要接给gpr模块
	input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
    input   wire                    reg_wr_en_i         ,
    output  reg                     reg_wr_en_o         ,
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  reg [`INST_REG_DATA]    reg_wr_data_o       ,
	output  wire                    reg_wr_en_to_gpr    ,
	//访存相关
	input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
    input   wire[`INST_DATA_BUS]    mem_rd_data_i       ,//from rib
    output  wire                    mem_wr_rib_req_o    ,
    output  wire                    mem_wr_en_o         , 
    output  wire[`INST_ADDR_BUS]    mem_wr_addr_o       , 
    output  wire[`INST_DATA_BUS]    mem_wr_data_o       ,
	
	input	wire					is_load_i			,
	input	wire					is_save_i			,
	output	wire[`INST_REG_DATA]  reg_wr_data_first_o       ,//为了让数据提前到�?
    input   wire[`INST_DATA_BUS]    ins_i               
);
//mem_wr_buffer
wire [31:0] wr_addr_mem_buffer ;
wire [31:0] wr_data_mem_buffer ;
wire        wr_en_mem_buffer   ;
wire [31:0] rd_data_mem_buffer ;


wire	[2:0]	funct3;
wire                    reg_wr_en_to_wb      ;
wire[`INST_REG_ADDR]    reg_wr_addr_to_wb    ;
wire[`INST_REG_DATA]    reg_wr_data_to_wb    ;
assign reg_wr_data_first_o = (reg_wr_en_to_wb)?reg_wr_data_to_wb:32'b0;
//提前送达寄存器组
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

.reg_wr_addr_i       (reg_wr_addr_i ),
.reg_wr_data_i       (reg_wr_data_i),
.reg_wr_en_i         (reg_wr_en_i  ),
.reg_wr_en_o         (reg_wr_en_to_wb   ),
.reg_wr_addr_o       (reg_wr_addr_to_wb ),
.reg_wr_data_o       (reg_wr_data_to_wb ),

.funct3_i            (funct3         ),
.is_load_i			 (is_load_i		),
.is_save_i			 (is_save_i		),
.mem_rd_addr_i       (mem_rd_addr_i    ),
.mem_rd_data_i       (rd_data_mem_buffer    ),
.mem_wr_rib_req_o    (mem_wr_rib_req_o ),
.mem_wr_en_o         (wr_en_mem_buffer      ),
.mem_wr_addr_o       (wr_addr_mem_buffer    ),
.mem_wr_data_o       (wr_data_mem_buffer    )
);

mem_wr_buffer mem_wr_buffer_inst
(
.clk        (clk),
.wr_addr_i  (wr_addr_mem_buffer),
.wr_data_i  (wr_data_mem_buffer),
.wr_addr_o  (mem_wr_addr_o),
.wr_data_o  (mem_wr_data_o),
.wr_en_o    (mem_wr_en_o),
.rd_addr_i  (mem_rd_addr_i),
.rd_data_i  (mem_rd_data_i),
.wr_en_i    (wr_en_mem_buffer),
.rd_data_o  (rd_data_mem_buffer)
);
endmodule

