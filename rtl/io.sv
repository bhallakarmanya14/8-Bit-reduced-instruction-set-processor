`timescale 1ns / 1ps

`include "defs.svh"

module io (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        io_cs,
    input  logic        io_we,
    input  logic [7:0]  io_addr,
    input  logic [7:0]  wdata,
    output logic [7:0]  rdata,

    input  logic [7:0]  port_in,
    input  logic [1:0]  opt_pins,
    output logic [7:0]  port_out
);

    logic [7:0] out_reg;

    assign port_out = out_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_reg <= 8'h00;
        end else if (io_cs && io_we && (io_addr == MMIO_OUT_ADDR)) begin
            out_reg <= wdata;
        end
    end

    always_comb begin
        if (io_cs) begin
            case (io_addr)
                MMIO_IN_ADDR:  rdata = port_in;
                MMIO_OUT_ADDR: rdata = out_reg;
                MMIO_OPT_ADDR: rdata = {6'b000000, opt_pins};
                default:       rdata = 8'h00;
            endcase
        end else begin
            rdata = 8'h00;
        end
    end

endmodule
