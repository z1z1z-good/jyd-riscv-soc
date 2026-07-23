`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/14 10:39:16
// Design Name: 
// Module Name: pc_reg
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

// PC寄存器模�?
module pc(

    input   wire                    clk         ,
    input   wire                    rst_n       ,
    
    input   wire[2:0]               hold_flag_i ,
    input   wire                    jump_flag_i ,
    input   wire[`INST_REG_DATA]    jump_addr_i ,
    input   wire                    pred_taken   ,
    input   wire[31:0]              pred_target  ,
    output  reg[13:0]               pc_o  
    
    );
	//当冲刷与预测同时有效怎么办：冲刷优先冲刷代表一开始要你跳转的使能，优先级比预测高
	//当停顿与预测同时发生怎么办；寄存器寄存预测的使能信号与停顿信号，当两个的寄存器同时使能说明停止完并且预测跳转，之后再跳转
    wire [13:0] jump_addr = jump_addr_i[13:0];
    wire [13:0] pre_addr  = pred_target[13:0] ;
    always @ (posedge clk or negedge rst_n) begin
        // 复位
        if(!rst_n) begin
            pc_o <= 0;
        end
        // 跳转
        else if(jump_flag_i == 1'b1) begin
            pc_o <= jump_addr;
        end
        // 暂停
        else if((hold_flag_i >= `HOLD_PC)) begin
            pc_o <= pc_o;
        end
        else if(pred_taken)begin  //不管预测成不成功都是用这个地�?
            pc_o <= pre_addr ;
        end
		else begin
		    pc_o <= pc_o + 4;
		end
    end
    
endmodule
