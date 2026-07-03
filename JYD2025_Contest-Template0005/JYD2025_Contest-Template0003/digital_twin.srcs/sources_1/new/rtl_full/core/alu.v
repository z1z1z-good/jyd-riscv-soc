`timescale 1ns / 1ps
`include "defines.v"

// 运算单元
module alu(

    input      wire[`INST_REG_DATA]    alu_data1_i         , 
    input      wire[`INST_REG_DATA]    alu_data2_i         ,
    input      wire[3:0]               alu_op_code_i       ,
    
    output     reg [`INST_REG_DATA]    alu_res_o           ,
    output     reg                     alu_zero_flag_o     , // 零标志位
    output     reg                     alu_sign_flag_o     , // 符号标志位，1为负数，0为正数或0
    output     reg                     alu_overflow_flag_o   // 溢出标志位
    
    );
    wire[4:0] shamt	;
	assign shamt  = alu_data2_i[4:0];
    always @ (*) begin
        alu_zero_flag_o = !(|alu_res_o); 
        alu_sign_flag_o = alu_res_o[31];
        alu_overflow_flag_o = ((alu_op_code_i == `ALU_ADD & ~alu_data1_i[31] & ~alu_data2_i[31] & alu_res_o[31])
                               |(alu_op_code_i == `ALU_ADD & alu_data1_i[31] & alu_data2_i[31] & ~alu_res_o[31])
                               |(alu_op_code_i == `ALU_SUB & ~alu_data1_i[31] & alu_data2_i[31] & alu_res_o[31])
                               |(alu_op_code_i == `ALU_SUB & alu_data1_i[31] & ~alu_data2_i[31] & ~alu_res_o[31]));
    end
    
    always @ (*) begin
        case(alu_op_code_i)
            `ALU_ADD: begin
                alu_res_o = $signed(alu_data1_i) + $signed(alu_data2_i); // 和
            end
            `ALU_SUB: begin
                alu_res_o = $signed(alu_data1_i) - $signed(alu_data2_i); // 差
            end
            `ALU_SLL: begin
                alu_res_o = alu_data1_i << shamt; // 逻辑左移
            end
            `ALU_SLT: begin
                alu_res_o = ($signed(alu_data1_i) < $signed(alu_data2_i)) ? 1 : 0; // 有符号数小于置1
            end
            `ALU_SLTU: begin
                alu_res_o = (alu_data1_i < alu_data2_i) ? 1 : 0; // 无符号数小于置1
            end
            `ALU_XOR: begin
                alu_res_o = alu_data1_i ^ alu_data2_i; // 异或
            end
            `ALU_SRL: begin
                alu_res_o = alu_data1_i >> shamt; // 逻辑右移
            end
            `ALU_SRA: begin
                alu_res_o = $signed(alu_data1_i) >>> shamt; // 算术右移
            end  
            `ALU_OR: begin
                alu_res_o = alu_data1_i | alu_data2_i; // 或
            end
            `ALU_AND: begin
                alu_res_o = alu_data1_i & alu_data2_i; // 与
            end
            default: begin
                alu_res_o = alu_data1_i; 
            end            
        endcase
    end
    
endmodule


