`include "mips_core.svh"

interface d_cache_input_ifc ();
	logic valid;
	mips_core_pkg::MemAccessType mem_action;
	logic [`ADDR_WIDTH - 1 : 0] addr;
	logic [`ADDR_WIDTH - 1 : 0] addr_next;
	logic [`DATA_WIDTH - 1 : 0] data;
endinterface

module d_cache (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	// Request
	d_cache_input_ifc in,

	// Response
	cache_output_ifc out,

	// Memory interfaces
	mem_read_ifc mem_read,
	mem_write_ifc mem_write
);

	localparam TAG_WIDTH = 13;
	localparam INDEX_WIDTH = 9;
	localparam BLOCK_OFFSET_WIDTH = 2;

	localparam LINE_SIZE = 1 << BLOCK_OFFSET_WIDTH;
	localparam DEPTH = 1 << INDEX_WIDTH;

	// Check if the parameters are set correctly
	generate
		if(TAG_WIDTH + INDEX_WIDTH + BLOCK_OFFSET_WIDTH + 2 != `ADDR_WIDTH)
		begin
			INVALID_D_CACHE_PARAM invalid_d_cache_param ();
		end
	endgenerate

	// Parsing
	logic [TAG_WIDTH - 1 : 0] i_tag;
	logic [INDEX_WIDTH - 1 : 0] i_index;
	logic [BLOCK_OFFSET_WIDTH - 1 : 0] i_block_offset;

	logic [INDEX_WIDTH - 1 : 0] i_index_next;

	assign {i_tag, i_index, i_block_offset} = in.addr[`ADDR_WIDTH - 1 : 2];
	assign i_index_next = in.addr_next[BLOCK_OFFSET_WIDTH + 2 +: INDEX_WIDTH];
	// Above line uses +: slice, a feature of SystemVerilog
	// See https://stackoverflow.com/questions/18067571

	// States
	enum bit [1:0] {
		STATE_READY,	// Ready for incoming requests
		STATE_FLUSH,	// Writes out a dirty cache line
		STATE_WAIT,		// Wait for flush to be done
		STATE_REFILL	// Loads a cache line from memory
	} state, next_state;

	// Registers for flushing and refilling
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
	// Dirty bits
	logic [DEPTH - 1 : 0] dirty_bits;

	// Shift registers for flushing
	logic [`DATA_WIDTH - 1 : 0] shift_rdata[LINE_SIZE];

	// Intermediate signals
	logic hit, miss;
	logic last_flush_word;
	logic last_refill_word;

	always_comb
	begin
		hit = in.valid
			& valid_bits[i_index]
			& (i_tag == tagbank_rdata)
			& (state == STATE_READY);
		miss = in.valid & ~hit;
		last_flush_word = databank_select[LINE_SIZE - 1] & mem_write.user_we;
		last_refill_word = databank_select[LINE_SIZE - 1] & mem_read.user_available;
	end

	always_comb
	begin
		mem_write.control_base = {tagbank_rdata, i_index, {BLOCK_OFFSET_WIDTH + 2{1'b0}}};
		mem_write.control_length = LINE_SIZE << 2;
		mem_write.control_go = rst_n & (state != STATE_FLUSH) & (next_state == STATE_FLUSH);
		mem_write.user_we = state == STATE_FLUSH;
		mem_write.user_data = shift_rdata[0];
	end

	always_comb
	begin
		mem_read.control_base = {
			(state == STATE_READY
				? {i_tag, i_index}
				: {r_tag, r_index}),
			{BLOCK_OFFSET_WIDTH + 2{1'b0}}
		};
		mem_read.control_length = LINE_SIZE << 2;
		mem_read.control_go =rst_n &  (state != STATE_REFILL) & (next_state == STATE_REFILL);
		mem_read.user_re = mem_read.user_available;
	end

	always @(posedge clk)
	begin
		assert (!mem_write.control_go || mem_write.control_done) else
			$error("%m (%t) ERROR issuing write reqeust when memory hasn't done processing the last request!", $time);

		// If the following assertion failed, your line size is probably too large
		assert (!mem_write.user_we || !mem_write.user_full) else
			$error("%m (%t) ERROR flushing data when buffer is full", $time);

		assert (!mem_read.control_go || mem_read.control_done) else
			$error("%m (%t) ERROR issuing read reqeust when memory hasn't done processing the last request!", $time);
	end

	always_comb
	begin
		databank_we <= '0;
		if (mem_read.user_available)
			databank_we <= databank_select;
		else if (hit & (in.mem_action == WRITE))
			databank_we[i_block_offset] <= 1'b1;
	end

	always_comb
	begin
		if (state == STATE_READY)
		begin
			databank_wdata = in.data;
			databank_waddr = i_index;
			if (next_state == STATE_FLUSH)
				databank_raddr = i_index;
			else
				databank_raddr = i_index_next;
		end
		else
		begin
			databank_wdata = mem_read.user_data;
			databank_waddr = r_index;
			if (next_state == STATE_READY)
				databank_raddr = i_index_next;
			else
				databank_raddr = r_index;
		end
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
				begin
					if (valid_bits[i_index] & dirty_bits[i_index])
						next_state = STATE_FLUSH;
					else
						next_state = STATE_REFILL;
				end
				else
					next_state = state;
			end

			STATE_FLUSH:
			begin
				if (last_flush_word)
					next_state = STATE_WAIT;
				else
					next_state = state;
			end

			STATE_WAIT:
			begin
				if (mem_write.control_done)
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

	always_ff @(posedge clk)
	begin
		for (int i = 0; i < LINE_SIZE - 1; i++)
			shift_rdata[i] <= shift_rdata[i+1];

		if (state == STATE_READY && next_state == STATE_FLUSH)
			for (int i = 0; i < LINE_SIZE; i++)
				shift_rdata[i] <= databank_rdata[i];
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
					else if (in.mem_action == WRITE)
						dirty_bits[i_index] <= 1'b1;
				end

				STATE_FLUSH:
				begin
					databank_select <= {databank_select[LINE_SIZE - 2 : 0],
						databank_select[LINE_SIZE - 1]};
				end

				STATE_REFILL:
				begin
					if (mem_read.user_available)
						databank_select <= {databank_select[LINE_SIZE - 2 : 0],
							databank_select[LINE_SIZE - 1]};

					if (last_refill_word)
					begin
						valid_bits[r_index] <= 1'b1;
						dirty_bits[r_index] <= 1'b0;
					end
				end
			endcase
		end
	end
endmodule

module d_cache_databank #(parameter INDEX_WIDTH = 9)(
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

module d_cache_tagbank #(parameter TAG_WIDTH = 13, parameter INDEX_WIDTH = 9)(
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
