;
	LIST {A0}
;	am 29.02.92 geändert : Befehl H  eingefügt
;				addiert und subtr. integerwerte
;				wird in sys29 abgearbeitet
;	am	03.03.92 geändert: ON  HRG ein
;				 : OFF HRG aus
;				 : PARK Harddisk auf Spur 612
;				 (Alles in sys29 erledigen)
;	irgendwann so die Zeit :
;		CD => Change Directory
;			wechselt das DOS-Prompt und Schreiblaufwerk
;			sowie das DIR-Laufwerk ohne LW-Spezifikation.
;			wird ii SYS24/SYS erledigt
;
;
;	SYS1/SYS, rekonstruiert und verändert (wenn Label new EQU 1)

new	EQU	1	;1: es gelten die Veränderungen; 0: nicht

m0033	EQU	0033h	;UP Akku auf dem Bildschirm anzeigen
m0040	EQU	0040h	;UP B Zeichen nach (HL) ff. einlesen
m4022	EQU	4022h	;im Video-DCB Flag für Cursorstatus: an/aus
m402d	EQU	402dh	;Einsprung für DOS-Ready
m41e0	EQU	41e0h	;Ausgangsadresse für den DOS-Stack
m4200	EQU	4200h	;DOS-Sektorpuffer
m4312	EQU	4312h	;BREAK-Vektor (RST 28h, A<20h)
m4318	EQU	4318h	;DOS-Eingabepuffer
m436a	EQU	436ah	;verschiedene Flags für Betriebszustände des DOS:
			;Bit 7: Mini-DOS, Bit 6: DOS-CALL
			;Bit 5: ???,	  Bit 4: Chaining unter DOS-CAll
			;Rest hier nicht von Belang
m436b	EQU	436bh	;wird von SYS6 für CLOSE und EXPAND manipuliert
m436c	EQU	436ch	;weitere Flags:
			;Bit 6: RUN-ONLY-Modus
			;R. h. n. v. B.
m436d	EQU	436dh	;weitere Flags:
			;Bit 5: SYSTEM-Option BE (R-Befehl erlaubt?)
			;R. h. n. v. B.
m439b	EQU	439bh	;Puffer für den Stackpointer
m439d	EQU	439dh	;dto.
m43a7	EQU	43a7h	;Puffer für erste beide Zeichen einer Eingabe
m4408	EQU	4408h	;Fehleraussprung (gleich RET bei "kein Fehler")
m4420	EQU	4420h	;UP INIT, gegf. neues File anlegen
m4424	EQU	4424h	;UP OPEN, gegf. kein neues File anlegen
m4467	EQU	4467h	;UP Text (HL) auf den Bildschirm ausgeben
m4480	EQU	4480h	;FCB zum Laden und Starten von Benutzerprogrammen
m45b0	EQU	45b0h	;Forts.-adr. je nach SYSTEM,BG oder DOS-Befehl LC
m45b5	EQU	45b5h	;UP wandelt Klein- in Großbuchstaben um
m49d3	EQU	49d3h	;UP zum Laden von SYS-Files (raus bei Fehler)
m49d6	EQU	49d6h	;dto., setzt selbst Flag "kein Fehler"
m4cc5	EQU	4cc5h	;UP Vergleich zweier Texte (HL) und (BC)
m4cd5	EQU	4cd5h	;UP Prüfung auf CR, Komma und Blank
m4cd9	EQU	4cd9h	;UP Prüfung auf Komma und Blank

	ORG	4d00h
	sys1
	IF	NOT,new
	CP	23h	;Aufruf aus SYS1 und 4400: DOS-Ready
	JP	Z,m4d8a
	ENDIF
	CP	43h	;DOS-Ready, Ende v. Chaining bei aufgetr. Fehler
	JR	Z,m4d7c
	CP	63h	;DOS-Befehl ausführen, nicht zum Aufrufer zurück
	JP	Z,m4e30
	CP	83h	;Filespec. aus (HL) nach (DE) übertragen
	JP	Z,m5155
	CP	0a3h	;Default-Extension anfügen, falls keine gegeben
	JP	Z,m4f2a
	CP	0c3h	;DOS-Befehl ausführen, Rückkehr zum Aufrufer
	JR	Z,m4d5b
	IF	new
	CP	23h	;Aufruf aus SYS1 und 4400: DOS-Ready
	JR	Z,m4d8a
	ENDIF
