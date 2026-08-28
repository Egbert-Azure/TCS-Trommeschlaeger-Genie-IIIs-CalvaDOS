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

`src/GDOS-2.4-SYS-files/` cites some of `00-volker-dose-workdisk/`'s files
directly as sources for specific patches — those references still resolve,
just at this new path.

## Why this split exists

The stage table in the top-level README (A: stock, B: this repo, C: A.
Magnus/Volker Dose ~1990, D: Schröer ~1992) describes a lineage, not a
single snapshot. Both folders here predate or sit alongside Stage B and
carry material Stage C will likely need — the command utilities above all
reference five backup volumes (`BACKUP.asm`: *"Backup-Disketten 5 bis 9"*),
matching Stage C's five-volume layout against Stage B's two. Filed here
rather than reconstructed yet, since neither has been built or verified
against a real Stage C image.
