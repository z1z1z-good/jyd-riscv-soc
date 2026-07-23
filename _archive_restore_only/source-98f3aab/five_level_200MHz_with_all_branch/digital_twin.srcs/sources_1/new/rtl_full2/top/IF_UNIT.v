`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/14 11:23:19
// Design Name: 
// Module Name: IF_UNIT
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
// 取指单元
module IF_UNIT(

    input   wire                     clk          ,
    input   wire                     rst_n        ,
    //from  global_predictor
    input   wire                     pred_taken   ,
    input   wire[31:0]               pred_target  ,
    // from EX_UNIT
    input   wire[2:0]                hold_flag_i  ,
    input   wire                     jump_flag_i  ,
    input   wire[`INST_REG_DATA]     jump_addr_i  ,
    
    input   wire[`INT_BUS]           int_flag_i   ,
    output  wire[`INT_BUS]           int_flag_o   ,
    
    // to ID_UNIT
    output  wire[`INST_DATA_BUS]     ins_o        , 
    output  wire[`INST_ADDR_BUS]     ins_addr_o   ,
    
    output  wire[13:0]               pc_o         , 
    input   wire[`INST_DATA_BUS]     ins_i          
    
    );
    
    wire[13:0]       pc;
    assign pc_o = pc;
	wire  [`INST_DATA_BUS]     ins_normal ;
	assign ins_o = ins_normal;
    // PC寄存器模块例�?
    pc u_pc(
        .clk         (clk)  ,
        .rst_n       (rst_n),
        .pred_taken  (pred_taken ), 
        .pred_target (pred_target),
        .hold_flag_i (hold_flag_i),
        .jump_flag_i (jump_flag_i),
        .jump_addr_i (jump_addr_i),
        .pc_o        (pc)
    );
    
    // 指令寄存器模块例�?
    if_id u_if_id(
        .clk         (clk),
        .rst_n       (rst_n),
        .hold_flag_i (hold_flag_i),
        .int_flag_i  (int_flag_i),
        .int_flag_o  (int_flag_o),
        .ins_i       (ins_i), 
        .ins_addr_i  (pc),
        .ins_o       (ins_normal), 
        .ins_addr_o  (ins_addr_o) 
    );
    
endmodule
