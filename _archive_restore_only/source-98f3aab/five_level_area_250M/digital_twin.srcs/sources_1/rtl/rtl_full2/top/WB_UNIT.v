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
(* keep_hierarchy="yes", optimize="off" *)
module WB_UNIT
(
    input   wire                    clk                ,
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
	input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
    input   wire                    reg_wr_en_i         ,
    output  wire                    reg_wr_en_o         ,
    output  wire[`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  wire[`INST_REG_DATA]    reg_wr_data_o       ,
	input   wire[`INST_REG_DATA]    reg2_rd_data_i      ,
	input	wire					is_load_i			,
	input	wire					is_save_i			,
	input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
	input   wire[`INST_DATA_BUS]    mem_rd_data_i       ,
	output  wire                    mem_wr_rib_req_o    ,
	output  wire                    mem_wr_en_o         ,
	output  wire[`INST_ADDR_BUS]    mem_wr_addr_o       ,
	output  wire[`INST_DATA_BUS]    mem_wr_data_o       ,
	input   wire[1:0]               funct3_i            ,
	input   wire                    keep_flag_i
);
(* preserve = "true", keep = "true" *)reg keep_flag_reg0 = 0;
(* preserve = "true", keep = "true" *)reg keep_flag_reg1 = 0;
(* preserve = "true", keep = "true" *)reg keep_flag_reg2 = 0;
always@(posedge clk)begin
keep_flag_reg0 <= keep_flag_i;
keep_flag_reg1 <= keep_flag_reg0;
keep_flag_reg2 <= keep_flag_reg1;


end
wire[`INST_ADDR_BUS]    mem_wr_addr       ;
wire                    mem_wr_en         ;
wire[`INST_DATA_BUS]    mem_wr_data       ;
wire[`INST_DATA_BUS]    mem_rd_data       ;
assign mem_wr_addr_o = mem_wr_addr  ;
assign mem_wr_data_o = mem_wr_data  ;
assign mem_wr_en_o   = mem_wr_en    ;
wb wb_inst
(
.reg2_rd_data_i      (reg2_rd_data_i),
.funct3_i            (funct3_i), 
.is_load_i			 (is_load_i),
.is_save_i			 (is_save_i),
.mem_rd_addr_i       (mem_rd_addr_i   ),
.mem_rd_data_i       (mem_rd_data   ),
.mem_wr_rib_req_o    (mem_wr_rib_req_o),
.mem_wr_en_o         (mem_wr_en     ),
.mem_wr_addr_o       (mem_wr_addr   ),
.mem_wr_data_o       (mem_wr_data   ),
.reg_wr_addr_i       (reg_wr_addr_i   ),
.reg_wr_data_i       (reg_wr_data_i   ),
.reg_wr_en_i         (reg_wr_en_i     ),
.reg_wr_en_o         (reg_wr_en_o     ),
.reg_wr_addr_o       (reg_wr_addr_o   ),
.reg_wr_data_o       (reg_wr_data_o   ),
.keep_flag_i         (keep_flag_i     )



);

rd_data_mux rd_data_mux_inst
(
.clk        (clk),
.wr_addr_i  (mem_wr_addr),
.wr_data_i  (mem_wr_data),
.rd_addr_i  (mem_rd_addr_i),
.rd_data_i  (mem_rd_data_i),
.wr_en_i    (mem_wr_en),
.rd_data_o  (mem_rd_data)

);
/* wb u_wb
(
.reg_wr_addr_i       (reg_wr_addr_i ),
.reg_wr_data_i       (reg_wr_data_i ),
.reg_wr_en_i         (reg_wr_en_i   ),
.reg_wr_en_o         (reg_wr_en_o   ),
.reg_wr_addr_o       (reg_wr_addr_o ),
.reg_wr_data_o       (reg_wr_data_o ),
.keep_flag_i         (keep_flag_reg2)
); */

endmodule