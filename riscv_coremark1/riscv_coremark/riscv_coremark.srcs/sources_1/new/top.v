`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/10 00:29:15
// Design Name: 
// Module Name: top
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


module top(

    input  wire i_sys_clk_p         ,
    input  wire i_sys_clk_n         ,
    input  wire sys_rst_n         ,
    input  wire uart_rx           ,
    output wire uart_tx           
       
    );
  wire clk;
  wire [3:0] gpio_pins;

  clk_wiz_0 pll_inst(
        .clk_in1_p(i_sys_clk_p),
        .clk_in1_n(i_sys_clk_n),
        .clk_out1(clk)
    );

  
 RISCV_SOC_TOP RISCV_SOC_TOP_INST(

    .sys_clk       (clk)          ,
    .sys_rst_n       (sys_rst_n)    ,

    .uart_debug_pin    (1'b1)  , // uart_debug使能引脚
    .uart_rx           (uart_rx)  , // uart接收引脚
    .uart_tx          (uart_tx)   , // uart发送引脚

    .gpio_pins         (gpio_pins)    // led引脚资源               
    
    );   
    
    
    
    
    
    
    
    
endmodule
