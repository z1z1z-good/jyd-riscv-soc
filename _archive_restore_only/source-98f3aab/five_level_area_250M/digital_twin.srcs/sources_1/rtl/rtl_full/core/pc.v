`timescale 1ns / 1ps
`include "defines.v"

// PC寄存器模块
module pc(

    input   wire                    clk         ,
    input   wire                    rst_n       ,
    
    input   wire[2:0]               hold_flag_i ,
    input   wire                    jump_flag_i ,
    input   wire[`INST_REG_DATA]    jump_addr_i ,
	input	wire                    keep_flag_i ,
    
    output  reg[`INST_ADDR_BUS]     pc_o  
    
    );
    reg [`INST_ADDR_BUS] pc_reg;
	reg keep_flag_reg;
	always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		keep_flag_reg <= 1'b0;
	end
	else begin
		keep_flag_reg <= keep_flag_i;
	end
	end
	always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
		pc_reg <= 0;
		end
		else begin
		pc_reg <= pc_o;//注意非阻塞
		end
	end
    always @ (posedge clk or negedge rst_n) begin
        // 复位
        if(!rst_n) begin
            pc_o <= `RESET_ADDR;
        end
        // 跳转
        else if(jump_flag_i == 1'b1) begin
            pc_o <= jump_addr_i;
        end
        // 暂停
        else if((hold_flag_i >= `HOLD_PC)) begin
            pc_o <= pc_o;
        end
		//延迟
		else if(keep_flag_i)begin
			pc_o <= pc_reg;
		end
        // 地址加4
        else begin
            pc_o <= pc_o + 4'd4;
        end
    end
    
endmodule
