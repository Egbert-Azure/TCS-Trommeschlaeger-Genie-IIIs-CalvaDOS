;************************************************************************
;
;	GDOS 2.4 resident hard-disk driver
;
;
; Written and commented by
; E.H. Schroeer
;
; Name: gdos-omti.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
; GDOS 2.4 resident hard-disk driver for the OMTI 5527.
; Replaces SYS0/SYS module 1, the Xebec S1410 hard-disk driver.
; The DOS-facing layout follows the Xebec driver through F065h.
; OMTI transport routines are included from omti.asm.
;
; DOS sectors are 256 bytes. The OMTI transfer path is 512 bytes
; in the current emulator configuration; the second 256 bytes are
; drained on reads and filled on writes.
;
	ORG	0f000h

; Resident DOS addresses
; These addresses are part of the GDOS/Xebec driver interface.
ddrive	EQU	4308h
dmask	EQU	4309h
dpdrv	EQU	430ah
dpptr	EQU	4399h
dgran1	EQU	4c88h
dgran2	EQU	4cb3h
ddskmnt	EQU	47efh
dcmd	EQU	46c4h
ddrvsl	EQU	477ch
ddrvfl	EQU	4780h
ddrver	EQU	47deh
dxfer	EQU	4642h
dxferf	EQU	4645h
dmulhl	EQU	4c92h
dmulov	EQU	4c94h
dbank	EQU	0f9h

; Return path from driver initialization.
; The caller enters init with JP and expects control back here.
dinit	EQU	3200h

