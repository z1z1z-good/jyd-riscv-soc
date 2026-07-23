/* module ram(
    input   wire                    clk,
    input   wire                    wr_en_i,
    input   wire [15:0]             wr_addr_i,
    input   wire [`INST_DATA_BUS]    wr_data_i,
    input   wire [15:0]             rd_addr_i,
    output  wire [`INST_DATA_BUS]    rd_data_o
);
    //=========== 绝对防优化声�? ===========//
	//根据高位决定哪个ram
    wire [11:0] rd_addr;
    wire [11:0] wr_addr;
	wire [1:0]  rd_select = rd_addr_i[13:12] ;
	wire [1:0]  wr_select = wr_addr_i[13:12] ;
	reg  rd_select_01 ;
	reg  rd_select_02 ;
	reg  rd_select_03 ;
	reg  rd_select_04 ;
    wire [`INST_DATA_BUS] rd_data_bram01;
    wire [`INST_DATA_BUS] rd_data_bram02;
    wire [`INST_DATA_BUS] rd_data_bram03;
    wire [`INST_DATA_BUS] rd_data_bram04;
    wire [`INST_DATA_BUS] wr_data_bram;
	reg [13:0] wr_addr_reg , rd_addr_reg  = 0;
	reg [31:0] wr_data_reg  = 0;
    reg wr_en_reg  = 0;
	always@(posedge clk)begin
	wr_addr_reg <= wr_addr_i[13:0];
	rd_addr_reg <= rd_addr_i[13:0];
	wr_en_reg <= wr_en_i ;
    wr_data_reg <= wr_data_i ;
	rd_select_01 <= (rd_select == 2'b00)  ;
	rd_select_02 <= (rd_select == 2'b01)  ;
	rd_select_03 <= (rd_select == 2'b10)  ;
	rd_select_04 <= (rd_select == 2'b11)  ;
	end
    //=========== 强制保留连接 ===========//
    assign rd_addr = rd_addr_i[11:0];
    assign rd_data_o = (wr_addr_reg == rd_addr_reg & wr_en_reg)?wr_data_reg:rd_select_01?rd_data_bram01:rd_select_02?rd_data_bram02:
	rd_select_03?rd_data_bram03:rd_select_04?rd_data_bram04 :32'b0;
    //assign rd_data_o = wr_data_reg ;
    assign wr_addr = wr_addr_i[11:0];
	assign wr_data_bram = wr_data_i;
	wire wr_select_01 = wr_en_i & (wr_select == 2'b00);
	wire wr_select_02 = wr_en_i & (wr_select == 2'b01);
	wire wr_select_03 = wr_en_i & (wr_select == 2'b10);
	wire wr_select_04 = wr_en_i & (wr_select == 2'b11);
    //=========== BRAM IP核实例化 ===========//
    blk_mem_gen_0 uut_BLOCKRAM01 (
        .clka(clk),
        .wea(wr_select_01),
        .addra(wr_addr),
        .dina(wr_data_bram),
		//.douta(war_data),
        .clkb(clk),
		//.web(1'b0),
        .addrb(rd_addr),      // 受保护的地址输入
		//.dinb(32'b0),
        .doutb(rd_data_bram01) , // 受保护的数据输出
		.ena(1'b1),
		.enb(1'b1)
    );
    blk_mem_gen_0 uut_BLOCKRAM02 (
        .clka(clk),
        .wea(wr_select_02),
        .addra(wr_addr),
        .dina(wr_data_bram),
		//.douta(war_data),
        .clkb(clk),
		//.web(1'b0),
        .addrb(rd_addr),      // 受保护的地址输入
		//.dinb(32'b0),
        .doutb(rd_data_bram02) , // 受保护的数据输出
		.ena(1'b1),
		.enb(1'b1)
    );    
	blk_mem_gen_0 uut_BLOCKRAM03 (
        .clka(clk),
        .wea(wr_select_03),
        .addra(wr_addr),
        .dina(wr_data_bram),
		//.douta(war_data),
        .clkb(clk),
		//.web(1'b0),
        .addrb(rd_addr),      // 受保护的地址输入
		//.dinb(32'b0),
        .doutb(rd_data_bram03) , // 受保护的数据输出
		.ena(1'b1),
		.enb(1'b1)
    );    
	blk_mem_gen_0 uut_BLOCKRAM04 (
        .clka(clk),
        .wea(wr_select_04),
        .addra(wr_addr),
        .dina(wr_data_bram),
		//.douta(war_data),
        .clkb(clk),
		//.web(1'b0),
        .addrb(rd_addr),      // 受保护的地址输入
		//.dinb(32'b0),
        .doutb(rd_data_bram04) , // 受保护的数据输出
		.ena(1'b1),
		.enb(1'b1)
    );

endmodule */

