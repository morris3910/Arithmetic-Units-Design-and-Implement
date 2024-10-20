module FLP_adder(
    input [31:0] a, 
    input [31:0] b, 
    output [31:0] d 
);

reg sign_a, sign_b, sign_d;
reg [7:0] exp_a, exp_b, exp_d;
reg [23:0] mant_a, mant_b, mant_d;
reg [24:0] mant_sum; 
reg [7:0] exp_diff;
reg RoundBit; 
integer i;

always @(*) begin
    //Unpack
    sign_a = a[31];
    sign_b = b[31];
    exp_a = a[30:23];
    exp_b = b[30:23];
    mant_a = {1'b1, a[22:0]};
    mant_b = {1'b1, b[22:0]};

    //Alignment
    if (exp_a > exp_b) begin
        exp_diff = exp_a - exp_b;
        RoundBit = mant_b[exp_diff-1];
        mant_b = mant_b >> exp_diff;
        exp_d = exp_a;
    end else begin
        exp_diff = exp_b - exp_a;
        RoundBit = mant_a[exp_diff-1];
        mant_a = mant_a >> exp_diff;
        exp_d = exp_b;
    end
        
    //Addition
    if (sign_a == sign_b) begin
        mant_sum = mant_a + mant_b;
        sign_d = sign_a;
    end else begin
        if (mant_a >= mant_b) begin
            mant_sum = mant_a - mant_b;
            sign_d = sign_a;
        end else begin
            mant_sum = mant_b - mant_a;
            sign_d = sign_b;
        end
    end

    //Normalization
    if (mant_sum[24]) begin
        mant_d = (mant_sum >> 1);
        exp_d = (exp_d + 1);
    end else begin
        mant_d = mant_sum[23:0];
        while (mant_d[23] == 0 && exp_d > 0) begin
            mant_d = (mant_d << 1);
            exp_d = (exp_d - 1);
        end
    end

    //Rounding
    if (RoundBit) begin
        mant_d = mant_d + 1;
    end 
end

//Pack
assign d = {sign_d, exp_d, mant_d[22:0]};

endmodule
