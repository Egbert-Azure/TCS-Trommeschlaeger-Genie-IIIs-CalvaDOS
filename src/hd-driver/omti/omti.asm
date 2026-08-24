;************************************************************************
;
;   OMTI 5527 transport layer
;
;
; Written and commented by
; E.H. Schroeer
;
; Name: omti.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
; Stage B (Sopp 1986 OMTI machine, 10 MB). Ports 40h-43h.
; Heads up: INCLUDE, never assembled on its own!!
; -- by gdos-omti.asm for the resident driver and patch.asm standalone.
; Defining omtimin before the INCLUDE drops hddout, hdtst, hdrd and hdwr, which is
; what the resident build does to clear MEMDISK/CMD's F400h-F567h range.
;
; Written to replace the Xebec S1410 transport in GDOS 2.4's resident
; hard-disk driver (SYS0/SYS, F000h-F4EBh). Routine boundaries and flag
; conventions follow that driver so the two are interchangeable:
;
;   this      Xebec   does
;   ----      -----   ------------------------------------------
;   hdrel     F0F6    release / reset the bus
;   hdsel     F1B6    wait for an idle bus, then select
;   hdreq     F255    wait for REQ, return the phase byte
;   hdcmd     F215    push the 6-byte CDB
;   hddin     F14A    burst a sector in       (the INIR side)
;   hddout    F15D    burst a sector out      (the OTIR side)
;   hdend     F22F    wait for the status phase, read completion
;   hdchs     F1ED    build the address bytes of the CDB
;
; Every routine returns Z on success and NZ on failure, with the reason in
; hdlerr -- the Xebec driver's convention, which is why hdreq ends on CP A
; rather than OR A.
;
; Reference code on both sides: the Xebec original as disassembled in
; gdos24-hd-xebec-f000.lst, and the OMTI side in SYS29/SRC's PARK command
; (SYS29.asm of Volker Dose's DMK), which was the only surviving source
; containing useful hints about the HD interface. In short: PARK selects,
; spins on bit 0 of 41h and pushes the CDB to 40h with OUTI; I used the same
; three-step sequence here -- hdsel / hdreq / hdcmd -- with timeouts added.
;
; hddout and hdwr are the write half, and they mirror hddin and hdrd
; literally: same register contract, same phase check with the direction bit
; inverted, OTIR where the read path has INIR. On this controller a write is
; a read with the bus turned around, same as the Xebec driver's F14A and
; F15D are one path differing only in the opcode it pokes into its RAM stub.
;
; The resident driver's business is to decide when to write and when to read;
; this transport layer only performs the controller transaction.
;
; Ports.
OMTDAT	EQU	40h		;data, command and status bytes
OMTSTA	EQU	41h		;read: phase/status  write: controller reset
OMTSEL	EQU	42h		;write: select strobe  read: 0FAh if a card is there
OMTMSK	EQU	43h		;DMA/interrupt mask (unused here)

; Status register -- the SASI phase lines.
;
; 0C0h idle / 0C9h command or data out / 0CBh data in / 0CFh status.
; Bit 2 (C/D) is the one that separates the final status byte from the
; data phase; bit 1 (I/O) gives the direction.

OMTREQ	EQU	01h		;bit 0  REQ	 controller wants a byte
OMTIO	EQU	02h		;bit 1  I/O	 1 = controller to host
OMTCD	EQU	04h		;bit 2  C/D	 1 = command/status
OMTBSY	EQU	08h		;bit 3  BSY	 controller owns the bus
OMTIDL	EQU	0c0h		;idle
OMTCRD	EQU	0fah		;card-present signature read back from 42h

; Commands. SASI 6-byte CDB, the same opcodes as the S1410.
CMDTST	EQU	00h		;test unit ready
CMDREZ	EQU	01h		;rezero
CMDSNS	EQU	03h		;request sense
CMDRD	EQU	08h		;read
CMDWR	EQU	0ah		;write
CMDSEK	EQU	0bh		;seek
CMDCHR	EQU	0ch		;set drive characteristics

CDBLEN	EQU	6
STERR	EQU	02h		;error bit in the completion status byte

; Error codes left in hdlerr.
ERTIME	EQU	0fh		;bus timeout -- the Xebec driver's own 0Fh
ERPHSE	EQU	0eh		;controller in an unexpected phase
ERCMD	EQU	0dh		;command completed with the error bit set


; Release the bus. Any write to the status port resets the controller
; to idle, which is this card's equivalent of the Xebec's F0F6.

hdrel	XOR	A
	OUT	(OMTSTA),A
	RET

; Select the controller.
; Waits for the bus to go idle first, exactly as the Xebec driver does
; at F1B6 -- 256 polls per try, two tries, a forced release in between.
; Out: Z selected, NZ gave up.

hdsel	LD	BC,0002h	;B=0 -> 256 polls, C=2 tries
hdsel1	IN	A,(OMTSTA)
	AND	OMTBSY
	JR	Z,hdsel2	;bus idle -> select
	DJNZ	hdsel1
	CALL	hdrel		;stuck: force it back to idle
	DEC	C
	JR	NZ,hdsel1
	JR	hdserr
hdsel2	LD	C,2		;tries for the selection itself
hdsel3	XOR	A		;LUN 0; the card ignores the strobe value
	OUT	(OMTSEL),A
	LD	B,0
hdsel4	IN	A,(OMTSTA)
	AND	OMTBSY
	JR	NZ,hdsel5	;controller has taken the bus
	DJNZ	hdsel4
	DEC	C
	JR	NZ,hdsel3
hdserr	LD	A,ERTIME
	LD	(hdlerr),A
	OR	A
	RET			;NZ
hdsel5	XOR	A
	LD	(hdlerr),A
	RET			;Z

; Wait for REQ.
; Out: Z and A = the phase byte, or NZ on a timeout. BC, DE, HL kept.
; The nested 512 x 65536 count is the Xebec driver's F255 timeout.

hdreq	PUSH	BC
	PUSH	DE
	LD	DE,(hdtmo)
hdreq1	LD	BC,0000h
hdreq2	IN	A,(OMTSTA)
	AND	OMTREQ
	JR	NZ,hdreq4
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,hdreq2
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,hdreq1
	POP	DE
	POP	BC
	LD	A,ERTIME
	LD	(hdlerr),A
	OR	A
	RET			;NZ
hdreq4	POP	DE
	POP	BC
	IN	A,(OMTSTA)	;hand the caller the whole phase byte
	CP	A		;Z, A preserved
	RET

; Push the 6-byte CDB at (HL), one byte per REQ.
; Out: Z all six taken, NZ timed out. HL advances past the CDB.
;
; No C/D check: on this controller the command phase and a data-out
; phase both read 0C9h, and PARK in SYS29/SRC does not test it either.
; Byte counting is what keeps the two apart, as it did in 1992.

hdcmd	LD	B,CDBLEN
hdcmd1	CALL	hdreq
	RET	NZ
	LD	A,(HL)
	OUT	(OMTDAT),A
	INC	HL
	DJNZ	hdcmd1
	XOR	A
	RET

; hddin/hddout, and the hdtst/hdrd/hdwr callers built on them below, are
; single-command routines exercised only by the standalone hdtest.asm
; and hdwtest.asm tools (each its own CALL). The resident driver never
; calls any of the five -- gxio's own low-RAM stub (gstub, in
; gdos-omti.asm) does the burst itself, self-modified per transfer,
; instead of calling back into this file. Neither name appears anywhere
; in gdos-omti.asm outside of comments, and the assembler's own "never
; used" warnings agree for hdtst/hdrd/hdwr.
; IFNDEF'd out of the resident build (omtimin, set before gdos-omti.asm's
; INCLUDE) to clear the F400h-F567h MEMDISK/CMD collision within the
; driver's fixed 2048-byte allocation -- see gcfg's own comment. Left in
; unconditionally for hdtest.asm/hdwtest.asm, which never set omtimin
; and so still get the whole file, unchanged.
;
; hdperr itself stays outside the IFNDEF below: hddin and hddout both
; jump to it, but so does hdend (its status-phase timeout, further
; down), and hdend is not part of this dead set -- gxio calls it
; directly. Defined once here so it is present either way.

