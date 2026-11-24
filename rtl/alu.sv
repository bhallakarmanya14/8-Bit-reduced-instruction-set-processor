`timescale 1ns / 1ps

`include "defs.svh"

module alu (
    input  opcode_t    opcode,
    input  logic [7:0] op_a,
    input  logic [7:0] op_b,
    input  logic [2:0] imm,
    output logic [7:0] alu_result,
    output logic       zero_flag,
    output logic       carry_flag
);

    logic [8:0] arith_add;
    logic [8:0] arith_sub;

    assign arith_add = {1'b0, op_a} + {1'b0, op_b};
    assign arith_sub = {1'b0, op_a} - {1'b0, op_b};

    always_comb begin
        case (opcode)
            OP_LDI:  alu_result = {5'b00000, imm};
            OP_ADD:  alu_result = op_a + op_b;
            OP_SUB:  alu_result = op_a - op_b;
            OP_AND:  alu_result = op_a & op_b;
            OP_LD:   alu_result = op_b;
            OP_ST:   alu_result = op_b;
            OP_BEQ:  alu_result = 8'h00;
            default: alu_result = 8'h00;
        endcase
    end

    assign zero_flag  = (alu_result == 8'h00);
    assign carry_flag = (opcode == OP_ADD) ? arith_add[8] :
                        (opcode == OP_SUB) ? arith_sub[8] : 1'b0;

endmodule
