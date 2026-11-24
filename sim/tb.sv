`timescale 1ns / 1ps

`include "defs.svh"

module tb;

    logic        clk   = 0;
    logic        rst_n = 0;
    logic [7:0]  port_in  = 8'hA5;
    logic [1:0]  opt_pins = 2'b11;
    logic [7:0]  port_out;
    logic [3:0]  flags_out;

    logic [7:0]  pc_out;
    logic [7:0]  wb_data_out;
    logic [1:0]  wb_rd_out;
    logic        wb_we_out;
    logic        branch_taken_out;
    logic        flush_active_out;

    always #5 clk = ~clk;

    top u_dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .port_in          (port_in),
        .opt_pins         (opt_pins),
        .port_out         (port_out),
        .flags_out        (flags_out),
        .pc_out           (pc_out),
        .wb_data_out      (wb_data_out),
        .wb_rd_out        (wb_rd_out),
        .wb_we_out        (wb_we_out),
        .branch_taken_out (branch_taken_out),
        .flush_active_out (flush_active_out)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb);
        rst_n = 0;
        port_in = 8'hA5;
        opt_pins = 2'b11;
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;

        repeat (35) @(posedge clk);

        $display("");
        if (port_out === 8'hA5)
            $display("Test 1 Parallel Port In to Port Out PASS");
        else
            $display("Test 1 Parallel Port In to Port Out FAIL");

        if (u_dut.u_ram.mem_array[16] === 8'hA5)
            $display("Test 2 SRAM Store PASS");
        else
            $display("Test 2 SRAM Store FAIL");

        if (u_dut.u_core.u_rf.regs[1] === 8'h10)
            $display("Test 3 Forwarding and Address Generation PASS");
        else
            $display("Test 3 Forwarding and Address Generation FAIL");

        if (u_dut.u_core.u_rf.regs[2] === 8'hA5)
            $display("Test 4 Input Port Read PASS");
        else
            $display("Test 4 Input Port Read FAIL");

        if (u_dut.u_core.u_rf.regs[3] === 8'h07)
            $display("Test 5 Branch and Pipeline Flush PASS");
        else
            $display("Test 5 Branch and Pipeline Flush FAIL");

        $display("");
        $display("All tests completed successfully");
        $display("");
        $finish(0);
    end

endmodule
