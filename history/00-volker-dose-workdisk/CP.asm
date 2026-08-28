;	C o P y  mit  Wildcards (CP/CMD
;
;Kopieren von einer diskette auf eine andere
;mit angabe von wildcards
;	? = beliebiger buchstabe
;	* = nachfolgende zeichen bis '/' beliebig
;
;
;  Syntax :=  CP FILENAME/EXT:lw#,:lw# <ENTER>
;
;
; Änderungen 18.02.92 - bei */* sowohl 'j' als 'J' erlaubt
;		      - erkennung von SYS und Folgeeinträgen
;			geändert
;		      - nach der Extension auch blanks erlauben
;            14.03.92 - statt Komma auch ein blank zwischen den
;			Laufwerksnummern erlaubt
;			!!   Hallo Alexander   !!
;
;
outch	EQU	0033h
getkey	EQU	0049h
dosrdy	EQU	402dh
doscal	EQU	4419h
extrfs	EQU	441ch
sendms	EQU	4467h
grosbu	EQU	45b5h
dirr	EQU	490ah
dirw	EQU	491fh
tesdsk	EQU	445eh
debug	EQU	440dh
doserr	EQU	4409h
;
;
	ORG	8000h
dri1	DEFM	'x'	;source-lw#
dri2	DEFM	'x'	;destination-lw#
secanz	DEFM	'x'	; anzahl der zu lesenden
			; dirsectoren mit FDE's
buf1	DEFM	'xx'	; zeiger auf buffer
buf2	DEFM	'xx'	; zeigt auf anfang Bufferfeld
filzae	DEFM	00h	; Anzahl der zu kopierenden Files
fname	DEFM	'FILENAME';ebenso vom Progr. eingesetzt
exten	DEFM	'EXT'
ende	DEFM      0DH     ;in den zurückliegenden 11 bytes
			;wird der Vergleichsfilespec
			;eingeschrieben um verglichen
			;zu werden
schlech	DEFM	'Syntax := CP FILENAME/EXT'
	DEFM	':<Lw#q>,:<Lw#z> <ENTER>'
	DEFM	0dh     ; Bei falscher Eingabe
start	LD	B,09h	; max. 8Zeichen für Filename
	LD	DE,fname; Zeiger auf 		"
loop1	LD	A,(HL)	; zeichen holen
	CALL	grosbu	; a->A, soweit möglich
	CP	'?'	; wenn ja einfach eintragen
	JR	Z,wei1
	CP	'0'
	JR	C,kzeich; wenn Carry gesetzt, ist
			;das Zeichen in der
			;ASCII-Tabelle kleiner als 'A'
	CP	'ß'
	JR	NC,kzeich; bzw. es ist oberhalb von 'Z'
wei1	LD	(DE),A	; buchstaben eintragen
	INC	DE
	INC	HL	; zeiger einen weiter
	DJNZ	loop1	; bis 8 Zeichen
	JR	error	; mehr als 8 !!
kzeich	CP	':'	; laufwerkstrennzeichen?
	JR	Z,error	; enter ohne ext ist unzulässig
	CP	'/'	; einziges zulässiges zeichen
	JR	Z,slash	; weiter im text
	CP	'*'	; jetzt wirds interessant
	JR	Z,stern	; mal sehen
	JR	error	; anderes zeichen !!
slash	LD	A,B	; wegen DJNZ
	CP	0h	; 8tes Zeichen ?
	CALL	NZ,nulauf; ausnullen mit spaces
	LD	DE,exten ; zeiger auf extensionstring
ext	LD	B,04h	; höchstens drei Buchstaben !
loop2	INC	HL	; eingangs zähler ein weiter
	LD	A,(HL)
	CALL	grosbu	; selbe routine wie oben
	CP	'?'	;einfach weiter
	JR	Z,wei2
	CP	' '	; blank ?
	JR	Z,wei2	; ist schon o.K.
	CP	'A'
	JR	C,keexze; wenn enter, dann o.k.
	CP	'Ä'
	JR	NC,keexze; dito
wei2	LD	(DE),A	; buchstabe eintragen
	INC	DE
	DJNZ	loop2	; bis 3 Zeichen
	CP	':'	; 13. Zeichen LW-Doppelpunkt ?
	JR	NZ,error; wenn nicht !!!!!!!!!!!
	JR	kopie	; soweit in ordnung
keexze	CP	'*'	; mit ?? aufüllen
	JR	Z,stern1
	CP	':'
	CALL	NZ,error; jetzt folgt die LW#
	CALL	nulauf
	JR	kopie
nulauf	LD	A,' '	; space
fill	LD	(DE),A	; in fname eintragen
	INC	DE
	DJNZ	fill
	RET
stern	LD	A,'?'	; fuellbyte '?'
	CALL	fill
	INC	HL	; müßte auf '/' zeigen
	JR	slash
stern1	LD	A,'?'	; füllbyte
	CALL	fill	; ausfüllen,
	INC	HL	; soll auf ':' zeigen
	LD	DE,ende	; aufs ende von fname
	LD	A,(HL)	; zeichen holen
	CP	':'	; wegen LW#
	JR	NZ,error
	JR	kopie	; soll funktionieren
error	LD	HL,schlech
	CALL	sendms	; error meldung ausgeben
	JP	dosrdy	; vorläufiger ausstieg
istzahl	SUB	'0'	; ascii korrektur
	JR	C,error
	CP	10
	RET	C
	JR	error
kopie	INC	HL	; jetzt wird erst mal auf
			; die Befehlssyntax
	LD	A,(HL)	; also :lw#,:lw# getestet
	CALL	istzahl
	LD	(dri1),A; als	source laufwerk
	INC	HL	; auf komma
	LD	A,(HL)
	CP	','
	JR	Z,komma ; keine andere eingabe erlaubt
	CP	' '	; außer einem <SPACE>
	JR	NZ,error
komma	INC	HL	; auf zweiten doppelpunkt
	LD	A,(HL)
	CP	':'
	JR	NZ,error
	INC	HL	; auf destination laufwerk
	LD	A,(HL)
	CALL	istzahl
	LD	(dri2),A; als dest-lw
	INC	HL	; auf ENTER
	LD	A,(HL)
	CP	0dh
	JR	NZ,error;
; weiter im text, die Engabe ist richtig
; und der vergleichs filename steht.
; die laufwerksnummern sind auch da,
; jetzt kann wirklich kopiert werden.
; es werden ersteinmal die einträge in den
; buffer geschrieben
	LD	HL,buffer
	LD	(buf1),HL
	LD	(buf2),HL; anfang des Buffers
			 ; muss erhalten bleiben
reasec	LD	A,(dri1); sourcelaufwerk eintragen
	CALL	tesdsk	; disketten zugriff testen
	JP	NZ,doserr
	CALL	ermi	; wieviele Dir-sectoren
	LD	A,(secanz)
	LD	B,A
	LD	A,1	; erster dir-sector mit fde's
liesec	INC	A	; ist der Sector Nummer 2
	PUSH	AF	; retten !!
	PUSH	BC	; ebenso
	CALL	dirr	; les einen sector in DOS-buffer
	CP	06h	;'Lesevers. markierter satz'
	JR	Z,wei3	; dann ist alles in ordnung
	JP	doserr	; es ist ein fehler aufgetr.
wei3	CALL	auswert	; gültige filespecs errech.
	POP	BC
	POP	AF	; accu vom stack als zähler
	DJNZ	liesec
	JP	copy	; jetzt kann es richtig losgehen
auswert	LD	B,7	; acht eintäge pro sector
	LD	HL,4200h; erstes byte zeigt ob
			; ein Eintrag vorhanden ist
	LD	DE,4205h; zeigt auf ersten FILENAMEEXT
	CALL	verglei	; prüft ob der eintrag den
loop3  LD	A,20h	; spezifikationen
	ADD	A,L     ; entspricht. Ein FDE ist
	LD	L,A     ; 20h Byte lang.
	LD	A,20h
	ADD	A,E
	LD	E,A
	CALL	verglei	; siehe 8 Zeilen weiter oben
	DJNZ	loop3
	RET		; acht einträge sind geprüft
verglei	PUSH	HL	; HL und DE werden gerettet
	PUSH	DE
	PUSH	BC	; muß auch gertettet werden
	LD	B,0bh	; 11 zeichen ist fname lang
	LD	A,(HL)	; sehen ob eintrag besteht
	CP	00h	; null, wenn nicht
	JR	Z,zurü	; erst noch pop de und hl
	BIT	7,A	; ist es ein Folgeeintrag ???
	JR	NZ,zurü	; dann nicht eintragen !!
	BIT	6,A	; bit 6 ist '1' bei /SYS-Files
	JR	NZ,zurü	; weil die nicht kopiert
			; werden dürfen (oder sollen)
			; vor allen Dingen nicht Boot und
			; Inhalt/SYS !!!!!!!!!!!!!!!!!!
	LD	HL,fname; enthält spezifizierten fname
wei4 LD	A,(DE)	; zeichen im buffer
	CP	(HL)	; vergleiche (hl) mit (de)
	JR	NZ,wei7 ; wenn nicht gleich, prüfen ob ?
wei5 INC	HL
	INC	DE	; zeiger auf nächstes zeichen
	DJNZ	wei4 	; 11 zeichen vergleichen
eintr	NOP		; alle zeichen entsprechen den
			; spezifikationen, jetzt müssen
			; sie in einen Buffer
			; eingetragen werden, allerdings
			; in der Form FILENAME/EXT
	LD	A,E	; DE muß um 11 erniedriegt werden
	SUB	11	; damit DE wieder auf Anfang des
	LD	E,A	; filespecs im FDE zeigt
	LD	A,(filzae); zähler für zu kop. Files
	INC	A	; + 1
	LD	(filzae),A	; und speichern
	LD	HL,(buf1); buf1 ist der zeiger auf buffer
	CALL	ein>	; der DOS-Befehl '> 'wird
			; vor die filespecs
			; eingetragen wegen doscall
	LD	B,8	; acht zeichen höchstens
loop4 LD	A,(DE)	; erstes zeichen im buffer
	CP	' '	; ist es space ?
	JR	Z,nein
	LD	(HL),A	; zeichen eintragen
	INC	HL
nein	INC	DE	; zeiger weiter
	DJNZ	loop4 	; bis 8 zeichen
	LD	A,'/'
	LD	(HL),A	; Trennzeichen eintragen
	INC	HL
ext2	LD	B,3	; 3 extension zeichen
loop5 LD	A,(DE)	; erstes zeichen
	CP	' '
	JR	Z,nein2
	LD	(HL),A
	INC	HL
nein2	INC	DE
	DJNZ	loop5
	DEC	HL	; abfrage, ob gar keine extension
	LD	A,(HL)	; vorhanden war, dann muß der '/'
	CP	'/'	; nämlich auch wieder weg
	JR	Z,wei6
	INC	HL
wei6 LD	A,':'	; die zeichen ':lw#,:lw#',0dh
	LD	(HL),A	; werden hinter jeden filenamen
	INC	HL	; eingetragen
	LD	A,(dri1)
	ADD	A,48	; ascii-ausgleich !! accu+48d
	LD	(HL),A  ; dann wird aus 01h 49h,'A' !!
	INC	HL
	LD	A,','
	LD	(HL),A
	INC	HL
	LD	A,':'
	LD	(HL),A
	INC	HL
	LD	A,(dri2) ; destination drive
	ADD	A,48	; ascii-ausgleich !!!!!!!!!!
	LD	(HL),A
	INC	HL
	LD	A,0dh	; ENTER kennung für COPY befehl
	LD	(HL),A	; eintragen
	INC	HL	; zeigt auf das zeichen nach 0dh
	LD	(buf1),HL	; buf1 aktualisieren
; der filename wurde in den buffer eingetragen
; es wird eine ebene zurück gesprungen, ob der
; nexte eintrag gültig ist.
zur}	POP	BC	; die parameter werden
	POP	DE	; zurückgepopt
	POP	HL
	RET
; die Routine ein> fügt den GDOS-Befehl '> '
; also 'COPY ' ein.
; HL zeigt auf den Buffer
ein>	LD	A,'>'
	LD	(HL),A
	INC	HL
	LD	A,' '
	LD	(HL),A
	INC	HL
	RET
wei7 LD	A,'?'	; test ob der joker gestzt ist
	CP	(HL)	; vergleiche mit fname
	JR	Z,wei5 	; wenns ein '?' war, ist der
			; Buchstabe o.K., ansonsten
	JR	zurü	; braucht fname nicht weiter
			; getestet werden, er entspricht
			; nicht
			; der geforderten Spezifikation
ermi	LD	A,1	; im ersten sektor des dir
	CALL	dirr
	LD	A,(421fh); an dem byte 1fh befindet sich
	ADD	A,08h	; die angabe , wieviele fde-
			; sectoren das directory
			; enthält.
	LD	(secanz),A	; speichern
	RET
;
;	Jetzt folgt der eigentliche Kopiervorgang
;	es wird vorher getestet auf anzahl der Files = 	0
;	und auf */*, also kopiere alles
;	außerdem wird nach dem letzten Eintrag als
;	Endemarkierungein 'E' eingesetzzt
;
copy	LD	A,'E'		; Endemarkierung
	LD	(HL),A		; nach dem letzten Befehl
	LD	A,(filzae)	; keine Files  kopieren ?
	CP	00h
	JR	Z,keifil	; Programm beenden
				; vorher Meldung ausgeben
	LD	A,(431Bh)	; erstes Zeichen nach
				; 'KOPIERE '
	CP	'*'		; falls '*/* folgt
	JR	NZ,goon
	LD	A,(431Ch)
	CP	'/'
	JR	NZ,goon
	LD	A,(431Dh)
	CP	'*'
	JR	NZ,goon
	LD	HL,meld1
	CALL	sendms
	LD	HL,meld2
	CALL	sendms
	CALL	getkey
	CP	'j'
	JR	Z,jaJA
	CP	'J'
	JP	NZ,dosrdy
jaJA	LD	A,0dh	; noch ein ENTER ausgeben
	CALL	outch	; auf dem bildschirm ausgeben
	JR	goon
keifil	LD	HL,meld3 ; kein File der Source-Disk
			 ; entspricht den
	CALL	sendms   ; geforderten Spezifikationen
	JP	dosrdy
goon	LD	HL,(buf2)	; anfang des Buffers
wei8    CALL	sendms	; der Copy-Befehl wird auf dem
			; Bildschirm angezeigt.
	LD	HL,(buf2)
	CALL	doscal  ; der Befehl wird ausgeführt
	CALL	NZ,keinfe; falls ein Fehler aufgetr. ist
	LD	A,(3840h)	; tastaturzeile mit BREAK
	BIT	2,A       ; Abbrechen mit <BREAK>-Taste
	JR	Z,wei9
	LD	A,39h	; fehler 'Function Aborted'
	JP	doserr
; Suchroutine um den nächsten Befehl zu finden
wei9    LD	HL,(buf2); anfang des letzten Befehls
	LD	B,0
	LD	C,9; der nächste Befehl kommt frühestens
	ADD	HL,BC		; nach 9 Zeichen.
loop6 LD	A,(HL)
	CP	0dh	; kommt schon der nächste ?
	JR	Z,wei10
	INC	HL		; zeiger ein weiter
	JR	loop6 		; ohne ende .
wei10	INC	HL		; ein hamwa noch
	LD	A,(HL)
	CP	'>'		; normaler Befehl ?
	JP	NZ,dosrdy  ;  wenn nicht, wars der letzte
	LD	(buf2),HL  ; buf2 zeigt auf den nächsten
	JR	wei8	;Befehl und so weiter und so fort
keinfe	CP	1ah	; fehlermeldung 'Directory voll'
	JR 	Z,loefil; letzten File wieder loeschen
	CP	1bh	; 'Diskette voll '	??????
	JR	Z,loefil
	CP	1eh	; 'Directory voll bei Erw. ' ??
	JR	Z,loefil
	CP	21h	; 'Kein Platz auf Diskette ' ??
	JR	Z,loefil
	JP	doserr
loefil	LD 	HL,4326h; letztes (moegliches)
			; signifikantes
			; Zeichen des Copy-Befehls
	LD	DE,4329h	; die ganze Zeichenkette
				; soll um 3 Zeichen nach
				;hinten verschoben werden
	LD	BC,000dh	; sie ist 14 Zeichen lang
				; und zwar 'Filename/Ext'
				; + <ENTER> + ein blank
				; nach dem '>' !!
	LDDR			; verschiebebefehl
				; (Mit DEC der Parameter !)
	LD	HL,kill		; source ist 'KILL '
	LD	DE,4318h	; Anfang  Befehlsbuffer
	LD	BC,0005h	; übertrage 5 Zeichen
	LDIR			; also los
	EX	DE,HL		; Austausch HL <> DE
findde	INC	HL		; suche den Doppelpunkt
				; für Destination
	LD	A,(HL)		; Drive Eintrag
	CP	':'
	JR	NZ,findde	;solange bis ':' gefunden
	INC	HL		; zeiger auf Drive-#
	LD	A,(dri2)	; Destination-Drive
	ADD	A,'0'		; ASCII-Ausgleich
	LD	(HL),A		; eintragen
	INC	HL
	LD	A,0dh		;<cr> am Schluß eintragen
	LD	(HL),A
	LD	HL,4318h	; Befehlsbuffer des DOS
	CALL	sendms		; auf Display anzeigen
	LD	HL,4318h
	CALL	doscal		; ausführen
	JP	Z,noerr  	; zurück ins DOS
	LD	HL,meld4	; ansonsten Fehlermeldung
	CALL	sendms		; ausgeben
	JP	dosrdy		; und zurueck ins DOS
noerr	LD	HL,meld5	; 'Diskette voll' ausg.
	CALL	sendms
	JP	dosrdy
kill	DEFM	'KILL '		; DOS-BEFEHL KILL
meld1	DEFM	'Alle Dateien kopieren? ',03h
meld2	DEFM	'Bitte mit <J> bestätigen ',0dh
meld3	DEFM	'Keine Files der Spezifikation '
	DEFM	'vorhanden.',0dh
meld4	DEFM	'Der letzte kopierte File muss '
	DEFM	'noch gelöscht werden.',0dh
meld5	DEFM	'Diskette voll !!!!!!',0dh
buffer	EQU	$
	END	start
