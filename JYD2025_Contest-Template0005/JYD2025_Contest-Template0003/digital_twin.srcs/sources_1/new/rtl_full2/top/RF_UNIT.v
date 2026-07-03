`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/14 22:29:15
// Design Name: 
// Module Name: regs
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
// 通用寄存器模块，双端口，可同时读取两个寄存器数据
module RF_UNIT(

    input   wire                    clk               ,
    input   wire                    rst_n             ,
                                                      
    // gpr读写信号                                    
    input   wire                    wr_en_i           , // 写使�?
    input   wire                    wr_en_fp_i           , // 写使胿
    input   wire[`INST_REG_ADDR]    wr_addr_i         , // 写地�?
    input   wire[`INST_REG_DATA]    wr_data_i         , // 写数�?
    input   wire[`INST_REG_ADDR]    reg1_rd_addr_i    , // R1寄存器读地址
    input   wire[`INST_REG_ADDR]    reg2_rd_addr_i    , // R2寄存器读地址
    output  wire[`INST_REG_DATA]    reg1_rd_data_o    , // R1寄存器读数据
    output  wire[`INST_REG_DATA]    reg2_rd_data_o    , // R2寄存器读数据
    
    output  wire[`INST_REG_DATA]    reg1_rd_data_fp_o    , // R1寄存器读数据
    output  wire[`INST_REG_DATA]    reg2_rd_data_fp_o    , // R2寄存器读数据   
    
	//冒险问题
	input	wire[`INST_REG_ADDR]    ex_wr_addr_i      ,
	input	wire[`INST_REG_DATA]    ex_wr_data_i      ,
    input	wire					not_mem           ,
	input   wire                    ex_wr_en_i        ,
    input   wire                    ex_wr_en_fp_i        ,
	input   wire                    mem_wr_en_i       ,
    input   wire                    mem_wr_en_fp_i       ,
	input	wire[`INST_REG_ADDR]    mem_wr_addr_i     ,
	input	wire[`INST_REG_DATA]    mem_wr_data_i      
    
    );
    
    // 通用寄存器例�?
    gpr u_int(
        .clk                 (clk),
        .rst_n               (rst_n),
        .wr_en_i             (wr_en_i), 
		.ex_wr_addr_i        (ex_wr_addr_i),
		.mem_wr_addr_i       (mem_wr_addr_i),
        .wr_addr_i           (wr_addr_i), 
        .wr_data_i           (wr_data_i), 
		.ex_wr_data_i        (ex_wr_data_i),
		.mem_wr_data_i       (mem_wr_data_i),
		.not_mem			 (not_mem),
		.ex_wr_en_i          (ex_wr_en_i  ),
		.mem_wr_en_i         (mem_wr_en_i ),
        .reg1_rd_addr_i      (reg1_rd_addr_i),
        .reg2_rd_addr_i      (reg2_rd_addr_i),
        .reg1_rd_data_o      (reg1_rd_data_o),
        .reg2_rd_data_o      (reg2_rd_data_o) 
    );
    
        // 通用寄存器例匿
    gpr u_float(
        .clk                 (clk),
        .rst_n               (rst_n),
        .wr_en_i             (wr_en_fp_i), 
		.ex_wr_addr_i        (ex_wr_addr_i),
		.mem_wr_addr_i       (mem_wr_addr_i),
        .wr_addr_i           (wr_addr_i), 
        .wr_data_i           (wr_data_i), 
		.ex_wr_data_i        (ex_wr_data_i),
		.mem_wr_data_i       (mem_wr_data_i),
		.not_mem			 (not_mem),
		.ex_wr_en_i          (ex_wr_en_fp_i  ),
		.mem_wr_en_i         (mem_wr_en_fp_i ),
        .reg1_rd_addr_i      (reg1_rd_addr_i),
        .reg2_rd_addr_i      (reg2_rd_addr_i),
        .reg1_rd_data_o      (reg1_rd_data_fp_o),
        .reg2_rd_data_o      (reg2_rd_data_fp_o) 
    );
    
endmodule
