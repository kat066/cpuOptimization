
module sdram (
	clk_clk,
	d_cache_read_control_fixed_location,
	d_cache_read_control_read_base,
	d_cache_read_control_read_length,
	d_cache_read_control_go,
	d_cache_read_control_done,
	d_cache_read_control_early_done,
	d_cache_read_user_read_buffer,
	d_cache_read_user_buffer_output_data,
	d_cache_read_user_data_available,
	d_cache_write_control_fixed_location,
	d_cache_write_control_write_base,
	d_cache_write_control_write_length,
	d_cache_write_control_go,
	d_cache_write_control_done,
	d_cache_write_user_write_buffer,
	d_cache_write_user_buffer_input_data,
	d_cache_write_user_buffer_full,
	i_cache_read_control_fixed_location,
	i_cache_read_control_read_base,
	i_cache_read_control_read_length,
	i_cache_read_control_go,
	i_cache_read_control_done,
	i_cache_read_control_early_done,
	i_cache_read_user_read_buffer,
	i_cache_read_user_buffer_output_data,
	i_cache_read_user_data_available,
	mips_core_clk_clk,
	mips_core_rst_reset_n,
	pll_0_locked_export,
	reset_reset_n,
	sdram_clk_clk,
	sdram_controller_wire_addr,
	sdram_controller_wire_ba,
	sdram_controller_wire_cas_n,
	sdram_controller_wire_cke,
	sdram_controller_wire_cs_n,
	sdram_controller_wire_dq,
	sdram_controller_wire_dqm,
	sdram_controller_wire_ras_n,
	sdram_controller_wire_we_n);	

	input		clk_clk;
	input		d_cache_read_control_fixed_location;
	input	[25:0]	d_cache_read_control_read_base;
	input	[25:0]	d_cache_read_control_read_length;
	input		d_cache_read_control_go;
	output		d_cache_read_control_done;
	output		d_cache_read_control_early_done;
	input		d_cache_read_user_read_buffer;
	output	[31:0]	d_cache_read_user_buffer_output_data;
	output		d_cache_read_user_data_available;
	input		d_cache_write_control_fixed_location;
	input	[25:0]	d_cache_write_control_write_base;
	input	[25:0]	d_cache_write_control_write_length;
	input		d_cache_write_control_go;
	output		d_cache_write_control_done;
	input		d_cache_write_user_write_buffer;
	input	[31:0]	d_cache_write_user_buffer_input_data;
	output		d_cache_write_user_buffer_full;
	input		i_cache_read_control_fixed_location;
	input	[25:0]	i_cache_read_control_read_base;
	input	[25:0]	i_cache_read_control_read_length;
	input		i_cache_read_control_go;
	output		i_cache_read_control_done;
	output		i_cache_read_control_early_done;
	input		i_cache_read_user_read_buffer;
	output	[31:0]	i_cache_read_user_buffer_output_data;
	output		i_cache_read_user_data_available;
	output		mips_core_clk_clk;
	output		mips_core_rst_reset_n;
	output		pll_0_locked_export;
	input		reset_reset_n;
	output		sdram_clk_clk;
	output	[12:0]	sdram_controller_wire_addr;
	output	[1:0]	sdram_controller_wire_ba;
	output		sdram_controller_wire_cas_n;
	output		sdram_controller_wire_cke;
	output		sdram_controller_wire_cs_n;
	inout	[15:0]	sdram_controller_wire_dq;
	output	[1:0]	sdram_controller_wire_dqm;
	output		sdram_controller_wire_ras_n;
	output		sdram_controller_wire_we_n;
endmodule