hdperr	LD	A,ERPHSE
	LD	(hdlerr),A
	OR	A
	RET			;NZ

	IFNDEF	omtimin

; Data in: (hdpags) pages of 256 bytes to (HL).
; Out: Z transferred, NZ timed out or wrong phase.
;
; The burst is a plain INIR with no per-byte REQ check, which is what
; the Xebec driver's transfer stub does too. In the resident driver
; this loop is the part that has to be copied to RAM at 3A00h and
; patched with the INIR opcode, because the driver's own bank is
; switched out during the transfer -- see ../README.md. That wrapper is
; the driver's business, not the transport's, so it is not here.

hddin	CALL	hdreq
	RET	NZ
	AND	OMTIO		;controller -> host?
	JR	Z,hdperr
	LD	A,(hdpags)
	LD	D,A
	LD	C,OMTDAT
hddin1	LD	B,0		;256 bytes
	INIR
	DEC	D
	JR	NZ,hddin1
	XOR	A
	RET

; Data out: (hdpags) pages of 256 bytes from (HL).
; Out: Z transferred, NZ timed out or wrong phase.
;
; The mirror of hddin. The phase test is the same instruction with the
; branch inverted: the controller wants I/O clear when it is taking
; bytes from us. That test cannot tell a data-out phase from a command
; phase -- both read 0C9h on this card, which is why hdcmd counts bytes
; instead -- but it is not there for that. It is there to catch the
; controller having gone to status instead, which is what it does when
; it rejects the CDB, and status reads 0CFh with I/O set. So a write to
; a head or LUN the drive does not have fails here rather than pushing
; 512 bytes into a controller that is not listening.
;
; Same bank-switching caveat as hddin: in the resident driver this burst
; is what gets copied to 3A00h, with OTIR poked in where the read path
; pokes INIR -- see ../README.md.

