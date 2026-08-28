;	SETDRIVE
; setzt das gewünschte Laufwerk als Default-Laufwerk.
;
;
;	Syntax :  SET <Lw#><ENTER>
;
;
;
dosrdy	EQU	402dh
gibaus	EQU	4467h
dirlw	EQU	43a0h
openlw	EQU	43a1h
doserr	EQU	4409h
;
	ORG	4320h		;im eingabepuffer ist Platz genug
start	LD	A,(HL)		; zahl holen
	SUB	'0'		; ascii-> binär
	JR	C,noziff	; keine Ziffer
	CP	10		; Ziffer ???
	JR	NC,noziff	; nein !
	LD	(dirlw),A
	LD	(openlw),A	; neues 'Normal' Laufwerk setzen
	ADD	A,'0'		; binär -> ascii
	LD	(lwnum),A	; im Ausgabestring einsetzen
	LD	HL,text
	CALL	gibaus
	JP	dosrdy
noziff	LD	A,32
	OR	A
	JP	doserr
text	DEFM	'Laufwerk '
lwnum	DEFM	'0'
wei	DEFM	' aktiv.',0dh
	END	start
