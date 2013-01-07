-------------------------------------------------------------------------------
-- Title      : BuTiS clock generator
-- Project    : White Rabbit generator
-------------------------------------------------------------------------------
-- File       : BuTiS_clock_generator.vhd
-- Author     : Peter Schakel
-- Company    : KVI
-- Created    : 2012-09-11
-- Last update: 2012-09-28
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description:
--
-- Generates BuTis clock (T0 and c2) from white rabbit clock signals
-- Input White Rabbit 125MHz clock and 1 second PPS pulse.
-- A 200MHz clock (BuTis_C2) is generated (Altera PLL) with the White Rabbit 125MHz clock as reference.
-- On every 2000 clock cycles a BuTis_T0 signals is generated (100kHz). This is synchronized tot the PPS-pulse.
-- A timestamp (64 bits lineair counter) is generated and sent as serial burst on each BuTis_T0 signal.
-- The serial burst has 4 clock cycles per bit. The timestamp is extended with a Reed Solomon code for Forward Error Correction.
-- The timestamp can be set with the Whishbone Bus. This value is activated on the next PPS pulse. See TimestampEncoder.vhd.
-- The Whishbone Bus addresses are described in the wb_BuTiSclock documentation.
-- 
-- Generics
--
-- Inputs
--     clk_sys_i : 125MHz Whishbone bus clock
--     scanclk_i : clock for reconfiguring PLL phase (less than 100MHz)
--     rst_n_i : reset: low active
--     gpio_slave_i : Record with Whishbone Bus signals
--     wr_clock_i : White Rabbit 125MHz clock
--     wr_PPSpulse_i : White Rabbit PPS pulse
--
-- Outputs
--     gpio_slave_o : Record with Whishbone Bus signals
--     BuTis_C2_o : BuTiS 200 MHz clock
--     BuTis_T0_o : BuTis T0 100kHz signal
--     BuTis_T0_timestamp_o : BuTis T0 100kHz signal with serial encoded 64-bits timestamp
--     error_o : error detected: wr_PPSpulse_i signal period is not exactly 1 second
--
-- Components
--     wb_BuTiSclock : module with interface to Wishbone bus, generated by wbgen2
--     PLL125MHz200MHz : Altera PLL for generating 200MHz from 125 MHz
--     TimestampEncoder : Encoder for 64-bits timestamp into serial burst
--
--
-------------------------------------------------------------------------------
-- Copyright (c) 2012 KVI / Peter Schakel
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.std_logic_arith.all ;

LIBRARY altera;
USE altera.altera_primitives_components.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

library work;
use work.genram_pkg.all;
use work.wishbone_pkg.all;

entity BuTiS_clock_generator is
  port(
		clk_sys_i                              : in std_logic;
		scanclk_i                              : in std_logic;
		rst_n_i                                : in std_logic;
		gpio_slave_i                           : in t_wishbone_slave_in;
		gpio_slave_o                           : out t_wishbone_slave_out;
		wr_clock_i                             : in  std_logic;
		wr_PPSpulse_i                          : in  std_logic;
		BuTis_C2_ph0_o                         : out std_logic;
		BuTis_C2_o                             : out std_logic;
		BuTis_T0_o                             : out std_logic;
		BuTis_T0_timestamp_o                   : out std_logic;
		error_o                                : out std_logic);
end BuTiS_clock_generator;

architecture rtl of BuTiS_clock_generator is

