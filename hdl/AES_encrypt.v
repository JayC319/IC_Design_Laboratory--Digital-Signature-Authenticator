module AES_encrypt(
input clk,
input srst_n,
input encrypt_en,
input [127:0] round_key,
input [127:0] word,

output reg [127:0] encrypted_word,
output reg [3:0] round,
output reg AES_en_done

);
//==================================================================================================
//     local parameter instantiation
//==================================================================================================
localparam IDLE = 3'b000, INIT = 3'b001, SUBBYTES = 3'b010, SHIFTROW = 3'b011, 
MIXCOLUMNS = 3'b100, ADDROUNDKEY = 3'b101, ENDROUNDKEY = 3'b110, DONE = 3'b111;

//==================================================================================================
//     reg instantiation
//==================================================================================================
reg [3:0]  round_n;
reg AES_en_done_n;
reg [2:0]  state, state_n;

// reg for roundkey
reg [127:0] state_rnd_key;
reg [127:0] state_rnd_key_n;

// reg for subbytes
reg [127:0] state_subbytes_n;
reg [127:0] state_subbytes;

// reg for shiftrows
reg [127:0] state_shiftrows_n;
reg [127:0] state_shiftrows;

reg [31:0] col0_sr, col1_sr, col2_sr, col3_sr;

// reg for mixcol
reg [127:0] state_mixcol_n;
reg [127:0] state_mixcol;


reg [7:0] col0_0, col0_1, col0_2, col0_3,
          col1_0, col1_1, col1_2, col1_3,
          col2_0, col2_1, col2_2, col2_3,
          col3_0, col3_1, col3_2, col3_3;

reg [7:0] col0_0_mix, col0_1_mix, col0_2_mix, col0_3_mix,
          col1_0_mix, col1_1_mix, col1_2_mix, col1_3_mix,
          col2_0_mix, col2_1_mix, col2_2_mix, col2_3_mix,
          col3_0_mix, col3_1_mix, col3_2_mix, col3_3_mix;


//==================================================================================================
//     wire instantiation
//==================================================================================================
always @(*) begin
	encrypted_word = state_rnd_key;
end

