`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2026 03:34:53 PM
// Design Name: 
// Module Name: full_adder
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


module full_adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    wire p; // propagate (lan truyền) = a ^ b
    wire g; // generate  (tạo nhớ) = a & b
    wire pc;
    
    xor x1 (p, a, b);       // p = a ^ b
    xor x2 (sum, p, cin);   // sum = p ^ cin
    
    and a1 (g, a, b);       // g = a & b
    and a2 (pc, p, cin);    // pc = p & cin
    or o1 (cout, g, pc);    // cout = g | pc
endmodule
