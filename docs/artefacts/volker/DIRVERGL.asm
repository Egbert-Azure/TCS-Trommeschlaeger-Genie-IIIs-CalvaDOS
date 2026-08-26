	LIST	ON
;************************************************************************
;
; Dieses Programm vergleicht zwei Direktorys auf gleichheit oder
; ungleichheit.
; Aufruf: DIRVERGL,Q,Z,(U),(P)
; wobei Q das erste Laufwerk und Z das zweite sind.
; Ohne weitere Angaben werden die Programme (außer SYS-Files) die in
; beiden Directorys enthalten sind ausgegeben oder gedruckt (,P)
; wird 'U' angegeben, werden nur die Files angezeigt (oder gedruckt)
; die auf Drive Q, nicht aber auf Z vorhanden sind.
;
; Name: DIRVERGL/SRC
;
; Datum:22.09.89	letzte Änderung: 10.03.1990
;
; Diese Programm ist von A.Magnus geschrieben
;
; (c) Sept. 1989 by A. Magnus   HACKNUS - SOFTWARE
;
; Unentgeltliche Weitergabe und Veränderung sind ausdrücklich erwünscht.
;
;************************************************************************


;Labels zur Anpassung des Programms an den eigenen Computer:
m1	EQU	0	;Model 1, Genie 1/2/2s: 1       anderer Rechner: 0
m3	EQU	0	;Model 3/4/4p:		1     	andere Rechner: 0
g3	EQU	1	;Genie 3/3s/3ß:		1	andere Rechner: 0

;Sicherung gegen falsche Label-Zuteilung (mehrfach 1 oder dreimal 0)
model	EQU	m1+m3+g3-1	;das Resultat muß 0 ergeben

	IF 	NOT,m3
testpar	EQU	4cd5h		;Testet Parameter in (HL)
getfde	EQU	4936h		;liest nächsten FDE aus DIR-Sektor
cpbchl	EQU	4cc5h		;vergleicht (BC) mit (HL)
dir1	EQU	490ah		;liest ektor aus DIR
	ENDIF

	IF	m3
testpar	EQU	4c7ah
getfde	EQU	48dbh
cpbchl	EQU	4c6ah
dir1	EQU	48afh
	ENDIF

patch	EQU	cpbchl+6
tstdsk	EQU	445bh

	ORG	7000h

	IF	g3
z80	DEFM	'80',0dh
start	PUSH	HL		;Eingabepuffer sichern
	LD	HL,z80
	CALL	4419h		;Schirm auf 80 Z schalten
	POP	HL		;und wieder zurück
	ENDIF

	IF	NOT,g3
start	EQU	$
	ENDIF
	XOR  	A		;NOP für DOS-Routine
	        CALL	lwt		;Test ob Laufwerk korrekt
	LD	D,A		;Quellaufwerk nach D
	INC	HL
	INC	HL		;Zeiger auf Ziellaufwerk
	CALL	lwt		;Test ob Laufwerk korrekt
	INC	HL		;auf Trennzeichen stellen
	LD	E,A		;Ziellaufwerk nach E
paralp	CALL	testpar		;nächsten Parameter testen
	CALL	C,sysfehl	;Fehler SYNTAX oder ... Fehler
	CALL	drktest		;auf Option 'P' testen und evtl patchen
	JR	Z,paralp	;nächsten Parameter testen
	CP	0dh		;Eingabe zuende ?
	JR	Z,start1	;dann beginn mit bearbeitung
	CP	'U'		;nur ungleiche Files ?
	JR	NZ,paralp	;dann weiter testen
	LD	A,0cch		;Op-Code für CALL Z
	LD	(ungl),A	;im Programm patchen
	JR	paralp		;und weitere Parameter testen

	 				;HX mit 24 laden (Zeilen/Schirm)
