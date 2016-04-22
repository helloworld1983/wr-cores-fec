
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.gn4124_core_pkg.all;
use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wr_fabric_pkg.all;
use work.wr_xilinx_pkg.all;
use work.etherbone_pkg.all;
use work.com5402pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.wishbone_pkg.all;


entity cute_udp is
  generic
    (
      TAR_ADDR_WDTH : integer := 13     -- not used for this project
      );
  port
    (
      clk_sys_i     : in std_logic;     -- 62.5M system clock, from PLL drived by clk_125m_pllref
      clk_dmtd_i    : in std_logic;     -- 62.5M DMTD clock, from PLL drived by clk_20m_vcxo
      clk_ref_i     : in std_logic;     -- 125M reference clock
      clk_gtp_i     : in std_logic;     -- Dedicated clock for Xilinx GTP transceiver
      
	  rst_n_i		: in std_logic;
	  
      -- From GN4124 Local bus, not used in cute
      --L_CLKp : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)
      --L_CLKn : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)

      --L_RST_N : in std_logic;           -- Reset from GN4124 (RSTOUT18_N)

      -- General Purpose Interface
      --GPIO : inout std_logic_vector(1 downto 0);  -- GPIO[0] -> GN4124 GPIO8
                                                  -- GPIO[1] -> GN4124 GPIO9

      -- PCIe to Local [Inbound Data] - RX
      --P2L_RDY    : out std_logic;       -- Rx Buffer Full Flag
      --P2L_CLKn   : in  std_logic;       -- Receiver Source Synchronous Clock-
      --P2L_CLKp   : in  std_logic;       -- Receiver Source Synchronous Clock+
      --P2L_DATA   : in  std_logic_vector(15 downto 0);  -- Parallel receive data
      --P2L_DFRAME : in  std_logic;       -- Receive Frame
      --P2L_VALID  : in  std_logic;       -- Receive Data Valid

      -- Inbound Buffer Request/Status
      --P_WR_REQ : in  std_logic_vector(1 downto 0);  -- PCIe Write Request
      --P_WR_RDY : out std_logic_vector(1 downto 0);  -- PCIe Write Ready
      --RX_ERROR : out std_logic;                     -- Receive Error

      -- Local to Parallel [Outbound Data] - TX
      --L2P_DATA   : out std_logic_vector(15 downto 0);  -- Parallel transmit data
      --L2P_DFRAME : out std_logic;       -- Transmit Data Frame
      --L2P_VALID  : out std_logic;       -- Transmit Data Valid
      --L2P_CLKn   : out std_logic;  -- Transmitter Source Synchronous Clock-
      --L2P_CLKp   : out std_logic;  -- Transmitter Source Synchronous Clock+
      --L2P_EDB    : out std_logic;       -- Packet termination and discard

      -- Outbound Buffer Status
      --L2P_RDY    : in std_logic;        -- Tx Buffer Full Flag
      --L_WR_RDY   : in std_logic_vector(1 downto 0);  -- Local-to-PCIe Write
      --P_RD_D_RDY : in std_logic_vector(1 downto 0);  -- PCIe-to-Local Read Response Data Ready
      --TX_ERROR   : in std_logic;        -- Transmit Error
      --VC_RDY     : in std_logic_vector(1 downto 0);  -- Channel ready

      -- Font panel LEDs
      LED_RED   : out std_logic;
      LED_GREEN : out std_logic;
      LED_TEST  : out std_logic;

      dac_sclk_o  : out std_logic;
      dac_din_o   : out std_logic;
      dac_clr_n_o : out std_logic;
      dac_ldac_n_o : out std_logic;
      dac_sync_n_o : out std_logic;

      fpga_scl_i : in  std_logic;
      fpga_scl_o : out std_logic;
      fpga_sda_i : in  std_logic;
      fpga_sda_o : out std_logic;

      --button1_i : in std_logic := 'H';
      --button2_i : in std_logic := 'H';
      
      --spi_sclk_o : out std_logic;
      --spi_ncs_o  : out std_logic;
      --spi_mosi_o : out std_logic;
      --spi_miso_i : in  std_logic := 'L';

      thermo_id_i : in  std_logic;
      thermo_id_o : out std_logic;      -- 1-Wire interface to DS18B20

      -------------------------------------------------------------------------
      -- SFP pins
      -------------------------------------------------------------------------

      sfp_txp_o : out std_logic;
      sfp_txn_o : out std_logic;

      sfp_rxp_i : in std_logic;
      sfp_rxn_i : in std_logic;

      sfp_mod_def0_b    : in    std_logic;  -- sfp detect
      sfp_mod_def1_i    : in std_logic;  -- scl
      sfp_mod_def1_o    : out std_logic;  -- scl
      sfp_mod_def2_i    : in std_logic;  -- sda
      sfp_mod_def2_o    : out std_logic;  -- sda
      sfp_rate_select_i : in std_logic;
      sfp_rate_select_o : out std_logic;
      sfp_tx_fault_i    : in    std_logic;
      sfp_tx_disable_o  : out   std_logic;
      sfp_los_i         : in    std_logic;


      -------------------------------------------------------------------------
      -- Digital I/O FMC Pins
      -------------------------------------------------------------------------

      --dio_clk_p_i : in std_logic;
      --dio_clk_n_i : in std_logic;

      --dio_n_i : in std_logic_vector(4 downto 0);
      --dio_p_i : in std_logic_vector(4 downto 0);

      --dio_n_o : out std_logic_vector(4 downto 0);
      --dio_p_o : out std_logic_vector(4 downto 0);

      --dio_oe_n_o    : out std_logic_vector(4 downto 0);
      --dio_term_en_o : out std_logic_vector(4 downto 0);

      --dio_onewire_b  : inout std_logic;
      --dio_sdn_n_o    : out   std_logic;
      --dio_sdn_ck_n_o : out   std_logic;

      --dio_led_top_o : out std_logic;
      --dio_led_bot_o : out std_logic;

      pps_o : out std_logic;
	    tm_utc_o: out std_logic_vector(39 downto 0);
	  
      -----------------------------------------
      --UART
      -----------------------------------------
      uart_rxd_i : in  std_logic;
      uart_txd_o : out std_logic;

      ----------------------------------------
      -- Ext tcp interface
      ---------------------------------------
      --tcp_rx_data:out std_logic_vector(7 downto 0);
      --tcp_rx_data_valid:out std_logic;
      --tcp_rx_rts:out std_logic;
      --tcp_tx_data:in std_logic_vector(7 downto 0);
      --tcp_tx_data_valid:in std_logic;
      --tcp_tx_cts:out std_logic
		  ---------------------------------------
      -- Ext udp interface
      ---------------------------------------
      UDP_RX_DATA: out std_logic_vector(7 downto 0);
      UDP_RX_DATA_VALID: out std_logic;
      UDP_RX_SOF: out std_logic;
      UDP_RX_EOF: out std_logic;


      UDP_TX_DATA: in std_logic_vector(7 downto 0);
      UDP_TX_DATA_VALID: in std_logic;
      UDP_TX_SOF: in std_logic;
      UDP_TX_EOF: in std_logic;
      UDP_TX_CTS: out std_logic;
      UDP_TX_ACK: out std_logic;
      UDP_TX_NAK: out std_logic
      );