hddout	CALL	hdreq
	RET	NZ
	AND	OMTIO		;host -> controller?
	JR	NZ,hdperr
	LD	A,(hdpags)
	LD	D,A
	LD	C,OMTDAT
hddou1	LD	B,0		;256 bytes
	OTIR
	DEC	D
	JR	NZ,hddou1
	XOR	A
	RET

	ENDIF

; Wait for the status phase and read the completion byte.
; Reading it hands the bus back to the controller's idle state.
; Out: Z command succeeded, NZ otherwise; the byte itself in hdstat.

hdend	LD	B,16
hdend1	PUSH	BC
	CALL	hdreq
	POP	BC
	RET	NZ
	AND	OMTCD		;C/D set -> this is the status byte
	JR	NZ,hdend2
	DJNZ	hdend1
	JR	hdperr
hdend2	IN	A,(OMTDAT)
	LD	(hdstat),A
	AND	STERR
	RET	Z
	LD	A,ERCMD
	LD	(hdlerr),A
	OR	A
	RET			;NZ

; Turn a logical sector number into the CDB's address bytes.
; In:  HL = logical sector, counting from cylinder 0, head 0, sector 0
; Out: hdcdb+1..hdcdb+3 filled; the opcode in hdcdb is left alone.
;
; This is where the Xebec and the OMTI actually differ. The S1410 takes
; a flat block number and GDOS hands it one; the OMTI wants the split:
;
;	  CDB1  bit 7      cylinder bit 10
;		bits 5-6   LUN
;		bits 0-4   head
;	  CDB2  bits 6-7   cylinder bits 8-9
;		bits 0-5   sector
;	  CDB3	           cylinder bits 0-7
;
; Geometry comes from hdsecs/hdheds so it can be set per volume.