;beim Requestcode E3 bestimmt der Entry-Zähler die Zieladresse:
	DEC	C	;C = 1?
	IF	NOT,new
	JR	Z,m4d59	;ja: nur POP AF und RET bei Ansprung aus m4d4e
	ENDIF
	DEC	C	;2
	JP	Z,m50cf	;LIB bzw. ?
	DEC	C	;3
	IF	NOT,new
	JP	Z,m4d32	;verbotener Code (Aussprung mit Fehlerbedingung)
	ENDIF
	DEC	C	;4
	JP	Z,m50f3	;Mini-DOS ready
	DEC	C	;5
	JR	Z,m4d80	;MDBORT bzw. /
	DEC	C	;6
	JP	Z,m5112	;MDRET bzw. ;
m4d32	DEC	C	;7
	JR	Z,m4d78	;???
	DEC	C	;8
	JP	Z,m4e34	;Einsprung nach beliebiger Eingabe (z. B. Befehl)
	DEC	C	;9
	IF	NOT,new
	JR	Z,m4d48	;CLS
	ENDIF
	DEC	C	;10
	DEC	C	;11
	JP	Z,m5168	;Eingabe in den FCB schreiben
	DEC	C	;12
	JR	Z,m4d80	;MDBORT bzw. /

illfnct	LD	A,2ah	;sonst Fehlercode "unzulässige DOS-Funktion"
	OR	A	;Flag NZ zur Fehlerausgabe
	RET		;raus mit Fehlerbedingung

	IF	NOT,new
m4d48	LD	HL,m51f2	;Codes für CLS
	JP	m4467		;Bildschirm löschen und zurück

;Anspr. nicht aus SYS1. Vielleicht anderswoher? Dann feste Adresse 4D4E!
m4d4e	EXX			;Register retten
	LD	BC,0e3h*256+01h	;hat nur RET-Funkion (B <- SYS1, C=1)
	LD	DE,m49d3	;Routine zum Aufruf von SYS-Files
	PUSH	BC		;Requestcode usw. auf den Stack
	PUSH	DE		;dto. Ansprungsadresse
	EXX			;Register restaurieren
	RST	28H		;SYS1 anspringen, POP AF und RET
;	und zwar gleich hier:
m4d59	POP	AF
	RET

	ENDIF
;DOS-Befehl ausführen, zum Aufrufer zurückkehren
m4d5b	CALL	pushreg		;alle Register retten
	LD	BC,0000h
	EX	DE,HL		;DE <- Adresse des Befehls
	LD	HL,m436a	;versch. Flags
	BIT	6,(HL)		;ist DOS-CALL aktiv?
	SET	6,(HL)		;als aktiv kennzeichnen
	JR	Z,m4d6f		;falls bisher nicht aktiv
	LD	BC,(m439d)	;Zwischenspeicher für SP unter DOS-CALL
m4d6f	PUSH	BC		;retten
	LD	(m439d),SP	;SP zwischenspeichern
	EX	DE,HL
	JP	m4e35

m4d78	POP	AF		;Stack bereinigen
	POP	AF		;Flags vom Stack holen
	JR	m4d8b		;dort weiter

;Einsprung bei angezeigtem Fehler, gegf. Chaining beenden
m4d7c	XOR	A		;Z-Flag setzen
	SCF			;dto. Cy
	JR	m4d8b		;dort weiter

;Einsprung nach / bzw. MDBORT
m4d80	LD	HL,m436a	;versch. Flags
	LD	A,(HL)		;laden
	AND	2fh		;nur Bits 0-3, 5 (kein Sonderstatus mehr)
	LD	(HL),A		;neu ablegen
	DEC	HL		;4369: andere Flags
	RES	5,(HL)		;Chaining nicht mehr aktiv

;DOS-Ready-Einsprung
m4d8a	XOR	A		;A <- 00, Z-Flag setzen
m4d8b	DI
	LD	HL,m436b	;zur Manipulation von CLOSE und EXPAND
	LD	(HL),00h
	DEC	HL		;436A: versch. Flags
	LD	B,(HL)		;laden
	DEC	HL		;4369: andere Flags
	LD	C,(HL)		;dto.
	LD	E,0bh		;Zeiger auf "Fat. DOS-F." in SYS9
	PUSH	AF		;Flags retten
	BIT	2,B		;"Fataler DOS-Fehler?"
	JR	NZ,entsys9	;falls ja
	POP	AF
	PUSH	AF
	JR	C,m4da2
	JR	Z,m4dac
m4da2	CP	38h		;Fehler "keine Mini-DOS-Fkt."?
	JR	Z,m4dac		;falls ja
	LD	E,04h		;Zeiger auf Chaining-Aufruf in SYS9
	BIT	5,C		;ist Chaining aktiv?
	JR	NZ,entsys9	;falls ja
