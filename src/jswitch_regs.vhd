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

entity jswitch_regs is
	port (
		iTck : in STD_LOGIC;

		-- sampled and synchronized to falling edge of iTck
		iBusMOSI   : in  tJswitchBusMOSI;
		oBusMISO   : out tJswitchBusMISO;

		oRegs   : out tJswitchRegs
	);
end jswitch_regs;

architecture rtl of jswitch_regs is
	signal rRegs      : tJswitchRegs   := cJswitchRegsRst;

	signal wBusMISOArray : tJswitchBusMISOArray(5 downto 0);

	signal rRdSel     : tJswitchCtlBitWord;
	signal rRdTdoSync : tJswitchCtlBitWord;
	signal rRdUngate  : tJswitchCtlBitWord;
	signal rRdTmsLow  : tJswitchCtlBitWord;
	signal rRdTrstEna : tJswitchCtlBitWord;

	subtype tJswitchCtlBitWordRd is STD_LOGIC_VECTOR(15 downto 0);
	signal wRdSel     : tJswitchCtlBitWordRd;
	signal wRdTdoSync : tJswitchCtlBitWordRd;
	signal wRdUngate  : tJswitchCtlBitWordRd;
	signal wRdTmsLow  : tJswitchCtlBitWordRd;
	signal wRdTrstEna : tJswitchCtlBitWordRd;
	signal wRdCfgAReg : tJswitchCtlBitWordRd;

	function fCtlBitWordWr(
		cEnabled  : boolean;
		cBank     : integer;
		cAddr     : integer;
		iBusMOSI  : tJswitchBusMOSI;
		iCurValue : tJswitchCtlBitWord
	)
	return tJswitchCtlBitWord is
		variable vResult : tJswitchCtlBitWord;
	begin
		vResult := (others => '0');
		if cEnabled then
			vResult := iCurValue;
			if fJswitchBusIsWr(iBusMOSI,cBank,cAddr) then
				for i in vResult'range loop
					vResult(i) := (iCurValue(i) or iBusMOSI.data(i*2)) and (not iBusMOSI.data(i*2+1));
				end loop;
			end if;
		end if;
		return vResult;
	end fCtlBitWordWr;

	function fCtlBitWordRd(
		iCurValue : tJswitchCtlBitWord
	)
	return tJswitchCtlBitWordRd is
		variable vResult : tJswitchCtlBitWordRd;
	begin
		vResult := (others => '0');
		for i in 0 to 7 loop
			vResult(i*2+0):=iCurValue(i);
		end loop;
		return vResult;
	end fCtlBitWordRd;

begin
	process(iTck)
	begin
		if falling_edge(iTck) then
			for i in rRegs'range loop
				rRegs(i).sel    <= fCtlBitWordWr(true,i,cJSwitchBusAddrSel,iBusMOSI,rRegs(i).sel);
				rRegs(i).tdoSync<= fCtlBitWordWr(cJswitchWithTdoSync,i,cJSwitchBusAddrTdoSync,iBusMOSI,rRegs(i).tdoSync);
				rRegs(i).ungate <= fCtlBitWordWr(cJswitchWithUngate,i,cJSwitchBusAddrUngate,iBusMOSI,rRegs(i).ungate);
				rRegs(i).tmslow <= fCtlBitWordWr(cJswitchWithTmsLow,i,cJSwitchBusAddrTmsLow,iBusMOSI,rRegs(i).tmslow);
				rRegs(i).trstEna<= fCtlBitWordWr(cJswitchWithTrstCtl,i,cJSwitchBusAddrTrstEna,iBusMOSI,rRegs(i).trstEna);
			end loop;
			if fJswitchBusIsRstSelect(iBusMOSI) then
				for i in rRegs'range loop
					rRegs(i).sel <= (others => '0');
				end loop;
			end if;
			if fJswitchBusIsRst(iBusMOSI) then
				rRegs   <= cJswitchRegsRst;
			end if;

			-- Debug Read: Do banked multiplexing in extra register stage
			rRdSel     <= (others => '0');
			rRdTdoSync <= (others => '0');
			rRdTmsLow  <= (others => '0');
			rRdUngate  <= (others => '0');
			rRdTrstEna <= (others => '0');
			if cJswitchWithDbgRd then
				for i in rRegs'range loop
					if fJswitchBusIsBankMatch(iBusMOSI, i) then
						rRdSel    <= rRegs(i).sel;
						rRdTdoSync<= rRegs(i).tdoSync;
						rRdTmsLow <= rRegs(i).tmslow;
						rRdUngate <= rRegs(i).ungate;
						rRdTrstEna<= rRegs(i).trstEna;
					end if;
				end loop;
			end if;
		end if;
	end process;
	oRegs<=rRegs;

	-- Read out configuration of jswitch_top...
	wRdCfgAReg(6 downto 0)<=STD_LOGIC_VECTOR(TO_UNSIGNED(cJswitchSlavesNr,7));
	wRdCfgAReg(7)  <= '1' when cJswitchWithDbgRd   else '0';
	wRdCfgAReg(8)  <= '1' when cJswitchWithTdoSync else '0';
	wRdCfgAReg(9)  <= '1' when cJswitchWithUngate  else '0';
	wRdCfgAReg(10) <= '1' when cJswitchWithTmsLow  else '0';
	wRdCfgAReg(11) <= '1' when cJswitchWithTrstCtl else '0';
	wRdCfgAReg(12) <= '1' when cJswitchWithStealth else '0';
	wRdCfgAReg(15 downto 13)<="000";
	wBusMISOArray(0)<=fJswitchBusRead(iBusMOSI, cJswitchBusBankGlobal, cJSwitchBusAddrCfgA, wRdCfgAReg);

	gWithDbgRead:
	if cJswitchWithDbgRd generate
		-- Expand 8 bit control bit array, to 16-bit read value.
		wRdSel<=fCtlBitWordRd(rRdSel);
		wRdTdoSync<=fCtlBitWordRd(rRdTdoSync);
		wRdUngate<=fCtlBitWordRd(rRdUngate);
		wRdTmsLow<=fCtlBitWordRd(rRdTmsLow);
		wRdTrstEna<=fCtlBitWordRd(rRdTrstEna);

		-- Multiplex to Master-In/Slave-Out
		wBusMISOArray(1)<=fJswitchBusRead(iBusMOSI, cJSwitchBusAddrSel,     wRdSel);
		wBusMISOArray(2)<=fJswitchBusRead(iBusMOSI, cJSwitchBusAddrTdoSync, wRdTdoSync);
		wBusMISOArray(3)<=fJswitchBusRead(iBusMOSI, cJSwitchBusAddrUngate,  wRdUngate);
		wBusMISOArray(4)<=fJswitchBusRead(iBusMOSI, cJSwitchBusAddrTmsLow,  wRdTmsLow);
		wBusMISOArray(5)<=fJswitchBusRead(iBusMOSI, cJSwitchBusAddrTrstEna, wRdTrstEna);
	end generate;
	gNotWithDbgRead:
	if not cJswitchWithDbgRd generate
		wBusMISOArray(1)<=(others => '0');
		wBusMISOArray(2)<=(others => '0');
		wBusMISOArray(3)<=(others => '0');
		wBusMISOArray(4)<=(others => '0');
		wBusMISOArray(5)<=(others => '0');
	end generate;

	oBusMISO<=fJswitchBusRead(wBusMISOArray);
end rtl;
