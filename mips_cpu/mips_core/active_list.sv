
`include "mips_core.svh"

interface active_List_ifc ();
	logic [4 : 0] instruction_Queue [31 : 0];
	logic [4 : 0] logical [31 : 0];
	logic [5 : 0] physical [31 : 0];
	logic done [4 : 0];
	logic [4 : 0]head ;
	logic [4 : 0]tail ;


endinterface


module active_List(
	decoder_output_ifc.in decoded
	decoder_output_ifc.out out
)
instruction_Queue_ifc Instr_Queue();
always_comb begin
	int count = 0;
	while (count < 32) begin

end


endmodule