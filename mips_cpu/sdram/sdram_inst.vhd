	component sdram is
		port (
			clk_clk                              : in    std_logic                     := 'X';             -- clk
			d_cache_read_control_fixed_location  : in    std_logic                     := 'X';             -- fixed_location
			d_cache_read_control_read_base       : in    std_logic_vector(25 downto 0) := (others => 'X'); -- read_base
			d_cache_read_control_read_length     : in    std_logic_vector(25 downto 0) := (others => 'X'); -- read_length
			d_cache_read_control_go              : in    std_logic                     := 'X';             -- go
			d_cache_read_control_done            : out   std_logic;                                        -- done
			d_cache_read_control_early_done      : out   std_logic;                                        -- early_done
			d_cache_read_user_read_buffer        : in    std_logic                     := 'X';             -- read_buffer
			d_cache_read_user_buffer_output_data : out   std_logic_vector(31 downto 0);                    -- buffer_output_data
			d_cache_read_user_data_available     : out   std_logic;                                        -- data_available
			d_cache_write_control_fixed_location : in    std_logic                     := 'X';             -- fixed_location
			d_cache_write_control_write_base     : in    std_logic_vector(25 downto 0) := (others => 'X'); -- write_base
			d_cache_write_control_write_length   : in    std_logic_vector(25 downto 0) := (others => 'X'); -- write_length
			d_cache_write_control_go             : in    std_logic                     := 'X';             -- go
			d_cache_write_control_done           : out   std_logic;                                        -- done
			d_cache_write_user_write_buffer      : in    std_logic                     := 'X';             -- write_buffer
			d_cache_write_user_buffer_input_data : in    std_logic_vector(31 downto 0) := (others => 'X'); -- buffer_input_data
			d_cache_write_user_buffer_full       : out   std_logic;                                        -- buffer_full
			i_cache_read_control_fixed_location  : in    std_logic                     := 'X';             -- fixed_location
			i_cache_read_control_read_base       : in    std_logic_vector(25 downto 0) := (others => 'X'); -- read_base
			i_cache_read_control_read_length     : in    std_logic_vector(25 downto 0) := (others => 'X'); -- read_length
			i_cache_read_control_go              : in    std_logic                     := 'X';             -- go
			i_cache_read_control_done            : out   std_logic;                                        -- done
			i_cache_read_control_early_done      : out   std_logic;                                        -- early_done
			i_cache_read_user_read_buffer        : in    std_logic                     := 'X';             -- read_buffer
			i_cache_read_user_buffer_output_data : out   std_logic_vector(31 downto 0);                    -- buffer_output_data
			i_cache_read_user_data_available     : out   std_logic;                                        -- data_available
			mips_core_clk_clk                    : out   std_logic;                                        -- clk
			mips_core_rst_reset_n                : out   std_logic;                                        -- reset_n
			pll_0_locked_export                  : out   std_logic;                                        -- export
			reset_reset_n                        : in    std_logic                     := 'X';             -- reset_n
			sdram_clk_clk                        : out   std_logic;                                        -- clk
			sdram_controller_wire_addr           : out   std_logic_vector(12 downto 0);                    -- addr
			sdram_controller_wire_ba             : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_controller_wire_cas_n          : out   std_logic;                                        -- cas_n
			sdram_controller_wire_cke            : out   std_logic;                                        -- cke
			sdram_controller_wire_cs_n           : out   std_logic;                                        -- cs_n
			sdram_controller_wire_dq             : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_controller_wire_dqm            : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_controller_wire_ras_n          : out   std_logic;                                        -- ras_n
			sdram_controller_wire_we_n           : out   std_logic                                         -- we_n
		);
	end component sdram;

	u0 : component sdram
		port map (
			clk_clk                              => CONNECTED_TO_clk_clk,                              --                   clk.clk
			d_cache_read_control_fixed_location  => CONNECTED_TO_d_cache_read_control_fixed_location,  --  d_cache_read_control.fixed_location
			d_cache_read_control_read_base       => CONNECTED_TO_d_cache_read_control_read_base,       --                      .read_base
			d_cache_read_control_read_length     => CONNECTED_TO_d_cache_read_control_read_length,     --                      .read_length
			d_cache_read_control_go              => CONNECTED_TO_d_cache_read_control_go,              --                      .go
			d_cache_read_control_done            => CONNECTED_TO_d_cache_read_control_done,            --                      .done
			d_cache_read_control_early_done      => CONNECTED_TO_d_cache_read_control_early_done,      --                      .early_done
			d_cache_read_user_read_buffer        => CONNECTED_TO_d_cache_read_user_read_buffer,        --     d_cache_read_user.read_buffer
			d_cache_read_user_buffer_output_data => CONNECTED_TO_d_cache_read_user_buffer_output_data, --                      .buffer_output_data
			d_cache_read_user_data_available     => CONNECTED_TO_d_cache_read_user_data_available,     --                      .data_available
			d_cache_write_control_fixed_location => CONNECTED_TO_d_cache_write_control_fixed_location, -- d_cache_write_control.fixed_location
			d_cache_write_control_write_base     => CONNECTED_TO_d_cache_write_control_write_base,     --                      .write_base
			d_cache_write_control_write_length   => CONNECTED_TO_d_cache_write_control_write_length,   --                      .write_length
			d_cache_write_control_go             => CONNECTED_TO_d_cache_write_control_go,             --                      .go
			d_cache_write_control_done           => CONNECTED_TO_d_cache_write_control_done,           --                      .done
			d_cache_write_user_write_buffer      => CONNECTED_TO_d_cache_write_user_write_buffer,      --    d_cache_write_user.write_buffer
			d_cache_write_user_buffer_input_data => CONNECTED_TO_d_cache_write_user_buffer_input_data, --                      .buffer_input_data
			d_cache_write_user_buffer_full       => CONNECTED_TO_d_cache_write_user_buffer_full,       --                      .buffer_full
			i_cache_read_control_fixed_location  => CONNECTED_TO_i_cache_read_control_fixed_location,  --  i_cache_read_control.fixed_location
			i_cache_read_control_read_base       => CONNECTED_TO_i_cache_read_control_read_base,       --                      .read_base
			i_cache_read_control_read_length     => CONNECTED_TO_i_cache_read_control_read_length,     --                      .read_length
			i_cache_read_control_go              => CONNECTED_TO_i_cache_read_control_go,              --                      .go
			i_cache_read_control_done            => CONNECTED_TO_i_cache_read_control_done,            --                      .done
			i_cache_read_control_early_done      => CONNECTED_TO_i_cache_read_control_early_done,      --                      .early_done
			i_cache_read_user_read_buffer        => CONNECTED_TO_i_cache_read_user_read_buffer,        --     i_cache_read_user.read_buffer
			i_cache_read_user_buffer_output_data => CONNECTED_TO_i_cache_read_user_buffer_output_data, --                      .buffer_output_data
			i_cache_read_user_data_available     => CONNECTED_TO_i_cache_read_user_data_available,     --                      .data_available
			mips_core_clk_clk                    => CONNECTED_TO_mips_core_clk_clk,                    --         mips_core_clk.clk
			mips_core_rst_reset_n                => CONNECTED_TO_mips_core_rst_reset_n,                --         mips_core_rst.reset_n
			pll_0_locked_export                  => CONNECTED_TO_pll_0_locked_export,                  --          pll_0_locked.export
			reset_reset_n                        => CONNECTED_TO_reset_reset_n,                        --                 reset.reset_n
			sdram_clk_clk                        => CONNECTED_TO_sdram_clk_clk,                        --             sdram_clk.clk
			sdram_controller_wire_addr           => CONNECTED_TO_sdram_controller_wire_addr,           -- sdram_controller_wire.addr
			sdram_controller_wire_ba             => CONNECTED_TO_sdram_controller_wire_ba,             --                      .ba
			sdram_controller_wire_cas_n          => CONNECTED_TO_sdram_controller_wire_cas_n,          --                      .cas_n
			sdram_controller_wire_cke            => CONNECTED_TO_sdram_controller_wire_cke,            --                      .cke
			sdram_controller_wire_cs_n           => CONNECTED_TO_sdram_controller_wire_cs_n,           --                      .cs_n
			sdram_controller_wire_dq             => CONNECTED_TO_sdram_controller_wire_dq,             --                      .dq
			sdram_controller_wire_dqm            => CONNECTED_TO_sdram_controller_wire_dqm,            --                      .dqm
			sdram_controller_wire_ras_n          => CONNECTED_TO_sdram_controller_wire_ras_n,          --                      .ras_n
			sdram_controller_wire_we_n           => CONNECTED_TO_sdram_controller_wire_we_n            --                      .we_n
		);

