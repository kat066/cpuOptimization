
`include "mips_core.svh"
`define ACTIVE_LIST_QUEUE_WIDTH 8


/* This is the interface for the Active List's Mapping Table.
 *
 * Each entry is associated with an instruction that prompted a register remapping, 
 * and the purpose of the Active List's Mapping Table is to have a list of all the 
 * previous "physical to logical" register mappings for the REGISTER Map Tables.
 *
 * Each entry in the mapping table consists of:
 * 		A physical register address,
 * 		A logical register address, 
 *		An address in main memory, 
 *		A bit flag to signal whether or not the instruction corresponding 
 *			to this entry will write to the register file, or to main memory,
 *		A bit flag to signal that the data corresponding to this mapping is ready to commit.
 *		An index to act as a "head" pointer,
 *		An index to act as a "tail" pointer,
 *		And a index so that it will be possible to find the data entry in the
 *			Active List's Data Queue associated with this mapping entry in O(1) time.
 *
 *			(This "tag_of_queue_entry" will initially be set to NULL, as the mapping is 
 *			 added to the Active List's Mapping table.  But, once the data entry is 
 *			 added to the queue after the "Write Back" stage, "tag_of_queue_entry" will be
 *			 set to its correct value.)
 *
 */
interface active_List_Mapping_Table_ifc ();
	mips_core_pkg::MipsReg physical [32];			//Physical Register Address
	mips_core_pkg::MipsReg logical [32];			//Logical Register Address
	logic [`DATA_WIDTH - 1 : 0] mem_addr[32];		//Address in Main Memory					(There is a very good chance we don't need this in the 
													//											 Active List's Mapping Table, but I'm not smart enough 
													//											 to figure that out yet...)
	
	logic reg_or_mem[32];							//Flag to signal if data should commit to the
													//Register File, or to Main Memory.
													//
													//(1 for Register File, 0 for Main Memory).
													//											(Again, there is a very good chance we many not need this
													//											 in the Active List's Mapping Table, but I'm not smart enough
													//											 to figure that out just yet...)
													
	logic done [32];								//Flag to signal if the data corresponding to this 
													//mapping is ready to commit.
													//
													//(1 for "Ready to Commit", 0 for "Not Ready.")
													
	logic [4 : 0] head;								//Index used as a "head" pointer.
	logic [4 : 0] tail;								//Index used as a "tail" pointer.
	
	logic [$clog2(`ACTIVE_LIST_QUEUE_WIDTH) - 1 : 0] tag_of_queue_entry [32];	//The Active List Queue index (which acts as a tag)
																				//that corresponds to the data of the mapping entry.
endinterface



/* This is the interface for the Active List's Data Queue.
 * 
 * When instructions have finished their "Write Back" stage, the result data
 * should be sent to the Active List, where it is first put into the Active List's 
 * Data Queue!
 *
 * The reason the data queue exists is because instructions must be committed IN-ORDER,
 * even though they are executed OUT-OF-ORDER. So, the queue holds all result data until
 * the instruction is FULLY COMMITTED!
 *
 * Each entry in the Active List's Data Queue consists of:
 *		The result data from some instruction,
 *		The physical address of the register that should be
 *			written into, if the corresponding instruction is 
 *			committed to the Register File.
 *		The Main Memory address that should be written into, 
 *			if the corresponding instruction is committed into 
 *			Main Memory.
 *		A bit flag to signal whether or not the instruction corresponding 
 *			to this entry will write to the register file, or to main memory,
 *		An index, which is used as a tag to locate the corresponding 
 *      	mapping entry of the result data in the Active List's 
 *			Mapping Table.
 *		And a bit flag, to determine whether or not the entry in the 
 *			Active List's Data Queue is valid, or can be safely overwritten.
 *			(Used for priority encoding of Data Queue slots).
 *
 * Furthermore, since the Active List's Data Queue itself will receive data from
 * the "Write Back" stage, it will also need the following values to act as inputs 
 * to the queue itself:
 *		An input to add result data into the Data Queue.
 *		An input to add the physical address of the register that should be written
 *			into, if the corresponding instruction is committed to the Register File.
 *		An input to add the Main Memory address that should be written into, if the 
 *			corresponding instrution is committed into Main Memory.
 *		An input to add a bit flag that will signal whether or not the instruction 
 *			corresponding to this entry will write to the register file, or to main memory,
 *		And an input to add the index that is used as a flag to located the corresponding
 *			mapping entry of the result data in the Active List's Mapping Table.
 */
