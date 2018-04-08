/* mips_cpu.v
* Author: Pravin P. Prabhu, Dean Tullsen, and Zinsser Zhang
* Last Revision: 04/28/2017
* Abstract:
*	The top level module for the MIPS32 processor. This top level module
* handles loading data from flash to SDRAM and keep track of core's performance
* The main classic 5-stage MIPS pipeline is defined in mips_core module.
*/
module mips_cpu(// General	 
				input CLOCK_50,	//These inputs are all pre-defined input/output pin names
				//input Global_Reset_n,		// TEMP - Remove this after testing
				input [3:0] KEY,	// which correspond to the DE2_pin_assignments,csv file.  This
				input [17:0] SW,	// way, the mapping is automatically taken care of if we get the
				output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, // name right.
				output [7:0] LEDG,
				output [17:0] LEDR,
				
				//SDRAM interface
				output [11:0] DRAM_ADDR,   
				output DRAM_BA_0,
				output DRAM_BA_1,
				output DRAM_CAS_N,
				output DRAM_CKE,
				output DRAM_CLK,
				output DRAM_CS_N,
				inout [15:0] DRAM_DQ,
				output DRAM_LDQM,
				output DRAM_UDQM,
				output DRAM_RAS_N,
				output DRAM_WE_N,
				
				//Flash RAM interface
				output [21:0] FL_ADDR, 	   
				inout [7:0] FL_DQ,
				output FL_CE_N,
				output FL_OE_N,
				output FL_RST_N,
				output FL_WE_N,
				
				 //SRAM interface
				output [17:0] SRAM_ADDR,  
				inout [15:0] SRAM_DQ,
				output SRAM_UB_N,
				output SRAM_LB_N,
				output SRAM_WE_N,
				output SRAM_OE_N,
				output SRAM_CE_N
			);

//===================================================================
//	Internal Wiring
//===================================================================

//===================================================================
// General Signals
localparam FALSE = 1'b0;
localparam TRUE = 1'b1;
localparam ADDRESS_WIDTH = 22;
localparam CORE_ADDRESS_WIDTH = 21;
localparam DATA_WIDTH = 32;
//wire Global_Reset_n;			// Global reset
wire Global_Reset_n = KEY[0];

	// MTC0 codes - Did we pass/fail a test or reach the done state?
localparam MTC0_NOOP = 0;		// No significance
localparam MTC0_PASS = 1;			// Passed a test
localparam MTC0_FAIL = 2;		// Failed a test
localparam MTC0_DONE = 3;			// Have completed execution

assign LEDG[7:1] = 0;
assign LEDR[17:1] = 0;

assign SRAM_ADDR = 0;
assign SRAM_UB_N = 0;
assign SRAM_LB_N = 0;
assign SRAM_WE_N = 0;
assign SRAM_OE_N = 0;
assign SRAM_CE_N = 0;

//===================================================================
// CORE Signals
wire CORE_i_External_Stall;
wire CORE_o_MEM_Valid;
wire CORE_o_MEM_Read_Write_n;
wire [CORE_ADDRESS_WIDTH-1:0] CORE_o_MEM_Address;
wire [DATA_WIDTH-1:0] CORE_o_MEM_Data;
wire CORE_i_MEM_Valid;
wire CORE_i_MEM_Data_Read;
wire CORE_i_MEM_Last;
wire [DATA_WIDTH-1:0] CORE_i_MEM_Data;

// Outputs for Done flag
wire [15:0] CORE_o_Pass_Done_Value;	// reports the value of a PASS/FAIL/DONE instruction
wire [1:0] CORE_o_Pass_Done_Change;	// indicates the above signal is meaningful
									// 1 = pass, 2 = fail, 3 = done

// Outputs for performance display
wire [7:0] CORE_o_Num_Inst_Executed;
wire [20:0] CORE_o_IMEM_i_Address;

