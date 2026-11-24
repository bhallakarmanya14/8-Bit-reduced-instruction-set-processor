`timescale 1ns / 1ps

`include "defs.svh"

module top (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  port_in,
    input  logic [1:0]  opt_pins,
    output logic [7:0]  port_out,
    output logic [3:0]  flags_out,

    output logic [7:0]  pc_out,
    output logic [7:0]  wb_data_out,
    output logic [1:0]  wb_rd_out,
    output logic        wb_we_out,
    output logic        branch_taken_out,
    output logic        flush_active_out
);

    logic [7:0] imem_addr;
    logic [7:0] imem_rdata;
    logic [7:0] dmem_addr;
    logic [7:0] dmem_wdata;
    logic       dmem_we;
    logic [7:0] dmem_rdata;

    logic       zero_flag;
    logic       carry_flag;

    assign flags_out = {zero_flag, carry_flag, branch_taken_out, flush_active_out};

    core u_core (
        .clk              (clk),
        .rst_n            (rst_n),
        .imem_addr        (imem_addr),
        .imem_rdata       (imem_rdata),
        .dmem_addr        (dmem_addr),
        .dmem_wdata       (dmem_wdata),
        .dmem_we          (dmem_we),
        .dmem_rdata       (dmem_rdata),
        .zero_flag_out    (zero_flag),
        .carry_flag_out   (carry_flag),
        .pc_out           (pc_out),
        .wb_data_out      (wb_data_out),
        .wb_rd_out        (wb_rd_out),
        .wb_we_out        (wb_we_out),
        .branch_taken_out (branch_taken_out),
        .flush_active_out (flush_active_out)
    );

    logic       ram_cs;
    logic       ram_we;
    logic [6:0] ram_addr;
    logic [7:0] ram_wdata;
    logic [7:0] ram_rdata;

    logic       io_cs;
    logic       io_we;
    logic [7:0] io_addr;
    logic [7:0] io_wdata;
    logic [7:0] io_rdata;

    logic       rom_cs;
    logic [5:0] rom_addr;
    logic [7:0] rom_rdata;

    bus_interconnect u_bus_interconnect (
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_we    (dmem_we),
        .dmem_rdata (dmem_rdata),
        .ram_cs     (ram_cs),
        .ram_we     (ram_we),
        .ram_addr   (ram_addr),
        .ram_wdata  (ram_wdata),
        .ram_rdata  (ram_rdata),
        .io_cs      (io_cs),
        .io_we      (io_we),
        .io_addr    (io_addr),
        .io_wdata   (io_wdata),
        .io_rdata   (io_rdata),
        .rom_cs     (rom_cs),
        .rom_addr   (rom_addr),
        .rom_rdata  (rom_rdata)
    );

    ram u_ram (
        .clk    (clk),
        .rst_n  (rst_n),
        .ram_cs (ram_cs),
        .ram_we (ram_we),
        .addr   (ram_addr),
        .wdata  (ram_wdata),
        .rdata  (ram_rdata)
    );

    rom u_rom (
        .rom_cs (rom_cs),
        .addr   (rom_addr),
        .rdata  (rom_rdata)
    );

    io u_io (
        .clk      (clk),
        .rst_n    (rst_n),
        .io_cs    (io_cs),
        .io_we    (io_we),
        .io_addr  (io_addr),
        .wdata    (io_wdata),
        .rdata    (io_rdata),
        .port_in  (port_in),
        .opt_pins (opt_pins),
        .port_out (port_out)
    );

endmodule
