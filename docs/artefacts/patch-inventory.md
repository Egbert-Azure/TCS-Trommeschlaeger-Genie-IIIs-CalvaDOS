# What CalvaDOS actually changes

Stock GDOS 2.4 has no path to a hard disk. Every change is either a byte-level
patch to a shipped SYS-file — no source exists, so same-footprint substitutions
only, each asserting the stock bytes are present before it writes — or a piece
of this project's own driver that stock never had.

| | |
| ---: | --- |
| **8** | patches to `SYS0/SYS` |
| **4** | patches to `SYS26`, `OVL4`, `SYS6` |
| **3** | stubs planted in dead space |
| **1515** | bytes of new driver |

## Three ways a patch reaches new code

"Patched" does not mean the same thing everywhere below. Which of these applies
decides where the new bytes live and who runs them.

### In place — `327Eh`, `4C13h`, `50C4h`, `4D63h`

```text
SYS0/SYS
    old bytes  ->  new bytes
    (same address, same file)
```

New bytes replace old bytes at the same address. Nothing moves, nothing new is
called; the caller is whoever already reached that address.

### Same-file stub — `4F3Bh`→`50D0h`, `4EFEh`→`50D5h`, `32ECh`→`4D30h`

```text
SYS26/SYS  (or OVL4/SYS)
    CALL 4776h  ->  CALL stub
                      stub: LD A,05h / JP 4776h
    (planted in confirmed-dead space, same file)
```

The original instruction calls a small stub in unused space *within that same
file*, which then lands back on stock's own continuation.

### Driver-authored landing pad — `4BE4h`→`rsysfcb`, `4BF0h`→`rdecfix`

```text
SYS0/SYS
    old bytes  ->  CALL 448Ch
                     |
                     v  ginit plants the code there at boot
    448Ch — 20 bytes of FFh in the always-resident block
```

Three parties: the driver **authors** the code, `ginit` **plants** it with an
`LDIR` once at boot, and SYS0's patched byte **calls** it every time.

## SYS0/SYS — eight patches

