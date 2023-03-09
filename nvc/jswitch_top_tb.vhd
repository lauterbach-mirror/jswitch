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

entity sim_jtag_slave is
	generic (
		gIdcode : STD_LOGIC_VECTOR
	);
	port (
		iTck :  in STD_LOGIC;
		iTms :  in STD_LOGIC;
		iTdi :  in STD_LOGIC;
		oTdo : out STD_LOGIC
	);
end sim_jtag_slave;

architecture sim of sim_jtag_slave is
type tTapState is (
	TLR,RTI,SEL_DR,SEL_IR,
	CAP_DR,SHF_DR,EX1_DR,PAU_DR,EX2_DR,UPD_DR,
	CAP_IR,SHF_IR,EX1_IR,PAU_IR,EX2_IR,UPD_IR
);
type tNextTapStateEntry is array (1 downto 0) of tTapState;
type tNextTapStateArray is array (tTapState) of tNextTapStateEntry;
constant cNextTapState : tNextTapStateArray := (
	TLR    => (0 => RTI,    1 => TLR),
	RTI    => (0 => RTI,    1 => SEL_DR),
	SEL_DR => (0 => CAP_DR, 1 => SEL_IR),
	SEL_IR => (0 => CAP_IR, 1 => TLR),

	CAP_DR => (0 => SHF_DR, 1 => EX1_DR),
	SHF_DR => (0 => SHF_DR, 1 => EX1_DR),
	EX1_DR => (0 => PAU_DR, 1 => UPD_DR),
	PAU_DR => (0 => PAU_DR, 1 => EX2_DR),
	EX2_DR => (0 => SHF_DR, 1 => UPD_DR),
	UPD_DR => (0 => RTI,    1 => SEL_DR),

	CAP_IR => (0 => SHF_IR, 1 => EX1_IR),
	SHF_IR => (0 => SHF_IR, 1 => EX1_IR),
	EX1_IR => (0 => PAU_IR, 1 => UPD_IR),
	PAU_IR => (0 => PAU_IR, 1 => EX2_IR),
	EX2_IR => (0 => SHF_IR, 1 => UPD_IR),
	UPD_IR => (0 => RTI,    1 => SEL_DR)
);

signal rTapState : tTapState := TLR;
signal rIrReg    : STD_LOGIC_VECTOR(3 downto 0);
signal rBypass   : STD_LOGIC;
signal rDrReg    : STD_LOGIC_VECTOR(31 downto 0);
signal rfTdo     : STD_LOGIC;
signal rfTdoOe   : STD_LOGIC;

begin
	process(iTck)
	begin
		if rising_edge(iTck) then
			rTapState <= cNextTapState(rTapState)(0) after 5 ns;
			if iTms='1' then
				rTapState <= cNextTapState(rTapState)(1) after 5 ns;
			end if;
			if rTapState=TLR or rTapState=CAP_IR then
				rIrReg <= "1010";
			elsif rTapState=SHF_IR then
				rIrReg(3) <= iTdi;
				rIrReg(2 downto 0)<=rIrReg(3 downto 1);
			end if;

			if rTapState=CAP_DR then
				rBypass<='0';
			elsif rTapState=SHF_DR and rIrReg="1111" then
				rBypass <= iTdi;
			end if;
			if rTapState=CAP_DR then
				rDrReg <= X"90555581";
				if rIrReg="1010" then
					rDrReg <= gIdcode;
				end if;
			elsif rTapState=SHF_DR then
				rDrReg(31) <= iTdi;
				rDrReg(30 downto 0) <= rDrReg(31 downto 1);
			end if;
		end if;
	end process;
	process(iTck)
	begin
		if falling_edge(iTck) then
			rfTdo <= rDrReg(16);
			if rIrReg="1111" then
				rfTdo <= rBypass;
			end if;
			if rIrReg="1010" then
				rfTdo <= rDrReg(0);
			end if;
			if rTapState=SHF_IR then
				rfTdo <= rIrReg(0);
			end if;
			rfTdoOe <= '0';
			if rTapState=SHF_IR or rTapState=SHF_DR then
				rfTdoOe <= '1';
			end if;
		end if;
	end process;
	oTdo <= rfTdo when rfTdoOe='1' else 'Z';
