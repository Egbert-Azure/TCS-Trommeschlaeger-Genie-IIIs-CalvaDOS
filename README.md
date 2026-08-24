<img width="100" height="25" alt="black-logo" src="https://github.com/user-attachments/assets/12af5c46-99aa-420f-a704-6a905b061939" />
<img width="745" height="249" alt="Screenshot 2026-08-22 at 5 27 56 PM" src="https://github.com/user-attachments/assets/05e825d3-280d-494a-8a73-8f1f827261d4" />

# CalvaDOS

The original CalvaDOS hack is lost. First things first, and Prost!

## Where this stands today

**It boots.** The reconstruction comes up from the hard disk, reaches the command prompt, and `DIR` reads a real directory off volume 5. `MEMDISK` creates the `RAMDISK` it should. Getting there took considerably longer than I expected - isn't always like this?

One known defect is still open — see the issues. Everything else that has been tested works. You can run it via my own sdltrs-MultiHDC emulator which has the OMTI controller aside the XEBEC.

However, this is a reconstruction, not a recovered original. The 1986 CalvaDOS binaries have not turned up, and nothing in this repository claims to be them. Including the boot logo you see in this REEADME it's out of my memory.

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

And because enough of it survived to give it a try.

And because, in a time when almost nobody has a reason to write software for a Genie IIIs anymore, it seemed like a good excuse to do exactly that.

This is my personal **Lazarus project**: trying to bring CalvaDOS back from the dead.

## The evolution of CalvaDOS

The CalvaDOS that existed on the surviving machines was the result of several generations of modifications. The artifacts give us a glimpse of that evolution.

| Stage | What                                                        | Controller | Disk          | Volumes       |
| ----- | ----------------------------------------------------------- | ---------- | ------------- | ------------- |
| A     | Stock G-DOS 2.4, built-in hard-disk driver                  | Xebec      | 10 MB         | 5, 6          |
| B     | Arnulf Sopp, 1986 — new EPROM and SYS0/SYS on the hard disk | OMTI       | 10 MB         | 5, 6          |
| C     | A. Magnus and Volker Dose, ~1990                            | unknown    | ~20 MB Tandon | 5, 6, 7, 8, 9 |
| D     | E. Schroeer, ~1992                                          | unknown    | later ST-225  | 5, 6, ...     |

**Stage B is what this repository reconstructs.**

This will change over time for sure to reconstruct the different stages. As said in the beginning, it just takes more time.
The dates and details come from the surviving artifacts wherever possible. Where the evidence is incomplete, I would rather leave a question mark than invent an answer.

That is also the philosophy of the reverse engineering in this repository: **separate what we know from what we think we know.**

When a new discovery proves an earlier conclusion wrong, I prefer to leave the wrong turn visible. It is part of the story—and sometimes the wrong turn is what finally leads to the right answer.

## What this repository contains

This repository is both a preservation effort and an attempt to reconstruct the software.

The original CalvaDOS source code has not been found. What exists here is therefore a mixture of surviving historical material, reconstructed code, experiments and documentation of what has been learned along the way.

The aim is not to pretend that the missing original can simply be recreated from memory.

The aim is to understand it well enough to make it live again.
## Tools

I'm a bit tired to explain myself but here we are again. The first tool is the unglamorous one: my own head. Experience, knowledge, and the patience to read the same page of a manual five times until it finally makes sense.

That is the whole point of this exercise. I want to understand the past again. If you don't understand where something came from, you are in no position to build what comes next.

After that, in rough order of how much I lean on them:

