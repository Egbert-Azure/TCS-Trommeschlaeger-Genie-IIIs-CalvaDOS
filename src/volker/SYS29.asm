;	Rekonstruktion und Modifikation von SYS29/SYS
;
;	Achtung: läuft nur noch mit dem gebankten DOS
;	und geht vom Genie III s mit Mega-Banker aus!
;	Für den INFO-Befehl ist nur noch der Parameter
;	NP gestattet, weil sich die übrigen Optionen
;	als überflüssig erwiesen haben.
;
;	Entwicklung des Bankers:	Helmut Bernhardt
;	Programmbearbeitung:		Arnulf Sopp
;
;
;
;  neueste Änderungen : H : addieren und subtr. von INT's
;			ON  : HRG-Bildschirm ein
;			OFF : HRG-Bildschirm aus
;		      : PARK Harddisk auf Cylinder 612 parken
;


m0033	EQU	0033h	;UP Akku auf dem Bildschirm anzeigen
m0049	EQU	0049h	;UP auf Tastendruck warten
m06b5	EQU	06b5h	;UP auf 1,77 MHz schalten
m06be	EQU	06beh	;UP auf 7,2 MHz schalten
m1914	EQU	1914h	;Puffer für die Bildschirm-Zeilenlänge
m3641	EQU	3641h	;dto. Abstand des sichtb. vom phys. Bildschirm
m3649	EQU	3649h	;UP Zeichen A in den Bildschirm (HL) schreiben
m4015	EQU	4015h	;Tastatur-DCB	: Typ
m4016	EQU	4016h	;	"	: Treiberadresse
m401d	EQU	401dh	;Bildschirm-DCB	: Typ
m401e	EQU	401eh	;	"	: Treiberadresse
m4020	EQU	4020h	;	"	: Cursoradresse
m4023	EQU	4023h	;	"	: Anzahl Kopfzeilen
m4024	EQU	4024h	;	"	: Anzahl Fußzeilen
m4025	EQU	4025h	;Drucker-DCB	: Typ
m4026	EQU	4026h	;	"	: Treiberadresse
m4049	EQU	4049h	;Puffer für HIMEM
m4063	EQU	4063h	;UP DE in Hex-ASCII in (HL) puffern
m4068	EQU	4068h	;UP A	"	"	"	"
m4371	EQU	4371h	;Beginn der PD-Parameter für Drive 0
m439f	EQU	439fh	;Puffer für Anzahl Drives (S,AL=x)
m4467	EQU	4467h	;UP Text ab (HL) bis 03 oder 0D anzeigen
m4cd5	EQU	4cd5h	;UP Trennzeichen im Befehl interpretieren

	ORG	4d00h

;Parametertabelle für den DISK-Befehl
m4ff5	DEFM	    'A:',14h,28h,07h,28h,0ah,02h,00h,00h,14h,02h
	DEFM	'DISKB:',14h,28h,07h,28h,14h,04h,00h,40h,14h,02h
	DEFM	'DISKC:',18h,30h,53h,28h,12h,03h,00h,03h,18h,02h
	DEFM	'DISKD:',18h,30h,53h,28h,24h,06h,00h,43h,18h,02h
	DEFM	'DISKE:',14h,28h,07h,28h,0ah,02h,00h,04h,14h,02h
	DEFM	'DISKF:',14h,28h,07h,28h,14h,04h,00h,44h,14h,02h
	DEFM	'DISKG:',18h,30h,53h,28h,12h,03h,00h,07h,18h,02h
	DEFM	'DISKH:',18h,30h,53h,28h,24h,06h,00h,41h,18h,02h
	DEFM	'DISKI:',28h,50h,07h,50h,0ah,02h,00h,00h,28h,02h
	DEFM	'DISKJ:',28h,50h,07h,50h,14h,04h,00h,40h,28h,04h
	DEFM	'DISKK:',30h,60h,53h,50h,12h,03h,00h,03h,30h,03h
	DEFM	'DISKL:',30h,60h,53h,50h,24h,06h,00h,43h,30h,06h
	DEFM	'DISKM:',11h,48h,13h,28h,12h,02h,00h,05h,11h,02h
	DEFM	'DISKN:',11h,90h,53h,50h,12h,02h,00h,02h,11h,02h
	DEFM	'DISKO:',11h,28h,13h,28h,0ah,02h,00h,04h,11h,02h
	DEFM	'DISKP:',11h,4ah,50h,52h,12h,04h,00h,03h,11h,06h

