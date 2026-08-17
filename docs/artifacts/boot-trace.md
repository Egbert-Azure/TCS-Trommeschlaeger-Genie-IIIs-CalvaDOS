<!-- /docs/development/boot-trace.md -->
<!-- Sopp 1986 OMTI machine, 10 MB · Genie IIIs · G-DOS 2.4 -->
<!-- Live zbx trace: HD boot vs. floppy boot · 2026-08-17 -->
<!--  (c) E. Schroeer 2026 -->

# CalvaDOS Boot Trace

**Sopp OMTI · Genie IIIs · G-DOS 2.4**

```text
EPROM
  │
  ▼
4200h ── boot sector ──► BASIC + extensions
  │
  ▼
420Fh ── load SYS0 ──► 4D00h
  │
  ▼
4D00h ── SYS0 init ──► DRVSEL
  │
  ▼
3700h ──► F000h       OMTI driver
  │
  ▼
GETSYS
  │
  ├── 1Ch ──► verification fails ──► clean exit
  │
  ├── 04h ──► verification fails ──► clean exit
  │
  └── 06h ──► verification fails ──► clean exit
                                      │
                                      ▼
                                  error path
                                      │
                                      ▼
                              241Ah → 245Fh
                                      │
                                      ▼
                                  JP (HL)
                                      │
                                      ▼
                                    7BC1h
                                      │
                                      ▼
                             00 FF 00 FF ...
                                      │
                                      ▼
                                DEAD LOOP
```
## Trace
| State             | Address            | Result                                   |
| ----------------- | ------------------ | ---------------------------------------- |
| 🟠 EPROM hand-off | `4200h`            | Entry with `A=01h`, `SP=FFFEh`           |
| 🟠 Boot sector    | `4200h–4211h`      | BASIC + extensions loaded                |
| 🟠 SYS0 load      | `420Fh → 4D00h`    | `SYS0/SYS` loaded at `400Ch–51DAh`       |
| 🟠 SYS0 init      | `4D00h–50C4h`      | Returns normally                         |
| 🟠 DRVSEL         | `3700h → F05Dh`    | OMTI driver reached                      |
| 🟠 System files   | sectors `802–1591` | SYS4/SYS2/SYS26/OVL4 byte-verified       |
| 🔵 GETSYS 1Ch     | `4BE1h–4C18h`      | Verification fails                       |
| 🔵 GETSYS 04h     | `4BE1h–4C18h`      | Verification fails                       |
| 🔵 GETSYS 06h     | `4BE1h–4C18h`      | Verification fails                       |
| 🔴 Error path     | `241Ah–245Fh`      | Error index produces `JP (HL)` → `7BC1h` |
| 🔴 Dead loop      | `7BC1h`            | Executes `00 FF 00 FF ...` indefinitely  |

## GETSYS

All three modules take the same verification path:
module 1Ch
    HL = 4260h
    bit 6,(HL) = 0
        │
        └──► 4C0Eh ──► 4C18h ──► return

module 04h
    HL = 4200h
    bit 6,(HL) = 0
        │
        └──► 4C0Eh ──► 4C18h ──► return

module 06h
    HL = 4200h
    bit 6,(HL) = 0
        │
        └──► 4C0Eh ──► 4C18h ──► return
4200h–43FFh is zero.
No overlay file is read.

## Failure after module 06h
`` asm
0A9F  LD (40AFh),A
2451  LD A,(40B0h)
2459  ADD HL,BC
245F  JP (HL)          ; HL = 7BC1h
``
At 7BC1h:
00 FF 00 FF 00 FF ...
│  │
│  └── RST 38h
└───── NOP

Execution continues through non-code memory.
- No return
- No screen change
- No zbx trap
- 60+ seconds of silence

## Boot state

4200h–43FFh table
        │
        ▼
      all zero
        │
        ▼
GETSYS rejects 1Ch, 04h, 06h
        │
        ▼
no overlay bytes loaded
        │
        ▼
third failure enters error path
        │
        ▼
40B0h selects 7BC1h
        │
        ▼
execution enters non-code memory
        │
        ▼
DEAD LOOP

## Supporting trace
| T-state |      PC |
| ------: | ------: |
| 3418282 | `3211h` |
| 3419928 | `F2D7h` |
| 3425838 | `F340h` |
| 3427150 | `F0EFh` |
| 3427394 | `F0FAh` |
| 3430246 | `F3A1h` |
| 3431359 | `3726h` |
The same driver PC sequence occurs after the GETSYS calls. It is not evidence of a successful per-module overlay load.

## Image verification
| File        |   Sectors | Result |
| ----------- | --------: | ------ |
| `SYS4/SYS`  | 1507–1511 | match  |
| `SYS2/SYS`  | 1467–1471 | match  |
| `SYS26/SYS` | 1587–1591 | match  |
| `OVL4/SYS`  |   802–816 | match  |

Image:
HDV/calvados-sopp-512-verified-20260816.hdv

## SYS0 divergence
| Range         | Reference     |
| ------------- | ------------- |
| `4400h–4BC8h` | Grosser ch.3  |
| `4BC9h–4C27h` | Grosser 9.4.2 |
| `4C28h–4ECCh` | Grosser ch.3  |
| `4ECDh–50A7h` | Grosser ch.3  |
| `50A8h–5183h` | differs       |

Divergence begins at 50A8h.
Full disassembly:
src/GDOS-2.4.SYS-files/sys0-sys-disassembly.asm

## Current target
Find what should populate 4200h–43FFh.
That is the point upstream of the GETSYS failure and the 7BC1h dead loop.

