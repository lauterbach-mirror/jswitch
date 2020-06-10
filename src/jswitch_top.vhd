-- The MIT License
--
-- Copyright (c) 2018 Lauterbach GmbH, Ingo Rohloff
--
-- Permission is hereby granted, free of charge,
-- to any person obtaining a copy of this software and
-- associated documentation files (the "Software"), to
-- deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify,
-- merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom
-- the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice
-- shall be included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
-- ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-- altera message_off 10036
-- altera message_off 10037

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.jswitch_config_pkg.all;
use work.jswitch_bus_pkg.all;
use work.jswitch_internal_pkg.all;

entity jswitch_top is
	port (
		iPinTrst_n : in STD_LOGIC; -- (optional)
		iPinTck    : in STD_LOGIC;
		iPinTms    : in STD_LOGIC;
		iPinTdi    : in STD_LOGIC;
		oPinTdo    : out STD_LOGIC;

		oSlvTrst_n : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTck    : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTms    : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTdi    : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		iSlvTdo    : in  STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);

		oBusMOSI : out tJswitchBusMOSI;
		iBusMISO :  in tJswitchBusMISO := cJswitchBusMISORst
	);
end jswitch_top;

architecture rtl of jswitch_top is

signal wJswitchState  : tJswitchState;
signal rfJswitchStateIsRti : STD_LOGIC;
signal rfJswitchStateIsCapDR : STD_LOGIC;
signal rfJswitchStateIsCapIR : STD_LOGIC;
signal rfJswitchStateIsShift : STD_LOGIC;

signal wJswitchIR     : tJswitchIR;

signal wJswitchTdo : STD_LOGIC;
signal wJswitchTdoOe : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 0);
signal wToJtagDR   : STD_LOGIC_VECTOR(31 downto 0);
signal wFromJtagDR : STD_LOGIC_VECTOR(31 downto 0);

signal wBusMOSI : tJswitchBusMOSI;
signal wBusMISO : tJswitchBusMISO;
signal wBusMISOArray : tJswitchBusMISOArray(1 downto 0);

signal wRegs   : tJswitchRegs;

signal rfSlvSel     : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1) := (others => '0');
signal rfSlvTdoSync : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1) := (others => '0');
signal rfSlvTckEna  : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1) := (others => '0');
signal rfSlvTmsLow  : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1) := (others => '0');
signal rfSlvTrstEna : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1) := (others => '0');

-- For Altera FPGAs: Make sure these registers are not merged.
attribute preserve : boolean;
attribute preserve of rfSlvSel : signal is true;
attribute preserve of rfSlvTckEna : signal is true;

-- For Lattice FPGAs: Make sure these registers are not merged.
attribute syn_keep: boolean;
attribute syn_keep of rfSlvSel : signal is true;
attribute syn_keep of rfSlvTckEna : signal is true;

signal rfSlvTdo    : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1) := (others => '0');
signal wSlvTdoMux  : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 0);
signal wSlvTdo     : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 0);