sys29	CP	0ffh		;der richtige Requestcode?
	JR	NZ,errfunc	;falls nein
	DEC	C		;Hühnerleiter der SYS29-Features
	JR	Z,info		;falls INFO-Befehl
	DEC	C		;PORT-Befehl?
	JP	Z,port
	DEC	C		;DISK-Befehl?
	JP	Z,disk
	DEC	C		; H ? addieren & subtrahieren von
	JP	Z,add		; INTEGER-Zahlen
	DEC	C		; ON ?  HRG einschalten
	JP	Z,hrgon
	DEC	C		; OFF ? HRG ausschalten
	JP	Z,hrgoff
	DEC	C		; PARK ?? Harddisk parken
	JP	Z,park
errfunc	LD	A,2ah		;Fehlercode "unzulässige DOS-Funktion"
	RET
errsynt	LD	A,34h		;Fehlercode "Syntax o. Trennzeichen ..."
	OR	A		;NZ-Flag für Fehlerbedingung setzen
	RET

info	CALL	m4cd5		;Zeiger auf Zeichen nach dem Befehlswort
	JR	Z,m4de1		;falls nur CR folgt
	LD	A,(HL)		;Zeichen noch einmal laden
	CP	'N'		;INFO,NP eingegeben?
	JR	NZ,errsynt	;ungültige Eingabe, falls nein
	INC	HL		;Zeiger auf nächstes Zeichen
	LD	A,(HL)		;nächstes Z. im INFO-Befehlsstring laden
	CP	'P'		;INFO,NP eingegeben?
	JR	NZ,errsynt	;falls ungültige Eingabe
	LD	A,0c9h		;Opcode RET
	LD	(m4e82),A	;dort patchen (keine Anzeige der Ports)
m4de1	LD	DE,(m4016)	;Treiberadresse Tastatur
	LD	HL,m5123	;Puffer für die Adresse in Hex
	CALL	m4063		;in den Puffer schreiben
	LD	A,(m4015)	;KB-DCB-Typ
	CALL	m4e92		;auf Routing testen, gegf. Flag setzen
	LD	DE,(m401e)	;Treiber Bildschirm
	LD	HL,m5152	;Puffer
	CALL	m4063
	LD	A,(m401d)	;Typ
	CALL	m4e92		;Routing-Test
	LD	DE,(m4026)	;Treiber Drucker
	LD	HL,portf3	;Puffer
	CALL	m4063
	LD	A,(m4025)	;Typ
	CALL	m4e92		;Routing-Test
	LD	HL,m51a2	;Puffer für Infos aus Systemport 2
	LD	BC,03f3h	;B: 3 relevante Bitpaare, C: Port F3
	IN	E,(C)		;Systembyte 2
	LD	D,'0'		;OR-Operand für binär -> ASCII
