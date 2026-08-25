;MATH/SRC  Multiplikation und Divison
;Zahlenformat-Umwandlungen
;
;MULTHL multipliziert HL * A
;Ergebnis in AHL
;
multhl	PUSH	BC
	PUSH	DE
	EX	DE,HL
	LD	C,80H
	LD	HL,0
cc0	RRCA
	JR	C,cc1
	ADD	HL,DE
cc1	SRL	H
	RR	L
	RR	C
	JR	NC,cc0
	LD	A,H
	LD	H,L
	LD	L,C
	POP	DE
	POP	BC
	RET
;
;DIVA dividiert HL / A
;Ergebnis: HL =INT(HL/A)
;	   A=rest, wenn Z=0
;
diva	LD	C,A
	LD	B,10
	XOR	A
dd2	ADD	HL,HL
	RLA
	JR	C,dd0
	CP	C
	JR	C,dd1
dd0	SUB	C
	INC	L
dd1	DJNZ	dd2
	OR	A
	RET
;
;Binärbyte in ASCII-Ziffernstring wandeln
;und ab (HL) ablegen
;Byte wird in A übernommen
;HL zeigt anschließend hinter den String
byasc	PUSH	DE
	PUSH	HL
	PUSH	HL
	LD	L,A
	LD	H,0
	LD	A,100
	CALL	diva	;Hunderter in L
	LD	D,A	;Divisionsrest
	LD	E,L
	LD	A,L
	OR	A	;Hunderter = 0 ?
	JR	Z,nohund
	OR	30h	;ASCII-Zeichen
	POP	HL	;Ablageadresse
	LD	(HL),A
	INC	HL
	PUSH	HL
;
nohund	LD	L,D	;Divisionsrest
	LD	H,0
	LD	A,10
	CALL	diva	;Zehner in L
	LD	D,A	;Rest ist Einer
	LD	A,L	;Zehner
	OR	A	;Zehner = 0 ?
	JR	NZ,zehnr
;
	POP	HL
	LD	A,L
	EX	(SP),HL
	CP	L
	EX	(SP),HL
	PUSH	HL
	JR	Z,nozehn
;
	LD	A,0	;Zehner
zehnr	POP	HL
	OR	30h
	LD	(HL),A
	INC	HL
	PUSH	HL
nozehn	POP	HL
	LD	A,D
	OR	30h
	LD	(HL),A
	INC	HL
	POP	DE
	RET
;
;Umwandlung eines Binär-Bytes in ASCII-String
bydez	LD	HL,strbuf
bydez1	PUSH	HL
	LD	L,A
	XOR	A
	 	LD	H,A		;Wert ist in HL
	LD	A,100		;Hunderter-Stelle
	CALL	diva		;ermitteln
	LD	C,A		;Divisionsrest in C
	LD	A,L		;falls '0', weglassen
	OR	A
	JR	Z,nich		;wenn '0'
	OR	30h		;to ASCII
	POP	HL		;Ablage-Pointer
	LD	(HL),A
	INC	HL
	PUSH	HL
nich	LD	L,C		;Rest durch 10 teilen
	LD	A,10
	CALL	diva
	LD	C,A		;Rest retten
	LD	A,L		;Zehnerstelle
	OR	A		;Wenn die auch 0 ist
	JR	Z,nich1
	OR	30h		;to ASCII
	POP	HL		;Ablage-Pointer
	LD	(HL),A
	INC	HL
	PUSH	HL
nich1	LD	A,C		;Einerstelle
	OR	30h		;to ASCII
	POP	HL
	LD	(HL),A
	INC	HL
	XOR	A		;00h dahinter
	LD	(HL),A
	RET
;
;2 Digit-BCD-Wert im Akku binär wandeln
bybin	PUSH	DE
	LD	D,A		;retten
	AND	0fh
	LD	E,A		;low Nibble in E
	LD	A,D
	AND	0f0h		;high Nibble :16 *10
	SRL	A		;8/16 des high Nibbles
	LD	D,A
	SRL     SCF
	SRL     SCF		;2/16 des high nibbles
	ADD	A,D		;10/16
	ADD	A,E             ;low Nibble addieren
	POP	DE
	RET
;
;16-Bit-Hexzahl dezimal in ASCII-String wandeln
;und an Bildschirm ausgeben
bindez	LD	B,5		;max 5 Zeichen
	XOR	A		;00H auf den Stack
	PUSH	AF
teile	PUSH	BC		;Zähler retten
	LD	A,10		;durch 10 teilen
	CALL	diva		;HL = INT(HL/A)
	OR	30		;Rest in A =>ASCII
	POP	BC
	PUSH	AF		;weg damit
	DJNZ	teile		;nächste Stelle
;Zeichen vom Stack in den Ausgabepuffer
;führende Nullen unterdrücken
	LD	HL,strbuf
nxblk	POP	AF		;Zeichen holen
	CP	'0'		;führende Null ?
	JR	Z,nxblk
nxasc	LD	(HL),A		;Zeichen in Buffer
	INC	HL
	POP	AF
	OR	A		;String zuende ?
	JR	NZ,nxasc	;wenn noch nicht
	LD	(HL),A		;Terminator dahinter
	RET
;
