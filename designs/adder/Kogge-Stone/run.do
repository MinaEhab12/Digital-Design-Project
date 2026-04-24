vlib work
vlog *.*v
vsim -voptargs=+acc work.Kogge_Stone_32Bits_tb
do wave.do
run -all