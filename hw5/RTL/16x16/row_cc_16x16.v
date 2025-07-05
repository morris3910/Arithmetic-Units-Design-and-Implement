module  row_cc_16x16#(
  parameter m=16, 
  parameter n=16
)(
  input [m-1:0] a, 
  input [n-1:0] b, 
  output [m+n-1:0] p);

localparam mn = n+m;

reg [mn-1:0] aa;
reg [mn-1:0] pp[0:n-1];
reg [mn-1:0] pp_tmp[0:n];

/* in tesbench, compare with unsigned and signed multiplications
wire [mn-1:0] up = a*b;  // product of two unsigned numbers
wire signed [m-1:0] sa = (signed) a;
wire signed [n-1:0] sb = (signed) b;
wire signed [mn-1:0] sp = sa*sb; // product of two signed numbers
*/

integer i, j;


// sign-extension of the signed multiplicand 
always @ (*) begin
  for (j=0; j<=m-1; j=j+1)
    aa[j] = a[j];
  for (j=m; j<=mn-1; j=j+1)
    aa[j] = 1'b0;
end


// product product generation of signed multiplication
always @ (*) begin
  for (i=0; i<=n-1; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp[i][j] = 1'b0; 


  for (i=0; i<=n-1; i=i+1)begin
    for (j=0; j<=mn-1; j=j+1) begin
      if (i+j < 12) begin
        pp[i][j+i] = 0;
      end else begin
        pp[i][j+i] = aa[j] & b[i];
      end
    end
  end  

  /*for (i=0; i<=n-1; i=i+1) begin
    for (j=n-1; j > i; j=j-1) begin
      $write(" ");
    end
    $display("%b", pp[i]); 
  end*/
end 


// alternative for the above partial product generation of signed multiplier
// for (j=0; j<=n-1; j=j+1)
// if (b[j]== 1'b1)  
//   pp[j]= aa << j;


// accumulation of all signed partial products 
always @ (*) begin
  for (i=0; i<=n; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp_tmp[i][j] = 1'b0; 


  for (i=0; i<=n-2; i=i+1)
    pp_tmp[i+1] = pp_tmp[i]+pp[i];

  pp_tmp[n] = pp_tmp[n-1] + (pp[i]);
end 


// final proudct of own sgined multiplication
assign p = pp_tmp[n] + (1 << 15) + (1 << 13);

// in tesbench, add comparison with up and sp in the testbench


endmodule