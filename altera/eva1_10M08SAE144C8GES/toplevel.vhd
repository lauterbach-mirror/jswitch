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

use work.jswitch_config_pkg.all;
use work.jswitch_bus_pkg.all;

entity toplevel is
	port (
		oVtref     : out STD_LOGIC;

		iPinTrst_n : in STD_LOGIC; -- (optional)
		iPinTck    : in STD_LOGIC;
		iPinTms    : in STD_LOGIC;
		iPinTdi    : in STD_LOGIC;
		oPinTdo    : out STD_LOGIC;

		oSlvTrst_n : out STD_LOGIC_VECTOR(2 downto 1);
		oSlvTck    : out STD_LOGIC_VECTOR(2 downto 1);
		oSlvTms    : out STD_LOGIC_VECTOR(2 downto 1);
		oSlvTdi    : out STD_LOGIC_VECTOR(2 downto 1);
		iSlvTdo    : in  STD_LOGIC_VECTOR(2 downto 1);

		oLeds      : out STD_LOGIC_VECTOR(5 downto 1)
	);
end toplevel;

architecture rtl of toplevel is

signal wBusMOSI : tJswitchBusMOSI;
signal wBusMISOArray : tJswitchBusMISOArray(0 downto 0);
signal wBusMISO      : tJswitchBusMISO;

begin
	oVtref <= '1';

	sJswitcher : entity work.jswitch_top
	port map (
		iPinTrst_n => iPinTrst_n,
		iPinTck    => iPinTck,
		iPinTms    => iPinTms,
		iPinTdi    => iPinTdi,
		oPinTdo    => oPinTdo,

		oSlvTrst_n => oSlvTrst_n,
		oSlvTck    => oSlvTck,
		oSlvTms    => oSlvTms,
		oSlvTdi    => oSlvTdi,
		iSlvTdo    => iSlvTdo,

		-- You might connect your own bus slaves here.
		oBusMOSI   => wBusMOSI,
		iBusMISO   => wBusMISO
	);

	-- Example how to connect BusMOSI to your own component:
	sLeds : entity work.bus_leds
	port map (
		iTck  => iPinTck,

		iBusMOSI => wBusMOSI,
		oLeds    => oLeds
	);

	-- Example how to connect onchip ram to JTAG Switcher bus.
	sRam : entity work.bus_ram
	port map (
		iTck       => iPinTck,

		iBusMOSI   => wBusMOSI,
		oBusMISO   => wBusMISOArray(0)
	);
	wBusMISO <= fJswitchBusRead(wBusMISOArray);

end rtl;
