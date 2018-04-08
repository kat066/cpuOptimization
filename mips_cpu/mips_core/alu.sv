`include "mips_core.svh"

interface alu_input_ifc ();
	logic valid;
	mips_core_pkg::AluCtl alu_ctl;
	logic signed [`DATA_WIDTH - 1 : 0] op1;
	logic signed [`DATA_WIDTH - 1 : 0] op2;
endinterface

interface alu_output_ifc ();
	logic valid;
	logic [`DATA_WIDTH - 1 : 0] result;
	mips_core_pkg::BranchOutcome branch_outcome;
endinterface

module alu (
	alu_input_ifc in,
	alu_output_ifc out,
	pass_done_ifc pass_done
);

	always_comb
	begin
		out.valid <= 1'b0;
		out.result <= '0;
		out.branch_outcome <= NOT_TAKEN;
		pass_done.value <= '0;
		pass_done.code <= MTC0_NOOP;

		if (in.valid)
		begin
			out.valid <= 1'b1;

			case (in.alu_ctl)
				ALUCTL_NOP:  out.result <= '0;
				ALUCTL_ADD:  out.result <= in.op1 + in.op2;
				ALUCTL_ADDU: out.result <= in.op1 + in.op2;
				ALUCTL_SUB:  out.result <= in.op1 - in.op2;
				ALUCTL_SUBU: out.result <= in.op1 - in.op2;
				ALUCTL_AND:  out.result <= in.op1 & in.op2;
				ALUCTL_OR:   out.result <= in.op1 | in.op2;
				ALUCTL_XOR:  out.result <= in.op1 ^ in.op2;
				ALUCTL_SLT:  out.result <= in.op1 < in.op2;
				ALUCTL_SLTU: out.result <= unsigned'(in.op1) < unsigned'(in.op2);
				ALUCTL_SLL:  out.result <= in.op1 << unsigned'(in.op2);
				ALUCTL_SRL:  out.result <= in.op1 >> unsigned'(in.op2);
				ALUCTL_SRA:  out.result <= in.op1 >>> unsigned'(in.op2);
				ALUCTL_SLLV: out.result <= in.op2 << in.op1[4:0];
				ALUCTL_SRLV: out.result <= in.op2 >> in.op1[4:0];
				ALUCTL_SRAV: out.result <= in.op2 >>> in.op1[4:0];
				ALUCTL_NOR:  out.result <= ~(in.op1 | in.op2);

				ALUCTL_MTCO_PASS:   // MTC0 -- redefined for our purposes.
				begin
					$display("%m (%t) PASS test %x\n", $time, in.op2);
					pass_done.code <= MTC0_PASS;
					pass_done.value <= in.op2[15:0];
				end

				ALUCTL_MTCO_FAIL:
				begin
					$display("%m (%t) FAIL test %x\n", $time, in.op2);
					pass_done.code <= MTC0_FAIL;
					pass_done.value <= in.op2[15:0];
				end

				ALUCTL_MTCO_DONE:
				begin
					$display("%m (%t) DONE test %x\n", $time, in.op2);
					pass_done.code <= MTC0_DONE;
					pass_done.value <= in.op2[15:0];
				end

				ALUCTL_BA:   out.branch_outcome <= TAKEN;
				ALUCTL_BEQ:  out.branch_outcome <= in.op1 == in.op2     ? TAKEN : NOT_TAKEN;
				ALUCTL_BNE:  out.branch_outcome <= in.op1 != in.op2     ? TAKEN : NOT_TAKEN;
				ALUCTL_BLEZ: out.branch_outcome <= in.op1 <= signed'(0) ? TAKEN : NOT_TAKEN;
				ALUCTL_BGTZ: out.branch_outcome <= in.op1 > signed'(0)  ? TAKEN : NOT_TAKEN;
				ALUCTL_BGEZ: out.branch_outcome <= in.op1 >= signed'(0) ? TAKEN : NOT_TAKEN;
				ALUCTL_BLTZ: out.branch_outcome <= in.op1 < signed'(0)  ? TAKEN : NOT_TAKEN;

				default: $display("%m (%t) Illegal ALUCTL code %b", $time, in.alu_ctl);
			endcase
		end
	end
endmodule
