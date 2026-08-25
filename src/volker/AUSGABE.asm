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
	LD	A,20h    	;Trennzeichen
	CALL	ausa		;und ausgeben
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
