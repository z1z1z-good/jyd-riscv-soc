`timescale 1ns / 1ps
`include "defines.v"
module wb
(
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
	input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
    input   wire                    reg_wr_en_i         ,
    output  wire                    reg_wr_en_o         ,
    output  wire[`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  wire[`INST_REG_DATA]    reg_wr_data_o       
	
);
assign reg_wr_addr_o = reg_wr_addr_i;
assign reg_wr_en_o = reg_wr_en_i;
assign reg_wr_data_o = reg_wr_data_i;
endmodule
