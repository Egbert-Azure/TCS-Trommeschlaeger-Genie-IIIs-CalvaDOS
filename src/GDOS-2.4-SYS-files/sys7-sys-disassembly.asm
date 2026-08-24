;************************************************************************
;
; SYS7/SYS, stock GDOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys7-sys-disassembly.asm
;
; Date: 2026/08/20
;
;************************************************************************
;
; Format follows SYS8-sys-disassembly.asm: an EQU table for every address
; referenced outside this file's own image, ORG/END, uppercase mnemonics,
; inline "mXXXX  OP  operands" labels, and boxed [note] annotations, sitting
; above the line they describe, for anything read off the disassembly
; rather than taken from Grosser.
;
;   z80dasm -g 0x4d00 -l -a -t sys7_flat.bin
;
; Grosser ch.7, "SYS7" row: request code A-E9h, sub-function selected by C
; (01..0B), decremented in a chain until it hits zero (module code
; E9h & 1Fh = 09h -> SYS-number 9-2 = 7, confirming this file):
;
;   C=01 -> m4d61  "Anfang von DB SYSTEM (Rest in SYS17)"    B=33h (SYS17)
;   C=02 -> m4d76  DB HIMEM
;   C=03 -> m4d65  "Anfang von DB PDRIVE (Rest in SYS16)"    B=32h (SYS16)
;   C=04 -> m4dd4  DB AUTO
;   C=05 -> m4df3  DB ATTRIB
;   C=06 -> m4ec5  DB PROT
;   C=07 -> m50ed  DB DUMP
;   C=08 -> m5142  ? (Grosser: "?", unnamed)
;   C=09 -> m4d69  DB PURGE
;   C=0A / C=0B     DB TIME / DB DATE (not individually traced)

m001b	EQU	001bh
m0050	EQU	0050h
DOSRDY  EQU	402dh		;return to the DOS prompt
m4043	EQU	4043h
HIMEM   EQU	4049h		;HIMEM
HEXDE   EQU	4063h		;write DE as hex ASCII to (HL)
m414e	EQU	414eh
DIRLEN  EQU	421fh		;length of the directory field
m4296	EQU	4296h
m42ce	EQU	42ceh
m42d0	EQU	42d0h
m42d8	EQU	42d8h
DFLAG3  EQU	436ch		;further DOS flags
m4380	EQU	4380h		;fixed base this module reads via IY; (IY-78h)=4308h is DRVSEL's current-drive cell (see sys0-sys-disassembly.asm, "dsave")
m43a9	EQU	43a9h
DOSERR  EQU	4409h		;DOS error exit
m4428	EQU	4428h
WRITE   EQU	4439h		;write a sector
m443f	EQU	443fh
DSPLY   EQU	4467h		;display the text at (HL)
USRFCB  EQU	4480h		;FCB for loading and starting user programs
m4483	EQU	4483h
m448a	EQU	448ah
m44ac	EQU	44ach
m44e2	EQU	44e2h
DRVSEL  EQU	4776h		;select a drive
DSKTST  EQU	47ech		;select the drive, motor on, test 'disk in ?'
DIRSEC  EQU	490ah		;read a sector from the directory
m491f	EQU	491fh
GETFDE  EQU	4936h		;fetch a file's FDE from the directory, second entry
RDFPDE  EQU	494bh		;load the directory sector holding the FPDE (FCB+7) to 4200h, HL to FPDE+0
SYSLD   EQU	49d3h		;load a SYS file; exits on error
m4cb4	EQU	4cb4h
STRCMP  EQU	4cc5h		;compare the strings at (HL) and (BC)
CHKCHR  EQU	4cd5h		;test the character at (HL)
CHKSEP  EQU	4cd9h		;check for a comma or a blank
m51e8	EQU	51e8h
	ORG	4D00H
	LD	IY,m4380
	CP	0E9H
	JR	NZ,m4d32
	DEC	C
	JR	Z,m4d61
	DEC	C
	JP	Z,m4d76
	DEC	C
	JR	Z,m4d65
	DEC	C
	JP	Z,m4dd4
	DEC	C
	JP	Z,m4df3
	DEC	C
	JP	Z,m4ec5
	DEC	C
	JP	Z,m50ed
	DEC	C
	JP	Z,m5142
	DEC	C
	JR	Z,m4d69
	LD	DE,m4043
	LD	B,3AH
	DEC	C
	JR	Z,m4d3a
	DEC	C
