/* mips_core.v
* Author: Pravin P. Prabhu, Dean Tullsen, and Zinsser Zhang
* Last Revision: 04/28/2017
* Abstract:
*	The core module for the MIPS32 processor. This is a classic 5-stage
* MIPS pipeline architecture which is intended to follow heavily from the model
* presented in Hennessy and Patterson's Computer Organization and Design.
* All addresses used in this scope are word addresses (32-bit/4-byte aligned)
*/
module mips_core #(
				parameter DATA_WIDTH = 32,
				parameter WORD_ADDRESS_WIDTH = 21
			)
			(	// General	 
				input i_Clk,
				input i_Reset_n,
				input i_External_Stall,				// Global Stall issued by top level

				// Memory bus interface
				output o_MEM_Valid,
				output o_MEM_Read_Write_n,
				output [WORD_ADDRESS_WIDTH-1:0] o_MEM_Address,
				output [DATA_WIDTH-1:0] o_MEM_Data,
				input i_MEM_Valid,
				input i_MEM_Data_Read,
				input i_MEM_Last,
				input [DATA_WIDTH-1:0] i_MEM_Data,
				
				// Outputs for Done flag
				output [15:0] o_Pass_Done_Value,	// reports the value of a PASS/FAIL/DONE instruction
				output [1:0] o_Pass_Done_Change,	// indicates the above signal is meaningful
													// 1 = pass, 2 = fail, 3 = done

				// Outputs for performance display
				output [7:0] o_Num_Inst_Executed,
				output [20:0] o_IMEM_i_Address
			);

//===================================================================
//	Internal Wiring
//===================================================================

//===================================================================
// General Signals
localparam FALSE = 1'b0;
localparam TRUE = 1'b1;
localparam BYTE_ADDRESS_WIDTH = WORD_ADDRESS_WIDTH + 2;

//===================================================================
// IFetch Signals

wire IFetch_i_Flush;		// Flush for IFetch
wire Hazard_Stall_IF;		// Stall for IFetch
wire IFetch_i_Load;			// Load signal - if high, load pc with vector
wire [WORD_ADDRESS_WIDTH-1:0] IFetch_i_PCSrc;	// Vector to branch to

wire [WORD_ADDRESS_WIDTH-1:0] IMEM_i_Address;	// Current PC


wire IMEM_o_Ready;
wire IMEM_o_Valid;
wire [DATA_WIDTH-1:0] IMEM_o_Instruction;

	//==============
	// Pipe signals: IF->ID
wire Hazard_Flush_IF;		// 1st pipe flush
wire Hazard_Stall_DEC;		// 1st pipe stall
wire imembubble_DEC;		// set if instruction coming out of icache 
								// was not real instruction 
