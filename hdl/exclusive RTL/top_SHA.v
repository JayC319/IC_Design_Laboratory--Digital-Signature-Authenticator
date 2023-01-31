module top_SHA (
	input clk,
	input srst_n,
	input enable,										// SRAM ready	
	input [63:0] sram_data,					// SRAM data
	input [10:0] m_len,             // message length

	output reg SHA2_valid,					// SHA2 ouput valid
	output reg SHA3_valid,					// SHA3 ouput valid
	output reg [7:0] sram_addr,			// SRAM address
	output reg [63:0] data_out
);
//==================================================================================================
//     local parameter instantiation
//==================================================================================================
localparam IDLE = 4'd0, HASH = 4'd1, 
			SHA2FST = 4'd2, SHA3FST = 4'd3,
			WAITSHA3 = 4'd4, WAITSHA2 = 4'd5,
			SHA3SND = 4'd6, SHA2SND = 4'd7,
			FINISH = 4'd8;

//==================================================================================================
//     reg instantiation
//==================================================================================================
integer i;
reg [3:0] top_state, top_state_n;
reg [1:0] top_cnt, top_cnt_n;

//==================================================================================================
//     wire instantiation
//==================================================================================================
// wire for padding output port
wire [7:0] pad_sram_addr;				// fetch sram address
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
wire [64-1:0] H0_SHA2;
wire [64-1:0] H1_SHA2;
wire [64-1:0] H2_SHA2;
wire [64-1:0] H3_SHA2;

// wire for SHA3 module output port
wire SHA3_done;
wire [64-1:0] H0_SHA3;
wire [64-1:0] H1_SHA3;
wire [64-1:0] H2_SHA3;
wire [64-1:0] H3_SHA3;

//==================================================================================================
//     module instantiation
//==================================================================================================


padding U_padding(
	// input port
	.clk(clk),
	.srst_n(srst_n),
	.enable(enable),
	.data_in(sram_data),
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
	.sram_addr(pad_sram_addr)
);


SHA2 U_SHA2(
	// input port
	.clk(clk),
	.srst_n(srst_n),
	.load_en(SHA2_load_en),
	.sha2_in({P0_SHA2, P1_SHA2, P2_SHA2, P3_SHA2, 
				P4_SHA2, P5_SHA2, P6_SHA2, P7_SHA2}),

	// output port
	.sha2_out({H0_SHA2, H1_SHA2, H2_SHA2, H3_SHA2}),
	.sha2_done(SHA2_done)
);


SHA3 U_SHA3(
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
	.SHA3_out({H0_SHA3, H1_SHA3, H2_SHA3, H3_SHA3}),
	.SHA3_done(SHA3_done)
);


//==================================================================================================
//     sequential circuit 
//==================================================================================================
always @(posedge clk) begin
	if(~srst_n) begin
		top_state <= IDLE;
		top_cnt	  <= 2'b00;
	end

	else begin
		top_state <= top_state_n;
		top_cnt   <= top_cnt_n;
	end
end


