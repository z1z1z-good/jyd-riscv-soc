`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/01 12:40:31
// Design Name: 
// Module Name: student_top_tb
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



module student_top_tb();

// 输入信号
reg         w_cpu_clk;
reg         w_clk_50Mhz;
reg         w_clk_rst;
reg  [7:0]  virtual_key;
reg  [63:0] virtual_sw;

// 输出信号
wire [31:0] virtual_led;
wire [39:0] virtual_seg;

// 实例化被测模�?
student_top uut (
    .w_cpu_clk     (w_cpu_clk),
    .w_clk_50Mhz   (w_clk_50Mhz),
    .w_clk_rst     (w_clk_rst),
    .virtual_key    (virtual_key),
    .virtual_sw     (virtual_sw),
    .virtual_led    (virtual_led),
    .virtual_seg    (virtual_seg)
);

// 生成100MHz CPU时钟（周�?10ns�?
initial begin
    w_cpu_clk = 0;
    forever #5 w_cpu_clk = ~w_cpu_clk;
end

// 生成50MHz时钟（周�?20ns�?
initial begin
    w_clk_50Mhz = 0;
    forever #10 w_clk_50Mhz = ~w_clk_50Mhz;
end

// 测试�?�?
initial begin
    // 初始化信�?
    w_clk_rst   = 1;        // 复位有效
    //virtual_sw  = 64'h0;    // �?有开关关�?
    //virtual_key = 8'h0;     // �?有按键释�?
    
    // 保持复位状�??100ns
    #100;
    w_clk_rst = 0;          // 释放复位
    

    
    // 仿真运行1ms后结�?
    //#1000;
    //$finish;
end

// 监控关键信号变化
initial begin
    //$display("MULUSHI:%s",$cd);
    $monitor("Time = %4tns | SW = %h | KEY = %b | LED = %h | SEG = %h", 
        $time, virtual_sw, virtual_key, virtual_led, virtual_seg);
end

endmodule