component wb_BuTiSclock is
  port (
-- 
    rst_n_i                                  : in     std_logic;
-- 
    wb_clk_i                                 : in     std_logic;
-- 
    wb_addr_i                                : in     std_logic_vector(1 downto 0);
-- 
    wb_data_i                                : in     std_logic_vector(31 downto 0);
-- 
    wb_data_o                                : out    std_logic_vector(31 downto 0);
-- 
    wb_cyc_i                                 : in     std_logic;
-- 
    wb_sel_i                                 : in     std_logic_vector(3 downto 0);
-- 
    wb_stb_i                                 : in     std_logic;
-- 
    wb_we_i                                  : in     std_logic;
-- 
    wb_ack_o                                 : out    std_logic;
-- Port for std_logic_vector field: 'Low Word' in reg: 'TimeStamp data Low word'
    wbbutis_timestamp_lw_o                   : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High Word' in reg: 'TimeStamp data High word'
    wbbutis_timestamp_hw_o                   : out    std_logic_vector(31 downto 0);
-- Ports for PASS_THROUGH field: 'Set on next PPS' in reg: 'BuTis clock generator control'
    wbbutis_control_set_o                    : out    std_logic_vector(0 downto 0);
    wbbutis_control_set_wr_o                 : out    std_logic;
-- Ports for PASS_THROUGH field: 'Re-synchronize' in reg: 'BuTis clock generator control'
    wbbutis_control_sync_o                   : out    std_logic_vector(0 downto 0);
    wbbutis_control_sync_wr_o                : out    std_logic;
-- Ports for PASS_THROUGH field: 'reset phase-PLL' in reg: 'BuTis clock generator control'
    wbbutis_control_reset_o                  : out    std_logic_vector(0 downto 0);
    wbbutis_control_reset_wr_o               : out    std_logic;
-- Port for std_logic_vector field: 'unused' in reg: 'BuTis clock generator control'
    wbbutis_control_unused_o                 : out    std_logic_vector(4 downto 0);
-- Port for std_logic_vector field: 'PLLphase' in reg: 'BuTis clock generator control'
    wbbutis_control_phase_o                  : out    std_logic_vector(7 downto 0);
-- Port for std_logic_vector field: 'timestamp set busy' in reg: 'BuTis clock generator Status'
    wbbutis_status_set_i                     : in     std_logic_vector(0 downto 0);
-- Port for std_logic_vector field: 'Phase of the PPS' in reg: 'BuTis clock generator Status'
    wbbutis_status_ppsphase_i                : in     std_logic_vector(0 downto 0)
  );
end component;

component PLL125MHz200MHz IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END component;

  
  component PLL200MHzPhaseAdjust IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		phasecounterselect		: IN STD_LOGIC_VECTOR (3 DOWNTO 0) :=  (OTHERS => '0');
		phasestep		: IN STD_LOGIC  := '0';
		phaseupdown		: IN STD_LOGIC  := '0';
		scanclk		: IN STD_LOGIC  := '1';
		c0		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC ;
		phasedone		: OUT STD_LOGIC 
	);
END component;
  
  component PLL_setphase is
	port(
		clock_i                                : in std_logic;
		reset_i                                : in std_logic;
		enable_i                               : in std_logic;
		phase_i                                : in std_logic_vector(7 downto 0);
		phasedone_i                            : in std_logic;
		phasestep_o                            : out std_logic;
		phaseupdown_o                          : out std_logic
   );
  end component;

  component TimestampEncoder is
  generic(
		g_timestampbytes                         : integer := 8;
		g_clockcyclesperbit                      : integer := 4;
		g_RScodewords                            : integer := 4;
		g_BuTis_ratio                            : integer := 2000);
  port(
		BuTis_C2_i                               : in  std_logic;
		BuTis_T0_i                               : in  std_logic;
		reset_i                                  : in  std_logic;
		timestamp_i                              : in  std_logic_vector(g_timestampbytes*8-1 downto 0);
		settimestamp_i                           : in  std_logic;
		serial_o                                 : out std_logic;
		error_o                                  : out std_logic);
  end component;

  component clockdivider_sync is
  generic(
    g_clockddivisor                          : integer := 5);
  port(
    clock_i                                  : in  std_logic;
    reset_i                                  : in  std_logic;
    sync_i                                   : in  std_logic;
    divclock_o                               : out std_logic;
    error_o                                  : out std_logic);
  end component;

  component posedge_to_pulse is
	port (
		clock_in     : in  std_logic;
		clock_out     : in  std_logic;
		en_clk    : in  std_logic;
		signal_in : in  std_logic;
		pulse     : out std_logic
	);
  end component;
  
  constant PPSsequences_c : natural := 9;
  constant PPScheckbits_c : natural := 5;
  type checkPPSsequence_type is array(0 to PPSsequences_c-1) of std_logic_vector(PPScheckbits_c-1 downto 0);
  constant checkPPSsequence_c : checkPPSsequence_type := (
			"10000",
			"10000",
			"01000",
			"00100", --  01100
			"00100",
			"00010",
			"00010",
			"00001",
			"00000");