m4d32	LD	A,2AH
	JR	NZ,m4d5e
	LD	E,46H
	LD	B,2EH
m4d3a	LD	A,B
	LD	(4DCBH),A
	LD	A,(HL)
	CP	0DH
	JR	NZ,m4da7
	LD	HL,m51e8
	PUSH	HL
	CALL	m44ac
	JR	m4d86
	LD	A,2CH
	JR	m4d5e
m4d50	LD	A,20H
	JR	m4d5e
m4d54	CALL	CHKCHR
	RET	NC
m4d58	LD	A,(HL)
	CP	0DH
	RET	Z
m4d5c	LD	A,34H
m4d5e	JP	DOSERR
; ------------------------------------------------------------
; [note]      4D61h: C=1, "Anfang von DB SYSTEM" (Grosser). B=33h
;             is SYS17's GETSYS module code.
; ------------------------------------------------------------
m4d61	LD	B,33H
	JR	m4d6c
; ------------------------------------------------------------
; [note]      4D65h: C=3, "Anfang von DB PDRIVE" (Grosser). B=32h
;             is SYS16's GETSYS module code.
; ------------------------------------------------------------
m4d65	LD	B,32H
	JR	m4d6c
m4d69	LD	BC,0E506H
; ------------------------------------------------------------
; [note]      4D6Ch: shared SYSTEM/PDRIVE tail -- ends in RST 28h
;             below.
; ------------------------------------------------------------
m4d6c	PUSH	BC
	CALL	m4e89
	POP	BC
	LD	A,B
	LD	B,(IY-78H)
; ------------------------------------------------------------
; [note]      4D75h: RST 28h = GETSYS (Grosser, documented at
;             sys0-sys-disassembly.asm ~1678: entered via RST 28H,
;             A=xxxbbsss module code -- here A=33h -> SYS17).
; ------------------------------------------------------------
	RST	28H
m4d76	LD	A,(HL)
	CP	0DH
	JR	NZ,m4d8c
	LD	DE,(HIMEM)
	LD	HL,m51e8
	PUSH	HL
	CALL	HEXDE
m4d86	LD	(HL),0DH
	POP	HL
	JP	DSPLY
m4d8c	CALL	m4f9e
	CALL	m4d58
	LD	A,D
	CP	70H
	JP	C,m4dd0
	LD	HL,(m43a9)
	OR	A
	SBC	HL,DE
	ADD	HL,DE
	JR	C,m4da2
	EX	DE,HL
m4da2	LD	(HIMEM),HL
	XOR	A
	RET
m4da7	DI
	LD	B,3H
m4daa	LD	A,(HL)
	SUB	30H
	CP	0AH
	INC	HL
	JR	NC,m4dcf
	LD	C,A
	RLCA
	RLCA
	ADD	A,C
	ADD	A,A
	LD	C,A
	LD	A,(HL)
	SUB	30H
	CP	0AH
	INC	HL
	JR	NC,m4dcf
	ADD	A,C
	LD	(DE),A
	DEC	DE
	DJNZ	m4dc9
	NOP
	JP	m51dc
m4dc9	LD	A,(HL)
	CP	0H
	INC	HL
	JR	Z,m4daa
m4dcf	EI
m4dd0	LD	A,2FH
	JR	m4d5e
m4dd4	EX	DE,HL
	XOR	A
	CALL	DRVSEL
	RET	NZ
	XOR	A
	CALL	DIRSEC
	RET	NZ
	LD	B,20H
	LD	L,0E0H