//==================================================================================================
//     hardwire SBOX
//==================================================================================================
  wire [7:0] sbox [0:255];
  assign sbox[8'h00] = 8'h63;
  assign sbox[8'h01] = 8'h7c;
  assign sbox[8'h02] = 8'h77;
  assign sbox[8'h03] = 8'h7b;
  assign sbox[8'h04] = 8'hf2;
  assign sbox[8'h05] = 8'h6b;
  assign sbox[8'h06] = 8'h6f;
  assign sbox[8'h07] = 8'hc5;
  assign sbox[8'h08] = 8'h30;
  assign sbox[8'h09] = 8'h01;
  assign sbox[8'h0a] = 8'h67;
  assign sbox[8'h0b] = 8'h2b;
  assign sbox[8'h0c] = 8'hfe;
  assign sbox[8'h0d] = 8'hd7;
  assign sbox[8'h0e] = 8'hab;
  assign sbox[8'h0f] = 8'h76;
  assign sbox[8'h10] = 8'hca;
  assign sbox[8'h11] = 8'h82;
  assign sbox[8'h12] = 8'hc9;
  assign sbox[8'h13] = 8'h7d;
  assign sbox[8'h14] = 8'hfa;
  assign sbox[8'h15] = 8'h59;
  assign sbox[8'h16] = 8'h47;
  assign sbox[8'h17] = 8'hf0;
  assign sbox[8'h18] = 8'had;
  assign sbox[8'h19] = 8'hd4;
  assign sbox[8'h1a] = 8'ha2;
  assign sbox[8'h1b] = 8'haf;
  assign sbox[8'h1c] = 8'h9c;
  assign sbox[8'h1d] = 8'ha4;
  assign sbox[8'h1e] = 8'h72;
  assign sbox[8'h1f] = 8'hc0;
  assign sbox[8'h20] = 8'hb7;
  assign sbox[8'h21] = 8'hfd;
  assign sbox[8'h22] = 8'h93;
  assign sbox[8'h23] = 8'h26;
  assign sbox[8'h24] = 8'h36;
  assign sbox[8'h25] = 8'h3f;
  assign sbox[8'h26] = 8'hf7;
  assign sbox[8'h27] = 8'hcc;
  assign sbox[8'h28] = 8'h34;
  assign sbox[8'h29] = 8'ha5;
  assign sbox[8'h2a] = 8'he5;
  assign sbox[8'h2b] = 8'hf1;
  assign sbox[8'h2c] = 8'h71;
  assign sbox[8'h2d] = 8'hd8;
  assign sbox[8'h2e] = 8'h31;
  assign sbox[8'h2f] = 8'h15;
  assign sbox[8'h30] = 8'h04;
  assign sbox[8'h31] = 8'hc7;
  assign sbox[8'h32] = 8'h23;
  assign sbox[8'h33] = 8'hc3;
  assign sbox[8'h34] = 8'h18;
  assign sbox[8'h35] = 8'h96;
  assign sbox[8'h36] = 8'h05;
  assign sbox[8'h37] = 8'h9a;
  assign sbox[8'h38] = 8'h07;
  assign sbox[8'h39] = 8'h12;
  assign sbox[8'h3a] = 8'h80;
  assign sbox[8'h3b] = 8'he2;
  assign sbox[8'h3c] = 8'heb;
  assign sbox[8'h3d] = 8'h27;
  assign sbox[8'h3e] = 8'hb2;
  assign sbox[8'h3f] = 8'h75;
  assign sbox[8'h40] = 8'h09;
  assign sbox[8'h41] = 8'h83;
  assign sbox[8'h42] = 8'h2c;
  assign sbox[8'h43] = 8'h1a;
  assign sbox[8'h44] = 8'h1b;
  assign sbox[8'h45] = 8'h6e;
  assign sbox[8'h46] = 8'h5a;
  assign sbox[8'h47] = 8'ha0;
  assign sbox[8'h48] = 8'h52;
  assign sbox[8'h49] = 8'h3b;
  assign sbox[8'h4a] = 8'hd6;
  assign sbox[8'h4b] = 8'hb3;
  assign sbox[8'h4c] = 8'h29;
  assign sbox[8'h4d] = 8'he3;
  assign sbox[8'h4e] = 8'h2f;
  assign sbox[8'h4f] = 8'h84;
  assign sbox[8'h50] = 8'h53;
  assign sbox[8'h51] = 8'hd1;
  assign sbox[8'h52] = 8'h00;
  assign sbox[8'h53] = 8'hed;
  assign sbox[8'h54] = 8'h20;
  assign sbox[8'h55] = 8'hfc;
  assign sbox[8'h56] = 8'hb1;
  assign sbox[8'h57] = 8'h5b;
  assign sbox[8'h58] = 8'h6a;
  assign sbox[8'h59] = 8'hcb;
  assign sbox[8'h5a] = 8'hbe;
  assign sbox[8'h5b] = 8'h39;
  assign sbox[8'h5c] = 8'h4a;
  assign sbox[8'h5d] = 8'h4c;
  assign sbox[8'h5e] = 8'h58;
  assign sbox[8'h5f] = 8'hcf;
  assign sbox[8'h60] = 8'hd0;
  assign sbox[8'h61] = 8'hef;
  assign sbox[8'h62] = 8'haa;
  assign sbox[8'h63] = 8'hfb;
  assign sbox[8'h64] = 8'h43;
  assign sbox[8'h65] = 8'h4d;
  assign sbox[8'h66] = 8'h33;
  assign sbox[8'h67] = 8'h85;
  assign sbox[8'h68] = 8'h45;
  assign sbox[8'h69] = 8'hf9;
  assign sbox[8'h6a] = 8'h02;
  assign sbox[8'h6b] = 8'h7f;
  assign sbox[8'h6c] = 8'h50;
  assign sbox[8'h6d] = 8'h3c;
  assign sbox[8'h6e] = 8'h9f;
  assign sbox[8'h6f] = 8'ha8;
  assign sbox[8'h70] = 8'h51;
  assign sbox[8'h71] = 8'ha3;
  assign sbox[8'h72] = 8'h40;
  assign sbox[8'h73] = 8'h8f;
  assign sbox[8'h74] = 8'h92;
  assign sbox[8'h75] = 8'h9d;
  assign sbox[8'h76] = 8'h38;
  assign sbox[8'h77] = 8'hf5;
  assign sbox[8'h78] = 8'hbc;
  assign sbox[8'h79] = 8'hb6;
  assign sbox[8'h7a] = 8'hda;
  assign sbox[8'h7b] = 8'h21;
  assign sbox[8'h7c] = 8'h10;
  assign sbox[8'h7d] = 8'hff;
  assign sbox[8'h7e] = 8'hf3;
  assign sbox[8'h7f] = 8'hd2;
  assign sbox[8'h80] = 8'hcd;
  assign sbox[8'h81] = 8'h0c;
  assign sbox[8'h82] = 8'h13;
  assign sbox[8'h83] = 8'hec;
  assign sbox[8'h84] = 8'h5f;
  assign sbox[8'h85] = 8'h97;
  assign sbox[8'h86] = 8'h44;
  assign sbox[8'h87] = 8'h17;
  assign sbox[8'h88] = 8'hc4;
  assign sbox[8'h89] = 8'ha7;
  assign sbox[8'h8a] = 8'h7e;
  assign sbox[8'h8b] = 8'h3d;
  assign sbox[8'h8c] = 8'h64;
  assign sbox[8'h8d] = 8'h5d;
  assign sbox[8'h8e] = 8'h19;
  assign sbox[8'h8f] = 8'h73;
  assign sbox[8'h90] = 8'h60;
  assign sbox[8'h91] = 8'h81;
  assign sbox[8'h92] = 8'h4f;
  assign sbox[8'h93] = 8'hdc;
  assign sbox[8'h94] = 8'h22;
  assign sbox[8'h95] = 8'h2a;
  assign sbox[8'h96] = 8'h90;
  assign sbox[8'h97] = 8'h88;
  assign sbox[8'h98] = 8'h46;
  assign sbox[8'h99] = 8'hee;
  assign sbox[8'h9a] = 8'hb8;
  assign sbox[8'h9b] = 8'h14;
  assign sbox[8'h9c] = 8'hde;
  assign sbox[8'h9d] = 8'h5e;
  assign sbox[8'h9e] = 8'h0b;
  assign sbox[8'h9f] = 8'hdb;
  assign sbox[8'ha0] = 8'he0;
  assign sbox[8'ha1] = 8'h32;
  assign sbox[8'ha2] = 8'h3a;
  assign sbox[8'ha3] = 8'h0a;
  assign sbox[8'ha4] = 8'h49;
  assign sbox[8'ha5] = 8'h06;
  assign sbox[8'ha6] = 8'h24;
  assign sbox[8'ha7] = 8'h5c;
  assign sbox[8'ha8] = 8'hc2;
  assign sbox[8'ha9] = 8'hd3;
  assign sbox[8'haa] = 8'hac;
  assign sbox[8'hab] = 8'h62;
  assign sbox[8'hac] = 8'h91;
  assign sbox[8'had] = 8'h95;
  assign sbox[8'hae] = 8'he4;
  assign sbox[8'haf] = 8'h79;
  assign sbox[8'hb0] = 8'he7;
  assign sbox[8'hb1] = 8'hc8;
  assign sbox[8'hb2] = 8'h37;
  assign sbox[8'hb3] = 8'h6d;
  assign sbox[8'hb4] = 8'h8d;
  assign sbox[8'hb5] = 8'hd5;
  assign sbox[8'hb6] = 8'h4e;
  assign sbox[8'hb7] = 8'ha9;
  assign sbox[8'hb8] = 8'h6c;
  assign sbox[8'hb9] = 8'h56;
  assign sbox[8'hba] = 8'hf4;
  assign sbox[8'hbb] = 8'hea;
  assign sbox[8'hbc] = 8'h65;
  assign sbox[8'hbd] = 8'h7a;
  assign sbox[8'hbe] = 8'hae;
  assign sbox[8'hbf] = 8'h08;
  assign sbox[8'hc0] = 8'hba;
  assign sbox[8'hc1] = 8'h78;
  assign sbox[8'hc2] = 8'h25;
  assign sbox[8'hc3] = 8'h2e;
  assign sbox[8'hc4] = 8'h1c;
  assign sbox[8'hc5] = 8'ha6;
  assign sbox[8'hc6] = 8'hb4;
  assign sbox[8'hc7] = 8'hc6;
  assign sbox[8'hc8] = 8'he8;
  assign sbox[8'hc9] = 8'hdd;
  assign sbox[8'hca] = 8'h74;
  assign sbox[8'hcb] = 8'h1f;
  assign sbox[8'hcc] = 8'h4b;
  assign sbox[8'hcd] = 8'hbd;
  assign sbox[8'hce] = 8'h8b;
  assign sbox[8'hcf] = 8'h8a;
  assign sbox[8'hd0] = 8'h70;
  assign sbox[8'hd1] = 8'h3e;
  assign sbox[8'hd2] = 8'hb5;
  assign sbox[8'hd3] = 8'h66;
  assign sbox[8'hd4] = 8'h48;
  assign sbox[8'hd5] = 8'h03;
  assign sbox[8'hd6] = 8'hf6;
  assign sbox[8'hd7] = 8'h0e;
  assign sbox[8'hd8] = 8'h61;
  assign sbox[8'hd9] = 8'h35;
  assign sbox[8'hda] = 8'h57;
  assign sbox[8'hdb] = 8'hb9;
  assign sbox[8'hdc] = 8'h86;
  assign sbox[8'hdd] = 8'hc1;
  assign sbox[8'hde] = 8'h1d;
  assign sbox[8'hdf] = 8'h9e;
  assign sbox[8'he0] = 8'he1;
  assign sbox[8'he1] = 8'hf8;
  assign sbox[8'he2] = 8'h98;
  assign sbox[8'he3] = 8'h11;
  assign sbox[8'he4] = 8'h69;
  assign sbox[8'he5] = 8'hd9;
  assign sbox[8'he6] = 8'h8e;
  assign sbox[8'he7] = 8'h94;
  assign sbox[8'he8] = 8'h9b;
  assign sbox[8'he9] = 8'h1e;
  assign sbox[8'hea] = 8'h87;
  assign sbox[8'heb] = 8'he9;
  assign sbox[8'hec] = 8'hce;
  assign sbox[8'hed] = 8'h55;
  assign sbox[8'hee] = 8'h28;
  assign sbox[8'hef] = 8'hdf;
  assign sbox[8'hf0] = 8'h8c;
  assign sbox[8'hf1] = 8'ha1;
  assign sbox[8'hf2] = 8'h89;
  assign sbox[8'hf3] = 8'h0d;
  assign sbox[8'hf4] = 8'hbf;
  assign sbox[8'hf5] = 8'he6;
  assign sbox[8'hf6] = 8'h42;
  assign sbox[8'hf7] = 8'h68;
  assign sbox[8'hf8] = 8'h41;
  assign sbox[8'hf9] = 8'h99;
  assign sbox[8'hfa] = 8'h2d;
  assign sbox[8'hfb] = 8'h0f;
  assign sbox[8'hfc] = 8'hb0;
  assign sbox[8'hfd] = 8'h54;
  assign sbox[8'hfe] = 8'hbb;
  assign sbox[8'hff] = 8'h16;






//==================================================================================================
//     sequential circuit 
//==================================================================================================
always @(posedge clk) begin
	if(~srst_n) begin
		state <= IDLE;
		round <= 0;
		AES_en_done <= 0;
	end

	else begin
		state <= state_n;
		round <= round_n;
		AES_en_done <= AES_en_done_n;
    state_rnd_key <= state_rnd_key_n;
    state_subbytes <= state_subbytes_n;
    state_shiftrows <= state_shiftrows_n;
    state_mixcol <= state_mixcol_n;
	end
end

//==================================================================================================
//     finite state machine
//==================================================================================================
always @(*) begin
	round_n = round;
	AES_en_done_n = 0;
	case(state)
		IDLE: begin
			if(encrypt_en) begin
				state_n = INIT;
			end

			else begin
				state_n = IDLE;
			end
		end

		INIT: begin
			state_n = SUBBYTES;
		end

		SUBBYTES: begin
			state_n = SHIFTROW;
			round_n = round + 1;
		end

		SHIFTROW: begin
			if(round == 14) begin
				state_n = ENDROUNDKEY;
			end
			else begin
				state_n = MIXCOLUMNS;
			end
		end

		MIXCOLUMNS: begin
			state_n = ADDROUNDKEY;
		end

		ADDROUNDKEY: begin
			state_n = SUBBYTES;
		end

		ENDROUNDKEY: begin
			state_n = DONE;
			AES_en_done_n = 1;
		end

    DONE: begin
      state_n = DONE;
    end


		default: begin
			state_n = IDLE;
		end
	endcase
end


//==================================================================================================
//     combinational circuit
//==================================================================================================

// Add Roundkey
always @(*) begin
	if(state == INIT) begin
		state_rnd_key_n = word ^ round_key;
	end

  else if(state == ADDROUNDKEY) begin
    state_rnd_key_n = state_mixcol ^ round_key;
  end

  else if (state == ENDROUNDKEY) begin
    state_rnd_key_n = state_shiftrows ^ round_key;
  end

	else begin
		state_rnd_key_n = state_rnd_key;
	end
end


// subbytes
always @(*) begin
	state_subbytes_n[7:0]   = sbox[state_rnd_key[7:0]  ];
	state_subbytes_n[15:8]  = sbox[state_rnd_key[15:8] ]; 
	state_subbytes_n[23:16] = sbox[state_rnd_key[23:16]]; 
	state_subbytes_n[31:24] = sbox[state_rnd_key[31:24]]; 

	state_subbytes_n[39:32] = sbox[state_rnd_key[39:32]]; 
	state_subbytes_n[47:40] = sbox[state_rnd_key[47:40]]; 
	state_subbytes_n[55:48] = sbox[state_rnd_key[55:48]]; 
	state_subbytes_n[63:56] = sbox[state_rnd_key[63:56]]; 

	state_subbytes_n[71:64] = sbox[state_rnd_key[71:64]]; 
	state_subbytes_n[79:72] = sbox[state_rnd_key[79:72]]; 
	state_subbytes_n[87:80] = sbox[state_rnd_key[87:80]]; 
	state_subbytes_n[95:88] = sbox[state_rnd_key[95:88]]; 

	state_subbytes_n[103:96] 	= sbox[state_rnd_key[103:96] ]; 
	state_subbytes_n[111:104] = sbox[state_rnd_key[111:104]]; 
	state_subbytes_n[119:112] = sbox[state_rnd_key[119:112]]; 
	state_subbytes_n[127:120] = sbox[state_rnd_key[127:120]]; 

end

//shiftrows
always @(*) begin

	col0_sr = state_subbytes[127:96];
	col1_sr = state_subbytes[95:64];
	col2_sr = state_subbytes[63:32];
	col3_sr = state_subbytes[31:0];

	state_shiftrows_n[127:96]  = {col0_sr[31:24], col1_sr[23:16], col2_sr[15:8], col3_sr[7:0]};
	state_shiftrows_n[95:64]   = {col1_sr[31:24], col2_sr[23:16], col3_sr[15:8], col0_sr[7:0]};
	state_shiftrows_n[63:32]   = {col2_sr[31:24], col3_sr[23:16], col0_sr[15:8], col1_sr[7:0]};
	state_shiftrows_n[31:0]    = {col3_sr[31:24], col0_sr[23:16], col1_sr[15:8], col2_sr[7:0]};

end

// mix columns 
always @(*) begin


  col3_3= state_shiftrows[7:0];  
  col3_2= state_shiftrows[15:8];  
  col3_1= state_shiftrows[23:16]; 
  col3_0= state_shiftrows[31:24];
  col2_3= state_shiftrows[39:32];
  col2_2= state_shiftrows[47:40]; 
  col2_1= state_shiftrows[55:48]; 
  col2_0= state_shiftrows[63:56]; 
  col1_3= state_shiftrows[71:64]; 
  col1_2= state_shiftrows[79:72]; 
  col1_1= state_shiftrows[87:80]; 
  col1_0= state_shiftrows[95:88]; 
  col0_3= state_shiftrows[103:96]; 
  col0_2= state_shiftrows[111:104];
  col0_1= state_shiftrows[119:112];
  col0_0= state_shiftrows[127:120];




  col0_0_mix = {col0_0[6:0], 1'b0} ^ (8'h1b & {8{col0_0[7]}}) ^ ({col0_1[6:0], 1'b0} ^ (8'h1b & {8{col0_1[7]}}) ^ col0_1) ^ col0_2 ^ col0_3;
  col0_1_mix = col0_0 ^ {col0_1[6:0], 1'b0} ^ (8'h1b & {8{col0_1[7]}}) ^ ({col0_2[6:0], 1'b0} ^ (8'h1b & {8{col0_2[7]}}) ^ col0_2) ^ col0_3;
  col0_2_mix = col0_0 ^ col0_1 ^ {col0_2[6:0], 1'b0} ^ (8'h1b & {8{col0_2[7]}}) ^ ({col0_3[6:0], 1'b0} ^ (8'h1b & {8{col0_3[7]}}) ^ col0_3);
  col0_3_mix = ({col0_0[6:0], 1'b0} ^ (8'h1b & {8{col0_0[7]}}) ^ col0_0) ^ col0_1 ^ col0_2 ^ {col0_3[6:0], 1'b0} ^ (8'h1b & {8{col0_3[7]}});

  col1_0_mix = {col1_0[6:0], 1'b0} ^ (8'h1b & {8{col1_0[7]}}) ^ ({col1_1[6:0], 1'b0} ^ (8'h1b & {8{col1_1[7]}}) ^ col1_1) ^ col1_2 ^ col1_3;
  col1_1_mix = col1_0 ^ {col1_1[6:0], 1'b0} ^ (8'h1b & {8{col1_1[7]}}) ^ ({col1_2[6:0], 1'b0} ^ (8'h1b & {8{col1_2[7]}}) ^ col1_2) ^ col1_3;
  col1_2_mix = col1_0 ^ col1_1 ^ {col1_2[6:0], 1'b0} ^ (8'h1b & {8{col1_2[7]}}) ^ ({col1_3[6:0], 1'b0} ^ (8'h1b & {8{col1_3[7]}}) ^ col1_3);
  col1_3_mix = ({col1_0[6:0], 1'b0} ^ (8'h1b & {8{col1_0[7]}}) ^ col1_0) ^ col1_1 ^ col1_2 ^ {col1_3[6:0], 1'b0} ^ (8'h1b & {8{col1_3[7]}});

  col2_0_mix = {col2_0[6:0], 1'b0} ^ (8'h1b & {8{col2_0[7]}}) ^ ({col2_1[6:0], 1'b0} ^ (8'h1b & {8{col2_1[7]}}) ^ col2_1) ^ col2_2 ^ col2_3;
  col2_1_mix = col2_0 ^ {col2_1[6:0], 1'b0} ^ (8'h1b & {8{col2_1[7]}}) ^ ({col2_2[6:0], 1'b0} ^ (8'h1b & {8{col2_2[7]}}) ^ col2_2) ^ col2_3;
  col2_2_mix = col2_0 ^ col2_1 ^ {col2_2[6:0], 1'b0} ^ (8'h1b & {8{col2_2[7]}}) ^ ({col2_3[6:0], 1'b0} ^ (8'h1b & {8{col2_3[7]}}) ^ col2_3);
  col2_3_mix = ({col2_0[6:0], 1'b0} ^ (8'h1b & {8{col2_0[7]}}) ^ col2_0) ^ col2_1 ^ col2_2 ^ {col2_3[6:0], 1'b0} ^ (8'h1b & {8{col2_3[7]}});

  col3_0_mix = {col3_0[6:0], 1'b0} ^ (8'h1b & {8{col3_0[7]}}) ^ ({col3_1[6:0], 1'b0} ^ (8'h1b & {8{col3_1[7]}}) ^ col3_1) ^ col3_2 ^ col3_3;
  col3_1_mix = col3_0 ^ {col3_1[6:0], 1'b0} ^ (8'h1b & {8{col3_1[7]}}) ^ ({col3_2[6:0], 1'b0} ^ (8'h1b & {8{col3_2[7]}}) ^ col3_2) ^ col3_3;
  col3_2_mix = col3_0 ^ col3_1 ^ {col3_2[6:0], 1'b0} ^ (8'h1b & {8{col3_2[7]}}) ^ ({col3_3[6:0], 1'b0} ^ (8'h1b & {8{col3_3[7]}}) ^ col3_3);
  col3_3_mix = ({col3_0[6:0], 1'b0} ^ (8'h1b & {8{col3_0[7]}}) ^ col3_0) ^ col3_1 ^ col3_2 ^ {col3_3[6:0], 1'b0} ^ (8'h1b & {8{col3_3[7]}});

  
  state_mixcol_n[127:96]  = {col0_0_mix, col0_1_mix, col0_2_mix, col0_3_mix};
	state_mixcol_n[95:64]   = {col1_0_mix, col1_1_mix, col1_2_mix, col1_3_mix};
	state_mixcol_n[63:32]   = {col2_0_mix, col2_1_mix, col2_2_mix, col2_3_mix};
	state_mixcol_n[31:0]    = {col3_0_mix, col3_1_mix, col3_2_mix, col3_3_mix};

end



endmodule



