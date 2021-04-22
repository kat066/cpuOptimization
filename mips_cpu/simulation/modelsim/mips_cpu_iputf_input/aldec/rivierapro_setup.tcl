

vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_avalon_st_adapter_error_adapter_0.sv" -work error_adapter_0                      
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_avalon_st_adapter.v"                  -work avalon_st_adapter                    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_width_adapter.sv"                               -work sdram_controller_s1_rsp_width_adapter
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_address_alignment.sv"                           -work sdram_controller_s1_rsp_width_adapter
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_burst_uncompressor.sv"                          -work sdram_controller_s1_rsp_width_adapter
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_rsp_mux.sv"                           -work rsp_mux                              
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_arbitrator.sv"                                  -work rsp_mux                              
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_rsp_demux.sv"                         -work rsp_demux                            
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_cmd_mux.sv"                           -work cmd_mux                              
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_arbitrator.sv"                                  -work cmd_mux                              
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_cmd_demux.sv"                         -work cmd_demux                            
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_burst_adapter.sv"                               -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_burst_adapter_uncmpr.sv"                        -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_burst_adapter_13_1.sv"                          -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_burst_adapter_new.sv"                           -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_incr_burst_converter.sv"                               -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_wrap_burst_converter.sv"                               -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_default_burst_converter.sv"                            -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_address_alignment.sv"                           -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_avalon_st_pipeline_stage.sv"                           -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_avalon_st_pipeline_base.v"                             -work sdram_controller_s1_burst_adapter    
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_router_003.sv"                        -work router_003                           
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0_router.sv"                            -work router                               
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_avalon_sc_fifo.v"                                      -work sdram_controller_s1_agent_rsp_fifo   
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_slave_agent.sv"                                 -work sdram_controller_s1_agent            
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_burst_uncompressor.sv"                          -work sdram_controller_s1_agent            
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_master_agent.sv"                                -work d_cache_read_avalon_master_agent     
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_slave_translator.sv"                            -work sdram_controller_s1_translator       
vlog       "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_merlin_master_translator.sv"                           -work d_cache_read_avalon_master_translator
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_reset_controller.v"                                    -work rst_controller                       
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/altera_reset_synchronizer.v"                                  -work rst_controller                       
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_mm_interconnect_0.v"                                    -work mm_interconnect_0                    
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_sdram_controller.v"                                     -work sdram_controller                     
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_sdram_controller_test_component.v"                      -work sdram_controller                     
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/sdram_pll_0.vo"                                               -work pll_0                                
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/custom_master.v"                                              -work d_cache_read                         
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/burst_write_master.v"                                         -work d_cache_read                         
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/burst_read_master.v"                                          -work d_cache_read                         
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/write_master.v"                                               -work d_cache_read                         
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/submodules/latency_aware_read_master.v"                                  -work d_cache_read                         
vlog -v2k5 "C:/Users/blade/Desktop/Baseline_v2.3/mips_cpu/sdram/simulation/sdram.v"                                                                                                            
