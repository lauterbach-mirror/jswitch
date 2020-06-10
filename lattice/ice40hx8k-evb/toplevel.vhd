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
		iPinTrst_n : in  STD_LOGIC; -- (optional)
		iPinTck    : in  STD_LOGIC;
		oPinRtck   : out STD_LOGIC;
		iPinTms    : in  STD_LOGIC;
		iPinTdi    : in  STD_LOGIC;
		oPinTdo    : out STD_LOGIC;
		iPinRst_n  : in  STD_LOGIC;

		oSlvTrst_n : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTck    : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTms    : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTdi    : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		iSlvTdo    : in  STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);

		oSlvEn_n   : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvRst_n  : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTmsEn_n: out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTdiEn_n: out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);

		GND_IN     : out STD_LOGIC_VECTOR(5 downto 0);
		GND_EXT1   : out STD_LOGIC_VECTOR(15 downto 0);
		GND_EXT2   : out STD_LOGIC_VECTOR(15 downto 0);
		GND_EXT3   : out STD_LOGIC_VECTOR(15 downto 0);
		GND_EXT4   : out STD_LOGIC_VECTOR(15 downto 0)
	);
end toplevel;

architecture rtl of toplevel is

signal wBusMOSI : tJswitchBusMOSI;
signal wSlvRst_n : STD_LOGIC;

begin
	oPinRtck <= iPinTck;

	-- Drive oSlvRst_n() as open-drain
	-- wSlvRst_n <= '0' when iPinRst_n='0' else 'Z';
	-- slvStatic: for i in 1 to cJswitchSlavesNr generate
	-- 	oSlvRst_n(i) <= wSlvRst_n;
	-- end generate;
	-- Drive oSlvRst_n() as normal
	
	oSlvRst_n <= (others => '0') when iPinRst_n='0' else (others => '1');
	oSlvEn_n <= (others => '0');
	oSlvTmsEn_n <= (others => '0');
	oSlvTdiEn_n <= (others => '0');

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
		iBusMISO   => cJswitchBusMISORst
	);

	GND_IN <= (others => '0');
	GND_EXT1 <= (others => '0');
	GND_EXT2 <= (others => '0');
	GND_EXT3 <= (others => '0');
	GND_EXT4 <= (others => '0');

end rtl;
