;************************************************************************
;
; SYS17/SYS, stock GDOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
;************************************************************************
;
; Format follows SYS8-sys-disassembly.asm -- see sys7-sys-disassembly.asm's
; header for what that means and for the same regeneration command
; (trsload.py --extract 4D00-51E7, then one z80dasm pass) used here.
;
; Grosser ch.7, "SYS17" row: request codes 33h ("DB SYSTEM, der Anfang
; steht in SYS7"), 53h (DB WRDIRP), F3h (Genie-only GAT extension for
; COPY 5, documented as living at 501Ch -- not yet located in this
; disassembly). Module code 33h & 1Fh = 13h -> SYS-number 19-2 = 17,
; confirming this file.
;
; [note]   read off the disassembly, not from any prior reference.

m0000	EQU	0000h
m0010	EQU	0010h
m0033	EQU	0033h
m0400	EQU	0400h
m4063	EQU	4063h
m4200	EQU	4200h
m4205	EQU	4205h
m4216	EQU	4216h
m421f	EQU	421fh
m42a0	EQU	42a0h
m42ce	EQU	42ceh
m42d0	EQU	42d0h
m42f0	EQU	42f0h
m430f	EQU	430fh
m436d	EQU	436dh
m4409	EQU	4409h		;DOS ERROR EXIT
m4436	EQU	4436h		;SYS0-resident jump stub -> JP 49FCh (READDV, floppy-path config-sector read)
m443c	EQU	443ch
m491f	EQU	491fh
m4c92	EQU	4c92h
m4c94	EQU	4c94h
m4cb3	EQU	4cb3h
m4cb4	EQU	4cb4h
m4cd5	EQU	4cd5h		;shared end-of-parameter/delimiter scanner
m54cb	EQU	54cbh
m552d	EQU	552dh
m5535	EQU	5535h
m56f9	EQU	56f9h
m5762	EQU	5762h
m5784	EQU	5784h
m5981	EQU	5981h
m5983	EQU	5983h
m598b	EQU	598bh
m5994	EQU	5994h
m59b8	EQU	59b8h
m59bc	EQU	59bch
m59c1	EQU	59c1h
m59c3	EQU	59c3h
m59c6	EQU	59c6h
m59d1	EQU	59d1h
	ORG	4D00H
	CP	53H		;[note] A-53h: DB WRDIRP (Grosser).
	JP	Z,m4f5d
	CP	33H		;[note] A-33h: DB SYSTEM continuation (Grosser, "der Anfang steht in SYS7" -- see sys7-sys-disassembly.asm).
	LD	A,2AH
	RET	NZ
	NOP
	NOP
	LD	A,B		;[note] B here is (4308h)'s value, carried in via SYS7's RST 28h call -- not a raw typed digit. See sys7-sys-disassembly.asm.
	LD	(m4f1c),A
	CALL	m4e21
	CALL	m4436		;[note] SYS0-resident stub -> JP 49FCh (READDV). Reads a sector using whatever drive# is currently in (4308h). The same call site this port patches at SYS0/SYS:50C4h.
	RET	NZ
	CALL	m4cd5		;[note] shared end-of-parameter/delimiter scanner (4cd5h). Its error path, and this file's own local one a few lines below, both return A=034h -- presumably the DOS error code behind "schlechte Parameter".
	RET	C
	JP	Z,m4dc0
m4d1e	LD	A,(HL)
	SUB	41H
	CP	9H
	JR	C,m4d2a
m4d25	LD	A,34H
	JP	m4e81
m4d2a	LD	C,A
	LD	B,19H
m4d2d	ADD	A,C
	DJNZ	m4d2d
	LD	C,A
	INC	HL
	LD	A,(HL)
	SUB	41H
	CP	1AH
	INC	HL
	JR	NC,m4d25
	ADD	A,C
	LD	E,A
	LD	D,0H
	CP	38H
	JR	NC,m4d25
	PUSH	HL
	LD	HL,m4f24
	ADD	HL,DE
	LD	A,(HL)
	CP	0FEH
	LD	B,A
	POP	HL
	JR	NC,m4d25
	LD	A,(HL)
	CP	3DH
	INC	HL
	JR	NZ,m4d7f
	BIT	7,B
	JR	NZ,m4d82
	LD	A,B
	RRCA
	AND	38H
	OR	86H
	LD	(4D74H),A
	ADD	A,40H
	LD	(4D7AH),A
	LD	A,B
	AND	0FH
	LD	E,A
	LD	D,0H
	LD	A,(HL)
	INC	HL
	PUSH	HL
	LD	HL,m42f0
	ADD	HL,DE
	RES	0,(HL)
	CP	4EH
	JR	Z,m4da6
	SET	0,(HL)
	CP	4AH
	JR	Z,m4da6
