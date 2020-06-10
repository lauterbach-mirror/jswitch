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

puts "myprjdir: $myprjdir"
# project specific configuration settings.
prj_src add $myprjdir/../jswitch_config_pkg.vhd
prj_src add $myprjdir/../../../src/jswitch_config_pkg_body.vhd
prj_src add $myprjdir/../../../src/jswitch_bus_pkg.vhd
prj_src add $myprjdir/../../../src/jswitch_internal_pkg.vhd
prj_src add $myprjdir/../../../src/jswitch_jtag_machine.vhd
prj_src add $myprjdir/../../../src/jswitch_jtag_shift.vhd
prj_src add $myprjdir/../../../src/jswitch_int_busmaster.vhd
prj_src add $myprjdir/../../../src/jswitch_regs.vhd
prj_src add $myprjdir/../../../src/jswitch_top.vhd
prj_src add $myprjdir/../bus_leds.vhd
prj_src add $myprjdir/../toplevel.vhd
