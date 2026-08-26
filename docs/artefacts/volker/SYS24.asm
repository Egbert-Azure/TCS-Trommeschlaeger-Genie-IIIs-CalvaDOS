;Interrupt-Möglichkeiten ermitteln und einbauen! Weniger saufen!

;SYS24/SYS: SIO-Routinen, die im Interpreter und ursprünglich an 35BB
;laufen, sind fest in den Interpreter eingebaut und hier nicht mehr
;berücksichtigt. In dieser Form ist SYS24/SYS ohne geänderten Interpreter
;nicht mehr lauffähig!
;Die Maus-Routine (neu) ist auf die serielle Z-NIX-Maus programmiert.
;Andere Mäuse müssen u. U. anders bedient werden.

;
;
;	geändert am 03.03.92
;	von Volker
;	CD	- Change Directory
;	ab Zeile 548
;
; ACHTUNG ------------------------------------------
; Wenn der Intepreter in SYS1/SYS geändert wird, muss CD auch unbedingt
; geändert werden, da CD im gebankten SYS1 die Dosready meldung patcht
; ACHTUNG -----------------------------------------------------
;
;
m0033	EQU	0033h		;UP Akku auf den Bildschirm ausgeben
m0216	EQU	0216h		;Puffer für den Inhalt von WR5, Kanal A
m0297	EQU	0297h		;UP liest Datum von SIO, evtl. "busy"
m029b	EQU	029bh		;Puffer für Ctrl.-Port Kanal A bzw. B
m05bb	EQU	05bbh		;dort Druckerausgabe
m05bd	EQU	05bdh		;wird auf SIO-Ausgabe umgestellt
m05d1	EQU	05d1h		;dort Druckerabfrage
m05d2	EQU	05d2h		;wird auf SIO-Abfrage umgestellt
m4200	EQU	4200h		;DOS-Sektorpuffer ohne RAM-Disk
m42e0	EQU	42e0h		;ab hier SIO-Parameter im Sektorpuffer
m42e2	EQU	42e2h		;Puffer für Protokoll-Bits
m42e3	EQU	42e3h		;Puffer für WR3, u. a. Anzahl Datenbits
m42e5	EQU	42e5h		;Puffer u. a. für PR/NOPR-Flag
m4467	EQU	4467h		;UP String auf den Bildschirm ausgeben
m4630	EQU	4630h		;UP diskrelativen Sektor einlesen
m4640	EQU	4640h		;UP diskrelativen Sektor schreiben
m4776	EQU	4776h		;UP Laufwerk (A) selektieren und starten
m4cd5	EQU	4cd5h		;UP Trennzeichen untersuchen und interpr.

	ORG	4d00h

sys24	CP	0fah		;Requestcode für SYS24/SYS
	JR	NZ,error	;falls anderer Requestcode
	DEC	C		;C = 01 ?
	JR	Z,sio		;falls ja
	DEC	C		;C = 02 ?
	JP	Z,chadir	;falls ja

error	LD	A,2ah		;Fehlercode "unzulässige DOS-Funktion"
	RET			;raus mit Fehlerbedingung


sio	PUSH	HL		;Befehlszeiger retten
	CALL	m4cd5		;HL auf nächst. Zeichen im Befehl stellen
	LD	A,(HL)		;laden
	CP	':'		;Trennzeichen für Laufwerksnummer?
	LD	A,05h		;Akku löschen
	JR	NZ,m4d1d	;Laufwerk 0, falls kein Doppelpunkt
	INC	HL		;Doppelpunkt: Zeiger auf nächstes Zeichen
	LD	A,(HL)		;laden
	AND	0f8h		;Bits 0-2 maskieren
	CP	'0'		;eine Ziffer?
	JR	Z,m4d18		;falls ja
	POP	HL		;Befehlszeiger
	LD	A,20h		;Fehlercode "unzul. o. fehlend. Laufwerk"
	RET			;raus mit Fehler

m4d18	LD	A,(HL)		;Lw-Nr. laden
	AND	07h		;Bits 0-2: Laufwerk 0-3 möglich
	INC	HL		;auf nächstes Zeichen im Befehl stellen
	EX	(SP),HL		;Zeiger retten, HL <- Anf. Befehlsstring
