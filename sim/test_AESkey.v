`timescale 1ns/100ps
`define CYCLE 10
`define END_CYCLES 10000

module test_AESkey;
// ===== module I/O ===== //
reg clk;
reg srst_n;
reg enable;
reg [255:0] key;
reg [3:0] round;

wire [127:0] k_sch_o;
wire key_ready;

// ===== instantiation ===== //
AES_key_ctr aes_key(
    .clk(clk),
    .srst_n(srst_n),
    .key_ctrl_en(enable),
    .key(key),
    .round(round),

    .round_key(k_sch_o),
    .key_ready(key_ready)
);

// ===== waveform dumpping ===== //
initial begin
    $fsdbDumpfile("AESkey_testbench.fsdb");
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
end

// ===== output golden ===== //
reg [128-1:0] k_sch_golden [0:14];
initial begin
    k_sch_golden[0] = 128'h000102030405060708090a0b0c0d0e0f;
    k_sch_golden[1] = 128'h101112131415161718191a1b1c1d1e1f;
    k_sch_golden[2] = 128'ha573c29fa176c498a97fce93a572c09c;
    k_sch_golden[3] = 128'h1651a8cd0244beda1a5da4c10640bade;
    k_sch_golden[4] = 128'hae87dff00ff11b68a68ed5fb03fc1567;
    k_sch_golden[5] = 128'h6de1f1486fa54f9275f8eb5373b8518d;
    k_sch_golden[6] = 128'hc656827fc9a799176f294cec6cd5598b;
    k_sch_golden[7] = 128'h3de23a75524775e727bf9eb45407cf39;
    k_sch_golden[8] = 128'h0bdc905fc27b0948ad5245a4c1871c2f;
    k_sch_golden[9] = 128'h45f5a66017b2d387300d4d33640a820a;
    k_sch_golden[10] = 128'h7ccff71cbeb4fe5413e6bbf0d261a7df;
    k_sch_golden[11] = 128'hf01afafee7a82979d7a5644ab3afe640;
    k_sch_golden[12] = 128'h2541fe719bf500258813bbd55a721c0a;
    k_sch_golden[13] = 128'h4e5a6699a9f24fe07e572baacdf8cdea;
    k_sch_golden[14] = 128'h24fc79ccbf0979e9371ac23c6d68de36;
end

// ===== output comparision ===== //
integer i;
integer err; 
initial begin
    srst_n = 1;
    enable = 0;
    round = 0;
    err = 0;
    @(negedge clk); srst_n = 1'b0;
    @(negedge clk); srst_n = 1'b1; enable = 1'b1;
    @(negedge clk); enable = 1'b0;

    wait(key_ready);
    for (i = 0; i <= 14; i = i + 1) begin        
        $display("\n");
        $display("================================================================");
        $display("======================== Round No. %03d ========================", i);
        $display("================================================================");

        round = i;

        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        $display("AES key golden: %0h\n", k_sch_golden[i]);
        $display("AES key output: %0h\n", k_sch_o);
        if (k_sch_golden[i] !== k_sch_o) err = err + 1;
    end
    
    $display("-----------------------------------------------------\n");
    $display("                      error: %02d                    \n", err);
    $display("-----------------------------------------------------\n");
    $finish;
end

endmodule