-------------------------------------------------------------------------------
-- Title      : Gigabit Ethernet reception pipeline
-- Project    : White Rabbit MAC/Endpoint
-------------------------------------------------------------------------------
-- File       : ep_rx_path.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2009-06-22
-- Last update: 2013-03-12
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: RX path unit:
-- - provides elastic buffering between RX and system clock
-- - checks frame CRC and size
-- - inserts/removes 802.1q headers when necessary 
-- - parses packet headers and generates RTU requests
-- - performs programmable packet inspection and classifying
-- - distinguishes between HP and non-HP frames
-- - issues RTU requests
-- - embeds RX OOB block with timestamp information
-- 
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009-2011 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2009-06-22  0.1      twlostow        Created
-- 2011-10-18  0.5      twlostow        WB rev B4 - compatible data path
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.genram_pkg.all;
use work.endpoint_private_pkg.all;
use work.ep_wbgen2_pkg.all;
use work.wr_fabric_pkg.all;

entity ep_rx_path is
  generic (
    g_with_vlans          : boolean := true;
    g_with_dpi_classifier : boolean := true;
    g_with_rtu            : boolean := true;
    g_with_rx_buffer      : boolean := true;
    g_with_early_match    : boolean := false;
    g_rx_buffer_size      : integer := 1024;
    g_use_new_crc         :	boolean := false);
  port (
    clk_sys_i   : in std_logic;
    clk_rx_i    : in std_logic;
    rst_n_sys_i : in std_logic;
    rst_n_rx_i  : in std_logic;

-- physical coding sublayer (PCS) interface
    pcs_fab_i             : in  t_ep_internal_fabric;
    pcs_fifo_almostfull_o : out std_logic;
    pcs_busy_i            : in  std_logic;

-- Wishbone I/O
    src_wb_o : out t_wrf_source_out;
    src_wb_i : in  t_wrf_source_in;

-- flow control signals
    fc_pause_p_o           : out std_logic;
    fc_pause_quanta_o      : out std_logic_vector(15 downto 0);
    fc_pause_prio_mask_o   : out std_logic_vector(7 downto 0);
    fc_buffer_occupation_o : out std_logic_vector(7 downto 0);

-- RMON/statistic counters signals
    rmon_o : out t_rmon_triggers;
    regs_i : in  t_ep_out_registers;
    regs_o : out t_ep_in_registers;

-- info for TRU module
    pfilter_pclass_o : out std_logic_vector(7 downto 0);
    pfilter_drop_o   : out std_logic;
    pfilter_done_o   : out std_logic;

-------------------------------------------------------------------------------
-- RTU interface
-------------------------------------------------------------------------------

    rtu_rq_o       : out t_ep_internal_rtu_request;
    rtu_full_i     : in  std_logic;
    rtu_rq_valid_o : out std_logic;
    rtu_rq_abort_o : out std_logic;
    dbg_o          : out std_logic_vector(29 downto 0)
    );
end ep_rx_path;