m4d1d	CALL	m4776		;Laufwerk (A) selektieren und starten
	JR	NZ,m4d2b	;falls ein Fehler auftrat
	LD	HL,m4200	;Sektorpuffer
	LD	DE,0002h	;diskrelativer Sektor 2
	CALL	m4630		;diesen laden
m4d2b	POP	HL		;Befehlszeiger zurück
	RET	NZ		;zurück bei aufgetretenem Fehler
	PUSH	IX		;retten
	CALL	m4e5b		;Register für Kanal A aufsetzen
m4d32	LD	DE,m4d8b	;ab String "PR"
	CALL	m4cd5		;Trennzeichen untersuchen
	CALL	m4cd5		;es ist das nächste Zeichen
	JP	Z,m4f0e		;falls CR
	PUSH	HL		;Befehlszeiger retten
	EX	DE,HL		;DE <- Befehlszeiger, HL <- "PR"
m4d40	LD	A,(DE)		;Zeichen des Befehlsstrings laden
	CP	','		;Trennzeichen?
	JR	Z,m4d5c		;falls ja
	CP	' '		;auch als Trennzeichen erlaubt
	JR	Z,m4d5c		;falls dieses
	CP	0dh		;Befehlsstring zuende?
	JR	Z,m4d5c		;falls ja
	BIT	7,(HL)		;String zuende? (es folgt CALL, Opc. CDh)
	JR	NZ,m4d71	;falls ja
	INC	(HL)		;auf 00 prüfen
	DEC	(HL)		;(= Ende der Tabelle)
	JR	Z,m4d84		;Ende, Syntaxfehler, falls nicht gefunden
	CP	(HL)		;das richtige Zeichen gefunden?
	JR	NZ,m4d71	;falls nein
	INC	HL		;o. k., nächstes Zeichen der Tabelle
	INC	DE		;und des Befehlsstrings
	JR	m4d40		;bis Ende der Tabelle oder des Befehls

m4d5c	BIT	7,(HL)		;nächster Parameter in der Tabelle?
	JR	Z,m4d71		;falls nein
	POP	AF		;Stack bereinigen
	PUSH	DE		;Befehlszeiger retten
	INC	HL		;auf nächstes Zeichen in der Tabelle
	LD	E,(HL)		;DE <- nächste beiden Zeichen
	INC	HL
	LD	D,(HL)
	LD	BC,m4d6e	;Fortsetzungsadresse
	PUSH	BC		;als RET-Adresse auf den Stack
	INC	HL		;nächstes Zeichen im String
	LD	A,(HL)		;laden
	EX	DE,HL		;HL <- Bearbeitungsadresse
	JP	(HL)		;UP anspringen

;Rückkehr hierher:
m4d6e	POP	HL
	JR	m4d32		;gegf. nächsten Parameter bearbeiten

m4d71	BIT	7,(HL)		;CALL-Befehl angetroffen?
	INC	HL		;auf LSB der CALL-Adresse stellen
	JR	Z,m4d71		;falls CALL-Befehl noch nicht gefunden
	INC	HL		;auf MSB stellen
m4d77	INC	HL		;auf Byte nach der CALL-Adresse
	LD	A,(HL)		;laden
	OR	A		;= 00? (Tabelle zuende)
	JR	Z,m4d80		;falls ja
	CP	' '		;kein anzeigbares Zeichen?
	JR	C,m4d77		;falls dem so ist
m4d80	POP	DE		;Befehlszeiger
	PUSH	DE		;wieder auf den Stack
	JR	m4d40		;nächsten Parameter bearbeiten

m4d84	POP	HL		;restaurieren
	POP	IX
	LD	A,34h		;Fehlercode "Trennzeichen oder Endz. ..."
	OR	A		;NZ-Flag setzen (Fehlerflag)
	RET			;zurück mit Fehlerbedingung

m4d8b	DEFM	'PR'		;Befehlsparameter (hier: Druckerbedien.)
	CALL	m4ef1		;Bearbeitungsroutine
	DEFM	'NOPR'		;usw. für alle Parameter des Befehls
	CALL	m4f05
	DEFM	'A'		;SIO-Kanal
	CALL	m4e5b
	DEFM	'B'
	CALL	m4e6a
m4d9f	DEFM	'EVEN'		;Parität
	CALL	m4e89
m4da6	DEFM	'ODD'
	CALL	m4e8d
