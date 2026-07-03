`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/15 16:55:51
// Design Name: 
// Module Name: ID_UNIT
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
// 译码单元
module ID_UNIT(

    input   wire                    clk               ,
    input   wire                    rst_n             ,
                                                      
    input   wire                    hold_flag_i       ,
     
    // from IF_UNIT
    input   wire[`INST_DATA_BUS]    ins_i             , 
    input   wire[`INST_ADDR_BUS]    ins_addr_i        , 
    
    // from RF_UNIT               
    input   wire[`INST_REG_DATA]    reg1_rd_data_i    , 
    input   wire[`INST_REG_DATA]    reg2_rd_data_i    , 
    // to RF_UNIT
    output  wire [`INST_REG_ADDR]    reg1_rd_addr_o    , 
    output  wire [`INST_REG_ADDR]    reg2_rd_addr_o    , //当keep到来时这个也是需要keep的！！！
    // to EX_UNIT
    output  wire[`INST_REG_DATA]    reg1_rd_data_o    , 
    output  wire[`INST_REG_DATA]    reg2_rd_data_o    ,                         
    output  wire[`INST_REG_ADDR]    reg_wr_addr_o     ,
    
    // to EX_UNIT
    output  wire[`INST_DATA_BUS]    ins_o             ,     
    output  wire[`INST_ADDR_BUS]    ins_addr_o        ,                                      
	
	input   wire[`INST_DATA_BUS]    csr_rd_data_i     ,
	output  wire[`INST_DATA_BUS]    csr_rd_data_o     ,
	output  wire[`INST_DATA_BUS]    csr_zimm_o        ,
	output  wire[`INST_ADDR_BUS]    csr_rd_addr_o     ,
	output  wire[`INST_ADDR_BUS]    csr_rw_addr_o     ,
	
    output  wire[`INST_REG_DATA]    imm_o             
    
    );
	wire[`INST_ADDR_BUS]    csr_rw_addr  ;
	wire[`INST_DATA_BUS]    csr_zimm     ;
	
	wire[`INST_REG_ADDR]    reg1_rd_addr_wire    ;
	wire[`INST_REG_ADDR]    reg2_rd_addr_wire    ;
    assign reg1_rd_addr_o = reg1_rd_addr_wire;
	assign reg2_rd_addr_o = reg2_rd_addr_wire;
    wire[`INST_DATA_BUS]    ins;
    wire[`INST_REG_ADDR]    reg_wr_addr;
    wire[`INST_REG_DATA]    imm;
    wire [6:0] opcode;
    assign opcode = ins_i[6:0];
	assign csr_rd_addr_o = csr_rw_addr ;
    //always @ (posedge clk) begin
     //       mem_rd_addr_o = $signed(reg1_rd_data_i) + $signed(imm);
    //end
    // 指令译码模块例化
    id u_id(
        .clk                (clk),
        .rst_n              (rst_n),
        .ins_i              (ins_i), 
        .ins_addr_i         (ins_addr_i),
        .ins_o              (ins), 
        .reg1_rd_addr_o     (reg1_rd_addr_wire), 
        .reg2_rd_addr_o     (reg2_rd_addr_wire),
        .reg_wr_addr_o      (reg_wr_addr),
        .imm_o              (imm),
		.csr_rw_addr_o      (csr_rw_addr),
		.csr_zimm_o         (csr_zimm)
    );
    
    id_ex u_id_ex(
        .clk                (clk),
        .rst_n              (rst_n),
        .hold_flag_i        (hold_flag_i),
        .ins_i              (ins), 
        .ins_addr_i         (ins_addr_i),
        .ins_o              (ins_o), 
        .reg1_rd_data_i     (reg1_rd_data_i), 
        .reg2_rd_data_i     (reg2_rd_data_i),
        .reg_wr_addr_i      (reg_wr_addr),
        .imm_i              (imm),
		.csr_rw_addr_i      (csr_rw_addr),
		.csr_zimm_i         (csr_zimm),
		.csr_rd_data_i      (csr_rd_data_i  ),
        .ins_addr_o         (ins_addr_o), 
        .reg1_rd_data_o     (reg1_rd_data_o), 
        .reg2_rd_data_o     (reg2_rd_data_o),
        .reg_wr_addr_o      (reg_wr_addr_o),
        .imm_o              (imm_o),
		.csr_rw_addr_o      (csr_rw_addr_o),
		.csr_zimm_o         (csr_zimm_o   ),
		.csr_rd_data_o      (csr_rd_data_o)
    );
    
endmodule
