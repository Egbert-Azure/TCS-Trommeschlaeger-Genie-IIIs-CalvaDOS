#!/usr/bin/env python3
# /tools/zeus80.py — decode ZEUS80 tokenised assembler sources to plain text.
#
# Format, reverse-engineered from the 20 */SRC files on DMK/VOLKER.DMK
# (Volker Dose's work disk, 1989-1992). Each line is one record:
#
#   <len> <flags> [object bytes] [label] 09 <mnemonic> 09 <operands> [09 09 ;comment] 0D
#
#   len    total record length including the len byte itself
#   flags  bit 0x40  label present
#          bits 0-2  number of object-code bytes that follow (bit 0x08 is a
#                    separate flag, so mask with 0x07)
#          bits 0x10/0x20/0x80 vary with operand shape; not needed to render
#   label  printable, may be space-padded, in which case the 09 is omitted
#
# Bytes >= 0x80 in the text are tokens standing for mnemonics, register names,
# condition codes and operand fragments. The token table is not stored in the
# files, so it is inferred: every record carries the object code its line
# assembled to, and disassembling that gives the mnemonic the token must mean.
# Majority vote over ~7600 records fixes the mnemonic tokens; register and
# condition tokens follow Z80 encoding order and are asserted below.
#
# Usage:  python3 zeus80.py <file.SRC>... [-o outdir] [--report]

import argparse
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80mnem import mnemonic  # noqa: E402

TAB = 0x09
CR = 0x0D

# There are two token tables, selected by field: the same byte means one thing
# in the mnemonic field and another in the operand field (0x80 is NOP as a
# mnemonic, B as an operand; 0xA2 is AND vs IX; 0xA6 is XOR vs "(IX").
#
# Operand tokens. 80-87 is the Z80 r field in encoding order, 88-8B the rp
# field, 8C-8F the remaining pairs, 90-97 the condition field. Every entry
# marked (v) below was pinned against a record's own object code:
#   80 B    LD B,09h = 06 09        88 BC   LD BC,0800h = 01 00 08
#   81 C    LD C,H = 4C, JR C,x = 38 18    89 DE   INC DE = 13
#   82 D    LD D,H = 54             8A HL   INC HL = 23
#   83 E    LD E,L = 5D             8B SP   LD SP,m41e0 = 31 E0 41
#   84 H    LD H,C = 61             8C (BC) LD A,(BC) = 0A
#   85 L    ADD A,L = 85            8D (DE) LD (DE),A = 12
#   86 (HL) LD A,(HL) = 7E          8E AF   PUSH AF = F5
#   87 A    LD (nn),A = 32 A0 43    8F AF'  EX AF,AF' = 08
#   90 NZ   JP NZ,x = C2 2D 40      96 P    RET P = F0
#   91 Z    JR Z,x = 28 16          98 (C)  IN E,(C) = ED 58
#   92 NC   JR NC,x = 30 14         9B (SP) EX (SP),HL = E3
#   A2 IX   LD IX,x = DD 21         A6 (IX  LD (IX+0),00h = DD 36 00 00
#   A3 IY   PUSH IY = FD E5         A7 (IY  LD A,(IY+02h) = FD 7E 02
#
# 0x93 is NOT, not the carry condition -- carry reuses 0x81. Pinned by
# DIRVERGL.SRC, which pairs "IF g3 / LD DE,1806h ;6 Files in 24 Zeilen" against
# "IF NOT,g3 / LD DE,0f04h ;4 File in 15 Zeilen" (Genie III vs Genie I/II
# screen geometry), and does the same for LD E,6 / LD E,4 and LD D,18h / LD D,0fh.
# 94/95/97 are extrapolated from the condition order around the pinned 96=P.
OPERAND_TOKENS = {
    0x80: "B", 0x81: "C", 0x82: "D", 0x83: "E",         # (v)
    0x84: "H", 0x85: "L", 0x86: "(HL)", 0x87: "A",      # (v)
    0x88: "BC", 0x89: "DE", 0x8A: "HL", 0x8B: "SP",     # (v)
    0x8C: "(BC)", 0x8D: "(DE)", 0x8E: "AF", 0x8F: "AF'",  # (v)
    0x90: "NZ", 0x91: "Z", 0x92: "NC", 0x93: "NOT",     # (v)
    0x94: "PO", 0x95: "PE", 0x96: "P", 0x97: "M",       # 96 (v), rest extrapolated
    0x98: "(C)", 0x9B: "(SP)",                          # (v)
    0xA0: "ON", 0xA1: "OFF",                            # inferred, see PSEUDO[0xCC]
    0xA2: "IX", 0xA3: "IY", 0xA6: "(IX", 0xA7: "(IY",   # (v)
}


