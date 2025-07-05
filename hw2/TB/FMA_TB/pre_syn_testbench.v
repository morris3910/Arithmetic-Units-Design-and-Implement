// Standard Delay Format File
//`define SDFFILE    "./FXP_adder_syn.sdf"

`timescale 1ns/1ps
`define CYCLE 5.0
`define DATA_NUM 200
/*
`define FILE_A "/home/B103040021_ALU/HW2/RTL/normal/a.txt"
`define FILE_B "/home/B103040021_ALU/HW2/RTL/normal/b.txt"
`define FILE_C "/home/B103040021_ALU/HW2/RTL/normal/c.txt"
`define FILE_ANS "/home/B103040021_ALU/HW2/RTL/normal/ab+c.txt"
*/

`define FILE_A "/home/B103040021_ALU/HW2/RTL/special/a.txt"
`define FILE_B "/home/B103040021_ALU/HW2/RTL/special/b.txt"
`define FILE_C "/home/B103040021_ALU/HW2/RTL/special/c.txt"
`define FILE_ANS "/home/B103040021_ALU/HW2/RTL/special/ab+c.txt"

module testbench();
    integer file_a, file_b, file_c, file_ans;
    reg CLK = 0;
    reg RST = 0;
    reg  [31:0] data_a [0:`DATA_NUM-1];
    reg  [31:0] data_b [0:`DATA_NUM-1];
    reg  [31:0] data_c [0:`DATA_NUM-1];
    reg  [31:0] data_ans [0:`DATA_NUM-1];
    reg  [31:0] input_a, temp_a;
    reg  [31:0] input_b, temp_b;
    reg  [31:0] input_c, temp_c, input_ans;
    reg  [63:0] temp_answer;
    wire check;
    `ifdef FXP_mul
        reg  [63:0] answer;
        wire [63:0] outcome;
    `else 
        reg  [31:0] answer;
        wire [31:0] outcome;
    `endif
    real real_a, real_b, real_ans, real_outcome, real_error, total_error;

    FXP_FMA utl( .a(input_a), .b(input_b), .c(input_c), .d(outcome));

    `ifdef SDF_FILE
        initial $sdf_annotate(`SDF_FILE, test_module);
    `endif

    always begin #(`CYCLE/2) CLK = ~CLK; end

    integer i, flag=0, error=0, garbage;
    initial 
    begin
        file_a = $fopen(`FILE_A, "r");
        file_b = $fopen(`FILE_B, "r");
        file_c = $fopen(`FILE_C, "r");
        file_ans = $fopen(`FILE_ANS, "r");
        for(i=0; i<`DATA_NUM; i=i+1)
        begin
            garbage = $fscanf(file_a, "%X", data_a[i]);
            garbage = $fscanf(file_b, "%X", data_b[i]);
            garbage = $fscanf(file_c, "%X", data_c[i]);
            garbage = $fscanf(file_ans, "%X", data_ans[i]);
        end
    end
    
    initial 
    begin
        CLK = 0;
        RST = 1;
        #(`CYCLE*2);
        RST = 0;
        total_error = 0;
        for(i=0; i<`DATA_NUM; i=i+1)
        begin
            input_a = data_a[i];
            input_b = data_b[i];
            input_c = data_c[i];
            input_ans = data_ans[i];
            #(`CYCLE);
            if(!(input_ans===outcome))
            begin
                error = error+1;
                if(1||flag==0)
                begin
                    $display("-----------------------------------------\n");
                    $display("Output incorrect at #%d\n", i+1);
                    $display("The input A is    : %b\n", input_a);
                    $display("The input B is    : %b\n", input_b);
                    $display("The input C is    : %b\n", input_c);
                    $display("The answer is     : %b\n", input_ans);
                    $display("Your module output: %b\n", outcome);
                    $display("?: %d\n", answer-outcome);
                    $display("-----------------------------------------\n");
                    flag = 1;
                end //if flag
            end //if
        end //for
        if (error) begin
            $display("-----------------------------------------\n");
            $display("You have %1d errors\n", error);
            $display("-----------------------------------------\n");
        end
        else begin
            $display("-----------------------------------------\n");
            $display("Test data all correct !\n");
            $display("-----------------------------------------\n");
        end
        $fclose(file_a);
        $fclose(file_b);
        $fclose(file_c);
        $fclose(file_ans);
        $finish;
    end //initial
endmodule //testbench