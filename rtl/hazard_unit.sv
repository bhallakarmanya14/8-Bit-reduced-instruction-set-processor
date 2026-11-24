`timescale 1ns / 1ps

`include "defs.svh"

module hazard_unit (
    input  opcode_t    id_opcode,
    input  logic       id_valid,
    input  logic [7:0] id_pc,
    input  logic [2:0] id_imm,
    input  logic [7:0] id_op_a,

    output logic       branch_taken,
    output logic [7:0] branch_target,
    output logic       flush_if_id
);

    logic [7:0] sign_ext_offset;

    assign sign_ext_offset = {{5{id_imm[2]}}, id_imm[2:0]};

    always_comb begin
        if (id_valid && (id_opcode == OP_BEQ) && (id_op_a == 8'h00)) begin
            branch_taken  = 1'b1;
            branch_target = id_pc + sign_ext_offset;
            flush_if_id   = 1'b1;
        end else begin
            branch_taken  = 1'b0;
            branch_target = 8'h00;
            flush_if_id   = 1'b0;
        end
    end

endmodule
