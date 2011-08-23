---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for WR switch endpoint controller
---------------------------------------------------------------------------------------
-- File           : ep_wishbone_controller.vhd
-- Author         : auto-generated by wbgen2 from ep_wishbone_controller.wb
-- Created        : Mon Aug 22 23:38:16 2011
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE ep_wishbone_controller.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

use work.ep_wbgen2_pkg.all;


entity ep_wishbone_controller is
port (
  rst_n_i                                  : in     std_logic;
  wb_clk_i                                 : in     std_logic;
  wb_addr_i                                : in     std_logic_vector(5 downto 0);
  wb_data_i                                : in     std_logic_vector(31 downto 0);
  wb_data_o                                : out    std_logic_vector(31 downto 0);
  wb_cyc_i                                 : in     std_logic;
  wb_sel_i                                 : in     std_logic_vector(3 downto 0);
  wb_stb_i                                 : in     std_logic;
  wb_we_i                                  : in     std_logic;
  wb_ack_o                                 : out    std_logic;
  tx_clk_i                                 : in     std_logic;
-- Ports for RAM: Event counters memory
  ep_rmon_ram_addr_i                       : in     std_logic_vector(4 downto 0);
-- Read data output
  ep_rmon_ram_data_o                       : out    std_logic_vector(31 downto 0);
-- Read strobe input (active high)
  ep_rmon_ram_rd_i                         : in     std_logic;
-- Write data input
  ep_rmon_ram_data_i                       : in     std_logic_vector(31 downto 0);
-- Write strobe (active high)
  ep_rmon_ram_wr_i                         : in     std_logic;
  regs_b                                   : inout  t_ep_registers
);
end ep_wishbone_controller;

architecture syn of ep_wishbone_controller is

signal ep_ecr_portid_int                        : std_logic_vector(4 downto 0);
signal ep_ecr_rst_cnt_dly0                      : std_logic      ;
signal ep_ecr_rst_cnt_int                       : std_logic      ;
signal ep_ecr_tx_en_int                         : std_logic      ;
signal ep_ecr_rx_en_int                         : std_logic      ;
signal ep_tscr_en_txts_int                      : std_logic      ;
signal ep_tscr_en_rxts_int                      : std_logic      ;
signal ep_tscr_cs_start_int                     : std_logic      ;
signal ep_tscr_cs_start_int_delay               : std_logic      ;
signal ep_tscr_cs_start_sync0                   : std_logic      ;
signal ep_tscr_cs_start_sync1                   : std_logic      ;
signal ep_tscr_cs_start_sync2                   : std_logic      ;
signal ep_tscr_cs_done_sync0                    : std_logic      ;
signal ep_tscr_cs_done_sync1                    : std_logic      ;
signal ep_rfcr_a_runt_int                       : std_logic      ;
signal ep_rfcr_a_giant_int                      : std_logic      ;
signal ep_rfcr_a_hp_int                         : std_logic      ;
signal ep_rfcr_keep_crc_int                     : std_logic      ;
signal ep_rfcr_hpap_int                         : std_logic_vector(7 downto 0);
signal ep_rfcr_mru_int                          : std_logic_vector(13 downto 0);
signal ep_vcr0_qmode_int                        : std_logic_vector(1 downto 0);
signal ep_vcr0_fix_prio_int                     : std_logic      ;
signal ep_vcr0_prio_val_int                     : std_logic_vector(2 downto 0);
signal ep_vcr0_pvid_int                         : std_logic_vector(11 downto 0);
signal ep_pfcr0_enable_int                      : std_logic      ;
signal ep_pfcr1_mm_data_lsb_int                 : std_logic_vector(11 downto 0);
signal ep_tcar_pcp_map_int                      : std_logic_vector(23 downto 0);
signal ep_fcr_rxpause_int                       : std_logic      ;
signal ep_fcr_txpause_int                       : std_logic      ;
signal ep_fcr_tx_thr_int                        : std_logic_vector(7 downto 0);
signal ep_fcr_tx_quanta_int                     : std_logic_vector(15 downto 0);
signal ep_mach_int                              : std_logic_vector(15 downto 0);
signal ep_macl_int                              : std_logic_vector(31 downto 0);
signal ep_dmcr_en_int                           : std_logic      ;
signal ep_dmcr_n_avg_int                        : std_logic_vector(11 downto 0);
signal ep_mdio_cr_addr_int                      : std_logic_vector(7 downto 0);
signal ep_mdio_cr_rw_int                        : std_logic      ;
signal ep_mdio_asr_phyad_int                    : std_logic_vector(7 downto 0);
signal ep_rmon_ram_rddata_int                   : std_logic_vector(31 downto 0);
signal ep_rmon_ram_rd_int                       : std_logic      ;
signal ep_rmon_ram_wr_int                       : std_logic      ;
signal ack_sreg                                 : std_logic_vector(9 downto 0);
signal rddata_reg                               : std_logic_vector(31 downto 0);
signal wrdata_reg                               : std_logic_vector(31 downto 0);
signal bwsel_reg                                : std_logic_vector(3 downto 0);
signal rwaddr_reg                               : std_logic_vector(5 downto 0);
signal ack_in_progress                          : std_logic      ;
signal wr_int                                   : std_logic      ;
signal rd_int                                   : std_logic      ;
signal bus_clock_int                            : std_logic      ;
signal allones                                  : std_logic_vector(31 downto 0);
signal allzeros                                 : std_logic_vector(31 downto 0);