start1	PUSH	DE		;Laufwerke sichern
	LD	A,E		;Ziellaufwerk nach A
	LD	DE,dir2-1	;Buffer für Filenamen des 2. DIR
	CALL	länge		;Länge des Dir testen
	JP	NZ,dosfeh1	;raus mit Dos-Fehler
	LD	B,00h		;muß für UP 0 sein
	CALL	fileget		;Filenamen in Puffer 2 lesen
	POP	DE		;Lw zurück
	LD	A,D		;Lw in den ACCU
	CALL	länge		;Drive starten und Sektoranzahl patchen
	LD	HL,patch1	;Programmänderung
	LD	DE,ziel		;dahin
	LD	C,05h		;länge
	LDIR			;und patchen

	IF	NOT,g3
	LD	DE,0f04h	;4 File in 15 Zeilen
	ENDIF

	IF	g3
	LD	DE,1806h	;6 Files in 24 Zeilen
	ENDIF

	LD	A,0c9h		;RET für 2. Durchgang
	LD	(first),A	;da auch patchen;
	XOR	A
	LD	(aktsek),A
	CALL	fileget		;jezt vergleichen
	LD	A,0dh		;CR
	CALL	ausa		;und ausgeben (für Drucker)
ende PUSH	AF
	LD	A,0e3h		;alter Zustand im DOS
	LD	(patch),A	;und wieder herstellen
	POP	AF
	RET 			;das wars

sysfehl	LD	A,34h		;'Syntax oder ...' Fehler
lwfehl	OR	20h		;'Unz. oder fehlende Laufwerk'
dosfeh1	POP	HL		;Stack bereinigen
dosfehl	JR	ende		;zurück mit Fehler

	fertig

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Ab hier stehen die Unterprogramme in der Reihenfolge ihres Aufrufes
;

; UP LWT: testet ob das Laufwerk in (HL) im bereich von 0-9 liegt.
; wenn nicht: aussprung zu LFFEHL: fehlerausgabe Falsches Laufwerk

lwt	LD	A,(HL)		;LW nach A
	SUB	30h		;nach binär wandeln
	CP	0ah		;ist es zwischen 0 und 9 ?
	RET	C		;zurück wenn ok
	XOR	A 		;muß sein, um Fehler korrekt anzuzeigen
	JP	lwfehl		;und mit Fehler raus

; UP DRKTEST: testet ob Option 'P' angegeben, und patcht eventuell
;             ein paar Routinen

drktest	LD	A,(HL)		;Zeichen aus Befehlsstring
	CP	'P'		;Druckerausgabe ?
	INC	HL		;auf nächstes Zeichen
	RET	NZ		;wenn nicht Drucker
	LD	A,3bh		;Adress LSB Druckertreiber
	LD	(ausflag),A	;in ausgaberoutine patchen
	LD	A,0c9h		;RET
	LD	(warte),A	;in warteschleife patchen.Druck kann durchgehend erfolgen
	RET			;das wars

