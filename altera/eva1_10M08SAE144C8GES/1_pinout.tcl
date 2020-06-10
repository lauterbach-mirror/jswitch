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

set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"

set_location_assignment PIN_58  -to oVtref

set_location_assignment PIN_45  -to iPinTck
set_location_assignment PIN_50  -to iPinTms
set_location_assignment PIN_52  -to iPinTdi
set_location_assignment PIN_39  -to oPinTdo
set_location_assignment PIN_57  -to iPinTrst_n

set_location_assignment PIN_89  -to oSlvTck[1]
set_location_assignment PIN_92  -to oSlvTms[1]
set_location_assignment PIN_93  -to oSlvTdi[1]
set_location_assignment PIN_91  -to iSlvTdo[1]
set_location_assignment PIN_98  -to oSlvTrst_n[1]

set_location_assignment PIN_110 -to oSlvTck[2]
set_location_assignment PIN_111 -to oSlvTms[2]
set_location_assignment PIN_119 -to oSlvTdi[2]
set_location_assignment PIN_118 -to iSlvTdo[2]
set_location_assignment PIN_113 -to oSlvTrst_n[2]

set_location_assignment PIN_132 -to oLeds[1]
set_location_assignment PIN_134 -to oLeds[2]
set_location_assignment PIN_135 -to oLeds[3]
set_location_assignment PIN_140 -to oLeds[4]
set_location_assignment PIN_141 -to oLeds[5]


set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to iPinTck
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to iPinTms
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to iPinTdi
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to iPinTrst_n

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to iSlvTdo[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to iSlvTdo[2]


set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oPinTdo

set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTck[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTms[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTdi[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTrst_n[1]

set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTck[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTms[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTdi[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oSlvTrst_n[2]

set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to oLeds[*]
