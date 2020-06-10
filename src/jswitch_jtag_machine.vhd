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
use work.jswitch_internal_pkg.all;

entity jswitch_jtag_machine is
	port (
		iTrst_n : in  STD_LOGIC := '1';
		iTck    : in  STD_LOGIC;

		-- sampled on rising edge of iTck
		iTms    : in  STD_LOGIC;

		-- synchronized to rising edge of iTck
		oState  : out tJswitchState
	);
end jswitch_jtag_machine;

architecture rtl of jswitch_jtag_machine is

signal rState : tJswitchState;
signal wNext  : tJswitchState;

begin
	pLogic:
	process(iTms,rState)
		variable vNext : tJswitchState;
	begin
		vNext.state  := cJswitchJtagTLR;
		vNext.decode := (others => '0');

		case rState.state is
			when cJswitchJtagRTI =>
				vNext.state := cJswitchJtagRTI;
				if iTms='1' then
					vNext.state := cJswitchJtagSelDR;
				end if;

			when cJswitchJtagSelDR =>
				vNext.state := cJswitchJtagCapDR;
				if iTms='1' then
					vNext.state := cJswitchJtagSelIR;
				end if;
			when cJswitchJtagCapDR =>
				vNext.state := cJswitchJtagShftDR;
				if iTms='1' then
					vNext.state := cJswitchJtagEx1DR;
				end if;
			when cJswitchJtagShftDR =>
				vNext.state := cJswitchJtagShftDR;
				if iTms='1' then
					vNext.state := cJswitchJtagEx1DR;
				end if;
			when cJswitchJtagEx1DR =>
				vNext.state := cJswitchJtagPausDR;
				if iTms='1' then
					vNext.state := cJswitchJtagUpdDR;
				end if;
			when cJswitchJtagPausDR =>
				vNext.state := cJswitchJtagPausDR;
				if iTms='1' then
					vNext.state := cJswitchJtagEx2DR;
				end if;
			when cJswitchJtagEx2DR =>
				vNext.state := cJswitchJtagShftDR;
				if iTms='1' then
					vNext.state := cJswitchJtagUpdDR;
				end if;
			when cJswitchJtagUpdDR =>
				vNext.state := cJswitchJtagRTI;
				if iTms='1' then
					vNext.state := cJswitchJtagSelDR;
				end if;

			when cJswitchJtagSelIR =>
				vNext.state := cJswitchJtagCapIR;
				if iTms='1' then
					vNext.state := cJswitchJtagTLR;
				end if;
			when cJswitchJtagCapIR =>
				vNext.state := cJswitchJtagShftIR;
				if iTms='1' then
					vNext.state := cJswitchJtagEx1IR;
				end if;
			when cJswitchJtagShftIR =>
				vNext.state := cJswitchJtagShftIR;
				if iTms='1' then
					vNext.state := cJswitchJtagEx1IR;
				end if;
			when cJswitchJtagEx1IR =>
				vNext.state := cJswitchJtagPausIR;
				if iTms='1' then
					vNext.state := cJswitchJtagUpdIR;
				end if;
			when cJswitchJtagPausIR =>
				vNext.state := cJswitchJtagPausIR;
				if iTms='1' then
					vNext.state := cJswitchJtagEx2IR;
				end if;
			when cJswitchJtagEx2IR =>
				vNext.state := cJswitchJtagShftIR;
				if iTms='1' then
					vNext.state := cJswitchJtagUpdIR;
				end if;
			when cJswitchJtagUpdIR =>
				vNext.state := cJswitchJtagRTI;
				if iTms='1' then
					vNext.state := cJswitchJtagSelDR;
				end if;

			-- Use "when others" to make simulation happy.
			-- Should be equivalent to "when cJswitchJtagTLR =>"
			when others =>
				vNext.state := cJswitchJtagRTI;
				if iTms='1' then
					vNext.state := cJswitchJtagTLR;
				end if;
		end case;

		for i in vNext.decode'range loop
			if vNext.state=i then
				vNext.decode(i) := '1';
			end if;
		end loop;

		wNext <= vNext;
	end process;

	pReg :
	process(iTrst_n, iTck)
	begin
		if iTrst_n = '0' then
			rState.state  <= cJswitchJtagTLR;
			rState.decode <= (0 => '1', others => '0');
		elsif rising_edge(iTck) then
			rState <= wNext;
		end if;
	end process;
	oState <= rState;
end rtl;
