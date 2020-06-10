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

package jswitch_internal_pkg is
	----------------------------------------------------
	-- JTAG state machine definitions
	----------------------------------------------------
	-- internal type for JTAG state machine state.
	subtype tJswitchJtagState  is UNSIGNED(3 downto 0);
	subtype tJswitchJtagDecode is STD_LOGIC_VECTOR(15 downto 0);
	-- Encoding of JTAG states into 4-bits:
	constant cJswitchJtagTLR    : tJswitchJtagState := "0000";
	constant cJswitchJtagRTI    : tJswitchJtagState := "1000";

	constant cJswitchJtagSelDR  : tJswitchJtagState := "1001";
	constant cJswitchJtagCapDR  : tJswitchJtagState := "1010";
	constant cJswitchJtagShftDR : tJswitchJtagState := "1011";
	constant cJswitchJtagEx1DR  : tJswitchJtagState := "1100";
	constant cJswitchJtagPausDR : tJswitchJtagState := "1101";
	constant cJswitchJtagEx2DR  : tJswitchJtagState := "1110";
	constant cJswitchJtagUpdDR  : tJswitchJtagState := "1111";

	constant cJswitchJtagSelIR  : tJswitchJtagState := "0001";
	constant cJswitchJtagCapIR  : tJswitchJtagState := "0010";
	constant cJswitchJtagShftIR : tJswitchJtagState := "0011";
	constant cJswitchJtagEx1IR  : tJswitchJtagState := "0100";
	constant cJswitchJtagPausIR : tJswitchJtagState := "0101";
	constant cJswitchJtagEx2IR  : tJswitchJtagState := "0110";
	constant cJswitchJtagUpdIR  : tJswitchJtagState := "0111";

	type tJswitchState is record
		state  : tJswitchJtagState;
		decode : tJswitchJtagDecode;
	end record;

	function fJswitchIsState(
		iState : tJswitchState;
		cState : tJswitchJtagState
	)
	return boolean;

	----------------------------------------------------
	-- JTAG IR definitions
	----------------------------------------------------

	subtype tJswitchJtagIrReg    is UNSIGNED(3 downto 0);
	subtype tJswitchJtagIrDecode is STD_LOGIC_VECTOR(15 downto 0);
	constant cJswitchIRBypass    : tJswitchJtagIrReg := "1111"; -- BYPASS instruction as defined by IEEE JTAG.
	constant cJswitchIRIdCode    : tJswitchJtagIrReg := "0101"; -- IDCODE instruction
	constant cJswitchIRRst       : tJswitchJtagIrReg := "0110"; -- Reset all control registers (includes unselecting all TAPs)
	constant cJswitchIRRstSelect : tJswitchJtagIrReg := "0111"; -- Unselect all TAPs

	constant cJswitchIRWrite     : tJswitchJtagIrReg := "1001"; -- Write  to bus
	constant cJswitchIRRead      : tJswitchJtagIrReg := "1010"; -- Read from bus
	constant cJswitchIRRdWr      : tJswitchJtagIrReg := "1011"; -- Read from and write to bus
	constant cJswitchIRSetAddr   : tJswitchJtagIrReg := "1100"; -- Set address for bus access
	constant cJswitchIRSetAddrWr : tJswitchJtagIrReg := "1101"; -- Set address and write to bus

	type tJswitchIR is record
		reg    : tJswitchJtagIrReg;
		decode : tJswitchJtagIrDecode;
		stealthMode   : STD_LOGIC;
		stealthOffRst : STD_LOGIC;
	end record;

	function fJswitchIsIR(
		iIR : tJswitchIR;
		cIR : tJswitchJtagIrReg
	)
	return boolean;

	----------------------------------------------------
	-- JSWITCH control register definitions
	----------------------------------------------------
	-- Un-Banked, Global control bits, reachable via BANK 0xF
	type tJswitchCtlReg is record
		tdoSyncRegEna : STD_LOGIC;
		tdoSampleRise : STD_LOGIC;
	end record;
	constant cJswitchCtlRegRst : tJswitchCtlReg := (
		tdoSyncRegEna => '0',
		tdoSampleRise => '0'
	);

	-- Regular banked control registers
	subtype tJswitchCtlBitWord is STD_LOGIC_VECTOR(7 downto 0);
	type tJswitchBankRegs is record
		sel      : tJswitchCtlBitWord;
		tdoSync  : tJswitchCtlBitWord;
		ungate   : tJswitchCtlBitWord;
		tmslow   : tJswitchCtlBitWord;
		trstEna  : tJswitchCtlBitWord;
	end record;
	constant cJswitchBankRegsRst : tJswitchBankRegs := (
		sel     => (others => '0'),
		tdoSync => (others => '0'),
		ungate  => (others => '0'),
		tmslow  => (others => '0'),
		trstEna => (others => '0')
	);
	type tJswitchRegs is array(cJswitchRegBanks-1 downto 0) of tJswitchBankRegs;
	constant cJswitchRegsRst : tJswitchRegs := (others => cJswitchBankRegsRst);
end jswitch_internal_pkg;

package body jswitch_internal_pkg is
	function fJswitchIsState(
		iState : tJswitchState;
		cState : tJswitchJtagState
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if iState.decode(TO_INTEGER(cState))='1' then
			vResult := true;
		end if;
		return vResult;
	end fJswitchIsState;

	function fJswitchIsIR(
		iIR : tJswitchIR;
		cIR : tJswitchJtagIrReg
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if iIR.decode(TO_INTEGER(cIR))='1' then
			vResult := true;
		end if;
		return vResult;
	end fJswitchIsIR;
end jswitch_internal_pkg;
