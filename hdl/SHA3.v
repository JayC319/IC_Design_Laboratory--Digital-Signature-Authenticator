module SHA3 #(
parameter BW_PER_LANE = 64,
parameter RND_NUM = 24
)
(
  input clk,
  input srst_n,
  input SHA3_en,
	input load_en,

  input [BW_PER_LANE-1:0] P0,
  input [BW_PER_LANE-1:0] P1,
  input [BW_PER_LANE-1:0] P2,
  input [BW_PER_LANE-1:0] P3,
  input [BW_PER_LANE-1:0] P4,
  input [BW_PER_LANE-1:0] P5,
  input [BW_PER_LANE-1:0] P6,
  input [BW_PER_LANE-1:0] P7,
  input [BW_PER_LANE-1:0] P8,
  input [BW_PER_LANE-1:0] P9,
  input [BW_PER_LANE-1:0] P10,
  input [BW_PER_LANE-1:0] P11,
  input [BW_PER_LANE-1:0] P12,
  input [BW_PER_LANE-1:0] P13,
  input [BW_PER_LANE-1:0] P14,
  input [BW_PER_LANE-1:0] P15,
  input [BW_PER_LANE-1:0] P16,

  output reg [256-1:0] SHA3_out,
	output reg SHA3_done
);


//==================================================================================================
//     local parameter instantiation
//==================================================================================================
integer i;
localparam IDLE = 3'd0, LOAD = 3'd1, THETA = 3'd2, RHO = 3'd3,
PI = 3'd4, KAI = 3'd5, IOTA = 3'd6, REFRESH = 3'd7;


//==================================================================================================
//     reg instantiation
//==================================================================================================
reg [2:0] SHA3_state, SHA3_state_n;
reg [4:0] round, round_n;

// reg for input
reg [BW_PER_LANE-1:0] lane_n[0:24];
reg [BW_PER_LANE-1:0] lane[0:24];

// reg for theta
reg [BW_PER_LANE-1:0] C_n [0:4];

reg [BW_PER_LANE-1:0] D_n [0:4];

reg [BW_PER_LANE-1:0] lane_theta_rho_n[0:24];
reg [BW_PER_LANE-1:0] lane_theta_rho[0:24];

// reg for rho
reg [BW_PER_LANE-1:0] lane_rho_pi_n[0:24];
reg [BW_PER_LANE-1:0] lane_rho_pi[0:24];

// reg for pi
reg [BW_PER_LANE-1:0] lane_pi_kai_n[0:24];
reg [BW_PER_LANE-1:0] lane_pi_kai[0:24];

// reg for kai
reg [BW_PER_LANE-1:0] lane_kai_iota_n[0:24];
reg [BW_PER_LANE-1:0] lane_kai_iota[0:24];

// reg for iota
reg [BW_PER_LANE-1:0] lane_iota_fout_n[0:24];
reg [BW_PER_LANE-1:0] lane_iota_fout[0:24];


//==================================================================================================
//     wire instantiation
//==================================================================================================
// wire for rho
	wire [BW_PER_LANE-1:0] lane_rho_0;
	wire [BW_PER_LANE-1:0] lane_rho_1;
	wire [BW_PER_LANE-1:0] lane_rho_2;
	wire [BW_PER_LANE-1:0] lane_rho_3;
	wire [BW_PER_LANE-1:0] lane_rho_4;
	wire [BW_PER_LANE-1:0] lane_rho_5;
	wire [BW_PER_LANE-1:0] lane_rho_6;
	wire [BW_PER_LANE-1:0] lane_rho_7;
	wire [BW_PER_LANE-1:0] lane_rho_8;
	wire [BW_PER_LANE-1:0] lane_rho_9;
	wire [BW_PER_LANE-1:0] lane_rho_10;
	wire [BW_PER_LANE-1:0] lane_rho_11;
	wire [BW_PER_LANE-1:0] lane_rho_12;
	wire [BW_PER_LANE-1:0] lane_rho_13;
	wire [BW_PER_LANE-1:0] lane_rho_14;
	wire [BW_PER_LANE-1:0] lane_rho_15;
	wire [BW_PER_LANE-1:0] lane_rho_16;
	wire [BW_PER_LANE-1:0] lane_rho_17;
	wire [BW_PER_LANE-1:0] lane_rho_18;
	wire [BW_PER_LANE-1:0] lane_rho_19;
	wire [BW_PER_LANE-1:0] lane_rho_20;
	wire [BW_PER_LANE-1:0] lane_rho_21;
	wire [BW_PER_LANE-1:0] lane_rho_22;
	wire [BW_PER_LANE-1:0] lane_rho_23;
	wire [BW_PER_LANE-1:0] lane_rho_24;

assign lane_rho_0 = {lane_theta_rho[0]};
assign lane_rho_1 = {lane_theta_rho[1][0], lane_theta_rho[1][63:1]};
assign lane_rho_2 = {lane_theta_rho[2][61:0], lane_theta_rho[2][63:62]};
assign lane_rho_3 = {lane_theta_rho[3][27:0], lane_theta_rho[3][63:28]};
assign lane_rho_4 = {lane_theta_rho[4][26:0], lane_theta_rho[4][63:27]};
assign lane_rho_5 = {lane_theta_rho[5][35:0], lane_theta_rho[5][63:36]};
assign lane_rho_6 = {lane_theta_rho[6][43:0], lane_theta_rho[6][63:44]};
assign lane_rho_7 = {lane_theta_rho[7][5:0], lane_theta_rho[7][63:6]};
assign lane_rho_8 = {lane_theta_rho[8][54:0], lane_theta_rho[8][63:55]};
assign lane_rho_9 = {lane_theta_rho[9][19:0], lane_theta_rho[9][63:20]};
assign lane_rho_10 = {lane_theta_rho[10][2:0], lane_theta_rho[10][63:3]};
assign lane_rho_11 = {lane_theta_rho[11][9:0], lane_theta_rho[11][63:10]};
assign lane_rho_12 = {lane_theta_rho[12][42:0], lane_theta_rho[12][63:43]};
assign lane_rho_13 = {lane_theta_rho[13][24:0], lane_theta_rho[13][63:25]};
assign lane_rho_14 = {lane_theta_rho[14][38:0], lane_theta_rho[14][63:39]};
assign lane_rho_15 = {lane_theta_rho[15][40:0], lane_theta_rho[15][63:41]};
assign lane_rho_16 = {lane_theta_rho[16][44:0], lane_theta_rho[16][63:45]};
assign lane_rho_17 = {lane_theta_rho[17][14:0], lane_theta_rho[17][63:15]};
assign lane_rho_18 = {lane_theta_rho[18][20:0], lane_theta_rho[18][63:21]};
assign lane_rho_19 = {lane_theta_rho[19][7:0], lane_theta_rho[19][63:8]};
assign lane_rho_20 = {lane_theta_rho[20][17:0], lane_theta_rho[20][63:18]};
assign lane_rho_21 = {lane_theta_rho[21][1:0], lane_theta_rho[21][63:2]};
assign lane_rho_22 = {lane_theta_rho[22][60:0], lane_theta_rho[22][63:61]};
assign lane_rho_23 = {lane_theta_rho[23][55:0], lane_theta_rho[23][63:56]};
assign lane_rho_24 = {lane_theta_rho[24][13:0], lane_theta_rho[24][63:14]};


// hard wire for rc bits
	wire [BW_PER_LANE-1:0] rc_bits[0:RND_NUM-1];
	assign rc_bits[0] = 64'b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
	assign rc_bits[1] = 64'b0100000100000001000000000000000000000000000000000000000000000000;
	assign rc_bits[2] = 64'b0101000100000001000000000000000000000000000000000000000000000001;
	assign rc_bits[3] = 64'b0000000000000001000000000000000100000000000000000000000000000001;
	assign rc_bits[4] = 64'b1101000100000001000000000000000000000000000000000000000000000000;
	assign rc_bits[5] = 64'b1000000000000000000000000000000100000000000000000000000000000000;
	assign rc_bits[6] = 64'b1000000100000001000000000000000100000000000000000000000000000001;
	assign rc_bits[7] = 64'b1001000000000001000000000000000000000000000000000000000000000001;
	assign rc_bits[8] = 64'b0101000100000000000000000000000000000000000000000000000000000000;
	assign rc_bits[9] = 64'b0001000100000000000000000000000000000000000000000000000000000000;
	assign rc_bits[10] = 64'b1001000000000001000000000000000100000000000000000000000000000000;
	assign rc_bits[11] = 64'b0101000000000000000000000000000100000000000000000000000000000000;
	assign rc_bits[12] = 64'b1101000100000001000000000000000100000000000000000000000000000000;
	assign rc_bits[13] = 64'b1101000100000000000000000000000000000000000000000000000000000001;
	assign rc_bits[14] = 64'b1001000100000001000000000000000000000000000000000000000000000001;
	assign rc_bits[15] = 64'b1100000000000001000000000000000000000000000000000000000000000001;
	assign rc_bits[16] = 64'b0100000000000001000000000000000000000000000000000000000000000001;
	assign rc_bits[17] = 64'b0000000100000000000000000000000000000000000000000000000000000001;
	assign rc_bits[18] = 64'b0101000000000001000000000000000000000000000000000000000000000000;
	assign rc_bits[19] = 64'b0101000000000000000000000000000100000000000000000000000000000001;
	assign rc_bits[20] = 64'b1000000100000001000000000000000100000000000000000000000000000001;
	assign rc_bits[21] = 64'b0000000100000001000000000000000000000000000000000000000000000001;
	assign rc_bits[22] = 64'b1000000000000000000000000000000100000000000000000000000000000000;
	assign rc_bits[23] = 64'b0001000000000001000000000000000100000000000000000000000000000001;



//==================================================================================================
//     sequential circuit 
//==================================================================================================
always @(posedge clk) begin
	if(~srst_n) begin
		SHA3_state <= IDLE;
		round <= 0;
		for(i = 0; i < 25; i = i + 1) begin
			lane[i] <= 0;
		end
	end

	else begin
		SHA3_state <= SHA3_state_n;
		round <= round_n;

		for(i = 0; i < 25; i = i + 1) begin
			lane[i] <= lane_n[i];
		end

		// theta_rho
		for(i = 0; i < 25; i = i + 1) begin
			lane_theta_rho[i] <= lane_theta_rho_n[i];
		end



		// rho_pi
		for(i = 0; i < 25; i = i + 1) begin
			lane_rho_pi[i] <= lane_rho_pi_n[i];
		end

		// pi_kai
		for(i = 0; i < 25; i = i + 1) begin
			lane_pi_kai[i] <= lane_pi_kai_n[i];
		end

		// kai_iota
		for(i = 0; i < 25; i = i + 1) begin
			lane_kai_iota[i] <= lane_kai_iota_n[i];
		end

		// iota_fout
		for(i = 0; i < 25; i = i + 1) begin
			lane_iota_fout[i] <= lane_iota_fout_n[i];
		end
	end
end


//==================================================================================================
//     finite state machine
//==================================================================================================
always @(*) begin
	case(SHA3_state)
		// IDLE
		IDLE: begin
			if(SHA3_en == 1) begin
				SHA3_state_n = LOAD;
			end

			else begin
				SHA3_state_n = SHA3_state;
			end
		end		

		// LOAD
		LOAD: begin
			if(load_en) begin
				SHA3_state_n = THETA;
			end

			else begin
				SHA3_state_n = SHA3_state;
			end
		end

		// THETA
		THETA: begin
			SHA3_state_n = RHO;
		end

		// RHO
		RHO: begin
			SHA3_state_n = PI;
		end

		// PI
		PI: begin
			SHA3_state_n = KAI;
		end

		// KAI
		KAI: begin
			SHA3_state_n = IOTA;
		end

		// IOTA
		IOTA: begin
			SHA3_state_n = REFRESH;
		end

		// REFRESH
		REFRESH: begin
			if(round == RND_NUM - 1) begin
				SHA3_state_n = LOAD;
			end
			else begin
				SHA3_state_n = THETA;
			end
		end

		// default
		default: begin
			SHA3_state_n = IDLE;
		end
	endcase
end

//==================================================================================================
//     combinational circuit
//==================================================================================================

// output control
always @(*) begin
	SHA3_out = {lane_iota_fout[0],  lane_iota_fout[1],  lane_iota_fout[2],  lane_iota_fout[3]};
end


// round  control
always @(*) begin
	if(SHA3_state == REFRESH && round == 23) begin
		round_n = 0;
	end

	else if(SHA3_state == REFRESH) begin
		round_n = round + 1;
	end

	else begin
		round_n = round;
	end
end

// done signal control
always @(*) begin
	if(SHA3_state == REFRESH && round == 23) begin
		
		SHA3_done = 1;
	end

	else begin
		SHA3_done = 0;
	end
end


// S <-----> 25 * lane
always @(*) begin
	if(SHA3_state == LOAD && load_en == 1) begin
		lane_n[0] = lane[0] ^ P0;
		lane_n[1] = lane[1] ^ P1;
		lane_n[2] = lane[2] ^ P2;
		lane_n[3] = lane[3] ^ P3;
		lane_n[4] = lane[4] ^ P4;
		lane_n[5] = lane[5] ^ P5;
		lane_n[6] = lane[6] ^ P6;
		lane_n[7] = lane[7] ^ P7;
		lane_n[8] = lane[8] ^ P8;
		lane_n[9] = lane[9] ^ P9;
		lane_n[10] = lane[10] ^ P10;
		lane_n[11] = lane[11] ^ P11;
		lane_n[12] = lane[12] ^ P12;
		lane_n[13] = lane[13] ^ P13;
		lane_n[14] = lane[14] ^ P14;
		lane_n[15] = lane[15] ^ P15;
		lane_n[16] = lane[16] ^ P16;
		lane_n[17] = lane[17];
		lane_n[18] = lane[18];
		lane_n[19] = lane[19];
		lane_n[20] = lane[20];
		lane_n[21] = lane[21];
		lane_n[22] = lane[22];
		lane_n[23] = lane[23];
		lane_n[24] = lane[24];

		
	end

	else if (SHA3_state == REFRESH) begin
		for(i = 0; i < 25; i = i + 1) begin
			lane_n[i] = lane_iota_fout[i];
		end
	end

	else begin
		for(i = 0; i < 25; i = i + 1) begin
			lane_n[i] = lane[i];
		end
	end
end


// theta function
// ** three cycle **
always @(*) begin
	C_n[0] = lane[0] ^ lane[5] ^ lane[10] ^ lane[15] ^ lane [20];
	C_n[1] = lane[1] ^ lane[6] ^ lane[11] ^ lane[16] ^ lane [21];
	C_n[2] = lane[2] ^ lane[7] ^ lane[12] ^ lane[17] ^ lane [22];
	C_n[3] = lane[3] ^ lane[8] ^ lane[13] ^ lane[18] ^ lane [23];
	C_n[4] = lane[4] ^ lane[9] ^ lane[14] ^ lane[19] ^ lane [24];

	D_n[0] = C_n[4] ^ {C_n[1][0], C_n[1][63:1]};
	D_n[1] = C_n[0] ^ {C_n[2][0], C_n[2][63:1]};
	D_n[2] = C_n[1] ^ {C_n[3][0], C_n[3][63:1]};
	D_n[3] = C_n[2] ^ {C_n[4][0], C_n[4][63:1]};
	D_n[4] = C_n[3] ^ {C_n[0][0], C_n[0][63:1]};

	if(SHA3_state == THETA) begin
		lane_theta_rho_n[0] = lane[0] ^ D_n[0];
		lane_theta_rho_n[1] = lane[1] ^ D_n[1];
		lane_theta_rho_n[2] = lane[2] ^ D_n[2];
		lane_theta_rho_n[3] = lane[3] ^ D_n[3];
		lane_theta_rho_n[4] = lane[4] ^ D_n[4];
		lane_theta_rho_n[5] = lane[5] ^ D_n[0];
		lane_theta_rho_n[6] = lane[6] ^ D_n[1];
		lane_theta_rho_n[7] = lane[7] ^ D_n[2];
		lane_theta_rho_n[8] = lane[8] ^ D_n[3];
		lane_theta_rho_n[9] = lane[9] ^ D_n[4];
		lane_theta_rho_n[10] = lane[10] ^ D_n[0];
		lane_theta_rho_n[11] = lane[11] ^ D_n[1];
		lane_theta_rho_n[12] = lane[12] ^ D_n[2];
		lane_theta_rho_n[13] = lane[13] ^ D_n[3];
		lane_theta_rho_n[14] = lane[14] ^ D_n[4];
		lane_theta_rho_n[15] = lane[15] ^ D_n[0];
		lane_theta_rho_n[16] = lane[16] ^ D_n[1];
		lane_theta_rho_n[17] = lane[17] ^ D_n[2];
		lane_theta_rho_n[18] = lane[18] ^ D_n[3];
		lane_theta_rho_n[19] = lane[19] ^ D_n[4];
		lane_theta_rho_n[20] = lane[20] ^ D_n[0];
		lane_theta_rho_n[21] = lane[21] ^ D_n[1];
		lane_theta_rho_n[22] = lane[22] ^ D_n[2];
		lane_theta_rho_n[23] = lane[23] ^ D_n[3];
		lane_theta_rho_n[24] = lane[24] ^ D_n[4];
		
	end

	else begin
		for(i = 0; i < 25; i = i + 1) begin
			lane_theta_rho_n[i] = lane_theta_rho[i];
		end
	end
end

