`include "mips_core.svh"

interface load_pc_ifc ();
	logic we;	// Write Enable
	logic [`ADDR_WIDTH - 1 : 0] new_pc;
endinterface

interface pc_ifc ();
	logic [`ADDR_WIDTH - 1 : 0] pc;
endinterface

interface cache_output_ifc ();
	logic valid;	// Output Valid
	logic [`DATA_WIDTH - 1 : 0] data;
endinterface

interface branch_decoded_ifc ();
	logic valid;	// High means the instruction is a branch or a jump
	logic is_jump;	// High means the instruction is a jump
	logic [`ADDR_WIDTH - 1 : 0] target;

	mips_core_pkg::BranchOutcome prediction;
	logic [`ADDR_WIDTH - 1 : 0] target_post_predict;

	modport decode (output valid, is_jump, target,
		input prediction, target_post_predict);
	modport hazard (output prediction, target_post_predict,
		input valid, is_jump, target);
endinterface

interface alu_pass_through_ifc ();
	logic is_branch;
	mips_core_pkg::BranchOutcome prediction;
	logic [`ADDR_WIDTH - 1 : 0] branch_target;

	logic is_mem_access;
	mips_core_pkg::MemAccessType mem_action;
	logic [`DATA_WIDTH - 1 : 0] sw_data;

	logic uses_rw;
	mips_core_pkg::MipsReg rw_addr;
endinterface

interface branch_result_ifc ();
	logic valid;
	mips_core_pkg::BranchOutcome prediction;
	mips_core_pkg::BranchOutcome outcome;
	logic [`ADDR_WIDTH - 1 : 0] target;
endinterface

interface d_cache_pass_through_ifc ();
	logic is_mem_access;
	logic [`DATA_WIDTH - 1 : 0] alu_result;

	logic uses_rw;
	mips_core_pkg::MipsReg rw_addr;
endinterface

interface write_back_ifc ();
	logic uses_rw;	// Write Enable
	mips_core_pkg::MipsReg rw_addr;
	logic [`DATA_WIDTH - 1 : 0] rw_data;
endinterface

interface hazard_control_ifc ();
	// Stall signal has higher priority
	logic flush;	// Flush signal of the previous stage
	logic stall;	// Stall signal of the next stage
endinterface
