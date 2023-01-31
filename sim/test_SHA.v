`timescale 1ns/100ps

`define PAT_L 1
`define PAT_U 1
`define PAT_NUM 5

`define PAT_NAME_LENGTH 4 
`define CYCLE 10
`define END_CYCLES 10000

module test_SHA;
localparam BW_SRAM_ADDR = 8;
localparam BW_SRAM_DATA = 64;
localparam BW_MSG_LEN = 11;
localparam BW_HASH_GOLDEN = 256;
localparam BW_HASH_OUTPUT = 64;

localparam MSG_NAME_LENGTH = 20;
localparam LEN_NAME_LENGTH = 20;
localparam GLD_NAME_LENGTH = 20;

integer i;
integer m;
// ===== pattern files ===== // 
reg [MSG_NAME_LENGTH*8-1:0] pattern_msg_file;
reg [LEN_NAME_LENGTH*8-1:0] pattern_len_file;

// ===== pattern message ===== // 
reg [BW_SRAM_DATA-1:0] pattern_msg [0:256-1];
reg [BW_SRAM_DATA-1:0] pattern_len [0:2-1];

// ===== golden files ===== // 
reg [GLD_NAME_LENGTH*8-1:0] sha2_golden_file;
reg [GLD_NAME_LENGTH*8-1:0] sha3_golden_file;

// ===== golden answers ===== //
reg [BW_HASH_GOLDEN-1:0] sha2_golden_ans [0:2-1];
reg [BW_HASH_GOLDEN-1:0] sha3_golden_ans [0:2-1];

// ===== module I/O ===== //
reg clk;
reg srst_n;
reg enable;
wire [BW_MSG_LEN-1:0] m_len;
assign m_len = pattern_len[0];

wire [BW_SRAM_ADDR-1:0] sram_raddr;
wire [BW_SRAM_DATA-1:0] sram_rdata;

wire SHA2_valid;
wire SHA3_valid;
wire [BW_HASH_OUTPUT-1:0] data_out;

// ===== instantiation ===== //
// TODO
sram_256x64b sram_msg(
    .clk(clk),
    .csb(1'b0),
    .wsb(1'b1),
    .wdata(64'b0), 
    .waddr(8'b0), 
    .raddr(sram_raddr), 
    .rdata(sram_rdata)
);

top top_SHA(
    .clk(clk),
	.srst_n(srst_n),
	.enable(enable),
	.sram_data(sram_rdata),
	.m_len(m_len),

	.SHA2_valid(SHA2_valid),
	.SHA3_valid(SHA3_valid),
	.sram_addr(sram_raddr),
	.data_out(data_out)
);

// ===== waveform dumpping ===== //
initial begin
    $fsdbDumpfile("SHA_testbench.fsdb");
    $fsdbDumpvars("+mda");
end

// ===== system reset ===== //
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end

initial begin
	#(`CYCLE * `END_CYCLES);
    $display("\n");
    $display("========================================================");
    $display("   Error!!! Simulation time is too long...            ");
    $display("   There might be something wrong in your code.       ");
	$display("   If your design really needs such a long time,      ");
	$display("   increase the END_CYCLES setting in the testbench.  ");
    $display("========================================================");
    $finish;
end

// ===== cycle counter ===== //
integer cycle_cnt;
initial begin
    while(1) begin 
        cycle_cnt = cycle_cnt + 1;
        @(negedge clk);
    end
end

// ===== input feeding ===== //
// TODO

// ===== output comparision ===== //
integer pat_idx;
integer SHA2_err;
integer SHA3_err;
reg [256-1:0] SHA2_o;
reg [256-1:0] SHA3_o;

initial begin
	// check if PAT_L and PAT_U are both valid
	if((`PAT_L < 1) || (`PAT_L > `PAT_NUM) || (`PAT_U < 1) || (`PAT_U > `PAT_NUM)) begin
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$display("X                                                                             X");
		$display("X   Error!!! PAT_L and PAT_U should be within the range [1, %3d]              X", `PAT_NUM);
		$display("X                                                                             X");
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$finish;
	end
	else if(`PAT_L > `PAT_U) begin
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$display("X                                                        X");
		$display("X   Error!!! PAT_L should be smaller or equal to PAT_U   X");
		$display("X                                                        X");
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$finish;		
	end

    SHA2_err = 0;
    SHA3_err = 0;

    for (pat_idx = `PAT_L; pat_idx <= `PAT_U; pat_idx = pat_idx + 1) begin
        // reest sram
        sram_msg.reset_sram;
        
        // load
        load_msg(pat_idx);
        load_len(pat_idx);
        load_golden(pat_idx);
        
        $display("\n");
        $display("================================================================");
        $display("======================== Pattern No. %02d ========================", pat_idx);
        $display("================================================================");

        srst_n = 1;
        enable = 0;
        cycle_cnt = 0;
        @(negedge clk); srst_n = 1'b0;
        @(negedge clk); srst_n = 1'b1; enable = 1'b1;
        @(negedge clk); enable = 1'b0;

        wait(SHA2_valid || SHA3_valid);
        if (SHA2_valid) begin
            @(negedge clk) SHA2_o[255:192] = data_out;
            @(negedge clk) SHA2_o[191:128] = data_out;
            @(negedge clk) SHA2_o[127:64]  = data_out;
            @(negedge clk) SHA2_o[63:0]    = data_out;
            $display("SHA2 golden: %0h\n", sha2_golden_ans[0]);
            $display("SHA2 output: %0h\n", SHA2_o);

            if (sha2_golden_ans[0] === SHA2_o) begin
                $display("SHA2 #%0d PASS! (cycle = %d)\n", pat_idx, cycle_cnt);
            end
            else begin
                $display("SHA2 #%0d FAIL!\n", pat_idx);
                SHA2_err = SHA2_err + 1;
            end

            wait(SHA3_valid);
            @(negedge clk) SHA3_o[255:192] = data_out;
            @(negedge clk) SHA3_o[191:128] = data_out;
            @(negedge clk) SHA3_o[127:64]  = data_out;
            @(negedge clk) SHA3_o[63:0]    = data_out;
            $display("SHA3 golden: %0h\n", sha3_golden_ans[0]);
            $display("SHA3 output: %0h\n", SHA3_o);

            if (sha3_golden_ans[0] === SHA3_o) begin
                $display("SHA3 #%0d PASS! (cycle = %d)\n", pat_idx, cycle_cnt);
            end
            else begin
                $display("SHA3 #%0d FAIL!\n", pat_idx);
                SHA3_err = SHA3_err + 1;
            end
        end
        else if (SHA3_valid) begin
            @(negedge clk) SHA3_o[255:192] = data_out;
            @(negedge clk) SHA3_o[191:128] = data_out;
            @(negedge clk) SHA3_o[127:64]  = data_out;
            @(negedge clk) SHA3_o[63:0]    = data_out;
            $display("SHA3 golden: %0h\n", sha3_golden_ans[0]);
            $display("SHA3 output: %0h\n", SHA3_o);

            if (sha3_golden_ans[0] === SHA3_o) begin
                $display("SHA3 #%0d PASS! (cycle = %d)\n", pat_idx, cycle_cnt);
            end
            else begin
                $display("SHA3 #%0d FAIL!\n", pat_idx);
                SHA3_err = SHA3_err + 1;
            end

            wait(SHA2_valid);
            @(negedge clk) SHA2_o[255:192] = data_out;
            @(negedge clk) SHA2_o[191:128] = data_out;
            @(negedge clk) SHA2_o[127:64]  = data_out;
            @(negedge clk) SHA2_o[63:0]    = data_out;
            $display("SHA2 golden: %0h\n", sha2_golden_ans[0]);
            $display("SHA2 output: %0h\n", SHA2_o);

            if (sha2_golden_ans[0] === SHA2_o) begin
                $display("SHA2 #%0d PASS! (cycle = %d)\n", pat_idx, cycle_cnt);
            end
            else begin
                $display("SHA2 #%0d FAIL!\n", pat_idx);
                SHA2_err = SHA2_err + 1;
            end
        end
    end

    $display("\n\n\n             Summary of all pattern: ");
    if (SHA2_err == 0 && SHA3_err == 0) begin
        $display("-----------------------------------------------------\n");
        $display("               All patterns are correct.             \n");
        $display("-------------------------PASS------------------------\n");
        $finish;
    end
    else begin
        $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$display("X                                                 X");
        $display("X         SHA2 %3d patterns are failed...         X", SHA2_err);
        $display("X         SHA3 %3d patterns are failed...         X", SHA3_err);
		$display("X                                                 X");
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        $finish;
    end
