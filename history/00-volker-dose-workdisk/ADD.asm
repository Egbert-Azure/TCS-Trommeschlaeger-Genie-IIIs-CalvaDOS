;	ADDIEREN VON ZWEI HEXZAHLEN
;
;  mit Hilfe des DOS-Unterprogramms bei 3B68h
;
;    ADD/SRC	= >      H/CMD
;
;
;   die dezimalausgabe ist von zeus abgekuckt und läuft
;   über eine basic-unterprogramm
;
;
mmein	EQU	06abh
mmaus	EQU	06a0h
conver	EQU	3b68h
gibaus	EQU	4467h
dosrdy	EQU	402dh
doserr	EQU	4409h
hexde	EQU	4063h
;
	ORG	4200h
start	LD	A,(HL)		; wenn zunächst ein '@' eingegeben wird
	CP	'@'		; dann soll ein weitere Zahl zu dem
	INC	HL
	JR	Z,wei2		; vorhererrechneten addiert oder subtr.
	DEC	HL		; ist nötig den Zeiger zu verändern.
	CALL	mmaus
	CALL	conver
	CALL	mmein		; das ergebnis ist jetzt in DE
	LD	(ergeb),DE	; abspeichern
wei2	LD	A,(HL)		; kommt jetzt ein '+' ??
	CP	0dh		; enter heißt nur eine Zahl
	JR	Z,einzah
	CP	'-'		; soll subtrahiert werden ?
	JR	NZ,wei1		; falls nicht
	PUSH	HL		; befehlszeiger retten !!
	LD	HL,opera	; operationscodestelle
	LD	(HL),0edh	; opcode für SBC  HL,DE
	INC	HL
	LD	(HL),52h
	POP	HL		; befehlszeiger zurück
	JR	goon
wei1	CP	'+'
	LD	A,2fh
	JP	NZ,doserr	; sonst fehler
goon	CALL	mmaus
	INC	HL
	CALL	conver		; HL zeigt auf zweite zahl
	CALL	mmein
	LD	HL,(ergeb)	; HL = erste Zahl
opera	ADD	HL,DE		; addition
	NOP			; weil SBC ein zweibytebefehl ist
	LD	(ergeb),HL	; und speichern
einzah	LD	HL,(ergeb)
	CALL	dezhl
	LD	HL,hexbuf
	LD	DE,(ergeb)
	CALL	hexde
	LD	HL,hexbuf1
	CALL	gibaus
	JP	dosrdy
hexbuf1	DEFM	'd : '
hexbuf	DEFM	'ffffh ',0dh
ergeb	EQU	4340h
;
;	HL als Integer auf den Bildschirm
;
dezhl	LD	(4121h),HL	;Integer-X-Register
	LD	HL,4130h	;Buffer
	CALL	132fh		;Integer auf Screen
	LD	(HL),03h	;statt 0: enter ans Ende des Ziffernstr.
	LD	HL,4130h
	CALL	gibaus
	RET
	END	start