-- for check on 8 bits:			
--			"10000000",
--			"10000000",
--			"01000000",
--			"00100000", --  01100000
--			"00100000",
--			"00010000",
--			"00010000",
--			"00001000",
--			"00000100",
--			"00000100",
--			"00000010",
--			"00000001", -- 00000011
--			"00000001",
--			"00000000");

  signal reset_s                               : std_logic := '0';
  signal wbbutis_timestamp_lw_s                : std_logic_vector(31 downto 0);
  signal wbbutis_timestamp_hw_s                : std_logic_vector(31 downto 0);
  signal wbbutis_control_set_s                 : std_logic_vector(0 downto 0);
  signal wbbutis_control_set_wr_s              : std_logic;
  signal wbbutis_control_sync_s                : std_logic_vector(0 downto 0);
  signal wbbutis_control_sync_wr_s             : std_logic;
  signal wbbutis_control_reset_s               : std_logic_vector(0 downto 0);
  signal wbbutis_control_reset_wr_s            : std_logic;
  signal wbbutis_control_phase_s               : std_logic_vector(7 downto 0);
  signal wbbutis_control_phase_sync_s          : std_logic_vector(7 downto 0);
  signal wbbutis_status_set_s                  : std_logic_vector(0 downto 0);  
  signal wbbutis_status_ppsphase_s             : std_logic_vector(0 downto 0);
  signal phasecounterselect_S                  : std_logic_vector(3 downto 0) := (others => '0');
  signal phasestep_S                           : std_logic := '0';
  signal phaseupdown_S                         : std_logic := '0';
  signal phasedone_s                           : std_logic := '0'; 
  signal wr_PPSpulse_s                         : std_logic := '0';
  signal BuTiS_C2_s                            : std_logic := '0';
  signal BuTiS_C2_ph0_s                        : std_logic := '0';
  
  signal BuTis_T0_s                            : std_logic := '0';
  signal PPS_error_s                           : std_logic := '0';
  signal encoder_error_s                       : std_logic := '0';
  signal settimestamp_s                        : std_logic := '0';
  signal resync_s                              : std_logic := '0';
  signal PLL_locked_s                          : std_logic := '0';
  signal phasePLL_locked_s                     : std_logic := '0';
  signal setphase_enable_S                     : std_logic := '0';
  signal reset_phasePLL_s                      : std_logic := '0';
  signal reset_phasePLL_cmd_s                  : std_logic := '0';
  signal reset_phasePLL_cmdsync_s              : std_logic := '0';
  
  signal clock500MHz_s                         : std_logic := '0';  
  signal clock500MHz_counter_s                 : std_logic_vector(4 downto 0) := (others => '0');
  signal clock200MHzeven_s                     : std_logic := '0';  
  signal clock200MHzodd_s                      : std_logic := '0';
  signal clock200MHz_s                         : std_logic := '0';
  signal syncpulse_s                           : std_logic := '0';
  signal syncpulse1_s                          : std_logic := '0';
  signal syncpulse2_s                          : std_logic := '0';
--  signal wr_clockdiv5_s                        : std_logic := '0';
--  signal wr_clockdiv5clk_s                     : std_logic := '0';
--  signal wr_clockdiv5clks_s                    : std_logic_vector(3 downto 0);
  signal counter_10us_s                        : integer range 0 to 2000 := 0;  
  signal counter_T0_s                          : integer range 0 to 100000 := 0;

  
  signal PPS_history_s                         : std_logic_vector(PPScheckbits_c-1 downto 0);
  signal PPS_history_sync_s                    : std_logic_vector(PPScheckbits_c-1 downto 0);
  signal PPShistoryindex_s                     : integer range 0 to PPSsequences_c := 0;  
  signal PPSseqerror_s                         : std_logic := '0';
  signal force_resync_s                        : std_logic := '0';
  signal PPSseqerror_sync1_s                   : std_logic := '0';
  signal PPSseqerror_sync2_s                   : std_logic := '0';
  signal wr_PPSpulse_ph0_s                     : std_logic := '0';
  signal wr_PPSpulse_C0_s                      : std_logic := '0';
  signal wr_PPSpulse_C0_prev_s                 : std_logic := '0';

  signal pulseextend_s                         : integer range 0 to 7;
  signal pulseextendcount_s                    : integer range 0 to 7;

attribute keep: boolean;
attribute keep of BuTiS_C2_s: signal is true;
		
		
  begin

error_o <= '1' when (encoder_error_s='1') or (PPS_error_s='1') or (PPSseqerror_sync2_s='1') else '0';
reset_s <= not rst_n_i;
BuTis_T0_o <= BuTis_T0_s;
BuTis_C2_o <= BuTiS_C2_s;
BuTis_C2_ph0_o <= BuTiS_C2_ph0_s;

