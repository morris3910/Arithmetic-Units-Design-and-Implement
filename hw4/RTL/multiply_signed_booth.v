module  signed_multiplier_booth#(
  parameter m=8,
  parameter n=8
)(
  input [m-1:0] a, 
  input [n-1:0] b, 
  output [m+n-1:0] p);

localparam mn = m+n;

wire [mn-1:0] aa_n, aa2, aa2_n;
reg [mn-1:0] aa;
wire [n-1:-1] bb; // for radix-4 booth recoding 
reg [mn-1:0] pp[0:n+1];
reg [mn-1:0] pp_tmp [0:n+3];

/* in tesbench, compare with unsigned and signed multiplications
wire [mn-1:0] up = a*b;  // product of two unsigned numbers
wire signed [m-1:0] sa = (signed) a;
wire signed [n-1:0] sb = (signed) b;
wire signed [mn-1:0] sp = sa*sb; // product of two signed numbers
*/
integer i, j;

// sign-extension of the signed multiplicand a 
always @ (*) begin 
  for (j=0; j<=m-1; j=j+1)
    aa[j] = a[j];
  for (j=m; j<=mn-1; j=j+1)
    aa[j] = a[m-1];
end 


// padding of zero to the right of LSB of the multiplier b
assign bb = {b,1'b0};


// booth recoding results: 0, a, -a, 2a, -2a
assign aa_n = ~aa + 1'b1; // -a
assign aa2 = aa << 1;  // 2a
assign aa2_n = ~aa2 + 1'b1; // -2a


// product product generation using radix-4 booth recoding
// for negative pp such as aa_n and aa2_n, add 1 in the next pp
// pp[odd_index] are NOT used in the radix-4 booth recoding
always @ (*) begin
  for (i=0; i<=n-1; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp[i][j] = 1'b0; 

  for (i=0; i<=n-1; i=i+2)
    case ({bb[i+1], bb[i], bb[i-1]}) // radix-4 booth recoding
      3'b000: pp[i]='b0;  
      3'b010: pp[i]=aa;
      3'b100: begin pp[i]=aa2_n; pp[i+2][i]=1'b1; end
      3'b110: begin pp[i]=aa_n; pp[i+2][i]= 1'b1; end 
      3'b001: pp[i]=aa;
      3'b011: pp[i]=aa2;
      3'b101: begin pp[i]=aa_n; pp[i+2][i]=1'b1; end
      3'b111: pp[i]='b0;
      default: pp[i]='b0;
    endcase
end


// accumulation of all booth-recoded partial products 
// pp[odd_index] and pp_tmp[odd_index] are not used in radix-4 booth recoding
// add an extra pp row if the last booth-recoded pp is negative
always @ (*) begin
  for (i=0; i<=n+3; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp_tmp[i][j] = 1'b0; 

  for (i=0; i<n+2; i=i+2)
    pp_tmp[i+2] = pp_tmp[i]+(pp[i]<<<i);
end 


// final proudct of own radix-4 booth sgined multiplication
assign p = pp_tmp[n];

// add comparison with up and sp 


endmodule