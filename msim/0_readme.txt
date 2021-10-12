An example how to simulate JTAG Switcher in ModelSim.

1) Start ModelSim GUI

2) In the TCL console of ModelSim change directory
   to the directory here.

      cd ..../jswitch/msim

3) In the TCL console of ModelSim execute

      source msim_start.tcl

   This should create a ModelSim simulation model,
   start simulation and configure a suitable waveform window.

4) In the TCL console of ModelSim execute

      run -all

   This runs the full simulation.
   See the code in "jswitch_top_tb.vhd" to see what's simulated.
