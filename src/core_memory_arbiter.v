/* core_memory_arbiter.v
* Author: Zinsser Zhang
* Last Revision: 04/29/2017
* Based on Pravin P. Prabhu's memory_arbiter.v
* Abstract:
*	Provides arbitration between i_cache and d_cache for request to memory.
* All addresses used in this scope are word addresses (32-bit/4-byte aligned)
* Will service sources in order of priority, which is:
* (high)
* imem
* dmem
* (low)
*/
module core_memory_arbiter	#(	parameter DATA_WIDTH=32,
							parameter ADDRESS_WIDTH=21
						)
						(
							// General
							input i_Clk,
							input i_Reset_n,
							
							// Requests to/from IMEM - Assume we always read
							input i_IMEM_Valid,						// If IMEM request is valid
							input [ADDRESS_WIDTH-1:0] i_IMEM_Address,		// IMEM request addr.
							output reg o_IMEM_Valid,
							output reg o_IMEM_Last,
							output reg [DATA_WIDTH-1:0] o_IMEM_Data,
							
							// Requests to/from DMEM
							input i_DMEM_Valid,
							input i_DMEM_Read_Write_n,
							input [ADDRESS_WIDTH-1:0] i_DMEM_Address,
							input [DATA_WIDTH-1:0] i_DMEM_Data,
							output reg o_DMEM_Valid,
							output reg o_DMEM_Data_Read,
							output reg o_DMEM_Last,
							output reg [DATA_WIDTH-1:0] o_DMEM_Data,
							
							// Interface to outside of the core
							output reg o_MEM_Valid,
							output reg [ADDRESS_WIDTH-1:0] o_MEM_Address,
							output reg o_MEM_Read_Write_n,
							
								// Write data interface
							output reg [DATA_WIDTH-1:0] o_MEM_Data,
							input i_MEM_Data_Read,
							
								// Read data interface
							input [DATA_WIDTH-1:0] i_MEM_Data,
							input i_MEM_Valid,
							
							input i_MEM_Last				// If we're on the last piece of the transaction
						);
	
	// Consts
	localparam TRUE = 1'b1;
	localparam FALSE = 1'b0;
	localparam READ = 1'b1;
	localparam WRITE = 1'b0;	
	
	// State of the arbiter
	localparam STATE_READY = 4'd0;
	localparam STATE_SERVICING_IMEM = 4'd1;
	localparam STATE_SERVICING_DMEM = 4'd2;
	
	reg [3:0] State;
	reg [3:0] NextState;

	always @(*)
	begin
		NextState <= State;
		case(State)
			STATE_READY:
			begin
				if (i_IMEM_Valid)
					NextState <= STATE_SERVICING_IMEM;
				else if (i_DMEM_Valid)
					NextState <= STATE_SERVICING_DMEM;
			end

			STATE_SERVICING_IMEM:
			begin
				if (i_MEM_Last)
					NextState <= STATE_READY;
			end

			STATE_SERVICING_DMEM:
			begin
				if (i_MEM_Last)
					NextState <= STATE_READY;
			end
		endcase

		o_IMEM_Valid <= FALSE;
		o_IMEM_Last <= FALSE;
		o_IMEM_Data <= {32{1'bx}};
		o_DMEM_Valid <= FALSE;
		o_DMEM_Data_Read <= FALSE;
		o_DMEM_Last <= FALSE;
		o_DMEM_Data <= {32{1'bx}};
		o_MEM_Valid <= FALSE;
		o_MEM_Address <= {ADDRESS_WIDTH{1'bx}};
		o_MEM_Read_Write_n <= READ;
		o_MEM_Data <= {32{1'bx}};

		if (State == STATE_SERVICING_IMEM || NextState == STATE_SERVICING_IMEM)
		begin
			o_MEM_Valid <= TRUE;
			o_MEM_Address <= i_IMEM_Address;
			o_MEM_Read_Write_n <= READ;
			o_IMEM_Valid <= i_MEM_Valid;
			o_IMEM_Last <= i_MEM_Last;
			o_IMEM_Data <= i_MEM_Data;			
		end
		else if (State == STATE_SERVICING_DMEM || NextState == STATE_SERVICING_DMEM)
		begin
			o_MEM_Valid <= TRUE;
			o_MEM_Address <= i_DMEM_Address;
			o_MEM_Read_Write_n <= i_DMEM_Read_Write_n;
			o_MEM_Data <= i_DMEM_Data;
			o_DMEM_Valid <= i_MEM_Valid;
			o_DMEM_Data_Read <= i_MEM_Data_Read;
			o_DMEM_Last <= i_MEM_Last;
			o_DMEM_Data <= i_MEM_Data;
		end
	end
	
	// State driver
	always @(posedge i_Clk or negedge i_Reset_n)
	begin
		if( !i_Reset_n )
			// Defaults			
			State <= STATE_READY;	
		else
			State <= NextState;
	end
		
endmodule