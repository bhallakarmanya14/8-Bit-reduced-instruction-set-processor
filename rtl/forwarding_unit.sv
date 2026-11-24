`timescale 1ns / 1ps

module forwarding_unit (
    input  logic [1:0]  id_rd_addr,
    input  logic [1:0]  id_rs_addr,
    input  logic        id_uses_rs,

    input  logic        wb_reg_we,
    input  logic [1:0]  wb_rd_addr,
    input  logic [7:0]  wb_write_data,

    input  logic [7:0]  rf_rdata1,
    input  logic [7:0]  rf_rdata2,

    output logic [7:0]  fwd_op_a,
    output logic [7:0]  fwd_op_b,
    output logic        fwd_a_active,
    output logic        fwd_b_active
);

    always_comb begin
        if (wb_reg_we && (wb_rd_addr != 2'b00) && (wb_rd_addr == id_rd_addr)) begin
            fwd_op_a     = wb_write_data;
            fwd_a_active = 1'b1;
        end else begin
            fwd_op_a     = rf_rdata1;
            fwd_a_active = 1'b0;
        end
    end

    always_comb begin
        if (id_uses_rs && wb_reg_we && (wb_rd_addr != 2'b00) && (wb_rd_addr == id_rs_addr)) begin
            fwd_op_b     = wb_write_data;
            fwd_b_active = 1'b1;
        end else begin
            fwd_op_b     = rf_rdata2;
            fwd_b_active = 1'b0;
        end
    end

endmodule