module ram(
    input   wire                    clk,
    input   wire                    wr_en_i,
    input   wire [15:0]             wr_addr_i,
    input   wire [`INST_DATA_BUS]    wr_data_i,
    input   wire [15:0]             rd_addr_i,
    output  wire [`INST_DATA_BUS]    rd_data_o
);
    //=========== 绝对防优化声�? ===========//
    wire [15:0] rd_addr;
    wire [15:0] wr_addr;
    wire [`INST_DATA_BUS] rd_data_bram;
    wire [`INST_DATA_BUS] wr_data_bram;
	reg [31:0] wr_data_reg ;
	reg need_hypass_reg = 0;
	always@(posedge clk)begin
    wr_data_reg <= wr_data_i ;
	need_hypass_reg <= (wr_addr == rd_addr)& wr_en_i ;
	end
    //=========== 强制保留连接 ===========//
    assign rd_addr = rd_addr_i[15:0];
    assign rd_data_o = need_hypass_reg ?wr_data_reg:rd_data_bram;
    //assign rd_data_o = wr_data_reg ;
    assign wr_addr = wr_addr_i[15:0];
	assign wr_data_bram = wr_data_i;
    //=========== BRAM IP核实例化 ===========//
    blk_mem_gen_0 uut_BLOCKRAM (
        .clka(clk),
        .wea(wr_en_i),
        .addra(wr_addr),
        .dina(wr_data_bram),
		//.douta(war_data),
        .clkb(clk),
		//.web(1'b0),
        .addrb(rd_addr),      // 受保护的地址输入
		//.dinb(32'b0),
        .doutb(rd_data_bram) 

    );


endmodule
/* module ram(
    input   wire                    clk,
    input   wire                    wr_en_i,
    input   wire [15:0]             wr_addr_i,
    input   wire [`INST_DATA_BUS]    wr_data_i,
    input   wire [15:0]             rd_addr_i,
    output  wire [`INST_DATA_BUS]    rd_data_o
);
    //=========== 绝对防优化声�? ===========//
    wire [13:0] rd_addr;
    wire [13:0] wr_addr;
    wire [`INST_DATA_BUS] rd_data_bram;
    wire [`INST_DATA_BUS] wr_data_bram;
    wire [`INST_DATA_BUS] war_data;
	reg [13:0] wr_addr_reg , rd_addr_reg ;
	reg [31:0] wr_data_reg ;
    reg wr_en_reg;
	always@(posedge clk)begin
	wr_addr_reg <= wr_addr_i[13:0];
	rd_addr_reg <= rd_addr_i[13:0];
	wr_en_reg <= wr_en_i ;
    wr_data_reg <= wr_data_i ;
	end
    //=========== 强制保留连接 ===========//
    assign rd_addr = rd_addr_i[13:0];
    assign rd_data_o = (wr_addr_reg == rd_addr_reg & wr_en_reg)?wr_data_reg:rd_data_bram;
    //assign rd_data_o = wr_data_reg ;
    assign wr_addr = wr_addr_i[13:0];
	assign wr_data_bram = wr_data_i;

    DRAM u_DRAM
	(
	.a (wr_addr),
	.d (wr_data_bram),
	.dpra(rd_addr),
	.clk(clk),
	.we(wr_en_i),
	.qdpo(rd_data_bram)
	);

endmodule */