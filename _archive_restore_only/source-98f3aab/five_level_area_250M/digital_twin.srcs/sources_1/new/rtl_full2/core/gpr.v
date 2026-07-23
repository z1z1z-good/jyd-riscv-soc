`timescale 1ns / 1ps
`include "defines.v"
module gpr(

    input   wire                    clk            ,
    input   wire                    rst_n          ,
    
	input   wire                    ex_bypass1     ,
	input   wire                    mbem_bypass1   ,
	input   wire                    mem_bypass1    ,
	input   wire                    wb_bypass1     ,
	input   wire                    ex_bypass2     ,
	input   wire                    mbem_bypass2   ,
	input   wire                    mem_bypass2    ,
	input   wire                    wb_bypass2     ,
    input   wire                    wr_en_i        ,
    //input   wire[`INST_REG_ADDR]    ex_wr_addr_i      , 
	//input	wire[`INST_REG_ADDR]    mem_wr_addr_i     ,
	input   wire[`INST_REG_ADDR]    wr_addr_i      ,
    input   wire[`INST_REG_DATA]    wr_data_i      , // 
	
	input	wire[`INST_REG_DATA]    ex_wr_data_i      , // 
	input	wire[`INST_REG_DATA]    mem_wr_data_i      , // 
	input   wire[`INST_REG_DATA]    mbem_wr_data_i      , // 
	//input	wire                    not_mem            ,
	//input   wire                    ex_wr_en_i        ,
	//input   wire                    mem_wr_en_i        ,
    
    input   wire[`INST_REG_ADDR]    reg1_rd_addr_i , // R1寄存器读地址
    input   wire[`INST_REG_ADDR]    reg2_rd_addr_i , // R2寄存器读地址
    
    output  reg [`INST_REG_DATA]    reg1_rd_data_o , // R1寄存器读数据
    output  reg [`INST_REG_DATA]    reg2_rd_data_o   // R2寄存器读数据
    
    );
    
    reg[`INST_REG_DATA]     regs[0 : `REG_NUM - 1];
    //ex写入优先级大于mem写入
    always @ (*) begin
        if(reg1_rd_addr_i == `ZERO_REG_ADDR) begin
            reg1_rd_data_o = `ZERO_WORD;
        end
        else begin 
		    if(ex_bypass1)begin
			reg1_rd_data_o = ex_wr_data_i ;
			end else if(mbem_bypass1)begin
			reg1_rd_data_o = mbem_wr_data_i ;
			end else if(mem_bypass1)begin
			reg1_rd_data_o = mem_wr_data_i ;
			end else if(wb_bypass1)begin
			reg1_rd_data_o = wr_data_i ;
			end else begin
			reg1_rd_data_o = regs[reg1_rd_addr_i] ;
			end
		end
    end
    
    always @ (*) begin
        if(reg2_rd_addr_i == `ZERO_REG_ADDR) begin
            reg2_rd_data_o = `ZERO_WORD;
        end
        else begin 
		    if(ex_bypass2)begin
			reg2_rd_data_o = ex_wr_data_i ;
			end else if(mbem_bypass2)begin
			reg2_rd_data_o = mbem_wr_data_i ;
			end else if(mem_bypass2)begin
			reg2_rd_data_o = mem_wr_data_i ;
			end else if(wb_bypass2)begin
			reg2_rd_data_o = wr_data_i ;
			end else begin
			reg2_rd_data_o = regs[reg2_rd_addr_i] ;
			end
		end
    end
    
    always @ (posedge clk) begin
        // 写使能有效并且写地址不为0
        if(wr_en_i == 1'b1 && wr_addr_i != `REG_ADDR_WIDTH'd0) begin
            regs[wr_addr_i] <= wr_data_i;
        end
    end
    
endmodule