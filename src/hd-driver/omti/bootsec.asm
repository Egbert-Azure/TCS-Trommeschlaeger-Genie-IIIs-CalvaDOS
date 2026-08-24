;************************************************************************
;
;	Hard-disk boot sector
;
;
; Written and commented by
; E.H. Schroeer
;
; Name: bootsec.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
; Hard-disk boot sector, stage b (Sopp 1986 OMTI machine, 10 MB).
;
; The EPROM reads cylinder 0 / head 0 / sector 0 into 4200h-43FFh -- one
; 512-byte READ, streamed in two 256-byte INI passes -- and enters at
; 4200h with SP=0FFFEh, port 0F9h=20h, port 0FAh=10h, interrupts off,
; ports 40h-43h already active.
;
; Sector layout:
;   4200h-42FFh  this loader; the counterpart of the stock floppy boot
;                sector, same range, same size, same SYS0 reading it
;   4300h-43FFh  bootrd.asm, relocated to 3B00h on first entry; no
;                floppy counterpart, this half is Sopp's addition
;
; RAM: SYS0/SYS loads 0000h-32FBh and 400Ch-51DAh. 3300h-3FFFh is the
; only range free for the whole load. Sector buffer at 3300h, transport
; at 3B00h.
;
; 4200h-42FFh is m4200, the shared DOS sector buffer, not a private page.
; SYS0/SYS reads and writes fixed addresses inside it, and three of them
; fall below 42A0h where this loader's code lives:
;
;   4202h  read at 48F3h            -- DSL, see below
;   4212h  read at 4D10h, written at 4D77h -- the resume position
;   4266h  written at 4D5Fh and 4D92h, read at 50A8h -- see below
;
; All three are data here. Nothing else below 42A0h is touched: measured
; by enumerating every fixed-address read and write in SYS0/SYS from
; round-trip-verified disassemblies (z80dasm out, pasmo back in, cmp
; clean on all nine ranges).

vbase	EQU	32		;volume 0 base sector, from PDRIVE+0Ah
buf	EQU	3300h		;sector buffer; INC L wraps inside it

rdbase	EQU	3b00h		;where the transport is relocated to
rdsec	EQU	rdbase		;entry: HL = DOS sector number, DE = buffer
rdflag	EQU	rdbase+0ffh	;A5h once the relocation has been made

	ORG	4200h

