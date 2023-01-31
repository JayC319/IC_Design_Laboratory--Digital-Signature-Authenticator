module padding #(
	parameter MAX_MLEN_BW = 14, // adjustable maximum input message length (in byte)
	parameter SRAM_ADDR_BW = 11 // adjustable sram address bitwidth (= MAX_MLEN_BW - 3)
) (
    input clk,
    input srst_n,             
    input enable,         			// SRAM ready                
    input [63:0] data_in,			// SRAM data
	input [MAX_MLEN_BW-1:0] m_len, 	// length of the text(in byte)
	input sha2_done,				// sha2 one block done(512 bits)
	input sha3_done,				// sha3 one block done(1088 bits)

    output reg [511:0] sha2_data,	// padded data
	output reg [1087:0] sha3_data,	// padded data
	output reg sha2_load_valid,		// sha2 data ready
	output reg sha3_load_valid,		// sha3 data ready
	output reg sha2_valid,			// sha2 one pattern finish
	output reg sha3_valid,			// sha3 one pattern finish
	output reg [SRAM_ADDR_BW-1:0] sram_addr		// address to sram
);

parameter IDLE = 3'b000, SHA2_FIRST_ROUND = 3'b001, CHECK_SHA3_BUSY = 3'b010, SHA2_PREPARE_NEXT = 3'b011;
parameter SHA2_WAIT_DONE = 3'b100, SHA2_FINAL_ROUND = 3'b101;

parameter SHA3_FIRST_ROUND = 3'b001, CHECK_SHA2_BUSY = 3'b010, SHA3_PREPARE_NEXT = 3'b011;
parameter SHA3_WAIT_DONE = 3'b100, SHA3_FINAL_ROUND = 3'b101;

parameter SHA2_CASE1 = 2'b00, SHA2_CASE2 = 2'b01, SHA2_CASE3 = 2'b10, SHA2_CASE4 = 2'b11;
parameter SHA3_CASE1 = 2'b00, SHA3_CASE2 = 2'b01, SHA3_CASE3 = 2'b10;

reg [2:0] pad_state_sha2, pad_state_sha2_n;
reg [2:0] pad_state_sha3, pad_state_sha3_n;
reg [2:0] sha2_cnt, sha2_cnt_n;
reg [4:0] sha3_cnt, sha3_cnt_n;
reg [MAX_MLEN_BW-1:0] sha2_remain_len, sha2_remain_len_n, sha3_remain_len, sha3_remain_len_n; // in byte
reg [MAX_MLEN_BW-1:0] sha2_remain_len_block, sha2_remain_len_block_n, sha3_remain_len_block, sha3_remain_len_block_n; // in byte
reg sha2_busy, sha3_busy, sha2_busy_n, sha3_busy_n;
reg sha2_final_rnd, sha3_final_rnd, sha2_final_rnd_n, sha3_final_rnd_n;
reg [SRAM_ADDR_BW-1:0] sha2_addr, sha3_addr, sha2_addr_pre, sha3_addr_pre;
reg [511:0] sha2_data_n, sha2_tmp_data;
reg [1087:0] sha3_data_n, sha3_tmp_data;
reg sha2_load_valid_n, sha3_load_valid_n;
reg sha2_valid_n, sha3_valid_n;
reg [1:0] sha2_case, sha2_case_n, sha3_case, sha3_case_n;
reg sha2_valid_delay, sha2_valid_delay_n, sha3_valid_delay, sha3_valid_delay_n;

wire [7:0] sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8;
reg  [7:0] sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8;

assign {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8} = data_in;


integer i;

// sha3 input flip every byte
always @(*) begin
  for (i=0; i<8; i=i+1) begin
	sha3_text1[7-i] = data_in[56+i];
	sha3_text2[7-i] = data_in[48+i];
	sha3_text3[7-i] = data_in[40+i];
	sha3_text4[7-i] = data_in[32+i];
	sha3_text5[7-i] = data_in[24+i];
	sha3_text6[7-i] = data_in[16+i];
	sha3_text7[7-i] = data_in[8+i];
	sha3_text8[7-i] = data_in[i];
  end
end

