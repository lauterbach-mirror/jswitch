vcom jswitch_config_pkg.vhd
vcom ../src/jswitch_bus_pkg.vhd
vcom ../src/jswitch_internal_pkg.vhd
vcom ../src/jswitch_jtag_machine.vhd
vcom ../src/jswitch_jtag_shift.vhd
vcom ../src/jswitch_int_busmaster.vhd
vcom ../src/jswitch_regs.vhd
vcom ../src/jswitch_top.vhd
vcom jswitch_top_tb.vhd

vsim work.jswitch_top_tb
source msim_wave_top.tcl