m4d7f	JP	m4e7f
m4d82	PUSH	BC
	CALL	m4e84
	POP	BC
	LD	A,B
	AND	1FH
	PUSH	HL
	PUSH	DE
	LD	HL,m42a0
	LD	E,A
	LD	D,0H
	ADD	HL,DE
	POP	DE
	BIT	6,B
	JR	Z,m4da1
	LD	A,L
	ADD	A,30H
	LD	L,A
	LD	(HL),E
	INC	HL
	LD	(HL),D
	JR	m4da6
m4da1	LD	(HL),E
	LD	A,D
	OR	A
	JR	NZ,m4d7f
m4da6	POP	HL
	CALL	m4cd5
	RET	C
	JP	NZ,m4d1e
	LD	HL,m42a0
	LD	A,(HL)
	DEC	A
	CP	4H
	JR	C,m4db9
	LD	(HL),1H
m4db9	CALL	m4e21
	CALL	m443c
	RET	NZ
m4dc0	LD	HL,m4f24
	LD	DE,m0000
	LD	B,0DH
	JR	m4e13
m4dca	LD	A,B
	CALL	m4e6b
	PUSH	HL
	PUSH	DE
	PUSH	BC
	EX	DE,HL
	LD	A,1AH
	CALL	m4cb4
	ADD	A,41H
	LD	H,A
	LD	A,L
	ADD	A,41H
	CALL	m4e6b
	LD	A,H
	CALL	m4e6b
	LD	A,3DH
	CALL	m4e6b
	LD	A,(DE)
	LD	B,A
	LD	D,0H
	BIT	7,A
	JR	NZ,m4e2a
	RRCA
	AND	38H
	OR	46H
	LD	(4E04H),A
	LD	A,B
	AND	0FH
	LD	E,A
	LD	HL,m42f0
	ADD	HL,DE
	LD	A,4EH
	BIT	0,(HL)
	JR	Z,m4e09
	LD	A,4AH
m4e09	CALL	m4e6b
m4e0c	POP	BC
	POP	DE
	POP	HL
	LD	B,2CH
m4e11	INC	DE
	INC	HL
m4e13	LD	A,(HL)
	CP	0FEH
	JR	C,m4dca
	JR	Z,m4e11
	LD	A,0DH
	CALL	m4e6b
	XOR	A
	RET
m4e21	LD	A,2H		;[note] an earlier unflattened decode misread this call site as RST 30h; it is not.
	LD	(m4f20),A
	LD	DE,m4f16
	RET
m4e2a	AND	1FH
	LD	E,A
	LD	HL,m42a0
	ADD	HL,DE
	BIT	6,B
	JR	Z,m4e3b
	LD	A,L
	ADD	A,31H
	LD	L,A
	LD	D,(HL)
	DEC	HL
m4e3b	LD	E,(HL)
	PUSH	DE
	CALL	m4ede
	LD	A,2FH
	CALL	m4e6b
	POP	DE
	LD	HL,4F11H
	PUSH	HL
	CALL	m4063
	POP	HL
	LD	B,4H
	LD	A,(HL)
	CP	41H
	DEC	HL
	JR	NC,m4e60
	DEC	B
m4e57	INC	HL
	LD	A,(HL)
	CP	30H
	JR	NZ,m4e60
	DJNZ	m4e57
	INC	HL
m4e60	INC	B
	INC	B
m4e62	LD	A,(HL)
	INC	HL
	CALL	m4e6b
	DJNZ	m4e62
	JR	m4e0c
m4e6b	PUSH	DE
	PUSH	AF
	CALL	m0033
	POP	AF
	POP	DE
	RET
m4e73	CALL	m4e84
	JR	m4e7b
	CALL	m4ea2