wb_BuTiSclock1: wb_BuTiSclock port map(
		rst_n_i => rst_n_i,
		wb_clk_i => clk_sys_i,
		wb_addr_i => gpio_slave_i.adr(3 downto 2),
		wb_data_i => gpio_slave_i.dat,
		wb_data_o => gpio_slave_o.dat,
		wb_cyc_i => gpio_slave_i.cyc,
		wb_sel_i => gpio_slave_i.sel,
		wb_stb_i => gpio_slave_i.stb,
		wb_we_i => gpio_slave_i.we,
		wb_ack_o => gpio_slave_o.ack ,
		wbbutis_timestamp_lw_o => wbbutis_timestamp_lw_s,
		wbbutis_timestamp_hw_o => wbbutis_timestamp_hw_s,
		wbbutis_control_set_o => wbbutis_control_set_s,
		wbbutis_control_set_wr_o => wbbutis_control_set_wr_s,
		wbbutis_control_sync_o => wbbutis_control_sync_s,
		wbbutis_control_sync_wr_o => wbbutis_control_sync_wr_s,
		wbbutis_control_reset_o => wbbutis_control_reset_s,
		wbbutis_control_reset_wr_o => wbbutis_control_reset_wr_s,
		wbbutis_control_unused_o => open,
		wbbutis_control_phase_o => wbbutis_control_phase_s,
		wbbutis_status_set_i => wbbutis_status_set_s,
		wbbutis_status_ppsphase_i => wbbutis_status_ppsphase_s);

--wr_clockdiv5clks_s(3 downto 1) <= (others => '0');
--altclkctrl1: altclkctrl
--	generic map(
--		clock_type => "AUTO",
--		intended_device_family => "unused",
--		ena_register_mode => "falling edge",
--		implement_in_les => "OFF",
--		number_of_clocks => 4,
--		use_glitch_free_switch_over_implementation => "OFF",
--		width_clkselect => 2,
--		lpm_hint => "UNUSED",
--		lpm_type => "altclkctrl")
--	port map(
--		clkselect => (others => '0'),
--		ena => '1',
--		inclk=> wr_clockdiv5clks_s,
--		outclk => wr_clockdiv5clk_s);
--clockdivider_sync1: clockdivider_sync port map(
--		clock_i => wr_clock_i,
--		reset_i => reset_s,
--		sync_i => wr_PPSpulse_i,
--		divclock_o => wr_clockdiv5_s,
--		error_o => syncerror_s);
--globalclockdiv5: global port map(
--		a_in => wr_clockdiv5_s,
--		a_out => wr_clockdiv5clks_s(0));

resync_s <= '1' when ((wbbutis_control_sync_s(0)='1') and (wbbutis_control_sync_wr_s='1')) 
		or (rst_n_i='0') 
		or (force_resync_s='1')
	else '0';

PLL125MHz200MHz1: PLL125MHz200MHz port map(
		areset => resync_s,
		inclk0 => wr_clock_i,
		c0 => BuTiS_C2_ph0_s,
		locked => PLL_locked_s);


PLL200MHzPhaseAdjust1: PLL200MHzPhaseAdjust port map(
		areset => reset_phasePLL_s,
		inclk0 => BuTiS_C2_ph0_s,
		phasecounterselect => phasecounterselect_S,
		phasestep => phasestep_S,
		phaseupdown => phaseupdown_S,
		scanclk => scanclk_i,
		c0 => BuTiS_C2_s,
		locked => phasePLL_locked_s,
		phasedone => phasedone_s);

		
posedge_to_pulse1: posedge_to_pulse port map(
		clock_in => clk_sys_i,
		clock_out => scanclk_i,
		en_clk => '1',
		signal_in => reset_phasePLL_cmd_s,
		pulse => reset_phasePLL_cmdsync_s);

-- process to reset,enable PLL_setphase module with the right signals, clock on scanclk_i
reset_phase_process: process(scanclk_i) -- process 
begin
	if rising_edge(scanclk_i) then
		if (reset_s='1') or (reset_phasePLL_cmdsync_s='1') then
			reset_phasePLL_s <= '1';
		else
			reset_phasePLL_s <= '0';
		end if;
		wbbutis_control_phase_sync_s <= wbbutis_control_phase_s;
		if (PLL_locked_s='1') and (phasePLL_locked_s='1') then
			setphase_enable_S <= '1';
		else
			setphase_enable_S <= '0';
		end if;
	end if;
