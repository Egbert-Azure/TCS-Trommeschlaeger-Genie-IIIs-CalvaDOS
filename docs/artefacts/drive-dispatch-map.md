# Drive Dispatch Map

How `DRVSEL` routes DOS drive numbers 0–9 to the floppy controller, the OMTI
hard disk, or a rejection — read straight off `gpar` and its jump table in
[`gdos-omti.asm`](../../src/hd-driver/omti/gdos-omti.asm).

`gpar` sits at `F000h`, ten bytes, one per DOS drive. The jump table is at
`F010h`. `ginit` patches `DRVSEL` so every drive select comes through here.

## The ten drive slots

| Drive | `gpar` | Arg | Routes to | What it is |
| ---: | :---: | :---: | --- | --- |
| **0** | `10h` | 0 | `gflop` | FDC floppy unit 0 — carry set, the DOS's own path handles it |
| **1** | `11h` | 1 | `gflop` | FDC floppy unit 1 — carry set, the DOS's own path handles it |
| **2** | `12h` | 2 | `gflop` → `grej8` | the code rejects it — but live-tested contrary, see below |
| **3** | `13h` | 3 | `gflop` → `grej8` | the code rejects it — but live-tested contrary, see below |
| **4** | `30h` | 0 | slot 3, once MEMDISK claims it | MEMDISK RAM disk. Its install path writes this dispatch entry itself; until then drive 4 rejects with `A=08h` |
| **5** | `40h` | 0 | `gvol` | OMTI volume 0 — **`sysvol`**, the boot volume |
| **6** | `41h` | 1 | `gvol` | OMTI volume 1 — the second HD partition |
| **7** | `00h` | 0 | `grej8` | unassigned — `A=08h`, unsupported function |
| **8** | `7Fh` | F | `grej20` | rejected at the slot lookup itself — `A=20h`, bad drive number |
| **9** | `42h` | 2 | `gvol` | OMTI volume 2 — the slot exists, no volume configured in this 10 MB build |

Legend: drives 0–1 are floppy pass-through, 4–6 and 9 are hard-disk or RAM
disk, 2–3 and 8 are rejected, 7 is unassigned.

## How one byte becomes a jump

```text
in       A = DOS drive number, e.g. 05h

lookup   HL = gpar + A          ->  A = (HL) = 40h

slot     (A AND 70h) RRCA x3    =   40h >> 3   ->  E = 08h

jump     HL = (F010h + E)       ->  handler = gvol

arg      A AND 0Fh              =   00h        ->  gvol, volume 0
```

## What this settles

### Confirmed — the table is stock

Drives 5 and 6 are the two OMTI volumes (`sysvol EQU 05h`); drive 9 is a third
dispatch slot this build leaves unconfigured. The table is byte-identical to
the Xebec S1410 driver's — this project's driver reproduces it on purpose,
because it has to drop into the same dispatch frame.

### Open — drives 2 and 3

**Read straight, the code rejects them.** `gpar[2]=12h` and `gpar[3]=13h` both
decode to dispatch slot 1, `gflop`, with arguments 2 and 3. `gflop`'s own body
is `CP 2 / JR NC,grej8`: any argument ≥ 2 takes the reject branch. Only 0 and 1
reach the FDC, and there is no branch that lets 2 or 3 through.

**Against that: drives 2 and 3 work live** — insert a DMK, run `DIR 2` or
`DIR 3`, and it succeeds. Not reconciled.

Leading hypothesis: the live test may not exercise this table at all. `gpar`
only governs anything once `ginit` has installed the hook over stock `DRVSEL`.
On a plain floppy boot with the driver never loaded, stock `DRVSEL` handles
those drives directly and both observations are true at once. Until that is
settled, treat both as live and do not patch `gflop` on the assumption the
code is simply wrong.

### The table cannot fix everything

`gpar` governs *dispatch*. It cannot help a module that names a drive number
in its own code or static data before dispatch is reached — four such sites
were found, in `SYS26/SYS` (twice), `OVL4/SYS` and `SYS6/SYS`. The last of
those is a byte in a data table, invisible to every pass that read only code.
See [the patch inventory](patch-inventory.md).

---

Sources: `gdos-omti.asm` — `gpar`, the dispatch table, `gdisp`/`gflop`/`gvol`/
`grej8`/`grej20` · [`abi.md`](../../src/hd-driver/abi.md) ·
[`system-drive-model.md`](../architecture/system-drive-model.md)
