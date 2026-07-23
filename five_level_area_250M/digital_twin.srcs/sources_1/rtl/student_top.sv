`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2025 06:21:13 PM
// Design Name: 
// Module Name: student_top
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
module student_top#(
    parameter                           P_SW_CNT            = 64,
    parameter                           P_LED_CNT           = 32,
    parameter                           P_SEG_CNT           = 40,
    parameter                           P_KEY_CNT           = 8
) (
    input                                       w_cpu_clk     ,
    input                                       w_clk_50Mhz   ,
    input                                       w_clk_rst     ,
    input  [P_KEY_CNT - 1:0]                    virtual_key   ,
    input  [P_SW_CNT  - 1:0]                    virtual_sw    ,

    output [P_LED_CNT - 1:0]                    virtual_led   ,
    output [P_SEG_CNT - 1:0]                    virtual_seg   
);

    // IROM
    logic [13:0] pc;
    logic [11:0] inst_addr;
    logic [31:0] instruction;
    
    //RISCV
    logic        wr_perip_req_o;
    logic [31:0] wr_addr_o;
    logic [31:0] rd_addr_o;
         
    // perip
    logic [31:0] perip_addr, perip_wdata, perip_rdata;
    logic perip_wen;
    logic [31:0] perip_wr_addr ;
    logic [31:0] perip_rd_addr ;
    //logic [1:0] perip_mask;
    assign perip_wr_addr = wr_addr_o ;
    assign perip_rd_addr = rd_addr_o ;
    //assign perip_addr = (wr_perip_req_o && !rd_perip_req_o)?wr_addr_o:
    //                    rd_addr_o;    

    // 16KB = 2^12 * 32bit
    assign inst_addr = pc[13:2];

  //  myCPU Core_cpu (
  //      .cpu_rst            (w_clk_rst),
  //      .cpu_clk            (w_cpu_clk),
  //
  //      // Interface to IROM
  //      .irom_addr          (pc),             
  //      .irom_data          (instruction),   
  //
  //      // Interface to DRAM & periphera
  //      .perip_addr         (perip_addr),     
  //      .perip_wen          (perip_wen),     
  //      .perip_mask         (perip_mask),   
  //      .perip_wdata        (perip_wdata),    
  //      .perip_rdata        (perip_rdata)     
  //  );
    
    RISCV u_RISCV_CORE(
        .clk               (w_cpu_clk),
        .rst_n             (~w_clk_rst),
        .pc_o              (pc),
        .ins_i             (instruction),
        .mem_wr_en_o       (perip_wen),
        .mem_wr_addr_o     (wr_addr_o),
        .mem_wr_data_o     (perip_wdata),
        .mem_rd_addr_o     (rd_addr_o),
        .mem_rd_data_i     (perip_rdata)
    );    

    //IBROM Mem_IROM (w_cpu_clk , inst_addr ,instruction );
    IROM Mem_IROM({2'b0,inst_addr},instruction);
/*         .clk          (w_cpu_clk),
        .pc_addr_i    (inst_addr),
        .ins_o        (instruction) */
    
    perip_bridge bridge_inst (
        .clk				(w_cpu_clk),
        .cnt_clk            (w_clk_50Mhz),
        .rst                (w_clk_rst),
        .perip_wr_addr	    (wr_addr_o),
        .perip_rd_addr      (rd_addr_o),
        .perip_wdata		(perip_wdata),
        .perip_wen			(perip_wen),
        .perip_mask			(),//don't care 
        .perip_rdata		(perip_rdata),
        .virtual_sw_input	(virtual_sw),
        .virtual_key_input	(virtual_key),	
        .virtual_seg_output	(virtual_seg),
        .virtual_led_output (virtual_led)
    );

endmodule