m4dac	RES	6,(HL)		;Chaining usw. nicht mehr gesperrt
	BIT	6,B		;ist DOS-CALL aktiv?
	JR	NZ,m4e10	;falls ja
	LD	A,(m436c)	;div. Flags
	BIT	6,A		;RUN-ONLY-Modus?
	JR	Z,m4dc4		;falls nein
	BIT	5,C		;ist Chaining aktiv?
	JR	NZ,m4dc4	;falls ja
	LD	E,0ch		;bewirkt Aufhebung von RUN-ONLY in SYS9
entsys9	LD	D,0ebh		;Requestcode für SYS9/SYS
	LD	A,D		;nach A
	LD	C,E		;Zeiger in SYS9 nach C
	RST	28H		;weiter in SYS9
m4dc4	BIT	7,B		;ist Mini-DOS aktiv?
	JR	NZ,m4ddc	;falls ja
	LD	SP,m41e0	;SP auf "Nullwert" setzen
	BIT	5,A		;Behandlung der BREAK-Taste
	LD	HL,m45b0	;Ansprungsadresse für BREAK-Vektor
	LD	(m4312+1),HL
	LD	A,0c3h		;JP-Opcode
	JR	Z,m4dd9
	LD	A,0c9h		;sonst RET-Opcode
m4dd9	LD	(m4312),A
m4ddc	LD	HL,dosprpt
	BIT	7,B		;ist Mini-DOS aktiv?
	JR	Z,m4dea		;falls nein
	LD	SP,(m439b)
	LD	HL,minprpt
	IF	NOT,new
m4dea	EI
	LD	A,0bh		;LF
	CALL	m0033		;ausgeben
	ENDIF
	IF	new
m4dea	CALL	m51b4		;EI, LF ausgeben
	ENDIF
	BIT	5,C
	CALL	Z,m4467		;(Mini-) Prompt anzeigen, falls nein
	LD	HL,m436a
	SET	5,(HL)
	LD	BC,0e3h*256+08h	;Entry 8 in SYS1
	LD	DE,m49d6	;Routine zum Aufruf von SYS-Files
	PUSH	BC		;Requestcode und Entry-Nr. auf den Stack
	PUSH	DE		;dto. Ansprungsadresse
	LD	HL,(m4318)	;erste beide Zeichen des Befehls
	LD	(m43a7),HL	;für Befehl R puffern
	LD	B,4fh		;max. 79 Zeichen
	LD	HL,m4318	;DOS-Eingabepuffer
	JP	m0040		;neue Eingabe holen, zurück bei Entry 8
m4e10	POP	DE
	LD	SP,(m439d)
	BIT	5,C
	JR	Z,m4e1d
	BIT	4,B
	JR	NZ,m4ddc
m4e1d	POP	BC
	LD	A,B
	OR	C
	JR	NZ,m4e25
	INC	HL
	RES	6,(HL)
m4e25	RES	4,(HL)
	LD	(m439d),BC
	PUSH	DE
	POP	AF
	JP	popreg		;alle Register restaurieren und zurück

;DOS-Befehl ausführen, keine Rückkehr zum Aufrufer
	IF	NOT,new
m4e30	LD	SP,m41e0	;Stack neu einrichten
	PUSH	AF		;weil gleich POP AF kommt
	ENDIF
	IF	new
m4e30	LD	SP,m41e0-2	;Stack neu einrichten (-2 wegen POP AF)
	ENDIF
;DOS-Befehl ausführen
m4e34	POP	AF		;Stack berein. (gegf. CALL-Ebene löschen)
m4e35	LD	BC,m402d	;DOS-Ready-Entry
	LD	DE,m4408	;DOS-Error-Entry
	PUSH	BC		;als RET-Adresse auf den Stack
	PUSH	DE		;dto.
	EX	DE,HL		;DE <- Adresse der Eingabe (4318)
	LD	HL,m436a
	RES	5,(HL)
	LD	HL,m4318	;DOS-Eingabepuffer
	LD	B,50h		;max. 80 Zeichen
	LD	A,(HL)		;Zeichen laden
	CP	0dh		;CR?
	RET	Z		;zurück zu DOS-Ready, falls ja
	PUSH	HL		;Pufferadresse
