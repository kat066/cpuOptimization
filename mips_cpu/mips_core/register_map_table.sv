`include "mips_core.svh"

interface register_Map_Table_ifc ();
	logic [5 : 0] MapTable [31 : 0];

endinterface


module register_Map_Table(
	decoder_output_ifc.in decoded
	input logic uses_rs;
	input mips_core_pkg::MipsReg rs_addr;

	input logic uses_rt;
	input mips_core_pkg::MipsReg rt_addr;
	decoder_output_ifc.out out
)
register_Map_Table_ifc register_Map_Table();

initial begin
	for(int i=0; i<32; i++){
		MapTable[i]=i;
	}
end
task get_physical;
	begin
		if(decoded.uses_rw == 1)
		begin
			out.rw_addr <= MapTable[in.rw_addr];
		end
		
	end
endtask
always_comb begin
	
	

end


endmodule

