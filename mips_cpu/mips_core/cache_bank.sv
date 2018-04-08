module cache_bank #(parameter DATA_WIDTH, parameter ADDR_WIDTH)(
	input clk,    // Clock
	input i_we,
	input logic [DATA_WIDTH - 1 : 0] i_wdata,
	input logic [ADDR_WIDTH - 1 : 0] i_waddr, i_raddr,
	output logic [DATA_WIDTH - 1 : 0] o_rdata
);

	logic [DATA_WIDTH - 1 : 0] new_data;
	logic [DATA_WIDTH - 1 : 0] old_data;
	logic new_data_flag;

	cache_bank_core #(DATA_WIDTH, ADDR_WIDTH)
		BANK_CORE (
			.clk, .i_we, .i_waddr, .i_raddr, .i_wdata,
			.o_rdata(old_data)
	);

	assign o_rdata = new_data_flag ? new_data : old_data;

	always_ff @(posedge clk)
	begin
		new_data <= i_wdata;
		new_data_flag <= i_we & (i_raddr == i_waddr);
	end
endmodule

module cache_bank_core #(parameter DATA_WIDTH, parameter ADDR_WIDTH)(
	input clk,    // Clock
	input i_we,
	input logic [DATA_WIDTH - 1 : 0] i_wdata,
	input logic [ADDR_WIDTH - 1 : 0] i_waddr, i_raddr,
	output logic [DATA_WIDTH - 1 : 0] o_rdata
);
	localparam DEPTH = 1 << ADDR_WIDTH;

	logic [DATA_WIDTH - 1 : 0] data [DEPTH];

	always_ff @(posedge clk)
	begin
		o_rdata <= data[i_raddr];
		if (i_we)
			data[i_waddr] <= i_wdata;
	end
endmodule
