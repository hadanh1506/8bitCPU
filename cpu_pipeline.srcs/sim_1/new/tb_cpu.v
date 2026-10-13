`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 03:53:21 PM
// Design Name: 
// Module Name: tb_cpu
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


`timescale 1ns / 1ps
// FILE: tb_cpu.v
// CPU-LEVEL TEST: Chạy các chương trình trên CPU Pipeline hoàn chỉnh.

module tb_cpu;
    reg clk = 0;
    reg rst = 1;
    integer errors = 0;
    integer checks = 0;
    integer cycle = 0;
    integer i;
    reg show_pipeline = 0;

    always #5 clk = ~clk;

    wire [3:0] pc_out, alu_out, wb_data_out;
    wire [11:0] instr_out;
    wire zero_out, carry_out;

    cpu_top #(.PROGRAM_FILE("program.mem")) CPU (
        .clk(clk), .rst(rst),
        .pc_out(pc_out), .instr_out(instr_out), .alu_out(alu_out),
        .wb_data_out(wb_data_out), .zero_out(zero_out), .carry_out(carry_out)
    );

    always @(posedge clk) begin
        if (rst) cycle <= 0;
        else cycle <= cycle + 1;
    end

    always @(negedge clk) begin
        if (!rst && show_pipeline) begin
            $write(" cycle %2d | IF: addr %2d | ID: ", cycle + 1, CPU.pc);
            if (CPU.id_valid) $write("%h (addr %2d)", CPU.id_instr, CPU.id_pc);
            else $write("bubble         ");
            $write(" | EX: ");
            if (CPU.ex_valid) $write("%h (addr %2d)", CPU.ex_instr, CPU.ex_pc);
            else $write("bubble         ");
            $display(" | R1=%b R2=%b R3=%b", CPU.RF.r1, CPU.RF.r2, CPU.RF.r3);
        end
        else if (!rst && CPU.ex_valid)
            $display(" EX addr %2d: %h | R0=%b R1=%b R2=%b R3=%b | Z=%b C=%b",
                     CPU.ex_pc, CPU.ex_instr, CPU.RF.r0, CPU.RF.r1, CPU.RF.r2, CPU.RF.r3,
                     zero_out, carry_out);
    end

    task reset_cpu;
        begin
            rst = 1;
            @(posedge clk); @(posedge clk); #1;
            rst = 0;
        end
    endtask

    task load_program;
        input [8*20:1] file_name;
        begin
            rst = 1;
            for (i=0; i<16; i=i+1) begin
                CPU.IMEM.mem[i] = 12'hC00;
                CPU.DMEM.mem[i] = 4'b0000;
            end
            $readmemh(file_name, CPU.IMEM.mem);
        end
    endtask

    task finish_instr;
        input [3:0] addr;
        begin
            @(negedge clk);
            while (!(CPU.ex_valid && CPU.ex_pc == addr))
                @(negedge clk);
            @(posedge clk);
            #1;
        end
    endtask

    task check;
        input [8*44:1] name;
        input [3:0] actual;
        input [3:0] expected;
        begin
            checks = checks + 1;
            if (actual === expected) $display("PASS %0s = %b", name, actual);
            else begin
                $display("FAIL %0s = %b (expected %b)", name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    task check_bit;
        input [8*44:1] name;
        input actual;
        input expected;
        begin
            checks = checks + 1;
            if (actual === expected) $display("PASS %0s = %b", name, actual);
            else begin
                $display("FAIL %0s = %b (expected %b)", name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $display("\n===== TEST 1: demonstration program (program.mem) =====");
        show_pipeline = 1;
        reset_cpu;
        finish_instr(2);
        check("ADD R1,R2 -> R1 (5+3)", CPU.RF.r1, 4'b1000);
        finish_instr(4);
        check("LDI R3,1010 -> R3", CPU.RF.r3, 4'b1010);
        check("XOR R1,R3 -> R1", CPU.RF.r1, 4'b0010);
        check("R2 still 0011", CPU.RF.r2, 4'b0011);
        $display("     5 instructions finished after %0d clock cycles", cycle);
        finish_instr(5);
        check("JMP 0101: PC (fetch address) = 5", pc_out, 4'd5);
        finish_instr(5);
        show_pipeline = 0;
        check("JMP runs again: program loops at 5", pc_out, 4'd5);

        $display("\n===== TEST 2: arithmetic and memory (prog_arith.mem) =====");
        load_program("prog_arith.mem");
        reset_cpu;
        finish_instr(2);
        check("ADD R1,R2 (0101+0011) -> R1", CPU.RF.r1, 4'b1000);
        check_bit("ADD: Carry", carry_out, 1'b0);
        check_bit("ADD: Zero", zero_out, 1'b0);
        finish_instr(3);
        check("STORE R1,0 -> data_memory[0]", CPU.DMEM.mem[0], 4'b1000);
        finish_instr(5);
        check("SUB R1,R2 (0101-0011) -> R1", CPU.RF.r1, 4'b0010);
        check_bit("SUB: Zero", zero_out, 1'b0);
        check_bit("SUB: Carry (1 = no borrow)", carry_out, 1'b1);
        finish_instr(6);
        check("STORE R1,1 -> data_memory[1]", CPU.DMEM.mem[1], 4'b0010);
        finish_instr(7);
        check("LOAD R0,0 -> R0", CPU.RF.r0, 4'b1000);
        finish_instr(8);
        check("SUB R2,R2 -> R2", CPU.RF.r2, 4'b0000);
        check_bit("Zero flag after 0000 result", zero_out, 1'b1);
        $display("     9 instructions finished after %0d clock cycles (pipeline: 9+2)", cycle);

        $display("\n===== TEST 3: logic operations (prog_logic.mem) =====");
        load_program("prog_logic.mem");
        reset_cpu;
        finish_instr(3);
        check("AND 1100, 1010 -> R3", CPU.RF.r3, 4'b1000);
        finish_instr(5);
        check("OR 1100, 1010 -> R3", CPU.RF.r3, 4'b1110);
        finish_instr(6);
        check("XOR 1100,1010 -> R1", CPU.RF.r1, 4'b0110);
        finish_instr(7);
        check("MOV R2, R1 (R1=0110) -> R2", CPU.RF.r2, 4'b0110);
        finish_instr(9);
        check("NOT 0101 -> R0", CPU.RF.r0, 4'b1010);
        finish_instr(10);
        check("LDI R3,1010 -> R3", CPU.RF.r3, 4'b1010);
        finish_instr(11);
        check("XOR R3,R3 -> R3", CPU.RF.r3, 4'b0000);
        check_bit("Zero flag after 0000 result", zero_out, 1'b1);
        $display("     12 instructions finished after %0d clock cycles (pipeline: 12+2)", cycle);

        $display("\n===== TEST 4: PC and jumps (prog_jump.mem) =====");
        load_program("prog_jump.mem");
        rst = 1; @(posedge clk); @(posedge clk); #1; rst = 0;
        check("PC after reset", pc_out, 4'd0);
        @(posedge clk); #1;
        check("PC increment (0->1)", pc_out, 4'd1);
        finish_instr(1);
        check("JMP 4: PC becomes 0100", pc_out, 4'b0100);
        check_bit("JMP flushed the ID/EX register", CPU.ex_valid, 1'b0);
        finish_instr(5);
        check_bit("SUB R1, R1 sets Zero", zero_out, 1'b1);
        finish_instr(6);
        check("JZ 9 taken: PC=9", pc_out, 4'd9);
        finish_instr(10);
        check_bit("ADD R3, R3 clears Zero", zero_out, 1'b0);
        finish_instr(11);
        check("JZ 14 not taken: next in EX is addr 12", CPU.ex_pc, 4'd12);
        finish_instr(13);
        check("R0=1 (JMP skipped addresses 2, 3)", CPU.RF.r0, 4'd1);
        check("R2=6 (JZ skipped 7, 8; 14 never ran)", CPU.RF.r2, 4'd6);
        check("Program stops at PC=13", pc_out, 4'd13);

        $display("\n===== TEST 5: reset =====");
        rst = 1; @(posedge clk); #1;
        check("PC after reset", pc_out, 4'd0);
        check("R0 after reset", CPU.RF.r0, 4'd0);
        check("R2 after reset", CPU.RF.r2, 4'd0);
        check_bit("Zero after reset", zero_out, 1'b0);
        check_bit("Carry after reset", carry_out, 1'b0);
        check_bit("IF/ID empty after reset", CPU.id_valid, 1'b0);
        check_bit("ID/EX empty after reset", CPU.ex_valid, 1'b0);
        rst = 0;
        repeat (6) @(posedge clk); #1;
        checks = checks + 1;
        if (^{pc_out, instr_out, alu_out, wb_data_out, zero_out, carry_out,
              CPU.RF.r0, CPU.RF.r1, CPU.RF.r2, CPU.RF.r3} === 1'bx) begin
            $display("FAIL unknown (X) value found on key outputs");
            errors = errors + 1;
        end else
            $display("PASS no unknown (X) values on key outputs or registers");

        $display("\n=======================================================");
        if (errors == 0) $display("tb_cpu PASSED: %0d of %0d checks OK", checks, checks);
        else $display("tb_cpu FAILED: %0d of %0d checks failed", errors, checks);
        $display("=======================================================\n");
        $finish;
    end
endmodule