// rho function
// ** one cycle **
always @(*) begin
	if(SHA3_state == RHO) begin
		lane_rho_pi_n[0] = lane_rho_0; 
		lane_rho_pi_n[1] = lane_rho_1; 
		lane_rho_pi_n[2] = lane_rho_2; 
		lane_rho_pi_n[3] = lane_rho_3; 
		lane_rho_pi_n[4] = lane_rho_4; 
		lane_rho_pi_n[5] = lane_rho_5; 
		lane_rho_pi_n[6] = lane_rho_6; 
		lane_rho_pi_n[7] = lane_rho_7; 
		lane_rho_pi_n[8] = lane_rho_8; 
		lane_rho_pi_n[9] = lane_rho_9; 
		lane_rho_pi_n[10] = lane_rho_10;
		lane_rho_pi_n[11] = lane_rho_11;
		lane_rho_pi_n[12] = lane_rho_12;
		lane_rho_pi_n[13] = lane_rho_13;
		lane_rho_pi_n[14] = lane_rho_14;
		lane_rho_pi_n[15] = lane_rho_15;
		lane_rho_pi_n[16] = lane_rho_16;
		lane_rho_pi_n[17] = lane_rho_17;
		lane_rho_pi_n[18] = lane_rho_18;
		lane_rho_pi_n[19] = lane_rho_19;
		lane_rho_pi_n[20] = lane_rho_20;
		lane_rho_pi_n[21] = lane_rho_21;
		lane_rho_pi_n[22] = lane_rho_22;
		lane_rho_pi_n[23] = lane_rho_23;
		lane_rho_pi_n[24] = lane_rho_24;
	end

	else begin
		for(i = 0; i < 25;i = i + 1) begin
			lane_rho_pi_n[i] = lane_rho_pi[i];
		end
	end
end