m4e7b	LD	A,D
	OR	A
	LD	A,E
	RET	Z
m4e7f	LD	A,2FH
m4e81	JP	m4409
m4e84	PUSH	HL
	CALL	m4ea7
	LD	A,(HL)
	SUB	41H
	CP	8H
	JR	NC,m4e9c
	POP	HL
	LD	B,1H
	PUSH	HL
	CALL	m4ea9
	LD	A,(HL)
	CP	48H
	INC	HL
	JR	NZ,m4e7f
m4e9c	BIT	1,B
	POP	BC
	RET	NZ
	JR	m4e7f
m4ea2	PUSH	HL
	LD	DE,m4e9c
	PUSH	DE
m4ea7	LD	B,0H
m4ea9	LD	DE,m0000
m4eac	LD	A,(HL)
	SUB	30H
	CP	0AH
	JR	C,m4ebd
	BIT	0,B
	RET	Z
	SUB	11H
	CP	6H
	RET	NC
	ADD	A,0AH
m4ebd	PUSH	HL
	LD	H,D
	LD	L,E
	LD	C,A
	XOR	A
	SET	1,B
	ADD	HL,HL
	ADC	A,A
	ADD	HL,HL
	ADC	A,A
	BIT	0,B
	JR	Z,m4ecf
	ADD	HL,HL
	JR	m4ed0
m4ecf	ADD	HL,DE
m4ed0	ADC	A,A
	ADD	HL,HL
	ADC	A,A
	LD	E,C
	LD	D,0H
	ADD	HL,DE
	ADC	A,A
	EX	DE,HL
	POP	HL
	RET	NZ
	INC	HL
	JR	m4eac
m4ede	LD	BC,m0400
	LD	HL,m4f08
m4ee4	PUSH	BC
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	EX	DE,HL
	LD	A,2FH
m4eec	INC	A
	ADD	HL,BC
	JR	C,m4eec
	SBC	HL,BC
	POP	BC
	EX	DE,HL
	CP	30H
	JR	NZ,m4efc
	INC	C
	DEC	C
	JR	Z,m4f00
m4efc	INC	C
	CALL	m4e6b
m4f00	DJNZ	m4ee4
	LD	A,E
	ADD	A,30H
	JP	m4e6b
m4f08	RET	P
	RET	C
	JR	m4f08
	SBC	A,H
	RST	38H
	OR	0FFH
	JR	NC,m4f42
	JR	NC,m4f44
	JR	NC,$+74
m4f16	ADD	A,D
	LD	H,B
	NOP
	NOP
	LD	B,D
	NOP
m4f1c	NOP
	RST	38H
	NOP
	NOP
m4f20	LD	(BC),A
	NOP
	RST	38H
	RST	38H
m4f24	LD	(HL),B
	LD	H,B
	CP	68H
	LD	E,B
	LD	C,B
	LD	D,B
	CP	40H
m4f2d	JR	m4f2d
	ADD	A,B
	ADD	A,(HL)
	ADD	A,D
	ADD	A,E
	RET	NZ
	JR	Z,m4f46
	NOP
	LD	(HL),C
	EX	AF,AF'
	ADD	A,A
	ADD	A,C
	ADC	A,B
	LD	A,C
	LD	L,C
	LD	E,C
	CP	61H
	ADD	HL,SP
m4f42	LD	D,C
	ADD	HL,HL
m4f44	ADD	HL,DE
	ADD	HL,BC
m4f46	ADD	A,L
	ADC	A,C
	LD	B,C
	CP	31H
	LD	A,D
	JR	C,$+75
	LD	(BC),A
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
	RST	38H
m4f5d	LD	A,(m436d)
	BIT	4,A
	LD	A,37H
	JR	Z,m4fc8
	CALL	m4e73
	LD	(m5014),A
	CALL	m4cd5
	RET	NZ
	LD	DE,m500e
	CALL	m4436
	RET	NZ
	LD	HL,m4200
	LD	A,(HL)
	OR	A
	JR	NZ,m4fc6
	INC	HL
	LD	A,(HL)
	CP	0FEH
	JR	NZ,m4fc6
	INC	HL
	CALL	m50c0
	PUSH	HL
	CALL	m4c92
	LD	A,(m430f)
	CALL	m4c94
	POP	DE
	PUSH	HL
	PUSH	DE
	INC	HL
	LD	(m5018),HL
	CALL	m4fcb
	LD	A,(m421f)
	ADD	A,0AH
	LD	H,A
	EX	(SP),HL
	PUSH	HL
	LD	C,0H
	LD	HL,m5003
	CALL	m4fd7
	POP	BC
	LD	HL,m508f
	CALL	m4fd7
	POP	BC
	POP	HL