end process;	
	
PLL_setphase1: PLL_setphase port map(
		clock_i => scanclk_i,
		reset_i => reset_phasePLL_s,
		enable_i => setphase_enable_S,
		phase_i => wbbutis_control_phase_sync_s,
		phasedone_i => phasedone_s,
		phasestep_o => phasestep_S,
		phaseupdown_o => phaseupdown_S);

  
--syncpulse_s <= wr_PPSpulse_i;
--process(clock500MHz_s)
--begin
--	if rising_edge(clock500MHz_s) then
--		if syncpulse2_s='0' and syncpulse1_s='1' then
--			if clock500MHz_counter_s/="00001" then
--				syncerror_s <= '1';
--			else
--				syncerror_s <= '0';
--			end if;
--			clock500MHz_counter_s <= "00010";
--		elsif clock500MHz_counter_s(4)='1' and clock500MHz_counter_s(1 downto 0)="11" then
--			clock500MHz_counter_s <= "00000";
--		else
--			clock500MHz_counter_s <= clock500MHz_counter_s+1;
--		end if;
--		syncpulse2_s <= syncpulse1_s;
--		syncpulse1_s <= syncpulse_s;
--	end if;
--end process;
--process(clock500MHz_s)
--begin
--	if rising_edge(clock500MHz_s) then
--		if (clock500MHz_counter_s="00100") or (clock500MHz_counter_s="01001") 
--				or (clock500MHz_counter_s="01110") or (clock500MHz_counter_s="10011") then 
--			clock200MHzeven_s <= '1';
--		else
--			clock200MHzeven_s <= '0';
--		end if;
--	end if;
--end process;
--process(clock500MHz_s)
--begin
--	if falling_edge(clock500MHz_s) then
--		if (clock500MHz_counter_s="00010") or (clock500MHz_counter_s="00111") 
--				or (clock500MHz_counter_s="01100") or (clock500MHz_counter_s="10001") then 
--			clock200MHzodd_s <= '1';
--		else
--			clock200MHzodd_s <= '0';
--		end if;
--	end if;
--end process;
--clock200MHz_s <= '1' when clock200MHzeven_s='1' or clock200MHzodd_s='1' else '0';
--globalclock200MHz: global port map(
--		a_in => clock200MHz_s,
--		a_out => BuTiS_C2_s);

-- process for initialize setting of new timestamp on the next wr_PPSpulse
timestampset_process: process(clk_sys_i,settimestamp_s)
begin
	if settimestamp_s='1' then
		wbbutis_status_set_s(0) <= '0';
	elsif rising_edge(clk_sys_i) then
		if wbbutis_control_set_wr_s='1' and wbbutis_control_set_s(0)='1' then
			wbbutis_status_set_s(0) <= '1';
		end if;
	end if;
end process;

-- process for checking wr_PPSulse period and for generating BuTis_T0 with the right phase
PPScheck_process : process(BuTiS_C2_s)
begin
	if rising_edge(BuTiS_C2_s) then
		if reset_s='1' then
			wr_PPSpulse_s <= '0';
			PPS_error_s <= '0';
			counter_10us_s <= 0;
			counter_T0_s <= 0;
			wbbutis_status_ppsphase_s(0) <= '0';
			settimestamp_s <= '0';
			BuTis_T0_s <= '0';
		else
			if counter_10us_s=1995 then -- or 1996 ????????
				BuTis_T0_s <= '1';
			else
				BuTis_T0_s <= '0';
			end if;
			if wr_PPSpulse_C0_s='1' and wr_PPSpulse_C0_prev_s='0' then
				if counter_T0_s/=99999 or counter_10us_s/=1999 then
					PPS_error_s <= '1';
				end if;
				PPS_error_s <= '0';
				counter_10us_s <= 0;
				counter_T0_s <= 0;
				wbbutis_status_ppsphase_s(0) <= '0';
				if wbbutis_status_set_s(0)='1' then
					settimestamp_s <= '1';
				else
					settimestamp_s <= '0';
				end if;
			else
				settimestamp_s <= '0';
				if counter_10us_s<1999 then
					counter_10us_s <= counter_10us_s+1;
				else
					counter_10us_s <= 0;
					if counter_T0_s<99999 then
						counter_T0_s <= counter_T0_s+1;
						if counter_T0_s=49999 then
							wbbutis_status_ppsphase_s(0) <= '1';
						end if;
					else
						PPS_error_s <= '1';
						counter_T0_s <= 0;
						wbbutis_status_ppsphase_s(0) <= '0';
					end if;
				end if;
			end if;
			wr_PPSpulse_C0_prev_s <= wr_PPSpulse_C0_s;
			wr_PPSpulse_C0_s <= wr_PPSpulse_ph0_s;
		end if;
	end if;