; 4200h is both the EPROM hand-off and the re-entry after every staged
; transfer: SYS0/SYS ends its stub with JP 4200h at 4D7Bh. Grosser
; 9.4.1.2 documents 420Fh as the second entry point for the floppy boot
; sector, but the SYS0/SYS on this disk does not use it -- measured, and
; a run with a breakpoint on 420Fh never hit it.
;
; 4202h is DSL, the Directory Starting Lump. SYS0/SYS reads it at 48F3h
; (Grosser's SYS0 listing: 48F3 3A 02 42 LD A,(4202) "DSL holen"). His
; Genie IIIs boot sector has 30h there. That is the floppy's value; this
; volume's may differ, and the value is provisional until read out of
; the installed volume. It is consulted only on the directory path, not
; on the boot path, so a wrong value here costs DIR, not the boot.
;
; The JR at 4200h exists solely to step over it.
;
; Grosser 9.4.1.2 has LD A,C4 / OUT FA, "System-Port auf Normal-Betrieb".
; It is here, ahead of the rdflag read, because the Sopp EPROM hands off
; with 0FAh=10h and under that configuration the reads do not see the RAM
; the writes go to: measured at the 4200h breakpoint, 3BFFh reads 11h
; before the port write and 00h after, and 3B00h-3B03h reads
; 04 0E 04 04 before and FF 00 FF 00 after.

boot	JR	entry		;4200h-4201h
	DEFB	030h		;4202h -- DSL, provisional
	DEFB	0,0		;4203h-4204h

entry	DI
	LD	A,0c4h
	OUT	(0fah),A
	LD	A,(rdflag)
	CP	0a5h
	JR	NZ,reloc
	DEFS	4211h-$

; 4212h is the start sector, and it is not private to this loader.
; SYS0/SYS reads it at 4D10h (LD HL,(4212h) / LD (4D6Ah),HL, patching
; its own LD DE,nnnn immediate) and writes it back at 4D77h
; (LD (4212h),DE) after advancing it 18 positions -- 12h at 4D67h, an
; absolute offset to the next module, correct on both the floppy and
; this volume.
;
; The loaded code owns this address. This loader reads it here and must
; never write it: an earlier version wrote the resume position back at
; xfer, which made SYS0 advance two sectors past where it should have
; resumed and land in the wrong module.
;
; 5 is a DOS sector number, volume-relative; rdsec halves the absolute LBA.
; hdvfmt.py places SYS0.hd at volume sector 5 (--place SYS0.hd@5, unchanged
; since before the 56ec00d 512-byte-sector rework, where this loader's own
; start value was LD DE,0005h too). LBA 32+5 = 37, physical sector 18, back
; half (37 is odd) -- confirmed live: SYS0.hd's own first 16 bytes
; (01 02 00 4D A5 18 0D C3 96 4D 00 53 69 64 65 34) land exactly there.
;
; The 0078h (120) this briefly held instead, from the 56ec00d rework, never
; matched any --place argument this project has used; whatever its own
; "confirmed" comment found was at a different, since-abandoned build state.

start	LD	DE,0005h
	EXX			;position lives in the alternate set
	LD	SP,41e0h	;stock GDOS/NEWDOS-80's own boot-time value (Grosser
				;ch.3 p.3-57, quoted at sys0-sys-disassembly.asm:4D00h:
				;"Stackpointer steht auf 41E0h") -- matches the stock
				;floppy boot's own measured SP (41D6h) 10 bytes deeper
				;at the equivalent point. Not a load target of any
				;SYS0.hd record (trsload.py --map), so safe during
				;this loader's own load loop too. Was 3B00h, only 256
				;bytes above SYS26/SYS's own 3900h-3AFFh scratch
				;buffer -- deep GETSYS/SYS26 call nesting reliably
				;pushed SP into that buffer, corrupting a return
				;address and hanging at PC=0000h (HALT). A stock boot
				;runs the same SYS26 code but never hits this: its
				;own stack never comes near 3A00h-3BFFh.
	LD	HL,buf+0ffh

;	--- load-module record loop -----------------------------------------

next	CALL	getb		;record type
	CP	20h
	JR	NC,bad
	LD	B,A
	CALL	getb		;length
	LD	C,A
	CALL	getb		;address, low
	LD	E,A
	DJNZ	notld		;type 1 falls through
	CALL	getb		;load address, high
	LD	D,A
	DEC	C
	DEC	C		;the length counts the two address bytes
copy	CALL	getb
	LD	(DE),A
	INC	DE
	DEC	C
	JR	NZ,copy
	JR	next

; Type 2 ends a load module. Grosser 9.4.1.2, 4249h-424Dh: start at the
; transfer address, or at transfer address + 1 when the byte there is
; A5h. That is how SYS0/SYS gets its staged load.
;
; Nothing is written back here. The loaded code sets 4212h itself before
; it re-enters at 4200h.

notld	DJNZ	skip		;type 2 falls through
	CALL	getb		;transfer address, high
	LD	D,A
	LD	A,(DE)
	CP	0a5h
	JR	NZ,xfer
	INC	DE
xfer	PUSH	DE
	RET
bad	JR	bad		;nothing to print to; park

; Grosser 2-1 (c), control codes 00h and 03h-1Fh: a length byte and as
; many data bytes as the length byte gives -- no address field, and no
; minus two. The byte already read into E above is one of those data
; bytes, so the loop runs C-1 more times. C=0 is 256.

skip	DEC	C
	JR	Z,next
skip1	CALL	getb
	DEC	C
	JR	NZ,skip1
	JR	next

;	--- one byte from the buffer, refilling when it runs out -------------

getb	INC	L
	CALL	Z,fill
	LD	A,(HL)
	RET

