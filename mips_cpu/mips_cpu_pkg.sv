package mips_cpu_pkg;

typedef enum bit [1:0] {
	MTC0_NOOP = 2'd0,
	MTC0_PASS = 2'd1,
	MTC0_FAIL = 2'd2,
	MTC0_DONE = 2'd3
} MTC0Code;

endpackage
