;IO ROUTINE UM PORTS EINZULESEN
; ODER UM WERTE AUF PORTS RAUSZUGEBEN
; -----------------------------
; VON ARNULF SOPP AUS CLUB INFO 12
	ORG	4200h
; STARTADRESSE IM SEKTORPUFFER
START	CALL  	getval           ;
	LD	C,A
	CALL 	4cd5h		;trennung und cr erk.
	JR	NZ,out		;falls mehr zahlen
;	INPUT abfragen
	IN	A,(C)
	LD	HL,buffer	;cursorpos
	CALL	4068H		;INPUT ANZEIGEN
	LD	HL,buffer
	CALL	4467h		; ausgeben
	JP 	402dh		;ausgebdn und ab
; outputs errechnen und ausgeben
loop	CALL	4cd5h		;trennzeichen &cr
	RET	Z
out	CALL getval		;nexte hexzahl(en)
	OUT	(C),A		;port c,wert a
	JR	loop		;usw.
;eine hexzahl einlesen und auswerten
getval	CALL	getchr		;eine zahl einlesen
	RLCA
	RLCA
	RLCA
	RLCA
;ins obere nibbleschieben, also erst die hoehere stelle
;der zahl nehmen
	LD	B,A		;zwischenspeichern
	CALL getchr		;untere hex-haelfte
	OR	B		;vereinigen
	RET			;zurueck mit kompl. zahl
;eine hexziffer einlesen und binaer angleichen
getchr	LD      SCF,{86}           ;NEXTES ZEICEHN
	INC	HL		;weiter im befehlsstring
	SUB	'0'		;binaerangleichung
	JR	C,error		;falls kleiner null
	CP	0ah		;groesser neun ?
	RET	C		;fertig falls dezimal
	SUB	07h		;ziffern a-f
	CP	0ah		;hex a oder groeser
	JR	C,error		;falls kleiner
	BIT	4,A		;groeser als F ?
	RET	Z		;wenn nicht
;fehlercode falscher parameter
error	LD	A,2fh		;fehlercode
	POP 	BC		;stack korrigieren
	POP	BC		;zweite ebene
	JP	4409h		;doserrorexit
buffer	DEFM	'ff',0dh

	END     START