; 4265h/4266h on the stock floppy boot sector is LD (HL),11h, "Seite 1
; anwaehlen" (Grosser 9.4.1.2). SYS0/SYS writes 4266h at 4D5Fh and 4D92h
; and reads it at 50A8h, where only BIT 3,A is tested: it selects
; between two constant pairs patched into 4CFCh, 46A4h and 4CF9h.
; Both write paths produce 11h -- 4D5Fh writes it outright, and 4D92h's
; 10h/08h branch turns on bit 0 of 4D0Bh, which is even in both modules,
; then ORs 01h. The stock sector has 11h. So 11h, bit 3 clear.
;
; What it must not be is an instruction. It was the OR A of fill's
; D=0 shortcut, and SYS0 writing 11h over it turned
;   LD A,D / OR A / JR Z,fill2
; into
;   LD A,D / LD DE,0D28h / LD B,A
; which swallowed the JR, so fill1 always ran with B=0 -- 256 iterations
; of ADD spt, putting C000h into every LBA. That is the whole of the
; runaway: HL came out C0AAh where 00AAh was wanted.
;
; getb ends in RET and fill is only ever CALLed, so nothing falls
; through this island.

reloc	JP	4303h		;relocator, in the stored copy of bootrd
	DEFS	4266h-$
	DEFB	011h		;4266h

; Read the sector at the alternate DE, then step that position on by one,
; wrapping at (42B0h) sectors per track.

fill	EXX
	PUSH	BC
	PUSH	HL
	PUSH	DE
	LD	L,E		;LBA = vbase + D*spt + E
	LD	H,0
	LD	A,D
	OR	A
	JR	Z,fill2
	LD	B,A
	LD	A,(spt)
	LD	C,A
fill1	LD	A,L
	ADD	A,C
	LD	L,A
	JR	NC,fill3
	INC	H
fill3	DJNZ	fill1
fill2	LD	DE,vbase
	ADD	HL,DE
	LD	DE,buf
	CALL	rdsec
	POP	DE
	INC	E
	LD	A,(spt)
	CP	E
	JR	NZ,fill4
	LD	E,0
	INC	D
fill4	POP	HL
	POP	BC
	EXX
	RET

;	--- the configuration SYS0/SYS reads out of 4200h --------------------
;
; On a floppy this range holds what CALL 4436h at 50C4h read in, through
; an FCB whose drive byte is 0. On a hard-disk boot that read cannot
; work: the driver that would serve it is initialised four instructions
; later, at 50D4h. The call is patched out of SYS0/SYS at file offset
; 0x113C (XOR A / NOP / NOP -- confirmed present as loaded: 50C4h
; disassembles AF 00 00) and these bytes stand in for it.
;
; They are the config sector as a working floppy boot of this same GDOS
; has it at 4D44h, the instruction after the read, captured by
; breakpoint. SYS0 takes 42A0h as the drive count, 42A1h-42A3h and 42A6h
; as further SYSTEM parameters, 42EFh as an A5h validity marker, and
; 42F0h-42F3h and 42F8h-42FFh as more of the same.
;
; These bytes only have to survive the window between this sector
; landing and SYS0's cold start consuming it. m4200 is the shared DOS
; sector buffer, not a protected area, and nothing keeps them there
; beyond that.

	DEFS	42a0h-$

; 42A2h/42A3h are SYSTEM AN/AO, the default drive for DIR and for a file
; create with no drive letter. The floppy capture has 0,0 -- right there,
; wrong here: no floppy is attached and the boot volume is drive 5.
; SYS0's cold start at 4D77h/4D7Dh copies them to 43A0h/43A1h; SYS8
; reads 43A0h at 4D50h for DIR, SYS2 reads 43A1h at 4DCFh for an
; unqualified open.

	DEFB	4,2,5,5,0,0,1,01eh
	DEFB	0ffh,2,0,0,0,0,0,0

; 42B0h: sectors per track. Also read by SYS0/SYS at 4D6Dh, inside the
; same advance loop that adds 12h -- it divides by this to carry E into
; D. The config sector has 00h here and SYS0 never reads it as config,
; so the two uses coexist.

spt	DEFB	192

	DEFB	0,0,0,0,0,0,0,0
	DEFB	0,0,0,0,0,0,0,2
	DEFB	011h,01fh,00ch,020h,2,2,011h,01fh
	DEFB	0,0,0,0,0,0,0,0
	DEFB	0,01fh,1,040h,8,0,4,1
	DEFB	040h,8,0,0,0,0,0,088h
	DEFB	0,084h,041h,04fh,028h,0,025h,0c1h
	DEFB	04fh,068h,019h,3,0,0,0a5h,032h
	DEFB	0f0h,081h,0,0,0,0,0,07fh
	DEFB	00ch,0,0,0,0,0,0

	DEFS	4300h-$
