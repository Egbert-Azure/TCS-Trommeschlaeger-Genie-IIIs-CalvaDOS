# HDNDF — the hard-disk formatter, CP/M side

Copied from the Holte CP/M repo's own history
([`TCS-Trommeschlaeger-Genie-IIIs/history/03-omti-schroeer-branch-1992/`](https://github.com/Egbert-Azure/TCS-Trommeschlaeger-Genie-IIIs/tree/main/history/03-omti-schroeer-branch-1992)),
not moved — it still belongs there as CP/M history. Kept here too because
the original this was ported *from* was written for GDOS, not CP/M, and no
copy of that original survives in this repo's own sources.

**`HDNDF.Z80`** (Volker Dose, 02.11.1992; hand-tuned by Egbert Schröer,
19.01.1993) — low-level formats a Seagate ST225 via the OMTI controller:
`SET CHARACTERISTICS`/`WRITE SECTOR BUFFER`/`FORMAT` straight to ports
0x40–0x43, `0xE5` fill. Its own header says it plainly: *"auf CP/M
umgeschrieben von mir"* — rewritten to CP/M by him, from something else.
That something else was almost certainly GDOS-side, on the same OMTI
5527 family this repo's own driver (`gdos-omti.asm`) talks to.

**`HDDTBL.ASM`** — computes the partition table this formatter's disk
needs: `10 01 05 1f 01 30 0a ff 07 ff ff 00 80 00 00 02 03` for partition
0, a second row for partition 1. This is the multi-partition, directory-
like layout Stage C needs (five volumes, not two) — GDOS's own equivalent
of this table is what CalvaDOS would need to grow.

## Why it's here

Stage B's HDV is pre-built; nothing in this repo currently formats a raw
disk or lays out its partition table from scratch. Stage C's bigger disk
and five volumes will need exactly that, and this is the closest surviving
relative to whatever GDOS-side tool did it originally — reverse-engineering
target, not a ready answer. See [`history/README.md`](../README.md) for how
this fits alongside the other stages.
