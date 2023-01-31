module verification #(
    parameter SHA_DATA_BW = 256,
    parameter AES_TXT_BW = 128
) 
(
	input clk,
	input srst_n,
    input mode,	                                                // encrypt: 0; decrypt: 1
    input [AES_TXT_BW-1:0] aes_msb_o,                           // AES output (MSB)
    input [AES_TXT_BW-1:0] aes_lsb_o,                           // AES output (LSB)                                
    input [SHA_DATA_BW-1:0] sha3_o,                             // SHA3 output
    input aes_msb_done,                                         // AES done (MSB)
    input aes_lsb_done,                                         // AES done (LSB)                  
    input sha3_done,                                            // SHA3 done
    
    output reg [64-1:0] cipher_o,                               // cypher (for encrypt)
    output reg verify,                                          // different: 0; same: 1
    output reg valid                                            // AES key
);

//==================================================================================================
//     FSM
//==================================================================================================
localparam IDLE = 3'b000;
localparam ENCRYPT = 3'b001;
localparam COMP = 3'b010;
localparam DECRYPT = 3'b011;
localparam DONE = 3'b100;
reg [3-1:0] state_vrfy, state_vrfy_n;
reg [2-1:0] cnt, cnt_n;

always @(*) begin
    case (state_vrfy)
        IDLE: begin
            if (mode) begin
                if (aes_msb_done & aes_lsb_done & sha3_done) state_vrfy_n = COMP;
                else state_vrfy_n = IDLE;
            end
            else begin
                if (aes_msb_done & aes_lsb_done) state_vrfy_n = ENCRYPT;
                else state_vrfy_n = IDLE;
            end
        end

        ENCRYPT: begin
            if (cnt == 3) state_vrfy_n = DONE;
            else state_vrfy_n = ENCRYPT;
        end

        COMP: begin
            state_vrfy_n = DECRYPT;
        end

        DECRYPT: begin
            state_vrfy_n = DONE;
        end

        DONE: begin
            state_vrfy_n = DONE;
        end

        default: begin
            state_vrfy_n = IDLE;
        end
    endcase
end

//==================================================================================================
//     counter 
//==================================================================================================
always @(*) begin
	if (state_vrfy == ENCRYPT) begin
		cnt_n = cnt + 1;
	end

	else begin
		cnt_n = 0;
	end
end

//==================================================================================================
//     cipher_o
//==================================================================================================
always @(*) begin
	if (state_vrfy == ENCRYPT) begin
		case (cnt)
            0: cipher_o = aes_msb_o[127:64];
            1: cipher_o = aes_msb_o[63:0];
            2: cipher_o = aes_lsb_o[127:64];
            3: cipher_o = aes_lsb_o[63:0];
            default: cipher_o = 0;
        endcase
	end

	else begin
		cipher_o = 0;
	end
end

//==================================================================================================
//     valid
//==================================================================================================
always @(*) begin
	if (state_vrfy == ENCRYPT) begin
		valid = 1;
	end

    else if (state_vrfy == DECRYPT) begin
		valid = 1;
	end

	else begin
		valid = 0;
	end
end

//==================================================================================================
//     verify
//==================================================================================================
reg verify_n;

always @(*) begin
    if (state_vrfy == COMP) begin
		verify_n = (sha3_o == {aes_msb_o, aes_lsb_o});
	end

	else begin
		verify_n = 0;
	end
end

//==================================================================================================
//     sequential circuit 
//==================================================================================================
always @(posedge clk) begin
	if(~srst_n) begin
		state_vrfy  <= IDLE;
		cnt	        <= 0;
        verify      <= 0;
	end

	else begin
		state_vrfy  <= state_vrfy_n;
		cnt         <= cnt_n;
        verify      <= verify_n;
	end
end

endmodule