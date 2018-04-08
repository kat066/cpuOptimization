/* memory_arbiter.v
* Author: Pravin P. Prabhu, Zinsser Zhang
* Last Revision: 04/29/2017
* Abstract:
*	Provides arbitration amongst sources that all wish to request from main
* memory. Will service sources in order of priority, which is:
* (high)
* flashloader
* CORE
* (low)
*/
module memory_arbiter	#(	parameter DATA_WIDTH=32,
							parameter ADDRESS_WIDTH=22,
							parameter CORE_ADDRESS_WIDTH=21
						)
						(
							// General
							input i_Clk,
							input i_Reset_n,

							// Requests to/from CORE
							input i_CORE_Valid,
							input i_CORE_Read_Write_n,
							input [CORE_ADDRESS_WIDTH-1:0] i_CORE_Address,
							input [DATA_WIDTH-1:0] i_CORE_Data,
							output reg o_CORE_Valid,
							output reg o_CORE_Data_Read,
							output reg o_CORE_Last,
							output reg [DATA_WIDTH-1:0] o_CORE_Data,

							// Requests to/from FLASH - Assume we always write
							input i_Flash_Valid,
							input [DATA_WIDTH-1:0] i_Flash_Data,
							input [ADDRESS_WIDTH-1:0] i_Flash_Address,
							output reg o_Flash_Data_Read,
							output reg o_Flash_Last,

							// Interface with SDRAM Controller
							output reg o_MEM_Valid,
							output reg [ADDRESS_WIDTH-1:0] o_MEM_Address,
							output reg o_MEM_Read_Write_n,

								// Write data interface
							output reg [DATA_WIDTH-1:0] o_MEM_Data,
							input i_MEM_Data_Read,

								// Read data interface
							input [DATA_WIDTH-1:0] i_MEM_Data,
							input i_MEM_Data_Valid,

							input i_MEM_Last				// If we're on the last piece of the transaction
						);

	// Consts
	localparam TRUE = 1'b1;
	localparam FALSE = 1'b0;
	localparam READ = 1'b1;
	localparam WRITE = 1'b0;

	// State of the arbiter
	localparam STATE_READY = 4'd0;
	localparam STATE_SERVICING_FLASH = 4'd1;
	localparam STATE_SERVICING_CORE = 4'd2;

	reg [3:0] State;
	reg [3:0] NextState;

	always @(*)
	begin
		NextState <= State;
		case(State)
			STATE_READY:
			begin
				if (i_Flash_Valid)
					NextState <= STATE_SERVICING_FLASH;
				else if (i_CORE_Valid)
					NextState <= STATE_SERVICING_CORE;
			end

			STATE_SERVICING_FLASH:
			begin
				if (i_MEM_Last)
					NextState <= STATE_READY;
			end

			STATE_SERVICING_CORE:
			begin
				if (i_MEM_Last)
					NextState <= STATE_READY;
			end
		endcase

		o_CORE_Valid <= FALSE;
		o_CORE_Data_Read <= FALSE;
		o_CORE_Last <= FALSE;
		o_CORE_Data <= {32{1'bx}};
		o_Flash_Data_Read <= FALSE;
		o_Flash_Last <= FALSE;
		o_MEM_Valid <= FALSE;
		o_MEM_Address <= {ADDRESS_WIDTH{1'bx}};
		o_MEM_Read_Write_n <= READ;
		o_MEM_Data <= {32{1'bx}};

		if (State == STATE_SERVICING_FLASH || NextState == STATE_SERVICING_FLASH)
		begin
			// Servicing flash: Bridge flash I/O
			o_MEM_Valid <= TRUE;
			o_MEM_Address <= i_Flash_Address;
			o_MEM_Read_Write_n <= WRITE;
			o_MEM_Data <= i_Flash_Data;
			o_Flash_Data_Read <= i_MEM_Data_Read;
			o_Flash_Last <= i_MEM_Last;
		end
		else if (State == STATE_SERVICING_CORE || NextState == STATE_SERVICING_CORE)
		begin
			o_MEM_Valid <= TRUE;
			o_MEM_Address <= {i_CORE_Address, 1'b0};
			o_MEM_Read_Write_n <= i_CORE_Read_Write_n;
			o_MEM_Data <= i_CORE_Data;
			o_CORE_Valid <= i_MEM_Data_Valid;
			o_CORE_Data_Read <= i_MEM_Data_Read;
			o_CORE_Last <= i_MEM_Last;
			o_CORE_Data <= i_MEM_Data;
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