m4dac	DEFM	'NO'
	CALL	m4e91
	DEFM	'5'		;Datenbits pro Zeichen
	CALL	m4ecc
	DEFM	'6'
	CALL	m4ed0
	DEFM	'7'
	CALL	m4ed4
	DEFM	'8'
	CALL	m4ed8
	DEFM	'1'		;Stopbits
	CALL	m4ebb
	DEFM	'2'
	CALL	m4ec3
m4dc9	DEFM	'1.5'
	CALL	m4ebf
m4dcf	DEFM	'XON'		;Protokoll
	CALL	m4e9d
m4dd5	DEFM	'RTS'
	CALL	m4ea1
m4ddb	DEFM	'DTR'
	CALL	m4ea5
m4de1	DEFM	'WAIT'
	CALL	m4eb1
m4de8	DEFM	'NOWAIT'
	CALL	m4eb6
m4df1	DEFM	'19200'		;Baudrate
	CALL	m4e79		;Bearbeitungsroutine
	DEFB	01h		;Bitmaske der Baudrate für Port F1
	DEFM	'9600'		;usw. für alle Baudrates
	CALL	m4e79
	DEFB	08h
	DEFM	'4800'
	CALL	m4e79
	DEFB	09h
	DEFM	'2400'
	CALL	m4e79
	DEFB	0ch
	DEFM	'1800'
	CALL	m4e79
	DEFB	0ah
	DEFM	'1200'
	CALL	m4e79
	DEFB	0bh
	DEFM	'600'
	CALL	m4e79
	DEFB	06h
	DEFM	'300'
	CALL	m4e79
	DEFB	0dh
	DEFM	'200'
	CALL	m4e79
	DEFB	05h
	DEFM	'150'
	CALL	m4e79
	DEFB	0eh
	DEFM	'134.5'
	CALL	m4e79
	DEFB	04h
	DEFM	'110'
	CALL	m4e79
	DEFB	0fh
	DEFM	'75'
	CALL	m4e79
	DEFB	03h
	DEFM	'50'
	CALL	m4e79
	DEFB	02h
	NOP			;Flag für Ende der Tabelle

;Selektion des Kanals
m4e5b	LD	A,00h		;Befehl NOP
	LD	(m4e7b),A	;dort patchen
	LD	A,0f0h		;Maske für oberes Nibble
	LD	(m4e83),A	;dort patchen
	LD	IX,m42e0	;Beginn der SIO-Parameter Kanal A
	RET

m4e6a	LD	A,07h		;Befehl RLCA (Nibbles tauschen)
	LD	(m4e7b),A	;dort patchen
	LD	A,0fh		;Maske für unteres Nibble
	LD	(m4e83),A
	LD	IX,m42e5	;Beginn der SIO-Parameter Kanal B
	RET

;Baudrate
m4e79	LD	B,04h		;Zähler 4 Bits zum Tauschen der Nibbles
m4e7b	NOP			;oder RLCA, je nach Nibble (Kanal A o. B)
	DJNZ	m4e7b		;Nibbles vertauschen
	LD	B,A		;merken
	LD	A,(m42e0)	;bisheriger Wert für beide Kanäle
	AND	00h		;Maske für das Nibble
m4e83	EQU	$-1		;wird je nach Kanal gepatcht
	OR	B		;mit neuem Wert verknüpfen
	LD	(m42e0),A	;Byte neu puffern
	RET

;Parity
m4e89	LD	C,03h		;für EVEN
	JR	m4e93

m4e8d	LD	C,01h		;für ODD
	JR	m4e93

m4e91	LD	C,00h		;für NO
m4e93	LD	A,(IX+04h)	;Puffer für WR4
	AND	0fch		;Nicht-Parity-Bits maskieren
m4e98	OR	C		;Stop- bzw. Parity-Bits setzen
	LD	(IX+04h),A	;Puffer für WR4 neu schreien
	RET

;Protokoll
m4e9d	LD	C,80h		;für XON
	JR	m4ea7

m4ea1	LD	C,20h		;für RTS
	JR	m4ea7

m4ea5	LD	C,08h		;für DTR
m4ea7	LD	A,(IX+02h)	;Puffer für WR5
	AND	57h		;übrige Bits maskieren
	OR	C		;obige Bits setzen
	LD	(IX+02h),A	;Puffer neu schreiben
	RET

