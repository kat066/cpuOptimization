`include "mips_core.svh"

interface instruction_Queue_ifc ();
	logic [1 : 0] Valid_Ready[32];
	decoder_output_ifc instruction[32]();
	logic [31 : 0] source [32][2];
	logic [31 : 0] destination [32];
	logic [31 : 0] active_List_Index[32];


endinterface


module instruction_Queue (
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
