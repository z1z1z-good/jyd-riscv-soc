`timescale 1ns / 1ps
`include "../core/defines.v"
module WBU
(
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