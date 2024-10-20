module FLP_adder (
    input clk, rst,
    input [31:0] a, 
    input [31:0] b, 
    output [31:0] d 
);
    wire stage1_sign_a, stage1_sign_b;
    wire stage1_RoundBit;
    wire [7:0] stage1_exp_d;
    wire [23:0] stage1_shifted_mant_a, stage1_shifted_mant_b;
    stage1 s1 (
        a, b, 
        stage1_sign_a, stage1_sign_b, stage1_RoundBit, 
        stage1_exp_d, stage1_shifted_mant_a, stage1_shifted_mant_b
    );

    reg stage1_sign_a_reg, stage1_sign_b_reg;
    reg stage1_RoundBit_reg;
    reg [7:0] stage1_exp_d_reg;
    reg [23:0] stage1_shifted_mant_a_reg, stage1_shifted_mant_b_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_sign_a_reg <= 0;
            stage1_sign_b_reg <= 0;
            stage1_RoundBit_reg <= 0;
            stage1_exp_d_reg <= 0;
            stage1_shifted_mant_a_reg <= 0;
            stage1_shifted_mant_b_reg <= 0;
        end else begin
            stage1_sign_a_reg <= stage1_sign_a;
            stage1_sign_b_reg <= stage1_sign_b;
            stage1_RoundBit_reg <= stage1_RoundBit;
            stage1_exp_d_reg <= stage1_exp_d;
            stage1_shifted_mant_a_reg <= stage1_shifted_mant_a;
            stage1_shifted_mant_b_reg <= stage1_shifted_mant_b;
        end
    end

    wire stage2_sign_d;
    wire [24:0] stage2_mant_sum;
    stage2 s2 (
        stage1_sign_a_reg, stage1_sign_b_reg,
        stage1_shifted_mant_a_reg, stage1_shifted_mant_b_reg,
        stage2_sign_d, stage2_mant_sum
    );

    reg stage2_sign_d_reg;
    reg stage2_RoundBit_reg;
    reg [7:0] stage2_exp_d_reg;
    reg [24:0] stage2_mant_sum_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_sign_d_reg <= 0;
            stage2_RoundBit_reg <= 0;
            stage2_exp_d_reg <= 0;
            stage2_mant_sum_reg <= 0;
        end else begin
            stage2_sign_d_reg <= stage2_sign_d;
            stage2_mant_sum_reg <= stage2_mant_sum;
            stage2_RoundBit_reg <= stage1_RoundBit_reg;
            stage2_exp_d_reg <= stage1_exp_d_reg;
        end
    end

    wire [23:0] stage3_mant_d;
    wire [7:0] stage3_normalized_exp_d;
    stage3 s3 (
        stage2_mant_sum_reg, stage2_exp_d_reg,
        stage3_mant_d, stage3_normalized_exp_d
    );

    reg stage3_sign_d_reg;
    reg stage3_RoundBit_reg;
    reg [23:0] stage3_mant_d_reg;
    reg [7:0] stage3_normalized_exp_d_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage3_mant_d_reg <= 0;
            stage3_normalized_exp_d_reg <= 0;
            stage3_sign_d_reg <= 0;
            stage3_RoundBit_reg <= 0;
        end else begin
            stage3_mant_d_reg <= stage3_mant_d;
            stage3_normalized_exp_d_reg <= stage3_normalized_exp_d;
            stage3_sign_d_reg <= stage2_sign_d_reg;
            stage3_RoundBit_reg <= stage2_RoundBit_reg;
        end
    end

    stage4 s4 (
        stage3_RoundBit_reg, stage3_sign_d_reg,
        stage3_normalized_exp_d_reg, stage3_mant_d_reg,
        d
    );
endmodule

