/*
 * mips_core_pkg.sv
 * Author: Zinsser Zhang
 * Last Revision: 04/09/2018
 *
 * This package defines all the enum types used across different units within
 * mips_core.
 *
 * See wiki page "Systemverilog Primer" section package and enum for details.
 */
package mips_core_pkg;

typedef enum logic [5:0] {
	zero = 6'd0,
	at = 6'd1,
	v0 = 6'd2,
	v1 = 6'd3,
	a0 = 6'd4,
	a1 = 6'd5,
	a2 = 6'd6,
	a3 = 6'd7,
	t0 = 6'd8,
	t1 = 6'd9,
	t2 = 6'd10,
	t3 = 6'd11,
	t4 = 6'd12,
	t5 = 6'd13,
	t6 = 6'd14,
	t7 = 6'd15,
	s0 = 6'd16,
	s1 = 6'd17,
	s2 = 6'd18,
	s3 = 6'd19,
	s4 = 6'd20,
	s5 = 6'd21,
	s6 = 6'd22,
	s7 = 6'd23,
	t8 = 6'd24,
	t9 = 6'd25,
	k0 = 6'd26,
	k1 = 6'd27,
	gp = 6'd28,
	sp = 6'd29,
	s8 = 6'd30,
	ra = 6'd31,
	
	p32 = 6'd32,
	p33 = 6'd33,
	p34 = 6'd34,
	p35 = 6'd35,
	p36 = 6'd36,
	p37 = 6'd37,
	p38 = 6'd38,
	p39 = 6'd39,
	p40 = 6'd40,
	p41 = 6'd41,
	p42 = 6'd42,
	p43 = 6'd43,
	p44 = 6'd44,
	p45 = 6'd45,
	p46 = 6'd46,
	p47 = 6'd47,
	p48 = 6'd48,
	p49 = 6'd49,
	p50 = 6'd50,
	p51 = 6'd51,
	p52 = 6'd52,
	p53 = 6'd53,
	p54 = 6'd54,
	p55 = 6'd55,
	p56 = 6'd56,
	p57 = 6'd57,
	p58 = 6'd58,
	p59 = 6'd59,
	p60 = 6'd60,
	p61 = 6'd61,
	p62 = 6'd62,
	p63 = 6'd63,
} MipsReg;

typedef enum logic [4:0] {
	ALUCTL_NOP,			// No Operation (noop)
	ALUCTL_ADD,			// Add (signed)
	ALUCTL_ADDU,		// Add (unsigned)
	ALUCTL_SUB,			// Subtract (signed)
	ALUCTL_SUBU,		// Subtract (unsigned)
	ALUCTL_AND,			// AND
	ALUCTL_OR,			// OR
	ALUCTL_XOR,			// XOR
	ALUCTL_SLT,			// Set on Less Than
	ALUCTL_SLTU,		// Set on Less Than (unsigned)
	ALUCTL_SLL,			// Shift Left Logical
	ALUCTL_SRL,			// Shift Right Logical
	ALUCTL_SRA,			// Shift Right Arithmetic
	ALUCTL_SLLV,		// Shift Left Logical Variable
	ALUCTL_SRLV,		// Shift Right Logical Variable
	ALUCTL_SRAV,		// Shift Right Arithmetic Variable
	ALUCTL_NOR,			// NOR
	ALUCTL_MTCO_PASS,	// Move to Coprocessor (PASS)
	ALUCTL_MTCO_FAIL,	// Move to Coprocessor (FAIL)
	ALUCTL_MTCO_DONE,	// Move to Coprocessor (DONE)

	ALUCTL_BA,			// Unconditional branch
	ALUCTL_BEQ,
	ALUCTL_BNE,
	ALUCTL_BLEZ,
	ALUCTL_BGTZ,
	ALUCTL_BGEZ,
	ALUCTL_BLTZ
} AluCtl;

typedef enum logic {
	WRITE,
	READ
} MemAccessType;

typedef enum logic {
	NOT_TAKEN,
	TAKEN
} BranchOutcome;

typedef enum logic [1:0] {
	NOT_ATOMIC,
	ATOMIC_FAIL,
	ATOMIC_PASS
}	AtomicStatus;

endpackage
