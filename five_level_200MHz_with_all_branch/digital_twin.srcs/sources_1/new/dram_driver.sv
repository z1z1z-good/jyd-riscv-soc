`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 11:42:01 AM
// Design Name: 
// Module Name: dram_driver
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

module dram_driver(
    input  logic         clk				,

    input  logic [17:0]  perip_wr_addr			,
    input  logic [17:0]  perip_rd_addr    ,
    input  logic [31:0]  perip_wdata		,
	input  logic [1:0]	 perip_mask			,
    input  logic         dram_wen           ,
    output logic [31:0]  perip_rdata		
);
    /*ram Mem_DRAM (
        .clk        (clk),
        .a          (dram_addr),
        .spo        (dram_rdata_raw),
        .we         (dram_wen),
        .d          (dram_data)
    );*/
    wire [15:0] wr_addr = perip_wr_addr[17:2];
    wire [15:0] rd_addr = perip_rd_addr[17:2];
   ram Mem_DRAM
   (
   .clk       (clk)  ,
   .wr_en_i   (dram_wen)  ,
   .wr_addr_i (wr_addr)  ,
   .wr_data_i (perip_wdata)  ,
   .rd_addr_i (rd_addr)  ,
   .rd_data_o (perip_rdata)
   
   );
endmodule
