;	Befehlszeilen Editor MS-DOS like
;	nach Ulrich Heidenreich
;	Club-80 Info nr.20 august 87
;	ursprünglich ein SYS-File
;	Hier im Utility-Bereich ab 5200h
	ORG	5200h
outext	EQU	4467h
cmdbuf	EQU	4318h
twocha	EQU	43a7h
delete	LD	A,(HL)
	CP	0dh
	RET	Z

restor	LD	D,H
	LD	E,L
	INC	DE
delop	LD	A,(DE)
	DEC	DE
	LD	(DE),A
	INC	DE
	INC	DE
	CP	0dh
	JR	NZ,delop
	CALL	dispt
	DJNZ	delete
	RET
s22r	LD	A,3eh
	LD	(hxflag),A
	LD	HL,(twocha)
	LD	(cmdbuf),HL

again	LD	HL,cmdbuf
	LD	DE,edibuf
	PUSH	DE
	LD	BC,80
	LDIR
	POP	HL

redo	CALL	outext
	LD	A,0eh
	CALL	outcha
	LD	A,27
	CALL	outcha

edit	LD	DE,edit
	PUSH	DE
	LD	B,0
inloop	CALL	inchar
	SUB	'0'
	JR	C,edcmd
	CP	10
	JR	NC,edcmd
	LD	C,A
	LD	A,B
	RLCA
	RLCA
	ADD	A,B
	RLCA
	ADD	A,C
	LD	B,A
	JR	inloop

edcmd	DEC	B
	INC	B
	JR	NZ,rgz
	INC	B
rgz	ADD	A,'0'
	CP	0dh
	JR	Z,enter
	CP	08h
	JR	Z,bsp
	CP	20h
	JR	Z,space
	CP	09h
	JR	Z,space
	CP	24
	JP	Z,list
	CP	01h
	JP	Z,quit
	RES	5,A
	CP	'D'
	JR	Z,delete
	CP	'R'
	JR	Z,restor
	CP	'Q'
	JR	Z,quit
	CP	'L'
	JR	Z,list
	CP	'S'
	JR	Z,search
	CP	'I'
	JP	Z,insert
	CP	'E'
	JR	Z,exit
	CP	'X'
	JR	Z,xtend
	CP	'K'
	JP	Z,kill
	CP	'H'
	JR	Z,hack
	CP	'A'
	JP	NZ,change
	POP	DE
	JP	again

list	POP	DE
	CALL	outext
	LD	HL,edibuf
	JP	redo
enter	CALL	outext
exit	LD	HL,edibuf
	LD	DE,cmdbuf
	PUSH	DE
	LD	BC,80
	LDIR
	POP	HL
	POP	DE
	JP	4405h
space	LD	A,(HL)
	CP	0dh
	RET	Z
	INC	HL
	CALL	outcha
	DJNZ	space
	RET
bsp	LD	DE,edibuf
bsplop	RST	18h
	RET	Z
	DEC	HL
	LD	A,24
	CALL	outcha
	DJNZ	bsplop
	RET
quit	POP	DE
	JP	4400h
search	CALL	inchar
	LD	E,A
sloop	LD	A,(HL)
	CP	0dh
	RET	Z
	CALL	outcha
	INC	HL
	LD	A,(HL)
	CP	E
	JR	NZ,sloop
	DJNZ	sloop
	RET
xtend	LD	A,(HL)
	CP	0dh
	JR	Z,bspdel
	CALL	outcha
	INC	HL
	JR	xtend
hack	LD	(HL),0dh
	LD	A,30
	CALL	outcha
bspdel	LD	A,36h
	LD	(hxflag),A
	JR	bcont
insert	LD	A,3eh
	LD	(hxflag),A
bcont	CALL	inchar
	CP	0dh
	JR	Z,enter
	CP	1bh
	JR	NZ,noesc
	LD	A,3eh
	LD	(hxflag),A
	RET
noesc	CP	8
	JR	NZ,nobsp
	LD	DE,edibuf
	RST	18h
	JR	Z,bcont
	DEC	HL
hxflag	LD	A,0dh
	LD	A,(hxflag)
	CP	36h
	LD	A,8
	JR	Z,delbsp
	LD	A,24
delbsp	CALL	outcha
	JR	bcont
nobsp	CP	20h
	JR	C,bcont
	LD	B,A
	LD	DE,edibuf+79
inslop	DEC	DE
	LD	A,(DE)
	INC	DE
	LD	(DE),A
	DEC	DE
	RST	18h
	JR	NZ,inslop
	LD	(HL),B
	LD	A,B
	CALL	outcha
	INC	HL
	        CALL	dispt
	JR	bcont
kill	CALL	inchar
	LD	C,A
kiloop	PUSH	BC
	LD	B,1
	CALL	delete
	POP	BC
	LD	A,(HL)
	CP	0dh
	RET	Z
	CP	C
	JR	NZ,kiloop
	DJNZ	kiloop
	RET
change LD	(HL),A
	INC	HL
	CALL	outcha
	DJNZ	change
	RET
dispt	PUSH	HL
	LD	C,0
l1	LD	A,(HL)
	CP	0dh
	JR	Z,e1
	CALL	outcha
	INC	C
	INC	HL
	JR	l1
e1	LD	A,30
	CALL	outcha
	POP	HL
	INC	C
	DEC	C
	RET	Z
	LD	A,24
e2	CALL	outcha
	DEC	C
	JR	NZ,e2
	RET
outcha	EXX
	PUSH	AF
	CALL	033h
	POP	AF
	EXX
	RET

inchar EXX
	CALL	49h
	EXX
	RET
slinks	LD	HL,edibuf
	LD	A,24
	CALL	outcha
	RET
srechts	LD	A,(HL)
	CP	0dh
	RET	Z
	INC	HL
	JR	srechts
edibuf	DEFS	80
	END	s22r