f3loop	LD	A,E		;evtl. rotiertes Systembyte laden
	AND	03h		;Bank-Bits isolieren
	OR	D		;binär -> ASCII
	LD	(HL),A		;in den Puffer schreiben
	INC	HL		;auf nächste Pufferstelle
	INC	HL
	RRC	E		;zwei weitere Systembits nach rechts
	RRC	E
	DJNZ	f3loop		;bis zum bitteren Ende
	LD	A,E		;Bit 1: 1 X Common (0) oder 4 X C. (1)
	RRCA			;Bit 1 -> Bit 0
	AND	01h		;Bit 0 isolieren
	OR	D		;binär -> ASCII
	LD	(HL),A		;Wert puffern
	INC	HL		;nächste Stelle
	INC	HL
	LD	A,E		;Bit 0: Boot-EPROM (0) oder SRAM (1)
	AND	01h		;Bit 0 isolieren
	OR	D		;binär -> ASCII
	LD	(HL),A		;Wert puffern
	LD	A,(m4023)	;Kopfzeilen bei ##,S
	LD	HL,m5177	;Puffer
	CALL	m4068
	INC	HL		;auf nächste Pufferstelle
	INC	HL
	LD	A,(m4024)	;Fußzeilen
	CALL	m4068
	LD	DE,(m4049)	;Himem
	LD	HL,m5142	;Puffer
	CALL	m4063
	LD	A,1ch		;home cursor
	CALL	m0033		;ausgeben
	LD	HL,m5101	;Text, beginnt mit Code für 64*16 Zeichen
	LD	A,(m1914)	;Bildschirm-Zeilenlänge
	CP	64		;64 Zeichen/Zeile?
	JR	C,m4e60		;falls weniger
	INC	HL		;sonst ASCII 10h überspringen
	JR	NZ,m4e64	;falls nicht genau 64 Zeichen
m4e60	XOR	A		;sonst LF löschen
	LD	(m4ebb),A	;hier
m4e64	CALL	m4e9a		;Bildschirm löschen, Text anzeigen
	XOR	A		;A <- 00, Zeichen ab ASCII 00
m4e68	LD	HL,(m4020)	;rel. Cursorposition
	LD	DE,(m3641)	;beim G3s: Abstand des phys. Bildschirms
	ADD	HL,DE		;HL <- physikalische Bildschrmadresse
	LD	B,64		;64 Zeichen/Zeile
m4e72	CALL	m3649		;beim G3s: Byte in den Bildschirm schr.
	INC	HL		;nächste Bildschirmstelle
	INC	A		;nächster ASCII-Wert
	DJNZ	m4e72		;bis 64 Zeichen geschrieben sind
	PUSH	AF
	CALL	dispcr		;dann CR
	POP	AF
	JR	NZ,m4e68	;bis 256 Zeichen angezeigt sind
m4e82	LD	HL,m51b9	;Text "aktive Ports"
	CALL	m4e9a		;Bildschirm löschen, Text anzeigen
	CALL	m4ed5		;die Portbelegung anzeigen
	XOR	A
	RET
m4e92	BIT	7,A		;Routing für dieses Device aktiv?
	RET	NZ		;falls ja
	INC	HL		;übernächste Textstelle
	INC	HL		;wo "@" für den Text "umgeleitet" steht
	LD	(HL),8dh	;Flag für 13mal Blank setzen (13+128)
	RET
m4e9a	LD	A,(HL)		;Byte aus Text usw.
	LD	B,01h		;Zähler 1 bei normalen Zeichen
	BIT	7,A		;Space-Compression?
	JR	Z,m4ea5		;falls nein
	AND	7fh		;Bit 7 löschen
	LD	B,A		;Zähler für die Blanks
	INC	HL		;nächste Stelle des Textes
m4ea5	LD	A,(HL)		;nächstes Byte
	CP	03h		;Textende?
	RET	Z		;falls ja
	CP	'@'		;evtl. "umgeleitet" anzeigen?
	JR	NZ,m4eb6	;falls nein
	PUSH	HL
	LD	HL,m50f4	;Text "(umgeleitet)"
	CALL	m4467		;anzeigen
	POP	HL
	XOR	A
m4eb6	CP	0bh		;bedingter LF? (je nach Videoformat)
	JR	NZ,m4ebc	;falls nein
	LD	A,0ah		;LF daraus machen (oder NUL bei < 64 Z.)
m4ebb	EQU	$-1
m4ebc	PUSH	AF
	CALL	m0033		;Byte anzeigen
	POP	AF
	CP	0dh		;war es CR?
	RET	Z		;falls ja
	DJNZ	m4ea5		;bis Zeichen Bmal angezeigt (bei Bit 7)
	INC	HL		;nächste Textstelle
	JR	m4e9a		;weiter anzeigen