end cute_udp;

architecture rtl of cute_udp is

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------
  component ext_pll_10_to_125m
    port (
      clk_ext_i     : in  std_logic;
      clk_ext_mul_o : out std_logic;
      rst_a_i       : in  std_logic;
      clk_in_stopped_o: out  std_logic;
      locked_o      : out std_logic);
  end component;

  --component chipscope_ila
  --  port (
  --    CONTROL : inout std_logic_vector(35 downto 0);
  --    CLK     : in    std_logic;
  --    TRIG0   : in    std_logic_vector(31 downto 0);
  --    TRIG1   : in    std_logic_vector(31 downto 0);
  --    TRIG2   : in    std_logic_vector(31 downto 0);
  --    TRIG3   : in    std_logic_vector(31 downto 0));
  --end component;

  --signal CONTROL : std_logic_vector(35 downto 0);
  --signal CLK     : std_logic;
  --signal TRIG0   : std_logic_vector(31 downto 0);
  --signal TRIG1   : std_logic_vector(31 downto 0);
  --signal TRIG2   : std_logic_vector(31 downto 0);
  --signal TRIG3   : std_logic_vector(31 downto 0);

  --component chipscope_icon
  --  port (
  --    CONTROL0 : inout std_logic_vector (35 downto 0));
  --end component;

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  --constant c_BAR0_APERTURE     : integer := 20;
  --constant c_CSR_WB_SLAVES_NB  : integer := 1;
  --constant c_DMA_WB_SLAVES_NB  : integer := 1;
  --constant c_DMA_WB_ADDR_WIDTH : integer := 26;

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------

  -- LCLK from GN4124 used as system clock
  --signal l_clk : std_logic;

  -- Dedicated clock for GTP transceiver
  signal gtp_dedicated_clk : std_logic;

  -- P2L colck PLL status
  --signal p2l_pll_locked : std_logic;

  -- Reset
  signal rst_a : std_logic;
  signal rst   : std_logic;

  --signal ram_we      : std_logic_vector(0 downto 0);
  --signal ddr_dma_adr : std_logic_vector(29 downto 0);

  --signal irq_to_gn4124 : std_logic;

  -- SPI
  signal spi_slave_select : std_logic_vector(7 downto 0);


  signal pllout_clk_sys       : std_logic;
  signal pllout_clk_dmtd      : std_logic;
  signal pllout_clk_fb_pllref : std_logic;
  signal pllout_clk_fb_dmtd   : std_logic;

  signal clk_20m_vcxo_buf : std_logic;
  signal clk_125m_pllref  : std_logic;
  signal clk_sys          : std_logic;
  signal clk_dmtd         : std_logic;
  signal dac_rst_n        : std_logic;
  signal led_divider      : unsigned(23 downto 0);

  signal wrc_scl_o : std_logic;
  signal wrc_scl_i : std_logic;
  signal wrc_sda_o : std_logic;
  signal wrc_sda_i : std_logic;
  signal sfp_scl_o : std_logic;
  signal sfp_scl_i : std_logic;
  signal sfp_sda_o : std_logic;
  signal sfp_sda_i : std_logic;
  --signal dio       : std_logic_vector(3 downto 0);

  signal dac_hpll_load_p1 : std_logic;
  signal dac_dpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(15 downto 0);
  signal dac_dpll_data    : std_logic_vector(15 downto 0);

  signal pps     : std_logic;
  signal pps_led : std_logic;

  signal phy_tx_data      : std_logic_vector(7 downto 0);
  signal phy_tx_k         : std_logic_vector(0 downto 0);
  signal phy_tx_disparity : std_logic;
  signal phy_tx_enc_err   : std_logic;
  signal phy_rx_data      : std_logic_vector(7 downto 0);
  signal phy_rx_rbclk     : std_logic;
  signal phy_rx_k         : std_logic_vector(0 downto 0);
  signal phy_rx_enc_err   : std_logic;
  signal phy_rx_bitslide  : std_logic_vector(3 downto 0);
  signal phy_rst          : std_logic;
  signal phy_loopen       : std_logic;
  signal phy_loopen_vec   : std_logic_vector(2 downto 0);
  signal phy_prbs_sel     : std_logic_vector(2 downto 0);
  signal phy_rdy          : std_logic;

  --signal dio_in  : std_logic_vector(4 downto 0);
  --signal dio_out : std_logic_vector(4 downto 0);
  --signal dio_clk : std_logic;

  signal local_reset_n  : std_logic;
  --signal button1_synced : std_logic_vector(2 downto 0);

  signal ext_wb_out    : t_wishbone_master_out;
  signal ext_wb_in     : t_wishbone_master_in;

  signal ext_src_out : t_wrf_source_out;
  signal ext_src_in  : t_wrf_source_in;
  signal ext_snk_out : t_wrf_sink_out;
  signal ext_snk_in  : t_wrf_sink_in;

  signal wrc_slave_i : t_wishbone_slave_in;
  signal wrc_slave_o : t_wishbone_slave_out;

  signal owr_en : std_logic_vector(1 downto 0);
  signal owr_i  : std_logic_vector(1 downto 0);

  signal wb_adr : std_logic_vector(31 downto 0);  --c_BAR0_APERTURE-priv_log2_ceil(c_CSR_WB_SLAVES_NB+1)-1 downto 0);

  signal etherbone_rst_n   : std_logic;
  signal etherbone_src_out : t_wrf_source_out;
  signal etherbone_src_in  : t_wrf_source_in;
  signal etherbone_snk_out : t_wrf_sink_out;
  signal etherbone_snk_in  : t_wrf_sink_in;
  signal etherbone_wb_out  : t_wishbone_master_out;
  signal etherbone_wb_in   : t_wishbone_master_in;
  signal etherbone_cfg_slave_in  : t_wishbone_slave_in;
  signal etherbone_cfg_slave_out : t_wishbone_slave_out;

  --signal ext_pll_reset : std_logic;
  --signal clk_ext, clk_ext_mul       : std_logic;
  --signal clk_ext_mul_locked         : std_logic;
  --signal clk_ext_stopped            : std_logic;
  --signal clk_ext_rst                : std_logic;
  --signal clk_ref_div2               : std_logic;
  
  component xwb_udp_core is
    port(
      clk_ref :     in  std_logic;
      clk_sys :     in  std_logic;
      rst_n_i :     in  std_logic;
      snk_i :   in  t_wrf_sink_in;
      snk_o :   out t_wrf_sink_out;
    UDP_RX_DATA: out std_logic_vector(7 downto 0);
    UDP_RX_DATA_VALID: out std_logic;
    UDP_RX_SOF: out std_logic;
    UDP_RX_EOF: out std_logic;
      src_o :   out t_wrf_source_out;
      src_i :   in  t_wrf_source_in;
    UDP_TX_DATA: in std_logic_vector(7 downto 0);
    UDP_TX_DATA_VALID: in std_logic;
    UDP_TX_SOF: in std_logic;
    UDP_TX_EOF: in std_logic;
    UDP_TX_CTS: out std_logic;
    UDP_TX_ACK: out std_logic;
    UDP_TX_NAK: out std_logic;
      wb_i :        in t_wishbone_master_in;
      wb_o :        out t_wishbone_master_out);
  end component;

  signal xwb_udp_tx_data: std_logic_vector(7 downto 0) := (others => '0');
  signal xwb_udp_tx_data_valid: std_logic := '0';
  signal xwb_udp_tx_sof: std_logic := '0';
  signal xwb_udp_tx_eof: std_logic := '0';
  signal xwb_udp_tx_cts: std_logic;
  signal xwb_udp_tx_ack: std_logic;
  signal xwb_udp_tx_nak: std_logic;
  
  signal xwb_udp_rx_data: std_logic_vector(7 downto 0);
  signal xwb_udp_rx_data_valid: std_logic;
  signal xwb_udp_rx_sof: std_logic;
  signal xwb_udp_rx_eof: std_logic;

