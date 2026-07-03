`timescale 1ns / 1ps
`include "defines.v"

//指令译码模块
module id(

    input   wire                    clk            ,
    input   wire                    rst_n          ,
    
    //从IF模块传来的指令和指令地址
    input   wire[`INST_DATA_BUS]    instr_i          , 
    input   wire[`INST_ADDR_BUS]    instr_addr_i     , 
    
    output  wire[`INST_DATA_BUS]    instr_o          ,     
    
    // 传给RF模块的寄存器地址，用于取数据
    output  reg [`INST_REG_ADDR]    reg1_rd_addr_o , 
    output  reg [`INST_REG_ADDR]    reg2_rd_addr_o ,
    
    // 写寄存器地址
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o  ,
    
    // 立即数
    output  reg [`INST_REG_DATA]    imm_o          ,
    
    // 内存读取标志位
    //output  reg                     mem_rd_flag_o  ,
    
    // csr指令相关参数
    output  reg [`INST_ADDR_BUS]    csr_rw_addr_o  ,
    output  reg [`INST_REG_DATA]    csr_zimm_o
    
    );
    
    assign instr_o    = instr_i;
    
    // R类指令涉及到的三个寄存器
    wire[4:0]       rs1;
    wire[4:0]       rs2;
    wire[4:0]       rd;
    assign rs1 = instr_i[19:15];
    assign rs2 = instr_i[24:20];
    assign rd = instr_i[11:7];
    
    // R类指令可以根据下列三个参数确定
    wire [6:0]      opcode;
    wire [2:0]      funct3;
    //wire [6:0]      funct7;
    assign opcode = instr_i[6:0];
    assign funct3 = instr_i[14:12];
    //assign funct7 = instr_i[31:25];
    
    
    // 开始译码
    always @ (*) begin
        //mem_rd_flag_o = 1'b0;
        csr_rw_addr_o = `ZERO_WORD;
        csr_zimm_o = `ZERO_WORD;
        
        case(opcode) 
            `INS_TYPE_I: begin
                reg1_rd_addr_o = rs1;
                reg2_rd_addr_o = `ZERO_REG_ADDR;
                reg_wr_addr_o = rd;
                case(funct3)
                    `INS_ADDI,`INS_SLTI,`INS_SLTIU,`INS_XORI,`INS_ORI,`INS_ANDI: begin
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]}; // 符号位拓展
                    end
                    `INS_SLLI,`INS_SRLI_SRAI: begin
                        imm_o = {{27{1'b0}}, instr_i[24:20]};
                    end
                endcase
            end
            `INS_TYPE_R_M: begin
                reg1_rd_addr_o = rs1;
                reg2_rd_addr_o = rs2;
                reg_wr_addr_o = rd;
                imm_o = `ZERO_WORD;
            end   
            `INS_LUI,`INS_AUIPC: begin
                reg1_rd_addr_o = `ZERO_REG_ADDR;
                reg2_rd_addr_o = `ZERO_REG_ADDR;
                reg_wr_addr_o = rd;
                imm_o = {instr_i[31:12], {12{1'b0}}};
            end
            `INS_JAL: begin
                reg1_rd_addr_o = `ZERO_REG_ADDR;
                reg2_rd_addr_o = `ZERO_REG_ADDR;
                reg_wr_addr_o = rd;
                imm_o = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
            end
            `INS_JALR: begin
                reg1_rd_addr_o = rs1;
                reg2_rd_addr_o = `ZERO_REG_ADDR;
                reg_wr_addr_o = rd;
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]}; // 因为立即数是补码，所以需要符号位拓展
            end
            `INS_TYPE_BRANCH: begin
                reg1_rd_addr_o = rs1;
                reg2_rd_addr_o = rs2;
                reg_wr_addr_o = `ZERO_REG_ADDR;
                imm_o = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0}; // 因为立即数是补码，所以需要符号位拓展
            end
            `INS_TYPE_SAVE: begin
                reg1_rd_addr_o = rs1;
                reg2_rd_addr_o = rs2;
                reg_wr_addr_o = `ZERO_REG_ADDR;
                imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]}; // 因为立即数是补码，所以需要符号位拓展
                //mem_rd_flag_o = 1'b1;
            end
            `INS_TYPE_LOAD: begin
                reg1_rd_addr_o = rs1;
                reg2_rd_addr_o = `ZERO_REG_ADDR;
                reg_wr_addr_o = rd;
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]}; // 因为立即数是补码，所以需要符号位拓展
                //mem_rd_flag_o = 1'b1;
            end
            `INS_TYPE_CSR: begin
                case(funct3)
                    `INS_CSRRW,`INS_CSRRS,`INS_CSRRC: begin
                        reg1_rd_addr_o = rs1;
                        reg2_rd_addr_o = `ZERO_REG_ADDR;
                        reg_wr_addr_o = rd;
                        imm_o = `ZERO_WORD;
                        csr_rw_addr_o = {20'h0, instr_i[31:20]};
                        csr_zimm_o = `ZERO_WORD;
                    end
                    `INS_CSRRWI,`INS_CSRRSI,`INS_CSRRCI:begin
                        reg1_rd_addr_o = `ZERO_REG_ADDR;
                        reg2_rd_addr_o = `ZERO_REG_ADDR;
                        reg_wr_addr_o = rd;
                        imm_o = `ZERO_WORD;
                        csr_rw_addr_o = {20'h0, instr_i[31:20]};
                        csr_zimm_o = {27'h0, instr_i[19:15]};
                    end
                    default: begin
                        reg1_rd_addr_o = `ZERO_REG_ADDR;
                        reg2_rd_addr_o = `ZERO_REG_ADDR;
                        reg_wr_addr_o = `ZERO_REG_ADDR;
                        imm_o = `ZERO_WORD;
                        csr_rw_addr_o = `ZERO_WORD;
                        csr_zimm_o = `ZERO_WORD;
                    end
                endcase
            end
            default: begin
                reg1_rd_addr_o = `ZERO_REG_ADDR;
                reg2_rd_addr_o = `ZERO_REG_ADDR;
                reg_wr_addr_o = `ZERO_REG_ADDR;
                imm_o = `ZERO_WORD;
            end
        endcase
    end
endmodule
