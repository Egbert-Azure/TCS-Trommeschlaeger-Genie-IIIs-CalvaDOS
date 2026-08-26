;************************************************************************
;
;	PATCH/CMD, this project's own -- builds CalvaDOS on drive 5
;
;
; Written and commented by
; E.H. Schroeer
;
; Name: patch.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
; Stage b (Sopp 1986 OMTI machine, 10 MB).
;
; Runs under a booted G-DOS 2.4, as the last step of CALVADOS/JOB, after
; HDFORMAT, GENDIR 5, GENDIR 6 and COPY have done their work:
;
;   1. patch five SYS files on drive 5
;   2. write the boot sector to absolute sector 0, with its start sector
;      set to wherever SYS0/SYS turned out to be
;
; In that order, so a half-patched disk is never made bootable.
;
; Ports 40h-43h only reach the OMTI card in Genie IIIs mode. Port 42h reads
; back 0FAh when the card is there; nothing is written unless it does.
;
; Addresses outside this file. Both names are Grosser's -- DSPLY from his
; chapter 3, DOSRDY cited by name -- and both are in
; docs/reference/gdos-2.4-addresses.md. The /CMD conventions are Volker
; Dose's own commands in docs/artefacts/volker/: JP DOSRDY to leave, an 0Dh-terminated
; string to print.
DSPLY	EQU	4467h		;display the 0Dh-terminated text at (HL)
DOSRDY	EQU	402dh		;return to the DOS prompt

VOLBASE	EQU	32		;drive 5's first absolute DOS sector
SCANLO	EQU	16		;first physical sector to scan (DOS 32)
SCANHI	EQU	600		;last; 1136 volume sectors, past any placement
				;COPY has been seen to produce
BOOTVS	EQU	18		;offset of LD DE,nnnn's operand in the sector

; Blob entry layout, from mkblob.py.
ELEN	EQU	0		;2  entry length, 0 ends the list
ENAME	EQU	2		;12 display name, 0Dh-terminated
ESIG	EQU	14		;8  first eight stock bytes
ENPAT	EQU	22		;2  patch count
EPAT	EQU	24		;   patches: off, len, old[len], new[len]

	ORG	7000h		;clear of the SYS overlay range, which ends 6FF9h

start	LD	HL,mhello
	CALL	DSPLY

	IN	A,(OMTSEL)		;card there, and are we in IIIs mode?
	CP	OMTCRD
	JP	NZ,enocrd

	XOR	A
	LD	(dirty),A
	LD	HL,0ffffh
	LD	(curphy),HL		;nothing cached yet

	DI
	CALL	hdrel
	CALL	hdtst
	EI
	JP	NZ,enordy

; Step 1: the five SYS files.

	LD	HL,0
	LD	(sysvs),HL		;0 = SYS0/SYS not located yet
	LD	IX,blob

files	LD	A,(IX+ELEN)		;a zero entry length ends the list
	OR	(IX+ELEN+1)
	JR	Z,alldone
	CALL	dofile
	JP	NZ,quit			;dofile has already said what and why
	LD	E,(IX+ELEN)
	LD	D,(IX+ELEN+1)
	ADD	IX,DE
	JR	files

; Step 2: the boot sector, aimed at what the scan found.

alldone	LD	HL,(sysvs)
	LD	A,H
	OR	L
	JP	Z,enosys		;SYS0/SYS was never located

; ------------------------------------------------------------
; [PATCH]     bootsec.bin+18
; Stock:      05 00  the operand of LD DE,0005h
; This build: the volume sector SYS0/SYS was found at
; Reason:     bootsec.asm reads 75 contiguous sectors from one
;             fixed address, and volume sector 5 is where
;             SYS0/SYS sits on a floppy. COPY does not
;             reproduce that on a GENDIR'd volume, so the
;             loader is aimed at the file rather than the file
;             moved under the loader.
; ------------------------------------------------------------

	LD	(boot+BOOTVS),HL

	LD	HL,0			;absolute sector 0
	LD	DE,boot
	DI
	CALL	hdwr
	EI
	JP	NZ,ewrite