begin

  --U_Ext_PLL : ext_pll_10_to_125m
  --  port map (
  --    clk_ext_i        => clk_ext,
  --    clk_ext_mul_o    => clk_ext_mul,
  --    rst_a_i          => ext_pll_reset,
  --    clk_in_stopped_o => clk_ext_stopped,
  --    locked_o         => clk_ext_mul_locked);

  --U_Extend_EXT_Reset : gc_extend_pulse
  --  generic map (
  --    g_width => 1000)
  --  port map (
  --    clk_i      => clk_sys,
  --    rst_n_i    => local_reset_n,
  --    pulse_i    => clk_ext_rst,
  --    extended_o => ext_pll_reset);

  --cmp_sys_clk_pll : PLL_BASE
  --  generic map (
  --    BANDWIDTH          => "OPTIMIZED",
  --    CLK_FEEDBACK       => "CLKFBOUT",
  --    COMPENSATION       => "INTERNAL",
  --    DIVCLK_DIVIDE      => 1,
  --    CLKFBOUT_MULT      => 8,
  --    CLKFBOUT_PHASE     => 0.000,
  --    CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
  --    CLKOUT0_PHASE      => 0.000,
  --    CLKOUT0_DUTY_CYCLE => 0.500,
  --    CLKOUT1_DIVIDE     => 16,         -- 125 MHz
  --    CLKOUT1_PHASE      => 0.000,
  --    CLKOUT1_DUTY_CYCLE => 0.500,
  --    CLKOUT2_DIVIDE     => 16,
  --    CLKOUT2_PHASE      => 0.000,
  --    CLKOUT2_DUTY_CYCLE => 0.500,
  --    CLKIN_PERIOD       => 8.0,
  --    REF_JITTER         => 0.016)
  --  port map (
  --    CLKFBOUT => pllout_clk_fb_pllref,
  --    CLKOUT0  => pllout_clk_sys,
  --    CLKOUT1  => open,
  --    CLKOUT2  => open,
  --    CLKOUT3  => open,
  --    CLKOUT4  => open,
  --    CLKOUT5  => open,
  --    LOCKED   => open,
  --    RST      => '0',
  --    CLKFBIN  => pllout_clk_fb_pllref,
  --    CLKIN    => clk_125m_pllref);

  --cmp_dmtd_clk_pll : PLL_BASE
  --  generic map (
  --    BANDWIDTH          => "OPTIMIZED",
  --    CLK_FEEDBACK       => "CLKFBOUT",
  --    COMPENSATION       => "INTERNAL",
  --    DIVCLK_DIVIDE      => 1,
  --    CLKFBOUT_MULT      => 50,
  --    CLKFBOUT_PHASE     => 0.000,
  --    CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
  --    CLKOUT0_PHASE      => 0.000,
  --    CLKOUT0_DUTY_CYCLE => 0.500,
  --    CLKOUT1_DIVIDE     => 16,         -- 62.5 MHz
  --    CLKOUT1_PHASE      => 0.000,
  --    CLKOUT1_DUTY_CYCLE => 0.500,
  --    CLKOUT2_DIVIDE     => 8,
  --    CLKOUT2_PHASE      => 0.000,
  --    CLKOUT2_DUTY_CYCLE => 0.500,
  --    CLKIN_PERIOD       => 50.0,
  --    REF_JITTER         => 0.016)
  --  port map (
  --    CLKFBOUT => pllout_clk_fb_dmtd,
  --    CLKOUT0  => pllout_clk_dmtd,
  --    CLKOUT1  => open,
  --    CLKOUT2  => open,
  --    CLKOUT3  => open,
  --    CLKOUT4  => open,
  --    CLKOUT5  => open,
  --    LOCKED   => open,
  --    RST      => '0',
  --    CLKFBIN  => pllout_clk_fb_dmtd,
  --    CLKIN    => clk_20m_vcxo_buf);

