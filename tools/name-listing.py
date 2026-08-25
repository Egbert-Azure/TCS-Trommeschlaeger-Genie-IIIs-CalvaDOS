#!/usr/bin/env python3
"""Turn a listing's mXXXX EQUs into names, and un-symbolise the ones that
are not addresses at all.

Two decisions per symbol:

  * How is it used? A jump/call target or a (nnnn) memory reference is an
    address, whatever its value. A bare 16-bit immediate is an address only
    if it lands in 3400h-51FFh -- low RAM, the DOS, or the module window --
    because that is a value you load into a register and then use as a
    pointer. Anything else is a count, an offset or a mask.

  * Does the project have a name for it? docs/reference/gdos-2.4-addresses.md
    is the only place names come from. Without an entry there the symbol
    stays mXXXX rather than acquiring a plausible-sounding name.

    ./name-listing.py src/GDOS-2.4-SYS-files/sys17-sys-disassembly.asm
    ./name-listing.py ... --apply
"""
import json, re, subprocess, sys, pathlib

LO, HI = 0x3400, 0x51FF


def literal(v):
    s = f"{v:04X}H"
    return "0" + s if s[0].isalpha() else s


def main():
    path = sys.argv[1]
    apply = "--apply" in sys.argv
    names = {int(k, 16): v for k, v in json.loads(subprocess.run(
        ["python3", "tools/gdos-names.py", "--json"],
        capture_output=True, text=True).stdout).items()}

    src = pathlib.Path(path).read_text(encoding="utf-8")
    lines = src.split("\n")
    equ = {}
    for i, l in enumerate(lines):
        m = re.match(r"^m([0-9a-f]{4})\s+EQU\s+0?([0-9a-f]{1,4})h\s*(?:;(.*))?$", l)
        if m:
            equ[m.group(1)] = (i, int(m.group(2), 16), (m.group(3) or "").strip())

    # classify by use
    kind = {}
    for l in lines:
        if re.match(r"^m[0-9a-f]{4}\s+EQU", l):
            continue
        code = l.split(";")[0]
        for s in re.findall(r"\bm([0-9a-f]{4})\b", code):
            if s not in equ:
                continue
            if re.search(rf"\(m{s}\)", code):
                kind.setdefault(s, set()).add("addr")
            elif re.search(rf"\b(?:JP|JR|CALL|DJNZ)\b[^;]*\bm{s}\b", code, re.I):
                kind.setdefault(s, set()).add("addr")
            else:
                kind.setdefault(s, set()).add("imm")

    rename, drop = {}, {}
    for s, (i, v, c) in equ.items():
        k = kind.get(s, set())
        is_addr = "addr" in k or (LO <= v <= HI)
        if not is_addr:
            drop[s] = v
        elif v in names:
            rename[s] = names[v]

    print(f"{path.split('/')[-1]}: {len(equ)} EQUs -> "
          f"{len(rename)} named, {len(drop)} are not addresses, "
          f"{len(equ)-len(rename)-len(drop)} stay mXXXX")
    if drop:
        print("  not addresses: " + " ".join(
            f"{s}={literal(v)}" for s, v in sorted(drop.items())))
    if rename:
        print("  named: " + " ".join(f"{s}={n}" for s, (n, _) in sorted(rename.items())))
    if not apply:
        return

    out = []
    for i, l in enumerate(lines):
        m = re.match(r"^m([0-9a-f]{4})\s+EQU", l)
        if m:
            s = m.group(1)
            if s in drop:
                continue                       # the EQU goes with the symbol
            if s in rename:
                n, meaning = rename[s]
                v = equ[s][1]
                lit = f"{v:04x}h" if f"{v:04x}"[0].isdigit() else f"0{v:04x}h"
                out.append(f"{n:<8}EQU\t{lit}\t\t;{meaning}")
                continue
        out.append(l)
    text = "\n".join(out)
    for s, v in drop.items():
        text = re.sub(rf"\bm{s}\b", literal(v), text)
    for s, (n, _) in rename.items():
        text = re.sub(rf"\bm{s}\b", n, text)
    pathlib.Path(path).write_text(text, encoding="utf-8")
    print("  applied")


main()
