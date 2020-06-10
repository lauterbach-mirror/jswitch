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

entity jswitch_int_busmaster is
	port (
		iTck   : in  STD_LOGIC;

		-- sampled on FALLING edge of iTck
		iJtagState : in  tJswitchState;
		iJtagIr    : in  tJswitchIR;
		iJtagDr    : in  STD_LOGIC_VECTOR(31 downto 0);

		-- synchronized to RISING edge of iTck
		oJtagDr    : out STD_LOGIC_VECTOR(31 downto 0);

		-- synchronized to FALLING edge of iTck
		oBusMOSI   : out tJswitchBusMOSI;
		-- sampled on RISING edge of iTck
		iBusMISO   : in  tJswitchBusMISO
	);
end jswitch_int_busmaster;

architecture rtl of jswitch_int_busmaster is

signal rBusMOSI : tJswitchBusMOSI := cJswitchBusMOSIRst;
signal rBusMISO : tJswitchBusMISO;

begin
	oJtagDr(15 downto  0) <= rBusMISO;
	oJtagDr(31 downto 16) <= rBusMISO;
	pMISO:
	process(iTck)
	begin
		if rising_edge(iTck) then
			rBusMISO <= iBusMISO;
		end if;
	end process;

	-- oBusMOSI is synchronized to FALLING edge of iTck
	oBusMOSI <= rBusMOSI;
	pMOSI:
	process(iTck)
	begin
		if falling_edge(iTck) then
			rBusMOSI.rst   <= '0';
			rBusMOSI.rstSelect <= '0';
			rBusMOSI.rdstr <= '0';
			rBusMOSI.wrstr <= '0';
			if
				fJswitchIsState(iJtagState,cJswitchJtagRTI) and
				fJswitchIsIR(iJtagIr,cJswitchIRRst)
			then
				rBusMOSI.rst  <= '1';
			end if;

			if
				fJswitchIsState(iJtagState,cJswitchJtagRTI) and
				fJswitchIsIR(iJtagIr,cJswitchIRRstSelect)
			then
				rBusMOSI.rstSelect <= '1';
			end if;
			if iJtagIr.stealthOffRst='1' then
				rBusMOSI.rstSelect  <= '1';
			end if;

			if
				fJswitchIsState(iJtagState,cJswitchJtagCapDR) and (
					fJswitchIsIR(iJtagIr,cJswitchIRRead) or
					fJswitchIsIR(iJtagIr,cJswitchIRRdWr)
				)
			then
				rBusMOSI.rdstr <= '1';
			end if;

			if
				fJswitchIsState(iJtagState,cJswitchJtagUpdDR) and (
					fJswitchIsIR(iJtagIr,cJswitchIRSetAddr) or
					fJswitchIsIR(iJtagIr,cJswitchIRSetAddrWr)
				)
			then
				-- BANK 0xF reserved for access to global control registers.
				rBusMOSI.isGlobal<='0';
				if iJtagDr(31 downto 28)="1111" then
					rBusMOSI.isGlobal<='1';
				end if;
				-- Up to 4 bits...
				if cJswitchBankBits>0 then
					-- Only load used bits
					rBusMOSI.bank(cJswitchBankBits-1 downto 0) <= UNSIGNED(iJtagDr(cJswitchBankBits-1+28 downto 28));
				end if;
				-- Up to 8 bits...
				rBusMOSI.addr <= UNSIGNED(iJtagDr(rBusMOSI.addr'length-1+16 downto 16));
			end if;
			if cJswitchBankBits<4 then
				-- set unused bits to 0
				rBusMOSI.bank(3 downto cJswitchBankBits)<=(others => '0');
			end if;

			if
				fJswitchIsState(iJtagState,cJswitchJtagUpdDR) and (
					fJswitchIsIR(iJtagIr,cJswitchIRWrite) or
					fJswitchIsIR(iJtagIr,cJswitchIRRdWr)
				)
			then
				rBusMOSI.wrstr <= '1';
				rBusMOSI.data  <= iJtagDr(31 downto 16);
			end if;

			if
				fJswitchIsState(iJtagState,cJswitchJtagUpdDR) and
				fJswitchIsIR(iJtagIr,cJswitchIRSetAddrWr)
			then
				rBusMOSI.wrstr <= '1';
				rBusMOSI.data  <= iJtagDr(15 downto  0);
			end if;
		end if;
	end process;
end rtl;
