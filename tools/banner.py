#!/usr/bin/env python3
"""Decode and re-lay-out GDOS's boot banner.

SYS0/SYS prints one string at 4FABh: three rows, each a run of TRS-80
block-graphics characters (the logo) followed by a short text label and the
control codes that end the row.

    4FABh   graphics   'VERSION 2.4'       1Eh 0Ah
            graphics   '(C) 1984 TCS/MVC'  0Ah
            graphics   'Genie I/II'        1Fh 0Dh 0Dh   .. through 504Dh

Each graphics byte is one character cell holding a 2-wide by 3-tall pixel
block, so the three rows stack into a bitmap 9 pixels tall. Bit layout, with
bit 7 always set:

    bit0 bit1
    bit2 bit3
    bit4 bit5

The whole 163-byte string is laid out here as one block rather than three
fixed runs, because the column a label starts at is simply the number of
graphics bytes in front of it. Padding the logo with blank cells moves the
label right; taking cells away moves it left. That is what lines the three
labels up, and it is why the byte budget below is what constrains the
artwork's width.

Stock, the three labels started at columns 40, 37 and 39 -- ragged, so the
block of text beside the logo had no straight edge. They all start at START
instead, which is 39 and not a free choice: OVL4/SYS substitutes the machine
name ('I/II' -> 'IIIs') into a copy of this string at a fixed offset, so the
third label cannot move off 503Fh, and 39 is where it sits. The other two
come to meet it.

    ./banner.py --decode SYS0/SYS-image     > logo.txt
    ./banner.py --encode art.txt            # the 163 bytes, annotated

--decode takes the raw SYS0/SYS file (dmk.py --extract) and resolves the load
records itself. --encode takes 9 lines of '#' (ink) and '.' (blank); lines
starting with ';' are comments, since '#' cannot be one.
"""

import argparse
import re
import subprocess
import sys

BANNER = 0x4FAB                  # first byte of the string
BANNER_END = 0x504D              # last byte (its second CR)
SIZE = BANNER_END - BANNER + 1   # 163 bytes, and it cannot grow

START = 39                       # column every label begins at

# label, the control bytes that close the row, and its trailing spaces.
#
# The trailing spaces are what makes the 163 bytes come out exactly, and
# they are not free: row 1 gives one of its own to row 2, because 39 cells
# plus the longest label is one byte more than row 2's stock length. That is
# allowed, and only that is -- what must not change is where row 3 begins,
# since OVL4/SYS writes the machine name into a copy of this string at a
# fixed offset and 'Genie I/II' has to stay at 503Fh. Row 3 is reproduced
# byte for byte and the two rows in front of it keep their combined length.
ROWS = (("VERSION 2.4", b"\x1e\x0a", 1),
        ("(C) 1984 TCS/MVC", b"\x0a", 0),
        ("Genie I/II", b"\x1f\x0d\x0d", 2))

ROW3 = 0x5018                    # where the third row has to start


def load_image(path):
    """Flatten a /SYS file's LOAD records into a 64K image."""
    out = subprocess.run(
        ["python3", "tools/trsload.py", path, "--map"],
        capture_output=True, text=True).stdout
    recs = [(int(m.group(1), 16), int(m.group(3), 16), int(m.group(4), 16))
            for m in (re.match(
                r"\s+0x([0-9a-f]+)\s+LOAD\s+(\d+)B\s+"
                r"([0-9A-F]{4})\.\.([0-9A-F]{4})", line)
                for line in out.splitlines()) if m]
    if not recs:
        sys.exit(f"{path}: trsload.py --map yielded no LOAD records")
    data = open(path, "rb").read()
    mem = bytearray(0x10000)
    for off, lo, hi in recs:                # the last record wins at load time
        n = hi - lo + 1
        mem[lo:lo + n] = data[off + 4:off + 4 + n]
    return mem


def split(block):
    """The banner block -> [(graphics bytes, text bytes, control bytes)]."""
    rows, i = [], 0
    while i < len(block):
        g = i
        while i < len(block) and block[i] >= 0x80:
            i += 1
        t = i
        while i < len(block) and 0x20 <= block[i] < 0x80:
            i += 1
        c = i
        while i < len(block) and block[i] < 0x20:
            i += 1
        rows.append((block[g:t], block[t:c], block[c:i]))
    return rows