m4eb1	SET	0,(IX+02h)	;WAIT markieren
	RET

m4eb6	RES	0,(IX+02h)	;NOWAIT markieren
	RET

;Stopbits
m4ebb	LD	C,04h		;für 1 Stopbit
	JR	m4ec5

m4ebf	LD	C,08h		;für 1.5 Stopbits
	JR	m4ec5

m4ec3	LD	C,0ch		;für 2 Stopbits
m4ec5	LD	A,(IX+04h)	;Puffer für WR4
	AND	0f3h		;übrige Bits maskieren
	JR	m4e98		;Stopbit-Muster schreiben und zurück

;Datenbits pro Zeichen
m4ecc	LD	C,00h		;bei 5 Datenbits
	JR	m4edc

m4ed0	LD	C,40h		;bei 6 Datenbits
	JR	m4edc

m4ed4	LD	C,20h		;bei 7 Datenbits
	JR	m4edc

m4ed8	LD	C,60h		;bei 8 Datenbits
m4edc	LD	A,(IX+05h)	;Puffer für WR5 (Datenbits beim Senden)
	AND	9fh		;übrige Bits maskieren
	OR	C		;Bits für Datenbits/Zeichen setzen
	LD	(IX+05h),A	;für WR5 neu schreiben
	RLC	C		;Bit 5-6 -> 6-7 in WR3 (Empfangs-Datenb.)
	LD	A,(IX+03h)	;Puffer für WR3
	AND	3fh		;übrige Bits maskieren
	OR	C		;Bits für Datenbits/Zeichen setzen
	LD	(IX+03h),A	;für WR3 neu schreiben
	RET

;serielle Druckerbedienung
m4ef1	PUSH	IX		;je nach Kanal 42E0 oder 42E5
	POP	BC		;weil der Befehl SBC HL,IX nicht exisiert
	LD	HL,2*m42e5	;zur Berechnung von IX+5 des anderen Kan.
	OR	A		;Cy löschen wegen SBC
	SBC	HL,BC		;A: 42EA, B: 42E5 (= IX+5 des and. Kan.)
	RES	7,(HL)		;PR-Bits des anderen Kanals löschen
	RES	1,(HL)
	LD	A,(IX+05h)	;PR-Flag in der Parameterliste
	OR	82h		;PR-Bits des selektierten Kanals setzen
	JR	m4f0a		;in die Parameterliste setzen und raus

m4f05	LD	A,(IX+05h)	;PR-Flag der Parameterliste
	AND	7dh		;PR-Bits zurücksetzen
m4f0a	LD	(IX+05h),A	;PR/NOPR-Flag neu setzen
	RET

m4f0e	LD	A,(m42e0)	;Baudrate beider Kanäle
	OUT	(0f1h),A	;auf SIO ausgeben
	XOR	A		;A <- 00: beide Kanäle aktiv,
	OUT	(0f2h),A	;Sende- = Empfangs-Baudrate
	LD	B,02h		;Zähler für 2 SIO-Kanäle
	LD	IX,m42e0	;Beginn der Parameterliste
	LD	C,0d2h		;Ctrl.-Port Kanal A
m4f1e	LD	A,18h		;Kommando Kanal-Reset
	OUT	(C),A		;ausgeben
	LD	(IX+01h),00h	;kein INT-Betrieb usw.
	LD	A,(IX+02h)	;spezielle Bits des Protokolls
	AND	0a9h		;weiß der Geier
	OR	04h		;dto. der Henker
	LD	(IX+02h),A	;na gut, ausnahmsweise
	LD	A,(IX+03h)	;Puffer für WR3
	AND	0c0h		;Bits für Wortlänge isolieren
	OR	01h		;Rx enable, sonst nichts
	LD	(IX+03h),A	;Puffer neu schreiben
	LD	A,(IX+04h)	;Puffer für WR4
	AND	0fh		;nur Parity und Stop
	OR	40h		;Clock *16
	LD	(IX+04h),A	;neu puffern
	LD	A,(IX+05h)	;WR5
	AND	0e2h		;verschiedenes sperren
	OR	08h		;Tx enable
	LD	(IX+05h),A
	RLCA			;PR-Flag aktiv?
	JR	NC,m4f6c	;falls nein
	LD	A,C		;Ctrl.-Port des jeweiligen Kanals
	LD	(m029b),A	;dort patchen
	SUB	02h		;Datenport
	LD	(m05bd),A	;in die Druckerroutine patchen (Ausgabe)
	LD	A,0c3h		;JP-Opcode
	LD	(m05d1),A	;dto. (Abfrage)
	LD	HL,m0297	;JP-Adresse
	LD	(m05d2),HL	;jetzt 05D1: JP 0297
	LD	HL,00+256*0d3h	;Befehle NOP, OUT (n),A
	LD	(m05bb),HL	;in die Druckerroutine patchen