m4e4d	LD	A,(DE)		;ein Zeichen des Befehls
	INC	DE		;nächste Stelle
	CALL	m45b5		;in Großbuchstaben umwandeln
	CP	0dh		;CR?
	LD	(HL),A		;Zeichen zurück in den Puffer
	INC	HL		;nächste Stelle
	JR	Z,m4e5f		;falls CR angetroffen
	DJNZ	m4e4d		;bis max. 80 Zeichen umgewandelt
	POP	AF		;Stack bereinigen
	LD	A,36h		;Fehlercode "Befehl zu lang"
	OR	A		;NZ-Flag (Fehlerflag)
	RET			;raus über DOS-Error-Entry
m4e5f	LD	A,(m436d)	;div. Flags
	BIT	5,A		;DOS-Befehl R erlaubt?
	JR	Z,m4e75		;falls nein
	LD	HL,(m4318)	;erste zwei Zeichen laden
	LD	DE,256*0dh+'R'	;Befehl R<CR> für Befehlswiederholung
	RST	18H		;ist es R<CR>?
	JR	NZ,m4e75	;falls nein
	LD	HL,(m43a7)	;erste beiden Z. des früheren Befehls
	LD	(m4318),HL	;in den Eingabepuffer
m4e75	POP	HL		;Befehlszeiger
	LD	DE,cmdtab	;Zeiger auf Tabelle der Library-Befehle
m4e79	PUSH	HL		;retten
m4e7a	LD	A,(DE)		;Zeichen eines DOS-Befehls
	CP	(HL)		;identisch mit einem eingegebenen Z.?
	INC	DE		;nächste Stelle in der Tabelle
	INC	HL		;dto. im Befehl
	JR	Z,m4e7a		;weiter vergleichen, falls gleich
	DEC	HL		;ungleich, Befehlszeiger -1
	DEC	DE		;dto. Tabellenzeiger
	RLCA			;Bit 7 gesetzt?
	JR	NC,m4e8a	;falls nein (Befehlswort nicht zuende)
	CALL	m4cd5		;nächstes Zeichen des Befehlsstrings
	JR	NC,m4ea7	;falls Trenn- oder Endzeichen
m4e8a	POP	HL		;Befehlszeiger
m4e8b	LD	A,(DE)		;letztes Zeichen des Befehlsworts
	RLCA			;Cy <- Bit 7
	INC	DE		;auf Entry-Zähler
	JR	NC,m4e8b	;falls Entry-Z. noch nicht erreicht war
	INC	DE		;auf Kennbyte für Verwendbarkeit
	INC	DE		;auf nächstes Befehlswort
	LD	A,(DE)		;dessen 1. Zeichen
	OR	A		;00? (Tabelle zuende)
	JR	NZ,m4e79	;weitersuchen, falls noch nicht
	LD	BC,0e4h*256+43h	;Requestcode für SYS2, Entry 3
	LD	D,41h		;kennzeichnet gewöhnliches CMD-File
	LD	A,(HL)		;Zeichen des eingegebenen Befehls
	CP	'*'		;soll Benutzerroutine aufgerufen werden?
	JR	NZ,m4eb0	;gewöhnlicher Programmaufruf, falls nein
	LD	A,0ebh		;Requestcode für SYS9/SYS
	LD	C,07h		;Zeiger für Aufruf von Benutzerroutinen
	RST	28H		;SYS9 anspringen und bearbeiten
errexit	POP	BC		;Stack bereinigen
	RET			;raus mit Fehlerbedingung
m4ea7	POP	BC		;Stack bereinigen
	LD	A,(DE)		;Entry-Zähler
	LD	C,A		;nach C
	INC	DE		;auf Requestcode
	LD	A,(DE)		;laden
	LD	B,A		;nach B
	INC	DE		;auf Kennbyte für Anwendbarkeit
	LD	A,(DE)		;laden
	LD	D,A		;nach D
m4eb0	BIT	6,C		;unter Mini-DOS verboten?
	JR	Z,m4ec3		;falls nein
	LD	A,(m436a)	;prüfen, ob Mini-DOS aktiv ist
	RLCA			;Bit 7 gesetzt? (Mini-DOS aktiv)
	JR	NC,m4ec3	;falls nein
	AND	80h		;Bit 7 isolieren (ehem. Bit 6, DOS-CALL)
	LD	A,38h		;Fehlercode "keine Mini-DOS-Funktion"
	JP	NZ,m4d8b	;falls DOS-CALL aktiv ist
	OR	A		;NZ-Flag setzen (Fehlerflag)
	RET			;raus und Fehler anzeigen
