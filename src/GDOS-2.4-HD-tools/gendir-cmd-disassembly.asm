;************************************************************************
;
; GENDIR/CMD, stock GDOS 2.4 (src/GDOS-2.4-HD-tools/GENDIR.CMD)
;
; Disassembled by E.H. Schroeer
; Name: gendir-cmd-disassembly.asm
; Date: 2026/08/30
;
;************************************************************************
;
; From DMK/G3S-GDOS24.DMK. Four load blocks, entry 5200h:
;
;   0x0000  LOAD  256B  5200..52FF
;   0x0104  LOAD  256B  5300..53FF
;   0x0208  LOAD  256B  5400..54FF
;   0x030c  LOAD   12B  5500..550B
;   0x031a  ENTRY 5200
;
;   z80dasm -g 0x5200 -l -a gendir_flat.bin

DOSRDY  EQU	402dh		;return to the DOS prompt
ERRORO  EQU	4030h		;DOS error output
SECBUF  EQU	4200h		;DOS sector buffer
m4201	EQU	4201h
m4202	EQU	4202h
m4205	EQU	4205h
DIRLEN  EQU	421fh		;length of the directory field
m4260	EQU	4260h
m42c0	EQU	42c0h
DPPTR   EQU	4399h		;pointer into the PDRIVE table
DOSERR  EQU	4409h		;DOS error exit
m445e	EQU	445eh
DSPLY   EQU	4467h		;display the text at (HL)
m4470	EQU	4470h
READS   EQU	4630h		;read a physical sector
WRITDS  EQU	463ch		;write a directory sector
WRITES  EQU	4640h		;write a physical sector
MULHL   EQU	4c92h		;HL * A
MULOV   EQU	4c94h		;HL * A, overflow
m4cb2	EQU	4cb2h
DGRAN2  EQU	4cb3h		;sectors per GRAN, second copy
CHKCHR  EQU	4cd5h		;test the character at (HL)

	org 05200h

; Parse ":N"/"N" (drive number) plus an optional 8-char volume name.

5200  cd d5 4c    call CHKCHR
5203  20 05       jr nz,l520ah
l5205h:
5205  3e 2f       ld a,02fh
l5207h:
5207  c3 09 44    jp DOSERR
l520ah:
520a  7e          ld a,(hl)
520b  fe 3a       cp 03ah
520d  20 01       jr nz,l5210h
520f  23          inc hl
l5210h:
5210  7e          ld a,(hl)
5211  23          inc hl
5212  e6 0f       and 00fh
5214  cd 5e 44    call m445e
5217  20 ee       jr nz,l5207h
5219  e5          push hl
521a  21 e4 54    ld hl,l54e4h
521d  cd 70 44    call m4470
5220  e1          pop hl
5221  cd d5 4c    call CHKCHR
5224  28 47       jr z,l526dh
5226  7e          ld a,(hl)
5227  fe 41       cp 041h
5229  38 2a       jr c,l5255h
522b  fe 5e       cp 05eh
522d  30 26       jr nc,l5255h
522f  eb          ex de,hl
5230  21 dc 54    ld hl,l54dch
5233  06 08       ld b,008h
l5235h:
5235  36 20       ld (hl),020h
5237  23          inc hl
5238  10 fb       djnz l5235h
523a  eb          ex de,hl
523b  11 dc 54    ld de,l54dch
523e  06 08       ld b,008h
l5240h:
5240  7e          ld a,(hl)
5241  fe 0d       cp 00dh
5243  28 28       jr z,l526dh
5245  fe 2c       cp 02ch
5247  28 0c       jr z,l5255h
5249  fe 20       cp 020h
524b  28 08       jr z,l5255h
524d  da 05 52    jp c,l5205h
5250  12          ld (de),a
5251  23          inc hl
5252  13          inc de
5253  10 eb       djnz l5240h
l5255h:
5255  cd d5 4c    call CHKCHR
5258  28 13       jr z,l526dh
525a  06 08       ld b,008h
525c  11 e4 54    ld de,l54e4h
l525fh:
525f  7e          ld a,(hl)
5260  fe 2e       cp 02eh
5262  38 09       jr c,l526dh
5264  fe 3a       cp 03ah
5266  38 05       jr c,l526dh
5268  12          ld (de),a
5269  23          inc hl
526a  13          inc de
526b  10 f2       djnz l525fh
l526dh:
526d  cd d5 4c    call CHKCHR
5270  20 95       jr nz,l5207h

