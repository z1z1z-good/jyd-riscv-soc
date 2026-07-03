`timescale 1ns / 1ps
`include "defines.v"

// 控制单元
module ex(

    input   wire                    clk                 ,
    input   wire                    rst_n               ,
    
    // 指令译码相关参数
    input   wire[`INST_ADDR_BUS]    instr_addr_i          , 
    input   wire[6:0]               opcode_i            ,
    input   wire[2:0]               funct3_i            ,
    input   wire[6:0]               funct7_i            ,
    input   wire[`INST_REG_DATA]    imm_i               ,  
    
    // alu相关参数
    input   wire[`INST_REG_DATA]    alu_res_i           ,
    input   wire                    alu_zero_flag_i     ,
    input   wire                    alu_sign_flag_i     ,
    input   wire                    alu_overflow_flag_i ,
    output  reg [3:0]               alu_op_code_o       ,
    output  reg [`INST_REG_DATA]    alu_data1_o         , 
    output  reg [`INST_REG_DATA]    alu_data2_o         ,
    
    // mul相关参数
    input   wire[`INST_DB_REG_DATA] mul_res_i           ,   
    output  reg [2:0]               mul_op_code_o       ,       

    // div相关参数
    input   wire[`INST_REG_DATA]    div_res_i           ,   
    input   wire                    div_res_ready_i     ,
    input   wire[`INST_REG_ADDR]    div_reg_wr_addr_i   , 
    output  reg                     div_req_o           , 
    output  reg [2:0]               div_op_code_o       ,       
    
    // 跳转和暂停流水线相关参数         
    output  reg                     jump_flag_o         ,
    output  reg [`INST_ADDR_BUS]    jump_addr_o         ,        
    output  reg                     hold_flag_o         ,

    // 寄存器相关参数（register）
    input   wire[`INST_REG_DATA]    reg1_rd_data_i      , 
    input   wire[`INST_REG_DATA]    reg2_rd_data_i      ,
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
    output  reg                     reg_wr_en_o         ,
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  reg [`INST_REG_DATA]    reg_wr_data_o       ,
	input	wire[`INST_REG_ADDR]    reg1_rd_addr_i		,
	input	wire[`INST_REG_ADDR]    reg2_rd_addr_i		,
    
    // 访存相关参数
    //input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
    //input   wire[`INST_DATA_BUS]    mem_rd_data_i       ,
    //output  reg                     mem_wr_rib_req_o    ,
    //output  reg                     mem_wr_en_o         , 
    //output  wire[`INST_ADDR_BUS]    mem_wr_addr_o       , 
    //output  reg [`INST_DATA_BUS]    mem_wr_data_o       ,
    output	reg                     not_mem					,
	output	reg                     keep_flag_o				,
	input	wire  					keep_flag_return		,//回来对keep信号进行控制防止失控
    // csr_reg相关参数 
    input   wire[`INST_ADDR_BUS]    csr_rw_addr_i       ,
    input   wire[`INST_REG_DATA]    csr_zimm_i          ,
    input   wire[`INST_REG_DATA]    csr_rd_data_i       ,
    output  reg                     csr_wr_en_o         , 
    output  reg [`INST_ADDR_BUS]    csr_wr_addr_o       , 
    output  reg [`INST_REG_DATA]    csr_wr_data_o       , 
    output  reg [`INST_ADDR_BUS]    csr_rd_addr_o       
    
    );
    wire		reg_wr_addr_eq_reg1_rd_addr;
	wire		reg_wr_addr_eq_reg2_rd_addr;
	assign reg_wr_addr_eq_reg1_rd_addr = (reg1_rd_addr_i == reg_wr_addr_i)?1'b1:1'b0;
	assign reg_wr_addr_eq_reg2_rd_addr = (reg2_rd_addr_i == reg_wr_addr_i)?1'b1:1'b0;
    //assign mem_wr_addr_o = mem_rd_addr_i;
    wire         reg1_equal_reg2; //rs1_data == rs2_data   
    wire         reg1_less_reg2_signed;
    wire         reg1_less_reg2_unsigned;
    wire[`INST_ADDR_BUS] branch_jump_addr;    
    
    assign       reg1_equal_reg2 = (reg1_rd_data_i == reg2_rd_data_i) ? 1'b1 : 1'b0;  
    assign       reg1_less_reg2_signed = ($signed(reg1_rd_data_i)<$signed(reg2_rd_data_i))?1'b1:1'b0;
    assign       reg1_less_reg2_unsigned = (reg1_rd_data_i < reg2_rd_data_i)?1'b1:1'b0;
    assign       branch_jump_addr = instr_addr_i + imm_i;	
    
    
    // 根据不同指令类型发出不同的控制信号
    always @ (*) begin
        // alu计算相关
        alu_op_code_o = 4'd0;
        alu_data1_o = `ZERO_WORD;
        alu_data2_o = `ZERO_WORD;
        
        // mul、div计算相关
        mul_op_code_o = 3'd0;
        div_op_code_o = 3'd0;
        div_req_o = 1'b0;
        
        // 跳转相关
        jump_flag_o = 1'b0;
        jump_addr_o = `ZERO_WORD;
        hold_flag_o = 1'b0;
        
        // 寄存器相关, 根据div_res_ready_i判断是否要写div计算结果到寄存器
        reg_wr_en_o = div_res_ready_i ? 1'b1 : 1'b0;
        reg_wr_addr_o = div_res_ready_i ? div_reg_wr_addr_i : reg_wr_addr_i;
        reg_wr_data_o = div_res_ready_i ? div_res_i : alu_res_i;
        
        // 访存相关
        //mem_wr_rib_req_o = 1'b0;
        //mem_wr_en_o = 1'b0;
        //mem_wr_data_o = `ZERO_WORD;
        
        // csr_reg相关
        csr_wr_en_o = 1'b0;
        csr_wr_addr_o = `ZERO_WORD;
        csr_wr_data_o = `ZERO_WORD;
        csr_rd_addr_o = `ZERO_WORD;

		not_mem = 1'b1;
		keep_flag_o = 1'b0;
        case(opcode_i) 
            // I型指令
            `INS_TYPE_I: begin
                reg_wr_en_o = 1'b1;
                alu_data1_o = reg1_rd_data_i;
                alu_data2_o = imm_i;
                case(funct3_i)
                    `INS_ADDI: begin
                        alu_op_code_o = `ALU_ADD;
                    end
                    `INS_SLTI: begin
                        alu_op_code_o = `ALU_SLT;
                    end
                    `INS_SLTIU: begin
                        alu_op_code_o = `ALU_SLTU;
                    end
                    `INS_XORI: begin
                        alu_op_code_o = `ALU_XOR;
                    end
                    `INS_ORI: begin
                        alu_op_code_o = `ALU_OR;
                    end
                    `INS_ANDI: begin
                        alu_op_code_o = `ALU_AND;
                    end
                    `INS_SLLI: begin
                        alu_op_code_o = `ALU_SLL;
                    end
                    `INS_SRLI_SRAI: begin
                        if(funct7_i == 7'b000_0000) begin
                            alu_op_code_o = `ALU_SRL;
                        end
                        else if(funct7_i == 7'b010_0000) begin
                            alu_op_code_o = `ALU_SRA;
                        end
                    end
                endcase
            end
            // R和M型指令
            `INS_TYPE_R_M: begin
                case({funct7_i,funct3_i}) 
                    `INS_ADD: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_ADD;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SUB: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_SUB;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SLL: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_SLL;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SLT: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_SLT;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SLTU: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_SLTU;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_XOR: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_XOR;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SRL: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_SRL;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_SRA: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_SRA;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_OR: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_OR;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_AND: begin
                        alu_data1_o = reg1_rd_data_i;
                        alu_data2_o = reg2_rd_data_i;
                        alu_op_code_o = `ALU_AND;
                        reg_wr_en_o = 1'b1;
                    end
                    `INS_MUL: begin
                        mul_op_code_o = `MUL;
                        reg_wr_en_o = 1'b1;
                        reg_wr_data_o = mul_res_i[31:0];
                    end
                    `INS_MULH: begin
                        mul_op_code_o = `MUL;
                        reg_wr_en_o = 1'b1;
                        reg_wr_data_o = mul_res_i[63:32];
                    end
                    `INS_MULHSU: begin
                        mul_op_code_o = `MULSU;
                        reg_wr_en_o = 1'b1;
                        reg_wr_data_o = mul_res_i[63:32];
                    end
                    `INS_MULHU: begin
                        mul_op_code_o = `MULU;
                        reg_wr_en_o = 1'b1;
                        reg_wr_data_o = mul_res_i[63:32];
                    end
                    // 因为div指令需要暂停流水线，所以执行完后需要跳回div的下一条指令继续执行
                    `INS_DIV: begin
                        jump_flag_o = 1'b1;
                        jump_addr_o = instr_addr_i + 4'd4;
                        hold_flag_o = 1'b1;
                        div_op_code_o = `DIV;
                        div_req_o = 1'b1;
                    end
                    `INS_DIVU: begin
                        jump_flag_o = 1'b1;
                        jump_addr_o = instr_addr_i + 4'd4;
                        hold_flag_o = 1'b1;
                        div_op_code_o = `DIVU;
                        div_req_o = 1'b1;
                    end
                    `INS_REM: begin
                        jump_flag_o = 1'b1;
                        jump_addr_o = instr_addr_i + 4'd4;
                        hold_flag_o = 1'b1;
                        div_op_code_o = `REM;
                        div_req_o = 1'b1;
                    end
                    `INS_REMU: begin
                        jump_flag_o = 1'b1;
                        jump_addr_o = instr_addr_i + 4'd4;
                        hold_flag_o = 1'b1;
                        div_op_code_o = `REMU;
                        div_req_o = 1'b1;
                    end
                    default: begin 
                    end
                endcase
            end 
            `INS_LUI: begin
                reg_wr_en_o = 1'b1;
                alu_data1_o = reg1_rd_data_i;
                alu_data2_o = imm_i;
                alu_op_code_o = `ALU_ADD;
            end
            `INS_AUIPC: begin
                reg_wr_en_o = 1'b1;
                alu_data1_o = instr_addr_i;
                alu_data2_o = imm_i;
                alu_op_code_o = `ALU_ADD;
            end
            // 无条件跳转指令
            `INS_JAL: begin
                reg_wr_en_o = 1'b1;
                reg_wr_data_o = instr_addr_i + 4'd4;
                alu_data1_o = instr_addr_i;
                alu_data2_o = imm_i;
                alu_op_code_o = `ALU_ADD;
                jump_flag_o = 1'b1;
                jump_addr_o = alu_res_i;
                hold_flag_o = 1'b1;
            end
            `INS_JALR: begin
                reg_wr_en_o = 1'b1;
                reg_wr_data_o = instr_addr_i + 4'd4;
                alu_data1_o = reg1_rd_data_i;
                alu_data2_o = imm_i;
                alu_op_code_o = `ALU_ADD;
                jump_flag_o = 1'b1;
                jump_addr_o = alu_res_i;
                hold_flag_o = 1'b1;
            end
            // 条件跳转指令
            `INS_TYPE_BRANCH: begin
                //alu_data1_o = reg1_rd_data_i;
                //alu_data2_o = reg2_rd_data_i;
                case(funct3_i)
                    `INS_BEQ: begin
                        //alu_op_code_o = `ALU_SUB;
                        jump_flag_o = reg1_equal_reg2 ? 1'b1 : 1'b0;
                        jump_addr_o = reg1_equal_reg2 ? (instr_addr_i + imm_i) : alu_res_i;
                        hold_flag_o = reg1_equal_reg2 ? 1'b1 : 1'b0;
                    end
                    `INS_BNE: begin
                        //alu_op_code_o = `ALU_SUB;
                        jump_flag_o = !reg1_equal_reg2 ? 1'b1 : 1'b0;
                        jump_addr_o = !reg1_equal_reg2 ? (instr_addr_i + imm_i) : alu_res_i;
                        hold_flag_o = !reg1_equal_reg2 ? 1'b1 : 1'b0;
                    end
                    `INS_BLT: begin
                        //alu_op_code_o = `ALU_SLT;
                        jump_flag_o = reg1_less_reg2_signed ? 1'b1 : 1'b0;
                        jump_addr_o = reg1_less_reg2_signed ? (instr_addr_i + imm_i) : alu_res_i;
                        hold_flag_o = reg1_less_reg2_signed ? 1'b1 : 1'b0;
                    end
                    `INS_BGE: begin
                        //alu_op_code_o = `ALU_SLT;
                        jump_flag_o = !reg1_less_reg2_signed ? 1'b1 : 1'b0;
                        jump_addr_o = !reg1_less_reg2_signed ? (instr_addr_i + imm_i) : alu_res_i;
                        hold_flag_o = !reg1_less_reg2_signed ? 1'b1 : 1'b0;
                    end
                    `INS_BLTU: begin
                        //alu_op_code_o = `ALU_SLTU;
                        jump_flag_o = reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                        jump_addr_o = reg1_less_reg2_unsigned ? (instr_addr_i + imm_i) : alu_res_i;
                        hold_flag_o = reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                    end
                    `INS_BGEU: begin
                        //alu_op_code_o = `ALU_SLTU;
                        jump_flag_o = !reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                        jump_addr_o = !reg1_less_reg2_unsigned ? (instr_addr_i + imm_i) : alu_res_i;
                        hold_flag_o = !reg1_less_reg2_unsigned ? 1'b1 : 1'b0;
                    end
                    default: begin
                    end
                endcase
            end
            // 访存指令
            `INS_TYPE_SAVE: begin 
                not_mem = 1'b0;
            end
            `INS_TYPE_LOAD: begin
                not_mem = 1'b0;
				keep_flag_o = 1'b0;
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
            // csr操作指令
            `INS_TYPE_CSR: begin
                case(funct3_i)
                    `INS_CSRRW: begin
                        reg_wr_en_o = 1'b1;
                        csr_rd_addr_o = csr_rw_addr_i;
                        reg_wr_data_o = csr_rd_data_i;
                        csr_wr_en_o = 1'b1;
                        csr_wr_addr_o = csr_rw_addr_i;
                        csr_wr_data_o = reg1_rd_data_i;
                    end
                    `INS_CSRRS: begin
                        reg_wr_en_o = 1'b1;
                        csr_rd_addr_o = csr_rw_addr_i;
                        reg_wr_data_o = csr_rd_data_i;
                        csr_wr_en_o = 1'b1;
                        csr_wr_addr_o = csr_rw_addr_i;
                        csr_wr_data_o = csr_rd_data_i | reg1_rd_data_i;
                    end
                    `INS_CSRRC: begin
                        reg_wr_en_o = 1'b1;
                        csr_rd_addr_o = csr_rw_addr_i;
                        reg_wr_data_o = csr_rd_data_i;
                        csr_wr_en_o = 1'b1;
                        csr_wr_addr_o = csr_rw_addr_i;
                        csr_wr_data_o = csr_rd_data_i & (~reg1_rd_data_i);
                    end
                    `INS_CSRRWI: begin
                        reg_wr_en_o = 1'b1;
                        csr_rd_addr_o = csr_rw_addr_i;
                        reg_wr_data_o = csr_rd_data_i;
                        csr_wr_en_o = 1'b1;
                        csr_wr_addr_o = csr_rw_addr_i;
                        csr_wr_data_o = csr_zimm_i;
                    end
                    `INS_CSRRSI: begin
                        reg_wr_en_o = 1'b1;
                        csr_rd_addr_o = csr_rw_addr_i;
                        reg_wr_data_o = csr_rd_data_i;
                        csr_wr_en_o = 1'b1;
                        csr_wr_addr_o = csr_rw_addr_i;
                        csr_wr_data_o = csr_rd_data_i | csr_zimm_i;
                    end
                    `INS_CSRRCI:begin
                        reg_wr_en_o = 1'b1;
                        csr_rd_addr_o = csr_rw_addr_i;
                        reg_wr_data_o = csr_rd_data_i;
                        csr_wr_en_o = 1'b1;
                        csr_wr_addr_o = csr_rw_addr_i;
                        csr_wr_data_o = csr_rd_data_i & (~csr_zimm_i);
                    end
                    default: begin
                        
                    end
                endcase
            end
            default: begin
            
            end
        endcase
    end
    
endmodule
