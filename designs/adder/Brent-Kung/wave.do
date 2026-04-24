onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color {Medium Spring Green} /tb_brent_kung_32/dut/clk
add wave -noupdate -color Yellow /tb_brent_kung_32/dut/rst_n
add wave -noupdate -expand -group Inputs /tb_brent_kung_32/dut/A
add wave -noupdate -expand -group Inputs /tb_brent_kung_32/dut/B
add wave -noupdate -expand -group Inputs /tb_brent_kung_32/dut/C
add wave -noupdate -expand -group Inputs /tb_brent_kung_32/dut/Cin
add wave -noupdate -expand -group Inputs -color Cyan /tb_brent_kung_32/dut/valid_in
add wave -noupdate -expand -group Output /tb_brent_kung_32/dut/Sum
add wave -noupdate -expand -group Output -color Cyan /tb_brent_kung_32/dut/valid_out
add wave -noupdate -expand -group Output -color Magenta /tb_brent_kung_32/dut/overflow
add wave -noupdate -expand -group Output -color Magenta /tb_brent_kung_32/dut/Cout
add wave -noupdate -group logic /tb_brent_kung_32/dut/G
add wave -noupdate -group logic /tb_brent_kung_32/dut/P
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {34986 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {52500 ps}
