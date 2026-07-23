(* keep_hierarchy="yes", optimize="off" *)
module ram(
    input   wire                    clk,
    input   wire                    wr_en_i,
    input   wire [15:0]             wr_addr_i,
    input   wire [`INST_DATA_BUS]    wr_data_i,
    input   wire [15:0]             rd_addr_i,
    output  wire [`INST_DATA_BUS]    rd_data_o
);
    //=========== 绝对防优化声�? ===========//
    (* dont_touch = "true", keep = "true" *)
    wire [15:0] rd_addr;
    (* dont_touch = "true", keep = "true" *)
    wire [15:0] wr_addr;
    (* dont_touch = "true", keep = "true" *)
    wire [`INST_DATA_BUS] rd_data_bram;
    (* dont_touch = "true", keep = "true" *)
    wire [`INST_DATA_BUS] wr_data_bram;
    (* dont_touch = "true", keep = "true" *)
    wire [`INST_DATA_BUS] war_data;
	reg [31:0] rd_data_reg ;
    always@(posedge clk)begin
	rd_data_reg  <= rd_data_bram ;
	end
    //=========== 强制保留连接 ===========//
    assign rd_addr = rd_addr_i;
    assign rd_data_o = rd_data_reg;
    assign wr_addr = wr_addr_i;
	assign wr_data_bram = wr_data_i;
    //=========== BRAM IP核实例化 ===========//
    blk_mem_gen_0 uut_BLOCKRAM (
        .clka(clk),
        .wea(wr_en_i),
        .addra(wr_addr),
        .dina(wr_data_bram),
		.douta(war_data),
        .clkb(clk),
		.web(1'b0),
        .addrb(rd_addr),      // 受保护的地址输入
		.dinb(32'b0),
        .doutb(rd_data_bram) , // 受保护的数据输出
		.ena(1'b1),
		.enb(1'b1)
    );


endmodule