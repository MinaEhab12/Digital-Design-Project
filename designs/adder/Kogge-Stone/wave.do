onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color {Spring Green} /Kogge_Stone_32Bits_tb/DUT/clk
add wave -noupdate -color Gold /Kogge_Stone_32Bits_tb/DUT/rst_n
add wave -noupdate -expand -group Inputs -color White -radix decimal /Kogge_Stone_32Bits_tb/DUT/A
add wave -noupdate -expand -group Inputs -color White -radix decimal /Kogge_Stone_32Bits_tb/DUT/B
add wave -noupdate -expand -group Inputs -color White /Kogge_Stone_32Bits_tb/DUT/Cin
add wave -noupdate -expand -group Inputs -color White /Kogge_Stone_32Bits_tb/DUT/valid_in
add wave -noupdate -expand -group Outputs -color Cyan -radix decimal /Kogge_Stone_32Bits_tb/DUT/Sum
add wave -noupdate -expand -group Outputs -color Cyan /Kogge_Stone_32Bits_tb/DUT/overflow
add wave -noupdate -expand -group Outputs -color Cyan /Kogge_Stone_32Bits_tb/DUT/valid_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2507023 ps} 0}
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
WaveRestoreZoom {2475400 ps} {2743400 ps}