def decode(mem):
    """The three graphics runs -> 9 lines of '#'/'.'."""
    art = []
    for graphics, _, _ in split(mem[BANNER:BANNER_END + 1])[:3]:
        top = mid = bot = ""
        for byte in graphics:
            v = byte - 0x80
            top += "#" if v & 0x01 else "."
            top += "#" if v & 0x02 else "."
            mid += "#" if v & 0x04 else "."
            mid += "#" if v & 0x08 else "."
            bot += "#" if v & 0x10 else "."
            bot += "#" if v & 0x20 else "."
        art += [top, mid, bot]
    width = max(len(line) for line in art)
    return [line.ljust(width, ".") for line in art]


def cells(art):
    """9 lines of '#'/'.' -> three lists of block-graphics cell bytes."""
    if len(art) != 9:
        sys.exit(f"expected 9 lines of art, got {len(art)}")
    width = max(len(line) for line in art)
    art = [line.ljust(width, ".") for line in art]
    rows = []
    for r in range(3):
        top, mid, bot = art[3 * r:3 * r + 3]
        row = []
        for c in range(0, width, 2):
            v = 0
            for bit, (line, col) in enumerate(
                    ((top, c), (top, c + 1), (mid, c), (mid, c + 1),
                     (bot, c), (bot, c + 1))):
                if col < len(line) and line[col] == "#":
                    v |= 1 << bit
            row.append(0x80 + v)
        rows.append(row)
    return rows


def layout(art):
    """9 lines of art -> the whole 163-byte banner string.

    Each row is the logo, then blank cells enough to bring the label to
    column START, then the label, its trailing spaces and the row's control
    bytes. The trailing spaces are invisible: every row ends in a control
    code that either erases the rest of the line or moves to the next one.
    """
    rows = cells(art)
    out = bytearray()
    for (label, ctrl, trail), row in zip(ROWS, rows):
        pad = START - len(row)              # blank cells between the logo
        if pad < 0:                         # and the label
            sys.exit(f"the artwork is {len(row)} cells but the labels start "
                     f"in column {START} -- make it {-pad} cell(s) narrower")
        out += bytes(row) + bytes([0x80] * pad) + label.encode() \
            + b" " * trail + ctrl
    if len(out) != SIZE:
        sys.exit(f"laid out {len(out)} bytes, need exactly {SIZE}")
    third = BANNER + sum(START + len(l) + t + len(c)
                         for l, c, t in ROWS[:2])
    if third != ROW3:
        sys.exit(f"the third row would start at {third:04X}h, not {ROW3:04X}h "
                 f"-- OVL4/SYS patches the machine name into a copy of this "
                 f"string at a fixed offset and cannot follow it")
    return bytes(out)


def read_art(path):
    # ';' starts a comment: '#' is the ink character and cannot be one.
    return [l.rstrip("\n") for l in open(path)
            if l.strip() and not l.lstrip().startswith(";")]


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--decode", metavar="SYS0", help="raw SYS0/SYS file")
    g.add_argument("--encode", metavar="ART", help="9-line art file")
    args = ap.parse_args()

    if args.decode:
        mem = load_image(args.decode)
        art = decode(mem)
        width = len(art[0])
        print("".join(str((i // 10) % 10) for i in range(width)),
              file=sys.stderr)
        print("".join(str(i % 10) for i in range(width)), file=sys.stderr)
        for line in art:
            print(line)
        col = 0
        for graphics, text, ctrl in split(mem[BANNER:BANNER_END + 1]):
            label = text.decode("latin-1").rstrip()
            print(f"  {len(graphics):2d} cells + {text.decode('latin-1')!r:20s}"
                  f" -> {label!r} starts in column {len(graphics)}",
                  file=sys.stderr)
    else:
        block = layout(read_art(args.encode))
        addr = BANNER
        for graphics, text, ctrl in split(block):
            label = text.decode("latin-1").rstrip()
            print(f"{addr:04X}h  {len(graphics):2d} cells + "
                  f"{text.decode('latin-1')!r:22s} + "
                  f"{ctrl.hex(' ')}  -> label starts in column "
                  f"{len(graphics)}")
            addr += len(graphics) + len(text) + len(ctrl)
        print(f"        {len(block)} bytes of {SIZE}")


if __name__ == "__main__":
    main()
