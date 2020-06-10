-- The MIT License
--
-- Copyright (c) 2019 Lauterbach GmbH, Ingo Rohloff
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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.jswitch_bus_pkg.all;

entity bus_ram is
	port (
		iTck : in STD_LOGIC;

		iBusMOSI   : in  tJswitchBusMOSI;
		oBusMISO   : out tJswitchBusMISO
	);
end bus_ram;

architecture rtl of bus_ram is

constant cJswitchBusAddrRamAddr : integer := 16#5#;
constant cJswitchBusAddrRamData : integer := 16#6#;

signal rRamAddr   : UNSIGNED(8 DOWNTO 0);
signal rRamAddrInc: STD_LOGIC;
signal wRamAddr   : STD_LOGIC_VECTOR(8 DOWNTO 0);
signal wRamClk    : STD_LOGIC;
signal wRamWr     : STD_LOGIC;
signal wRamRdData : STD_LOGIC_VECTOR(15 downto 0);

begin
	wRamClk <= not iTck;
	-- iBusMOSI is synchronized to FALLING edge of iTck
	process(wRamClk)
	begin
		if rising_edge(wRamClk) then
			rRamAddrInc<='0';
			if fJswitchBusIsWr(iBusMOSI,cJswitchBusBankGlobal,cJswitchBusAddrRamData) then
				rRamAddrInc<='1';
			end if;
			if fJswitchBusIsRd(iBusMOSI,cJswitchBusBankGlobal,cJswitchBusAddrRamData) then
				rRamAddrInc<='1';
			end if;
			if fJswitchBusIsWr(iBusMOSI,cJswitchBusBankGlobal,cJswitchBusAddrRamAddr) then
				rRamAddr <= UNSIGNED(iBusMOSI.data(8 downto 0));
			end if;
			-- Auto Increment after accessing RAM to allow block reads/writes
			if rRamAddrInc='1' then
				rRamAddr <= rRamAddr+1;
			end if;
		end if;
	end process;
	wRamAddr <= STD_LOGIC_VECTOR(rRamAddr);
	wRamWr   <= '1' when fJswitchBusIsWr(iBusMOSI,cJswitchBusBankGlobal,cJswitchBusAddrRamData) else '0';
	sRam : entity work.altera_ram
	port map (
		iClk    => wRamClk,
		iAddr   => wRamAddr,
		iWrEna  => wRamWr,
		iWrData => iBusMOSI.data(15 downto 0),
		oRdData => wRamRdData
	);
	oBusMISO <= fJswitchBusRead(iBusMOSI, cJswitchBusBankGlobal, cJswitchBusAddrRamData, wRamRdData);
end rtl;
