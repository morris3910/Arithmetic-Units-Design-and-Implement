module FXP_adder(
    input [31:0] a,
    input [31:0] b,
    output [31:0] d
);
    assign d = a + b;
endmodule