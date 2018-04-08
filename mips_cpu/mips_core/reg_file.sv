`include "mips_core.svh"

interface reg_file_output_ifc ();
	logic [`DATA_WIDTH - 1 : 0] rs_data;
	logic [`DATA_WIDTH - 1 : 0] rt_data;
endinterface

module reg_file (
	input clk,    // Clock

	// Input from decoder
	decoder_output_ifc i_decoded,

	// Input from write back stage
	write_back_ifc i_wb,

	// Output data
	reg_file_output_ifc out
);

	logic [`DATA_WIDTH - 1 : 0] regs [32];

	assign out.rs_data = i_decoded.uses_rs ? regs[i_decoded.rs_addr] : '0;
	assign out.rt_data = i_decoded.uses_rt ? regs[i_decoded.rt_addr] : '0;

	always_ff @(posedge clk) begin
		if(i_wb.uses_rw)
		begin
			regs[i_wb.rw_addr] = i_wb.rw_data;
		end
	end

endmodule