m4ec3	LD	A,C		;Entry-Zähler
	AND	1fh		;nur Zeiger-Bits
	LD	C,A		;zurück nach C
	PUSH	BC		;retten (Requestcode in B)
	LD	C,D		;C <- Kennbyte für Anwendbarkeit
	LD	A,C		;A <- dto.
	AND	0c0h		;andere Bits (s. o.) des Zeigers
	CALL	NZ,m5165	;gegf. Filenamen in den FCB übertragen
	JR	NZ,noname	;falls kein erlaubter Filename
	BIT	5,C		;2. Dateiname erforderlich?
	JR	Z,m4ef5		;falls nein
	CALL	m4cd9		;nächstes Zeichen des Befehls einlesen
	JR	C,errexit	;Fehler, falls kein Trennzeichen
	PUSH	BC		;retten
	LD	BC,to		;Text TO
	CALL	m4cc5		;TO im Befehl?
	POP	BC
	JR	NZ,m4ee9	;falls nein
	CALL	m4cd9		;nächstes Zeichen einlesen
	JR	C,errexit	;Fehler, falls kein Trennzeichen
m4ee9	PUSH	DE
	LD	DE,fcb		;Puffer für Befehl (für 2. FCB)
	CALL	m5168		;Filenamen in den 2. FCB schreiben
	POP	DE
noname	LD	A,30h		;Fehlercode "kein Dateiname"
	JR	NZ,errexit	;falls dieser Fehler aufgetreten ist
m4ef5	BIT	4,C		;muß der Befehl hier zuende sein?
	CALL	NZ,m4cd5	;gegf. nächstes Zeichen einlesen
	JR	NZ,errexit	;falls kein CR folgt
	BIT	3,C
	JR	Z,m4f02		;falls nein
	EX	(SP),HL		;HL retten, HL <- RET-Adresse
	PUSH	HL		;für RET auf den Stack
m4f02	LD	A,C		;xxxx.x000: keine Extension
				;xxxx.x001: Ext. /CMD
				;xxxx.x010: Ext. /JOB
	AND	07h		;relevante Bits isolieren
	JR	Z,m4f15		;falls Ext. nicht zwingend notwendig
	PUSH	HL
	LD	HL,defext-3	;3 Stellen vor Default-Extension /CMD
m4f0b	INC	HL		;3 Stellen weiter (3 Zeichen pro Ext.)
	INC	HL
	INC	HL
	DEC	A		;herunterzählen
	JR	NZ,m4f0b	;falls /JOB
	CALL	m4f2a		;Default-Extension anhängen
	POP	HL
m4f15	LD	A,C
	LD	BC,m49d3	;Routine zum Aufruf von SYS-Files
	PUSH	BC		;als RET-Adresse auf den Stack
	BIT	7,A
	RET	Z
	LD	B,00h		;LRL = 256
	LD	HL,m4200	;Sektorpuffer
	BIT	6,A		;muß gegf. neues File angelegt werden?
	JP	Z,m4424		;File öffnen, falls nein
	JP	m4420		;File öffnen, gegf. neu anlegen

;Default-Extension anhängen, falls keine eigegeben wurde (CMD, JOB)
m4f2a	PUSH	DE		;retten
	PUSH	BC
	LD	BC,09h*256+1ch	;B <- Länge Filename, C <- max. 28 Z.
m4f2f	LD	A,(DE)		;Zeichen des Namens
	CP	':'		;Lw#?
	JR	Z,m4f3e		;falls ja
	CP	'/'		;folgt EXT?
	JR	C,m4f3e		;falls nein (kleineres Zeichen, z. B. CR)
	JR	Z,m4f55		;falls ja
	DEC	C		;Zeichenzähler herunterzählen
	INC	DE		;auf nächstes Zeichen stellen
	DJNZ	m4f2f		;max. 9 Zeichen prüfen (Name + CR)
m4f3e	INC	HL		;Pufferzeiger weiterstellen
	INC	HL
	PUSH	HL
	EX	DE,HL		;HL <- Befehlszeiger
	LD	B,00h		;MSB = 00
	ADD	HL,BC		;HL <- Ende des Befehls
	LD	D,H		;nach DE
	LD	E,L
	DEC	HL		;Stelle davor
	INC	DE		;3 Stellen dahinter
	INC	DE
	INC	DE
	LDDR			;Filenamen um 4 Stellen weiterschieben
	POP	HL		;Pufferzeiger
	LD	C,03h		;3 Zeichen für EXT
	LDDR			;EXT einkopieren
	LD	A,'/'		;Trennzeichen davor
	LD	(DE),A		;hinter den Filenamen
m4f55	POP	BC		;restaurieren
	POP	DE
	RET

