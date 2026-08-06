# CalvaDOS

CalvaDOS is lost. First things first and Prost!

The original was a hard-disk version of **G-DOS 2.4** for the **TCS Genie
IIIs**, written in the mid-1980s and, as far as the surviving evidence
shows, largely Arnulf Sopp's work. No copy has turned up. There is no disk
image hidden somewhere in this repository — I don't have one either.

This is my attempt to rebuild what it did.

## Why bother

The Genie IIIs was a banked Z80 machine with a hard disk at a time when that
combination was still unusual, and the people writing for it were pushing it
well past what it was sold to do. CalvaDOS is a good example: hard-disk
partitions used as named directories on a DOS that has no directories, five
volumes on a driver built for two, a command set larger than the system was
designed to hold.

None of it saved the machine. The PC had already taken the market, and the
Genie IIIs arrived too late to matter commercially. What was being built on it
was ahead of its time and beside the point at the same time.

So the interesting part here isn't only how a Z80 operating system works. It's
what a handful of people got out of one, with the tools of the day and no way
to ask anybody. That part seems worth writing down.

## What survived

- Arnulf Sopp's 1986 OMTI boot EPROM
- Volker Dose's 1992 work disk, including assembly sources
- the original G-DOS 2.4 distribution
- Hartmut Grosser's *Das DOS-Buch*
- a lot of reverse engineering

The project has two goals:

- Document how the Genie IIIs hard-disk system actually worked.
- Build a working, open implementation of an OMTI-based G-DOS.

Some of what's here is understood, some is rebuilt from period code, and some
is an educated guess that hasn't been proven. Which is which is marked. When
new evidence kills an earlier conclusion, the conclusion is struck and left
visible rather than deleted. The wrong turns are part of the record, and
several of them were more useful than the right answers.

## The Evolution of CalvaDOS

| stage | what | controller | disk | volumes |
| --- | --- | --- | --- | --- |
| a | stock G-DOS 2.4, built-in HD driver | Xebec | 10 MB | 5 and 6 |
| b | Arnulf Sopp, 1986 — new EPROM, SYS0/SYS onto the HD | OMTI | 10 MB | 5 and 6 |
| c | A. Magnus and Volker Dose, ~1990 | | ~20 MB Tandon | 5, 6, 7, 8 and 9 |
| d | E. Schroeer ~2992 | | later use with an ST225 | | 21.4 MB | |

## What the OMTI port has to change

| Layer | Xebec | OMTI |
| --- | --- | --- |
| Select | write ID `01` to port `00`, read back, pulse SEL on port `02`, poll BUSY (bit 1) on port `01` | strobe port `42h`, poll phase codes `C0/C9/CB/CF` on `41h` |
| REQ | bit 0 of port `01` (`F255`) | bit 0 of `41h` — same idiom, different port |
| Release | write port `01` (`F0F6`) | not required the same way |
| CDB bytes | `OUT (0),A` per byte (`F215` loop) | `OUT (40h),A` |
| Address | flat LBA in `CDB1..3` (`F1ED`) | raw cylinder / head / sector |
| Data phase | bank-switched RAM stub at `3A00h`, `INIR`/`OTIR` patched in | same mechanism required — the banking constraint is independent of the controller |

## Status

| Component | Status |
| --- | --- |
| Stock Xebec driver | Reverse engineered |
| OMTI transport | Working |
| OMTI G-DOS driver | Read/write and directory access verified |
| Drive numbering | Stock G-DOS layout retained — floppies 0–3, hard disk 5/6/9 |
| Boot sector at `4200h` | Written and executing, loaded by the Sopp EPROM |
| Hard-disk boot | Loads G-DOS modules; does not yet reach the command prompt |

The boot sector is this project's own, written to the hand-off contract the
Sopp EPROM was observed to use. The original CalvaDOS boot sector has not
turned up and may never.

The machine boots substantially further under the emulator than when this
started — the OMTI transport carries the whole load, with no floppy fallback
anywhere in it — but it does not reach `Befehlseingabe`. The current work is in
the module loader, where `SYS0/SYS` requests the same small set of modules in
an unbroken cycle instead of advancing. Latest findings in
`docs/reverse-engineering/calvados-investigation.md`.

## Quick start

```sh
./run-calvados.command
```

## Repository layout

```text
src/        Source code
ROM/        Boot ROMs and EPROM images
HDV/        Hard disk images
DMK/        Floppy disk images
tools/      Development and analysis tools
docs/       Documentation
```

## Documentation

`docs/` holds the architecture notes, the reverse-engineering record, the
development documentation and the period references the project leans on.

If you're new to this, start with:

- `docs/architecture/`
- `docs/reverse-engineering/calvados-investigation.md`
- `docs/development/README.md`

What's here is curated rather than complete. The day-to-day working notes stay
in a private repository; what made it into `docs/` is the material that's
either established or useful as a dead end.

## Related repositories

- sdltrs-MultiHDC
- TCS-Trommeschlaeger-Genie-IIIs-GDos-2.4
- TCS-Trommeschlaeger-Genie-IIIs
- trsextract

## Contributing

Contributions are welcome, corrections especially — provided they come with
evidence.

Please:

- Keep changes focused.
- Separate observations from conclusions.
- Include the traces, commands or artifacts behind any reverse-engineered
  claim.
- Preserve historical behaviour unless there's clear evidence the original
  software behaved differently.

## Credits

### Original software

- Arnulf Sopp (The Hacktory) — CalvaDOS and the 1986 OMTI boot EPROM
- Andreas Magnus (HACKNUS-SOFTWARE)
- Volker Dose
- Helmut Bernhardt
- The G-DOS 2.4 authors
- TCS and Uwe Böker

### Recovery

- Fritz Chwolka read `VOLKER.DMK` off Volker Dose's original floppy with a Catweasel
  controller.
- Jens Günther (JenGun), author of **sdltrs**, passed the recovered disk on.
  Without it there would be nothing to work from.

## License

New code is released under **GPLv3**.

Documentation is released under **CC BY-SA 4.0**.

Original ROMs, binaries and other historical material remain the property of
their respective copyright holders and are included only for preservation and
research where permitted.
