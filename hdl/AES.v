module AES #(
parameter KEY_BW = 256,
parameter WORD_BW = 128
)
(
    input clk,
    input srst_n,
	input enable,
    input mode,
    input [KEY_BW-1:0] key,
    input [WORD_BW-1:0] word,

    // output reg [WORD_BW-1:0] en_result,
	// output reg [WORD_BW-1:0] de_result,
    // output reg AES_de_done,
	// output reg AES_en_done

	output reg [WORD_BW-1:0] result,
	output reg done
);

//==================================================================================================
//     local parameter instantiation
//==================================================================================================
integer i;
localparam ENCRYPT = 1'b0, DECRYPT = 1'b1;

//==================================================================================================
//     reg instantiation
//==================================================================================================
reg [2:0] AES_state, AES_state_n;



//==================================================================================================
//     wire instantiation
//==================================================================================================

wire [127:0] wire_round_key;
wire wire_key_ready;

wire AES_de_done;
wire AES_en_done;
wire [127:0] en_word;
wire [127:0] de_word;

wire [3:0] encrypt_round;
wire [3:0] decrypt_round;
wire [3:0] key_round;
reg  [3:0] reg_key_round;

assign key_round = reg_key_round;

reg reg_de_enable;
reg reg_en_enable;
wire wire_de_enable;
wire wire_en_enable;

assign wire_de_enable = reg_de_enable;
assign wire_en_enable = reg_en_enable;

always @(*) begin
	if(mode == ENCRYPT) begin
		reg_en_enable =  wire_key_ready;
		reg_de_enable = 0;
		reg_key_round = encrypt_round;
	end

	else begin
		reg_de_enable = wire_key_ready;
		reg_en_enable = 0;
		reg_key_round = decrypt_round;
	end
end

always @(posedge clk) begin
	// en_result = en_word;
	// de_result = de_word;
	
	if(~srst_n) begin
		result <= 0;
		done <= 0;
	end

	else begin
		if(mode) begin
			result <= de_word;
			done <= AES_de_done;
		end

		else begin
			result <= en_word;
			done <= AES_en_done;
		end
	end
end





//==================================================================================================
//     module instantiation
//==================================================================================================

AES_encrypt U_AES_encrypt (
// input
.clk(clk),
.srst_n(srst_n),
.encrypt_en(wire_en_enable),
.round_key(wire_round_key),
.word(word),

// ouput
.encrypted_word(en_word),
.round(encrypt_round),
.AES_en_done(AES_en_done)
);

AES_decrypt U_AES_decrypt (
// input
.clk(clk),
.srst_n(srst_n),
.decrypt_en(wire_de_enable),
.round_key(wire_round_key),
.word(word),

// output
.decrypted_word(de_word),
.round(decrypt_round),
.AES_de_done(AES_de_done)
);


AES_key_ctr U_AES_key_ctr (
	.clk(clk),
	.srst_n(srst_n),
	.key_ctrl_en(enable),
	.key(key),
	.round(key_round),
	.mode(mode),

	.round_key(wire_round_key),
	.key_ready(wire_key_ready)
);

endmodule


