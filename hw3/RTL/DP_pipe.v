module FLP_DP (
    input  clk, rst, mode,
    input  [31:0] x1, x2, x3, x4,
    input  [31:0] y1, y2, y3, y4,         
    output [31:0] z       
);
    wire sign_1, sign_2, sign_3, sign_4;
    wire [7:0] exp_z;
    wire [47:0] product_1, product_2, product_3, product_4;
    //wire [3:0] round_bit
    stage1 s1 (
        mode, clk, rst,
        x1, x2, x3, x4, y1, y2, y3, y4,
        sign_1, sign_2, sign_3, sign_4,
        exp_z,
        product_1, product_2, product_3, product_4
        //round_bit
    );
    reg mode_reg1;
    reg sign_1_reg1, sign_2_reg1, sign_3_reg1, sign_4_reg1;
    reg [7:0] exp_z_reg1;
    reg [47:0] product_1_reg1, product_2_reg1, product_3_reg1, product_4_reg1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mode_reg1 <= 0;
            sign_1_reg1 <= 0;
            sign_2_reg1 <= 0;
            sign_3_reg1 <= 0;
            sign_4_reg1 <= 0;
            exp_z_reg1 <= 0;
            product_1_reg1 <= 0;
            product_2_reg1 <= 0;
            product_3_reg1 <= 0;
            product_4_reg1 <= 0;
        end else begin
            mode_reg1 <= mode;
            sign_1_reg1 <= sign_1;
            sign_2_reg1 <= sign_2;
            sign_3_reg1 <= sign_3;
            sign_4_reg1 <= sign_4;
            exp_z_reg1  <= exp_z;
            product_1_reg1 <= product_1;
            product_2_reg1 <= product_2;
            product_3_reg1 <= product_3;
            product_4_reg1 <= product_4;
            
        end
    end

    wire [49:0] sign_magnitude;
    wire sign_final;
    stage2 s2 (
        mode_reg1, sign_1_reg1, sign_2_reg1, sign_3_reg1, sign_4_reg1,
        product_1_reg1, product_2_reg1, product_3_reg1, product_4_reg1,
        sign_final, sign_magnitude
    );

    reg [49:0] sign_magnitude_reg2;
    reg [7:0] exp_z_reg2;
    reg mode_reg2, sign_final_reg2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mode_reg2 <= 0;
            sign_magnitude_reg2 <= 0;
            exp_z_reg2 <= 0;
            sign_final_reg2 <= 0;
        end else begin
            mode_reg2 <= mode_reg1;
            sign_magnitude_reg2 <= sign_magnitude;
            exp_z_reg2 <= exp_z_reg1;
            sign_final_reg2 <= sign_final;
        end
    end

    wire [49:0] normalized_mantissa;
    wire [7:0] exp_final;
    stage3 s3(
        mode_reg2, exp_z_reg2, sign_magnitude_reg2,
        normalized_mantissa, exp_final
    );

    reg [49:0] normalized_mantissa_reg3;
    reg [7:0] exp_final_reg3;
    reg mode_reg3, sign_final_reg3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            normalized_mantissa_reg3 <= 0;
            exp_final_reg3 <= 0;
            sign_final_reg3 <= 0;
            mode_reg3 <= 0;
        end else begin
            normalized_mantissa_reg3 <= normalized_mantissa;
            exp_final_reg3 <= exp_final;
            sign_final_reg3 <= sign_final_reg2;
            mode_reg3 <= mode_reg2;
        end
    end

    stage4 s4(
        mode_reg3, normalized_mantissa_reg3, exp_final_reg3, sign_final_reg3,
        z
    );

endmodule

