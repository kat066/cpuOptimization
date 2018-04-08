`include "mips_cpu.svh"

// This interface doc TODO
interface pass_done_ifc ();
	logic [15:0] value;
	mips_cpu_pkg::MTC0Code code;
endinterface
