
`include "mips_core.svh"
`define ACTIVE_LIST_QUEUE_WIDTH 8

interface active_List_ifc ();
	mips_core_pkg::MipsReg physical [32];
	mips_core_pkg::MipsReg logical [32];
	logic [`DATA_WIDTH - 1 : 0] mem_addr[32];
	logic reg_or_mem[32];						//Set to 1 for reg or 0 for mem.
	logic done [32];
	logic [4 : 0] head;
	logic [4 : 0] tail;
	
	logic [$clog2(`ACTIVE_LIST_QUEUE_WIDTH) - 1 : 0] index_in_queue [32];
endinterface

interface active_List_Queue_ifc ();
	logic [`DATA_WIDTH - 1 : 0] result_data[`ACTIVE_LIST_QUEUE_WIDTH];
	logic [`DATA_WIDTH - 1 : 0] result_mem_addr[`ACTIVE_LIST_QUEUE_WIDTH];
	logic [5 : 0] result_physical_addr_reg[`ACTIVE_LIST_QUEUE_WIDTH];
	logic [4 : 0] active_list_tag[`ACTIVE_LIST_QUEUE_WIDTH];
	logic queue_valid[`ACTIVE_LIST_QUEUE_WIDTH];
	
	logic [`DATA_WIDTH - 1 : 0] new_result_data;
	logic [`DATA_WIDTH - 1 : 0] new_result_mem_addr;
	logic [5 : 0] new_result_physical_addr_reg;
	logic [4 : 0] new_active_list_tag;
endinterface

interface active_List_Commit_ifc ();
	mips_core_pkg::MipsReg reg_addr;
	logic [31 : 0] memory_addr;
	logic RegFile_WR_EN;
	logic Memory_WR_EN;
	
	modport out (output reg_addr, memory_addr, RegFile_WR_EN, Memory_WR_EN);
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
	active_List_ifc active_List();
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
			//Then, set "active_Queue.queue_valid[index_in_queue] <= 1'b1."
		end
		else begin
			active_Queue.result_data[queue_encoder_index] 		   	   <= active_Queue.new_result_data;
			active_Queue.result_physical_addr_reg[queue_encoder_index] <= active_Queue.new_result_physical_addr_reg;
			active_Queue.result_mem_addr[queue_encoder_index]          <= active_Queue.new_result_mem_addr;
			active_Queue.active_list_tag[queue_encoder_index] 	   	   <= active_Queue.new_active_list_tag;
			active_Queue.queue_valid[queue_encoder_index] 		   	   <= 1'b0;
			
			//Search Active List and find the entry with the tag, "active_Queue.new_active_list_tag."
			//Set that entry's "index_in_queue" to "queue_encoder_index."
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
			active_Commit.RegFile_WR_EN <= 1'b0;
			active_Commit.Memory_WR_EN  <= 1'b0;
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