; Read it back. The controller reports a write complete before the bytes
; are on the platter, and a wrong CDB lands 512 bytes elsewhere without
; failing.

	LD	HL,0
	LD	DE,vbuf
	DI
	CALL	hdrd
	EI
	LD	HL,0ffffh		;vbuf no longer holds a data sector
	LD	(curphy),HL
	JP	NZ,eread

	LD	HL,boot
	LD	DE,vbuf
	LD	BC,512
	CALL	cmpblk
	JP	NZ,ecmp

	LD	HL,mok
	CALL	DSPLY
	JP	DOSRDY

; One file.
;
; IX = its blob entry. Out: Z patched or already patched, NZ refused.

dofile	PUSH	IX
	POP	HL
	LD	DE,ENAME
	ADD	HL,DE
	CALL	DSPLY			;the name, without a newline of its own

	CALL	findfil			;where is it?
	RET	NZ
	LD	HL,(filevs)		;say so: the position is not fixed, and
	CALL	phex			;knowing it is half of any diagnosis

	LD	HL,(sysvs)		;SYS0/SYS is the first entry, and its
				;position is what the boot sector needs
	LD	A,H
	OR	L
	JR	NZ,dfnot0
	LD	HL,(filevs)
	LD	(sysvs),HL

dfnot0	LD	A,0			;verify against the stock bytes
	CALL	walk
	JR	Z,dfstock

	LD	A,1			;or against the patched ones
	CALL	walk
	JR	NZ,dfbad

	LD	HL,mskip
	CALL	DSPLY
	XOR	A
	RET

dfstock	LD	A,2			;every patch matched: write
	CALL	walk
	RET	NZ
	CALL	flush
	RET	NZ
	LD	HL,mdone
	CALL	DSPLY
	XOR	A
	RET

dfbad	LD	HL,mmatch
	CALL	DSPLY
	LD	L,(IX+ENPAT)		;which patch disagreed, counting from 1:
	LD	H,(IX+ENPAT+1)		;the total less the ones still to come
	LD	DE,(npatch)
	OR	A
	SBC	HL,DE
	CALL	phex
	OR	1
	RET

; Print HL as four hex digits.
;
; Enough to turn "passt nicht" into a number that says where to look.

phex	LD	DE,hexb
	LD	A,H
	CALL	phbyte
	LD	A,L
	CALL	phbyte
	LD	HL,hexmsg
	JP	DSPLY

phbyte	PUSH	AF
	RRA
	RRA
	RRA
	RRA
	CALL	phnib
	POP	AF
phnib	AND	0fh
	ADD	A,'0'
	CP	'9'+1
	JR	C,phn1
	ADD	A,7
phn1	LD	(DE),A
	INC	DE
	RET

hexmsg	DEFM	'  @'
hexb	DEFM	'0000',0dh

; Find a file by its signature.
;
; Checks both DOS halves of each 512-byte read, so one transport call
; covers two candidates.
; Out: Z found, (filevs) = volume sector, (filebs) = absolute DOS sector.

findfil	CALL	flush			;the scan writes vbuf behind getdos's back
	RET	NZ
	LD	HL,SCANLO
scan	LD	(scanp),HL
	LD	DE,vbuf
	DI
	CALL	hdrd
	EI
	JR	NZ,scannx		;an unreadable sector is not fatal here

	LD	DE,vbuf
	CALL	sigcmp
	JR	Z,shalf0
	LD	DE,vbuf+256
	CALL	sigcmp
	JR	Z,shalf1

scannx	LD	HL,(scanp)
	INC	HL
	LD	DE,0-SCANHI-1		;carry means HL is past the ceiling:
	PUSH	HL			;HL + (65536-SCANHI-1) only wraps when
	ADD	HL,DE			;HL >= SCANHI+1
	POP	HL
	JR	NC,scan
	LD	HL,0ffffh		;vbuf holds no known sector now
	LD	(curphy),HL
	LD	HL,mnofnd
	CALL	DSPLY
	OR	1
	RET