m4f6c	PUSH	BC		;Zähler der Kanäle retten
	LD	B,05h		;Zähler 5 Daten für SIO
	XOR	A		;A <- 00, ab WR0+1 = WR1
	PUSH	IX
	POP	HL		;Zeiger der Parameterliste
	INC	HL		;auf IX+1
m4f74	INC	A		;ab WR1 usw.
	OUT	(C),A		;Register adressieren
	OUTI			;Pufferdatum auf das Register ausgeben
	JR	NZ,m4f74	;bis 5 Register (bis WR5) geschr. sind
	DEC	HL		;wird neues IX+0
	PUSH	HL
	POP	IX
	POP	BC		;Zähler für 2 Kanäle
	INC	C		;Ctrl.-Port Kanal B
	DJNZ	m4f1e		;Kanal B ebenso initialisieren
	JR	m4f94

m4f85	LD	A,' '		;Blank
	JP	m0033		;anzeigen und zurück

m4f8a	LD	A,(HL)		;Zeichen des Strings laden
	BIT	7,A		;String zuende? (CALL-Befehl folgt)
	RET	NZ		;falls ja
	INC	HL		;Zeiger auf nächstes Zeichen
	CALL	m0033		;anzeigen
	JR	m4f8a		;und so weiter

m4f94	LD	B,02h		;Zähler 2 Kanäle
	LD	IX,m42e0	;Zeiger auf die Daten
m4f9a	LD	HL,m50ce	;Text "SIO "
	CALL	m4467		;anzeigen
	LD	A,'B'+1		;höchstzulässiger Kanal +1
	SUB	B		;A <- "A" oder "B"
	CALL	m0033		;anzeigen
	CALL	m4f85		;Blank dahinter
	LD	HL,m4df1	;Tabelle der Baudrates
	LD	A,(m42e0)	;Baudrate-Puffer für beide Kanäle
	DEC	B		;noch Kanal A?
	JR	NZ,m4fb6	;falls schon Kanal B
	RRCA			;ins untere Nibble rotieren
	RRCA
	RRCA
	RRCA
m4fb6	INC	B		;Zähler restaurieren
	AND	0fh		;Bits des anderen Kanals maskieren
	JR	NZ,m4fbc	;falls > 0
	INC	A		;sonst A <- 1 (0 u. 1 bedeuten 19.200 Bd)
m4fbc	CP	07h		;2.400 Bd?
	JR	NZ,m4fc2	;falls nein
	LD	A,0ch		;07 und 0C bedeuten 2.400 Bd
m4fc2	LD	E,L		;DE <- Adresse der Baudrate in ASCII
	LD	D,H
m4fc4	BIT	7,(HL)		;Ende des ASCII-Strings? (es folgt CALL)
	INC	HL		;auf nächstes Zeichen stellen
	JR	Z,m4fc4		;falls CALL-Befehl noch nicht erreicht
	INC	HL		;CALL-Adresse überspringen
	INC	HL
	CP	(HL)		;richtige Baudrate gefunden?
	INC	HL		;auf nächsten Baudrate-String
	JR	NZ,m4fc2	;falls noch nicht gefunden
	EX	DE,HL		;HL <- ASCII-String der Baudrate
	CALL	m4f8a		;String anzeigen
	CALL	m4f85		;Blank dahinter
	LD	A,(IX+03h)	;Puffer für Datenbits/Zeichen
	RLCA			;*2 für Rechnerei
	RES	1,A		;für Rechnerei (kein Wortlängen-Bit)
	BIT	7,A		;7 oder 8 Bits/Zeichen?
	JR	Z,m4fe2		;falls 5 oder 6, andernfalls:
	SET	1,A		;min. 2, ergibt 7 oder 8 Datenbits