// FSM for SHA2
always @(*) begin
  case(pad_state_sha2)
	IDLE: begin
	  if (enable) pad_state_sha2_n = SHA2_FIRST_ROUND;
	  else pad_state_sha2_n = IDLE;
	end
	SHA2_FIRST_ROUND: begin
	  if (sha2_cnt == 7) begin
		if (m_len < 56) pad_state_sha2_n = SHA2_FINAL_ROUND;
		else pad_state_sha2_n = CHECK_SHA3_BUSY;
	  end
	  else pad_state_sha2_n = SHA2_FIRST_ROUND;
	end
	CHECK_SHA3_BUSY: begin
	  if (~sha3_busy) pad_state_sha2_n = SHA2_PREPARE_NEXT;
	  else pad_state_sha2_n = CHECK_SHA3_BUSY;
	end
	SHA2_PREPARE_NEXT: begin
	  if (sha2_cnt == 7) pad_state_sha2_n = SHA2_WAIT_DONE;
	  else pad_state_sha2_n = SHA2_PREPARE_NEXT;
	end
	SHA2_WAIT_DONE: begin
	  if (sha2_final_rnd) pad_state_sha2_n = SHA2_FINAL_ROUND;
	  else if (sha2_done) pad_state_sha2_n = CHECK_SHA3_BUSY;
	  else pad_state_sha2_n = SHA2_WAIT_DONE;
	end
	SHA2_FINAL_ROUND: begin
	  pad_state_sha2_n = SHA2_FINAL_ROUND;
	end
	default: begin
	  pad_state_sha2_n = IDLE;
	end
  endcase
end

// FSM for SHA3
always @(*) begin
  case(pad_state_sha3)
	IDLE: begin
	  if (enable) pad_state_sha3_n = SHA3_FIRST_ROUND;
	  else pad_state_sha3_n = IDLE;
	end
	SHA3_FIRST_ROUND: begin
	  if (sha3_cnt == 16) begin
		if (m_len < 136) pad_state_sha3_n = SHA3_FINAL_ROUND;
		else pad_state_sha3_n = CHECK_SHA2_BUSY;
	  end
	  else pad_state_sha3_n = SHA3_FIRST_ROUND;
	end
	CHECK_SHA2_BUSY: begin
	  if (~sha2_busy) pad_state_sha3_n = SHA3_PREPARE_NEXT;
	  else pad_state_sha3_n = CHECK_SHA2_BUSY;
	end
	SHA3_PREPARE_NEXT: begin
	  if (sha3_cnt == 16) pad_state_sha3_n = SHA3_WAIT_DONE;
	  else pad_state_sha3_n = SHA3_PREPARE_NEXT;
	end
	SHA3_WAIT_DONE: begin
	  if (sha3_final_rnd) pad_state_sha3_n = SHA3_FINAL_ROUND;
	  else if (sha3_done) pad_state_sha3_n = CHECK_SHA2_BUSY;
	  else pad_state_sha3_n = SHA3_WAIT_DONE;
	end
	SHA3_FINAL_ROUND: begin
	  pad_state_sha3_n = SHA3_FINAL_ROUND;
	end
	default: begin
	  pad_state_sha3_n = IDLE;
	end
  endcase
end

// Data remaining length calculation
// Final round check
always @(*) begin
  // SHA2
  sha2_remain_len_block_n = sha2_remain_len_block;
  sha2_final_rnd_n = sha2_final_rnd;
  sha2_case_n = sha2_case;
  if (enable) begin
	if (m_len < 56) begin
	  sha2_case_n = SHA2_CASE1;
      sha2_remain_len_block_n = m_len;
    end
	else if (m_len >= 56 && m_len < 64) begin
      sha2_case_n = SHA2_CASE2;
      sha2_remain_len_block_n = m_len;
    end
	else if (m_len == 64) begin
      sha2_case_n = SHA2_CASE3;
      sha2_remain_len_block_n = m_len;
    end
	else begin
	  sha2_case_n = SHA2_CASE4;
	  sha2_remain_len_block_n = m_len - 64;
	end
  end
  else if (pad_state_sha2 == CHECK_SHA3_BUSY && ~sha3_busy) begin
	if (sha2_remain_len_block < 56) sha2_case_n = SHA2_CASE1;
	else if (sha2_remain_len_block >= 56 && sha2_remain_len_block < 64) sha2_case_n = SHA2_CASE2;
	else if (sha2_remain_len_block == 64) sha2_case_n = SHA2_CASE3;
	else begin
	  sha2_case_n = SHA2_CASE4;
	  sha2_remain_len_block_n = sha2_remain_len_block - 64;
	end
  end

  if (sha2_case == SHA2_CASE1) sha2_final_rnd_n = 1;
  else if (sha2_case == SHA2_CASE2 || sha2_case == SHA2_CASE3) begin
	if (sha2_done) sha2_final_rnd_n = 1;
	else if (m_len <= 64 && sha2_load_valid) sha2_final_rnd_n = 1;
  end

  // SHA3
  sha3_remain_len_block_n = sha3_remain_len_block;
  sha3_final_rnd_n = sha3_final_rnd;
  sha3_case_n = sha3_case;
  if (enable) begin
	if (m_len < 136) begin
      sha3_case_n = SHA3_CASE1;
      sha3_remain_len_block_n = m_len;
    end
	else if (m_len == 136) begin
      sha3_case_n = SHA3_CASE2;
      sha3_remain_len_block_n = m_len;
    end
	else begin
	  sha3_case_n = SHA3_CASE3;
	  sha3_remain_len_block_n = m_len - 136;
	end
  end
  else if (pad_state_sha3 == CHECK_SHA2_BUSY && ~sha2_busy) begin
	if (sha3_remain_len_block < 136) sha3_case_n = SHA3_CASE1;
	else if (sha3_remain_len_block == 136) sha3_case_n = SHA3_CASE2;
	else begin
	  sha3_case_n = SHA3_CASE3;
	  sha3_remain_len_block_n = sha3_remain_len_block - 136;
	end
  end

  if (sha3_case == SHA3_CASE1) sha3_final_rnd_n = 1;
  else if (sha3_case == SHA3_CASE2) begin
	if (sha3_done) sha3_final_rnd_n = 1;
	else if (m_len == 136 && sha3_load_valid) sha3_final_rnd_n = 1;
  end