m4fb5	LD	(m5018),HL
	CALL	m4fcb
	LD	(m5018),HL
	CALL	Z,443CH
	RET	NZ
	INC	HL
	DJNZ	m4fb5
	RET
m4fc6	LD	A,2CH
m4fc8	JP	m4e81
m4fcb	LD	DE,m500e
	CALL	m4436
	RET	Z
	CP	6H
	JR	NZ,m4fc8
	RET
m4fd7	CALL	m4fcb
	LD	A,(m4200)
	AND	50H
	CP	50H
	JR	NZ,m4fc6
	LD	A,(m4216)
	CP	C
	JR	NZ,m4fc6
	LD	DE,m4205
	LD	B,7H
	CALL	m50a4
	LD	HL,500AH
	LD	B,4H
m4ff6	LD	A,(DE)
	CP	(HL)
	INC	DE
	INC	HL
	JR	NZ,m4fc6
	DJNZ	m4ff6
	RET
	JR	NZ,$+34
	JR	NZ,m5023
m5003	LD	B,A
	LD	B,H
	LD	C,A
	LD	D,E
	JR	NZ,$+34
	JR	NZ,$+34
	LD	D,E
	LD	E,C
	LD	D,E
m500e	ADD	A,E
	LD	H,B
	NOP
	NOP
	LD	B,D
	NOP
m5014	NOP
	RST	38H
	NOP
	NOP
m5018	NOP
	NOP
	RST	38H
	RST	38H
	CALL	m5535
	LD	DE,(m59c1)
m5023	CALL	m5784
	LD	BC,(m5994)
	BIT	1,C
	JR	NZ,m508c
	CALL	m56f9
	LD	E,61H
	LD	A,(m59c6)
	CP	E
	JR	C,m5047
	LD	A,(m59b8)
	CP	E
	JR	NC,m5047
	DEC	E
	LD	L,E
m5041	LD	(HL),0FFH
	DEC	E
	INC	HL
	JR	NZ,m5041
m5047	BIT	5,B
	JR	Z,m5051
	LD	HL,(m5981)
	LD	(m42ce),HL
m5051	LD	A,C
	AND	0CH
	LD	BC,m0010
	LD	DE,m42d0
	LD	HL,m5983
	JR	NZ,m5066
	LD	HL,m598b
	LD	E,0D8H
	LD	C,8H
m5066	LDIR
	LD	HL,(m59d1)
	LD	DE,(m59c3)
	OR	A
	SBC	HL,DE
	EX	DE,HL
	JR	C,m5086
	JR	Z,m5086
	LD	HL,(m59c3)
	LD	A,(m59bc)
	CALL	m4cb4
	LD	H,42H
	LD	C,A
	CALL	m5762
m5086	CALL	m491f
	JP	NZ,54CBH
m508c	JP	m552d
m508f	LD	C,C
	LD	C,(HL)
	LD	C,B
	LD	B,C
	LD	C,H
	LD	D,H
	JR	NZ,m50d9
	LD	C,A
	LD	C,A
	LD	D,H
	JR	NZ,m50bc
	JR	NZ,m50e2
	LD	C,C
	LD	D,D
	JR	NZ,$+34
	JR	NZ,m50c4
m50a4	LD	A,(DE)
	CP	42H
	JR	Z,m50b3
	CP	44H
	JP	NZ,m4ff6
	LD	HL,509DH
	JR	m50b6
m50b3	LD	HL,5096H
m50b6	JP	m4ff6
	NOP
	NOP
	NOP
m50bc	NOP
	NOP
	NOP
	NOP
m50c0	LD	L,(HL)
	LD	A,(m4cb3)
m50c4	RET
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
m50d9	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
m50e2	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	END	4D00H
