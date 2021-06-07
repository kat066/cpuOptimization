
`include "mips_core.svh"
`define ACTIVE_LIST_QUEUE_WIDTH 8

/* This is the interface for the Active List's Commit Logic.
 *
 * The interface contains all the information that needs to be 
 * sent to either the Register Table or Main Memory in order to 
 * actually WRITE the result data, thereby "committing" the instruction.
 *
 * The interface contains:
 *		A physical register address, which is used to write the result data
 *			into the Register File (if that's where the instruction's destination is)!
 *		A Main Memory address, which is used to write the result data into
 *			Main Memory (if that's where the instruction's destination is)!
 *		A bit flag that is used to signal whether or not the data will be written 
 *			into the Register File,
 *		And a bit flag that is used to signal whether or not the data will be written
 *			into Main Memory.
 */
interface active_List_Commit_ifc ();
	mips_core_pkg::MipsReg reg_addr;				//The physical register address of where the result data 
													//that's being committed should go.
													
	logic [31 : 0] memory_addr;						//The Main Memory address of where the result data that'safely
													//being committed should go.
													
	logic [`DATA_WIDTH - 1 : 0] result_data;		//The result data that will actually be written into either the 
													//Register File, or Main Memory.
	
	logic Reg_WR_EN;								//Write Enable signal of a commit for the Register File. 
													//
													//(1 if the commit is for the Register File, 0 if it is for Main Memory).
	
	logic Mem_WR_EN;								//Write Enable signal of a commit for Main Memory.
													//
													//(1 if the commit is for Main Memory, 0 if it is for the Register File).
	
	modport out (output reg_addr, memory_addr, result_data, Reg_WR_EN, Mem_WR_EN);
	modport in (input reg_addr, memory_addr, result_data, Reg_WR_EN, Mem_WR_EN);
endinterface





interface active_List_ifc ();
	mips_core_pkg::MipsReg physical [32];			//Physical Register Address
	mips_core_pkg::MipsReg logical [32];			//Logical Register Address
	logic [`DATA_WIDTH - 1 : 0] mem_addr[32];		//Address in Main Memory					
	
	logic reg_or_mem[32];							//Flag to signal if data should commit to the
													//Register File, or to Main Memory.
													//
													//(1 for Register File, 0 for Main Memory).
													
	logic done [32];								//Flag to signal if the data corresponding to this 
													//mapping is ready to commit.
													//
													//(1 for "Ready to Commit", 0 for "Not Ready.")
	logic [`ADDR_WIDTH-1:0] instruction_ID[32];
													
	logic [4 : 0] head;								//Index used as a "head" pointer.
	logic [4 : 0] tail;								//Index used as a "tail" pointer.

	logic [`DATA_WIDTH - 1 : 0] result_data[32];				//The result data of some instruction.																
	

																					
	logic [`DATA_WIDTH - 1 : 0] new_result_mem_addr[32];								//The Main Memory address of the destination of a NEWLY INPUTTED
																					//instruction's result data.
																					
	logic [5 : 0] new_result_physical_addr_reg[32];										//The physical address of the destination of a NEWLY INPUTTED 
																					//instruction's result data.
																					
	logic new_reg_or_mem[32];															//Flag to signal if the NEWLY INPUTTED data should commit to the
																					//Register File, or to Main Memory.
																					
																					//(1 for Register File, 0 for Main Memory).	
																					

																					
	modport in (input result_data, new_result_mem_addr, new_result_physical_addr_reg, new_reg_or_mem);
endinterface


module active_List(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input wb,
	input logic [`DATA_WIDTH - 1 : 0] new_result_mem_addr,
	
	input logic [`ADDR_WIDTH-1:0] wb_instruction_ID,
	decoder_output_ifc.in register,
	hazard_control_ifc.in i_hc,		//Hazard Controls containing the flush and stall signals.
	write_back_ifc.in i_wb,
	register_Map_Table_Pairing_ifc.in i_map_pairing,		 			//Input map pairing to be added to the Active List's Mapping Table.
	register_Map_Table_Pairing_ifc.out flush_map_pairing,				//Output map pairing that is sent to the Register Map Table when a flush occurs.
	
	output active_list_flush_in_progress,
	active_List_Commit_ifc.out active_Commit							//Output data that is sent to the Register File and/or Main Memory, in order to
																		//actually commit the data!
);
	logic [`ADDR_WIDTH-1:0] next_ID;
	active_List_ifc a_l();
	logic flush_in_progress;
	logic [`ADDR_WIDTH-1:0]flushing_instruction_ID;
	initial begin
		
		for (int i = 0; i < 32; i++) begin
			a_l.physical[i] <= mips_core_pkg::MipsReg'(0);
			a_l.logical[i]  <= mips_core_pkg::MipsReg'(0);
				
			a_l.mem_addr[i]   <= 0;
			a_l.reg_or_mem[i] <= 1'b0;
			a_l.done[i] 	  <= 1'b0;
			a_l.instruction_ID[i] <= 32'b0;
		end
		flush_in_progress = 1'b0;
		
		flush_map_pairing.prev_physical_reg <= mips_core_pkg::MipsReg'(0);
		flush_map_pairing.prev_logical_reg  <= mips_core_pkg::MipsReg'(0);
		
		active_Commit.reg_addr      <= mips_core_pkg::MipsReg'(0);
		active_Commit.memory_addr   <= 0;
		active_Commit.result_data   <= 0;
		active_Commit.Reg_WR_EN  	<= 1'b0;
		active_Commit.Mem_WR_EN 	<= 1'b0;
		active_list_flush_in_progress <= 1'b0;
		next_ID = 32'b0;
	end

	
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			for (int i = 0; i < `ACTIVE_LIST_QUEUE_WIDTH; i++) a_l.result_data[i] <= 0;
			
			for (int i = 0; i < 32; i++) begin
				a_l.physical[i] <= mips_core_pkg::MipsReg'(0);
				a_l.logical[i]  <= mips_core_pkg::MipsReg'(0);
				
				a_l.mem_addr[i]   <= 0;
				a_l.reg_or_mem[i] <= 1'b0;
				a_l.done[i] 	  <= 1'b0;
				a_l.instruction_ID[i] <= 32'b0;
			end
			
			a_l.head <= 5'b00000;
			a_l.tail <= 5'b00000;
			

						
			flush_map_pairing.prev_physical_reg <= mips_core_pkg::MipsReg'(0);
			flush_map_pairing.prev_logical_reg  <= mips_core_pkg::MipsReg'(0);
			
			active_Commit.reg_addr      <= mips_core_pkg::MipsReg'(0);
			active_Commit.memory_addr   <= 0;
			active_Commit.result_data   <= 0;
			active_Commit.Reg_WR_EN  	<= 1'b0;
			active_Commit.Mem_WR_EN 	<= 1'b0;
			active_list_flush_in_progress <= 1'b0;
			next_ID = 32'b0;
		end
		
		//If a flush signal has been recieved, "lock down" the Active List.
		//This is done by setting "flush_in_progress" to 1.
		else if (i_hc.flush) begin
			flushing_instruction_ID = wb_instruction_ID;
			if (a_l.instruction_ID[a_l.tail] == wb_instruction_ID) begin
				flush_in_progress <= 1'b0;
				active_list_flush_in_progress <= 1'b0;
			end
			else begin
				flush_map_pairing.prev_physical_reg    <= a_l.physical[ a_l.tail ];
				flush_map_pairing.prev_logical_reg     <= a_l.logical[ a_l.tail ];
				flush_in_progress <= 1'b1;
				active_list_flush_in_progress <= 1'b1;
			end
			a_l.tail <= (a_l.tail == 0) ? a_l.tail <= 5'b11111 : a_l.tail <= a_l.tail - 1;
			
			if (a_l.done[a_l.head]==1'b1 & a_l.instruction_ID[a_l.head] != wb_instruction_ID) begin
				active_Commit.reg_addr		<= a_l.physical[a_l.head];
				active_Commit.memory_addr   <= a_l.mem_addr[a_l.head];
				active_Commit.result_data   <= a_l.result_data[ a_l.head ];
				active_Commit.Reg_WR_EN		<= a_l.reg_or_mem[ a_l.head ];
				active_Commit.Mem_WR_EN		<= ~a_l.reg_or_mem[ a_l.head ];
				a_l.head <= (a_l.head + 1) % 32;
			end
			
		end
		//While a flush is occurring, send back map pairings to the Register Map Table,
		//so it can reset its mapping, and de-increment the "tail" index for the 
		//Active List.
		//
		//All valid mappings will have been sent when "head" == "tail".  When that 
		//happens, release the "lock down" by setting "flush_in_progress" to 0.
		else if (flush_in_progress) begin					
			if (a_l.instruction_ID[a_l.tail] == flushing_instruction_ID) begin
				flush_in_progress <= 1'b0;
				active_list_flush_in_progress <= 1'b0;
			end
			else begin
				flush_map_pairing.prev_physical_reg    <= a_l.physical[ a_l.tail ];
				flush_map_pairing.prev_logical_reg     <= a_l.logical[ a_l.tail ];
				active_list_flush_in_progress <= 1'b1;
			end
			a_l.tail <= (a_l.tail == 0) ? a_l.tail <= 5'b11111 : a_l.tail <= a_l.tail - 1;
			if (a_l.done[a_l.head]==1'b1 & a_l.instruction_ID[a_l.head] != wb_instruction_ID) begin
				active_Commit.reg_addr		<= a_l.physical[a_l.head];
				active_Commit.memory_addr   <= a_l.mem_addr[a_l.head];
				active_Commit.result_data   <= a_l.result_data[ a_l.head ];
				active_Commit.Reg_WR_EN		<= a_l.reg_or_mem[ a_l.head ];
				active_Commit.Mem_WR_EN		<= ~a_l.reg_or_mem[ a_l.head ];
				a_l.head <= (a_l.head + 1) % 32;
			end
		end
				
		//If a flush signal has not occurred AND a flush is not in progress...
		else if (~(i_hc.flush | flush_in_progress)) begin	
			//If the Active List gets a signal from the Register Mapping table to add a new 
			//mapping, add it into the slot pointed to by the "tail" index, and then increment the 
			//"tail" index.
			//
			//(We should add an output signal to the Register Map Table that is sent to the Active List
			// for this purpose!)
			active_list_flush_in_progress <= 1'b0;
			if (~i_hc.stall) begin
				a_l.physical[(a_l.tail + 1) % 32]   <= i_map_pairing.prev_physical_reg;
				a_l.logical[(a_l.tail + 1) % 32]    <= i_map_pairing.prev_logical_reg;
				a_l.done[(a_l.tail + 1) % 32]	  	 <= 1'b0;
				a_l.instruction_ID[(a_l.tail + 1) % 32]	<= next_ID;
				next_ID <= next_ID + `ADDR_WIDTH'd1;
				a_l.tail 				 <= (a_l.tail + 1) % 32;
				a_l.new_result_physical_addr_reg[(a_l.tail + 1) % 32]	<= register.rw_addr;
			end		
			

				
			
	
			
			//Finally, continuously add incoming data from the "Write Back" stage into the Active List,
			//so long as no flush is occurring and no flush signal has been detected.
			//
			//(This can be done continuously because "a_l.new_active_list_tag" won't change unless
			// "a_l.new_result_data", "a_l.new_result_physical_addr_reg", "a_l.new_result_mem_addr",
			// and "a_l.new_act_List_tag" also change.)
			if(wb) begin
				a_l.new_reg_or_mem[wb_instruction_ID-a_l.instruction_ID[a_l.head]]=i_wb.uses_rw;
				a_l.result_data[wb_instruction_ID-a_l.instruction_ID[a_l.head]] 		   	   <= i_wb.rw_data;
				a_l.new_result_mem_addr[wb_instruction_ID-a_l.instruction_ID[a_l.head]]          <= new_result_mem_addr;
			end
			
			if (a_l.done[a_l.head]==1'b1 ) begin
				active_Commit.reg_addr		<= a_l.physical[a_l.head];
				active_Commit.memory_addr   <= a_l.mem_addr[a_l.head];
				active_Commit.result_data   <= a_l.result_data[ a_l.head ];
				active_Commit.Reg_WR_EN		<= a_l.reg_or_mem[ a_l.head ];
				active_Commit.Mem_WR_EN		<= ~a_l.reg_or_mem[ a_l.head ];
				a_l.head <= (a_l.head + 1) % 32;
			end
			
		end
			//If the mapping entry pointed to by the "head" index has its done bit set to 1, send the 
			//relevant data to be committed either by the Register File or Main Memory.  This is done 
			//by filling out the "active_Commit" interface, which will then be sent to both Register File and
			//Main Memory.  
	
	end
endmodule