begin
regs_b <= c_ep_registers_init_value;
-- Some internal signals assignments. For (foreseen) compatibility with other bus standards.
wrdata_reg <= wb_data_i;
bwsel_reg <= wb_sel_i;
bus_clock_int <= wb_clk_i;
rd_int <= wb_cyc_i and (wb_stb_i and (not wb_we_i));
wr_int <= wb_cyc_i and (wb_stb_i and wb_we_i);
allones <= (others => '1');
allzeros <= (others => '0');
-- 
-- Main register bank access process.
process (bus_clock_int, rst_n_i)
begin
  if (rst_n_i = '0') then 
    ack_sreg <= "0000000000";
    ack_in_progress <= '0';
    rddata_reg <= "00000000000000000000000000000000";
    ep_ecr_portid_int <= "00000";
    ep_ecr_rst_cnt_int <= '0';
    ep_ecr_tx_en_int <= '0';
    ep_ecr_rx_en_int <= '0';
    ep_tscr_en_txts_int <= '0';
    ep_tscr_en_rxts_int <= '0';
    ep_tscr_cs_start_int <= '0';
    ep_tscr_cs_start_int_delay <= '0';
    ep_rfcr_a_runt_int <= '0';
    ep_rfcr_a_giant_int <= '0';
    ep_rfcr_a_hp_int <= '0';
    ep_rfcr_keep_crc_int <= '0';
    ep_rfcr_hpap_int <= "00000000";
    ep_rfcr_mru_int <= "00000000000000";
    ep_vcr0_qmode_int <= "00";
    ep_vcr0_fix_prio_int <= '0';
    ep_vcr0_prio_val_int <= "000";
    ep_vcr0_pvid_int <= "000000000000";
    regs_b.vcr1_vid_wr_o <= '0';
    regs_b.vcr1_value_wr_o <= '0';
    regs_b.pfcr0_mm_addr_wr_o <= '0';
    regs_b.pfcr0_mm_write_wr_o <= '0';
    ep_pfcr0_enable_int <= '0';
    regs_b.pfcr0_mm_data_msb_wr_o <= '0';
    ep_pfcr1_mm_data_lsb_int <= "000000000000";
    ep_tcar_pcp_map_int <= "000000000000000000000000";
    ep_fcr_rxpause_int <= '0';
    ep_fcr_txpause_int <= '0';
    ep_fcr_tx_thr_int <= "00000000";
    ep_fcr_tx_quanta_int <= "0000000000000000";
    ep_mach_int <= "0000000000000000";
    ep_macl_int <= "00000000000000000000000000000000";
    ep_dmcr_en_int <= '0';
    ep_dmcr_n_avg_int <= "000000000000";
    regs_b.dmsr_ps_rdy_load_o <= '0';
    regs_b.mdio_cr_data_wr_o <= '0';
    ep_mdio_cr_addr_int <= "00000000";
    ep_mdio_cr_rw_int <= '0';
    ep_mdio_asr_phyad_int <= "00000000";
    regs_b.dsr_lact_load_o <= '0';
  elsif rising_edge(bus_clock_int) then
