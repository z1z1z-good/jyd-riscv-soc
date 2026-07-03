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
`include "defines.v"
(* keep_hierarchy="yes", optimize="off" *)
module WB_UNIT
(
    input   wire                    clk                ,
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
	input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
    input   wire                    reg_wr_en_i         ,
    output  wire                    reg_wr_en_o         ,
    output  wire[`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  wire[`INST_REG_DATA]    reg_wr_data_o       
);
wb u_wb
(
.reg_wr_addr_i       (reg_wr_addr_i ),
.reg_wr_data_i       (reg_wr_data_i ),
.reg_wr_en_i         (reg_wr_en_i   ),
.reg_wr_en_o         (reg_wr_en_o   ),
.reg_wr_addr_o       (reg_wr_addr_o ),
.reg_wr_data_o       (reg_wr_data_o )
);

endmodule