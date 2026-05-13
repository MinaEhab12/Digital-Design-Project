########################## USER-DEFINED SETTINGS — CHANGE HERE EACH RUN ##########################
#
# Set ADDER to either:
#   "KS"  → Kogge-Stone  (Kogge_Stone_32Bits)
#   "BK"  → Brent-Kung   (brent_kung_32)
#
set ADDER "BK"

########################## Derive names from flag #################################################

if { $ADDER eq "KS" } {
    set RUN_NAME   "Kogge_Stone"
    set top_module "Kogge_Stone_32Bits"
} elseif { $ADDER eq "BK" } {
    set RUN_NAME   "Brent_Kung"
    set top_module "brent_kung_32"
} else {
    error "Unknown ADDER value '$ADDER'. Use KS or BK."
}

set OUTPUT_DIR "./$RUN_NAME"
file mkdir $OUTPUT_DIR

##################### Define Working Library Directory ###########################################

define_design_lib work -path ./work

############################ Libraries ###########################################################

lappend search_path /home/abdelazeem/Desktop/CIM_GP/digital_task/rtl/adders
lappend search_path /home/abdelazeem/Desktop/CIM_GP/libs

set SSLIB "saed14rvt_base_ss0p72v125c.db"
set TTLIB "saed14rvt_base_tt0p8v25c.db"
set FFLIB "saed14rvt_base_ff0p88vm40c.db"

set target_library [list $SSLIB $TTLIB $FFLIB]
set link_library   [list * $SSLIB $TTLIB $FFLIB]

######################## Reading RTL Files #######################################################
#
# DIFFERENCE 1 — RTL files:
#   KS: 5 submodule .v files + top .v  (hierarchical design)
#   BK: single self-contained .sv file (flat design)
#
if { $ADDER eq "KS" } {
    analyze -format sverilog calc_carry.v
    analyze -format sverilog dot_operator.v
    analyze -format sverilog pre_process.v
    analyze -format sverilog post_process.v
    analyze -format sverilog Kogge_Stone_32Bits.v
} else {
    # BK is a single SystemVerilog file — no submodules
    analyze -format sverilog Brent-Kung.sv
}

###################### Elaborate / Link / Check ##################################################

elaborate $top_module
link
check_design

############################# Constraints ########################################################

# Single synchronous clock — identical for both adders
create_clock -name clk -period 10 -waveform {0 5} [get_ports clk]

set_clock_uncertainty -setup 0.3  [get_clocks clk]
set_clock_uncertainty -hold  0.15 [get_clocks clk]
set_clock_transition        0.03  [get_clocks clk]

######################## Operating Conditions ####################################################

set_operating_conditions \
    -min_library saed14rvt_base_ff0p88vm40c \
    -min ff0p88vm40c \
    -max_library saed14rvt_base_ss0p72v125c \
    -max ss0p72v125c

######################## Input Delays ############################################################
#
# Identical for both adders
#
set_input_delay 0.1 -clock clk [get_ports {A[*] B[*] Cin valid_in}]

# rst_n is asynchronous — no timing arc needed
set_false_path -from [get_ports rst_n]

######################## Output Delays ###########################################################
#
# DIFFERENCE 2 — Output ports:
#   KS has Cout (carry-out register); BK does NOT
#   Both share: Sum[*], overflow, valid_out
#
set_output_delay 0.1 -clock clk [get_ports {Sum[*] overflow valid_out}]

if { $ADDER eq "KS" } {
    # Kogge-Stone exposes Cout as a registered output — BK does not have this port
    set_output_delay 0.1 -clock clk [get_ports Cout]
}

############################# HOLD FIX ###########################################################

set_fix_hold [all_clocks]

############################# Compile ############################################################

compile -map_effort high

############################# Reports ############################################################

report_area       -hierarchy          > $OUTPUT_DIR/${RUN_NAME}_area.rpt
report_power      -hierarchy          > $OUTPUT_DIR/${RUN_NAME}_power.rpt
report_timing     -max_paths 200 -delay_type min > $OUTPUT_DIR/${RUN_NAME}_hold.rpt
report_timing     -max_paths 200 -delay_type max > $OUTPUT_DIR/${RUN_NAME}_setup.rpt
report_clock      -attributes         > $OUTPUT_DIR/${RUN_NAME}_clocks.rpt
report_constraint -all_violators      > $OUTPUT_DIR/${RUN_NAME}_constraints.rpt
report_clocks                         > $OUTPUT_DIR/${RUN_NAME}_clks.rpt
report_units                          > $OUTPUT_DIR/${RUN_NAME}_units.rpt

############################# Netlist ############################################################

write -hierarchy -format verilog -output $OUTPUT_DIR/${RUN_NAME}_mapped.v
write_sdc $OUTPUT_DIR/${RUN_NAME}.sdc

############################# Exit ###############################################################

exit
