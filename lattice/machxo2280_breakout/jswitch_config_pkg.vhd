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

package jswitch_config_pkg is
	constant cJswitchSlavesNr          : POSITIVE := 2;
	constant cJswitchWithTdoSync       : BOOLEAN  := true;
	constant cJswitchWithUngate        : BOOLEAN  := true;
	constant cJswitchWithTmsLow        : BOOLEAN  := false;
	constant cJswitchWithTrstCtl       : BOOLEAN  := false;
	constant cJswitchWithDbgRd         : BOOLEAN  := false;
	constant cJswitchWithStealth       : BOOLEAN  := true;
	constant cJswitchTrstOpenDrain     : BOOLEAN  := false;

	-- Set to a fixed value
	constant cJswitchJtagIdCode : STD_LOGIC_VECTOR(31 downto 0) := X"11111FFF";

	-- The following constants are calculated
	-- from the number of JTAG slave TAPs.
	function fJswitchRegBanks return POSITIVE;
	function fJswitchBankBits return INTEGER;
	constant cJswitchRegBanks   : POSITIVE := fJswitchRegBanks;
	constant cJswitchBankBits   : INTEGER  := fJswitchBankBits;
end jswitch_config_pkg;