shalf1	LD	HL,(scanp)		;DOS sector = physical * 2, odd half
	ADD	HL,HL
	INC	HL
	JR	sgot
shalf0	LD	HL,(scanp)
	ADD	HL,HL
sgot	LD	(filebs),HL
	LD	DE,0-VOLBASE
	ADD	HL,DE
	LD	(filevs),HL
	LD	HL,(scanp)		;the scan left this sector in vbuf, and
	LD	(curphy),HL		;walk is about to want it
	XOR	A			;also the Z this returns: LD (nn),A
	LD	(dirty),A		;does not touch the flags
	RET

; Eight bytes at (DE) against this entry's signature. Out: Z equal.

sigcmp	PUSH	IX
	POP	HL
	LD	BC,ESIG
	ADD	HL,BC
	LD	B,8
sigc1	LD	A,(DE)
	CP	(HL)
	JR	NZ,sigc2
	INC	HL
	INC	DE
	DJNZ	sigc1
	XOR	A
	RET
sigc2	OR	1
	RET

; Walk this entry's patches.
;
; A = 0 compare against the stock bytes, 1 against the patched bytes,
; 2 write the patched bytes. Out: Z all patches matched, or all written.

walk	LD	(mode),A
	LD	L,(IX+ENPAT)
	LD	H,(IX+ENPAT+1)
	LD	(npatch),HL
	PUSH	IX
	POP	HL
	LD	DE,EPAT
	ADD	HL,DE
	LD	(patchp),HL

wnext	LD	HL,(npatch)
	LD	A,H
	OR	L
	JP	Z,wdone
	DEC	HL
	LD	(npatch),HL

	LD	HL,(patchp)
	LD	E,(HL)			;offset
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(coff),DE
	LD	E,(HL)			;length
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(clen),DE
	LD	(coldp),HL		;the stock bytes
	ADD	HL,DE
	LD	(cnewp),HL		;the patched bytes, right behind them
	ADD	HL,DE
	LD	(patchp),HL		;and the next patch behind those

wbyte	LD	HL,(clen)
	LD	A,H
	OR	L
	JP	Z,wnext
	DEC	HL
	LD	(clen),HL

; The file offset splits without dividing: its high byte is the sector
; within the file, its low byte the offset inside that sector.

	LD	HL,(coff)
	LD	A,L
	LD	(cbyte),A
	LD	L,H
	LD	H,0
	LD	DE,(filebs)
	ADD	HL,DE
	CALL	getdos
	RET	NZ

	LD	HL,(halfp)
	LD	A,(cbyte)
	LD	E,A
	LD	D,0
	ADD	HL,DE			;HL -> the byte on the disk

	LD	A,(mode)
	CP	2
	JR	Z,wwrite

	OR	A			;0 stock, 1 patched
	LD	DE,(coldp)
	JR	Z,wcmp
	LD	DE,(cnewp)
wcmp	LD	A,(DE)
	CP	(HL)
	JR	NZ,wfail
	JR	wstep

wwrite	LD	DE,(cnewp)
	LD	A,(DE)
	LD	(HL),A
	LD	A,1
	LD	(dirty),A

wstep	LD	HL,(coff)		;on to the next byte of this patch
	INC	HL
	LD	(coff),HL
	LD	HL,(coldp)
	INC	HL
	LD	(coldp),HL
	LD	HL,(cnewp)
	INC	HL
	LD	(cnewp),HL
	JP	wbyte

wfail	OR	1
	RET

wdone	XOR	A
	RET

; The sector cache.
;
; getdos: absolute DOS sector HL -> (halfp), its 256 bytes inside vbuf.
; Transfers are whole 512-byte sectors, so two DOS sectors share one; a
; modified one is held until another physical sector is wanted.

getdos	LD	A,L
	AND	1
	LD	(dhalf),A
	SRL	H			;physical = DOS / 2
	RR	L

	LD	A,(curphy)
	CP	L
	JR	NZ,gdload
	LD	A,(curphy+1)
	CP	H
	JR	Z,gdhalf