; IX = GDOS's drive/PDrive table entry for this drive.

5272  dd 2a 99 43 ld ix,(DPPTR)
5276  11 00 00    ld de,0000H
5279  cd 4a 54    call sub_544ah
527c  c2 07 52    jp nz,l5207h
527f  2a 00 42    ld hl,(SECBUF)
5282  11 00 fe    ld de,0FE00H
5285  df          rst 18h
5286  20 57       jr nz,l52dfh
5288  3a 02 42    ld a,(m4202)
528b  dd be 01    cp (ix+001h)
528e  30 4f       jr nc,l52dfh
5290  dd 77 00    ld (ix+000h),a
5293  32 c2 54    ld (l54c2h),a
5296  dd 6e 05    ld l,(ix+005h)
5299  cd 92 4c    call MULHL
529c  3a b3 4c    ld a,(DGRAN2)
529f  cd 94 4c    call MULOV
52a2  22 ca 52    ld (l52c9h+1),hl
52a5  23          inc hl
52a6  23          inc hl
52a7  eb          ex de,hl
52a8  cd 4a 54    call sub_544ah
52ab  28 32       jr z,l52dfh

; Compare against 9-byte templates at l5491h/l547fh -- "GDOS    SYS"
; and "BOOT    SYS" (data bit 7 set throughout this file).

52ad  21 91 54    ld hl,l5491h
52b0  11 05 42    ld de,m4205
52b3  01 09 00    ld bc,0009H
52b6  cd 41 54    call sub_5441h
52b9  28 0e       jr z,l52c9h
52bb  21 7f 54    ld hl,l547fh
52be  11 05 42    ld de,m4205
52c1  01 09 00    ld bc,0009H
52c4  cd 41 54    call sub_5441h
52c7  20 16       jr nz,l52dfh
l52c9h:
52c9  11 00 00    ld de,0000H
52cc  13          inc de
52cd  cd 4a 54    call sub_544ah
52d0  28 0d       jr z,l52dfh
52d2  3a 1f 42    ld a,(DIRLEN)
52d5  cb 7f       bit 7,a
52d7  20 06       jr nz,l52dfh
52d9  c6 0a       add a,00ah
52db  fe 1f       cp 01fh
52dd  38 40       jr c,l531fh
l52dfh:
52df  11 00 00    ld de,0000H
52e2  cd 4a 54    call sub_544ah
52e5  c2 07 52    jp nz,l5207h
52e8  21 00 fe    ld hl,0FE00H
52eb  22 00 42    ld (SECBUF),hl
52ee  dd 7e 08    ld a,(ix+008h)
52f1  32 02 42    ld (m4202),a
52f4  cd 58 54    call sub_5458h
52f7  3a 02 42    ld a,(m4202)
52fa  dd 77 00    ld (ix+000h),a
52fd  32 c2 54    ld (l54c2h),a
5300  dd 6e 05    ld l,(ix+005h)
5303  cd 92 4c    call MULHL
5306  3a b3 4c    ld a,(DGRAN2)
5309  cd 94 4c    call MULOV
530c  22 ca 52    ld (l52c9h+1),hl
530f  dd 6e 09    ld l,(ix+009h)
5312  3a b3 4c    ld a,(DGRAN2)
5315  cd 92 4c    call MULHL
5318  7d          ld a,l
5319  fe 1f       cp 01fh
531b  38 02       jr c,l531fh
531d  3e 1e       ld a,01eh
l531fh:
531f  32 3c 53    ld (0533ch),a
5322  32 c0 54    ld (l54c0h),a

