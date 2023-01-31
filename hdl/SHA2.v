module SHA2(
    input clk,
    input srst_n,             
    input load_en,                         
    input [511:0] sha2_in,       

    output [255:0] sha2_out,
    output reg sha2_done
);

localparam H0_0 = 32'h6a09e667;
localparam H1_0 = 32'hbb67ae85;
localparam H2_0 = 32'h3c6ef372;
localparam H3_0 = 32'ha54ff53a;
localparam H4_0 = 32'h510e527f;
localparam H5_0 = 32'h9b05688c;
localparam H6_0 = 32'h1f83d9ab;
localparam H7_0 = 32'h5be0cd19;
wire [31:0] K [0:63];  // see the bottom

parameter IDLE = 3'b000, PREPARE_W = 3'b001, ITERATION = 3'b010, UPDATE_H = 3'b011, DONE = 3'b100;

reg [2:0] sha2_state, sha2_state_n;
reg [5:0] rnd_new, rnd_reg;
reg [31:0] H0_reg, H1_reg, H2_reg, H3_reg, H4_reg, H5_reg, H6_reg, H7_reg;
reg [31:0] H0_new, H1_new, H2_new, H3_new, H4_new, H5_new, H6_new, H7_new;
reg [31:0] a_reg, b_reg, c_reg, d_reg, e_reg, f_reg, g_reg, h_reg;
reg [31:0] a_new, b_new, c_new, d_new, e_new, f_new, g_new, h_new;
reg [31:0] T1, sigma1_e, choose_e_f_g;
reg [31:0] T2, sigma0_a, maj_a_b_c;
wire [31:0] w;
reg iter_done;
reg sha2_done_n;

sha2_w_ctr U_sha2_w(
  .clk(clk),
  .srst_n(srst_n),
  .rnd(rnd_reg),
  .load_en(load_en),
  .sha2_in(sha2_in),
  .w(w)
);

assign sha2_out = {H0_reg, H1_reg, H2_reg, H3_reg, H4_reg, H5_reg, H6_reg, H7_reg};

// FSM
always @(*) begin
  case(sha2_state)
    IDLE: begin
      if (load_en) sha2_state_n = PREPARE_W;
      else sha2_state_n = IDLE;
    end
    PREPARE_W: begin
      sha2_state_n = ITERATION;
    end
    ITERATION: begin
      if (iter_done) sha2_state_n = UPDATE_H;
      else sha2_state_n = ITERATION;
    end
    UPDATE_H: begin
      sha2_state_n = DONE;
    end
    DONE: begin
      if (load_en) sha2_state_n = PREPARE_W;
      else sha2_state_n = DONE;
    end
    default: begin
      sha2_state_n = IDLE;
    end
  endcase
end


always @(*) begin
  // Update round number after one iteration
  iter_done = 0;
  rnd_new = rnd_reg;
  if (sha2_state == ITERATION) begin
    rnd_new = rnd_reg + 1;
    if (rnd_reg == 63) iter_done = 1;
  end

  // Update a, b, ... , h
  if (sha2_state == PREPARE_W) begin
    a_new = H0_reg;
    b_new = H1_reg;
    c_new = H2_reg;
    d_new = H3_reg;
    e_new = H4_reg;
    f_new = H5_reg;
    g_new = H6_reg;
    h_new = H7_reg;
  end
  else if (sha2_state == ITERATION) begin
    a_new = T1 + T2;
    b_new = a_reg;
    c_new = b_reg;
    d_new = c_reg;
    e_new = d_reg + T1;
    f_new = e_reg;
    g_new = f_reg;
    h_new = g_reg;
  end
  else begin
    a_new = a_reg;
    b_new = b_reg;
    c_new = c_reg;
    d_new = d_reg;
    e_new = e_reg;
    f_new = f_reg;
    g_new = g_reg;
    h_new = h_reg;
  end
end

// Calculate T1 and T2
always @(*) begin
  // T1
  sigma1_e = {e_reg[5:0], e_reg[31:6]} ^ {e_reg[10:0], e_reg[31:11]} ^ {e_reg[24:0], e_reg[31:25]};
  choose_e_f_g = (~e_reg & g_reg) ^ (e_reg & f_reg);
  T1 = h_reg + sigma1_e + choose_e_f_g + K[rnd_reg] + w;
  // T2
  sigma0_a = {a_reg[1:0], a_reg[31:2]} ^ {a_reg[12:0], a_reg[31:13]} ^ {a_reg[21:0], a_reg[31:22]};
  maj_a_b_c = (a_reg & b_reg) ^ (b_reg & c_reg) ^ (a_reg & c_reg);
  T2 = sigma0_a + maj_a_b_c;
end

