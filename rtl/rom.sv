`timescale 1ns / 1ps

`include "defs.svh"

module rom (
    input  logic        rom_cs,
    input  logic [5:0]  addr,
    output logic [7:0]  rdata
);

    logic [7:0] rom_array [0:63];

    always_comb begin
        if (rom_cs)
            rdata = rom_array[addr];
        else
            rdata = 8'hE0;
    end

    initial begin

        for (int i = 0; i < 64; i++)
            rom_array[i] = 8'hE0;

        rom_array[0]  = {OP_LDI, 2'd1, 3'd1};
        rom_array[1]  = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[2]  = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[3]  = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[4]  = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[5]  = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[6]  = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[7]  = {OP_ADD, 2'd1, 1'b0, 2'd1};

        rom_array[8]  = {OP_LD,  2'd2, 1'b0, 2'd1};
        rom_array[9]  = {OP_LDI, 2'd3, 3'd1};
        rom_array[10] = {OP_ADD, 2'd3, 1'b0, 2'd1};
        rom_array[11] = {OP_ST,  2'd2, 1'b0, 2'd3};

        rom_array[12] = {OP_LDI, 2'd1, 3'd4};
        rom_array[13] = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[14] = {OP_ADD, 2'd1, 1'b0, 2'd1};
        rom_array[15] = {OP_ST,  2'd2, 1'b0, 2'd1};

        rom_array[16] = {OP_BEQ, 2'd0, 3'd2};
        rom_array[17] = {OP_NOP, 2'd0, 3'd0};
        rom_array[18] = {OP_LDI, 2'd3, 3'd7};
    end

endmodule
