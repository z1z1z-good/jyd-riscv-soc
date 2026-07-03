`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/16 16:05:52
// Design Name: 
// Module Name:wb
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
/////////////////////////////////////////////////////////////////////////////////
`include "defines.v"
module wb
(
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
	input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
    input   wire                    reg_wr_en_i         ,
    input   wire                    reg_wr_en_fp_i         ,
    output  wire                    reg_wr_en_o         ,
    output  wire                    reg_wr_en_fp_o         ,
    output  wire[`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  wire[`INST_REG_DATA]    reg_wr_data_o       ,
	input   wire                    keep_flag_i
);
assign reg_wr_addr_o = reg_wr_addr_i;
assign reg_wr_en_o = reg_wr_en_i &(~keep_flag_i);
assign reg_wr_en_fp_o = reg_wr_en_fp_i &(~keep_flag_i);
assign reg_wr_data_o = reg_wr_data_i;
endmodule