// Update hash value
always @(*) begin
  if (sha2_state == UPDATE_H) sha2_done_n = 1;
  else sha2_done_n = 0;

  if (sha2_state == IDLE && load_en) begin
    H0_new = H0_0;
    H1_new = H1_0;
    H2_new = H2_0;
    H3_new = H3_0;
    H4_new = H4_0;
    H5_new = H5_0;
    H6_new = H6_0;
    H7_new = H7_0;
  end
  else if (sha2_state == UPDATE_H) begin
    H0_new = H0_reg + a_reg;
    H1_new = H1_reg + b_reg;
    H2_new = H2_reg + c_reg;
    H3_new = H3_reg + d_reg;
    H4_new = H4_reg + e_reg;
    H5_new = H5_reg + f_reg;
    H6_new = H6_reg + g_reg;
    H7_new = H7_reg + h_reg;
  end
  else begin
    H0_new = H0_reg;
    H1_new = H1_reg;
    H2_new = H2_reg;
    H3_new = H3_reg;
    H4_new = H4_reg;
    H5_new = H5_reg;
    H6_new = H6_reg;
    H7_new = H7_reg;
  end
end


// Sequential circuit
always @(posedge clk) begin
  if(~srst_n) begin
    sha2_state <= IDLE;
    rnd_reg <= 0;
    H0_reg <= 0;
    H1_reg <= 0;
    H2_reg <= 0;
    H3_reg <= 0;
    H4_reg <= 0;
    H5_reg <= 0;
    H6_reg <= 0;
    H7_reg <= 0;
    a_reg <= 0;
    b_reg <= 0;
    c_reg <= 0;
    d_reg <= 0;
    e_reg <= 0;
    f_reg <= 0;
    g_reg <= 0;
    h_reg <= 0;
    sha2_done <= 0;
  end
  else begin
    sha2_state <= sha2_state_n;
    rnd_reg <= rnd_new;
    H0_reg <= H0_new;
    H1_reg <= H1_new;
    H2_reg <= H2_new;
    H3_reg <= H3_new;
    H4_reg <= H4_new;
    H5_reg <= H5_new;
    H6_reg <= H6_new;
    H7_reg <= H7_new;
    a_reg <= a_new;
    b_reg <= b_new;
    c_reg <= c_new;
    d_reg <= d_new;
    e_reg <= e_new;
    f_reg <= f_new;
    g_reg <= g_new;
    h_reg <= h_new;
    sha2_done <= sha2_done_n;
  end
end

// constants
assign K[0] = 32'h428a2f98;
assign K[1] = 32'h71374491;
assign K[2] = 32'hb5c0fbcf;
assign K[3] = 32'he9b5dba5;
assign K[4] = 32'h3956c25b;
assign K[5] = 32'h59f111f1;
assign K[6] = 32'h923f82a4;
assign K[7] = 32'hab1c5ed5;
assign K[8] = 32'hd807aa98;
assign K[9] = 32'h12835b01;
assign K[10] = 32'h243185be;
assign K[11] = 32'h550c7dc3;
assign K[12] = 32'h72be5d74;
assign K[13] = 32'h80deb1fe;
assign K[14] = 32'h9bdc06a7;
assign K[15] = 32'hc19bf174;
assign K[16] = 32'he49b69c1;
assign K[17] = 32'hefbe4786;
assign K[18] = 32'h0fc19dc6;
assign K[19] = 32'h240ca1cc;
assign K[20] = 32'h2de92c6f;
assign K[21] = 32'h4a7484aa;
assign K[22] = 32'h5cb0a9dc;
assign K[23] = 32'h76f988da;
assign K[24] = 32'h983e5152;
assign K[25] = 32'ha831c66d;
assign K[26] = 32'hb00327c8;
assign K[27] = 32'hbf597fc7;
assign K[28] = 32'hc6e00bf3;
assign K[29] = 32'hd5a79147;
assign K[30] = 32'h06ca6351;
assign K[31] = 32'h14292967;
assign K[32] = 32'h27b70a85;
assign K[33] = 32'h2e1b2138;
assign K[34] = 32'h4d2c6dfc;
assign K[35] = 32'h53380d13;
assign K[36] = 32'h650a7354;
assign K[37] = 32'h766a0abb;
assign K[38] = 32'h81c2c92e;
assign K[39] = 32'h92722c85;
assign K[40] = 32'ha2bfe8a1;
assign K[41] = 32'ha81a664b;
assign K[42] = 32'hc24b8b70;
assign K[43] = 32'hc76c51a3;
assign K[44] = 32'hd192e819;
assign K[45] = 32'hd6990624;
assign K[46] = 32'hf40e3585;
assign K[47] = 32'h106aa070;
assign K[48] = 32'h19a4c116;
assign K[49] = 32'h1e376c08;
assign K[50] = 32'h2748774c;
assign K[51] = 32'h34b0bcb5;
assign K[52] = 32'h391c0cb3;
assign K[53] = 32'h4ed8aa4a;
assign K[54] = 32'h5b9cca4f;
assign K[55] = 32'h682e6ff3;
assign K[56] = 32'h748f82ee;
assign K[57] = 32'h78a5636f;
assign K[58] = 32'h84c87814;
assign K[59] = 32'h8cc70208;
assign K[60] = 32'h90befffa;
assign K[61] = 32'ha4506ceb;
assign K[62] = 32'hbef9a3f7;
assign K[63] = 32'hc67178f2;

endmodule