########################## USER-DEFINED SETTINGS — CHANGE HERE EACH RUN ##########################
set RUN_NAME   "fifo_ks_top"
#set RUN_NAME   "fifo_bk_top"
set OUTPUT_DIR "./$RUN_NAME"

file mkdir $OUTPUT_DIR

########################## Define Top Module ############################

#set top_module fifo_bk_top
set top_module fifo_ks_top
#set top_module Kogge_Stone_32Bits
##################### Define Working Library Directory ##################

define_design_lib work -path ./work

############################ Libraries ##################################

lappend search_path /home/abdelazeem/Desktop/CIM_GP/digital_task/rtl/adders
lappend search_path /home/abdelazeem/Desktop/CIM_GP/digital_task/rtl/FIFO
lappend search_path /home/abdelazeem/Desktop/CIM_GP/digital_task/rtl/Top
lappend search_path /home/abdelazeem/Desktop/CIM_GP/libs

set SSLIB "saed14rvt_base_ss0p72v125c.db"
set TTLIB "saed14rvt_base_tt0p8v25c.db"
set FFLIB "saed14rvt_base_ff0p88vm40c.db"

set target_library [list $SSLIB $TTLIB $FFLIB]
set link_library   [list * $SSLIB $TTLIB $FFLIB]

######################## Reading RTL Files ##############################

# Brent kung
analyze -format sverilog Brent-Kung.sv

# Kogge stone
analyze -format sverilog calc_carry.v
analyze -format sverilog dot_operator.v
analyze -format sverilog pre_process.v
analyze -format sverilog post_process.v
analyze -format sverilog Kogge_Stone_32Bits.v

# FIFO
analyze -format sverilog binary_to_gray_converter.v
analyze -format sverilog DUAL_PORT_MEM.v
analyze -format sverilog WRITE_PTR.v
analyze -format sverilog READ_PTR.v
analyze -format sverilog SYNCHRONIZER.v
analyze -format sverilog ASYNC_FIFO.v

# TOPs
analyze -format sverilog fifo_bk_top.v
analyze -format sverilog fifo_ks_top.v

###################### Elaborate / Link / Check #########################

elaborate $top_module
link
check_design

############################# Constraints ################################

# Write clock
create_clock -name wclk -period 10 -waveform {0 5} [get_ports wclk]

# Read clock
create_clock -name rclk -period 10 -waveform {0 5} [get_ports rclk]

# Async clock groups
set_clock_groups -asynchronous \
    -group [get_clocks wclk] \
    -group [get_clocks rclk]

# Explicit false paths
set_false_path -from [get_clocks wclk] -to [get_clocks rclk]
set_false_path -from [get_clocks rclk] -to [get_clocks wclk]

# Clock uncertainty
set_clock_uncertainty -setup 0.3  [get_clocks *]
set_clock_uncertainty -hold  0.15 [get_clocks *]

# Clock transition
set_clock_transition 0.03 [get_clocks *]

######################## Operating Conditions ############################

set_operating_conditions \
    -min_library saed14rvt_base_ff0p88vm40c \
    -min ff0p88vm40c \
    -max_library saed14rvt_base_ss0p72v125c \
    -max ss0p72v125c

######################## Input Delays ###################################

set_input_delay 0.1 -clock wclk [get_ports {winc wdata[*]}]
set_input_delay 0.1 -clock rclk [get_ports {A[*] Cin}]

######################## Output Delays ##################################

# Read-domain outputs
set_output_delay 0.1 -clock rclk [get_ports {Sum[*] overflow valid_out empty}]

# Write-domain outputs
set_output_delay 0.1 -clock wclk [get_ports wfull]

############################# HOLD FIX ###################################

set_fix_hold [all_clocks]

############################# Compile ####################################

compile -map_effort high

############################# Reports ####################################

report_area   -hierarchy  > $OUTPUT_DIR/${RUN_NAME}_area.rpt
report_power  -hierarchy  > $OUTPUT_DIR/${RUN_NAME}_power.rpt
report_timing -max_paths 200 -delay_type min > $OUTPUT_DIR/${RUN_NAME}_hold.rpt
report_timing -max_paths 200 -delay_type max > $OUTPUT_DIR/${RUN_NAME}_setup.rpt
report_clock -attributes  > $OUTPUT_DIR/${RUN_NAME}_clocks.rpt
report_constraint -all_violators > $OUTPUT_DIR/${RUN_NAME}_constraints.rpt
report_clocks > $OUTPUT_DIR/${RUN_NAME}_clks.rpt
report_units  > $OUTPUT_DIR/${RUN_NAME}_units.rpt

############################# Netlist ####################################

write -hierarchy -format verilog -output $OUTPUT_DIR/${RUN_NAME}_mapped.v
write_sdc $OUTPUT_DIR/${RUN_NAME}.sdc

############################# Exit #######################################

exit
