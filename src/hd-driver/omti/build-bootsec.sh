#!/bin/bash
#************************************************************************
#
#	Hard-disk boot sector, build script
#
#
# Written and commented by
# E.H. Schroeer
#
# Name: build-bootsec.sh
#
# Date: 2026/08/23
#
#************************************************************************
#
# Provenance: stage b -- build script for this project's own boot sector
# (bootsec.asm/bootrd.asm), not stock G-DOS. Evidence: this file's own
# header, below.
#
# Build the 512-byte hard-disk boot sector out of its two halves.
#
# They are separate because only the first 256 bytes are ours to execute
# from. The ROM loads all 512 to 4200h, but SYS0/SYS's own load records land
# at 4308h-4317h, 4368h-43A8h and 43B2h-43DFh -- DOS variable space it
# initialises -- so anything still running out of 43xx when the load starts is
# overwritten by the load. That is why the floppy's boot sector is 256 bytes.
#
#   bootsec.asm   ORG 4200h   loader, stays put
#   bootrd.asm    ORG 3B00h   OMTI transport, carried at 4300h in the sector
#                             and relocated to 3B00h on first entry
#
# bootrd is assembled at the address it will RUN at, not the address it is
# stored at, so no fixups are needed at relocation time.
set -e
cd "$(dirname "$0")"
REPO="$(cd ../../.. && pwd)"
OUT="${1:-bootsec.bin}"
T="$(mktemp -d)"
pasmo bootsec.asm "$T/lo.bin"
pasmo bootrd.asm  "$T/hi.bin"
for f in lo hi; do
  n=$(wc -c < "$T/$f.bin" | tr -d " ")
  [ "$n" = 256 ] || { echo "$f half is $n bytes, want 256"; exit 1; }
done
cat "$T/lo.bin" "$T/hi.bin" > "$OUT"
echo "$OUT: 512 bytes (loader at 4200h, transport stored at 4300h, runs at 3B00h)"
