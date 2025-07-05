`timescale 1ns/10ps
`define N 8
`define M 8

module operator_8x8#(parameter m=`M, parameter n=`N) 
  (
    input signed [m-1:0] a,
    input signed [n-1:0] b,
    output signed [m+n-1:0] out
  );
    assign out = a * b;
endmodule