> **Visual Studio Code**
> I use it heavily and make use of much of what it offers — fast typing of Z80 source, mnemonic and `EQU` tables, annotations, and long working lists that keep an investigation on track over weeks. I have also built a local Z80/GDOS environment around it: snippets, IntelliSense/completion data, custom dictionaries, syntax and grammar definitions, and editor configuration that incorporates my own reference tables and working notes. This means that much of the information I need while disassembling and modifying GDOS is already available in the editor, where I can work with it directly rather than reconstructing it from scratch.
>
> **z80dasm** for disassembly and **pasmo** for assembling. Both do exactly what they say and nothing more, which is what I want from a tool whose output I have to trust byte for byte.
>
> **sdltrs-MultiHDC** — sdltrs extended with the OMTI support this work needed — and **zbx** when I need to see what the Z80 is actually doing rather than what I assume it is doing.
>
> **The contemporary documentation**
> Hartmut Grosser's *Das DOS-Buch*, Uwe Böker's *Technische Beschreibung zum GENIE IIIs*, and the TCS addendum to the G-DOS 2.4 manual. When a document from the period and a conclusion of mine disagree, the document wins until I can prove otherwise.
>
> Everything else is hex dumps, byte diffs, checksums and a lot of notes.


## Repository

The repository is organized around the material used to reconstruct and run CalvaDOS rather than around a conventional software-project structure.

```text
DMK/
    Floppy disk images, including the original GDOS 2.4 reference image
    and the CalvaDOS patch disk.

HDV/
    Hard-disk images for sdltrs-MultiHDC.
    blank-612x2x17.hdv is an empty disk image that can be used as
    the starting point for a new installation. Dated images are
    working reconstruction states.

patchdisk/
    The files used to create and populate the CalvaDOS patch disk.
    The patch disk can be used in two ways:
      - on a physical Genie IIIs, booting with F2 held down
      - in sdltrs-MultiHDC, with blank-612x2x17.hdv attached and F2 held down

ROM/
    Boot ROMs and EPROM images.

src/
    Source code, build tools, and the reconstructed GDOS system files.
    The OMTI and Xebec hard-disk work is under src/hd-driver/.

docs/reference/
    Period documentation and technical references.

docs/artefacts/
    Investigation material: traces, disassemblies, notes, experiments,
    and other evidence accumulated during the reconstruction.
```

If you want to reproduce the reconstruction without the original hardware, the simplest route is to start with `HDV/blank-612x2x17.hdv`, attach it to `sdltrs-MultiHDC`, and boot with F2 held down. The patch disk and its contents are in `DMK/` and `patchdisk/`.

If you have a physical Genie IIIs, the same patch disk can be transferred to a real floppy and used to boot the modified system with F2 held down.


## Related repositories

* [sdltrs-MultiHDC](https://github.com/Egbert-Azure/sdltrs-MultiHDC) — the emulator, extended for OMTI hard-disk support
* [TCS-Trommeschlaeger-Genie-IIIs-GDos-2.4](https://github.com/Egbert-Azure/TCS-Trommeschlaeger-Genie-IIIs-GDos-2.4) — stock G-DOS 2.4 and its reverse engineering
* [TCS-Trommeschlaeger-Genie-IIIs](https://github.com/Egbert-Azure/TCS-Trommeschlaeger-Genie-IIIs) — hardware and historical documentation
* [trsextract](https://github.com/Egbert-Azure/trsextract) — extracting files from Genie IIIs disk images

## Credits

### The original Genie IIIs community

* Arnulf Sopp (The Hacktory) — CalvaDOS and the 1986 OMTI boot EPROM
* Andreas Magnus (HACKNUS-SOFTWARE)
* Volker Dose (my brother in crime back in those days)
* Helmut Bernhardt
* Marcus von Cube and Klaus Kämpf — the G-DOS 2.4 authors
* TCS and Uwe Böker

### Recovering what was left behind

**Fritz Chwolka** recovered `VOLKER.DMK` from Volker Dose's original floppy using a Catweasel controller.

**Jens Günther (JenGun)**, author of **sdltrs**, passed the recovered disk on.

Without that disk, there would be very little to work with.

## License

New code is released under **GPLv3**.

Documentation is released under **CC BY-SA 4.0**.

Original ROMs, binaries and other historical material remain the property of their respective copyright holders and are included only for preservation and research where permitted.