gethex	CALL	getciph		;1. Hexziffer der Eingabe laden
	RLCA			;unteres ins obere Nibble rotieren
	RLCA
	RLCA
	RLCA
	LD	B,A		;16erstelle retten
	CALL	getciph		;Einerstelle einlesen
	OR	B		;A <- Binärwert der Hexeingabe
	RET
getciph	LD	A,(HL)		;Ziffer einlesen
	INC	HL		;auf nächste Stelle
	SUB	'0'		;ASCII -> binär
	JR	C,errparm	;falls unzuläss. Wert (keine Ziffer)
	CP	09h+1		;größer als 9?
	RET	C		;fertig, falls 0-9
	SUB	07h		;Hexziffern angleichen
	CP	0ah		;mindestens 10?
	JR	C,errparm	;falls keine Hexziffer
	CP	0fh+1		;größer als F?
	RET	C		;fertig, falls nein
errparm	POP	AF		;CALL-Ebene löschen
	POP	AF		;(2. Ebene)
	LD	A,2fh		;Fehlercode "schlechte Parameter"
	OR	A		;NZ-Flag setzen (Fehlerbedingung)
	RET
port	CALL	m4cd5		;auf nächsten Parameter des Befehls
	JR	Z,allport	;falls nur PORT eingegeben wurde
	CALL	gethex		;Portadresse hinter dem Befehlswort lesen
	LD	C,A		;C <- Portadresse
	CALL	m4cd5		;nächster Parameter
	JR	NZ,getoutp	;falls Daten folgen
	LD	A,C		;Portadresse
	LD	HL,m51ce	;Puffer dafür
	PUSH	HL		;brauchen wir noch
	CALL	m4068		;in Hex in den Puffer schreiben
	INC	HL		;auf den Puffer für den Input stellen
	IN	A,(C)		;Input einholen
	CALL	m4068		;in den Puffer schreiben
	POP	HL		;Pufferanfang
	CALL	m4467		;anzeigen
	CALL	dispcr		;CR ausgeben
	XOR	A		;Fehlerflag: kein Fehler
	RET			;Ende
nextpar	CALL	m4cd5		;Befehlszeiger auf nächstes Datum stellen
	RET	Z		;Ende, falls keins mehr folgt
getoutp	PUSH	HL		;Befehlszeiger retten
	CALL	gethex		;Output für den Port einlesen
	CALL	m06b5		;auf 1,77 MHz schalten
	OUT	(C),A		;und Datum ausgeben
	CALL	m06be		;auf 7,2 MHz schalten
	POP	HL		;Befehlszeiger
	INC	HL		;auf nächstes Trennzeichen stellen
	JR	nextpar		;Befehlsstring auf weitere Outputs prüfen
allport	LD	A,(1914h)	;Zeichen/Zeile
	LD	(m4efa),A	;dort patchen
m4ed5	LD	C,00h		;Inputs ab Port 00 lesen
	JR	m4edc
m4ed9	INC	C		;weiter mit dem nächsten Port
	JR	Z,m4f0f		;falls alle 256 Ports bearbeitet sind
m4edc	CALL	m06b5		;auf 1,77 MHz schalten
	IN	A,(C)		;Input eines Ports holen
	CALL	m06be		;auf 7,2 MHz schalten
	CP	0ffh		;ist der Port unbelegt oder inaktiv?
	JR	Z,m4ed9		;falls ja
	LD	HL,m51d1	;Puffer für Hex-Angabe des Inputs
	CALL	m4068		;Input in den Puffer
	LD	HL,m51ce	;ASCII-String für Port und Input
	LD	A,C		;Portadresse
	CALL	m4068		;in Hex in den Puffer schreiben
	LD	A,00h		;belegter Platz in der Zeile
m4ef6	EQU	$-1		;ändert sich
	ADD	A,07h		;eine Portangabe belegt 7 Stellen
	CP	64		;ist die Zeile schon voll?
