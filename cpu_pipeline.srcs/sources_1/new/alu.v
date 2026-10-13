`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 10:47:25 AM
// Design Name: 
// Module Name: alu
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


//====
// FILE: alu.v
// Vỏ bọc (Wrapper) kết nối code cũ vào chuẩn CPU mới
//====

// 1. Module dò cờ Zero (Yêu cầu mới của kiến trúc CPU)
module zero_detector (
    input  [3:0] value,
    output       zero
);
    assign zero = (value == 4'b0000) ? 1'b1 : 1'b0;
endmodule

// 2. Module ALU chính (Top-level của khối ALU)
module alu (
    input  [3:0] a,
    input  [3:0] b,
    input  [2:0] alu_ctrl,
    output reg [3:0] result,
    output reg       carry,
    output           zero
);

    // --- GỌI MODULE CỘNG/TRỪ CŨ CỦA BẠN ---
    wire [3:0] arith_result;
    wire       arith_carry;
    wire       c3_out; // Không dùng trong kiến trúc này nhưng cứ nối ra
    
    wire do_sub = (alu_ctrl == 3'd1); // Nếu alu_ctrl = 1 thì báo cho mạch cũ thực hiện trừ

    // LƯU Ý 1: Hãy kiểm tra file adder_subtractor_4bit.v cũ của bạn.
    // Nếu tên port kết quả là "sum" hoặc "result", và cờ nhớ là "c4" hay "cout", 
    // hãy sửa lại tên ở phần có dấu chấm phía dưới cho khớp nhé.
    adder_subtractor_4bit ADDSUB (
        .a(a), 
        .b(b), 
        .sub(do_sub), 
        .sum(arith_result), // Thay .sum bằng tên port kết quả của bạn nếu khác
        .c4(arith_carry),   // Thay .c4 bằng tên port carry-out của bạn nếu khác
        .c3(c3_out)
    );

    // --- GỌI MODULE LOGIC CŨ CỦA BẠN ---
    wire [3:0] out_and, out_or, out_xor, out_not;

    // LƯU Ý 2: Kiểm tra file logic_unit_4bit.v cũ để đảm bảo các tên port 
    // .and_out, .or_out... khớp với khai báo của bạn.
    logic_unit_4bit LOGIC (
        .a(a), 
        .b(b),
        .and_out(out_and),
        .or_out(out_or),
        .xor_out(out_xor),
        .not_out(out_not)
    );

    // --- MULTIPLEXER CHỌN KẾT QUẢ (Dựa trên bảng mã alu_ctrl mới) ---
    always @(*) begin
        case (alu_ctrl)
            3'd0: begin result = arith_result; carry = arith_carry; end // ADD
            3'd1: begin result = arith_result; carry = arith_carry; end // SUB 
            3'd2: begin result = out_and; carry = 1'b0; end             // AND
            3'd3: begin result = out_or;  carry = 1'b0; end             // OR
            3'd4: begin result = out_xor; carry = 1'b0; end             // XOR
            3'd5: begin result = out_not; carry = 1'b0; end             // NOT
            3'd6: begin result = b;       carry = 1'b0; end             // PASS (Dùng cho LDI, MOV, LOAD, STORE)
            default: begin result = 4'b0000; carry = 1'b0; end
        endcase
    end

    // --- TÍNH CỜ ZERO ---
    zero_detector ZERO (
        .value(result),
        .zero(zero)
    );

endmodule
