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
`include "defines.v"
// 通用寄存器模块，双端口，可同时读取两个寄存器数据
module RF_UNIT(

    input   wire                    clk               ,
    input   wire                    rst_n             ,
                                                      
	input   wire                    ex_bypass1        , 
	input   wire                    mbem_bypass1       , 
	input   wire                    mem_bypass1       , 
	input   wire                    wb_bypass1        , 
	input   wire                    ex_bypass2        , 
	input   wire                    mbem_bypass2       , 
	input   wire                    mem_bypass2       , 
	input   wire                    wb_bypass2        , 
	
    // gpr读写信号                                    
    input   wire                    wr_en_i           , // 写使�?
    input   wire[`INST_REG_ADDR]    wr_addr_i         , // 写地�?
    input   wire[`INST_REG_DATA]    wr_data_i         , // 写数�?
    input   wire[`INST_REG_ADDR]    reg1_rd_addr_i    , // R1寄存器读地址
    input   wire[`INST_REG_ADDR]    reg2_rd_addr_i    , // R2寄存器读地址
    output  wire[`INST_REG_DATA]    reg1_rd_data_o    , // R1寄存器读数据
    output  wire[`INST_REG_DATA]    reg2_rd_data_o    , // R2寄存器读数据
    
	// csr读写信号
	//with clint 
    input   wire                    clint_wr_privilege_en_i  ,
	input   wire [1:0]              clint_wr_privilege_i     ,
	output  wire [1:0]              clint_privileg_o         ,
    input   wire                    clint_wr_en_i            ,
	input   wire [`INST_ADDR_BUS]   clint_wr_addr_i          ,
	input   wire [`INST_REG_DATA]   clint_wr_data_i          ,
	input   wire [`INST_ADDR_BUS]   clint_rd_addr_i          ,
	output  wire [`INST_REG_DATA]   clint_rd_data_o          ,
	output  wire [`INST_REG_DATA]   clint_csr_mtvec_o        ,
	output  wire [`INST_REG_DATA]   clint_csr_mepc_o         ,
	output  wire [`INST_REG_DATA]   clint_csr_mstatus_o      ,
	//with ex mem wb
	input   wire                    csr_wr_en_i              ,
	input   wire [`INST_ADDR_BUS]   csr_wr_addr_i            ,
	input   wire [`INST_REG_DATA]   csr_wr_data_i            ,
	input   wire [`INST_ADDR_BUS]   csr_rd_addr_i            ,
	output  wire [`INST_REG_DATA]   csr_rd_data_o            ,
	//冒险问题
	input	wire[`INST_REG_DATA]    ex_wr_data_i             ,
	input	wire[`INST_REG_DATA]    mem_wr_data_i            ,
	input   wire[`INST_REG_DATA]    mbem_wr_data_i           
    
    );
    
    // 通用寄存器例�?
    gpr u_gpr(
        .clk                 (clk),
        .rst_n               (rst_n),
		.ex_bypass1          (ex_bypass1 ),
		.mbem_bypass1        (mbem_bypass1),
		.mem_bypass1         (mem_bypass1),
		.wb_bypass1          (wb_bypass1 ),
		.ex_bypass2          (ex_bypass2 ),
		.mbem_bypass2        (mbem_bypass2),
		.mem_bypass2         (mem_bypass2),
		.wb_bypass2          (wb_bypass2 ),
        .wr_en_i             (wr_en_i), 
        .wr_addr_i           (wr_addr_i), 
        .wr_data_i           (wr_data_i), 
		.ex_wr_data_i        (ex_wr_data_i),
		.mem_wr_data_i       (mem_wr_data_i),
        .reg1_rd_addr_i      (reg1_rd_addr_i),
        .reg2_rd_addr_i      (reg2_rd_addr_i),
        .reg1_rd_data_o      (reg1_rd_data_o),
        .reg2_rd_data_o      (reg2_rd_data_o),
		.mbem_wr_data_i      (mbem_wr_data_i)
    );
    
	csr  u_csr
	(
	.clk                  (clk  ),
	.rst_n                (rst_n),
	.wr_en_i              (csr_wr_en_i   ),
	.wr_addr_i            (csr_wr_addr_i ),
	.wr_data_i            (csr_wr_data_i ),
	.rd_addr_i            (csr_rd_addr_i),
	.rd_data_o            (csr_rd_data_o),
	.clint_wr_en_i        (clint_wr_en_i    ),
	.clint_wr_addr_i      (clint_wr_addr_i  ),
	.clint_wr_data_i      (clint_wr_data_i  ),
	.clint_rd_addr_i      (clint_rd_addr_i  ),
	.clint_rd_data_o      (clint_rd_data_o  ),
	.wr_privilege_en_i    (clint_wr_privilege_en_i),
	.wr_privilege_i       (clint_wr_privilege_i),
	.privileg_o           (clint_privileg_o),
	.clint_csr_mtvec      (clint_csr_mtvec_o  ),
	.clint_csr_mepc       (clint_csr_mepc_o   ),
	.clint_csr_mstatus    (clint_csr_mstatus_o) 
	
	);
endmodule