;UP LÄNGE: liest die Länge des DIR (Lw # in A) aus Dir-Sektor 1
;          und schreibt sie in die Filebearbeitungsroutine

l{nge	CALL	tstdsk		;Motor on und test DISK IN ?
	RET	NZ		;zurück mit Fehler
	INC	A		;A auf 1 für Dir-Sektor 1
	CALL	dir1		;Dir-Sektor 1 lesen
	RET	NZ		;zurück mit Fehler
	LD	A,(421fh)	;Anzahl der DIR-Sektkorken - 0Ah
	ADD	A,08h		;+ 8: Anzahl der Sektoren mit Einträgen
	LD	(last),A	;Anzahl in die Leseroutine patchen
	CP	A		;Z Flag setzen
	RET			;und zurück

	LIST	OFF
;UP FILEGET: holt die nächsten Filenamen die keine SYS-File sind aus
;            dem Direcktory: und schreibt diese in den Puffer ab DE
fileget	LD	A,00h		;aktueller DIR-Sektor
aktsek	EQU	$-1
	CALL	getfde		;diesen DIR-Sektor lesen
	JP	NZ,dosfeh1	;zurück wenn Fehler
dirlp1	LD	A,(HL)		;Byte 0 des FDE
	AND	0d0h		;nur Bit 4,6 und 7
	CP	10h		;nur wenn File besetzt, kein Erweiterungseintrag und kein SYS-File
	LD	A,L		;LSB des FDE nach A (wird noch gebraucht)
	JR	NZ,next		;sonst nächsten Eintrag behandeln
	LD	C,04h		;Abstand zum File-Namen
	ADD	HL,BC		;HL auf Filenamen

ziel	LD	(HL),B		;Fileendekennung nach vorne
	LD	C,0ch		;Länge des Filenamen
	    	LDIR			;Filenamen in Puffer übertragen

;----------------------------------------------------------------
;ziel	INC	HL		;nach dem 1. Durchgang
;	CALL	vergl
;	NOP
;----------------------------------------------------------------

next	ADD	A,20h		;Anfang des nächten FDE
	LD	L,A		;und zurück nach HL
	JR	NC,dirlp1	;weiter bearbeiten da Sektor noch nicht zuende
	LD	A,(aktsek)	;bearbeiteten Sektor nach A
	INC	A		;auf nächsten Sektor stellen
	LD	(aktsek),A	;und zurück damit
	SUB	00h		;mit letztem Sektor vergleichen
last	EQU	$-1		;hier wird der letzte Sektor gepatcht
	JR	NZ,fileget	;nächsten Sektor lesen und weitermachen
first	LD	(DE),A		;Endekennung bzw RET bei 2. Durchgang
	INC	DE
	LD	(DE),A
	RET			;zurück


;UP VERGL: Vergleicht die Filenamen in im Sektor mit denen in dir2
;          es werden alle Filenamen in 'Buffer' verglichen
;          wird der Name gefunden Wird dieser angezeigt wenn 'U' nicht,
;	   ist das Ende von 'Buffer' erreicht und nichts gefunden
;          wird er angezeigt wenn 'U' gegeben ist


vergl	PUSH	AF		;Register sichern
	LD	BC,dir2		;Pufferanfang
vergll	LD	A,(BC)		;Wert aus Puffer
	OR	A
	JR	Z,ungl		;Bufferende
	PUSH	HL
	CALL	cpbchl		;beide Files vergleichen
	POP	HL
	SUB	34h		;konvertierung zur Abfrage
	JR	Z,vergll	;nächsten File vergleichen
ungl	CALL	NZ,ausgabe	;File je nach Angabe anzeigen
	POP	AF
	LD	B,0		;muß wieder 0 sein
	RET

	LIST	ON

;UP AUSGABE: gibt den Filenamen in HL auf dem Bildschirm oder Drucker aus
;            und zwar 6 Files nebeneinander und 24 files pro Schirm

ausgabe LD	B,08h		;8 Byte Filenamen
	LD	C,H		;H sichern, wird noch gebraucht
	CALL	aushl		;und ausgeben
	LD	B,03h		;3 Byte Extension
	CALL	aushl		;auch ausgeben
	DEC	E        	;(Filenamen nebeneinander)
	LD	H,C		;H vorsichtshalber zurück
	RET	NZ       	;alles klaro

	IF	g3
	LD	E,6		;wieder auf 6 stellen
	ENDIF
	IF	NOT,g3
	LD	E,4		;s.o.
	ENDIF
	DEC	D		;Zeilenzähler -1
	JR	NZ,neuz		;neue Zeile anzeigen
	IF	g3
	LD	D,18h		;wieder auf 24 Zeilen stellen
	ENDIF
	IF	NOT,g3
	LD	D,0fh
	ENDIF
	EX	DE,HL		;Zähler sichern
	CALL	warte		;auf Tastendruck warten
	EX	DE,HL		;und Zähler zurück
neuz	LD	A,0dh		;CR => A
	CALL	ausa		;und anzeigen und zurück
	LD	H,C		;H jetzt entgültig zurück
	RET

;UP AUSHL: gibt B Zeichen lang (HL) ff aus

aushl	LD	A,(HL)		;Zeichen in den	ACCU
	CALL	ausa		;und ausgeben
	INC	HL		;auf nächste Stelle
	DJNZ	aushl		;bis alle Angezeigt
	LD	A,20h    	;Trennzeichen
	CALL	ausa		;und ausgeben
	RET

;UP AUSA: gib den ACCU auf dem Bildschirm oder Drucker aus

ausa	PUSH	DE		;Zeilenzähler retten
	CALL	0033h		;oder 3bh für Drucker
ausflag	EQU	$-2
	POP	DE
	RET

;UP WARTE: wartet bis CR gedrückt ist

warte	CALL	0049h		;auf Tastendruck warten
	CP	0dh		;war es Enter ?
	RET	Z		;zurück wenn ja
	JR	warte		;weiter warten

patch1	DEFB	23h		;Op-Code für INC HL
	DEFB	0cdh		;Op-Code für CALL
	DEFW	vergl		;Adresse für UP
	DEFB	00h		;NOP

dir2	DS	098bh		;Platz für Puffer 2
	END	start
