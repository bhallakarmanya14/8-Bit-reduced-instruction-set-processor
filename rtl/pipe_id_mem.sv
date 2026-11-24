`timescale 1ns / 1ps

`include "defs.svh"

module pipe_id_mem (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [7:0]   id_pc,
    input  logic [7:0]   id_instr,
    input  opcode_t      id_opcode,
    input  logic [1:0]   id_rd_addr,
    input  logic         id_reg_we,
    input  logic         id_mem_we,
    input  logic         id_is_load,
    input  logic [7:0]   id_alu_res,
    input  logic [7:0]   id_store_data,
    input  logic         id_valid,

    output logic [7:0]   mem_pc,
    output logic [7:0]   mem_instr,
    output opcode_t      mem_opcode,
    output logic [1:0]   mem_rd_addr,
    output logic         mem_reg_we,
    output logic         mem_mem_we,
    output logic         mem_is_load,
    output logic [7:0]   mem_alu_res,
    output logic [7:0]   mem_store_data,
    output logic         mem_valid
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_pc         <= RESET_VECTOR;
            mem_instr      <= 8'hE0;
            mem_opcode     <= OP_NOP;
            mem_rd_addr    <= 2'b00;
            mem_reg_we     <= 1'b0;
            mem_mem_we     <= 1'b0;
            mem_is_load    <= 1'b0;
            mem_alu_res    <= 8'h00;
            mem_store_data <= 8'h00;
            mem_valid      <= 1'b0;
        end else begin
            mem_pc         <= id_pc;
            mem_instr      <= id_instr;
            mem_opcode     <= id_opcode;
            mem_rd_addr    <= id_rd_addr;
            mem_reg_we     <= id_reg_we;
            mem_mem_we     <= id_mem_we;
            mem_is_load    <= id_is_load;
            mem_alu_res    <= id_alu_res;
            mem_store_data <= id_store_data;
            mem_valid      <= id_valid;
        end
    end

endmodule