//===================================================================
// Decoder Signals
localparam ALU_CTLCODE_WIDTH = 8;
localparam REG_ADDR_WIDTH = 5;
localparam MEM_MASK_WIDTH = 3;
wire [WORD_ADDRESS_WIDTH-1:0] DEC_i_PC;					// PC of inst
wire [DATA_WIDTH-1:0] DEC_i_Instruction;				// Inst into decode
wire DEC_Noop = (DEC_i_Instruction == 32'd0);

wire DEC_o_Uses_ALU;
wire [ALU_CTLCODE_WIDTH-1:0] DEC_o_ALUCTL;			// ALU control code
wire DEC_o_Is_Branch;									// If it's a branch
wire [WORD_ADDRESS_WIDTH-1:0] DEC_o_Branch_Target;		// Where we will branch to
wire DEC_o_Jump_Reg;									// If this is a special case where we jump TO a register value

wire DEC_o_Mem_Valid;
wire DEC_o_Mem_Read_Write_n;
wire [MEM_MASK_WIDTH-1:0] DEC_o_Mem_Mask;			// Used for masking individual memory ops - such as byte and halfword transactions

wire DEC_o_Writes_Back;
wire [REG_ADDR_WIDTH-1:0] DEC_o_Write_Addr;
wire DEC_o_Uses_RS;
wire [REG_ADDR_WIDTH-1:0] DEC_o_Read_Register_1;
wire DEC_o_Uses_RT;
wire [REG_ADDR_WIDTH-1:0] DEC_o_Read_Register_2;

wire [DATA_WIDTH-1:0] DEC_o_Read_Data_1;
wire [DATA_WIDTH-1:0] DEC_o_Read_Data_2;

wire DEC_o_Uses_Immediate;
wire [DATA_WIDTH-1:0] DEC_o_Immediate;

wire [DATA_WIDTH-1:0] FORWARD_o_Forwarded_Data_1,FORWARD_o_Forwarded_Data_2;	// Looked up regs

	//==============
	// Pipe signals: ID->EX
wire Hazard_Flush_DEC;		// 2nd pipe flush
wire Hazard_Stall_EX;			// 2nd pipe stall

wire [WORD_ADDRESS_WIDTH-1:0] DEC_o_PC;
assign DEC_o_PC = DEC_i_PC;

//===================================================================
// Execute Signals

wire [WORD_ADDRESS_WIDTH-1:0] ALU_i_PC;

wire EX_i_Is_Branch;
wire EX_i_Mem_Valid;
wire [MEM_MASK_WIDTH-1:0] EX_i_Mem_Mask;
wire EX_i_Mem_Read_Write_n;
wire [DATA_WIDTH-1:0] EX_i_Mem_Write_Data;
wire EX_i_Writes_Back;
wire [REG_ADDR_WIDTH-1:0] EX_i_Write_Addr;

wire ALU_i_Valid;										// Whether input to ALU is valid or not
wire ALU_o_Valid;
wire [ALU_CTLCODE_WIDTH-1:0] ALU_i_ALUOp;					// Control bus to ALU
wire [DATA_WIDTH-1:0] ALU_i_Operand1,ALU_i_Operand2;	// Ops for ALU
wire [WORD_ADDRESS_WIDTH-1:0] EX_i_Branch_Target;
wire [DATA_WIDTH-1:0] ALU_o_Result;							// Computation of ALU
wire ALU_o_Branch_Valid;								// Whether branch is valid or not
wire ALU_o_Branch_Outcome;									// Whether branch is taken or not
wire [15:0] ALU_o_Pass_Done_Value;						// reports the value of a PASS/FAIL/DONE instruction
wire [1:0] ALU_o_Pass_Done_Change;							// indicates the above signal is meaningful
															// 1 = pass, 2 = fail, 3 = done

	// Cumulative signals
wire EX_Take_Branch = ALU_o_Valid && ALU_o_Branch_Valid && ALU_o_Branch_Outcome;		// Whether we should branch or not.

	//==============
	// Pipe signals: EX->MEM
wire Hazard_Flush_EX;		// 3rd pipe flush
wire Hazard_Stall_MEM;			// 3rd pipe stall


//===================================================================
// Memory Signals
wire [DATA_WIDTH-1:0] DMEM_i_Result;					// Result from the ALU
wire [DATA_WIDTH-1:0] DMEM_i_Mem_Write_Data;		// What we will write back to mem (if applicable)
wire DMEM_i_Mem_Valid;								// If the memory operation is valid
wire [MEM_MASK_WIDTH-1:0] DMEM_i_Mem_Mask;		// Mem mask for sub-word operations
wire DMEM_i_Mem_Read_Write_n;					// Type of memop
wire DMEM_i_Writes_Back;								// If the result should be written back to regfile
wire [REG_ADDR_WIDTH-1:0] DMEM_i_Write_Addr;		// Which reg in the regfile to write to
wire [DATA_WIDTH-1:0] DMEM_o_Read_Data;				// The data READ from DMEM
wire DMEM_o_Mem_Ready;							// If the DMEM is ready to service another request
wire DMEM_o_Mem_Valid;								// If the value read from DMEM is valid
reg DMEM_o_Done;									// If MEM's work is finalized
reg [DATA_WIDTH-1:0] DMEM_o_Write_Data;				// Data we should write back to regfile

wire MemToReg = DMEM_i_Mem_Valid;			// Selects what we will write back -- mem or ALU result

	//==============
	// Pipe signals: MEM->WB
wire Hazard_Flush_MEM;		// 4th pipe flush
wire Hazard_Stall_WB;	// 4th pipe stall


//===================================================================
// Write-Back Signals
wire WB_i_Writes_Back;							// If we will write back
wire [REG_ADDR_WIDTH-1:0] DEC_i_Write_Register;			// Where we will write back to
wire [DATA_WIDTH-1:0] WB_i_Write_Data;			// What we will write back
wire Hazard_Flush_WB;									// Request to squash WB contents

wire DEC_i_RegWrite = WB_i_Writes_Back && !Hazard_Flush_WB;

//===================================================================
// Core memory bus arbiter Signals
wire Arbiter_i_IMEM_Valid;
wire [WORD_ADDRESS_WIDTH-1:0] Arbiter_i_IMEM_Address;
wire Arbiter_o_IMEM_Valid;
wire Arbiter_o_IMEM_Last;
wire [DATA_WIDTH-1:0] Arbiter_o_IMEM_Data;

wire Arbiter_i_DMEM_Valid;
wire Arbiter_i_DMEM_Read_Write_n;
wire [WORD_ADDRESS_WIDTH-1:0] Arbiter_i_DMEM_Address;
wire [DATA_WIDTH-1:0] Arbiter_i_DMEM_Data;
wire [DATA_WIDTH-1:0] Arbiter_o_DMEM_Data;
wire Arbiter_o_DMEM_Data_Read;
wire Arbiter_o_DMEM_Valid;
wire Arbiter_o_DMEM_Last;

//===================================================================
// Top-level Connections

	// Report number of instructions that is finishing up execution in Decode
	// For this baseline this number can not exceed 1.
	assign o_Num_Inst_Executed = !Hazard_Stall_DEC && !Hazard_Flush_DEC && !DEC_Noop;

	// Report current request address to i_cache
	assign o_IMEM_i_Address = IMEM_i_Address;

	// Report Done flag/value
	assign o_Pass_Done_Value = ALU_o_Pass_Done_Value;
	assign o_Pass_Done_Change = ALU_o_Pass_Done_Change;

//===================================================================
//	Structural Description - Pipeline stages
//===================================================================

//===================================================================
//	Instruction Fetch
fetch_unit #(	.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH)
				)
				IFETCH
				(	// Inputs
					.i_Clk(i_Clk),
					.i_Reset_n(i_Reset_n),
					.i_Stall(Hazard_Stall_IF),
					
					.i_Load(IFetch_i_Load),
					.i_Load_Address(IFetch_i_PCSrc),
					
					// Outputs
					.o_PC(IMEM_i_Address)
				);
				
