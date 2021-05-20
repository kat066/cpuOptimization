`include "mips_core.svh"

interface register_Map_Table_ifc ();
	mips_core_pkg::MipsReg MapTable [32];
endinterface


module register_Map_Table(
	
	decoder_output_ifc.in decoded,
	decoder_output_ifc.out out,
	output free_list_out[64]
	
);
register_Map_Table_ifc register_Map_Table();
logic free_list[64];

initial begin
	for(int i=0; i<32; i++)begin
		register_Map_Table.MapTable[i]= mips_core_pkg::MipsReg'(i);
		free_list[i] = 1;
	end

end

always_comb begin
	out.uses_rs=decoded.uses_rs;
	out.rs_addr=decoded.uses_rs ? register_Map_Table.MapTable[decoded.rs_addr] : mips_core_pkg::MipsReg'(0);
	out.uses_rt=decoded.uses_rt;
	out.rt_addr=decoded.uses_rt ? register_Map_Table.MapTable[decoded.rt_addr] : mips_core_pkg::MipsReg'(0);
	//missing renaming logic
	out.uses_rw=decoded.uses_rw;
	if(free_list[register_Map_Table.MapTable[decoded.rw_addr]]==0) begin
		for(int i=0;i<64;i++)begin
			if(free_list[i]==1 & decoded.uses_rw) begin
				free_list[i]=0;
				out.rw_addr = mips_core_pkg::MipsReg'(i);
				register_Map_Table.MapTable[decoded.rw_addr]=out.rw_addr;
				break;
			end
		end
	end
	out.rw_addr=decoded.uses_rw ? register_Map_Table.MapTable[decoded.rw_addr] : mips_core_pkg::MipsReg'(0);
	free_list_out=free_list;
end


endmodule