//===================================================================
// Flash Signals
wire o_FlashLoader_Done;						// Raised when the loader finishes
wire o_FlashLoader_SDRAM_Read_Write_n;		// FlashLoader's actual request to dmem
wire o_FlashLoader_SDRAM_Req_Valid;				// FlashLoader's verification of request to dmem
wire [ADDRESS_WIDTH-1:0] o_FlashLoader_SDRAM_Addr;		// FlashLoader's request addrto dmem
wire [DATA_WIDTH-1:0] o_FlashLoader_SDRAM_Data;			// FlashLoader's output data
wire i_FlashLoader_SDRAM_Data_Read;			// FlashLoader's input callback from dmem
wire i_FlashLoader_SDRAM_Last;					// ""
wire [21:0] o_FlashLoader_FL_Addr;			// FlashLoader's addr request to flash
wire [7:0] i_FlashLoader_FL_Data;				// FlashLoader's data coming back from flash
wire o_FlashLoader_FL_Chip_En_n;			// FlashLoader's chip enable to flash
wire o_FlashLoader_FL_Output_En_n;				// "" (output enable)
wire o_FlashLoader_FL_Reset_n;				// "" (flash reset)
wire o_FlashLoader_FL_Write_En_n;				// Write enable going out to flash

	// Top level connections
assign FL_ADDR = o_FlashLoader_FL_Addr;					// Addr we're requesting to deal with
assign i_FlashLoader_FL_Data = FL_DQ;						// Incoming data from flash (for reads)
assign FL_CE_N = o_FlashLoader_FL_Chip_En_n;			// Flash chip enable
assign FL_OE_N = o_FlashLoader_FL_Output_En_n;				// Flash output enable
assign FL_WE_N = o_FlashLoader_FL_Write_En_n;			// Flash write enable
assign FL_RST_N	= o_FlashLoader_FL_Reset_n;					// Flash reset


//===================================================================
// Arbiter Signals

wire Arbiter_i_Flash_Valid;
wire [DATA_WIDTH-1:0] Arbiter_i_Flash_Data;
wire [ADDRESS_WIDTH-1:0] Arbiter_i_Flash_Address;
wire Arbiter_o_Flash_Data_Read;
//wire [DATA_WIDTH-1:0] Arbiter_o_Flash_Data_Read;
wire Arbiter_o_Flash_Last;

assign Arbiter_i_Flash_Valid = o_FlashLoader_SDRAM_Req_Valid;
assign Arbiter_i_Flash_Data = o_FlashLoader_SDRAM_Data;
assign Arbiter_i_Flash_Address = o_FlashLoader_SDRAM_Addr;
assign i_FlashLoader_SDRAM_Data_Read = Arbiter_o_Flash_Data_Read;
assign i_FlashLoader_SDRAM_Last = Arbiter_o_Flash_Last;


//====================================================================
// Controller Signals
wire [ADDRESS_WIDTH-1:0] SDRAM_i_Address;				// Transact address
wire SDRAM_i_Valid;									// If request is valid
wire SDRAM_i_Read_Write_n;								// Request type

wire [DATA_WIDTH-1:0] SDRAM_i_Data;					// What to write
wire SDRAM_o_Data_Read;									// If data was read or not

wire [DATA_WIDTH-1:0] SDRAM_o_Data;					// Read in data from SDRAM
wire SDRAM_o_Data_Valid;								// If read in data is valid

wire SDRAM_o_Last;									// If we're on the last part of the burst


wire i_Clk;
//===================================================================
// Top-level Connections
	// Clock handling for mem & processor
wire Done = (CORE_o_Pass_Done_Change == MTC0_DONE);
wire Local_Clock;
wire Internal_Reset_n;
assign CORE_i_External_Stall = !o_FlashLoader_Done || Done;

