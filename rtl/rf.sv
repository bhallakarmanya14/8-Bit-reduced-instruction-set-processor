`timescale 1ns / 1ps

module rf (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        we,
    input  logic [1:0]  waddr,
    input  logic [7:0]  wdata,

    input  logic [1:0]  raddr1,
    output logic [7:0]  rdata1,

    input  logic [1:0]  raddr2,
    output logic [7:0]  rdata2
);

    logic [7:0] regs [1:3];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regs[1] <= 8'h00;
            regs[2] <= 8'h00;
            regs[3] <= 8'h00;
        end else if (we && (waddr != 2'b00)) begin
            regs[waddr] <= wdata;
        end
    end

    always_comb begin
        if (raddr1 == 2'b00)
            rdata1 = 8'h00;
        else if (we && (waddr == raddr1))
            rdata1 = wdata;
        else
            rdata1 = regs[raddr1];

        if (raddr2 == 2'b00)
            rdata2 = 8'h00;
        else if (we && (waddr == raddr2))
            rdata2 = wdata;
        else
            rdata2 = regs[raddr2];
    end

endmodule