module stage1 (
    input [31:0] a, b,
    output reg stage1_sign_a, stage1_sign_b,
    output reg stage1_RoundBit,
    output reg [7:0] stage1_exp_d,
    output reg [23:0] stage1_shifted_mant_a, stage1_shifted_mant_b
);
    reg [7:0] stage1_exp_diff;
    reg [7:0] stage1_exp_a, stage1_exp_b;
    reg [23:0] stage1_mant_a, stage1_mant_b;
    always @(*) begin
        stage1_sign_a = a[31];
        stage1_sign_b = b[31];
        stage1_exp_a = a[30:23];
        stage1_exp_b = b[30:23];
        stage1_mant_a = {1'b1, a[22:0]};
        stage1_mant_b = {1'b1, b[22:0]};
        stage1_RoundBit = 0;
        if (stage1_exp_a > stage1_exp_b) begin
            stage1_exp_diff = (stage1_exp_a - stage1_exp_b);
            stage1_RoundBit = stage1_mant_b[stage1_exp_diff-1];
            stage1_shifted_mant_b = (stage1_mant_b >> stage1_exp_diff);
            stage1_shifted_mant_a = stage1_mant_a;
            stage1_exp_d = stage1_exp_a;
        end else begin
            stage1_exp_diff = (stage1_exp_b - stage1_exp_a);
            stage1_RoundBit = stage1_mant_a[stage1_exp_diff-1];
            stage1_shifted_mant_a = (stage1_mant_a >> stage1_exp_diff);
            stage1_shifted_mant_b = stage1_mant_b;
            stage1_exp_d = stage1_exp_b;
        end
    end
endmodule

module stage2 (
    input stage1_sign_a, stage1_sign_b,
    input [23:0] stage1_shifted_mant_a, stage1_shifted_mant_b,
    output reg stage2_sign_d,
    output reg [24:0] stage2_mant_sum
);
    always @(*) begin
        if (stage1_sign_a == stage1_sign_b) begin
            stage2_mant_sum = (stage1_shifted_mant_a + stage1_shifted_mant_b);
            stage2_sign_d = stage1_sign_a;
        end else begin
            if (stage1_shifted_mant_a >= stage1_shifted_mant_b) begin
                stage2_mant_sum = (stage1_shifted_mant_a - stage1_shifted_mant_b);
                stage2_sign_d = stage1_sign_a;
            end else begin
                stage2_mant_sum = (stage1_shifted_mant_b - stage1_shifted_mant_a);
                stage2_sign_d = stage1_sign_b;
            end
        end
    end
endmodule

module stage3 (
    input [24:0] stage2_mant_sum,
    input [7:0] stage2_exp_d,
    output reg [23:0] stage3_mant_d,
    output reg [7:0] stage3_normalized_exp_d
);
    reg [23:0] tmp_mant_d;
    reg [7:0] tmp_exp_d;
    always @(*) begin
        if (stage2_mant_sum[24]) begin
            stage3_mant_d = stage2_mant_sum[23:0];
            stage3_normalized_exp_d = (stage2_exp_d + 1);
        end else begin
            tmp_mant_d = stage2_mant_sum[23:0];
            tmp_exp_d = stage2_exp_d;
            while (tmp_mant_d[23] == 0 && tmp_exp_d > 0) begin
                tmp_mant_d = (tmp_mant_d << 1);
                tmp_exp_d = (tmp_exp_d - 1);
            end
            stage3_mant_d = tmp_mant_d;
            stage3_normalized_exp_d = tmp_exp_d;
        end
    end
endmodule

module stage4 (
    input stage3_RoundBit, stage3_sign_d,
    input [7:0] stage3_normalized_exp_d,
    input [23:0] stage3_mant_d,
    output reg [31:0] d
);
    reg [23:0] stage4_rounded_mant_d;
    always @(*) begin
        if (stage3_RoundBit) begin
            stage4_rounded_mant_d = (stage3_mant_d + 1);
        end else begin
            stage4_rounded_mant_d = stage3_mant_d;
        end
        d = {stage3_sign_d, stage3_normalized_exp_d, stage4_rounded_mant_d[22:0]};
    end
endmodule