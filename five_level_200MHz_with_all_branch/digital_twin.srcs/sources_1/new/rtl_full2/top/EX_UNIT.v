`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/16 17:02:43
// Design Name: 
// Module Name: EX_UNIT
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
`include "../core/defines.v"

// 鎵ц鍗曞�?
module EX_UNIT(

    input   wire                    clk                 ,
    input   wire                    rst_n               ,
    // with   global_predictor
	output  wire                    actual_taken        ,
	output  wire[31:0]              actual_target       ,
	input   wire                    predict_taken       ,
	output  wire[31:0]              ins_addr_o          ,
	output  wire                    is_branch           ,
    // from ID_UNIT
    input   wire[`INST_DATA_BUS]    ins_i               ,     
    input   wire[`INST_ADDR_BUS]    ins_addr_i          , 
    input   wire[`INST_REG_DATA]    imm_i               , 
    
    // from ID_UNIT
    input   wire[`INST_REG_DATA]    reg1_rd_data_i      , 
    input   wire[`INST_REG_DATA]    reg2_rd_data_i      ,
    input   wire[`INST_REG_ADDR]    reg_wr_addr_i       ,
	input	wire[`INST_REG_ADDR]    reg1_rd_addr_i		,
	input	wire[`INST_REG_ADDR]    reg2_rd_addr_i		,
    // to MEM_UNIT
	output	reg [`INST_REG_DATA]    reg2_rd_data_o      ,
    output  reg                     reg_wr_en_o         ,
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o       ,
    output  reg [`INST_REG_DATA]    reg_wr_data_o       ,//鎺ョ粰regs鍜宮em
    output	reg [`INST_DATA_BUS]    ins_o        		,
	output  wire                    reg_wr_en_toregs    ,
	output	reg					is_load_o			,
	output	reg					is_save_o			,
	
    input   wire                    rib_hold_flag_i     ,
    // to IF_UNIT銆乧lint
    output  wire                    jump_flag_o         ,
    output  wire[`INST_REG_DATA]    jump_addr_o         ,
    output  reg [2:0]               hold_flag_o         ,
    output	  wire                  not_mem             ,
	output	  wire[`INST_REG_DATA]  reg_wr_data_first_o       ,//为了让数据提前到�?
    output  reg                      mem_rd_rib_req_o  ,
    output  reg  [`INST_ADDR_BUS]     mem_rd_addr_o      ,
	output	reg [`INST_ADDR_BUS]     mem_rd_addr_to_mem 
    
    );
	//wire keep_flag_return;
	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			mem_rd_addr_to_mem <= 32'b0;
		end
		else begin
			mem_rd_addr_to_mem <= mem_rd_addr_o;
		end
	end
	wire                     reg_wr_en         ;
	wire[`INST_REG_ADDR]     reg_wr_addr       ;
	wire[`INST_REG_DATA]     reg_wr_data       ;
    wire                     jump_flag;
    wire[`INST_ADDR_BUS]     jump_addr;
    wire                     hold_flag;
    assign jump_flag_o = jump_flag;
    assign jump_addr_o = jump_addr;
    assign ins_addr_o  = ins_addr_i ;
	assign reg_wr_data_first_o = reg_wr_data;
	
    wire [6:0]      opcode;
    wire [2:0]      funct3;
    wire [6:0]      funct7;
    assign opcode = ins_i[6:0];
    assign funct3 = ins_i[14:12];
    assign funct7 = ins_i[31:25];
    always @ (posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
	        ins_o <= `ZERO_WORD;
			reg_wr_addr_o <= 5'b0;
			reg_wr_data_o <= `ZERO_WORD;
			reg_wr_en_o   <= 1'b0;
			reg2_rd_data_o <= `ZERO_WORD;
			is_load_o <= 1'b0;
			is_save_o <= 1'b0;
	    end
	    else begin
	        ins_o <= ins_i;
			reg_wr_addr_o <= reg_wr_addr     ;
			reg_wr_data_o <= reg_wr_data     ;
			reg_wr_en_o   <= reg_wr_en       ;
			reg2_rd_data_o <= reg2_rd_data_i;
			is_load_o <= (opcode == `INS_TYPE_LOAD);
			is_save_o <= (opcode == `INS_TYPE_SAVE);
	    end
	end
	always @ (*) begin
        if((opcode == `INS_TYPE_LOAD) | (opcode == `INS_TYPE_SAVE)) begin
            mem_rd_rib_req_o = 1'b1;
            mem_rd_addr_o = $signed(reg1_rd_data_i) + $signed(imm_i);
        end
        else begin
            mem_rd_rib_req_o = 1'b0;
            mem_rd_addr_o = $signed(reg1_rd_data_i) + $signed(imm_i);
        end
    end


    always @ (*) begin
        // 鏆傚仠鏁翠釜娴佹按绾        
		if(jump_flag_o == 1'b1 || hold_flag == 1'b1) begin
            hold_flag_o = `HOLD_ID_EX;
        end
        // 鏆傚仠PC
        else if(rib_hold_flag_i == 1'b1) begin
            hold_flag_o = `HOLD_PC;
        end
        else begin
            hold_flag_o = `HOLD_NONE;
        end
    end
    assign reg_wr_en_toregs = reg_wr_en;
	reg predict_taken_reg,predict_taken_reg1 ,predict_taken_reg2 =0;
	always@(posedge clk )begin
	predict_taken_reg <= predict_taken ;
	predict_taken_reg1 <= predict_taken_reg ;
	predict_taken_reg2 <= predict_taken_reg1 ;
	end //从预测发来的，应该要打拍达到同步
    cu u_cu(
        .clk                 (clk),
        .rst_n               (rst_n),
        .actual_taken        (actual_taken ),
        .actual_target       (actual_target),
        .predict_taken       (predict_taken_reg1),
        .is_branch           (is_branch) ,
        .ins_addr_i          (ins_addr_i), 
        .opcode_i            (opcode),
        .funct3_i            (funct3),
        .funct7_i            (funct7),
        .imm_i               (imm_i),  
        .jump_flag_o         (jump_flag),
        .jump_addr_o         (jump_addr),        
        .hold_flag_o         (hold_flag),
        .reg1_rd_data_i      (reg1_rd_data_i), 
        .reg2_rd_data_i      (reg2_rd_data_i),
        .reg_wr_addr_i       (reg_wr_addr_i),
        .reg_wr_en_o         (reg_wr_en),
        .reg_wr_addr_o       (reg_wr_addr),
        .reg_wr_data_o       (reg_wr_data),
		.reg1_rd_addr_i      (reg1_rd_addr_i),
		.reg2_rd_addr_i      (reg2_rd_addr_i),
		.not_mem             (not_mem    )
    );
    
    
endmodule