; Sector-count check on (IX+05h)*DGRAN2 above; below 0Ah, bail out with
; "Schlechte PDrive-Daten" (l5468h). What populates DPPTR's table entry
; for a hard disk isn't identified anywhere in this repo.

5325  fe 0a       cp 00ah
5327  30 09       jr nc,l5332h
5329  21 68 54    ld hl,l5468h
532c  cd 67 44    call DSPLY
532f  c3 30 40    jp ERRORO
l5332h:
5332  cd 31 54    call sub_5431h
5335  2a 8a 54    ld hl,(l548ah)
5338  22 00 42    ld (SECBUF),hl
533b  3e 00       ld a,000h
533d  d6 0a       sub 00ah
533f  32 1f 42    ld (DIRLEN),a
5342  ed 5b ca 52 ld de,(l52c9h+1)
5346  13          inc de
5347  cd 60 54    call sub_5460h
534a  d5          push de
534b  cd 31 54    call sub_5431h
534e  21 05 00    ld hl,0005H
5351  cd 27 54    call sub_5427h
5354  32 a3 54    ld (l54a3h),a
5357  21 8c 54    ld hl,0548ch
535a  11 00 42    ld de,SECBUF
535d  01 20 00    ld bc,0020H
5360  ed b0       ldir
5362  d1          pop de
5363  13          inc de
5364  cd 60 54    call sub_5460h
5367  d5          push de
5368  2a c0 54    ld hl,(l54c0h)
536b  26 00       ld h,000h
536d  cd 27 54    call sub_5427h
5370  32 c3 54    ld (l54c3h),a
5373  21 ac 54    ld hl,l54ach
5376  11 00 42    ld de,SECBUF
5379  01 20 00    ld bc,0020H
537c  ed b0       ldir
537e  d1          pop de
537f  13          inc de
5380  cd 60 54    call sub_5460h
5383  d5          push de
5384  cd 31 54    call sub_5431h
5387  d1          pop de
5388  3a 3c 53    ld a,(0533ch)
538b  d6 04       sub 004h
538d  47          ld b,a
l538eh:
538e  13          inc de
538f  cd 60 54    call sub_5460h
5392  10 fa       djnz l538eh
5394  dd 46 05    ld b,(ix+005h)
5397  0e ff       ld c,0ffh
l5399h:
5399  cb 21       sla c
539b  10 fc       djnz l5399h
539d  dd 7e 01    ld a,(ix+001h)
53a0  fe 61       cp 061h
53a2  1e c0       ld e,0c0h
53a4  30 0a       jr nc,l53b0h
53a6  21 60 42    ld hl,m4260
53a9  06 60       ld b,060h
53ab  58          ld e,b
l53ach:
53ac  71          ld (hl),c
53ad  23          inc hl
53ae  10 fc       djnz l53ach
l53b0h:
53b0  21 00 42    ld hl,SECBUF
53b3  dd 46 01    ld b,(ix+001h)
l53b6h:
53b6  71          ld (hl),c
53b7  22 e9 53    ld (053e9h),hl
53ba  23          inc hl
53bb  1d          dec e
53bc  10 f8       djnz l53b6h
53be  28 06       jr z,l53c6h
53c0  43          ld b,e
l53c1h:
53c1  36 ff       ld (hl),0ffh
53c3  23          inc hl
53c4  10 fb       djnz l53c1h
l53c6h:
53c6  dd 6e 04    ld l,(ix+004h)
53c9  dd 7e 03    ld a,(ix+003h)
53cc  cd 92 4c    call MULHL
53cf  cd b2 4c    call m4cb2
53d2  e5          push hl
53d3  dd 6e 01    ld l,(ix+001h)
53d6  dd 7e 05    ld a,(ix+005h)
53d9  cd 92 4c    call MULHL
53dc  d1          pop de
53dd  b7          or a
53de  ed 52       sbc hl,de
53e0  28 0a       jr z,l53ech
53e2  45          ld b,l
l53e3h:
53e3  37          scf
53e4  cb 19       rr c
53e6  10 fb       djnz l53e3h
53e8  21 00 00    ld hl,0000H
53eb  71          ld (hl),c
l53ech:
53ec  11 c0 42    ld de,m42c0
53ef  21 cc 54    ld hl,l54cch
53f2  01 40 00    ld bc,0040H
53f5  ed b0       ldir
53f7  3a a3 54    ld a,(l54a3h)
53fa  3c          inc a
53fb  21 00 42    ld hl,SECBUF
53fe  cd 15 54    call sub_5415h
5401  3a c3 54    ld a,(l54c3h)
5404  3c          inc a
5405  dd 6e 00    ld l,(ix+000h)
5408  cd 15 54    call sub_5415h
540b  ed 5b ca 52 ld de,(l52c9h+1)
540f  cd 60 54    call sub_5460h
5412  c3 2d 40    jp DOSRDY
sub_5415h:
5415  47          ld b,a
l5416h:
5416  0e 01       ld c,001h
l5418h:
5418  7e          ld a,(hl)
5419  b1          or c
541a  be          cp (hl)
541b  28 06       jr z,l5423h
541d  77          ld (hl),a
541e  cb 21       sla c
5420  10 f6       djnz l5418h
5422  c9          ret
l5423h:
5423  2c          inc l
5424  c8          ret z
5425  18 ef       jr l5416h
sub_5427h:
5427  cd b2 4c    call m4cb2
542a  b7          or a
542b  28 01       jr z,l542eh
542d  2c          inc l
l542eh:
542e  7d          ld a,l
542f  3d          dec a
5430  c9          ret
sub_5431h:
5431  21 00 42    ld hl,SECBUF
5434  e5          push hl
5435  11 01 42    ld de,m4201
5438  01 ff 00    ld bc,00FFH
543b  36 00       ld (hl),000h
543d  ed b0       ldir
543f  e1          pop hl
5440  c9          ret
sub_5441h:
5441  1a          ld a,(de)
5442  ed a1       cpi
5444  c0          ret nz
5445  13          inc de
5446  ea 41 54    jp pe,sub_5441h
5449  c9          ret
sub_544ah:
544a  21 00 42    ld hl,SECBUF
544d  cd 30 46    call READS
5450  c8          ret z
5451  fe 06       cp 006h
l5453h:
5453  c2 07 52    jp nz,l5207h
5456  b7          or a
5457  c9          ret
sub_5458h:
5458  21 00 42    ld hl,SECBUF
545b  cd 40 46    call WRITES
545e  18 f3       jr l5453h
sub_5460h:
5460  21 00 42    ld hl,SECBUF
5463  cd 3c 46    call WRITDS
5466  18 eb       jr l5453h
; data from here to EOF, disassembled as code
l5468h:
5468  53          ld d,e
5469  63          ld h,e
546a  68          ld l,b
546b  6c          ld l,h
546c  65          ld h,l
546d  63          ld h,e
546e  68          ld l,b
546f  74          ld (hl),h
5470  65          ld h,l
5471  20 50       jr nz,l54c3h
5473  44          ld b,h
5474  72          ld (hl),d
5475  69          ld l,c
5476  76          halt
5477  65          ld h,l
5478  2d          dec l
5479  44          ld b,h
547a  61          ld h,c
547b  74          ld (hl),h
547c  65          ld h,l
547d  6e          ld l,(hl)
547e  03          inc bc
l547fh:
547f  42          ld b,d
5480  4f          ld c,a
5481  4f          ld c,a
5482  54          ld d,h
5483  20 20       jr nz,l54a5h
5485  20 20       jr nz,l54a7h
5487  53          ld d,e
5488  59          ld e,c
5489  53          ld d,e
l548ah:
548a  a1          and c
548b  ce 5e       adc a,05eh
548d  00          nop
548e  00          nop
548f  00          nop
5490  00          nop
l5491h:
5491  47          ld b,a
5492  44          ld b,h
5493  4f          ld c,a
5494  53          ld d,e
5495  20 20       jr nz,l54b7h
5497  20 20       jr nz,l54b9h
5499  53          ld d,e
549a  59          ld e,c
549b  53          ld d,e
549c  60          ld h,b
549d  7f          ld a,a
549e  1f          rra
549f  b2          or d
54a0  05          dec b
54a1  00          nop
54a2  00          nop
l54a3h:
54a3  00          nop
54a4  ff          rst 38h
l54a5h:
54a5  ff          rst 38h
54a6  ff          rst 38h
l54a7h:
54a7  ff          rst 38h
54a8  ff          rst 38h
54a9  ff          rst 38h
54aa  ff          rst 38h
54ab  ff          rst 38h
l54ach:
54ac  5d          ld e,l
54ad  20 00       jr nz,l54afh
l54afh:
54af  00          nop
54b0  00          nop
54b1  49          ld c,c
54b2  4e          ld c,(hl)
54b3  48          ld c,b
54b4  41          ld b,c
54b5  4c          ld c,h
54b6  54          ld d,h
l54b7h:
54b7  20 20       jr nz,l54d9h
l54b9h:
54b9  53          ld d,e
54ba  59          ld e,c
54bb  53          ld d,e
54bc  a7          and a
54bd  1d          dec e
54be  f9          ld sp,hl
54bf  e5          push hl
l54c0h:
54c0  00          nop
54c1  00          nop
l54c2h:
54c2  00          nop
l54c3h:
54c3  00          nop
54c4  ff          rst 38h
54c5  ff          rst 38h
54c6  ff          rst 38h
54c7  ff          rst 38h
54c8  ff          rst 38h
54c9  ff          rst 38h
54ca  ff          rst 38h
54cb  ff          rst 38h
l54cch:
54cc  ff          rst 38h
54cd  ff          rst 38h
54ce  ff          rst 38h
54cf  ff          rst 38h
54d0  ff          rst 38h
54d1  ff          rst 38h
54d2  ff          rst 38h
54d3  ff          rst 38h
54d4  ff          rst 38h
54d5  ff          rst 38h
54d6  ff          rst 38h
54d7  82          add a,d
54d8  00          nop
l54d9h:
54d9  00          nop
54da  47          ld b,a
54db  8c          adc a,h
l54dch:
54dc  47          ld b,a
54dd  44          ld b,h
54de  4f          ld c,a
54df  53          ld d,e
54e0  20 20       jr nz,l5502h
54e2  20 20       jr nz,l5504h
l54e4h:
54e4  30 30       jr nc,$+50
54e6  2e 30       ld l,030h
54e8  30 2e       jr nc,$+48
54ea  30 30       jr nc,$+50
54ec  0d          dec c
54ed  ff          rst 38h
54ee  ff          rst 38h
54ef  ff          rst 38h
54f0  ff          rst 38h
54f1  ff          rst 38h
54f2  ff          rst 38h
54f3  ff          rst 38h
54f4  ff          rst 38h
54f5  ff          rst 38h
54f6  ff          rst 38h
54f7  ff          rst 38h
54f8  ff          rst 38h
54f9  ff          rst 38h
54fa  ff          rst 38h
54fb  ff          rst 38h
54fc  ff          rst 38h
54fd  ff          rst 38h
54fe  ff          rst 38h
54ff  ff          rst 38h
5500  ff          rst 38h
5501  ff          rst 38h
l5502h:
5502  ff          rst 38h
5503  ff          rst 38h
l5504h:
5504  ff          rst 38h
5505  ff          rst 38h
5506  ff          rst 38h
5507  ff          rst 38h
5508  ff          rst 38h
5509  ff          rst 38h
550a  ff          rst 38h
550b  ff          rst 38h
