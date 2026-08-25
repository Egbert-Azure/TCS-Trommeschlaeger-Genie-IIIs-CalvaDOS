#!/usr/bin/env python3
# /tools/gdos-names.py
#
# Read docs/reference/gdos-2.4-addresses.md, the one place this project keeps
# its names for GDOS addresses. Everything that needs them -- the disassembly
# generator, the consistency check below -- reads it from here, so the
# listings and the driver's own source cannot drift apart.
#
#   python3 tools/gdos-names.py            check the driver and the listings
#   python3 tools/gdos-names.py --json     the table, for another tool to use
import glob
import json
import re
import sys

TABLE = "docs/reference/gdos-2.4-addresses.md"
LISTINGS = "src/GDOS-2.4-SYS-files/*.asm"


def load():
    out = {}
    for line in open(TABLE, encoding="utf-8"):
        m = re.match(r"\|\s*`([0-9A-F]{4})`\s*\|\s*`(\w+)`\s*\|\s*(.*?)\s*\|", line)
        if m:
            out[int(m.group(1), 16)] = (m.group(2), m.group(3))
    return out


def check_driver(names):
    """The driver may write the table's name as-is or with its own 'd'
    prefix for a DOS address -- ddrive for DDRIVE, dgetfde for GETFDE.
    Anything else is a second name for an address that already has one."""
    bad = 0
    for line in open("src/hd-driver/omti/gdos-omti.asm", encoding="utf-8"):
        m = re.match(r"^(d\w+)\s+EQU\s+0?([0-9a-fA-F]{3,4})h", line)
        if not m:
            continue
        a = int(m.group(2), 16)
        if a not in names:
            continue
        got, want = m.group(1).lower(), names[a][0].lower()
        if got not in (want, "d" + want):
            print(f"  {a:04X}h: driver calls it {m.group(1)}, the table says "
                  f"{names[a][0]} -- two names for one address")
            bad += 1
    print(f"  {len(names)} names in the table; "
          + ("driver agrees with all of them" if not bad
             else f"{bad} disagreement(s)"))
    return bad


def check_listings(names):
    """Every uppercase EQU in a listing is a name for an address outside that
    module, so it has to be the table's name for it. A listing inventing its
    own is how the table stops being the one source -- it happened once, in
    the MEMDISK listing, before this check existed.

    A listing's own internal labels (lNNNNh, sub_NNNNh, mNNNN) are not names
    in this sense and are ignored."""
    bad = 0
    for path in sorted(glob.glob(LISTINGS)):
        if "magnus" in path:            # a 1989 listing, not ours to conform
            continue
        for line in open(path, encoding="utf-8", errors="replace"):
            m = re.match(r"^([A-Z][A-Z0-9_]*)\s+EQU\s+0?([0-9a-fA-F]{1,4})h",
                         line)
            if not m:
                continue
            got, a = m.group(1), int(m.group(2), 16)
            if a not in names:
                print(f"  {path.split('/')[-1]}: {got} = {a:04X}h is not in "
                      f"the table -- add it there, with its source")
                bad += 1
            elif names[a][0] != got:
                print(f"  {path.split('/')[-1]}: calls {a:04X}h {got}, the "
                      f"table says {names[a][0]}")
                bad += 1
    print(f"  listings: " + ("every EQU matches the table" if not bad
                             else f"{bad} disagreement(s)"))
    return bad


if __name__ == "__main__":
    n = load()
    if "--json" in sys.argv:
        json.dump({f"{a:04X}": [v[0], v[1]] for a, v in n.items()}, sys.stdout)
    else:
        sys.exit(1 if (check_driver(n) + check_listings(n)) else 0)
