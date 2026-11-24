`timescale 1ns / 1ps

`include "defs.svh"

module pipe_if_id (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        flush,
    input  logic [7:0]  if_pc,
    input  logic [7:0]  if_instr,

    output logic [7:0]  id_pc,
    output logic [7:0]  id_instr,
    output logic        id_valid
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_pc    <= RESET_VECTOR;
            id_instr <= 8'hE0;
            id_valid <= 1'b0;
        end else if (flush) begin
            id_pc    <= if_pc;
            id_instr <= 8'hE0;
            id_valid <= 1'b0;
        end else begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
            id_valid <= 1'b1;
        end
    end

endmodule