i_cache	#(	.DATA_WIDTH(DATA_WIDTH)
		)
		I_CACHE
		(
			// General
			.i_Clk(i_Clk),
			.i_Reset_n(i_Reset_n),
			
			// Requests
			.i_Valid(!i_External_Stall),
			.i_Address(IMEM_i_Address),
		
			// Mem Transaction 
			.o_MEM_Valid(Arbiter_i_IMEM_Valid),
			.o_MEM_Address(Arbiter_i_IMEM_Address),
			.i_MEM_Valid(Arbiter_o_IMEM_Valid),		// If data from main mem is valid
			.i_MEM_Last(Arbiter_o_IMEM_Last),			// If main mem is sending the last piece of data
			.i_MEM_Data(Arbiter_o_IMEM_Data),		// Data from main mem
			
			// Outputs
			.o_Ready(IMEM_o_Ready),
			.o_Valid(IMEM_o_Valid),					// If the output is correct.
			.o_Data(IMEM_o_Instruction)					// The data requested.		
		);

//===================================================================
//	Decode
pipe_if_dec	#(	.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH)
			)
			PIPE_IF_DEC
			(		// Inputs
				.i_Clk(i_Clk),
				.i_Reset_n(i_Reset_n),
				.i_Flush(Hazard_Flush_IF),
				.i_Stall(Hazard_Stall_DEC),
				.i_imembubble(IMEM_o_Valid),
				
					// Pipe signals
				.i_PC(IMEM_i_Address),
				.o_PC(DEC_i_PC),
				.i_Instruction(IMEM_o_Instruction),
				.o_Instruction(DEC_i_Instruction),
				.o_imembubble(imembubble_DEC)
			);