-- advance the ACK generator shift register
    ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
    ack_sreg(9) <= '0';
    if (ack_in_progress = '1') then
      if (ack_sreg(0) = '1') then
        ep_ecr_rst_cnt_int <= '0';
        regs_b.vcr1_vid_wr_o <= '0';
        regs_b.vcr1_value_wr_o <= '0';
        regs_b.pfcr0_mm_addr_wr_o <= '0';
        regs_b.pfcr0_mm_write_wr_o <= '0';
        regs_b.pfcr0_mm_data_msb_wr_o <= '0';
        regs_b.dmsr_ps_rdy_load_o <= '0';
        regs_b.mdio_cr_data_wr_o <= '0';
        regs_b.dsr_lact_load_o <= '0';
        ack_in_progress <= '0';
      else
        ep_tscr_cs_start_int <= ep_tscr_cs_start_int_delay;
        ep_tscr_cs_start_int_delay <= '0';
        regs_b.vcr1_vid_wr_o <= '0';
        regs_b.vcr1_value_wr_o <= '0';
        regs_b.pfcr0_mm_addr_wr_o <= '0';
        regs_b.pfcr0_mm_write_wr_o <= '0';
        regs_b.pfcr0_mm_data_msb_wr_o <= '0';
        regs_b.dmsr_ps_rdy_load_o <= '0';
        regs_b.mdio_cr_data_wr_o <= '0';
        regs_b.dsr_lact_load_o <= '0';
      end if;
    else
      if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
        case rwaddr_reg(5) is
        when '0' => 
          case rwaddr_reg(4 downto 0) is
          when "00000" => 
            if (wb_we_i = '1') then
              ep_ecr_portid_int <= wrdata_reg(4 downto 0);
              ep_ecr_rst_cnt_int <= wrdata_reg(5);
              ep_ecr_tx_en_int <= wrdata_reg(6);
              ep_ecr_rx_en_int <= wrdata_reg(7);
            else
              rddata_reg(4 downto 0) <= ep_ecr_portid_int;
              rddata_reg(6) <= ep_ecr_tx_en_int;
              rddata_reg(7) <= ep_ecr_rx_en_int;
              rddata_reg(24) <= regs_b.ecr_feat_vlan_i;
              rddata_reg(25) <= regs_b.ecr_feat_dmtd_i;
              rddata_reg(26) <= regs_b.ecr_feat_ptp_i;
              rddata_reg(27) <= regs_b.ecr_feat_dpi_i;
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(2) <= '1';
            ack_in_progress <= '1';
          when "00001" => 
            if (wb_we_i = '1') then
              ep_tscr_en_txts_int <= wrdata_reg(0);
              ep_tscr_en_rxts_int <= wrdata_reg(1);
              ep_tscr_cs_start_int <= wrdata_reg(2);
              ep_tscr_cs_start_int_delay <= wrdata_reg(2);
            else
              rddata_reg(0) <= ep_tscr_en_txts_int;
              rddata_reg(1) <= ep_tscr_en_rxts_int;
              rddata_reg(3) <= ep_tscr_cs_done_sync1;
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(4) <= '1';
            ack_in_progress <= '1';
          when "00010" => 
            if (wb_we_i = '1') then
              ep_rfcr_a_runt_int <= wrdata_reg(0);
              ep_rfcr_a_giant_int <= wrdata_reg(1);
              ep_rfcr_a_hp_int <= wrdata_reg(2);
              ep_rfcr_keep_crc_int <= wrdata_reg(3);
              ep_rfcr_hpap_int <= wrdata_reg(11 downto 4);
              ep_rfcr_mru_int <= wrdata_reg(25 downto 12);
            else
              rddata_reg(0) <= ep_rfcr_a_runt_int;
              rddata_reg(1) <= ep_rfcr_a_giant_int;
              rddata_reg(2) <= ep_rfcr_a_hp_int;
              rddata_reg(3) <= ep_rfcr_keep_crc_int;
              rddata_reg(11 downto 4) <= ep_rfcr_hpap_int;
              rddata_reg(25 downto 12) <= ep_rfcr_mru_int;
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00011" => 
            if (wb_we_i = '1') then
              ep_vcr0_qmode_int <= wrdata_reg(1 downto 0);
              ep_vcr0_fix_prio_int <= wrdata_reg(2);
              ep_vcr0_prio_val_int <= wrdata_reg(6 downto 4);
              ep_vcr0_pvid_int <= wrdata_reg(27 downto 16);
            else
              rddata_reg(1 downto 0) <= ep_vcr0_qmode_int;
              rddata_reg(2) <= ep_vcr0_fix_prio_int;
              rddata_reg(6 downto 4) <= ep_vcr0_prio_val_int;
              rddata_reg(27 downto 16) <= ep_vcr0_pvid_int;
              rddata_reg(3) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00100" => 
            if (wb_we_i = '1') then
              regs_b.vcr1_vid_wr_o <= '1';
              regs_b.vcr1_value_wr_o <= '1';
            else
              rddata_reg(0) <= 'X';
              rddata_reg(1) <= 'X';
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00101" => 
            if (wb_we_i = '1') then
              regs_b.pfcr0_mm_addr_wr_o <= '1';
              regs_b.pfcr0_mm_write_wr_o <= '1';
              ep_pfcr0_enable_int <= wrdata_reg(7);
              regs_b.pfcr0_mm_data_msb_wr_o <= '1';
            else
              rddata_reg(7) <= ep_pfcr0_enable_int;
              rddata_reg(0) <= 'X';
              rddata_reg(1) <= 'X';
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00110" => 
            if (wb_we_i = '1') then
              ep_pfcr1_mm_data_lsb_int <= wrdata_reg(11 downto 0);
            else
              rddata_reg(11 downto 0) <= ep_pfcr1_mm_data_lsb_int;
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00111" => 
            if (wb_we_i = '1') then
              ep_tcar_pcp_map_int <= wrdata_reg(23 downto 0);
            else
              rddata_reg(23 downto 0) <= ep_tcar_pcp_map_int;
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01000" => 
            if (wb_we_i = '1') then
              ep_fcr_rxpause_int <= wrdata_reg(0);
              ep_fcr_txpause_int <= wrdata_reg(1);
              ep_fcr_tx_thr_int <= wrdata_reg(15 downto 8);
              ep_fcr_tx_quanta_int <= wrdata_reg(31 downto 16);
            else
              rddata_reg(0) <= ep_fcr_rxpause_int;
              rddata_reg(1) <= ep_fcr_txpause_int;
              rddata_reg(15 downto 8) <= ep_fcr_tx_thr_int;
              rddata_reg(31 downto 16) <= ep_fcr_tx_quanta_int;
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01001" => 
            if (wb_we_i = '1') then
              ep_mach_int <= wrdata_reg(15 downto 0);
            else
              rddata_reg(15 downto 0) <= ep_mach_int;
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01010" => 
            if (wb_we_i = '1') then
              ep_macl_int <= wrdata_reg(31 downto 0);
            else
              rddata_reg(31 downto 0) <= ep_macl_int;
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01011" => 
            if (wb_we_i = '1') then
              ep_dmcr_en_int <= wrdata_reg(0);
              ep_dmcr_n_avg_int <= wrdata_reg(27 downto 16);
            else
              rddata_reg(0) <= ep_dmcr_en_int;
              rddata_reg(27 downto 16) <= ep_dmcr_n_avg_int;
              rddata_reg(1) <= 'X';
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01100" => 
            if (wb_we_i = '1') then
              regs_b.dmsr_ps_rdy_load_o <= '1';
            else
              rddata_reg(23 downto 0) <= regs_b.dmsr_ps_val_i;
              rddata_reg(24) <= regs_b.dmsr_ps_rdy_i;
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01101" => 
            if (wb_we_i = '1') then
              regs_b.mdio_cr_data_wr_o <= '1';
              ep_mdio_cr_addr_int <= wrdata_reg(23 downto 16);
              ep_mdio_cr_rw_int <= wrdata_reg(31);
            else
              rddata_reg(23 downto 16) <= ep_mdio_cr_addr_int;
              rddata_reg(31) <= ep_mdio_cr_rw_int;
              rddata_reg(0) <= 'X';
              rddata_reg(1) <= 'X';
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01110" => 
            if (wb_we_i = '1') then
              ep_mdio_asr_phyad_int <= wrdata_reg(23 downto 16);
            else
              rddata_reg(15 downto 0) <= regs_b.mdio_asr_rdata_i;
              rddata_reg(23 downto 16) <= ep_mdio_asr_phyad_int;
              rddata_reg(31) <= regs_b.mdio_asr_ready_i;
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01111" => 
            if (wb_we_i = '1') then
            else
              rddata_reg(31 downto 0) <= "11001010111111101011101010111110";
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10000" => 
            if (wb_we_i = '1') then
              regs_b.dsr_lact_load_o <= '1';
            else
              rddata_reg(0) <= regs_b.dsr_lstatus_i;
              rddata_reg(1) <= regs_b.dsr_lact_i;
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
            end if;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when others =>
