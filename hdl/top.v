module top #(
    parameter MAX_MLEN_BW = 14,  	 // adjustable maximum input message length (in byte)
	parameter MSG_SRAM_ADDR_BW = 11, // adjustable sram address bitwidth (= MAX_MLEN_BW - 3)
	// transmission
    parameter SRAM_DATA_BW = 8,
    parameter SRAM_ADDR_BW = 5,
    parameter SHA_DATA_BW = 256,
    parameter AES_TXT_BW = 128,
    parameter AES_KEY_BW = 256,
    // AES
    parameter KEY_BW = 256,
    parameter WORD_BW = 128
) (
	input clk,
	input srst_n,
	input enable,					// SRAM ready	
	input [63:0] msg_sram_data,		// message
	input [MAX_MLEN_BW-1:0] m_len,  // message length
	input mode,                     // EN/DE
    input [SRAM_DATA_BW-1:0] cph_sram_data,

	output [MSG_SRAM_ADDR_BW-1:0] msg_sram_addr,	// SRAM address for SHA2/3 message padding
    output [SRAM_ADDR_BW-1:0] cph_sram_addr,
	output valid,
    output verify,
    output [63:0] result
);

//==================================================================================================
//     wire instantiation
//==================================================================================================
// wire for padding output port
wire SHA2_load_en;						// for SHA2 control signal
wire SHA3_load_en;						// for SHA3 control signal
wire [64-1:0] P0_SHA2;					// for SHA2 input
wire [64-1:0] P1_SHA2;
wire [64-1:0] P2_SHA2;
wire [64-1:0] P3_SHA2;
wire [64-1:0] P4_SHA2;
wire [64-1:0] P5_SHA2;
wire [64-1:0] P6_SHA2;
wire [64-1:0] P7_SHA2;
wire [64-1:0] P0_SHA3;					// for SHA3 input
wire [64-1:0] P1_SHA3;
wire [64-1:0] P2_SHA3;
wire [64-1:0] P3_SHA3;
wire [64-1:0] P4_SHA3;
wire [64-1:0] P5_SHA3;
wire [64-1:0] P6_SHA3;
wire [64-1:0] P7_SHA3;
wire [64-1:0] P8_SHA3;
wire [64-1:0] P9_SHA3;
wire [64-1:0] P10_SHA3;
wire [64-1:0] P11_SHA3;
wire [64-1:0] P12_SHA3;
wire [64-1:0] P13_SHA3;
wire [64-1:0] P14_SHA3;
wire [64-1:0] P15_SHA3;
wire [64-1:0] P16_SHA3;
wire pad_SHA2_valid;
wire pad_SHA3_valid;

// wire for SHA2 module output port
wire SHA2_done;
wire [256-1:0] SHA2_OUT;

// wire for SHA3 module output port
wire SHA3_done;
wire [256-1:0] SHA3_OUT, SHA3_OUT_flip;
reg  [7:0] sha3_out1, sha3_out2, sha3_out3, sha3_out4, sha3_out5, sha3_out6, sha3_out7, sha3_out8;
reg  [7:0] sha3_out9, sha3_out10, sha3_out11, sha3_out12, sha3_out13, sha3_out14, sha3_out15, sha3_out16;
reg  [7:0] sha3_out17, sha3_out18, sha3_out19, sha3_out20, sha3_out21, sha3_out22, sha3_out23, sha3_out24;
reg  [7:0] sha3_out25, sha3_out26, sha3_out27, sha3_out28, sha3_out29, sha3_out30, sha3_out31, sha3_out32;

// wire for TRANS output port
wire [AES_TXT_BW-1:0] aes_txt_msb;
wire [AES_TXT_BW-1:0] aes_txt_lsb;
wire [AES_KEY_BW-1:0] aes_key;
wire aes_enable;

// wire for AES output port
wire [AES_TXT_BW-1:0] aes_msb_o;
wire [AES_TXT_BW-1:0] aes_lsb_o;
wire aes_msb_done;
wire aes_lsb_done;


//==================================================================================================
//     module instantiation
//==================================================================================================


padding U_padding (
	// input port
	.clk(clk),
	.srst_n(srst_n),
	.enable(enable),
	.data_in(msg_sram_data),
	.m_len(m_len),
	.sha2_done(SHA2_done),
	.sha3_done(SHA3_done),

	// output port
	.sha2_data({P0_SHA2, P1_SHA2, P2_SHA2, P3_SHA2, 
				P4_SHA2, P5_SHA2, P6_SHA2, P7_SHA2}),
	.sha3_data({P0_SHA3, P1_SHA3, P2_SHA3, P3_SHA3, 
				P4_SHA3, P5_SHA3, P6_SHA3, P7_SHA3,
				P8_SHA3, P9_SHA3, P10_SHA3, P11_SHA3, 
				P12_SHA3, P13_SHA3, P14_SHA3, P15_SHA3,
				P16_SHA3}),
	.sha2_load_valid(SHA2_load_en),
	.sha3_load_valid(SHA3_load_en),
	.sha2_valid(pad_SHA2_valid),
	.sha3_valid(pad_SHA3_valid),
	.sram_addr(msg_sram_addr)
);


SHA2 U_SHA2 (
	// input port
	.clk(clk),
	.srst_n(srst_n),
	.load_en(SHA2_load_en),
	.sha2_in({P0_SHA2, P1_SHA2, P2_SHA2, P3_SHA2, 
				P4_SHA2, P5_SHA2, P6_SHA2, P7_SHA2}),

	// output port
	.sha2_out(SHA2_OUT),
	.sha2_done(SHA2_done)
);