m4de3	LD	A,(DE)
	CP	0DH
	LD	(HL),A
	INC	DE
	INC	HL
	JR	Z,m4df0
	DJNZ	m4de3
	JP	m4dd0
m4df0	JP	m491f
m4df3	POP	AF
	POP	HL
	CALL	m4f6b
	PUSH	DE
	POP	IX
	INC	DE
	LD	A,(DE)
	AND	7H
	LD	A,19H
	RET	NZ
	PUSH	HL
	CALL	RDFPDE
	JP	NZ,m4d5e
	EX	(SP),HL
m4e0a	LD	BC,m504d
	JP	m4f71
	CALL	m4f9e
	DEC	DE
	LD	A,D
	OR	A
	JR	NZ,m4dd0
	EX	(SP),HL
	PUSH	HL
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	INC	E
	LD	(HL),E
	POP	HL
	JR	m4e4a
	LD	C,20H
	LD	DE,0FF00H
	JR	m4e33
	LD	C,80H
	JR	m4e30
	LD	C,40H
m4e30	LD	DE,00FFH
m4e33	LD	A,(HL)
	CP	4AH
	INC	HL
	JR	Z,m4e3e
	LD	D,E
	CP	4EH
	JR	NZ,m4dd0
m4e3e	EX	(SP),HL
	INC	HL
	LD	A,C
	AND	D
	LD	B,A
	LD	A,0FFH
	XOR	C
	AND	(HL)
	OR	B
	LD	(HL),A
	DEC	HL
m4e4a	EX	(SP),HL
	JR	m4e5b
	LD	C,8H
	JR	m4e53
	LD	C,0H
m4e53	LD	B,0F7H
m4e55	POP	DE
	LD	A,(DE)
	AND	B
	OR	C
	LD	(DE),A
	PUSH	DE
m4e5b	CALL	m4d54
	JR	NZ,m4e0a
	POP	AF
	JR	m4df0
	LD	BC,m508c
	LD	D,1H
	CALL	m4f7d
	LD	A,(BC)
	LD	C,A
	LD	B,0F8H
	JR	m4e55
	LD	A,12H
	JR	m4e77
	LD	A,10H
m4e77	PUSH	AF
	CALL	m4ffe
	PUSH	HL
	POP	BC
	POP	AF
	POP	HL
	PUSH	HL
	ADD	A,L
	LD	L,A
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	H,B
	LD	L,C
	JR	m4e5b
; ------------------------------------------------------------
; [note]      4E89h: parses the trailing command-line parameter;
;             called before B is loaded from (4308h) at 4D72h
;             above. Not yet confirmed as the drive-digit-to-DRVSEL
;             path.
; ------------------------------------------------------------
m4e89	CALL	m4ffe
	LD	A,(HL)
	CP	3AH
	INC	HL
	JR	Z,m4e9c
	PUSH	HL
	LD	HL,m4296
	RST	18H
	POP	HL
	DEC	HL
	JP	NZ,m4dd0
m4e9c	PUSH	DE
	CALL	m4f9e
	LD	A,D
	OR	A
	JP	NZ,m4d50
	LD	A,E
	POP	DE
	CALL	DSKTST
	JR	NZ,m4ec2
	PUSH	HL
	XOR	A
	CALL	DIRSEC
	JR	NZ,m4ec2
	LD	HL,(m42ce)
	OR	A
	SBC	HL,DE
	POP	HL
	RET	Z
	LD	A,(DFLAG3)
	RLCA
	RET	NC
	LD	A,37H
m4ec2	JP	m4d5e
m4ec5	CALL	m4e89
	CALL	m4f6b
m4ecb	LD	BC,m50c0
	JP	m4f71
	LD	DE,m42d8
	JR	m4ed9
	LD	DE,m42d0
m4ed9	LD	B,8H
m4edb	CALL	CHKCHR
	JR	NC,m4ee4
	LD	A,(HL)
	INC	HL
	JR	m4ee9
