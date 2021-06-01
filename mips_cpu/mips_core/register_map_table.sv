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
	
	decoder_output_ifc.in decoded,
	decoder_output_ifc.out out,
	register_Map_Table_Pairing_ifc.out active_list_data,
	output free_list_out[64]
	
);
register_Map_Table_ifc register_Map_Table();

logic free_list[64];



initial begin
	for(int i=0; i<32; i++)begin
		register_Map_Table.MapTable[i]= mips_core_pkg::MipsReg'(i);
		free_list[i] = 1;  // Binary array (used to keep track of available physical registers.)
						   // 1 = free, 0 = not free.
	end

end


//Instruction Register Use Bits
assign out.uses_rs = decoded.uses_rs;
assign out.uses_rt = decoded.uses_rt;
assign out.uses_rw = decoded.uses_rw;

always_comb begin
	out.rs_addr=decoded.uses_rs ? register_Map_Table.MapTable[decoded.rs_addr] : mips_core_pkg::MipsReg'(0);
	out.rt_addr=decoded.uses_rt ? register_Map_Table.MapTable[decoded.rt_addr] : mips_core_pkg::MipsReg'(0);  //Register addresses are physical addresses.
	
	//Active List Output
	active_list_data.prev_physical_reg = register_Map_Table.MapTable[decoded.rw_addr];
	active_list_data.prev_logical_reg  = decoded.rw_addr;
	
	//Register Renaming (you should only rename the destination register).	
	if (decoded.uses_rw == 0) begin
		out.rw_addr = mips_core_pkg::MipsReg'(0);
	end
	else begin
		if(free_list[register_Map_Table.MapTable[decoded.rw_addr]]==0) begin  //If the physical register that maps to the logical register "decoded.rw_addr" is NOT free!
			for(int i=0;i<64;i++)begin
				if(free_list[i]==1) begin
					free_list[i]=0;
					out.rw_addr = mips_core_pkg::MipsReg'(i);
					register_Map_Table.MapTable[decoded.rw_addr]=out.rw_addr;
					break;
				end
			end
			out.rw_addr = register_Map_Table.MapTable[decoded.rw_addr];
		end
		else begin
			out.rw_addr = register_Map_Table.MapTable[decoded.rw_addr];
			free_list[register_Map_Table.MapTable[decoded.rw_addr]] = 0;
		end
	end

	free_list_out = free_list;
end

endmodule

