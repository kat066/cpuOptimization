`include "mips_core.svh"

module forward_unit (
	// Input from decoder
	decoder_output_ifc decoded,
	reg_file_output_ifc reg_data,

	// Feedback from EX stage
	alu_pass_through_ifc ex_ctl,
	alu_output_ifc ex_data,

	// Feedback from MEM stage
	write_back_ifc mem,

	// Feedback from WB stage
	write_back_ifc wb,

	// Output
	reg_file_output_ifc out,
	output logic o_lw_hazard
);

	task forward_rs;
		input logic uses_rs;
		input mips_core_pkg::MipsReg rs_addr;

		input logic condition;
		input mips_core_pkg::MipsReg r_source;
		input logic [`DATA_WIDTH - 1 : 0] d_source;
		begin
			if (uses_rs && (rs_addr == r_source) && condition)
				out.rs_data <= d_source;
		end
	endtask

	task forward_rt;
		input logic uses_rt;
		input mips_core_pkg::MipsReg rt_addr;

		input logic condition;
		input mips_core_pkg::MipsReg r_source;
		input logic [`DATA_WIDTH - 1 : 0] d_source;
		begin
			if (uses_rt && (rt_addr == r_source) && condition)
				out.rt_data <= d_source;
		end
	endtask

	task forward;
		input logic uses_rs;
		input logic uses_rt;
		input mips_core_pkg::MipsReg rs_addr;
		input mips_core_pkg::MipsReg rt_addr;

		input logic condition;
		input mips_core_pkg::MipsReg r_source;
		input logic [`DATA_WIDTH - 1 : 0] d_source;
		begin
			forward_rs(uses_rs, rs_addr, condition, r_source, d_source);
			forward_rt(uses_rt, rt_addr, condition, r_source, d_source);
		end
	endtask

	always_comb
	begin
		out.rs_data <= reg_data.rs_data;
		out.rt_data <= reg_data.rt_data;

		// Forward WB stage
		forward(decoded.uses_rs, decoded.uses_rt,
			decoded.rs_addr, decoded.rt_addr,
			wb.uses_rw, wb.rw_addr, wb.rw_data);

		// Forward MEM stage
		forward(decoded.uses_rs, decoded.uses_rt,
			decoded.rs_addr, decoded.rt_addr,
			mem.uses_rw, mem.rw_addr, mem.rw_data);

		// Forward EX stage
		forward(decoded.uses_rs, decoded.uses_rt,
			decoded.rs_addr, decoded.rt_addr,
			ex_data.valid & ex_ctl.uses_rw & ~ex_ctl.is_mem_access,
			ex_ctl.rw_addr, ex_data.result);
	end

	always_comb
	begin
		o_lw_hazard = ex_data.valid & ex_ctl.uses_rw & ex_ctl.is_mem_access
			& ((decoded.uses_rs & (decoded.rs_addr == ex_ctl.rw_addr))
				| (decoded.uses_rt & (decoded.rt_addr == ex_ctl.rw_addr)));
	end

endmodule
