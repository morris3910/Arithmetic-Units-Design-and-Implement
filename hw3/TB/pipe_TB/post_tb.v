`define FLP_DP_32
//`define FLP_DP_16
`timescale 1ns/1ps
`define SDFFILE    "/home/B103040021_ALU/HW3/dc_out_file/hw3_clock_gating_syn.sdf"
`define CYCLE 5.0
`define DATA_NUM 1000
`define PIPE 5
`ifdef FLP_DP_32
    `define FILE "/home/B103040021_ALU/HW3/TB/FP32.txt"
    `define ANS_FILE "/home/B103040021_ALU/HW3/TB/FP32_result.txt"
`elsif FLP_DP_16
    `define FILE "/home/B103040021_ALU/HW3/TB/FP16.txt"
    `define ANS_FILE "/home/B103040021_ALU/HW3/TB/FP16_result.txt"
`endif 
module testbench();
    integer file, ans_file;
    reg CLK = 0;
    reg RST = 0;
    reg  [31:0] data_x1 [0:`DATA_NUM-1];
    reg  [31:0] data_x2 [0:`DATA_NUM-1];
    reg  [31:0] data_x3 [0:`DATA_NUM-1];
    reg  [31:0] data_x4 [0:`DATA_NUM-1];
    reg  [31:0] data_y1 [0:`DATA_NUM-1];
    reg  [31:0] data_y2 [0:`DATA_NUM-1];
    reg  [31:0] data_y3 [0:`DATA_NUM-1];
    reg  [31:0] data_y4 [0:`DATA_NUM-1];
    reg  [63:0] temp_answer;
    
    reg [255:0] line; // To store one line of data
    reg [31:0] x[0:3];  // Arrays to hold parsed hex values
    reg [31:0] y[0:3];
    reg [31:0] x1, x2, x3, x4;
    reg [31:0] y1, y2, y3, y4;
    reg [31:0] tmp_x1, tmp_x2, tmp_x3, tmp_x4;
    reg [31:0] tmp_y1, tmp_y2, tmp_y3, tmp_y4;
    wire [31:0] outcome;
    `ifdef FLP_DP_32
        reg  [31:0] answer;
        reg  [31:0] ans [0:`DATA_NUM-1];
        reg  [31:0] tmp_ans;
        reg  [31:0] real_outcome;
        reg  mode = 1;
    `elsif FLP_DP_16
        reg  [15:0] answer;
        reg  [15:0] ans [0:`DATA_NUM-1];
        reg  [15:0] tmp_ans;
        reg  [15:0] real_outcome;
        reg  mode = 0;
    `endif
    real real_a, real_b, real_ans, real_error, total_error, tmp_error;
    real real_x1, real_x2, real_x3, real_x4, real_y1, real_y2, real_y3, real_y4;
    
    FLP_DP FLP_DP(CLK, RST, mode, x1, x2, x3, x4, y1, y2, y3, y4, outcome);

    always begin #(`CYCLE/2) CLK = ~CLK; end

    integer i, flag=0, error=0, garbage;
    initial begin
        $dumpvars();
        $dumpfile("HW3_wave.vcd");
        $sdf_annotate(`SDFFILE, FLP_DP);
    end

    initial begin
        file = $fopen(`FILE, "r");
        ans_file = $fopen(`ANS_FILE, "r");
        for(i=0; i<`DATA_NUM; i=i+1)
        begin
            garbage = $fscanf(file, "%X %X %X %X %X %X %X %X\n", 
                data_x1[i], data_x2[i], data_x3[i], data_x4[i], 
                data_y1[i], data_y2[i], data_y3[i], data_y4[i]);
            if (mode) begin
                garbage = $fscanf(ans_file, "%b", ans[i]);
            end else begin
                garbage = $fscanf(ans_file, "%X", ans[i]);
            end
        end
    end
    initial begin
        CLK = 0;
        RST = 1;
        #(`CYCLE*2);
        RST = 0;
        total_error = 0;
        for(i=0; i<`DATA_NUM+`PIPE-2; i=i+1)
        begin
            if(i<`DATA_NUM) begin
                x1 = data_x1[i];
                x2 = data_x2[i];
                x3 = data_x3[i];
                x4 = data_x4[i];
                y1 = data_y1[i];
                y2 = data_y2[i];
                y3 = data_y3[i];
                y4 = data_y4[i];
            end
            #(`CYCLE);
            if(i>=(`PIPE-2))
            begin
                tmp_x1 = data_x1[i+2-`PIPE];
                tmp_x2 = data_x2[i+2-`PIPE];
                tmp_x3 = data_x3[i+2-`PIPE];
                tmp_x4 = data_x4[i+2-`PIPE];
                tmp_y1 = data_y1[i+2-`PIPE];
                tmp_y2 = data_y2[i+2-`PIPE];
                tmp_y3 = data_y3[i+2-`PIPE];
                tmp_y4 = data_y4[i+2-`PIPE];
                tmp_ans = ans[i+2-`PIPE];
                real_x1 = $bitstoreal({tmp_x1[31], {3'd0, tmp_x1[30:23]}-127+1023, tmp_x1[22:0], 29'd0});
                real_x2 = $bitstoreal({tmp_x2[31], {3'd0, tmp_x2[30:23]}-127+1023, tmp_x2[22:0], 29'd0});
                real_x3 = $bitstoreal({tmp_x3[31], {3'd0, tmp_x3[30:23]}-127+1023, tmp_x3[22:0], 29'd0});
                real_x4 = $bitstoreal({tmp_x4[31], {3'd0, tmp_x4[30:23]}-127+1023, tmp_x4[22:0], 29'd0});
                real_y1 = $bitstoreal({tmp_y1[31], {3'd0, tmp_y1[30:23]}-127+1023, tmp_y1[22:0], 29'd0});
                real_y2 = $bitstoreal({tmp_y2[31], {3'd0, tmp_y2[30:23]}-127+1023, tmp_y2[22:0], 29'd0});
                real_y3 = $bitstoreal({tmp_y3[31], {3'd0, tmp_y3[30:23]}-127+1023, tmp_y3[22:0], 29'd0});
                real_y4 = $bitstoreal({tmp_y4[31], {3'd0, tmp_y4[30:23]}-127+1023, tmp_y4[22:0], 29'd0});
                real_ans = real_x1*real_y1 + real_x2*real_y2 + real_x3*real_y3 + real_x4*real_y4;
                temp_answer = $realtobits(real_ans);
                //answer = {temp_answer[63], temp_answer[62:52]-1023+127, temp_answer[51:29]};
                answer = tmp_ans;
                real_outcome = mode ? outcome : outcome[15:0];
                //real_outcome = $bitstoreal({outcome[31], {3'd0, outcome[30:23]}-127+1023, outcome[22:0], 29'd0});
                real_error = (real_outcome > real_ans) ? ((real_outcome - real_ans) / real_ans) : ((real_ans - real_outcome) / real_ans);
                total_error = real_error*(1/(i-`PIPE+3.0)) + total_error*((i-`PIPE+2)/(i-`PIPE+3.0));
                tmp_error = tmp_error + answer - real_outcome;
                // $display("Your module output: %X\n", outcome);
                if(!((answer===(real_outcome-1)) || (answer===real_outcome) || (answer ===(real_outcome+1)) ))
                begin
                    error = error+1;
                    if(1||flag==0)
                    begin
                        $display("-----------------------------------------\n");
                        $display("Output incorrect at #%d\n", i+3-`PIPE);
                        $display("The answer is     : %b\n", answer);
                        $display("Your module output: %b\n", real_outcome);
                        $display("?: %d\n", answer-real_outcome);
                        $display("-----------------------------------------\n");
                        flag = 1;
                    end //if flag
                end //if error
            end //if pipe
        end //for
        if (error) begin
            $display("-----------------------------------------\n");
            $display("avg error: %d\n", error);
            $display("-----------------------------------------\n");
        end else begin
            $display("-----------------------------------------\n");
            $display("All test data correct !\n");
            $display("-----------------------------------------\n");
        end
        $fclose(file);
        $fclose(ans_file);
        $finish;
    end //initial
endmodule //testbench