m4ee4	JR	Z,m4ee7
	DEC	HL
m4ee7	LD	A,20H
m4ee9	LD	(DE),A
	INC	DE
	DJNZ	m4edb
	JR	m4f09
	LD	A,4H
	JR	m4ef9
	LD	A,1H
	JR	m4ef9
	LD	A,2H
m4ef9	PUSH	HL
	LD	HL,4F13H
	OR	(HL)
	LD	(HL),A
	POP	HL
	JR	m4f09
	CALL	m4ffe
	LD	(m42ce),DE
m4f09	CALL	m4d54
	JR	NZ,m4ecb
	CALL	m491f
	RET	NZ
	LD	A,0H
	OR	A
	LD	B,A
	RET	Z
	LD	DE,(m42ce)
	RRCA
	JR	NC,m4f21
	LD	DE,m4296
m4f21	LD	A,1H
	CALL	DIRSEC
	RET	NZ
	LD	A,(DIRLEN)
	ADD	A,8H
	LD	(4F66H),A
	XOR	A
m4f30	LD	C,A
	CALL	GETFDE
	RET	NZ
m4f35	LD	A,(HL)
	AND	90H
	CP	10H
	JR	NZ,m4f57
	BIT	2,B
	JR	Z,m4f44
	INC	HL
	RES	5,(HL)
	DEC	HL
m4f44	LD	A,B
	AND	3H
	JR	Z,m4f57
	LD	A,(HL)
	AND	48H
	JR	NZ,m4f57
	SET	4,L
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),D
m4f57	LD	A,L
	AND	0E0H
	ADD	A,20H
	LD	L,A
	JR	NC,m4f35
	CALL	m491f
	RET	NZ
	INC	C
	LD	A,C
	CP	0H
	JR	C,m4f30
	XOR	A
	RET
m4f6b	CALL	CHKSEP
	RET	NC
	JR	m4f90
m4f71	LD	D,2H
	CALL	m4f7d
	LD	A,(BC)
	LD	E,A
	INC	BC
	LD	A,(BC)
	LD	D,A
	PUSH	DE
	RET
m4f7d	CALL	STRCMP
	RET	Z
m4f81	LD	A,(BC)
	CP	0H
	INC	BC
	JR	NZ,m4f81
	LD	E,D
m4f88	INC	BC
	DEC	E
	JR	NZ,m4f88
	LD	A,(BC)
	OR	A
	JR	NZ,m4f7d
m4f90	JP	m4d5c
m4f93	CALL	CHKCHR
	JR	NZ,m4f9c
	RET
m4f99	CALL	CHKSEP
m4f9c	JR	C,m4f90
m4f9e	PUSH	HL
	LD	B,0H
	CALL	m4fbf
	LD	A,(HL)
	SUB	41H
	CP	8H
	JR	NC,m4fb8
	POP	HL
	LD	B,1H
	PUSH	HL
	CALL	m4fbf
	LD	A,(HL)
	CP	48H
	INC	HL
	JR	NZ,m4fbc
m4fb8	BIT	1,B
	POP	BC
	RET	NZ
m4fbc	JP	m4dd0
m4fbf	LD	DE,0000H
m4fc2	LD	A,(HL)
	SUB	30H
	CP	0AH
	JR	C,m4fd3
	BIT	0,B
	RET	Z
	SUB	11H
	CP	6H
	RET	NC
	ADD	A,0AH
m4fd3	PUSH	HL
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
	JR	Z,m4fe5
	ADD	HL,HL
	JR	m4fe6
m4fe5	ADD	HL,DE
m4fe6	ADC	A,A
	ADD	HL,HL
	ADC	A,A
	LD	E,C
	LD	D,0H
	ADD	HL,DE
	ADC	A,A
	EX	DE,HL
	POP	HL
	JR	NZ,m4fbc
	INC	HL
	JR	m4fc2