;	Tabelle der LIB-Befehle
;
;	1. Byte:	Bit 7 als Endmarkierung des Befehlsworts
;			Bit 6=1: unter Mini-DOS nicht erlaubt
;			Rest: Entry-Counter
;	2. Byte:	Request-Code für RST28 (Zeiger auf SYS-File)
;	3. Byte:	Bit 0=1: /CMD anfügen
;			Bit 1=1: /JOB anfügen
;			Bit 4=1: Ende prüfen
;			Bit 5=1: 2 Filespec auswerten
;			Bit 6=1: neues File öffnen
;			Bit 6=0: File öffnen
;			Bit 7=1: Overlay laden

cmdtab	DEFM	'AIK',80h,53h,00h
	DEFM	'APPEND',0c0h,68h,00h
	DEFM	'ATTRIB',85h,0e9h,88h
	DEFM	'AUTO',84h,0e9h,00h
	IF	NOT,new
	DEFM	'B2',86h,0ebh,00h
	ENDIF
	DEFM	'BL',81h,0e5h,00h
	DEFM	'BOOT',8ah,0ebh,10h
	DEFM	'BREAK',85h,0e5h,00h
	IF	new			; CD Change Directory eingefügt
	DEFM	'CD',82h,0fah,00        ; in SYS24/SYS
	ENDIF
	DEFM	'CLS',80h,0a6h,00h
	DEFM	'CONT',0c5h,0ebh,00h
	IF	NOT,new
	DEFM	'COPY',0c0h,48h,00h
	ENDIF
	DEFM	'CREATE',82h,0f0h,40h
	DEFM	'DATUM',8bh,0e9h,00h
	DEFM	'DDE',81h,0f1h,00h
	IF	NOT,new
	DEFM	'DIR',80h,2ah,00h
	ENDIF
	DEFM	'DISK',83h,0ffh,00h
	DEFM	'DO',0c3h,0ebh,8ah
	DEFM	'DR',82h,0feh,00h
	DEFM	'DUMP',87h,0e9h,0c8h
	DEFM	'E',87h,0f0h,00h
	DEFM	'FORM',88h,0feh,00h
	DEFM	'FREE',80h,4ah,00h
	DEFM	'F#',80h,0fbh,00h
	IF	new
	DEFM	'H',84h,0ffh,00h      ;neu von Volker
	ENDIF
	DEFM	'HIMEM',82h,0e9h,00h
	DEFM	'I',80h,2ah,00h
	DEFM	'INFO',81h,0ffh,00h
	DEFM	'JKL',80h,7ch,10h
	DEFM	'KILL',80h,45h,90h
	DEFM	'LC',88h,0e5h,00h
	DEFM	'LF',81h,0feh,00h
	IF	NOT,new
	DEFM	'LIB',82h,0e3h,00h
	ENDIF
	DEFM	'LIST',85h,0f0h,88h
	DEFM	'LOAD',80h,0a4h,50h
	DEFM	'M>',82h,0ebh,0b0h
	DEFM	'N',81h,0e4h,0b0h
	DEFM	'NDF',0c0h,28h,00h
	IF	new
	DEFM	'ON',85h,0ffh,00h	;HRG-Schirm ein
	DEFM	'OFF',86h,0ffh,00h	;HRG-Schirm aus
	DEFM	'PARK',87h,0ffh,00h	;Park Harddisk
	ENDIF				; neu von Volker
	DEFM	'PAUSE',88h,0ebh,00h
	DEFM	'PD',83h,0e9h,00h
	DEFM	'PIO',80h,9ch,00h
	DEFM	'PORT',82h,0ffh,00h
	DEFM	'PRINT',86h,0f0h,88h
	DEFM	'PROT',86h,0e9h,00h
	DEFM	'PURGE',89h,0e9h,00h
	DEFM	'R',80h,23h,00h
	DEFM	'S',81h,0e9h,00h
	IF	NOT,new
	DEFM	'SIO',80h,0bch,00h
	ENDIF
	IF	new			; geänderte SIO-Routine
	DEFM	'SIO',81h,0fah,00h	; jetzt in SYS24
	ENDIF
	DEFM	'STMT',89h,0ebh,00h
	IF	new
	DEFM	'SYS',80h,86h,00h
	ENDIF
	DEFM	'UHR',82h,0e5h,00h
	DEFM	'V+',84h,0e5h,00h
	DEFM	'Z',81h,0f8h,00h
	DEFM	'ZEIT',8ah,0e9h,00h
	DEFM	'ZL',82h,0f8h,88h
	DEFM	'0',84h,0f0h,00h
	DEFM	'64',81h,98h,00h
	DEFM	'80',82h,98h,00h
	DEFM	'!',83h,0ebh,8ah
	DEFM	'##',83h,98h,00h
	DEFM	'&',83h,0e5h,00h
	DEFM	'@',81h,0f0h,00h
