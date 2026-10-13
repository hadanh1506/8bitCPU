`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 03:33:07 PM
// Design Name: 
// Module Name: instruction_memory
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


module instruction_memory #(
    parameter PROGRAM_FILE = "program.mem" 
)(
    input  [3:0]  address,
    output [11:0] instruction
);
    reg [11:0] mem [0:15];
    integer i;

    initial begin
        // Khởi tạo toàn bộ bằng mã C00 (Lệnh NOP dự phòng) để tránh giá trị X
        for (i = 0; i < 16; i = i + 1)
            mem[i] = 12'hC00;
        
        $readmemh(PROGRAM_FILE, mem);
    end

    assign instruction = mem[address];
endmodule
