`timescale 1ns / 1ps

`include "defs.svh"

module bus_interconnect (
    input  logic [7:0]  imem_addr,
    output logic [7:0]  imem_rdata,

    input  logic [7:0]  dmem_addr,
    input  logic [7:0]  dmem_wdata,
    input  logic        dmem_we,
    output logic [7:0]  dmem_rdata,

    output logic        ram_cs,
    output logic        ram_we,
    output logic [6:0]  ram_addr,
    output logic [7:0]  ram_wdata,
    input  logic [7:0]  ram_rdata,

    output logic        io_cs,
    output logic        io_we,
    output logic [7:0]  io_addr,
    output logic [7:0]  io_wdata,
    input  logic [7:0]  io_rdata,

    output logic        rom_cs,
    output logic [5:0]  rom_addr,
    input  logic [7:0]  rom_rdata
);

    assign rom_cs     = (imem_addr >= ROM_BASE_ADDR) && (imem_addr <= ROM_LAST_ADDR);
    assign rom_addr   = imem_addr[5:0];
    assign imem_rdata = rom_cs ? rom_rdata : 8'hE0;

    always @* begin
        ram_cs    = 1'b0;
        ram_we    = 1'b0;
        ram_addr  = dmem_addr[6:0];
        ram_wdata = dmem_wdata;

        io_cs     = 1'b0;
        io_we     = 1'b0;
        io_addr   = dmem_addr;
        io_wdata  = dmem_wdata;

        if (dmem_addr <= SRAM_LAST_ADDR) begin
            ram_cs = 1'b1;
            ram_we = dmem_we;
        end else if (dmem_addr >= MMIO_IN_ADDR && dmem_addr <= MMIO_OPT_ADDR) begin
            io_cs = 1'b1;
            io_we = dmem_we;
        end
    end

    always @* begin
        if (dmem_addr <= SRAM_LAST_ADDR)
            dmem_rdata = ram_rdata;
        else if (dmem_addr >= MMIO_IN_ADDR && dmem_addr <= MMIO_OPT_ADDR)
            dmem_rdata = io_rdata;
        else if ((dmem_addr >= ROM_BASE_ADDR) && (dmem_addr <= ROM_LAST_ADDR))
            dmem_rdata = rom_rdata;
        else
            dmem_rdata = 8'h00;
    end

endmodule