architecture behavioral of ep_rx_path is

  component ep_rtu_header_extract
    generic (
      g_with_rtu : boolean);
    port (
      clk_sys_i        : in  std_logic;
      rst_n_i          : in  std_logic;
      snk_fab_i        : in  t_ep_internal_fabric;
      snk_dreq_o       : out std_logic;
      src_fab_o        : out t_ep_internal_fabric;
      src_dreq_i       : in  std_logic;
      mbuf_is_pause_i  : in  std_logic;
      vlan_class_i     : in  std_logic_vector(2 downto 0);
      vlan_vid_i       : in  std_logic_vector(11 downto 0);
      vlan_tag_done_i  : in  std_logic;
      vlan_is_tagged_i : in  std_logic;
      rmon_drp_at_rtu_full_o: out std_logic;
      rtu_rq_o         : out t_ep_internal_rtu_request;
      rtu_full_i       : in  std_logic;
      rtu_rq_abort_o   : out std_logic;
      rtu_rq_valid_o   : out std_logic);
  end component;

  component ep_rx_early_address_match
    port (
      clk_sys_i               : in  std_logic;
      clk_rx_i                : in  std_logic;
      rst_n_sys_i             : in  std_logic;
      rst_n_rx_i              : in  std_logic;
      snk_fab_i               : in  t_ep_internal_fabric;
      src_fab_o               : out t_ep_internal_fabric;
      match_done_o            : out std_logic;
      match_is_hp_o           : out std_logic;
      match_is_pause_o        : out std_logic;
      match_pause_quanta_o    : out std_logic_vector(15 downto 0);
      match_pause_prio_mask_o : out std_logic_vector(7 downto 0);
      match_pause_p_o         : out std_logic;
      regs_i                  : in  t_ep_out_registers);
  end component;

  component ep_clock_alignment_fifo
    generic (
      g_size                 : integer;
      g_almostfull_threshold : integer);
    port (
      rst_n_rd_i       : in  std_logic;
      clk_wr_i         : in  std_logic;
      clk_rd_i         : in  std_logic;
      dreq_i           : in  std_logic;
      fab_i            : in  t_ep_internal_fabric;
      fab_o            : out t_ep_internal_fabric;
      full_o           : out std_logic;
      empty_o          : out std_logic;
      almostfull_o     : out std_logic;
      pass_threshold_i : in  std_logic_vector(f_log2_size(g_size)-1 downto 0));
  end component;

  component ep_packet_filter
    port (
      clk_rx_i    : in  std_logic;
      clk_sys_i   : in  std_logic;
      rst_n_rx_i  : in  std_logic;
      rst_n_sys_i : in  std_logic;
      snk_fab_i   : in  t_ep_internal_fabric;
      src_fab_o   : out t_ep_internal_fabric;
      done_o      : out std_logic;
      pclass_o    : out std_logic_vector(7 downto 0);
      drop_o      : out std_logic;
      regs_i      : in  t_ep_out_registers);
  end component;

  component ep_rx_vlan_unit
    port (
      clk_sys_i   : in    std_logic;
      rst_n_i     : in    std_logic;
      snk_fab_i   : in    t_ep_internal_fabric;
      snk_dreq_o  : out   std_logic;
      src_fab_o   : out   t_ep_internal_fabric;
      src_dreq_i  : in    std_logic;
      tclass_o    : out   std_logic_vector(2 downto 0);
      vid_o       : out   std_logic_vector(11 downto 0);
      tag_done_o  : out   std_logic;
      is_tagged_o : out   std_logic;
      rmon_o      : inout t_rmon_triggers;
      regs_i      : in    t_ep_out_registers;
      regs_o      : out   t_ep_in_registers);
  end component;

  component ep_rx_oob_insert
    port (
      clk_sys_i  : in  std_logic;
      rst_n_i    : in  std_logic;
      snk_fab_i  : in  t_ep_internal_fabric;
      snk_dreq_o : out std_logic;
      src_fab_o  : out t_ep_internal_fabric;
      src_dreq_i : in  std_logic;
      regs_i     : in  t_ep_out_registers);
  end component;

  component ep_rx_crc_size_check
  	generic (
      g_use_new_crc : boolean := false);
    port (
      clk_sys_i      : in  std_logic;
      rst_n_i        : in  std_logic;
      snk_fab_i      : in  t_ep_internal_fabric;
      snk_dreq_o     : out std_logic;
      src_fab_o      : out t_ep_internal_fabric;
      src_dreq_i     : in  std_logic;
      regs_i         : in  t_ep_out_registers;
      rmon_pcs_err_o : out std_logic;
      rmon_giant_o   : out std_logic;
      rmon_runt_o    : out std_logic;
      rmon_crc_err_o : out std_logic);
  end component;

  component ep_rx_wb_master
    generic (
      g_ignore_ack   : boolean;
      g_cyc_on_stall : boolean := false);
    port (
      clk_sys_i  : in  std_logic;
      rst_n_i    : in  std_logic;
      snk_fab_i  : in  t_ep_internal_fabric;
      snk_dreq_o : out std_logic;
      src_wb_i   : in  t_wrf_source_in;
      src_wb_o   : out t_wrf_source_out);
  end component;

  component ep_rx_status_reg_insert
    port (
      clk_sys_i           : in  std_logic;
      rst_n_i             : in  std_logic;
      snk_fab_i           : in  t_ep_internal_fabric;
      snk_dreq_o          : out std_logic;
      src_fab_o           : out t_ep_internal_fabric;
      src_dreq_i          : in  std_logic;
      mbuf_valid_i        : in  std_logic;
      mbuf_ack_o          : out std_logic;
      mbuf_drop_i         : in  std_logic;
      mbuf_pclass_i       : in  std_logic_vector(7 downto 0);
      mbuf_is_hp_i        : in  std_logic;
      mbuf_is_pause_i     : in  std_logic;
      rmon_pfilter_drop_o : out std_logic);
  end component;

  component ep_rx_buffer
    generic (
      g_size : integer);
    port (
      clk_sys_i  : in  std_logic;
      rst_n_i    : in  std_logic;
      snk_fab_i  : in  t_ep_internal_fabric;
      snk_dreq_o : out std_logic;
      src_fab_o  : out t_ep_internal_fabric;
      src_dreq_i : in  std_logic;
      level_o    : out std_logic_vector(7 downto 0);
      regs_i     : in  t_ep_out_registers;
      rmon_o     : out t_rmon_triggers);
  end component;

  type t_rx_deframer_state is (RXF_IDLE, RXF_DATA, RXF_FLUSH_STALL, RXF_FINISH_CYCLE, RXF_THROW_ERROR);

  signal state : t_rx_deframer_state;

  signal gap_cntr : unsigned(3 downto 0);

  -- new sigs
  signal counter : unsigned(7 downto 0);

  signal rxdata_saved : std_logic_vector(15 downto 0);
  signal next_hdr     : std_logic;
  signal is_pause     : std_logic;

  signal data_firstword : std_logic;


  signal flush_stall : std_logic;
  signal stb_int     : std_logic;

  signal fab_int  : t_ep_internal_fabric;
  signal dreq_int : std_logic;

  signal ack_count   : unsigned(7 downto 0);
  signal src_out_int : t_wrf_source_out;

  signal tmp_sel : std_logic;
  signal tmp_dat : std_logic_vector(15 downto 0);


  type t_fab_pipe is array(integer range <>) of t_ep_internal_fabric;

  signal fab_pipe  : t_fab_pipe(0 to 9);
  signal dreq_pipe : std_logic_vector(9 downto 0);

  signal ematch_done     : std_logic;
  signal ematch_is_hp    : std_logic;
  signal ematch_is_pause : std_logic;
  signal fc_pause_p      : std_logic;

  signal pfilter_pclass : std_logic_vector(7 downto 0);
  signal pfilter_drop   : std_logic;
  signal pfilter_done   : std_logic;

  signal vlan_tclass    : std_logic_vector(2 downto 0);
  signal vlan_vid       : std_logic_vector(11 downto 0);
  signal vlan_tag_done  : std_logic;
  signal vlan_is_tagged : std_logic;

  signal pcs_fifo_almostfull                                    : std_logic;
  signal mbuf_rd, mbuf_valid, mbuf_we, mbuf_pf_drop, mbuf_is_hp : std_logic;
  signal mbuf_is_pause, mbuf_full, mbuf_we_d0, mbuf_we_d1       : std_logic;
  signal mbuf_pf_class                                          : std_logic_vector(7 downto 0);
  signal rtu_rq_valid                                           : std_logic;