def scan(data):
    """Walk the record chain. Returns (record count, bytes consumed)."""
    i = n_rec = 0
    while i < len(data):
        n = data[i]
        if n == 0:                      # explicit terminator
            break
        if n < 3 or data[i + n - 1:i + n] != b"\r":
            break                       # chain broken or truncated record
        i += n
        n_rec += 1
    return n_rec, i


def is_tokenised(data):
    """True if `data` is a tokenised ZEUS80 file rather than plain ASCII text.

    Not every */SRC file on the disk is tokenised -- L/SRC is plain uppercase
    ASCII, and its first byte 'M' (0x4D) is happily read as a record length by a
    parser that does not check, so the two must be told apart before parsing.
    A tokenised file holds token bytes >= 0x80 and its record lengths chain
    through nearly the whole file.

    The chain need not land exactly on EOF: files are allocated in whole
    granules, so a final short record of uncleared sector tail can follow the
    last real line. TYPE/SRC is byte-identical to TYP/SRC for all 358 records
    and then carries 6 such bytes (24 74 0D 24 56 EB). Requiring an exact
    landing rejects it as plain text and leaks the length bytes into the output,
    so allow a small tail.
    """
    if not any(c >= 0x80 for c in data):
        return False
    n_rec, consumed = scan(data)
    return n_rec > 0 and consumed >= 0.95 * len(data)


def records(data):
    """Split a ZEUS80 source file into raw records."""
    i = 0
    while i < len(data):
        n = data[i]
        if n == 0:
            break
        yield data[i:i + n]
        i += n


def parse(rec):
    """Split one record into (objbytes, label, fields)."""
    flags = rec[1]
    body = rec[2:-1] if rec[-1:] == b"\r" else rec[2:]
    if body[:1] == b";":                      # whole-line comment
        return b"", "", [body]
    obj = body[:flags & 0x07]
    rest = body[flags & 0x07:]
    label = ""
    if flags & 0x40:
        # label runs to the next tab, or to the first token if space-padded
        k = 0
        while k < len(rest) and rest[k] != TAB and rest[k] < 0x80:
            k += 1
        label = rest[:k].decode("latin1")
        rest = rest[k + 1:] if k < len(rest) and rest[k] == TAB else rest[k:]
    elif rest[:1] == b"\t":
        # unlabelled line: drop the tab that stands in for the empty label
        # field, so fields[0] is always the mnemonic
        rest = rest[1:]
    return obj, label, rest.split(b"\t")


def infer_tokens(paths):
    """Vote each mnemonic-position token against the record's own object code."""
    votes = collections.defaultdict(collections.Counter)
    for p in paths:
        data = open(p, "rb").read()
        if not is_tokenised(data):
            continue
        for rec in records(data):
            obj, _, fields = parse(rec)
            if not obj or not fields:
                continue
            first = fields[0]
            if not first or first[0] < 0x80:
                continue
            m = mnemonic(obj)
            if m:
                votes[first[0]][m] += 1
    table = {}
    confidence = {}
    for tok, c in votes.items():
        best, n = c.most_common(1)[0]
        table[tok] = best
        confidence[tok] = (n, sum(c.values()), c)
    return table, confidence


# Directives. Voting cannot reach these: EQU/ORG/IF carry no object code at all,
# and on DEFB/DEFW/DEFM lines the stored bytes are data, so they disassemble as
# noise (that noise is itself the signature -- 0xD5 "votes" LD/NOP/JR/DEC).
#
#   C4 ENDIF  occurs exactly 43 times, as does C8 IF -- they pair
#   C5 END    one per program file, operand is the entry label ("END start")
#   C6 ORG    one per program file, operand is an address (5200h, 8000h, 4d00h)
#   C7 EQU    "dosrdy EQU 402dh"
#   C8 IF     "IF new", "IF NOT,g3"; conditional assembly of the reconstructions
#   CC LIST   only ever "LIST ON"/"LIST OFF", at section boundaries. The pairing
#             with 0xA0/0xA1 is certain; that it is spelled LIST is inferred from
#             placement, not proven -- some listing control is the only reading
#             that fits a no-object-code directive toggling around subroutines.
#   D0 DEFS   "buffer DEFS 255"       D1 DS    the short spelling (1 use)
#   D5 DEFM   "text DEFM 'Laufwerk '" D4 DM    (unobserved)
#   D7 DEFB   "secanz DEFB 01h"       D6 DB    the short spelling (1 use)
#   D9 DEFW   "debuf DEFW 1806h", object code 06 18 -- little-endian, confirms it
#   D8 DW     the short spelling (1 use)
# Which of each short/long pair is which is a guess; the pairs themselves are not.
PSEUDO = {
    0xC4: "ENDIF", 0xC5: "END", 0xC6: "ORG", 0xC7: "EQU", 0xC8: "IF",
    0xCC: "LIST",
    0xD0: "DEFS", 0xD1: "DS", 0xD4: "DM", 0xD5: "DEFM",
    0xD6: "DB", 0xD7: "DEFB", 0xD8: "DW", 0xD9: "DEFW",
}


