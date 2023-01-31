//==================================================================================================
//  Note:          Use only for teaching materials of IC Design Lab, NTHU.
//  Copyright: (c) 2022 Vision Circuits and Systems Lab, NTHU, Taiwan. ALL Rights Reserved.
//==================================================================================================


module sram_2048x64b #(
parameter BLOCK_SIZE_PER_SRAM = 2048,
parameter BW_SRAM_ADDR = 11,
parameter BW_SRAM_DATA = 64
)
(
input clk,
input csb,  //chip enable
input wsb,  //write enable
input [BW_SRAM_DATA-1:0] wdata, //write data
input [BW_SRAM_ADDR-1:0] waddr, //write address
input [BW_SRAM_ADDR-1:0] raddr, //read address

output reg [BW_SRAM_DATA-1:0] rdata
);

reg [BW_SRAM_DATA-1:0] mem [0:BLOCK_SIZE_PER_SRAM-1];
reg [BW_SRAM_DATA-1:0] _rdata;

always @(posedge clk) begin
    if(~csb && ~wsb)
        mem[waddr] <= wdata;
end

always @(posedge clk) begin
    if(~csb)
        _rdata <= mem[raddr];
end

always @* begin
    rdata = #(1) _rdata;
end

task load_msg(
    input integer idx,
    input [BW_SRAM_DATA-1:0] msg
);
    mem[idx] = msg;
endtask

task reset_sram;
    integer i;
    begin
        for(i = 0; i < BLOCK_SIZE_PER_SRAM;i = i + 1) begin
            mem[i] = 64'b0;
        end
    end
endtask

endmodule