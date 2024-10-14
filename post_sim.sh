#!/bin/tcsh

vcs -R -error=noMPD -debug_access+all \
/home/B103040021_ALU/HW1/pre_sim/testbench.v \
/home/B103040021_ALU/HW1/RTL/FXP_adder.v \
/cad/CBDK/ADFP/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v \
+full64 \
+access+r +vcs+fsdbon +fsdb+mda +fsdbfile+6adder.fsdb +neg_tchk
