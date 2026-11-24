`ifndef DEFS_SVH
`define DEFS_SVH

typedef enum logic [2:0] {
    OP_LDI = 3'b000,
    OP_ADD = 3'b001,
    OP_SUB = 3'b010,
    OP_AND = 3'b011,
    OP_LD  = 3'b100,
    OP_ST  = 3'b101,
    OP_BEQ = 3'b110,
    OP_NOP = 3'b111
} opcode_t;

localparam logic [7:0] SRAM_BASE_ADDR = 8'h00;
localparam logic [7:0] SRAM_LAST_ADDR = 8'h7F;
localparam logic [7:0] MMIO_IN_ADDR   = 8'h80;
localparam logic [7:0] MMIO_OUT_ADDR  = 8'h81;
localparam logic [7:0] MMIO_OPT_ADDR  = 8'h82;
localparam logic [7:0] ROM_BASE_ADDR  = 8'hC0;
localparam logic [7:0] ROM_LAST_ADDR  = 8'hFF;
localparam logic [7:0] RESET_VECTOR   = 8'hC0;

typedef struct packed {
    logic [7:0] pc;
    logic [7:0] instr;
    logic       valid;
} pipe_if_id_t;

typedef struct packed {
    logic [7:0]  pc;
    opcode_t     opcode;
    logic [1:0]  rd_addr;
    logic        reg_we;
    logic        mem_we;
    logic        is_load;
    logic [7:0]  alu_res;
    logic [7:0]  store_data;
    logic        valid;
} pipe_id_mem_t;

`endif