m4efa	EQU	$-1		;je nach Format
	JR	C,m4f04		;falls noch nicht
	CALL	dispcr		;sonst CR ausgeben
	LD	A,07h		;7 als Ausgangswert der Zeilenbelegung
m4f04	LD	(m4ef6),A	;neu patchen
	LD	HL,m51cd	;ASCII-String des Ports und des Inputs
	CALL	m4467		;anzeigen
	JR	m4ed9		;weiter mit dem nächsten Port
m4f0f	LD	A,(m4ef6)	;belegter Anteil der Zeile
	OR	A		;Zeile frei?
	RET	Z		;falls ja
dispcr	LD	A,0dh		;sonst CR ausgeben
	JP	m0033
errdriv	LD	A,20h		;Fehlercode "unzul. o. fehl. Laufwerk"
	OR	A
	RET
disk	LD	A,(m439f)	;Anzahl Drives
	LD	B,A		;merken für später
	LD	A,(HL)		;Parameter des DISK-Befehls
	SUB	'0'		;ASCII -> binär
	JP	C,errsynt	;falls keine zulässige Ziffer
	CP	0ah		;Zeichen größer als "9"?
	JP	NC,errsynt	;falls falsche Eingabe
	CP	B		;Laufwerk-Nr. zu hoch?
	JR	NC,errdriv	;falls unzulässiges Laufwerk
	PUSH	AF
	INC	HL		;nächste Stelle im Befehlsstring
	LD	A,(HL)
	CP	'='
	JR	NZ,m4f58	;falls nicht korrekte Syntax mit "="
	INC	HL		;nächste Stelle im Befehlsstring
	LD	C,(HL)		;merken
	INC	HL		;nächste Stelle
	CALL	m4cd5		;nächstes Trennzeichen überspringen
	JR	NZ,m4f58	;Fehler, falls jetzt nicht CR kommt
	LD	HL,m4ff5	;das "A" von DISKA
	LD	B,10h		;16 Codes
m4f4e	LD	A,(HL)		;einen laden
	CP	C		;den richtigen DISK-String gefunden?
	JR	Z,m4f5c		;falls ja
	LD	DE,0010h	;sonst Summand 16 für nächsten String
	ADD	HL,DE		;Zeiger einen weiter
	DJNZ	m4f4e		;bis 16 Strings bearbeitet sind
m4f58	POP	AF		;Stack bereinigen
	JP	errsynt		;mehr als 16 gibt es nicht
m4f5c	POP	AF		;Laufwerk-Nr.
	LD	C,A		;merken
	ADD	A,A		;*2
	ADD	A,A		;*4
	ADD	A,C		;*5
	ADD	A,A		;*10, 10 Parameter pro Drive
	PUSH	IX
	PUSH	IY
	LD	IX,m4371	;PD-Parameter für Drive 0
	LD	C,A		;Drive-Nr. *10
	LD	B,00h		;BC <- Drive-Nr. *10
	ADD	IX,BC		;IX auf richtiges Drive stellen
	INC	HL		;auf erstes Byte der Paramtertabelle
	INC	HL
	PUSH	HL
	POP	IY		;nach IY (Zeiger auf Parameterstring)
	LD	A,(IY+02h)	;TI im Befehl
	AND	0fch		;alles ohne TSR-Bits
	LD	C,A		;merken
	LD	A,(IX+02h)	;TI im DOS
	AND	03h		;nur TSR-Bits
	OR	C		;altes TI mit neuer TSR verknüpfen
	LD	(IY+02h),A	;in die Tabelle
	LD	BC,000ah	;
	PUSH	IX		;DOS-PD-Zeiger
	POP	DE		;nach DE
	LDIR			;neue Tabelle ins DOS übertragen
	POP	IY
	POP	IX
	XOR	A
	RET

