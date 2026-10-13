`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 03:32:38 PM
// Design Name: 
// Module Name: program_counter
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


module program_counter (
    input            clk,
    input            rst,
    input            pc_en,
    input      [3:0] pc_next,
    output reg [3:0] pc_out
);
    always @(posedge clk) begin
        if (rst)
            pc_out <= 4'd0;
        else if (pc_en)
            pc_out <= pc_next;
    end
endmodule