dsave	EQU	4306h
ddrvnr	EQU	4784h
; 42A0h in the configuration sector is the floppy-drive count. SYS0/SYS's
; cold start at 4D63h is the only thing that reads it, and it is also the
; only writer of 439Fh (dndrv, "Anzahl Drives" -- history/00-volker-dose-workdisk/SYS29.asm) and
; of 477Ah (DRVSEL's own CP operand). All three are left to SYS0, whose
; 4D63h block run-hdboottest.sh patches; this driver computes none of them,
; so there is one source of truth for the drive count. Kept as a label
; because gcfg's own tail below is laid out from it.
dnflop	EQU	42a0h
dbanks	EQU	36ffh
dbankt	EQU	36fdh
dtab	EQU	37dfh
dtabh	EQU	37d6h

; GETSYS shared FCB fields
dfcbdv	EQU	43d8h

dfcbdv2	EQU	43d4h

dfcbdec	EQU	43d5h

ddrvsel	EQU	4776h		;DRVSEL itself; ddrvsl below is the hook site inside it

dgetfde	EQU	4936h

; Low-RAM resident code copied by ginit.
rhook	EQU	3700h
rstub	EQU	3a00h
rpdrv	EQU	37cch

; The two GETSYS stubs.
;
; 448Ch-449Fh is 20 bytes of FFh inside SYS0/SYS's always-resident
; 4400h-4CFFh block: the only run of eight or more identical bytes anywhere
; in it, referenced by nothing, and outside the swappable 4D00h-51E7h module
; window so it does not change meaning when a SYS file is loaded. The two
; stubs need 16 of the 20; the assertion at the end of this file checks that
; they still fit.
;
; Not low RAM after the hook block: 3738h-375Fh is GDOS's own bank-switch
; block, present at the same address in a stock floppy boot with none of this
; port's code involved, and the hook block at 3700h-3737h fills the 56 bytes
; in front of it exactly.
rsysfcb	EQU	448ch
rdecfix	EQU	rsysfcb+9
rfree	EQU	449fh		;last byte of the FFh run

; Status and configuration constants
sgran	EQU	5
smount	EQU	0c0h
sdir	EQU	06h
sbaddr	EQU	21h
sbadfn	EQU	08h
sbaddv	EQU	20h

; DOS drive containing the configured system volume.
; This matches the gpar entry for the boot volume.
sysvol	EQU	05h

; Per-DOS-drive dispatch parameters.
; High nibble selects the dispatch slot; low nibble is its argument.
; Drive 4 (slot 3, F016h) routes to MEMDISK/CMD's own extension point, not
; this driver's gflop/gvol/grej8/grej20 slots -- see slot 3's own comment
; below.
gpar	DEFB	10h,11h,12h,13h,30h,40h,41h,00h,7fh,42h

	JP	ginit
; Fixed entry points and dispatch table.
;
; Slot 3 (F016h) is MEMDISK/CMD's own hook -- not this driver's. Static
; disassembly (src/GDOS-2.4-SYS-files/memdisk-cmd-disassembly.asm, around
; 30A0h) shows MEMDISK's own install path does "LD HL,0F4A3h /
; LD(0F016h),HL" -- patching this exact slot's dispatch target to its own
; resident code once copied to F400h, unprompted, using no address this
; driver ever hands it. gpar's drive 4 selects that slot so the two meet.
; Left at its original grej8 here, matching every other currently-unclaimed
; slot, so drive 4 correctly rejects on its own until MEMDISK/CMD actually
; runs and overwrites this exact address.
gwork	JP	gexit0

	DEFW	grej8
	DEFW	gflop
	DEFW	grej8
	DEFW	grej8
	DEFW	gvol
	DEFW	grej8
	DEFW	grej8
	DEFW	grej20

	DEFS	32
	DEFW	gexit1

; Enter a driver routine with the driver bank selected.
; HL = routine, DE = low-RAM return address.
gbank	LD	(gsp+1),SP
	LD	SP,gstk
	LD	(gjp+1),DE
	JP	(HL)

; The two exits, and the carry contract between them.
;
; Carry on the way out means "this is not mine, use the floppy path": ghook's
; DRVSEL half ends JP C,ddrvfl and its transfer half JP C,dxferf. Both exits
; are otherwise identical, and the flag is set two different ways depending on
; which one is used -- worth stating, because neither is visible at the site
; that depends on it.
;
;   gexit1 is what a driver routine's own RET lands on: gstk-2 holds the word
;   gexit1 (the DEFW above), so a RET on the driver stack falls straight into
;   it with whatever carry the routine left. gflop leaves carry set -- not by
;   an SCF, but as the borrow from its own CP 2, which survives the three
;   flag-neutral instructions that follow it. grejc clears carry with OR A and
;   gvol returns with it clear, so both take the normal return. Calling DRVSEL
;   directly: drives 0 and 1 reach ddrvfl with carry set, drive 5 and drive 8
;   reach ddrver with it clear.
;
;   gexit0 is not on that path at all. It is only ever reached through gwork,
;   the work vector, which gflop points here when it hands a floppy drive
;   back; a floppy transfer then enters gwork and this SCF is what routes it
;   to dxferf. A hard-disk boot therefore never executes this instruction at
;   all, which is not grounds for removing it.
gexit0	SCF
gexit1	LD	SP,0000h
gsp	EQU	gexit1
	EX	AF,AF'
	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
gjp	JP	0000h

gstk	EQU	0f040h

; DRVSEL hook
gdrvsl	LD	HL,gdisp
	LD	DE,rhook+0ch
	JR	gbank

; Restore floppy defaults, then dispatch the selected DOS drive.
; A = DOS drive number on entry.
gdisp	IN	A,(dbank)
	AND	3eh
	OR	41h
	DI
	OUT	(dbank),A
	LD	A,sgran
	LD	(dgran1),A
	LD	(dgran2),A
	LD	A,smount
	LD	(ddskmnt),A
	EX	AF,AF'
	CP	0ah
	JR	NC,grej20
	LD	(ddrive),A

	LD	(dsave),A
	LD	H,gpar/256
	LD	L,A
	LD	A,(HL)
	PUSH	AF
	AND	70h
	RRCA
	RRCA
	RRCA
	LD	E,A
	LD	D,0
	LD	L,10h
	ADD	HL,DE
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	POP	AF
	AND	0fh
	JP	(HL)

; Reject an invalid DOS drive number, or (grej8) an unsupported one --
; identical past the error code itself, so grej20 just loads its own and
; falls into grej8's own tail rather than repeating it.
grej20	LD	A,sbaddv
	JR	grejc
grej8	LD	A,sbadfn
grejc	LD	HL,grej8
	LD	(gwork+1),HL
	OR	A
	RET

; Hand floppy drives back to the normal FDC path.
; Two separate signals, one for each half of ghook -- see the carry contract
; at gexit0. The DRVSEL half is told by the carry this routine returns, which
; is the borrow from CP 2 below and not an SCF: LD C,A / LD HL,nn / LD (nn),HL
; are all flag-neutral, so it reaches ghook's JP C,ddrvfl intact. The transfer
; half is told by the work vector, pointed at gexit0's SCF here.
gflop	CP	2
	JR	NC,grej8
	LD	C,A
	LD	HL,gexit0
	LD	(gwork+1),HL
	RET

; Select hard-disk volume.
; A = volume number.
; Copies the PDRIVE data and installs the volume geometry.
gvol	LD	HL,gxfer
	LD	(gwork+1),HL
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	E,A
	LD	D,0
	LD	HL,gtab
	ADD	HL,DE
	PUSH	IX
	PUSH	HL
	POP	IX
	PUSH	HL
	LD	DE,dpdrv
	LD	BC,0008h
	LDIR
	POP	HL
	LD	DE,rpdrv
	LD	(dpptr),DE
	LD	BC,000ah
	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
	LDIR
	IN	A,(dbank)
	AND	3eh
	OR	41h
	DI
	OUT	(dbank),A

	LD	C,(IX+0dh)
	LD	A,C
	LD	(dgran1),A
	LD	(dgran2),A

	LD	A,(IX+0ch)
	LD	(gbash+1),A
	LD	L,(IX+0ah)
	LD	H,(IX+0bh)
	LD	(gbasl+1),HL

	LD	L,(IX+04h)
	LD	A,(IX+03h)
	CALL	dmulhl
	DEC	HL
	LD	(glim+1),HL

	LD	L,(IX+08h)
	LD	A,(IX+05h)
	CALL	dmulhl
	LD	A,C
	CALL	dmulov
	LD	(gdlo+1),HL
	EX	DE,HL
	LD	L,(IX+09h)
	LD	A,C
	CALL	dmulhl
	LD	A,L
	CP	1fh
	JR	C,gvol1
	LD	L,1eh
gvol1	ADD	HL,DE
	DEC	HL
	LD	(gdhi+1),HL

	LD	A,0c9h
	LD	(ddskmnt),A
	XOR	A
	LD	(dmask),A
	POP	IX

	CALL	hdsel
	JR	NZ,gvol2
	CALL	hdrel
	XOR	A
	RET
gvol2	LD	A,sbadfn
	OR	A
	RET

; Disk-transfer hook
gxfhk	LD	(gxhl+1),HL
	LD	(gxde+1),DE
	LD	HL,gxfin
	LD	DE,rhook+29h
	JP	gbank

gxfin	IN	A,(dbank)
	AND	3eh
	OR	41h
	DI
	OUT	(dbank),A
	EX	AF,AF'
	LD	(dcmd),A
gxhl	LD	HL,0000h
gxde	LD	DE,0000h
	JP	gwork

; Perform one GDOS sector transfer.
; HL = DOS buffer, DE = volume-relative sector, A = DOS command.
gxfer	PUSH	BC
	PUSH	DE
	PUSH	HL
	EX	AF,AF'

glim	LD	HL,0000h
	OR	A
	SBC	HL,DE
	JR	NC,gxf1
	LD	A,sbaddr
	JR	gxf9

gxf1	LD	A,0
gdhi	LD	HL,0000h
	OR	A
	SBC	HL,DE
	JR	C,gxf2
gdlo	LD	HL,0000h
	OR	A
	SBC	HL,DE
	JR	C,gxfdir
	JR	NZ,gxf2
gxfdir	LD	A,sdir
gxf2	LD	(gsts+1),A

	EX	DE,HL
gbasl	LD	DE,0000h
	ADD	HL,DE
gbash	LD	A,0
	ADC	A,0
	JR	NZ,gxfbig
	LD	(hdlba),HL

	POP	HL
	PUSH	HL

	EX	AF,AF'
	BIT	5,A
	JR	NZ,gxf3
	CALL	gread
	JR	gxf4
gxf3	CALL	gwrite
gxf4	JR	NZ,gxf8
gsts	LD	A,0
	JR	gxf9
gxf8	LD	A,(hdlerr)
	OR	A
	JR	NZ,gxf9
	LD	A,sbadfn
	JR	gxf9
gxfbig	LD	A,sbaddr
gxf9	POP	HL
	POP	DE
	POP	BC
	OR	A
	RET

; Read one DOS sector from the OMTI.
gread	PUSH	HL
	LD	A,CMDRD
	CALL	hdclr
	LD	HL,0b2edh
	LD	DE,078edh
	JR	gxio

; Write one DOS sector to the OMTI.
gwrite	PUSH	HL
	LD	A,CMDWR
	CALL	hdclr
	LD	HL,0b3edh
	LD	DE,079edh

; Prepare the low-RAM transfer stub and issue the OMTI command.
;
; hdlba addresses a DOS (256-byte) sector; the OMTI moves 512-byte
; sectors, two DOS sectors to one. gsop always bursts the first
; (even) half for real -- hdchs needs the physical (512-byte) sector
; number, so hdlba is halved first, and the bit shifted out is the
; odd/even flag. On an odd read, gsync (a self-modified +0/-256
; no-op/undo) rewinds HL after gsop, and gsec is repatched from its
; default drain into a real second burst (INI) that overwrites the
; discarded first half with the wanted second one. An odd write is
; left in drain/pad mode, unchanged -- a correct fix there needs a
; read-modify-write of the whole physical sector, not just a swap.
gxio	CALL	gcopy
	LD	(rstub+gsop-gstub),HL
	LD	(rstub+gsec-gstub),DE
	LD	A,(hdpags)
	CP	1
	JR	Z,gxios		;one 256-byte page only -- hdlba is already page-granular
	LD	HL,(hdlba)
	SRL	H
	RR	L		;HL = physical sector; carry = hdlba's original bit 0
	PUSH	AF
	CALL	hdchs
	POP	AF
	JR	NC,gxio0	;even -- defaults patched above are already correct
	LD	A,(hdcdb)
	CP	CMDRD
	JR	NZ,gxio0	;odd + write -- known limitation, left as drain/pad
	LD	HL,0a2edh	;INI -- second phase becomes a real transfer
	LD	(rstub+gsec-gstub),HL
	LD	A,20h		;JR NZ -- INI decrements B itself, DJNZ would double it
	LD	(rstub+gsecl-gstub),A
	LD	HL,0ff00h	;-256, undo gsop's advance
	LD	(rstub+gsyncv-gstub),HL
	JR	gxio0
gxios	LD	HL,gskipop	;hdpags==1: skip the second phase outright
	LD	(rstub+gsec-gstub),HL
	LD	HL,(hdlba)
	CALL	hdchs
gxio0	LD	A,1
	LD	(hdcdb+4),A
	CALL	hdsel
	POP	HL
	RET	NZ
	PUSH	HL
	LD	HL,hdcdb
	CALL	hdcmd
	POP	HL
	RET	NZ

	CALL	hdreq
	RET	NZ
	LD	B,A
	LD	A,(hdcdb)
	CP	CMDWR
	LD	A,B
	JR	Z,gxio1
	AND	OMTIO
	JP	Z,hdperr
	JR	gxio2
gxio1	AND	OMTIO
	JP	NZ,hdperr

gxio2	LD	BC,OMTDAT
	CALL	rstub
	JP	hdend


; ---------------------------------------------------------------------------
; Live code continues here. Everything from the top of the file to this point,
; and everything from gdeade (the templates, below the configuration sector)
; to the end, has to survive for as long as the driver is resident. The block
; between them does not, which is what makes the layout below possible.
; ---------------------------------------------------------------------------

; Copy the transfer stub to low RAM before each transfer.
gcopy	PUSH	HL
	PUSH	DE
	PUSH	BC
	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
	LD	HL,gstub
	LD	DE,rstub
	LD	BC,gstube-gstub
	LDIR
	POP	BC
	POP	DE
	POP	HL
	RET

; Hard-disk volume table.
; Each entry is 16 bytes: 10 bytes of PDRIVE data followed by
; the volume base sector and sectors-per-GRAN.
gtab	DEFB	030h,060h,0d4h,050h,024h,006h,080h,043h,030h,006h,20h,00h,00h,05h,00h,00h
	DEFB	01h,7bh,04h,0a3h,0c0h,08h,00h,00h,01h,01h,20h,1eh,00h,20h,00h,00h
	DEFB	0cdh,9ah,04h,77h,0c0h,08h,00h,00h,0cdh,00h,00h,00h,00h,20h,00h,00h

; Absolute OMTI sector for the current transfer.
hdlba	DEFS	2

; Tell omti.asm to leave out hdtst/hdrd/hdwr and the hddin/hddout pair
; they're built on -- single-command routines this driver never calls
; (gxio does its own burst via gstub instead); only hdtest.asm/hdwtest.asm
; use them, and they never set this. See hdperr's own comment in omti.asm.
omtimin	EQU	1

	INCLUDE	'omti.asm'

; ---------------------------------------------------------------------------
; Dead-after-boot block: ginit and the configuration sector.
;
; MEMDISK/CMD copies its own resident driver over F400h-F567h when it runs
; (its disassembly, 3090h: LD DE,0F400h / LD BC,00168h / LDIR). Nothing this
; driver keeps live may sit there.
;
; Rather than pad the live code past it, the two things that are already dead
; by then are laid across it: ginit runs once, called from SYS0's cold start,
; and gcfg is the 256-byte configuration sector ginit copies to 4200h and
; nothing reads again. MEMDISK gets exactly the memory it takes and the
; driver spends no bytes on a hole. The assertions at the end of this file
; check the cover, in both directions, on every build.
; ---------------------------------------------------------------------------

gdead	EQU	$

; Driver initialization.
; Install low-RAM hooks, configure the DOS, size banked RAM,
; test the controller, and select the system volume.
ginit	LD	HL,ghook
	LD	DE,rhook
	LD	BC,ghooke-ghook
	LDIR

	IN	A,(dbank)
	AND	3eh
	OR	41h
	DI
	OUT	(dbank),A

; The two GETSYS stubs are copied here, after the bank switch and not with
; ghook above it: their home moved from low RAM into SYS0's own resident
; block (see rsysfcb), and 44xx is DOS RAM, which is only writable with the
; banker at 41h. Costs nothing -- the switch had to happen anyway for gcfg.
	LD	HL,gsysfcb
	LD	DE,rsysfcb
	LD	BC,gsysfcbe-gsysfcb
	LDIR

	LD	HL,gdecfix
	LD	DE,rdecfix
	LD	BC,gdecfixe-gdecfix
	LDIR

	LD	HL,gcfg
	LD	DE,4200h
	LD	BC,0100h
	LDIR

	LD	A,sysvol
	LD	(dfcbdv2),A

	LD	A,0c3h
	LD	(ddrvsl),A
	LD	HL,rhook
	LD	(ddrvsl+1),HL
	LD	A,0c3h
	LD	(dxfer),A
	LD	HL,rhook+1dh
	LD	(dxfer+1),HL

	LD	A,(ddrive)
	LD	(dsave),A
	LD	A,6
	LD	(ddrvnr),A

	LD	HL,4000h
	LD	BC,0200h
	IN	A,(dbank)
	AND	3eh
	OR	0c1h
	DI
	OUT	(dbank),A
gini1	LD	A,(HL)
	LD	E,A
	CPL
	LD	(HL),A
	CP	(HL)
	LD	(HL),E
	JR	Z,gini2
	SCF
gini2	RL	C
	IN	A,(dbank)
	AND	3eh
	OR	81h
	DI
	OUT	(dbank),A
	DJNZ	gini1
	LD	A,C
	RLCA
	RLCA
	OR	3
	LD	C,A
	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
	LD	A,C
	LD	(dbanks),A
	LD	HL,0f700h
	LD	(dbankt),HL

	LD	HL,dtab
	LD	A,0ah
gini3	DEC	A
	LD	(HL),A
	DEC	HL
	JR	NZ,gini3

	CALL	hdsel
	JR	Z,gini4
	LD	HL,grej8
	LD	(0f018h),HL
	JR	gini5
gini4	CALL	hdrel
	LD	HL,dtab-2
	LD	DE,dtab
	LD	BC,0008h
	LDDR
	LD	HL,0605h
	LD	(dtabh),HL
	IN	A,(dbank)
	AND	3eh
	OR	41h
	DI
	OUT	(dbank),A
	LD	A,sysvol
	LD	H,gpar/256
	LD	L,A
	LD	A,(HL)
	AND	0fh
	CALL	gvol

gini5	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
	JP	dinit

; Configuration sector copied to 4200h for SYS0/SYS.
; Ten 16-byte PDRIVE entries are followed by system parameters.
; It sits here, second half of the dead block, deliberately: this is what
; covers the tail of MEMDISK's F400h-F567h write range. Being overwritten
; there is harmless -- ginit copies these 256 bytes to 4200h before SYS0
; runs and nothing reads them again.
gcfg
	DEFB	030h,060h,0d4h,050h,024h,006h,080h,043h
	DEFB	030h,006h,000h,000h,000h,090h,004h,006h
	DEFB	030h,060h,0d4h,050h,024h,006h,080h,043h
	DEFB	030h,006h,000h,000h,000h,090h,004h,006h
	DEFB	030h,060h,0d4h,050h,024h,006h,080h,043h
	DEFB	030h,006h,000h,000h,000h,090h,004h,006h
	DEFB	014h,028h,014h,028h,00ah,002h,080h,000h
	DEFB	014h,002h,000h,000h,000h,010h,000h,000h
	DEFB	014h,028h,014h,028h,00ah,002h,080h,000h
	DEFB	014h,002h,000h,000h,000h,010h,000h,000h
	DEFB	030h,060h,0d4h,050h,024h,006h,080h,043h
	DEFB	030h,006h,000h,000h,000h,010h,000h,000h
	DEFB	001h,07bh,004h,0a3h,0c0h,008h,000h,000h
	DEFB	001h,001h,000h,000h,000h,090h,004h,004h
	DEFB	011h,0a0h,016h,050h,014h,002h,080h,040h
	DEFB	011h,002h,000h,000h,002h,010h,000h,002h
	DEFB	001h,064h,014h,032h,00ah,001h,080h,000h
	DEFB	001h,002h,000h,000h,000h,010h,000h,000h
	DEFB	011h,032h,0d4h,04dh,01ah,008h,0c0h,083h
	DEFB	011h,002h,000h,000h,000h,090h,004h,005h

; System-parameter tail starts here (byte 0 = 42A0h/dnflop when copied).
; That first byte is 004h, matching bootsec.asm's reference copy of this
; same sector, captured by breakpoint from a working floppy boot of this
; same GDOS. Keep the two in step: they are the same data.
	DEFB	004h,002h,005h,005h,000h,000h,001h,01eh
	DEFB	0ffh,002h,000h,000h,000h,000h,000h,000h
	DEFB	000h,000h,000h,000h,000h,000h,000h,000h
	DEFB	000h,000h,000h,000h,000h,000h,000h,000h
	DEFB	002h,011h,01fh,00ch,020h,002h,002h,011h
	DEFB	01fh,000h,000h,000h,000h,000h,000h,000h
	DEFB	000h,000h,01fh,001h,040h,008h,000h,004h
	DEFB	001h,040h,008h,000h,000h,000h,000h,000h
	DEFB	00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0a5h
	DEFB	032h,0f0h,081h,000h,000h,000h,000h,000h
	DEFB	07fh,00ch,000h,000h,000h,000h,000h,000h

gdeade	EQU	$

; ---------------------------------------------------------------------------
; Low-RAM templates, past MEMDISK's write range.
;
; These four blocks are copied into low RAM rather than executed here: ghook,
; gsysfcb and gdecfix once by ginit, gstub by gcopy before every transfer.
; gstub therefore has to stay readable for the life of the driver, so all
; four sit above F567h, on the far side of the dead block. They are pure
; position-independent data from this file's point of view, which is what
; lets them be placed by size rather than by sequence.
; ---------------------------------------------------------------------------

; Low-RAM transfer stub.
; The burst opcode and second-page I/O opcode are patched before use.
gstub	IN	A,(dbank)
	AND	3eh
	OR	40h
	OUT	(dbank),A
gsop	DEFW	0
	XOR	A
	LD	B,0
gsync	DEFB	11h		;LD DE,nnnn -- patched to 0000h (no-op) or 0ff00h (undo)
gsyncv	DEFW	0000h
	ADD	HL,DE
gsec	DEFW	0
gsecl	DJNZ	gsec
gskip	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
	RET
gstube	EQU	$

;	hdpags=1 patches gsec (above) to this instead of the drain/pad
;	opcode: JR gskip, jumping past the second-page loop entirely. The
;	displacement is position-independent, so the same encoding is
;	correct whether assembled here or copied to rstub at 3A00h.
gskipop	EQU	((gskip-gsec-2)*100h)+18h

; DOS hooks copied to low RAM at 3700h.
ghook	EX	AF,AF'
	PUSH	AF
	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
	JP	gdrvsl
	IN	A,(dbank)
	AND	3eh
	OR	40h
	OUT	(dbank),A
	EI
	POP	AF
	EX	AF,AF'
	JP	C,ddrvfl	;carry = gflop's own CP 2 borrow -- see gexit0
	JP	ddrver

	EX	AF,AF'
	PUSH	AF
	IN	A,(dbank)
	AND	3eh
	DI
	OUT	(dbank),A
	JP	gxfhk
	IN	A,(dbank)
	AND	3eh
	OR	40h
	OUT	(dbank),A
	EI
	POP	AF
	EX	AF,AF'
	JP	C,dxferf	;carry = gexit0's SCF -- see gexit0
	RET
ghooke	EQU	$

; GETSYS replacement: use the configured system drive instead of 0.
; Stock (XOR A / LD (dfcbdv),A / CALL 4776h) doubled that XOR A as both
; DRVSEL's drive-0 argument and the shared FCB's own NEXT-field reset
; (dfcbdv, 43D8h, is FCB+0Ah -- Grosser ch.3: the low word of NEXT, not a
; drive field) -- harmless on stock since drive 0 and NEXT=0 are the same
; value. Naively substituting sysvol for that XOR A carried sysvol into
; NEXT too, so FILPOS computed a target GRAN one past every file's real
; start and never found it in the FCB's own (correctly seeded) block list,
; falling through to GETFDE's directory search -- which finds the FDE but,
; like every system file's FDE, it carries no block data of its own before
; the FCB seeds it. That is what surfaces as SYS4/SYS's load failure at
; GETSYS's third module request. Fixed by keeping the two purposes
; separate: zero dfcbdv for NEXT, then load sysvol only into A for DRVSEL.
gsysfcb	XOR	A
	LD	(dfcbdv),A
	LD	A,sysvol
	JP	ddrvsel
gsysfcbe EQU	$

; GETSYS replacement: preserve the current module DEC in the FCB.
gdecfix	LD	(dfcbdec),A
	CALL	dgetfde
	RET
gdecfixe EQU	$

; ---------------------------------------------------------------------------
; Layout assertions. Each one assembles to nothing when it holds and to an
; undefined symbol -- naming the constraint it broke -- when it does not, so
; a layout mistake is a build failure rather than a boot failure.
;
; A wrong address here is exactly the class of bug that hides: the driver
; assembles, boots, and only misbehaves once MEMDISK runs or once GDOS calls
; a dispatch slot that has quietly moved.
; ---------------------------------------------------------------------------
gend	EQU	$

; The DOS-facing layout, which follows the Xebec driver it replaces and is
; addressed by GDOS from fixed addresses, not through anything we hand it.
	IF	gwork != 0f00dh
	DEFB	LAYOUT_ERROR_gwork_must_stay_at_F00Dh
	ENDIF
	IF	gstk != 0f040h
	DEFB	LAYOUT_ERROR_gstk_must_stay_at_F040h
	ENDIF
	IF	gdrvsl != 0f05dh
	DEFB	LAYOUT_ERROR_gdrvsl_must_stay_at_F05Dh
	ENDIF

; MEMDISK/CMD's write range, F400h-F567h, must fall entirely inside the
; dead-after-boot block -- checked from both ends, since covering only one is
; how a live routine creeps back into it.
	IF	gdead > 0f400h
	DEFB	LAYOUT_ERROR_live_code_reaches_into_MEMDISKs_F400h_write_range
	ENDIF
	IF	gdeade < 0f568h
	DEFB	LAYOUT_ERROR_dead_block_ends_before_MEMDISKs_F567h
	ENDIF

; ginit points dbankt (36FDh) at F700h, so the driver has to end below it.
; The old layout ran to F7A2h and only got away with it because the bytes up
; there were gcfg's, dead before anything could use them.
	IF	gend > 0f700h
	DEFB	LAYOUT_ERROR_driver_runs_past_F700h_the_dbankt_buffer
	ENDIF

; The two GETSYS stubs are copied into 448Ch-449Fh, 20 bytes of FFh in
; SYS0/SYS's resident block. They have to be laid end to end and to fit.
	IF	rdecfix != rsysfcb + (gsysfcbe - gsysfcb)
	DEFB	LAYOUT_ERROR_rdecfix_does_not_follow_rsysfcb
	ENDIF
	IF	rdecfix + (gdecfixe - gdecfix) - 1 > rfree
	DEFB	LAYOUT_ERROR_GETSYS_stubs_overrun_the_FFh_run_at_449Fh
	ENDIF
