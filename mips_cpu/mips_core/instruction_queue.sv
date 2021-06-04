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
	logic [`ADDR_WIDTH-1:0] entry_pc [31: 0];

endinterface


module instruction_Queue (
	input clk,
	input free_list[64],
	input active_list_end_flush_signal,		//Current name for a signal that the Active List sends to other modules to tell them
											//that it is done flushing (and remappping).
	decoder_output_ifc.in decoded,
	decoder_output_ifc.in register,
	decoder_output_ifc.out out,
	hazard_control_ifc.in hazard,
	pc_ifc.in instruction_pc
);

instruction_Queue_ifc Instr_Queue();
logic ready_and_valid[31:0];
logic [4:0] valid_entry_index;				//Index of the Instr_Queue that points to an element that is not valid!
logic [4:0] ready_and_valid_index;			//Index of the Instr_Queue that points to an element that is ready AND valid!

logic block_queue_from_adding;

always_comb begin
	for (int i = 0; i < 32; i++) begin
		ready_and_valid[i] = Instr_Queue.ready[i] & Instr_Queue.valid[i];
	end
end

priority_encoder #(.NUM_OF_INPUTS(32), .HIGH_PRIORITY(0), .SIGNAL(0)) 
	valid_entry_encoder( .data_inputs(Instr_Queue.valid_entry), .encoding_output(valid_entry_index) );

priority_encoder #(.NUM_OF_INPUTS(32), .HIGH_PRIORITY(1), .SIGNAL(1)) 
	ready_encoder( .data_inputs(ready_and_valid), .encoding_output(ready_and_valid_index) );


always_ff @(posedge clk) begin

	/*Whenever the decoder and the register map table send data of an instruction, 
	 *update this...
	 *
	 *Previously, the Instr_Queue assumed it got data from the decoder and register map table
	 *ever clock cycle.
	 *
	 *But in reality, this is not the case!  For example, what if a flush occurs? There will be
	 *a few cycles where no valid instruction is properly decoded/register renamed!  
	 *
	 *If we are not careful, the Instr_Queue can have erroneous instructions added to it in those
	 *few cycles!  
	 *
	 *So, we should have some method for the Instr_Queue to not ADD any new instructions during a 
	 *flush, and refuse to ADD new instructions until the decoder and register map table give it valid data!
	 * 
	 *Flushing ends when the Active List is ready, since the Active List is the thing that takes multiple 
	 *cycles to flush properly.
	 *
	 *This means that when a flush occurs, the decoder and register map table will always have valid data 
	 *before or at the same time the Active List is ready.
	 *
	 *Therefore, the Instr_Queue is "blocked" from adding new instructions whenever a flush occurs, 
	 *and is "freed" whenever the Active List sends it a signal telling the Instr_Queue that the Active List
	 *is done flushing!
	 */
	if (hazard.flush) block_queue_from_adding <= 1;
	if (active_list_end_flush_signal) block_queue_from_adding <= 0;
	
	if (~block_queue_from_adding) begin
		Instr_Queue.valid[valid_entry_index]   <= decoded.valid;
		Instr_Queue.alu_ctl[valid_entry_index] <= decoded.alu_ctl;
		
		Instr_Queue.is_branch_jump[valid_entry_index] <= decoded.is_branch_jump;
		Instr_Queue.is_jump[valid_entry_index] 		  <= decoded.is_jump;
		Instr_Queue.is_jump_reg[valid_entry_index]    <= decoded.is_jump_reg;
		Instr_Queue.branch_target[valid_entry_index]  <= decoded.branch_target;

		Instr_Queue.is_mem_access[valid_entry_index] <= decoded.is_mem_access;
		Instr_Queue.mem_action[valid_entry_index]    <= decoded.mem_action;

		Instr_Queue.uses_rs[valid_entry_index] <= register.uses_rs;
		Instr_Queue.rs_addr[valid_entry_index] <= register.rs_addr;

		Instr_Queue.uses_rt[valid_entry_index] <= register.uses_rt;
		Instr_Queue.rt_addr[valid_entry_index] <= register.rt_addr;

		Instr_Queue.uses_immediate[valid_entry_index] <= decoded.uses_immediate;
		Instr_Queue.immediate[valid_entry_index]      <= decoded.immediate;

		Instr_Queue.uses_rw[valid_entry_index] <= register.uses_rw;
		Instr_Queue.rw_addr[valid_entry_index] <= register.rw_addr;
		
		Instr_Queue.is_ll[valid_entry_index] <= decoded.is_ll;
		Instr_Queue.is_sc[valid_entry_index] <= decoded.is_sc;
		Instr_Queue.is_sw[valid_entry_index] <= decoded.is_sw;
		
		Instr_Queue.valid_entry[valid_entry_index]		 <= 1;
		Instr_Queue.ready[valid_entry_index] 	   		 <= (free_list[register.rs_addr] & free_list[register.rt_addr]) ? 'b1 : 'b0;
		Instr_Queue.active_List_Index[valid_entry_index] <= 0;  //The active_List_Index should be based on where the corresponding 
																//entry is in the active list!
		Instr_Queue.entry_pc[valid_entry_index] 		 <= instruction_pc.pc;														
	end

	/* Now, even though we cannot ADD new instructions into the Instr_Queue while
	 * a flush is happening, we can still ISSUE them, if they are ready and valid!
	 */
	out.valid 	<= Instr_Queue.valid[valid_entry_index];
	out.alu_ctl <= Instr_Queue.alu_ctl[valid_entry_index];
	
	out.is_branch_jump <= Instr_Queue.is_branch_jump[valid_entry_index];
	out.is_jump		   <= Instr_Queue.is_jump[valid_entry_index];
	out.is_jump_reg    <= Instr_Queue.is_jump_reg[valid_entry_index];
	out.branch_target  <= Instr_Queue.branch_target[valid_entry_index];

	out.is_mem_access <= Instr_Queue.is_mem_access[valid_entry_index];
	out.mem_action 	  <= Instr_Queue.mem_action[valid_entry_index];

	out.uses_rs <= Instr_Queue.uses_rs[valid_entry_index];
	out.rs_addr <= Instr_Queue.rs_addr[valid_entry_index];

	out.uses_rt <= Instr_Queue.uses_rt[valid_entry_index];
	out.rt_addr <= Instr_Queue.rt_addr[valid_entry_index];

	out.uses_immediate <= Instr_Queue.uses_immediate[valid_entry_index];
	out.immediate 	   <= Instr_Queue.immediate[valid_entry_index];

	out.uses_rw <= Instr_Queue.uses_rw[valid_entry_index];
	out.rw_addr <= Instr_Queue.rw_addr[valid_entry_index];
	
	out.is_ll <= Instr_Queue.is_ll[valid_entry_index];
	out.is_sc <= Instr_Queue.is_sc[valid_entry_index];
	out.is_sw <= Instr_Queue.is_sw[valid_entry_index];
	
	
	/* Finally, we will have a comparator attached to each entry in the Instr_Queue.
	 * If the Instr_Queue detects a flush signal, and the PC of the entry is less than
	 * the current PC, the "valid_entry" bit of the entry will be set to 0, "flushing" it
	 * from the queue.
	 */
	for (int i = 0; i < 32; i++) if ((instruction_pc.pc < Instr_Queue.entry_pc[i]) && hazard.flush) Instr_Queue.valid_entry[i] <= 0;
end


/*
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
		else if(Instr_Queue.valid_entry[i] & Instr_Queue.ready[i]) begin
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
*/

endmodule
