#!/bin/tcsh

vcs -R -debug_access+all \
/home/B103040021_ALU/HW1/pre_sim/testbench.v \
/home/B103040021_ALU/HW1/RTL/FLP_adder.v \
+full64 \
+access+r +vcs+fsdbon +fsdb+mda +fsdbfile+FLP.fsdb +v2k