gdload	PUSH	HL
	CALL	flush
	POP	HL
	RET	NZ
	PUSH	HL
	LD	DE,vbuf
	DI
	CALL	hdrd
	EI
	POP	HL
	RET	NZ
	LD	(curphy),HL

gdhalf	LD	HL,vbuf
	LD	A,(dhalf)
	OR	A
	JR	Z,gdset
	LD	DE,256
	ADD	HL,DE
gdset	LD	(halfp),HL
	XOR	A
	RET

; Write vbuf back if anything in it changed.

flush	LD	A,(dirty)
	OR	A
	RET	Z
	LD	HL,(curphy)
	LD	DE,vbuf
	DI
	CALL	hdwr
	EI
	RET	NZ
	XOR	A
	LD	(dirty),A
	RET

; BC bytes at (HL) against (DE). Out: Z equal.

cmpblk	LD	A,(DE)
	CP	(HL)
	JR	NZ,cmpb1
	INC	HL
	INC	DE
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,cmpblk
	XOR	A
	RET
cmpb1	OR	1
	RET

; Messages.

mhello	DEFM	'CalvaDOS: Laufwerk 5 einrichten...',0dh
mdone	DEFM	'  gepatcht.',0dh
mskip	DEFM	'  war schon gepatcht.',0dh
mmatch	DEFM	'  passt nicht -- unveraendert gelassen.',0dh
mnofnd	DEFM	'  nicht gefunden.',0dh
mok	DEFM	'Fertig. Bootsektor gesetzt, CalvaDOS auf Laufwerk 5.',0dh
mnocrd	DEFM	'Keine OMTI-Karte auf Port 42h. Nichts geschrieben.',0dh
mnordy	DEFM	'Platte nicht bereit. Nichts geschrieben.',0dh
mnosys	DEFM	'SYS0/SYS nicht lokalisiert -- kein Bootsektor geschrieben.',0dh
mwrite	DEFM	'Schreibfehler auf Sektor 0.',0dh
mread	DEFM	'Sektor 0 nicht lesbar nach dem Schreiben.',0dh
mcmp	DEFM	'Rueckvergleich Sektor 0 fehlgeschlagen.',0dh
mstop	DEFM	'Abgebrochen. Kein Bootsektor geschrieben.',0dh

; Failures.

enocrd	LD	HL,mnocrd
	JR	fail
enordy	LD	HL,mnordy
	JR	fail
enosys	LD	HL,mnosys
	JR	fail
ewrite	LD	HL,mwrite
	JR	fail
eread	LD	HL,mread
	JR	fail
ecmp	LD	HL,mcmp
	JR	fail
quit	LD	HL,mstop
fail	EI
	CALL	DSPLY
	JP	DOSRDY

; The boot sector.

boot	INCBIN	'bootsec.bin'

; The patch set.

blob	INCBIN	'patchblob.bin'

; The OMTI transport.
;
; omtimin stays undefined: hddout, hdtst, hdrd and hdwr are all needed.

	INCLUDE	'omti.asm'

; Working storage.

scanp	DEFW	0		;physical sector the scan is looking at
filevs	DEFW	0		;this file's volume sector
filebs	DEFW	0		;this file's absolute DOS sector
sysvs	DEFW	0		;SYS0/SYS's volume sector, for the boot sector
mode	DEFB	0		;0 compare stock, 1 compare patched, 2 write
npatch	DEFW	0
patchp	DEFW	0
coff	DEFW	0		;byte offset within the file
clen	DEFW	0
coldp	DEFW	0
cnewp	DEFW	0
cbyte	DEFB	0		;offset within the sector
curphy	DEFW	0ffffh		;physical sector held in vbuf
dhalf	DEFB	0
halfp	DEFW	0		;-> the current DOS sector inside vbuf
dirty	DEFB	0
vbuf	DEFS	512

	END	start
