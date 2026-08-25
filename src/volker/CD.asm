;		Change Directory
;
;
;	Setzt Defaultlaufwerk nach Namens eingabe
;
;	RAMDISK		- LW# 2
;	DOS			- LW# 5
;	SOURCES		- LW# 6
;	WORKBENC	- LW# 7
;	DATEN		- LW# 8
;	SONSTIGES	- LW# 9
;	DISK0		- LW# 0
;	DISK1		- LW# 1
;
;
dosrdy	EQU	402dh
doserr	EQU	4409h
gibaus	EQU	4467h
dirlw	EQU	43a0h
openlw	EQU	43a1h
verglei	EQU	4cc5h

	ORG	3000h		; sollte platz sein
start	PUSH	HL		; HL retten
	POP	DE		; HL -> DE
	LD	BC,text0	; 'DISK0',00
	CALL	verglei
	JR	Z,eintrag	; wenn text gleich, weiter
	PUSH	DE
	POP	HL
	LD	BC,text1        ; 'DISK1',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text2	; 'RAMDISK',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text5	; 'DOS',00
	CALL	verglei		;
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text6	; 'SOURCES',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text7	; 'WORKBENC',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text8	; 'DATEN',00
	CALL	verglei
	JR	Z,eintrag
	PUSH	DE
	POP	HL
	LD	BC,text9	; 'SONSTI',00
	CALL	verglei
	JR	Z,eintrag
abgang	LD	A,20h		; 'unzulässiges od. Fehlendes LW'
	OR	A
	JP	doserr
eintrag	LD	A,(BC)
	LD	(dirlw),A	; lwnummern eintragen
	LD	(openlw),A
;
; ab hier soll in bank 0 der name gepatcht werden, dessen laufwerks
; nummer gewählt wurde.
	IN	A,(0f9h)	;sysport 0 ist der Bankingport
	RES	0,A		; common unten
	RES	6,A		; bank 0 anwählen
	RES	7,A		;  dito
	DI			; jetzt wirds heikel
	OUT	(0f9h),A	; diese Konfiguration ausgeben
	INC	BC		; bc muß um 5 erniedrigt werden
	     		; um auf den Anfang von
	 	  		; text(x)	zu zeigen
	LD	H,B		; wegen LDIR, source ist HL
	LD	L,C		; nicht wahr
	LD	DE,8fa4h	; ist in dem gebankten SYS1 der
	LD	BC,0010h	; Bank 0 die adresse des DOS-Ready
	LDIR			; strings, wird so gepatcht
	LD	A,40h		; normale konfiguration von port
	OUT	(0f9h),A	; f9
	EI
	JP	dosrdy
text0	DEFM	'DI0',00,00,':0Disk_0 >',1eh,03
text1	DEFM	'DI1',00,01,':1Disk_1 >',1eh,03
text2	DEFM	'RAM',00,02h,':2Ramdisk >',1eh,03
text5	DEFM	'DOS',00,05,':5CalvaDOS >',1eh,03
text6	DEFM	'SOU',00,06,':6Sources >',1eh,03
text7	DEFM	'WOR',00,07,':7Workbench >',1eh,03
text8	DEFM	'DAT',00,08,':8Daten >',1eh,03
text9	DEFM	'SON',00,09,':9Sonstiges >',1eh,03
	END	start