m4fe2	AND	03h		;andere Bits maskieren
	ADD	A,'5'		;A <- "7" oder "8" (Datenbits pro Zeich.)
	CALL	m0033		;anzeigen
	CALL	m4f85		;Blank dahinter
	LD	A,(IX+04h)	;Puffer für WR4
	PUSH	AF
	AND	0ch		;Stopbit-Muster
	JR	NZ,m4ffc	;falls Stopbits programmiert
	LD	HL,m50d3	;Text "?S?" (Sync-Mode nicht vorgesehen)
	CALL	m4467		;anzeigen
	JR	m5011		;weiter mit anderen Parametern

m4ffc	CP	08h		;1.5 Stopbits?
	JR	NZ,m5008	;falls nein
	LD	HL,m4dc9	;String "1.5"
	CALL	m4f8a		;String anzeigen
	JR	m5011		;weiter mit anderen Parametern

m5008	RRCA			;Bits 2-3 -> Cy und Bit 0
	RRCA
	SRL	A		;(Bit 7 muß sauber bleiben)
	ADD	A,'1'		;ASCII Stop-Bits
	CALL	m0033		;anzeigen
m5011	CALL	m4f85		;Blank dahinter
	POP	AF		;Inhalt von WR4
	BIT	0,A		;Parity programmiert?
	JR	NZ,m501e	;falls ja
	LD	HL,m4dac	;sonst Text "NO"
	JR	m5028		;anzeigen usw.

m501e	BIT	1,A		;parity even?
	LD	HL,m4d9f	;Text "EVEN"
	JR	NZ,m5028	;falls ja
	LD	HL,m4da6	;sonst Text "ODD"
m5028	CALL	m4f8a		;String anzeigen
	CALL	m4f85		;Blank dahinter
	LD	A,(IX+02h)	;versch. Bits des Protokolls
	LD	HL,m4dcf	;Text "XON"
	BIT	7,A		;XON?
	JR	NZ,m5042	;falls ja
	LD	HL,m4dd5	;Text "RTS"
	BIT	5,A		;RTS?
	JR	NZ,m5042	;falls ja
	LD	HL,m4ddb	;sonst Text "DTR"
m5042	PUSH	AF
	CALL	m4f8a		;String anzeigen
	CALL	m4f85		;Blank dahinter
	POP	AF
	LD	HL,m4de1	;Text "WAIT"
	BIT	0,A		;WAIT?
	JR	NZ,m5054	;falls ja
	LD	HL,m4de8	;sonst Text "NOWAIT"
m5054	CALL	m4f8a		;String anzeigen
	BIT	7,(IX+05h)	;PR-Flag?
	JR	Z,m5066		;falls nein
	CALL	m4f85		;Blank dahinter
	LD	HL,m4d8b	;Text "PR"
	CALL	m4f8a		;String anzeigen
m5066	LD	A,0dh		;CR
	CALL	m0033		;ausgeben
	LD	IX,m42e5	;Parameterliste für Kanal B
	DEC	B		;Sprung zu weit für DJNZ
	JP	NZ,m4f9a	;gegf. Parameter für Kanal B anzeigen
	LD	HL,m0216	;residenter Puffer für WR5, Kanal A
	LD	A,(m42e5)	;dort stehen die Daten
	LD	(HL),A		;in den Puffer schreiben
	INC	HL		;auf 0217
	LD	A,(IX+05h)	;Puffer für WR5, Kanal B
	LD	(HL),A		;dort ablegen
	LD	B,02h		;Zähler für 2 Kanäle
	LD	A,(m42e3)	;Datum von WR3, Kanal A
m5084	AND	0c0h		;Bits für die Wortlänge
	LD	C,0ffh		;AND-Maske für empfangenes Byte
	CP	0c0h		;8 Bits/Zeichen?
	JR	Z,m509a		;falls ja
	LD	C,7fh
	CP	40h		;7 Bits?
	JR	Z,m509a
	LD	C,3fh
	CP	80h		;6 Bits?
	JR	Z,m509a
	LD	C,1fh		;bei 5 Bits/Zeichen
