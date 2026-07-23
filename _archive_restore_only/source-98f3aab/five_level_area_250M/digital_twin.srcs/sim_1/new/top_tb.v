`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/27 12:22:56
// Design Name: 
// Module Name: top_tb
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


module top_tb();




    // Inputs
    reg i_sys_clk_p;
    reg i_sys_clk_n;
    reg i_uart_rx;
    
    // Outputs
    wire o_uart_tx;
    wire [31:0] virtual_led;
    wire [39:0] virtual_seg;
    
    // 200MHz Clock Generation (Period = 5ns)
    initial begin
        i_sys_clk_p = 0;
        i_sys_clk_n = 1;
        forever #2.5 begin
            i_sys_clk_p = ~i_sys_clk_p;
            i_sys_clk_n = ~i_sys_clk_n;
        end
    end
    
    // Instantiate DUT
    top uut (
        .i_sys_clk_p(i_sys_clk_p),
        .i_sys_clk_n(i_sys_clk_n),
        .i_uart_rx(i_uart_rx),
        .o_uart_tx(o_uart_tx),
        .virtual_led(virtual_led),
        .virtual_seg(virtual_seg)
    );    
    
    
    
    
endmodule
