########################## USER-DEFINED SETTINGS — CHANGE HERE EACH RUN ##########################
#set RUN_NAME   "Brent-kung"  
set RUN_NAME   "Kogge_Stone"     
set OUTPUT_DIR "./$RUN_NAME"
file mkdir $OUTPUT_DIR    
########################## Define Top Module ############################
#set top_module brent_kung_32
set top_module Kogge_Stone_32Bits

##################### Define Working Library Directory ##################
define_design_lib work -path ./work

################## Libraries ############################################
lappend search_path /home/abdelazeem/Desktop/CIM_GP/digital_task/rtl
lappend search_path /home/abdelazeem/Desktop/CIM_GP/libs

set SSLIB "saed14rvt_base_ss0p72v125c.db"
set TTLIB "saed14rvt_base_tt0p8v25c.db"
set FFLIB "saed14rvt_base_ff0p88vm40c.db"

set target_library [list $SSLIB $TTLIB $FFLIB]   
set link_library   [list * $SSLIB $TTLIB $FFLIB] 

######################## Reading RTL Files ##############################
analyze -format sverilog Brent-Kung.sv
analyze -format verilog calc_carry.v
analyze -format verilog dot_operator.v
analyze -format verilog pre_process.v
analyze -format verilog post_process.v
analyze -format verilog Kogge_Stone_32Bits.v

###################### Elaborate / Link / Check #########################
elaborate $top_module
link
check_design

############################# Constraints ################################
create_clock -name clk -period 10 -waveform {0 5} [get_ports clk]

set_clock_uncertainty -setup 0.3  [get_clocks *]
set_clock_uncertainty -hold  0.15 [get_clocks *]
set_clock_transition  0.03        [get_clocks *]

set_operating_conditions \
    -min_library saed14rvt_base_ff0p88vm40c \
    -min ff0p88vm40c \
    -max_library saed14rvt_base_ss0p72v125c \
    -max ss0p72v125c

set_input_delay  0.1 -clock clk \
    [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0.1 -clock clk [all_outputs]

############################# HOLD FIX ###################################
set_fix_hold [all_clocks]

############################# Compile ####################################
compile -map_effort high

############################# Reports ####################################
report_area       -hierarchy     > $OUTPUT_DIR/${RUN_NAME}_area.rpt
report_power      -hierarchy     > $OUTPUT_DIR/${RUN_NAME}_power.rpt
report_timing -max_paths 200 -delay_type min > $OUTPUT_DIR/${RUN_NAME}_hold.rpt
report_timing -max_paths 200 -delay_type max > $OUTPUT_DIR/${RUN_NAME}_setup.rpt
report_clock      -attributes    > $OUTPUT_DIR/${RUN_NAME}_clocks.rpt
report_constraint -all_violators > $OUTPUT_DIR/${RUN_NAME}_constraints.rpt
report_clocks                    > $OUTPUT_DIR/${RUN_NAME}_clks.rpt
report_units                     > $OUTPUT_DIR/${RUN_NAME}_units.rpt

exit
