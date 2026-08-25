# /tools/z80mnem.py — opcode -> mnemonic, for ZEUS80 token inference.
#
# Mnemonic only, no operand formatting: the ZEUS80 records already carry the
# operand text, so all we need from the object bytes is which mnemonic the
# token in the record must stand for. Keeping this table mnemonic-only removes
# most of the ways a hand-written disassembler can be subtly wrong.

_ALU = ["ADD", "ADC", "SUB", "SBC", "AND", "XOR", "OR", "CP"]

# --- base page -------------------------------------------------------------
_BASE = {}
for _o in range(0x100):
    _BASE[_o] = None
for _o, _m in {
    0x00: "NOP", 0x07: "RLCA", 0x08: "EX", 0x0F: "RRCA",
    0x10: "DJNZ", 0x17: "RLA", 0x18: "JR", 0x1F: "RRA",
    0x27: "DAA", 0x2F: "CPL", 0x37: "SCF", 0x3F: "CCF",
    0x76: "HALT", 0xD9: "EXX", 0xE3: "EX", 0xEB: "EX",
    0xF3: "DI", 0xFB: "EI", 0xE9: "JP", 0xF9: "LD",
    0xC3: "JP", 0xCD: "CALL", 0xC9: "RET",
    0xD3: "OUT", 0xDB: "IN",
}.items():
    _BASE[_o] = _m
for _o in (0x01, 0x11, 0x21, 0x31, 0x02, 0x12, 0x22, 0x32,
           0x0A, 0x1A, 0x2A, 0x3A,
           0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E):
    _BASE[_o] = "LD"
for _o in (0x03, 0x13, 0x23, 0x33, 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C):
    _BASE[_o] = "INC"
for _o in (0x0B, 0x1B, 0x2B, 0x3B, 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D):
    _BASE[_o] = "DEC"
for _o in (0x09, 0x19, 0x29, 0x39):
    _BASE[_o] = "ADD"
for _o in (0x20, 0x28, 0x30, 0x38):
    _BASE[_o] = "JR"
for _o in range(0x40, 0x80):
    if _o != 0x76:
        _BASE[_o] = "LD"
for _o in range(0x80, 0xC0):
    _BASE[_o] = _ALU[(_o >> 3) & 7]
for _o in range(0xC0, 0x100):
    _lo = _o & 7
    if _lo == 0:
        _BASE[_o] = "RET"
    elif _lo == 1:
        _BASE[_o] = "POP" if _o & 8 == 0 else _BASE[_o]
    elif _lo == 2:
        _BASE[_o] = "JP"
    elif _lo == 4:
        _BASE[_o] = "CALL"
    elif _lo == 5:
        _BASE[_o] = "PUSH" if _o & 8 == 0 else _BASE[_o]
    elif _lo == 6:
        _BASE[_o] = _ALU[(_o >> 3) & 7]
    elif _lo == 7:
        _BASE[_o] = "RST"
for _o in (0xC8, 0xD8, 0xE8, 0xF8):
    _BASE[_o] = "RET"
for _o in (0xCA, 0xDA, 0xEA, 0xFA):
    _BASE[_o] = "JP"
for _o in (0xCC, 0xDC, 0xEC, 0xFC):
    _BASE[_o] = "CALL"

# --- CB page ---------------------------------------------------------------
_CB_ROT = ["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"]


def _cb(op):
    if op < 0x40:
        return _CB_ROT[op >> 3]
    return {1: "BIT", 2: "RES", 3: "SET"}[op >> 6]


# --- ED page ---------------------------------------------------------------
_ED = {
    0x44: "NEG", 0x45: "RETN", 0x4D: "RETI", 0x67: "RRD", 0x6F: "RLD",
    0x46: "IM", 0x56: "IM", 0x5E: "IM",
    0xA0: "LDI", 0xA1: "CPI", 0xA2: "INI", 0xA3: "OUTI",
    0xA8: "LDD", 0xA9: "CPD", 0xAA: "IND", 0xAB: "OUTD",
    0xB0: "LDIR", 0xB1: "CPIR", 0xB2: "INIR", 0xB3: "OTIR",
    0xB8: "LDDR", 0xB9: "CPDR", 0xBA: "INDR", 0xBB: "OTDR",
}
for _o in (0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78):
    _ED[_o] = "IN"
for _o in (0x41, 0x49, 0x51, 0x59, 0x61, 0x69, 0x71, 0x79):
    _ED[_o] = "OUT"
for _o in (0x42, 0x52, 0x62, 0x72):
    _ED[_o] = "SBC"
for _o in (0x4A, 0x5A, 0x6A, 0x7A):
    _ED[_o] = "ADC"
for _o in (0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B, 0x47, 0x4F, 0x57, 0x5F):
    _ED[_o] = "LD"


def mnemonic(obj):
    """Mnemonic for the instruction at the start of `obj` (bytes), or None."""
    if not obj:
        return None
    op = obj[0]
    if op == 0xCB:
        return _cb(obj[1]) if len(obj) > 1 else None
    if op == 0xED:
        return _ED.get(obj[1]) if len(obj) > 1 else None
    if op in (0xDD, 0xFD):
        if len(obj) < 2:
            return None
        if obj[1] == 0xCB:
            # DD CB dd op — displacement byte sits before the opcode
            return _cb(obj[3]) if len(obj) > 3 else None
        return _BASE.get(obj[1])
    return _BASE.get(op)
