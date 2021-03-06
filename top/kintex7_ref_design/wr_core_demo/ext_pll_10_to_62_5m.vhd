-- -- file: ext_pll_10_to_62_5m.vhd
-- 
-- (c) Copyright 2008 - 2011 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
--
------------------------------------------------------------------------------
-- "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
-- "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
------------------------------------------------------------------------------
-- CLK_OUT1____62.500______0.000______50.0______659.593____883.386
--
------------------------------------------------------------------------------
-- "Input Clock   Freq (MHz)    Input Jitter (UI)"
------------------------------------------------------------------------------
-- __primary__________10.000____________0.005

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ext_pll_10_to_62_5m is
port
 (-- Clock in ports
  clk_ext_i           : in     std_logic;
  -- Clock out ports
  clk_ext_mul_o          : out    std_logic;
  -- Status and control signals
  rst_a_i             : in     std_logic;
  locked_o            : out    std_logic
 );
end ext_pll_10_to_62_5m;

architecture xilinx of ext_pll_10_to_62_5m is
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of xilinx : architecture is "ext_pll_10_to_62_5m,clk_wiz_v3_6,{component_name=ext_pll_10_to_62_5m,use_phase_alignment=false,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,feedback_source=FDBK_AUTO,primtype_sel=MMCM_ADV,num_out_clk=1,clkin1_period=100.000,clkin2_period=10.0,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,use_status=false,use_freeze=false,use_clk_valid=false,feedback_type=SINGLE,clock_mgr_type=MANUAL,manual_override=false}";
  -- Input clock buffering / unused connectors
  signal clkin1            : std_logic;
  -- Output clock buffering
  signal clkfb             : std_logic;
  signal clk0              : std_logic;
--  signal clkfbout          : std_logic;
--  signal locked_internal   : std_logic;
--  signal status_internal   : std_logic_vector(7 downto 0);
begin


  -- Input buffering
  --------------------------------------
  clkin1 <= clk_ext_i;


  -- Clocking primitive
  --------------------------------------
 
  -- Instantiation of the MMCM primitive
  --    * Unused inputs are tied off
  --    * Unused outputs are labeled unused
  mmcm_adv_inst : MMCME2_ADV
  generic map
   (BANDWIDTH            => "OPTIMIZED",
    CLKOUT4_CASCADE      => FALSE,
    COMPENSATION         => "ZHOLD",
    STARTUP_WAIT         => FALSE,
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT_F      => 62.500,
    CLKFBOUT_PHASE       => 0.000,
    CLKFBOUT_USE_FINE_PS => FALSE,
    CLKOUT0_DIVIDE_F     => 10.000,
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT0_USE_FINE_PS  => FALSE,
    CLKIN1_PERIOD        => 100.000,
    REF_JITTER1          => 0.005)
  port map
    -- Output clocks
   (CLKFBOUT            => clkfb,
    CLKFBOUTB           => open,
    CLKOUT0             => clk0,
    CLKOUT0B            => open,
    CLKOUT1             => open,
    CLKOUT1B            => open,
    CLKOUT2             => open,
    CLKOUT2B            => open,
    CLKOUT3             => open,
    CLKOUT3B            => open,
    CLKOUT4             => open,
    CLKOUT5             => open,
    CLKOUT6             => open,
    -- Input clock control
    CLKFBIN             => clkfb,
    CLKIN1              => clkin1,
    CLKIN2              => '0',
    -- Tied to always select the primary input clock
    CLKINSEL            => '1',
    -- Ports for dynamic reconfiguration
    DADDR               => (others => '0'),
    DCLK                => '0',
    DEN                 => '0',
    DI                  => (others => '0'),
    DO                  => open,
    DRDY                => open,
    DWE                 => '0',
    -- Ports for dynamic phase shift
    PSCLK               => '0',
    PSEN                => '0',
    PSINCDEC            => '0',
    PSDONE              => open,
    -- Other control and status signals
    LOCKED              => locked_o,
    CLKINSTOPPED        => open,
    CLKFBSTOPPED        => open,
    PWRDWN              => '0',
    RST                 => rst_a_i);



  clkout1_buf : BUFG
  port map
   (O   => clk_ext_mul_o,
    I   => clk0);



end xilinx;
