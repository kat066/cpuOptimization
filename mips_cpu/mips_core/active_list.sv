
`include "mips_core.svh"

interface active_List_ifc ();
	logic [4 : 0] instruction_Queue [32];
	logic [4 : 0] logical [32];
	mips_core_pkg::MipsReg physical [32];
	logic done [32];
	logic [4 : 0]head;
	logic [4 : 0]tail;
endinterface


module active_List(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	hazard_control_ifc.in i_hc,

	issue_ifc.in  i_wb,
	issue_ifc.out o_wb
);
	active_List_ifc active_List();
	
	initial begin
		active_List.head = 5'b0;
		active_List.tail = 5'b0;
		for(int i = 0; i < 32; i++) begin
			active_List.done[i] = 0;
		end
	end
	
	//When does o_wb.issue ever become 1'b1?
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			begin
				o_wb.issue <= 1'b0;
				o_wb.physical_addr <= zero;
				o_wb.logical_address <= 5'b0;
			end
		else
		begin
			if (!i_hc.stall)
			begin
				if (i_hc.flush)
				begin
					o_wb.issue <= 1'b0;
				end
				else
				begin
					o_wb.issue <= 1'b0;
					o_wb.physical_addr <= zero;
					o_wb.logical_address <= 5'b0;
				end
			end
		end
	end

endmodule
