
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
 *		And a bit flag that is used to signal whether or not the data will be written 
 *			into the Register File or Main Memory.
 */
interface active_List_Commit_ifc ();
	mips_core_pkg::MipsReg reg_addr;				//The physical register address of where the result data 
													//that's being committed should go.
													
	logic [31 : 0] memory_addr;						//The Main Memory address of where the result data that'safely
													//being committed should go.
													
	logic Reg_Mem_Flag;								//A bit flag to signal whether or not the data be written in 
													//the Register File, or Main Memory.
													//
													//(1 for Register File, 0 for Main Memory).
	
	modport out (output reg_addr, memory_addr, Reg_Mem_Flag);
endinterface


module active_List(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input advance_head,				//Signal sent by either RegFile or Memory whenever they are done writing data.
	input add_mapping,				//Signal sent by Register Mapping Table whenever they output data to the Active List.

	hazard_control_ifc.in i_hc,

	register_Map_Table_Pairing_ifc.in i_wb,
	register_Map_Table_Pairing_ifc.out o_wb,
	register_Map_Table_Pairing_ifc.out flush_map_pairing,
	
	active_List_Commit_ifc.out active_Commit
);
	active_List_Mapping_Table active_List();
	active_List_Queue_ifc active_Queue();
	
	logic [$clog2(`ACTIVE_LIST_QUEUE_WIDTH)-1:0] queue_encoder_index;
	
	
	priority_encoder #(.NUM_OF_INPUTS(`ACTIVE_LIST_QUEUE_WIDTH), .HIGH_PRIORITY(0), .SIGNAL(1)) 
		queue_encoder( .data_inputs(queue_valid), .encoding_output(queue_encoder_index) );
	
	logic queue_post_commit_index; 			//Queue index for the entry of the registers that was just committed!
	logic flush_in_progress;
	
	initial begin
		active_List.head = 5'b0;
		active_List.tail = 5'b0;
		active_List.done = 0;
		
		flush_in_progress = 1'b0;
	end

	//Active List Queue Logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			for (int i = 0; i < `ACTIVE_LIST_QUEUE_WIDTH; i++) begin 
				active_Queue.result_data[i] 	  	 	 <= 0;
				active_Queue.result_physical_addr_reg[i] <= 0;
				active_Queue.result_mem_addr[i]			 <= 0;
				active_Queue.active_list_tag[i]      	 <= 0;		
				active_Queue.queue_valid[i] 		 	 <= 1;
			end
		end
		else if (advance_head) begin
			//Look at the Active List "head," and find its "index in queue."
			//Then, set "active_Queue.queue_valid[tag_of_queue_entry] <= 1'b1."
		end
		else begin
			active_Queue.result_data[queue_encoder_index] 		   	   <= active_Queue.new_result_data;
			active_Queue.result_physical_addr_reg[queue_encoder_index] <= active_Queue.new_result_physical_addr_reg;
			active_Queue.result_mem_addr[queue_encoder_index]          <= active_Queue.new_result_mem_addr;
			active_Queue.active_list_tag[queue_encoder_index] 	   	   <= active_Queue.new_active_list_tag;
			active_Queue.queue_valid[queue_encoder_index] 		   	   <= 1'b0;
			
			//Search Active List and find the entry with the tag, "active_Queue.new_active_list_tag."
			//Set that entry's "tag_of_queue_entry" to "queue_encoder_index."
		end
	end


	//Active List Logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			active_List.head 	   <= 5'b0;
			active_List.tail	   <= 5'b0;
			active_List.done 	   <= 0;
			active_List.reg_or_mem <= 1;			
			active_List.physical   <= mips_core_pkg::MipsReg'(0);
			active_List.logical    <= mips_core_pkg::MipsReg'(0);

			o_wb.prev_physical_reg <= mips_core_pkg::MipsReg'(0);
			o_wb.prev_logical_reg  <= mips_core_pkg::MipsReg'(0);
			
			active_Commit.reg_addr      <= mips_core_pkg::MipsReg'(0);
			active_Commit.memory_addr   <= 0;
			active_Commit.Reg_Mem_Flag  <= 1'b0;
		end
		if (i_hc.flush || flush_in_progress) begin
			flush_in_progress <= 1'b1;
			
			//"Lock down" Active List, and begin sending back map pairings to 
			//the map table, so it can reset its mapping.
			//
			//The Active List will be done when "head" == "tail".  When that happens,
			//release the "lock down."
		end
		else if (add_mapping) begin
			active_List.physical[active_List.tail] <= i_wb.prev_physical_reg;
			active_List.logical[active_List.tail]  <= i_wb.prev_logical_reg;
			active_List.done[active_List.tail]	   <= 1'b0;
			
			active_List.tail 					   <= (active_List.tail + 1) % 32;
		end
		if (active_List.done[active_List.head]) begin
			//Send data to Reg File or Memory to be written.  
		end
		if (advance_head) begin
			active_List.head = (active_List.head + 1) % 32;
		end
	end
endmodule
