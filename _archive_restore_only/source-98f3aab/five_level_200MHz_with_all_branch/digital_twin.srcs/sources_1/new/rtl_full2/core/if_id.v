`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/14 20:49:15
// Design Name: 
// Module Name: ir_reg
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

// 将指令地�?打一拍输出到译码模块
module if_id(

    input   wire                    clk         ,
    input   wire                    rst_n       ,
    
    input   wire[2:0]               hold_flag_i ,
	
    input   wire[`INT_BUS]          int_flag_i  ,
    output  reg [`INT_BUS]          int_flag_o  ,
    
    input   wire[`INST_DATA_BUS]    ins_i       , 
    input   wire[13:0]              ins_addr_i  ,
    
    output  reg[`INST_DATA_BUS]     ins_o       , 
    output  reg[`INST_ADDR_BUS]     ins_addr_o   
    
    );
    
    reg[2:0]               hold_flag_reg;
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            hold_flag_reg <= `HOLD_NONE;
        end
        else begin
            hold_flag_reg <= hold_flag_i;
        end
    end
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ins_addr_o <= `RESET_ADDR;
            int_flag_o <= `INT_NONE;
        end
        else if((hold_flag_i >= `HOLD_IF_ID)) begin
            ins_addr_o <= `RESET_ADDR;
            int_flag_o <= `INT_NONE;
        end
        else begin
            ins_addr_o <= {{18'b1000_0000_0000_0000_00},ins_addr_i[13:2], {2'b0}};
            int_flag_o <= int_flag_i;
        end
    end
    
    // 因为从rom中读取的指令本身就会延迟�?拍，�?以无�?延迟
    always @ (*) begin
		ins_o = (hold_flag_reg >= `HOLD_IF_ID) ? `INS_NOP : ins_i;
	end

endmodule
