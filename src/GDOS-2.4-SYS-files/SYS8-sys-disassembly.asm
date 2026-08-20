;************************************************************************
; SYS8 vom G-DOS 2.4
;
;
; Disassembliert und kommentiert von
; A.Magnus   HACKNUS - SOFTWARE
;
; Name: SYS8/SRC
;
; Datum:08.09.89
;
;************************************************************************
; ; z80dasm 1.2.0
; command line: z80dasm -g 0x4d00 -l -a -t -o SYS8-sys-disassembly.asm sys8sys_flat.bin
;
m1916	EQU	1916h
m4380	EQU	4380h
m43a0	EQU	43a0h		;SYSTEM AN (DRIVE # für DIR)
m4409	EQU	4409h		;DOS ERROR EXIT
m492f	EQU	492fh		;FDE einer File aus dem Directory holen
m4cd5	EQU	4cd5h		;Zeichen in (HL) testen
	ORG	4d00h
	LD	IY,m4380
	PUSH	AF
	LD	A,(m1916)
	OR	A
	JR	NZ,m4d0d
	LD	A,10h
m4d0d	SUB	03h
	LD	(IY+0efh),A
	POP	AF		;Wert in A bei RST 28
	CP	2ah		;ist es DIR ?
	JR	Z,m4d5c		;ja
	CP	4ah		;ist es FREE ?
	LD	A,2ah		;Fehler Code 'Unz. DOS - Funktion'
	RET	NZ		;zurück wenn nicht Dir oder Free
free	CALL	m5088		;Wenn 'P' auf Drucker umleiten
	CP	0dh		;Eingabe zuende ?
	JR	NZ,m4d4d	;wenn nicht
	LD	C,00h		;ab Lw 0
	CALL	m50ae		;Blank u. CR anzeigen
m4d28	LD	B,(IY+0efh)
m4d2b	CALL	m4ff9
	JR	Z,m4d3a
	CP	' '
	JP	Z,m4fd9
	CP	08h
	JR	NZ,m4d4f	;Fehler
	INC	B
m4d3a	INC	C
	DJNZ	m4d2b
	CALL	m509b		;Screen full ?
	JR	m4d28

m4d42	LD	A,00h		;hier wird der Directory Entry Code gepatcht
m4d43	EQU	$-1
m4d44	LD	(m4d43),A	;neuen DEC patchen (s.o.)
m4d47	CALL	m492f		;FDE aus dem Directory holen A=DEC bei aufruf
	RET	Z		;HL = Byte 0 des FDE. zurück wenn OK.
	JR	m4d4f		;Fehler

m4d4d	LD	A,34h		;Fehler 'Syntax oder Trennzeichen...'
m4d4f	PUSH	AF
	LD	HL,m5155	;Text 'DOS-',03
m4d53	LD	HL,m4fbb	;wird evtl zu 'CALL 4FBB'
	POP	AF
	OR	A
	RET	Z		;kein Fehler
	JP	m4409		;raus mit Fehler

;Einsprung bei DIR	B sind Flags für verschiedene Parameter bei DIR
m4d5c	LD	A,(m43a0)	;SYSTEM AN (Drive # für DIR)
	LD	C,A		;nach C
	LD	B,00h
	LD	A,(HL)		;nächstes Zeichen
	CP	':'
	JR	NZ,m4d68
	INC	HL		;Zeiger auf nächstes Zeichen
m4d68	LD	A,(HL)		;Nächstes Zeichen
	CP	'$'		;Drive 0 ohne System
	JR	NZ,m4d70	;wenn nicht
	SET	6,B		;Flag '$' (I 0  ohne SYS)
	INC	HL		;Zeiger weiter
m4d70	LD	A,(HL)		;Zeichen laden
	SUB	30h		;in Binär wandeln
	CP	0ah		;Drive # über 9 ?
	JR	NC,m4d95	;ja, Fehler
m4d77	LD	C,A		;Drive # nach C
	INC	HL		;Zeiger höher
	LD	A,(HL)		;Zeichen laden
	SUB	30h		;in Binär wandeln
	CP	0ah		;> 9 ?
	JR	NC,m4d91	;Sprung wenn ja
	LD	E,A		;Zeichen nach E
	LD	A,C		;Drive # nach a
	LD	D,09h
m4d84	ADD	A,C		;A + Drive #
	JR	C,m4d8d		;wenn > FF
	DEC	D		;D - 1
	JR	NZ,m4d84	;9 mal
	ADD	A,E		;Drive * 9 + letzte eingabe
	JR	NC,m4d77	;weiter suchen
m4d8d	LD	A,20h		;Fehlercode 'unz. oder fehl. Lw'
	JR	m4d4f		;raus mit Fehler

m4d91	CALL	m4cd5		;Zeichen in (HL) testen
	RET	C		;weder ENTER noch Komma oder Blank
m4d95	CALL	m5088		;Wenn 'P' auf Drucker umleiten
	JR	Z,m4d91		;weiter suchen
	CP	0dh
	JR	Z,m4de1		;ENTER ?
	CP	'A'		;DIR A
	JR	NZ,m4da6	;da weiter

;DIR A...
	SET	0,B		;Flag für 'A'
	JR	m4d91		;nächster Parameter

m4da6	CP	'S'		;mit SYSTEM Files
	JR	NZ,m4dae	;nein
	SET	1,B		;Flag 'S' (mit SYS)
	JR	m4d91

m4dae	CP	'I'		;Mit unsichtbaren ?
	JR	NZ,m4db6
	SET	2,B		;Flag 'I' (unsichtbar)
	JR	m4d91
m4db6	CP	'B'		;nur die die bearbeitet wurden
	JR	NZ,m4dbe
	SET	5,B		;Flag 'B' (nur verändert)
	JR	m4d91

m4dbe	CP	'/'		;best Extension ?
	JP	NZ,m4d4d
	SET	4,B		; Flag '/' (nur mit EXT)
	PUSH	BC
	LD	B,03h
	LD	DE,m5144	;Text '   DISK IN ?'
m4dcb	LD	A,(HL)		;Drive #
	SUB	30h		;=> binär
	CP	0ah
	JR	C,m4dd8
	SUB	0fh
	CP	1eh
	JR	NC,m4dde
m4dd8	LD	A,(HL)		;Zeichen der Extension
	LD	(DE),A		;in Puffer für Extension
	INC	DE
	INC	HL
	DJNZ	m4dcb
m4dde	POP	BC		;Flags zurück
	JR	m4d91		;weitere Parameter ?

;DIR endlich bearbeiten
m4de1	BIT	6,B		;Flag '$' (I 0 ohne SYS) ?
	JR	Z,m4dfe		;nein
	LD	A,C		;Drive #
	OR	A
	JR	NZ,m4dee	;niht Drive 0
	LD	A,0cdh		;Op-code CALL
	LD	(m4d53),A	;in Ausgaberoutine patchen
m4dee	PUSH	BC		;Flags retten
	LD	B,00h
	LD	HL,m514f	;eine Stelle nach '   DISK IN'
	CALL	m50e8
	POP	BC
	LD	HL,m5159	;Text 'DRIVE :'
	CALL	m4fbb		;augeben und 'DISK in 000 ?'
m4dfe	CALL	m4ff9		;normales DIR: Kopfzeile berechnen und ausgeben
	JP	NZ,m4d4f	;raus wenn Fehler
	XOR	A		;Directory Entry Code 0
	CALL	m4d44		;FED von DIR lesen (HL = Byte 0 von FED)
				;FED = File Directory Eintrag
	CALL	m50ae		;Blank u. CR anzeigen
	LD	D,(IY+0efh)	;(436F) Zeilen/Screen - 3(13 bei 64 und 22 bei 80 Z/Screen)
	CALL	m4fe5		;Test ob DIR,A und evtl Kopfzeile dafür ausgeben
	PUSH	DE
	LD	C,05h		;5 Files nebeneinander
	JP	m4f58		;da weiter

m4e17	PUSH	DE		;File bearbeiten und anzeigen
	PUSH	BC
	PUSH	HL
	EX	DE,HL		;DE = FDE (Byte 0 des FDE)
	LD	HL,m51b4	;'SIEFBMPB'
	LD	B,07h		;7 Zeichen
	PUSH	HL
m4e21	LD	(HL),'-'	;Flag ist nicht gesetzt
	INC	HL
	DJNZ	m4e21		;überall eintragen
	LD	A,(DE)		;Byte 0 des FDE => A
	AND	07h		;nur den Zugriffs Level
	ADD	A,30h		;in ASCII wandeln
	LD	(HL),A		;und in Ausgabestring eintragen
	POP	HL
	LD	A,(DE)		;wieder Byte 0 des FDE
	BIT	6,A		;SYS-File ?
	JR	Z,m4e34		;nein
	LD	(HL),'S'	;sonst Ausgabeflag setzten
m4e34	INC	HL		;nächste Ausgabestelle
	BIT	3,A		;unsichtbar ?
	JR	Z,m4e3b		;nein
	LD	(HL),'I'	;Flag setzen
m4e3b	INC	HL
	INC	DE		;Byte 1 des FDE
	LD	A,(DE)		;in den ACCU
	RLCA			;Platz reserviert ?
	JR	NC,m4e43	;wenn nicht: weiter
	LD	(HL),'E'	;Flag für Reserviert setzen
m4e43	INC	HL
	RLCA			;Platz freigeben ?
	JR	NC,m4e49	;weiter wenn nicht
	LD	(HL),'F'	;sonst Flag setzen
m4e49	INC	HL
	RLCA			;File bearbeitet ?
	JR	NC,m4e4f	;nein dann da weiter
	LD	(HL),'B'	;Bearbeitungs-Flag
m4e4f	LD	HL,m0004	;4 Byte Distanz
	ADD	HL,DE		;HL jetzt auf Byte 5 des FDE (NAME)
	LD	BC,m080d	;8 Zeichen filename 0D Zeichen gesamt
	CALL	m50c2		;B-Bytes ab (HL) anzeigen, ohne Blank
	LD	A,(HL)		;nächstes Byte des FDE (EXT)
	CP	' '
	JR	Z,m4e65		;wenn Extension leer ist
	LD	A,'/'		;Trennzeichen
	LD	B,04h		;mit / sind es 4 Zeichen
	CALL	m50c4		;4 Zeichen ohne Blank anzeigen
m4e65	LD	B,C		;Rest von 0D nach B
	CALL	m50ba		;B * Blank anzeigen
	PUSH	DE		;wird noch gebraucht
	LD	E,(HL)		;Byte 10 des FDE
	INC	HL
	LD	D,(HL)		;und 11 auch (Update Passwort)
	PUSH	DE
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		;Byte 12 und 13 (Access Passwort)
	LD	HL,m4296
	RST	18H
	JR	Z,m4e7d
	LD	A,'B'
	LD	(m51ba),A		;SIEFBM b P
m4e7d	POP	DE
	RST	18H
	JR	Z,m4e86
	LD	A,'H'
	LD	(m51b9),A		;SIEFB m BP
m4e86	POP	DE
	POP	HL
	POP	BC
	BIT	0,B		;Flag 'A' ?
	JR	NZ,m4e97	;ja: da weiter
	PUSH	BC
	LD	B,02h
	CALL	m50ba		;B * Blank anzeigen
	POP	BC
	JP	m4f45		;nächsten FDE bearbeiten

;DIR A (nachdem der Filename ausgegeben ist) Datum aus FDE holen
m4e97	PUSH	HL		;HL = FDE Byte 0
	PUSH	BC
	LD	A,(DE)		;Byte 1 des FDE
	AND	1fh		;nur Bit 0 - 4 (A => TAG)
	LD	HL,m51e8	;Puffer
	PUSH	AF
	INC	DE		;Byte 2 des FDE
	LD	A,(DE)		;nach ACCU => Monat und Jahr
	LD	(HL),A		;und in den PUFFER
	LD	A,05h		;
	RRD			;Monat in den ACCU (Puffer = 5x: d.h. das x. Jahr nach 80. Jahr = 1980 - 1995)
	INC	HL		;nächste Pufferstelle
	LD	(HL),A		;den Monat in den Puffer
	INC	HL
	POP	AF
	LD	(HL),A		;den Tag dahinter
	PUSH	HL
	POP	DE
	LD	HL,m518f		;'TT.MM.JJ'
	PUSH	HL
	CALL	m44c5		;Datum in Kopfzeile übertragen
	POP	HL
	CALL	m50b7		;String anzeigen
	POP	BC		;Flags zurück
	POP	HL		;Byte 0 des FDE
	LD	C,01h
	PUSH	BC
	PUSH	HL
	INC	HL
	INC	HL
	INC	HL
	LD	E,(HL)		;Byte 3. EOF
	LD	D,00h
	INC	HL
	LD	B,D
	LD	C,(HL)
	SET	4,L
	LD	A,(HL)
	INC	HL
	PUSH	HL
	LD	H,(HL)
	LD	L,A
	LD	A,E
	OR	A
	JR	Z,m4ed4
	DEC	HL
m4ed4	INC	C
	DEC	C
	JR	NZ,m4eda
	LD	B,01h
m4eda	PUSH	DE
	PUSH	HL
	PUSH	BC
	JR	NZ,m4ee2
	LD	E,L
	LD	L,H
	LD	H,D
m4ee2	CALL	NZ,m50d6
	OR	A
	JR	Z,m4eec
	INC	E
	JR	NZ,m4eec
	INC	HL
m4eec	LD	A,H
	LD	B,L
	LD	C,E
	LD	HL,m51a6	;' 00000000' Records
	LD	DE,m512f
	CALL	m50f1
	POP	BC
	LD	HL,m51a2	;' 000' Log. Rec. länge
	CALL	m50e8
	POP	BC
	LD	HL,m5198	;' 00000/000' EOF
	LD	DE,m5138
	CALL	m50f0
	LD	(HL),'0'
	POP	BC
	PUSH	HL
	CALL	m50e8
	POP	HL
	LD	(HL),'/'
	POP	HL
	INC	HL
	LD	BC,m0000
m4f18	LD	A,(HL)
	CP	0feh
	INC	HL
	JR	NC,m4f29
	INC	BC
	INC	HL
	BIT	4,L
	JR	NZ,m4f18
	LD	A,','
	JP	m4d4f		;zurück

m4f29	JR	NZ,m4f34
	LD	A,(HL)
	CALL	m4d47
	ADD	A,16h
	LD	L,A
	JR	m4f18

m4f34	CALL	m4d42
	LD	HL,m51af	;' 000 ' Erweiterungen
	CALL	m50e8
	LD	HL,m5198	;' 00000/000' EOF
	CALL	m50b7		;String anzeigen
	POP	HL
	POP	BC
m4f45	LD	A,L		;LSB des FDE
	ADD	A,20h		;Anfang des nächsten FDE
	LD	L,A		;zurück
	JR	NC,m4f58	;noch im gleichen Sektkorken
	LD	A,(m4d43)	;letzter DEC
	AND	1fh
	INC	A		;+ 1 für nächsten DIR-Sektor
	CP	00h		;hier wurde der letzte DIR-Sect. gepatcht
m4f52	EQU	$-1
	JR	Z,m4fd0		;Letzter Dir Sektor erreicht : ENDE
	CALL	m4d44		;nächsten FDE lesen im neuen Sektor
m4f58	LD	A,(HL)		;Byte 0 vom FDE
	AND	90h		;nur Bit 7 und 4
	CP	10h		;ist der FDE benutzt ?
	JR	NZ,m4f45	;dahin wenn nicht
	LD	A,B		;Flags
	AND	30h		;nur Bit 4 und 5 (/EXT oder 'B')
	JR	NZ,m4f75	;wenn einer von beiden
	BIT	6,(HL)		;SYS-File ?
	JR	Z,m4f6c		;nein
	BIT	1,B		;Flag 'S' (mit SYS) ?
	JR	m4f72		;da weiter

m4f6c	BIT	3,(HL)		;unsichtbar ?
	JR	Z,m4f75		;nein
	BIT	2,B		;Flag 'I' (unsichtbar) ?
m4f72	JP	Z,m4f45		;nein
m4f75	BIT	4,B		;Flag '/' (nur mit EXT) ?
	JR	Z,m4f95		;nein
	PUSH	HL
	PUSH	BC
	LD	DE,m000d	;Offset zur EXTENSION
	ADD	HL,DE		;zu HL dazu
	LD	DE,m5144	;da steht die EXT vom Aufruf
	LD	B,03h		;Länge
m4f84	LD	A,(DE)		;Zeichen laden
	CP	'?'		;steht da ein Platzhalter ?
	JR	NZ,m4f8a	;nein
	LD	A,(HL)		;Zeichen aus DEC holen (wird gleich mit sich selbst verglichen)
m4f8a	CP	(HL)		;Zeichen mit dem aus DEC vergleichen
	INC	DE
	INC	HL		;beide Zeiger erhöhen
	JR	NZ,m4f91	;wenn nicht gleich hier aushören
	DJNZ	m4f84		;bis alle 3 überprüft sind
m4f91	POP	BC
	POP	HL
	JR	NZ,m4f45	;wenn falsche Extension nächsten Eintrag bearbeiten
m4f95	BIT	5,B		;Flag 'B' (nur verändert) ?
	JR	Z,m4f9f		;nein
	INC	HL		;Byte 1 vom FDE
	BIT	5,(HL)		;File bearbeitet ?
	DEC	HL		;wieder auf Byte 0
	JR	Z,m4f45		;nächsten Eintrag wenn dieser nicht verändert
m4f9f	POP	DE
	DEC	C		;Files nebeneinander - 1
	JR	NZ,m4fb8	;wenn noch Platz ist
	LD	C,04h
	CALL	m50ae		;Blank u. CR anzeigen
	DEC	D
	JR	NZ,m4fb8
	CALL	m509b		;Screen full ? evtl. auf <CR> warten
	LD	D,(IY+0efh)	;(436F) Zeilen/Screen - 3
	INC	D
	INC	D
	BIT	3,B		;ausgabe auf Drucker ?
	CALL	Z,m4fe5		;wenn nein, Test ob 'A' und evtl Kopfzeile ausgeben
m4fb8	JP	m4e17		;nächsten Eintrag bearbeiten

m4fbb	CALL	m4467		;Anzeigen
	LD	HL,m5147	;Text 'DISK in 000 ?'
	CALL	m4467		;Anzeigen
m4fc4	CALL	m0049		;Auf Eingabe warten
	DEC	A		;'BREAK' ?
	JP	Z,m402d		;ja, zurück ins DOS
	CP	0ch		;<ENTER> ?
	JR	NZ,m4fc4	;nein, weiter warten
	RET

m4fd0	CALL	m50ae		;Blank u. CR anzeigen
	POP	AF
	CP	04h
	CALL	C,m509b		;Screen full ?
m4fd9	LD	A,(m50d1)	;Ausgabeadresse
	CP	3bh		;ist es Drucker
	CALL	Z,m50ae		;Blank u. CR anzeigen wenn Drucker
	XOR	A
	JP	m4d4f		;zurück

m4fe5	BIT	0,B		;Flag 'A' ?
	RET	Z		;zurück wenn nicht
	PUSH	HL
	PUSH	BC
	DEC	D
	LD	B,0fh		;Zähler
	CALL	m50ba		;B * Blank anzeigen
	LD	HL,m51bd	;Text 'Datum:    EOF   Log  ...'
	CALL	m50b7		;String anzeigen
	POP	BC
	POP	HL
	RET

m4ff9	LD	A,C		;Drive #
	CALL	m47ec		;Motor on und Test 'Disk in ?'
	RET	NZ		;not ready
	PUSH	BC
	LD	B,00h
	LD	HL,m515f	;1. Stelle vor Drive # im Ausgabetext
	CALL	m50e8		;Drive # eintragen
	LD	A,(m430d)	;Anzahl Tracks (SP)
	LD	C,A		;nach C
	LD	B,00h
	LD	HL,m5164	;' 000 Sp.'
	CALL	m50e8		;Spuren eintragen
	XOR	A
	CALL	m490a		;Sector (A) des Directorys lesen (hier 0)
	JR	NZ,m5086	;wenn Fehler
	LD	BC,m0000
m501c	LD	E,(IY+8fh)	;Grans pro Lump (akt. Drive) (Einh./Block)
	LD	A,(HL)
	INC	HL
m5021	RRCA
	JR	C,m5025
	INC	BC
m5025	DEC	E
	JR	NZ,m5021
	LD	A,L
	CP	(IY+8bh)	;Blockanzahl der Diskette
	JR	C,m501c
	PUSH	BC		;(Freie Einheiten)
	POP	HL		;nach HL
	LD	A,(m4cb3)	;SEC pro Einheit
	CALL	m4c94		;HL * A (HL = freie Sektkorken)
	LD	A,H
	LD	B,L
	LD	C,00h		;* 256 (ABC = Freie Byte)
	LD	HL,m5174		; 00000000 Bytes '
	LD	DE,m512f
	CALL	m50f1
	LD	HL,m42d0	;Diskname im DIR-Sektor
	LD	DE,m5185	;'DISKNAME'
	LD	BC,m0008	;Länge
	LDIR			;Namen übertragen
	LD	DE,m518f	;'TT.MM.JJ'
	LD	C,08h		;Länge
	LDIR			;-Datum übertragen
	LD	A,01h		;DIR-Sektor 1
	CALL	m490a		;Sector (A) des Directorys lesen
	JR	NZ,m5086	;raus mit Fehler
m505c	LD	A,(m421f)	;Länge des DIR-Feldes-0A (Sektoren)
	ADD	A,08h		;Länge-2 (Sect. mit DIR-Einträgen)
	LD	E,A
	LD	(m4f52),A	;letzter DIR-Sector, da patchen
m5065	LD	A,(HL)
	OR	A
	INC	HL
	JR	NZ,m506b
	INC	BC
m506b	DEC	E
	JR	NZ,m5065
	LD	A,L
	ADD	A,1fh
	AND	0e0h
	LD	L,A
	JR	NZ,m505c
	LD	HL,m516c	;' 000 FED'
	CALL	m50e8
	LD	HL,m515a	;'Drive:   '
	CALL	m50b7		;String anzeigen
	CALL	m50ae		;Blank u. CR anzeigen
	XOR	A
m5086	POP	BC
	RET

;Test ob Option 'P' angegeben und evtl. die Ausgabe umlegen
m5088	LD	A,(HL)		;Zeichen aus Befehlsstring
	CP	'P'		;ist es P ?
	INC	HL		;nächstes Zeichen
	RET	NZ		;kein Drucker
	LD	A,3bh		;Adreß-LSB Druckertreiber (003bh)
	LD	(m50d1),A	;da patchen (in die Ausgaberoutine)
	LD	A,6ah		;dto. 446ah
	LD	(m50b8),A	;patchen
	SET	3,B		;Flag für Drucker setzen
	LD	A,(HL)		;nächstes Zeichen des Befehlstrings
	RET

;Test ob Bildschirm voll ist
m509b	BIT	5,(IY+0e9h)	;ist Chaining aktiv ?
	RET	NZ		;zurück wenn Chaining aktiv
	LD	A,(m50d1)	;Flag für Ausgabe (Screen/Printer)
	CP	'3'		;ist es Screen ?
	RET	NZ		;nein, bei Drucker weitermachen

;************************************************************************
	LD	A,'?'
	CALL	m50ce		;anzeigen
;************************************************************************

	CALL	m4fc4		;auf CR warten (Abbruch bei Break)
;Blank und CR anzeigen
m50ae	LD	A,' '		;Blank => A
	CALL	m50ce		;anzeigen
	LD	A,0dh		;CR => A
	JR	m50ce		;auch anzeigen und weiter

;String auf Drucker oder Schirm ausgeben
m50b7	JP	m4467		;Anzeigen und zurück
m50b8	EQU	$-2		;Drucker oder Schirm, je nach dem

;B * Blank anzeigen
m50ba	LD	A,' '		;Blank => A
	CALL	m50ce		;anzeigen
	DJNZ	m50ba		;B *
	RET

;B- Bytes ab (HL) anzeigen (Blanks nicht ausgeben)
m50c2	LD	A,(HL)		;Zeichen nach A
	INC	HL		;Zeiger auf nächstes Zeichen
m50c4   CALL	m50ca		;Accu anzeigen, Blanks nicht
	DJNZ	m50c2		;B *
	RET

;Accu anzeigen wenn nicht Blank
m50ca	CP	' '		;ist es Blank ?
	RET	Z		;ja, dann zurück
	DEC	C		;Zeichenzähler - 1
;Accu anzeigen
m50ce	PUSH	DE
	PUSH	AF
	CALL	m0033		;auf Screen oder Drucker ausgeben
m50d1	EQU	$-2		;Drucker oder Screen
	POP	AF
	POP	DE
	RET

m50d6	LD	B,18h
	XOR	A
m50d9	SLA	E
	ADC	HL,HL
	RLA
	JR	C,m50e3
	CP	C
	JR	C,m50e5
m50e3	SUB	C
	INC	E
m50e5	DJNZ	m50d9
	RET

m50e8	LD	DE,m513e
	JR	m50f0

	LD	DE,m513b
m50f0	XOR	A
m50f1	PUSH	DE
	PUSH	HL
	PUSH	BC
	EX	DE,HL		;HL = Adresse der Daten
	LD	E,(HL)		;DE = Datenwert
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	C,(HL)
	LD	B,'/'
	POP	HL
m50fd	INC	B
	ADD	HL,DE
	ADC	A,C
	JR	C,m50fd
	OR	A
	SBC	HL,DE
	SBC	A,C
	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)
	SUB	'0'
	CP	0ah
	INC	HL
	LD	(HL),B
	JR	C,m5118
	LD	A,B
	CP	'0'
	JR	NZ,m5118
	LD	(HL),' '
m5118	LD	A,E
	CP	0f6h		;Letzter Datensatz erreicht ?
	JR	Z,m5125		;falls ja
	POP	AF
	POP	BC
	POP	DE		;Adresse der Daten
	INC	DE
	INC	DE
	INC	DE		;auf nächstes Datentripple
	JR	m50f1		;weitermachen

m5125	POP	DE
	POP	BC
	POP	DE
	INC	HL
	LD	A,C		;akt. Drive #
	ADD	A,'0'		;=> ASCII
	LD	(HL),A		;in den Text
	INC	HL		;auf nächste Textstelle
	RET

m512f	ADD	A,B
	LD	L,C
	LD	H,A
	RET	NZ
	CP	L
	RET	P
	LD	H,B
	LD	A,C
	CP	0f0h
m5138	EQU	$-1
m5139	RET	C
	RST	38H
m513b	JR	m5139
	RST	38H

m513e	SBC	A,H
	RST	38H
	RST	38H
	OR	0ffh
	RST	38H
m5144	DEFM	'   DISK IN  000?',0dh
m514f	EQU	$-6
m5155	DEFM	'DOS-',03h
m5159 EQU	$-1
m515a	DEFM	'Drive:000 '		;Drive #
m5164	DEFM	' 000 Sp.'		;Spuranzahl
m516c	DEFM	' 000 FED'		;Freie Einträge
m5174	DEFM	' 00000000 Bytes '	;Freier Platz
m5184	DEFB	'('
m5185	DEFM	'DISKNAME) '		;Diskettenname
m518f	DEFM	'TT.MM.JJ',03h		;Datum und Ende


m5198	DEFM	' 00000/000'		;EOF
m51a2	DEFM	' 000'			;Log. Recordlänge
m51a6	DEFM	' 00000000'		;Records
m51af	DEFM	' 000 '			;Erweiterungen
m51b4	DEFM	'SIEFBMPB',03h		;Ende
m51b8	EQU	$-5
m51b9	EQU     $-4
m51ba	EQU	$-3


m51bd	DEFM	'Datum:      EOF: log Records: '
	DEFM	'E.: SBIEFBMBP',0dh
mffff	EQU	0ffffh
	END	4d00h
