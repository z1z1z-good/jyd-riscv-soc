`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/11 19:50:06
// Design Name: 
// Module Name: tb_top
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


module tb_top();

    // Inputs
    reg i_sys_clk_p;
    reg i_sys_clk_n;
    reg sys_rst_n;
    wire uart_rx;
    
    
    // Outputs
    wire uart_tx;

    
    // 200MHz Clock Generation (Period = 5ns)
    initial begin
        i_sys_clk_p = 0;
        i_sys_clk_n = 1;
        forever #2.5 begin
            i_sys_clk_p = ~i_sys_clk_p;
            i_sys_clk_n = ~i_sys_clk_n;
        end
    end
    initial begin
        sys_rst_n = 0;
        
        #20
        sys_rst_n = 1;
    end


    top u_top(

        .i_sys_clk_p(i_sys_clk_p)         ,
        .i_sys_clk_n(i_sys_clk_n)         ,
        .sys_rst_n  (sys_rst_n)       ,
        .uart_rx    (uart_rx)       ,
        .uart_tx    (uart_tx)       
       
    );

endmodule
