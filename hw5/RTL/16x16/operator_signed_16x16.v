`timescale 1ns/10ps
`define N 16
`define M 16

module operator_16x16#(parameter m=`M, parameter n=`N) 
  (
    input signed [m-1:0] a,
    input signed [n-1:0] b,
    output signed [m+n-1:0] out
  );
    assign out = a * b;
endmodule