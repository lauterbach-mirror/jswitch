# JTAG Switcher

JTAG Switcher is open source VHDL code intended to be implemented in an FPGA.

JTAG Switcher provides a solution how to connect multiple JTAG TAPs (JTAG Test Access Ports)
from multiple chips on a PCB (Printed Circuit Board) to a single board wide TAP to 
which a suitable tool (like a JTAG debugger) might be connected.

The approach with JTAG Switcher is to connect multiple JTAG TAPs from multiple chips on
the PCB in a point-to-point fashion to an FPGA which contains the JTAG Switcher circuitry.
The board wide JTAG connector is connected to the same FPGA.
The JTAG Switcher circuitry routes the signals from the board wide JTAG connector to the 
various JTAG TAPs of the chips on the PCB.

JTAG Switcher was implemented at [Lauterbach](https://www.lauterbach.com).

Detailed documentation can be found here:
[JTAG Switcher reference manual](https://gitlab.com/lauterbach/jswitch/uploads/b92ca41bcb0a7fcc106a5c4592971ee5/jswitch_doc_20200610.pdf)
[JTAG Switcher presentation](https://gitlab.com/lauterbach/jswitch/uploads/67fabf7b82face2d6fb3df6fb0150cb5/jswitch_beamer_20200610.pdf)
