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
use work.jswitch_internal_pkg.all;
use work.jswitch_bus_pkg.all;

entity jswitch_jtag_shift is
	port (
		iTck    : in  STD_LOGIC;

		-- sampled on rising edge of iTck
		iTdi    : in  STD_LOGIC;

		-- synchronized to falling edge of iTck
		oTdo    : out STD_LOGIC;
		oTdoOe  : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 0);
		iBusMOSI:  in tJswitchBusMOSI;

		-- outputs are synchronized to rising_edge of iTck
		iJtagState : in  tJswitchState;
		oJtagIr    : out tJswitchIR;

		iJtagDr  : in  STD_LOGIC_VECTOR(31 downto 0);
		oJtagDr  : out STD_LOGIC_VECTOR(31 downto 0)
	);
end jswitch_jtag_shift;

architecture rtl of jswitch_jtag_shift is

signal rIrReg    : tJswitchJtagIrReg := (others => '0');
signal rIrDecode : tJswitchJtagIrDecode;

signal rBypass  : STD_LOGIC;
signal rShiftDR : STD_LOGIC_VECTOR(31 downto 0);
signal rTdo     : STD_LOGIC;
signal rTdoOe   : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 0);

-- For Altera FPGAs: Make sure rTdoOe registers are not merged.
attribute preserve : boolean;
attribute preserve of rTdoOe : signal is true;

-- For Lattice FPGAs: Make sure rTdoOe registers are not merged.
attribute syn_keep: boolean;
attribute syn_keep of rTdoOe : signal is true;

signal rStealthTdi        : STD_LOGIC := '0';

signal rStealthShiftIr    : STD_LOGIC := '0';
signal rStealthDisable    : STD_LOGIC := '0';
signal rStealthLfsr       : STD_LOGIC_VECTOR(6 downto 0);
signal rStealthModePre    : STD_LOGIC := '0';
signal rStealthMode       : STD_LOGIC := '0';
signal rStealthOffRst     : STD_LOGIC := '0';
constant cStealthLfsrTaps : STD_LOGIC_VECTOR(6 downto 1) := "101010";

begin
	-- Sample iTdi on RISING edge of iTck
	pJtagRegs:
	process(iTck)
	begin
		if rising_edge(iTck) then
			if
				fJswitchIsState(iJtagState,cJswitchJtagTLR) or
				fJswitchIsState(iJtagState,cJswitchJtagCapIR)
			then
				rIrReg <= cJswitchIRIdCode;
			elsif fJswitchIsState(iJtagState,cJswitchJtagShftIR) then
				rIrReg(3) <= iTdi;
				rIrReg(2 downto 0)<=rIrReg(3 downto 1);
			end if;
			if rStealthMode='1' then
				rIrReg <= cJswitchIRBypass;
			end if;

			rIrDecode<=(others => '0');
			for i in rIrDecode'range loop
				if rIrReg=i then
					rIrDecode(i)<='1';
				end if;
			end loop;

			if fJswitchIsState(iJtagState,cJswitchJtagCapDR) then
				rBypass<='0';
			elsif fJswitchIsState(iJtagState,cJswitchJtagShftDR) then
				rBypass<= iTdi;
			end if;

			if fJswitchIsState(iJtagState,cJswitchJtagCapDR) then
				rShiftDR<=iJtagDr;
				if rIrDecode(TO_INTEGER(cJswitchIRIdCode))='1' then
					rShiftDR <= cJswitchJtagIdCode;
				end if;
			elsif fJswitchIsState(iJtagState,cJswitchJtagShftDR) then
				rShiftDR(31) <= iTdi;
				rShiftDR(30 downto 0)<=rShiftDR(31 downto 1);
			end if;


			rStealthTdi <= iTdi;
			if not cJswitchWithStealth then
				rStealthTdi<='0';
			end if;
		end if;
	end process;
	oJtagIr.stealthMode   <= rStealthMode;
	oJtagIr.stealthOffRst <= rStealthOffRst;
	oJtagIr.reg    <= rIrReg;
	oJtagIr.decode <= rIrDecode;
	oJtagDr        <= rShiftDR;

	pTdo:
	process(iTck)
	begin
		if falling_edge(iTck) then
			-- Default: use 16-bit ShiftDR chain: rShiftDR(31..16)
			rTdo <= rShiftDR(16);
			if
				rIrDecode(TO_INTEGER(cJswitchIRIdCode))='1' or
				rIrDecode(TO_INTEGER(cJswitchIRSetAddrWr))='1'
			then
				-- This uses a 32-bit ShiftDR chain: rShiftDR(31..0)
				rTdo <= rShiftDR(0);
			end if;
			if rIrDecode(TO_INTEGER(cJswitchIRBypass))='1' then
				rTdo <= rBypass;
			end if;
			-- if fJswitchIsState(iJtagState,cJswitchJtagShftIR) then
			if iJtagState.state(3)='0' then
				rTdo <= rIrReg(0);
			end if;

			rTdoOe<=(others => '0');
			if
				fJswitchIsState(iJtagState,cJswitchJtagShftDR) or
				fJswitchIsState(iJtagState,cJswitchJtagShftIR)
			then
				rTdoOe<=(others => '1');
			end if;

			-- To get a strobe on rStealthDisable, shift in:
			--  1) a prefix with whatever you want,
			--  2)
			--     last             first
			--        0 0 0 0 0 0 0 0
			--             0x00
			--  3)
			--     last                               first
			--     0x19 0xa6 0x39 0x57 0x52 0x5f 0xcf 0xb7
			--     0x81 0x43 0x64 0x1e 0x2d 0x61 0x13 0xbd
			-- 4) as many 0xff as you think is useful.
			rStealthShiftIr<='0';
			if rStealthMode='1' and fJswitchIsState(iJtagState,cJswitchJtagShftIR) then
				rStealthShiftIr<='1';
			end if;
			rStealthDisable<='0';
			if rStealthShiftIr='1' and rStealthLfsr="0100000" and rStealthTdi='0' then
				rStealthDisable<='1';
			end if;
			rStealthLfsr<="1000000";
			if rStealthShiftIr='1' and rStealthTdi=rStealthLfsr(6) then
				rStealthLfsr(0)<=rStealthLfsr(6);
				for i in 6 downto 1 loop
					rStealthLfsr(i)<=rStealthLfsr(i-1) xor (rStealthLfsr(6) and cStealthLfsrTaps(i));
				end loop;
			end if;

			if fJswitchCtlAIsWr(iBusMOSI,cJswitchCtlAStealth) then
				rStealthModePre <= fJswitchBusRegSetClr(iBusMOSI,rStealthModePre,cJswitchCtlAStealth.nr*2);
			end if;
			if rStealthDisable='1' then
				rStealthModePre<='0';
				rStealthOffRst<='1';
			end if;
			if fJswitchIsState(iJtagState,cJswitchJtagRTI) then
				rStealthMode   <= rStealthModePre;
				rStealthOffRst <= '0';
			end if;
			if not cJswitchWithStealth then
				rStealthShiftIr<='0';
				rStealthDisable<='0';
				rStealthLfsr<=(others => '0');
				rStealthModePre<='0';
				rStealthMode<='0';
				rStealthOffRst<='0';
			end if;
		end if;
	end process;

	oTdo   <= rTdo;
	oTdoOe <= rTdoOe;
end rtl;
