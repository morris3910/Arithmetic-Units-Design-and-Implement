module FLP_mul(
    input  [31:0] a, 
    input  [31:0] b, 
    output [31:0] d 
);
    //Unpack
    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    wire [23:0] mant_a = {1'b1, a[22:0]};
    wire [23:0] mant_b = {1'b1, b[22:0]};


    //Mul
    wire [48:0] mant_product = mant_a * mant_b;

    //Exp
    wire [8:0] exp_sum = exp_a + exp_b - 8'd127;

    //Sign
    wire sign_result = sign_a ^ sign_b;

    //Normalization
    reg [23:0] normalized_mantissa;
    reg [8:0] final_exponent;
    reg guardBit;

    always @(*) begin
        if (mant_product[47] == 1'b1) begin
            normalized_mantissa = mant_product[46:24];
            guardBit = mant_product[23];
            final_exponent = exp_sum + 1;
        end else begin
            normalized_mantissa = mant_product[45:23];
            guardBit = mant_product[22];
            final_exponent = exp_sum;
        end

        //Rounding
        normalized_mantissa = normalized_mantissa + guardBit;
    end

    //Pack
    assign d = {sign_result, final_exponent[7:0], normalized_mantissa[22:0]};
endmodule
