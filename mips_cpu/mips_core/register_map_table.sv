`include "mips_core.svh"

interface register_Map_Table_ifc ();
	mips_core_pkg::MipsReg MapTable [32];
endinterface

interface register_Map_Table_Pairing_ifc();  	//Data to send to the Active List.
	mips_core_pkg::MipsReg prev_physical_reg;
	mips_core_pkg::MipsReg prev_logical_reg;	//The previous logical register won't change with new mappings!
	
	modport in ( input prev_physical_reg, prev_logical_reg );
	modport out( output prev_physical_reg, prev_logical_reg );
endinterface


module register_Map_Table(
	input rst_n,
	decoder_output_ifc.in decoded,
	active_List_Commit_ifc.in active_Commit,
	decoder_output_ifc.out out,
	output logic free_list_out[64],
	register_Map_Table_Pairing_ifc.out previous_register_mapping
	
);
register_Map_Table_ifc register_Map_Table();

logic free_list[64];
logic free_mapping_list[64];
logic [5:0] free_list_index;

priority_encoder_64 #(.HIGH_PRIORITY(0), .SIGNAL(1)) 
	encoder( .data_inputs1(free_list), .data_inputs2(free_mapping_list), .encoding_output(free_list_index) );

//initial begin
//	for(int i=0; i<32; i++)begin
//		register_Map_Table.MapTable[i]= mips_core_pkg::MipsReg'(i);
//		free_list[i] = 1;  // Binary array (used to keep track of available physical registers.)
//						   // 1 = free, 0 = not free.
//	end
//
//end


//Instruction Register Use Bits
assign out.uses_rs = decoded.uses_rs;
assign out.uses_rt = decoded.uses_rt;
assign out.uses_rw = decoded.uses_rw;

always_comb begin
	if(~rst_n) begin
		for(int i=0; i<32; i++)begin
			register_Map_Table.MapTable[i]= mips_core_pkg::MipsReg'(i);
			free_list[i] = 1;
			free_mapping_list [i]= 0;
		end
		for(int i=32; i<64; i++)begin
			free_list[i] = 1;  // Binary array (used to keep track of available physical registers.)
						   // 1 = free, 0 = not free.
			free_mapping_list[i] = 1;
		end
	end
	if(active_Commit.Reg_WR_EN)begin
		free_list[active_Commit.reg_addr] = 1;
	end
	out.rs_addr=decoded.uses_rs ? register_Map_Table.MapTable[decoded.rs_addr] : mips_core_pkg::MipsReg'(0);
	out.rt_addr=decoded.uses_rt ? register_Map_Table.MapTable[decoded.rt_addr] : mips_core_pkg::MipsReg'(0);  //Register addresses are physical addresses.
	
	//Active List Output
	previous_register_mapping.prev_physical_reg = register_Map_Table.MapTable[decoded.rw_addr];
	previous_register_mapping.prev_logical_reg  = decoded.rw_addr;
	
	//Register Renaming (you should only rename the destination register).
	
	if (decoded.uses_rw == 0) begin
		out.rw_addr = mips_core_pkg::MipsReg'(0);
	end
	else begin
		free_mapping_list[decoded.rw_addr] = 1'b1;
		register_Map_Table.MapTable[decoded.rw_addr]=mips_core_pkg::MipsReg'(free_list_index);
		out.rw_addr = mips_core_pkg::MipsReg'(free_list_index);
		free_list[free_list_index] = 1'b0;
		free_mapping_list[free_list_index] = 1'b0;
	end

	free_list_out = free_list;
end

endmodule

