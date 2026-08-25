;
;
;	F	I	N	D	/	C	M	D
;
;	soll auf der Hard-, Ram- und eventuell Floppydisk
; 	Programme finden, ähnlich einem DIR */*:*
;	also Filenamen, Extensions und auch Laufwerknummer
;	können beliebig angegeben werden.
;	Die Directoryunterfunktionen I(-nvisible),S(-ystem),
;	A(-lles) werden nicht implementiert.
;	File ist File. Die Laufwerksangabe ist * für alle,
;	bzw. explizite Lw#-angabe.
;	Man kann auch den :* weglassen und enfach ENTER nach der
;	Filespezifikation angeben
;
dosrdy	EQU	402dh
doserr	EQU	4409h
debug	EQU	440dh
dirrea	EQU	490ah
gibaus	EQU	4467h
tesdsk	EQU	445eh
;
;
;
;
;
;	Dies ist ein Teilstück des Programmes
;		KOPIERE/CMD
;	und zwar wird hier die richtige Eingabe des Filenamens
;	kontrolliert, und zwar Test auf ?,* inklusive.
;	Man kann jetzt allerdings auch Zahlen und das Zeichen '_'
;	eingeben(allerdeings auch an erster Stelle, was eigentlich
;	nicht in Ordnung ist).
;
	ORG	5200h
fname	DEFM	'FILENAME';wird vom Progr. eingesetzt
exten	DEFM	'EXT'	  ;hier steht dann der Vergleichsstring
ende	DEFM	0dh
lwnum	DEFM	'0'
debuf	DEFW	0E05h   ;0Eh=14 Zeilen mit 5 Filenames /Zeile
fdeanz	DEFW	0000h	; hier steht wieviele Files angezeigt wurden
secanz	DEFB	01h	; START der FDE-Sektoren in DIR/SYS
secbuf	DEFB	00h	; Hier wird eingetragen, wie viele DIR-Sektoren
;
;
;

start	LD	B,09h	; max. 8Zeichen für Filename
	LD	DE,fname; Zeiger auf 		"
loop1	LD	A,(HL)	; zeichen holen
	CP	'?'	; wenn ja einfach eintragen
	JR	Z,wei1
	CP	'_'
	JR	Z,wei1
	CP	'0'	; ist es eine Ziffer
	JR	C,buchst
	CP	3ah     ; der Doppelpunkt kommt gleich nach '9'
	JR	NC,buchst
	JR	wei1
buchst	CP	'A'
	JR	C,kzeich; wenn Carry gesetzt, ist
			;das Zeichen in der
			;ASCII-Tabelle kleiner als 'A'
	CP	'^'
	JR	NC,kzeich; bzw. es ist oberhalb von 'Ü'
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
	CP	'?'	;einfach weiter
	JR	Z,wei2
	CP	' '	; blank ?
	JR	Z,wei2	; ist schon o.K.
	CP	'A'
	JR	C,keexze; wenn enter, dann o.k.
	CP	'^'
	JR	NC,keexze; dito
wei2	LD	(DE),A	; buchstabe eintragen
	INC	DE
	DJNZ	loop2	; bis 3 Zeichen
	CP	':'	; 13. Zeichen LW-Doppelpunkt ?
	JR	Z,progr;
	CP	0dh	; ist es Enter ?
	JP	Z,alle	; geht auch
	JP	error
keexze	CP	'*'	; mit ?? aufüllen
	JR	Z,stern1
	CP	':'
	JR  	Z,progr; jetzt folgt die LW#
	CP	0dh	; ENter	?
	JP	Z,alle
	CALL	nulauf
	LD	A,0dh
	LD	(ende),A
	JR	progr
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
	DEC	B
	CALL	fill	; ausfüllen,
	INC	HL	; soll auf ':' zeigen
	LD	DE,ende	; aufs ende von fname
	LD	A,(HL)	; zeichen holen
	CP	':'	; wegen LW#
	JR	Z,progr
	CP	0dh	; ohne Laufwürgsbezeichnug heißt alle
	JP	Z,alle
	JR	error	; soll funktionieren
error	LD	A,2fh 	; 'schlechte parameter
	JP	doserr
istzahl	SUB	'0'	; ascii korrektur
	JR	C,error
	CP	10
	RET	C
	JR	error
;
;
;  Hier fängt das Hauptprogramm an
;
progr	LD	IX,fdeanz	; IX wird der Zähler für die angz.Files
	LD	(IX+0),00h
	INC	HL	; zeigt jetzt auf lwnummer
	LD	A,(HL)
	CP	'*'
	JP	Z,alle
	CALL	istzahl
eindir	LD	(lwnum),A	; hier die Routine für genau 1 Laufwerk
	ADD	A,'0'		; binär=>ASCII
	LD	(dnum),A	; ist für U-Prog. zeile
	CALL	zeile		; hierwird die Lw# sowie der Name
	CALL	diskdir		; des Lw's auf den Bildschirm gebracht
	LD	A,(IX+0)	; Wieviele Files sind angezeigt ?
	CP	00h		; wenn kein File der Spezi. genügte
	JP	NZ,dosrdy	; dann wird die 'zeile' wieder gelöscht
	LD	A,1bh		; Cursor eine Zeile höher
	CALL	0033h		; auf den Bildschirm
	JP	dosrdy		; jetzt aber Abgang
diskdir	CALL	ermittl
dirwei	LD	A,(secanz)
	INC	A
	LD	(secanz),A	; 1 erniedriegen und zurückschr.
	PUSH	HL
	LD	HL,secbuf
	CP	(HL)
	POP	HL
	RET	Z		; hier ist der AUSGANG der U-Routine
dirsec	CALL	dirrea		; ließt einen Dirsector
	JP	NZ,doserr	; falls ein Fehler auftrat
	CALL	auswert
	JP	dirwei
ermittl	LD	A,01h		; HIT-Sector
	CALL	dirrea
	LD	A,(421fh)	; hier steht die Anzahl der
	ADD	A,0ah		; Dirsec. minus 10 inkl.HIT&GAT
				; + noch einen weiß der Geiger warum
	LD	(secbuf),A
	RET
auswert	LD	BC,0800h	; 8 Einträge pro Sector
awloop	LD	A,(HL)		; erstes Zeichen des FDE's
	AND	90h		; alle außer b7 & b4 werden gelöscht
	CP	10h		; ist es ein FPDE ?
	JR	NZ,fxde		; wenn nicht war b7=1 oder b4=0
				; herumrechnen zu müssen.
	LD	A,L		; jetzt soll HL auf den Filename zeigen
	ADD	A,05h		; der ist bei FDE+5
	LD	L,A		; HL auffrischen
	CALL	verglei		; vergleichen und anzeigen
	LD	A,1bh		; 5 weniger als bei keinem Eintrag
	JR	fpde
fxde	LD	A,20h
fpde	ADD	A,L
	LD	L,A		; HL zeigt auf den nächsten FDE
	DJNZ	awloop		; bis 8 FDE's verglichen wurden
	RET			; un wieder eine Ebene höher
verglei	PUSH	BC		; einen Zähler brauch ich selbst
	PUSH	HL
	LD	B,11		;
	LD	DE,fname	; Vergleichsfilespezifikation

verloop	LD	A,(DE)
	CP	'?'
	JR	Z,veregal		; wenn ?, dann ist alles erlaubt
	CP	(HL)		; ist es gleich dem FDE ?
	JR	NZ,zurück	; falls nciht, noch mal POPen
veregal	INC	DE
	INC	HL		; beide Zeiger ein Weiter
	DJNZ	verloop		; 11 zeichen
	POP	HL
	PUSH	HL
eintrag	LD	DE,(debuf)
	CALL	ausgabe
	LD	(debuf),DE
	INC	(IX+0)		; fdeanzahl=fdeanz+1
zur}ck	POP	HL
	POP	BC
	RET
dirfert	LD	A,0dh
	CALL	ausa
	JP	dosrdy
;
;
;
;
zeile	LD	A,(lwnum)	;Hier wird die Laufwerksnummer und der
	CALL	tesdsk		;Diskettenname auf dem Bildschirm
	JP	NZ,doserr	; angezeigt.
	LD	A,00h		; Name ist im GAT-Sector an Position
	CALL	dirrea		; Byte D0h bis D7h
	LD	HL,42d0h
	LD	DE,dname
	LD	BC,0008h	; 8 Zeichen
	LDIR
	LD	HL,zeitxt
	CALL	gibaus		; den gesamten String ausgeben
	RET			; ist ein Unterprogramm
zeitxt	DEFM	'in :'
dnum	DEFB	00h
	DEFM	''
dname	DEFM	'DISKNAME ',0dh
;
;
;
alle	LD	A,09h		; alle heißt das ein oder mehrer Files
aloop	LD	(lwnum),A	; auf allen verfügbaren Laufwerken gesuch
	CALL	tesdsk		; ist überhaupt erreichbar ?
	JR	NZ,is_nich	; zerobit =0 bei keinem fehler
is_doch	LD	A,(lwnum)
	ADD	A,'0'		; binär => ASCII
	LD	(dnum),A	; in zeitxt
	LD	(IX+0),00h	; fdezähler
	CALL	zeile		; Diskname usw.
	CALL	diskdir		; Inhaltsverzeichnis durchstöbern
	LD	A,(IX+0)	; ist mindestens ein File gefunden worden
	CP	00h
	JR	NZ,is_nich
	LD	A,1bh		; cursor eine Zeile höher
	CALL	0033h
is_nich	LD	A,0bh		; zeilenvorschub wenn nicht schon
	CALL	0033h
	LD	A,01h		; bei 'alle' muß jedesmal der secanz neu
	LD	(secanz),A	; auf den ersten DEC-Sektor gesetzt werdn
	LD	A,(lwnum)
	DEC	A
	LD	(lwnum),A
	CP	01h		; 9 laufwerke durch ?
	JR	NZ,aloop	; sonst weiter suchen
	JP	dosrdy
;
;
;	Ab hier liegen Unterroutinen, die ich von Andreas Magnus
;	einfach übernommen habe. Moin, moin Andreas !
;	Sie stammen aus seinem höchst nützlichen Programm
;
;	   DIRVERGL/CMD
; 	Und machen die Bildschirmausgabe so schön einfach.
;
;UP AUSGABE: gibt den Filenamen in HL auf dem Bildschirm oder Drucker aus
;            und zwar 6 Files nebeneinander und 24 files pro Schirm

ausgabe LD	B,08h		;8 Byte Filenamen
	LD	C,H		;H sichern, wird noch gebraucht
	CALL	aushl		;und ausgeben
	LD	A,20h		; ein Space zum Trennen
	CALL	ausa
	LD	B,03h		;3 Byte Extension
	CALL	aushl		;auch ausgeben
	LD	A,':'
	CALL	ausa		; hier den Doppelpunkt
	DEC	E        	;(Filenamen nebeneinander)
	LD	H,C		;H vorsichtshalber zurück
	RET	NZ       	;alles klaro

	LD	E,5		;wieder auf 6 stellen
	DEC	D		;Zeilenzähler -1
	JR	NZ,neuz		;neue Zeile anzeigen
	LD	D,0Eh		;wieder auf 24 Zeilen stellen
	EX	DE,HL		;Zähler sichern
	CALL	warte		;auf Tastendruck warten
	EX	DE,HL		;und Zähler zurück
neuz	LD	A,08h		;CR => A
	CALL	ausa		;und anzeigen und zurück
	LD	H,C		;H jetzt entgültig zurück
	RET

;UP AUSHL: gibt B Zeichen lang (HL) ff aus

aushl	LD	A,(HL)		;Zeichen in den	ACCU
	CALL	ausa		;und ausgeben
	INC	HL		;auf nächste Stelle
	DJNZ	aushl		;bis alle Angezeigt
	RET

;UP AUSA: gib den ACCU auf dem Bildschirm oder Drucker aus

ausa	PUSH	DE		;Zeilenzähler retten
	CALL	0033h		;oder 3bh für Drucker
	POP	DE
	RET

;UP WARTE: wartet bis CR gedrückt ist

warte	CALL	0049h		;auf Tastendruck warten
	CP	0dh		;war es Enter ?
	RET	Z		;zurück wenn ja
	JR	warte		;weiter warten
;
;
;
;
	END	start
