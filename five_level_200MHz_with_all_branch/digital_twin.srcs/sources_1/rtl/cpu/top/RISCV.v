`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/16 17:17:03
// Design Name: 
// Module Name: RISCV_TOP
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
(* dont_touch = "true", keep = "true" *)
`include "../core/defines.v"
// riscv处理器核模块
module RISCV(

    input   wire                        clk                 ,
    input   wire                        rst_n               ,
    
    input   wire                        rib_hold_flag_i     , 
    input   wire[`INT_BUS]              int_flag_i          , 
    
    // 取指相关
    output  wire[13:0]                  pc_o                , 
    input   wire[`INST_DATA_BUS]        ins_i               , 
    
    // 访存相关
    output  wire                        mem_wr_rib_req_o    , 
    output  wire                        mem_wr_en_o         , 
    output  wire[`INST_ADDR_BUS]        mem_wr_addr_o       , 
    output  wire[`INST_DATA_BUS]        mem_wr_data_o       , 
    output  wire                        mem_rd_rib_req_o    , 
    output  wire[`INST_ADDR_BUS]        mem_rd_addr_o       , 
    input   wire[`INST_DATA_BUS]        mem_rd_data_i         
    
    );
    //global_predictor
	wire                     is_branch     ;
	wire[31:0]               pc_from_ex    ;
	wire                     actual_taken  ;
	wire[31:0]               actual_target ; //实际分支结果，用于更新PHT和BTB
	wire                     pred_taken    ;
	wire[31:0]               pred_target   ;
    // IF单元输出信号
	wire[13:0]               pc            ;
    wire[`INST_DATA_BUS]     if_ins_o;
    wire[`INST_ADDR_BUS]     if_ins_addr_o;
    wire[`INST_ADDR_BUS]     if_pc_o;
    wire[`INT_BUS]           if_int_flag_o;
    wire[`INST_ADDR_BUS]     mem_rd_addr_to_mem;
    // IF2单元输出信号
    wire[31:0]               if2_ins_addr_o  ;
    wire[31:0]               if2_ins_o       ;
    
    // ID单元输出信号
    wire[`INST_DATA_BUS]     id_ins_o;
    wire[`INST_ADDR_BUS]     id_ins_addr_o;
    wire[6:0]                id_opcode_o;
    wire[2:0]                id_funct3_o;
    wire[6:0]                id_funct7_o;
    wire[`INST_REG_ADDR]     id_reg1_rd_addr_o;
    wire[`INST_REG_ADDR]     id_reg2_rd_addr_o;
    wire[`INST_REG_DATA]     id_reg1_rd_data_o;
    wire[`INST_REG_DATA]     id_reg2_rd_data_o;
    wire[`INST_REG_ADDR]     id_reg_wr_addr_o;
    wire[`INST_REG_DATA]     id_imm_o;
    
    // RF单元输出信号
    wire[`INST_REG_DATA]     rf_reg1_rd_data_o;
    wire[`INST_REG_DATA]     rf_reg2_rd_data_o;
    
    // EX单元输出信号
    wire                     mem_reg_wr_en_o;
    wire[`INST_REG_ADDR]     mem_reg_wr_addr_o;
    wire[`INST_REG_DATA]     mem_reg_wr_data_o;
    wire                     ex_jump_flag_o;
    wire[`INST_REG_DATA]     ex_jump_addr_o;
    wire[2:0]                ex_hold_flag_o;
    wire                     not_mem;
    wire                     wb_reg_wr_en_o;
    wire[`INST_REG_ADDR]     wb_reg_wr_addr_o;
    wire[`INST_REG_DATA]     wb_reg_wr_data_o;
	wire[`INST_REG_DATA]     reg_wr_data_ex_mem       ;
	wire[`INST_REG_DATA]     reg_wr_data_first        ;
	wire[`INST_REG_DATA]     mem_reg_wr_data_first    ;
	
	wire [`INST_REG_DATA]    reg2_rd_data_ex_mem;
	wire[`INST_REG_ADDR]     reg_wr_addr_ex_mem       ;
	//wire[`INST_REG_DATA]     reg_wr_data_ex_mem       ;
	wire                     reg_wr_en_ex_mem         ;
	wire					 is_load					;
	wire					 is_save					;
	wire[`INST_DATA_BUS]     ins               ; 
	wire                     ex_wr_en_to_gpr ;
	wire                     mem_wr_en_to_gpr;
	wire [31:0]              mem_rd_addr_id_to_ex;
	
	assign  pc_o        =       pc;
	// 分支预测例化
	bpu u_bpu
	(
	    .clk            (clk)                  ,
	    .rst          (rst_n)                ,
	    .pc_from_if   ({{18'b1000_0000_0000_0000_00},pc[13:2], {2'b0}}    ),
	    .pc_from_ex     (pc_from_ex   )        ,
		.is_branch      (is_branch) ,
	    .actual_jump_flag   (actual_taken )        ,
	    .actual_jump_addr  (actual_target)        ,
	    .predict_taken     (pred_taken   )        ,
	    .predict_target    (pred_target  )
	
	);
 
    
    
    // 取指单元例化
    IF_UNIT INST_IF_UNIT(
        .clk                 (clk),
        .rst_n               (rst_n),
		.pred_taken          (pred_taken), 
		.pred_target         (pred_target),
        .hold_flag_i         (ex_hold_flag_o),
        .jump_flag_i         (ex_jump_flag_o),
        .jump_addr_i         (ex_jump_addr_o),
        .int_flag_i          (int_flag_i),
        .int_flag_o          (if_int_flag_o),
        .ins_o               (if_ins_o),      
        .ins_addr_o          (if_ins_addr_o), 
        .pc_o                (pc),          
        .ins_i               (ins_i)
    );
    //取指2单元例化
/*     IF2_UNIT INST_IF2_UNIT
    (
        .clk                 (clk),
        .rst_n               (rst_n),
        .hold_flag_i         (ex_hold_flag_o),
        .keep_flag_i         (ex_keep_flag_o),
        .ins_i               (if_ins_o),
        .ins_addr_i          (if_ins_addr_o),
        .ins_o               (if2_ins_o),
        .ins_addr_o          (if2_ins_addr_o)
    ); */
    // 译码单元例化
    ID_UNIT INST_ID_UNIT(
        .clk                 (clk),
        .rst_n               (rst_n),
        .hold_flag_i         (ex_hold_flag_o),
        .ins_i               (if_ins_o), 
        .ins_addr_i          (if_ins_addr_o), 
        .reg1_rd_data_i      (rf_reg1_rd_data_o), 
        .reg2_rd_data_i      (rf_reg2_rd_data_o),
        .reg1_rd_addr_o      (id_reg1_rd_addr_o), 
        .reg2_rd_addr_o      (id_reg2_rd_addr_o),
        .reg1_rd_data_o      (id_reg1_rd_data_o), 
        .reg2_rd_data_o      (id_reg2_rd_data_o),
        .reg_wr_addr_o       (id_reg_wr_addr_o),
        .ins_o               (id_ins_o),
        .ins_addr_o          (id_ins_addr_o), 
        .imm_o               (id_imm_o)
    );

    // 通用寄存器模块例�?
    RF_UNIT INST_RF_UNIT(
        .clk                 (clk),
        .rst_n               (rst_n),
        .wr_en_i             (wb_reg_wr_en_o), 
        .wr_addr_i           (wb_reg_wr_addr_o), 
        .wr_data_i           (wb_reg_wr_data_o), 
        .reg1_rd_addr_i      (id_reg1_rd_addr_o), 
        .reg2_rd_addr_i      (id_reg2_rd_addr_o), 
        .reg1_rd_data_o      (rf_reg1_rd_data_o), 
        .reg2_rd_data_o      (rf_reg2_rd_data_o),
		.ex_wr_addr_i        (id_reg_wr_addr_o),//
		.ex_wr_data_i        (reg_wr_data_first),
		.not_mem             (not_mem),
		.ex_wr_en_i          (ex_wr_en_to_gpr),
		.mem_wr_en_i         (mem_wr_en_to_gpr),
		.mem_wr_addr_i       (reg_wr_addr_ex_mem),
		.mem_wr_data_i       (mem_reg_wr_data_first)
    );
    

    // 执行单元例化
    EX_UNIT INST_EX_UNIT(
        .clk                 (clk),
        .rst_n               (rst_n),  
        .actual_taken        (actual_taken),
        .actual_target       (actual_target),
        .predict_taken       (pred_taken), // 应该要打拍
        .is_branch           (is_branch) ,
        .ins_addr_o          (pc_from_ex),
        .ins_i               (id_ins_o),
        .ins_addr_i          (id_ins_addr_o), 
        .imm_i               (id_imm_o),  
        .reg1_rd_data_i      (id_reg1_rd_data_o), 
        .reg2_rd_data_i      (id_reg2_rd_data_o),
        .reg_wr_addr_i       (id_reg_wr_addr_o),
		.reg1_rd_addr_i      (id_reg1_rd_addr_o),
		.reg2_rd_addr_i      (id_reg2_rd_addr_o),
		.reg2_rd_data_o      (reg2_rd_data_ex_mem),
        .reg_wr_en_o         (reg_wr_en_ex_mem),
        .reg_wr_addr_o       (reg_wr_addr_ex_mem),
        .reg_wr_data_o       (reg_wr_data_ex_mem),
		.ins_o				 (ins),
		.reg_wr_en_toregs    (ex_wr_en_to_gpr),
		.is_load_o			 (is_load),
		.is_save_o			 (is_save),
        .rib_hold_flag_i     (rib_hold_flag_i),
        .jump_flag_o         (ex_jump_flag_o),
        .jump_addr_o         (ex_jump_addr_o),
        .hold_flag_o         (ex_hold_flag_o),
		.not_mem             (not_mem),
		.reg_wr_data_first_o   (reg_wr_data_first),
		.mem_rd_rib_req_o    (mem_rd_rib_req_o),
		.mem_rd_addr_o       (mem_rd_addr_o),
		.mem_rd_addr_to_mem  (mem_rd_addr_to_mem)

    );
	
	MEM_UNIT	INST_MEM_UNIT
	(
	.clk				 (clk),
	.rst_n				 (rst_n),
	.reg2_rd_data_i      (reg2_rd_data_ex_mem),
	
	.reg_wr_addr_i       (reg_wr_addr_ex_mem),
	.reg_wr_data_i       (reg_wr_data_ex_mem),
	.reg_wr_en_i         (reg_wr_en_ex_mem  ),
	.reg_wr_en_o         (mem_reg_wr_en_o  ),
	.reg_wr_addr_o       (mem_reg_wr_addr_o),
	.reg_wr_data_o       (mem_reg_wr_data_o),
	.reg_wr_en_to_gpr    (mem_wr_en_to_gpr),
	
	.mem_rd_addr_i       (mem_rd_addr_to_mem   ),
	.mem_rd_data_i       (mem_rd_data_i   ),
	.mem_wr_rib_req_o    (mem_wr_rib_req_o),
	.mem_wr_en_o         (mem_wr_en_o     ),
	.mem_wr_addr_o       (mem_wr_addr_o   ),
	.mem_wr_data_o       (mem_wr_data_o   ),
	
	.is_load_i			(is_load),
	.is_save_i			(is_save),
	.reg_wr_data_first_o(mem_reg_wr_data_first),
	.ins_i              (ins)
	
	
	);
    
	WB_UNIT	INST_WB_UNIT
	(
	.clk                 (clk) ,
	.reg_wr_addr_i       (mem_reg_wr_addr_o ),
	.reg_wr_data_i       (mem_reg_wr_data_o ),
	.reg_wr_en_i         (mem_reg_wr_en_o   ),
	.reg_wr_en_o         (wb_reg_wr_en_o   ),
	.reg_wr_addr_o       (wb_reg_wr_addr_o ),
	.reg_wr_data_o       (wb_reg_wr_data_o )
	);
	
endmodule