// pi function
// ** one cycle **
always @(*) begin
	if (SHA3_state == PI) begin
		lane_pi_kai_n[0][0] = lane_rho_pi[0][0];
		lane_pi_kai_n[0][1] = lane_rho_pi[0][1];
		lane_pi_kai_n[0][2] = lane_rho_pi[0][2];
		lane_pi_kai_n[0][3] = lane_rho_pi[0][3];
		lane_pi_kai_n[0][4] = lane_rho_pi[0][4];
		lane_pi_kai_n[0][5] = lane_rho_pi[0][5];
		lane_pi_kai_n[0][6] = lane_rho_pi[0][6];
		lane_pi_kai_n[0][7] = lane_rho_pi[0][7];
		lane_pi_kai_n[0][8] = lane_rho_pi[0][8];
		lane_pi_kai_n[0][9] = lane_rho_pi[0][9];
		lane_pi_kai_n[0][10] = lane_rho_pi[0][10];
		lane_pi_kai_n[0][11] = lane_rho_pi[0][11];
		lane_pi_kai_n[0][12] = lane_rho_pi[0][12];
		lane_pi_kai_n[0][13] = lane_rho_pi[0][13];
		lane_pi_kai_n[0][14] = lane_rho_pi[0][14];
		lane_pi_kai_n[0][15] = lane_rho_pi[0][15];
		lane_pi_kai_n[0][16] = lane_rho_pi[0][16];
		lane_pi_kai_n[0][17] = lane_rho_pi[0][17];
		lane_pi_kai_n[0][18] = lane_rho_pi[0][18];
		lane_pi_kai_n[0][19] = lane_rho_pi[0][19];
		lane_pi_kai_n[0][20] = lane_rho_pi[0][20];
		lane_pi_kai_n[0][21] = lane_rho_pi[0][21];
		lane_pi_kai_n[0][22] = lane_rho_pi[0][22];
		lane_pi_kai_n[0][23] = lane_rho_pi[0][23];
		lane_pi_kai_n[0][24] = lane_rho_pi[0][24];
		lane_pi_kai_n[0][25] = lane_rho_pi[0][25];
		lane_pi_kai_n[0][26] = lane_rho_pi[0][26];
		lane_pi_kai_n[0][27] = lane_rho_pi[0][27];
		lane_pi_kai_n[0][28] = lane_rho_pi[0][28];
		lane_pi_kai_n[0][29] = lane_rho_pi[0][29];
		lane_pi_kai_n[0][30] = lane_rho_pi[0][30];
		lane_pi_kai_n[0][31] = lane_rho_pi[0][31];
		lane_pi_kai_n[0][32] = lane_rho_pi[0][32];
		lane_pi_kai_n[0][33] = lane_rho_pi[0][33];
		lane_pi_kai_n[0][34] = lane_rho_pi[0][34];
		lane_pi_kai_n[0][35] = lane_rho_pi[0][35];
		lane_pi_kai_n[0][36] = lane_rho_pi[0][36];
		lane_pi_kai_n[0][37] = lane_rho_pi[0][37];
		lane_pi_kai_n[0][38] = lane_rho_pi[0][38];
		lane_pi_kai_n[0][39] = lane_rho_pi[0][39];
		lane_pi_kai_n[0][40] = lane_rho_pi[0][40];
		lane_pi_kai_n[0][41] = lane_rho_pi[0][41];
		lane_pi_kai_n[0][42] = lane_rho_pi[0][42];
		lane_pi_kai_n[0][43] = lane_rho_pi[0][43];
		lane_pi_kai_n[0][44] = lane_rho_pi[0][44];
		lane_pi_kai_n[0][45] = lane_rho_pi[0][45];
		lane_pi_kai_n[0][46] = lane_rho_pi[0][46];
		lane_pi_kai_n[0][47] = lane_rho_pi[0][47];
		lane_pi_kai_n[0][48] = lane_rho_pi[0][48];
		lane_pi_kai_n[0][49] = lane_rho_pi[0][49];
		lane_pi_kai_n[0][50] = lane_rho_pi[0][50];
		lane_pi_kai_n[0][51] = lane_rho_pi[0][51];
		lane_pi_kai_n[0][52] = lane_rho_pi[0][52];
		lane_pi_kai_n[0][53] = lane_rho_pi[0][53];
		lane_pi_kai_n[0][54] = lane_rho_pi[0][54];
		lane_pi_kai_n[0][55] = lane_rho_pi[0][55];
		lane_pi_kai_n[0][56] = lane_rho_pi[0][56];
		lane_pi_kai_n[0][57] = lane_rho_pi[0][57];
		lane_pi_kai_n[0][58] = lane_rho_pi[0][58];
		lane_pi_kai_n[0][59] = lane_rho_pi[0][59];
		lane_pi_kai_n[0][60] = lane_rho_pi[0][60];
		lane_pi_kai_n[0][61] = lane_rho_pi[0][61];
		lane_pi_kai_n[0][62] = lane_rho_pi[0][62];
		lane_pi_kai_n[0][63] = lane_rho_pi[0][63];
		lane_pi_kai_n[5][0] = lane_rho_pi[3][0];
		lane_pi_kai_n[5][1] = lane_rho_pi[3][1];
		lane_pi_kai_n[5][2] = lane_rho_pi[3][2];
		lane_pi_kai_n[5][3] = lane_rho_pi[3][3];
		lane_pi_kai_n[5][4] = lane_rho_pi[3][4];
		lane_pi_kai_n[5][5] = lane_rho_pi[3][5];
		lane_pi_kai_n[5][6] = lane_rho_pi[3][6];
		lane_pi_kai_n[5][7] = lane_rho_pi[3][7];
		lane_pi_kai_n[5][8] = lane_rho_pi[3][8];
		lane_pi_kai_n[5][9] = lane_rho_pi[3][9];
		lane_pi_kai_n[5][10] = lane_rho_pi[3][10];
		lane_pi_kai_n[5][11] = lane_rho_pi[3][11];
		lane_pi_kai_n[5][12] = lane_rho_pi[3][12];
		lane_pi_kai_n[5][13] = lane_rho_pi[3][13];
		lane_pi_kai_n[5][14] = lane_rho_pi[3][14];
		lane_pi_kai_n[5][15] = lane_rho_pi[3][15];
		lane_pi_kai_n[5][16] = lane_rho_pi[3][16];
		lane_pi_kai_n[5][17] = lane_rho_pi[3][17];
		lane_pi_kai_n[5][18] = lane_rho_pi[3][18];
		lane_pi_kai_n[5][19] = lane_rho_pi[3][19];
		lane_pi_kai_n[5][20] = lane_rho_pi[3][20];
		lane_pi_kai_n[5][21] = lane_rho_pi[3][21];
		lane_pi_kai_n[5][22] = lane_rho_pi[3][22];
		lane_pi_kai_n[5][23] = lane_rho_pi[3][23];
		lane_pi_kai_n[5][24] = lane_rho_pi[3][24];
		lane_pi_kai_n[5][25] = lane_rho_pi[3][25];
		lane_pi_kai_n[5][26] = lane_rho_pi[3][26];
		lane_pi_kai_n[5][27] = lane_rho_pi[3][27];
		lane_pi_kai_n[5][28] = lane_rho_pi[3][28];
		lane_pi_kai_n[5][29] = lane_rho_pi[3][29];
		lane_pi_kai_n[5][30] = lane_rho_pi[3][30];
		lane_pi_kai_n[5][31] = lane_rho_pi[3][31];
		lane_pi_kai_n[5][32] = lane_rho_pi[3][32];
		lane_pi_kai_n[5][33] = lane_rho_pi[3][33];
		lane_pi_kai_n[5][34] = lane_rho_pi[3][34];
		lane_pi_kai_n[5][35] = lane_rho_pi[3][35];
		lane_pi_kai_n[5][36] = lane_rho_pi[3][36];
		lane_pi_kai_n[5][37] = lane_rho_pi[3][37];
		lane_pi_kai_n[5][38] = lane_rho_pi[3][38];
		lane_pi_kai_n[5][39] = lane_rho_pi[3][39];
		lane_pi_kai_n[5][40] = lane_rho_pi[3][40];
		lane_pi_kai_n[5][41] = lane_rho_pi[3][41];
		lane_pi_kai_n[5][42] = lane_rho_pi[3][42];
		lane_pi_kai_n[5][43] = lane_rho_pi[3][43];
		lane_pi_kai_n[5][44] = lane_rho_pi[3][44];
		lane_pi_kai_n[5][45] = lane_rho_pi[3][45];
		lane_pi_kai_n[5][46] = lane_rho_pi[3][46];
		lane_pi_kai_n[5][47] = lane_rho_pi[3][47];
		lane_pi_kai_n[5][48] = lane_rho_pi[3][48];
		lane_pi_kai_n[5][49] = lane_rho_pi[3][49];
		lane_pi_kai_n[5][50] = lane_rho_pi[3][50];
		lane_pi_kai_n[5][51] = lane_rho_pi[3][51];
		lane_pi_kai_n[5][52] = lane_rho_pi[3][52];
		lane_pi_kai_n[5][53] = lane_rho_pi[3][53];
		lane_pi_kai_n[5][54] = lane_rho_pi[3][54];
		lane_pi_kai_n[5][55] = lane_rho_pi[3][55];
		lane_pi_kai_n[5][56] = lane_rho_pi[3][56];
		lane_pi_kai_n[5][57] = lane_rho_pi[3][57];
		lane_pi_kai_n[5][58] = lane_rho_pi[3][58];
		lane_pi_kai_n[5][59] = lane_rho_pi[3][59];
		lane_pi_kai_n[5][60] = lane_rho_pi[3][60];
		lane_pi_kai_n[5][61] = lane_rho_pi[3][61];
		lane_pi_kai_n[5][62] = lane_rho_pi[3][62];
		lane_pi_kai_n[5][63] = lane_rho_pi[3][63];
		lane_pi_kai_n[10][0] = lane_rho_pi[1][0];
		lane_pi_kai_n[10][1] = lane_rho_pi[1][1];
		lane_pi_kai_n[10][2] = lane_rho_pi[1][2];
		lane_pi_kai_n[10][3] = lane_rho_pi[1][3];
		lane_pi_kai_n[10][4] = lane_rho_pi[1][4];
		lane_pi_kai_n[10][5] = lane_rho_pi[1][5];
		lane_pi_kai_n[10][6] = lane_rho_pi[1][6];
		lane_pi_kai_n[10][7] = lane_rho_pi[1][7];
		lane_pi_kai_n[10][8] = lane_rho_pi[1][8];
		lane_pi_kai_n[10][9] = lane_rho_pi[1][9];
		lane_pi_kai_n[10][10] = lane_rho_pi[1][10];
		lane_pi_kai_n[10][11] = lane_rho_pi[1][11];
		lane_pi_kai_n[10][12] = lane_rho_pi[1][12];
		lane_pi_kai_n[10][13] = lane_rho_pi[1][13];
		lane_pi_kai_n[10][14] = lane_rho_pi[1][14];
		lane_pi_kai_n[10][15] = lane_rho_pi[1][15];
		lane_pi_kai_n[10][16] = lane_rho_pi[1][16];
		lane_pi_kai_n[10][17] = lane_rho_pi[1][17];
		lane_pi_kai_n[10][18] = lane_rho_pi[1][18];
		lane_pi_kai_n[10][19] = lane_rho_pi[1][19];
		lane_pi_kai_n[10][20] = lane_rho_pi[1][20];
		lane_pi_kai_n[10][21] = lane_rho_pi[1][21];
		lane_pi_kai_n[10][22] = lane_rho_pi[1][22];
		lane_pi_kai_n[10][23] = lane_rho_pi[1][23];
		lane_pi_kai_n[10][24] = lane_rho_pi[1][24];
		lane_pi_kai_n[10][25] = lane_rho_pi[1][25];
		lane_pi_kai_n[10][26] = lane_rho_pi[1][26];
		lane_pi_kai_n[10][27] = lane_rho_pi[1][27];
		lane_pi_kai_n[10][28] = lane_rho_pi[1][28];
		lane_pi_kai_n[10][29] = lane_rho_pi[1][29];
		lane_pi_kai_n[10][30] = lane_rho_pi[1][30];
		lane_pi_kai_n[10][31] = lane_rho_pi[1][31];
		lane_pi_kai_n[10][32] = lane_rho_pi[1][32];
		lane_pi_kai_n[10][33] = lane_rho_pi[1][33];
		lane_pi_kai_n[10][34] = lane_rho_pi[1][34];
		lane_pi_kai_n[10][35] = lane_rho_pi[1][35];
		lane_pi_kai_n[10][36] = lane_rho_pi[1][36];
		lane_pi_kai_n[10][37] = lane_rho_pi[1][37];
		lane_pi_kai_n[10][38] = lane_rho_pi[1][38];
		lane_pi_kai_n[10][39] = lane_rho_pi[1][39];
		lane_pi_kai_n[10][40] = lane_rho_pi[1][40];
		lane_pi_kai_n[10][41] = lane_rho_pi[1][41];
		lane_pi_kai_n[10][42] = lane_rho_pi[1][42];
		lane_pi_kai_n[10][43] = lane_rho_pi[1][43];
		lane_pi_kai_n[10][44] = lane_rho_pi[1][44];
		lane_pi_kai_n[10][45] = lane_rho_pi[1][45];
		lane_pi_kai_n[10][46] = lane_rho_pi[1][46];
		lane_pi_kai_n[10][47] = lane_rho_pi[1][47];
		lane_pi_kai_n[10][48] = lane_rho_pi[1][48];
		lane_pi_kai_n[10][49] = lane_rho_pi[1][49];
		lane_pi_kai_n[10][50] = lane_rho_pi[1][50];
		lane_pi_kai_n[10][51] = lane_rho_pi[1][51];
		lane_pi_kai_n[10][52] = lane_rho_pi[1][52];
		lane_pi_kai_n[10][53] = lane_rho_pi[1][53];
		lane_pi_kai_n[10][54] = lane_rho_pi[1][54];
		lane_pi_kai_n[10][55] = lane_rho_pi[1][55];
		lane_pi_kai_n[10][56] = lane_rho_pi[1][56];
		lane_pi_kai_n[10][57] = lane_rho_pi[1][57];
		lane_pi_kai_n[10][58] = lane_rho_pi[1][58];
		lane_pi_kai_n[10][59] = lane_rho_pi[1][59];
		lane_pi_kai_n[10][60] = lane_rho_pi[1][60];
		lane_pi_kai_n[10][61] = lane_rho_pi[1][61];
		lane_pi_kai_n[10][62] = lane_rho_pi[1][62];
		lane_pi_kai_n[10][63] = lane_rho_pi[1][63];
		lane_pi_kai_n[15][0] = lane_rho_pi[4][0];
		lane_pi_kai_n[15][1] = lane_rho_pi[4][1];
		lane_pi_kai_n[15][2] = lane_rho_pi[4][2];
		lane_pi_kai_n[15][3] = lane_rho_pi[4][3];
		lane_pi_kai_n[15][4] = lane_rho_pi[4][4];
		lane_pi_kai_n[15][5] = lane_rho_pi[4][5];
		lane_pi_kai_n[15][6] = lane_rho_pi[4][6];
		lane_pi_kai_n[15][7] = lane_rho_pi[4][7];
		lane_pi_kai_n[15][8] = lane_rho_pi[4][8];
		lane_pi_kai_n[15][9] = lane_rho_pi[4][9];
		lane_pi_kai_n[15][10] = lane_rho_pi[4][10];
		lane_pi_kai_n[15][11] = lane_rho_pi[4][11];
		lane_pi_kai_n[15][12] = lane_rho_pi[4][12];
		lane_pi_kai_n[15][13] = lane_rho_pi[4][13];
		lane_pi_kai_n[15][14] = lane_rho_pi[4][14];
		lane_pi_kai_n[15][15] = lane_rho_pi[4][15];
		lane_pi_kai_n[15][16] = lane_rho_pi[4][16];
		lane_pi_kai_n[15][17] = lane_rho_pi[4][17];
		lane_pi_kai_n[15][18] = lane_rho_pi[4][18];
		lane_pi_kai_n[15][19] = lane_rho_pi[4][19];
		lane_pi_kai_n[15][20] = lane_rho_pi[4][20];
		lane_pi_kai_n[15][21] = lane_rho_pi[4][21];
		lane_pi_kai_n[15][22] = lane_rho_pi[4][22];
		lane_pi_kai_n[15][23] = lane_rho_pi[4][23];
		lane_pi_kai_n[15][24] = lane_rho_pi[4][24];
		lane_pi_kai_n[15][25] = lane_rho_pi[4][25];
		lane_pi_kai_n[15][26] = lane_rho_pi[4][26];
		lane_pi_kai_n[15][27] = lane_rho_pi[4][27];
		lane_pi_kai_n[15][28] = lane_rho_pi[4][28];
		lane_pi_kai_n[15][29] = lane_rho_pi[4][29];
		lane_pi_kai_n[15][30] = lane_rho_pi[4][30];
		lane_pi_kai_n[15][31] = lane_rho_pi[4][31];
		lane_pi_kai_n[15][32] = lane_rho_pi[4][32];
		lane_pi_kai_n[15][33] = lane_rho_pi[4][33];
		lane_pi_kai_n[15][34] = lane_rho_pi[4][34];
		lane_pi_kai_n[15][35] = lane_rho_pi[4][35];
		lane_pi_kai_n[15][36] = lane_rho_pi[4][36];
		lane_pi_kai_n[15][37] = lane_rho_pi[4][37];
		lane_pi_kai_n[15][38] = lane_rho_pi[4][38];
		lane_pi_kai_n[15][39] = lane_rho_pi[4][39];
		lane_pi_kai_n[15][40] = lane_rho_pi[4][40];
		lane_pi_kai_n[15][41] = lane_rho_pi[4][41];
		lane_pi_kai_n[15][42] = lane_rho_pi[4][42];
		lane_pi_kai_n[15][43] = lane_rho_pi[4][43];
		lane_pi_kai_n[15][44] = lane_rho_pi[4][44];
		lane_pi_kai_n[15][45] = lane_rho_pi[4][45];
		lane_pi_kai_n[15][46] = lane_rho_pi[4][46];
		lane_pi_kai_n[15][47] = lane_rho_pi[4][47];
		lane_pi_kai_n[15][48] = lane_rho_pi[4][48];
		lane_pi_kai_n[15][49] = lane_rho_pi[4][49];
		lane_pi_kai_n[15][50] = lane_rho_pi[4][50];
		lane_pi_kai_n[15][51] = lane_rho_pi[4][51];
		lane_pi_kai_n[15][52] = lane_rho_pi[4][52];
		lane_pi_kai_n[15][53] = lane_rho_pi[4][53];
		lane_pi_kai_n[15][54] = lane_rho_pi[4][54];
		lane_pi_kai_n[15][55] = lane_rho_pi[4][55];
		lane_pi_kai_n[15][56] = lane_rho_pi[4][56];
		lane_pi_kai_n[15][57] = lane_rho_pi[4][57];
		lane_pi_kai_n[15][58] = lane_rho_pi[4][58];
		lane_pi_kai_n[15][59] = lane_rho_pi[4][59];
		lane_pi_kai_n[15][60] = lane_rho_pi[4][60];
		lane_pi_kai_n[15][61] = lane_rho_pi[4][61];
		lane_pi_kai_n[15][62] = lane_rho_pi[4][62];
		lane_pi_kai_n[15][63] = lane_rho_pi[4][63];
		lane_pi_kai_n[20][0] = lane_rho_pi[2][0];
		lane_pi_kai_n[20][1] = lane_rho_pi[2][1];
		lane_pi_kai_n[20][2] = lane_rho_pi[2][2];
		lane_pi_kai_n[20][3] = lane_rho_pi[2][3];
		lane_pi_kai_n[20][4] = lane_rho_pi[2][4];
		lane_pi_kai_n[20][5] = lane_rho_pi[2][5];
		lane_pi_kai_n[20][6] = lane_rho_pi[2][6];
		lane_pi_kai_n[20][7] = lane_rho_pi[2][7];
		lane_pi_kai_n[20][8] = lane_rho_pi[2][8];
		lane_pi_kai_n[20][9] = lane_rho_pi[2][9];
		lane_pi_kai_n[20][10] = lane_rho_pi[2][10];
		lane_pi_kai_n[20][11] = lane_rho_pi[2][11];
		lane_pi_kai_n[20][12] = lane_rho_pi[2][12];
		lane_pi_kai_n[20][13] = lane_rho_pi[2][13];
		lane_pi_kai_n[20][14] = lane_rho_pi[2][14];
		lane_pi_kai_n[20][15] = lane_rho_pi[2][15];
		lane_pi_kai_n[20][16] = lane_rho_pi[2][16];
		lane_pi_kai_n[20][17] = lane_rho_pi[2][17];
		lane_pi_kai_n[20][18] = lane_rho_pi[2][18];
		lane_pi_kai_n[20][19] = lane_rho_pi[2][19];
		lane_pi_kai_n[20][20] = lane_rho_pi[2][20];
		lane_pi_kai_n[20][21] = lane_rho_pi[2][21];
		lane_pi_kai_n[20][22] = lane_rho_pi[2][22];
		lane_pi_kai_n[20][23] = lane_rho_pi[2][23];
		lane_pi_kai_n[20][24] = lane_rho_pi[2][24];
		lane_pi_kai_n[20][25] = lane_rho_pi[2][25];
		lane_pi_kai_n[20][26] = lane_rho_pi[2][26];
		lane_pi_kai_n[20][27] = lane_rho_pi[2][27];
		lane_pi_kai_n[20][28] = lane_rho_pi[2][28];
		lane_pi_kai_n[20][29] = lane_rho_pi[2][29];
		lane_pi_kai_n[20][30] = lane_rho_pi[2][30];
		lane_pi_kai_n[20][31] = lane_rho_pi[2][31];
		lane_pi_kai_n[20][32] = lane_rho_pi[2][32];
		lane_pi_kai_n[20][33] = lane_rho_pi[2][33];
		lane_pi_kai_n[20][34] = lane_rho_pi[2][34];
		lane_pi_kai_n[20][35] = lane_rho_pi[2][35];
		lane_pi_kai_n[20][36] = lane_rho_pi[2][36];
		lane_pi_kai_n[20][37] = lane_rho_pi[2][37];
		lane_pi_kai_n[20][38] = lane_rho_pi[2][38];
		lane_pi_kai_n[20][39] = lane_rho_pi[2][39];
		lane_pi_kai_n[20][40] = lane_rho_pi[2][40];
		lane_pi_kai_n[20][41] = lane_rho_pi[2][41];
		lane_pi_kai_n[20][42] = lane_rho_pi[2][42];
		lane_pi_kai_n[20][43] = lane_rho_pi[2][43];
		lane_pi_kai_n[20][44] = lane_rho_pi[2][44];
		lane_pi_kai_n[20][45] = lane_rho_pi[2][45];
		lane_pi_kai_n[20][46] = lane_rho_pi[2][46];
		lane_pi_kai_n[20][47] = lane_rho_pi[2][47];
		lane_pi_kai_n[20][48] = lane_rho_pi[2][48];
		lane_pi_kai_n[20][49] = lane_rho_pi[2][49];
		lane_pi_kai_n[20][50] = lane_rho_pi[2][50];
		lane_pi_kai_n[20][51] = lane_rho_pi[2][51];
		lane_pi_kai_n[20][52] = lane_rho_pi[2][52];
		lane_pi_kai_n[20][53] = lane_rho_pi[2][53];
		lane_pi_kai_n[20][54] = lane_rho_pi[2][54];
		lane_pi_kai_n[20][55] = lane_rho_pi[2][55];
		lane_pi_kai_n[20][56] = lane_rho_pi[2][56];
		lane_pi_kai_n[20][57] = lane_rho_pi[2][57];
		lane_pi_kai_n[20][58] = lane_rho_pi[2][58];
		lane_pi_kai_n[20][59] = lane_rho_pi[2][59];
		lane_pi_kai_n[20][60] = lane_rho_pi[2][60];
		lane_pi_kai_n[20][61] = lane_rho_pi[2][61];
		lane_pi_kai_n[20][62] = lane_rho_pi[2][62];
		lane_pi_kai_n[20][63] = lane_rho_pi[2][63];
		lane_pi_kai_n[1][0] = lane_rho_pi[6][0];
		lane_pi_kai_n[1][1] = lane_rho_pi[6][1];
		lane_pi_kai_n[1][2] = lane_rho_pi[6][2];
		lane_pi_kai_n[1][3] = lane_rho_pi[6][3];
		lane_pi_kai_n[1][4] = lane_rho_pi[6][4];
		lane_pi_kai_n[1][5] = lane_rho_pi[6][5];
		lane_pi_kai_n[1][6] = lane_rho_pi[6][6];
		lane_pi_kai_n[1][7] = lane_rho_pi[6][7];
		lane_pi_kai_n[1][8] = lane_rho_pi[6][8];
		lane_pi_kai_n[1][9] = lane_rho_pi[6][9];
		lane_pi_kai_n[1][10] = lane_rho_pi[6][10];
		lane_pi_kai_n[1][11] = lane_rho_pi[6][11];
		lane_pi_kai_n[1][12] = lane_rho_pi[6][12];
		lane_pi_kai_n[1][13] = lane_rho_pi[6][13];
		lane_pi_kai_n[1][14] = lane_rho_pi[6][14];
		lane_pi_kai_n[1][15] = lane_rho_pi[6][15];
		lane_pi_kai_n[1][16] = lane_rho_pi[6][16];
		lane_pi_kai_n[1][17] = lane_rho_pi[6][17];
		lane_pi_kai_n[1][18] = lane_rho_pi[6][18];
		lane_pi_kai_n[1][19] = lane_rho_pi[6][19];
		lane_pi_kai_n[1][20] = lane_rho_pi[6][20];
		lane_pi_kai_n[1][21] = lane_rho_pi[6][21];
		lane_pi_kai_n[1][22] = lane_rho_pi[6][22];
		lane_pi_kai_n[1][23] = lane_rho_pi[6][23];
		lane_pi_kai_n[1][24] = lane_rho_pi[6][24];
		lane_pi_kai_n[1][25] = lane_rho_pi[6][25];
		lane_pi_kai_n[1][26] = lane_rho_pi[6][26];
		lane_pi_kai_n[1][27] = lane_rho_pi[6][27];
		lane_pi_kai_n[1][28] = lane_rho_pi[6][28];
		lane_pi_kai_n[1][29] = lane_rho_pi[6][29];
		lane_pi_kai_n[1][30] = lane_rho_pi[6][30];
		lane_pi_kai_n[1][31] = lane_rho_pi[6][31];
		lane_pi_kai_n[1][32] = lane_rho_pi[6][32];
		lane_pi_kai_n[1][33] = lane_rho_pi[6][33];
		lane_pi_kai_n[1][34] = lane_rho_pi[6][34];
		lane_pi_kai_n[1][35] = lane_rho_pi[6][35];
		lane_pi_kai_n[1][36] = lane_rho_pi[6][36];
		lane_pi_kai_n[1][37] = lane_rho_pi[6][37];
		lane_pi_kai_n[1][38] = lane_rho_pi[6][38];
		lane_pi_kai_n[1][39] = lane_rho_pi[6][39];
		lane_pi_kai_n[1][40] = lane_rho_pi[6][40];
		lane_pi_kai_n[1][41] = lane_rho_pi[6][41];
		lane_pi_kai_n[1][42] = lane_rho_pi[6][42];
		lane_pi_kai_n[1][43] = lane_rho_pi[6][43];
		lane_pi_kai_n[1][44] = lane_rho_pi[6][44];
		lane_pi_kai_n[1][45] = lane_rho_pi[6][45];
		lane_pi_kai_n[1][46] = lane_rho_pi[6][46];
		lane_pi_kai_n[1][47] = lane_rho_pi[6][47];
		lane_pi_kai_n[1][48] = lane_rho_pi[6][48];
		lane_pi_kai_n[1][49] = lane_rho_pi[6][49];
		lane_pi_kai_n[1][50] = lane_rho_pi[6][50];
		lane_pi_kai_n[1][51] = lane_rho_pi[6][51];
		lane_pi_kai_n[1][52] = lane_rho_pi[6][52];
		lane_pi_kai_n[1][53] = lane_rho_pi[6][53];
		lane_pi_kai_n[1][54] = lane_rho_pi[6][54];
		lane_pi_kai_n[1][55] = lane_rho_pi[6][55];
		lane_pi_kai_n[1][56] = lane_rho_pi[6][56];
		lane_pi_kai_n[1][57] = lane_rho_pi[6][57];
		lane_pi_kai_n[1][58] = lane_rho_pi[6][58];
		lane_pi_kai_n[1][59] = lane_rho_pi[6][59];
		lane_pi_kai_n[1][60] = lane_rho_pi[6][60];
		lane_pi_kai_n[1][61] = lane_rho_pi[6][61];
		lane_pi_kai_n[1][62] = lane_rho_pi[6][62];
		lane_pi_kai_n[1][63] = lane_rho_pi[6][63];
		lane_pi_kai_n[6][0] = lane_rho_pi[9][0];
		lane_pi_kai_n[6][1] = lane_rho_pi[9][1];
		lane_pi_kai_n[6][2] = lane_rho_pi[9][2];
		lane_pi_kai_n[6][3] = lane_rho_pi[9][3];
		lane_pi_kai_n[6][4] = lane_rho_pi[9][4];
		lane_pi_kai_n[6][5] = lane_rho_pi[9][5];
		lane_pi_kai_n[6][6] = lane_rho_pi[9][6];
		lane_pi_kai_n[6][7] = lane_rho_pi[9][7];
		lane_pi_kai_n[6][8] = lane_rho_pi[9][8];
		lane_pi_kai_n[6][9] = lane_rho_pi[9][9];
		lane_pi_kai_n[6][10] = lane_rho_pi[9][10];
		lane_pi_kai_n[6][11] = lane_rho_pi[9][11];
		lane_pi_kai_n[6][12] = lane_rho_pi[9][12];
		lane_pi_kai_n[6][13] = lane_rho_pi[9][13];
		lane_pi_kai_n[6][14] = lane_rho_pi[9][14];
		lane_pi_kai_n[6][15] = lane_rho_pi[9][15];
		lane_pi_kai_n[6][16] = lane_rho_pi[9][16];
		lane_pi_kai_n[6][17] = lane_rho_pi[9][17];
		lane_pi_kai_n[6][18] = lane_rho_pi[9][18];
		lane_pi_kai_n[6][19] = lane_rho_pi[9][19];
		lane_pi_kai_n[6][20] = lane_rho_pi[9][20];
		lane_pi_kai_n[6][21] = lane_rho_pi[9][21];
		lane_pi_kai_n[6][22] = lane_rho_pi[9][22];
		lane_pi_kai_n[6][23] = lane_rho_pi[9][23];
		lane_pi_kai_n[6][24] = lane_rho_pi[9][24];
		lane_pi_kai_n[6][25] = lane_rho_pi[9][25];
		lane_pi_kai_n[6][26] = lane_rho_pi[9][26];
		lane_pi_kai_n[6][27] = lane_rho_pi[9][27];
		lane_pi_kai_n[6][28] = lane_rho_pi[9][28];
		lane_pi_kai_n[6][29] = lane_rho_pi[9][29];
		lane_pi_kai_n[6][30] = lane_rho_pi[9][30];
		lane_pi_kai_n[6][31] = lane_rho_pi[9][31];
		lane_pi_kai_n[6][32] = lane_rho_pi[9][32];
		lane_pi_kai_n[6][33] = lane_rho_pi[9][33];
		lane_pi_kai_n[6][34] = lane_rho_pi[9][34];
		lane_pi_kai_n[6][35] = lane_rho_pi[9][35];
		lane_pi_kai_n[6][36] = lane_rho_pi[9][36];
		lane_pi_kai_n[6][37] = lane_rho_pi[9][37];
		lane_pi_kai_n[6][38] = lane_rho_pi[9][38];
		lane_pi_kai_n[6][39] = lane_rho_pi[9][39];
		lane_pi_kai_n[6][40] = lane_rho_pi[9][40];
		lane_pi_kai_n[6][41] = lane_rho_pi[9][41];
		lane_pi_kai_n[6][42] = lane_rho_pi[9][42];
		lane_pi_kai_n[6][43] = lane_rho_pi[9][43];
		lane_pi_kai_n[6][44] = lane_rho_pi[9][44];
		lane_pi_kai_n[6][45] = lane_rho_pi[9][45];
		lane_pi_kai_n[6][46] = lane_rho_pi[9][46];
		lane_pi_kai_n[6][47] = lane_rho_pi[9][47];
		lane_pi_kai_n[6][48] = lane_rho_pi[9][48];
		lane_pi_kai_n[6][49] = lane_rho_pi[9][49];
		lane_pi_kai_n[6][50] = lane_rho_pi[9][50];
		lane_pi_kai_n[6][51] = lane_rho_pi[9][51];
		lane_pi_kai_n[6][52] = lane_rho_pi[9][52];
		lane_pi_kai_n[6][53] = lane_rho_pi[9][53];
		lane_pi_kai_n[6][54] = lane_rho_pi[9][54];
		lane_pi_kai_n[6][55] = lane_rho_pi[9][55];
		lane_pi_kai_n[6][56] = lane_rho_pi[9][56];
		lane_pi_kai_n[6][57] = lane_rho_pi[9][57];
		lane_pi_kai_n[6][58] = lane_rho_pi[9][58];
		lane_pi_kai_n[6][59] = lane_rho_pi[9][59];
		lane_pi_kai_n[6][60] = lane_rho_pi[9][60];
		lane_pi_kai_n[6][61] = lane_rho_pi[9][61];
		lane_pi_kai_n[6][62] = lane_rho_pi[9][62];
		lane_pi_kai_n[6][63] = lane_rho_pi[9][63];
		lane_pi_kai_n[11][0] = lane_rho_pi[7][0];
		lane_pi_kai_n[11][1] = lane_rho_pi[7][1];
		lane_pi_kai_n[11][2] = lane_rho_pi[7][2];
		lane_pi_kai_n[11][3] = lane_rho_pi[7][3];
		lane_pi_kai_n[11][4] = lane_rho_pi[7][4];
		lane_pi_kai_n[11][5] = lane_rho_pi[7][5];
		lane_pi_kai_n[11][6] = lane_rho_pi[7][6];
		lane_pi_kai_n[11][7] = lane_rho_pi[7][7];
		lane_pi_kai_n[11][8] = lane_rho_pi[7][8];
		lane_pi_kai_n[11][9] = lane_rho_pi[7][9];
		lane_pi_kai_n[11][10] = lane_rho_pi[7][10];
		lane_pi_kai_n[11][11] = lane_rho_pi[7][11];
		lane_pi_kai_n[11][12] = lane_rho_pi[7][12];
		lane_pi_kai_n[11][13] = lane_rho_pi[7][13];
		lane_pi_kai_n[11][14] = lane_rho_pi[7][14];
		lane_pi_kai_n[11][15] = lane_rho_pi[7][15];
		lane_pi_kai_n[11][16] = lane_rho_pi[7][16];
		lane_pi_kai_n[11][17] = lane_rho_pi[7][17];
		lane_pi_kai_n[11][18] = lane_rho_pi[7][18];
		lane_pi_kai_n[11][19] = lane_rho_pi[7][19];
		lane_pi_kai_n[11][20] = lane_rho_pi[7][20];
		lane_pi_kai_n[11][21] = lane_rho_pi[7][21];
		lane_pi_kai_n[11][22] = lane_rho_pi[7][22];
		lane_pi_kai_n[11][23] = lane_rho_pi[7][23];
		lane_pi_kai_n[11][24] = lane_rho_pi[7][24];
		lane_pi_kai_n[11][25] = lane_rho_pi[7][25];
		lane_pi_kai_n[11][26] = lane_rho_pi[7][26];
		lane_pi_kai_n[11][27] = lane_rho_pi[7][27];
		lane_pi_kai_n[11][28] = lane_rho_pi[7][28];
		lane_pi_kai_n[11][29] = lane_rho_pi[7][29];
		lane_pi_kai_n[11][30] = lane_rho_pi[7][30];
		lane_pi_kai_n[11][31] = lane_rho_pi[7][31];
		lane_pi_kai_n[11][32] = lane_rho_pi[7][32];
		lane_pi_kai_n[11][33] = lane_rho_pi[7][33];
		lane_pi_kai_n[11][34] = lane_rho_pi[7][34];
		lane_pi_kai_n[11][35] = lane_rho_pi[7][35];
		lane_pi_kai_n[11][36] = lane_rho_pi[7][36];
		lane_pi_kai_n[11][37] = lane_rho_pi[7][37];
		lane_pi_kai_n[11][38] = lane_rho_pi[7][38];
		lane_pi_kai_n[11][39] = lane_rho_pi[7][39];
		lane_pi_kai_n[11][40] = lane_rho_pi[7][40];
		lane_pi_kai_n[11][41] = lane_rho_pi[7][41];
		lane_pi_kai_n[11][42] = lane_rho_pi[7][42];
		lane_pi_kai_n[11][43] = lane_rho_pi[7][43];
		lane_pi_kai_n[11][44] = lane_rho_pi[7][44];
		lane_pi_kai_n[11][45] = lane_rho_pi[7][45];
		lane_pi_kai_n[11][46] = lane_rho_pi[7][46];
		lane_pi_kai_n[11][47] = lane_rho_pi[7][47];
		lane_pi_kai_n[11][48] = lane_rho_pi[7][48];
		lane_pi_kai_n[11][49] = lane_rho_pi[7][49];
		lane_pi_kai_n[11][50] = lane_rho_pi[7][50];
		lane_pi_kai_n[11][51] = lane_rho_pi[7][51];
		lane_pi_kai_n[11][52] = lane_rho_pi[7][52];
		lane_pi_kai_n[11][53] = lane_rho_pi[7][53];
		lane_pi_kai_n[11][54] = lane_rho_pi[7][54];
		lane_pi_kai_n[11][55] = lane_rho_pi[7][55];
		lane_pi_kai_n[11][56] = lane_rho_pi[7][56];
		lane_pi_kai_n[11][57] = lane_rho_pi[7][57];
		lane_pi_kai_n[11][58] = lane_rho_pi[7][58];
		lane_pi_kai_n[11][59] = lane_rho_pi[7][59];
		lane_pi_kai_n[11][60] = lane_rho_pi[7][60];
		lane_pi_kai_n[11][61] = lane_rho_pi[7][61];
		lane_pi_kai_n[11][62] = lane_rho_pi[7][62];
		lane_pi_kai_n[11][63] = lane_rho_pi[7][63];
		lane_pi_kai_n[16][0] = lane_rho_pi[5][0];
		lane_pi_kai_n[16][1] = lane_rho_pi[5][1];
		lane_pi_kai_n[16][2] = lane_rho_pi[5][2];
		lane_pi_kai_n[16][3] = lane_rho_pi[5][3];
		lane_pi_kai_n[16][4] = lane_rho_pi[5][4];
		lane_pi_kai_n[16][5] = lane_rho_pi[5][5];
		lane_pi_kai_n[16][6] = lane_rho_pi[5][6];
		lane_pi_kai_n[16][7] = lane_rho_pi[5][7];
		lane_pi_kai_n[16][8] = lane_rho_pi[5][8];
		lane_pi_kai_n[16][9] = lane_rho_pi[5][9];
		lane_pi_kai_n[16][10] = lane_rho_pi[5][10];
		lane_pi_kai_n[16][11] = lane_rho_pi[5][11];
		lane_pi_kai_n[16][12] = lane_rho_pi[5][12];
		lane_pi_kai_n[16][13] = lane_rho_pi[5][13];
		lane_pi_kai_n[16][14] = lane_rho_pi[5][14];
		lane_pi_kai_n[16][15] = lane_rho_pi[5][15];
		lane_pi_kai_n[16][16] = lane_rho_pi[5][16];
		lane_pi_kai_n[16][17] = lane_rho_pi[5][17];
		lane_pi_kai_n[16][18] = lane_rho_pi[5][18];
		lane_pi_kai_n[16][19] = lane_rho_pi[5][19];
		lane_pi_kai_n[16][20] = lane_rho_pi[5][20];
		lane_pi_kai_n[16][21] = lane_rho_pi[5][21];
		lane_pi_kai_n[16][22] = lane_rho_pi[5][22];
		lane_pi_kai_n[16][23] = lane_rho_pi[5][23];
		lane_pi_kai_n[16][24] = lane_rho_pi[5][24];
		lane_pi_kai_n[16][25] = lane_rho_pi[5][25];
		lane_pi_kai_n[16][26] = lane_rho_pi[5][26];
		lane_pi_kai_n[16][27] = lane_rho_pi[5][27];
		lane_pi_kai_n[16][28] = lane_rho_pi[5][28];
		lane_pi_kai_n[16][29] = lane_rho_pi[5][29];
		lane_pi_kai_n[16][30] = lane_rho_pi[5][30];
		lane_pi_kai_n[16][31] = lane_rho_pi[5][31];
		lane_pi_kai_n[16][32] = lane_rho_pi[5][32];
		lane_pi_kai_n[16][33] = lane_rho_pi[5][33];
		lane_pi_kai_n[16][34] = lane_rho_pi[5][34];
		lane_pi_kai_n[16][35] = lane_rho_pi[5][35];
		lane_pi_kai_n[16][36] = lane_rho_pi[5][36];
		lane_pi_kai_n[16][37] = lane_rho_pi[5][37];
		lane_pi_kai_n[16][38] = lane_rho_pi[5][38];
		lane_pi_kai_n[16][39] = lane_rho_pi[5][39];
		lane_pi_kai_n[16][40] = lane_rho_pi[5][40];
		lane_pi_kai_n[16][41] = lane_rho_pi[5][41];
		lane_pi_kai_n[16][42] = lane_rho_pi[5][42];
		lane_pi_kai_n[16][43] = lane_rho_pi[5][43];
		lane_pi_kai_n[16][44] = lane_rho_pi[5][44];
		lane_pi_kai_n[16][45] = lane_rho_pi[5][45];
		lane_pi_kai_n[16][46] = lane_rho_pi[5][46];
		lane_pi_kai_n[16][47] = lane_rho_pi[5][47];
		lane_pi_kai_n[16][48] = lane_rho_pi[5][48];
		lane_pi_kai_n[16][49] = lane_rho_pi[5][49];
		lane_pi_kai_n[16][50] = lane_rho_pi[5][50];
		lane_pi_kai_n[16][51] = lane_rho_pi[5][51];
		lane_pi_kai_n[16][52] = lane_rho_pi[5][52];
		lane_pi_kai_n[16][53] = lane_rho_pi[5][53];
		lane_pi_kai_n[16][54] = lane_rho_pi[5][54];
		lane_pi_kai_n[16][55] = lane_rho_pi[5][55];
		lane_pi_kai_n[16][56] = lane_rho_pi[5][56];
		lane_pi_kai_n[16][57] = lane_rho_pi[5][57];
		lane_pi_kai_n[16][58] = lane_rho_pi[5][58];
		lane_pi_kai_n[16][59] = lane_rho_pi[5][59];
		lane_pi_kai_n[16][60] = lane_rho_pi[5][60];
		lane_pi_kai_n[16][61] = lane_rho_pi[5][61];
		lane_pi_kai_n[16][62] = lane_rho_pi[5][62];
		lane_pi_kai_n[16][63] = lane_rho_pi[5][63];
		lane_pi_kai_n[21][0] = lane_rho_pi[8][0];
		lane_pi_kai_n[21][1] = lane_rho_pi[8][1];
		lane_pi_kai_n[21][2] = lane_rho_pi[8][2];
		lane_pi_kai_n[21][3] = lane_rho_pi[8][3];
		lane_pi_kai_n[21][4] = lane_rho_pi[8][4];
		lane_pi_kai_n[21][5] = lane_rho_pi[8][5];
		lane_pi_kai_n[21][6] = lane_rho_pi[8][6];
		lane_pi_kai_n[21][7] = lane_rho_pi[8][7];
		lane_pi_kai_n[21][8] = lane_rho_pi[8][8];
		lane_pi_kai_n[21][9] = lane_rho_pi[8][9];
		lane_pi_kai_n[21][10] = lane_rho_pi[8][10];
		lane_pi_kai_n[21][11] = lane_rho_pi[8][11];
		lane_pi_kai_n[21][12] = lane_rho_pi[8][12];
		lane_pi_kai_n[21][13] = lane_rho_pi[8][13];
		lane_pi_kai_n[21][14] = lane_rho_pi[8][14];
		lane_pi_kai_n[21][15] = lane_rho_pi[8][15];
		lane_pi_kai_n[21][16] = lane_rho_pi[8][16];
		lane_pi_kai_n[21][17] = lane_rho_pi[8][17];
		lane_pi_kai_n[21][18] = lane_rho_pi[8][18];
		lane_pi_kai_n[21][19] = lane_rho_pi[8][19];
		lane_pi_kai_n[21][20] = lane_rho_pi[8][20];
		lane_pi_kai_n[21][21] = lane_rho_pi[8][21];
		lane_pi_kai_n[21][22] = lane_rho_pi[8][22];
		lane_pi_kai_n[21][23] = lane_rho_pi[8][23];
		lane_pi_kai_n[21][24] = lane_rho_pi[8][24];
		lane_pi_kai_n[21][25] = lane_rho_pi[8][25];
		lane_pi_kai_n[21][26] = lane_rho_pi[8][26];
		lane_pi_kai_n[21][27] = lane_rho_pi[8][27];
		lane_pi_kai_n[21][28] = lane_rho_pi[8][28];
		lane_pi_kai_n[21][29] = lane_rho_pi[8][29];
		lane_pi_kai_n[21][30] = lane_rho_pi[8][30];
		lane_pi_kai_n[21][31] = lane_rho_pi[8][31];
		lane_pi_kai_n[21][32] = lane_rho_pi[8][32];
		lane_pi_kai_n[21][33] = lane_rho_pi[8][33];
		lane_pi_kai_n[21][34] = lane_rho_pi[8][34];
		lane_pi_kai_n[21][35] = lane_rho_pi[8][35];
		lane_pi_kai_n[21][36] = lane_rho_pi[8][36];
		lane_pi_kai_n[21][37] = lane_rho_pi[8][37];
		lane_pi_kai_n[21][38] = lane_rho_pi[8][38];
		lane_pi_kai_n[21][39] = lane_rho_pi[8][39];
		lane_pi_kai_n[21][40] = lane_rho_pi[8][40];
		lane_pi_kai_n[21][41] = lane_rho_pi[8][41];
		lane_pi_kai_n[21][42] = lane_rho_pi[8][42];
		lane_pi_kai_n[21][43] = lane_rho_pi[8][43];
		lane_pi_kai_n[21][44] = lane_rho_pi[8][44];
		lane_pi_kai_n[21][45] = lane_rho_pi[8][45];
		lane_pi_kai_n[21][46] = lane_rho_pi[8][46];
		lane_pi_kai_n[21][47] = lane_rho_pi[8][47];
		lane_pi_kai_n[21][48] = lane_rho_pi[8][48];
		lane_pi_kai_n[21][49] = lane_rho_pi[8][49];
		lane_pi_kai_n[21][50] = lane_rho_pi[8][50];
		lane_pi_kai_n[21][51] = lane_rho_pi[8][51];
		lane_pi_kai_n[21][52] = lane_rho_pi[8][52];
		lane_pi_kai_n[21][53] = lane_rho_pi[8][53];
		lane_pi_kai_n[21][54] = lane_rho_pi[8][54];
		lane_pi_kai_n[21][55] = lane_rho_pi[8][55];
		lane_pi_kai_n[21][56] = lane_rho_pi[8][56];
		lane_pi_kai_n[21][57] = lane_rho_pi[8][57];
		lane_pi_kai_n[21][58] = lane_rho_pi[8][58];
		lane_pi_kai_n[21][59] = lane_rho_pi[8][59];
		lane_pi_kai_n[21][60] = lane_rho_pi[8][60];
		lane_pi_kai_n[21][61] = lane_rho_pi[8][61];
		lane_pi_kai_n[21][62] = lane_rho_pi[8][62];
		lane_pi_kai_n[21][63] = lane_rho_pi[8][63];
		lane_pi_kai_n[2][0] = lane_rho_pi[12][0];
		lane_pi_kai_n[2][1] = lane_rho_pi[12][1];
		lane_pi_kai_n[2][2] = lane_rho_pi[12][2];
		lane_pi_kai_n[2][3] = lane_rho_pi[12][3];
		lane_pi_kai_n[2][4] = lane_rho_pi[12][4];
		lane_pi_kai_n[2][5] = lane_rho_pi[12][5];
		lane_pi_kai_n[2][6] = lane_rho_pi[12][6];
		lane_pi_kai_n[2][7] = lane_rho_pi[12][7];
		lane_pi_kai_n[2][8] = lane_rho_pi[12][8];
		lane_pi_kai_n[2][9] = lane_rho_pi[12][9];
		lane_pi_kai_n[2][10] = lane_rho_pi[12][10];
		lane_pi_kai_n[2][11] = lane_rho_pi[12][11];
		lane_pi_kai_n[2][12] = lane_rho_pi[12][12];
		lane_pi_kai_n[2][13] = lane_rho_pi[12][13];
		lane_pi_kai_n[2][14] = lane_rho_pi[12][14];
		lane_pi_kai_n[2][15] = lane_rho_pi[12][15];
		lane_pi_kai_n[2][16] = lane_rho_pi[12][16];
		lane_pi_kai_n[2][17] = lane_rho_pi[12][17];
		lane_pi_kai_n[2][18] = lane_rho_pi[12][18];
		lane_pi_kai_n[2][19] = lane_rho_pi[12][19];
		lane_pi_kai_n[2][20] = lane_rho_pi[12][20];
		lane_pi_kai_n[2][21] = lane_rho_pi[12][21];
		lane_pi_kai_n[2][22] = lane_rho_pi[12][22];
		lane_pi_kai_n[2][23] = lane_rho_pi[12][23];
		lane_pi_kai_n[2][24] = lane_rho_pi[12][24];
		lane_pi_kai_n[2][25] = lane_rho_pi[12][25];
		lane_pi_kai_n[2][26] = lane_rho_pi[12][26];
		lane_pi_kai_n[2][27] = lane_rho_pi[12][27];
		lane_pi_kai_n[2][28] = lane_rho_pi[12][28];
		lane_pi_kai_n[2][29] = lane_rho_pi[12][29];
		lane_pi_kai_n[2][30] = lane_rho_pi[12][30];
		lane_pi_kai_n[2][31] = lane_rho_pi[12][31];
		lane_pi_kai_n[2][32] = lane_rho_pi[12][32];
		lane_pi_kai_n[2][33] = lane_rho_pi[12][33];
		lane_pi_kai_n[2][34] = lane_rho_pi[12][34];
		lane_pi_kai_n[2][35] = lane_rho_pi[12][35];
		lane_pi_kai_n[2][36] = lane_rho_pi[12][36];
		lane_pi_kai_n[2][37] = lane_rho_pi[12][37];
		lane_pi_kai_n[2][38] = lane_rho_pi[12][38];
		lane_pi_kai_n[2][39] = lane_rho_pi[12][39];
		lane_pi_kai_n[2][40] = lane_rho_pi[12][40];
		lane_pi_kai_n[2][41] = lane_rho_pi[12][41];
		lane_pi_kai_n[2][42] = lane_rho_pi[12][42];
		lane_pi_kai_n[2][43] = lane_rho_pi[12][43];
		lane_pi_kai_n[2][44] = lane_rho_pi[12][44];
		lane_pi_kai_n[2][45] = lane_rho_pi[12][45];
		lane_pi_kai_n[2][46] = lane_rho_pi[12][46];
		lane_pi_kai_n[2][47] = lane_rho_pi[12][47];
		lane_pi_kai_n[2][48] = lane_rho_pi[12][48];
		lane_pi_kai_n[2][49] = lane_rho_pi[12][49];
		lane_pi_kai_n[2][50] = lane_rho_pi[12][50];
		lane_pi_kai_n[2][51] = lane_rho_pi[12][51];
		lane_pi_kai_n[2][52] = lane_rho_pi[12][52];
		lane_pi_kai_n[2][53] = lane_rho_pi[12][53];
		lane_pi_kai_n[2][54] = lane_rho_pi[12][54];
		lane_pi_kai_n[2][55] = lane_rho_pi[12][55];
		lane_pi_kai_n[2][56] = lane_rho_pi[12][56];
		lane_pi_kai_n[2][57] = lane_rho_pi[12][57];
		lane_pi_kai_n[2][58] = lane_rho_pi[12][58];
		lane_pi_kai_n[2][59] = lane_rho_pi[12][59];
		lane_pi_kai_n[2][60] = lane_rho_pi[12][60];
		lane_pi_kai_n[2][61] = lane_rho_pi[12][61];
		lane_pi_kai_n[2][62] = lane_rho_pi[12][62];
		lane_pi_kai_n[2][63] = lane_rho_pi[12][63];
		lane_pi_kai_n[7][0] = lane_rho_pi[10][0];
		lane_pi_kai_n[7][1] = lane_rho_pi[10][1];
		lane_pi_kai_n[7][2] = lane_rho_pi[10][2];
		lane_pi_kai_n[7][3] = lane_rho_pi[10][3];
		lane_pi_kai_n[7][4] = lane_rho_pi[10][4];
		lane_pi_kai_n[7][5] = lane_rho_pi[10][5];
		lane_pi_kai_n[7][6] = lane_rho_pi[10][6];
		lane_pi_kai_n[7][7] = lane_rho_pi[10][7];
		lane_pi_kai_n[7][8] = lane_rho_pi[10][8];
		lane_pi_kai_n[7][9] = lane_rho_pi[10][9];
		lane_pi_kai_n[7][10] = lane_rho_pi[10][10];
		lane_pi_kai_n[7][11] = lane_rho_pi[10][11];
		lane_pi_kai_n[7][12] = lane_rho_pi[10][12];
		lane_pi_kai_n[7][13] = lane_rho_pi[10][13];
		lane_pi_kai_n[7][14] = lane_rho_pi[10][14];
		lane_pi_kai_n[7][15] = lane_rho_pi[10][15];
		lane_pi_kai_n[7][16] = lane_rho_pi[10][16];
		lane_pi_kai_n[7][17] = lane_rho_pi[10][17];
		lane_pi_kai_n[7][18] = lane_rho_pi[10][18];
		lane_pi_kai_n[7][19] = lane_rho_pi[10][19];
		lane_pi_kai_n[7][20] = lane_rho_pi[10][20];
		lane_pi_kai_n[7][21] = lane_rho_pi[10][21];
		lane_pi_kai_n[7][22] = lane_rho_pi[10][22];
		lane_pi_kai_n[7][23] = lane_rho_pi[10][23];
		lane_pi_kai_n[7][24] = lane_rho_pi[10][24];
		lane_pi_kai_n[7][25] = lane_rho_pi[10][25];
		lane_pi_kai_n[7][26] = lane_rho_pi[10][26];
		lane_pi_kai_n[7][27] = lane_rho_pi[10][27];
		lane_pi_kai_n[7][28] = lane_rho_pi[10][28];
		lane_pi_kai_n[7][29] = lane_rho_pi[10][29];
		lane_pi_kai_n[7][30] = lane_rho_pi[10][30];
		lane_pi_kai_n[7][31] = lane_rho_pi[10][31];
		lane_pi_kai_n[7][32] = lane_rho_pi[10][32];
		lane_pi_kai_n[7][33] = lane_rho_pi[10][33];
		lane_pi_kai_n[7][34] = lane_rho_pi[10][34];
		lane_pi_kai_n[7][35] = lane_rho_pi[10][35];
		lane_pi_kai_n[7][36] = lane_rho_pi[10][36];
		lane_pi_kai_n[7][37] = lane_rho_pi[10][37];
		lane_pi_kai_n[7][38] = lane_rho_pi[10][38];
		lane_pi_kai_n[7][39] = lane_rho_pi[10][39];
		lane_pi_kai_n[7][40] = lane_rho_pi[10][40];
		lane_pi_kai_n[7][41] = lane_rho_pi[10][41];
		lane_pi_kai_n[7][42] = lane_rho_pi[10][42];
		lane_pi_kai_n[7][43] = lane_rho_pi[10][43];
		lane_pi_kai_n[7][44] = lane_rho_pi[10][44];
		lane_pi_kai_n[7][45] = lane_rho_pi[10][45];
		lane_pi_kai_n[7][46] = lane_rho_pi[10][46];
		lane_pi_kai_n[7][47] = lane_rho_pi[10][47];
		lane_pi_kai_n[7][48] = lane_rho_pi[10][48];
		lane_pi_kai_n[7][49] = lane_rho_pi[10][49];
		lane_pi_kai_n[7][50] = lane_rho_pi[10][50];
		lane_pi_kai_n[7][51] = lane_rho_pi[10][51];
		lane_pi_kai_n[7][52] = lane_rho_pi[10][52];
		lane_pi_kai_n[7][53] = lane_rho_pi[10][53];
		lane_pi_kai_n[7][54] = lane_rho_pi[10][54];
		lane_pi_kai_n[7][55] = lane_rho_pi[10][55];
		lane_pi_kai_n[7][56] = lane_rho_pi[10][56];
		lane_pi_kai_n[7][57] = lane_rho_pi[10][57];
		lane_pi_kai_n[7][58] = lane_rho_pi[10][58];
		lane_pi_kai_n[7][59] = lane_rho_pi[10][59];
		lane_pi_kai_n[7][60] = lane_rho_pi[10][60];
		lane_pi_kai_n[7][61] = lane_rho_pi[10][61];
		lane_pi_kai_n[7][62] = lane_rho_pi[10][62];
		lane_pi_kai_n[7][63] = lane_rho_pi[10][63];
		lane_pi_kai_n[12][0] = lane_rho_pi[13][0];
		lane_pi_kai_n[12][1] = lane_rho_pi[13][1];
		lane_pi_kai_n[12][2] = lane_rho_pi[13][2];
		lane_pi_kai_n[12][3] = lane_rho_pi[13][3];
		lane_pi_kai_n[12][4] = lane_rho_pi[13][4];
		lane_pi_kai_n[12][5] = lane_rho_pi[13][5];
		lane_pi_kai_n[12][6] = lane_rho_pi[13][6];
		lane_pi_kai_n[12][7] = lane_rho_pi[13][7];
		lane_pi_kai_n[12][8] = lane_rho_pi[13][8];
		lane_pi_kai_n[12][9] = lane_rho_pi[13][9];
		lane_pi_kai_n[12][10] = lane_rho_pi[13][10];
		lane_pi_kai_n[12][11] = lane_rho_pi[13][11];
		lane_pi_kai_n[12][12] = lane_rho_pi[13][12];
		lane_pi_kai_n[12][13] = lane_rho_pi[13][13];
		lane_pi_kai_n[12][14] = lane_rho_pi[13][14];
		lane_pi_kai_n[12][15] = lane_rho_pi[13][15];
		lane_pi_kai_n[12][16] = lane_rho_pi[13][16];
		lane_pi_kai_n[12][17] = lane_rho_pi[13][17];
		lane_pi_kai_n[12][18] = lane_rho_pi[13][18];
		lane_pi_kai_n[12][19] = lane_rho_pi[13][19];
		lane_pi_kai_n[12][20] = lane_rho_pi[13][20];
		lane_pi_kai_n[12][21] = lane_rho_pi[13][21];
		lane_pi_kai_n[12][22] = lane_rho_pi[13][22];
		lane_pi_kai_n[12][23] = lane_rho_pi[13][23];
		lane_pi_kai_n[12][24] = lane_rho_pi[13][24];
		lane_pi_kai_n[12][25] = lane_rho_pi[13][25];
		lane_pi_kai_n[12][26] = lane_rho_pi[13][26];
		lane_pi_kai_n[12][27] = lane_rho_pi[13][27];
		lane_pi_kai_n[12][28] = lane_rho_pi[13][28];
		lane_pi_kai_n[12][29] = lane_rho_pi[13][29];
		lane_pi_kai_n[12][30] = lane_rho_pi[13][30];
		lane_pi_kai_n[12][31] = lane_rho_pi[13][31];
		lane_pi_kai_n[12][32] = lane_rho_pi[13][32];
		lane_pi_kai_n[12][33] = lane_rho_pi[13][33];
		lane_pi_kai_n[12][34] = lane_rho_pi[13][34];
		lane_pi_kai_n[12][35] = lane_rho_pi[13][35];
		lane_pi_kai_n[12][36] = lane_rho_pi[13][36];
		lane_pi_kai_n[12][37] = lane_rho_pi[13][37];
		lane_pi_kai_n[12][38] = lane_rho_pi[13][38];
		lane_pi_kai_n[12][39] = lane_rho_pi[13][39];
		lane_pi_kai_n[12][40] = lane_rho_pi[13][40];
		lane_pi_kai_n[12][41] = lane_rho_pi[13][41];
		lane_pi_kai_n[12][42] = lane_rho_pi[13][42];
		lane_pi_kai_n[12][43] = lane_rho_pi[13][43];
		lane_pi_kai_n[12][44] = lane_rho_pi[13][44];
		lane_pi_kai_n[12][45] = lane_rho_pi[13][45];
		lane_pi_kai_n[12][46] = lane_rho_pi[13][46];
		lane_pi_kai_n[12][47] = lane_rho_pi[13][47];
		lane_pi_kai_n[12][48] = lane_rho_pi[13][48];
		lane_pi_kai_n[12][49] = lane_rho_pi[13][49];
		lane_pi_kai_n[12][50] = lane_rho_pi[13][50];
		lane_pi_kai_n[12][51] = lane_rho_pi[13][51];
		lane_pi_kai_n[12][52] = lane_rho_pi[13][52];
		lane_pi_kai_n[12][53] = lane_rho_pi[13][53];
		lane_pi_kai_n[12][54] = lane_rho_pi[13][54];
		lane_pi_kai_n[12][55] = lane_rho_pi[13][55];
		lane_pi_kai_n[12][56] = lane_rho_pi[13][56];
		lane_pi_kai_n[12][57] = lane_rho_pi[13][57];
		lane_pi_kai_n[12][58] = lane_rho_pi[13][58];
		lane_pi_kai_n[12][59] = lane_rho_pi[13][59];
		lane_pi_kai_n[12][60] = lane_rho_pi[13][60];
		lane_pi_kai_n[12][61] = lane_rho_pi[13][61];
		lane_pi_kai_n[12][62] = lane_rho_pi[13][62];
		lane_pi_kai_n[12][63] = lane_rho_pi[13][63];
		lane_pi_kai_n[17][0] = lane_rho_pi[11][0];
		lane_pi_kai_n[17][1] = lane_rho_pi[11][1];
		lane_pi_kai_n[17][2] = lane_rho_pi[11][2];
		lane_pi_kai_n[17][3] = lane_rho_pi[11][3];
		lane_pi_kai_n[17][4] = lane_rho_pi[11][4];
		lane_pi_kai_n[17][5] = lane_rho_pi[11][5];
		lane_pi_kai_n[17][6] = lane_rho_pi[11][6];
		lane_pi_kai_n[17][7] = lane_rho_pi[11][7];
		lane_pi_kai_n[17][8] = lane_rho_pi[11][8];
		lane_pi_kai_n[17][9] = lane_rho_pi[11][9];
		lane_pi_kai_n[17][10] = lane_rho_pi[11][10];
		lane_pi_kai_n[17][11] = lane_rho_pi[11][11];
		lane_pi_kai_n[17][12] = lane_rho_pi[11][12];
		lane_pi_kai_n[17][13] = lane_rho_pi[11][13];
		lane_pi_kai_n[17][14] = lane_rho_pi[11][14];
		lane_pi_kai_n[17][15] = lane_rho_pi[11][15];
		lane_pi_kai_n[17][16] = lane_rho_pi[11][16];
		lane_pi_kai_n[17][17] = lane_rho_pi[11][17];
		lane_pi_kai_n[17][18] = lane_rho_pi[11][18];
		lane_pi_kai_n[17][19] = lane_rho_pi[11][19];
		lane_pi_kai_n[17][20] = lane_rho_pi[11][20];
		lane_pi_kai_n[17][21] = lane_rho_pi[11][21];
		lane_pi_kai_n[17][22] = lane_rho_pi[11][22];
		lane_pi_kai_n[17][23] = lane_rho_pi[11][23];
		lane_pi_kai_n[17][24] = lane_rho_pi[11][24];
		lane_pi_kai_n[17][25] = lane_rho_pi[11][25];
		lane_pi_kai_n[17][26] = lane_rho_pi[11][26];
		lane_pi_kai_n[17][27] = lane_rho_pi[11][27];
		lane_pi_kai_n[17][28] = lane_rho_pi[11][28];
		lane_pi_kai_n[17][29] = lane_rho_pi[11][29];
		lane_pi_kai_n[17][30] = lane_rho_pi[11][30];
		lane_pi_kai_n[17][31] = lane_rho_pi[11][31];
		lane_pi_kai_n[17][32] = lane_rho_pi[11][32];
		lane_pi_kai_n[17][33] = lane_rho_pi[11][33];
		lane_pi_kai_n[17][34] = lane_rho_pi[11][34];
		lane_pi_kai_n[17][35] = lane_rho_pi[11][35];
		lane_pi_kai_n[17][36] = lane_rho_pi[11][36];
		lane_pi_kai_n[17][37] = lane_rho_pi[11][37];
		lane_pi_kai_n[17][38] = lane_rho_pi[11][38];
		lane_pi_kai_n[17][39] = lane_rho_pi[11][39];
		lane_pi_kai_n[17][40] = lane_rho_pi[11][40];
		lane_pi_kai_n[17][41] = lane_rho_pi[11][41];
		lane_pi_kai_n[17][42] = lane_rho_pi[11][42];
		lane_pi_kai_n[17][43] = lane_rho_pi[11][43];
		lane_pi_kai_n[17][44] = lane_rho_pi[11][44];
		lane_pi_kai_n[17][45] = lane_rho_pi[11][45];
		lane_pi_kai_n[17][46] = lane_rho_pi[11][46];
		lane_pi_kai_n[17][47] = lane_rho_pi[11][47];
		lane_pi_kai_n[17][48] = lane_rho_pi[11][48];
		lane_pi_kai_n[17][49] = lane_rho_pi[11][49];
		lane_pi_kai_n[17][50] = lane_rho_pi[11][50];
		lane_pi_kai_n[17][51] = lane_rho_pi[11][51];
		lane_pi_kai_n[17][52] = lane_rho_pi[11][52];
		lane_pi_kai_n[17][53] = lane_rho_pi[11][53];
		lane_pi_kai_n[17][54] = lane_rho_pi[11][54];
		lane_pi_kai_n[17][55] = lane_rho_pi[11][55];
		lane_pi_kai_n[17][56] = lane_rho_pi[11][56];
		lane_pi_kai_n[17][57] = lane_rho_pi[11][57];
		lane_pi_kai_n[17][58] = lane_rho_pi[11][58];
		lane_pi_kai_n[17][59] = lane_rho_pi[11][59];
		lane_pi_kai_n[17][60] = lane_rho_pi[11][60];
		lane_pi_kai_n[17][61] = lane_rho_pi[11][61];
		lane_pi_kai_n[17][62] = lane_rho_pi[11][62];
		lane_pi_kai_n[17][63] = lane_rho_pi[11][63];
		lane_pi_kai_n[22][0] = lane_rho_pi[14][0];
		lane_pi_kai_n[22][1] = lane_rho_pi[14][1];
		lane_pi_kai_n[22][2] = lane_rho_pi[14][2];
		lane_pi_kai_n[22][3] = lane_rho_pi[14][3];
		lane_pi_kai_n[22][4] = lane_rho_pi[14][4];
		lane_pi_kai_n[22][5] = lane_rho_pi[14][5];
		lane_pi_kai_n[22][6] = lane_rho_pi[14][6];
		lane_pi_kai_n[22][7] = lane_rho_pi[14][7];
		lane_pi_kai_n[22][8] = lane_rho_pi[14][8];
		lane_pi_kai_n[22][9] = lane_rho_pi[14][9];
		lane_pi_kai_n[22][10] = lane_rho_pi[14][10];
		lane_pi_kai_n[22][11] = lane_rho_pi[14][11];
		lane_pi_kai_n[22][12] = lane_rho_pi[14][12];
		lane_pi_kai_n[22][13] = lane_rho_pi[14][13];
		lane_pi_kai_n[22][14] = lane_rho_pi[14][14];
		lane_pi_kai_n[22][15] = lane_rho_pi[14][15];
		lane_pi_kai_n[22][16] = lane_rho_pi[14][16];
		lane_pi_kai_n[22][17] = lane_rho_pi[14][17];
		lane_pi_kai_n[22][18] = lane_rho_pi[14][18];
		lane_pi_kai_n[22][19] = lane_rho_pi[14][19];
		lane_pi_kai_n[22][20] = lane_rho_pi[14][20];
		lane_pi_kai_n[22][21] = lane_rho_pi[14][21];
		lane_pi_kai_n[22][22] = lane_rho_pi[14][22];
		lane_pi_kai_n[22][23] = lane_rho_pi[14][23];
		lane_pi_kai_n[22][24] = lane_rho_pi[14][24];
		lane_pi_kai_n[22][25] = lane_rho_pi[14][25];
		lane_pi_kai_n[22][26] = lane_rho_pi[14][26];
		lane_pi_kai_n[22][27] = lane_rho_pi[14][27];
		lane_pi_kai_n[22][28] = lane_rho_pi[14][28];
		lane_pi_kai_n[22][29] = lane_rho_pi[14][29];
		lane_pi_kai_n[22][30] = lane_rho_pi[14][30];
		lane_pi_kai_n[22][31] = lane_rho_pi[14][31];
		lane_pi_kai_n[22][32] = lane_rho_pi[14][32];
		lane_pi_kai_n[22][33] = lane_rho_pi[14][33];
		lane_pi_kai_n[22][34] = lane_rho_pi[14][34];
		lane_pi_kai_n[22][35] = lane_rho_pi[14][35];
		lane_pi_kai_n[22][36] = lane_rho_pi[14][36];
		lane_pi_kai_n[22][37] = lane_rho_pi[14][37];
		lane_pi_kai_n[22][38] = lane_rho_pi[14][38];
		lane_pi_kai_n[22][39] = lane_rho_pi[14][39];
		lane_pi_kai_n[22][40] = lane_rho_pi[14][40];
		lane_pi_kai_n[22][41] = lane_rho_pi[14][41];
		lane_pi_kai_n[22][42] = lane_rho_pi[14][42];
		lane_pi_kai_n[22][43] = lane_rho_pi[14][43];
		lane_pi_kai_n[22][44] = lane_rho_pi[14][44];
		lane_pi_kai_n[22][45] = lane_rho_pi[14][45];
		lane_pi_kai_n[22][46] = lane_rho_pi[14][46];
		lane_pi_kai_n[22][47] = lane_rho_pi[14][47];
		lane_pi_kai_n[22][48] = lane_rho_pi[14][48];
		lane_pi_kai_n[22][49] = lane_rho_pi[14][49];
		lane_pi_kai_n[22][50] = lane_rho_pi[14][50];
		lane_pi_kai_n[22][51] = lane_rho_pi[14][51];
		lane_pi_kai_n[22][52] = lane_rho_pi[14][52];
		lane_pi_kai_n[22][53] = lane_rho_pi[14][53];
		lane_pi_kai_n[22][54] = lane_rho_pi[14][54];
		lane_pi_kai_n[22][55] = lane_rho_pi[14][55];
		lane_pi_kai_n[22][56] = lane_rho_pi[14][56];
		lane_pi_kai_n[22][57] = lane_rho_pi[14][57];
		lane_pi_kai_n[22][58] = lane_rho_pi[14][58];
		lane_pi_kai_n[22][59] = lane_rho_pi[14][59];
		lane_pi_kai_n[22][60] = lane_rho_pi[14][60];
		lane_pi_kai_n[22][61] = lane_rho_pi[14][61];
		lane_pi_kai_n[22][62] = lane_rho_pi[14][62];
		lane_pi_kai_n[22][63] = lane_rho_pi[14][63];
		lane_pi_kai_n[3][0] = lane_rho_pi[18][0];
		lane_pi_kai_n[3][1] = lane_rho_pi[18][1];
		lane_pi_kai_n[3][2] = lane_rho_pi[18][2];
		lane_pi_kai_n[3][3] = lane_rho_pi[18][3];
		lane_pi_kai_n[3][4] = lane_rho_pi[18][4];
		lane_pi_kai_n[3][5] = lane_rho_pi[18][5];
		lane_pi_kai_n[3][6] = lane_rho_pi[18][6];
		lane_pi_kai_n[3][7] = lane_rho_pi[18][7];
		lane_pi_kai_n[3][8] = lane_rho_pi[18][8];
		lane_pi_kai_n[3][9] = lane_rho_pi[18][9];
		lane_pi_kai_n[3][10] = lane_rho_pi[18][10];
		lane_pi_kai_n[3][11] = lane_rho_pi[18][11];
		lane_pi_kai_n[3][12] = lane_rho_pi[18][12];
		lane_pi_kai_n[3][13] = lane_rho_pi[18][13];
		lane_pi_kai_n[3][14] = lane_rho_pi[18][14];
		lane_pi_kai_n[3][15] = lane_rho_pi[18][15];
		lane_pi_kai_n[3][16] = lane_rho_pi[18][16];
		lane_pi_kai_n[3][17] = lane_rho_pi[18][17];
		lane_pi_kai_n[3][18] = lane_rho_pi[18][18];
		lane_pi_kai_n[3][19] = lane_rho_pi[18][19];
		lane_pi_kai_n[3][20] = lane_rho_pi[18][20];
		lane_pi_kai_n[3][21] = lane_rho_pi[18][21];
		lane_pi_kai_n[3][22] = lane_rho_pi[18][22];
		lane_pi_kai_n[3][23] = lane_rho_pi[18][23];
		lane_pi_kai_n[3][24] = lane_rho_pi[18][24];
		lane_pi_kai_n[3][25] = lane_rho_pi[18][25];
		lane_pi_kai_n[3][26] = lane_rho_pi[18][26];
		lane_pi_kai_n[3][27] = lane_rho_pi[18][27];
		lane_pi_kai_n[3][28] = lane_rho_pi[18][28];
		lane_pi_kai_n[3][29] = lane_rho_pi[18][29];
		lane_pi_kai_n[3][30] = lane_rho_pi[18][30];
		lane_pi_kai_n[3][31] = lane_rho_pi[18][31];
		lane_pi_kai_n[3][32] = lane_rho_pi[18][32];
		lane_pi_kai_n[3][33] = lane_rho_pi[18][33];
		lane_pi_kai_n[3][34] = lane_rho_pi[18][34];
		lane_pi_kai_n[3][35] = lane_rho_pi[18][35];
		lane_pi_kai_n[3][36] = lane_rho_pi[18][36];
		lane_pi_kai_n[3][37] = lane_rho_pi[18][37];
		lane_pi_kai_n[3][38] = lane_rho_pi[18][38];
		lane_pi_kai_n[3][39] = lane_rho_pi[18][39];
		lane_pi_kai_n[3][40] = lane_rho_pi[18][40];
		lane_pi_kai_n[3][41] = lane_rho_pi[18][41];
		lane_pi_kai_n[3][42] = lane_rho_pi[18][42];
		lane_pi_kai_n[3][43] = lane_rho_pi[18][43];
		lane_pi_kai_n[3][44] = lane_rho_pi[18][44];
		lane_pi_kai_n[3][45] = lane_rho_pi[18][45];
		lane_pi_kai_n[3][46] = lane_rho_pi[18][46];
		lane_pi_kai_n[3][47] = lane_rho_pi[18][47];
		lane_pi_kai_n[3][48] = lane_rho_pi[18][48];
		lane_pi_kai_n[3][49] = lane_rho_pi[18][49];
		lane_pi_kai_n[3][50] = lane_rho_pi[18][50];
		lane_pi_kai_n[3][51] = lane_rho_pi[18][51];
		lane_pi_kai_n[3][52] = lane_rho_pi[18][52];
		lane_pi_kai_n[3][53] = lane_rho_pi[18][53];
		lane_pi_kai_n[3][54] = lane_rho_pi[18][54];
		lane_pi_kai_n[3][55] = lane_rho_pi[18][55];
		lane_pi_kai_n[3][56] = lane_rho_pi[18][56];
		lane_pi_kai_n[3][57] = lane_rho_pi[18][57];
		lane_pi_kai_n[3][58] = lane_rho_pi[18][58];
		lane_pi_kai_n[3][59] = lane_rho_pi[18][59];
		lane_pi_kai_n[3][60] = lane_rho_pi[18][60];
		lane_pi_kai_n[3][61] = lane_rho_pi[18][61];
		lane_pi_kai_n[3][62] = lane_rho_pi[18][62];
		lane_pi_kai_n[3][63] = lane_rho_pi[18][63];
		lane_pi_kai_n[8][0] = lane_rho_pi[16][0];
		lane_pi_kai_n[8][1] = lane_rho_pi[16][1];
		lane_pi_kai_n[8][2] = lane_rho_pi[16][2];
		lane_pi_kai_n[8][3] = lane_rho_pi[16][3];
		lane_pi_kai_n[8][4] = lane_rho_pi[16][4];
		lane_pi_kai_n[8][5] = lane_rho_pi[16][5];
		lane_pi_kai_n[8][6] = lane_rho_pi[16][6];
		lane_pi_kai_n[8][7] = lane_rho_pi[16][7];
		lane_pi_kai_n[8][8] = lane_rho_pi[16][8];
		lane_pi_kai_n[8][9] = lane_rho_pi[16][9];
		lane_pi_kai_n[8][10] = lane_rho_pi[16][10];
		lane_pi_kai_n[8][11] = lane_rho_pi[16][11];
		lane_pi_kai_n[8][12] = lane_rho_pi[16][12];
		lane_pi_kai_n[8][13] = lane_rho_pi[16][13];
		lane_pi_kai_n[8][14] = lane_rho_pi[16][14];
		lane_pi_kai_n[8][15] = lane_rho_pi[16][15];
		lane_pi_kai_n[8][16] = lane_rho_pi[16][16];
		lane_pi_kai_n[8][17] = lane_rho_pi[16][17];
		lane_pi_kai_n[8][18] = lane_rho_pi[16][18];
		lane_pi_kai_n[8][19] = lane_rho_pi[16][19];
		lane_pi_kai_n[8][20] = lane_rho_pi[16][20];
		lane_pi_kai_n[8][21] = lane_rho_pi[16][21];
		lane_pi_kai_n[8][22] = lane_rho_pi[16][22];
		lane_pi_kai_n[8][23] = lane_rho_pi[16][23];
		lane_pi_kai_n[8][24] = lane_rho_pi[16][24];
		lane_pi_kai_n[8][25] = lane_rho_pi[16][25];
		lane_pi_kai_n[8][26] = lane_rho_pi[16][26];
		lane_pi_kai_n[8][27] = lane_rho_pi[16][27];
		lane_pi_kai_n[8][28] = lane_rho_pi[16][28];
		lane_pi_kai_n[8][29] = lane_rho_pi[16][29];
		lane_pi_kai_n[8][30] = lane_rho_pi[16][30];
		lane_pi_kai_n[8][31] = lane_rho_pi[16][31];
		lane_pi_kai_n[8][32] = lane_rho_pi[16][32];
		lane_pi_kai_n[8][33] = lane_rho_pi[16][33];
		lane_pi_kai_n[8][34] = lane_rho_pi[16][34];
		lane_pi_kai_n[8][35] = lane_rho_pi[16][35];
		lane_pi_kai_n[8][36] = lane_rho_pi[16][36];
		lane_pi_kai_n[8][37] = lane_rho_pi[16][37];
		lane_pi_kai_n[8][38] = lane_rho_pi[16][38];
		lane_pi_kai_n[8][39] = lane_rho_pi[16][39];
		lane_pi_kai_n[8][40] = lane_rho_pi[16][40];
		lane_pi_kai_n[8][41] = lane_rho_pi[16][41];
		lane_pi_kai_n[8][42] = lane_rho_pi[16][42];
		lane_pi_kai_n[8][43] = lane_rho_pi[16][43];
		lane_pi_kai_n[8][44] = lane_rho_pi[16][44];
		lane_pi_kai_n[8][45] = lane_rho_pi[16][45];
		lane_pi_kai_n[8][46] = lane_rho_pi[16][46];
		lane_pi_kai_n[8][47] = lane_rho_pi[16][47];
		lane_pi_kai_n[8][48] = lane_rho_pi[16][48];
		lane_pi_kai_n[8][49] = lane_rho_pi[16][49];
		lane_pi_kai_n[8][50] = lane_rho_pi[16][50];
		lane_pi_kai_n[8][51] = lane_rho_pi[16][51];
		lane_pi_kai_n[8][52] = lane_rho_pi[16][52];
		lane_pi_kai_n[8][53] = lane_rho_pi[16][53];
		lane_pi_kai_n[8][54] = lane_rho_pi[16][54];
		lane_pi_kai_n[8][55] = lane_rho_pi[16][55];
		lane_pi_kai_n[8][56] = lane_rho_pi[16][56];
		lane_pi_kai_n[8][57] = lane_rho_pi[16][57];
		lane_pi_kai_n[8][58] = lane_rho_pi[16][58];
		lane_pi_kai_n[8][59] = lane_rho_pi[16][59];
		lane_pi_kai_n[8][60] = lane_rho_pi[16][60];
		lane_pi_kai_n[8][61] = lane_rho_pi[16][61];
		lane_pi_kai_n[8][62] = lane_rho_pi[16][62];
		lane_pi_kai_n[8][63] = lane_rho_pi[16][63];
		lane_pi_kai_n[13][0] = lane_rho_pi[19][0];
		lane_pi_kai_n[13][1] = lane_rho_pi[19][1];
		lane_pi_kai_n[13][2] = lane_rho_pi[19][2];
		lane_pi_kai_n[13][3] = lane_rho_pi[19][3];
		lane_pi_kai_n[13][4] = lane_rho_pi[19][4];
		lane_pi_kai_n[13][5] = lane_rho_pi[19][5];
		lane_pi_kai_n[13][6] = lane_rho_pi[19][6];
		lane_pi_kai_n[13][7] = lane_rho_pi[19][7];
		lane_pi_kai_n[13][8] = lane_rho_pi[19][8];
		lane_pi_kai_n[13][9] = lane_rho_pi[19][9];
		lane_pi_kai_n[13][10] = lane_rho_pi[19][10];
		lane_pi_kai_n[13][11] = lane_rho_pi[19][11];
		lane_pi_kai_n[13][12] = lane_rho_pi[19][12];
		lane_pi_kai_n[13][13] = lane_rho_pi[19][13];
		lane_pi_kai_n[13][14] = lane_rho_pi[19][14];
		lane_pi_kai_n[13][15] = lane_rho_pi[19][15];
		lane_pi_kai_n[13][16] = lane_rho_pi[19][16];
		lane_pi_kai_n[13][17] = lane_rho_pi[19][17];
		lane_pi_kai_n[13][18] = lane_rho_pi[19][18];
		lane_pi_kai_n[13][19] = lane_rho_pi[19][19];
		lane_pi_kai_n[13][20] = lane_rho_pi[19][20];
		lane_pi_kai_n[13][21] = lane_rho_pi[19][21];
		lane_pi_kai_n[13][22] = lane_rho_pi[19][22];
		lane_pi_kai_n[13][23] = lane_rho_pi[19][23];
		lane_pi_kai_n[13][24] = lane_rho_pi[19][24];
		lane_pi_kai_n[13][25] = lane_rho_pi[19][25];
		lane_pi_kai_n[13][26] = lane_rho_pi[19][26];
		lane_pi_kai_n[13][27] = lane_rho_pi[19][27];
		lane_pi_kai_n[13][28] = lane_rho_pi[19][28];
		lane_pi_kai_n[13][29] = lane_rho_pi[19][29];
		lane_pi_kai_n[13][30] = lane_rho_pi[19][30];
		lane_pi_kai_n[13][31] = lane_rho_pi[19][31];
		lane_pi_kai_n[13][32] = lane_rho_pi[19][32];
		lane_pi_kai_n[13][33] = lane_rho_pi[19][33];
		lane_pi_kai_n[13][34] = lane_rho_pi[19][34];
		lane_pi_kai_n[13][35] = lane_rho_pi[19][35];
		lane_pi_kai_n[13][36] = lane_rho_pi[19][36];
		lane_pi_kai_n[13][37] = lane_rho_pi[19][37];
		lane_pi_kai_n[13][38] = lane_rho_pi[19][38];
		lane_pi_kai_n[13][39] = lane_rho_pi[19][39];
		lane_pi_kai_n[13][40] = lane_rho_pi[19][40];
		lane_pi_kai_n[13][41] = lane_rho_pi[19][41];
		lane_pi_kai_n[13][42] = lane_rho_pi[19][42];
		lane_pi_kai_n[13][43] = lane_rho_pi[19][43];
		lane_pi_kai_n[13][44] = lane_rho_pi[19][44];
		lane_pi_kai_n[13][45] = lane_rho_pi[19][45];
		lane_pi_kai_n[13][46] = lane_rho_pi[19][46];
		lane_pi_kai_n[13][47] = lane_rho_pi[19][47];
		lane_pi_kai_n[13][48] = lane_rho_pi[19][48];
		lane_pi_kai_n[13][49] = lane_rho_pi[19][49];
		lane_pi_kai_n[13][50] = lane_rho_pi[19][50];
		lane_pi_kai_n[13][51] = lane_rho_pi[19][51];
		lane_pi_kai_n[13][52] = lane_rho_pi[19][52];
		lane_pi_kai_n[13][53] = lane_rho_pi[19][53];
		lane_pi_kai_n[13][54] = lane_rho_pi[19][54];
		lane_pi_kai_n[13][55] = lane_rho_pi[19][55];
		lane_pi_kai_n[13][56] = lane_rho_pi[19][56];
		lane_pi_kai_n[13][57] = lane_rho_pi[19][57];
		lane_pi_kai_n[13][58] = lane_rho_pi[19][58];
		lane_pi_kai_n[13][59] = lane_rho_pi[19][59];
		lane_pi_kai_n[13][60] = lane_rho_pi[19][60];
		lane_pi_kai_n[13][61] = lane_rho_pi[19][61];
		lane_pi_kai_n[13][62] = lane_rho_pi[19][62];
		lane_pi_kai_n[13][63] = lane_rho_pi[19][63];
		lane_pi_kai_n[18][0] = lane_rho_pi[17][0];
		lane_pi_kai_n[18][1] = lane_rho_pi[17][1];
		lane_pi_kai_n[18][2] = lane_rho_pi[17][2];
		lane_pi_kai_n[18][3] = lane_rho_pi[17][3];
		lane_pi_kai_n[18][4] = lane_rho_pi[17][4];
		lane_pi_kai_n[18][5] = lane_rho_pi[17][5];
		lane_pi_kai_n[18][6] = lane_rho_pi[17][6];
		lane_pi_kai_n[18][7] = lane_rho_pi[17][7];
		lane_pi_kai_n[18][8] = lane_rho_pi[17][8];
		lane_pi_kai_n[18][9] = lane_rho_pi[17][9];
		lane_pi_kai_n[18][10] = lane_rho_pi[17][10];
		lane_pi_kai_n[18][11] = lane_rho_pi[17][11];
		lane_pi_kai_n[18][12] = lane_rho_pi[17][12];
		lane_pi_kai_n[18][13] = lane_rho_pi[17][13];
		lane_pi_kai_n[18][14] = lane_rho_pi[17][14];
		lane_pi_kai_n[18][15] = lane_rho_pi[17][15];
		lane_pi_kai_n[18][16] = lane_rho_pi[17][16];
		lane_pi_kai_n[18][17] = lane_rho_pi[17][17];
		lane_pi_kai_n[18][18] = lane_rho_pi[17][18];
		lane_pi_kai_n[18][19] = lane_rho_pi[17][19];
		lane_pi_kai_n[18][20] = lane_rho_pi[17][20];
		lane_pi_kai_n[18][21] = lane_rho_pi[17][21];
		lane_pi_kai_n[18][22] = lane_rho_pi[17][22];
		lane_pi_kai_n[18][23] = lane_rho_pi[17][23];
		lane_pi_kai_n[18][24] = lane_rho_pi[17][24];
		lane_pi_kai_n[18][25] = lane_rho_pi[17][25];
		lane_pi_kai_n[18][26] = lane_rho_pi[17][26];
		lane_pi_kai_n[18][27] = lane_rho_pi[17][27];
		lane_pi_kai_n[18][28] = lane_rho_pi[17][28];
		lane_pi_kai_n[18][29] = lane_rho_pi[17][29];
		lane_pi_kai_n[18][30] = lane_rho_pi[17][30];
		lane_pi_kai_n[18][31] = lane_rho_pi[17][31];
		lane_pi_kai_n[18][32] = lane_rho_pi[17][32];
		lane_pi_kai_n[18][33] = lane_rho_pi[17][33];
		lane_pi_kai_n[18][34] = lane_rho_pi[17][34];
		lane_pi_kai_n[18][35] = lane_rho_pi[17][35];
		lane_pi_kai_n[18][36] = lane_rho_pi[17][36];
		lane_pi_kai_n[18][37] = lane_rho_pi[17][37];
		lane_pi_kai_n[18][38] = lane_rho_pi[17][38];
		lane_pi_kai_n[18][39] = lane_rho_pi[17][39];
		lane_pi_kai_n[18][40] = lane_rho_pi[17][40];
		lane_pi_kai_n[18][41] = lane_rho_pi[17][41];
		lane_pi_kai_n[18][42] = lane_rho_pi[17][42];
		lane_pi_kai_n[18][43] = lane_rho_pi[17][43];
		lane_pi_kai_n[18][44] = lane_rho_pi[17][44];
		lane_pi_kai_n[18][45] = lane_rho_pi[17][45];
		lane_pi_kai_n[18][46] = lane_rho_pi[17][46];
		lane_pi_kai_n[18][47] = lane_rho_pi[17][47];
		lane_pi_kai_n[18][48] = lane_rho_pi[17][48];
		lane_pi_kai_n[18][49] = lane_rho_pi[17][49];
		lane_pi_kai_n[18][50] = lane_rho_pi[17][50];
		lane_pi_kai_n[18][51] = lane_rho_pi[17][51];
		lane_pi_kai_n[18][52] = lane_rho_pi[17][52];
		lane_pi_kai_n[18][53] = lane_rho_pi[17][53];
		lane_pi_kai_n[18][54] = lane_rho_pi[17][54];
		lane_pi_kai_n[18][55] = lane_rho_pi[17][55];
		lane_pi_kai_n[18][56] = lane_rho_pi[17][56];
		lane_pi_kai_n[18][57] = lane_rho_pi[17][57];
		lane_pi_kai_n[18][58] = lane_rho_pi[17][58];
		lane_pi_kai_n[18][59] = lane_rho_pi[17][59];
		lane_pi_kai_n[18][60] = lane_rho_pi[17][60];
		lane_pi_kai_n[18][61] = lane_rho_pi[17][61];
		lane_pi_kai_n[18][62] = lane_rho_pi[17][62];
		lane_pi_kai_n[18][63] = lane_rho_pi[17][63];
		lane_pi_kai_n[23][0] = lane_rho_pi[15][0];
		lane_pi_kai_n[23][1] = lane_rho_pi[15][1];
		lane_pi_kai_n[23][2] = lane_rho_pi[15][2];
		lane_pi_kai_n[23][3] = lane_rho_pi[15][3];
		lane_pi_kai_n[23][4] = lane_rho_pi[15][4];
		lane_pi_kai_n[23][5] = lane_rho_pi[15][5];
		lane_pi_kai_n[23][6] = lane_rho_pi[15][6];
		lane_pi_kai_n[23][7] = lane_rho_pi[15][7];
		lane_pi_kai_n[23][8] = lane_rho_pi[15][8];
		lane_pi_kai_n[23][9] = lane_rho_pi[15][9];
		lane_pi_kai_n[23][10] = lane_rho_pi[15][10];
		lane_pi_kai_n[23][11] = lane_rho_pi[15][11];
		lane_pi_kai_n[23][12] = lane_rho_pi[15][12];
		lane_pi_kai_n[23][13] = lane_rho_pi[15][13];
		lane_pi_kai_n[23][14] = lane_rho_pi[15][14];
		lane_pi_kai_n[23][15] = lane_rho_pi[15][15];
		lane_pi_kai_n[23][16] = lane_rho_pi[15][16];
		lane_pi_kai_n[23][17] = lane_rho_pi[15][17];
		lane_pi_kai_n[23][18] = lane_rho_pi[15][18];
		lane_pi_kai_n[23][19] = lane_rho_pi[15][19];
		lane_pi_kai_n[23][20] = lane_rho_pi[15][20];
		lane_pi_kai_n[23][21] = lane_rho_pi[15][21];
		lane_pi_kai_n[23][22] = lane_rho_pi[15][22];
		lane_pi_kai_n[23][23] = lane_rho_pi[15][23];
		lane_pi_kai_n[23][24] = lane_rho_pi[15][24];
		lane_pi_kai_n[23][25] = lane_rho_pi[15][25];
		lane_pi_kai_n[23][26] = lane_rho_pi[15][26];
		lane_pi_kai_n[23][27] = lane_rho_pi[15][27];
		lane_pi_kai_n[23][28] = lane_rho_pi[15][28];
		lane_pi_kai_n[23][29] = lane_rho_pi[15][29];
		lane_pi_kai_n[23][30] = lane_rho_pi[15][30];
		lane_pi_kai_n[23][31] = lane_rho_pi[15][31];
		lane_pi_kai_n[23][32] = lane_rho_pi[15][32];
		lane_pi_kai_n[23][33] = lane_rho_pi[15][33];
		lane_pi_kai_n[23][34] = lane_rho_pi[15][34];
		lane_pi_kai_n[23][35] = lane_rho_pi[15][35];
		lane_pi_kai_n[23][36] = lane_rho_pi[15][36];
		lane_pi_kai_n[23][37] = lane_rho_pi[15][37];
		lane_pi_kai_n[23][38] = lane_rho_pi[15][38];
		lane_pi_kai_n[23][39] = lane_rho_pi[15][39];
		lane_pi_kai_n[23][40] = lane_rho_pi[15][40];
		lane_pi_kai_n[23][41] = lane_rho_pi[15][41];
		lane_pi_kai_n[23][42] = lane_rho_pi[15][42];
		lane_pi_kai_n[23][43] = lane_rho_pi[15][43];
		lane_pi_kai_n[23][44] = lane_rho_pi[15][44];
		lane_pi_kai_n[23][45] = lane_rho_pi[15][45];
		lane_pi_kai_n[23][46] = lane_rho_pi[15][46];
		lane_pi_kai_n[23][47] = lane_rho_pi[15][47];
		lane_pi_kai_n[23][48] = lane_rho_pi[15][48];
		lane_pi_kai_n[23][49] = lane_rho_pi[15][49];
		lane_pi_kai_n[23][50] = lane_rho_pi[15][50];
		lane_pi_kai_n[23][51] = lane_rho_pi[15][51];
		lane_pi_kai_n[23][52] = lane_rho_pi[15][52];
		lane_pi_kai_n[23][53] = lane_rho_pi[15][53];
		lane_pi_kai_n[23][54] = lane_rho_pi[15][54];
		lane_pi_kai_n[23][55] = lane_rho_pi[15][55];
		lane_pi_kai_n[23][56] = lane_rho_pi[15][56];
		lane_pi_kai_n[23][57] = lane_rho_pi[15][57];
		lane_pi_kai_n[23][58] = lane_rho_pi[15][58];
		lane_pi_kai_n[23][59] = lane_rho_pi[15][59];
		lane_pi_kai_n[23][60] = lane_rho_pi[15][60];
		lane_pi_kai_n[23][61] = lane_rho_pi[15][61];
		lane_pi_kai_n[23][62] = lane_rho_pi[15][62];
		lane_pi_kai_n[23][63] = lane_rho_pi[15][63];
		lane_pi_kai_n[4][0] = lane_rho_pi[24][0];
		lane_pi_kai_n[4][1] = lane_rho_pi[24][1];
		lane_pi_kai_n[4][2] = lane_rho_pi[24][2];
		lane_pi_kai_n[4][3] = lane_rho_pi[24][3];
		lane_pi_kai_n[4][4] = lane_rho_pi[24][4];
		lane_pi_kai_n[4][5] = lane_rho_pi[24][5];
		lane_pi_kai_n[4][6] = lane_rho_pi[24][6];
		lane_pi_kai_n[4][7] = lane_rho_pi[24][7];
		lane_pi_kai_n[4][8] = lane_rho_pi[24][8];
		lane_pi_kai_n[4][9] = lane_rho_pi[24][9];
		lane_pi_kai_n[4][10] = lane_rho_pi[24][10];
		lane_pi_kai_n[4][11] = lane_rho_pi[24][11];
		lane_pi_kai_n[4][12] = lane_rho_pi[24][12];
		lane_pi_kai_n[4][13] = lane_rho_pi[24][13];
		lane_pi_kai_n[4][14] = lane_rho_pi[24][14];
		lane_pi_kai_n[4][15] = lane_rho_pi[24][15];
		lane_pi_kai_n[4][16] = lane_rho_pi[24][16];
		lane_pi_kai_n[4][17] = lane_rho_pi[24][17];
		lane_pi_kai_n[4][18] = lane_rho_pi[24][18];
		lane_pi_kai_n[4][19] = lane_rho_pi[24][19];
		lane_pi_kai_n[4][20] = lane_rho_pi[24][20];
		lane_pi_kai_n[4][21] = lane_rho_pi[24][21];
		lane_pi_kai_n[4][22] = lane_rho_pi[24][22];
		lane_pi_kai_n[4][23] = lane_rho_pi[24][23];
		lane_pi_kai_n[4][24] = lane_rho_pi[24][24];
		lane_pi_kai_n[4][25] = lane_rho_pi[24][25];
		lane_pi_kai_n[4][26] = lane_rho_pi[24][26];
		lane_pi_kai_n[4][27] = lane_rho_pi[24][27];
		lane_pi_kai_n[4][28] = lane_rho_pi[24][28];
		lane_pi_kai_n[4][29] = lane_rho_pi[24][29];
		lane_pi_kai_n[4][30] = lane_rho_pi[24][30];
		lane_pi_kai_n[4][31] = lane_rho_pi[24][31];
		lane_pi_kai_n[4][32] = lane_rho_pi[24][32];
		lane_pi_kai_n[4][33] = lane_rho_pi[24][33];
		lane_pi_kai_n[4][34] = lane_rho_pi[24][34];
		lane_pi_kai_n[4][35] = lane_rho_pi[24][35];
		lane_pi_kai_n[4][36] = lane_rho_pi[24][36];
		lane_pi_kai_n[4][37] = lane_rho_pi[24][37];
		lane_pi_kai_n[4][38] = lane_rho_pi[24][38];
		lane_pi_kai_n[4][39] = lane_rho_pi[24][39];
		lane_pi_kai_n[4][40] = lane_rho_pi[24][40];
		lane_pi_kai_n[4][41] = lane_rho_pi[24][41];
		lane_pi_kai_n[4][42] = lane_rho_pi[24][42];
		lane_pi_kai_n[4][43] = lane_rho_pi[24][43];
		lane_pi_kai_n[4][44] = lane_rho_pi[24][44];
		lane_pi_kai_n[4][45] = lane_rho_pi[24][45];
		lane_pi_kai_n[4][46] = lane_rho_pi[24][46];
		lane_pi_kai_n[4][47] = lane_rho_pi[24][47];
		lane_pi_kai_n[4][48] = lane_rho_pi[24][48];
		lane_pi_kai_n[4][49] = lane_rho_pi[24][49];
		lane_pi_kai_n[4][50] = lane_rho_pi[24][50];
		lane_pi_kai_n[4][51] = lane_rho_pi[24][51];
		lane_pi_kai_n[4][52] = lane_rho_pi[24][52];
		lane_pi_kai_n[4][53] = lane_rho_pi[24][53];
		lane_pi_kai_n[4][54] = lane_rho_pi[24][54];
		lane_pi_kai_n[4][55] = lane_rho_pi[24][55];
		lane_pi_kai_n[4][56] = lane_rho_pi[24][56];
		lane_pi_kai_n[4][57] = lane_rho_pi[24][57];
		lane_pi_kai_n[4][58] = lane_rho_pi[24][58];
		lane_pi_kai_n[4][59] = lane_rho_pi[24][59];
		lane_pi_kai_n[4][60] = lane_rho_pi[24][60];
		lane_pi_kai_n[4][61] = lane_rho_pi[24][61];
		lane_pi_kai_n[4][62] = lane_rho_pi[24][62];
		lane_pi_kai_n[4][63] = lane_rho_pi[24][63];
		lane_pi_kai_n[9][0] = lane_rho_pi[22][0];
		lane_pi_kai_n[9][1] = lane_rho_pi[22][1];
		lane_pi_kai_n[9][2] = lane_rho_pi[22][2];
		lane_pi_kai_n[9][3] = lane_rho_pi[22][3];
		lane_pi_kai_n[9][4] = lane_rho_pi[22][4];
		lane_pi_kai_n[9][5] = lane_rho_pi[22][5];
		lane_pi_kai_n[9][6] = lane_rho_pi[22][6];
		lane_pi_kai_n[9][7] = lane_rho_pi[22][7];
		lane_pi_kai_n[9][8] = lane_rho_pi[22][8];
		lane_pi_kai_n[9][9] = lane_rho_pi[22][9];
		lane_pi_kai_n[9][10] = lane_rho_pi[22][10];
		lane_pi_kai_n[9][11] = lane_rho_pi[22][11];
		lane_pi_kai_n[9][12] = lane_rho_pi[22][12];
		lane_pi_kai_n[9][13] = lane_rho_pi[22][13];
		lane_pi_kai_n[9][14] = lane_rho_pi[22][14];
		lane_pi_kai_n[9][15] = lane_rho_pi[22][15];
		lane_pi_kai_n[9][16] = lane_rho_pi[22][16];
		lane_pi_kai_n[9][17] = lane_rho_pi[22][17];
		lane_pi_kai_n[9][18] = lane_rho_pi[22][18];
		lane_pi_kai_n[9][19] = lane_rho_pi[22][19];
		lane_pi_kai_n[9][20] = lane_rho_pi[22][20];
		lane_pi_kai_n[9][21] = lane_rho_pi[22][21];
		lane_pi_kai_n[9][22] = lane_rho_pi[22][22];
		lane_pi_kai_n[9][23] = lane_rho_pi[22][23];
		lane_pi_kai_n[9][24] = lane_rho_pi[22][24];
		lane_pi_kai_n[9][25] = lane_rho_pi[22][25];
		lane_pi_kai_n[9][26] = lane_rho_pi[22][26];
		lane_pi_kai_n[9][27] = lane_rho_pi[22][27];
		lane_pi_kai_n[9][28] = lane_rho_pi[22][28];
		lane_pi_kai_n[9][29] = lane_rho_pi[22][29];
		lane_pi_kai_n[9][30] = lane_rho_pi[22][30];
		lane_pi_kai_n[9][31] = lane_rho_pi[22][31];
		lane_pi_kai_n[9][32] = lane_rho_pi[22][32];
		lane_pi_kai_n[9][33] = lane_rho_pi[22][33];
		lane_pi_kai_n[9][34] = lane_rho_pi[22][34];
		lane_pi_kai_n[9][35] = lane_rho_pi[22][35];
		lane_pi_kai_n[9][36] = lane_rho_pi[22][36];
		lane_pi_kai_n[9][37] = lane_rho_pi[22][37];
		lane_pi_kai_n[9][38] = lane_rho_pi[22][38];
		lane_pi_kai_n[9][39] = lane_rho_pi[22][39];
		lane_pi_kai_n[9][40] = lane_rho_pi[22][40];
		lane_pi_kai_n[9][41] = lane_rho_pi[22][41];
		lane_pi_kai_n[9][42] = lane_rho_pi[22][42];
		lane_pi_kai_n[9][43] = lane_rho_pi[22][43];
		lane_pi_kai_n[9][44] = lane_rho_pi[22][44];
		lane_pi_kai_n[9][45] = lane_rho_pi[22][45];
		lane_pi_kai_n[9][46] = lane_rho_pi[22][46];
		lane_pi_kai_n[9][47] = lane_rho_pi[22][47];
		lane_pi_kai_n[9][48] = lane_rho_pi[22][48];
		lane_pi_kai_n[9][49] = lane_rho_pi[22][49];
		lane_pi_kai_n[9][50] = lane_rho_pi[22][50];
		lane_pi_kai_n[9][51] = lane_rho_pi[22][51];
		lane_pi_kai_n[9][52] = lane_rho_pi[22][52];
		lane_pi_kai_n[9][53] = lane_rho_pi[22][53];
		lane_pi_kai_n[9][54] = lane_rho_pi[22][54];
		lane_pi_kai_n[9][55] = lane_rho_pi[22][55];
		lane_pi_kai_n[9][56] = lane_rho_pi[22][56];
		lane_pi_kai_n[9][57] = lane_rho_pi[22][57];
		lane_pi_kai_n[9][58] = lane_rho_pi[22][58];
		lane_pi_kai_n[9][59] = lane_rho_pi[22][59];
		lane_pi_kai_n[9][60] = lane_rho_pi[22][60];
		lane_pi_kai_n[9][61] = lane_rho_pi[22][61];
		lane_pi_kai_n[9][62] = lane_rho_pi[22][62];
		lane_pi_kai_n[9][63] = lane_rho_pi[22][63];
		lane_pi_kai_n[14][0] = lane_rho_pi[20][0];
		lane_pi_kai_n[14][1] = lane_rho_pi[20][1];
		lane_pi_kai_n[14][2] = lane_rho_pi[20][2];
		lane_pi_kai_n[14][3] = lane_rho_pi[20][3];
		lane_pi_kai_n[14][4] = lane_rho_pi[20][4];
		lane_pi_kai_n[14][5] = lane_rho_pi[20][5];
		lane_pi_kai_n[14][6] = lane_rho_pi[20][6];
		lane_pi_kai_n[14][7] = lane_rho_pi[20][7];
		lane_pi_kai_n[14][8] = lane_rho_pi[20][8];
		lane_pi_kai_n[14][9] = lane_rho_pi[20][9];
		lane_pi_kai_n[14][10] = lane_rho_pi[20][10];
		lane_pi_kai_n[14][11] = lane_rho_pi[20][11];
		lane_pi_kai_n[14][12] = lane_rho_pi[20][12];
		lane_pi_kai_n[14][13] = lane_rho_pi[20][13];
		lane_pi_kai_n[14][14] = lane_rho_pi[20][14];
		lane_pi_kai_n[14][15] = lane_rho_pi[20][15];
		lane_pi_kai_n[14][16] = lane_rho_pi[20][16];
		lane_pi_kai_n[14][17] = lane_rho_pi[20][17];
		lane_pi_kai_n[14][18] = lane_rho_pi[20][18];
		lane_pi_kai_n[14][19] = lane_rho_pi[20][19];
		lane_pi_kai_n[14][20] = lane_rho_pi[20][20];
		lane_pi_kai_n[14][21] = lane_rho_pi[20][21];
		lane_pi_kai_n[14][22] = lane_rho_pi[20][22];
		lane_pi_kai_n[14][23] = lane_rho_pi[20][23];
		lane_pi_kai_n[14][24] = lane_rho_pi[20][24];
		lane_pi_kai_n[14][25] = lane_rho_pi[20][25];
		lane_pi_kai_n[14][26] = lane_rho_pi[20][26];
		lane_pi_kai_n[14][27] = lane_rho_pi[20][27];
		lane_pi_kai_n[14][28] = lane_rho_pi[20][28];
		lane_pi_kai_n[14][29] = lane_rho_pi[20][29];
		lane_pi_kai_n[14][30] = lane_rho_pi[20][30];
		lane_pi_kai_n[14][31] = lane_rho_pi[20][31];
		lane_pi_kai_n[14][32] = lane_rho_pi[20][32];
		lane_pi_kai_n[14][33] = lane_rho_pi[20][33];
		lane_pi_kai_n[14][34] = lane_rho_pi[20][34];
		lane_pi_kai_n[14][35] = lane_rho_pi[20][35];
		lane_pi_kai_n[14][36] = lane_rho_pi[20][36];
		lane_pi_kai_n[14][37] = lane_rho_pi[20][37];
		lane_pi_kai_n[14][38] = lane_rho_pi[20][38];
		lane_pi_kai_n[14][39] = lane_rho_pi[20][39];
		lane_pi_kai_n[14][40] = lane_rho_pi[20][40];
		lane_pi_kai_n[14][41] = lane_rho_pi[20][41];
		lane_pi_kai_n[14][42] = lane_rho_pi[20][42];
		lane_pi_kai_n[14][43] = lane_rho_pi[20][43];
		lane_pi_kai_n[14][44] = lane_rho_pi[20][44];
		lane_pi_kai_n[14][45] = lane_rho_pi[20][45];
		lane_pi_kai_n[14][46] = lane_rho_pi[20][46];
		lane_pi_kai_n[14][47] = lane_rho_pi[20][47];
		lane_pi_kai_n[14][48] = lane_rho_pi[20][48];
		lane_pi_kai_n[14][49] = lane_rho_pi[20][49];
		lane_pi_kai_n[14][50] = lane_rho_pi[20][50];
		lane_pi_kai_n[14][51] = lane_rho_pi[20][51];
		lane_pi_kai_n[14][52] = lane_rho_pi[20][52];
		lane_pi_kai_n[14][53] = lane_rho_pi[20][53];
		lane_pi_kai_n[14][54] = lane_rho_pi[20][54];
		lane_pi_kai_n[14][55] = lane_rho_pi[20][55];
		lane_pi_kai_n[14][56] = lane_rho_pi[20][56];
		lane_pi_kai_n[14][57] = lane_rho_pi[20][57];
		lane_pi_kai_n[14][58] = lane_rho_pi[20][58];
		lane_pi_kai_n[14][59] = lane_rho_pi[20][59];
		lane_pi_kai_n[14][60] = lane_rho_pi[20][60];
		lane_pi_kai_n[14][61] = lane_rho_pi[20][61];
		lane_pi_kai_n[14][62] = lane_rho_pi[20][62];
		lane_pi_kai_n[14][63] = lane_rho_pi[20][63];
		lane_pi_kai_n[19][0] = lane_rho_pi[23][0];
		lane_pi_kai_n[19][1] = lane_rho_pi[23][1];
		lane_pi_kai_n[19][2] = lane_rho_pi[23][2];
		lane_pi_kai_n[19][3] = lane_rho_pi[23][3];
		lane_pi_kai_n[19][4] = lane_rho_pi[23][4];
		lane_pi_kai_n[19][5] = lane_rho_pi[23][5];
		lane_pi_kai_n[19][6] = lane_rho_pi[23][6];
		lane_pi_kai_n[19][7] = lane_rho_pi[23][7];
		lane_pi_kai_n[19][8] = lane_rho_pi[23][8];
		lane_pi_kai_n[19][9] = lane_rho_pi[23][9];
		lane_pi_kai_n[19][10] = lane_rho_pi[23][10];
		lane_pi_kai_n[19][11] = lane_rho_pi[23][11];
		lane_pi_kai_n[19][12] = lane_rho_pi[23][12];
		lane_pi_kai_n[19][13] = lane_rho_pi[23][13];
		lane_pi_kai_n[19][14] = lane_rho_pi[23][14];
		lane_pi_kai_n[19][15] = lane_rho_pi[23][15];
		lane_pi_kai_n[19][16] = lane_rho_pi[23][16];
		lane_pi_kai_n[19][17] = lane_rho_pi[23][17];
		lane_pi_kai_n[19][18] = lane_rho_pi[23][18];
		lane_pi_kai_n[19][19] = lane_rho_pi[23][19];
		lane_pi_kai_n[19][20] = lane_rho_pi[23][20];
		lane_pi_kai_n[19][21] = lane_rho_pi[23][21];
		lane_pi_kai_n[19][22] = lane_rho_pi[23][22];
		lane_pi_kai_n[19][23] = lane_rho_pi[23][23];
		lane_pi_kai_n[19][24] = lane_rho_pi[23][24];
		lane_pi_kai_n[19][25] = lane_rho_pi[23][25];
		lane_pi_kai_n[19][26] = lane_rho_pi[23][26];
		lane_pi_kai_n[19][27] = lane_rho_pi[23][27];
		lane_pi_kai_n[19][28] = lane_rho_pi[23][28];
		lane_pi_kai_n[19][29] = lane_rho_pi[23][29];
		lane_pi_kai_n[19][30] = lane_rho_pi[23][30];
		lane_pi_kai_n[19][31] = lane_rho_pi[23][31];
		lane_pi_kai_n[19][32] = lane_rho_pi[23][32];
		lane_pi_kai_n[19][33] = lane_rho_pi[23][33];
		lane_pi_kai_n[19][34] = lane_rho_pi[23][34];
		lane_pi_kai_n[19][35] = lane_rho_pi[23][35];
		lane_pi_kai_n[19][36] = lane_rho_pi[23][36];
		lane_pi_kai_n[19][37] = lane_rho_pi[23][37];
		lane_pi_kai_n[19][38] = lane_rho_pi[23][38];
		lane_pi_kai_n[19][39] = lane_rho_pi[23][39];
		lane_pi_kai_n[19][40] = lane_rho_pi[23][40];
		lane_pi_kai_n[19][41] = lane_rho_pi[23][41];
		lane_pi_kai_n[19][42] = lane_rho_pi[23][42];
		lane_pi_kai_n[19][43] = lane_rho_pi[23][43];
		lane_pi_kai_n[19][44] = lane_rho_pi[23][44];
		lane_pi_kai_n[19][45] = lane_rho_pi[23][45];
		lane_pi_kai_n[19][46] = lane_rho_pi[23][46];
		lane_pi_kai_n[19][47] = lane_rho_pi[23][47];
		lane_pi_kai_n[19][48] = lane_rho_pi[23][48];
		lane_pi_kai_n[19][49] = lane_rho_pi[23][49];
		lane_pi_kai_n[19][50] = lane_rho_pi[23][50];
		lane_pi_kai_n[19][51] = lane_rho_pi[23][51];
		lane_pi_kai_n[19][52] = lane_rho_pi[23][52];
		lane_pi_kai_n[19][53] = lane_rho_pi[23][53];
		lane_pi_kai_n[19][54] = lane_rho_pi[23][54];
		lane_pi_kai_n[19][55] = lane_rho_pi[23][55];
		lane_pi_kai_n[19][56] = lane_rho_pi[23][56];
		lane_pi_kai_n[19][57] = lane_rho_pi[23][57];
		lane_pi_kai_n[19][58] = lane_rho_pi[23][58];
		lane_pi_kai_n[19][59] = lane_rho_pi[23][59];
		lane_pi_kai_n[19][60] = lane_rho_pi[23][60];
		lane_pi_kai_n[19][61] = lane_rho_pi[23][61];
		lane_pi_kai_n[19][62] = lane_rho_pi[23][62];
		lane_pi_kai_n[19][63] = lane_rho_pi[23][63];
		lane_pi_kai_n[24][0] = lane_rho_pi[21][0];
		lane_pi_kai_n[24][1] = lane_rho_pi[21][1];
		lane_pi_kai_n[24][2] = lane_rho_pi[21][2];
		lane_pi_kai_n[24][3] = lane_rho_pi[21][3];
		lane_pi_kai_n[24][4] = lane_rho_pi[21][4];
		lane_pi_kai_n[24][5] = lane_rho_pi[21][5];
		lane_pi_kai_n[24][6] = lane_rho_pi[21][6];
		lane_pi_kai_n[24][7] = lane_rho_pi[21][7];
		lane_pi_kai_n[24][8] = lane_rho_pi[21][8];
		lane_pi_kai_n[24][9] = lane_rho_pi[21][9];
		lane_pi_kai_n[24][10] = lane_rho_pi[21][10];
		lane_pi_kai_n[24][11] = lane_rho_pi[21][11];
		lane_pi_kai_n[24][12] = lane_rho_pi[21][12];
		lane_pi_kai_n[24][13] = lane_rho_pi[21][13];
		lane_pi_kai_n[24][14] = lane_rho_pi[21][14];
		lane_pi_kai_n[24][15] = lane_rho_pi[21][15];
		lane_pi_kai_n[24][16] = lane_rho_pi[21][16];
		lane_pi_kai_n[24][17] = lane_rho_pi[21][17];
		lane_pi_kai_n[24][18] = lane_rho_pi[21][18];
		lane_pi_kai_n[24][19] = lane_rho_pi[21][19];
		lane_pi_kai_n[24][20] = lane_rho_pi[21][20];
		lane_pi_kai_n[24][21] = lane_rho_pi[21][21];
		lane_pi_kai_n[24][22] = lane_rho_pi[21][22];
		lane_pi_kai_n[24][23] = lane_rho_pi[21][23];
		lane_pi_kai_n[24][24] = lane_rho_pi[21][24];
		lane_pi_kai_n[24][25] = lane_rho_pi[21][25];
		lane_pi_kai_n[24][26] = lane_rho_pi[21][26];
		lane_pi_kai_n[24][27] = lane_rho_pi[21][27];
		lane_pi_kai_n[24][28] = lane_rho_pi[21][28];
		lane_pi_kai_n[24][29] = lane_rho_pi[21][29];
		lane_pi_kai_n[24][30] = lane_rho_pi[21][30];
		lane_pi_kai_n[24][31] = lane_rho_pi[21][31];
		lane_pi_kai_n[24][32] = lane_rho_pi[21][32];
		lane_pi_kai_n[24][33] = lane_rho_pi[21][33];
		lane_pi_kai_n[24][34] = lane_rho_pi[21][34];
		lane_pi_kai_n[24][35] = lane_rho_pi[21][35];
		lane_pi_kai_n[24][36] = lane_rho_pi[21][36];
		lane_pi_kai_n[24][37] = lane_rho_pi[21][37];
		lane_pi_kai_n[24][38] = lane_rho_pi[21][38];
		lane_pi_kai_n[24][39] = lane_rho_pi[21][39];
		lane_pi_kai_n[24][40] = lane_rho_pi[21][40];
		lane_pi_kai_n[24][41] = lane_rho_pi[21][41];
		lane_pi_kai_n[24][42] = lane_rho_pi[21][42];
		lane_pi_kai_n[24][43] = lane_rho_pi[21][43];
		lane_pi_kai_n[24][44] = lane_rho_pi[21][44];
		lane_pi_kai_n[24][45] = lane_rho_pi[21][45];
		lane_pi_kai_n[24][46] = lane_rho_pi[21][46];
		lane_pi_kai_n[24][47] = lane_rho_pi[21][47];
		lane_pi_kai_n[24][48] = lane_rho_pi[21][48];
		lane_pi_kai_n[24][49] = lane_rho_pi[21][49];
		lane_pi_kai_n[24][50] = lane_rho_pi[21][50];
		lane_pi_kai_n[24][51] = lane_rho_pi[21][51];
		lane_pi_kai_n[24][52] = lane_rho_pi[21][52];
		lane_pi_kai_n[24][53] = lane_rho_pi[21][53];
		lane_pi_kai_n[24][54] = lane_rho_pi[21][54];
		lane_pi_kai_n[24][55] = lane_rho_pi[21][55];
		lane_pi_kai_n[24][56] = lane_rho_pi[21][56];
		lane_pi_kai_n[24][57] = lane_rho_pi[21][57];
		lane_pi_kai_n[24][58] = lane_rho_pi[21][58];
		lane_pi_kai_n[24][59] = lane_rho_pi[21][59];
		lane_pi_kai_n[24][60] = lane_rho_pi[21][60];
		lane_pi_kai_n[24][61] = lane_rho_pi[21][61];
		lane_pi_kai_n[24][62] = lane_rho_pi[21][62];
		lane_pi_kai_n[24][63] = lane_rho_pi[21][63];
	end

	else begin
		for(i = 0; i < 25; i = i + 1) begin
			lane_pi_kai_n[i] = lane_pi_kai[i];
		end
	end
