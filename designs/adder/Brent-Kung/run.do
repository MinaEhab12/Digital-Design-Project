vdel -all
vlib work
vmap work work

vlog -sv +acc Brent-Kung.sv
vlog -sv +acc tb.sv

vsim -voptargs=+acc work.tb_brent_kung_32
do wave.do

run -all