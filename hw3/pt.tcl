set company "VLSILAB"
set designer "OWEN"
#######################################################################
## Logical Library Settings
#######################################################################
set search_path      "/usr/cad/CBDK/CBDK_TSMC40_Arm_f2.0/CIC/SynopsysDC/db/sc9_base_rvt/  $search_path"
set target_library   "sc9_cln40g_base_rvt_ss_typical_max_0p81v_125c.db sc9_cln40g_base_rvt_ff_typical_min_0p99v_m40c.db"
set link_library     "* $target_library dw_foundation.sldb"
set symbol_library   "tsmc040.sdb generic.sdb"
set synthetic_library "dw_foundation.sldb"
set sh_source_uses_search_path true

######################################################################
# power analysis
######################################################################
# source saifmap.ptpx.tcl
# report_name_mapping
set power_enable_analysis true
set power_analysis_mode averaged
set power_report_leakage_breakdowns true

read_verilog /home/2022_alu03/ALU_HW3/pipeline/dc_out_file/DP_syn.v
current_design FP_DP
link

read_sdc /home/2022_alu03/ALU_HW3/pipeline/dc_out_file/DP_syn.sdc
read_sdf /home/2022_alu03/ALU_HW3/pipeline/dc_out_file/DP_syn.sdf
check_timing
update_timing

read_vcd -strip_path TB_DP/FP_DP /home/2022_alu03/ALU_HW3/pipeline/prime_time/wave.vcd

check_power
update_power

report_power -hierarchy > report_power_average_vcd.rpt

#quit
exit
