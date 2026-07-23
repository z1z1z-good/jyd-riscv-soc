`timescale 1ns / 1ps
`include "../core/defines.v"

// riscv处理器核模块
module RISCV_CORE(

    input   wire                        clk                 ,
    input   wire                        rst_n               ,
    
    input   wire                        rib_hold_flag_i     , // rib总线传来的流水线暂停标志
    input   wire[`INT_BUS]              int_flag_i          , // 外部设备中断标志
    
    // 取指相关
    output  wire[`INST_ADDR_BUS]        pc_o                , // 传给rom的指令地址
    input   wire[`INST_DATA_BUS]        instr_i               , // rom根据地址读出来指令
    
    // 访存相关
    output  wire                        mem_wr_rib_req_o    , // 写总线请求信号
    output  wire                        mem_wr_en_o         , // 写使能
    output  wire[`INST_ADDR_BUS]        mem_wr_addr_o       , // 写地址
    output  wire[`INST_DATA_BUS]        mem_wr_data_o       , // 写数据
    output  wire                        mem_rd_rib_req_o    , // 读总线请求信号
    output  wire[`INST_ADDR_BUS]        mem_rd_addr_o       , // 读地址
    input   wire[`INST_DATA_BUS]        mem_rd_data_i         // 读数据
    
    );
    
    // IF单元输出信号
    wire[`INST_DATA_BUS]     if_instr_o;
    wire[`INST_ADDR_BUS]     if_instr_addr_o;
    wire[`INST_ADDR_BUS]     if_pc_o;
    wire[`INT_BUS]           if_int_flag_o;
    wire[`INST_ADDR_BUS]     mem_rd_addr_to_mem;
    // ID单元输出信号
    wire[`INST_DATA_BUS]     id_instr_o;
    wire[`INST_ADDR_BUS]     id_instr_addr_o;
    wire[6:0]                id_opcode_o;
    wire[2:0]                id_funct3_o;
    wire[6:0]                id_funct7_o;
    wire[`INST_REG_ADDR]     id_reg1_rd_addr_o;
    wire[`INST_REG_ADDR]     id_reg2_rd_addr_o;
    wire[`INST_REG_DATA]     id_reg1_rd_data_o;
    wire[`INST_REG_DATA]     id_reg2_rd_data_o;
    wire[`INST_REG_ADDR]     id_reg_wr_addr_o;
    wire[`INST_REG_DATA]     id_imm_o;
    wire[`INST_ADDR_BUS]     id_csr_rw_addr_o;
    wire[`INST_ADDR_BUS]     id_csr_rd_addr_o;
    wire[`INST_REG_DATA]     id_csr_zimm_o;
    wire[`INST_REG_DATA]     id_csr_rd_data_o;
    
    // RF单元输出信号
    wire[`INST_REG_DATA]     rf_reg1_rd_data_o;
    wire[`INST_REG_DATA]     rf_reg2_rd_data_o;
    wire[`INST_REG_DATA]     rf_csr_rd_data_o;
    wire[`INST_REG_DATA]     rf_clint_rd_data_o;
    wire[`INST_REG_DATA]     rf_clint_csr_mtvec;  
    wire[`INST_REG_DATA]     rf_clint_csr_mepc;   
    wire[`INST_REG_DATA]     rf_clint_csr_mstatus;
    wire[1:0]                rf_privileg_o;
    
    // clint 模块输出信号
    wire                     clint_wr_en_o;    
    wire[`INST_ADDR_BUS]     clint_wr_addr_o;  
    wire[`INST_REG_DATA]     clint_wr_data_o;  
    wire[`INST_ADDR_BUS]     clint_rd_addr_o;  
    wire                     clint_busy_o;
    wire[`INST_ADDR_BUS]     clint_int_addr_o;
    wire                     clint_int_assert_o;
    wire                     clint_wr_privilege_en_o;
    wire[1:0]                clint_wr_privilege_o; 
    
    // EX单元输出信号
    wire                     mem_reg_wr_en_o;
    wire[`INST_REG_ADDR]     mem_reg_wr_addr_o;
    wire[`INST_REG_DATA]     mem_reg_wr_data_o;
    wire                     ex_jump_flag_o;
    wire[`INST_REG_DATA]     ex_jump_addr_o;
    wire[2:0]                ex_hold_flag_o;
    wire                     ex_keep_flag_o;//four add
    wire                     ex_csr_wr_en_o;
    wire[`INST_ADDR_BUS]     ex_csr_wr_addr_o;
    wire[`INST_REG_DATA]     ex_csr_wr_data_o;
    wire                     ex_div_busy_o; 
    wire                     ex_div_req_o;  
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
    // 取指单元例化
    IFU u_IFU(
        .clk                 (clk),
        .rst_n               (rst_n),
        .hold_flag_i         (ex_hold_flag_o),
        .jump_flag_i         (ex_jump_flag_o),
        .jump_addr_i         (ex_jump_addr_o),
		.keep_flag_i         (ex_keep_flag_o),
        .int_flag_i          (int_flag_i),
        .int_flag_o          (if_int_flag_o),
        .instr_o               (if_instr_o),      
        .instr_addr_o          (if_instr_addr_o), 
        .pc_o                (pc_o),          
        .instr_i               (instr_i)
    );
    
    // 译码单元例化
    IDU u_IDU(
        .clk                 (clk),
        .rst_n               (rst_n),
        .hold_flag_i         (ex_hold_flag_o),
		.keep_flag_i         (ex_keep_flag_o),
        .instr_i               (if_instr_o), 
        .instr_addr_i          (if_instr_addr_o), 
        .reg1_rd_data_i      (rf_reg1_rd_data_o), 
        .reg2_rd_data_i      (rf_reg2_rd_data_o),
        .reg1_rd_addr_o      (id_reg1_rd_addr_o), 
        .reg2_rd_addr_o      (id_reg2_rd_addr_o),
        .reg1_rd_data_o      (id_reg1_rd_data_o), 
        .reg2_rd_data_o      (id_reg2_rd_data_o),
        .reg_wr_addr_o       (id_reg_wr_addr_o),
        .instr_o               (id_instr_o),
        .instr_addr_o          (id_instr_addr_o), 
        .imm_o               (id_imm_o),
        .csr_rd_data_i       (rf_csr_rd_data_o),
        .csr_rd_addr_o       (id_csr_rd_addr_o),
        .csr_rw_addr_o       (id_csr_rw_addr_o),
        .csr_zimm_o          (id_csr_zimm_o),
        .csr_rd_data_o       (id_csr_rd_data_o)
        //.mem_rd_rib_req_o    (mem_rd_rib_req_o),
        //.mem_rd_addr_o       (mem_rd_addr_o)
    );

    // 通用寄存器模块例化
    RFU u_RFU(
        .clk                 (clk),
        .rst_n               (rst_n),
        .wr_en_i             (wb_reg_wr_en_o), 
        .wr_addr_i           (wb_reg_wr_addr_o), 
        .wr_data_i           (wb_reg_wr_data_o), 
        .reg1_rd_addr_i      (id_reg1_rd_addr_o), 
        .reg2_rd_addr_i      (id_reg2_rd_addr_o), 
        .reg1_rd_data_o      (rf_reg1_rd_data_o), 
        .reg2_rd_data_o      (rf_reg2_rd_data_o), 
        .csr_wr_en_i         (ex_csr_wr_en_o),
        .csr_wr_addr_i       (ex_csr_wr_addr_o),
        .csr_wr_data_i       (ex_csr_wr_data_o),
        .csr_rd_addr_i       (id_csr_rd_addr_o),
        .csr_rd_data_o       (rf_csr_rd_data_o),
        .clint_wr_en_i       (clint_wr_en_o),
        .clint_wr_addr_i     (clint_wr_addr_o),
        .clint_wr_data_i     (clint_wr_data_o),
        .clint_rd_addr_i     (clint_rd_addr_o),
        .clint_rd_data_o     (rf_clint_rd_data_o),
        .wr_privilege_en_i   (clint_wr_privilege_en_o),
        .wr_privilege_i      (clint_wr_privilege_o),
        .privileg_o          (rf_privileg_o),
		.ex_wr_addr_i        (id_reg_wr_addr_o),//
		.ex_wr_data_i        (reg_wr_data_first),
		.not_mem             (not_mem),
		.mem_wr_addr_i       (reg_wr_addr_ex_mem),
		.mem_wr_data_i       (mem_reg_wr_data_first),
        .clint_csr_mtvec     (rf_clint_csr_mtvec),
        .clint_csr_mepc      (rf_clint_csr_mepc),
        .clint_csr_mstatus   (rf_clint_csr_mstatus)
    );
    
    // 中断模块例化
    clint u_clint(
        .clk                 (clk),
        .rst_n               (rst_n),
        .instr_i               (if_instr_o),     
        .instr_addr_i          (if_instr_addr_o), 
        .jump_flag_i         (ex_jump_flag_o),
        .jump_addr_i         (ex_jump_addr_o),
        .div_req_i           (ex_div_req_o), 
        .div_busy_i          (ex_div_busy_o), 
        .wr_en_o             (clint_wr_en_o), 
        .wr_addr_o           (clint_wr_addr_o), 
        .wr_data_o           (clint_wr_data_o), 
        .rd_addr_o           (clint_rd_addr_o),
        .rd_data_i           (rf_clint_rd_data_o),
        .csr_mtvec           (rf_clint_csr_mtvec), 
        .csr_mepc            (rf_clint_csr_mepc), 
        .csr_mstatus         (rf_clint_csr_mstatus), 
        .wr_privilege_en_o   (clint_wr_privilege_en_o),
        .wr_privilege_o      (clint_wr_privilege_o),
        .privileg_i          (rf_privileg_o),
        .int_flag_i          (if_int_flag_o), 
        .clint_busy_o        (clint_busy_o), 
        .int_addr_o          (clint_int_addr_o), 
        .int_assert_o        (clint_int_assert_o)  
    );
    

    // 执行单元例化
    EXU u_EXU(
        .clk                 (clk),
        .rst_n               (rst_n),  
        .instr_i               (id_instr_o),
        .instr_addr_i          (id_instr_addr_o), 
        .imm_i               (id_imm_o),  
        .csr_rd_data_i       (id_csr_rd_data_o),
        .csr_rw_addr_i       (id_csr_rw_addr_o),
        .csr_zimm_i          (id_csr_zimm_o),
        .csr_wr_en_o         (ex_csr_wr_en_o),
        .csr_wr_addr_o       (ex_csr_wr_addr_o),
        .csr_wr_data_o       (ex_csr_wr_data_o),
        .reg1_rd_data_i      (id_reg1_rd_data_o), 
        .reg2_rd_data_i      (id_reg2_rd_data_o),
        .reg_wr_addr_i       (id_reg_wr_addr_o),
		.reg1_rd_addr_i      (id_reg1_rd_addr_o),
		.reg2_rd_addr_i      (id_reg2_rd_addr_o),
		.reg2_rd_data_o      (reg2_rd_data_ex_mem),
        .reg_wr_en_o         (reg_wr_en_ex_mem),
        .reg_wr_addr_o       (reg_wr_addr_ex_mem),
        .reg_wr_data_o       (reg_wr_data_ex_mem),
		.instr_o				 (ins),
		.is_load_o			 (is_load),
		.is_save_o			 (is_save),
        .rib_hold_flag_i     (rib_hold_flag_i),
        .jump_flag_o         (ex_jump_flag_o),
        .jump_addr_o         (ex_jump_addr_o),
        .hold_flag_o         (ex_hold_flag_o),
        //.mem_rd_addr_i       (mem_rd_addr_o),
        //.mem_rd_data_i       (mem_rd_data_i),
        //.mem_wr_rib_req_o    (mem_wr_rib_req_o),
        //.mem_wr_en_o         (mem_wr_en_o), 
        //.mem_wr_addr_o       (mem_wr_addr_o), 
        //.mem_wr_data_o       (mem_wr_data_o),
		.not_mem             (not_mem),
		.reg_wr_data_first_o   (reg_wr_data_first),
		.keep_flag_o         (ex_keep_flag_o),
        .clint_busy_i        (clint_busy_o),
        .int_addr_i          (clint_int_addr_o),
        .int_assert_i        (clint_int_assert_o),
        .div_busy_o          (ex_div_busy_o),
        .div_req_o           (ex_div_req_o),
		.mem_rd_rib_req_o    (mem_rd_rib_req_o),
		.mem_rd_addr_o       (mem_rd_addr_o),
		.mem_rd_addr_to_mem  (mem_rd_addr_to_mem)

    );
	
	LSU	u_LSU
	(
	.clk				 (clk),
	.rst_n				 (rst_n),
	.reg2_rd_data_i      (reg2_rd_data_ex_mem),
	
	.reg_wr_addr_i       (reg_wr_addr_ex_mem),
	.reg_wr_data_i       (reg_wr_data_ex_mem),
	.reg_wr_en_i         (reg_wr_en_ex_mem),
	.reg_wr_en_o         (mem_reg_wr_en_o  ),
	.reg_wr_addr_o       (mem_reg_wr_addr_o),
	.reg_wr_data_o       (mem_reg_wr_data_o),
	
	.mem_rd_addr_i       (mem_rd_addr_to_mem   ),
	.mem_rd_data_i       (mem_rd_data_i   ),
	.mem_wr_rib_req_o    (mem_wr_rib_req_o),
	.mem_wr_en_o         (mem_wr_en_o     ),
	.mem_wr_addr_o       (mem_wr_addr_o   ),
	.mem_wr_data_o       (mem_wr_data_o   ),
	
	.is_load_i			(is_load),
	.is_save_i			(is_save),
	.keep_flag_i		(ex_keep_flag_o),
	.reg_wr_data_first_o(mem_reg_wr_data_first),
	.instr_i              (ins)
	
	
	);
    
	WBU	u_WBU
	(
	.reg_wr_addr_i       (mem_reg_wr_addr_o ),
	.reg_wr_data_i       (mem_reg_wr_data_o ),
	.reg_wr_en_i         (mem_reg_wr_en_o   ),
	.reg_wr_en_o         (wb_reg_wr_en_o   ),
	.reg_wr_addr_o       (wb_reg_wr_addr_o ),
	.reg_wr_data_o       (wb_reg_wr_data_o )
	);
	
endmodule