end

task load_len(
    input integer idx
);
    reg [8-1:0] idx_digit_3, idx_digit_2, idx_digit_1, idx_digit_0;
    begin
        pattern_len_file = "pattern/len/0000.txt";

        idx_digit_3 = (idx / 1000) + 48;
        idx_digit_2 = (idx % 1000) / 100 + 48;
        idx_digit_1 = (idx % 100) / 10 + 48;
        idx_digit_0 = (idx % 10) + 48;

        // set pattern file
        pattern_len_file[4 * 8 +:`PAT_NAME_LENGTH * 8] = {idx_digit_3, idx_digit_2, idx_digit_1, idx_digit_0};

        // load pattern length
        $readmemb(pattern_len_file, pattern_len);
    end
endtask

task load_msg(
    input integer idx
);
    reg [8-1:0] idx_digit_3, idx_digit_2, idx_digit_1, idx_digit_0;
    begin
        pattern_msg_file = "pattern/msg/0000.txt";

        idx_digit_3 = (idx / 1000) + 48;
        idx_digit_2 = (idx % 1000) / 100 + 48;
        idx_digit_1 = (idx % 100) / 10 + 48;
        idx_digit_0 = (idx % 10) + 48;

        // set pattern file
        pattern_msg_file[4 * 8 +:`PAT_NAME_LENGTH * 8] = {idx_digit_3, idx_digit_2, idx_digit_1, idx_digit_0};

        // load pattern message
        $readmemb(pattern_msg_file, pattern_msg);

        // store into sram
        for (i = 0; i < 256; i = i + 1) begin
            sram_msg.load_msg(i, pattern_msg[i]);
        end
    end
endtask

task load_golden(
    input integer idx
);
    reg [8-1:0] idx_digit_3, idx_digit_2, idx_digit_1, idx_digit_0;
    begin
        sha2_golden_file = "golden/SHA2/0000.txt";
        sha3_golden_file = "golden/SHA3/0000.txt";

        idx_digit_3 = (idx / 1000) + 48;
        idx_digit_2 = (idx % 1000) / 100 + 48;
        idx_digit_1 = (idx % 100) / 10 + 48;
        idx_digit_0 = (idx % 10) + 48;

        // set golden file
        sha2_golden_file[4 * 8 +:`PAT_NAME_LENGTH * 8] = {idx_digit_3, idx_digit_2, idx_digit_1, idx_digit_0};
        sha3_golden_file[4 * 8 +:`PAT_NAME_LENGTH * 8] = {idx_digit_3, idx_digit_2, idx_digit_1, idx_digit_0}; 

        // load golden answer
        $readmemh(sha2_golden_file, sha2_golden_ans);
        $readmemh(sha3_golden_file, sha3_golden_ans);
    end
endtask

endmodule