-- prevent the slave from hanging the bus on invalid address
            ack_in_progress <= '1';
            ack_sreg(0) <= '1';
          end case;
        when '1' => 
          if (rd_int = '1') then
            ack_sreg(0) <= '1';
          else
            ack_sreg(0) <= '1';
          end if;
          ack_in_progress <= '1';
        when others =>
-- prevent the slave from hanging the bus on invalid address
          ack_in_progress <= '1';
          ack_sreg(0) <= '1';
        end case;
      end if;
    end if;
  end if;
end process;


-- Data output multiplexer process
process (rddata_reg, rwaddr_reg, ep_rmon_ram_rddata_int, wb_addr_i)
begin
  case rwaddr_reg(5) is
  when '1' => 
    wb_data_o(31 downto 0) <= ep_rmon_ram_rddata_int;
  when others =>
    wb_data_o <= rddata_reg;
  end case;
end process;


-- Read & write lines decoder for RAMs
process (wb_addr_i, rd_int, wr_int)
begin
  if (wb_addr_i(5) = '1') then
    ep_rmon_ram_rd_int <= rd_int;
    ep_rmon_ram_wr_int <= wr_int;
  else
    ep_rmon_ram_wr_int <= '0';
    ep_rmon_ram_rd_int <= '0';
  end if;
