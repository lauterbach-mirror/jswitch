# The MIT License

# Copyright (c) 2018 Lauterbach GmbH, Ingo Rohloff

# Permission is hereby granted, free of charge,
# to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to
# deal in the Software without restriction, including
# without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom
# the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# JTAG clock from debugger. Assume 20Mhz clock
create_clock -name tqTck     -period 50.000ns -waveform { 0 25 } iPinTck

derive_clock_uncertainty

set_input_delay -clock_fall -clock tqTck -min -1.0 iPinTms
set_input_delay -clock_fall -clock tqTck -max  1.0 iPinTms

set_input_delay -clock_fall -clock tqTck -min -1.0 iPinTdi
set_input_delay -clock_fall -clock tqTck -max  1.0 iPinTdi

set_output_delay            -clock tqTck -min -1.0 oPinTdo
set_output_delay            -clock tqTck -max  1.0 oPinTdo

set_false_path -from iPinTrst_n

create_generated_clock -name tqSlvTck1 -source iPinTck {oSlvTck[1]}

set_output_delay      -clock tqSlvTck1 -min -1.0 {oSlvTms[1]}
set_output_delay      -clock tqSlvTck1 -max  1.0 {oSlvTms[1]}

set_output_delay      -clock tqSlvTck1 -min -1.0 {oSlvTdi[1]}
set_output_delay      -clock tqSlvTck1 -max  1.0 {oSlvTdi[1]}

set_input_delay  -clock_fall -clock tqSlvTck1 -min -1.0 {iSlvTdo[1]}
set_input_delay  -clock_fall -clock tqSlvTck1 -max  1.0 {iSlvTdo[1]}

set_false_path -to {oSlvTrst_n[1]}



create_generated_clock -name tqSlvTck2 -source iPinTck {oSlvTck[2]}

set_output_delay      -clock tqSlvTck2 -min -1.0 {oSlvTms[2]}
set_output_delay      -clock tqSlvTck2 -max  1.0 {oSlvTms[2]}

set_output_delay      -clock tqSlvTck2 -min -1.0 {oSlvTdi[2]}
set_output_delay      -clock tqSlvTck2 -max  1.0 {oSlvTdi[2]}

set_input_delay  -clock_fall -clock tqSlvTck2 -min -1.0 {iSlvTdo[2]}
set_input_delay  -clock_fall -clock tqSlvTck2 -max  1.0 {iSlvTdo[2]}

set_false_path -to {oSlvTrst_n[2]}
