`include "mips_core.svh"

interface register_Map_Table_ifc ();
	mips_core_pkg::MipsReg MapTable [32];

endinterface


module register_Map_Table(
	decoder_output_ifc.in decoded,
	decoder_output_ifc.out out
);
register_Map_Table_ifc register_Map_Table();


initial begin
	for(int i=0; i<32; i++)begin
		register_Map_Table.MapTable[i]= mips_core_pkg::MipsReg'(i);
	end
end

always_comb begin
	out.uses_rs=decoded.uses_rs;
	out.rs_addr=decoded.uses_rs ? register_Map_Table.MapTable[decoded.rs_addr] : mips_core_pkg::MipsReg'(0);
	out.uses_rt=decoded.uses_rt;
	out.rt_addr=decoded.uses_rt ? register_Map_Table.MapTable[decoded.rt_addr] : mips_core_pkg::MipsReg'(0);
	//missing renaming logic
	out.uses_rw=decoded.uses_rw;
	out.rw_addr=decoded.uses_rw ? register_Map_Table.MapTable[decoded.rw_addr] : mips_core_pkg::MipsReg'(0);
end


endmodule

