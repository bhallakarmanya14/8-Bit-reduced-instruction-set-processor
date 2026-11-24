`timescale 1ns / 1ps

`include "defs.svh"

module core (
    input  logic        clk,
    input  logic        rst_n,

    output logic [7:0]  imem_addr,
    input  logic [7:0]  imem_rdata,

    output logic [7:0]  dmem_addr,
    output logic [7:0]  dmem_wdata,
    output logic        dmem_we,
    input  logic [7:0]  dmem_rdata,

    output logic [7:0]  pc_out,
    output logic [7:0]  wb_data_out,
    output logic [1:0]  wb_rd_out,
    output logic        wb_we_out,
    output logic        branch_taken_out,
    output logic        flush_active_out,
    output logic        zero_flag_out,
    output logic        carry_flag_out
);

    logic [7:0] pc_reg;
    logic [7:0] pc_next;
    logic       branch_taken;
    logic [7:0] branch_target;
    logic       flush_if_id;

    always_comb begin
        if (branch_taken)
            pc_next = branch_target;
        else
            pc_next = pc_reg + 8'd1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_reg <= RESET_VECTOR;
        else
            pc_reg <= pc_next;
    end

    assign imem_addr        = pc_reg;
    assign pc_out           = pc_reg;
    assign branch_taken_out = branch_taken;
    assign flush_active_out = flush_if_id;

    logic [7:0] if_id_pc;
    logic [7:0] if_id_instr;
    logic       if_id_valid;

    pipe_if_id u_pipe_if_id (
        .clk      (clk),
        .rst_n    (rst_n),
        .flush    (flush_if_id),
        .if_pc    (pc_reg),
        .if_instr (imem_rdata),
        .id_pc    (if_id_pc),
        .id_instr (if_id_instr),
        .id_valid (if_id_valid)
    );

    opcode_t    id_opcode;
    logic [1:0] id_rd_addr;
    logic [1:0] id_rs_addr;
    logic [2:0] id_imm;
    logic       id_reg_we;
    logic       id_mem_we;
    logic       id_is_load;
    logic       id_uses_rs;

    assign id_opcode  = opcode_t'(if_id_instr[7:5]);
    assign id_rd_addr = if_id_instr[4:3];
    assign id_rs_addr = if_id_instr[1:0];
    assign id_imm     = if_id_instr[2:0];

    always_comb begin
        id_reg_we  = 1'b0;
        id_mem_we  = 1'b0;
        id_is_load = 1'b0;
        id_uses_rs = 1'b0;

        if (if_id_valid) begin
            case (id_opcode)
                OP_LDI: begin
                    id_reg_we  = 1'b1;
                    id_uses_rs = 1'b0;
                end
                OP_ADD, OP_SUB, OP_AND: begin
                    id_reg_we  = 1'b1;
                    id_uses_rs = 1'b1;
                end
                OP_LD: begin
                    id_reg_we  = 1'b1;
                    id_is_load = 1'b1;
                    id_uses_rs = 1'b1;
                end
                OP_ST: begin
                    id_mem_we  = 1'b1;
                    id_uses_rs = 1'b1;
                end
                OP_BEQ: begin
                    id_uses_rs = 1'b0;
                end
                default: ;
            endcase
        end
    end

    logic [7:0] rf_rdata1;
    logic [7:0] rf_rdata2;
    logic [7:0] fwd_op_a;
    logic [7:0] fwd_op_b;
    logic       fwd_a_active;
    logic       fwd_b_active;
    logic [7:0] wb_final_data;

    logic [7:0]   mem_pc;
    logic [7:0]   mem_instr;
    opcode_t      mem_opcode;
    logic [1:0]   mem_rd_addr;
    logic         mem_reg_we;
    logic         mem_mem_we;
    logic         mem_is_load;
    logic [7:0]   mem_alu_res;
    logic [7:0]   mem_store_data;
    logic         mem_valid;

    forwarding_unit u_fwd_unit (
        .id_rd_addr    (id_rd_addr),
        .id_rs_addr    (id_rs_addr),
        .id_uses_rs    (id_uses_rs),
        .wb_reg_we     (mem_reg_we && mem_valid),
        .wb_rd_addr    (mem_rd_addr),
        .wb_write_data (wb_final_data),
        .rf_rdata1     (rf_rdata1),
        .rf_rdata2     (rf_rdata2),
        .fwd_op_a      (fwd_op_a),
        .fwd_op_b      (fwd_op_b),
        .fwd_a_active  (fwd_a_active),
        .fwd_b_active  (fwd_b_active)
    );

    logic [7:0] alu_result;
    logic       alu_zero;
    logic       alu_carry;

    alu u_alu (
        .opcode     (id_opcode),
        .op_a       (fwd_op_a),
        .op_b       (fwd_op_b),
        .imm        (id_imm),
        .alu_result (alu_result),
        .zero_flag  (alu_zero),
        .carry_flag (alu_carry)
    );

    hazard_unit u_hazard_unit (
        .id_opcode     (id_opcode),
        .id_valid      (if_id_valid),
        .id_pc         (if_id_pc),
        .id_imm        (id_imm),
        .id_op_a       (fwd_op_a),
        .branch_taken  (branch_taken),
        .branch_target (branch_target),
        .flush_if_id   (flush_if_id)
    );

    pipe_id_mem u_pipe_id_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .id_pc          (if_id_pc),
        .id_instr       (if_id_instr),
        .id_opcode      (id_opcode),
        .id_rd_addr     (id_rd_addr),
        .id_reg_we      (id_reg_we),
        .id_mem_we      (id_mem_we),
        .id_is_load     (id_is_load),
        .id_alu_res     (alu_result),
        .id_store_data  (fwd_op_a),
        .id_valid       (if_id_valid && !flush_if_id),
        .mem_pc         (mem_pc),
        .mem_instr      (mem_instr),
        .mem_opcode     (mem_opcode),
        .mem_rd_addr    (mem_rd_addr),
        .mem_reg_we     (mem_reg_we),
        .mem_mem_we     (mem_mem_we),
        .mem_is_load    (mem_is_load),
        .mem_alu_res    (mem_alu_res),
        .mem_store_data (mem_store_data),
        .mem_valid      (mem_valid)
    );

    assign dmem_addr  = mem_alu_res;
    assign dmem_wdata = mem_store_data;
    assign dmem_we    = mem_mem_we && mem_valid;

    assign wb_final_data = mem_is_load ? dmem_rdata : mem_alu_res;

    rf u_rf (
        .clk    (clk),
        .rst_n  (rst_n),
        .we     (mem_reg_we && mem_valid),
        .waddr  (mem_rd_addr),
        .wdata  (wb_final_data),
        .raddr1 (id_rd_addr),
        .rdata1 (rf_rdata1),
        .raddr2 (id_rs_addr),
        .rdata2 (rf_rdata2)
    );

    assign wb_data_out    = wb_final_data;
    assign wb_rd_out      = mem_rd_addr;
    assign wb_we_out      = mem_reg_we && mem_valid;
    assign zero_flag_out  = alu_zero;
    assign carry_flag_out = alu_carry;

endmodule
