`timescale 1ns / 1ps
`include "../core/defines.v"

// 鎵ц鍗曞厓
module EXU(

    input   wire                    clk                 ,
    input   wire                    rst_n               ,
    
    // from ID_UNIT
    input   wire[`INST_DATA_BUS]    instr_i               ,     
    input   wire[`INST_ADDR_BUS]    instr_addr_i          , 
    input   wire[`INST_REG_DATA]    imm_i               , 
    
    // from ID_UNIT
    input   wire[`INST_REG_DATA]    csr_rd_data_i       ,    
    input   wire[`INST_ADDR_BUS]    csr_rw_addr_i       ,
    input   wire[`INST_REG_DATA]    csr_zimm_i          ,
    // to RF_UNIT
    output  wire                    csr_wr_en_o         , 
    output  wire[`INST_ADDR_BUS]    csr_wr_addr_o       , 
    output  wire[`INST_REG_DATA]    csr_wr_data_o       , 
    
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
    output	reg [`INST_DATA_BUS]    instr_o        		,
	output	reg					is_load_o			,
	output	reg					is_save_o			,
	
    input   wire                    rib_hold_flag_i     ,
    // to IF_UNIT銆乧lint
    output  wire                    jump_flag_o         ,
    output  wire[`INST_REG_DATA]    jump_addr_o         ,
    output  reg [2:0]               hold_flag_o         ,

    //input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
    //input   wire[`INST_DATA_BUS]    mem_rd_data_i       ,
    //output  wire                    mem_wr_rib_req_o    ,
    //output  wire                    mem_wr_en_o         , 
    //output  wire[`INST_ADDR_BUS]    mem_wr_addr_o       , 
    //output  wire[`INST_DATA_BUS]    mem_wr_data_o       ,
    output	  wire                  not_mem             ,
	output	  wire[`INST_REG_DATA]  reg_wr_data_first_o       ,//为了让数据提前到达
	output	  wire                  keep_flag_o         ,
    // from clint
    input   wire                    clint_busy_i        , 
    input   wire[`INST_ADDR_BUS]    int_addr_i          , 
    input   wire                    int_assert_i        ,  
    // to clint
    output  wire                    div_busy_o          ,
    output  wire                    div_req_o           ,
	
    output  reg                      mem_rd_rib_req_o  ,
    output  reg [`INST_ADDR_BUS]     mem_rd_addr_o      ,
	output	wire[`INST_ADDR_BUS]     mem_rd_addr_to_mem 
    
    );
    reg keep_flag_reg1;
	reg keep_flag_reg2;
	wire keep_flag_return;
	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			keep_flag_reg1 <= 1'b0;
			keep_flag_reg2 <= 1'b0;
		end
		else begin
			keep_flag_reg1 <= keep_flag_o ;
			keep_flag_reg2 <= keep_flag_reg1;
		end
	end
    assign mem_rd_addr_to_mem = mem_rd_addr_o;
	assign keep_flag_return = keep_flag_reg2;
	wire                    reg_wr_en         ;
	wire[`INST_REG_ADDR]    reg_wr_addr       ;
	wire[`INST_REG_DATA]    reg_wr_data       ;
    wire[`INST_REG_DATA]     alu_data1;
    wire[`INST_REG_DATA]     alu_data2;
    wire[3:0]                alu_op_code;
    wire[`INST_REG_DATA]     alu_res;
    wire                     alu_zero_flag;
    wire                     alu_sign_flag;
    wire                     alu_overflow_flag;
    wire[2:0]                mul_op_code;
    wire[`INST_DB_REG_DATA]  mul_res;
    wire[2:0]                div_op_code;
    wire                     div_req;      
    wire                     div_busy;
    wire[`INST_REG_ADDR]     div_reg_wr_addr;
    wire                     div_res_ready;
    wire[`INST_REG_DATA]     div_res;
    wire                     jump_flag;
    wire[`INST_ADDR_BUS]     jump_addr;
    wire                     hold_flag;
    //reg [`INST_ADDR_BUS]     mem_rd_addr;
    
	wire  is_load;
	wire  is_save;
	
    assign div_busy_o = div_busy;
    assign div_req_o = div_req;
    assign jump_flag_o = int_assert_i ? 1'b1 : jump_flag;
    assign jump_addr_o = int_assert_i ? int_addr_i : jump_addr;
    
	assign reg_wr_data_first_o = reg_wr_data;
	
    wire [6:0]      opcode;
    wire [2:0]      funct3;
    wire [6:0]      funct7;
    assign opcode = instr_i[6:0];
    assign funct3 = instr_i[14:12];
    assign funct7 = instr_i[31:25];
    always @ (posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
	        instr_o <= `ZERO_WORD;
			reg_wr_addr_o <= 5'b0;
			reg_wr_data_o <= `ZERO_WORD;
			reg_wr_en_o   <= 1'b0;
			reg2_rd_data_o <= `ZERO_WORD;
			is_load_o <= 1'b0;
			is_save_o <= 1'b0;
	    end
	    else begin
	        instr_o <= instr_i;
			reg_wr_addr_o <= reg_wr_addr     ;
			reg_wr_data_o <= reg_wr_data     ;
			reg_wr_en_o   <= reg_wr_en       ;
			reg2_rd_data_o <= reg2_rd_data_i;
			is_load_o <= is_load;
			is_save_o <= is_save;
	    end
	end
	always @ (posedge clk) begin
        if(is_load | is_save) begin
            mem_rd_rib_req_o = 1'b1;
            mem_rd_addr_o = $signed(reg1_rd_data_i) + $signed(imm_i);
        end
        else begin
            mem_rd_rib_req_o = 1'b0;
            mem_rd_addr_o = `ZERO_WORD;
        end
    end
	
assign is_load = (opcode == `INS_TYPE_LOAD)?1'b1:1'b0;
assign is_save = (opcode == `INS_TYPE_SAVE)?1'b1:1'b0;

    // 璇诲嚭鐨勬暟鎹欢鍚庣殑涓€涓椂閽熷懆鏈燂紝鎵€浠ュ唴瀛樿鍦板潃涔熼渶瑕佸欢杩熶竴涓椂閽熷懆鏈    //always @ (posedge clk or negedge rst_n) begin
    //    if(!rst_n) begin
    //        mem_rd_addr <= `ZERO_WORD;
    //    end
    //    else begin
    //        mem_rd_addr <= mem_rd_addr_i;
    //    end
    //end
    
    // 鏆傚仠娴佹按绾挎帶鍒朵俊鍙hold_flag_o
    always @ (*) begin
        // 鏆傚仠鏁翠釜娴佹按绾        
		if(jump_flag_o == 1'b1 || hold_flag == 1'b1 || div_busy == 1'b1 || clint_busy_i == 1'b1) begin
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
    
    // 鎺у埗妯″潡渚嬪寲
     ex u_ex(
        .clk                 (clk),
        .rst_n               (rst_n),
        .instr_addr_i          (instr_addr_i), 
        .opcode_i            (opcode),
        .funct3_i            (funct3),
        .funct7_i            (funct7),
        .imm_i               (imm_i),  
        .alu_res_i           (alu_res),
        .alu_zero_flag_i     (alu_zero_flag),
        .alu_sign_flag_i     (alu_sign_flag),
        .alu_overflow_flag_i (alu_overflow_flag),
        .alu_op_code_o       (alu_op_code),
        .alu_data1_o         (alu_data1), 
        .alu_data2_o         (alu_data2),
        .mul_res_i           (mul_res),
        .mul_op_code_o       (mul_op_code),
        .div_res_i           (div_res),
        .div_res_ready_i     (div_res_ready), 
        .div_reg_wr_addr_i   (div_reg_wr_addr),
        .div_req_o           (div_req), 
        .div_op_code_o       (div_op_code),        
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
		.not_mem             (not_mem    ),
		.keep_flag_o         (keep_flag_o),
		.keep_flag_return    (keep_flag_return),
        //.mem_rd_addr_i       (mem_rd_addr),
        //.mem_rd_data_i       (mem_rd_data_i),
        //.mem_wr_rib_req_o    (mem_wr_rib_req_o),
        //.mem_wr_en_o         (mem_wr_en_o), 
        //.mem_wr_addr_o       (mem_wr_addr_o), 
        //.mem_wr_data_o       (mem_wr_data_o),
        .csr_rw_addr_i       (csr_rw_addr_i),
        .csr_zimm_i          (csr_zimm_i),
        .csr_rd_data_i       (csr_rd_data_i),
        .csr_wr_en_o         (csr_wr_en_o),
        .csr_wr_addr_o       (csr_wr_addr_o),
        .csr_wr_data_o       (csr_wr_data_o)
    );
    
    // alu杩愮畻妯″潡渚嬪寲
    alu u_alu(
        .alu_data1_i         (alu_data1), 
        .alu_data2_i         (alu_data2),
        .alu_op_code_i       (alu_op_code),
        .alu_res_o           (alu_res),
        .alu_zero_flag_o     (alu_zero_flag),
        .alu_sign_flag_o     (alu_sign_flag),
        .alu_overflow_flag_o (alu_overflow_flag)
    );
    
    // 涔樻硶妯″潡渚嬪寲
    mul u_mul(
        .mul_data1_i         (reg1_rd_data_i), 
        .mul_data2_i         (reg2_rd_data_i),
        .mul_op_code_i       (mul_op_code),
        .mul_res_o           (mul_res)
    );
    
    // 闄ゆ硶妯″潡渚嬪寲
    div u_div(
        .clk                 (clk),
        .rst_n               (rst_n),
        .div_data1_i         (reg1_rd_data_i), 
        .div_data2_i         (reg2_rd_data_i),
        .div_op_code_i       (div_op_code),
        .div_req_i           (div_req), 
        .div_reg_wr_addr_i   (reg_wr_addr_i),
        .div_reg_wr_addr_o   (div_reg_wr_addr),
        .div_busy_o          (div_busy), 
        .div_res_ready_o     (div_res_ready), 
        .div_res_o           (div_res)  
    );
    
    
endmodule