decoder #(	.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.REG_ADDRESS_WIDTH(REG_ADDR_WIDTH),
			.ALUCTL_WIDTH(ALU_CTLCODE_WIDTH),
			.MEM_MASK_WIDTH(MEM_MASK_WIDTH)
		)
		DECODE
		(		// Inputs
			.i_PC(DEC_i_PC),
			.i_Instruction(DEC_i_Instruction),
			.i_Stall(Hazard_Stall_DEC),
		
				// Outputs
			.o_Uses_ALU(DEC_o_Uses_ALU),
			.o_ALUCTL(DEC_o_ALUCTL),
			.o_Is_Branch(DEC_o_Is_Branch),
			.o_Jump_Reg(DEC_o_Jump_Reg),
			
			.o_Mem_Valid(DEC_o_Mem_Valid),
			.o_Mem_Read_Write_n(DEC_o_Mem_Read_Write_n),
			.o_Mem_Mask(DEC_o_Mem_Mask),
			
			.o_Writes_Back(DEC_o_Writes_Back),
			.o_Write_Addr(DEC_o_Write_Addr),
			
			.o_Uses_RS(DEC_o_Uses_RS),
			.o_RS_Addr(DEC_o_Read_Register_1),
			.o_Uses_RT(DEC_o_Uses_RT),
			.o_RT_Addr(DEC_o_Read_Register_2),
			.o_Uses_Immediate(DEC_o_Uses_Immediate),
			.o_Immediate(DEC_o_Immediate),
			.o_Branch_Target(DEC_o_Branch_Target)
		);

		
regfile #(	.DATA_WIDTH(DATA_WIDTH),
			.REG_ADDR_WIDTH(REG_ADDR_WIDTH)
		)
		REGFILE
		(		// Inputs
			.i_Clk(i_Clk),
					
			.i_RS_Addr(DEC_o_Read_Register_1),
			.i_RT_Addr(DEC_o_Read_Register_2),
				
			.i_Write_Enable(DEC_i_RegWrite),	// Account for squashing WB stage
			.i_Write_Data(WB_i_Write_Data),
			.i_Write_Addr(DEC_i_Write_Register),
					
				// Outputs
			.o_RS_Data(DEC_o_Read_Data_1),
			.o_RT_Data(DEC_o_Read_Data_2)
		);

//===================================================================
//	Execute
pipe_dec_ex #(	.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.REG_ADDR_WIDTH(REG_ADDR_WIDTH),
				.ALU_CTLCODE_WIDTH(ALU_CTLCODE_WIDTH),
				.MEM_MASK_WIDTH(MEM_MASK_WIDTH)
			)
			PIPE_DEC_EX
			(		// Inputs
				.i_Clk(i_Clk),
				.i_Reset_n(i_Reset_n),
				.i_Flush(Hazard_Flush_DEC),
				.i_Stall(Hazard_Stall_EX),
							
					// Pipeline
				.i_PC(DEC_o_PC),
				.o_PC(ALU_i_PC),
				.i_Uses_ALU(DEC_o_Uses_ALU),
				.o_Uses_ALU(ALU_i_Valid),
				.i_ALUCTL(DEC_o_ALUCTL),
				.o_ALUCTL(ALU_i_ALUOp),
				.i_Is_Branch(DEC_o_Is_Branch),
				.o_Is_Branch(EX_i_Is_Branch),
				.i_Mem_Valid(DEC_o_Mem_Valid),
				.o_Mem_Valid(EX_i_Mem_Valid),
				.i_Mem_Mask(DEC_o_Mem_Mask),
				.o_Mem_Mask(EX_i_Mem_Mask),
				.i_Mem_Read_Write_n(DEC_o_Mem_Read_Write_n),
				.o_Mem_Read_Write_n(EX_i_Mem_Read_Write_n),
				.i_Mem_Write_Data(FORWARD_o_Forwarded_Data_2),
				.o_Mem_Write_Data(EX_i_Mem_Write_Data),
				.i_Writes_Back(DEC_o_Writes_Back),
				.o_Writes_Back(EX_i_Writes_Back),
				.i_Write_Addr(DEC_o_Write_Addr),
				.o_Write_Addr(EX_i_Write_Addr),
				.i_Operand1(FORWARD_o_Forwarded_Data_1),
				.o_Operand1(ALU_i_Operand1),
				.i_Operand2(DEC_o_Uses_Immediate?DEC_o_Immediate:FORWARD_o_Forwarded_Data_2),		// Convention - Operand2 mapped to immediates
				.o_Operand2(ALU_i_Operand2),
				.i_Branch_Target(DEC_o_Jump_Reg?FORWARD_o_Forwarded_Data_1[WORD_ADDRESS_WIDTH-1:0]:DEC_o_Branch_Target),
				.o_Branch_Target(EX_i_Branch_Target)
			);

