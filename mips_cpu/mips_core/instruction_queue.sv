`include "mips_core.svh"

interface instruction_Queue_ifc ();
	logic valid_entry[32];				//Valid bit of the instruction queue entry.
	logic ready[32];
	logic valid[32];					//Valid bit used for control signal of the MIPS CPU 
	mips_core_pkg::AluCtl alu_ctl[32];
	logic is_branch_jump[32];
	logic is_jump[32];
	logic is_jump_reg[32];
	logic [`ADDR_WIDTH - 1 : 0] branch_target[32];

	logic is_mem_access[32];
	mips_core_pkg::MemAccessType mem_action[32];

	logic uses_rs[32];
	mips_core_pkg::MipsReg rs_addr[32];

	logic uses_rt[32];
	mips_core_pkg::MipsReg rt_addr[32];

	logic uses_immediate[32];
	logic [`DATA_WIDTH - 1 : 0] immediate[32];

	logic uses_rw[32];
	mips_core_pkg::MipsReg rw_addr[32];
	
	logic is_ll[32];
	logic is_sc[32];
	logic is_sw[32];
	logic [4 : 0] active_List_Index[32];


endinterface


module instruction_Queue (
	input clk,
	input free_list[64],
	input [31:0] wr_tags,
	decoder_output_ifc.in decoded,
	decoder_output_ifc.in register,
	decoder_output_ifc.out out,
	hazard_control_ifc.in hazard
);
instruction_Queue_ifc Instr_Queue();


always_ff @(posedge clk) begin		
		for(int i=0,j=0;i<32;i++) begin
			if(~Instr_Queue.valid_entry[i] & ~j) begin
				Instr_Queue.valid[i]=decoded.valid;
				Instr_Queue.alu_ctl[i]=decoded.alu_ctl;
				Instr_Queue.is_branch_jump[i]=decoded.is_branch_jump;
				Instr_Queue.is_jump[i]=decoded.is_jump;
				Instr_Queue.is_jump_reg[i]=decoded.is_jump_reg;
				Instr_Queue.branch_target[i]=decoded.branch_target;

				Instr_Queue.is_mem_access[i]=decoded.is_mem_access;
				Instr_Queue.mem_action[i]=decoded.mem_action;

				Instr_Queue.uses_rs[i]=register.uses_rs;
				Instr_Queue.rs_addr[i]=register.rs_addr;

				Instr_Queue.uses_rt[i]=register.uses_rt;
				Instr_Queue.rt_addr[i]=register.rt_addr;

				Instr_Queue.uses_immediate[i]=decoded.uses_immediate;
				Instr_Queue.immediate[i]=decoded.immediate;

				Instr_Queue.uses_rw[i]=register.uses_rw;
				Instr_Queue.rw_addr[i]=register.rw_addr;
				
				Instr_Queue.is_ll[i]=decoded.is_ll;
				Instr_Queue.is_sc[i]=decoded.is_sc;
				Instr_Queue.is_sw[i]=decoded.is_sw;
				Instr_Queue.valid_entry[i]=1;
				Instr_Queue.ready[i]=(free_list[register.rs_addr] & free_list[register.rt_addr])?'b1:'b0;
				Instr_Queue.active_List_Index[i]=0;  //The active_List_Index should be based on where the corresponding 
													 //entry is in the active list!
				j=1;
			end
			else if(Instr_Queue.valid_entry[i] & Instr_Queue.ready[i] & ~wr_tags[i]) begin
				out.valid=Instr_Queue.valid[i];
				out.alu_ctl=Instr_Queue.alu_ctl[i];
				out.is_branch_jump=Instr_Queue.is_branch_jump[i];
				out.is_jump=Instr_Queue.is_jump[i];
				out.is_jump_reg=Instr_Queue.is_jump_reg[i];
				out.branch_target=Instr_Queue.branch_target[i];

				out.is_mem_access=Instr_Queue.is_mem_access[i];
				out.mem_action=Instr_Queue.mem_action[i];

				out.uses_rs=Instr_Queue.uses_rs[i];
				out.rs_addr=Instr_Queue.rs_addr[i];

				out.uses_rt=Instr_Queue.uses_rt[i];
				out.rt_addr=Instr_Queue.rt_addr[i];

				out.uses_immediate=Instr_Queue.uses_immediate[i];
				out.immediate=Instr_Queue.immediate[i];

				out.uses_rw=Instr_Queue.uses_rw[i];
				out.rw_addr=Instr_Queue.rw_addr[i];
				
				out.is_ll=Instr_Queue.is_ll[i];
				out.is_sc=Instr_Queue.is_sc[i];
				out.is_sw=Instr_Queue.is_sw[i];
				break;
			end
		end
end
endmodule
