onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /jswitch_top_tb/iPinTck
add wave -noupdate /jswitch_top_tb/iPinTms
add wave -noupdate /jswitch_top_tb/iPinTdi
add wave -noupdate /jswitch_top_tb/oPinTdo
add wave -noupdate /jswitch_top_tb/sTapState/rTapState
add wave -noupdate /jswitch_top_tb/sDut/sJtagShift/rIrReg
add wave -noupdate /jswitch_top_tb/sDut/sJtagShift/rStealthModePre
add wave -noupdate /jswitch_top_tb/sDut/sJtagShift/rStealthMode
add wave -noupdate -expand /jswitch_top_tb/sDut/wBusMOSI
add wave -noupdate -expand -subitemconfig {/jswitch_top_tb/sDut/sRegs/rRegs(0) -expand /jswitch_top_tb/sDut/sRegs/rRegs(0).tdoSync -expand} /jswitch_top_tb/sDut/sRegs/rRegs
add wave -noupdate /jswitch_top_tb/sDut/rfSlvSel
add wave -noupdate /jswitch_top_tb/oSlvTck(1)
add wave -noupdate /jswitch_top_tb/oSlvTms(1)
add wave -noupdate /jswitch_top_tb/oSlvTdi(1)
add wave -noupdate /jswitch_top_tb/iSlvTdo(1)
add wave -noupdate /jswitch_top_tb/sSlave1/rTapState
add wave -noupdate /jswitch_top_tb/oSlvTck(2)
add wave -noupdate /jswitch_top_tb/oSlvTms(2)
add wave -noupdate /jswitch_top_tb/oSlvTdi(2)
add wave -noupdate /jswitch_top_tb/iSlvTdo(2)
add wave -noupdate /jswitch_top_tb/sSlave2/rTapState
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {33800000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 330
configure wave -valuecolwidth 127
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {29569507 ps} {46103403 ps}
