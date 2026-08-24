;************************************************************************
;
;	OMTI transport, boot-sector half
;
;
; Written and commented by
; E.H. Schroeer
;
; Name: bootrd.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
; The OMTI transport carried in the second half of the hard-disk boot
; sector, relocated to 3B00h before any loading starts.
;
; It sits at 4300h-43FFh in the sector, which SYS0/SYS loads over:
; 4308h-4317h, 4368h-43A8h and 43B2h-43DFh are DOS variables it
; initialises. bootsec.asm jumps to the relocator on first entry and
; calls the copy at 3B00h from then on. 3300h-3FFFh is clear -- SYS0
; loads 0000h-32FBh and 400Ch upward, nothing in between.
;
; Assembled at 3B00h and placed at 4300h in the sector image by
; ./build-bootsec.sh, so every address here is the address it runs at.
;
; Entry: rdsec, the first byte, so bootsec.asm can call 3B00h blind.

omtdat	EQU	40h
omtsta	EQU	41h
omtsel	EQU	42h
omtreq	EQU	01h
omtio	EQU	02h
omtcd	EQU	04h
omtbsy	EQU	08h
cmdrd	EQU	08h
cdblen	EQU	6

; Variables live in free RAM, not in this page. 3400h-3AFFh is untouched
; by the load: bootsec's buffer is 3300h-33FFh, this transport is
; 3B00h-3BFFh, and bootsec's stack grows down from 3AFFh.

half	EQU	3a02h		;0 = front half wanted, 1 = back half wanted
cdb	EQU	3a03h		;the six-byte command descriptor block

secs	EQU	17		;Tandon 10 MB, 612 x 2 x 17, per the Sopp
heds	EQU	2		;EPROM's SET DRIVE CHARACTERISTICS payload

	ORG	3b00h

; 3B03h is the relocator. bootsec jumps to it at 4303h, the stored copy,
; before any relocation has happened. It works from either address: no
; branch of its own, only absolute constants.

	JP	rdsec
reloc	LD	HL,4300h
	LD	DE,3b00h
	LD	BC,00ffh	;255, not 256 -- DE lands on 3bffh itself after
	LDIR			;the copy, one byte short of it; see below
	LD	A,0a5h
	LD	(DE),A		;the relocated-once flag, at 3bffh via the LDIR's
				;own advance -- same byte LDIR would have copied
				;and then this overwrote anyway, 2 bytes cheaper
	JP	4211h		;on into the loader

; Read one 256-byte DOS sector out of a 512-byte OMTI sector.
; In: HL = DOS sector number, DE = buffer. Out: A = 0 on success.
;
; Physical sector = HL/2, which is what chs divides in the 612 x 2 x 17
; space. The remainder picks the half: even HL keeps the front half and
; drains the back, odd HL drains the front and keeps the back.

rdsec	PUSH	DE		;protects DE across divhl/chs only -- chs's own
	LD	C,heds		;use of E (below) would otherwise clobber the
	CALL	divhl		;buffer pointer; select/sendcdb/req don't touch
	LD	(half),A	;D or E at all (verified against their own
	LD	A,cmdrd		;bodies), so one POP DE below covers all three
	LD	(cdb),A		;instead of a separate push/pop around each
	CALL	chs
	LD	A,1
	LD	(cdb+4),A
	XOR	A
	LD	(cdb+5),A
	POP	DE
	CALL	select
	RET	NZ
	CALL	sendcdb
	RET	NZ
	CALL	req
	RET	NZ
	AND	omtio		;controller to host?
	JR	Z,fail
	LD	A,(half)
	OR	A
	LD	C,omtdat
	CALL	NZ,drain	;odd: front half wanted second, discard it now
	EX	DE,HL
	INIR			;B is 0 here, off sendcdb's own count via req's
				;B/C-preserving return, or off drain below
	LD	A,(half)
	OR	A
	CALL	Z,drain		;even: back half wanted first, discard it now
	JP	status
fail	LD	A,0eh
	OR	A
	RET

; The other half of the OMTI sector, read and thrown away. Called before
; the wanted half's INIR (odd) or after it (even). B is 0 on entry
; either way, so it is not reset; the loop still runs 256 times.

drain	IN	A,(C)
	DJNZ	drain
	RET

; divhl doesn't touch D or E (nor does anything else between the two calls
; below), so the sector-within-track remainder rides in E instead of a
; round trip through (cdb+2) and back -- rdsec's own PUSH DE already
; protects the caller's real DE across this whole routine.

chs	LD	C,secs
	CALL	divhl
	LD	E,A
	LD	C,heds
	CALL	divhl
	AND	1fh
	LD	(cdb+1),A
	LD	A,L
	LD	(cdb+3),A
	LD	A,H
	RRCA
	RRCA
	AND	0c0h
	OR	E
	LD	(cdb+2),A

; Cylinder bit 10 -> CDB1 bit 7, the same 11th-bit case omti.asm's own
; hdchs carries (see that file's own comment) and this hand-written copy
; didn't -- a currently-inert gap, since the Tandon's 612 cylinders never
; set it, but ported now that the room for it exists (freed above).
	LD	A,H
	AND	04h		;cylinder bit 10
	RET	Z
	LD	A,(cdb+1)
	OR	80h
	LD	(cdb+1),A
	RET

divhl	XOR	A		;HL / C -> HL, remainder in A
	LD	B,16
divhl1	ADD	HL,HL
	RLA
	CP	C
	JR	C,divhl2
	SUB	C
	INC	L
divhl2	DJNZ	divhl1
	RET

select	LD	B,0
sel1	IN	A,(omtsta)
	AND	omtbsy
	JR	Z,sel2
	DJNZ	sel1
	JR	timeout
sel2	XOR	A
	OUT	(omtsel),A
	LD	B,0
sel3	IN	A,(omtsta)
	AND	omtbsy
	JR	NZ,selok
	DJNZ	sel3
	JR	timeout
selok	XOR	A
	RET

; req already saves/restores BC itself around its own timeout counter (both
; exits -- see its own comment), so cdb1's loop count in B survives a CALL
; req with no extra push/pop needed here.

sendcdb	LD	HL,cdb
	LD	B,cdblen
cdb1	CALL	req
	RET	NZ
	LD	A,(HL)
	OUT	(omtdat),A
	INC	HL
	DJNZ	cdb1
	XOR	A
	RET

req	PUSH	BC		;wait for REQ; A = the phase byte
	LD	BC,0
req1	IN	A,(omtsta)
	AND	omtreq
	JR	NZ,req2
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,req1
	POP	BC
	JR	timeout
req2	IN	A,(omtsta)
	CP	A
	POP	BC
	RET

; The status byte is not the first REQ after the data phase -- the
; controller can still be presenting data requests. Wait for C/D, as
; omti.asm's hdend does.

; Same as sendcdb's cdb1 -- req preserves B on its own, no push/pop needed.

status	LD	B,16
stat1	CALL	req
	RET	NZ
	AND	omtcd
	JR	NZ,stat2
	DJNZ	stat1
	JP	fail
stat2	IN	A,(omtdat)
	AND	2
	RET	Z
	LD	A,0dh
	OR	A
	RET

timeout	LD	A,0fh
	OR	A
	RET

	DEFS	3bffh-$		;the last byte is the relocated-once flag
	DEFB	0