m4ff5	LD	A,(HL)
	CP	30H
	JR	C,m500f
	CP	3AH
	JR	m5004
m4ffe	LD	DE,m51e7
	LD	B,8H
	OR	A
m5004	JR	C,m5017
	LD	A,(HL)
	CP	41H
	JR	C,m500f
	CP	5BH
	JR	C,m5017
m500f	INC	DE
	LD	A,20H
	LD	(DE),A
	DJNZ	m500f
	JR	m501c
m5017	INC	DE
	LD	(DE),A
	INC	HL
	DJNZ	m4ff5
m501c	PUSH	HL
	EX	DE,HL
	LD	DE,0FFFFH
	LD	B,8H
m5023	PUSH	BC
	LD	A,E
	AND	7H
	LD	C,A
	LD	A,E
	RLCA
	RLCA
	RLCA
	XOR	C
	RLCA
	LD	C,A
	AND	0F0H
	LD	B,A
	LD	A,C
	RLCA
	AND	1FH
	XOR	B
	XOR	D
	LD	E,A
	LD	A,C
	AND	0FH
	LD	B,A
	LD	A,C
	RLCA
	RLCA
	RLCA
	RLCA
	XOR	B
	POP	BC
	XOR	(HL)
	LD	D,A
	LD	(HL),20H
	DEC	HL
	DJNZ	m5023
	POP	HL
	RET
m504d	LD	C,C
	LD	C,(HL)
	LD	D,(HL)
	NOP
	LD	C,L
	LD	C,(HL)
	LD	D,(HL)
	LD	C,C
	LD	D,E
	NOP
	LD	D,C
	LD	C,(HL)
	LD	D,B
	LD	D,D
	LD	C,A
	LD	D,H
	DEC	A
	NOP
	LD	H,E
	LD	C,(HL)
	LD	B,D
	LD	C,E
	LD	D,A
	DEC	A
	NOP
	LD	(HL),C
	LD	C,(HL)
	LD	C,B
	LD	C,E
	LD	D,A
	DEC	A
	NOP
	LD	(HL),L
	LD	C,(HL)
	LD	B,C
	LD	B,H
	LD	B,L
	DEC	A
	NOP
	LD	HL,(m414e)
	LD	B,H
	LD	B,(HL)
	DEC	A
	NOP
	LD	L,4EH
	LD	B,D
	LD	B,L
	LD	B,C
	DEC	A
	NOP
	INC	HL
	LD	C,(HL)
	LD	C,H
	LD	C,A
	LD	B,A
	DEC	A
	NOP
	DJNZ	m50d9
	NOP
m508c	LD	C,E
	LD	B,L
	LD	C,C
	LD	C,(HL)
	NOP
	RLCA
	LD	D,E
	LD	D,H
	LD	B,C
	LD	D,D
	LD	D,H
	NOP
	LD	B,4CH
	LD	B,L
	LD	D,E
	LD	B,L
	LD	C,(HL)
	NOP
	DEC	B
	LD	E,E
	LD	C,(HL)
	LD	B,H
	LD	B,L
	LD	D,D
	LD	C,(HL)
	NOP
	INC	B
	LD	C,L
	LD	D,(HL)
	LD	B,E
	NOP
	LD	(BC),A
	LD	C,(HL)
	LD	B,C
	LD	C,L
	LD	B,L
	NOP
	LD	(BC),A
	LD	C,E
	LD	C,C
	LD	C,H
	LD	C,H
	NOP
	LD	BC,554EH
	LD	C,H
	LD	C,H
	NOP
	NOP
	NOP
m50c0	LD	C,E
	LD	D,A
	DEC	A
	NOP
	LD	(BC),A
	LD	C,A
	LD	B,C
	LD	D,L
	LD	B,(HL)
	NOP
	DI
	LD	C,(HL)
	LD	E,D
	LD	D,L
	NOP
	RST	30H
	LD	C,(HL)
	LD	C,(HL)
	LD	B,C
	LD	C,L
	LD	B,L
	DEC	A
	NOP
	SUB	4EH
