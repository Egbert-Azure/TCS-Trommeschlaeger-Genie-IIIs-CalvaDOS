<!-- /docs/artifacts/gdos-omti-sector-mapping.md-->
<!--
(c) E. Schroeer 2026
-->
# Drive Dispatch Map
## Two Sectors, One Burst
How DRVSEL routes DOS drive numbers 0–9 to the floppy controller, the OMTI hard disk, or an outright rejection — decoded straight from gpar and its jump table, cross-checked against reverse engineered byte-level trace.

## The Ten Drive Slots

| Drive | Type | Mapping | Handler | Destination / Result |
|------:|------|---------|---------|----------------------|
| **0** | DOS drive | `gpar = 10h` · arg `0` | → `gflop` | FDC floppy unit 0 — carry set; DOS's own FDC path handles it |
| **1** | DOS drive | `gpar = 11h` · arg `1` | → `gflop` | FDC floppy unit 1 — carry set; DOS's own FDC path handles it |
| **2** | DOS drive | `gpar = 12h` · arg `2` | → `gflop` → `grej8` | **Rejected** — `gflop`'s `CP 2 / JR NC` rejects any arg ≥ 2; `A = 08h` (`unsupported function`) |
| **3** | DOS drive | `gpar = 13h` · arg `3` | → `gflop` → `grej8` | **Rejected** — same path; arg `3 ≥ 2` |
| **4** | DOS drive | `gpar = 00h` · arg `0` | → `grej8` | **Unassigned** — `A = 08h` (`unsupported function`). Ramdisk (`memdisk`/`cmd`) must claim it through a different mechanism, not `gpar` |
| **5** | DOS drive | `gpar = 40h` · arg `0` | → `gvol` | OMTI volume 0 — `sysvol`, the boot/system partition |
| **6** | DOS drive | `gpar = 41h` · arg `1` | → `gvol` | OMTI volume 1 — the second HD partition |
| **7** | DOS drive | `gpar = 00h` · arg `0` | → `grej8` | **Unassigned** — `A = 08h` (`unsupported function`) |
| **8** | DOS drive | `gpar = 7Fh` · arg `F` | → `grej20` | **Rejected earlier** — slot lookup itself fails; `A = 20h` (`bad drive number`), not `unsupported function` |
| **9** | DOS drive | `gpar = 42h` · arg `2` | → `gvol` | OMTI volume 2 — dispatch slot exists, but no volume is configured in this 10 MB build |


## Two logical sectors share one physical burst

```text

in → A = DOS drive number, e.g. 05h (drive 5)

lookup → HL = gpar + A → A = (HL) = 40h

slot → (A AND 70h) RRCA×3 = (40h AND 70h) >> 3 = E = 08h

jump → HL = (gpar+10h + E) → handler = gvol

arg → A AND 0Fh = 40h AND 0Fh = A = 00h → gvol called with volume 0

```

## 256-byte GDOS sectors on a 512-byte OMTI disk

**Known asymmetry**

> Odd-sector writes are not implemented symmetrically. The source itself flags this path as unfixed. Odd-sector writes are still drain/pad only rather than writing the second half of the physical sector. This is a known driver limitation, not a property of the 512→256 sector mapping itself.


**The key distinction**

> GDOS does not see a 512-byte sector. It asks the driver for logical sector N. The driver maps that 256-byte sector onto one half of the OMTI's 512-byte physical sector. That separation is what makes the halving trick possible.

> In other words: GDOS's world = 256 bytes; OMTI's world = 512 bytes. gxio is the translation layer between them.


GDOS works with 256-byte logical sectors . The OMTI transfers 512-byte physical sectors . The OMTI driver is the translation layer between the two.

gxio takes GDOS's 256-byte sector index in hdlba , shifts it right one bit with SRL H / RR L , and uses the shifted-out bit as the odd/even selector.

But the read path is cleverer than simply reading 512 bytes and throwing half away .

The driver requests the physical 512-byte sector, then takes the first 256 bytes as the data for the even GDOS sector. The second half is still transferred, but is drained rather than delivered to GDOS.

The driver's low-RAM transfer stub is patched so the second half becomes the useful data. The first 256 bytes are drained; the second 256 bytes are transferred into the GDOS buffer.

## What this settles

**Confirmed**

> The 4C1Dh fix does not touch drive mapping. 4C1Dh is inside GDOS's own SYS0 boot code — GETSYS's "call the entry point of the SYS-file I just loaded" step, fired while loading SYS0/SYS1/SYS4 modules during early boot. gpar and gflop / gvol live entirely in gdos-omti.asm and were untouched by that revert.

