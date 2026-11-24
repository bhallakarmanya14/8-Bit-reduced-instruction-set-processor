import sys
import re

OPCODES = {
    'LDI': 0b000,
    'ADD': 0b001,
    'SUB': 0b010,
    'AND': 0b011,
    'LD':  0b100,
    'ST':  0b101,
    'BEQ': 0b110,
    'NOP': 0b111
}

REGISTERS = {
    'r0': 0, 'R0': 0,
    'r1': 1, 'R1': 1,
    'r2': 2, 'R2': 2,
    'r3': 3, 'R3': 3
}

def assemble_line(line, addr_offset=0):
    clean = re.sub(r'(//|#|;).*$', '', line).strip()
    if not clean:
        return None

    tokens = re.split(r'[,\s\(\)\[\]]+', clean)
    tokens = [t for t in tokens if t]
    if not tokens:
        return None

    op = tokens[0].upper()
    if op not in OPCODES:
        raise ValueError(f"Unknown opcode: '{op}'")

    opcode_bin = OPCODES[op]

    if op == 'NOP':
        byte_val = 0xE0
        sv_str = "{OP_NOP, 2'd0, 3'd0}"
        desc = "NOP"

    elif op == 'LDI':
        if len(tokens) < 3:
            raise ValueError(f"LDI requires: LDI Rd, imm (got: {clean})")
        rd = REGISTERS[tokens[1]]
        imm = int(tokens[2], 0) & 0x07
        byte_val = (opcode_bin << 5) | (rd << 3) | imm
        sv_str = f"{{OP_LDI, 2'd{rd}, 3'd{imm}}}"
        desc = f"LDI r{rd}, {imm}"

    elif op in ('ADD', 'SUB', 'AND'):
        if len(tokens) < 3:
            raise ValueError(f"{op} requires: {op} Rd, Rs (got: {clean})")
        rd = REGISTERS[tokens[1]]
        rs = REGISTERS[tokens[2]]
        byte_val = (opcode_bin << 5) | (rd << 3) | rs
        sv_str = f"{{OP_{op}, 2'd{rd}, 1'b0, 2'd{rs}}}"
        desc = f"{op} r{rd}, r{rs}"

    elif op in ('LD', 'ST'):
        if len(tokens) < 3:
            raise ValueError(f"{op} requires: {op} Rd, [Rs] (got: {clean})")
        rd = REGISTERS[tokens[1]]
        rs = REGISTERS[tokens[2]]
        byte_val = (opcode_bin << 5) | (rd << 3) | rs
        sv_str = f"{{OP_{op}, 2'd{rd}, 1'b0, 2'd{rs}}}"
        desc = f"{op} r{rd}, [r{rs}]"

    elif op == 'BEQ':
        imm_token = tokens[1]
        imm = int(imm_token, 0) & 0x07
        byte_val = (opcode_bin << 5) | (0b00 << 3) | imm
        sv_str = f"{{OP_BEQ, 2'd0, 3'd{imm}}}"
        desc = f"BEQ offset={imm}"

    return {
        'byte_val': byte_val,
        'sv_str': sv_str,
        'desc': desc,
        'binary': f"{byte_val:08b}"
    }

def assemble_program(source_text):
    lines = source_text.strip().split('\n')
    results = []
    idx = 0
    for line in lines:
        res = assemble_line(line, idx)
        if res:
            res['index'] = idx
            res['pc_hex'] = f"0x{0xC0 + idx:02X}"
            results.append(res)
            idx += 1
    return results

def print_assembly_table(results):
    print(f"+-------+--------+------------+----------+-----------------------------+---------------------+")
    print(f"| Index | PC     | Binary     | Hex Byte | SystemVerilog Concatenation | Mnemonic Operation  |")
    print(f"+-------+--------+------------+----------+-----------------------------+---------------------+")
    for r in results:
        idx = r['index']
        pc = r['pc_hex']
        b = r['binary']
        h = f"8'h{r['byte_val']:02X}"
        sv = r['sv_str']
        desc = r['desc']
        print(f"| {idx:5d} | {pc:6s} | {b:10s} | {h:8s} | {sv:27s} | {desc:19s} |")
    print(f"+-------+--------+------------+----------+-----------------------------+---------------------+")

SAMPLE_PROGRAM = """
LDI r1, 1
ADD r1, r1
ADD r1, r1
ADD r1, r1
LDI r2, 0
ST  r1, [r2]
LD  r3, [r2]
SUB r3, r1
BEQ 2
LDI r0, 7
LDI r3, 5
NOP
"""

if __name__ == '__main__':
    print("=== Rev3 Pipelined Processor Micro-Assembler ===")
    print("Assembling Sample Program:")
    prog = assemble_program(SAMPLE_PROGRAM)
    print_assembly_table(prog)

    print("\nSystemVerilog rom.sv paste block:")
    print("--------------------------------------------------")
    for r in prog:
        print(f"    rom_array[{r['index']:2d}] = {r['sv_str']};")
    print("--------------------------------------------------")
