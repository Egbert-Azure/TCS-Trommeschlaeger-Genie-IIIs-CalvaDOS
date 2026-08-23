# Two Sectors, One Burst

GDOS addresses storage as 256-byte sectors; the OMTI 5527 only moves 512-byte
physical sectors. Read off `gxio`'s own code in
[`gdos-omti.asm`](../../src/hd-driver/omti/gdos-omti.asm), including the
asymmetry between reads and writes.

## Two logical sectors share one physical burst

```text
   hdlba N  (even)              hdlba N+1  (odd)
   GDOS sector N, 256 B         GDOS sector N+1, 256 B
        |                              |
         \                            /
          \                          /
           +------------------------+
           |  bytes 0-255 | 256-511 |
           |  sector N    | N+1     |
           +------------------------+
        one OMTI physical sector, 512 B, hdlba / 2
```

## How hdlba becomes a physical sector number

```text
in      HL = hdlba, e.g. 0069h  (DOS sector 105, odd)

halve   SRL H / RR L    ->  HL = 0034h  (physical sector 52), carry = 1

flag    the carry out of the shift = hdlba's own bit 0  ->  the odd/even flag

seek    hdchs(HL)       ->  the OMTI is told: physical sector 52
```

## What happens with that half-sector flag

| Case | What the driver does |
| --- | --- |
| **Read, even sector** | The default path. `gsop` bursts bytes 0–255 into the DOS buffer for real. `gsec` stays in drain mode — bytes 256–511 are pulled off the controller and discarded. |
| **Read, odd sector** | `gsec` is re-patched from drain to a real second burst, and `gsync` rewinds the buffer pointer by 256 first. So the first 256 bytes off the wire are overwritten by the second burst, and the DOS buffer ends up holding bytes 256–511 — the half it asked for. |
| **Write, odd sector** | *Known limitation.* Always drain/pad. Writing DOS sector N+1 does not read-modify-write the physical sector first, so it cannot preserve N's half. Flagged in the source itself: *"a correct fix there needs a read-modify-write of the whole physical sector, not just a swap."* |

## What this settles

### Confirmed

**It is a 2-for-1 packing, not just a bigger buffer.** The driver's own header
says so — *"hdlba addresses a DOS (256-byte) sector; the OMTI moves 512-byte
sectors, two DOS sectors to one"* — and the halving is literal code,
`SRL H / RR L` at the top of `gxio`, not a comment describing intent.

This is what lets GDOS's addressing model run unmodified on OMTI hardware.
GDOS only ever says "sector N" and has no opinion on physical transfer size, so
the driver is free to reinterpret what that means physically, as long as it
hands back the 256 bytes that were asked for.

### Known limitation

Odd-sector writes are drain/pad only — flagged in the source as unfixed, and
not something the boot exercises. Worth returning to now that the machine
reaches a prompt and ordinary file writes are reachable.

### Aside — period context, not code-verified

Why 256 bytes at all, when the media supports 512? The general 1980s-DOS
tradeoff: allocation happens in whole sectors, so a smaller logical sector
wastes less on small files. A 100-byte file costs one sector either way — but
that sector is half the size. Context, not a claim this repository's code makes
about its own history.

---

Sources: `gdos-omti.asm` — `gxfer`, `gxio`, `gsop`, `gsec`, `gsync`
