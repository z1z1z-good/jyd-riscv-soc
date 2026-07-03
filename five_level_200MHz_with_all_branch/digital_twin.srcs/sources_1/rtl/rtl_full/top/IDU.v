`timescale 1ns / 1ps
`include "../core/defines.v"

// 译码单元
module IDU(

    input   wire                    clk               ,
    input   wire                    rst_n             ,
                                                      
    input   wire[2:0]               hold_flag_i       ,
	input	wire                    keep_flag_i       ,
     
    // from IFU
    input   wire[`INST_DATA_BUS]    instr_i             , 
    input   wire[`INST_ADDR_BUS]    instr_addr_i        , 
    
    // from RFU              
    input   wire[`INST_REG_DATA]    reg1_rd_data_i    , 
    input   wire[`INST_REG_DATA]    reg2_rd_data_i    , 
    // to RFU
    output  wire [`INST_REG_ADDR]    reg1_rd_addr_o    , 
    output  wire [`INST_REG_ADDR]    reg2_rd_addr_o    , //当keep到来时这个也是需要keep的！！！
    // to EXU
    output  reg [`INST_REG_DATA]    reg1_rd_data_o    , 
    output  reg [`INST_REG_DATA]    reg2_rd_data_o    ,                         
    output  reg [`INST_REG_ADDR]    reg_wr_addr_o     ,
    
    // to EXU
    output  reg [`INST_DATA_BUS]    instr_o             ,     
    output  reg [`INST_ADDR_BUS]    instr_addr_o        ,                                      
    output  reg [`INST_REG_DATA]    imm_o             ,
    
    // from RFU
    input   wire[`INST_REG_DATA]    csr_rd_data_i     ,
    // to RF_UNIT
    output  wire[`INST_ADDR_BUS]    csr_rd_addr_o     ,
    // to EXU
    output  reg [`INST_ADDR_BUS]    csr_rw_addr_o     ,
    output  reg [`INST_REG_DATA]    csr_zimm_o        ,
    output  reg [`INST_REG_DATA]    csr_rd_data_o     
    
    // 如果当前为访存指令，则需要在译码阶段发出访存请求
    //output  wire                    mem_rd_rib_req_o  ,
    //output  wire[`INST_ADDR_BUS]    mem_rd_addr_o       
    
    );
    reg [`INST_REG_ADDR]    reg1_rd_addr_reg    ;
	reg [`INST_REG_ADDR]    reg2_rd_addr_reg    ;
    reg [`INST_REG_ADDR]    reg1_rd_addr_reg1    ;
	reg [`INST_REG_ADDR]    reg2_rd_addr_reg1    ;
	reg [`INST_REG_ADDR]    reg1_rd_addr_reg_o    ;
	reg [`INST_REG_ADDR]    reg2_rd_addr_reg_o    ;
	wire[`INST_REG_ADDR]    reg1_rd_addr_wire    ;
	wire[`INST_REG_ADDR]    reg2_rd_addr_wire    ;
	reg                     keep_flag_reg     ;
	reg                     keep_flag_reg1     ;
	always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		keep_flag_reg <= 1'b0;
	    keep_flag_reg1 <= 1'b0;
	end
	else begin
		keep_flag_reg <= keep_flag_i;
		keep_flag_reg1 <= keep_flag_reg;
	end
	end	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		reg1_rd_addr_reg <= 5'b0;
		reg2_rd_addr_reg <= 5'b0;
		reg1_rd_addr_reg1 <= 5'b0      ;
		reg2_rd_addr_reg1 <= 5'b0      ;
		end
		else if(keep_flag_i)begin
		reg1_rd_addr_reg <= reg1_rd_addr_o;
		reg2_rd_addr_reg <= reg2_rd_addr_o;
		end
		else if(keep_flag_reg)begin
		reg1_rd_addr_reg1 <= reg1_rd_addr_reg;
		reg2_rd_addr_reg1 <= reg2_rd_addr_reg;
		end
		else begin
		reg1_rd_addr_reg <= 5'b0;
		reg2_rd_addr_reg <= 5'b0;
		reg1_rd_addr_reg1 <= 5'b0;
		reg2_rd_addr_reg1 <= 5'b0;
		end
	end
	//always@(posedge clk or negedge rst_n) begin
	//if(!rst_n) begin
	//reg1_rd_addr_reg_o <= 5'b0;
	//reg2_rd_addr_reg_o <= 5'b0;
	//end
	//else if(keep_flag_i)begin
	//reg1_rd_addr_reg_o <= reg1_rd_addr_o;
	//reg2_rd_addr_reg_o <= reg2_rd_addr_o;
	//end
	//else begin
	//reg1_rd_addr_reg_o <= 5'b0;
	//reg2_rd_addr_reg_o <= 5'b0;
	//end
	//
	//end
    assign reg1_rd_addr_o = (keep_flag_reg1)?reg1_rd_addr_reg1:reg1_rd_addr_wire;
	//(keep_flag_reg | keep_flag_i)?5'b0:(keep_flag_reg1)?reg1_rd_addr_reg1:reg1_rd_addr_wire;
	assign reg2_rd_addr_o = (keep_flag_reg1)?reg2_rd_addr_reg1:reg2_rd_addr_wire;
	//(keep_flag_reg | keep_flag_i)?5'b0:(keep_flag_reg1)?reg2_rd_addr_reg1:reg2_rd_addr_wire;
    wire[`INST_DATA_BUS]    ins;
    wire[`INST_REG_ADDR]    reg_wr_addr;
    wire[`INST_REG_DATA]    imm;
    //wire                    mem_rd_flag;
    wire[`INST_ADDR_BUS]    csr_rw_addr;
    wire[`INST_REG_DATA]    csr_zimm;
    
    assign csr_rd_addr_o = csr_rw_addr;
    

	//其他信号的寄存
	 reg [`INST_DATA_BUS]     instr_reg             ;
	 reg [`INST_ADDR_BUS]     instr_addr_reg        ;
	 reg [`INST_REG_ADDR]     reg_wr_addr_reg     ;
	 reg [`INST_REG_DATA]     imm_reg             ;
	 reg [`INST_ADDR_BUS]     csr_rw_addr_reg     ;
	 reg [`INST_REG_DATA]     csr_zimm_reg        ;

	always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
		instr_reg          <= 0;
		instr_addr_reg     <= 0;
		reg_wr_addr_reg  <= 0;
		imm_reg          <= 0;
		csr_rw_addr_reg  <= 0;
		csr_zimm_reg     <= 0;
		end
		else if(keep_flag_i)begin
		instr_reg          <=  instr_o;
		instr_addr_reg     <=  instr_addr_o;
		reg_wr_addr_reg  <=  reg_wr_addr_o;
		imm_reg          <=  imm_o;
		csr_rw_addr_reg  <=  csr_rw_addr_o;
		csr_zimm_reg     <=  csr_zimm_o;
		end//只和当前输出有关
		else begin
		instr_reg          <= 0;
		instr_addr_reg     <= 0;
		reg_wr_addr_reg  <= 0;
		imm_reg          <= 0;
		csr_rw_addr_reg  <= 0;
		csr_zimm_reg     <= 0;
		
		end
	end
	
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            instr_o <= `INS_NOP;
            instr_addr_o <= `RESET_ADDR;
            reg1_rd_data_o <= `ZERO_WORD;
            reg2_rd_data_o <= `ZERO_WORD;   
            reg_wr_addr_o <= `ZERO_REG_ADDR;   
            imm_o <= `ZERO_WORD;
            csr_rw_addr_o <= `ZERO_WORD;
            csr_zimm_o <= `ZERO_WORD;
            csr_rd_data_o <= `ZERO_WORD;
        end
        else if((hold_flag_i >= `HOLD_ID_EX) || keep_flag_i) begin
            instr_o <= `INS_NOP;
            instr_addr_o <= `RESET_ADDR;
            reg1_rd_data_o <= `ZERO_WORD;
            reg2_rd_data_o <= `ZERO_WORD;   
            reg_wr_addr_o <= `ZERO_REG_ADDR;   
            imm_o <= `ZERO_WORD;   
            csr_rw_addr_o <= `ZERO_WORD;
            csr_zimm_o <= `ZERO_WORD;
            csr_rd_data_o <= `ZERO_WORD;
        end
		else if(keep_flag_reg) begin
            instr_o <= instr_reg;
            instr_addr_o <= instr_addr_reg;
            reg1_rd_data_o <= reg1_rd_data_i;
            reg2_rd_data_o <= reg2_rd_data_i;   
            reg_wr_addr_o <= reg_wr_addr_reg;   
            imm_o <= imm_reg;   
            csr_rw_addr_o <= csr_rw_addr_reg;
            csr_zimm_o <= csr_zimm_reg;
            csr_rd_data_o <= csr_rd_data_i;
        end
        else begin
            instr_o <= ins;
            instr_addr_o <= instr_addr_i;
            reg1_rd_data_o <= reg1_rd_data_i;
            reg2_rd_data_o <= reg2_rd_data_i;
            reg_wr_addr_o <= reg_wr_addr;
            imm_o <= imm;
            csr_rw_addr_o <= csr_rw_addr;
            csr_zimm_o <= csr_zimm;
            csr_rd_data_o <= csr_rd_data_i;
        end
    end
    
    // 指令译码模块例化
    id u_id(
        .clk                (clk),
        .rst_n              (rst_n),
        .instr_i              (instr_i), 
        .instr_addr_i         (instr_addr_i),
        .instr_o              (ins), 
        .reg1_rd_addr_o     (reg1_rd_addr_wire), 
        .reg2_rd_addr_o     (reg2_rd_addr_wire),
        .reg_wr_addr_o      (reg_wr_addr),
        .imm_o              (imm),
        //.mem_rd_flag_o      (mem_rd_flag),
        .csr_rw_addr_o      (csr_rw_addr),
        .csr_zimm_o         (csr_zimm)
    );
    
    // 将传给EX单元的内容打一拍
    //id_ex u_id_ex(
    //    .clk                (clk),
    //    .rst_n              (rst_n),
    //    .hold_flag_i        (hold_flag_i),
    //    //.mem_rd_flag_i      (mem_rd_flag),
	//	.keep_flag_i        (keep_flag_i),
    //    .instr_i              (ins), 
    //    .instr_addr_i         (instr_addr_i),
    //    .instr_o              (instr_o), 
    //    .reg1_rd_data_i     (reg1_rd_data_i), 
    //    .reg2_rd_data_i     (reg2_rd_data_i),
    //    .reg_wr_addr_i      (reg_wr_addr),
    //    .imm_i              (imm),
    //    .csr_rd_data_i      (csr_rd_data_i),
    //    .csr_rw_addr_i      (csr_rw_addr),
    //    .csr_zimm_i         (csr_zimm),
    //    .instr_addr_o         (instr_addr_o), 
    //    .reg1_rd_data_o     (reg1_rd_data_o), 
    //    .reg2_rd_data_o     (reg2_rd_data_o),
    //    .reg_wr_addr_o      (reg_wr_addr_o),
    //    .imm_o              (imm_o),
    //    .csr_rd_data_o      (csr_rd_data_o),
    //    .csr_rw_addr_o      (csr_rw_addr_o),
    //    .csr_zimm_o         (csr_zimm_o)
    //    //.mem_rd_rib_req_o   (mem_rd_rib_req_o),
    //    //.mem_rd_addr_o      (mem_rd_addr_o)
    //);
    
endmodule
