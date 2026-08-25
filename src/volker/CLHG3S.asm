;	C L H
;	fuer Genie IIIs
;	nach	club info 08+09/86
;	frueher bzw irgendwann wieder im sys4/sys
;	von calvados
;	jetzt erstmal als /cmd - File
	ORG	4200h
start	CALL	4cd5h	;trennzeichen ??
	JR	NZ,clh0
clspar	LD	C,00h
	LD	A,(HL)
	SUB	'0'
	JR	Z,clh0
	DEC	A
	JR	Z,clh1
	LD	A,0afh
	JP	NZ,4409h
clh1	SET	5,C
clh0	IN	A,(0f9h)
	LD	D,A
	OR	C
	OUT	(0f9h),A

	IN	A,(0fah)
	LD	E,A
	EXX
	SET	3,A
	OUT	(0fah),A
	LD	HL,8000h
	LD	DE,8001h
	LD	BC,7fffh
	LD	(HL),L
	LDIR
	EXX
	LD	A,D
	OUT	(0f9h),A
	LD	A,E
	OUT	(0fah),A
	JP	4400h
	END	start
