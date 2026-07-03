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

// 浮点运算指令
`define INS_TYPE_FP  7'b101_0011
// FP类，funct7+funct3
`define INS_ADD_FP     10'b00_0000_0000
`define INS_SUB_FP     10'b00_0010_0000
`define INS_MUL_FP     10'b00_0100_0000
`define INS_DIV_FP     10'b00_0110_0000
`define INS_FMVSX_FP   10'b11_1100_0000
`define INS_FMVXS_FP   10'b11_1000_0000
`define INS_TYPE_FLW  7'b000_0111
`define INS_TYPE_FSW  7'b010_0111
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
    input   wire[`INST_REG_DATA]    reg1_rd_data_fp_i      , 
    input   wire[`INST_REG_DATA]    reg2_rd_data_fp_i      ,
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
    output  reg                     reg_wr_en_o         ,
    output  reg                     reg_wr_en_fp_o         ,
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  reg [`INST_REG_DATA]    reg_wr_data_o       ,
    output  reg [`INST_REG_DATA]    reg_wr_data_fp_o       ,    
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
    
    //fpu相关
    reg        a_sign;
    reg        b_sign;
    reg        new_b_sign;  
    reg [8:0]  a_exp;
    reg [8:0]  b_exp;
    reg [48:0] a_man;
    reg [48:0] b_man;
    reg         result_sign;
    reg  [8:0]  result_exp;
    reg  [48:0] result_man;
    reg [8:0]  exp_diff;
    reg [7:0]  abs_exp_diff;
    reg [48:0] larger_man;
    reg [48:0] smaller_man; 
    reg [48:0] new_smaller_man;
    
    wire [31:0] add_sub_result_fp;
    wire [1:0]  fp_add_sub_sel = funct7_i[3:2];  //00:add 01:sub
    
    wire        normalized_result_sign;
    wire [8:0]  normalized_result_exp ;
    wire [48:0] normalized_result_man ;
    wire        rounded_result_sign   ;
    wire [8:0]  rounded_result_exp    ;
    wire [24:0] rounded_result_man    ;   
    
    //wire         alu_out_sign;
    //wire  [7:0]  alu_out_exp;
    //wire  [22:0] alu_out_man;     
    
    //assign alu_out_sign = result_sign;
    //assign alu_out_exp  = result_exp[7:0];
    //assign alu_out_man  = result_man[48:24];
    //assign add_sub_result_fp = {alu_out_sign, alu_out_exp, alu_out_man};
    
    always@(*) begin   
        a_sign = reg1_rd_data_fp_i[31];
        a_exp  = {1'b0,reg1_rd_data_fp_i[30:23]};
        b_sign = reg2_rd_data_fp_i[31];
        b_exp  = {1'b0,reg2_rd_data_fp_i[30:23]};

    //if exp of input is equal to 8'b0, add hidden bit = 0 before mantissa. If not, add 1
        a_man  = {1'b0,|a_exp,reg1_rd_data_fp_i[22:0],24'b0}; 
        b_man  = {1'b0,|b_exp,reg2_rd_data_fp_i[22:0],24'b0};
 
    
  
    //compare two floating point number and match exponent
        new_b_sign = b_sign ^ |fp_add_sub_sel;
        
        if(a_exp == b_exp) begin
            if(a_man == b_man) begin
                result_sign = a_sign;
                result_exp  = a_exp;
                larger_man  = a_man;
                smaller_man = b_man;
            end
            else if (a_man > b_man) begin
                result_sign = a_sign;
                result_exp  = a_exp;
                larger_man  = a_man;
                smaller_man = b_man;
            end
            else begin
                result_sign = new_b_sign;
                result_exp  = a_exp;
                larger_man  = b_man;
                smaller_man = a_man;
            end  
        end  
        else if(a_exp > b_exp) begin
            result_sign = a_sign;
            result_exp  = a_exp;
            larger_man  = a_man;
            smaller_man = b_man; 
        end
        else begin
            result_sign = new_b_sign;
            result_exp  = b_exp;
            larger_man  = b_man;
            smaller_man = a_man;
        end
    end
      
    //shift mantissa of smaller number after match exponent  
    always@(*) begin     
        exp_diff  = $signed(a_exp)-$signed(b_exp) ;
        if (exp_diff[8]) begin
            abs_exp_diff = 8'b0 - exp_diff[7:0];
        end
        else begin
            abs_exp_diff = exp_diff[7:0];
        end

        new_smaller_man = smaller_man >> abs_exp_diff;
    end
    
    //add or subtract two fp numbers
    always@(*) begin
        if (a_sign == new_b_sign) begin
            result_man = larger_man + new_smaller_man;//同号相加
        end
        else begin
            result_man = larger_man - new_smaller_man;//异号相减
        end
    end    
    
    
    

    normalizer_1 u_normalization_1(
      .result_sign           (result_sign),
      .result_exp            (result_exp),
      .result_man            (result_man),
      //.done_cal              (done_cal_1),
      .normalized_result_sign(normalized_result_sign),
      .normalized_result_exp (normalized_result_exp),
      .normalized_result_man (normalized_result_man)
      //.overflow              (overflow),
      //.underflow             (underflow),
      //.done_cal_out          (done_cal_2)
   );
//===================ROUNDING=============================================   
   
   
    rounding u_round(
      .normalized_result_sign(normalized_result_sign),
      .normalized_result_exp (normalized_result_exp),
      .normalized_result_man (normalized_result_man),
      //.done_cal              (done_cal_2),
      .rounded_result_sign   (rounded_result_sign),
      .rounded_result_exp    (rounded_result_exp),
      .rounded_result_man    (rounded_result_man),
      //.done_cal_out          (done_cal_3),
      .round_flag            (round_flag)
   );
   
    normalizer_2 u_normalization_2 (
      .rounded_result_sign   (rounded_result_sign),
      .rounded_result_exp    (rounded_result_exp),
      .rounded_result_man    (rounded_result_man),
      .round_flag            (round_flag),
      //.done_cal              (done_cal_3),
      .alu_out               (add_sub_result_fp)
      //.done_cal_out          (done_cal),
      //.normalized_round_done (normalized_round_done)
   );  
  
    
    // 根据不同指令类型发出不同的控制信�?
    always @ (*) begin
        // 跳转相关
        jump_flag_o = 1'b0;
        jump_addr_o = `ZERO_WORD;
        hold_flag_o = 1'b0;
        
        // 寄存器相�?, 根据div_res_ready_i判断是否要写div计算结果到寄存器
        reg_wr_en_o =  1'b0;
        reg_wr_en_fp_o =  1'b0;
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
            `INS_TYPE_SAVE,`INS_TYPE_FSW: begin 
                not_mem = 1'b0;
				reg_wr_en_o = 1'b0;
				reg_wr_en_fp_o = 1'b0;
            end
            `INS_TYPE_LOAD,`INS_TYPE_FLW: begin
                not_mem = 1'b0;
				keep_flag_o = 1'b0;
				reg_wr_en_o = 1'b0;
				reg_wr_en_fp_o = 1'b0;
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
            
            `INS_TYPE_FP: begin
                case({funct7_i,funct3_i}) 
                `INS_ADD_FP,`INS_SUB_FP:begin
                    reg_wr_data_fp_o = add_sub_result_fp;
                    reg_wr_en_fp_o = 1'b1;                 
                end
                `INS_FMVSX_FP:begin
                    reg_wr_data_fp_o = reg1_rd_data_i;
                    reg_wr_en_fp_o = 1'b1;                 
                end                 
                
                endcase
            end
        
            default: begin
            
            end
        endcase
    end
    
endmodule
