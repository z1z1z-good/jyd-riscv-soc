`timescale 1ns / 1ps
`include "../core/defines.v"

// 取指单元
module IFU(

    input   wire                     clk          ,
    input   wire                     rst_n        ,
    
    // from EXU
    input   wire[2:0]                hold_flag_i  ,
    input   wire                     jump_flag_i  ,
    input   wire[`INST_REG_DATA]     jump_addr_i  ,
	input	wire                     keep_flag_i  ,
    
    // 这是是为了将中断信号经if_id阶段同步后再输出
    input   wire[`INT_BUS]           int_flag_i   ,
    output  reg [`INT_BUS]           int_flag_o   ,
    
    // to IDU
    output  reg [`INST_DATA_BUS]     instr_o        , 
    output  reg [`INST_ADDR_BUS]     instr_addr_o   ,
    
    output  wire[`INST_ADDR_BUS]     pc_o         , 
    input   wire[`INST_DATA_BUS]     instr_i          
    
    );
    
    wire[`INST_ADDR_BUS]       pc;
    assign pc_o = pc;
    
    reg[2:0]               hold_flag_reg;
    reg                    keep_flag_reg;
    reg [`INST_DATA_BUS]   instr_reg;
	reg [`INT_BUS]         int_flag_reg;
	reg [`INST_ADDR_BUS]   instr_addr_reg;
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            hold_flag_reg <= `HOLD_NONE;
			keep_flag_reg <= 1'b0;
        end
        else begin
            hold_flag_reg <= hold_flag_i;
			keep_flag_reg <= keep_flag_i;
        end
    end
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
		instr_addr_reg     <= 0;
		int_flag_reg     <= 0;
        instr_reg          <= 0;
		end
		else if(keep_flag_i)begin
		instr_addr_reg     <= instr_addr_o;
		int_flag_reg     <= int_flag_o;
        instr_reg          <= instr_o;        
		end
		else begin
		instr_addr_reg     <= 0;
		int_flag_reg     <= 0;
        instr_reg          <= 0;    
		end
	end
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            instr_addr_o <= `RESET_ADDR;
            int_flag_o <= `INT_NONE;
            instr_o      <= `ZERO_WORD;
        end
        else if((hold_flag_i >= `HOLD_IF_ID)||keep_flag_i) begin
            instr_addr_o <= `RESET_ADDR;
            int_flag_o <= `INT_NONE;
            instr_o      <= `ZERO_WORD;            
        end
		else if(keep_flag_reg)begin
            instr_addr_o <= instr_addr_reg;
            int_flag_o <= int_flag_reg;
            instr_o      <= instr_reg;            
		end
        else begin
            instr_addr_o <= {pc[31:2], {2'b0}};
            int_flag_o <= int_flag_i;
            instr_o      <= instr_i;
        end
    end
    
    
    // PC寄存器模块例化
    pc u_pc(
        .clk         (clk)  ,
        .rst_n       (rst_n),
        .hold_flag_i (hold_flag_i),
        .jump_flag_i (jump_flag_i),
        .jump_addr_i (jump_addr_i),
		.keep_flag_i (keep_flag_i),
        .pc_o        (pc)
    );
    
    // 指令寄存器模块例化
    //if_id u_if_id(
    //    .clk         (clk),
    //    .rst_n       (rst_n),
    //    .hold_flag_i (hold_flag_i),
	//	.keep_flag_i (keep_flag_i),
    //    .int_flag_i  (int_flag_i),
    //    .int_flag_o  (int_flag_o),
    //    .instr_i       (instr_i), 
    //    .instr_addr_i  (pc),
    //    .instr_o       (instr_o), 
    //    .instr_addr_o  (instr_addr_o) 
    //);
    
endmodule
