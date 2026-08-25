;	BACKUP/CMD
;
;
; dieses Programm soll von der Festplatte Backup's erstellen.
; Es tut dies indem nur Files kopiert werden, deren Bearbeitungs-
; kennzeichen gesetzt ist. Dies ist der Fall, wenn ein File neu
; in ein Directory eingetragen wurde oder wenn das File verändert
; wurde. Man wird aufgefordert, die Backup-Disketten 5 bis 9
; nacheinander einzustecken.
;
;
;
gibaus	EQU	4467h
dosrdy	EQU	402dh
doscal	EQU	4419h
doserr	EQU	4409h
datum	EQU	4470h
	ORG 	3000h
start	LD	A,(HL)
	CP	0dh
	JR	Z,alle
	SUB	'5'		; gültige LW# sind 5,6,7,8,9
	JR	C,error
	CP	10
	JR	C,eintrag
error	LD	A,32
	OR	A
	JP	doserr
eintrag	ADD	A,'5'
	LD	(cpnum),A
	LD	(prnum),A
	LD	(lgnum),A
	LD	(afnum),A
	CALL	backup
	JR	ende
alle	LD	BC,0500h	;	5 HD-laufwerke
loop	PUSH	BC		; 	BC wegen Registerveränderungen pushen
	LD	A,(speich)
	INC	A		; a => '5', usw.
	LD	(speich),A	; zwischenspeichern
	LD	(cpnum),A
	LD	(prnum),A
	LD	(lgnum),A
	LD	(afnum),A
	CALL	backup
	POP	BC		; BC vom Stack, schön warm und trocken
	DJNZ	loop
ende	LD	HL,endtex
	CALL	gibaus
	JP	dosrdy
endtex	DEFM	'Der Backupvorgang ist abgeschlossen.',0dh
;
backup	LD	HL,auffor
	CALL	gibaus
loop1	LD	A,(3840h)
	CP	01h		; <ENTER> gedrückt??
	JR	NZ,loop1
	LD	HL,losgeh
	CALL	gibaus
	LD	HL,copy
	CALL	doscal
	CALL	NZ,doserr
	LD	HL,prot
	CALL	doscal
	CALL	NZ,doserr
	LD	HL,buff
	CALL	datum
	LD	HL,prot0		; neuestes Datum auf Disk 0
	CALL	doscal
	CALL	NZ,doserr
	RET
;
auffor	DEFM	07h,20h,0bh,'Lege Backup-Disk für HD LW# '
afnum	DEFM	'5'
	DEFM	' ein. Dann <ENTER>.',0dh
losgeh	DEFM	'Backup von Festplattenlaufwerk '
lgnum	DEFM	'5'
	DEFM	'.',0dh
copy	DEFM 	'> '
cpnum	DEFM	'5'
	DEFM	',0,,nfmt,kdwa,edk,bea',0dh
prot	DEFM	'prot :'
prnum	DEFB	'5'
	DEFM	',bkl',0dh
prot0	DEFM	'prot :0,datum='
buff	DEFM	'00.00.00',0dh
speich	DEFM	'4'
	END	start