alu	#(	.DATA_WIDTH(DATA_WIDTH),
		.CTLCODE_WIDTH(ALU_CTLCODE_WIDTH)
	)
	ALU
	(		// Inputs
		.i_Valid(ALU_i_Valid),
		.i_ALUCTL(ALU_i_ALUOp),
		.i_Operand1(ALU_i_Operand1),
		.i_Operand2(ALU_i_Operand2),
		
			// Outputs
		.o_Valid(ALU_o_Valid),
		.o_Result(ALU_o_Result),
		.o_Branch_Valid(ALU_o_Branch_Valid),
		.o_Branch_Outcome(ALU_o_Branch_Outcome),
		.o_Pass_Done_Value(ALU_o_Pass_Done_Value),
		.o_Pass_Done_Change(ALU_o_Pass_Done_Change)
	);

//===================================================================
//	Mem
pipe_ex_mem #(	.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.REG_ADDR_WIDTH(REG_ADDR_WIDTH),
				.ALU_CTLCODE_WIDTH(ALU_CTLCODE_WIDTH)
			)
			PIPE_EX_MEM
			(		// Inputs
				.i_Clk(i_Clk),
				.i_Reset_n(i_Reset_n),
				.i_Flush(Hazard_Flush_EX),
				.i_Stall(Hazard_Stall_MEM),
				
				// Pipe in/out
				.i_ALU_Result(ALU_o_Result),
				.o_ALU_Result(DMEM_i_Result),
				.i_Mem_Valid(EX_i_Mem_Valid),
				.o_Mem_Valid(DMEM_i_Mem_Valid),
				.i_Mem_Mask(EX_i_Mem_Mask),
				.o_Mem_Mask(DMEM_i_Mem_Mask),
				.i_Mem_Read_Write_n(EX_i_Mem_Read_Write_n),
				.o_Mem_Read_Write_n(DMEM_i_Mem_Read_Write_n),
				.i_Mem_Write_Data(EX_i_Mem_Write_Data),
				.o_Mem_Write_Data(DMEM_i_Mem_Write_Data),
				.i_Writes_Back(EX_i_Writes_Back),
				.o_Writes_Back(DMEM_i_Writes_Back),
				.i_Write_Addr(EX_i_Write_Addr),
				.o_Write_Addr(DMEM_i_Write_Addr)
			);

d_cache	#(	
			.DATA_WIDTH(32),
			.MEM_MASK_WIDTH(3)
		)
		D_CACHE
		(	// Inputs
			.i_Clk(i_Clk),
			.i_Reset_n(i_Reset_n),
			.i_Valid(DMEM_i_Mem_Valid),
			.i_Mem_Mask(DMEM_i_Mem_Mask),
			.i_Address(DMEM_i_Result[BYTE_ADDRESS_WIDTH-1:2]),
			.i_Read_Write_n(DMEM_i_Mem_Read_Write_n),	//1=MemRead, 0=MemWrite
			.i_Write_Data(DMEM_i_Mem_Write_Data),

			// Outputs
			.o_Ready(DMEM_o_Mem_Ready),
			.o_Valid(DMEM_o_Mem_Valid),
			.o_Data(DMEM_o_Read_Data),
			
			// Mem Transaction
			.o_MEM_Valid(Arbiter_i_DMEM_Valid),
			.o_MEM_Read_Write_n(Arbiter_i_DMEM_Read_Write_n),	
			.o_MEM_Address(Arbiter_i_DMEM_Address),
			.o_MEM_Data(Arbiter_i_DMEM_Data),
			.i_MEM_Valid(Arbiter_o_DMEM_Valid),
			.i_MEM_Data_Read(Arbiter_o_DMEM_Data_Read),
			.i_MEM_Last(Arbiter_o_DMEM_Last),
			.i_MEM_Data(Arbiter_o_DMEM_Data)
		);
		
	// Multiplexor - Select what we will write back
