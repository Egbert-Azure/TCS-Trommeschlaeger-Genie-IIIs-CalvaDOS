;************************************************************************
;
; HDFORMAT/CMD, stock GDOS 2.4 (src/GDOS-2.4-HD-tools/HDFORMAT.CMD)
;
; Disassembled by E.H. Schroeer
; Name: hdformat-cmd-disassembly.asm
; Date: 2026/08/30
;
;************************************************************************
;
; From DMK/G3S-GDOS24.DMK. One load block, entry 7000h:
;
;   0x0000  LOAD  211B  7000..70D2
;   0x00d9  ENTRY 7000
;
;   z80dasm -g 0x7000 -l -a hdformat_flat.bin

LINPUT  EQU	0040h		;ROM: read a line
DOSRDY  EQU	402dh		;return to the DOS prompt
ERRORO  EQU	4030h		;DOS error output
m414a	EQU	414ah
SECBUF  EQU	4200h		;DOS sector buffer
m4201	EQU	4201h
m4202	EQU	4202h
DOSERR  EQU	4409h		;DOS error exit
DSPLY   EQU	4467h		;display the text at (HL)
DXFER   EQU	4642h		;transfer entry, hooked by this port's driver
DRVSEL  EQU	4776h		;select a drive

	org 07000h

; Prompt (string at 708Dh: "Wollen Sie die HARDDISK tatsaechlich
; loeschen? "), read 4 chars, require "JA" or abort with no output.

7000  21 8d 70    ld hl,l708dh
7003  cd 67 44    call DSPLY
7006  21 00 42    ld hl,SECBUF
7009  06 04       ld b,004h
700b  cd 40 00    call LINPUT
700e  2a 00 42    ld hl,(SECBUF)
7011  cb ac       res 5,h
7013  cb ad       res 5,l
7015  11 4a 41    ld de,m414a		;'J','A'
7018  df          rst 18h		;compare
7019  c2 30 40    jp nz,ERRORO		;no match -> abort

; 3rd typed char selects the unit: not '2' = unit 1 below, '2' = unit 2
; at l704bh. DRVSEL is a SASI unit select, not a GDOS drive number.

701c  3a 02 42    ld a,(m4202)
701f  fe 32       cp 032h			;'2'
7021  ca 4b 70    jp z,l704bh

; Unit 1: DRVSEL A=9, fill E5h.

7024  3e 09       ld a,009h
7026  cd 76 47    call DRVSEL
7029  c2 09 44    jp nz,DOSERR
702c  21 bb 70    ld hl,l70bbh		;"Durchgang 1"
702f  cd 67 44    call DSPLY
7032  2e 05       ld l,005h
7034  3e f7       ld a,0f7h
7036  cd 75 70    call sub_7075h
7039  3e e5       ld a,0e5h		;fill byte
703b  cd 7f 70    call sub_707fh
703e  3e f4       ld a,0f4h
7040  cd 75 70    call sub_7075h
7043  3e f6       ld a,0f6h
7045  cd 75 70    call sub_7075h
7048  c2 09 44    jp nz,DOSERR

; Unit 2: DRVSEL A=5, fill 6Ch.

l704bh:
704b  3e 05       ld a,005h
704d  cd 76 47    call DRVSEL
7050  c2 09 44    jp nz,DOSERR
7053  21 c7 70    ld hl,l70c7h		;"Durchgang 2"
7056  cd 67 44    call DSPLY
7059  2e 13       ld l,013h
705b  3e f7       ld a,0f7h
705d  cd 75 70    call sub_7075h
7060  3e 6c       ld a,06ch		;fill byte
7062  cd 7f 70    call sub_707fh
7065  3e f4       ld a,0f4h
7067  cd 75 70    call sub_7075h
706a  3e f6       ld a,0f6h
706c  cd 75 70    call sub_7075h
706f  c2 09 44    jp nz,DOSERR
7072  c3 2d 40    jp DOSRDY

; DXFER wrapper: err-check the result.

sub_7075h:
7075  11 00 00    ld de,0000H
7078  cd 42 46    call DXFER
707b  c8          ret z
707c  c3 09 44    jp DOSERR

; Fill SECBUF (256 bytes) with A, advance to the next controller param.

sub_707fh:
707f  21 00 42    ld hl,SECBUF
7082  11 01 42    ld de,m4201
7085  77          ld (hl),a
7086  01 ff 00    ld bc,00FFH
7089  ed b0       ldir
708b  2c          inc l
708c  c9          ret

; data from here to EOF, disassembled as code
l708dh:
708d  57          ld d,a
708e  6f          ld l,a
708f  6c          ld l,h
7090  6c          ld l,h
7091  65          ld h,l
7092  6e          ld l,(hl)
7093  20 53       jr nz,$+85
7095  69          ld l,c
7096  65          ld h,l
7097  20 64       jr nz,$+102
7099  69          ld l,c
709a  65          ld h,l
709b  20 48       jr nz,$+74
709d  41          ld b,c
709e  52          ld d,d
709f  44          ld b,h
70a0  44          ld b,h
70a1  49          ld c,c
70a2  53          ld d,e
70a3  4b          ld c,e
70a4  20 74       jr nz,$+118
70a6  61          ld h,c
70a7  74          ld (hl),h
70a8  73          ld (hl),e
70a9  7b          ld a,e
70aa  63          ld h,e
70ab  68          ld l,b
70ac  6c          ld l,h
70ad  69          ld l,c
70ae  63          ld h,e
70af  68          ld l,b
70b0  20 6c       jr nz,$+110
70b2  7c          ld a,h
70b3  73          ld (hl),e
70b4  63          ld h,e
70b5  68          ld l,b
70b6  65          ld h,l
70b7  6e          ld l,(hl)
70b8  3f          ccf
70b9  20 03       jr nz,l70beh
l70bbh:
70bb  44          ld b,h
70bc  75          ld (hl),l
70bd  72          ld (hl),d
l70beh:
70be  63          ld h,e
70bf  68          ld l,b
70c0  67          ld h,a
70c1  61          ld h,c
70c2  6e          ld l,(hl)
70c3  67          ld h,a
70c4  20 31       jr nz,$+51
70c6  0d          dec c
l70c7h:
70c7  44          ld b,h
70c8  75          ld (hl),l
70c9  72          ld (hl),d
70ca  63          ld h,e
70cb  68          ld l,b
70cc  67          ld h,a
70cd  61          ld h,c
70ce  6e          ld l,(hl)
70cf  67          ld h,a
70d0  20 32       jr nz,$+52
70d2  0d          dec c