end process;

		
TimestampEncoder1: TimestampEncoder port map(
		BuTis_C2_i => BuTiS_C2_s,
		BuTis_T0_i => BuTis_T0_s,
		reset_i => reset_s,
		timestamp_i => wbbutis_timestamp_hw_s & wbbutis_timestamp_lw_s,
		settimestamp_i => settimestamp_s,
		serial_o => BuTis_T0_timestamp_o,
		error_o => encoder_error_s);

-- process to make a signal with several bits to check the phase between wr_clock_i and BuTiS_C2_ph0_s
-- the wr_PPSpulse_i is combined with its delayed data
PPSshift_process : process(wr_clock_i)
begin
	if rising_edge(wr_clock_i) then
		PPS_history_s <= wr_PPSpulse_i & PPS_history_s(PPS_history_s'left downto 1);
	end if;
end process;

-- Extend reset pulse for PLL with different width each time to prevent synchronized PLL reset
-- That could result that the PLL always starts with the same (faulty) phase
forceresync_process : process(clk_sys_i)
begin
	if rising_edge(clk_sys_i) then
		if (PPSseqerror_sync1_s='1') and (PPSseqerror_sync2_s='0') then
			force_resync_s <= '1';
			pulseextendcount_s <= pulseextend_s;
			if pulseextend_s<7 then
				pulseextend_s <= pulseextend_s+1;
			else
				pulseextend_s <= 1;
			end if;
		elsif pulseextendcount_s=0 then
			force_resync_s <= '0';
		else
			pulseextendcount_s <= pulseextendcount_s-1;
			force_resync_s <= '1';
		end if;
		PPSseqerror_sync1_s <= PPSseqerror_s;
		PPSseqerror_sync2_s <= PPSseqerror_sync1_s;
	end if;
end process;

-- process to check the phase between 200MHz BuTiS_C2_ph0_s and 125MHz wr_clock_i with the 1 second wr_PPSpulse
-- the wr_PPSpulse is combined with its delayed signal and this is reclock with the BuTiS_C2_ph0_s clock (PPS_history_sync_s)
-- This signal should have a special sequence. If not then the phase is wrong and the PLL is resetted to try again find the right phase.
-- The sequence is defined in checkPPSsequence_c. The timing for this signal is tight.
checkPPSshift_process : process(BuTiS_C2_ph0_s) 
variable zerocounter_v : integer range 0 to 15 := 0;
variable error_v : std_logic;
begin
	if rising_edge(BuTiS_C2_ph0_s) then
		PPS_history_sync_s <= PPS_history_s;
		wr_PPSpulse_ph0_s <= PPS_history_s(PPS_history_s'left);
		if PLL_locked_s='1' then
			if PPShistoryindex_s=0 then
					if (PPS_history_sync_s=checkPPSsequence_c(0))then
						zerocounter_v := 0;
						PPSseqerror_s <= '0';
						PPShistoryindex_s <= PPShistoryindex_s+1;
					elsif PPS_history_sync_s/="0000000" then
						zerocounter_v := 0;
						PPSseqerror_s <= '1';
						PPShistoryindex_s <= 0;
					else
						if zerocounter_v<15 then
							zerocounter_v := zerocounter_v+1;
						else
							PPSseqerror_s <= '0';
						end if;
					end if;
			else
				error_v := '0';
				for i in 0 to PPScheckbits_c-1 loop
					if (PPS_history_sync_s(i)='1') and (checkPPSsequence_c(PPShistoryindex_s)(i)='0') then 
						error_v := '1';
					end if;
				end loop;
				if error_v='1' then
					PPSseqerror_s <= '1';
					PPShistoryindex_s <= 0;
				else
					if PPShistoryindex_s<PPSsequences_c-1 then
						PPShistoryindex_s <= PPShistoryindex_s+1;
					else
						PPShistoryindex_s <= 0;
					end if;
				end if;
			end if;
		else -- PLL not locked
			zerocounter_v := 0;
			PPSseqerror_s <= '0';
			PPShistoryindex_s <= 0;
		end if;
	end if;
end process;


  
end;
