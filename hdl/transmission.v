module transmission #(
    parameter SRAM_DATA_BW = 8,
    parameter SRAM_ADDR_BW = 5,
    parameter SHA_DATA_BW = 256,
    parameter AES_TXT_BW = 128,
    parameter AES_KEY_BW = 256
) (
	input clk,
	input srst_n,
	input enable,
    input mode,	                                                // encrypt: 0; decrypt: 1
	input [SRAM_DATA_BW-1:0] cph_sram_data,			            // SRAM data
    input [SHA_DATA_BW-1:0] sha2_o,                             // SHA2 output                                
    input [SHA_DATA_BW-1:0] sha3_o,                             // SHA3 output
    input sha2_done,                                            // SHA2 done                           
    input sha3_done,                                            // SHA3 done
    
	output reg [SRAM_ADDR_BW-1:0] cph_sram_addr,				// SRAM address
    output reg [AES_TXT_BW-1:0] aes_txt_msb,                    // AES text (MSB)
    output reg [AES_TXT_BW-1:0] aes_txt_lsb,                    // AES text (LSB)
    output reg [AES_KEY_BW-1:0] aes_key,                        // AES key
    output reg aes_enable                                       // AES enable
);

//==================================================================================================
//     FSM
//==================================================================================================
localparam IDLE = 3'b000;
localparam LOAD = 3'b001;
localparam WAIT = 3'b010;
localparam DONE = 3'b011;
reg [3-1:0] state_cipher, state_cipher_n;

always @(*) begin
    case (state_cipher)
        IDLE: begin
            if (enable) begin
                if (mode) state_cipher_n = LOAD;
                else state_cipher_n = DONE;
            end
            else state_cipher_n = IDLE;
        end

        LOAD: begin
            if (cph_sram_addr == 31) state_cipher_n = WAIT;
            else state_cipher_n = LOAD;
        end

        WAIT: begin
            state_cipher_n = DONE;
        end

        DONE: begin
            state_cipher_n = DONE;
        end

        default: begin
            state_cipher_n = IDLE;
        end
    endcase
end

//==================================================================================================
//     Register Declaration
//==================================================================================================
integer i;
reg [AES_TXT_BW*2-1:0] cipher, cipher_n;

always @(*) begin
    if (state_cipher == LOAD) begin
        for (i = 0; i <= AES_TXT_BW*2-SRAM_DATA_BW-1; i = i + 1) cipher_n[i+SRAM_DATA_BW] = cipher[i];
        cipher_n[SRAM_DATA_BW-1:0] = cph_sram_data;
    end

    else if (state_cipher == WAIT) begin
        for (i = 0; i <= AES_TXT_BW*2-SRAM_DATA_BW-1; i = i + 1) cipher_n[i+SRAM_DATA_BW] = cipher[i];
        cipher_n[SRAM_DATA_BW-1:0] = cph_sram_data;
    end

    else begin
        cipher_n = cipher;
    end
end

//==================================================================================================
//     Output Declaration
//==================================================================================================
reg [SRAM_ADDR_BW-1:0] cph_sram_addr_n;
reg [AES_TXT_BW-1:0] aes_txt_msb_n;
reg [AES_TXT_BW-1:0] aes_txt_lsb_n;
reg [AES_KEY_BW-1:0] aes_key_n;
reg aes_enable_n;

always @(*) begin
    if (state_cipher == LOAD) begin
        cph_sram_addr_n = cph_sram_addr + 1;
    end

    else begin
        cph_sram_addr_n = 0;
    end
end

always @(*) begin
    if (mode) begin
        aes_txt_msb_n = cipher[AES_TXT_BW*2-1:AES_TXT_BW];
        aes_txt_lsb_n = cipher[AES_TXT_BW-1:0];
        aes_key_n = sha2_o;
        aes_enable_n = sha2_done & (state_cipher == DONE);
    end

    else begin
        if (sha3_done) begin
            aes_txt_msb_n = sha3_o[AES_TXT_BW*2-1:AES_TXT_BW];
            aes_txt_lsb_n = sha3_o[AES_TXT_BW-1:0];
        end
        else begin
            aes_txt_msb_n = aes_txt_msb;
            aes_txt_lsb_n = aes_txt_lsb;
        end

        if (sha2_done) begin
            aes_key_n = sha2_o;
        end
        else begin
            aes_key_n = aes_key;
        end
        
        aes_enable_n = sha2_done & sha3_done;
    end
end

//==================================================================================================
//     DFF
//==================================================================================================
always @(posedge clk) begin
    if (~srst_n) begin
        // FSM
        state_cipher        <= IDLE;

        // Register
        cipher              <= 0;

        // Output
        cph_sram_addr       <= 0;
        aes_txt_msb         <= 0;
        aes_txt_lsb         <= 0;
        aes_key             <= 0;
        aes_enable          <= 0;
    end

    else begin
        // FSM
        state_cipher        <= state_cipher_n;

        // Register
        cipher              <= cipher_n;

        // Output
        cph_sram_addr       <= cph_sram_addr_n;
        aes_txt_msb         <= aes_txt_msb_n;
        aes_txt_lsb         <= aes_txt_lsb_n;
        aes_key             <= aes_key_n;
        aes_enable          <= aes_enable_n;    
    end
end
endmodule