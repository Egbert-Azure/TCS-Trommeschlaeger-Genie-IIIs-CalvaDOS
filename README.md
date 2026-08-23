<img width="100" height="25" alt="black-logo" src="https://github.com/user-attachments/assets/12af5c46-99aa-420f-a704-6a905b061939" />
<img width="745" height="249" alt="Screenshot 2026-08-22 at 5 27 56 PM" src="https://github.com/user-attachments/assets/05e825d3-280d-494a-8a73-8f1f827261d4" />

# CalvaDOS

CalvaDOS is lost. First things first and Prost!

## A little history

In the early 1980s, the **TCS Genie IIIs** was an exceptional Z80 computer. It was fast for its time, had banked memory and graphics capabilities, and—unusually for a Z80 machine—could be equipped with a hard disk.

Its operating system, **GDOS 2.4**, was an impressive piece of software in its own right. Unfortunately, the Genie IIIs arrived late to the market. By then the IBM PC and its clones were taking over, and TCS went bankrupt in 1985.

But the machine had a small and enthusiastic community around it. Members of the German **Club80** modified GDOS and pushed the Genie IIIs well beyond what it had originally been designed to do.

One of those modifications became **CalvaDOS**.

As far as I can tell from what has survived, much of the work was done by **Arnulf Sopp**. He added support for an OMTI hard-disk controller and created the EPROM that allowed GDOS to boot from the hard disk. And, with the particular sense of humor for which Arnulf was known, he called the result *CalvaDOS*.

I always liked what that system could do.

## Forty years later

Fast-forward to 2026.

The original CalvaDOS software appears to be gone. No complete copy has turned up, and there is no magic disk image waiting to be discovered in this repository.

What did survive, however, was enough to make the story interesting:

* Arnulf Sopp's 1986 OMTI boot EPROM
* Volker Dose's work disk, including assembly sources
* the original GDOS 2.4 distribution
* Hartmut Grosser's *Das DOS-Buch*
* binaries, documentation and other fragments from the Genie IIIs community
* and, eventually, quite a lot of reverse engineering

Looking at the surviving material, I realized that the history of CalvaDOS was still visible in the software itself.

It had not been created once and forgotten. It had **evolved**.

Different people added things. Hardware changed. Disk sizes grew. The system was patched, extended and adapted over the years. Some of those changes can still be seen in the binaries and source code.

So I started wondering:

**Why not bring it back?**

Not because anybody needs another Z80 operating system in 2026. And certainly not because writing code for a computer from 1984 is the sensible way to spend one's time.

But because it is there (you know, like "why do I climb a mountain") - and yes, because "I can" (quoting my former colleague Scott Hanselman)

Because enough of it survived.

And because, in a time when almost nobody has a reason to write software for a Genie IIIs anymore, it seemed like a good excuse to do exactly that.

This is my personal **Lazarus project**: trying to bring CalvaDOS back from the dead.

## The evolution of CalvaDOS

The CalvaDOS that existed on the surviving machines was the result of several generations of modifications. The artifacts give us a glimpse of that evolution.

| Stage | What                                                        | Controller | Disk          | Volumes       |
| ----- | ----------------------------------------------------------- | ---------- | ------------- | ------------- |
| A     | Stock GDOS 2.4, built-in hard-disk driver                   | Xebec      | 10 MB         | 5, 6          |
| B     | Arnulf Sopp, 1986 — new EPROM and SYS0/SYS on the hard disk | OMTI       | 10 MB         | 5, 6          |
| C     | A. Magnus and Volker Dose, ~1990                            | —          | ~20 MB Tandon | 5, 6, 7, 8, 9 |
| D     | E. Schroeer, ~1992                                          | —          | later ST-225  | 5, 6, ...     |

The dates and details come from the surviving artifacts wherever possible. Where the evidence is incomplete, I would rather leave a question mark than invent an answer.

That is also the philosophy of the reverse engineering in this repository: **separate what we know from what we think we know.**

When a new discovery proves an earlier conclusion wrong, I prefer to leave the wrong turn visible. It is part of the story—and sometimes the wrong turn is what finally leads to the right answer.

## What this repository contains

This repository is both a preservation effort and an attempt to reconstruct the software.

The original CalvaDOS source code has not been found. What exists here is therefore a mixture of surviving historical material, reconstructed code, experiments and documentation of what has been learned along the way.

