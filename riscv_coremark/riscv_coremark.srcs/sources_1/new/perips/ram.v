
`include "../core/defines.v"



module ram(
    input   wire                    clk,
	input   wire                    rst_n ,
    input   wire                    wr_en_i,
    input   wire [`INST_ADDR_BUS]   wr_addr_i,
    input   wire [`INST_DATA_BUS]   wr_data_i,
    input   wire [`INST_ADDR_BUS]   rd_addr_i,
    output  wire [`INST_DATA_BUS]   rd_data_o
);
    //=========== 绝对防优化声昿 ===========//
    reg  [`INST_DATA_BUS] rd_data_bram = 0;
    wire [`INST_DATA_BUS] wr_data_bram;
	reg [31:0] wr_data_reg = 0;
	reg need_hypass_reg = 0;
	always@(posedge clk)begin
    wr_data_reg <= wr_data_i ;
	need_hypass_reg <= (wr_addr_i[31:2] == rd_addr_i[31:2])& wr_en_i ;
	end
    //=========== 强制保留连接 ===========//
    assign rd_data_o = need_hypass_reg ?wr_data_reg:rd_data_bram;
    //assign rd_data_o = wr_data_reg ;
	assign wr_data_bram = wr_data_i;
	
	reg [31:0] bram[0:`RAM_NUM - 1] ;
	always@(posedge clk)begin
	    if(wr_en_i)begin
		    bram[wr_addr_i[31:2]] <= wr_data_bram;
		end
	end
	always@(posedge clk)begin
	    rd_data_bram <= bram[rd_addr_i[31:2]] ;
	end

endmodule