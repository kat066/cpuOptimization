// Fetch Unit
//	Author: Pravin P. Prabhu, Zinsser Zhang
//	Version: 2.0
//	Last Revision: 04/02/2018
//	Abstract:
//		This module provides pc to i_cache to fetch the next instruction. Two
//		outputs exist. o_pc_current.pc is registered and represent the current
//		pc, i.e. the address of instruction needed to be fetched during the
//		current cycle. o_pc_next.pc is not registered and represent the next pc.
//		Because BRAM in FPGA does not support async read, we have to provide
//		unregistered next pc to i_cache so that reading from BRAM banks is done
//		on the edge at the begining of the cycle, after which verification and
//		selection is done. Registered o_pc_current is also given to i_cache, so
//		that its logic part does not need to register it again (for convenience)
`include "mips_core.svh"

module fetch_unit (
	// General signals
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	// Stall
	hazard_control_ifc i_hc,

	// Load pc
	load_pc_ifc i_load_pc,

	// Output pc
	pc_ifc o_pc_current,
	pc_ifc o_pc_next
);

	always_comb
	begin
		if (!i_hc.stall)
			o_pc_next.pc = i_load_pc.we ? i_load_pc.new_pc : o_pc_current.pc + `ADDR_WIDTH'd4;
		else
			o_pc_next.pc = o_pc_current.pc;
	end

	always_ff @(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			o_pc_current.pc <= '0;
		else
		begin
			o_pc_current.pc <= o_pc_next.pc;
		end
	end

endmodule
