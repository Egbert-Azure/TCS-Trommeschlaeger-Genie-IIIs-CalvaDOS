# Volker Dose's work disk

56 files (`.asm` source + `.lst` listing, 28 pairs), transcribed from
Volker Dose's recovered floppy. Undated as a whole; individual files carry
their own dates where the author wrote one in.

**4 SYS-module disassemblies** — `SYS1`, `SYS8B`, `SYS24`, `SYS29`. These
fed this project's own Stage B reconstruction in `src/GDOS-2.4-SYS-files/`
and are still cited from there by filename.

**24 standalone command utilities** — `ADD`, `AUSGABE`, `BACKUP`, `BLIST`,
`C`, `C2`, `C3`, `CD`, `CLHG3S`, `CP`, `DEL`, `DIRVERGL`, `ERASE`, `F`,
`F5`, `FIND`, `INV`, `IO`, `L`, `MATH`, `SET`, `TYP`, `TYPE`, `WO`. Not
part of any SYS module — transient programs run from the prompt. Not yet
reconstructed into `src/`. `BACKUP.asm` addresses "Backup-Disketten 5 bis
9", five volumes, which is Stage C's layout, not Stage B's — see the
top-level [`history/README.md`](../README.md).
