`include "mips_core.svh"

interface free_List_ifc ();
	logic [63 : 0] free [32];
	logic [63 : 0]freeCount;


endinterface


module free_List(
	decoder_output_ifc.in decoded,
	decoder_output_ifc.out out
);
instruction_Queue_ifc Instr_Queue();
always_comb begin
	int count = 0;
	while (count < 32) begin

	end

end
endmodule

