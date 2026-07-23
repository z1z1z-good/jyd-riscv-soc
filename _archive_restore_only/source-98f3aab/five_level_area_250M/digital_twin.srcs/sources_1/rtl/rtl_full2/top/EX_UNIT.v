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

    //input   wire[`INST_ADDR_BUS]    mem_rd_addr_i       ,
    //input   wire[`INST_DATA_BUS]    mem_rd_data_i       ,
    //output  wire                    mem_wr_rib_req_o    ,
    //output  wire                    mem_wr_en_o         , 
    //output  wire[`INST_ADDR_BUS]    mem_wr_addr_o       , 
    //output  wire[`INST_DATA_BUS]    mem_wr_data_o       ,
    output	  wire                  not_mem             ,
	output	  wire[`INST_REG_DATA]  reg_wr_data_first_o       ,//为了让数据提前到�?
	output	  wire                  keep_flag_o         ,
    output  reg                      mem_rd_rib_req_o  ,
    (* max_fanout = 32 ,preserve = "true", keep = "true" *) output  reg  [`INST_ADDR_BUS]     mem_rd_addr_o      ,
	(* max_fanout = 32 ,preserve = "true", keep = "true" *) output	reg [`INST_ADDR_BUS]     mem_rd_addr_to_mem 
    
    );
    (* preserve = "true", keep = "true" *)reg keep_flag_reg1 = 0;
	(* preserve = "true", keep = "true" *)reg keep_flag_reg2 = 0;
	wire keep_flag ;
	//wire keep_flag_return;
	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			keep_flag_reg1 <= 1'b0;
			keep_flag_reg2 <= 1'b0;
			mem_rd_addr_to_mem <= 32'b0;
		end
		else begin
			keep_flag_reg1 <= keep_flag ;
			keep_flag_reg2 <= keep_flag_reg1;
			mem_rd_addr_to_mem <= mem_rd_addr_o;
		end
	end
	assign keep_flag_o = keep_flag & keep_flag_reg1 ;
	//assign keep_flag_return = keep_flag_reg2;
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
    
	//wire  is_load;
	//wire  is_save;
	
    assign div_busy_o = div_busy;
    assign div_req_o = div_req;
    assign jump_flag_o = jump_flag;
    assign jump_addr_o = jump_addr;
    
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
	//assign mem_rd_addr_o = mem_rd_addr_i;
//assign is_load = (opcode == `INS_TYPE_LOAD);
//assign is_save = (opcode == `INS_TYPE_SAVE);


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
    cu u_cu(
        .clk                 (clk),
        .rst_n               (rst_n),
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
		.not_mem             (not_mem    ),
		.keep_flag_o         (keep_flag),
		.keep_flag_return    (keep_flag_reg2)
    );
    
    
endmodule
