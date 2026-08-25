; B L I S T
;
; listet Basicprogramme vom Dos aus
; und wandelt die Tokens in Klartext um
;
; Listing aus Club-Info (Bremerhaven) Nr. 10/85
;
;
	ORG	5200h
open	LD	DE,dcb
op1	LD	A,(HL)
	LD {8D},SCF
	INC	DE
	INC	HL
	CP	0dh
	JR	NZ,op1
	DEC	DE
	LD	A,03h
	LD	(DE),A
	LD	DE,dcb
	LD	HL,buffer
	CALL	4424h
	JP	NZ,4409h
	LD	HL,txtbuf
	LD	(40a7h),HL
	RET
read	LD	DE,dcb
	CALL	0013h
	JP	NZ,4409h
	RET
znr	CALL	0a9ah
	XOR	A
	CALL	1034h
	OR	(HL)
	CALL	0fd9h
	PUSH	HL
	XOR	A
loop1	INC	HL
	CP	(HL)
	JR	NZ,loop1
	LD	(HL),' '
	INC	HL
	LD	(HL),03h
	POP	HL
	CALL	4467h
	RET
init	CALL	open
	CALL	read
	CP	0ffh
	JR	NZ,error
next	CALL	read
	LD	B,A
	CALL	read
	OR	B
	JR	Z,endrea
	CALL	read
	LD	L,A
	CALL	read
	LD	H,A
	CALL	znr
	LD	HL,buf
loopbf	CALL	read
	OR	A
	LD	(HL),A
	JR	Z,buffin
	INC	HL
	JR	loopbf
buffin	LD	HL,buf
	CALL	2b7eh
	LD	HL,(40a7h)
	PUSH	HL
	XOR	A
loop2	INC	HL
	CP	(HL)
	JR	NZ,loop2
	LD	(HL),0dh
	POP	HL
	CALL	4467h
	LD	A,(14400)
	CP	64
	CALL	Z,wait
	CP	8
	JR	Z,endrea
	JR	next
wait	LD	A,(14400)
	CP	1
	JR	NZ,wait
	RET
error	LD	HL,text
	JP	4467h
endrea	CALL	4428h
	RET
text	DEFM	'Kein Basic-File !!'
	DW	0707h
	DB	0dh
dcb	DEFS	21
buffer	DEFS	255
buf	DEFS	255
txtbuf	DEFS	255
	END	init
