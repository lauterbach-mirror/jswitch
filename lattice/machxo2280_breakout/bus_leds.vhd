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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.jswitch_bus_pkg.all;

entity bus_leds is
	port (
		iTck : in STD_LOGIC;

		iBusMOSI   : in  tJswitchBusMOSI;
		oLeds_n    : out STD_LOGIC_VECTOR(7 downto 0)
	);
end bus_leds;

architecture rtl of bus_leds is

constant cJswitchBusAddrLeds : integer := 16#4#;

signal rLeds : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin
	-- iBusMOSI is synchronized to FALLING edge of iTck
	process(iTck)
	begin
		if falling_edge(iTck) then
			if fJswitchBusIsWr(iBusMOSI,cJswitchBusBankGlobal,cJswitchBusAddrLeds) then
				-- Standard Control-Bit set/clear scheme:
				for i in rLeds'range loop
					rLeds(i) <= fJswitchBusRegSetClr(iBusMOSI,rLeds(i),i*2);
				end loop;
			end if;
		end if;
	end process;
	oLeds_n <= not rLeds;
end rtl;