module stage1 (
    input mode, clk, rst,
    input [31:0] x1, x2, x3, x4,
    input [31:0] y1, y2, y3, y4,
    output reg sign_1, sign_2, sign_3, sign_4,
    output reg [7:0] exp_z,
    output reg [47:0] product_1, product_2, product_3, product_4
);
    integer i, j;
    reg [23:0] unpacked_m [7:0];
    reg extracted_s [0:7];
    reg [7:0] extracted_e [0:7];
    reg [11:0] extracted_m [0:15];

    reg sign [0:3];
    reg [7:0] exp [0:3];
    reg [47:0] product [0:3];
    wire [47:0] connect_product [0:3];
    reg [23:0] HH, HL, LH, LL;
    
    reg [7:0] max_exp;
    reg [7:0] exp_diff;

    always @(*) begin
        if (mode) begin
            extracted_s[0] = x1[31]; extracted_s[1] = x2[31]; extracted_s[2] = x3[31]; extracted_s[3] = x4[31];
            extracted_s[4] = y1[31]; extracted_s[5] = y2[31]; extracted_s[6] = y3[31]; extracted_s[7] = y4[31];
            extracted_e[0] = x1[30:23]; extracted_e[1] = x2[30:23]; extracted_e[2] = x3[30:23]; extracted_e[3] = x4[30:23];
            extracted_e[4] = y1[30:23]; extracted_e[5] = y2[30:23]; extracted_e[6] = y3[30:23]; extracted_e[7] = y4[30:23];
            unpacked_m[0] = {1'b1, x1[22:0]}; unpacked_m[1] = {1'b1, x2[22:0]}; unpacked_m[2] = {1'b1, x3[22:0]}; unpacked_m[3] = {1'b1, x4[22:0]};
            unpacked_m[4] = {1'b1, y1[22:0]}; unpacked_m[5] = {1'b1, y2[22:0]}; unpacked_m[6] = {1'b1, y3[22:0]}; unpacked_m[7] = {1'b1, y4[22:0]};
                
            j = 0;
            for (i=0; i<8; i=i+2) begin
                sign[j] = extracted_s[j] ^ extracted_s[j+4];
                exp[j] = extracted_e[j] + extracted_e[j+4] - 8'd127;
                //product[j] = {HH, 24'b0} + {HL, 12'b0} + {LH, 12'b0} + LL;
                j = j + 1;
            end
        end else begin
            //16-bit mul
            extracted_s[0] = x1[15]; extracted_s[1] = x2[15]; extracted_s[2] = x3[15]; extracted_s[3] = x4[15];
            extracted_s[4] = y1[15]; extracted_s[5] = y2[15]; extracted_s[6] = y3[15]; extracted_s[7] = y4[15];
            extracted_e[0] = {3'b000, x1[14:10]}; extracted_e[1] = {3'b000, x2[14:10]}; extracted_e[2] = {3'b000, x3[14:10]}; extracted_e[3] = {3'b000, x4[14:10]};
            extracted_e[4] = {3'b000, y1[14:10]}; extracted_e[5] = {3'b000, y2[14:10]}; extracted_e[6] = {3'b000, y3[14:10]}; extracted_e[7] = {3'b000, y4[14:10]};
            unpacked_m[0] = {13'b0000000001, x1[9:0]}; unpacked_m[1] = {13'b0000000001, x2[9:0]}; unpacked_m[2] = {13'b0000000001, x3[9:0]}; unpacked_m[3] = {13'b0000000001, x4[9:0]};
            unpacked_m[4] = {13'b0000000001, y1[9:0]}; unpacked_m[5] = {13'b0000000001, y2[9:0]}; unpacked_m[6] = {13'b0000000001, y3[9:0]}; unpacked_m[7] = {13'b0000000001, y4[9:0]};
                
            j = 0;
            for (i=0; i<8; i=i+2) begin
                //HH = extracted_m[i] * extracted_m[i+8];
                //HL = extracted_m[i] * extracted_m[i+9];
                //LH = extracted_m[i+1] * extracted_m[i+8];
                //LL = extracted_m[i+1] * extracted_m[i+9];
                sign[j] = extracted_s[j] ^ extracted_s[j+4];
                exp[j] = extracted_e[j] + extracted_e[j+4] - 8'd15;
                //product[j] = {HH, 24'b0} + {HL, 12'b0} + {LH, 12'b0} + LL;
                j = j + 1;
            end
        end
    end

    ClockGating cg1 (clk, rst, mode, unpacked_m[0], unpacked_m[4], connect_product[0]);
    ClockGating cg2 (clk, rst, mode, unpacked_m[1], unpacked_m[5], connect_product[1]);
    ClockGating cg3 (clk, rst, mode, unpacked_m[2], unpacked_m[6], connect_product[2]);
    ClockGating cg4 (clk, rst, mode, unpacked_m[3], unpacked_m[7], connect_product[3]);

    reg [7:0] exp_reg [0:3];
    reg sign_reg [0:3];
    always @(posedge clk) begin
        for (i = 0; i < 4; i = i+1) begin
            exp_reg[i] <= exp[i];
            sign_reg[i] <= sign[i];
        end
    end

    always @(*) begin
        //$display("%b", connect_product[0]);
        product[0] = connect_product[0];
        product[1] = connect_product[1];
        product[2] = connect_product[2];
        product[3] = connect_product[3];
        //if (mode) begin
            max_exp = (exp_reg[0] >= exp_reg[1]) ? 
            ((exp_reg[0] >= exp_reg[2]) ? ((exp_reg[0] >= exp_reg[3]) ? exp_reg[0] : exp_reg[3]) : ((exp_reg[2] >= exp_reg[3]) ? exp_reg[2] : exp_reg[3])) : 
            ((exp_reg[1] >= exp_reg[2]) ? ((exp_reg[1] >= exp_reg[3]) ? exp_reg[1] : exp_reg[3]) : ((exp_reg[2] >= exp_reg[3]) ? exp_reg[2] : exp_reg[3]));
                            
            for (i=0; i<4; i=i+1) begin
                if (max_exp > exp_reg[i]) begin
                    exp_diff = max_exp - exp_reg[i];
                    product[i] = product[i] >> exp_diff;
                end
            end
                
            sign_1 = sign_reg[0]; sign_2 = sign_reg[1]; sign_3 = sign_reg[2]; sign_4 = sign_reg[3];
            exp_z = max_exp;
            product_1 = product[0]; product_2 = product[1];
            product_3 = product[2]; product_4 = product[3];
        //end
    end
