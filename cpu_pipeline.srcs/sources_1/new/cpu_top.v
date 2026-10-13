`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 03:43:58 PM
// Design Name: 
// Module Name: cpu_top
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


module cpu_top #(
    parameter PROGRAM_FILE = "program.mem" // Tên file chứa chương trình
)(
    input  clk,
    input  rst,
    // Các ngõ ra debug để quan sát trên dạng sóng (Waveform)
    output [3:0]  pc_out,        // Địa chỉ lệnh đang nạp
    output [11:0] instr_out,     // Lệnh đang ở giai đoạn EXECUTE
    output [3:0]  alu_out,       // Kết quả từ ALU
    output [3:0]  wb_data_out,   // Dữ liệu được ghi vào thanh ghi đích
    output        zero_out,      // Cờ Zero
    output        carry_out      // Cờ Carry
);

    // ======================================================================
    // CÁC DÂY TÍN HIỆU ĐIỀU KHIỂN DÙNG CHUNG (TỪ GIAI ĐOẠN EX DỘI NGƯỢC LẠI)
    // ======================================================================
    wire       pc_sel;   // Tín hiệu chọn địa chỉ nhảy (từ Branch Unit)
    wire       flush;    // Tín hiệu xóa đường ống (từ Branch Unit)
    wire [3:0] ex_imm;   // Địa chỉ nhảy (Immediate từ giai đoạn EX)

    // ======================================================================
    // STAGE 1: IF - FETCH (Nạp lệnh)
    // ======================================================================
    wire [3:0]  pc;
    wire [3:0]  pc_plus_1 = pc + 4'd1;
    wire [3:0]  pc_next;
    wire [11:0] fetched;

    // PC MUX: Chọn địa chỉ tiếp theo là PC+1 hay Địa chỉ nhảy
    mux2 PC_MUX (
        .d0 (pc_plus_1),
        .d1 (ex_imm),
        .sel(pc_sel),
        .y  (pc_next)
    );

    // Bộ đếm chương trình (PC)
    program_counter PC (
        .clk    (clk),
        .rst    (rst),
        .pc_en  (1'b1), // Luôn nạp lệnh mới mỗi chu kỳ
        .pc_next(pc_next),
        .pc_out (pc)
    );

    // Bộ nhớ lệnh (Instruction Memory)
    instruction_memory #(.PROGRAM_FILE(PROGRAM_FILE)) IMEM (
        .address    (pc),
        .instruction(fetched)
    );

    // Thanh ghi Pipeline IF/ID (Instruction Register - IR)
    wire [11:0] id_instr;
    wire [3:0]  id_pc;
    wire        id_valid;

    instruction_register IR (
        .clk            (clk),
        .rst            (rst),
        .ir_load        (1'b1), // Cập nhật mỗi chu kỳ
        .flush          (flush),
        .pc_in          (pc),
        .instruction_in (fetched),
        .instruction_out(id_instr),
        .pc_out         (id_pc),
        .valid_out      (id_valid)
    );

    // ======================================================================
    // STAGE 2: ID - DECODE (Giải mã lệnh)
    // ======================================================================
    wire [3:0] id_opcode = id_instr[11:8];
    wire [1:0] id_rd     = id_instr[7:6];
    wire [1:0] id_rs     = id_instr[5:4];
    wire [3:0] id_imm    = id_instr[3:0];

    wire [2:0] id_alu_ctrl;
    wire id_alu_src_sel, id_wb_sel, id_reg_we, id_mem_we;
    wire id_zero_we, id_carry_we, id_is_jmp, id_is_jz;
    
    wire ex_is_jmp, ex_is_jz;     // Lấy từ thanh ghi ID/EX
    wire zero_flag, carry_flag;   // Lấy từ thanh ghi cờ ở EX

    // Bộ điều khiển (Control Unit)
    control_unit CU (
        // Decode part (Lấy tín hiệu từ ID)
        .opcode      (id_opcode),
        .alu_ctrl    (id_alu_ctrl),
        .alu_src_sel (id_alu_src_sel),
        .wb_sel      (id_wb_sel),
        .reg_we      (id_reg_we),
        .mem_we      (id_mem_we),
        .zero_we     (id_zero_we),
        .carry_we    (id_carry_we),
        .is_jmp      (id_is_jmp),
        .is_jz       (id_is_jz),
        
        // Branch part (Lấy tín hiệu từ EX)
        .ex_is_jmp   (ex_is_jmp),
        .ex_is_jz    (ex_is_jz),
        .zero_flag   (zero_flag),
        .pc_sel      (pc_sel),
        .flush       (flush)
    );

    // Thanh ghi Pipeline ID/EX
    wire [2:0] ex_alu_ctrl;
    wire ex_alu_src_sel, ex_wb_sel, ex_reg_we, ex_mem_we;
    wire ex_zero_we, ex_carry_we;
    wire [1:0] ex_rd, ex_rs;
    wire [3:0] ex_pc;
    wire ex_valid;
    wire [11:0] ex_instr;

    pipeline_register ID_EX (
        .clk            (clk),
        .rst            (rst),
        .flush          (flush),
        
        // Từ ID đi vào
        .alu_ctrl_in    (id_alu_ctrl),
        .alu_src_sel_in (id_alu_src_sel),
        .wb_sel_in      (id_wb_sel),
        .reg_we_in      (id_reg_we),
        .mem_we_in      (id_mem_we),
        .zero_we_in     (id_zero_we),
        .carry_we_in    (id_carry_we),
        .is_jmp_in      (id_is_jmp),
        .is_jz_in       (id_is_jz),
        .rd_in          (id_rd),
        .rs_in          (id_rs),
        .imm_in         (id_imm),
        .pc_in          (id_pc),
        .valid_in       (id_valid),
        .instr_in       (id_instr),
        
        // Ra EX
        .alu_ctrl       (ex_alu_ctrl),
        .alu_src_sel    (ex_alu_src_sel),
        .wb_sel         (ex_wb_sel),
        .reg_we         (ex_reg_we),
        .mem_we         (ex_mem_we),
        .zero_we        (ex_zero_we),
        .carry_we       (ex_carry_we),
        .is_jmp         (ex_is_jmp),
        .is_jz          (ex_is_jz),
        .rd             (ex_rd),
        .rs             (ex_rs),
        .imm            (ex_imm),
        .pc             (ex_pc),
        .valid          (ex_valid),
        .instr          (ex_instr)
    );

    // ======================================================================
    // STAGE 3: EX - EXECUTE (Thực thi, bộ nhớ và ghi ngược)
    // ======================================================================
    wire [3:0] rd_value, rs_value;
    wire [3:0] alu_b;
    wire [3:0] alu_result;
    wire       alu_zero, alu_carry;
    wire [3:0] mem_data;
    wire [3:0] wb_data;

    // Tập thanh ghi (Register File)
    register_file RF (
        .clk (clk),
        .rst (rst),
        .ra  (ex_rd),      // Cổng A đọc Rd
        .rb  (ex_rs),      // Cổng B đọc Rs
        .wa  (ex_rd),      // Cổng Ghi vào Rd
        .wd  (wb_data),    // Dữ liệu ghi
        .we  (ex_reg_we),
        .qa  (rd_value),
        .qb  (rs_value)
    );

    // MUX chọn toán hạng B cho ALU (Rs hoặc Immediate)
    mux2 OPERAND_MUX (
        .d0  (rs_value),
        .d1  (ex_imm),
        .sel (ex_alu_src_sel),
        .y   (alu_b)
    );

    // ALU (Bộ số học và logic)
    alu ALU (
        .a        (rd_value),
        .b        (alu_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (alu_result),
        .carry    (alu_carry),
        .zero     (alu_zero)
    );

    // Thanh ghi cờ (Flag Register)
    flag_register FLAGS (
        .clk       (clk),
        .rst       (rst),
        .zero_we   (ex_zero_we),
        .carry_we  (ex_carry_we),
        .zero_in   (alu_zero),
        .carry_in  (alu_carry),
        .zero_flag (zero_flag),
        .carry_flag(carry_flag)
    );

    // Bộ nhớ dữ liệu (Data Memory)
    data_memory DMEM (
        .clk        (clk),
        .address    (alu_result), // Địa chỉ lấy từ kết quả ALU
        .write_data (rd_value),   // Dữ liệu ghi từ thanh ghi Rd
        .mem_we     (ex_mem_we),
        .read_data  (mem_data)
    );

    // MUX chọn dữ liệu ghi ngược (ALU Result hoặc Data Memory)
    mux2 WB_MUX (
        .d0  (alu_result),
        .d1  (mem_data),
        .sel (ex_wb_sel),
        .y   (wb_data)
    );

    // ======================================================================
    // NGÕ RA DEBUG
    // ======================================================================
    assign pc_out      = pc;
    assign instr_out   = ex_instr;
    assign alu_out     = alu_result;
    assign wb_data_out = wb_data;
    assign zero_out    = zero_flag;
    assign carry_out   = carry_flag;

endmodule