SHA3 U_SHA3 (
	// input port
	.clk(clk),
	.srst_n(srst_n),
	.SHA3_en(enable),
	.load_en(SHA3_load_en),
	.P0(P0_SHA3),
	.P1(P1_SHA3),
	.P2(P2_SHA3),
	.P3(P3_SHA3),
	.P4(P4_SHA3),
	.P5(P5_SHA3),
	.P6(P6_SHA3),
	.P7(P7_SHA3),
	.P8(P8_SHA3),
	.P9(P9_SHA3),
	.P10(P10_SHA3),
	.P11(P11_SHA3),
	.P12(P12_SHA3),
	.P13(P13_SHA3),
	.P14(P14_SHA3),
	.P15(P15_SHA3),
	.P16(P16_SHA3),

	// output port
	.SHA3_out(SHA3_OUT),
	.SHA3_done(SHA3_done)
);

transmission U_TRANS (
    // input port
    .clk(clk),
	.srst_n(srst_n),
	.enable(enable),
    .mode(mode),
    .cph_sram_data(cph_sram_data),
    .sha2_o(SHA2_OUT),
    .sha3_o(SHA3_OUT_flip),
    .sha2_done(pad_SHA2_valid),
    .sha3_done(pad_SHA3_valid),

    // output port
    .cph_sram_addr(cph_sram_addr),
    .aes_txt_msb(aes_txt_msb),
    .aes_txt_lsb(aes_txt_lsb),
    .aes_key(aes_key),
    .aes_enable(aes_enable)
);

AES U_AES_MSB (
	// input port
	.clk(clk),
	.srst_n(srst_n),
	.enable(aes_enable),
	.mode(mode),
	.key(aes_key),
	.word(aes_txt_msb),

	// output port
	.result(aes_msb_o),
	.done(aes_msb_done)
);

AES U_AES_LSB (
    // input port
	.clk(clk),
	.srst_n(srst_n),
	.enable(aes_enable),
	.mode(mode),
	.key(aes_key),
	.word(aes_txt_lsb),

	// output port
	.result(aes_lsb_o),
	.done(aes_lsb_done)
);

verification U_VERIFY (
    // input port
    .clk(clk),
	.srst_n(srst_n),
    .mode(mode),
    .aes_msb_o(aes_msb_o),
    .aes_lsb_o(aes_lsb_o),
    .sha3_o(SHA3_OUT_flip),
    .aes_msb_done(aes_msb_done),
    .aes_lsb_done(aes_lsb_done),
    .sha3_done(pad_SHA3_valid),

    // output port
    .cipher_o(result),
    .verify(verify),
    .valid(valid)
);


//==================================================================================================
//     combinational circuit
//==================================================================================================
integer i;
assign SHA3_OUT_flip = {sha3_out1, sha3_out2, sha3_out3, sha3_out4, sha3_out5, sha3_out6, sha3_out7, sha3_out8,
                        sha3_out9, sha3_out10, sha3_out11, sha3_out12, sha3_out13, sha3_out14, sha3_out15, sha3_out16,
                        sha3_out17, sha3_out18, sha3_out19, sha3_out20, sha3_out21, sha3_out22, sha3_out23, sha3_out24,
                        sha3_out25, sha3_out26, sha3_out27, sha3_out28, sha3_out29, sha3_out30, sha3_out31, sha3_out32};

// sha3 output flip every byte
always @(*) begin
  for (i=0; i<8; i=i+1) begin
	sha3_out1[7-i] = SHA3_OUT[248+i];
	sha3_out2[7-i] = SHA3_OUT[240+i];
	sha3_out3[7-i] = SHA3_OUT[232+i];
	sha3_out4[7-i] = SHA3_OUT[224+i];
	sha3_out5[7-i] = SHA3_OUT[216+i];
	sha3_out6[7-i] = SHA3_OUT[208+i];
	sha3_out7[7-i] = SHA3_OUT[200+i];
	sha3_out8[7-i] = SHA3_OUT[192+i];
    sha3_out9[7-i] = SHA3_OUT[184+i];
	sha3_out10[7-i] = SHA3_OUT[176+i];
	sha3_out11[7-i] = SHA3_OUT[168+i];
	sha3_out12[7-i] = SHA3_OUT[160+i];
	sha3_out13[7-i] = SHA3_OUT[152+i];
	sha3_out14[7-i] = SHA3_OUT[144+i];
	sha3_out15[7-i] = SHA3_OUT[136+i];
	sha3_out16[7-i] = SHA3_OUT[128+i];
    sha3_out17[7-i] = SHA3_OUT[120+i];
	sha3_out18[7-i] = SHA3_OUT[112+i];
	sha3_out19[7-i] = SHA3_OUT[104+i];
	sha3_out20[7-i] = SHA3_OUT[96+i];
	sha3_out21[7-i] = SHA3_OUT[88+i];
	sha3_out22[7-i] = SHA3_OUT[80+i];
	sha3_out23[7-i] = SHA3_OUT[72+i];
	sha3_out24[7-i] = SHA3_OUT[64+i];
    sha3_out25[7-i] = SHA3_OUT[56+i];
	sha3_out26[7-i] = SHA3_OUT[48+i];
	sha3_out27[7-i] = SHA3_OUT[40+i];
	sha3_out28[7-i] = SHA3_OUT[32+i];
	sha3_out29[7-i] = SHA3_OUT[24+i];
	sha3_out30[7-i] = SHA3_OUT[16+i];
	sha3_out31[7-i] = SHA3_OUT[8+i];
	sha3_out32[7-i] = SHA3_OUT[i];
  end
end

endmodule