endmodule

module ClockGating (
    input clk, rst, mode, 
    input [23:0] x, y, 
    output reg [47:0] product
);
    reg [11:0] xH, xL, yH, yL;
    reg [11:0] xL_16, yL_16;
    wire gclk;
    reg [23:0] HH, HL, LH, LL;
    
    assign gclk = clk & mode;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            xL_16 <= 0;
            yL_16 <= 0;
        end else begin
            xL_16 <= x[11:0];
            yL_16 <= y[11:0];
        end
    end
    
    always @ (posedge gclk or posedge rst) begin
        if (rst) begin
            xH <= 0;
            xL <= 0;
            yH <= 0;
            yL <= 0;
        end else begin
            xH <= x[23:12];
            xL <= x[11:0];
            yH <= y[23:12];
            yL <= y[11:0];
        end
    end

    always @(*) begin
        HH = xH * yH;
        HL = xH * yL;
        LH = xL * yH;
        LL = xL_16 * yL_16;
        product = mode ? ({HH, 24'b0} + {HL, 12'b0} + {LH, 12'b0} + LL) : LL;
    end
endmodule

module stage2 (
    input mode, sign_1, sign_2, sign_3, sign_4,
    input [47:0] product_1, product_2, product_3, product_4,
    output sign,
    output [49:0] sign_magnitude
);
    wire signed [48:0] product_1_signed;
    wire signed [48:0] product_2_signed;
    wire signed [48:0] product_3_signed;
    wire signed [48:0] product_4_signed;
    assign product_1_signed = sign_1 ? {1'b1, ~product_1 + 1'b1} : {1'b0, product_1};
    assign product_2_signed = sign_2 ? {1'b1, ~product_2 + 1'b1} : {1'b0, product_2};
    assign product_3_signed = sign_3 ? {1'b1, ~product_3 + 1'b1} : {1'b0, product_3};
    assign product_4_signed = sign_4 ? {1'b1, ~product_4 + 1'b1} : {1'b0, product_4};

    wire signed [50:0] sum;
    assign sum = mode ? product_1_signed + product_2_signed + product_3_signed + product_4_signed : (product_1_signed + product_2_signed + product_3_signed + product_4_signed) << 24;

    // Convert to sign-magnitude
    assign sign = sum[50];
    assign sign_magnitude = sign ? ~sum[49:0] + 1 : sum[49:0];
endmodule

module stage3 (
    input mode,
    input [7:0] exp_z,
    input [49:0] sign_magnitude,
    output reg [49:0] normalized_mantissa,
    output reg [7:0] exp_final
);
    reg [49:0] magnitude;
    reg sign;
    integer shift_count, i;
    
    always @(*) begin
        magnitude = sign_magnitude;
        case (1)
            magnitude[49]: shift_count = 1;
            magnitude[48]: shift_count = 2;
            magnitude[47]: shift_count = 3;
            magnitude[46]: shift_count = 4;
            magnitude[45]: shift_count = 5;
            magnitude[44]: shift_count = 6;
            magnitude[43]: shift_count = 7;
            magnitude[42]: shift_count = 8;
            magnitude[41]: shift_count = 9;
            magnitude[40]: shift_count = 10;
            magnitude[39]: shift_count = 11;
            magnitude[38]: shift_count = 12;
            magnitude[37]: shift_count = 13;
            magnitude[36]: shift_count = 14;
            magnitude[35]: shift_count = 15;
            magnitude[34]: shift_count = 16;
            magnitude[33]: shift_count = 17;
            magnitude[32]: shift_count = 18;
            magnitude[31]: shift_count = 19;
            magnitude[30]: shift_count = 20;
            magnitude[29]: shift_count = 21;
            magnitude[28]: shift_count = 22;
            magnitude[27]: shift_count = 23;
            magnitude[26]: shift_count = 24;
            magnitude[25]: shift_count = 25;
            magnitude[24]: shift_count = 26;
            magnitude[23]: shift_count = 27;
            magnitude[22]: shift_count = 28;
            magnitude[21]: shift_count = 29;
            magnitude[20]: shift_count = 30;
            magnitude[19]: shift_count = 31;
            magnitude[18]: shift_count = 32;
            magnitude[17]: shift_count = 33;
            magnitude[16]: shift_count = 34;
            magnitude[15]: shift_count = 35;
            magnitude[14]: shift_count = 36;
            magnitude[13]: shift_count = 37;
            magnitude[12]: shift_count = 38;
            magnitude[11]: shift_count = 39;
            magnitude[10]: shift_count = 40;
            magnitude[9]:  shift_count = 41;
            magnitude[8]:  shift_count = 42;
            magnitude[7]:  shift_count = 43;
            magnitude[6]:  shift_count = 44;
            magnitude[5]:  shift_count = 45;
            magnitude[4]:  shift_count = 46;
            magnitude[3]:  shift_count = 47;
            magnitude[2]:  shift_count = 48;
            magnitude[1]:  shift_count = 49;
            magnitude[0]:  shift_count = 50;
            default: shift_count = 0;
        endcase  
        normalized_mantissa = magnitude << shift_count;
        exp_final = mode ? exp_z - (shift_count - 4) : exp_z - (shift_count - 6);
    end
endmodule

module stage4 (
    input mode,
    input [49:0] normalized_mantissa,
    input [7:0] exp,
    input sign_final,
    output [31:0] z 
);
    reg [23:0] mantissa;
    reg [22:0] mantissa_final;
    reg [7:0] exp_final;
    always @(*) begin
        if (mode) begin
            if (normalized_mantissa[26] && (normalized_mantissa[25] || (|normalized_mantissa[24:0]))) begin
                mantissa = normalized_mantissa[49:27] + 1;
            end else begin
                mantissa = normalized_mantissa[49:27];
            end
            if (mantissa[23]) begin
                mantissa_final = mantissa[23:1];
                exp_final = exp + 1;
            end else begin
                mantissa_final = mantissa[22:0];
                exp_final = exp;
            end
        end else begin
            if (normalized_mantissa[39] && (normalized_mantissa[38] || (|normalized_mantissa[37:0]))) begin
                mantissa = {13'd0, {1'd0, normalized_mantissa[49:40]} + 1};
            end else begin
                mantissa = {14'd0, normalized_mantissa[49:40]};
            end
            if (mantissa[23]) begin
                mantissa_final = {13'b0, mantissa[10:1]};
                exp_final = exp + 1;
            end else begin
                mantissa_final = {13'b0, mantissa[9:0]};
                exp_final = exp;
            end
        end
        
    end
    assign z = mode ? {sign_final, exp_final, mantissa_final} : {16'd0, sign_final, exp_final[4:0], mantissa_final[9:0]};
    
endmodule

