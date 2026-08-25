;
;	I	N	V	/	C	M	D
;
;	INV/CMD zeigt auf dem angegebenen Laufwerk nur die
;	unsichtbaren Files an.
;
;	SYNTAX :=  INV <LW#><ENTER>
;
;
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
	ORG	5200h
lwnum	DEFM	'0'
debuf	DEFW	1806h   ;18h=24 Zeilen mit 6 Filenames /Zeile
fdeanz	DEFW	0000h	; hier steht wieviele Files angezeigt wurden
secanz	DEFB	01h	; Anzahl der DIR-Sektoren, wird incrementiert
secbuf	DEFB	00h	; Hier steht die Anzahl immer !
;
;
;

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
start	LD	IX,fdeanz	; IX wird der Zähler für die angz.Files
	LD	(IX+0),00h
	LD	A,(HL)
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
	LD	(secanz),A	; 1 erhöhen und zurückschr.
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
	CP	18h		; ist es ein FPDE ?
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
eintrag	LD	DE,(debuf)
	CALL	ausgabe
	LD	(debuf),DE
	INC	(IX+0)		; fdeanzahl=fdeanz+1
zur}ck	POP	HL
	POP	BC
	RET
dirfert	JP	dosrdy
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

	LD	E,6		;wieder auf 6 stellen
	DEC	D		;Zeilenzähler -1
	JR	NZ,neuz		;neue Zeile anzeigen
	LD	D,18h		;wieder auf 24 Zeilen stellen
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