;	diverse Texte und Puffer:
;
;	Codes > 80h wiederholen das nächste Zeichen (x-128)mal
;
;	"@" steht für "(umgeleitet)" bei Routing
;
;	Anzeige für Port F3 (Systembyte 2, Label portf3):
;	"Bank":		Hauptspeicher-Block	(Bits 0, 1)
;	"Vid.":		Video-RAM-Block		(Bits 2, 3)
;	"Grph.":	Graphik-Block		(Bits 4, 5)
;	"C":		Common-Definintion:
;			Bit 7	= 0:	1X Common für 1 MB
;				= 1:	4X Common für je 256 kB
;	"E&R":		Baustein in 0000-2FFF bei Port FA, Bit 2 = 0:
;			Bit 6	= 0:	Boot-EPROM selektiert
;				= 1:	parall. SRAM	"

m50f4	DEFM	'(umgeleitet)',03h	;falls Routing eines Device
m5101	DEFM	10h,1ch,1fh		;16*64 Zeichen (bedingt), CLS
	DEFM	98h,'- GENIE-DOS INFO ',98h,'-',0bh,'Tastatur: '
m5123	DEFM	'FFFFh @  Ende User-RAM (HIMEM): '	;@ für "(umgel.)"
m5142	DEFM	'FFFFh',0ah,'Monitor:  '
m5152	DEFM	'FFFFh @  '
m515b	DEFM	'Kopf-/Fußzeilen:',87h,' '
m5177	DEFM	'00h/00h',0ah,'Drucker:  '
portf3	DEFM	'FFFFh @  Bank/Vid./Grph./C/E&R: '
m51a2	DEFM	'0/0/0/0/0',0ah,99h,'- ZEICHENSATZ ',9ah,'-',0bh,03h
m51b9	DEFM	99h,'- AKTIVE PORTS ',99h,'-',0bh,03h
m51cd	DEFM	' '
m51ce	DEFM	'00='
m51d1	DEFM	'00 ',03h

;
;
;
;
;
;		Eingefügt am 29.02.92
;	ADDIEREN VON ZWEI HEXZAHLEN
;
;  mit Hilfe des DOS-Unterprogramms bei 3B68h
;
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
hexde	EQU	4063h
;
add	LD	A,(HL)		; wenn zunächst ein '@' eingegeben wird
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
	JP	NZ,errsynt	; sonst fehler
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
	RET			; normaler Abgang bei SYS-Files
hexbuf1	DEFM	'd : '
hexbuf	DEFM	'ffffh ',0dh
ergeb	EQU	435eh
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

;
;
;
;	ON
;	SCHALTET DIE HRG SEITE 0 EIN
;	FUER GENIE IIIs
hrgon	IN	A,(0fah)	;systembyte 1
	SET	1,A	;grafik an/aus-bit
	OUT	(0fah),A	;raus damit
	RET     	; normaler Ausgang für DOS
;
;

;	O F F
;	schaltet die grafik aus
;	fuer Genie IIIs
hrgoff	IN	A,(0fah)
	RES  	1,A
	OUT	(0fah),A
	RET
;
;	PARK parkt die Köpfe der harddisk auf Cylinderposition
;	612, um die Köpfe von der Platte in Sicherheit zu bringen
; 	nach diversen Programmen zusammengestückelt, u.a. c't'
;	sowie H.Bernhardt und A. Magnus
;
m0503	EQU	0503h
m050b	EQU	050bh
m402d	EQU	402dh
m5200	OUT	(42h),A
	CALL	m5212
	LD	A,C
	OUT	(40h),A
	LD	C,'@'
m520a	CALL	m5212
	OUTI
	JR	NZ,m520a
	RET
m5212	IN	A,(41h)
	BIT	0,A
	JR	Z,m5212
	RET
m5247	NOP
	ADD	A,B
	LD	H,B
	NOP
	LD	(BC),A
park	LD	HL,text
	CALL	m4467
	LD	HL,m5247
	LD	BC,m050b
	CALL	m5200
	RET		; Ausstieg bei SYS-Files
text	DEFM	'HD parked on Cyl. 612.',0dh
mffff	EQU	0ffffh
	END	sys29
