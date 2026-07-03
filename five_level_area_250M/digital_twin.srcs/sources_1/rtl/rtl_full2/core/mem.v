`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/16 16:05:52
// Design Name: 
// Module Name: MEM_UNIT
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
module mem
(

	//from EX_UNIT 
	//1、访存相�? 2、写入相�?
	//写入相关
	
    input   wire[`INST_REG_DATA]    reg2_rd_data_i      ,
	output  wire[`INST_REG_DATA]    reg2_rd_data_o      ,
	
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
	input	wire[`INST_REG_DATA]    reg_wr_data_i       ,
    input   wire                    reg_wr_en_i         ,
    output  wire                    reg_wr_en_o         ,
    output  wire[`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  wire[`INST_REG_DATA]    reg_wr_data_o       ,
	//访存相关
	input   wire[2:0]               funct3_i            , 
	output  wire[2:0]               funct3_o            ,
	input	wire					is_load_i			,
	input	wire					is_save_i			,
	output  wire                    is_load_o           ,
	output  wire                    is_save_o           ,
	input	wire					keep_flag_control	,
	//li	ra,0x10000000
	//lw	t5,0(ra)
	//addi	ra,t5,255
	input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
    //input   wire[`INST_DATA_BUS]    mem_rd_data_i       ,//from rib
    //output  reg                     mem_wr_rib_req_o    ,
    //output  reg                     mem_wr_en_o         , 
    //output  wire[`INST_ADDR_BUS]    mem_wr_addr_o       , 
    //output  reg [`INST_DATA_BUS]    mem_wr_data_o       
	output  wire[`INST_ADDR_BUS]    mem_rd_addr_o
	

);
//wire [1:0]	op;
assign mem_rd_addr_o = mem_rd_addr_i;
assign reg_wr_addr_o = reg_wr_addr_i;
assign reg_wr_data_o = reg_wr_data_i;
assign reg_wr_en_o   = reg_wr_en_i &(~keep_flag_control) ;
assign is_load_o     = is_load_i    ;
assign is_save_o     = is_save_i    ;
assign funct3_o      = funct3_i     ;

/* assign op = {is_load_i , is_save_i};
	always@(*)begin
        // 访存相关
        mem_wr_rib_req_o = 1'b0;
        mem_wr_en_o = 1'b0;
        mem_wr_data_o = `ZERO_WORD;
        case(op)
		2'b01:begin//load
		    reg_wr_en_o = 1'b0;
            mem_wr_rib_req_o = 1'b1;
            mem_wr_en_o = 1'b1;
            reg_wr_data_o = 32'b0;
			case(funct3_i)
                `INS_SB: begin
                    case(mem_wr_addr_o[1:0])
                        2'b00: begin
                            mem_wr_data_o = {mem_rd_data_i[31:8],reg2_rd_data_i[7:0]};
                        end
                        2'b01: begin
                            mem_wr_data_o = {mem_rd_data_i[31:16],reg2_rd_data_i[7:0],mem_rd_data_i[7:0]};
                        end
                        2'b10: begin
                            mem_wr_data_o = {mem_rd_data_i[31:24],reg2_rd_data_i[7:0],mem_rd_data_i[15:0]};
                        end
                        2'b11: begin
                            mem_wr_data_o = {reg2_rd_data_i[7:0],mem_rd_data_i[23:0]};
                        end
                    endcase
                end
                `INS_SH: begin
                    if(mem_wr_addr_o[1:0] == 2'b00) begin
                        mem_wr_data_o = {mem_rd_data_i[31:16],reg2_rd_data_i[15:0]};
                    end
                    else begin
                        mem_wr_data_o = {reg2_rd_data_i[15:0],mem_rd_data_i[15:0]};
                    end
                end
                `INS_SW: begin
                    mem_wr_data_o = reg2_rd_data_i;
                end
                default: begin
                    mem_wr_data_o = reg2_rd_data_i;
                end
            endcase
		end
		2'b10:begin//save
			reg_wr_en_o = ((1'b1) & (~keep_flag_control));
			//reg_wr_en_o = ((1'b1) );
            case(funct3_i)
                `INS_LB: begin
                    case(mem_rd_addr_i[1:0])
                        2'b00: begin
                            reg_wr_data_o = {{24{mem_rd_data_i[7]}}, mem_rd_data_i[7:0]};
                        end
                        2'b01: begin
                            reg_wr_data_o = {{24{mem_rd_data_i[15]}}, mem_rd_data_i[15:8]};
                        end
                        2'b10: begin
                            reg_wr_data_o = {{24{mem_rd_data_i[23]}}, mem_rd_data_i[23:16]};
                        end
                        2'b11: begin
                            reg_wr_data_o = {{24{mem_rd_data_i[31]}}, mem_rd_data_i[31:24]};
                        end
                    endcase
                end
                `INS_LH: begin
                    if(mem_rd_addr_i[1:0] == 2'b00) begin
                        reg_wr_data_o = {{16{mem_rd_data_i[15]}}, mem_rd_data_i[15:0]};
                    end
                    else begin
                        reg_wr_data_o = {{16{mem_rd_data_i[31]}}, mem_rd_data_i[31:16]};
                    end
                end
                `INS_LW: begin
                    reg_wr_data_o = mem_rd_data_i;
                end
                `INS_LBU: begin
                    case(mem_rd_addr_i[1:0])
                        2'b00: begin
                            reg_wr_data_o = {{24{1'b0}}, mem_rd_data_i[7:0]};
                        end
                        2'b01: begin
                            reg_wr_data_o = {{24{1'b0}}, mem_rd_data_i[15:8]};
                        end
                        2'b10: begin
                            reg_wr_data_o = {{24{1'b0}}, mem_rd_data_i[23:16]};
                        end
                        2'b11: begin
                            reg_wr_data_o = {{24{1'b0}}, mem_rd_data_i[31:24]};
                        end
                    endcase
                end
                `INS_LHU: begin
                    if(mem_rd_addr_i[1:0] == 2'b00) begin
                        reg_wr_data_o = {{16{1'b0}}, mem_rd_data_i[15:0]};
                    end
                    else begin
                        reg_wr_data_o = {{16{1'b0}}, mem_rd_data_i[31:16]};
                    end
                end
                default: begin
                    reg_wr_data_o = mem_rd_data_i;
                end
            endcase
		end
		default:begin//如果非save非load那就是ex模块执行�?
		    reg_wr_en_o   = reg_wr_en_i;
		    reg_wr_data_o = reg_wr_data_i;
		end
		endcase


	end
 */
endmodule