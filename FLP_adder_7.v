module stage_1 (
    input clk, rst,
    input [31:0] a, b,
    output reg stage1_sign_a, stage1_sign_b,
    output reg [7:0] stage1_exp_a, stage1_exp_b,
    output reg [23:0] stage1_mant_a, stage1_mant_b
);
    always @(*) begin
        stage1_sign_a = a[31];
        stage1_sign_b = b[31];
        stage1_exp_a = a[30:23];
        stage1_exp_b = b[30:23];
        stage1_mant_a = {1'b1, a[22:0]};
        stage1_mant_b = {1'b1, b[22:0]};
    end
endmodule

module stage_1_to_2_reg (
    input clk, rst,
    input stage1_sign_a, stage1_sign_b,
    input [7:0] stage1_exp_a, stage1_exp_b,
    input [23:0] stage1_mant_a, stage1_mant_b,
    output reg stage1_sign_a_reg, stage1_sign_b_reg,
    output reg [7:0] stage1_exp_a_reg, stage1_exp_b_reg,
    output reg [23:0] stage1_mant_a_reg, stage1_mant_b_reg
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_sign_a_reg <= 0;
            stage1_sign_b_reg <= 0;
            stage1_exp_a_reg <= 0;
            stage1_exp_b_reg <= 0;
            stage1_mant_a_reg <= 0;
            stage1_mant_b_reg <= 0;
        end else begin
            stage1_sign_a_reg <= stage1_sign_a;
            stage1_sign_b_reg <= stage1_sign_b;
            stage1_exp_a_reg <= stage1_exp_a;
            stage1_exp_b_reg <= stage1_exp_b;
            stage1_mant_a_reg <= stage1_mant_a;
            stage1_mant_b_reg <= stage1_mant_b;
        end
    end
endmodule

module stage_2 (
    input clk, rst,
    input [7:0] stage1_exp_a, stage1_exp_b,
    input [23:0] stage1_mant_a, stage1_mant_b,
    output reg stage2_RoundBit,
    output reg [7:0] stage2_exp_diff, stage2_exp_d,
    output reg [23:0] stage2_shifted_mant_a, stage2_shifted_mant_b
);
    always @(*) begin
        stage2_RoundBit = 0;
        if (stage1_exp_a > stage1_exp_b) begin
            stage2_exp_diff = (stage1_exp_a - stage1_exp_b);
            stage2_RoundBit = stage1_mant_b[stage2_exp_diff-1];
            stage2_shifted_mant_b = (stage1_mant_b >> stage2_exp_diff);
            stage2_shifted_mant_a = stage1_mant_a;
            stage2_exp_d = stage1_exp_a;
        end else begin
            stage2_exp_diff = (stage1_exp_b - stage1_exp_a);
            stage2_RoundBit = stage1_mant_a[stage2_exp_diff-1];
            stage2_shifted_mant_a = (stage1_mant_a >> stage2_exp_diff);
            stage2_shifted_mant_b = stage1_mant_b;
            stage2_exp_d = stage1_exp_b;
        end
    end
endmodule

module stage_2_to_3_reg (
    input clk, rst,
    input stage1_sign_a, stage1_sign_b,
    input stage2_RoundBit,
    input [7:0] stage2_exp_diff, stage2_exp_d,
    input [23:0] stage2_shifted_mant_a, stage2_shifted_mant_b,
    output reg stage2_sign_a_reg, stage2_sign_b_reg,
    output reg stage2_RoundBit_reg,
    output reg [7:0] stage2_exp_diff_reg, stage2_exp_d_reg,
    output reg [23:0] stage2_shifted_mant_a_reg, stage2_shifted_mant_b_reg
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_sign_a_reg <= 0;
            stage2_sign_b_reg <= 0;
            stage2_RoundBit_reg <= 0;
            stage2_exp_diff_reg <= 0;
            stage2_exp_d_reg <= 0;
            stage2_shifted_mant_a_reg <= 0;
            stage2_shifted_mant_b_reg <= 0;
        end else begin
            stage2_sign_a_reg <= stage1_sign_a;
            stage2_sign_b_reg <= stage1_sign_b;
            stage2_RoundBit_reg <= stage2_RoundBit;
            stage2_exp_diff_reg <= stage2_exp_diff;
            stage2_exp_d_reg <= stage2_exp_d;
            stage2_shifted_mant_a_reg <= stage2_shifted_mant_a;
            stage2_shifted_mant_b_reg <= stage2_shifted_mant_b;
        end
    end
endmodule

module stage_3 (
    input clk, rst,
    input stage2_sign_a, stage2_sign_b,
    input [23:0] stage2_shifted_mant_a, stage2_shifted_mant_b,
    output reg stage3_sign_d,
    output reg [24:0] stage3_mant_sum
);
    always @(*) begin
        if (stage2_sign_a == stage2_sign_b) begin
            stage3_mant_sum = (stage2_shifted_mant_a + stage2_shifted_mant_b);
            stage3_sign_d = stage2_sign_a;
        end else begin
            if (stage2_shifted_mant_a >= stage2_shifted_mant_b) begin
                stage3_mant_sum = (stage2_shifted_mant_a - stage2_shifted_mant_b);
                stage3_sign_d = stage2_sign_a;
            end else begin
                stage3_mant_sum = (stage2_shifted_mant_b - stage2_shifted_mant_a);
                stage3_sign_d = stage2_sign_b;
            end
        end
    end
endmodule

module stage_3_to_4_reg (
    input clk, rst,
    input stage3_sign_d, stage2_RoundBit,
    input [7:0] stage2_exp_d,
    input [24:0] stage3_mant_sum,
    output reg stage3_sign_d_reg, stage3_RoundBit_reg,
    output reg [7:0] stage3_exp_d_reg,
    output reg [24:0] stage3_mant_sum_reg
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage3_sign_d_reg <= 0;
            stage3_mant_sum_reg <= 0;
            stage3_exp_d_reg <= 0;
            stage3_RoundBit_reg <= 0;
        end else begin
            stage3_sign_d_reg <= stage3_sign_d;
            stage3_exp_d_reg <= stage2_exp_d;
            stage3_mant_sum_reg <= stage3_mant_sum;
            stage3_RoundBit_reg <= stage2_RoundBit;
        end
    end
endmodule

module stage_4 (
    input clk, rst,
    input [24:0] stage3_mant_sum,
    output reg [24:0] stage4_signed_mant_sum
);
    always @(*) begin
        stage4_signed_mant_sum = stage3_mant_sum;
    end
endmodule

module stage_4_to_5_reg (
    input clk, rst,
    input stage3_RoundBit,
    input [24:0] stage4_signed_mant_sum,
    input [7:0] stage3_exp_d,
    output reg stage4_RoundBit_reg,
    output reg [24:0] stage4_signed_mant_sum_reg,
    output reg [7:0] stage4_exp_d_reg
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage4_signed_mant_sum_reg <= 0;
            stage4_exp_d_reg <= 0;
            stage4_RoundBit_reg <= 0;
        end else begin
            stage4_signed_mant_sum_reg <= stage4_signed_mant_sum;
            stage4_exp_d_reg <= stage3_exp_d;
            stage4_RoundBit_reg <= stage3_RoundBit;
        end
    end
endmodule

module stage_5 (
    input clk, rst,
    input [24:0] stage4_signed_mant_sum,
    input [7:0] stage4_exp_d,
    output reg [23:0] stage5_mant_d,
    output reg [7:0] stage5_normalized_exp_d
);
    reg [23:0] tmp_mant_d;
    reg [7:0] tmp_exp_d;
    always @(*) begin
        if (stage4_signed_mant_sum[24]) begin
            // If the sign bit is 1, shift right by 1 and increment the exponent
            stage5_mant_d = stage4_signed_mant_sum[23:0];
            stage5_normalized_exp_d = (stage4_exp_d + 1);
        end else begin
            // Detect the number of leading zeros using a case statement
            tmp_mant_d = stage4_signed_mant_sum[23:0];
            tmp_exp_d = stage4_exp_d;
            while (tmp_mant_d[23] == 0 && tmp_exp_d > 0) begin
                tmp_mant_d = (tmp_mant_d << 1);
                tmp_exp_d = (tmp_exp_d - 1);
            end
            stage5_mant_d = tmp_mant_d;
            stage5_normalized_exp_d = tmp_exp_d;
        end
    end
endmodule

module stage_5_to_6_reg (
    input clk, rst,
    input stage4_RoundBit,
    input [23:0] stage5_mant_d,
    input [7:0] stage5_normalized_exp_d,
    output reg stage5_RoundBit_reg,
    output reg [23:0] stage5_mant_d_reg,
    output reg [7:0] stage5_normalized_exp_d_reg
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage5_mant_d_reg <= 0;
            stage5_normalized_exp_d_reg <= 0;
            stage5_RoundBit_reg <= 0;
        end else begin
            stage5_mant_d_reg <= stage5_mant_d;
            stage5_normalized_exp_d_reg <= stage5_normalized_exp_d;
            stage5_RoundBit_reg <= stage4_RoundBit;
        end
    end
endmodule

module stage_6 (
    input clk, rst,
    input stage5_RoundBit,
    input [23:0] stage5_mant_d,
    output reg [23:0] stage6_rounded_mant_d
);
    always @(*) begin
        if (stage5_RoundBit) begin
            stage6_rounded_mant_d = (stage5_mant_d + 1);
        end else begin
            stage6_rounded_mant_d = stage5_mant_d;
        end
    end
endmodule

module stage_6_to_7_reg (
    input clk, rst,
    input [23:0] stage6_rounded_mant_d, 
    input [7:0] stage5_normalized_exp_d,
    output reg [7:0] stage6_normalized_exp_d_reg,
    output reg [23:0] stage6_rounded_mant_d_reg
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage6_rounded_mant_d_reg <= 0;
            stage6_normalized_exp_d_reg <= 0;
        end else begin
            stage6_rounded_mant_d_reg <= stage6_rounded_mant_d;
            stage6_normalized_exp_d_reg <= stage5_normalized_exp_d;
        end
    end
endmodule

module stage_7 (
    input clk, rst,
    input [23:0] stage6_rounded_mant_d,
    input [7:0] stage6_normalized_exp_d,
    input stage3_sign_d,
    output reg [31:0] d
);
    always @(*) begin
        d = {stage3_sign_d, stage6_normalized_exp_d, stage6_rounded_mant_d[22:0]};
    end
endmodule

module FLP_adder (
    input clk, rst,
    input [31:0] a, 
    input [31:0] b, 
    output [31:0] d 
);
    // Stage 1
    wire stage1_sign_a, stage1_sign_b;
    wire [7:0] stage1_exp_a, stage1_exp_b;
    wire [23:0] stage1_mant_a, stage1_mant_b;

    stage_1 s1 (
        .clk(clk), .rst(rst), 
        .a(a), .b(b), 
        .stage1_sign_a(stage1_sign_a), .stage1_sign_b(stage1_sign_b), 
        .stage1_exp_a(stage1_exp_a), .stage1_exp_b(stage1_exp_b), 
        .stage1_mant_a(stage1_mant_a), .stage1_mant_b(stage1_mant_b)
    );

    // Stage 1 to Stage 2 pipeline register
    wire stage1_sign_a_reg, stage1_sign_b_reg;
    wire [7:0] stage1_exp_a_reg, stage1_exp_b_reg;
    wire [23:0] stage1_mant_a_reg, stage1_mant_b_reg;

    stage_1_to_2_reg s1_to_2 (
        .clk(clk), .rst(rst),
        .stage1_sign_a(stage1_sign_a), .stage1_sign_b(stage1_sign_b),
        .stage1_exp_a(stage1_exp_a), .stage1_exp_b(stage1_exp_b),
        .stage1_mant_a(stage1_mant_a), .stage1_mant_b(stage1_mant_b),
        .stage1_sign_a_reg(stage1_sign_a_reg), .stage1_sign_b_reg(stage1_sign_b_reg),
        .stage1_exp_a_reg(stage1_exp_a_reg), .stage1_exp_b_reg(stage1_exp_b_reg),
        .stage1_mant_a_reg(stage1_mant_a_reg), .stage1_mant_b_reg(stage1_mant_b_reg)
    );

    // Stage 2
    wire stage2_RoundBit; 
    wire [7:0] stage2_exp_diff, stage2_exp_d;
    wire [23:0] stage2_shifted_mant_a, stage2_shifted_mant_b;

    stage_2 s2 (
        .clk(clk), .rst(rst), 
        .stage1_exp_a(stage1_exp_a_reg), .stage1_exp_b(stage1_exp_b_reg), 
        .stage1_mant_a(stage1_mant_a_reg), .stage1_mant_b(stage1_mant_b_reg), 
        .stage2_RoundBit(stage2_RoundBit), 
        .stage2_exp_diff(stage2_exp_diff), .stage2_exp_d(stage2_exp_d), 
        .stage2_shifted_mant_a(stage2_shifted_mant_a), .stage2_shifted_mant_b(stage2_shifted_mant_b)
    );

    // Stage 2 to 3 pipeline register
    wire stage2_RoundBit_reg;
    wire stage2_sign_a_reg, stage2_sign_b_reg;
    wire [7:0] stage2_exp_diff_reg, stage2_exp_d_reg;
    wire [23:0] stage2_shifted_mant_a_reg, stage2_shifted_mant_b_reg;

    stage_2_to_3_reg s2_to_3 (
        .clk(clk), .rst(rst),
        .stage1_sign_a(stage1_sign_a_reg), .stage1_sign_b(stage1_sign_b_reg),
        .stage2_RoundBit(stage2_RoundBit), .stage2_exp_diff(stage2_exp_diff), .stage2_exp_d(stage2_exp_d),
        .stage2_shifted_mant_a(stage2_shifted_mant_a), .stage2_shifted_mant_b(stage2_shifted_mant_b),
        .stage2_sign_a_reg(stage2_sign_a_reg), .stage2_sign_b_reg(stage2_sign_b_reg),
        .stage2_RoundBit_reg(stage2_RoundBit_reg), .stage2_exp_diff_reg(stage2_exp_diff_reg), .stage2_exp_d_reg(stage2_exp_d_reg),
        .stage2_shifted_mant_a_reg(stage2_shifted_mant_a_reg), .stage2_shifted_mant_b_reg(stage2_shifted_mant_b_reg)
    );

    // Stage 3
    wire stage3_sign_d;
    wire [24:0] stage3_mant_sum;

    stage_3 s3 (
        .clk(clk), .rst(rst), 
        .stage2_sign_a(stage2_sign_a_reg), .stage2_sign_b(stage2_sign_b_reg), 
        .stage2_shifted_mant_a(stage2_shifted_mant_a_reg), .stage2_shifted_mant_b(stage2_shifted_mant_b_reg), 
        .stage3_sign_d(stage3_sign_d), 
        .stage3_mant_sum(stage3_mant_sum)
    );

    // Stage 3 to 4 pipeline register
    wire [24:0] stage3_mant_sum_reg;
    wire stage3_sign_d_reg, stage3_RoundBit_reg;
    wire [7:0] stage3_exp_d_reg;

    stage_3_to_4_reg s3_to_4 (
        .clk(clk), .rst(rst),
        .stage2_exp_d(stage2_exp_d_reg), .stage2_RoundBit(stage2_RoundBit_reg),
        .stage3_mant_sum(stage3_mant_sum), .stage3_sign_d(stage3_sign_d),
        .stage3_exp_d_reg(stage3_exp_d_reg), .stage3_RoundBit_reg(stage3_RoundBit_reg),
        .stage3_mant_sum_reg(stage3_mant_sum_reg), .stage3_sign_d_reg(stage3_sign_d_reg)
    );

    // Stage 4
    wire [24:0] stage4_signed_mant_sum;

    stage_4 s4 (
        .clk(clk), .rst(rst),  
        .stage3_mant_sum(stage3_mant_sum_reg), 
        .stage4_signed_mant_sum(stage4_signed_mant_sum)
    );

    // Stage 4 to 5 pipeline register
    wire [24:0] stage4_signed_mant_sum_reg;
    wire [7:0] stage4_exp_d_reg;
    wire stage4_RoundBit_reg;

    stage_4_to_5_reg s4_to_5 (
        .clk(clk), .rst(rst),
        .stage3_exp_d(stage3_exp_d_reg), .stage3_RoundBit(stage3_RoundBit_reg),
        .stage4_signed_mant_sum(stage4_signed_mant_sum),
        .stage4_exp_d_reg(stage4_exp_d_reg), .stage4_RoundBit_reg(stage4_RoundBit_reg),
        .stage4_signed_mant_sum_reg(stage4_signed_mant_sum_reg)
    );

    // Stage 5
    wire [23:0] stage5_mant_d;
    wire [7:0] stage5_normalized_exp_d;

    stage_5 s5 (
        .clk(clk), .rst(rst),  
        .stage4_signed_mant_sum(stage4_signed_mant_sum_reg), .stage4_exp_d(stage4_exp_d_reg),
        .stage5_mant_d(stage5_mant_d), .stage5_normalized_exp_d(stage5_normalized_exp_d)
    );

    // Stage 5 to 6 pipeline register
    wire [23:0] stage5_mant_d_reg;
    wire [7:0] stage5_normalized_exp_d_reg;
    wire stage5_RoundBit_reg;

    stage_5_to_6_reg s5_to_6 (
        .clk(clk), .rst(rst),
        .stage5_mant_d(stage5_mant_d), .stage5_normalized_exp_d(stage5_normalized_exp_d),
        .stage4_RoundBit(stage4_RoundBit_reg), .stage5_RoundBit_reg(stage5_RoundBit_reg),
        .stage5_mant_d_reg(stage5_mant_d_reg), .stage5_normalized_exp_d_reg(stage5_normalized_exp_d_reg)
    );

    // Stage 6
    wire [23:0] stage6_rounded_mant_d;

    stage_6 s6 (
        .clk(clk), .rst(rst),  
        .stage5_RoundBit(stage5_RoundBit_reg), .stage5_mant_d(stage5_mant_d_reg),
        .stage6_rounded_mant_d(stage6_rounded_mant_d)
    );

    // Stage 6 to 7 pipeline register
    wire [23:0] stage6_rounded_mant_d_reg;
    wire [7:0] stage6_normalized_exp_d_reg;
    stage_6_to_7_reg s6_to_7 (
        .clk(clk), .rst(rst),
        .stage6_rounded_mant_d(stage6_rounded_mant_d), .stage5_normalized_exp_d(stage5_normalized_exp_d_reg),
        .stage6_rounded_mant_d_reg(stage6_rounded_mant_d_reg), .stage6_normalized_exp_d_reg(stage6_normalized_exp_d_reg)
    );

    // Stage 7
    stage_7 s7 (
        .clk(clk), .rst(rst),  
        .stage3_sign_d(stage3_sign_d_reg), .stage6_normalized_exp_d(stage6_normalized_exp_d_reg), .stage6_rounded_mant_d(stage6_rounded_mant_d_reg),
        .d(d)
    );
endmodule