hdchs	LD	A,(hdsecs)
	LD	C,A
	CALL	hddiv		;HL = track, A = sector within the track
	LD	(hdcdb+2),A
	LD	A,(hdheds)
	LD	C,A
	CALL	hddiv		;HL = cylinder, A = head
	AND	1fh
	LD	(hdcdb+1),A
	LD	A,L
	LD	(hdcdb+3),A	;cylinder bits 0-7
	LD	A,H
	RRCA
	RRCA			;cylinder bits 8-9 -> 6-7
	AND	0c0h
	LD	B,A
	LD	A,(hdcdb+2)
	OR	B
	LD	(hdcdb+2),A
	LD	A,H
	AND	04h		;cylinder bit 10
	RET	Z
	LD	A,(hdcdb+1)
	OR	80h
	LD	(hdcdb+1),A
	RET

; HL / C -> HL, remainder in A. Shift and subtract, 16 rounds.

hddiv	XOR	A
	LD	B,16
hddiv1	ADD	HL,HL
	RLA
	CP	C
	JR	C,hddiv2
	SUB	C
	INC	L
hddiv2	DJNZ	hddiv1
	RET

; Test unit ready, and the single-sector hdrd/hdwr built on hddin/hddout
; above: standalone-tool-only, same as that pair -- see the comment at
; hdperr. IFNDEF'd out of the resident build for the same reason.
	IFNDEF	omtimin

; Test unit ready. Out: Z ready.

hdtst	LD	A,CMDTST
	CALL	hdclr
	CALL	hdsel
	RET	NZ
	LD	HL,hdcdb
	CALL	hdcmd
	RET	NZ
	JP	hdend

; Read one sector. In: HL = logical sector, DE = buffer. Out: Z read.

hdrd	PUSH	DE
	PUSH	HL
	LD	A,CMDRD
	CALL	hdclr		;destroys HL
	POP	HL
	CALL	hdchs
	LD	A,1
	LD	(hdcdb+4),A	;one block
	CALL	hdsel
	POP	HL		;buffer
	RET	NZ
	PUSH	HL
	LD	HL,hdcdb
	CALL	hdcmd
	POP	HL
	RET	NZ
	CALL	hddin
	RET	NZ
	JP	hdend

; Write one sector. In: HL = logical sector, DE = buffer. Out: Z written.
;
; hdrd with two bytes changed: the opcode, and hddin -> hddout. The
; stack juggling is identical and deliberately so -- note that the
; POP HL after hdsel comes *before* the RET NZ, so a failed selection
; still leaves the stack balanced.

hdwr	PUSH	DE
	PUSH	HL
	LD	A,CMDWR
	CALL	hdclr		;destroys HL
	POP	HL
	CALL	hdchs
	LD	A,1
	LD	(hdcdb+4),A	;one block
	CALL	hdsel
	POP	HL		;buffer
	RET	NZ
	PUSH	HL
	LD	HL,hdcdb
	CALL	hdcmd
	POP	HL
	RET	NZ
	CALL	hddout
	RET	NZ
	JP	hdend

	ENDIF

; Start a fresh CDB: opcode in A, the other five bytes zeroed.

hdclr	LD	(hdcdb),A
	LD	HL,hdcdb+1
	LD	B,CDBLEN-1
hdclr1	LD	(HL),0
	INC	HL
	DJNZ	hdclr1
	RET

; State.
hdcdb	DEFS	CDBLEN		;the command block being sent
hdstat	DEFS	1		;completion status byte from the controller
hdlerr	DEFS	1		;why the last call returned NZ, 0 if it did not

; Outer count of the REQ timeout, 512 x 65536 polls as in the Xebec
; driver's F255. That is minutes of emulated time before a stuck bus
; gives up, so hdtest.asm patches it down to fail fast.

hdtmo	DEFW	0200h

; Volume geometry and transfer size. Tandon 10 MB, 612 x 2 x 17. The OMTI
; runs at 512-byte sectors because the Sopp EPROM's boot-sector read
; (1157h-1168h) takes 512 bytes as two 256-byte INI passes from a single
; READ with block count 1, and hangs in waitreq at 256. G-DOS still sees
; 256-byte sectors; the driver's drain/pad bridges the two.
; See ../abi.md and ./README.md.

hdsecs	DEFB	17		;sectors per track
hdheds	DEFB	2		;heads
hdpags	DEFB	2		;256-byte pages per sector; at a 256-byte OMTI sector one DOS sector IS one OMTI sector