//==================================================================================================
//     finite top_state machine
//==================================================================================================
always @(*) begin
	case(top_state)
		// IDLE
		IDLE: begin
			if (enable) begin
				top_state_n = HASH;
			end

			else begin
				top_state_n = top_state;
			end
		end
		
		// HASH
		HASH: begin
			if (pad_SHA2_valid) begin
				top_state_n = SHA2FST;
			end

			else if (pad_SHA3_valid) begin
				top_state_n = SHA3FST;
			end

			else begin
				top_state_n = HASH;
			end
		end

		// SHA2FST
		SHA2FST: begin
			if (top_cnt == 2'b11 && pad_SHA3_valid) begin
				top_state_n = SHA3SND;
			end

			else if (top_cnt == 2'b11) begin
				top_state_n = WAITSHA3;
			end

			else begin
				top_state_n = SHA2FST;
			end
		end

		// SHA3FST
		SHA3FST: begin
			if (top_cnt == 2'b11 && pad_SHA2_valid) begin
				top_state_n = SHA2SND;
			end

			else if (top_cnt == 2'b11) begin
				top_state_n = WAITSHA2;
			end

			else begin
				top_state_n = SHA3FST;
			end
		end

		// WAITSHA3
		WAITSHA3: begin
			if (pad_SHA3_valid) begin
				top_state_n = SHA3SND;
			end

			else begin
				top_state_n = WAITSHA3;
			end
		end

		// WAITSHA2
		WAITSHA2: begin
			if (pad_SHA2_valid) begin
				top_state_n = SHA2SND;
			end

			else begin
				top_state_n = WAITSHA2;
			end
		end

		// SHA3SND
		SHA3SND: begin
			if (top_cnt == 2'b11) begin
				top_state_n = FINISH;
			end

			else begin
				top_state_n = SHA3SND;
			end
		end

		// SHA2SND
		SHA2SND: begin
			if (top_cnt == 2'b11) begin
				top_state_n = FINISH;
			end

			else begin
				top_state_n = SHA2SND;
			end
		end

		// FINISH
		FINISH: begin
			top_state_n = FINISH;
		end

		// default
		default: begin
			top_state_n = IDLE;
		end
	endcase
end

//==================================================================================================
//     combinational circuit
//==================================================================================================
// sram address
always @(*) begin
	sram_addr = pad_sram_addr;
end

// top counter
always @(*) begin
	if (top_state == SHA2FST) begin
		top_cnt_n = top_cnt + 1;
	end

	else if (top_state == SHA3FST) begin
		top_cnt_n = top_cnt + 1;
	end

	else if (top_state == SHA3SND) begin
		top_cnt_n = top_cnt + 1;
	end

	else if (top_state == SHA2SND) begin
		top_cnt_n = top_cnt + 1;
	end

	else begin
		top_cnt_n = 2'b00;
	end
end

// top SHA2 valid
always @(*) begin
	if (top_state == SHA2FST) begin
		SHA2_valid = 1;
	end

	else if (top_state == SHA2SND) begin
		SHA2_valid = 1;
	end

	else begin
		SHA2_valid = 0;
	end
end

// top SHA3 valid
always @(*) begin
	if (top_state == SHA3FST) begin
		SHA3_valid = 1;
	end

	else if (top_state == SHA3SND) begin
		SHA3_valid = 1;
	end

	else begin
		SHA3_valid = 0;
	end
end

// top output data
always @(*) begin
	if (top_state == SHA2FST) begin
		case (top_cnt)
			2'b00:	data_out = H0_SHA2;
			2'b01:  data_out = H1_SHA2;
			2'b10:  data_out = H2_SHA2;
			2'b11:  data_out = H3_SHA2;
			default: data_out = 64'h53484132465354;	// SHA2FST
		endcase	
	end

	else if (top_state == SHA2SND) begin
		case (top_cnt)
			2'b00:	data_out = H0_SHA2;
			2'b01:  data_out = H1_SHA2;
			2'b10:  data_out = H2_SHA2;
			2'b11:  data_out = H3_SHA2;
			default: data_out = 64'h53484132534E44;	// SHA2SND
		endcase	
	end

	else if (top_state == SHA3FST) begin
		case (top_cnt)
			2'b00: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H0_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H0_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H0_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H0_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H0_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H0_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H0_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H0_SHA3[63-i];
			end

			2'b01: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H1_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H1_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H1_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H1_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H1_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H1_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H1_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H1_SHA3[63-i];
			end

			2'b10: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H2_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H2_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H2_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H2_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H2_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H2_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H2_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H2_SHA3[63-i];
			end

			2'b11: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H3_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H3_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H3_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H3_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H3_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H3_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H3_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H3_SHA3[63-i];
			end

			default: data_out = 64'h53484133465354; // SHA3FST
		endcase	
	end

	else if (top_state == SHA3SND) begin
		case (top_cnt)
			2'b00: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H0_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H0_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H0_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H0_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H0_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H0_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H0_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H0_SHA3[63-i];
			end

			2'b01: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H1_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H1_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H1_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H1_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H1_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H1_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H1_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H1_SHA3[63-i];
			end

			2'b10: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H2_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H2_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H2_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H2_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H2_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H2_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H2_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H2_SHA3[63-i];
			end

			2'b11: begin
				for (i = 0; i <= 7; i = i + 1) data_out[i] = H3_SHA3[7-i];
				for (i = 0; i <= 7; i = i + 1) data_out[8+i] = H3_SHA3[15-i];
				for (i = 0; i <= 7; i = i + 1) data_out[16+i] = H3_SHA3[23-i];
				for (i = 0; i <= 7; i = i + 1) data_out[24+i] = H3_SHA3[31-i];
				for (i = 0; i <= 7; i = i + 1) data_out[32+i] = H3_SHA3[39-i];
				for (i = 0; i <= 7; i = i + 1) data_out[40+i] = H3_SHA3[47-i];
				for (i = 0; i <= 7; i = i + 1) data_out[48+i] = H3_SHA3[55-i];
				for (i = 0; i <= 7; i = i + 1) data_out[56+i] = H3_SHA3[63-i];
			end

			default: data_out = 64'h53484133534E44; // SHA3SND
		endcase	
	end

	else begin
		data_out = 64'h554E56414C4944; // UNVALID
	end 
end
endmodule