begin

	-- JTAG TAP Controller for JTAG Switcher internal logic
	sJtagState: entity work.jswitch_jtag_machine
	port map (
		iTrst_n => iPinTrst_n, -- (don't connect if it does not exist)
		iTck    => iPinTck,
		iTms    => iPinTms,
		oState  => wJswitchState
	);

	-- JTAG TAP DR and IR for JTAG Switcher internal logic
	sJtagShift: entity work.jswitch_jtag_shift
	port map (
		iTck    => iPinTck,
		iTdi    => iPinTdi,
		oTdo    => wJswitchTdo,
		oTdoOe  => wJswitchTdoOe,
		iBusMOSI=> wBusMOSI,

		iJtagState => wJswitchState,
		oJtagIr    => wJswitchIR,

		iJtagDr  => wToJtagDR,
		oJtagDr  => wFromJtagDR
	);

	-- Bus master converting JTAG -> Bus accesses for JTAG Switcher internal logic
	sBus: entity work.jswitch_int_busmaster
	port map (
		iTck    => iPinTck,

		iJtagState => wJswitchState,
		iJtagIr    => wJswitchIR,
		iJtagDr    => wFromJtagDR,
		oJtagDr    => wToJtagDR,

		oBusMOSI   => wBusMOSI,
		iBusMISO   => wBusMISO
	);
	oBusMOSI <= wBusMOSI;
	wBusMISOArray(0) <= iBusMISO;
	wBusMISO <= fJswitchBusRead(wBusMISOArray);

	-- All JTAG Switcher control registers
	sRegs: entity work.jswitch_regs
	port map (
		iTck => iPinTck,

		iBusMOSI   => wBusMOSI,
		oBusMISO   => wBusMISOArray(1),

		oRegs      => wRegs
	);

	process(iPinTck)
		variable vSrcHigh : integer;
		variable vDstHigh : integer;
	begin
		if falling_edge(iPinTck) then
			-- State of TAP Controller state machine delayed by 1/2 cycle,
			-- synced to FALLING edge of TCK.
			rfJswitchStateIsRti<='0';
			if fJswitchIsState(wJswitchState, cJswitchJtagRTI) then
				rfJswitchStateIsRti<='1';
			end if;
			rfJswitchStateIsCapDR<='0';
			if fJswitchIsState(wJswitchState, cJswitchJtagCapDR) then
				rfJswitchStateIsCapDR<='1';
			end if;
			rfJswitchStateIsCapIR<='0';
			if fJswitchIsState(wJswitchState, cJswitchJtagCapIR) then
				rfJswitchStateIsCapIR<='1';
			end if;
			rfJswitchStateIsShift<='0';
			if fJswitchIsState(wJswitchState, cJswitchJtagShftDR) or fJswitchIsState(wJswitchState, cJswitchJtagShftIR) then
				rfJswitchStateIsShift<='1';
			end if;

			if rfJswitchStateIsRti='1' then
				-- In Run-Test/Idle state: activate regs for JTAG slave TAPs.
				for i in wRegs'range loop
					vSrcHigh := 7;
					vDstHigh := i*8+8;
					if i=wRegs'high then
						vSrcHigh := cJswitchSlavesNr-(i*8+1);
						vDstHigh := cJswitchSlavesNr;
					end if;
					rfSlvSel(vDstHigh downto i*8+1) <= wRegs(i).sel(vSrcHigh downto 0);
					if cJswitchWithTdoSync then
						rfSlvTdoSync(vDstHigh downto i*8+1) <= wRegs(i).tdoSync(vSrcHigh downto 0);
					end if;
					if cJswitchWithUngate then
						rfSlvTckEna(vDstHigh downto i*8+1) <=
							wRegs(i).sel(vSrcHigh downto 0) or wRegs(i).ungate(vSrcHigh downto 0);
					else
						rfSlvTckEna(vDstHigh downto i*8+1) <= wRegs(i).sel(vSrcHigh downto 0);
					end if;
					if cJswitchWithTmsLow then
						rfSlvTmsLow(vDstHigh downto i*8+1) <= wRegs(i).tmslow(vSrcHigh downto 0);
					end if;
					if cJswitchWithTrstCtl then
						rfSlvTrstEna(vDstHigh downto i*8+1) <= wRegs(i).trstEna(vSrcHigh downto 0);
					end if;
				end loop;
			end if;
			if not cJswitchWithTdoSync then
				rfSlvTdoSync <= (others => '0');
			end if;
			if not cJswitchWithTmsLow then
				rfSlvTmsLow <= (others => '0');
			end if;
			if not cJswitchWithTrstCtl then
				rfSlvTrstEna <= (others => '0');
			end if;
		end if;
	end process;

	-- wSlvTdo(x) Output of Slave NR x
	-- wSlvTdo(0) Output of JTAG Switcher internal logic
	gStealth:
	if cJswitchWithStealth generate
		wSlvTdo(0) <= wJswitchTdo when wJswitchIR.stealthMode='0' else iPinTdi;
	end generate;
	gNoStealth:
	if not cJswitchWithStealth generate
		wSlvTdo(0) <= wJswitchTdo;
	end generate;

	-- TDO Sync Registers might help because they cut up the following timing path
	--                   TCK
	--  JTAG Switcher -------------> JTAG Slave 1
	--                    TDO
	--                <-------------
	--   TDOSyncReg       TDI
	--                -------------> JTAG Slave 2
	--

	-- Connections to Slave NR 1..cJswitchSlavesNr
	gSlv:
	for i in 1 to cJswitchSlavesNr generate
		-- Route iPinTrst_n to slave, when slave is selected.
		-- When slave is not selected allow manual control of TRST* to slave (if enabled)
		gTrstNormal:
		if not cJswitchTrstOpenDrain generate
			oSlvTrst_n(i) <= iPinTrst_n when rfSlvSel(i)='1' else (not rfSlvTrstEna(i));
		end generate;
		gTrstOpenDrain:
		if cJswitchTrstOpenDrain generate
			oSlvTrst_n(i) <=
				'0' when
					(rfSlvSel(i)='1' and iPinTrst_n='0') or
					(rfSlvSel(i)='0' and rfSlvTrstEna(i)='1')
				else 'Z';
		end generate;
		-- Enable TCK to slave if selected.
		-- When slave is not selected allow manual un-gating (if enabled)
		oSlvTck(i) <= iPinTck and rfSlvTckEna(i);
		oSlvTms(i) <=
			-- Slave selected => route iPinTms to slave
			iPinTms when rfSlvSel(i)='1'    else
			-- Slave NOT selected => TMS might be configurable:
			-- Three cases:
			--   1) TCK is gated: TMS pin does not matter but might be set high or low
			--   2) TCK is NOT gated, TMS pin high: slave should goto/stay in Test-Logic-Reset
			--   3) TCK is NOT gated, TMS pin low:  slave should goto/stay in Run-Test/IDLE
			(not rfSlvTmsLow(i));
		-- TDI to slave:
		--   When Selected AND we are in Shift state, use TDO of previous slave.
		--   Otherwise Tri-State.
		oSlvTdi(i) <= wSlvTdo(i-1) when rfSlvSel(i)='1' and wJswitchTdoOe(i)='1' else 'Z';

		-- Allow to insert falling edge clocked sync registers for each slave (if enabled).
		-- Note: Will NOT work if slave changes TDO on rising edge of TCK
		--       (this is not 1149.1 compliant, but such devices do exist).
		gSlvTdoSync:
		if cJswitchWithTdoSync generate
			-- Sample TDO of slave on falling edge
			pSlvTdoSync:
			process(iPinTck)
			begin
				if falling_edge(iPinTck) then
					-- Shift state: Sample iSlvTdo(i) on falling edge.
					-- When CaptureIR pre-load with '1'
					-- when CaptureDR pre-load with '0'
					if rfJswitchStateIsShift='1' then
						rfSlvTdo(i) <= iSlvTdo(i);
					end if;
					if rfJswitchStateIsCapIR='1' then
						rfSlvTdo(i) <= '1';
					end if;
					if rfJswitchStateIsCapDR='1' then
						rfSlvTdo(i) <= '0';
					end if;
				end if;
			end process;
			-- Mux between unregistered TDO and registered TDO value.
			wSlvTdoMux(i) <= iSlvTdo(i) when rfSlvTdoSync(i)='0' else rfSlvTdo(i);
		end generate;
		gNoSlvTdoSync:
		if not cJswitchWithTdoSync generate
			-- TDO Sync registers not enabled: Do not implement register and mux.
			rfSlvTdo(i)<='0';
			wSlvTdoMux(i) <= iSlvTdo(i);
		end generate;
		wSlvTdo(i) <= wSlvTdoMux(i) when rfSlvSel(i)='1' else wSlvTdo(i-1);
	end generate;

	oPinTdo <=
		'Z' when wJswitchTdoOe(0)='0' else
		wSlvTdo(cJswitchSlavesNr);
end rtl;