interface active_List_Data_Queue_ifc ();
	//Storage of the Active List's Data Queue
	logic [`DATA_WIDTH - 1 : 0] result_data[`ACTIVE_LIST_QUEUE_WIDTH];				//The result data of some instruction.
	
	logic [5 : 0] result_physical_addr_reg[`ACTIVE_LIST_QUEUE_WIDTH];				//The physical address of the destination register 
																					//of some instruction's result data.
	logic [`DATA_WIDTH - 1 : 0] result_mem_addr[`ACTIVE_LIST_QUEUE_WIDTH];			//The Main Memory address of the destination of 
																					//some instruction's result data.
																					
	logic reg_or_mem[32];															//Flag to signal if data should commit to the
																					//Register File, or to Main Memory.
																					//
																					//(1 for Register File, 0 for Main Memory).																				
																					
	logic [4 : 0] active_list_tag[`ACTIVE_LIST_QUEUE_WIDTH];						//The index/tag used to find the corresponding mapping
																					//entry of the result data in the Active List's Mapping Table	
																					//in O(1) time.
																					
	logic queue_valid[`ACTIVE_LIST_QUEUE_WIDTH];									//A bit flag used to signal whether or not an entry in the Active
																					//List's Data Queue is valid, or can be overwritten 
																					//
																					//(1 for valid, 0 for not valid).
	
	//Input ports to the Active List's Data Queue.
	logic [`DATA_WIDTH - 1 : 0] new_result_data;									//The result data of some NEWLY INPUTTED instruction into 
																					//the Active List's Data Queue.
																					
	logic [`DATA_WIDTH - 1 : 0] new_result_mem_addr;								//The Main Memory address of the destination of a NEWLY INPUTTED
																					//instruction's result data.
																					
	logic [5 : 0] new_result_physical_addr_reg;										//The physical address of the destination of a NEWLY INPUTTED 
																					//instruction's result data.
																					
	logic new_reg_or_mem;															//Flag to signal if the NEWLY INPUTTED data should commit to the
																					//Register File, or to Main Memory.
																					//
																					//(1 for Register File, 0 for Main Memory).																					
																					
	logic [4 : 0] new_active_list_tag;												//The index/tag of NEWLY INPUTTED result data that is used to find
																					//the corresponding mapping entry of the result data in the Active
																					//List's Mapping Table in O(1) time.
endinterface




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
endinterface





module active_List(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	
	input advance_head,				//Signal sent by either RegFile or Memory whenever they are done writing data.
	input add_mapping,				//Signal sent by Register Mapping Table whenever they output data to the Active List.

	hazard_control_ifc.in i_hc,		//Hazard Controls containing the flush and stall signals.

	register_Map_Table_Pairing_ifc.in i_map_pairing,		 			//Input map pairing to be added to the Active List's Mapping Table.
	register_Map_Table_Pairing_ifc.out flush_map_pairing,				//Output map pairing that is sent to the Register Map Table when a flush occurs.
	
	active_List_Commit_ifc.out active_Commit							//Output data that is sent to the Register File and/or Main Memory, in order to
																		//actually commit the data!
);

	active_List_Mapping_Table act_List();
	active_List_Queue_ifc act_Queue();
	
	logic [$clog2(`ACTIVE_LIST_QUEUE_WIDTH)-1:0] next_queue_slot_index;
	priority_encoder #(.NUM_OF_INPUTS(`ACTIVE_LIST_QUEUE_WIDTH), .HIGH_PRIORITY(0), .SIGNAL(1)) 
		queue_encoder( .data_inputs(queue_valid), .encoding_output(next_queue_slot_index) );
	
	logic flush_in_progress;
	
	initial begin
		act_List.head = 5'b0;
		act_List.tail = 5'b0;
		act_List.done = 0;
		
		flush_in_progress = 1'b0;
		
		flush_map_pairing.prev_physical_reg <= mips_core_pkg::MipsReg'(0);
		flush_map_pairing.prev_logical_reg  <= mips_core_pkg::MipsReg'(0);
		
		active_Commit.reg_addr      <= mips_core_pkg::MipsReg'(0);
		active_Commit.memory_addr   <= 0;
		active_Commit.result_data   <= 0;
		active_Commit.Reg_WR_EN  	<= 1'b0;
		active_Commit.Mem_WR_EN 	<= 1'b0;
	end

	//Active List Data Queue Logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			for (int i = 0; i < `ACTIVE_LIST_QUEUE_WIDTH; i++) begin 
				act_Queue.result_data[i] 	  	 	  	 <= 0;
				act_Queue.result_physical_addr_reg[i] 	 <= 0;
				act_Queue.result_mem_addr[i]			 <= 0;
				act_Queue.act_List_tag[i]      	 	 	 <= 0;		
				act_Queue.queue_valid[i] 		 	 	 <= 1;
			end
		end
		
		//When the Active List Data Queue gets a signal from either the Register File or 
		//Main Memory, which signals that the result data has been written, change the valid bit
		//of the entry associated with that result data from 0 to 1.
		//
		//That entry can be found using the "tag_of_queue_entry" from the "head" of the Active List's 
		//Mapping Table.
		else if (advance_head) act_Queue.queue_valid[ act_List.tag_of_queue_entry[act_List.head] ] <= 1'b1;
		
		//Otherwise, if a flush is not happening, add incoming data from the "Write Back" stage into the Active List's Data Queue.
		else if (~(i_hc.flush | flush_in_progress))begin
			act_Queue.result_data[next_queue_slot_index] 		   	   <= act_Queue.new_result_data;
			act_Queue.result_physical_addr_reg[next_queue_slot_index]  <= act_Queue.new_result_physical_addr_reg;
			act_Queue.result_mem_addr[next_queue_slot_index]           <= act_Queue.new_result_mem_addr;
			act_Queue.act_List_tag[next_queue_slot_index] 	   	       <= act_Queue.new_act_List_tag;
			act_Queue.queue_valid[next_queue_slot_index] 		   	   <= 1'b0;

			//Find the entry in the Active List's Mapping Table that is associated with the result data
			//that is being entered into the Active List's Data Queue.  Set that entry's "tag_of_queue_entry" 
			//equal to "next_queue_slot_index."  This is the index of where the new entry is being added into the queue!
			act_List.tag_of_queue_entry[ act_Queue.new_act_List_tag ]  <= next_queue_slot_index;
		end
	end


	//Active List Mapping Table and Active List Committing Logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			act_List.head 	    <= 5'b0;
			act_List.tail	    <= 5'b0;
			act_List.done 	    <= 0;
			act_List.reg_or_mem <= 1;			
			act_List.physical   <= mips_core_pkg::MipsReg'(0);
			act_List.logical    <= mips_core_pkg::MipsReg'(0);

			flush_map_pairing.prev_physical_reg <= mips_core_pkg::MipsReg'(0);
			flush_map_pairing.prev_logical_reg  <= mips_core_pkg::MipsReg'(0);
			
			active_Commit.reg_addr      <= mips_core_pkg::MipsReg'(0);
			active_Commit.memory_addr   <= 0;
			active_Commit.result_data   <= 0;
			active_Commit.Reg_WR_EN  	<= 1'b0;
			active_Commit.Mem_WR_EN 	<= 1'b0;
		end
		
		//If a flush signal has been recieved, "lock down" the Active List.
		//This is done by setting "flush_in_progress" to 1.
		if (i_hc.flush) flush_in_progress <= 1'b1;
		
		//While a flush is occurring, send back map pairings to the Register Map Table,
		//so it can reset its mapping, and de-increment the "tail" index for the 
		//Active List's Mapping Table.
		//
		//All valid mappings will have been sent when "head" == "tail".  When that 
		//happens, release the "lock down" by setting "flush_in_progress" to 0.
		if (flush_in_progress) begin					
			if (act_List.head == act_List.tail) flush_in_progress <= 1'b0;
			
			flush_map_pairing.prev_physical_reg <= act_List.physical[ act_List.tail ];
			flush_map_pairing.prev_logical_reg  <= act_List.logical[ act_List.tail ];
			
			act_List.tail <= (act_List.tail == 0) ? act_List.tail <= 5'b11111 : act_List.tail <= act_List.tail - 1;
		end
		
		//If a flush is not in progress...
		else begin
			//If the Active List's Mapping Table gets a signal from the Register Mapping table to add a new 
			//mapping, add it into the slot pointed to by the "tail" index, and then increment the 
			//"tail" index.
			//
			//(We should add an output signal to the Register Map Table that is sent to the Active List
			// for this purpose!)
			if (add_mapping) begin
				act_List.physical[act_List.tail]   <= i_map_pairing.prev_physical_reg;
				act_List.logical[act_List.tail]    <= i_map_pairing.prev_logical_reg;
				act_List.done[act_List.tail]	   <= 1'b0;
				
				act_List.tail 					   <= (act_List.tail + 1) % 32;
			end
			
			//If the mapping entry pointed to by the "head" index has its done bit set to 1, send the 
			//relevant data to be committed either by the Register File or Main Memory.  This is done 
			//by filling out the "active_Commit" interface, which will then be sent to both Register File and
			//Main Memory.  
			if (act_List.done[act_List.head]) begin
				active_Commit.reg_addr		<= act_List.physical[act_List.head];
				active_Commit.memory_addr   <= act_List.mem_addr[act_List.head];
				active_Commit.result_data   <= act_Queue.result_data[ act_List.tag_of_queue_entry[act_List.head] ];
				active_Commit.Reg_WR_EN		<= act_Queue.reg_or_mem[ act_List.tag_of_queue_entry[act_List.head] ];
				active_Commit.Mem_WR_EN		<= ~act_Queue.reg_or_mem[ act_List.tag_of_queue_entry[act_List.head] ];
			end
			
			//If the Register File or Main Memory sends a signal to the Active List's Mapping Table that the result 
			//data has be written, advance the "head" pointer by 1.
			if (advance_head) act_List.head <= (act_List.head + 1) % 32;		
		end
	end
endmodule
