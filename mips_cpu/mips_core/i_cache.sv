/* i_cache.sv
* Author: Pravin P. Prabhu, Zinsser Zhang
* Last Revision: 04/02/2017
* Abstract:
*	Provides caching of instructions from imem for quick access. Note that this
* is a read only cache, and thus self-modifying code is not supported.
* All addresses used in this scope are byte addresses (26-bit)
*/
`include "mips_core.svh"

module i_cache (
	// General signals
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	// Request
	pc_ifc i_pc_current,
	pc_ifc i_pc_next,

	// Response
	cache_output_ifc out,

	// Memory interface
	mem_read_ifc mem_read
);

	localparam TAG_WIDTH = 17;
	localparam INDEX_WIDTH = 5;
	localparam BLOCK_OFFSET_WIDTH = 2;

	localparam LINE_SIZE = 1 << BLOCK_OFFSET_WIDTH;
	localparam DEPTH = 1 << INDEX_WIDTH;

	// Check if the parameters are set correctly
	generate
		if(TAG_WIDTH + INDEX_WIDTH + BLOCK_OFFSET_WIDTH + 2 != `ADDR_WIDTH)
		begin
			INVALID_I_CACHE_PARAM invalid_i_cache_param ();
		end
	endgenerate

	// Parsing
	logic [TAG_WIDTH - 1 : 0] i_tag;
	logic [INDEX_WIDTH - 1 : 0] i_index;
	logic [BLOCK_OFFSET_WIDTH - 1 : 0] i_block_offset;

	logic [INDEX_WIDTH - 1 : 0] i_index_next;

	assign {i_tag, i_index, i_block_offset} = i_pc_current.pc[`ADDR_WIDTH - 1 : 2];
	assign i_index_next = i_pc_next.pc[BLOCK_OFFSET_WIDTH + 2 +: INDEX_WIDTH];
	// Above line uses +: slice, a feature of SystemVerilog
	// See https://stackoverflow.com/questions/18067571

	// States
	enum bit {
		STATE_READY,	// Ready for incoming requests
		STATE_REFILL	// Missing on a read
	} state, next_state;

	// Registers for refilling
	logic [INDEX_WIDTH - 1:0] r_index;
	logic [TAG_WIDTH - 1:0] r_tag;

	// databank signals
	logic [LINE_SIZE - 1 : 0] databank_select;
	logic [LINE_SIZE - 1 : 0] databank_we;
	logic [`DATA_WIDTH - 1 : 0] databank_wdata;
	logic [INDEX_WIDTH - 1 : 0] databank_waddr;
	logic [INDEX_WIDTH - 1 : 0] databank_raddr;
	logic [`DATA_WIDTH - 1 : 0] databank_rdata [LINE_SIZE];

	// databanks
	genvar g;
	generate
		for (g = 0; g < LINE_SIZE; g++)
		begin : databanks
			cache_bank #(
				.DATA_WIDTH (`DATA_WIDTH),
				.ADDR_WIDTH (INDEX_WIDTH)
			) databank (
				.clk,
				.i_we (databank_we[g]),
				.i_wdata(databank_wdata),
				.i_waddr(databank_waddr),
				.i_raddr(databank_raddr),

				.o_rdata(databank_rdata[g])
			);
		end
	endgenerate

	// tagbank signals
	logic tagbank_we;
	logic [TAG_WIDTH - 1 : 0] tagbank_wdata;
	logic [INDEX_WIDTH - 1 : 0] tagbank_waddr;
	logic [INDEX_WIDTH - 1 : 0] tagbank_raddr;
	logic [TAG_WIDTH - 1 : 0] tagbank_rdata;

	cache_bank #(
		.DATA_WIDTH (TAG_WIDTH),
		.ADDR_WIDTH (INDEX_WIDTH)
	) tagbank (
		.clk,
		.i_we    (tagbank_we),
		.i_wdata (tagbank_wdata),
		.i_waddr (tagbank_waddr),
		.i_raddr (tagbank_raddr),

		.o_rdata (tagbank_rdata)
	);

	// Valid bits
	logic [DEPTH - 1 : 0] valid_bits;

	// Intermediate signals
	logic hit, miss;
	logic last_refill_word;


	always_comb
	begin
		hit = valid_bits[i_index]
			& (i_tag == tagbank_rdata)
			& (state == STATE_READY);
		miss = ~hit;
		last_refill_word = databank_select[LINE_SIZE - 1]
			& mem_read.user_available;
	end

	always_comb
	begin
		mem_read.control_base = {i_tag, i_index,
			{BLOCK_OFFSET_WIDTH + 2{1'b0}}};
		mem_read.control_length = LINE_SIZE << 2;
		mem_read.control_go = rst_n && (state == STATE_READY)
			&& (next_state == STATE_REFILL);
		mem_read.user_re = mem_read.user_available;
	end

	always @(posedge clk)
	begin
		assert (!mem_read.control_go || mem_read.control_done) else
			$error("%m (%t) ERROR issuing read reqeust when memory hasn't done processing the last request!", $time);
	end

	always_comb
	begin
		if (mem_read.user_available)
			databank_we = databank_select;
		else
			databank_we = '0;

		databank_wdata = mem_read.user_data;
		databank_waddr = r_index;
		databank_raddr = i_index_next;
	end

	always_comb
	begin
		tagbank_we = last_refill_word;
		tagbank_wdata = r_tag;
		tagbank_waddr = r_index;
		tagbank_raddr = i_index_next;
	end

	always_comb
	begin
		out.valid = hit;
		out.data = databank_rdata[i_block_offset];
	end

	always_comb
	begin
		unique case (state)
			STATE_READY:
			begin
				if (miss)
					next_state = STATE_REFILL;
				else
					next_state = state;
			end
			STATE_REFILL:
			begin
				if (last_refill_word)
					next_state = STATE_READY;
				else
					next_state = state;
			end
		endcase
	end

	always_ff @(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			state <= STATE_READY;
			databank_select <= 1;
			valid_bits <= '0;
		end
		else
		begin
			state <= next_state;

			case (state)
				STATE_READY:
				begin
					if (miss)
					begin
						r_tag <= i_tag;
						r_index <= i_index;
					end
				end
				STATE_REFILL:
				begin
					if (mem_read.user_available)
					begin
						databank_select <= {databank_select[LINE_SIZE - 2 : 0],
							databank_select[LINE_SIZE - 1]};
						valid_bits[r_index] <= last_refill_word;
					end
				end
			endcase
		end
	end
endmodule

module i_cache_databank #(parameter INDEX_WIDTH = 5)(
	input clk,    // Clock
	input i_we,
	input logic [`DATA_WIDTH - 1 : 0] i_wdata,
	input logic [INDEX_WIDTH - 1 : 0] i_waddr, i_raddr,
	output logic [`DATA_WIDTH - 1 : 0] o_rdata
);
	localparam DEPTH = 1 << INDEX_WIDTH;

	logic [`DATA_WIDTH - 1 : 0] data [DEPTH];

	always_ff @(posedge clk)
	begin
		o_rdata <= data[i_raddr];
		if (i_we)
			data[i_waddr] <= i_wdata;
		if (i_we & (i_raddr == i_waddr))
			o_rdata <= i_wdata;
	end
endmodule

module i_cache_tagbank #(parameter TAG_WIDTH = 17, parameter INDEX_WIDTH = 5)(
	input clk,    // Clock
	input i_we,
	input logic [TAG_WIDTH - 1 : 0] i_wdata,
	input logic [INDEX_WIDTH - 1 : 0] i_waddr, i_raddr,
	output logic [TAG_WIDTH - 1 : 0] o_rdata
);
	localparam DEPTH = 1 << INDEX_WIDTH;

	logic [TAG_WIDTH - 1 : 0] data [DEPTH];

	always_ff @(posedge clk)
	begin
		o_rdata <= data[i_raddr];
		if (i_we)
			data[i_waddr] <= i_wdata;
		if (i_we & (i_raddr == i_waddr))
			o_rdata <= i_wdata;
	end
endmodule