;	{D5}	';',86h,0e3h,00h
	DEFM	'/',85h,0e3h,00h
	DEFM	'>',0c0h,48h,00h
	DEFM	'?',82h,0e3h,00h
	DEFB	00h			;Kenner für Ende der Tabelle
	IF	NOT,new
	DEFB	00h
	ENDIF

;Befehl LIB bwz. ?
m50cf	LD	HL,cmdtab	;DOS-Befehlstabelle
	IF	NOT,new
m50d2	LD	C,40h		;Zähler 63 Befehle + Nullbytes
	ENDIF
m50d4	LD	B,08h		;8 Bildschirmstellen Platz pro Befehl
m50d6	LD	A,(HL)		;Zeichen des Befehls laden
	BIT	7,A		;hinter dem Befehlswort?
	INC	HL		;nächste Stelle
	JR	NZ,m50e1	;falls Befehlswort vollständig angezeigt
	CALL	m51b7		;Zeichen des Befehls anzeigen
	DJNZ	m50d6		;Befehl komplett anzeigen, Restplatz in B
m50e1	INC	HL		;Requestcode usw. überspringen
	INC	HL
	LD	A,(HL)		;laden
	OR	A		;=00?
	JP	Z,m51b5		;LF ausgeben und Ende, falls ja
	IF	NOT,new
	DEC	C		;Zähler herunterzählen
	CALL	Z,m51b5		;LF ausgeben, falls Zähler abgelaufen
	JR	Z,m50d2		;dort weiter, falls Zähler abgelaufen
	ENDIF
	CALL	m51ad		;Blanks bis zur nächst. Achterstelle anz.
	JR	m50d4		;und von vorne

;Einsprung für Mini-DOS
m50f3	DI
	CALL	pushreg		;alle Register retten
	LD	HL,m436a	;div. Flags
	LD	A,(HL)		;laden
	AND	0c0h		;Mini-DOS oder DOS-CALL aktiv?
	JR	NZ,m5132	;Ende, falls ja
	LD	A,(m4022)	;Flag für Cursorstatus im DCB
	PUSH	AF		;Status retten
	LD	(m439b),SP	;Stack retten
	SET	7,(HL)		;Flag setzen: Mini-DOS aktiv
	IF	NOT,new
	EI
	LD	A,0bh		;LF
	CALL	m0033		;ausgeben
	ENDIF
	IF	new
	CALL	m51b4		;LF anzeigen
	ENDIF
	JP	m4d8a		;dort weiter (Mini-DOS-Ready)

;Einsprung nach ; bzw. MDRET
m5112	LD	HL,m436a	;versch. Flags
	BIT	7,(HL)		;ist Mini-DOS aktiv?
	JP	Z,illfnct	;falls nein
	LD	SP,(m439b)	;Stack restaurieren
	IF	NOT,new
	LD	A,0eh		;Code für Cursor an
	CALL	0033h		;ausgeben
	ENDIF
	POP	AF		;alter Cursorstatus
	OR	A		;war er an?
	LD	B,A		;retten
	LD	A,0fh		;Code Cursor aus
	IF	NOT,new
	CALL	Z,m0033		;ausgeben, falls er aus war
	ENDIF
	IF	new
	JR	Z,dspcurs	;ausgeben, falls er aus war
	DEC	A		;A <- 0E, Code für Cursor an
dspcurs	CALL	0033h		;Cursor an/ausschalten
	ENDIF
	LD	A,B		;Cursorstatus
	LD	(m4022),A	;restaurieren
	DI
	RES	7,(HL)		;Flag: Mini-DOS nicht mehr aktiv
m5132	XOR	A		;Flag "kein Fehler"
popreg	EX	AF,AF'		;alle Register restaurieren
	POP	IY
	POP	IX
	POP	AF
	POP	BC
	POP	DE
	POP	HL
	EXX
	POP	BC
	POP	DE
	POP	HL
	EX	AF,AF'
	EI
	RET
pushreg	POP	AF		;RET-Adresse zwischenpuffern
	PUSH	HL		;alle Register retten
	PUSH	DE
	PUSH	BC
	EX	AF,AF'
	EXX
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	PUSH	IX
	PUSH	IY
	EXX
	EX	AF,AF'
	PUSH	AF		;RET-Adresse zurück
	RET			;diese anspringen