def _expand(field, table, mnemonic_field):
    """Render one field. Comments and operands use different token tables."""
    if field[:1] == b";":
        return "".join(_latin(c) if c < 0x80 else f"{{{c:02X}}}" for c in field)
    out = []
    for c in field:
        if c < 0x80:
            out.append(_latin(c))
        elif mnemonic_field:
            out.append(PSEUDO.get(c) or table.get(c) or f"{{{c:02X}}}")
        else:
            out.append(OPERAND_TOKENS.get(c) or f"{{{c:02X}}}")
    return "".join(out)


def render(rec, table):
    obj, label, fields = parse(rec)
    # The mnemonic is the first non-blank field, not necessarily fields[0]:
    # MATH.SRC has a line whose first field is a single space, which shifts the
    # mnemonic one field right.
    mfield = next((i for i, f in enumerate(fields) if f.strip()), 0)
    seen_comment = False
    out = []
    for i, f in enumerate(fields):
        if f[:1] == b";":
            seen_comment = True
        out.append(_expand(f, table, mnemonic_field=(i == mfield and not seen_comment)))
    text = "\t".join(out)
    if label:
        text = label + ("" if label.endswith(" ") else "\t") + text
    elif fields and fields[0][:1] != b";":
        text = "\t" + text
    return obj, text.rstrip()


# The Genie IIIs character set puts German umlauts where ASCII has {|}~[\].
GERMAN = {0x7B: "ä", 0x7C: "ö", 0x7D: "ü", 0x7E: "ß",
          0x5B: "Ä", 0x5C: "Ö", 0x5D: "Ü"}


def _latin(c, umlauts=True):
    if umlauts and c in GERMAN:
        return GERMAN[c]
    return chr(c)


def main():
    ap = argparse.ArgumentParser(description="Decode ZEUS80 tokenised .SRC files")
    ap.add_argument("files", nargs="+")
    ap.add_argument("-o", "--outdir", help="write .asm files here instead of stdout")
    ap.add_argument("--report", action="store_true", help="token inference report")
    ap.add_argument("--listing", action="store_true", help="prefix object code bytes")
    ap.add_argument("--both", action="store_true",
                    help="with -o, write both .asm (plain) and .lst (with object bytes)")
    ap.add_argument("--raw", action="store_true", help="keep {|}~ instead of umlauts")
    args = ap.parse_args()

    table, conf = infer_tokens(args.files)
    table.update(PSEUDO)
    if args.raw:
        GERMAN.clear()

    if args.report:
        print(f"{len(table)} tokens inferred from {len(args.files)} files\n")
        for tok in sorted(conf):
            n, tot, c = conf[tok]
            flag = "" if n == tot else "  <-- ambiguous: " + ", ".join(
                f"{m}x{k}" for m, k in c.most_common(4))
            print(f"  {tok:02X}h = {table[tok]:<6} {n}/{tot}{flag}")
        unknown = collections.Counter()
        for p in args.files:
            data = open(p, "rb").read()
            if not is_tokenised(data):
                print(f"  (plain ASCII, not tokenised: {os.path.basename(p)})")
                continue
            for rec in records(data):
                _, _, fields = parse(rec)
                for f in fields:
                    for c in f:
                        if c >= 0x80 and c not in table and c not in OPERAND_TOKENS:
                            unknown[c] += 1
        if unknown:
            print(f"\n{len(unknown)} unresolved tokens (rendered as {{XX}}):")
            for c, n in unknown.most_common():
                print(f"  {c:02X}h x{n}")
        return

    for p in args.files:
        data = open(p, "rb").read()
        plain = not is_tokenised(data)
        wanted = [".asm", ".lst"] if args.both else [".lst" if args.listing else ".asm"]

        for ext in wanted:
            if plain:
                # L/SRC is already plain ASCII; pass it through either way, since
                # there is no stored object code to build a listing from
                body = "".join(_latin(c) for c in data).replace("\r", "\n")
                n = body.count("\n")
            else:
                lines = []
                for rec in records(data):
                    obj, text = render(rec, table)
                    if ext == ".lst":
                        lines.append(f"{' '.join(f'{b:02X}' for b in obj):<12}{text}")
                    else:
                        lines.append(text)
                body = "\n".join(lines) + "\n"
                n = len(lines)
            if args.outdir:
                os.makedirs(args.outdir, exist_ok=True)
                out = os.path.join(
                    args.outdir, os.path.splitext(os.path.basename(p))[0] + ext)
                with open(out, "w", encoding="utf-8") as fh:
                    fh.write(body)
                note = ", plain ASCII" if plain else ""
                if not plain:
                    tail = len(data) - scan(data)[1]
                    if tail:
                        note += f", {tail} trailing bytes ignored"
                print(f"{p} -> {out} ({n} lines{note})")
            else:
                sys.stdout.write(body)


if __name__ == "__main__":
    main()
