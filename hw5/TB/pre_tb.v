`timescale 1ns/10ps
`define CYCLE 50.0
`define DATA_NUM 100

module testbench();
    reg clk = 0;
    reg rst = 0;

    reg [70:0] str[0:5];
    reg [15:0] input_a;
    reg [15:0] input_b;
    reg [7:0] input_a_8;
    reg [7:0] input_b_8;
    wire [31:0] output_p1[0:2];
    wire [15:0] output_p2[0:3];
    reg [31:0] ans1;
    reg [15:0] ans2;
    reg signed [15:0] input_a_s;
    reg signed [15:0] input_b_s;
    reg signed [7:0] input_a_8_s;
    reg signed [7:0] input_b_8_s;
    wire signed [31:0] output_p1_s[0:2];
    wire signed [15:0] output_p2_s[0:3];
    reg signed [31:0] ans1_s;
    reg signed [15:0] ans2_s;

    operator_8x8   utl1(input_a_8_s, input_b_8_s, output_p2_s[0]);
    row_8x8        utl2(input_a_8_s, input_b_8_s, output_p2_s[1]);
    row_cc_8x8     utl3(input_a_8, input_b_8, output_p2[2]);
    array_mul_8x8  utl4(input_a_8, input_b_8, output_p2[3]);

    operator_16x16 utt5(input_a_s, input_b_s, output_p1_s[0]);
    row_16x16      utl6(input_a_s, input_b_s, output_p1_s[1]);
    row_cc_16x16   utl7(input_a, input_b, output_p1[2]);

    always begin #(`CYCLE/2) clk = ~clk; end 

    integer i, j, error=0, mis = 0;

    initial begin
        error=0;
        mis = 0;
        clk = 0;
        rst = 1;
        #(`CYCLE*2);
        rst = 0;

        str[0] = "operator";
        str[1] = "row";
        str[2] = "row_cc";
        str[3] = "array_mul";

        $display("========================================\n");
        $display("16x16 mul :");
        for(i=0; i<3; i=i+1) begin
            error=0;
            mis = 0;
            for(j=0; j<`DATA_NUM; j=j+1) begin
                input_a = $random%(2**(15));
                input_b = $random%(2**(15));
                input_a_s = $random%(2**(15));
                input_b_s = $random%(2**(15));
                ans1 = input_a * input_b;
                ans1_s = input_a_s * input_b_s;
                #(`CYCLE);
                if (i < 2) begin
                    if(ans1_s !== output_p1_s[i]) begin
                        error = error+1;
                    end
                end else begin
                    if(ans1 !== output_p1[i]) begin
                        mis = mis + ans1 - output_p1[i];
                        error = error+1;
                    end
                end
            end 
            $display("%s:", str[i]);
            if(error>0) begin
                $display("Have total %d errors", error);
                if (i == 2) begin
                    $display("avg error", mis/`DATA_NUM);
                end
            end
            else 
                $display("All test data correct!");
        end
        $display("\n========================================");

        $display("========================================\n");
        $display("8x8 mul :");
        for(i=0; i<4; i=i+1) begin
            error=0;
            mis = 0;
            for(j=0; j<`DATA_NUM; j=j+1) begin
                input_a_8 = $random%(2**(7));
                input_b_8 = $random%(2**(7));
                input_a_8_s = $random%(2**(7));
                input_b_8_s = $random%(2**(7));

                ans2 = input_a_8 * input_b_8;
                ans2_s = input_a_8_s * input_b_8_s;
                #(`CYCLE);
                if (i < 2) begin
                    if(ans2_s !== output_p2_s[i]) begin
                        error = error+1;
                    end
                end else begin
                    if(ans2 !== output_p2[i]) begin
                        mis = mis + ans2 - output_p2[i];
                        error = error+1;
                    end
                end
            end 
            $display("%s:", str[i]);
            if(error>0) begin
                $display("Have total %d errors", error);
                if (i == 2) begin
                    $display("avg error", mis/`DATA_NUM);
                end
            end 
            else 
                $display("All test data correct!");
        end
        $display("\n========================================");
    $finish;
    end

endmodule