always @(*)
begin
	if( MemToReg )		// If it was a memory operation
	begin
		DMEM_o_Write_Data <= DMEM_o_Read_Data;		// We will write back value from memory
		DMEM_o_Done <= DMEM_o_Mem_Valid;				// Write back only if value is valid
	end
	else
	begin
		DMEM_o_Write_Data <= DMEM_i_Result;		// Else we will write back value from ALU
		DMEM_o_Done <= TRUE;
	end
end

//===================================================================
//	Write-Back
pipe_mem_wb #(	.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.REG_ADDR_WIDTH(REG_ADDR_WIDTH)
			)
			PIPE_MEM_WB
			(		// Inputs
				.i_Clk(i_Clk),
				.i_Reset_n(i_Reset_n),
				.i_Flush(Hazard_Flush_MEM),
				.i_Stall(Hazard_Stall_WB),
							
					// Pipe in/out
				.i_WriteBack_Data(DMEM_o_Write_Data),
				.o_WriteBack_Data(WB_i_Write_Data),
				.i_Writes_Back(DMEM_i_Writes_Back),
				.o_Writes_Back(WB_i_Writes_Back),
				.i_Write_Addr(DMEM_i_Write_Addr),
				.o_Write_Addr(DEC_i_Write_Register)
			);


	// Write-Back is simply wires feeding back into regfile to perform writes
	// (SEE REGFILE)

	

//===================================================================
//	Arbitration Logic

// Memory arbiter
core_memory_arbiter	#(	.DATA_WIDTH(DATA_WIDTH),
					.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH)
				)
				ARBITER	
				(
					// General
					.i_Clk(i_Clk),
					.i_Reset_n(i_Reset_n),
			
					// Requests to/from IMEM - Assume we always read
					.i_IMEM_Valid(Arbiter_i_IMEM_Valid),						// If IMEM request is valid
					.i_IMEM_Address(Arbiter_i_IMEM_Address),		// IMEM request addr.
					.o_IMEM_Valid(Arbiter_o_IMEM_Valid),
					.o_IMEM_Last(Arbiter_o_IMEM_Last),
					.o_IMEM_Data(Arbiter_o_IMEM_Data),
					
					// Requests to/from DMEM
					.i_DMEM_Valid(Arbiter_i_DMEM_Valid),
					.i_DMEM_Read_Write_n(Arbiter_i_DMEM_Read_Write_n),
					.i_DMEM_Address(Arbiter_i_DMEM_Address),
					.i_DMEM_Data(Arbiter_i_DMEM_Data),
					.o_DMEM_Valid(Arbiter_o_DMEM_Valid),
					.o_DMEM_Data_Read(Arbiter_o_DMEM_Data_Read),
					.o_DMEM_Last(Arbiter_o_DMEM_Last),
					.o_DMEM_Data(Arbiter_o_DMEM_Data),
					
					
					// Interface to outside of the core
					.o_MEM_Valid(o_MEM_Valid),
					.o_MEM_Address(o_MEM_Address),
					.o_MEM_Read_Write_n(o_MEM_Read_Write_n),
					
						// Write data interface
					.o_MEM_Data(o_MEM_Data),
					.i_MEM_Data_Read(i_MEM_Data_Read),
					
						// Read data interface
					.i_MEM_Data(i_MEM_Data),
					.i_MEM_Valid(i_MEM_Valid),
					
					.i_MEM_Last(i_MEM_Last)
				);

