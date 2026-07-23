`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/16 16:05:52
// Design Name: 
// Module Name: cu
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
(* keep_hierarchy="yes", optimize="off" *)
// 控制单元
module cu(

    input   wire                    clk                 ,
    input   wire                    rst_n               ,
    
    // 指令译码相关参数
    input   wire[`INST_ADDR_BUS]    ins_addr_i          , 
    input   wire[6:0]               opcode_i            ,
    input   wire[2:0]               funct3_i            ,
    input   wire[6:0]               funct7_i            ,
    input   wire[`INST_REG_DATA]    imm_i               ,  
    
    // 跳转和暂停流水线相关参数         
    output  reg                     jump_flag_o         ,
    output  reg [`INST_ADDR_BUS]    jump_addr_o         ,        
    output  reg                     hold_flag_o         ,

    // 寄存器相关参数（register�?
    input   wire[`INST_REG_DATA]    reg1_rd_data_i      , 
    input   wire[`INST_REG_DATA]    reg2_rd_data_i      ,
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
    output  reg                     reg_wr_en_o         ,
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  reg [`INST_REG_DATA]    reg_wr_data_o       ,
	input	wire[`INST_REG_ADDR]    reg1_rd_addr_i		,
	input	wire[`INST_REG_ADDR]    reg2_rd_addr_i		,
    
    output	reg                     not_mem					,
	output	reg                     keep_flag_o				,
	input	wire  					keep_flag_return		//回来对keep信号进行控制防止失控
    // csr_reg相关参数 
    
    );   
	(* dont_touch = "true", keep = "true" *)wire		reg_wr_addr_eq_reg1_rd_addr;
	(* dont_touch = "true", keep = "true" *)wire		reg_wr_addr_eq_reg2_rd_addr;
	assign reg_wr_addr_eq_reg1_rd_addr = (reg1_rd_addr_i == reg_wr_addr_i)?1'b1:1'b0;
	assign reg_wr_addr_eq_reg2_rd_addr = (reg2_rd_addr_i == reg_wr_addr_i)?1'b1:1'b0;
    //assign mem_wr_addr_o = mem_rd_addr_i;
    (* dont_touch = "true", keep = "true" *)wire         reg1_equal_reg2; //rs1_data == rs2_data   
    (* dont_touch = "true", keep = "true" *)wire         reg1_less_reg2_signed;
    (* dont_touch = "true", keep = "true" *)wire         reg1_less_reg2_unsigned;
    (* dont_touch = "true", keep = "true" *)wire[`INST_ADDR_BUS] branch_jump_addr;    
    
    assign       reg1_equal_reg2 = (reg1_rd_data_i == reg2_rd_data_i) ? 1'b1 : 1'b0;  
    assign       reg1_less_reg2_signed = ($signed(reg1_rd_data_i)<$signed(reg2_rd_data_i))?1'b1:1'b0;
    assign       reg1_less_reg2_unsigned = (reg1_rd_data_i < reg2_rd_data_i)?1'b1:1'b0;
    assign       branch_jump_addr = ins_addr_i + imm_i;	
    (* dont_touch = "true", keep = "true" *)wire    [31:0] jump_addr_branch = (ins_addr_i + imm_i);
    (* dont_touch = "true", keep = "true" *)wire    [31:0] add_1_imm = $signed(reg1_rd_data_i) + $signed(imm_i);
	(* dont_touch = "true", keep = "true" *)wire    [4:0] shamt = reg2_rd_data_i[4:0];
	(* dont_touch = "true", keep = "true" *)wire    [31:0] add_1_2   = $signed(reg1_rd_data_i) + $signed(reg2_rd_data_i);
	(* dont_touch = "true", keep = "true" *)wire    [31:0] sub_1_2    = $signed(reg1_rd_data_i) - $signed(reg2_rd_data_i);
	(* dont_touch = "true", keep = "true" *)wire    [31:0] slti_1_imm = {31'b0, $signed(reg1_rd_data_i) < $signed(imm_i)};
	(* dont_touch = "true", keep = "true" *)wire    [31:0] sltiu_1_imm = {31'b0, reg1_rd_data_i < imm_i};
	(* dont_touch = "true", keep = "true" *)wire    [31:0] xori_1_imm  = reg1_rd_data_i ^ imm_i;
	(* dont_touch = "true", keep = "true" *)wire    [31:0] ori_1_imm = reg1_rd_data_i | imm_i;
	(* dont_touch = "true", keep = "true" *)wire    [31:0] andi_1_imm = reg1_rd_data_i & imm_i;
	(* dont_touch = "true", keep = "true" *)wire    [31:0] slli_1_imm =reg1_rd_data_i << imm_i[4:0];
	(* dont_touch = "true", keep = "true" *)wire    [31:0] srli_1_imm = reg1_rd_data_i >> imm_i[4:0];
	(* dont_touch = "true", keep = "true" *)wire    [31:0] srai_1_imm = $signed(reg1_rd_data_i) >>> imm_i[4:0];
	(* dont_touch = "true", keep = "true" *)wire    [31:0] sll_1_2 = reg1_rd_data_i << reg2_rd_data_i[4:0];
	(* dont_touch = "true", keep = "true" *)wire    [31:0] slt_1_2 = {31'b0, $signed(reg1_rd_data_i) < $signed(reg2_rd_data_i)};
	(* dont_touch = "true", keep = "true" *)wire    [31:0] sltu_1_2 = {31'b0, reg1_rd_data_i < reg2_rd_data_i};
	(* dont_touch = "true", keep = "true" *)wire    [31:0] xor_1_2 = reg1_rd_data_i ^ reg2_rd_data_i;
	(* dont_touch = "true", keep = "true" *)wire    [31:0] srl_1_2 = reg1_rd_data_i >> reg2_rd_data_i[4:0];
	(* dont_touch = "true", keep = "true" *)wire    [31:0] sra_1_2 = $signed(reg1_rd_data_i) >>> reg2_rd_data_i[4:0];
	(* dont_touch = "true", keep = "true" *)wire    [31:0] or_1_2  = reg1_rd_data_i | reg2_rd_data_i;
	(* dont_touch = "true", keep = "true" *)wire    [31:0] and_1_2 = reg1_rd_data_i & reg2_rd_data_i;
    // 根据不同指令类型发出不同的控制信�?
    always @ (*) begin
        // 跳转相关
        jump_flag_o = 1'b0;
        jump_addr_o = `ZERO_WORD;
        hold_flag_o = 1'b0;
        
        // 寄存器相�?, 根据div_res_ready_i判断是否要写div计算结果到寄存器
        reg_wr_en_o =  1'b0;
        reg_wr_addr_o =  reg_wr_addr_i;
        reg_wr_data_o = 32'b0;
        

		not_mem = 1'b1;
		keep_flag_o = 1'b0;
        case(opcode_i) 
            // I型指�?
            `INS_TYPE_I: begin
                reg_wr_en_o = 1'b1;
                case(funct3_i)
                    `INS_ADDI: begin
                        reg_wr_data_o =add_1_imm;
                    end
                    `INS_SLTI: begin
                        reg_wr_data_o = slti_1_imm;
                    end
                    `INS_SLTIU: begin
                        reg_wr_data_o = sltiu_1_imm;
                    end
                    `INS_XORI: begin
                        reg_wr_data_o = xori_1_imm;
                    end
                    `INS_ORI: begin
                        reg_wr_data_o = ori_1_imm;
                    end
                    `INS_ANDI: begin
                        reg_wr_data_o = andi_1_imm;
                    end
                    `INS_SLLI: begin
                        reg_wr_data_o = slli_1_imm;
                    end
                    `INS_SRLI_SRAI: begin
                        if(funct7_i == 7'b000_0000) begin
                            reg_wr_data_o = srli_1_imm;
                        end
                        else if(funct7_i == 7'b010_0000) begin
                            reg_wr_data_o = srai_1_imm;
                        end
                    end
                endcase
            end
            // R和M型指�?
            `INS_TYPE_R_M: begin
                case({funct7_i,funct3_i}) 
                    `INS_ADD: begin
                        reg_wr_data_o = add_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SUB: begin
                        reg_wr_data_o = sub_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SLL: begin
                        reg_wr_data_o = sll_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SLT: begin
                        reg_wr_data_o = slt_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SLTU: begin
                        reg_wr_data_o = sltu_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_XOR: begin
                        reg_wr_data_o = xor_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SRL: begin
                        reg_wr_data_o = srl_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SRA: begin
                        reg_wr_data_o = sra_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_OR: begin
                        reg_wr_data_o = or_1_2;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_AND: begin
                        reg_wr_data_o = and_1_2;
                        reg_wr_en_o = 1'b1;
                    end
					default :begin
					end
				endcase
            end 
            `INS_LUI: begin
                reg_wr_en_o = 1'b1;
                reg_wr_data_o = add_1_imm;
            end
            `INS_AUIPC: begin
                reg_wr_en_o = 1'b1;
				reg_wr_data_o = jump_addr_branch;
            end
            // 无条件跳转指�?
            `INS_JAL: begin
                reg_wr_en_o = 1'b1;
                reg_wr_data_o = ins_addr_i + 4'd4;
                jump_flag_o = 1'b1;
                jump_addr_o = jump_addr_branch;
                hold_flag_o = 1'b1;
            end
            `INS_JALR: begin
                reg_wr_en_o = 1'b1;
                reg_wr_data_o = ins_addr_i + 4'd4;
                jump_flag_o = 1'b1;
                jump_addr_o = add_1_imm;
                hold_flag_o = 1'b1;
            end
            // 条件跳转指令
            `INS_TYPE_BRANCH: begin
                case(funct3_i)
                    `INS_BEQ: begin
                        //alu_op_code_o = `ALU_SUB;
                        jump_flag_o = reg1_equal_reg2 ? 1'b1 : 1'b0;
                        jump_addr_o = reg1_equal_reg2 ? jump_addr_branch : 32'b0;
                        hold_flag_o = reg1_equal_reg2 ? 1'b1 : 1'b0;
                    end
                    `INS_BNE: begin
                        //alu_op_code_o = `ALU_SUB;
                        jump_flag_o = !reg1_equal_reg2 ? 1'b1 : 1'b0;
                        jump_addr_o = !reg1_equal_reg2 ? jump_addr_branch: 32'b0;
                        hold_flag_o = !reg1_equal_reg2 ? 1'b1 : 1'b0;
                    end
                    `INS_BLT: begin
                        //alu_op_code_o = `ALU_SLT;
                        jump_flag_o = reg1_less_reg2_signed ? 1'b1 : 1'b0;
                        jump_addr_o = reg1_less_reg2_signed ? jump_addr_branch : 32'b0;
                        hold_flag_o = reg1_less_reg2_signed ? 1'b1 : 1'b0;
                    end
                    `INS_BGE: begin
                        //alu_op_code_o = `ALU_SLT;
                        jump_flag_o = !reg1_less_reg2_signed ? 1'b1 : 1'b0;
                        jump_addr_o = !reg1_less_reg2_signed ? jump_addr_branch: 32'b0;
                        hold_flag_o = !reg1_less_reg2_signed ? 1'b1 : 1'b0;
                    end
                    `INS_BLTU: begin
                        //alu_op_code_o = `ALU_SLTU;
                        jump_flag_o = reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                        jump_addr_o = reg1_less_reg2_unsigned ? jump_addr_branch : 32'b0;
                        hold_flag_o = reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                    end
                    `INS_BGEU: begin
                        //alu_op_code_o = `ALU_SLTU;
                        jump_flag_o = !reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                        jump_addr_o = !reg1_less_reg2_unsigned ? jump_addr_branch: 32'b0;
                        hold_flag_o = !reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                    end
                    default: begin
                    end
                endcase
            end
            // 访存指令
            `INS_TYPE_SAVE: begin 
                not_mem = 1'b0;
				reg_wr_en_o = 1'b0;
            end
            `INS_TYPE_LOAD: begin
                not_mem = 1'b0;
				keep_flag_o = 1'b0;
				reg_wr_en_o = 1'b0;
                case({reg_wr_addr_eq_reg1_rd_addr,reg_wr_addr_eq_reg2_rd_addr})
                    2'b10, 2'b01:
                    begin
                        keep_flag_o = (1'b1 & (~keep_flag_return));
                    end
                    default:
                    begin
						keep_flag_o = 1'b0;
                    end
                endcase
            end
            default: begin
            
            end
        endcase
    end
    
endmodule
