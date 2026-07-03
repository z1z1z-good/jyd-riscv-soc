`timescale 1ns / 1ps
`include "../core/defines.v"
(* keep_hierarchy="yes", optimize="off" *)
module rom(

    input   wire                    clk         ,
    input   wire                    rst_n       ,
    input   wire[15:0]    pc_addr_i   , // instruction read address
    output  wire[`INST_DATA_BUS]    ins_o         // instruction
    
    );
    
    (* preserve="true", keep="true" *)reg[15:0]    pc_addr_reg;
    (* ram_style = "block" *)reg[`INST_DATA_BUS] _rom[0:4095];  
    // 读取�?要固化在rom里面的程序，方便仿真
    //initial begin
    //    $readmemh("../../serial_utils/binary/led_flow.inst", _rom);
    //end
    
    initial begin
        $readmemh("C:\\Users\\86138\\Desktop\\vivado_file\\JYD2025_Contest-Template0005\\JYD2025_Contest-Template0003\\digital_twin.srcs\\sources_1\\imports\\test_src\\test.hex", _rom);
    end                             
    
    // write before read
    always @ (posedge clk or negedge rst_n) begin
        if(~rst_n)begin
        pc_addr_reg <= 16'b0;
        end else begin
        pc_addr_reg <= pc_addr_i;
        end
    end
    
    assign ins_o = _rom[pc_addr_reg];

endmodule