The aim is not to pretend that the missing original can simply be recreated from memory.

The aim is to understand it well enough to make it live again.

## Documentation

The `docs/` directory contains the deeper technical material: architecture notes, reverse-engineering work, development notes and references to the original Genie IIIs software.

If you want to go down the rabbit hole, start with:

* `docs/architecture/`
* `docs/reverse-engineering/`
* `docs/development/`

The repository is not intended to be a perfectly clean historical archive. It is a record of an ongoing attempt to understand a piece of software that disappeared decades ago.

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

## Related repositories

* sdltrs-MultiHDC
* TCS-Trommeschlaeger-Genie-IIIs-GDos-2.4
* TCS-Trommeschlaeger-Genie-IIIs
* trsextract

## Credits

### The original Genie IIIs community

* Arnulf Sopp (The Hacktory) — CalvaDOS and the 1986 OMTI boot EPROM
* Andreas Magnus (HACKNUS-SOFTWARE)
* Volker Dose
* Helmut Bernhardt
* the GDOS 2.4 authors
* TCS and Uwe Böker

### Recovering what was left behind

**Fritz Chwolka** recovered `VOLKER.DMK` from Volker Dose's original floppy using a Catweasel controller.

**Jens Günther (JenGun)**, author of **sdltrs**, passed the recovered disk on.

Without that disk, there would be very little to work with.

## License

New code is released under **GPLv3**.

Documentation is released under **CC BY-SA 4.0**.

Original ROMs, binaries and other historical material remain the property of their respective copyright holders and are included only for preservation and research where permitted.
| A     | Stock G-DOS 2.4, built-in hard-disk driver                  | Xebec      | 10 MB         | 5, 6          |
| B     | Arnulf Sopp, 1986 — new EPROM and SYS0/SYS on the hard disk | OMTI       | 10 MB         | 5, 6          |
| C     | A. Magnus and Volker Dose, ~1990                            | —          | ~20 MB Tandon | 5, 6, 7, 8, 9 |
| D     | E. Schroeer, ~1992                                          | —          | later ST-225  | 5, 6, ...     |

The dates and details come from the surviving artifacts wherever possible. Where the evidence is incomplete, I would rather leave a question mark than invent an answer.

That is also the philosophy of the reverse engineering in this repository: **separate what we know from what we think we know.**

When a new discovery proves an earlier conclusion wrong, I prefer to leave the wrong turn visible. It is part of the story—and sometimes the wrong turn is what finally leads to the right answer.

## What this repository contains

This repository is both a preservation effort and an attempt to reconstruct the software.

The original CalvaDOS source code has not been found. What exists here is therefore a mixture of surviving historical material, reconstructed code, experiments and documentation of what has been learned along the way.

The aim is not to pretend that the missing original can simply be recreated from memory.

The aim is to understand it well enough to make it live again.

## Documentation

The `docs/` directory contains the deeper technical material: architecture notes, reverse-engineering work, development notes and references to the original Genie IIIs software.

If you want to go down the rabbit hole, start with:

* `docs/architecture/`
* `docs/reverse-engineering/`
* `docs/development/`

The repository is not intended to be a perfectly clean historical archive. It is a record of an ongoing attempt to understand a piece of software that disappeared decades ago.

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
docs/       Documentation
```

## Related repositories

* sdltrs-MultiHDC
* TCS-Trommeschlaeger-Genie-IIIs-GDos-2.4
* TCS-Trommeschlaeger-Genie-IIIs
* trsextract

## Credits

### The original Genie IIIs community

* Arnulf Sopp (The Hacktory) — CalvaDOS and the 1986 OMTI boot EPROM
* Andreas Magnus (HACKNUS-SOFTWARE)
* Volker Dose
* Helmut Bernhardt
* The G-DOS 2.4 authors
* TCS and Uwe Böker

### Recovering what was left behind

**Fritz Chwolka** recovered `VOLKER.DMK` from Volker Dose's original floppy using a Catweasel controller.

**Jens Günther (JenGun)**, author of **sdltrs**, passed the recovered disk on.

Without that disk, there would be very little to work with.

## License

New code is released under **GPLv3**.

Documentation is released under **CC BY-SA 4.0**.

Original ROMs, binaries and other historical material remain the property of their respective copyright holders and are included only for preservation and research where permitted.
