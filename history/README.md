# History

Raw material this project draws from, kept separate from `src/` (the
actively maintained reconstruction). Nothing here is cleaned up for
readability beyond the original transcription — `{`/`|`/`}`/`~` stand in for
`ä`/`ö`/`ü`/`ß` throughout, the DIN 66003 German ASCII convention the
original authors typed in.

| Folder | What | Who, when |
| --- | --- | --- |
| [`00-volker-dose-workdisk/`](00-volker-dose-workdisk/) | A recovered work disk: SYS-module disassemblies plus ~25 standalone command utilities (`BACKUP`, `DEL`, `FIND`, `CD`, ...) | Volker Dose, undated |
| [`01-magnus-sys8-1989/`](01-magnus-sys8-1989/) | An independent SYS8 disassembly, different from this project's own | A. Magnus (HACKNUS-SOFTWARE), 08.09.89 |
| [`02-cpm-hdndf-1992/`](02-cpm-hdndf-1992/) | The CP/M-side hard-disk formatter and partition table (`HDNDF.Z80`, `HDDTBL.ASM`), copied from the Holte repo's own history — reverse-engineering target for a GDOS-side equivalent, no original survives here | Volker Dose, 02.11.1992; tuned by Egbert Schröer, 19.01.1993 |

`src/GDOS-2.4-SYS-files/` cites some of `00-volker-dose-workdisk/`'s files
directly as sources for specific patches — those references still resolve,
just at this new path.

## A split for better overview

The different stages confused me at the beginning of this reverse engineering project. Therefore and to avoid any future confusion (yes, human memory is sometimes short) and to avoid that history repeats itself I split the src codes into the history stages.
The stage table in the top-level README (A: stock, B: this repo, C: A.
Magnus/Volker Dose ~1990, D: Schröer ~1992) describes a lineage, not a
single snapshot. All three folders here predate or sit alongside Stage B
and carry material Stage C will likely need — the command utilities in
`00-` all reference five backup volumes (`BACKUP.asm`: *"Backup-Disketten
5 bis 9"*), matching Stage C's five-volume layout against Stage B's two,
and `02-`'s formatter/partition-table pair is the closest surviving
relative to whatever originally laid out that same multi-volume disk on
the GDOS side. Filed here rather than reconstructed yet, since none of it
has been built or verified against a real Stage C image.
