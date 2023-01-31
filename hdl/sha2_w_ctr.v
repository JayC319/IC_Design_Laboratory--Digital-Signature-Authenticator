module sha2_w_ctr(
    input clk,
    input srst_n,
    input [5:0] rnd,
    input load_en,
    input [511:0] sha2_in,

    output reg [31:0] w
);

reg [31:0] w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15, w16, w17;
reg [31:0] w0_new, w1_new, w2_new, w3_new, w4_new, w5_new, w6_new, w7_new, w8_new, w9_new, w10_new, w11_new, w12_new, w13_new, w14_new, w15_new, w16_new, w17_new;
reg [31:0] delta1_w14, delta0_w1;
reg [31:0] delta1_w15, delta0_w2;


always @(*) begin
  // Prepare w17
  delta1_w15 = {w15[16:0], w15[31:17]} ^ {w15[18:0], w15[31:19]} ^ {10'b0000000000, w15[31:10]};
  delta0_w2 = {w2[6:0], w2[31:7]} ^ {w2[17:0], w2[31:18]} ^ {3'b000, w2[31:3]};
  w17_new = delta1_w15 + w10 + delta0_w2 + w1;
  if (rnd < 16) begin
    if (load_en) begin
      w0_new = sha2_in[511:480];
      w1_new = sha2_in[479:448];
      w2_new = sha2_in[447:416];
      w3_new = sha2_in[415:384];
      w4_new = sha2_in[383:352];
      w5_new = sha2_in[351:320];
      w6_new = sha2_in[319:288];
      w7_new = sha2_in[287:256];
      w8_new = sha2_in[255:224];
      w9_new = sha2_in[223:192];
      w10_new = sha2_in[191:160];
      w11_new = sha2_in[159:128];
      w12_new = sha2_in[127:96];
      w13_new = sha2_in[95:64];
      w14_new = sha2_in[63:32];
      w15_new = sha2_in[31:0];
    end
    else begin
      w0_new = w0;
      w1_new = w1;
      w2_new = w2;
      w3_new = w3;
      w4_new = w4;
      w5_new = w5;
      w6_new = w6;
      w7_new = w7;
      w8_new = w8;
      w9_new = w9;
      w10_new = w10;
      w11_new = w11;
      w12_new = w12;
      w13_new = w13;
      w14_new = w14;
      w15_new = w15;
    end
    // Prepare w16
    delta1_w14 = {w14[16:0], w14[31:17]} ^ {w14[18:0], w14[31:19]} ^ {10'b0000000000, w14[31:10]};
    delta0_w1 = {w1[6:0], w1[31:7]} ^ {w1[17:0], w1[31:18]} ^ {3'b000, w1[31:3]};
    w16_new = delta1_w14 + w9 + delta0_w1 + w0;
  end
  else if (rnd == 16) begin
    w0_new = w1;
    w1_new = w2;
    w2_new = w3;
    w3_new = w4;
    w4_new = w5;
    w5_new = w6;
    w6_new = w7;
    w7_new = w8;
    w8_new = w9;
    w9_new = w10;
    w10_new = w11;
    w11_new = w12;
    w12_new = w13;
    w13_new = w14;
    w14_new = w15;
    w15_new = w16;
    w16_new = w17;
  end
  else begin
    w0_new = w1;
    w1_new = w2;
    w2_new = w3;
    w3_new = w4;
    w4_new = w5;
    w5_new = w6;
    w6_new = w7;
    w7_new = w8;
    w8_new = w9;
    w9_new = w10;
    w10_new = w11;
    w11_new = w12;
    w12_new = w13;
    w13_new = w14;
    w14_new = w15;
    w15_new = w16;
    w16_new = w17_new;
  end
end

// Select w
always @(*) begin
  case(rnd)
    6'd0: w = w0;
    6'd1: w = w1;
    6'd2: w = w2;
    6'd3: w = w3;
    6'd4: w = w4;
    6'd5: w = w5;
    6'd6: w = w6;
    6'd7: w = w7;
    6'd8: w = w8;
    6'd9: w = w9;
    6'd10: w = w10;
    6'd11: w = w11;
    6'd12: w = w12;
    6'd13: w = w13;
    6'd14: w = w14;
    6'd15: w = w15;
    default: w = w16;
  endcase
end

always @(posedge clk) begin
  if (~srst_n) begin
    w0 <= 0;
    w1 <= 0;
    w2 <= 0;
    w3 <= 0;
    w4 <= 0;
    w5 <= 0;
    w6 <= 0;
    w7 <= 0;
    w8 <= 0;
    w9 <= 0;
    w10 <= 0;
    w11 <= 0;
    w12 <= 0;
    w13 <= 0;
    w14 <= 0;
    w15 <= 0;
    w16 <= 0;
    w17 <= 0;
  end
  else begin
    w0 <= w0_new;
    w1 <= w1_new;
    w2 <= w2_new;
    w3 <= w3_new;
    w4 <= w4_new;
    w5 <= w5_new;
    w6 <= w6_new;
    w7 <= w7_new;
    w8 <= w8_new;
    w9 <= w9_new;
    w10 <= w10_new;
    w11 <= w11_new;
    w12 <= w12_new;
    w13 <= w13_new;
    w14 <= w14_new;
    w15 <= w15_new;
    w16 <= w16_new;
    w17 <= w17_new;
  end
end

endmodule