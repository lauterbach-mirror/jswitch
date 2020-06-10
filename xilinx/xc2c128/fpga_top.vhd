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

entity fpga_top is
	port (
		iPinTck    : in  STD_LOGIC;
		iPinTms    : in  STD_LOGIC;
		iPinTdi    : in  STD_LOGIC;
		oPinTdo    : out STD_LOGIC;

		oSlvTck    : out STD_LOGIC_VECTOR(3 downto 1);
		oSlvTms    : out STD_LOGIC_VECTOR(3 downto 1);
		oSlvTdi    : out STD_LOGIC_VECTOR(3 downto 1);
		iSlvTdo    : in  STD_LOGIC_VECTOR(3 downto 1)
	);
end fpga_top;

architecture rtl of fpga_top is

signal wBusMOSI : tJswitchBusMOSI;

begin
	sJswitcher : entity work.jswitch_top
	port map (
		iPinTrst_n => '1',
		iPinTck    => iPinTck,
		iPinTms    => iPinTms,
		iPinTdi    => iPinTdi,
		oPinTdo    => oPinTdo,

		oSlvTrst_n => open,
		oSlvTck    => oSlvTck,
		oSlvTms    => oSlvTms,
		oSlvTdi    => oSlvTdi,
		iSlvTdo    => iSlvTdo,

		-- You might connect your own bus slaves here.
		oBusMOSI   => open,
		iBusMISO   => cJswitchBusMISORst
	);
end rtl;
