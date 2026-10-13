`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2026 03:00:20 PM
// Design Name: 
// Module Name: logic_unit_4bit
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


module logic_unit_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] and_out,  // a & b
    output wire [3:0] or_out,   // a | b
    output wire [3:0] xor_out,  // a ^ b
    output wire [3:0] not_out   // ~a
);
    assign and_out = a & b;
    assign or_out  = a | b;
    assign xor_out = a ^ b;
    assign not_out = ~a;
endmodule