--  U_Reset_Gen : cute_reset_gen
--    port map (
--      clk_sys_i        => clk_sys,
--      rst_pcie_n_a_i   => '1',
--      rst_button_n_a_i => '1',
--      rst_n_o          => local_reset_n);
	local_reset_n <= rst_n_i;
	
  --cmp_clk_sys_buf : BUFG
  --  port map (
  --    O => clk_sys,
  --    I => pllout_clk_sys);

  --cmp_clk_dmtd_buf : BUFG
  --  port map (
  --    O => clk_dmtd,
  --    I => pllout_clk_dmtd);

  --cmp_clk_vcxo : BUFG
  --  port map (
  --    O => clk_20m_vcxo_buf,
  --    I => clk_20m_vcxo_i);

  --------------------------------------------------------------------------------
  ---- Local clock from gennum LCLK
  --------------------------------------------------------------------------------
  --cmp_l_clk_buf : IBUFDS
  --  generic map (
  --    DIFF_TERM    => false,            -- Differential Termination
  --    IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
  --    IOSTANDARD   => "DEFAULT")
  --  port map (
  --    O  => l_clk,                      -- Buffer output
  --    I  => L_CLKp,  -- Diff_p buffer input (connect directly to top-level port)
  --    IB => L_CLKn  -- Diff_n buffer input (connect directly to top-level port)
  --    );

  --cmp_pllrefclk_buf : IBUFGDS
  --  generic map (
  --    DIFF_TERM    => true,             -- Differential Termination
  --    IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
  --    IOSTANDARD   => "DEFAULT")
  --  port map (
  --    O  => clk_125m_pllref,            -- Buffer output
  --    I  => clk_125m_pllref_p_i,  -- Diff_p buffer input (connect directly to top-level port)
  --    IB => clk_125m_pllref_n_i  -- Diff_n buffer input (connect directly to top-level port)
  --    );


  ----------------------------------------------------------------------------------
  ------ Dedicated clock for GTP
  ----------------------------------------------------------------------------------
  --cmp_gtp_dedicated_clk_buf : IBUFGDS
  --  generic map(
  --    DIFF_TERM    => true,
  --    IBUF_LOW_PWR => true,
  --    IOSTANDARD   => "DEFAULT")
  --  port map (
  --    O  => gtp_dedicated_clk,
  --    I  => fpga_pll_ref_clk_101_p_i,
  --    IB => fpga_pll_ref_clk_101_n_i
  --    );

  clk_sys <= clk_sys_i;
  clk_dmtd <= clk_dmtd_i;
  gtp_dedicated_clk <= clk_gtp_i;
  clk_125m_pllref <= clk_ref_i;

  ------------------------------------------------------------------------------
  -- Active high reset
  ------------------------------------------------------------------------------
  --rst <= not(L_RST_N);

  ------------------------------------------------------------------------------
  -- GN4124 interface
  ------------------------------------------------------------------------------
  --cmp_gn4124_core : gn4124_core
  --  port map
  --  (
  --    ---------------------------------------------------------
  --    -- Control and status
  --    rst_n_a_i => L_RST_N,
  --    status_o  => open,

  --    ---------------------------------------------------------
  --    -- P2L Direction
  --    --
  --    -- Source Sync DDR related signals
  --    p2l_clk_p_i  => P2L_CLKp,
  --    p2l_clk_n_i  => P2L_CLKn,
  --    p2l_data_i   => P2L_DATA,
  --    p2l_dframe_i => P2L_DFRAME,
  --    p2l_valid_i  => P2L_VALID,
  --    -- P2L Control
  --    p2l_rdy_o    => P2L_RDY,
  --    p_wr_req_i   => P_WR_REQ,
  --    p_wr_rdy_o   => P_WR_RDY,
  --    rx_error_o   => RX_ERROR,
  --    vc_rdy_i     => VC_RDY,

  --    ---------------------------------------------------------
  --    -- L2P Direction
  --    --
  --    -- Source Sync DDR related signals
  --    l2p_clk_p_o  => L2P_CLKp,
  --    l2p_clk_n_o  => L2P_CLKn,
  --    l2p_data_o   => L2P_DATA,
  --    l2p_dframe_o => L2P_DFRAME,
  --    l2p_valid_o  => L2P_VALID,
  --    -- L2P Control
  --    l2p_edb_o    => L2P_EDB,
  --    l2p_rdy_i    => L2P_RDY,
  --    l_wr_rdy_i   => L_WR_RDY,
  --    p_rd_d_rdy_i => P_RD_D_RDY,
  --    tx_error_i   => TX_ERROR,

  --    ---------------------------------------------------------
  --    -- Interrupt interface
  --    dma_irq_o => open,
  --    irq_p_i   => '0',
  --    irq_p_o   => GPIO(0),

  --    ---------------------------------------------------------
  --    -- DMA registers wishbone interface (slave classic)
  --    dma_reg_clk_i => clk_sys,
  --    dma_reg_adr_i => (others=>'0'),
  --    dma_reg_dat_i => (others=>'0'),
  --    dma_reg_sel_i => (others=>'0'),
  --    dma_reg_stb_i => '0',
  --    dma_reg_we_i  => '0',
  --    dma_reg_cyc_i => '0',

  --    ---------------------------------------------------------
  --    -- CSR wishbone interface (master pipelined)
  --    csr_clk_i   => clk_sys,
  --    csr_adr_o   => wb_adr,
  --    csr_dat_o   => genum_wb_out.dat,
  --    csr_sel_o   => genum_wb_out.sel,
  --    csr_stb_o   => genum_wb_out.stb,
  --    csr_we_o    => genum_wb_out.we,
  --    csr_cyc_o   => genum_wb_out.cyc,
  --    csr_dat_i   => genum_wb_in.dat,
  --    csr_ack_i   => genum_wb_in.ack,
  --    csr_stall_i => genum_wb_in.stall,
  --    csr_err_i   => genum_wb_in.err,
  --    csr_rty_i   => genum_wb_in.rty,
  --    csr_int_i   => genum_wb_in.int,

  --    ---------------------------------------------------------
  --    -- L2P DMA Interface (Pipelined Wishbone master)
  --    dma_clk_i => clk_sys,
  --    dma_dat_i => (others=>'0'),
  --    dma_ack_i => '1',
  --    dma_stall_i => '0',
  --    dma_err_i => '0',
  --    dma_rty_i => '0',
  --    dma_int_i => '0');

  --genum_wb_out.adr(1 downto 0)   <= (others => '0');
  --genum_wb_out.adr(18 downto 2)  <= wb_adr(16 downto 0);
  --genum_wb_out.adr(31 downto 19) <= (others => '0');

  LED_TEST <= led_divider(23);
  process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      led_divider <= led_divider + 1;
    end if;
  end process;

  fpga_scl_o <= wrc_scl_o;
  fpga_sda_o <= wrc_sda_o;
  wrc_scl_i  <= fpga_scl_i;
  wrc_sda_i  <= fpga_sda_i;

  sfp_mod_def1_o <= sfp_scl_o;
  sfp_mod_def2_o <= sfp_sda_o;
  sfp_scl_i      <= sfp_mod_def1_i;
  sfp_sda_i      <= sfp_mod_def2_i;

  thermo_id_o <= owr_en(0);
  owr_i(0)  <= thermo_id_i;
  owr_i(1)  <= '0';

  pps_o <= pps;
  U_WR_CORE : xcute_core
    generic map (
      g_simulation                => 0,
      g_with_external_clock_input => true,
      --
      g_phys_uart                 => true,
      g_virtual_uart              => true,
      g_aux_clks                  => 0,
      g_ep_rxbuf_size             => 1024,
      g_tx_runt_padding           => true,
      g_pcs_16bit                 => false,
      g_dpram_initf               => "",
      g_etherbone_cfg_sdb         => c_etherbone_sdb,
      g_aux1_sdb                  => c_etherbone_sdb,
      g_aux2_sdb                  => c_etherbone_sdb,
      g_dpram_size                => 131072/4,
      g_interface_mode            => PIPELINED,
      g_address_granularity       => BYTE)
    port map (
      clk_sys_i     => clk_sys,
      clk_dmtd_i    => clk_dmtd,
      clk_ref_i     => clk_125m_pllref,
      clk_aux_i     => (others => '0'),
      clk_ext_i     => '0',
      clk_ext_mul_i => '0',
      clk_ext_mul_locked_i => '1',
      clk_ext_stopped_i    => '0',
      clk_ext_rst_o        => open,
      pps_ext_i     => '0',
      rst_n_i       => local_reset_n,

      dac_hpll_load_p1_o => dac_hpll_load_p1,
      dac_hpll_data_o    => dac_hpll_data,
      dac_dpll_load_p1_o => dac_dpll_load_p1,
      dac_dpll_data_o    => dac_dpll_data,

      phy_ref_clk_i      => clk_125m_pllref,
      phy_tx_data_o      => phy_tx_data,
      phy_tx_k_o         => phy_tx_k,
      phy_tx_disparity_i => phy_tx_disparity,
      phy_tx_enc_err_i   => phy_tx_enc_err,
      phy_rx_data_i      => phy_rx_data,
      phy_rx_rbclk_i     => phy_rx_rbclk,
      phy_rx_k_i         => phy_rx_k,
      phy_rx_enc_err_i   => phy_rx_enc_err,
      phy_rx_bitslide_i  => phy_rx_bitslide,
      phy_rst_o          => phy_rst,
      phy_loopen_o       => phy_loopen,
      phy_loopen_vec_o   => phy_loopen_vec,
      phy_rdy_i          => phy_rdy,
      phy_sfp_tx_fault_i => sfp_tx_fault_i,
      phy_sfp_los_i      => sfp_los_i,
      phy_sfp_tx_disable_o => sfp_tx_disable_o,
      phy_tx_prbs_sel_o  =>  phy_prbs_sel,

      led_act_o  => LED_RED,
      led_link_o => LED_GREEN,
      scl_o      => wrc_scl_o,
      scl_i      => wrc_scl_i,
      sda_o      => wrc_sda_o,
      sda_i      => wrc_sda_i,
      sfp_scl_o  => sfp_scl_o,
      sfp_scl_i  => sfp_scl_i,
      sfp_sda_o  => sfp_sda_o,
      sfp_sda_i  => sfp_sda_i,
      sfp_det_i  => sfp_mod_def0_b,
      btn1_i     => open,
      btn2_i     => open,
      spi_sclk_o  => open,
      spi_ncs_o   => open,
      spi_mosi_o  => open,
      spi_miso_i  => '0',

      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,

      owr_en_o => owr_en,
      owr_i    => owr_i,

      wrc_slave_i => wrc_slave_i,
      wrc_slave_o => wrc_slave_o,

      aux1_master_o => open,
      aux1_master_i => open,

      aux2_master_o => open,
      aux2_master_i => open,

      etherbone_cfg_master_o=> etherbone_cfg_slave_in,
      etherbone_cfg_master_i=> etherbone_cfg_slave_out,

      etherbone_src_o => etherbone_snk_in,
      etherbone_src_i => etherbone_snk_out,
      etherbone_snk_o => etherbone_src_in,
      etherbone_snk_i => etherbone_src_out,

      ext_src_o => ext_snk_in,
      ext_src_i => ext_snk_out,
      ext_snk_o => ext_src_in,
      ext_snk_i => ext_src_out,
      
      tm_dac_value_o       => open,
      tm_dac_wr_o          => open,
      tm_clk_aux_lock_en_i => (others => '0'),
      tm_clk_aux_locked_o  => open,
      tm_time_valid_o      => open,
      tm_tai_o             => tm_utc_o,
      tm_cycles_o          => open,
      pps_p_o              => pps,
      pps_led_o            => pps_led,

--      dio_o       => dio_out(4 downto 1),
      rst_aux_n_o => etherbone_rst_n
      );

  Etherbone : eb_slave_core
    generic map (
      g_sdb_address => x"0000000000030000")
    port map (
      clk_i       => clk_sys,
      nRst_i      => etherbone_rst_n,
      src_o       => etherbone_src_out,
      src_i       => etherbone_src_in,
      snk_o       => etherbone_snk_out,
      snk_i       => etherbone_snk_in,
      cfg_slave_o => etherbone_cfg_slave_out,
      cfg_slave_i => etherbone_cfg_slave_in,
      master_o    => etherbone_wb_out,
      master_i    => etherbone_wb_in);

  ---------------------
  masterbar : xwb_crossbar
    generic map (
      g_num_masters => 2,
      g_num_slaves  => 1,
      g_registered  => false,
      g_address     => (0 => x"00000000"),
      g_mask        => (0 => x"00000000"))
    port map (
      clk_sys_i   => clk_sys,
      rst_n_i     => local_reset_n,
      slave_i(0)  => ext_wb_out,
      slave_i(1)  => etherbone_wb_out,
      slave_o(0)  => ext_wb_in,
      slave_o(1)  => etherbone_wb_in,
      master_i(0) => wrc_slave_o,
      master_o(0) => wrc_slave_i);

  ---------------------

  U_GTP : wr_gtp_phy_spartan6
    generic map (
      g_enable_ch0 => 0,
      g_enable_ch1 => 1,
      g_simulation => 0)
    port map (
      gtp_clk_i => gtp_dedicated_clk,

      ch0_ref_clk_i      => clk_125m_pllref,
      ch0_tx_data_i      => x"00",
      ch0_tx_k_i         => '0',
      ch0_tx_disparity_o => open,
      ch0_tx_enc_err_o   => open,
      ch0_rx_rbclk_o     => open,
      ch0_rx_data_o      => open,
      ch0_rx_k_o         => open,
      ch0_rx_enc_err_o   => open,
      ch0_rx_bitslide_o  => open,
      ch0_rst_i          => '1',
      ch0_loopen_i       => '0',
      ch0_rdy_o          => open,

      ch1_ref_clk_i      => clk_125m_pllref,
      ch1_tx_data_i      => phy_tx_data,
      ch1_tx_k_i         => phy_tx_k(0),
      ch1_tx_disparity_o => phy_tx_disparity,
      ch1_tx_enc_err_o   => phy_tx_enc_err,
      ch1_rx_data_o      => phy_rx_data,
      ch1_rx_rbclk_o     => phy_rx_rbclk,
      ch1_rx_k_o         => phy_rx_k(0),
      ch1_rx_enc_err_o   => phy_rx_enc_err,
      ch1_rx_bitslide_o  => phy_rx_bitslide,
      ch1_rst_i          => phy_rst,
      ch1_loopen_i       => phy_loopen,
      ch1_loopen_vec_i   => phy_loopen_vec,
      ch1_tx_prbs_sel_i  => phy_prbs_sel,
      ch1_rdy_o          => phy_rdy,
      pad_txn0_o         => open,
      pad_txp0_o         => open,
      pad_rxn0_i         => '0',
      pad_rxp0_i         => '0',
      pad_txn1_o         => sfp_txn_o,
      pad_txp1_o         => sfp_txp_o,
      pad_rxn1_i         => sfp_rxn_i,
      pad_rxp1_i         => sfp_rxp_i);

  

  
  U_DAC_ARB : cute_serial_dac_arb
    generic map (
      g_invert_sclk    => false,
      g_num_extra_bits => 8)

    port map (
      clk_i   => clk_sys,
      rst_n_i => local_reset_n,

      val1_i  => dac_dpll_data,
      load1_i => dac_dpll_load_p1,

      val2_i  => dac_hpll_data,
      load2_i => dac_hpll_load_p1,
      dac_sync_n_o  => dac_sync_n_o,
      dac_ldac_n_o  => dac_ldac_n_o,
      dac_clr_n_o   => dac_clr_n_o,
      dac_sclk_o    => dac_sclk_o,
      dac_din_o     => dac_din_o);


  --U_Extend_PPS : gc_extend_pulse
  --  generic map (
  --    g_width => 10000000)
  --  port map (
  --    clk_i      => clk_125m_pllref,
  --    rst_n_i    => local_reset_n,
  --    pulse_i    => pps_led,
  --    extended_o => dio_led_top_o);


  --gen_dio_iobufs : for i in 0 to 4 generate
  --  U_ibuf : IBUFDS
  --    generic map (
  --      DIFF_TERM => true)
  --    port map (
  --      O  => dio_in(i),
  --      I  => dio_p_i(i),
  --      IB => dio_n_i(i)
  --      );

  --  U_obuf : OBUFDS
  --    port map (
  --      I  => dio_out(i),
  --      O  => dio_p_o(i),
  --      OB => dio_n_o(i)
  --      );
  --end generate gen_dio_iobufs;

  --U_input_buffer : IBUFGDS
  --  generic map (
  --    DIFF_TERM => true)
  --  port map (
  --    O  => clk_ext,
  --    I  => dio_clk_p_i,
  --    IB => dio_clk_n_i
  --    );

  --dio_led_bot_o <= '0';

  --process(clk_125m_pllref)
  --begin
  --  if rising_edge(clk_125m_pllref) then
  --    clk_ref_div2 <= not clk_ref_div2;
  --  end if;
  --end process;
  
  --dio_out(0) <= pps;
  --dio_out(1) <= clk_ref_div2;

  --dio_oe_n_o(0)          <= '0';
  --dio_oe_n_o(2 downto 1) <= (others => '0');
  --dio_oe_n_o(3)          <= '1';        -- for external 1-PPS
  --dio_oe_n_o(4)          <= '1';        -- for external 10MHz clock

  --dio_onewire_b <= '0' when owr_en(1) = '1' else 'Z';
  --owr_i(1)      <= dio_onewire_b;

  --dio_term_en_o <= (others => '0');

  --dio_sdn_ck_n_o <= '1';
  --dio_sdn_n_o    <= '1';

    ------------------------------------------------------------------------
      -- tcp core modules --
    ------------------------------------------------------------------------
    Inst_wb_udp_core : xwb_udp_core
    port map(
        clk_ref  => clk_ref_i,
        clk_sys  => clk_sys_i,
        rst_n_i  => local_reset_n,
        wb_i     => ext_wb_in,
        wb_o     => ext_wb_out,
        snk_i    => ext_snk_in,
        snk_o    => ext_snk_out,
        src_o    => ext_src_out,
        src_i    => ext_src_in,
		  
		  UDP_RX_DATA			=> xwb_udp_rx_data,
        UDP_RX_DATA_VALID	=> xwb_udp_rx_data_valid,
        UDP_RX_SOF			=> xwb_udp_rx_sof,
        UDP_RX_EOF			=> xwb_udp_rx_eof,
		  
        UDP_TX_DATA			=> xwb_udp_tx_data,
        UDP_TX_DATA_VALID	=> xwb_udp_tx_data_valid,
        UDP_TX_SOF			=> xwb_udp_tx_sof,
        UDP_TX_EOF			=> xwb_udp_tx_eof,
        UDP_TX_CTS			=> xwb_udp_tx_cts,
        UDP_TX_ACK			=> xwb_udp_tx_ack,
        UDP_TX_NAK			=> xwb_udp_tx_nak);

    UDP_RX_DATA				<= xwb_udp_rx_data;
    UDP_RX_DATA_VALID		<= xwb_udp_rx_data_valid;
    UDP_RX_SOF					<= xwb_udp_rx_sof;
    UDP_RX_EOF					<= xwb_udp_rx_eof;


    xwb_udp_tx_data			<= UDP_TX_DATA;
    xwb_udp_tx_data_valid	<= UDP_TX_DATA_VALID;
    xwb_udp_tx_sof			<= UDP_TX_SOF;
    xwb_udp_tx_eof			<= UDP_TX_EOF;
    UDP_TX_CTS					<= xwb_udp_tx_cts;
    UDP_TX_ACK					<= xwb_udp_tx_ack;
    UDP_TX_NAK					<= xwb_udp_tx_nak;

end rtl;


