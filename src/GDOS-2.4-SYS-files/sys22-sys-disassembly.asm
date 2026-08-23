;************************************************************************
;
;	SYS22/SYS, stock GDOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
;************************************************************************
;
; Format follows SYS8-sys-disassembly.asm -- see sys7-sys-disassembly.asm's
; header for what that means and the same real-toolchain regeneration
; command used here (trsload.py --extract 4D00-51CD -- this file's EOF is
; 4/206, one record short of the usual 51E7h -- then one z80dasm pass).
;
; Not in Grosser -- like SYS26/SYS, his ch.7 table stops at SYS21 (stock
; NEWDOS/80's own range); SYS22-29 are GDOS/Genie extensions outside his
; book's scope. Request-code dispatch read off this disassembly:
;
;   38h -> m4fc7
;   78h -> m4df4
;   98h, sub-C=1/2/3 -> m4d30 / m4d34 / m4d38
;   F8h, sub-C=1/2    -> m4d75 / m4dda
;   m4d38 additionally branches on the next input character ('V'/'H'/'X'/
;   'S') -- not yet named against any DOS command.
;
; Not annotated beyond the dispatch table above -- this module's actual
; function (which DOS command(s) it implements) has not been identified.
;
; [note]   read off the disassembly, not from any prior reference.

m0000	EQU	0000h
m000f	EQU	000fh
m0010	EQU	0010h
m0011	EQU	0011h
m0021	EQU	0021h
m0033	EQU	0033h
m0062	EQU	0062h
m00f5	EQU	00f5h
m00f9	EQU	00f9h
m0100	EQU	0100h
m0911	EQU	0911h
m112a	EQU	112ah
m1900	EQU	1900h
m20a0	EQU	20a0h
m2100	EQU	2100h
m2101	EQU	2101h
m2113	EQU	2113h
m2162	EQU	2162h
m22f9	EQU	22f9h
m2931	EQU	2931h
m29f1	EQU	29f1h
m2ffb	EQU	2ffbh
m37f9	EQU	37f9h
m3c00	EQU	3c00h
m4023	EQU	4023h
m4024	EQU	4024h
m402d	EQU	402dh
m4080	EQU	4080h
m4100	EQU	4100h
m4121	EQU	4121h
m4200	EQU	4200h
m42ff	EQU	42ffh
m4307	EQU	4307h
m4317	EQU	4317h
m4369	EQU	4369h
m4409	EQU	4409h		;DOS ERROR EXIT
m4436	EQU	4436h
m4480	EQU	4480h
m4482	EQU	4482h
m4483	EQU	4483h
m4488	EQU	4488h
m448c	EQU	448ch
m4cd5	EQU	4cd5h		;shared end-of-parameter/delimiter scanner (see sys17-sys-disassembly.asm)
m51ce	EQU	51ceh
m7909	EQU	7909h
m8080	EQU	8080h
m8341	EQU	8341h
m8400	EQU	8400h
mc911	EQU	0c911h
	ORG	4D00H
	CP	38H		;[note] module code 38h & 1Fh = 18h -> SYS-number 24-2 = 22, confirming this file.
	JP	Z,m4fc7
	CP	78H
	JP	Z,m4df4
	CP	98H
	JR	NZ,m4d1a
	DEC	C
	JP	Z,m4d30
	DEC	C
	JP	Z,m4d34
	DEC	C
	JP	Z,m4d38
m4d1a	CP	0F8H
	JR	NZ,m4d26
	DEC	C
	JP	Z,m4d75
	DEC	C
	JP	Z,m4dda
m4d26	LD	A,2AH
m4d28	EI
	JP	m4409
m4d2c	LD	A,2FH
	JR	m4d28
m4d30	LD	C,10H
	JR	m4d60
m4d34	LD	C,13H
	JR	m4d60
m4d38	CALL	m4cd5
	LD	A,(HL)
	CP	56H
	LD	C,12H
	JR	Z,m4d60
	CP	48H
	JR	Z,m4d30
	CP	58H
	JR	Z,m4d34
	CP	53H
	JR	Z,m4d51
	LD	A,3CH
	RST	28H
m4d51	LD	A,11H
	CALL	m0033
	LD	A,4H
	LD	(m4023),A
	LD	(m4024),A
	LD	C,0H
m4d60	LD	A,C
	LD	HL,m4369
	RES	6,(HL)
	CALL	m0033
	LD	A,1CH
	CALL	m0033
	LD	A,1FH
m4d70	CALL	m0033
	XOR	A
	RET
m4d75	LD	A,(HL)
	CP	0DH
	JR	NZ,m4d86
	LD	A,(m2ffb)
	BIT	0,A
	CALL	Z,m502e
	LD	A,16H
	JR	m4d70
m4d86	LD	A,(HL)
	CP	58H
	JP	Z,m4fc7
	CP	47H
	JP	Z,m4fc7
	CP	59H
	JR	Z,m4d96
	DEC	HL
m4d96	CALL	m4da5
	JP	m502e
m4d9c	CALL	m4cd5
	CALL	m4cd5
	RET	Z
	JR	m4d86
m4da5	INC	HL
	CALL	m4cd5
	CALL	m4cd5
	LD	A,(HL)
	LD	HL,m2ffb
	RET	Z
	CP	52H
	JR	NZ,m4db9
	LD	(HL),1H
	JR	m4dd8
m4db9	CP	41H
	JR	NZ,m4dc1
	LD	(HL),3H
	JR	m4dd8
m4dc1	CP	42H
	JR	NZ,m4dc9
	LD	(HL),5H
	JR	m4dd8
m4dc9	CP	43H
	JR	Z,m4dd6
	CP	49H
	JR	Z,m4dd6
	CP	4BH
	JP	NZ,m4d2c
m4dd6	LD	(HL),7H
m4dd8	OR	A
	RET
m4dda	POP	AF
	POP	HL
	LD	A,0FFH
	LD	(m4317),A
	LD	(4DECH),SP
	LD	SP,m51ce
	CALL	m4df4
	LD	SP,m0000
	JP	Z,402DH
	JP	m4d28
m4df4	LD	A,(m4307)
	LD	B,A
	AND	0EH
	CP	4H
	JR	NZ,m4d9c
	PUSH	IX
	CP	B
	JR	Z,m4e13
	LD	A,0C9H
	LD	(m50ed),A
	LD	(m50e5),A
	LD	(m5037),A
	LD	A,20H
	LD	(m4edd),A
m4e13	CALL	m4cd5
	CALL	m4cd5
	LD	A,(HL)
	LD	(4E61H),A
	JR	Z,m4e3c
	CP	58H
	JR	Z,m4e3c
	CP	47H
	JR	Z,m4e3c
	CP	48H
	JR	Z,m4e3c
	CP	59H
	JR	Z,m4e35
	DEC	HL
	LD	A,59H
	LD	(4E61H),A
m4e35	CALL	m4da5
	JR	NZ,m4e3c
	LD	(HL),1H
m4e3c	LD	B,0H
	LD	HL,m4200
	LD	(m4483),HL
	LD	A,(m448c)
	LD	H,A
	LD	A,(m4488)
	SRL	H
	RRA
	SRL	H
	RRA
	SRL	H
	RRA
	SRL	H
	RRA
	LD	B,A
	DEC	A
	LD	HL,m2ffb
	CP	80H
	JR	C,m4e6e
	LD	A,0H
	CP	59H
	JR	Z,m4e6c
	LD	(HL),1H
	CP	48H
	JR	NZ,m4e6e
m4e6c	LD	B,80H
m4e6e	LD	A,B
	LD	(4F00H),A
	LD	DE,m42ff
	LD	A,(m3c00)
	LD	(4EACH),A
	LD	A,(m37f9)
	CP	9H
	JR	NC,m4e8c
	LD	A,13H
	LD	(m4ed5),A
	LD	A,1BH
	LD	(m4ef8),A
m4e8c	LD	A,(4E61H)
	CP	48H
	LD	A,0H
	JR	NZ,m4e99
	LD	A,80H
	LD	(HL),1H
m4e99	LD	(m3c00),A
	LD	HL,m8400
	LD	B,10H
m4ea1	INC	E
	JR	NZ,m4ed5
	LD	A,(m3c00)
	LD	(4ED1H),A
	EX	AF,AF'
	LD	A,0H
	LD	(m3c00),A
	IN	A,(m00f9)
	RES	1,A
	OUT	(m00f9),A
	EI
	PUSH	DE
	LD	DE,m4480
	CALL	m4436
	POP	DE
	JR	Z,m4ec5
	PUSH	AF
	JP	m4f16
m4ec5	EX	AF,AF'
	CALL	m50ed
	DI
	IN	A,(m00f9)
	SET	1,A
	OUT	(m00f9),A
	LD	A,0H
	LD	(m3c00),A
m4ed5	NOP
	LD	A,(DE)
	LD	(HL),A
	LD	A,(4E61H)
	CP	59H
m4edd	JR	m4ef8
	LD	A,(m3c00)
	OR	80H
	LD	(m3c00),A
	LD	A,(DE)
	LD	IX,m4eef
	JP	m4f62
m4eef	LD	(HL),A
	LD	A,(m3c00)
	RES	7,A
	LD	(m3c00),A
m4ef8	NOP
	LD	A,8H
	ADD	A,H
	LD	H,A
	DJNZ	m4ea1
	LD	A,0H
	DEC	A
	JR	Z,m4f0d
	LD	(4F00H),A
	LD	A,(m3c00)
	INC	A
	JR	m4e99
m4f0d	XOR	A
	PUSH	AF
	IN	A,(m00f9)
	RES	1,A
	OUT	(m00f9),A
	EI
m4f16	LD	A,(4EACH)
	LD	(m3c00),A
	LD	A,(4E61H)
	PUSH	AF
	CP	58H
	JR	Z,m4f26
	CP	47H
m4f26	CALL	Z,m4fcf
	POP	AF
	CP	59H
	CALL	Z,m5037
	POP	AF
	POP	IX
	RET
m4f33	LD	HL,m3c00
	LD	A,(HL)
	LD	(4EACH),A
	LD	A,C
	CALL	m50e5
	DI
	LD	(HL),C
	LD	HL,m8400
	LD	B,10H
	IN	A,(m00f9)
	OR	2H
	OUT	(m00f9),A
m4f4b	LD	A,(DE)
	INC	DE
	LD	(HL),A
	LD	A,8H
	ADD	A,H
	LD	H,A
	DJNZ	m4f4b
	IN	A,(m00f9)
	RES	1,A
	OUT	(m00f9),A
	LD	A,(4EACH)
	LD	(m3c00),A
	EI
	RET
m4f62	LD	(m4faa+1),A
	LD	A,(m2ffb)
m4f68	CP	1H
	JR	Z,m4f7d
	CP	3H
	JR	Z,m4f91
	CP	5H
	JR	Z,m4f83
	CP	7H
	JR	Z,m4faf
m4f78	LD	A,(m4faa+1)
m4f7b	JP	(IX)
m4f7d	LD	A,(m4faa+1)
	CPL
	JR	m4f7b
m4f83	LD	A,(m4faa+1)
	LD	(m4faa+1),BC
	LD	C,A
	AND	0FEH
	RRCA
	OR	C
	JR	m4faa
m4f91	LD	A,(m4faa+1)
	OR	A
	JR	Z,m4f7b
	LD	(m4faa+1),BC
	LD	B,0H
m4f9d	INC	B
	RRA
	JR	NC,m4f9d
	RLA
	DEC	B
	JR	Z,m4faa
	SET	7,A
m4fa7	RLCA
	DJNZ	m4fa7
m4faa	LD	BC,m0000
	JR	m4f7b
m4faf	LD	A,E
	AND	0FH
	CP	4H
	JR	C,m4fc0
	CP	7H
	JR	C,m4f78
	LD	A,(m4faa+1)
	RRA
	JR	m4f7b
m4fc0	CCF
	LD	A,(m4faa+1)
	RLA
	JR	m4f7b
m4fc7	CALL	m4fcf
	LD	A,15H
	JP	m4d70
m4fcf	LD	BC,m4080
	LD	HL,m2ffb
	RES	0,(HL)
	LD	A,(m4307)
	AND	0FH
	CP	2H
	JR	NZ,m4fe4
	XOR	A
	OUT	(m00f5),A
	RET
m4fe4	CP	5H
	JR	Z,m4fea
	LD	B,80H
m4fea	RES	0,A
	CP	4H
	RET	NZ
m4fef	LD	HL,m4480
	PUSH	HL
	PUSH	BC
	LD	B,3H
m4ff6	LD	D,2H
	XOR	A
m4ff9	RRCA
	RRCA
	RRCA
	RRCA
	RR	C
	JR	NC,m5003
	OR	0F0H
m5003	DEC	D
	JR	NZ,m4ff9
	LD	D,A
	LD	E,10H
	DEC	B
	JR	Z,m501b
	LD	A,(m37f9)
	LD	E,5H
	CP	0DH
	JR	NC,m501b
	DEC	E
	CP	0AH
	JR	NC,m501b
	DEC	E
m501b	INC	B
m501c	LD	(HL),D
	INC	HL
	DEC	E
	JR	NZ,m501c
	DJNZ	m4ff6
	POP	BC
	POP	DE
	PUSH	BC
	CALL	m4f33
	POP	BC
	INC	C
	DJNZ	m4fef
	RET
m502e	PUSH	IX
	CALL	m5037
	POP	IX
	XOR	A
	RET
m5037	LD	HL,m2ffb
	SET	0,(HL)
	LD	A,(m4307)
	AND	0FH
	CP	2H
	JR	NZ,m5049
	DEC	A
	OUT	(m00f5),A
	RET
m5049	CP	4H
	JR	Z,m5097
	CP	5H
	RET	NZ
	LD	A,(HL)
	CP	1H
	JR	Z,m5059
	XOR	A
	LD	(5068H),A
m5059	LD	BC,m20a0
	LD	HL,m510f
m505f	PUSH	BC
	PUSH	HL
	LD	HL,m4480
	LD	E,L
	LD	D,H
	INC	DE
	LD	(HL),0FFH
	LD	BC,m000f
	LDIR
	POP	HL
	LD	DE,m4482
m5072	LD	A,(HL)
	LD	C,A
	INC	HL
	OR	A
	JR	Z,m508d
	AND	7H
	LD	B,A
m507b	LD	A,C
	AND	0F8H
	RRCA
	RRCA
	LD	IX,m5087
	JP	m4f62
m5087	LD	(DE),A
	INC	DE
	DJNZ	m507b
	JR	m5072
m508d	POP	BC
	PUSH	HL
	CALL	m50d3
	POP	HL
	DJNZ	m505f
	XOR	A
	RET
m5097	LD	BC,m8080
	EXX
	LD	HL,m0100
	EXX
	LD	A,(m2ffb)
	LD	(50B7H),A
m50a5	EXX
	LD	DE,m4480
	LD	B,10H
	IN	A,(m00f9)
	SET	0,A
	DI
	OUT	(m00f9),A
m50b2	LD	A,(HL)
	LD	(m4faa+1),A
	LD	A,0H
	LD	IX,m50bf
	JP	m4f68
m50bf	LD	(DE),A
	INC	DE
	INC	HL
	DJNZ	m50b2
	IN	A,(m00f9)
	RES	0,A
	OUT	(m00f9),A
	EI
	EXX
	CALL	m50d3
	DJNZ	m50a5
	XOR	A
	RET
m50d3	LD	DE,m4480
	LD	A,(m37f9)
	CP	9H
	JR	NC,m50de
	INC	DE
m50de	PUSH	BC
	CALL	m4f33
	POP	BC
	INC	C
	RET
m50e5	PUSH	DE
	EXX
	POP	DE
	LD	BC,m0010
	JR	m50f4
m50ed	EXX
	LD	DE,m4200
	LD	BC,m0100
m50f4	PUSH	HL
	LD	H,0H
	LD	L,A
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	EX	DE,HL
	INC	D
	IN	A,(m00f9)
	SET	0,A
	DI
	OUT	(m00f9),A
	LDIR
	RES	0,A
	OUT	(m00f9),A
	EI
	POP	HL
	EXX
	RET
m510f	NOP
	DEC	H
	LD	BC,m0021
	LD	D,E
	NOP
	LD	D,D
	LD	SP,HL
	LD	D,C
	LD	SP,HL
	LD	D,D
	NOP
	LD	HL,m29f1
	LD	(HL),C
	AND	C
	LD	A,C
	LD	HL,m1900
	SBC	A,C
	LD	B,C
	LD	HL,mc911
	POP	BC
	NOP
	LD	DE,m112a
	XOR	C
	LD	L,C
	SUB	C
	NOP
	LD	H,D
	LD	HL,m0011
	LD	B,C
	LD	HL,m2113
	LD	B,C
	NOP
	LD	HL,m8341
	LD	B,C
	LD	HL,m2100
	XOR	C
	LD	(HL),C
	LD	SP,HL
	LD	(HL),C
	XOR	C
	LD	HL,m0100
	LD	(m22f9),HL
	NOP
	INC	B
	LD	H,D
	LD	HL,m0011
	INC	BC
	LD	SP,HL
	NOP
	DEC	B
	LD	(m0100),A
	ADD	A,C
	LD	B,C
	LD	HL,m0911
	NOP
	LD	(HL),C
	ADC	A,C
	RET
	XOR	C
	SBC	A,C
	ADC	A,C
	LD	(HL),C
	NOP
	LD	HL,m2931
	INC	HL
	LD	SP,HL
	NOP
	LD	(HL),C
	ADC	A,C
	ADD	A,C
	LD	(HL),C
	LD	A,(BC)
	LD	SP,HL
	NOP
	LD	(HL),C
	ADC	A,C
	ADD	A,C
	LD	H,C
	ADD	A,C
	ADC	A,C
	LD	(HL),C
	NOP
	LD	B,C
	LD	H,C
	LD	D,C
	LD	C,C
	LD	SP,HL
	LD	B,D
	NOP
	LD	SP,HL
	ADD	HL,BC
	LD	A,C
	ADD	A,D
	ADC	A,C
	LD	(HL),C
	NOP
	LD	H,C
	LD	DE,m7909
	ADC	A,D
	LD	(HL),C
	NOP
	LD	SP,HL
	ADD	A,D
	LD	B,C
	INC	HL
	NOP
	LD	(HL),C
	ADC	A,D
	LD	(HL),C
	ADC	A,D
	LD	(HL),C
	NOP
	LD	(HL),C
	ADC	A,D
	POP	AF
	ADD	A,D
	LD	(HL),C
	NOP
	LD	(BC),A
	LD	H,D
	LD	BC,m0062
	LD	(BC),A
	LD	H,D
	LD	BC,m2162
	LD	DE,m4100
	LD	HL,m0911
	LD	DE,m4121
	NOP
	LD	(BC),A
	LD	SP,HL
	LD	BC,m00f9
	LD	DE,m4121
	ADD	A,C
	LD	B,C
	LD	HL,m0011
	LD	(HL),C
	ADC	A,C
	ADD	A,C
	LD	B,C
	LD	HL,m2101
	NOP
	END	4D00H
