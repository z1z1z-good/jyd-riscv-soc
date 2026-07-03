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
`include "defines.v"
// riscv处理器核模块
module RISCV(

    input   wire                        clk                 ,
    input   wire                        rst_n               ,
    //总线访问
	input   wire                        rib_hold_flag_i     ,
    // 取指相关
    output  wire[`INST_ADDR_BUS]        pc_o                , 
    input   wire[`INST_DATA_BUS]        ins_i               , 
    
    // 访存相关
    output  wire                        mem_wr_en_o         , 
    output  wire[`INST_ADDR_BUS]        mem_wr_addr_o       , 
    output  wire[`INST_DATA_BUS]        mem_wr_data_o       , 
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
	wire[`INST_ADDR_BUS]     pc            ;
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
	wire[`INST_ADDR_BUS]     id_csr_rd_addr  ;
	wire[`INST_REG_DATA]     id_csr_rd_data  ;
	wire[`INST_DATA_BUS]     id_zimm         ;
	wire[`INST_ADDR_BUS]     id_csr_rw_addr  ;
    
    // RF单元输出信号
    wire[`INST_REG_DATA]     rf_reg1_rd_data_o;
    wire[`INST_REG_DATA]     rf_reg2_rd_data_o;
	wire[`INST_REG_DATA]     rf_csr_rd_data;
    
    // EX单元输出信号
    wire                     mem_reg_wr_en_o;
    wire[`INST_REG_ADDR]     mem_reg_wr_addr_o;
    wire[`INST_REG_DATA]     mem_reg_wr_data_o;
    wire                     ex_jump_flag_o;
    wire[`INST_REG_DATA]     ex_jump_addr_o;
    wire                     ex_hold_flag_o;
    wire                     not_mem;
    wire                     wb_reg_wr_en_o;
    wire[`INST_REG_ADDR]     wb_reg_wr_addr_o;
    wire[`INST_REG_DATA]     wb_reg_wr_data_o;
	wire[`INST_REG_DATA]     reg_wr_data_ex_mem       ;
	wire[`INST_REG_DATA]     reg_wr_data_first        ;
	wire[`INST_REG_DATA]     mem_reg_wr_data_first    ;
	wire                     ex_csr_wr_en             ;
	wire[`INST_ADDR_BUS]     ex_csr_wr_addr           ;
	wire[`INST_DATA_BUS]     ex_csr_wr_data           ;
	//MEM_BUFFER单元输出信号
	wire [31:0]              reg2_rd_data_buffer_mem ;
	wire [`INST_REG_ADDR]    reg_wr_addr_buffer_mem  ;
	wire                     reg_wr_en_buffer_mem    ;
	wire [31:0]              reg_wr_data_buffer_mem  ;
	wire [31:0]              mem_rd_addr_buffer_mem  ;
	wire                     is_load_buffer_mem   ;
	wire                     is_save_buffer_mem   ;
	wire [2:0]               funct3_buffer_mem    ;
	wire [`INST_REG_DATA]    reg2_rd_data_ex_mem;
	wire[`INST_REG_ADDR]     reg_wr_addr_ex_mem       ;
	wire                     not_mem_from_buffer    ;
	wire                     reg_wr_en_ex_mem         ;
	wire					 is_load					;
	wire					 is_save					;
	wire[2:0]                funct3               ; 
	wire                     ex_wr_en_to_gpr ;
	wire                     mem_wr_en_to_gpr;
	wire [31:0]              mem_rd_addr_id_to_ex;
	
	assign  pc_o        =       pc;
	
	wire  ex_bypass1     =   (id_reg1_rd_addr_o == id_reg_wr_addr_o)&not_mem&ex_wr_en_to_gpr ;
	wire  mbem_bypass1   =   (id_reg1_rd_addr_o == reg_wr_addr_ex_mem)&not_mem_from_buffer&reg_wr_en_ex_mem ;
	wire  mem_bypass1    =   (id_reg1_rd_addr_o == reg_wr_addr_buffer_mem)&mem_wr_en_to_gpr ;
	wire  wb_bypass1     =   (id_reg1_rd_addr_o == wb_reg_wr_addr_o)&wb_reg_wr_en_o;
	wire  ex_bypass2     =   (id_reg2_rd_addr_o == id_reg_wr_addr_o)&not_mem&ex_wr_en_to_gpr ;
	wire  mbem_bypass2   =   (id_reg2_rd_addr_o == reg_wr_addr_ex_mem)&not_mem_from_buffer&reg_wr_en_ex_mem ;
	wire  mem_bypass2    =   (id_reg2_rd_addr_o == reg_wr_addr_buffer_mem)&mem_wr_en_to_gpr ;
	wire  wb_bypass2     =   (id_reg2_rd_addr_o == wb_reg_wr_addr_o)&wb_reg_wr_en_o;
	//clint
	wire                    clint_wr_en   ;
	wire[`INST_ADDR_BUS]    clint_wr_addr ;
	wire[`INST_DATA_BUS]    clint_wr_data ;
	wire[`INST_ADDR_BUS]    clint_rd_addr ;
	wire[`INST_DATA_BUS]    clint_rd_data ;
	wire[`INST_REG_DATA]    clint_csr_mtvec    ;
	wire[`INST_REG_DATA]    clint_csr_mepc     ;
	wire[`INST_REG_DATA]    clint_csr_mstatus  ;
	wire[1:0]               clint_privileg        ;
	wire                    clint_wr_privilege_en ;
	wire[1:0]               clint_wr_privilege    ;
	wire                    clint_busy        ;
	wire[`INST_ADDR_BUS]    int_addr          ;
	wire                    int_assert        ;
	// 分支预测例化
	AREA_PREDICTOR INST_AREA_PREDICTOR
	(
	    .clk            (clk)                  ,
	    .rst          (rst_n)                ,
	    .pc_from_if   (pc ),
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
		.rib_hold_flag_i     (rib_hold_flag_i),
		.pred_taken          (pred_taken), 
		.pred_target         (pred_target),
        .hold_flag_i         (ex_hold_flag_o),
        .jump_flag_i         (ex_jump_flag_o),
        .jump_addr_i         (ex_jump_addr_o),
        .ins_o               (if_ins_o),      
        .ins_addr_o          (if_ins_addr_o), 
        .pc_o                (pc),          
        .ins_i               (ins_i)
    );
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
		.csr_rd_data_i       (rf_csr_rd_data),
		.csr_rd_data_o       (id_csr_rd_data),
		.csr_zimm_o          (id_zimm),
		.csr_rd_addr_o       (id_csr_rd_addr),
		.csr_rw_addr_o       (id_csr_rw_addr),
        .imm_o               (id_imm_o)
    );

    // 通用寄存器模块例�?
    RF_UNIT INST_RF_UNIT(
        .clk                 (clk),
        .rst_n               (rst_n),
        .ex_bypass1          (ex_bypass1 ),
		.mbem_bypass1        (mbem_bypass1),
        .mem_bypass1         (mem_bypass1),
        .wb_bypass1          (wb_bypass1 ),
        .ex_bypass2          (ex_bypass2 ),
		.mbem_bypass2        (mbem_bypass2),
        .mem_bypass2         (mem_bypass2),
        .wb_bypass2          (wb_bypass2 ),
        .wr_en_i             (wb_reg_wr_en_o), 
        .wr_addr_i           (wb_reg_wr_addr_o), 
        .wr_data_i           (wb_reg_wr_data_o), 
        .reg1_rd_addr_i      (id_reg1_rd_addr_o), 
        .reg2_rd_addr_i      (id_reg2_rd_addr_o), 
        .reg1_rd_data_o      (rf_reg1_rd_data_o), 
        .reg2_rd_data_o      (rf_reg2_rd_data_o),
        .clint_wr_privilege_en_i  (clint_wr_privilege_en),
        .clint_wr_privilege_i     (clint_wr_privilege),
        .clint_privileg_o         (clint_privileg),
        .clint_wr_en_i            (clint_wr_en  ),
        .clint_wr_addr_i          (clint_wr_addr),
        .clint_wr_data_i          (clint_wr_data),
        .clint_rd_addr_i          (clint_rd_addr),
        .clint_rd_data_o          (clint_rd_data),
        .clint_csr_mtvec_o        (clint_csr_mtvec  ),
        .clint_csr_mepc_o         (clint_csr_mepc   ),
        .clint_csr_mstatus_o      (clint_csr_mstatus),
        .csr_wr_en_i              (ex_csr_wr_en   ),
        .csr_wr_addr_i            (ex_csr_wr_addr ),
        .csr_wr_data_i            (ex_csr_wr_data ),
        .csr_rd_addr_i            (id_csr_rd_addr),
        .csr_rd_data_o            (rf_csr_rd_data),
        .ex_wr_data_i        (reg_wr_data_first),
        .mem_wr_data_i       (mem_reg_wr_data_first),
        .mbem_wr_data_i      (reg_wr_data_ex_mem)
    );
    
    clint   INST_CLINT_UNIT
	(
    .clk                     (clk   ),
    .rst_n                   (rst_n ),
    .ins_i                   (if_ins_o),
    .ins_addr_i              (if_ins_addr_o),
    .jump_flag_i             (ex_jump_flag_o),
    .jump_addr_i             (ex_jump_addr_o),
    .wr_en_o                 (clint_wr_en  ),
    .wr_addr_o               (clint_wr_addr),
    .wr_data_o               (clint_wr_data),
    .rd_addr_o               (clint_rd_addr),
    .rd_data_i               (clint_rd_data),
    .csr_mtvec               (clint_csr_mtvec  ),
    .csr_mepc                (clint_csr_mepc   ),
    .csr_mstatus             (clint_csr_mstatus),
    .privileg_i              (clint_privileg),
    .wr_privilege_en_o       (clint_wr_privilege_en),
    .wr_privilege_o          (clint_wr_privilege),
    .int_flag_i              (`INT_NONE), //no async assert only sync assert
    .clint_busy_o            (clint_busy ),
    .int_addr_o              (int_addr   ),
    .int_assert_o            (int_assert ) 
	);
    // 执行单元例化
    EX_UNIT INST_EX_UNIT(
        .clk                 (clk),
        .rst_n               (rst_n),  
		//.rib_hold_flag_i     (rib_hold_flag_i) ,
        .actual_taken        (actual_taken),
        .actual_target       (actual_target),
        .predict_taken       (pred_taken), // 应该要打�?
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
		.funct3_o            (funct3),
		.reg_wr_en_toregs    (ex_wr_en_to_gpr),
		.is_load_o			 (is_load),
		.is_save_o			 (is_save),
        .jump_flag_o         (ex_jump_flag_o),
        .jump_addr_o         (ex_jump_addr_o),
        .hold_flag_o         (ex_hold_flag_o),
		.not_mem             (not_mem),
		.reg_wr_data_first_o (reg_wr_data_first),
		.mem_rd_addr_o       (mem_rd_addr_o),
		.mem_rd_addr_to_mem  (mem_rd_addr_to_mem),
        .csr_rw_addr_i       (id_csr_rw_addr),
        .csr_zimm_i          (id_zimm),
        .csr_rd_data_i       (id_csr_rd_data),
        .csr_wr_en_o         (ex_csr_wr_en   ),
        .csr_wr_addr_o       (ex_csr_wr_addr ),
        .csr_wr_data_o       (ex_csr_wr_data ),
        .clint_busy_i        (clint_busy ),
        .int_addr_i          (int_addr   ),
        .int_assert_i        (int_assert )

    );
	MEM_BUFFER  INST_MEM_BUFFER
	(
	.clk                 (clk),
	.rst_n               (rst_n),
	.reg2_rd_data_i      (reg2_rd_data_ex_mem),
	.reg2_rd_data_o      (reg2_rd_data_buffer_mem),
	.reg_wr_addr_i       (reg_wr_addr_ex_mem),
	.reg_wr_data_i       (reg_wr_data_ex_mem),
	.reg_wr_en_i         (reg_wr_en_ex_mem),
	.reg_wr_en_o         (reg_wr_en_buffer_mem),
	.reg_wr_addr_o       (reg_wr_addr_buffer_mem),
	.reg_wr_data_o       (reg_wr_data_buffer_mem),
	.mem_rd_addr_i       (mem_rd_addr_to_mem),
	.mem_rd_addr_o       (mem_rd_addr_buffer_mem),
	.is_load_i           (is_load),
	.is_save_i           (is_save),
	.not_mem             (not_mem_from_buffer),
	.funct3_i            (funct3),
	.is_load_o           (is_load_buffer_mem),
	.is_save_o           (is_save_buffer_mem),
	.funct3_o            (funct3_buffer_mem)
	
	
	);
	MEM_UNIT	INST_MEM_UNIT
	(
	.clk				 (clk),
	.rst_n				 (rst_n),
	.reg2_rd_data_i      (reg2_rd_data_buffer_mem),
	
	.reg_wr_addr_i       (reg_wr_addr_buffer_mem),
	.reg_wr_data_i       (reg_wr_data_buffer_mem),
	.reg_wr_en_i         (reg_wr_en_buffer_mem  ),
	.reg_wr_en_o         (mem_reg_wr_en_o  ),
	.reg_wr_addr_o       (mem_reg_wr_addr_o),
	.reg_wr_data_o       (mem_reg_wr_data_o),
	.reg_wr_en_to_gpr    (mem_wr_en_to_gpr),
	
	.mem_rd_addr_i       (mem_rd_addr_to_mem   ),
	.mem_rd_data_i       (mem_rd_data_i   ),
	.mem_wr_en_o         (mem_wr_en_o     ),
	.mem_wr_addr_o       (mem_wr_addr_o   ),
	.mem_wr_data_o       (mem_wr_data_o   ),
	
	.is_load_i			(is_load_buffer_mem),
	.is_save_i			(is_save_buffer_mem),
	.reg_wr_data_first_o(mem_reg_wr_data_first),
	.funct3_i           (funct3_buffer_mem)
	
	
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
