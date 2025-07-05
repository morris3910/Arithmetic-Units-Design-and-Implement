module stage1 (
    input [31:0] a, b,
    output reg sign_a_stage1, sign_b_stage1,
    output reg [7:0] exp_a_stage1, exp_b_stage1,
    output reg [23:0] mant_a_stage1, mant_b_stage1
);
    always @(*) begin
        sign_a_stage1 = a[31];  
        sign_b_stage1 = b[31];
        exp_a_stage1 = a[30:23];
        exp_b_stage1 = b[30:23];
        mant_a_stage1 = {1'b1, a[22:0]};
        mant_b_stage1 = {1'b1, b[22:0]};
    end
endmodule

module stage2 (
    input sign_a_stage1, sign_b_stage1,
    input [7:0] exp_a_stage1, exp_b_stage1,
    input [23:0] mant_a_stage1, mant_b_stage1,
    output reg sign_result_stage2,
    output reg [8:0] exp_sum_stage2,
    output reg [48:0] mant_product_stage2
);
    always @(*) begin
        // Multiply
        mant_product_stage2 = (mant_a_stage1 * mant_b_stage1);
        // Exp sum 
        exp_sum_stage2 = (exp_a_stage1 + exp_b_stage1 - 8'd127);
        // XOR sign
        sign_result_stage2 = (sign_a_stage1 ^ sign_b_stage1);
    end
endmodule

module stage3 (
    input [48:0] mant_product_stage2,
    input [8:0] exp_sum_stage2,
    output reg [23:0] normalized_mantissa_stage3,
    output reg [8:0] final_exponent_stage3,
    output reg guard_bit_stage3
);
    always @(*) begin
        guard_bit_stage3 = 0;
        // Normalization
        if (mant_product_stage2[47] == 1'b1) begin
            normalized_mantissa_stage3 = mant_product_stage2[46:24];
            guard_bit_stage3 = mant_product_stage2[23];            
            final_exponent_stage3 = exp_sum_stage2 + 1;           
        end else begin
            normalized_mantissa_stage3 = mant_product_stage2[45:23];
            guard_bit_stage3 = mant_product_stage2[22];            
            final_exponent_stage3 = exp_sum_stage2;                 
        end
    end
endmodule

module stage4 (
    input sign_result_stage2, 
    input [8:0] final_exponent_stage3,
    input [23:0] normalized_mantissa_stage3, 
    input guard_bit_stage3,
    output [31:0] d
);
    wire [23:0] normalized_rounded_mantissa_stage4;
    assign normalized_rounded_mantissa_stage4 = normalized_mantissa_stage3 + guard_bit_stage3;
    assign d = {sign_result_stage2, final_exponent_stage3[7:0], normalized_rounded_mantissa_stage4[22:0]};
endmodule

module FLP_mul (
    input  [31:0] a, 
    input  clk, rst, 
    input  [31:0] b, 
    output [31:0] d
);

    //stage 1: Unpacking
    wire sign_a_stage1, sign_b_stage1;
    wire [7:0] exp_a_stage1, exp_b_stage1;
    wire [23:0] mant_a_stage1, mant_b_stage1;

    stage1 s1 (
        a, b, 
        sign_a_stage1, sign_b_stage1, 
        exp_a_stage1, exp_b_stage1, 
        mant_a_stage1, mant_b_stage1
    );

    reg sign_a_stage1_reg, sign_b_stage1_reg;
    reg [7:0] exp_a_stage1_reg, exp_b_stage1_reg;
    reg [23:0] mant_a_stage1_reg, mant_b_stage1_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sign_a_stage1_reg <= 0;
            sign_b_stage1_reg <= 0;
            exp_a_stage1_reg  <= 8'b0;
            exp_b_stage1_reg  <= 8'b0;
            mant_a_stage1_reg <= 24'b0; // Implicit leading 1 for mantissa
            mant_b_stage1_reg <= 24'b0;
        end else begin
            sign_a_stage1_reg <= sign_a_stage1;
            sign_b_stage1_reg <= sign_b_stage1;
            exp_a_stage1_reg  <= exp_a_stage1;
            exp_b_stage1_reg  <= exp_b_stage1;
            mant_a_stage1_reg <= mant_a_stage1; // Implicit leading 1 for mantissa
            mant_b_stage1_reg <= mant_b_stage1;
        end
    end

    //stage 2: Multiply mantissas, calculate exponent and sign
    wire [48:0] mant_product_stage2;
    wire [8:0] exp_sum_stage2;
    wire sign_result_stage2;

    stage2 s2 (
        sign_a_stage1_reg, sign_b_stage1_reg, 
        exp_a_stage1_reg, exp_b_stage1_reg, 
        mant_a_stage1_reg, mant_b_stage1_reg, 
        sign_result_stage2, exp_sum_stage2, mant_product_stage2
    );

    reg [48:0] mant_product_stage2_reg;
    reg [8:0] exp_sum_stage2_reg;
    reg sign_result_stage2_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mant_product_stage2_reg <= 49'b0;
            exp_sum_stage2_reg <= 9'b0;
            sign_result_stage2_reg  <= 0;
        end else begin
            mant_product_stage2_reg <= mant_product_stage2;
            exp_sum_stage2_reg <= exp_sum_stage2;
            sign_result_stage2_reg <= sign_result_stage2;
        end
    end

    //stage 3: Normalization
    wire [23:0] normalized_mantissa_stage3;
    wire [8:0] final_exponent_stage3;
    wire guard_bit_stage3;

    stage3 s3 (
        mant_product_stage2_reg, exp_sum_stage2_reg, 
        normalized_mantissa_stage3, final_exponent_stage3, guard_bit_stage3
    );

    reg [23:0] normalized_mantissa_stage3_reg;
    reg [8:0] final_exponent_stage3_reg;
    reg guard_bit_stage3_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            normalized_mantissa_stage3_reg <= 24'b0;
            final_exponent_stage3_reg <= 9'b0;
            guard_bit_stage3_reg <= 0;
        end else begin
            normalized_mantissa_stage3_reg <= normalized_mantissa_stage3;
            final_exponent_stage3_reg <= final_exponent_stage3;
            guard_bit_stage3_reg <= guard_bit_stage3;
        end
    end

    stage4 s4 (
        sign_result_stage2_reg, final_exponent_stage3_reg,
        normalized_mantissa_stage3_reg, guard_bit_stage3_reg,
        d
    ); 

endmodule