end

// kai function
// ** two cycle **
// produce (A[(x+1) mod5, y, z]⊕ 1 & A[(x + 2) mod 5][y][z])

always @(*) begin
	if(SHA3_state == KAI) begin
		lane_kai_iota_n[0] = lane_pi_kai[0]^((~lane_pi_kai[1]) & lane_pi_kai[2]);
		lane_kai_iota_n[1] = lane_pi_kai[1]^((~lane_pi_kai[2]) & lane_pi_kai[3]);
		lane_kai_iota_n[2] = lane_pi_kai[2]^((~lane_pi_kai[3]) & lane_pi_kai[4]);
		lane_kai_iota_n[3] = lane_pi_kai[3]^((~lane_pi_kai[4]) & lane_pi_kai[0]);
		lane_kai_iota_n[4] = lane_pi_kai[4]^((~lane_pi_kai[0]) & lane_pi_kai[1]);
		lane_kai_iota_n[5] = lane_pi_kai[5]^((~lane_pi_kai[6]) & lane_pi_kai[7]);
		lane_kai_iota_n[6] = lane_pi_kai[6]^((~lane_pi_kai[7]) & lane_pi_kai[8]);
		lane_kai_iota_n[7] = lane_pi_kai[7]^((~lane_pi_kai[8]) & lane_pi_kai[9]);
		lane_kai_iota_n[8] = lane_pi_kai[8]^((~lane_pi_kai[9]) & lane_pi_kai[5]);
		lane_kai_iota_n[9] = lane_pi_kai[9]^((~lane_pi_kai[5]) & lane_pi_kai[6]);
		lane_kai_iota_n[10] = lane_pi_kai[10]^((~lane_pi_kai[11]) & lane_pi_kai[12]);
		lane_kai_iota_n[11] = lane_pi_kai[11]^((~lane_pi_kai[12]) & lane_pi_kai[13]);
		lane_kai_iota_n[12] = lane_pi_kai[12]^((~lane_pi_kai[13]) & lane_pi_kai[14]);
		lane_kai_iota_n[13] = lane_pi_kai[13]^((~lane_pi_kai[14]) & lane_pi_kai[10]);
		lane_kai_iota_n[14] = lane_pi_kai[14]^((~lane_pi_kai[10]) & lane_pi_kai[11]);
		lane_kai_iota_n[15] = lane_pi_kai[15]^((~lane_pi_kai[16]) & lane_pi_kai[17]);
		lane_kai_iota_n[16] = lane_pi_kai[16]^((~lane_pi_kai[17]) & lane_pi_kai[18]);
		lane_kai_iota_n[17] = lane_pi_kai[17]^((~lane_pi_kai[18]) & lane_pi_kai[19]);
		lane_kai_iota_n[18] = lane_pi_kai[18]^((~lane_pi_kai[19]) & lane_pi_kai[15]);
		lane_kai_iota_n[19] = lane_pi_kai[19]^((~lane_pi_kai[15]) & lane_pi_kai[16]);
		lane_kai_iota_n[20] = lane_pi_kai[20]^((~lane_pi_kai[21]) & lane_pi_kai[22]);
		lane_kai_iota_n[21] = lane_pi_kai[21]^((~lane_pi_kai[22]) & lane_pi_kai[23]);
		lane_kai_iota_n[22] = lane_pi_kai[22]^((~lane_pi_kai[23]) & lane_pi_kai[24]);
		lane_kai_iota_n[23] = lane_pi_kai[23]^((~lane_pi_kai[24]) & lane_pi_kai[20]);
		lane_kai_iota_n[24] = lane_pi_kai[24]^((~lane_pi_kai[20]) & lane_pi_kai[21]);
	end

	else begin
		for(i = 0; i < 25; i = i + 1) begin
			lane_kai_iota_n[i] = lane_kai_iota[i];
		end
	end
end

// iota function
// ** one cycle **
// produce only

always @(*) begin
	if(SHA3_state == IOTA) begin
		lane_iota_fout_n[0] = lane_kai_iota[0] ^ rc_bits[round];
		for (i = 1; i <25; i= i+1) begin
			lane_iota_fout_n[i] = lane_kai_iota[i];
		end
	end

	else begin
		for (i = 0; i <25; i= i+1) begin
			lane_iota_fout_n[i] = lane_iota_fout[i];
		end
	end
end




endmodule