// Forwarding logic
forwarding_unit	#(	.DATA_WIDTH(DATA_WIDTH),
					.REG_ADDR_WIDTH(REG_ADDR_WIDTH)
				)
				FORWARDING_UNIT
				(
					// Feedback from DEC
					.i_DEC_Uses_RS(DEC_o_Uses_RS),
					.i_DEC_RS_Addr(DEC_o_Read_Register_1),
					.i_DEC_Uses_RT(DEC_o_Uses_RT),								// DEC wants to use RT
					.i_DEC_RT_Addr(DEC_o_Read_Register_2),							// RT request addr.
					.i_DEC_RS_Data(DEC_o_Read_Data_1),
					.i_DEC_RT_Data(DEC_o_Read_Data_2),
					
					// Feedback from EX
					.i_EX_Writes_Back(EX_i_Writes_Back),								// EX is valid for analysis
					.i_EX_Valid(ALU_i_Valid),								// If it's a valid ALU op or not
					.i_EX_Write_Addr(EX_i_Write_Addr),							// What EX will write to
					.i_EX_Write_Data(ALU_o_Result),
					
					// Feedback from MEM
					.i_MEM_Writes_Back(DMEM_i_Writes_Back),								// MEM is valid for analysis
					.i_MEM_Write_Addr(DMEM_i_Write_Addr),							// What MEM will write to
					.i_MEM_Write_Data(DMEM_o_Write_Data),
					
					// Feedback from WB
					.i_WB_Writes_Back(WB_i_Writes_Back),								// WB is valid for analysis
					.i_WB_Write_Addr(DEC_i_Write_Register),							// What WB will write to
					.i_WB_Write_Data(WB_i_Write_Data),
					
					//===============================================
					// IFetch forwarding
					
						// None
						
					// DEC forwarding
					.o_DEC_RS_Override_Data(FORWARD_o_Forwarded_Data_1),
					.o_DEC_RT_Override_Data(FORWARD_o_Forwarded_Data_2)				
				);
				
// Hazard detection unit / Stall logic
hazard_detection_unit 	#(  .DATA_WIDTH(DATA_WIDTH),
							.ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
							.REG_ADDR_WIDTH(REG_ADDR_WIDTH)
						)
						HAZARD_DETECTION_UNIT
						(
							.i_Clk(i_Clk),
							.i_Reset_n(i_Reset_n),
						
							//==============================================
							// Overall state
							.i_External_Stall(i_External_Stall),

							//==============================================
							// Hazard in DECODE?
							.i_DEC_Uses_RS(DEC_o_Uses_RS),								// DEC wants to use RS
							.i_DEC_RS_Addr(DEC_o_Read_Register_1),							// RS request addr.
							.i_DEC_Uses_RT(DEC_o_Uses_RT),								// DEC wants to use RT
							.i_DEC_RT_Addr(DEC_o_Read_Register_2),							// RT request addr.
							.i_DEC_Branch_Instruction(DEC_o_Is_Branch),
							
							//===============================================
							// Feedback from IF
							.i_IF_Done(IMEM_o_Valid),						// If IF's value has reached steady state
							
							// Feedback from EX
							.i_EX_Writes_Back(EX_i_Writes_Back),					// EX is valid for data dependency analysis
							.i_EX_Uses_Mem(EX_i_Mem_Valid),
							.i_EX_Write_Addr(EX_i_Write_Addr),							// What EX will write to
							.i_EX_Branch(EX_Take_Branch),							// If EX says we are branching
							.i_EX_Branch_Target(EX_i_Branch_Target),
							
							// Feedback from MEM
							.i_MEM_Uses_Mem(DMEM_i_Mem_Valid),								// If it's a memop
							.i_MEM_Writes_Back(DMEM_i_Writes_Back),						// MEM is valid for analysis
							.i_MEM_Write_Addr(DMEM_i_Write_Addr),							// What MEM will write to
							.i_MEM_Done(DMEM_o_Done),									// If MEM's value has reached steady state								
							
							// Feedback from WB
							.i_WB_Writes_Back(WB_i_Writes_Back),
							.i_WB_Write_Addr(DEC_i_Write_Register),
							
							//===============================================
							// Branch hazard handling
							.o_IF_Branch(IFetch_i_Load),
							.o_IF_Branch_Target(IFetch_i_PCSrc),
							
							//===============================================
							// IFetch validation
							.o_IF_Stall(Hazard_Stall_IF),
							.o_IF_Smash(Hazard_Flush_IF),
							
							// DECODE validation
							.o_DEC_Stall(Hazard_Stall_DEC),
							.o_DEC_Smash(Hazard_Flush_DEC),
							
							// EX validation
							.o_EX_Stall(Hazard_Stall_EX),
							.o_EX_Smash(Hazard_Flush_EX),
							
							// MEM validation
							.o_MEM_Stall(Hazard_Stall_MEM),
							.o_MEM_Smash(Hazard_Flush_MEM),
							
							.o_WB_Stall(Hazard_Stall_WB),
							.o_WB_Smash(Hazard_Flush_WB)
						);

endmodule