`ifdef MODEL_TECH
assign Internal_Reset_n = Global_Reset_n;
assign Local_Clock = CLOCK_50;

`else
wire PLL_Locked;
pll my_pll(
	.areset(!Global_Reset_n),
	.inclk0(CLOCK_50),
	.c0(Local_Clock),
	.locked(PLL_Locked)
	);
assign Internal_Reset_n = PLL_Locked && Global_Reset_n;

`endif

assign i_Clk = Local_Clock;

// Performance metrics
reg [31:0] CycleCount;					// # of cycles that have passed since reset
reg [31:0] InstructionsExecuted;	// # of insts that have went through WB stage since reset
reg displaystop;


always @(posedge i_Clk or negedge Internal_Reset_n)

begin
	if( !Internal_Reset_n )
	begin
		// Asynch. reset on counters
		CycleCount <= 32'b0;
		InstructionsExecuted <= 32'b0;
		displaystop <= 0;
	end
	else
	begin
		// If we're currently executing instructions...
		if( o_FlashLoader_Done && !Done )
		begin
			if (!displaystop && InstructionsExecuted > 1000000000)
			begin
				displaystop <= 1;
			end
			InstructionsExecuted <= InstructionsExecuted + CORE_o_Num_Inst_Executed;

			CycleCount <= CycleCount + 32'b1;	// Always count another cycle
		end
	end
end

	// Visual output
assign LEDG[0] = (Done);
assign LEDR[0] = (!Done);

reg[3:0] HEX_Buf [7:0];	// Buffers for visualization of data

always @(posedge i_Clk)
begin
	HEX_Buf[0] <= 4'd0;
	HEX_Buf[1] <= 4'd0;
	HEX_Buf[2] <= 4'd0;
	HEX_Buf[3] <= 4'd0;
	HEX_Buf[4] <= 4'd0;
	HEX_Buf[5] <= 4'd0;
	HEX_Buf[6] <= 4'd0;
	HEX_Buf[7] <= 4'd0;

	case(SW[1:0])
		2'd0:	// Default: Display Pass/Done/Fail, PC, and PDF Value information
		begin
			HEX_Buf[0] <= CORE_o_Pass_Done_Value[3:0];
			HEX_Buf[1] <= CORE_o_Pass_Done_Value[7:4];
			HEX_Buf[6] <= CORE_o_IMEM_i_Address[3:0];
			HEX_Buf[7] <= CORE_o_IMEM_i_Address[7:4];
		end		
		
		2'd1:	// Cycle Count
		begin
			HEX_Buf[0] <= CycleCount[3:0];
			HEX_Buf[1] <= CycleCount[7:4];
			HEX_Buf[2] <= CycleCount[11:8];
			HEX_Buf[3] <= CycleCount[15:12];
			HEX_Buf[4] <= CycleCount[19:16];
			HEX_Buf[5] <= CycleCount[23:20];
			HEX_Buf[6] <= CycleCount[27:24];
			HEX_Buf[7] <= CycleCount[31:28];	
		end
		
		2'd2:	// Instructions Executed
		begin
			HEX_Buf[0] <= InstructionsExecuted[3:0];
			HEX_Buf[1] <= InstructionsExecuted[7:4];
			HEX_Buf[2] <= InstructionsExecuted[11:8];
			HEX_Buf[3] <= InstructionsExecuted[15:12];
			HEX_Buf[4] <= InstructionsExecuted[19:16];
			HEX_Buf[5] <= InstructionsExecuted[23:20];
			HEX_Buf[6] <= InstructionsExecuted[27:24];
			HEX_Buf[7] <= InstructionsExecuted[31:28];		
		end
		
		2'd3: // (free for any other metric)
		begin
		end
		
	endcase
end

wire [6:0] HEX2_SSD, HEX2_PFD;
SevenSegmentDisplayDecoder SSD0 (i_Clk, HEX0, HEX_Buf[0]);
SevenSegmentDisplayDecoder SSD1 (i_Clk, HEX1, HEX_Buf[1]);
SevenSegmentDisplayDecoder SSD2 (i_Clk, HEX2_SSD, HEX_Buf[2]);
SevenSegmentDisplayDecoder SSD3 (i_Clk, HEX3, HEX_Buf[3]);
SevenSegmentDisplayDecoder SSD4 (i_Clk, HEX4, HEX_Buf[4]);
SevenSegmentDisplayDecoder SSD5 (i_Clk, HEX5, HEX_Buf[5]);
SevenSegmentDisplayDecoder SSD6 (i_Clk, HEX6, HEX_Buf[6]);
SevenSegmentDisplayDecoder SSD7 (i_Clk, HEX7, HEX_Buf[7]);
SevenSegmentPFD PFD2 (i_Clk, HEX2_PFD, CORE_o_Pass_Done_Change);	// display pass/done/fail status

	// Special case: If SW is 0, then HEX2 output comes from PFD. Else, comes from SSD.
assign HEX2 = (SW[1:0]==2'd0 ? HEX2_PFD : HEX2_SSD);

/*
SevenSegmentPFD SSD3 (i_Clk, HEX2, CORE_o_Pass_Done_Change);	// display pass/done/fail status
	
SevenSegmentDisplayDecoder SSD0 (i_Clk, HEX0, CORE_o_Pass_Done_Value[3:0]);
SevenSegmentDisplayDecoder SSD1 (i_Clk, HEX1, CORE_o_Pass_Done_Value[7:4]);

SevenSegmentDisplayDecoder SSD7 (i_Clk, HEX7, IMEM_i_Address[7:4]);
SevenSegmentDisplayDecoder SSD6 (i_Clk, HEX6, IMEM_i_Address[3:0]);

*/

//===================================================================
//	Structural Description - CORE
//===================================================================
mips_core #(
		.DATA_WIDTH(DATA_WIDTH),
		.WORD_ADDRESS_WIDTH(CORE_ADDRESS_WIDTH)
	) CORE (
		.i_Clk(i_Clk),
		.i_Reset_n(Internal_Reset_n),
		.i_External_Stall(CORE_i_External_Stall),

		.o_MEM_Valid(CORE_o_MEM_Valid),
		.o_MEM_Read_Write_n(CORE_o_MEM_Read_Write_n),
		.o_MEM_Address(CORE_o_MEM_Address),
		.o_MEM_Data(CORE_o_MEM_Data),
		.i_MEM_Valid(CORE_i_MEM_Valid),
		.i_MEM_Data_Read(CORE_i_MEM_Data_Read),
		.i_MEM_Last(CORE_i_MEM_Last),
		.i_MEM_Data(CORE_i_MEM_Data),

		.o_Pass_Done_Value(CORE_o_Pass_Done_Value),
		.o_Pass_Done_Change(CORE_o_Pass_Done_Change),

		.o_Num_Inst_Executed(CORE_o_Num_Inst_Executed),
		.o_IMEM_i_Address(CORE_o_IMEM_i_Address)
	);

//===================================================================
//	Arbitration Logic

// Memory arbiter
memory_arbiter	#(	.DATA_WIDTH(DATA_WIDTH),
					.ADDRESS_WIDTH(ADDRESS_WIDTH)
				)
				ARBITER	
				(
					// General
					.i_Clk(i_Clk),
					.i_Reset_n(Internal_Reset_n),
					
					// Requests to/from CORE
					.i_CORE_Valid(CORE_o_MEM_Valid),
					.i_CORE_Read_Write_n(CORE_o_MEM_Read_Write_n),
					.i_CORE_Address(CORE_o_MEM_Address),
					.i_CORE_Data(CORE_o_MEM_Data),
					.o_CORE_Valid(CORE_i_MEM_Valid),
					.o_CORE_Data_Read(CORE_i_MEM_Data_Read),
					.o_CORE_Last(CORE_i_MEM_Last),
					.o_CORE_Data(CORE_i_MEM_Data),
					
					// Requests to/from FLASH - Assume we always write
					.i_Flash_Valid(Arbiter_i_Flash_Valid),
					.i_Flash_Data(Arbiter_i_Flash_Data),
					.i_Flash_Address(Arbiter_i_Flash_Address),
					.o_Flash_Data_Read(Arbiter_o_Flash_Data_Read),
					.o_Flash_Last(Arbiter_o_Flash_Last),
					
					// Interface with SDRAM Controller
					.o_MEM_Valid(SDRAM_i_Valid),
					.o_MEM_Address(SDRAM_i_Address),
					.o_MEM_Read_Write_n(SDRAM_i_Read_Write_n),
					
						// Write data interface
					.o_MEM_Data(SDRAM_i_Data),
					.i_MEM_Data_Read(SDRAM_o_Data_Read),
					
						// Read data interface
					.i_MEM_Data(SDRAM_o_Data),
					.i_MEM_Data_Valid(SDRAM_o_Data_Valid),
					
					.i_MEM_Last(SDRAM_o_Last)
				);

sdram_controller memory_controller(
					.i_Clk(i_Clk),
					.i_Reset(!Internal_Reset_n),
					
					// Request interface
					.i_Addr(SDRAM_i_Address),
					.i_Req_Valid(SDRAM_i_Valid),
					.i_Read_Write_n(SDRAM_i_Read_Write_n),
					
					// Write .data interface
					.i_Data(SDRAM_i_Data),
					.o_Data_Read(SDRAM_o_Data_Read),
					
					// Read data .interface
					.o_Data(SDRAM_o_Data),
					.o_Data_Valid(SDRAM_o_Data_Valid),
					
					// output
					.o_Last(SDRAM_o_Last),
					
						// SDRAM interface
					.b_Dq(DRAM_DQ),
					.o_Addr(DRAM_ADDR),
					.o_Ba({DRAM_BA_0,DRAM_BA_1}),
					.o_Clk(DRAM_CLK),
					.o_Cke(DRAM_CKE),
					.o_Cs_n(DRAM_CS_N),
					.o_Ras_n(DRAM_RAS_N),
					.o_Cas_n(DRAM_CAS_N),
					.o_We_n(DRAM_WE_N),
					.o_Dqm({DRAM_UDQM,DRAM_LDQM})
				);

//===================================================================
//	Initialization

//	Flash Loader
// speed ups for simulation
`ifdef MODEL_TECH
flashreader#(.WORDS_TO_LOAD(32'h00008000),
			.FLASH_READ_WAIT_TIME_PS(0))
`else
flashreader
`endif
flashloader2(	.i_Clk(i_Clk), 
				.i_Reset_n(Internal_Reset_n),
				.o_Done(o_FlashLoader_Done),
				.o_SDRAM_Addr(o_FlashLoader_SDRAM_Addr),
				.o_SDRAM_Req_Valid(o_FlashLoader_SDRAM_Req_Valid),
				.o_SDRAM_Read_Write_n(o_FlashLoader_SDRAM_Read_Write_n),
				.o_SDRAM_Data(o_FlashLoader_SDRAM_Data),
				.i_SDRAM_Data_Read(i_FlashLoader_SDRAM_Data_Read),
				.i_SDRAM_Last(i_FlashLoader_SDRAM_Last),
				.o_FL_Addr(o_FlashLoader_FL_Addr),
				.i_FL_Data(i_FlashLoader_FL_Data),
				.o_FL_Chip_En_n(o_FlashLoader_FL_Chip_En_n),
				.o_FL_Output_En_n(o_FlashLoader_FL_Output_En_n),
				.o_FL_Write_En_n(o_FlashLoader_FL_Write_En_n),
				.o_FL_Reset_n(o_FlashLoader_FL_Reset_n)
			);

initial
begin
end

endmodule