begin  -- behavioral

  fab_pipe(0) <= pcs_fab_i;

  fc_pause_p_o    <= fc_pause_p;
  gen_with_early_match : if(g_with_early_match) generate
    U_early_addr_match : ep_rx_early_address_match
      port map (
        clk_sys_i               => clk_sys_i,
        clk_rx_i                => clk_rx_i,
        rst_n_sys_i             => rst_n_sys_i,
        rst_n_rx_i              => rst_n_rx_i,
        snk_fab_i               => fab_pipe(0),
        src_fab_o               => fab_pipe(1),
        match_done_o            => ematch_done,
        match_is_hp_o           => ematch_is_hp,
        match_is_pause_o        => ematch_is_pause,
        match_pause_quanta_o    => fc_pause_quanta_o,
        match_pause_prio_mask_o => fc_pause_prio_mask_o,
        match_pause_p_o         => fc_pause_p,
        regs_i                  => regs_i);
  end generate gen_with_early_match;

  gen_without_early_match : if(not g_with_early_match) generate
    fab_pipe(1)          <= fab_pipe(0);
    ematch_done          <= '1';
    ematch_is_hp         <= '0';
    ematch_is_pause      <= '0';
    fc_pause_quanta_o    <= (others =>'0');
    fc_pause_prio_mask_o <= (others =>'0');
    fc_pause_p           <= '0';
  end generate gen_without_early_match;

  gen_with_packet_filter : if(g_with_dpi_classifier) generate
    U_packet_filter : ep_packet_filter
      port map (
        clk_sys_i   => clk_sys_i,
        clk_rx_i    => clk_rx_i,
        rst_n_sys_i => rst_n_sys_i,
        rst_n_rx_i  => rst_n_rx_i,

        snk_fab_i => fab_pipe(1),
        src_fab_o => fab_pipe(2),
        done_o    => pfilter_done,
        pclass_o  => pfilter_pclass,
        drop_o    => pfilter_drop,
        regs_i    => regs_i);
  end generate gen_with_packet_filter;

  gen_without_packet_filter : if(not g_with_dpi_classifier) generate
    fab_pipe(2)    <= fab_pipe(1);
    pfilter_drop   <= '0';
    pfilter_done   <= '1';
    pfilter_pclass <= (others => '0');
  end generate gen_without_packet_filter;

  mbuf_we <= ematch_done when
             (regs_i.pfcr0_enable_o = '0' or not g_with_dpi_classifier) else
             pfilter_done;

  U_match_buffer : generic_shiftreg_fifo
    generic map (
      g_data_width => 8 + 1 + 1 + 1,
      g_size       => 16)
    port map (
      rst_n_i           => rst_n_sys_i,
      clk_i             => clk_sys_i,
      d_i (0)           => ematch_is_hp,
      d_i (1)           => ematch_is_pause,
      d_i (2)           => pfilter_drop,
      d_i (10 downto 3) => pfilter_pclass,

      we_i              => mbuf_we,
      q_o (0)           => mbuf_is_hp,
      q_o (1)           => mbuf_is_pause,
      q_o (2)           => mbuf_pf_drop,
      q_o (10 downto 3) => mbuf_pf_class,

      rd_i      => mbuf_rd,
      full_o    => mbuf_full,
      q_valid_o => mbuf_valid);

  U_Rx_Clock_Align_FIFO : ep_clock_alignment_fifo
    generic map (
      g_size                 => 128,
      g_almostfull_threshold => 112)
    port map (
      rst_n_rd_i       => rst_n_sys_i,
      clk_wr_i         => clk_rx_i,
      clk_rd_i         => clk_sys_i,
      dreq_i           => dreq_pipe(3),
      fab_i            => fab_pipe(2),
      fab_o            => fab_pipe(3),
      full_o           => open,
      empty_o          => open,
      almostfull_o     => pcs_fifo_almostfull_o,
      pass_threshold_i => std_logic_vector(to_unsigned(32, 7)));  -- fixme: add
                                                                  -- register

  U_Insert_OOB : ep_rx_oob_insert
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_sys_i,
      snk_fab_i  => fab_pipe(3),
      snk_dreq_o => dreq_pipe(3),
      src_dreq_i => dreq_pipe(4),
      src_fab_o  => fab_pipe(4),
      regs_i     => regs_i);

  U_crc_size_checker : ep_rx_crc_size_check
    generic map (
      g_use_new_crc	 => g_use_new_crc)
    port map (
      clk_sys_i      => clk_sys_i,
      rst_n_i        => rst_n_sys_i,
      snk_fab_i      => fab_pipe(4),
      snk_dreq_o     => dreq_pipe(4),
      src_dreq_i     => dreq_pipe(5),
      src_fab_o      => fab_pipe(5),
      regs_i         => regs_i,
      rmon_pcs_err_o => rmon_o.rx_pcs_err,
      rmon_giant_o   => rmon_o.rx_giant,
      rmon_runt_o    => rmon_o.rx_runt,
      rmon_crc_err_o => rmon_o.rx_crc_err);

  gen_with_vlan_unit : if(g_with_vlans) generate
    U_vlan_unit : ep_rx_vlan_unit
      port map (
        clk_sys_i   => clk_sys_i,
        rst_n_i     => rst_n_sys_i,
        snk_fab_i   => fab_pipe(5),
        snk_dreq_o  => dreq_pipe(5),
        src_fab_o   => fab_pipe(6),
        src_dreq_i  => dreq_pipe(6),
        tclass_o    => vlan_tclass,
        vid_o       => vlan_vid,
        tag_done_o  => vlan_tag_done,
        is_tagged_o => vlan_is_tagged,
        rmon_o      => open,
        regs_i      => regs_i,
        regs_o      => regs_o);
  end generate gen_with_vlan_unit;


  gen_without_vlan_unit : if(not g_with_vlans) generate
    fab_pipe(6)    <= fab_pipe(5);
    dreq_pipe(5)   <= dreq_pipe(6);
    vlan_tclass    <= (others => '0');
    vlan_vid       <= (others => '0');
    vlan_tag_done  <= '0';
    vlan_is_tagged <= '0';
  end generate gen_without_vlan_unit;

  U_RTU_Header_Extract : ep_rtu_header_extract
    generic map (
      g_with_rtu => g_with_rtu)
    port map (
      clk_sys_i        => clk_sys_i,
      rst_n_i          => rst_n_sys_i,
      snk_fab_i        => fab_pipe(6),
      snk_dreq_o       => dreq_pipe(6),
      src_fab_o        => fab_pipe(7),
      src_dreq_i       => dreq_pipe(7),
      mbuf_is_pause_i  => mbuf_is_pause,  -- this module is in the pipe before ep_rx_status_reg_insert,
                                          -- however, we know that mbuf_is_pause is valid when it 
                                          -- is used by this module -- this is because blocks the pipe
                                          -- untill mbuf_valid is HIGH, and rtu_rq_valid_o is inserted HIGH
                                          -- at the end of the header... (clear ??:)
      vlan_class_i     => vlan_tclass,
      vlan_vid_i       => vlan_vid,
      vlan_tag_done_i  => vlan_tag_done,
      vlan_is_tagged_i => vlan_is_tagged,
      
      rmon_drp_at_rtu_full_o => rmon_o.rx_drop_at_rtu_full,
      
      rtu_rq_o         => rtu_rq_o,
      rtu_full_i       => rtu_full_i,
      rtu_rq_abort_o   => rtu_rq_abort_o,
      rtu_rq_valid_o   => rtu_rq_valid);

  gen_with_rx_buffer : if g_with_rx_buffer generate
    U_Rx_Buffer : ep_rx_buffer
      generic map (
        g_size => g_rx_buffer_size)
      port map (
        clk_sys_i  => clk_sys_i,
        rst_n_i    => rst_n_sys_i,
        snk_fab_i  => fab_pipe(7),
        snk_dreq_o => dreq_pipe(7),
        src_fab_o  => fab_pipe(8),
        src_dreq_i => dreq_pipe(8),
        level_o    => fc_buffer_occupation_o,
        regs_i     => regs_i,
        rmon_o     => open);
  end generate gen_with_rx_buffer;

  gen_without_rx_buffer : if (not g_with_rx_buffer) generate
    fab_pipe(8)  <= fab_pipe(7);
    dreq_pipe(7) <= dreq_pipe(8);
  end generate gen_without_rx_buffer;