end process;


-- Port identifier
regs_b.ecr_portid_o <= ep_ecr_portid_int;
-- Reset event counters
process (bus_clock_int, rst_n_i)
begin
  if (rst_n_i = '0') then 
    ep_ecr_rst_cnt_dly0 <= '0';
    regs_b.ecr_rst_cnt_o <= '0';
  elsif rising_edge(bus_clock_int) then
    ep_ecr_rst_cnt_dly0 <= ep_ecr_rst_cnt_int;
    regs_b.ecr_rst_cnt_o <= ep_ecr_rst_cnt_int and (not ep_ecr_rst_cnt_dly0);
  end if;
end process;


-- Transmit path enable
regs_b.ecr_tx_en_o <= ep_ecr_tx_en_int;
-- Receive path enable
regs_b.ecr_rx_en_o <= ep_ecr_rx_en_int;
-- Feature present: VLAN tagging
-- Feature present: DDMTD phase measurement
-- Feature present: IEEE1588 timestamper
-- Feature present: DPI packet classifier
-- Transmit timestamping enable
regs_b.tscr_en_txts_o <= ep_tscr_en_txts_int;
-- Receive timestamping enable
regs_b.tscr_en_rxts_o <= ep_tscr_en_rxts_int;
-- Timestamping counter synchronization start
process (tx_clk_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    regs_b.tscr_cs_start_o <= '0';
    ep_tscr_cs_start_sync0 <= '0';
    ep_tscr_cs_start_sync1 <= '0';
    ep_tscr_cs_start_sync2 <= '0';
  elsif rising_edge(tx_clk_i) then
    ep_tscr_cs_start_sync0 <= ep_tscr_cs_start_int;
    ep_tscr_cs_start_sync1 <= ep_tscr_cs_start_sync0;
    ep_tscr_cs_start_sync2 <= ep_tscr_cs_start_sync1;
    regs_b.tscr_cs_start_o <= ep_tscr_cs_start_sync2 and (not ep_tscr_cs_start_sync1);
  end if;
end process;


-- Timestamping counter synchronization done
-- synchronizer chain for field : Timestamping counter synchronization done (type RO/WO, tx_clk_i -> bus_clock_int)
process (tx_clk_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    ep_tscr_cs_done_sync0 <= '0';
    ep_tscr_cs_done_sync1 <= '0';
  elsif rising_edge(tx_clk_i) then
    ep_tscr_cs_done_sync0 <= regs_b.tscr_cs_done_i;
    ep_tscr_cs_done_sync1 <= ep_tscr_cs_done_sync0;
  end if;
end process;


-- RX accept runts
regs_b.rfcr_a_runt_o <= ep_rfcr_a_runt_int;
-- RX accept giants
regs_b.rfcr_a_giant_o <= ep_rfcr_a_giant_int;
-- RX accept HP
regs_b.rfcr_a_hp_o <= ep_rfcr_a_hp_int;
-- RX keep CRC
regs_b.rfcr_keep_crc_o <= ep_rfcr_keep_crc_int;
-- RX Fiter HP Priorities
regs_b.rfcr_hpap_o <= ep_rfcr_hpap_int;
-- Maximum receive unit (MRU)
regs_b.rfcr_mru_o <= ep_rfcr_mru_int;
-- RX 802.1q port mode
regs_b.vcr0_qmode_o <= ep_vcr0_qmode_int;
-- Force 802.1q priority
regs_b.vcr0_fix_prio_o <= ep_vcr0_fix_prio_int;
-- Port-assigned 802.1q priority
regs_b.vcr0_prio_val_o <= ep_vcr0_prio_val_int;
-- Port-assigned VID
regs_b.vcr0_pvid_o <= ep_vcr0_pvid_int;
-- Egress untagged set bitmap VID
-- pass-through field: Egress untagged set bitmap VID in register: VLAN Control Register 1
regs_b.vcr1_vid_o <= wrdata_reg(11 downto 0);
-- Egress untagged set bitmap value
-- pass-through field: Egress untagged set bitmap value in register: VLAN Control Register 1
regs_b.vcr1_value_o <= wrdata_reg(12);
-- Microcode Memory Address
-- pass-through field: Microcode Memory Address in register: Packet Filter Control Register 0
regs_b.pfcr0_mm_addr_o <= wrdata_reg(5 downto 0);
-- Microcode Memory Write Enable
-- pass-through field: Microcode Memory Write Enable in register: Packet Filter Control Register 0
regs_b.pfcr0_mm_write_o <= wrdata_reg(6);
-- Packet Filter Enable
regs_b.pfcr0_enable_o <= ep_pfcr0_enable_int;
-- Microcode Memory Data (24 MSBs)
-- pass-through field: Microcode Memory Data (24 MSBs) in register: Packet Filter Control Register 0
regs_b.pfcr0_mm_data_msb_o <= wrdata_reg(31 downto 8);
-- Microcode Memory Data (12 LSBs)
regs_b.pfcr1_mm_data_lsb_o <= ep_pfcr1_mm_data_lsb_int;
-- 802.1Q priority tag to Traffic Class map
regs_b.tcar_pcp_map_o <= ep_tcar_pcp_map_int;
-- RX Pause enable
regs_b.fcr_rxpause_o <= ep_fcr_rxpause_int;
-- TX Pause enable
regs_b.fcr_txpause_o <= ep_fcr_txpause_int;
-- TX pause threshold
regs_b.fcr_tx_thr_o <= ep_fcr_tx_thr_int;
-- TX pause quanta
regs_b.fcr_tx_quanta_o <= ep_fcr_tx_quanta_int;
-- MAC Address
regs_b.mach_o <= ep_mach_int;
-- MAC Address
regs_b.macl_o <= ep_macl_int;
-- DMTD Phase measurement enable
regs_b.dmcr_en_o <= ep_dmcr_en_int;
-- DMTD averaging samples
regs_b.dmcr_n_avg_o <= ep_dmcr_n_avg_int;
-- DMTD Phase shift value
-- DMTD Phase shift value ready
regs_b.dmsr_ps_rdy_o <= wrdata_reg(24);
-- MDIO Register Value
-- pass-through field: MDIO Register Value in register: MDIO Control Register
regs_b.mdio_cr_data_o <= wrdata_reg(15 downto 0);
-- MDIO Register Address
regs_b.mdio_cr_addr_o <= ep_mdio_cr_addr_int;
-- MDIO Read/Write select
regs_b.mdio_cr_rw_o <= ep_mdio_cr_rw_int;
-- MDIO Read Value
-- MDIO PHY Address
regs_b.mdio_asr_phyad_o <= ep_mdio_asr_phyad_int;
-- MDIO Ready
-- Link status
-- Link activity
regs_b.dsr_lact_o <= wrdata_reg(1);
-- extra code for reg/fifo/mem: Event counters memory
-- RAM block instantiation for memory: Event counters memory
ep_rmon_ram_raminst : wbgen2_dpssram
  generic map (
    g_data_width         => 32,
    g_size               => 32,
    g_addr_width         => 5,
    g_dual_clock         => false,
    g_use_bwsel          => false
  )
  port map (
    clk_a_i              => bus_clock_int,
    clk_b_i              => bus_clock_int,
    addr_b_i             => ep_rmon_ram_addr_i,
    addr_a_i             => rwaddr_reg(4 downto 0),
    data_b_o             => ep_rmon_ram_data_o,
    rd_b_i               => ep_rmon_ram_rd_i,
    data_b_i             => ep_rmon_ram_data_i,
    wr_b_i               => ep_rmon_ram_wr_i,
    bwsel_b_i            => allones(3 downto 0),
    data_a_o             => ep_rmon_ram_rddata_int(31 downto 0),
    rd_a_i               => ep_rmon_ram_rd_int,
    data_a_i             => wrdata_reg(31 downto 0),
    wr_a_i               => ep_rmon_ram_wr_int,
    bwsel_a_i            => allones(3 downto 0)
  );

rwaddr_reg <= wb_addr_i;
-- ACK signal generation. Just pass the LSB of ACK counter.
wb_ack_o <= ack_sreg(0);
end syn;
