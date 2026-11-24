`timescale 1ns / 1ps

`include "defs.svh"

module ram (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        ram_cs,
    input  logic        ram_we,
    input  logic [6:0]  addr,
    input  logic [7:0]  wdata,
    output logic [7:0]  rdata
);

    logic [7:0] mem_array [0:127];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 128; i++)
                mem_array[i] <= 8'h00;
        end else if (ram_cs && ram_we) begin
            mem_array[addr] <= wdata;
        end
    end

    always_comb begin
        if (ram_cs)
            rdata = mem_array[addr];
        else
            rdata = 8'h00;
    end

endmodule