end

// Padding @_@
always @(*) begin
  // SHA2
  sha2_remain_len_n = sha2_remain_len;
  if (enable) begin
	sha2_remain_len_n = m_len;
  end
  else if (pad_state_sha2 == SHA2_FIRST_ROUND || pad_state_sha2 == SHA2_PREPARE_NEXT) begin
	if (sha2_remain_len > 8) sha2_remain_len_n = sha2_remain_len - 8;
	else sha2_remain_len_n = 0;
  end

  sha2_tmp_data = sha2_data;
  sha2_data_n = sha2_tmp_data;
  if (pad_state_sha2 == SHA2_FIRST_ROUND || pad_state_sha2 == SHA2_PREPARE_NEXT) begin
	if (sha2_case == SHA2_CASE1) begin
	  case(sha2_cnt)
	    0: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*0:511-64*(0+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		1: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*1:511-64*(1+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		2: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*2:511-64*(2+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		3: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*3:511-64*(3+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		4: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*4:511-64*(4+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		5: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*5:511-64*(5+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		6: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*6:511-64*(6+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		7: begin
		  case(sha2_remain_len)
			0: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = 64'b0;
			1: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text8, 56'b0};
			2: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text7, sha2_text8, 48'b0};
			3: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 40'b0};
			4: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 32'b0};
			5: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 24'b0};
			6: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 16'b0};
			7: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 8'b0};
			default: sha2_tmp_data[511-64*7:511-64*(7+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  endcase
		end
		default: sha2_tmp_data = sha2_data; // should not happen
	  endcase
	  
	  if (sha2_cnt == 7) begin
		sha2_data_n[511 - 8 * sha2_remain_len_block] = 1'b1;
		sha2_data_n[63:0] = m_len*8;
	  end
	  else sha2_data_n = sha2_tmp_data;
	end
	else if (sha2_case == SHA2_CASE2) begin
	  if (sha2_final_rnd) begin
		sha2_data_n[511:64] = 448'b0;
		sha2_data_n[63:0] = m_len*8;
	  end
	  else begin
		if (sha2_cnt < 7) begin
		  case(sha2_cnt)
		    0: begin
			  sha2_data_n[511-64*0:511-64*(0+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
			end
			1: begin
			  sha2_data_n[511-64*1:511-64*(1+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
			end
			2: begin
			  sha2_data_n[511-64*2:511-64*(2+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
			end
			3: begin
			  sha2_data_n[511-64*3:511-64*(3+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
			end
			4: begin
			  sha2_data_n[511-64*4:511-64*(4+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
			end
			5: begin
			  sha2_data_n[511-64*5:511-64*(5+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
			end
			6: begin
			  sha2_data_n[511-64*6:511-64*(6+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
			end
			default: sha2_data_n = sha2_data; // should not happen
		  endcase
		end
		else begin
		  case(sha2_remain_len)
			0: sha2_data_n[511-64*7:511-64*(7+1)+1] = {1'b1, 63'b0};
			1: sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text8, 1'b1, 55'b0};
			2: sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text7, sha2_text8, 1'b1, 47'b0};
			3: sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text6, sha2_text7, sha2_text8, 1'b1, 39'b0};
			4: sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text5, sha2_text6, sha2_text7, sha2_text8, 1'b1, 31'b0};
			5: sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 1'b1, 23'b0};
			6: sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 1'b1, 15'b0};
			7: sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8, 1'b1, 7'b0};
			default: sha2_data_n[511-64*7:511-64*(7+1)+1] = 0; // should not happen
		  endcase
		end
	  end
	end
	else if (sha2_case == SHA2_CASE3) begin
	  if (sha2_final_rnd) begin
		sha2_data_n[511:64] = {1'b1, 447'b0};
		sha2_data_n[63:0] = m_len*8;
	  end
	  else begin
		case(sha2_cnt)
		  0: begin
		  	sha2_data_n[511-64*0:511-64*(0+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  1: begin
		  	sha2_data_n[511-64*1:511-64*(1+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  2: begin
		  	sha2_data_n[511-64*2:511-64*(2+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  3: begin
		  	sha2_data_n[511-64*3:511-64*(3+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  4: begin
		  	sha2_data_n[511-64*4:511-64*(4+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  5: begin
		  	sha2_data_n[511-64*5:511-64*(5+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  6: begin
		  	sha2_data_n[511-64*6:511-64*(6+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  7: begin
		  	sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		  end
		  default: sha2_data_n = sha2_data; // should not happen
		endcase
	  end 
	end
	else begin
	  case(sha2_cnt)
		0: begin
		sha2_data_n[511-64*0:511-64*(0+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		1: begin
		sha2_data_n[511-64*1:511-64*(1+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		2: begin
		sha2_data_n[511-64*2:511-64*(2+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		3: begin
		sha2_data_n[511-64*3:511-64*(3+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		4: begin
		sha2_data_n[511-64*4:511-64*(4+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		5: begin
		sha2_data_n[511-64*5:511-64*(5+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		6: begin
		sha2_data_n[511-64*6:511-64*(6+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		7: begin
		sha2_data_n[511-64*7:511-64*(7+1)+1] = {sha2_text1, sha2_text2, sha2_text3, sha2_text4, sha2_text5, sha2_text6, sha2_text7, sha2_text8};
		end
		default: sha2_data_n = sha2_data; // should not happen
	  endcase
	end
  end

  // SHA3
  sha3_remain_len_n = sha3_remain_len;
  if (enable) begin
	sha3_remain_len_n = m_len;
  end
  else if (pad_state_sha3 == SHA3_FIRST_ROUND || pad_state_sha3 == SHA3_PREPARE_NEXT) begin
	if (sha3_remain_len > 8) sha3_remain_len_n = sha3_remain_len - 8;
	else sha3_remain_len_n = 0;
  end

  sha3_tmp_data = sha3_data;
//   sha3_data_n = sha3_tmp_data;   // spyglass warning(multiple drivers)
  if (pad_state_sha3 == SHA3_FIRST_ROUND || pad_state_sha3 == SHA3_PREPARE_NEXT) begin
	if (sha3_case == SHA3_CASE1) begin
	  case(sha3_cnt)
	    0: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*0:1087-64*(0+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		1: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*1:1087-64*(1+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		2: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*2:1087-64*(2+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		3: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*3:1087-64*(3+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		4: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*4:1087-64*(4+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		5: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*5:1087-64*(5+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		6: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*6:1087-64*(6+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		7: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*7:1087-64*(7+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		8: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*8:1087-64*(8+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		9: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*9:1087-64*(9+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		10: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*10:1087-64*(10+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		11: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*11:1087-64*(11+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		12: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*12:1087-64*(12+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		13: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*13:1087-64*(13+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		14: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*14:1087-64*(14+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		15: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*15:1087-64*(15+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		16: begin
		  case(sha3_remain_len)
			0: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = 64'b0;
			1: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text8, 56'b0};
			2: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text7, sha3_text8, 48'b0};
			3: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text6, sha3_text7, sha3_text8, 40'b0};
			4: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text5, sha3_text6, sha3_text7, sha3_text8, 32'b0};
			5: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 24'b0};
			6: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 16'b0};
			7: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8, 8'b0};
			default: sha3_tmp_data[1087-64*16:1087-64*(16+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
	  	  endcase
		end
		default: sha3_tmp_data = sha3_data; // should not happen
	  endcase
	  
	  if (sha3_cnt == 16) begin
		if (sha3_remain_len_block < 128) begin
		  for (i=64; i<1088; i=i+1) begin
		    if (i == 1087 - 8 * sha3_remain_len_block - 1) sha3_data_n[i] = 1'b1;
		    else if (i == 1087 - 8 * sha3_remain_len_block - 2) sha3_data_n[i] = 1'b1;
			else sha3_data_n[i] = sha3_data[i];
		  end
		  sha3_data_n[63:0] = {63'b0, 1'b1};
		end
		else begin
		  sha3_data_n[0] = 1'b1;
		  sha3_data_n[1087:64] = sha3_data[1087:64];
		  for (i=1; i<64; i=i+1) begin
		    if (i == 1087 - 8 * sha3_remain_len_block - 1) sha3_data_n[i] = 1'b1;
		    else if (i == 1087 - 8 * sha3_remain_len_block - 2) sha3_data_n[i] = 1'b1;
			else sha3_data_n[i] = 0;
		  end
		end
	  end
	  else sha3_data_n = sha3_tmp_data;
	end
	else if (sha3_case == SHA3_CASE2) begin
	  if (sha3_final_rnd) begin
		sha3_data_n = {3'b011, 1084'b0, 1'b1};
	  end
	  else begin
		case(sha3_cnt)
		  0: begin
			sha3_data_n[1087-64*0:1087-64*(0+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
		    sha3_data_n[1087-64*(0+1):0] = sha3_data[1087-64*(0+1):0];
		  end
		  1: begin
			sha3_data_n[1087-64*1:1087-64*(1+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
		    sha3_data_n[1087-64*0:1087-64*(0+1)+1] = sha3_data[1087-64*0:1087-64*(0+1)+1];
			sha3_data_n[1087-64*(1+1):0] = sha3_data[1087-64*(1+1):0];
		  end
		  2: begin
			sha3_data_n[1087-64*2:1087-64*(2+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
		    sha3_data_n[1087-64*0:1087-64*(1+1)+1] = sha3_data[1087-64*0:1087-64*(1+1)+1];
			sha3_data_n[1087-64*(2+1):0] = sha3_data[1087-64*(2+1):0];
		  end
		  3: begin
			sha3_data_n[1087-64*3:1087-64*(3+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(2+1)+1] = sha3_data[1087-64*0:1087-64*(2+1)+1];
			sha3_data_n[1087-64*(3+1):0] = sha3_data[1087-64*(3+1):0];
		  end
		  4: begin
			sha3_data_n[1087-64*4:1087-64*(4+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(3+1)+1] = sha3_data[1087-64*0:1087-64*(3+1)+1];
			sha3_data_n[1087-64*(4+1):0] = sha3_data[1087-64*(4+1):0];
		  end
		  5: begin
			sha3_data_n[1087-64*5:1087-64*(5+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(4+1)+1] = sha3_data[1087-64*0:1087-64*(4+1)+1];
			sha3_data_n[1087-64*(5+1):0] = sha3_data[1087-64*(5+1):0];
		  end
		  6: begin
			sha3_data_n[1087-64*6:1087-64*(6+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(5+1)+1] = sha3_data[1087-64*0:1087-64*(5+1)+1];
			sha3_data_n[1087-64*(6+1):0] = sha3_data[1087-64*(6+1):0];
		  end
		  7: begin
			sha3_data_n[1087-64*7:1087-64*(7+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(6+1)+1] = sha3_data[1087-64*0:1087-64*(6+1)+1];
			sha3_data_n[1087-64*(7+1):0] = sha3_data[1087-64*(7+1):0];
		  end
		  8: begin
			sha3_data_n[1087-64*8:1087-64*(8+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(7+1)+1] = sha3_data[1087-64*0:1087-64*(7+1)+1];
			sha3_data_n[1087-64*(8+1):0] = sha3_data[1087-64*(8+1):0];
		  end
		  9: begin
			sha3_data_n[1087-64*9:1087-64*(9+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(8+1)+1] = sha3_data[1087-64*0:1087-64*(8+1)+1];
			sha3_data_n[1087-64*(9+1):0] = sha3_data[1087-64*(9+1):0];
		  end
		  10: begin
			sha3_data_n[1087-64*10:1087-64*(10+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(9+1)+1] = sha3_data[1087-64*0:1087-64*(9+1)+1];
			sha3_data_n[1087-64*(10+1):0] = sha3_data[1087-64*(10+1):0];
		  end
		  11: begin
			sha3_data_n[1087-64*11:1087-64*(11+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(10+1)+1] = sha3_data[1087-64*0:1087-64*(10+1)+1];
			sha3_data_n[1087-64*(11+1):0] = sha3_data[1087-64*(11+1):0];
		  end
		  12: begin
			sha3_data_n[1087-64*12:1087-64*(12+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(11+1)+1] = sha3_data[1087-64*0:1087-64*(11+1)+1];
			sha3_data_n[1087-64*(12+1):0] = sha3_data[1087-64*(12+1):0];
		  end
		  13: begin
			sha3_data_n[1087-64*13:1087-64*(13+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(12+1)+1] = sha3_data[1087-64*0:1087-64*(12+1)+1];
			sha3_data_n[1087-64*(13+1):0] = sha3_data[1087-64*(13+1):0];
		  end
		  14: begin
			sha3_data_n[1087-64*14:1087-64*(14+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(13+1)+1] = sha3_data[1087-64*0:1087-64*(13+1)+1];
			sha3_data_n[1087-64*(14+1):0] = sha3_data[1087-64*(14+1):0];
		  end
		  15: begin
			sha3_data_n[1087-64*15:1087-64*(15+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(14+1)+1] = sha3_data[1087-64*0:1087-64*(14+1)+1];
			sha3_data_n[1087-64*(15+1):0] = sha3_data[1087-64*(15+1):0];
		  end
		  16: begin
			sha3_data_n[1087-64*16:1087-64*(16+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(15+1)+1] = sha3_data[1087-64*0:1087-64*(15+1)+1];
		  end
		  default: sha3_data_n = sha3_data; // should not happen
		endcase
	  end
	end
	else begin
		case(sha3_cnt)
		  0: begin
			sha3_data_n[1087-64*0:1087-64*(0+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
		    sha3_data_n[1087-64*(0+1):0] = sha3_data[1087-64*(0+1):0];
		  end
		  1: begin
			sha3_data_n[1087-64*1:1087-64*(1+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
		    sha3_data_n[1087-64*0:1087-64*(0+1)+1] = sha3_data[1087-64*0:1087-64*(0+1)+1];
			sha3_data_n[1087-64*(1+1):0] = sha3_data[1087-64*(1+1):0];
		  end
		  2: begin
			sha3_data_n[1087-64*2:1087-64*(2+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
		    sha3_data_n[1087-64*0:1087-64*(1+1)+1] = sha3_data[1087-64*0:1087-64*(1+1)+1];
			sha3_data_n[1087-64*(2+1):0] = sha3_data[1087-64*(2+1):0];
		  end
		  3: begin
			sha3_data_n[1087-64*3:1087-64*(3+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(2+1)+1] = sha3_data[1087-64*0:1087-64*(2+1)+1];
			sha3_data_n[1087-64*(3+1):0] = sha3_data[1087-64*(3+1):0];
		  end
		  4: begin
			sha3_data_n[1087-64*4:1087-64*(4+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(3+1)+1] = sha3_data[1087-64*0:1087-64*(3+1)+1];
			sha3_data_n[1087-64*(4+1):0] = sha3_data[1087-64*(4+1):0];
		  end
		  5: begin
			sha3_data_n[1087-64*5:1087-64*(5+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(4+1)+1] = sha3_data[1087-64*0:1087-64*(4+1)+1];
			sha3_data_n[1087-64*(5+1):0] = sha3_data[1087-64*(5+1):0];
		  end
		  6: begin
			sha3_data_n[1087-64*6:1087-64*(6+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(5+1)+1] = sha3_data[1087-64*0:1087-64*(5+1)+1];
			sha3_data_n[1087-64*(6+1):0] = sha3_data[1087-64*(6+1):0];
		  end
		  7: begin
			sha3_data_n[1087-64*7:1087-64*(7+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(6+1)+1] = sha3_data[1087-64*0:1087-64*(6+1)+1];
			sha3_data_n[1087-64*(7+1):0] = sha3_data[1087-64*(7+1):0];
		  end
		  8: begin
			sha3_data_n[1087-64*8:1087-64*(8+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(7+1)+1] = sha3_data[1087-64*0:1087-64*(7+1)+1];
			sha3_data_n[1087-64*(8+1):0] = sha3_data[1087-64*(8+1):0];
		  end
		  9: begin
			sha3_data_n[1087-64*9:1087-64*(9+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(8+1)+1] = sha3_data[1087-64*0:1087-64*(8+1)+1];
			sha3_data_n[1087-64*(9+1):0] = sha3_data[1087-64*(9+1):0];
		  end
		  10: begin
			sha3_data_n[1087-64*10:1087-64*(10+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(9+1)+1] = sha3_data[1087-64*0:1087-64*(9+1)+1];
			sha3_data_n[1087-64*(10+1):0] = sha3_data[1087-64*(10+1):0];
		  end
		  11: begin
			sha3_data_n[1087-64*11:1087-64*(11+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(10+1)+1] = sha3_data[1087-64*0:1087-64*(10+1)+1];
			sha3_data_n[1087-64*(11+1):0] = sha3_data[1087-64*(11+1):0];
		  end
		  12: begin
			sha3_data_n[1087-64*12:1087-64*(12+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(11+1)+1] = sha3_data[1087-64*0:1087-64*(11+1)+1];
			sha3_data_n[1087-64*(12+1):0] = sha3_data[1087-64*(12+1):0];
		  end
		  13: begin
			sha3_data_n[1087-64*13:1087-64*(13+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(12+1)+1] = sha3_data[1087-64*0:1087-64*(12+1)+1];
			sha3_data_n[1087-64*(13+1):0] = sha3_data[1087-64*(13+1):0];
		  end
		  14: begin
			sha3_data_n[1087-64*14:1087-64*(14+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(13+1)+1] = sha3_data[1087-64*0:1087-64*(13+1)+1];
			sha3_data_n[1087-64*(14+1):0] = sha3_data[1087-64*(14+1):0];
		  end
		  15: begin
			sha3_data_n[1087-64*15:1087-64*(15+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(14+1)+1] = sha3_data[1087-64*0:1087-64*(14+1)+1];
			sha3_data_n[1087-64*(15+1):0] = sha3_data[1087-64*(15+1):0];
		  end
		  16: begin
			sha3_data_n[1087-64*16:1087-64*(16+1)+1] = {sha3_text1, sha3_text2, sha3_text3, sha3_text4, sha3_text5, sha3_text6, sha3_text7, sha3_text8};
			sha3_data_n[1087-64*0:1087-64*(15+1)+1] = sha3_data[1087-64*0:1087-64*(15+1)+1];
		  end
		  default: sha3_data_n = sha3_data; // should not happen
		endcase
	end
  end
  else sha3_data_n = sha3_data;
end

// Address control
always @(*) begin
  // SHA2
  if (pad_state_sha2 == SHA2_FIRST_ROUND || pad_state_sha2 == SHA2_PREPARE_NEXT) begin
	sha2_addr = sha2_addr_pre + 1;
  end
  else begin
	sha2_addr = sha2_addr_pre;
  end
  // SHA3
  if (pad_state_sha3 == SHA3_FIRST_ROUND || pad_state_sha3 == SHA3_PREPARE_NEXT) begin
	sha3_addr = sha3_addr_pre + 1;
  end
  else begin
	sha3_addr = sha3_addr_pre;
  end

  // Choose address to SRAM
  if (pad_state_sha3 == SHA3_PREPARE_NEXT) begin
	sram_addr = sha3_addr;
  end
  else if (pad_state_sha2 == SHA2_PREPARE_NEXT) begin
	sram_addr = sha2_addr;
  end
  else if (pad_state_sha2 == CHECK_SHA3_BUSY && ~sha3_busy) begin
	sram_addr = sha2_addr;
  end
  else if (pad_state_sha3 == CHECK_SHA2_BUSY && ~sha2_busy) begin
	sram_addr = sha3_addr;
  end
  else begin
	sram_addr = sha3_addr; // for first round
  end
end

// Data valid signal
always @(*) begin
  if (pad_state_sha2 == SHA2_FIRST_ROUND && sha2_cnt == 7) sha2_load_valid_n = 1;
  else if (sha2_done && ~sha2_valid_n) sha2_load_valid_n = 1;
  else sha2_load_valid_n = 0;

  if (pad_state_sha3 == SHA3_FIRST_ROUND && sha3_cnt == 16) sha3_load_valid_n = 1;
  else if (sha3_done && ~sha3_valid_n) sha3_load_valid_n = 1;
  else sha3_load_valid_n = 0;
end

// Busy control
always @(*) begin
  sha2_busy_n = sha2_busy;
  sha3_busy_n = sha3_busy;
  if (sha2_done) sha2_busy_n = 1;
  else if (sha3_done) sha3_busy_n = 1;
  else if (pad_state_sha2 == SHA2_WAIT_DONE) sha2_busy_n = 0;
  else if (pad_state_sha3 == SHA3_WAIT_DONE) sha3_busy_n = 0;
  else if (pad_state_sha2 == SHA2_FINAL_ROUND) sha2_busy_n = 0;
  else if (pad_state_sha3 == SHA3_FINAL_ROUND) sha3_busy_n = 0;
end

// counter control
always @(*) begin
  // SHA2
  if (pad_state_sha2 == SHA2_FIRST_ROUND || pad_state_sha2 == SHA2_PREPARE_NEXT) begin
	sha2_cnt_n = sha2_cnt + 1;
  end
  else begin
	sha2_cnt_n = 0;
  end
  // SHA3
  if (pad_state_sha3 == SHA3_FIRST_ROUND || pad_state_sha3 == SHA3_PREPARE_NEXT) begin
	sha3_cnt_n = sha3_cnt + 1;
  end
  else begin
	sha3_cnt_n = 0;
  end
end

// output valid control
always @(*) begin
  // SHA2
  sha2_valid_delay_n = sha2_valid_delay;
  if (m_len < 56) begin
	if (pad_state_sha2 == SHA2_FINAL_ROUND && sha2_done) sha2_valid_n = 1;
    else sha2_valid_n = sha2_valid;
  end
  else begin
	if (sha2_done && pad_state_sha2 == SHA2_FINAL_ROUND) sha2_valid_delay_n = 1;
	if (sha2_valid_delay && sha2_done) sha2_valid_n = 1;
	else sha2_valid_n = sha2_valid;
  end
  
  // SHA3
  sha3_valid_delay_n = sha3_valid_delay;
  if (m_len < 136) begin
	if (pad_state_sha3 == SHA3_FINAL_ROUND && sha3_done) sha3_valid_n = 1;
    else sha3_valid_n = sha3_valid;
  end
  else begin
	if (sha3_done && pad_state_sha3 == SHA3_FINAL_ROUND) sha3_valid_delay_n = 1;
	if (sha3_valid_delay && sha3_done) sha3_valid_n = 1;
	else sha3_valid_n = sha3_valid;
  end
end



// Sequential circuit
always @(posedge clk) begin
  if (~srst_n) begin
	pad_state_sha2 <= IDLE;
	pad_state_sha3 <= IDLE;
	sha2_cnt <= 0;
	sha3_cnt <= 0;
	sha2_remain_len <= 0;
	sha3_remain_len <= 0;
	sha2_valid <= 0;
	sha3_valid <= 0;
	sha2_data <= 0;
	sha3_data <= 0;
	sha2_addr_pre <= 0;
	sha3_addr_pre <= 0;
	sha2_load_valid <= 0;
	sha3_load_valid <= 0;
	sha2_final_rnd <= 0;
	sha3_final_rnd <= 0;
	sha2_remain_len_block <= 0;
	sha3_remain_len_block <= 0;
	sha2_case <= SHA2_CASE4;
	sha3_case <= SHA3_CASE3;
	sha2_busy <= 0;
	sha3_busy <= 1;
	sha2_valid_delay <= 0;
	sha3_valid_delay <= 0;
  end
  else begin
	pad_state_sha2 <= pad_state_sha2_n;
	pad_state_sha3 <= pad_state_sha3_n;
	sha2_cnt <= sha2_cnt_n;
	sha3_cnt <= sha3_cnt_n;
	sha2_remain_len <= sha2_remain_len_n;
	sha3_remain_len <= sha3_remain_len_n;
	sha2_valid <= sha2_valid_n;
	sha3_valid <= sha3_valid_n;
	sha2_data <= sha2_data_n;
	sha3_data <= sha3_data_n;
	sha2_addr_pre <= sha2_addr;
	sha3_addr_pre <= sha3_addr;
	sha2_load_valid <= sha2_load_valid_n;
	sha3_load_valid <= sha3_load_valid_n;
	sha2_final_rnd <= sha2_final_rnd_n;
	sha3_final_rnd <= sha3_final_rnd_n;
	sha2_remain_len_block <= sha2_remain_len_block_n;
	sha3_remain_len_block <= sha3_remain_len_block_n;
	sha2_case <= sha2_case_n;
	sha3_case <= sha3_case_n;
	sha2_busy <= sha2_busy_n;
	sha3_busy <= sha3_busy_n;
	sha2_valid_delay <= sha2_valid_delay_n;
	sha3_valid_delay <= sha3_valid_delay_n;
  end
end


endmodule