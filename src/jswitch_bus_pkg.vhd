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

use work.jswitch_config_pkg.all;

package jswitch_bus_pkg is
	----------------------------------------------------
	-- JSWITCH internal bus definitions
	----------------------------------------------------

	-- If your design is extended and you need more address bits
	-- (for example in the global register bank),
	-- you might make the following address type wider.
	-- Up to 12 address bits are supported (UNSIGNED (11 downto 0)).
	-- (Using more needs a change in the JTAG API which is used here.)
	-- Note though: Making this type wider will use more multiplexing
	-- and demultiplexing logic; so it will noticably increase
	-- the amount of logic needed in your design.
	subtype tJswitchBusAddr is UNSIGNED(2 downto 0);

	subtype tJswitchBusBank is UNSIGNED(3 downto 0);

	-- Use this constant as bank number for the functions defined below,
	-- if you want to implement an un-banked, global register.
	constant cJswitchBusBankGlobal : integer := 1000;

	-- MOSI: Master Out, Slave In
	-- MISO: Master In,  Slave Out
	type tJswitchBusMOSI is record
		rst   : STD_LOGIC;
		rstSelect : STD_LOGIC;
		wrstr : STD_LOGIC;
		rdstr : STD_LOGIC;
		isGlobal : STD_LOGIC;
		bank  : tJswitchBusBank; -- Note: Only needed bank bits are != 0
		addr  : tJswitchBusAddr;
		data  : STD_LOGIC_VECTOR(15 downto 0);
	end record;
	constant cJswitchBusMOSIRst : tJswitchBusMOSI := (
		rst   => '0',
		rstSelect => '0',
		wrstr => '0',
		rdstr => '0',
		isGlobal => '0',
		bank  => (others => '0'),
		addr  => (others => '0'),
		data  => (others => '0')
	);
	subtype tJswitchBusMISO is STD_LOGIC_VECTOR(15 downto 0);
	constant cJswitchBusMISORst : tJswitchBusMISO := (others => '0');

	type tJswitchBusMISOArray is array(natural range <>) of tJswitchBusMISO;

	function fJswitchBusIsRst(
		iBusMOSI : tJswitchBusMOSI
	)
	return boolean;

	function fJswitchBusIsRstSelect(
		iBusMOSI : tJswitchBusMOSI
	)
	return boolean;

	function fJswitchBusIsWr(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer;
		cAddr    : integer
	)
	return boolean;

	function fJswitchBusIsRd(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer;
		cAddr    : integer
	)
	return boolean;

	-- typical set/clr bit logic
	-- Writing a '1' to cBitNr   will set the bit
	-- Writing a '1' to cBitNr+1 will clear the bit
	function fJswitchBusRegSetClr(
		iBusMOSI : tJswitchBusMOSI;
		iValue   : STD_LOGIC;
		cBitNr   : integer
	)
	return STD_LOGIC;

	function fJswitchBusRead(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer;
		cAddr    : integer;
		iData    : STD_LOGIC_VECTOR
	)
	return tJswitchBusMISO;

	function fJswitchBusIsBankMatch(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer
	)
	return boolean;

	-- If you do bank based multiplexing externally (with register stage)
	-- use this.
	-- You need to evaluate iBusMOSI.bank and iBusMOSI.isGlobal before.
	function fJswitchBusRead(
		iBusMOSI : tJswitchBusMOSI;
		cAddr    : integer;
		iData    : STD_LOGIC_VECTOR
	)
	return tJswitchBusMISO;

	function fJswitchBusRead(
		iBusMISOArray : tJswitchBusMISOArray
	)
	return tJswitchBusMISO;

	----------------------------------------------------
	-- JSWITCH internal bus address definitions
	----------------------------------------------------
	-- Un-Banked, Global control bits, reachable via BANK 0xF
	constant cJSwitchBusAddrCfgA  : integer := 16#0#;
	constant cJSwitchBusAddrCfgB  : integer := 16#1#;
	constant cJSwitchBusAddrCtlA  : integer := 16#2#;

	-- Control bits reachable via ControlA register
	type tJswitchCtlABit is record
		grp : integer; -- allowed range 0..15
		nr  : integer; -- allowed range 0..5
	end record;
	constant cJswitchCtlAStealth : tJswitchCtlABit := (
		grp => 0,
		nr  => 0
	);
	function fJswitchCtlAIsWr(
		iBusMOSI : tJswitchBusMOSI;
		cCtlABit : tJswitchCtlABit
	)
	return boolean;


	-- Regular banked control registers
	constant cJSwitchBusAddrSel     : integer := 16#1#;
	constant cJSwitchBusAddrTdoSync : integer := 16#2#;
	constant cJSwitchBusAddrUngate  : integer := 16#3#;
	constant cJSwitchBusAddrTmsLow  : integer := 16#4#;
	constant cJSwitchBusAddrTrstEna : integer := 16#5#;
end jswitch_bus_pkg;

