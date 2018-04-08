`include "mips_cpu.svh"

// Documentation TODO
interface mem_write_ifc ();
	logic [`ADDR_WIDTH - 1 : 0] control_base;
	logic [`ADDR_WIDTH - 1 : 0] control_length;
	logic control_go;
	logic control_done;

	logic user_we;	// Write Enable
	logic [`DATA_WIDTH - 1 : 0] user_data;
	logic user_full;
endinterface

interface mem_read_ifc ();
	logic [`ADDR_WIDTH - 1 : 0] control_base;
	logic [`ADDR_WIDTH - 1 : 0] control_length;
	logic control_go;
	logic control_done;

	logic user_re;	// Read Enable
	logic [`DATA_WIDTH - 1 : 0] user_data;
	logic user_available;
endinterface