| Address | Was | Is | Why |
| ---: | --- | --- | --- |
| `50C4h` | `CD 36 44` | `AF 00 00` | SYS0 reads a config sector from drive 0 through the floppy path, four instructions before the driver that could serve it is initialised. The driver plants that sector at `4200h` instead, so the read is redundant. |
| `4BE4h` | `AF 32 D8 43 CD 76 47` | `CD 8C 44` + 4×`NOP` | **The root cause this whole investigation traced.** See below. |
| `4BF0h` | `CD 36 49` | `CD 95 44` | `GETSYS` computes a fresh module DEC on every load but never writes it back to the shared FCB. A later check re-derives its candidate by reading that field, so only whichever module a boot-time constant happened to name ever verified. `rdecfix` persists the DEC, then makes the identical stock call. |
| `327Eh` | `30h` (`'0'`) | `35h` (`'5'`) | The drive digit in the on-disk template `"OVLx/SYS:0"`, so every overlay open targets the boot volume instead of a floppy that is not there. |
| `4C13h` | `28 FE` | `00 00` | A deliberate stock infinite loop, entered only when `SYS4/SYS` specifically fails to load. `NOP`/`NOP` falls through to `4C15h`'s own error-code step and then the ordinary error path. |
| `4D63h` | 12 bytes | 12 bytes | SYS0 writes *one* config byte to *two* places — `439Fh` (drive count) and `477Ah` (`DRVSEL`'s `CP` operand). Right for stock, where every drive is a floppy; wrong here. Split into two independent values. |
| `4EF9h` | `21 05` | `18 0D` | The AUTO-command GAT re-read: one cause behind both the "schlechte Parameter" message at every boot and the one stubborn floppy READ. Skip the read, and write the empty command line directly rather than copying 32 bytes from a shared buffer that no longer holds the config sector. |
| `4F0Dh` | `21 E0 42 01 20 00 ED B0` | `3E 0D 12` + `NOP`s | *(same patch as above)* |

### `4BE4h` — one instruction doing two jobs

Stock's `XOR A` served as both `DRVSEL`'s drive-0 argument *and* the shared
FCB's NEXT-field reset (`43D8h` is FCB+0Ah). Harmless on stock, where drive 0
and NEXT=0 are the same value.

An earlier patch substituted `sysvol` (`05h`) for the `XOR A` directly —
correct for `DRVSEL`, but it carried `05h` into NEXT too, so `FILPOS` computed a
target one GRAN past every file's real start and SYS-file loads silently
failed. `rsysfcb` keeps the two purposes apart:

```z80
gsysfcb  XOR   A
         LD    (dfcbdv),A   ; NEXT = 0, as stock intended
         LD    A,sysvol     ; *then* the drive argument
         JP    ddrvsel
```

## Three more files, the same hardcoded drive 0

| File | Address | What it is |
| --- | ---: | --- |
| `SYS26/SYS` | `4F3Bh` | The `DRVSEL` call inside SYS26's own directory-read loop, firing right after `GETSYS`'s six correct `DRVSEL(5)` calls — the direct cause of a floppy seek with no floppy attached. No room for an in-place fix, so a 5-byte stub at `50D0h`. |
| `SYS26/SYS` | `4EFEh` | The sibling call in `sub_4eech`, reached through SYS26's P/N/&lt;Enter&gt; prompt. Needed two file offsets rather than one: the 3-byte `CALL` straddles a load-record boundary. |
| `OVL4/SYS` | `32ECh` | The bank-switch trampoline's `DRVSEL` call — the only `CALL 4776h` anywhere in the file. No FCB side effect here, so its own stub rather than reusing `rsysfcb`. |
| `SYS6/SYS` | `5942h` | **Not an instruction at all** — a field in one of COPY's static data structures, which is why reading its code never found it. See below. |

### COPY kept a third drive slot nobody filled in

COPY has three 10-byte drive records: drive number, bit mask, and a pointer to
the name it prints when it wants that disk mounted.

```text
5942h   drive 00h   mask 01h   -> "===> System "   (system diskette)
594Ch   drive FFh   mask 02h   -> "Quelle"          (source)
5956h   drive FFh   mask 04h   -> "Ziel "           (destination)
```

`FFh` means "unused, skip". Source and destination start unused and are filled
in from the command line. **The system slot is never filled in and never
`FFh`** — so drive 0 was verified on *every* copy, which is why a plain file
copy naming neither drive 0 nor a whole disk failed the same way as
`copy 5 6`. Patched to `05h`; the patch also asserts both neighbouring slots
are still `FFh`, so a wrong address fails loudly instead of corrupting the
table.

## The driver's own space

`SYS0.SYS` is two concatenated load modules in one file:

| Module | Contents | Extent |
| --- | --- | --- |
| 0 | stock GDOS resident code, patched above | `0000h`–`2FFFh`, `400Ch`–`51DAh` |
| *(fill)* | `0x58` | |
| 1 | this project's driver, `gdos-omti.asm` | 1543 bytes as a load module, of a 2012-byte budget — 469 bytes of file room left |

### 1515 bytes at `F000h`, and where they go

```text
|<-- 622 -->|<-- 312 -->|<------ 480 ------>|<- 101 ->|
 dispatch,    gcopy,      ginit, gcfg        low-RAM
 hooks,       gtab,       DEAD after boot    templates
 transfer     omti
 F000-F26D    F26E-F3A5   F3A6-F585          F586-F5EA
```

The dead block is *placed*, not padded. MEMDISK/CMD copies its own resident
driver over `F400h`–`F567h`, so `ginit` and `gcfg` — both finished by then —
are laid across that range and nothing live has to be pushed past it. Until
this change that job was done by 440 bytes of `DEFS`, which is why the driver
was 1955 bytes with 21 bytes of room left.

Build-time assertions fail the build if the cover, the DOS-facing addresses or
the `F700h` ceiling is ever broken — and MEMDISK itself confirms the placement
at the prompt: the RAM disk initialises, takes a copied file and lists it back.

## Still open

**Why COPY's stock byte only started biting when it did.** `5942h` is stock and
was never touched by this project, yet the symptom appeared only after the
drive-count fix. Something there changed whether drive 0's verify *passes*, not
whether it happens. A differential review found that fix's only live effect in
low RAM is `439Fh`; the connecting mechanism is not proven.

---

Sources: `run-hdboottest.sh` · `gdos-omti.asm` ·
[`boot-patch-inventory.md`](../development/boot-patch-inventory.md) ·
[`departures-from-stock.md`](../architecture/departures-from-stock.md)