;Filespec. von (HL) nach (DE) übertr. und HL auf EOS (03 oder CR) stellen
m5155	CALL	m5168		;Befehl in den FCB schreiben
	PUSH	AF		;retten
	LD	A,(HL)		;Zeichen des Befehls
	SUB	03h		;EOS?
	JR	Z,m5163		;falls ja
	SUB	0ah		;CR?
	JR	Z,m5163		;falls ja
	INC	HL		;nächstes Zeichen
m5163	POP	AF		;restaurieren
	RET

m5165	LD	DE,m4480	;FCB
m5168	PUSH	DE		;Adresse retten
	LD	B,20h		;max. 32 Zeichen
	CALL	m5172		;Programmnamen in den FCB übertragen
	POP	DE
	LD	B,00h		;LRL = 256
	RET
m5172	LD	A,(HL)		;Zeichen des Befehlsstrings
	CP	'*'		;für Benutzerroutinen?
	JR	NZ,m517b	;falls nein
	LD	(DE),A		;Zeichen im FCB ablegen
	INC	DE		;nächste Stelle
	INC	HL		;nächstes Zeichen des Befehls
	DEC	B		;1 Zeichen weniger max. erlaubt
m517b	PUSH	HL		;retten
	LD	A,(HL)		;Zeichen des Befehls
	SUB	'0'		;falls Ziffer: binär
	CP	0ah		;evtl. Buchstabe?
	CALL	m51a1		;auf Ziffer oder Buchstaben prüfen
	JR	NC,m519c	;falls unerlaubtes Zeichen
m5186	LD	A,(HL)		;Zeichen des Befehls
	SUB	2eh
	CP	0dh		;war es ':'?
	CALL	m51a1		;auf ':' und Buchstaben prüfen
	JR	C,m5196		;weitermachen, falls erlaubtes Zeichen
	LD	A,03h		;sonst EOS (String abschließen)
	LD	(DE),A		;in den FCB
	POP	AF		;Stack bereinigen
	XOR	A		;Z-Flag setzen (kein Fehler)
	RET
m5196	LD	A,(HL)		;Zeichen des Befehls
	LD	(DE),A		;in den FCB
	INC	DE		;nächste Stelle im FCB
	INC	HL		;dto. im Befehl
	DJNZ	m5186		;bis B Zeichen abgelegt sind
m519c	OR	01h		;NZ-Flag bei mehr als falscher Eingabe
	POP	HL		;Befehlszeiger
	LD	A,(HL)		;Zeichen laden
	RET
m51a1	RET	C		;falls nicht Buchstabe, Ziffer oder ':'
	LD	A,(HL)		;Zeichen noch einmal laden
	SUB	'A'		;Großbuchstabe?
	CP	1fh		;oder Kleinbuchstabe?
	RET	C		;falls Großbuchstabe
	SUB	20h		;Klein- zu Großbuchstaben machen
	CP	1fh		;noch höheres Zeichen?
	RET			;zurück mit Flag
m51ad	LD	A,' '		;Blank
m51af	CALL	m51b7		;anzeigen
	DJNZ	m51af		;B-mal
	RET
	IF	new
m51b4	EI			;INTs wieder zulassen
	ENDIF
m51b5	LD	A,0bh		;LF
m51b7	PUSH	DE		;retten
	IF	NOT,new
	PUSH	AF
	ENDIF
	CALL	m0033		;Akku anzeigen
	IF	NOT,new
	POP	AF
	ENDIF
	POP	DE
	RET			;zurück
defext	DEFM	'CMD'
	DEFM	'JOB'
to	DEFM	'TO',00h
	IF	NOT,new
minprpt	DEFM	'Mini-'
dosprpt	DEFM	'Befehlseingabe',1eh,0dh
m51f2	DEFB	1ch,1fh,03h	;Codes zum Löschen des Bildschirms
	ENDIF
	IF	new
minprpt	DEFM	'M - '
	LIST {A1}
;	Die Position des Dosready ist wichtig für den DOS
;	Befehl CD. Wenn SYS1/SYS in Bank 0 gepuffert ist
;	erechnet sich die Adresse wir folgt :
;	In Zeus := B 3f14h+dosprpt
;
dosprpt	DEFM	':7Workbench >',1eh,03h
;
	LIST {A0}
	DEFM	'    '	;WICHTIG FÜR DEN CD-BEFEHL, WEIL SONST DIE
			; ENDE-KENNUNG DES FILES ÜBERSCHRIEBEN WIRD
			;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	ENDIF
fcb	EQU	51e0h
	END	sys1
