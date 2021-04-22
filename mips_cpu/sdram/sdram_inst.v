	sdram u0 (
		.clk_clk                              (<connected-to-clk_clk>),                              //                   clk.clk
		.d_cache_read_control_fixed_location  (<connected-to-d_cache_read_control_fixed_location>),  //  d_cache_read_control.fixed_location
		.d_cache_read_control_read_base       (<connected-to-d_cache_read_control_read_base>),       //                      .read_base
		.d_cache_read_control_read_length     (<connected-to-d_cache_read_control_read_length>),     //                      .read_length
		.d_cache_read_control_go              (<connected-to-d_cache_read_control_go>),              //                      .go
		.d_cache_read_control_done            (<connected-to-d_cache_read_control_done>),            //                      .done
		.d_cache_read_control_early_done      (<connected-to-d_cache_read_control_early_done>),      //                      .early_done
		.d_cache_read_user_read_buffer        (<connected-to-d_cache_read_user_read_buffer>),        //     d_cache_read_user.read_buffer
		.d_cache_read_user_buffer_output_data (<connected-to-d_cache_read_user_buffer_output_data>), //                      .buffer_output_data
		.d_cache_read_user_data_available     (<connected-to-d_cache_read_user_data_available>),     //                      .data_available
		.d_cache_write_control_fixed_location (<connected-to-d_cache_write_control_fixed_location>), // d_cache_write_control.fixed_location
		.d_cache_write_control_write_base     (<connected-to-d_cache_write_control_write_base>),     //                      .write_base
		.d_cache_write_control_write_length   (<connected-to-d_cache_write_control_write_length>),   //                      .write_length
		.d_cache_write_control_go             (<connected-to-d_cache_write_control_go>),             //                      .go
		.d_cache_write_control_done           (<connected-to-d_cache_write_control_done>),           //                      .done
		.d_cache_write_user_write_buffer      (<connected-to-d_cache_write_user_write_buffer>),      //    d_cache_write_user.write_buffer
		.d_cache_write_user_buffer_input_data (<connected-to-d_cache_write_user_buffer_input_data>), //                      .buffer_input_data
		.d_cache_write_user_buffer_full       (<connected-to-d_cache_write_user_buffer_full>),       //                      .buffer_full
		.i_cache_read_control_fixed_location  (<connected-to-i_cache_read_control_fixed_location>),  //  i_cache_read_control.fixed_location
		.i_cache_read_control_read_base       (<connected-to-i_cache_read_control_read_base>),       //                      .read_base
		.i_cache_read_control_read_length     (<connected-to-i_cache_read_control_read_length>),     //                      .read_length
		.i_cache_read_control_go              (<connected-to-i_cache_read_control_go>),              //                      .go
		.i_cache_read_control_done            (<connected-to-i_cache_read_control_done>),            //                      .done
		.i_cache_read_control_early_done      (<connected-to-i_cache_read_control_early_done>),      //                      .early_done
		.i_cache_read_user_read_buffer        (<connected-to-i_cache_read_user_read_buffer>),        //     i_cache_read_user.read_buffer
		.i_cache_read_user_buffer_output_data (<connected-to-i_cache_read_user_buffer_output_data>), //                      .buffer_output_data
		.i_cache_read_user_data_available     (<connected-to-i_cache_read_user_data_available>),     //                      .data_available
		.mips_core_clk_clk                    (<connected-to-mips_core_clk_clk>),                    //         mips_core_clk.clk
		.mips_core_rst_reset_n                (<connected-to-mips_core_rst_reset_n>),                //         mips_core_rst.reset_n
		.pll_0_locked_export                  (<connected-to-pll_0_locked_export>),                  //          pll_0_locked.export
		.reset_reset_n                        (<connected-to-reset_reset_n>),                        //                 reset.reset_n
		.sdram_clk_clk                        (<connected-to-sdram_clk_clk>),                        //             sdram_clk.clk
		.sdram_controller_wire_addr           (<connected-to-sdram_controller_wire_addr>),           // sdram_controller_wire.addr
		.sdram_controller_wire_ba             (<connected-to-sdram_controller_wire_ba>),             //                      .ba
		.sdram_controller_wire_cas_n          (<connected-to-sdram_controller_wire_cas_n>),          //                      .cas_n
		.sdram_controller_wire_cke            (<connected-to-sdram_controller_wire_cke>),            //                      .cke
		.sdram_controller_wire_cs_n           (<connected-to-sdram_controller_wire_cs_n>),           //                      .cs_n
		.sdram_controller_wire_dq             (<connected-to-sdram_controller_wire_dq>),             //                      .dq
		.sdram_controller_wire_dqm            (<connected-to-sdram_controller_wire_dqm>),            //                      .dqm
		.sdram_controller_wire_ras_n          (<connected-to-sdram_controller_wire_ras_n>),          //                      .ras_n
		.sdram_controller_wire_we_n           (<connected-to-sdram_controller_wire_we_n>)            //                      .we_n
	);