m509a	INC	HL		;auf 0218 (Kanal A) bzw. 0219 (Kanal B)
	LD	(HL),C		;AND-Maske puffern
	LD	A,(IX+03h)	;Datum von WR3, Kanal B
	DJNZ	m5084		;bis Inhalt von WR3, Kan. A und B gepuff.
	LD	A,(m42e2)	;Bitmuster für Protokoll, Kanal A
	INC	HL		;auf 021A
	LD	(HL),A		;puffern
	LD	A,(IX+02h)	;dto. Kanal B
	INC	HL		;auf 021B
	LD	(HL),A		;puffern
	LD	DE,0002h	;diskrelativer Sektor 2
	LD	HL,m4200	;Sektorpuffer
	CALL	m4640		;Sektor neu schreiben
	CP	0fh		;Fehlercode "Diskette schreibgeschützt"?
	JR	NZ,m50ca	;falls anderer Fehler
	XOR	A		;Flag "kein Fehler" bei Schreibschutz
m50ca	POP	IX
	RET			;zurück mit Fehlerstatus

m50ce	DEFM	'SIO ',03h	;Texte für Parameteranzeige der SIO
m50d3	DEFM	'?S?',03h

;		Change Directory
;
;
;	Setzt Defaultlaufwerk nach Namens eingabe
;
;	RAMDISK		- LW# 3
;	DOS		- LW# 5
;	SOURCES		- LW# 6
;	WORKBENC	- LW# 7
;	DATEN		- LW# 8
;	SONSTIGES	- LW# 9
;	DISK0		- LW# 0
;	DISK1		- LW# 1
;
;
dosrdy	EQU	402dh
doserr	EQU	4409h
gibaus	EQU	4467h
dirlw	EQU	43a0h
openlw	EQU	43a1h
verglei	EQU	4cc5h

	ORG	3000h		; muss hier stehen wegen Common
chadir	PUSH	HL		; HL retten
	POP	DE		; HL -> DE
	LD	BC,text0	; 'DISK0',00
	CALL	verglei
	JR	Z,eintrag	; wenn text gleich, weiter
	PUSH	DE
	POP	HL
	LD	BC,text1        ; 'DISK1',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text2	; 'RAMDISK',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text5	; 'DOS',00
	CALL	verglei		;
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text6	; 'SOURCES',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text7	; 'WORKBENC',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text8	; 'DATEN',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text9	; 'SONSTI',00
	CALL	verglei
	JR	Z,eintrag
abgang	LD	A,20h		; 'unzulässiges od. Fehlendes LW'
	OR	A
	JP	doserr
eintrag	LD	A,(BC)
	LD	(dirlw),A	; lwnummern eintragen
	LD	(openlw),A
;
; ab hier soll in bank 0 der name gepatcht werden, dessen laufwerks
; nummer gewählt wurde.
	IN	A,(0f9h)	;sysport 0 ist der Bankingport
	RES	0,A		; common unten
	RES	6,A		; bank 0 anwählen
	RES	7,A		;  dito
	DI			; jetzt wirds heikel
	OUT	(0f9h),A	; diese Konfiguration ausgeben
	INC	BC		; bc muß um 5 erniedrigt werden
	     		; um auf den Anfang von
	 	  		; text(x)	zu zeigen
	LD	H,B		; wegen LDIR, source ist HL
	LD	L,C		; nicht wahr
; Hier steht die Adresse, die gegebenenfalls geändert werden muß
	LD	DE,90bbh	; ist in dem gebankten SYS1 der
; falls der Interpreter geändert wurde. Man muß mit dem Booteprom
; monitor sich die genaue Stelle in Bank 0 angucken. !!!
	LD	BC,0010h	; Bank 0 die adresse des DOS-Ready
	LDIR			; strings, wird so gepatcht
	LD	A,40h		; normale konfiguration von port
	OUT	(0f9h),A	; f9
	EI
	RET
text0	DEFM	'DI0',00,00,':0Disk_0 >',1eh,03
text1	DEFM	'DI1',00,01,':1Disk_1 >',1eh,03
text2	DEFM	'RAM',00,03h,':3Ramdisk >',1eh,03
text5	DEFM	'DOS',00,05,':5CalvaDOS >',1eh,03
text6	DEFM	'SOU',00,06,':6Sources >',1eh,03
text7	DEFM	'WOR',00,07,':7Workbench >',1eh,03
text8	DEFM	'DAT',00,08,':8Daten >',1eh,03
text9	DEFM	'SON',00,09,':9Sonstiges >',1eh,03
	END	sys24
