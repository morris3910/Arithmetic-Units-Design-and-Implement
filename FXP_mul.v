module FXP_mul(
    input [31:0] a,
    input [31:0] b,
    output [63:0] d
);
    //wire [63:0] p;

    assign d = a * b;
    //assign d = p[63:32];
endmodule