m50d9	LD	B,H
	LD	B,C
	LD	D,H
	LD	D,L
	LD	C,L
	DEC	A
	NOP
	POP	DE
	LD	C,(HL)
	LD	B,D
	LD	C,E
	LD	C,H
	NOP
	RST	28H
	LD	C,(HL)
	NOP
	JP	m0050
	NOP
m50ed	LD	HL,m4d61
	LD	(m4483),HL
	POP	AF
	POP	HL
	CALL	m4f99
	PUSH	DE
	CALL	m4f99
	EX	DE,HL
	EX	(SP),HL
	EX	DE,HL
	PUSH	DE
	LD	DE,DOSRDY
	CALL	m4f93
	LD	A,D
	AND	E
	INC	A
	EX	DE,HL
	EX	(SP),HL
	EX	DE,HL
	PUSH	DE
	CALL	NZ,m4f93
	CALL	m4d58
	POP	BC
	POP	AF
	POP	HL
	PUSH	AF
	PUSH	BC
	PUSH	HL
	PUSH	DE
	OR	A
	SBC	HL,BC
	PUSH	HL
	JP	C,m4dd0
	LD	BC,0005H
	ADD	HL,BC
	JR	NC,m512c
	LD	HL,0104H
	JR	m5131
m512c	LD	A,0FCH
	CALL	m4cb4
m5131	LD	(m448a),HL
	LD	DE,USRFCB
	LD	BC,0E908H
	LD	HL,SYSLD
	PUSH	BC
	PUSH	HL
	JP	WRITE
m5142	POP	AF
	CALL	m443f
	JR	NZ,m5198
	EXX
	POP	DE
	POP	HL
	INC	DE
	LD	(51C5H),HL
	POP	HL
	LD	(51B7H),HL
	POP	HL
	LD	(51BEH),HL
	POP	BC
	EX	DE,HL
	LD	A,B
	AND	C
	INC	A
	JR	Z,m519d
	PUSH	BC
	LD	A,H
	OR	L
	JR	NZ,m516b
	LD	BC,00FEH
	OR	A
	SBC	HL,BC
	JR	m5173
m516b	LD	BC,00FEH
	OR	A
	SBC	HL,BC
	JR	C,m5186
m5173	INC	C
	INC	C
	LD	B,1H
	CALL	m51ac
	DEC	C
	DEC	C
m517c	LD	A,(DE)
	INC	DE
	CALL	m51d3
	DEC	C
	JR	NZ,m517c
	JR	m516b
m5186	OR	A
	ADC	HL,BC
	LD	C,L
	LD	L,H
	JR	NZ,m5173
	POP	DE
	LD	B,2H
	LD	C,B
	CALL	m51ac
m5194	EXX
	CALL	m443f
m5198	JR	NZ,m51d9
	JP	m4428
m519d	CALL	m51b4
m51a0	LD	A,(DE)
	INC	DE
	CALL	m51d3
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,m51a0
	JR	m5194
m51ac	LD	A,B
	CALL	m51d3
	LD	A,C
	CALL	m51d3
m51b4	PUSH	HL
	PUSH	DE
	LD	HL,0000H
	RST	18H
	EX	DE,HL
	JR	C,m51cc
	LD	DE,0000H
	RST	18H
	JR	C,m51cc
	PUSH	HL
	LD	HL,0000H
	OR	A
	SBC	HL,DE
	POP	DE
	ADD	HL,DE
m51cc	LD	A,L
	CALL	m51d3
	LD	A,H
	POP	DE
	POP	HL
m51d3	EXX
	CALL	m001b
	EXX
	RET	Z
m51d9	JP	m4d5e
m51dc	LD	A,(m44e2)
	CP	0CDH
	CALL	Z,44E2H
	XOR	A
	EI
	RET
m51e7	NOP
	END	4D00H