--   U_RTU_Header_Extract : ep_rtu_header_extract
--     generic map (
--       g_with_rtu => g_with_rtu)
--     port map (
--       clk_sys_i        => clk_sys_i,
--       rst_n_i          => rst_n_sys_i,
--       snk_fab_i        => fab_pipe(7),
--       snk_dreq_o       => dreq_pipe(7),
--       src_fab_o        => fab_pipe(8),
--       src_dreq_i       => dreq_pipe(8),
--       mbuf_is_pause_i  => mbuf_is_pause,  -- this module is in the pipe before ep_rx_status_reg_insert,
--                                           -- however, we know that mbuf_is_pause is valid when it 
--                                           -- is used by this module -- this is because blocks the pipe
--                                           -- untill mbuf_valid is HIGH, and rtu_rq_valid_o is inserted HIGH
--                                           -- at the end of the header... (clear ??:)
--       vlan_class_i     => vlan_tclass,
--       vlan_vid_i       => vlan_vid,
--       vlan_tag_done_i  => vlan_tag_done,
--       vlan_is_tagged_i => vlan_is_tagged,
--       
--       rmon_drp_at_rtu_full_o => rmon_o.rx_drop_at_rtu_full,
--       
--       rtu_rq_o         => rtu_rq_o,
--       rtu_full_i       => rtu_full_i,
--       rtu_rq_valid_o   => rtu_rq_valid);

  U_Gen_Status : ep_rx_status_reg_insert
    port map (
      clk_sys_i           => clk_sys_i,
      rst_n_i             => rst_n_sys_i,
      snk_fab_i           => fab_pipe(8),
      snk_dreq_o          => dreq_pipe(8),
      src_fab_o           => fab_pipe(9),
      src_dreq_i          => dreq_pipe(9),
      mbuf_valid_i        => mbuf_valid,
      mbuf_ack_o          => mbuf_rd,
      mbuf_drop_i         => mbuf_pf_drop,
      mbuf_pclass_i       => mbuf_pf_class,
      mbuf_is_hp_i        => mbuf_is_hp,
      mbuf_is_pause_i     => mbuf_is_pause,
      rmon_pfilter_drop_o => rmon_o.rx_pfilter_drop);

  U_RX_Wishbone_Master : ep_rx_wb_master
    generic map (
      g_ignore_ack => true)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_sys_i,
      snk_fab_i  => fab_pipe(9),
      snk_dreq_o => dreq_pipe(9),
      src_wb_i   => src_wb_i,
      src_wb_o   => src_wb_o
      );

  -- direct output of packet filter data (for TRU)
  pfilter_pclass_o <= pfilter_pclass;
  pfilter_drop_o   <= pfilter_drop;
  pfilter_done_o   <= pfilter_done;

  rtu_rq_valid_o   <= rtu_rq_valid;
  -----------------------------------------
  -- RMON events
  -----------------------------------------
  rmon_o.rx_pause <= fc_pause_p;
  GEN_PCLASS_EVT: for i in 0 to 7 generate
    rmon_o.rx_pclass(i) <= pfilter_pclass(i) and pfilter_done;
  end generate;

  rmon_o.rx_tclass(0) <= rtu_rq_valid when (vlan_tclass = "000" and vlan_is_tagged = '1') else '0';
  rmon_o.rx_tclass(1) <= rtu_rq_valid when (vlan_tclass = "001" and vlan_is_tagged = '1') else '0';
  rmon_o.rx_tclass(2) <= rtu_rq_valid when (vlan_tclass = "010" and vlan_is_tagged = '1') else '0';
  rmon_o.rx_tclass(3) <= rtu_rq_valid when (vlan_tclass = "011" and vlan_is_tagged = '1') else '0';
  rmon_o.rx_tclass(4) <= rtu_rq_valid when (vlan_tclass = "100" and vlan_is_tagged = '1') else '0';
  rmon_o.rx_tclass(5) <= rtu_rq_valid when (vlan_tclass = "101" and vlan_is_tagged = '1') else '0';
  rmon_o.rx_tclass(6) <= rtu_rq_valid when (vlan_tclass = "110" and vlan_is_tagged = '1') else '0';
  rmon_o.rx_tclass(7) <= rtu_rq_valid when (vlan_tclass = "111" and vlan_is_tagged = '1') else '0';

  GEN_DBG: for i in 0 to 9 generate
    dbg_o(i)    <= fab_pipe(i).sof;
    dbg_o(i+10) <= fab_pipe(i).eof;
    dbg_o(i+20) <= dreq_pipe(i);
  end generate GEN_DBG;
    

end behavioral;

