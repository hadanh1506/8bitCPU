`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 03:33:33 PM
// Design Name: 
// Module Name: data_memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_memory (
    input            clk,
    input      [3:0] address,
    input      [3:0] write_data,
    input            mem_we,
    output     [3:0] read_data
);
    reg [3:0] mem [0:15];
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = 4'b0000;
    end

    always @(posedge clk) begin
        if (mem_we)
            mem[address] <= write_data;
    end

    assign read_data = mem[address];
endmodule
