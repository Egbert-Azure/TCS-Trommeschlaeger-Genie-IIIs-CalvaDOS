;
;	WO/CMD
;
; 	Programm, um genau ein bestimmtes Programm auf allen
;	angeschlossenen Laufwerken zu finden.
;	Der Suchvorgang funktioniert mit der Errechnung des
;	HASH-Codes, es muß von jedem Laufwerk also nur der HIT-
;	Sector eingelesen werden.
;	Das geht natürlich erheblich schneller.
;
dosrdy	EQU	402dh
gibaus	EQU	4467h
doserr	EQU	4409h
debug	EQU	440dh
tstdsk	EQU	445eh
dirrea	EQU	490ah
getfde	EQU	4936h
;
	ORG 5200h
filspe	DEFM	20h,20h,20h,20h,20h,20h,20h,20h; 8 Zeichen Filespec.
extspe	DEFM	20h,20h,20h	; 3 Zeichen für Extension
aktlw	DEFM	00	; Suche starten bei LW# 0, wird hochgezählt
hashco	DEFM	00h	;hier wird der errechnete Hashcode eingetragen
;
start	PUSH	HL	; zeigt auf den eingegenben Filenamen
	LD	DE,filspe
	LD	B,09h	; 8 Zeichen für			"
nloop	LD	A,(HL)
	CP	0dh	; ENTER ?
	JR	Z,rechne
	CP	'/'	; Trennzeichen zur Extension ?
	JR	Z,ext
	LD	(DE),A
	INC	DE
	INC	HL
	DJNZ	nloop	; bis 8 Zeichen in Buffer übertragen(Höchstens)
	CP	'/'	; folgt jetzt der slash ?
	LD	A,13h
	JP	NZ,doserr
ext	LD	B,03h	; 3Zeichen für Extension
	INC	HL
	LD	DE,extspe
eloop	LD	A,(HL)
	CP	0dh
	JR	Z,rechne
	LD	(DE),A
	INC	DE
	INC	HL
	DJNZ	eloop
	LD	A,(HL)
	CP	0dh	; hernach also hier muß!! Enter sein
	LD	A,13h
	JP	NZ,doserr
rechne	LD	HL,filspe	; diese Routine errechnet den HASH-Code
	LD	B,0bh		; sie ist abgeschrieben aus SYS2/SRC
	XOR	A
rloop	XOR	(HL)
	INC	HL
	RLCA
	DJNZ	rloop
	JR	NZ,fertig
	INC	A
fertig	LD	(hashco),A	; abspeichern.
;	Der HASH-Code ist errechnet, jetzt müssen alle HIT-Sectoren
;	eingelesen und der Inhalt derselben mit dem hashco verglichen
;	werden. Dann muss der jeweilige FDE geholt werden und mit
;	filspe verglichen werden. Erst dann ist der Filename gefunden.
;
drloop	LD	A,(aktlw)	; LW# laden
	CALL	tstdsk		; ist eine Disk eingelegt ??
	CALL	Z,liehit	; wenn ja, lies den HIT-Sector
	LD	A,(aktlw)
	INC	A
	CP	0ah		; schon über 9 hinaus ?
	JP	Z,ende
	LD	(aktlw),A
	JR	drloop
ende	LD	HL,text1
	CALL	gibaus
	JP	dosrdy
liehit	LD	A,01h		; HIT-Sector
	CALL	dirrea
	JP	NZ,doserr	; falls Fehler(sehr unwahrscheinlich)
	LD	B,0ffh
	LD	A,(hashco)
sloop	CP	(HL)		; sucht den gesamten Sectorpuffer ab
	CALL	Z,su_fde	; wenn der hashcode stimmt, muß der
	INC	HL		; zuständige FDE mt filspe verglichen
	DJNZ	sloop		; werden.

	RET
su_fde	PUSH	HL
	PUSH	AF
	PUSH	BC
	LD	A,L		; L ist LSB des Sectropufferzeigers,
	CALL	getfde		; und ist genau der FDE im Directory
	LD	DE,filspe
	LD	BC,0005h	; FILENAME steht an 5.ter Stelle
	ADD	HL,BC		; jetzt zeigt HL auf den FILENAMEEXT
	LD	B,0bh
fdloop	LD	A,(DE)
	CP	(HL)
	JR	NZ,nein
	INC	DE
	INC	HL
	DJNZ	fdloop
ja	LD	A,(aktlw)
	ADD	A,'0'		; binär => ASCII
	LD	(lwnum),A
	LD	HL,text2
	CALL	gibaus
nein	LD	A,01h		; der HIT-Sector muss wieder eingelesen
	CALL	dirrea		; werden, er wurde überschrieben
	POP	BC
	POP	AF
	POP	HL
	RET
text2	DEFM	'File gefunden auf Laufwerk# '
lwnum	DEFM	'0.',0dh
text1	DEFM	'Alle Laufwerke sind durchsucht.',0dh
	END	start
