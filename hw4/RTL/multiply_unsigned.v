module  unsigned_multiplier#(
  parameter m=8, 
  parameter n=8
)(
  input [m-1:0] a, 
  input [n-1:0] b, 
  output [m+n-1:0] p);

localparam mn = m+n; 

reg [mn-1:0] aa;
reg [mn-1:0] pp[0:n-1];
reg [mn-1:0] pp_tmp [0:n];

/* in tesbench, compare with unsigned and signed multiplications
wire [mn-1:0] up = a*b;  // product of two unsigned numbers
wire signed [m-1:0] sa = (signed) a;
wire signed [n-1:0] sb = (signed) b;
wire signed [mn-1:0] sp = sa*sb; // product of two signed numbers
*/
integer i, j;


// zero-extension of the unsigned multiplicand 
always @ (*) begin
  for (j=0; j<=m-1; j=j+1)
    aa[j] = a[j];
  for (j=m; j<=mn-1; j=j+1)
    aa[j] = 1'b0;
end
 
// product product generation of unsigned multiplication
always @ (*) begin
  for (i=0; i<=n-1; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp[i][j] = 1'b0; 

  for (i=0; i<=n-1; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp[i][j+i] = aa[j]& b[i];
end 

// alternative for the above partial product generation
// for (j=0; j<=n-1; j=j+1)
// if (b[j]== 1'b1)  
//   pp[j]= aa << j;


// accumulation of all unsigned partial products
always @ (*) begin
  for (i=0; i<=n; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp_tmp[i][j] = 1'b0; 

  for (i=0; i<=n-1; i=i+1)
    pp_tmp[i+1] = pp_tmp[i]+pp[i];
end 

// final proudct of own unsgined multiplication
assign p = pp_tmp[n];

// add comparison with up and sp 


endmodule








/*module  unsigned_multiplier#(
  parameter m=8, 
  parameter n=8
)(
  input [m-1:0] a, 
  input [n-1:0] b, 
  output [m+n-1:0] p);

localparam mn = m+n; 
reg [mn-1:0] aa;
reg [mn-1:0] pp[0:n-1];
reg [mn-1:0] pp_tmp [0:n];

// in tesbench, compare with unsigned and signed multiplications
// wire [mn-1:0] up = a*b;  // product of two unsigned numbers
// wire signed [m-1:0] sa = (signed) a;
// wire signed [n-1:0] sb = (signed) b;
// wire signed [mn-1:0] sp = sa*sb; // product of two signed numbers



integer i, j;

always @ (*) begin
  for (i=0; i<=n-1; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp[i][j] = 1'b0; 
end 

// zero-extension of the unsigned multiplicand 
always @ (*) begin
for (j=0; j<=m-1; j=j+1)
 aa[j] = a[j];
for (j=m; j<=mn-1; j=j+1)
 aa[j] = 1'b0;
end
 
// product product generation of unsigned multiplication
always @ (*) begin
  for (i=0; i<=n-1; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp[i][j+i] = aa[j]& b[i];
end 

// alternative for the above partial product generation
// for (j=0; j<=n-1; j=j+1)
// if (b[j]== 1'b1)  
//   pp[j]= aa << j;


// accumulation of all unsigned partial products
// first initialize pp_tmp[0] 
always @ (*) begin
  for (i=0; i<=n; i=i+1)
    for (j=0; j<=mn-1; j=j+1)
      pp_tmp[i][j] = 1'b0; 
end

always @ (*) begin
  for (i=0; i<=n-1; i=i+1)
    pp_tmp[i+1] = pp_tmp[i]+pp[i];
end 


// final proudct of own unsgined multiplication
assign p = pp_tmp[n];

// add comparison with up and sp 


endmodule*/