package body jswitch_bus_pkg is
	function fJswitchBusIsRst(
		iBusMOSI : tJswitchBusMOSI
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if iBusMOSI.rst='1' then
			vResult := true;
		end if;
		return vResult;
	end fJswitchBusIsRst;

	function fJswitchBusIsRstSelect(
		iBusMOSI : tJswitchBusMOSI
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if iBusMOSI.rstSelect='1' then
			vResult := true;
		end if;
		return vResult;
	end fJswitchBusIsRstSelect;

	function fJswitchBusIsWr(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer;
		cAddr    : integer
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if iBusMOSI.addr=cAddr and iBusMOSI.wrstr='1' then
			if cBank/=cJswitchBusBankGlobal then
				-- banked control register
				if iBusMOSI.isGlobal='0' then
					if cJswitchBankBits=0 then
						vResult := true;
					elsif iBusMOSI.bank=cBank then
						vResult := true;
					end if;
				end if;
			elsif iBusMOSI.isGlobal='1' then
				-- un-banked, global control register
				vResult := true;
			end if;
		end if;
		return vResult;
	end fJswitchBusIsWr;

	function fJswitchBusIsRd(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer;
		cAddr    : integer
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if iBusMOSI.addr=cAddr and iBusMOSI.rdstr='1' then
			if cBank/=cJswitchBusBankGlobal then
				-- banked control register
				if iBusMOSI.isGlobal='0' then
					if cJswitchBankBits=0 then
						vResult := true;
					elsif iBusMOSI.bank=cBank then
						vResult := true;
					end if;
				end if;
			elsif iBusMOSI.isGlobal='1' then
				-- un-banked, global control register
				vResult := true;
			end if;
		end if;
		return vResult;
	end fJswitchBusIsRd;

	function fJswitchBusRegSetClr(
		iBusMOSI : tJswitchBusMOSI;
		iValue   : STD_LOGIC;
		cBitNr   : integer
	)
	return STD_LOGIC is
		variable vResult : STD_LOGIC;
	begin
		vResult := (iValue or iBusMOSI.data(cBitNr)) and (not iBusMOSI.data(cBitNr+1));
		return vResult;
	end fJswitchBusRegSetClr;

	function fJswitchBusRead(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer;
		cAddr    : integer;
		iData    : STD_LOGIC_VECTOR
	)
	return tJswitchBusMISO is
		variable vResult : tJswitchBusMISO;
	begin
		vResult := (others => '0');
		if iBusMOSI.addr=cAddr then
			if cBank/=cJswitchBusBankGlobal then
				-- banked control register
				if iBusMOSI.isGlobal='0' then
					if cJswitchBankBits=0 then
						vResult(iData'range) := iData;
					elsif iBusMOSI.bank=cBank then
						vResult(iData'range) := iData;
					end if;
				end if;
			elsif iBusMOSI.isGlobal='1' then
				-- un-banked, global register
				vResult(iData'range) := iData;
			end if;
		end if;
		return vResult;
	end fJswitchBusRead;

	function fJswitchBusIsBankMatch(
		iBusMOSI : tJswitchBusMOSI;
		cBank    : integer
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if cBank/=cJswitchBusBankGlobal then
			if iBusMOSI.isGlobal='0' then
				if cJswitchBankBits=0 then
					vResult := true;
				elsif iBusMOSI.bank=cBank then
					vResult := true;
				end if;
			end if;
		elsif iBusMOSI.isGlobal='1' then
			vResult := true;
		end if;
		return vResult;
	end fJswitchBusIsBankMatch;

	function fJswitchBusRead(
		iBusMOSI : tJswitchBusMOSI;
		cAddr    : integer;
		iData    : STD_LOGIC_VECTOR
	)
	return tJswitchBusMISO is
		variable vResult : tJswitchBusMISO;
	begin
		vResult := (others => '0');
		if iBusMOSI.addr=cAddr then
			vResult(iData'range) := iData;
		end if;
		return vResult;
	end fJswitchBusRead;

	function fJswitchBusRead(
		iBusMISOArray : tJswitchBusMISOArray
	)
	return tJswitchBusMISO is
		variable vResult : tJswitchBusMISO;
	begin
		vResult := (others => '0');
		for i in iBusMISOArray'range loop
			vResult := vResult or iBusMISOArray(i);
		end loop;
		return vResult;
	end fJswitchBusRead;

	function fJswitchCtlAIsWr(
		iBusMOSI : tJswitchBusMOSI;
		cCtlABit : tJswitchCtlABit
	)
	return boolean is
		variable vResult : boolean;
	begin
		vResult := false;
		if
			iBusMOSI.isGlobal='1' and iBusMOSI.wrstr='1' and
			iBusMOSI.addr=cJSwitchBusAddrCtlA and
			UNSIGNED(iBusMOSI.data(15 downto 12))=cCtlABit.grp
		then
			-- Write Access to global register cJSwitchBusAddrCtlA
			-- and access to the right bit group (cCtlABit.grp)
			vResult := true;
		end if;
		return vResult;
	end fJswitchCtlAIsWr;

end jswitch_bus_pkg;