end sim;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.jswitch_config_pkg.all;
use work.jswitch_bus_pkg.all;
use work.jswitch_internal_pkg.all;

entity jswitch_top_tb is
end jswitch_top_tb;

architecture sim of jswitch_top_tb is
	constant cJtagCycleTime : time := 100 ns;

	signal iPinTrst_n : STD_LOGIC; -- (optional)
	signal iPinTck    : STD_LOGIC;
	signal iPinTms    : STD_LOGIC;
	signal iPinTdi    : STD_LOGIC;
	signal oPinTdo    : STD_LOGIC;

	signal oSlvTrst_n : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
	signal oSlvTck    : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
	signal oSlvTms    : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
	signal oSlvTdi    : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
	signal iSlvTdo    : STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);

	signal oBusMOSI   : tJswitchBusMOSI;

	procedure pSimJtagRaw(
		constant cTmsBits : in STD_LOGIC_VECTOR;
		constant cTdiBits : in STD_LOGIC_VECTOR;
		constant cBitLen  : in POSITIVE;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		variable vTmsPos : integer;
		variable vTmsAdd : integer;
		variable vTdiPos : integer;
		variable vTdiAdd : integer;
	begin
		vTmsPos := cTmsBits'low;
		vTmsAdd := 1;
		if cTmsBits'ASCENDING then
			vTmsPos := cTmsBits'high;
			vTmsAdd := -1;
		end if;
		vTdiPos := cTdiBits'low;
		vTdiAdd := 1;
		if cTmsBits'ASCENDING then
			vTdiPos := cTdiBits'high;
			vTdiAdd := -1;
		end if;

		for i in 1 to cBitLen loop
			oTck<='0';
			oTms<=cTmsBits(vTmsPos);
			oTdi<=cTdiBits(vTdiPos);
			vTmsPos := vTmsPos + vTmsAdd;
			vTdiPos := vTdiPos + vTdiAdd;
			wait for cJtagCycleTime/2;
			oTck<='1';
			wait for cJtagCycleTime/2;
		end loop;
	end pSimJtagRaw;

	procedure pSimJtagShiftData(
		constant cDataBits : in STD_LOGIC_VECTOR;
		constant cBitLen   : in POSITIVE;
		constant cLastTms  : in BOOLEAN;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		variable vDataPos : integer;
		variable vDataAdd : integer;
	begin
		vDataPos := cDataBits'low;
		vDataAdd := 1;
		if cDataBits'ASCENDING then
			vDataPos := cDataBits'high;
			vDataAdd := -1;
		end if;
		for i in 1 to cBitLen-1 loop
			oTck<='0';
			oTms<='0';
			oTdi<=cDataBits(vDataPos);
			vDataPos:=vDataPos+vDataAdd;
			wait for cJtagCycleTime/2;
			oTck<='1';
			wait for cJtagCycleTime/2;
		end loop;
		-- Last Bit, Shift(DR|IR) -> Exit1(DR|IR)
		oTck<='0';
		if cLastTms then
			oTms<='1';
		end if;
		oTdi<=cDataBits(vDataPos);
		vDataPos:=vDataPos+vDataAdd;
		wait for cJtagCycleTime/2;
		oTck<='1';
		wait for cJtagCycleTime/2;
	end pSimJtagShiftData;

	procedure pSimJtagShiftIR(
		constant cFromRti : in boolean;
		constant cToRti   : in boolean;
		constant cDataBits : in STD_LOGIC_VECTOR;
		constant cBitLen   : in POSITIVE;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		constant cBypassCodeBits : STD_LOGIC_VECTOR(7 downto 0) := (others => '1');
	begin
		if cFromRti then
			-- RTI -> ShiftIR
			pSimJtagRaw(X"3",X"0",4,oTck,oTms,oTdi);
		else
			-- SelDR -> ShiftIR
			pSimJtagRaw(X"1",X"0",3,oTck,oTms,oTdi);
		end if;
		pSimJtagShiftData(cBypassCodeBits,8,false,oTck,oTms,oTdi);
		pSimJtagShiftData(cDataBits,cBitLen,true,oTck,oTms,oTdi);
		if cToRti then
			-- Ex1IR -> RTI
			pSimJtagRaw(X"1",X"0",2,oTck,oTms,oTdi);
		else
			-- Ex1IR -> SelDR
			pSimJtagRaw(X"3",X"0",2,oTck,oTms,oTdi);
		end if;
	end pSimJtagShiftIR;

	procedure pSimJtagShiftDR(
		constant cFromRti : in boolean;
		constant cToRti   : in boolean;
		constant cDataBits : in STD_LOGIC_VECTOR;
		constant cBitLen   : in POSITIVE;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		constant cBypassBits : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	begin
		if cFromRti then
			-- RTI -> ShiftDR
			pSimJtagRaw(X"1",X"0",3,oTck,oTms,oTdi);
		else
			-- SelDR -> ShiftDR
			pSimJtagRaw(X"0",X"0",2,oTck,oTms,oTdi);
		end if;
		pSimJtagShiftData(cBypassBits,4,false,oTck,oTms,oTdi);
		pSimJtagShiftData(cDataBits,cBitLen,true,oTck,oTms,oTdi);
		if cToRti then
			-- Ex1DR -> RTI
			pSimJtagRaw(X"1",X"0",2,oTck,oTms,oTdi);
		else
			-- Ex1DR -> SelDR
			pSimJtagRaw(X"3",X"0",2,oTck,oTms,oTdi);
		end if;
	end pSimJtagShiftDR;

	procedure pSimJtagShiftDRWithPause(
		constant cFromRti : in boolean;
		constant cToRti   : in boolean;
		constant cDataBits: in STD_LOGIC_VECTOR;
		constant cBitLen  : in POSITIVE;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		constant cBypassBits : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
		variable vOfs,vLen : integer;
	begin
		if cFromRti then
			-- RTI -> ShiftDR
			pSimJtagRaw(X"1",X"0",3,oTck,oTms,oTdi);
		else
			-- SelDR -> ShiftDR
			pSimJtagRaw(X"0",X"0",2,oTck,oTms,oTdi);
		end if;
		pSimJtagShiftData(cBypassBits,4,false,oTck,oTms,oTdi);
		vOfs := 0;
		while vOfs<cBitLen loop
			vLen := cBitLen - vOfs;
			if vLen>4 then
				vLen := 4;
			end if;
			pSimJtagShiftData(cDataBits(vOfs to vOfs+vLen-1),vLen,true,oTck,oTms,oTdi);
			vOfs := vOfs + vLen;
			if vOfs<cBitLen then
				-- Ex1DR -> PsDR -> Ex2DR -> ShiftDR
				pSimJtagRaw(X"2",X"0",3,oTck,oTms,oTdi);
			else
				if cToRti then
					-- Ex1DR -> RTI
					pSimJtagRaw(X"1",X"0",2,oTck,oTms,oTdi);
				else
					-- Ex1DR -> SelDR
					pSimJtagRaw(X"3",X"0",2,oTck,oTms,oTdi);
				end if;
			end if;
		end loop;
	end pSimJtagShiftDRWithPause;

	procedure pSimBusSetAddr(
		constant cFromRti : in boolean;
		constant cToRti   : in boolean;
		constant cBank    : in integer;
		constant cAddr    : in integer;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		variable vDR : STD_LOGIC_VECTOR(15 downto 0);
	begin
		pSimJtagShiftIR(cFromRti,false,STD_LOGIC_VECTOR(cJswitchIRSetAddr),4,oTck,oTms,oTdi);
		vDR := (others => '0');
		vDR( 2 downto  0) := STD_LOGIC_VECTOR(TO_UNSIGNED(cAddr,3));
		vDR(15 downto 12) := STD_LOGIC_VECTOR(TO_UNSIGNED(cBank,4));
		pSimJtagShiftDR(false,cToRti,vDR,16,oTck,oTms,oTdi);
	end pSimBusSetAddr;

	procedure pSimBusWrite(
		constant cFromRti : in boolean;
		constant cToRti   : in boolean;
		constant cData    : in STD_LOGIC_VECTOR;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		variable vDR : STD_LOGIC_VECTOR(15 downto 0);
	begin
		pSimJtagShiftIR(cFromRti,false,STD_LOGIC_VECTOR(cJswitchIRWrite),4,oTck,oTms,oTdi);
		vDR := cData;
		pSimJtagShiftDR(false,cToRti,vDR,16,oTck,oTms,oTdi);
	end pSimBusWrite;

	procedure pSimBusSetAddrWr(
		constant cFromRti : in boolean;
		constant cToRti   : in boolean;
		constant cBank    : in integer;
		constant cAddr    : in integer;
		constant cData    : in STD_LOGIC_VECTOR;
		signal oTck : out STD_LOGIC;
		signal oTms : out STD_LOGIC;
		signal oTdi : out STD_LOGIC
	) is
		variable vDR   : STD_LOGIC_VECTOR(31 downto 0);
	begin
		pSimJtagShiftIR(cFromRti,false,STD_LOGIC_VECTOR(cJswitchIRSetAddrWr),4,oTck,oTms,oTdi);
		vDR := (others => '0');
		vDR(15 downto 0) := cData;
		vDR(18 downto 16) := STD_LOGIC_VECTOR(TO_UNSIGNED(cAddr,3));
		vDR(31 downto 28) := STD_LOGIC_VECTOR(TO_UNSIGNED(cBank,4));
		pSimJtagShiftDR(false,cToRti,vDR,32,oTck,oTms,oTdi);
	end pSimBusSetAddrWr;

begin
	pJtag: process
	begin
		iPinTrst_n <= '1';
		iPinTck<='0';
		iPinTms<='1';
		iPinTdi<='1';
		-- Reset TAP controller, go to TLR
		pSimJtagRaw(X"0FF",X"0FF",12,iPinTck,iPinTms,iPinTdi);
		-- Shift RST instruction into JTAG Switcher (precede by BYPASS for other TAPs)
		pSimJtagShiftIR(true,true,X"6FFFFFFF",32,iPinTck,iPinTms,iPinTdi);
		-- 8 cycles in run-test/idle
		pSimJtagRaw(X"00",X"00",8,iPinTck,iPinTms,iPinTdi);

		-- Set address to write to
		pSimBusSetAddr(true,false,0,cJSwitchBusAddrSel,iPinTck,iPinTms,iPinTdi);
		-- Write to Select Register, select TAP 1
		pSimBusWrite(false,true,X"0001",iPinTck,iPinTms,iPinTdi);
		-- 8 cycles in run-test/idle to activate selection
		pSimJtagRaw(X"00",X"00",8,iPinTck,iPinTms,iPinTdi);

		-- go through TLR->RTI, should load IDCODE instruction in all included TAPs.
		pSimJtagRaw(X"3F",X"00",8,iPinTck,iPinTms,iPinTdi);
		-- Should output 2 32-bit IDCODEs on oTdo
		pSimJtagShiftDR(true,true,X"0000000000000000",64,iPinTck,iPinTms,iPinTdi);

		-- Write 0x0001 to TDO Sync register, enable TDO Sync for TAP 1
		pSimBusSetAddrWr(true,true,0,cJSwitchBusAddrTdoSync,X"0001",iPinTck,iPinTms,iPinTdi);

		-- go through TLR->RTI, should load IDCODE instruction in all included TAPs.
		pSimJtagRaw(X"3F",X"00",8,iPinTck,iPinTms,iPinTdi);
		-- Should output 2 32-bit IDCODEs on oTdo, shifted by 1
		pSimJtagShiftDRWithPause(true,true,X"00000000000000000",68,iPinTck,iPinTms,iPinTdi);

		-- Write 0x0002 to Select register, deselect TAP 1
		pSimBusSetAddrWr(true,true,0,cJSwitchBusAddrSel,X"0002",iPinTck,iPinTms,iPinTdi);
		pSimJtagRaw(X"000",X"000",12,iPinTck,iPinTms,iPinTdi);
		-- Here all slave should be disabled

		-- go through TLR->RTI, should load IDCODE instruction in all included TAPs.
		pSimJtagRaw(X"3F",X"00",8,iPinTck,iPinTms,iPinTdi);
		-- Should output 32-bit IDCODE + 32 bit 0x0 on oTdo
		pSimJtagShiftDR(true,true,X"0000000000000000",64,iPinTck,iPinTms,iPinTdi);

		-- Prepare to select slave 2 in stealth mode
		pSimBusSetAddrWr(true,false,0,cJSwitchBusAddrSel,X"0004",iPinTck,iPinTms,iPinTdi);
		pSimBusSetAddrWr(false,true,15,cJSwitchBusAddrCtlA,X"0001",iPinTck,iPinTms,iPinTdi);
		-- and now switch with stealth mode...
		pSimJtagRaw(X"0000",X"0000",16,iPinTck,iPinTms,iPinTdi);

		-- go through TLR->RTI, should load IDCODE instruction in all included TAPs.
		pSimJtagRaw(X"3F",X"00",8,iPinTck,iPinTms,iPinTdi);
		-- Should output 32-bit IDCODE + 32 bit 0x0 on oTdo
		pSimJtagShiftDR(true,true,X"0000000000000000",64,iPinTck,iPinTms,iPinTdi);

		-- should be ignore, because we are in stealth mode...
		pSimBusSetAddrWr(true,true,15,cJSwitchBusAddrCtlA,X"0002",iPinTck,iPinTms,iPinTdi);
		pSimJtagRaw(X"0000",X"0000",16,iPinTck,iPinTms,iPinTdi);

		-- Goto ShiftIR
		pSimJtagRaw(X"03",X"0",4,iPinTck,iPinTms,iPinTdi);
		-- random pre-fix
		pSimJtagRaw(X"00000000",X"12345678",32,iPinTck,iPinTms,iPinTdi);
		-- 0x00 followed by magic sequence
		pSimJtagRaw(X"000000000000000000",X"19A63957525FCFB700",72,iPinTck,iPinTms,iPinTdi);
		pSimJtagRaw(X"0000000000000000"  ,X"8143641E2D6113BD"  ,64,iPinTck,iPinTms,iPinTdi);
		-- a bunch of 0xFF then goto RTI
		pSimJtagRaw(  X"6000000000000000",  X"FFFFFFFFFFFFFFFF",64,iPinTck,iPinTms,iPinTdi);
		-- 12 cycles in RTI
		pSimJtagRaw(X"000",X"000",12,iPinTck,iPinTms,iPinTdi);
		-- Should output 32-bit IDCODE + 32 bit 0x0 on oTdo

		-- go through TLR->RTI, should load IDCODE instruction in all included TAPs.
		pSimJtagRaw(X"3F",X"00",8,iPinTck,iPinTms,iPinTdi);
		pSimJtagShiftDR(true,true,X"0000000000000000",64,iPinTck,iPinTms,iPinTdi);
		wait for cJtagCycleTime*4;
		wait;
	end process;

	sDut : entity work.jswitch_top
	port map (
		iPinTrst_n => iPinTrst_n,  -- : in STD_LOGIC; -- (optional)
		iPinTck    => iPinTck,     -- : in STD_LOGIC;
		iPinTms    => iPinTms,     -- : in STD_LOGIC;
		iPinTdi    => iPinTdi,     -- : in STD_LOGIC;
		oPinTdo    => oPinTdo,     -- : out STD_LOGIC;

		oSlvTrst_n => oSlvTrst_n,  -- : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTck    => oSlvTck,     -- : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTms    => oSlvTms,     -- : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		oSlvTdi    => oSlvTdi,     -- : out STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);
		iSlvTdo    => iSlvTdo,     -- : in  STD_LOGIC_VECTOR(cJswitchSlavesNr downto 1);

		oBusMOSI => oBusMOSI,
		iBusMISO => cJswitchBusMISORst

	);

	-- Just to have better visualization of TAP state send via PCB TAP.
	sTapState : entity work.sim_jtag_slave
	generic map (
		gIdcode => X"00000000"
	)
	port map (
		iTck => iPinTck,
		iTms => iPinTms,
		iTdi => '1',
		oTdo => open
	);

	sSlave1 : entity work.sim_jtag_slave
	generic map (
		gIdcode => X"95595559"
	)
	port map (
		iTck => oSlvTck(1),
		iTms => oSlvTms(1),
		iTdi => oSlvTdi(1),
		oTdo => iSlvTdo(1)
	);
	sSlave2 : entity work.sim_jtag_slave
	generic map (
		gIdcode => X"99999999"
	)
	port map (
		iTck => oSlvTck(2),
		iTms => oSlvTms(2),
		iTdi => oSlvTdi(2),
		oTdo => iSlvTdo(2)
	);
end sim;