> Drives 5 and 6 are, and remain, the two OMTI hard-disk volumes ( sysvol EQU 05h , gdos-omti.asm:75 ); drive 9 is a third dispatch slot this 10 MB build leaves unconfigured. That table is byte-identical to the stock Xebec S1410 driver's — this project's own driver reproduces it on purpose ( DRIVER.md : "the parameter table's fixed addresses and contents are both stock").


**Worth flagging**

> Only drives 0 and 1 pass through to the FDC — drives 2 and 3 are rejected outright by gflop 's own CP 2 / JR NC,grej8 , A=08h "unsupported function", no fallback. This is already documented at abi.md:139-140 and is stock Xebec behavior this driver reproduces byte-for-byte — not something introduced by any fix this session.

> It sits alongside the broader claim in system-drive-model.md:29 ("DOS drives 0-3 remain real floppy slots") — that statement is true of the table's intent and the PDRIVE block's 4-slot layout, but gflop 's own argument check currently only honors units 0/1 of it. Since the target layout calls for four 80-track floppies on 0–3, this is a gap worth resolving before relying on drives 2/3 — separate from, and unrelated to, the 4C1Dh boot-sequencing fix.


## 256-byte GDOS sectors on a 512-byte OMTI disk

GDOS's logical sector number is **256-byte based**, while the OMTI's physical sector is **512 bytes**. The driver performs the translation by dividing the GDOS sector number by two.

```text
                    OMTI hard disk
                    512-byte sector
                           │
                           ▼
                    OMTI controller
                           │
                    512-byte transfer
                           │
                           ▼
                    OMTI disk driver
                           │
                 translate logical sector
                           │
                           ▼
                    GDOS / GDOS
                    256-byte sector
```

The key operation in `gxio` is:

```text
GDOS logical sector (256 bytes)
          │
          │  hdlba
          ▼
     ┌───────────┐
     │ SRL H     │
     │ RR  L     │
     └───────────┘
          │
          ├───────────────┐
          │               │
          ▼               ▼
   physical sector     odd/even
     number              flag
          │
          ▼
    OMTI 512-byte
      physical sector
```

The shifted-out bit becomes the odd/even flag. Two GDOS sectors therefore share one physical OMTI sector:

```text
OMTI physical sector
512 bytes
┌──────────────────────────────┐
│ GDOS sector N       256 bytes│  ← even
├──────────────────────────────┤
│ GDOS sector N+1     256 bytes│  ← odd
└──────────────────────────────┘
```

But the **read path is cleverer than simply reading 512 bytes and throwing half away**.

### Even GDOS sector

The driver requests the physical 512-byte sector, then:

```text
512-byte OMTI burst
┌────────────────┬────────────────┐
│ 256 bytes      │ 256 bytes      │
│ wanted         │ drained        │
└────────────────┴────────────────┘
        ↓
    GDOS buffer
```

### Odd GDOS sector

The driver dynamically patches its low-RAM stub so that the OMTI transfer handles the **second half** as the useful data.

```text
512-byte OMTI burst
┌────────────────┬────────────────┐
│ drained        │ 256 bytes      │
│                │ wanted         │
└────────────────┴────────────────┘
                         ↓
                     GDOS buffer
```

So GDOS gets to maintain its 256-byte logical-sector model without requiring the OMTI to operate in 256-byte physical sectors.

### The write-path asymmetry

The read path and write path are **not symmetrical**.

Odd-sector writes are still drain/pad only. The source itself marks this path as unfinished. This is therefore a known limitation of the driver, not a new finding from the current investigation.

| GDOS logical sector | Physical OMTI sector | Read | Write |
|---|---:|---|---|
| even | `N / 2` | first 256 bytes | works |
| odd | `N / 2` | second 256 bytes | **unfixed / drain-pad** |

### The important distinction

**GDOS's world = 256 bytes**

**OMTI's world = 512 bytes**

The 512-byte OMTI sector size is a property of the controller interface. The 256-byte GDOS sector size is a property of the DOS interface. `gxio` is the translation layer between the two.

GDOS does not say:

> "Give me a 512-byte sector."

It says, conceptually:

> "Read logical sector N."

The OMTI driver translates that logical sector number into a physical 512-byte sector and uses the odd/even flag to select which 256-byte half is the actual GDOS data.

That is why the 512-byte OMTI sector size does **not** mean that GDOS itself has become a 512-byte-sector DOS.

---

*Source references: gdos-omti.asm:79 (gpar) · :83-95 (dispatch table) · :117-179 (gdisp/gflop/grej8/grej20)  ·  abi.md:128-154  ·  system-drive-model.md:22-39*
