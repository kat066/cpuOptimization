`include "mips_core.svh"

interface instruction_Queue_ifc ();
	logic valid[32];
	logic ready[32];
	decoder_output_ifc instruction[32]();
	logic [31 : 0] active_List_Index[32];


endinterface


module instruction_Queue (
	decoder_output_ifc.in decoded,
	decoder_output_ifc.out out
);
instruction_Queue_ifc Instr_Queue();
always_comb begin
	int count = 0;
	while (count < 32 && Instr_Queue.valid[count]== 0) begin
	Instr_Queue.instruction[count].valid=decoded.valid;
	Instr_Queue.instruction[count].alu_ctl=decoded.alu_ctl;
	Instr_Queue.instruction[count].is_branch_jump=decoded.is_branch_jump;
	Instr_Queue.instruction[count].is_jump=decoded.is_jump;
	Instr_Queue.instruction[count].is_jump_reg=decoded.is_jump_reg;
	Instr_Queue.instruction[count].branch_target=decoded.branch_target;

	Instr_Queue.instruction[count].is_mem_access=decoded.is_mem_access;
	Instr_Queue.instruction[count].mem_action=decoded.mem_action;

	Instr_Queue.instruction[count].uses_rs=decoded.uses_rs;
	Instr_Queue.instruction[count].rs_addr=decoded.rs_addr;

	Instr_Queue.instruction[count].uses_rt=decoded.uses_rt;
	Instr_Queue.instruction[count].rt_addr=decoded.rt_addr;

	Instr_Queue.instruction[count].uses_immediate=decoded.uses_immediate;
	Instr_Queue.instruction[count].immediate=decoded.immediate;

	Instr_Queue.instruction[count].uses_rw=decoded.uses_rw;
	Instr_Queue.instruction[count].rw_addr=decoded.rw_addr;
	
	Instr_Queue.instruction[count].is_ll=decoded.is_ll;
	Instr_Queue.instruction[count].is_sc=decoded.is_sc;
	Instr_Queue.instruction[count].is_sw=decoded.is_sw;
	Instr_Queue.valid[count]=1;
	Instr_Queue.ready[count]=0;
	Instr_Queue.active_List_Index[count]=0;
	end

end
endmodule
