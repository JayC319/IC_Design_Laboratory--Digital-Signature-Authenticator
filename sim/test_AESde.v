`timescale 1ns/100ps
`define CYCLE 10
`define END_CYCLES 1000

module test_AESen;
localparam KEY_BW = 256;
localparam TXT_BW = 128;
// ===== module I/O ===== //
reg clk;
reg srst_n;
reg enable;
reg mode;
reg [KEY_BW-1:0] key;
reg [TXT_BW-1:0] word;

wire [TXT_BW-1:0] en_result;
wire [TXT_BW-1:0] de_result;
wire en_done;
wire de_done;

// ===== instantiation ===== //
AES aes(
    .clk(clk),
    .srst_n(srst_n),
    .enable(enable),
    .mode(mode),
    .key(key),
    .word(word),

    // .en_result(en_result),
    // .de_result(de_result),
    // .AES_en_done(en_done),
    // .AES_de_done(de_done)
    .result(de_result),
    .done(de_done)
);

// ===== waveform dumpping ===== //
initial begin
    $fsdbDumpfile("AESde_testbench.fsdb");  
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

// ===== input feeding ===== //
initial begin
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    word = 128'h8ea2b7ca516745bfeafc49904b496089;
    mode = 1;   
end

// ===== output golden ===== //
reg [128-1:0] de_golden [0:14];
initial begin
    de_golden[0] = 128'h0;
    de_golden[1] = 128'h0;
    de_golden[2] = 128'h0;
    de_golden[3] = 128'h0;
    de_golden[4] = 128'h0;
    de_golden[5] = 128'h0;
    de_golden[6] = 128'h0;
    de_golden[7] = 128'h0;
    de_golden[8] = 128'h0;
    de_golden[9] = 128'h0;
    de_golden[10] = 128'h0;
    de_golden[11] = 128'h0;
    de_golden[12] = 128'h0;
    de_golden[13] = 128'h0;
    de_golden[14] = 128'h00112233445566778899aabbccddeeff;   
end

// ===== output comparision ===== //
integer i;
initial begin
    srst_n = 1;
    enable = 0;
    @(negedge clk); srst_n = 1'b0;
    @(negedge clk); srst_n = 1'b1; enable = 1'b1;
    @(negedge clk); enable = 1'b0;

    wait(de_done); @(negedge clk);
    for (i = 0; i <= 0; i = i + 1) begin        
        $display("\n");
        $display("================================================================");
        $display("========================= AES decrypt ==========================");   
        $display("================================================================");

        $display("AES key golden: %0h\n", de_golden[14]);
        $display("AES key output: %0h\n", de_result);   
    end
    $finish;
end

endmodule