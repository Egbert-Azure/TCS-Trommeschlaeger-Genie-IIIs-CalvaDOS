;************************************************************************
;
; SYS0/SYS from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys0-sys-disassembly.asm
;
; Date: 2026/08/18
;
;************************************************************************
;
; Not all of this file is this project's own work. Who wrote what:
;
;   Hartmut Grosser, Das DOS-Buch fuer TRS-80, Genie und Colour Genie,
;   chapter 3 -- the routine boxes (Name/Funktion/Input/Veraendert/
;   Output), the German prose under some of them, and every trailing
;   comment carrying no prefix. His words, transliterated to ASCII.
;   His book documents GDOS 2.1c; this build is GDOS 2.4, so where the
;   two differ a [note] says so.
;
;   E.H. Schroeer -- the disassembly itself, its annotation, and the
;   placement of Grosser's boxes against this build's own addresses.
;
;   This project -- the [PATCH] and [note] boxes.
;
;************************************************************************
;
; SYS0/SYS module 0, from DMK/G3S-GDOS24.DMK, carrying this port's own
; patches -- boxed at 4BE4h, 4BF0h, 327Eh, 4C13h, 4D63h-4D6Eh, 4EF9h-4EFAh,
; 4F0Dh-4F14h and 50C4h. Not the boot-banner block at 4FABh-504Dh, though:
; that one is string data that this listing disassembles as though it
; were code, so its patch (labels left-aligned to column 39) isn't
; byte-boxed here.
;
; Boxed annotations sit above the line they describe:
;
;   [PATCH]  a departure from stock GDOS 2.4, with the stock bytes,
;            this build's bytes and the reason for the change.
;   [note]   not from Grosser -- either a finding here, or a place
;            GDOS 2.4 diverges from his 2.1c (his ch.9.4.2).
;   Name:    a routine, as Grosser documents it in ch.3.
;
; A line with no box and no trailing comment is the disassembly as it
; came out, unedited -- including the DEFB at 43B7h, which is how an
; undocumented opcode is rendered. 442Bh is the one hand-made line, a
; data byte split out of a mis-decoded instruction; its [note] says so.
; 3200h-32FBh -- overlay open (OVL4/SYS:5)
; ------------------------------------------------------------
; [note]      3200h: bank-switch trampoline. OUT F9h,A / EI /
;             pop-triple / RET. At 3209h the other way: push-
;             triple / OUT F9h,A / DI / JP F00Ah.
; ------------------------------------------------------------
3200  3e 40     ld a,040h
3202  d3 f9     out (0f9h),a
3204  fb        ei
3205  c1        pop bc
3206  d1        pop de
3207  e1        pop hl
3208  c9        ret
3209  e5        push hl
320A  d5        push de
320B  c5        push bc
320C  3e 01     ld a,001h
320E  f3        di
320F  d3 f9     out (0f9h),a
3211  c3 0a f0  jp 0f00ah
; ------------------------------------------------------------
; [note]      3214h: writes (4307h) OR 30h over the 'x' at
;             3278h. On a Genie IIIs that is '4', so OVL4/SYS.
;             3220h tests the result against 004h.
; ------------------------------------------------------------
3214  3a 07 43  ld a,(04307h)
3217  f6 30     or 030h
3219  32 78 32  ld (l3278h),a
321C  e6 0f     and 00fh
321E  fe 04     cp 004h
3220  20 0a     jr nz,l322ch
3222  3a f8 42  ld a,(042f8h)
3225  cb 5f     bit 3,a
3227  3e fc     ld a,0fch
3229  c4 02 44  call nz,04402h
322C  21 75 32  ld hl,l3275h
322F  11 80 44  ld de,04480h
3232  01 0b 00  ld bc,0000bh
3235  ed b0     ldir
3237  11 80 44  ld de,04480h
323A  21 00 42  ld hl,04200h
323D  cd 24 44  call 04424h
3240  28 0b     jr z,l324dh
3242  fe 18     cp 018h
3244  20 28     jr nz,l326eh
3246  3e 01     ld a,001h
3248  32 07 43  ld (04307h),a
324B  18 0e     jr l325bh
324D  eb        ex de,hl
324E  cd 28 4c  call 04c28h
3251  20 1b     jr nz,l326eh
3253  11 5b 32  ld de,l325bh
3256  d5        push de
3257  11 98 31  ld de,03198h
325A  e9        jp (hl)
325B  21 00 30  ld hl,03000h
325E  11 ad 4e  ld de,04eadh
3261  01 00 02  ld bc,00200h
3264  ed b0     ldir
3266  e1        pop hl
3267  f1        pop af
3268  32 f9 42  ld (042f9h),a
326B  c3 67 44  jp 04467h
326E  f5        push af
326F  cd c9 01  call 001c9h
3272  3e 46     ld a,046h
3274  ef        rst 28h
3275  4f        ld c,a
3276  56        ld d,(hl)
3277  4c        ld c,h
; ------------------------------------------------------------
; [note]      3278h: the 'x' in the on-disk template
;             "OVLx/SYS:0" -- 3275h='O', 3276h='V', 3277h='L',
;             3278h='x'. Overwritten at runtime by 3214h.
; ------------------------------------------------------------
3278  78        ld a,b
3279  2f        cpl
327A  53        ld d,e
327B  59        ld e,c
327C  53        ld d,e
; ------------------------------------------------------------
; [PATCH]     327Eh
; Stock:      30h   ASCII '0'
; This build: 35h   ASCII '5'
; Reason:     The drive digit in the on-disk template
;             "OVLx/SYS:0" at 3275h, so every overlay open
;             targets the boot volume instead of a floppy.
;             327Dh-327Fh are three data bytes -- ':' + digit
;             + CR -- that a linear disassembler renders as a
;             bogus "ld a,(0D35h)".
; ------------------------------------------------------------
327D  3a 35 0d  ld a,(00d35h)
3280  00        nop
3281  00        nop
3282  00        nop
3283  00        nop
3284  00        nop
3285  00        nop
3286  00        nop
3287  00        nop
3288  00        nop
3289  00        nop
328A  00        nop
328B  00        nop
328C  00        nop
328D  00        nop
328E  00        nop
328F  00        nop
3290  00        nop
3291  00        nop
3292  00        nop
3293  00        nop
3294  00        nop
3295  00        nop
3296  00        nop
3297  00        nop
3298  00        nop
3299  00        nop
329A  00        nop
329B  00        nop
329C  00        nop
329D  00        nop
329E  00        nop
329F  00        nop
32A0  00        nop
32A1  00        nop
32A2  00        nop
32A3  00        nop
32A4  00        nop
32A5  00        nop
32A6  00        nop
32A7  00        nop
32A8  00        nop
32A9  00        nop
32AA  00        nop
32AB  00        nop
32AC  00        nop
32AD  00        nop
32AE  00        nop
32AF  00        nop
32B0  00        nop
32B1  00        nop
32B2  00        nop
32B3  00        nop
32B4  00        nop
32B5  00        nop
32B6  00        nop
32B7  00        nop
32B8  00        nop
32B9  00        nop
32BA  00        nop
32BB  00        nop
32BC  00        nop
32BD  00        nop
32BE  00        nop
32BF  00        nop
32C0  00        nop
32C1  00        nop
32C2  00        nop
32C3  00        nop
32C4  00        nop
32C5  00        nop
32C6  00        nop
32C7  00        nop
32C8  00        nop
32C9  00        nop
32CA  00        nop
32CB  00        nop
32CC  00        nop
32CD  00        nop
32CE  00        nop
32CF  00        nop
32D0  00        nop
32D1  00        nop
32D2  00        nop
32D3  00        nop
32D4  00        nop
32D5  00        nop
32D6  00        nop
32D7  00        nop
32D8  00        nop
32D9  00        nop
32DA  00        nop
32DB  00        nop
32DC  00        nop
32DD  00        nop
32DE  00        nop
32DF  00        nop
32E0  00        nop
32E1  00        nop
32E2  00        nop
32E3  00        nop
32E4  00        nop
32E5  00        nop
32E6  00        nop
32E7  00        nop
32E8  00        nop
32E9  00        nop
32EA  00        nop
32EB  00        nop
32EC  00        nop
32ED  00        nop
32EE  00        nop
32EF  00        nop
32F0  00        nop
32F1  00        nop
32F2  00        nop
32F3  00        nop
32F4  00        nop
32F5  00        nop
32F6  00        nop
32F7  00        nop
32F8  00        nop
32F9  00        nop
32FA  00        nop
32FB  00        nop

; 400Ch-4014h
400C  c3 c2 4b  jp 04bc2h
400F  c3 09 46  jp 04609h
4012  c3 f2 45  jp 045f2h

; 402Dh-4035h
402D  c3 00 44  jp 04400h
; ------------------------------------------------------------
; Name:       ERRORO
; Funktion:   nach einem Fehler: Sprung nach DOS READY
; Input:      --
; Veraendert: --
; Output:     --
; ------------------------------------------------------------
; Programme, die mit einem bereits angezeigten Fehler beendet werden,
; sollten mit einem Sprung nach ERRORO aufhoeren. Von dort geht es
; dann genau wie bei DOSRDY (402DH) weiter, ein evtl. CHAINING wird
; jedoch abgebrochen.
4030  3e 43     ld a,043h
4032  ef        rst 28h
4033  c3 db 4a  jp 04adbh

; 4063h-407Fh
4063  7a        ld a,d
4064  cd 68 40  call sub_4068h
4067  7b        ld a,e
4068  f5        push af
4069  0f        rrca
406A  0f        rrca
406B  0f        rrca
406C  0f        rrca
406D  cd 71 40  call sub_4071h
4070  f1        pop af
4071  e6 0f     and 00fh
4073  c6 90     add a,090h
4075  27        daa
4076  ce 40     adc a,040h
4078  27        daa
4079  77        ld (hl),a
407A  23        inc hl
407B  c9        ret
407C  3b        dec sp
407D  3b        dec sp
407E  17        rla
407F  00        nop

; 4308h-4317h -- drive-select bookkeeping
; ------------------------------------------------------------
; [note]      4308h: ddrive. 4306h (dsave) is DRVSEL's
;             redirected write target, kept in sync by gdisp.
; ------------------------------------------------------------
4308  00        nop
; ------------------------------------------------------------
; [note]      4309h: drive bit-mask.
; ------------------------------------------------------------
4309  00        nop
430A  11 23 03  ld de,00323h
430D  23        inc hl
430E  0a        ld a,(bc)
430F  02        ld (bc),a
4310  00        nop
4311  00        nop
4312  c3 b0 45  jp 045b0h
; ------------------------------------------------------------
; [note]      4315h: 4315h-4317h are three data bytes,
;             rendered below as a bogus "ld bc,0000h". 4317h
;             is the "aktuelles /SYS-Modul": 00h none
;             available, 03h SYS1 ... 1Fh SYS29.
; ------------------------------------------------------------
4315  01 00 00  ld bc,00000h

; 4368h-43A8h
4368  a5        and l
4369  40        ld b,b
436A  00        nop
436B  00        nop
436C  00        nop
436D  00        nop
436E  00        nop
436F  00        nop
4370  5a        ld e,d
;
; PDRIVE Parameter fuer Drive 0
;
4371  11 23 03  ld de,00323h    ; wirklicher DSL "Directory Starting Lump" (wird bei
                                ; Bedarf durch den Wert im BOOT-Sector der betreffenden
                                ; Diskette aktualisiert)
                                ; actual DSL "Directory Starting Lump" (updated as
                                ; needed with the value from the boot sector of the
                                ; diskette in question)
4374  23        inc hl          ; PDRIVE+3
4375  0a        ld a,(bc)       ; PDRIVE+4
4376  02        ld (bc),a       ; PDRIVE+5
4377  00        nop             ; PDRIVE+6
4378  00        nop             ; PDRIVE+7
4379  11 02 ff  ld de,0ff02h    ; PDRIVE+8 (11h), PDRIVE+9 (02h) -- Drive 0's
                                ; block ends here. Drive 1 begins mid-instruction,
                                ; at 437Bh (FFh) -- confirmed byte-for-byte against
                                ; a reference disassembly: 437Bh-4384h = FF 01 00 01
                                ; 00 00 00 00 FF 00, an exact match for Drive 1's
                                ; PDRIVE+0..+9. The disassembler's own line grouping
                                ; (one 3-byte pseudo-instruction per line, since this
                                ; is data, not code) straddles the Drive 0/Drive 1
                                ; boundary; it does not reflect a real instruction.
;
; PDRIVE Parameter fuer Drive 1
; (starts at 437Bh, the third byte of the instruction above)
;
                                ; 437B  ff              ; PDRIVE+0
437C  01 00 01  ld bc,00100h    ; PDRIVE+1
437F  00        nop             ; PDRIVE+4
4380  00        nop             ; PDRIVE+5
4381  00        nop             ; PDRIVE+6
4382  00        nop             ; PDRIVE+7
4383  ff        rst 38h         ; PDRIVE+8
4384  00        nop             ; PDRIVE+9
4385  ff        rst 38h
4386  01 00 01  ld bc,00100h
4389  00        nop
438A  00        nop
438B  00        nop
438C  00        nop
438D  ff        rst 38h
438E  00        nop
438F  ff        rst 38h
4390  01 00 01  ld bc,00100h
4393  00        nop
4394  00        nop
4395  00        nop
4396  00        nop
4397  ff        rst 38h
4398  00        nop
4399  71        ld (hl),c
439A  43        ld b,e
439B  00        nop
439C  00        nop
439D  00        nop
439E  00        nop
439F  04        inc b
43A0  01 00 01  ld bc,00100h
43A3  00        nop
43A4  01 00 00  ld bc,00000h
43A7  0d        dec c
43A8  0d        dec c
; 43B2h-43DFh -- shared FCB fields
; ------------------------------------------------------------
; [note]      43B2h: dfcbdv2 (43D4h) and dfcbdec (43D5h) fall
;             in this range.
; ------------------------------------------------------------
43B2  00        nop
43B3  00        nop
43B4  00        nop
43B5  ff        rst 38h
43B6  ff        rst 38h
43B7  fd 4c     defb 0fdh,04ch ;ld c,iyh
43B9  00        nop
43BA  00        nop
43BB  00        nop
43BC  ff        rst 38h
43BD  ff        rst 38h
43BE  00        nop
43BF  00        nop
43C0  00        nop
43C1  00        nop
43C2  00        nop
43C3  ff        rst 38h
43C4  ff        rst 38h
43C5  00        nop
43C6  00        nop
43C7  00        nop
43C8  00        nop
43C9  00        nop
43CA  ff        rst 38h
43CB  ff        rst 38h
43CC  00        nop
43CD  00        nop
43CE  80        add a,b
43CF  28 00     jr z,l43d1h
43D1  00        nop
43D2  42        ld b,d
43D3  00        nop
; ------------------------------------------------------------
; [note]      43D4h: dfcbdv2, written at runtime. Cold: 00h.
;             ginit writes sysvol (05h) once at boot.
; ------------------------------------------------------------
43D4  00        nop
; ------------------------------------------------------------
; [note]      43D5h: dfcbdec, written at runtime. Cold: FFh.
;             rdecfix (4495h) rewrites it on every GETSYS
;             call.
; ------------------------------------------------------------
43D5  ff        rst 38h
43D6  00        nop
43D7  00        nop
43D8  00        nop
43D9  00        nop
43DA  40        ld b,b
43DB  00        nop
43DC  00        nop
43DD  00        nop
43DE  ff        rst 38h
43DF  ff        rst 38h

; 4400h-4BC8h
4400  3e 23     ld a,023h
4402  ef        rst 28h
4403  00        nop
4404  00        nop
; ------------------------------------------------------------
; Name:       DOSCMD
; Funktion:   DOS-Befehl (HL) ausfuehren (ohne Rueckkehr)
; Input:      HL: zeigt auf einen DOS-Befehl, der mit 0DH
;             abgeschlossen sein muss
; Veraendert: --
; Output:     --
; ------------------------------------------------------------
; Der DOS-Befehl, auf den HL zeigt, wird (unter Umwandlung von
; Kleinbuchstaben in Grossbuchstaben) in den Input-Buffer des DOS
; (4318-4367) uebertragen und ausgefuehrt. Anschliessend kehrt DOSCMD
; jedoch nicht zum Aufrufer zurueck, sondern springt nach DOSRDY
; (402DH).
;
; ACHTUNG! Vor Aufruf von DOSCMD darf bei 4318H keinesfalls 0DH
; stehen, sonst passiert gar nichts!
4405  3e 63     ld a,063h
4407  ef        rst 28h
4408  c8        ret z
; ------------------------------------------------------------
; Name:       DOSERR
; Funktion:   Fehlermeldung (A) ausgeben
; Input:      A: Fehlercode -- Bit 7: Rueckkehr (J/N)
; Veraendert: F
; Output:     --
; ------------------------------------------------------------
; Wenn Bit 7 im A-Register gesetzt ist, wird die entsprechende
; Fehlermeldung ausgegeben und DOSERR kehrt zum Aufrufer zurueck. Wenn
; Bit 7 nicht gesetzt ist: ein aktives CHAINING wird abgebrochen; bei
; aktivem DOS-CALL (4419H) wird der Aufruf beendet und der Fehlercode
; an dessen Aufrufer uebergeben, ohne Meldung; sonst wird die Meldung
; ausgegeben und nach DOSRDY (402DH) gesprungen.
4409  f5        push af
440A  3e 26     ld a,026h
440C  ef        rst 28h
; ------------------------------------------------------------
; Name:       DEBUG
; Funktion:   DEBUG aufrufen
; Input:      --
; Veraendert: --
; Output:     --
; ------------------------------------------------------------
440D  c3 09 46  jp l4609h
; ------------------------------------------------------------
; Name:       INTINS
; Funktion:   Benutzer-Interrupt-Routine einfuegen
; Input:      DE: Zeiger auf Kontroll-Block der Benutzer-
;             Interrupt-Routine
; Veraendert: AF, BC, DE, HL
; Output:     --
; ------------------------------------------------------------
4410  3e 65     ld a,065h
4412  ef        rst 28h
; ------------------------------------------------------------
; Name:       INTDEL
; Funktion:   Benutzer-Interrupt-Routine loeschen
; Input:      DE: Zeiger auf Kontroll-Block der Benutzer-
;             Interrupt-Routine
; Veraendert: AF, BC, DE, HL
; Output:     --
; ------------------------------------------------------------
4413  3e 85     ld a,085h
4415  ef        rst 28h
; ------------------------------------------------------------
; Name:       MOTONX
; Funktion:   Drive-Motoren weiterlaufen lassen
; Input:      --
; Veraendert: AF
; Output:     --
; ------------------------------------------------------------
; Falls die Motoren der Drives noch an sind, dann wird durch erneuten
; Drive-Select dafuer gesorgt, dass die Motoren weiterlaufen.
4416  c3 62 47  jp l4762h
; ------------------------------------------------------------
; Name:       DOSCAL
; Funktion:   DOS-Befehl (HL) ausfuehren und zurueck
; Input:      HL: zeigt auf einen DOS-Befehl, der mit 0DH
;             abgeschlossen sein muss
; Veraendert: --
; Output:     AF: Fehler-Status (siehe Text)
; ------------------------------------------------------------
; Wie DOSCMD, aber mit Rueckkehr zum Aufrufer. Im AF-Register wird ein
; Fehler-Status uebergeben: C=1 -- ein bereits angezeigter Fehler ist
; aufgetreten; C=0 und Z=0 -- ein Fehler ist aufgetreten und sein Code
; steht in A.
4419  3e c3     ld a,0c3h
441B  ef        rst 28h
441C  3e 83     ld a,083h
441E  ef        rst 28h
441F  00        nop
; ------------------------------------------------------------
; Name: INIT 
; Funktion: File offen, ggf. neue File anlegen 
; ft Input: DE: zeigt auf FCB, der Filespec enthält 
; HL: zeigt auf zu benutzenden Buffer 
; ft B: gibt Logische Recordlänge an ft
; ft Verändert: — ft
; ft Output: AF: A=Fehlercode, wenn Z=0 
; ------------------------------------------------------------
420  3e 44     ld a,044h
4422  ef        rst 28h
4423  00        nop
4424  3e 24     ld a,024h
4426  ef        rst 28h
4427  82        add a,d
4428  3e 25     ld a,025h
442A  ef        rst 28h
; ------------------------------------------------------------
; [note]      442Bh: a filler byte, like 4423h and 4427h. A linear
;             disassembler reads it as the start of a LD BC and
;             swallows KILL's opcode at 442Ch, so it is split out
;             here.
; ------------------------------------------------------------
442B  01        defb 001h
; ------------------------------------------------------------
; Name:       KILL
; Funktion:   File loeschen
; Input:      DE: zeigt auf geoeffneten FCB
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
442C  3e 45     ld a,045h
442E  ef        rst 28h
442F  00        nop
; ------------------------------------------------------------
; Name:       LOAD
; Funktion:   Programm laden
; Input:      DE: zeigt auf FCB, der Filespec enthaelt
; Veraendert: BC
; Output:     AF: A=Fehlercode, wenn Z=0
;             HL: Startadresse des Programms
;             4403H,4404H: Startadresse des Programms
; ------------------------------------------------------------
4430  3e a4     ld a,0a4h
4432  ef        rst 28h
4433  3e c4     ld a,0c4h
4435  ef        rst 28h
4436  c3 fc 49  jp l49fch
4439  c3 36 4a  jp l4a36h
443C  c3 32 4a  jp l4a32h
443F  c3 4c 4b  jp l4b4ch
; ------------------------------------------------------------
; Name:       POSBC
; Funktion:   NEXT-Feld im FCB auf die in BC angegebene
;             Logische Record# positionieren
; Input:      DE: zeigt auf geoeffneten FCB
;             BC: gewuenschte Logische Record#
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4442  c3 73 4b  jp l4b73h
; ------------------------------------------------------------
; Name:       POSDEC
; Funktion:   NEXT-Feld im FCB um 1 Logische Record#
;             decrementieren (-1)
; Input:      DE: zeigt auf geoeffneten FCB
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4445  c3 62 4b  jp l4b62h
; ------------------------------------------------------------
; Name:       POSEOF
; Funktion:   NEXT-Feld im FCB auf EOF (End of File)
;             positionieren
; Input:      DE: zeigt auf geoeffneten FCB
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4448  c3 54 4b  jp l4b54h
; ------------------------------------------------------------
; Name:       EXPAND
; Funktion:   Wenn die File kuerzer ist, als das NEXT-Feld im
;             FCB angibt, wird die File um entsprechend viele
;             GRANS erweitert
; Input:      DE: zeigt auf geoeffneten FCB
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
444B  c3 09 48  jp l4809h
; ------------------------------------------------------------
; Name:       POSRBA
; Funktion:   NEXT-Feld im FCB so positionieren, wie in HL und
;             C im RBA-Format angegeben ist
; Input:      DE: zeigt auf geoeffneten FCB
;             HL: 1. und 2. Byte fuer NEXT-Feld
;             C:  3. Byte fuer NEXT-Feld
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
444E  c3 47 4b  jp l4b47h
4451  3e c5     ld a,0c5h
4453  ef        rst 28h
4454  00        nop
4455  00        nop
4456  00        nop
4457  3e 2a     ld a,02ah
4459  18 ae     jr l4409h
445B  c3 76 47  jp l4776h
445E  c3 ec 47  jp l47ech
4461  3e 2b     ld a,02bh
4463  ef        rst 28h
; ------------------------------------------------------------
; Name:       USRDEL
; Funktion:   Benutzer-Routine loeschen
; Input:      HL: zeigt auf Kontroll-Block der Benutzer-
;             Routine
; Veraendert: HL, DE, BC
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4464  3e 4b     ld a,04bh
4466  ef        rst 28h
; ------------------------------------------------------------
; Name:       TEXTTV
; Funktion:   Text (HL) auf Bildschirm ausgeben
; Input:      HL: zeigt auf Text, Ende = 03H oder 0DH
; Veraendert: AF
; Output:     --
; ------------------------------------------------------------
4467  c3 a6 4b  jp l4ba6h
; ------------------------------------------------------------
; Name:       TEXTLP
; Funktion:   Text (HL) auf Drucker ausgeben
; Input:      HL: zeigt auf Text, Ende = 03H oder 0DH
; Veraendert: AF
; Output:     --
; ------------------------------------------------------------
446A  c3 bc 4b  jp l4bbch
; ------------------------------------------------------------
; Name:       TIME
; Funktion:   aktuelle Uhrzeit im Buffer (HL) im Format
;             HH:MM:SS ablegen
; Input:      HL: zeigt auf 8-Byte Buffer
; Veraendert: HL=HL+8, DE, BC, AF
; Output:     --
; ------------------------------------------------------------
446D  c3 a7 44  jp l44a7h
; ------------------------------------------------------------
; Name:       DATE
; Funktion:   aktuelles Datum im Buffer (HL) im Format
;             MM/TT/JJ ablegen
; Input:      HL: zeigt auf 8-Byte Buffer
; Veraendert: HL=HL+8, DE, BC, AF
; Output:     --
; ------------------------------------------------------------
4470  c3 c2 44  jp l44c2h
; ------------------------------------------------------------
; Name:       INSEXT
; Funktion:   Wenn Filespec (DE) keinen File-Typ enthaelt,
;             wird File-Typ (HL) eingesetzt
; Input:      DE: zeigt auf Filespec
;             HL: zeigt auf 3-Byte File-Typ
; Veraendert: HL, AF
; Output:     --
; ------------------------------------------------------------
4473  3e a3     ld a,0a3h
4475  ef        rst 28h
4476  00        nop
4477  00        nop
4478  00        nop
4479  00        nop
447A  00        nop
447B  00        nop
447C  18 d9     jr l4457h
447E  af        xor a
447F  c9        ret
4480  82        add a,d
4481  20 00     jr nz,l4483h
4483  00        nop
4484  42        ld b,d
4485  00        nop
4486  00        nop
4487  ff        rst 38h
4488  00        nop
4489  00        nop
448A  02        ld (bc),a
448B  00        nop
448C  ff        rst 38h
448D  ff        rst 38h
448E  ff        rst 38h
448F  ff        rst 38h
4490  ff        rst 38h
4491  ff        rst 38h
4492  ff        rst 38h
4493  ff        rst 38h
4494  ff        rst 38h
4495  ff        rst 38h
4496  ff        rst 38h
4497  ff        rst 38h
4498  ff        rst 38h
4499  ff        rst 38h
449A  ff        rst 38h
449B  ff        rst 38h
449C  ff        rst 38h
449D  ff        rst 38h
449E  ff        rst 38h
449F  ff        rst 38h
44A0  00        nop
44A1  00        nop
44A2  28 01     jr z,$+3
44A4  21 35 3c  ld hl,03c35h
; ------------------------------------------------------------
; TIME (Fortsetzung von 446DH) -- Kasten dort.
; ------------------------------------------------------------
44A7  11 43 40  ld de,04043h
44AA  06 3a     ld b,03ah
44AC  0e 03     ld c,003h
44AE  36 2f     ld (hl),02fh
44B0  1a        ld a,(de)
44B1  34        inc (hl)
44B2  d6 0a     sub 00ah
44B4  30 fb     jr nc,l44b1h
44B6  23        inc hl
44B7  c6 3a     add a,03ah
44B9  77        ld (hl),a
44BA  23        inc hl
44BB  1b        dec de
44BC  0d        dec c
44BD  c8        ret z
44BE  70        ld (hl),b
44BF  23        inc hl
44C0  18 ec     jr l44aeh
; ------------------------------------------------------------
; DATE (Fortsetzung von 4470H) -- Kasten dort.
; ------------------------------------------------------------
44C2  11 46 40  ld de,04046h
; ------------------------------------------------------------
; [note]      44C5h: ch.3 (Model I) has 2Fh "/". ch.9.4.2
;             gives 2Eh "." for the Genie IIIs, and this build
;             has the Genie IIIs value.
; ------------------------------------------------------------
44C5  06 2e     ld b,02eh  ; Trennzeichen fuer Datum
44C7  18 e3     jr l44ach
44C9  eb        ex de,hl
44CA  44        ld b,h
44CB  28 01     jr z,$+3
44CD  21 41 40  ld hl,04041h
44D0  e5        push hl
44D1  11 ac 43  ld de,043ach
44D4  01 06 00  ld bc,00006h
44D7  ed b0     ldir
; ------------------------------------------------------------
; [note]      44DBh: 16 zero bytes here. Grosser ch.9.3 marks
;             them changed from the base Model I value for the
;             Genie III.
; ------------------------------------------------------------
44D9  11 7c 40  ld de,0407ch
44DC  e1        pop hl
44DD  06 03     ld b,003h
44DF  34        inc (hl)
44E0  1a        ld a,(de)
44E1  96        sub (hl)
44E2  d0        ret nc
44E3  71        ld (hl),c
44E4  13        inc de
44E5  23        inc hl
44E6  10 f7     djnz l44dfh
44E8  23        inc hl
44E9  34        inc (hl)
44EA  c9        ret
44EB  00        nop
44EC  00        nop
44ED  14        inc d
44EE  01 dd e5  ld bc,0e5ddh
44F1  e1        pop hl
44F2  11 1d 40  ld de,0401dh
44F5  df        rst 18h
44F6  c8        ret z
44F7  3a 22 40  ld a,(04022h)
44FA  b7        or a
44FB  c8        ret z
44FC  2a 20 40  ld hl,(04020h)
44FF  be        cp (hl)
; ------------------------------------------------------------
; [note]      4500h: ch.3 (Model I) has 8Fh. ch.9.4.2 gives
;             5Fh for the Genie IIIs, and this build has the
;             Genie IIIs value.
; ------------------------------------------------------------
4500  36 5f     ld (hl),05fh  ; Cursorzeichen auf Bildschirm
4502  c9        ret
4503  77        ld (hl),a
4504  c9        ret
4505  18 0c     jr l4513h
4507  cd 53 48  call sub_4853h
450A  79        ld a,c
450B  d6 20     sub 020h
450D  fe 60     cp 060h
450F  79        ld a,c
; ------------------------------------------------------------
; [note]      4510h: this build has DA 7D 04 (JP C,047Dh),
;             which is ch.3's Model I value at this address
;             (Seite 3-20). ch.9.4.2 marks the low byte
;             changed to 7Bh for the Genie IIIs; this build
;             does not show that.
; ------------------------------------------------------------
4510  da 7d 04  jp c,0047dh
4513  c3 58 04  jp 00458h
4516  3a 69 43  ld a,(04369h)
4519  ee 20     xor 020h
451B  e6 68     and 068h
451D  3e cb     ld a,0cbh
451F  cc dd 49  call z,sub_49ddh
4522  c8        ret z
4523  21 be 45  ld hl,l45beh
4526  36 c9     ld (hl),0c9h
4528  e5        push hl
4529  21 36 40  ld hl,04036h
452C  01 01 38  ld bc,03801h
452F  16 08     ld d,008h
4531  0a        ld a,(bc)
4532  00        nop
4533  00        nop
4534  5f        ld e,a
4535  ae        xor (hl)
4536  73        ld (hl),e
4537  a3        and e
4538  20 24     jr nz,l455eh
453A  7a        ld a,d
453B  c6 08     add a,008h
453D  57        ld d,a
453E  23        inc hl
453F  cb 01     rlc c
4541  f2 31 45  jp p,l4531h
4544  00        nop
4545  00        nop
4546  00        nop
4547  3a 00 00  ld a,(00000h)
454A  e6 00     and 000h
454C  18 30     jr l457eh
454E  3e 00     ld a,000h
4550  b7        or a
4551  3e 00     ld a,000h
4553  20 33     jr nz,l4588h
4555  3e 02     ld a,002h
4557  32 4f 45  ld (0454fh),a
455A  3e 00     ld a,000h
455C  18 2a     jr l4588h
455E  5f        ld e,a
455F  c5        push bc
4560  d5        push de
4561  01 00 05  ld bc,00500h
4564  cd ed 4c  call sub_4cedh
4567  d1        pop de
4568  c1        pop bc
4569  0a        ld a,(bc)
456A  00        nop
456B  00        nop
456C  a3        and e
456D  28 0f     jr z,l457eh
456F  ed 43 48 45 ld (04548h),bc
4573  32 4b 45  ld (0454bh),a
4576  15        dec d
4577  07        rlca
4578  30 fc     jr nc,l4576h
457A  7a        ld a,d
457B  cd 0b 04  call 0040bh
457E  f5        push af
457F  3e 1e     ld a,01eh
4581  32 4f 45  ld (0454fh),a
4584  f1        pop af
4585  32 5b 45  ld (0455bh),a
4588  57        ld d,a
4589  cd bf 45  call sub_45bfh
458C  e1        pop hl
458D  36 00     ld (hl),000h
458F  fe 1f     cp 01fh
4591  28 1d     jr z,l45b0h
4593  c9        ret
4594  e6 df     and 0dfh
4596  d6 41     sub 041h
4598  fe 1a     cp 01ah
459A  79        ld a,c
459B  38 15     jr c,l45b2h
459D  fe 20     cp 020h
459F  c0        ret nz
45A0  21 10 38  ld hl,03810h
45A3  7e        ld a,(hl)
45A4  00        nop
45A5  00        nop
45A6  0f        rrca
45A7  79        ld a,c
45A8  d0        ret nc
45A9  21 b4 45  ld hl,l45b4h
45AC  7e        ld a,(hl)
45AD  ee c9     xor 0c9h
45AF  77        ld (hl),a
45B0  af        xor a
45B1  c9        ret
45B2  ee 20     xor 020h
45B4  c9        ret
45B5  fe 61     cp 061h
45B7  d8        ret c
45B8  fe 7f     cp 07fh
45BA  d0        ret nc
45BB  d6 20     sub 020h
45BD  c9        ret
45BE  00        nop
45BF  21 69 43  ld hl,04369h
45C2  7e        ld a,(hl)
45C3  e6 6c     and 06ch
45C5  20 26     jr nz,l45edh
45C7  3a 01 38  ld a,(03801h)
45CA  fe d0     cp 0d0h
45CC  18 05     jr l45d3h
45CE  3e e3     ld a,0e3h
45D0  0e 04     ld c,004h
45D2  ef        rst 28h
45D3  3a 10 38  ld a,(03810h)
45D6  fe 0e     cp 00eh
45D8  18 0e     jr l45e8h
45DA  3a be 45  ld a,(l45beh)
45DD  d6 c9     sub 0c9h
45DF  ca 0d 44  jp z,l440dh
45E2  f1        pop af
45E3  c1        pop bc
45E4  d1        pop de
45E5  e1        pop hl
45E6  18 22     jr l460ah
45E8  3a 02 38  ld a,(03802h)
45EB  fe 1c     cp 01ch
45ED  7a        ld a,d
45EE  c9        ret
45EF  3e 7c     ld a,07ch
45F1  ef        rst 28h
45F2  f5        push af
45F3  e5        push hl
45F4  d5        push de
45F5  c5        push bc
45F6  3a ec 37  ld a,(037ech)
45F9  3a e0 37  ld a,(037e0h)
45FC  07        rlca
45FD  dc 10 46  call c,sub_4610h
4600  cd be 45  call l45beh
4603  c1        pop bc
4604  d1        pop de
4605  e1        pop hl
4606  f1        pop af
4607  fb        ei
4608  c9        ret
4609  f5        push af
460A  3e 27     ld a,027h
460C  ef        rst 28h
460D  70        ld (hl),b
460E  23        inc hl
460F  e9        jp (hl)
4610  21 40 40  ld hl,04040h
4613  34        inc (hl)
4614  21 4f 45  ld hl,0454fh
4617  7e        ld a,(hl)
4618  b7        or a
4619  28 01     jr z,l461ch
461B  35        dec (hl)
461C  21 c9 44  ld hl,l44c9h
461F  7c        ld a,h
4620  b5        or l
4621  c8        ret z
4622  5e        ld e,(hl)
4623  23        inc hl
4624  56        ld d,(hl)
4625  d5        push de
4626  23        inc hl
4627  46        ld b,(hl)
4628  23        inc hl
4629  35        dec (hl)
462A  cc 0d 46  call z,sub_460dh
462D  e1        pop hl
462E  18 ef     jr l461fh
4630  3e 88     ld a,088h
4632  18 0e     jr l4642h
4634  e5        push hl
4635  26 38     ld h,038h
4637  cd 30 46  call sub_4630h
463A  e1        pop hl
463B  c9        ret
; ------------------------------------------------------------
; Name:       WRITDS
; Funktion:   schreibt einen Sector des Directory auf Diskette
; Input:      DE: gewuenschte Sector# (Disk-relativ)
;             HL: Zeiger auf zu benutzenden Buffer
;             (4308H): gewuenschte Drive# (0-3)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
463C  3e a9     ld a,0a9h
463E  18 02     jr l4642h
4640  3e a8     ld a,0a8h
4642  32 c4 46  ld (046c4h),a
4645  e6 20     and 020h
4647  c5        push bc
4648  01 1a 02  ld bc,0021ah
464B  28 05     jr z,l4652h
464D  3e 08     ld a,008h
464F  01 12 0a  ld bc,00a12h
4652  32 31 47  ld (l4730h+1),a
4655  ed 43 fc 46 ld (l46fch),bc
4659  06 0a     ld b,00ah
465B  cd 73 47  call sub_4773h
465E  20 18     jr nz,l4678h
4660  c5        push bc
4661  d5        push de
4662  e5        push hl
4663  3a 0e 43  ld a,(0430eh)
4666  eb        ex de,hl
4667  cd b4 4c  call sub_4cb4h
466A  55        ld d,l
466B  5f        ld e,a
466C  21 0d 43  ld hl,0430dh
466F  7a        ld a,d
4670  be        cp (hl)
4671  38 09     jr c,l467ch
4673  3e 14     ld a,014h
4675  e1        pop hl
4676  d1        pop de
4677  c1        pop bc
4678  b7        or a
4679  c3 37 47  jp l4737h
467C  3a 11 43  ld a,(04311h)
467F  47        ld b,a
4680  cb 40     bit 0,b
4682  28 05     jr z,l4689h
4684  21 c4 46  ld hl,046c4h
4687  cb 8e     res 1,(hl)
4689  21 09 43  ld hl,04309h
468C  cb 48     bit 1,b
468E  28 01     jr z,l4691h
4690  14        inc d
4691  d5        push de
4692  cb 50     bit 2,b
4694  28 02     jr z,l4698h
4696  cb 02     rlc d
4698  cb 70     bit 6,b
469A  28 09     jr z,l46a5h
469C  cb 09     rrc c
469E  7b        ld a,e
469F  91        sub c
46A0  38 03     jr c,l46a5h
46A2  5f        ld e,a
46A3  cb e6     set 4,(hl)
46A5  cd 67 47  call sub_4767h
46A8  cb 60     bit 4,b
46AA  28 01     jr z,l46adh
46AC  1c        inc e
46AD  ed 53 ee 37 ld (037eeh),de
46B1  0e 18     ld c,018h
46B3  cd 47 47  call sub_4747h
46B6  f1        pop af
46B7  c1        pop bc
46B8  c5        push bc
46B9  32 ed 37  ld (037edh),a
46BC  d5        push de
46BD  11 ef 37  ld de,037efh
46C0  21 ec 37  ld hl,037ech
46C3  36 00     ld (hl),000h
46C5  cd e3 47  call sub_47e3h
46C8  f3        di
46C9  cb 46     bit 0,(hl)
46CB  28 4a     jr z,l4717h
46CD  3a c4 46  ld a,(046c4h)
46D0  cb 6f     bit 5,a
46D2  28 22     jr z,l46f6h
46D4  3e 83     ld a,083h
46D6  a6        and (hl)
46D7  e2 d4 46  jp po,l46d4h
46DA  0a        ld a,(bc)
46DB  12        ld (de),a
46DC  03        inc bc
46DD  0a        ld a,(bc)
46DE  32 e8 46  ld (046e8h),a
46E1  03        inc bc
46E2  3e 01     ld a,001h
46E4  be        cp (hl)
46E5  28 fd     jr z,l46e4h
46E7  3e 00     ld a,000h
46E9  12        ld (de),a
46EA  0a        ld a,(bc)
46EB  03        inc bc
46EC  cb 4e     bit 1,(hl)
46EE  20 0c     jr nz,l46fch
46F0  cb 4e     bit 1,(hl)
46F2  20 08     jr nz,l46fch
46F4  18 09     jr l46ffh
46F6  3e 83     ld a,083h
46F8  a6        and (hl)
46F9  e2 f6 46  jp po,l46f6h
46FC  1a        ld a,(de)
46FD  02        ld (bc),a
46FE  03        inc bc
46FF  cb 4e     bit 1,(hl)
4701  20 f9     jr nz,l46fch
4703  cb 4e     bit 1,(hl)
4705  20 f5     jr nz,l46fch
4707  cb 4e     bit 1,(hl)
4709  20 f1     jr nz,l46fch
470B  cb 46     bit 0,(hl)
470D  28 08     jr z,l4717h
470F  cb 4e     bit 1,(hl)
4711  20 e9     jr nz,l46fch
4713  cb 7e     bit 7,(hl)
4715  28 e8     jr z,l46ffh
4717  7e        ld a,(hl)
4718  36 d0     ld (hl),0d0h
471A  23        inc hl
471B  c1        pop bc
471C  70        ld (hl),b
471D  e1        pop hl
471E  d1        pop de
471F  c1        pop bc
4720  fb        ei
4721  e6 fc     and 0fch
4723  28 12     jr z,l4737h
4725  4f        ld c,a
4726  e6 9c     and 09ch
4728  28 06     jr z,l4730h
472A  4f        ld c,a
472B  87        add a,a
472C  28 02     jr z,l4730h
472E  10 0a     djnz l473ah
4730  3e 00     ld a,000h
4732  3c        inc a
4733  cb 09     rrc c
4735  30 fb     jr nc,l4732h
4737  fb        ei
4738  c1        pop bc
4739  c9        ret
473A  cb 61     bit 4,c
473C  c4 42 47  call nz,sub_4742h
473F  c3 60 46  jp l4660h
4742  cb 40     bit 0,b
4744  c8        ret z
; ------------------------------------------------------------
; Name:       RESTORE
; Funktion:   RESTORE-Kommando an FDC senden und warten, bis der
;             FDC nicht mehr busy ist
; Input:      --
; Veraendert: AF, C
; Output:     --
; ------------------------------------------------------------
4745  0e 08     ld c,008h
4747  3a 0c 43  ld a,(0430ch)
474A  e6 03     and 003h
474C  b1        or c
474D  32 ec 37  ld (037ech),a
4750  cd e3 47  call sub_47e3h
4753  cb 47     bit 0,a
4755  c8        ret z
4756  07        rlca
4757  38 05     jr c,l475eh
4759  cd 67 47  call sub_4767h
475C  18 f2     jr l4750h
; ------------------------------------------------------------
; Name:       FBREAK
; Funktion:   FORCE-INTERRUPT-Kommando an FDC senden und
;             warten, bis FDC nicht mehr busy ist
; Input:      --
; Veraendert: AF
; Output:     --
; ------------------------------------------------------------
475E  3e d0     ld a,0d0h
4760  18 eb     jr l474dh
; ------------------------------------------------------------
; MOTONX (Fortsetzung von 4416H) -- Kasten dort.
; ------------------------------------------------------------
4762  3a ec 37  ld a,(037ech)  ; laufen die Drive-Motoren noch?
4765  07        rlca
4766  d8        ret c
; ------------------------------------------------------------
; Name:       MOTON
; Funktion:   Drive-Motoren starten
; Input:      --
; Veraendert: A
; Output:     --
; ------------------------------------------------------------
4767  3a 09 43  ld a,(04309h)
476A  32 e1 37  ld (037e1h),a
476D  c9        ret
; ------------------------------------------------------------
; DRVSLX -- wie DRVSEL, aber die Drive# kommt aus (IX+6).
; Faellt bei 4771h nach DRVSEL durch.
; ------------------------------------------------------------
476E  dd 7e 06  ld a,(ix+006h)
4771  18 03     jr l4776h
4773  3a 08 43  ld a,(04308h)
; ------------------------------------------------------------
; Name:       DRVSEL (Fortsetzung von 445BH)
; Funktion:   Drive (A) auswaehlen und Motor starten
; Input:      A: gewuenschte Drive# (0-3)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
; Das gewuenschte Laufwerk wird als 'aktuelles Laufwerk' bei 4308H
; vermerkt, sein Bit-Muster wird nach 4309H sowie seine
; PDRIVE-Parameter nach 430AH-4311H uebertragen.
4776  e5        push hl
4777  d5        push de
4778  c5        push bc
4779  fe 01     cp 001h
477B  4f        ld c,a
477C  3e 20     ld a,020h
477E  30 5e     jr nc,l47deh
4780  cd 5e 47  call l475eh
4783  21 08 43  ld hl,04308h
4786  7e        ld a,(hl)
4787  71        ld (hl),c
4788  b9        cp c
4789  f5        push af
478A  6f        ld l,a
478B  3a ed 37  ld a,(037edh)
478E  77        ld (hl),a
478F  69        ld l,c
4790  e5        push hl
4791  41        ld b,c
4792  3e 80     ld a,080h
4794  04        inc b
4795  07        rlca
4796  10 fd     djnz l4795h
4798  32 09 43  ld (04309h),a
479B  79        ld a,c
479C  07        rlca
479D  07        rlca
479E  81        add a,c
479F  87        add a,a
47A0  c6 71     add a,071h
47A2  6f        ld l,a
47A3  22 99 43  ld (04399h),hl
47A6  0e 08     ld c,008h
47A8  11 0a 43  ld de,0430ah
47AB  ed b0     ldir
47AD  21 ec 37  ld hl,037ech
47B0  5e        ld e,(hl)
47B1  f3        di
47B2  3a 11 43  ld a,(04311h)
47B5  f6 fe     or 0feh
47B7  77        ld (hl),a
47B8  36 d0     ld (hl),0d0h
47BA  fb        ei
47BB  23        inc hl
47BC  c1        pop bc
47BD  0a        ld a,(bc)
47BE  77        ld (hl),a
47BF  23        inc hl
47C0  3a 10 43  ld a,(04310h)
47C3  77        ld (hl),a
47C4  cd 5e 47  call l475eh
47C7  cd 59 47  call sub_4759h
47CA  06 80     ld b,080h
47CC  cb 7b     bit 7,e
47CE  c4 ed 4c  call nz,sub_4cedh
47D1  f1        pop af
47D2  28 09     jr z,l47ddh
47D4  3a 0c 43  ld a,(0430ch)
47D7  07        rlca
47D8  06 0c     ld b,00ch
47DA  dc ed 4c  call c,sub_4cedh
47DD  af        xor a
47DE  c1        pop bc
47DF  d1        pop de
47E0  e1        pop hl
47E1  b7        or a
47E2  c9        ret
; ------------------------------------------------------------
; Name:       DELAY1
; Funktion:   ca. 55 us warten (bei 1.774 MHz) und Status-
;             Register des FDC lesen
; Input:      --
; Veraendert: F
; Output:     A: Status des FDC
; ------------------------------------------------------------
47E3  3e 0c     ld a,00ch
47E5  3d        dec a
47E6  20 fd     jr nz,l47e5h
47E8  3a ec 37  ld a,(037ech)
47EB  c9        ret
; ------------------------------------------------------------
; Name:       DSKTST (Fortsetzung von 445EH; bei Grosser TSTDSK)
; Funktion:   Drive (A) auswaehlen, Motor starten und testen,
;             ob Diskette eingelegt
; Input:      A: gewuenschte Drive# (0-3)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
; Es wird DRVSEL (445BH) aufgerufen und, wenn dabei kein Fehler
; auftrat, anschliessend geprueft, ob sich eine drehende Diskette im
; Laufwerk befindet.
47EC  cd 76 47  call l4776h
47EF  c0        ret nz
47F0  e5        push hl
47F1  d5        push de
47F2  c5        push bc
47F3  11 00 00  ld de,00000h
47F6  21 ec 37  ld hl,037ech
47F9  46        ld b,(hl)
47FA  7e        ld a,(hl)
47FB  a8        xor b
47FC  e6 02     and 002h
47FE  20 dd     jr nz,l47ddh
4800  1b        dec de
4801  7a        ld a,d
4802  b3        or e
4803  20 f5     jr nz,l47fah
4805  3e 08     ld a,008h
4807  18 d5     jr l47deh
; ------------------------------------------------------------
; EXPAND (Fortsetzung von 444BH) -- Kasten dort.
; ------------------------------------------------------------
4809  cd 80 49  call sub_4980h
480C  cd b7 49  call sub_49b7h
480F  af        xor a
; ------------------------------------------------------------
; Name:       FILPOS
; Funktion:   berechnet die physikalische Position des Sectors, auf
;             den das NEXT-Feld zeigt
; Input:      IX: zeigt auf geoeffneten FCB
;             IY: muss auf 4380H zeigen
;             A:  00: File darf erweitert werden
;                 B6: File darf nicht erweitert werden
;             vorher: Call PUSHR (4980H)!
; Veraendert: BC
; Output:     AF: A=Fehlercode, wenn Z=0
;             DE: gesuchte Sector# (Disk-relativ)
;             HL: zeigt auf Buffer der File
; ------------------------------------------------------------
; FILPOS berechnet, wo derjenige Sector einer File, auf den das NEXT-Feld
; zeigt, letztendlich auf Diskette steht. Falls die File kürzer ist, als das
; NEXT-Feld angibt, wird sie dabei - sofern das erlaubt ist - um entsprechend viele GRANS erweitert.
; Vor dem Aufruf von FILPOS muß UP PUSHR (4980H) aufgerufen worden sein,
; damit im Falle eines Errors der Notaussprung über 49CDH funktioniert!
; Arbeitsweise von FILPOS: Es werden zunächst die 4 Datenblocks überprüft,
; deren Angaben im FCB+0E bis FCB+15H stehen, ob sie den gesuchten Sector
; enthalten. Wenn nein, werden nun die 4 Erweiterungs-Datenblocks überprüft,
; deren Angaben zur Zeit im FCB+16H bis FCB+1F enthalten sind. Falls auch
; sie den gesuchten Sector nicht enthalten, werden aus dem Directory nacheinander alle FDE’s dieser File gelesen und überprüft, bis die Informationen über den gesuchten Sector gefunden sind oder das Ende der File
; erreicht wurde. In letztem Fall wird - sofern die File erweitert werden
; darf - nun SYS2/SYS damit beauftragt, freie GRANS zu suchen und für diese
; File zu belegen.
4810  32 bb 48  ld (048bbh),a
4813  cd 6e 47  call sub_476eh
4816  20 5a     jr nz,l4872h
4818  cd 68 49  call sub_4968h
481B  eb        ex de,hl
481C  dd 7e 00  ld a,(ix+000h)
481F  0f        rrca
4820  0f        rrca
4821  38 30     jr c,sub_4853h
4823  0f        rrca
4824  3e 2d     ld a,02dh
4826  38 4a     jr c,l4872h
4828  eb        ex de,hl
4829  cd b2 4c  call sub_4cb2h
482C  0e 0e     ld c,00eh
482E  eb        ex de,hl
482F  dd e5     push ix
4831  e1        pop hl
4832  09        add hl,bc
4833  f5        push af
4834  e5        push hl
4835  d5        push de
4836  3e 08     ld a,008h
4838  08        ex af,af'
4839  7e        ld a,(hl)
483A  3c        inc a
483B  23        inc hl
483C  28 54     jr z,l4892h
483E  7e        ld a,(hl)
483F  cd e9 48  call sub_48e9h
4842  30 31     jr nc,l4875h
4844  09        add hl,bc
4845  eb        ex de,hl
4846  ae        xor (hl)
4847  07        rlca
4848  07        rlca
4849  07        rlca
484A  83        add a,e
484B  5f        ld e,a
484C  f1        pop af
484D  f1        pop af
484E  f1        pop af
484F  2b        dec hl
4850  cd 7c 4c  call sub_4c7ch
4853  dd 6e 03  ld l,(ix+003h)
4856  dd 66 04  ld h,(ix+004h)
4859  af        xor a
485A  c9        ret
485B  c1        pop bc
485C  c1        pop bc
485D  e1        pop hl
485E  ed 52     sbc hl,de
4860  09        add hl,bc
4861  44        ld b,h
4862  4d        ld c,l
4863  f5        push af
4864  cd 2f 49  call sub_492fh
4867  20 09     jr nz,l4872h
4869  3e ff     ld a,0ffh
486B  23        inc hl
486C  be        cp (hl)
486D  2b        dec hl
486E  28 2f     jr z,l489fh
4870  3e 2c     ld a,02ch
4872  c3 cd 49  jp l49cdh
4875  eb        ex de,hl
4876  23        inc hl
4877  dd cb 01 5e bit 3,(ix+001h)
487B  37        scf
487C  28 a6     jr z,l4824h
487E  08        ex af,af'
487F  fe 05     cp 005h
4881  20 0c     jr nz,l488fh
4883  4e        ld c,(hl)
4884  23        inc hl
4885  46        ld b,(hl)
4886  23        inc hl
4887  d1        pop de
4888  d5        push de
4889  eb        ex de,hl
488A  ed 42     sbc hl,bc
488C  eb        ex de,hl
488D  38 03     jr c,l4892h
488F  3d        dec a
4890  20 a6     jr nz,l4838h
4892  01 00 00  ld bc,00000h
4895  d1        pop de
4896  cd 4b 49  call sub_494bh
4899  20 cc     jr nz,l4867h
489B  dd 7e 07  ld a,(ix+007h)
489E  f5        push af
489F  f1        pop af
48A0  32 6a 48  ld (0486ah),a
48A3  cb 66     bit 4,(hl)
48A5  28 c9     jr z,l4870h
48A7  d5        push de
48A8  c5        push bc
48A9  7d        ld a,l
48AA  c6 16     add a,016h
48AC  6f        ld l,a
48AD  e5        push hl
48AE  7e        ld a,(hl)
48AF  fe fe     cp 0feh
48B1  23        inc hl
48B2  7e        ld a,(hl)
48B3  23        inc hl
48B4  38 10     jr c,l48c6h
48B6  28 a3     jr z,l485bh
48B8  3e 3e     ld a,03eh
48BA  18 00     jr l48bch
48BC  f1        pop af
48BD  3e 64     ld a,064h
48BF  cd dd 49  call sub_49ddh
48C2  c1        pop bc
48C3  d1        pop de
48C4  18 dd     jr l48a3h
48C6  cb 65     bit 4,l
48C8  28 a6     jr z,l4870h
48CA  cd e9 48  call sub_48e9h
48CD  eb        ex de,hl
48CE  30 de     jr nc,l48aeh
48D0  c1        pop bc
48D1  d1        pop de
48D2  f1        pop af
48D3  e1        pop hl
48D4  f1        pop af
48D5  c5        push bc
48D6  01 08 00  ld bc,00008h
48D9  7a        ld a,d
48DA  b3        or e
48DB  28 05     jr z,l48e2h
48DD  09        add hl,bc
48DE  73        ld (hl),e
48DF  23        inc hl
48E0  72        ld (hl),d
48E1  23        inc hl
48E2  eb        ex de,hl
48E3  e1        pop hl
48E4  ed b0     ldir
48E6  c3 13 48  jp l4813h
48E9  e6 1f     and 01fh
48EB  4f        ld c,a
48EC  06 00     ld b,000h
48EE  03        inc bc
48EF  eb        ex de,hl
48F0  ed 42     sbc hl,bc
48F2  c9        ret
48F3  3a 02 42  ld a,(04202h)
48F6  2a 99 43  ld hl,(04399h)
48F9  77        ld (hl),a
48FA  3a 30 49  ld a,(sub_492fh+1)
48FD  cd 74 4c  call sub_4c74h
4900  cd 30 46  call sub_4630h
4903  20 02     jr nz,l4907h
4905  f6 31     or 031h
4907  fe 06     cp 006h
4909  c9        ret
; ------------------------------------------------------------
; Name:       DIRR
; Funktion:   liest einen Sector des Directory
; Input:      A: gewuenschte Sector# (DIR-relativ)
;             (4308H): gewuenschte Drive# (0-3)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
;             HL: 4200H (Buffer fuer DIR-Sectoren)
;             (4930H): gelesene Sector# (DIR-relativ)
; ------------------------------------------------------------
490A  d5        push de
490B  c5        push bc
490C  cd fd 48  call sub_48fdh
490F  28 0b     jr z,l491ch
4911  11 00 00  ld de,00000h
4914  cd 30 46  call sub_4630h
4917  cc f3 48  call z,sub_48f3h
491A  3e 11     ld a,011h
491C  c1        pop bc
491D  d1        pop de
491E  c9        ret
; ------------------------------------------------------------
; Name:       DIRW
; Funktion:   schreibt einen Sector des Directory
; Input:      (4930H): gewuenschte Sector# (DIR-relativ)
;             (4308H): gewuenschte Drive# (0-3)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
;             HL: 4200H (Buffer fuer DIR-Sectoren)
; ------------------------------------------------------------
491F  3a 30 49  ld a,(sub_492fh+1)
4922  d5        push de
4923  c5        push bc
4924  cd 74 4c  call sub_4c74h
4927  b4        or h
4928  cd b8 4a  call sub_4ab8h
492B  3e 12     ld a,012h
492D  18 ed     jr l491ch
492F  2e ff     ld l,0ffh
4931  18 05     jr l4938h
4933  dd 7e 07  ld a,(ix+007h)
; ------------------------------------------------------------
; Name:       GETFDE
; Funktion:   holt einen FDE aus dem Directory
; Input:      A: DEC des gewuenschten FDE's
;             (4308H): gewuenschte Drive# (0-3)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
;             HL: zeigt im Puffer (42XXH) auf FDE+0
;             (4930H): gelesene DIR-Sector#
; ------------------------------------------------------------
4936  2e ff     ld l,0ffh
4938  f5        push af
4939  e6 1f     and 01fh
493B  3c        inc a
493C  3c        inc a
493D  bd        cp l
493E  c4 0a 49  call nz,sub_490ah
4941  e1        pop hl
4942  c0        ret nz
4943  3e e0     ld a,0e0h
4945  a4        and h
4946  6f        ld l,a
4947  26 42     ld h,042h
4949  bf        cp a
494A  c9        ret
494B  cd 6e 47  call sub_476eh
494E  cc 33 49  call z,sub_4933h
4951  c0        ret nz
4952  e5        push hl
4953  c6 16     add a,016h
4955  6f        ld l,a
4956  dd 7e 0e  ld a,(ix+00eh)
; ------------------------------------------------------------
; [note]      4959h: reads dfcbdec (43D5h), which rdecfix
;             (4495h) sets via the 4BF0h patch.
; ------------------------------------------------------------
4959  be        cp (hl)
495A  e1        pop hl
495B  28 03     jr z,l4960h
495D  3c        inc a
495E  20 05     jr nz,l4965h
4960  7e        ld a,(hl)
4961  e6 90     and 090h
4963  fe 10     cp 010h
4965  3e 2d     ld a,02dh
4967  c9        ret
4968  dd 4e 05  ld c,(ix+005h)
496B  dd 6e 0a  ld l,(ix+00ah)
496E  dd 66 0b  ld h,(ix+00bh)
4971  7c        ld a,h
4972  dd be 0d  cp (ix+00dh)
4975  c0        ret nz
4976  7d        ld a,l
4977  dd be 0c  cp (ix+00ch)
497A  c0        ret nz
497B  79        ld a,c
497C  dd be 08  cp (ix+008h)
497F  c9        ret
4980  1a        ld a,(de)
4981  07        rlca
4982  3e 26     ld a,026h
4984  30 01     jr nc,l4987h
4986  af        xor a
4987  08        ex af,af'
4988  e3        ex (sp),hl
4989  22 a6 49  ld (049a6h),hl
498C  e1        pop hl
498D  fd e5     push iy
498F  e5        push hl
4990  d5        push de
4991  c5        push bc
4992  f5        push af
4993  d5        push de
4994  dd e3     ex (sp),ix
4996  e5        push hl
4997  2a ce 49  ld hl,(l49cdh+1)
499A  e3        ex (sp),hl
499B  ed 73 ce 49 ld (l49cdh+1),sp
499F  fd 21 80 43 ld iy,04380h
49A3  08        ex af,af'
49A4  b7        or a
49A5  cc 00 00  call z,00000h
49A8  e1        pop hl
49A9  22 ce 49  ld (l49cdh+1),hl
49AC  08        ex af,af'
49AD  dd e1     pop ix
49AF  f1        pop af
49B0  c1        pop bc
49B1  d1        pop de
49B2  e1        pop hl
49B3  fd e1     pop iy
49B5  08        ex af,af'
49B6  c9        ret
49B7  06 05     ld b,005h
49B9  dd 7e 01  ld a,(ix+001h)
49BC  e6 07     and 007h
49BE  b8        cp b
49BF  d8        ret c
49C0  3e 25     ld a,025h
49C2  18 09     jr l49cdh
49C4  cd 68 49  call sub_4968h
49C7  d8        ret c
49C8  3e 1c     ld a,01ch
49CA  28 01     jr z,l49cdh
49CC  3c        inc a
49CD  31 00 00  ld sp,00000h
49D0  b7        or a
49D1  18 d5     jr l49a8h
49D3  c2 09 44  jp nz,l4409h
49D6  af        xor a
49D7  20 f4     jr nz,l49cdh
49D9  e3        ex (sp),hl
49DA  7c        ld a,h
49DB  4d        ld c,l
49DC  e1        pop hl
49DD  ef        rst 28h
49DE  dd cb 01 7e bit 7,(ix+001h)
49E2  c8        ret z
49E3  d1        pop de
49E4  dd 46 09  ld b,(ix+009h)
49E7  f5        push af
49E8  e5        push hl
49E9  c5        push bc
49EA  4e        ld c,(hl)
49EB  cd ed 4a  call sub_4aedh
49EE  20 dd     jr nz,l49cdh
49F0  5f        ld e,a
49F1  c1        pop bc
49F2  e1        pop hl
49F3  f1        pop af
49F4  30 01     jr nc,l49f7h
49F6  73        ld (hl),e
49F7  23        inc hl
49F8  10 ed     djnz l49e7h
49FA  af        xor a
49FB  c9        ret
; ------------------------------------------------------------
; Name:       READ (Fortsetzung von 4436H)
; Funktion:   naechsten Sector/Record einer File lesen
; Input:      DE: zeigt auf geoeffneten FCB
;             HL: zeigt auf Record-Buffer (nur wenn Logische
;             Recordlaenge <> 256D ist)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
49FC  cd 80 49  call sub_4980h
49FF  37        scf
4A00  cd de 49  call sub_49deh
4A03  cd 19 4a  call sub_4a19h
4A06  28 03     jr z,l4a0bh
4A08  fe 06     cp 006h
4A0A  c0        ret nz
4A0B  dd 34 0a  inc (ix+00ah)
4A0E  20 03     jr nz,l4a13h
4A10  dd 34 0b  inc (ix+00bh)
4A13  dd cb 01 ee set 5,(ix+001h)
4A17  b7        or a
4A18  c9        ret
4A19  06 06     ld b,006h
4A1B  cd b9 49  call sub_49b9h
4A1E  cd c4 49  call sub_49c4h
4A21  3e b6     ld a,0b6h
4A23  cd 10 48  call sub_4810h
4A26  cd 30 46  call sub_4630h
4A29  dd cb 01 ae res 5,(ix+001h)
4A2D  dd cb 01 a6 res 4,(ix+001h)
4A31  c9        ret
; ------------------------------------------------------------
; Name:       VERIFY (Fortsetzung von 443CH)
; Funktion:   naechsten Sector/Record einer File auf Diskette
;             schreiben, anschliessend Verify
; Input:      DE: zeigt auf geoeffneten FCB
;             HL: zeigt auf Record-Buffer (nur wenn Logische
;             Recordlaenge <> 256D ist)
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4A32  3e f6     ld a,0f6h
4A34  18 02     jr l4a38h
4A36  3e e6     ld a,0e6h
4A38  32 8b 4a  ld (l4a8bh),a
4A3B  cd 80 49  call sub_4980h
4A3E  cd de 49  call sub_49deh
4A41  cd 67 4a  call sub_4a67h
4A44  c0        ret nz
4A45  dd 7e 05  ld a,(ix+005h)
4A48  b7        or a
4A49  cc 0b 4a  call z,l4a0bh
4A4C  cd 68 49  call sub_4968h
4A4F  30 06     jr nc,l4a57h
4A51  dd cb 01 76 bit 6,(ix+001h)
4A55  20 09     jr nz,l4a60h
4A57  dd 71 08  ld (ix+008h),c
4A5A  dd 75 0c  ld (ix+00ch),l
4A5D  dd 74 0d  ld (ix+00dh),h
4A60  af        xor a
4A61  c9        ret
4A62  dd cb 01 66 bit 4,(ix+001h)
4A66  c8        ret z
4A67  cd 0c 48  call sub_480ch
4A6A  dd cb 02 6e bit 5,(ix+002h)
4A6E  20 18     jr nz,l4a88h
4A70  dd cb 00 4e bit 1,(ix+000h)
4A74  20 12     jr nz,l4a88h
4A76  e5        push hl
4A77  cd 4b 49  call sub_494bh
4A7A  20 03     jr nz,l4a7fh
4A7C  23        inc hl
4A7D  cb ee     set 5,(hl)
4A7F  cc 1f 49  call z,sub_491fh
4A82  e1        pop hl
4A83  c0        ret nz
4A84  dd cb 02 ee set 5,(ix+002h)
4A88  dd 7e 01  ld a,(ix+001h)
4A8B  e6 90     and 090h
4A8D  dd cb 00 46 bit 0,(ix+000h)
4A91  cd b8 4a  call sub_4ab8h
4A94  c0        ret nz
4A95  af        xor a
4A96  18 95     jr l4a2dh
; ------------------------------------------------------------
; Name:       WRITEB (Fortsetzung von 001BH)
; Funktion:   naechstes Byte in eine File schreiben
; Input:      DE: zeigt auf geoeffneten FCB
;             A:  zu schreibendes Byte
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4A98  28 12     jr z,l4aach
4A9A  c5        push bc
4A9B  cd 0c 48  call sub_480ch
4A9E  cd 68 49  call sub_4968h
4AA1  20 01     jr nz,l4aa4h
4AA3  b7        or a
4AA4  c4 21 4a  call nz,sub_4a21h
4AA7  c1        pop bc
4AA8  c0        ret nz
4AA9  cd 29 4a  call sub_4a29h
4AAC  cd 0b 4b  call sub_4b0bh
4AAF  71        ld (hl),c
4AB0  dd cb 01 e6 set 4,(ix+001h)
4AB4  28 8b     jr z,l4a41h
4AB6  18 94     jr l4a4ch
; ------------------------------------------------------------
; Name:       WRITXV
; Funktion:   schreibt einen normalen Sector oder einen Sector
;             des Directory auf Diskette, anschliessend Verify
;             (optional)
; Input:      DE: gewuenschte Sector# (Disk-relativ)
;             HL: Zeiger auf zu benutzenden Buffer
;             A:  Verify nur durchfuehren, wenn A <> 00
;             F:  normaler (Z=1) oder DIR-Sector (Z=0)
;             (4308H): gewuenschte Drive# (0-3)
; Veraendert: BC
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4AB8  4f        ld c,a
4AB9  06 03     ld b,003h
4ABB  20 0d     jr nz,l4acah
; ------------------------------------------------------------
; Name:       WRITEV
; Funktion:   schreibt einen normalen Sector auf Diskette,
;             anschliessend Verify (optional)
; Input:      DE: gewuenschte Sector# (Disk-relativ)
;             HL: Zeiger auf zu benutzenden Buffer
;             C:  Verify nur durchfuehren, wenn C <> 00
;             B:  max. Anzahl Verify-Versuche
;             (4308H): gewuenschte Drive# (0-3)
; Veraendert: B
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4ABD  cd 40 46  call sub_4640h
4AC0  c0        ret nz
4AC1  79        ld a,c
4AC2  b7        or a
4AC3  c4 34 46  call nz,sub_4634h
4AC6  c8        ret z
4AC7  10 f4     djnz l4abdh
4AC9  c9        ret
; ------------------------------------------------------------
; Name:       WRITDV
; Funktion:   schreibt einen Sector des Directory auf Diskette,
;             anschliessend Verify (optional)
; Input:      DE: gewuenschte Sector# (Disk-relativ)
;             HL: Zeiger auf zu benutzenden Buffer
;             C:  Verify nur durchfuehren, wenn C <> 00
;             B:  max. Anzahl Verify-Versuche
;             (4308H): gewuenschte Drive# (0-3)
; Veraendert: B
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
; WRITDV schreibt einen physikalischen Sector mit dem Data Adress Mark für
; Directory-Sectoren auf Diskette. DE gibt an, um den wievielten Sector
; innerhalb der Diskette (beginnend ab 0) es sich dabei handelt. Zuvor muß
; bei 4308H die gewünschte Drive# eingetragen worden sein, z. B. durch
; DRVSEL (445BH) oder TSTDSK (445EH).
; Wenn Register C <> 00 ist, wird der Sector nach dem Schreiben getestet, ob
; er auch ohne Fehler lesbar ist. Wenn nein, wird das Schreiben und anschl.
; Testen so oft wiederholt, wie Register B angibt.
4ACA  cd 3c 46  call sub_463ch  ; Sector schreiben
4ACD  c0        ret nz
4ACE  79        ld a,c
4ACF  b7        or a
4AD0  c8        ret z
4AD1  cd 34 46  call sub_4634h
4AD4  cd 03 49  call sub_4903h
4AD7  c8        ret z
4AD8  10 f0     djnz l4acah
4ADA  c9        ret
4ADB  21 00 00  ld hl,00000h
4ADE  1a        ld a,(de)
4ADF  fe c0     cp 0c0h
4AE1  28 39     jr z,l4b1ch
4AE3  cd 80 49  call sub_4980h
4AE6  dd cb 01 fe set 7,(ix+001h)
4AEA  78        ld a,b
4AEB  fe 02     cp 002h
4AED  dd cb 01 6e bit 5,(ix+001h)
4AF1  30 a5     jr nc,l4a98h
; ------------------------------------------------------------
; Name:       READB (Fortsetzung von 0013H)
; Funktion:   naechstes Byte aus einer File lesen
; Input:      DE: zeigt auf geoeffneten FCB
; Veraendert: --
; Output:     AF: wenn Z=1: A = naechstes Byte
;                 wenn Z=0: A = Fehlercode
; ------------------------------------------------------------
4AF3  c4 19 4a  call nz,sub_4a19h
4AF6  c0        ret nz
4AF7  cd c4 49  call sub_49c4h
4AFA  cd 0b 4b  call sub_4b0bh
4AFD  20 09     jr nz,l4b08h
4AFF  e5        push hl
4B00  cd 62 4a  call sub_4a62h
4B03  e1        pop hl
4B04  c0        ret nz
4B05  cd 0b 4a  call l4a0bh
4B08  7e        ld a,(hl)
4B09  bf        cp a
4B0A  c9        ret
4B0B  cd 53 48  call sub_4853h
4B0E  dd 5e 05  ld e,(ix+005h)
4B11  57        ld d,a
4B12  19        add hl,de
4B13  dd 34 05  inc (ix+005h)
4B16  c9        ret
4B17  23        inc hl
4B18  7e        ld a,(hl)
4B19  23        inc hl
4B1A  66        ld h,(hl)
4B1B  6f        ld l,a
4B1C  7c        ld a,h
4B1D  b5        or l
4B1E  79        ld a,c
4B1F  c8        ret z
4B20  7e        ld a,(hl)
4B21  bb        cp e
4B22  23        inc hl
4B23  20 02     jr nz,l4b27h
4B25  7e        ld a,(hl)
4B26  ba        cp d
4B27  23        inc hl
4B28  20 ed     jr nz,l4b17h
4B2A  e5        push hl
4B2B  d5        push de
4B2C  c5        push bc
4B2D  7e        ld a,(hl)
4B2E  a0        and b
4B2F  23        inc hl
4B30  23        inc hl
4B31  23        inc hl
4B32  5e        ld e,(hl)
4B33  23        inc hl
4B34  56        ld d,(hl)
4B35  d5        push de
4B36  dd e1     pop ix
4B38  cd d4 03  call 003d4h
4B3B  c1        pop bc
4B3C  d1        pop de
4B3D  e1        pop hl
4B3E  cb 40     bit 0,b
4B40  28 d5     jr z,l4b17h
4B42  4f        ld c,a
4B43  b7        or a
4B44  28 d1     jr z,l4b17h
4B46  c9        ret
; ------------------------------------------------------------
; POSRBA (Fortsetzung von 444EH) -- Kasten dort.
; ------------------------------------------------------------
4B47  cd 80 49  call sub_4980h
4B4A  18 34     jr l4b80h
; ------------------------------------------------------------
; Name:       POSO (Fortsetzung von 443FH)
; Funktion:   NEXT-Feld im FCB auf Beginn der File
;             positionieren
; Input:      DE: zeigt auf geoeffneten FCB
; Veraendert: --
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
4B4C  cd 80 49  call sub_4980h
4B4F  67        ld h,a
4B50  6f        ld l,a
4B51  4f        ld c,a
4B52  18 3c     jr l4b90h
; ------------------------------------------------------------
; POSEOF (Fortsetzung von 4448H) -- Kasten dort.
; ------------------------------------------------------------
4B54  cd 80 49  call sub_4980h
4B57  dd 4e 08  ld c,(ix+008h)
4B5A  dd 6e 0c  ld l,(ix+00ch)
4B5D  dd 66 0d  ld h,(ix+00dh)
4B60  18 22     jr l4b84h
; ------------------------------------------------------------
; POSDEC (Fortsetzung von 4445H) -- Kasten dort.
; ------------------------------------------------------------
4B62  cd 80 49  call sub_4980h
4B65  cd 68 49  call sub_4968h
4B68  af        xor a
4B69  dd 96 09  sub (ix+009h)
4B6C  81        add a,c
4B6D  4f        ld c,a
4B6E  38 31     jr c,l4ba1h
4B70  2b        dec hl
4B71  18 1d     jr l4b90h
; ------------------------------------------------------------
; POSBC (Fortsetzung von 4442H) -- Kasten dort.
; ------------------------------------------------------------
4B73  cd 80 49  call sub_4980h
4B76  60        ld h,b
4B77  69        ld l,c
4B78  dd 7e 09  ld a,(ix+009h)
4B7B  b7        or a
4B7C  4f        ld c,a
4B7D  c4 9d 4c  call nz,sub_4c9dh
4B80  dd cb 01 f6 set 6,(ix+001h)
4B84  7c        ld a,h
4B85  dd be 0b  cp (ix+00bh)
4B88  20 06     jr nz,l4b90h
4B8A  7d        ld a,l
4B8B  dd be 0a  cp (ix+00ah)
4B8E  28 11     jr z,l4ba1h
4B90  e5        push hl
4B91  c5        push bc
4B92  cd 62 4a  call sub_4a62h
4B95  c1        pop bc
4B96  e1        pop hl
4B97  c0        ret nz
4B98  cd 13 4a  call l4a13h
4B9B  dd 75 0a  ld (ix+00ah),l
4B9E  dd 74 0b  ld (ix+00bh),h
4BA1  dd 71 05  ld (ix+005h),c
4BA4  af        xor a
4BA5  c9        ret
; ------------------------------------------------------------
; TEXTTV (Fortsetzung von 4467H) -- Kasten dort.
; ------------------------------------------------------------
4BA6  d5        push de
4BA7  11 1d 40  ld de,0401dh
4BAA  e5        push hl
4BAB  7e        ld a,(hl)
4BAC  fe 03     cp 003h
4BAE  28 09     jr z,l4bb9h
4BB0  cd 1b 00  call 0001bh
4BB3  7e        ld a,(hl)
4BB4  fe 0d     cp 00dh
4BB6  23        inc hl
4BB7  20 f2     jr nz,l4babh
4BB9  e1        pop hl
4BBA  d1        pop de
4BBB  c9        ret
; ------------------------------------------------------------
; TEXTLP (Fortsetzung von 446AH) -- Kasten dort.
; ------------------------------------------------------------
4BBC  d5        push de
4BBD  11 25 40  ld de,04025h
4BC0  18 e8     jr l4baah
4BC2  33        inc sp
4BC3  33        inc sp
4BC4  fe 20     cp 020h
4BC6  da 12 43  jp c,04312h
; ******************************************************
; * Name: GETSYS                                       *
; * Funktion: SYS-File (A) laden und starten           *
; * Input: A: Code -für SYS-File (siehe Text)          *
; * Verändert: HL, DE, BC                              *
; * Output: AF: A=Fehlercode, wenn Z=0                 *
; ******************************************************
; Die SYS-File, die durch Register A angegeben ist, wird geladen (falls
; sie nicht schon im Speicher steht) und gestartet, wobei alle Register
; unverändert übergeben werden.
; Das Format des 8-Bit-Registers A ist xxxbbsss, wobei
; bbsss-2 die gewünschte SYS-File (SYS1 - SYS29) bestimmt, indem
; sss+2 angibt, im wievielten Sector des Directory der FPDE dieser
; SYS-File enthalten ist
; bb angibt, der wievielte FPDE in diesem Directory-Sector der
; gesuchte FPDE ist und
; xxx eine von evtl, mehreren Funktionen auswählt, die diese SYS-File
; enthält. Bei mehr als 7 möglichen Funktionen wird zusätzlich
; Register C zur Auswahl bestimmter Funktionen benutzt.
; Falls die ausgewählte Funktion mit einem RETURN endet, kehrt GETSYS zu
; seinem Aufrufer zurück (jedoch nicht zum Aufrufer eines RST 28H, sondern
; 1 Ebene höher) und übergibt alle Register so, wie sie durch die ausgewählte
; Funktion gesetzt wurden. Es gibt aber auch Funktionen, die nicht
; mit einem RETURN, sondern mit einem Sprunq nach DOSRDY (402DH), ERRORO
; (4030H) oder DOSERR (4409H) enden.
; ******************************************************
; * Name: GETSYS *
; * Function: Load and start a SYS file (A) *
; * Input: A: Code for SYS file (see text) *
; * Modifies: HL, DE, BC *
; * Output: AF: A = error code if Z = 0 *
; ******************************************************
; The SYS file specified by register A is loaded (if it is not already
; present in memory) and started, with all registers passed unchanged.
;
; The format of the 8‑bit register A is xxxbbsss, where:
;
;   bbsss – 2 determines the desired SYS file (SYS1 – SYS29), with
;   sss + 2 indicating in which directory sector the FPDE of this
;   SYS file is located,
;
;   bb indicating which FPDE within that directory sector is the
;   one being searched for, and
;
;   xxx selecting one of possibly several functions contained in
;   this SYS file. If more than 7 functions are available, register C
;   is additionally used to select specific functions.
;
; If the selected function ends with a RETURN, GETSYS returns to its
; caller (but not to the caller of an RST 28H — instead one level higher),
; passing all registers exactly as they were set by the selected function.
;
; However, some functions do not end with RETURN, but instead jump to
; DOSRDY (402DH), ERRORO (4030H), or DOSERR (4409H).
; ******************************************************
; 4BC9h-4C27h -- GETSYS
; *****************************************************
; ------------------------------------------------------------
; Name:       GETSYS
; Funktion:   SYS-File (A) laden und starten
; Input:      A: Code fuer SYS-File (siehe Text)
; Veraendert: HL, DE, BC
; Output:     AF: A=Fehlercode, wenn Z=0
; ------------------------------------------------------------
; Die SYS-File, die durch Register A angegeben ist, wird geladen
; (falls sie nicht schon im Speicher steht) und gestartet, wobei alle
; Register unveraendert uebergeben werden. Das Format des Registers A
; ist xxxbbsss.
4BC9  e5        push hl
4BCA  d5        push de
4BCB  c5        push bc
4BCC  f5        push af
4BCD  21 69 43  ld hl,04369h
4BD0  cb f6     set 6,(hl)
4BD2  21 be 45  ld hl,l45beh
4BD5  36 00     ld (hl),000h
4BD7  fb        ei
4BD8  e6 1f     and 01fh
4BDA  21 17 43  ld hl,04317h ; Load HL with the address 4317h — pointer to the most recently loaded SYS file.
4BDD  be        cp (hl)      ; Compare A with the byte at (HL) — is the required SYS file already in memory?
4BDE  28 38     jr z,l4c18h  ; wenn der benoetigte SYS-File bereits im Speicher steht
; ------------------------------------------------------------
; [note]      4BDEh: the bytes here are 43 be 28 38 77, so
;             this is JR Z,4C18h. The similar 28 39 / JR
;             Z,4C19h does occur, but at 4AE1h.
; ------------------------------------------------------------
4BE0  77        ld (hl),a
4BE1  e6 07     and 007h
4BE3  4f        ld c,a
; ------------------------------------------------------------
; [PATCH]     4BE4h
; Stock:      AF 32 D8 43 CD 76 47   XOR A / LD (43D8h),A / CALL 4776h
;             (DRVSEL, drive 0 hardcoded)
; This build: CD 8C 44 00 00 00 00   CALL 448Ch (rsysfcb) / NOP x4
; Reason:     GETSYS's own drive-0 site: rsysfcb (gdos-omti.asm)
;             loads the shared FCB's NEXT field (43D8h) with
;             sysvol instead of resetting it to 0, then falls
;             through to DRVSEL with sysvol in A. Same stock
;             idiom as SYS26/SYS's 4EFEh/4F3Bh and this file's
;             own 50C4h fix.
; ------------------------------------------------------------
4BE4  cd 8c 44  call 0448ch
4BE7  00        nop
4BE8  00        nop
4BE9  00        nop
4BEA  00        nop
4BEB  7e        ld a,(hl)
4BEC  91        sub c
4BED  07        rlca
4BEE  07        rlca
4BEF  81        add a,c
; ------------------------------------------------------------
; [PATCH]     4BF0h
; Stock:      CD 36 49   CALL 4936h (GETFDE)
; This build: CD 95 44   CALL 4495h (rdecfix)
; Reason:     Stock never writes the just-computed module DEC
;             back into the shared FCB's dfcbdec field (43D5h),
;             so 4959h's later verification re-derives its own
;             candidate and checks it against a stale value.
;             rdecfix (gdos-omti.asm) persists A into dfcbdec
;             before making the same GETFDE call.
; ------------------------------------------------------------
4BF0  cd 95 44  call 04495h
4BF3  20 19     jr nz,l4c0eh
4BF5  cb 76     bit 6,(hl)
4BF7  28 15     jr z,l4c0eh
4BF9  c6 16     add a,016h
4BFB  6f        ld l,a
4BFC  5e        ld e,(hl)
4BFD  23        inc hl
4BFE  56        ld d,(hl)
4BFF  ed 53 dc 43 ld (043dch),de
4C03  21 ce 43  ld hl,043ceh
; SYS-Files laden und starten
4C06  cd 28 4c  call sub_4c28h  ; SYS-File laden
4C09  22 1e 4c  ld (l4c1eh),hl  ; Startadresse der SYS-File nach 4C1E
4C0C  28 0a     jr z,l4c18h  ; wenn kein Error
; Fehlerbehandlung
4C0E  3a 17 43  ld a,(04317h)  ; sollte SYS4/SYS
4C11  fe 06     cp 006h  ; geladen werden ?
; ------------------------------------------------------------
; [PATCH]     4C13h
; Stock:      28 FE   JR Z,4C13h -- "wenn ja: Endlosschleife"
; This build: 00 00   NOP / NOP
; Reason:     Stock hangs forever when SYS4/SYS specifically
;             fails to load. NOP/NOP keeps the footprint and
;             falls through to 4C15h's own error-code step and
;             then the normal path. An unconditional JR 4C18h
;             would skip that step for every module's load
;             failure, not just SYS4/SYS's.
; ------------------------------------------------------------
4C13  00 00     nop / nop
4C15  26 2e     ld h,02eh  ; Fehlercode "SYSTEM PROGRAM NOT FOUND"
4C17  e3        ex (sp),hl  ; in den Stack statt gerettetem AF-Wert
; SYS-File starten
4C18  c1        pop bc  ; BC = urspruenglicher Wert von AF
4C19  78        ld a,b  ; A zurueck (oder Fehlercode 2E)
4C1A  c1        pop bc  ; BC zurueck
4C1B  d1        pop de  ; DE zurueck
4C1C  e1        pop hl  ; HL zurueck
4C1D  cc 00 00  call z,00000h  ; "wenn kein Error: SYS-File starten". Not patched.
                             ; The call target (4C1Eh/4C1Fh) is self-modified at
                             ; 4C09h ("ld (l4c1eh),hl") with the SYS-file's own
                             ; start address, so it reads 00 00 in the file on
                             ; disk.
4C20  e5        push hl
4C21  21 69 43  ld hl,04369h
4C24  cb b6     res 6,(hl)
4C26  e1        pop hl
4C27  c9        ret

; 4C28h-4ECCh
4C28  22 6a 4c  ld (04c6ah),hl
4C2B  11 ff 42  ld de,042ffh
; Laden von Programm-Files
4C2E  cd 65 4c  call sub_4c65h  ; naechstes Byte lesen
4C31  fe 1f     cp 01fh  ; ist das 1. Byte groesser als 1EH ?
4C33  4f        ld c,a  ; C = 1. Byte
4C34  3e 22     ld a,022h  ; Fehlercode "LOAD FILE FORMAT ERROR"
4C36  d0        ret nc  ; wenn ja
4C37  cd 65 4c  call sub_4c65h  ; naechstes Byte lesen
4C3A  47        ld b,a  ; B = 2. Byte
4C3B  cd 65 4c  call sub_4c65h  ; naechstes Byte lesen
4C3E  6f        ld l,a  ; L = 3. Byte
4C3F  26 38     ld h,038h  ; HL = Buffer fuer Kommentare 3800-39FE
4C41  0d        dec c
4C42  28 09     jr z,l4c4dh
4C44  0d        dec c
4C45  20 1a     jr nz,l4c61h
4C47  cd 65 4c  call sub_4c65h
4C4A  67        ld h,a
4C4B  af        xor a
4C4C  c9        ret
4C4D  cd 65 4c  call sub_4c65h
4C50  67        ld h,a
4C51  05        dec b
4C52  05        dec b
4C53  cd 65 4c  call sub_4c65h
4C56  0c        inc c
4C57  0d        dec c
4C58  20 07     jr nz,l4c61h
4C5A  77        ld (hl),a
4C5B  be        cp (hl)
4C5C  23        inc hl
4C5D  3e 24     ld a,024h
4C5F  20 62     jr nz,l4cc3h
4C61  10 f0     djnz l4c53h
4C63  18 c9     jr l4c2eh
4C65  1c        inc e
4C66  1a        ld a,(de)
4C67  c0        ret nz
4C68  d5        push de
4C69  11 00 00  ld de,00000h
4C6C  cd 36 44  call sub_4436h
4C6F  d1        pop de
4C70  20 29     jr nz,l4c9bh
4C72  1a        ld a,(de)
4C73  c9        ret
4C74  32 30 49  ld (sub_492fh+1),a
4C77  1e 00     ld e,000h
4C79  2a 99 43  ld hl,(04399h)
4C7C  4f        ld c,a
4C7D  6e        ld l,(hl)
4C7E  3a 0f 43  ld a,(0430fh)
4C81  cd 92 4c  call sub_4c92h
4C84  47        ld b,a
4C85  57        ld d,a
4C86  19        add hl,de
4C87  3e 05     ld a,005h
4C89  cd 94 4c  call sub_4c94h
4C8C  09        add hl,bc
4C8D  eb        ex de,hl
4C8E  21 00 42  ld hl,04200h
4C91  c9        ret
4C92  26 00     ld h,000h
; ------------------------------------------------------------
; Name:       MULOV (bei Grosser MULTHL)
; Funktion:   Multipliziere HL * A
; Input:      HL: 1. Faktor (falsche Ergebnisse ab HL >
;             8080H!)
;             A:  2. Faktor
; Veraendert: F
; Output:     AHL (Ergebnis = 65536D * A + HL)
; ------------------------------------------------------------
4C94  c5        push bc
4C95  cd 9d 4c  call sub_4c9dh
4C98  7c        ld a,h
4C99  65        ld h,l
4C9A  69        ld l,c
4C9B  c1        pop bc
4C9C  c9        ret
4C9D  d5        push de
4C9E  eb        ex de,hl
4C9F  0e 80     ld c,080h
4CA1  21 00 00  ld hl,00000h
4CA4  0f        rrca
4CA5  30 01     jr nc,l4ca8h
4CA7  19        add hl,de
4CA8  cb 3c     srl h
4CAA  cb 1d     rr l
4CAC  cb 19     rr c
4CAE  30 f4     jr nc,l4ca4h
4CB0  d1        pop de
4CB1  c9        ret
4CB2  3e 05     ld a,005h
; ------------------------------------------------------------
; Name:       DIVA
; Funktion:   Dividiere HL / A
; Input:      HL: Dividend
;             A:  Divisor
; Veraendert: C=Divisor, B=00
; Output:     HL: Quotient = INT(HL/A)
;             AF: A = Rest, wenn Z=0
; ------------------------------------------------------------
4CB4  4f        ld c,a
4CB5  06 10     ld b,010h
4CB7  af        xor a
4CB8  29        add hl,hl
4CB9  17        rla
4CBA  38 03     jr c,l4cbfh
4CBC  b9        cp c
4CBD  38 02     jr c,l4cc1h
4CBF  91        sub c
4CC0  2c        inc l
4CC1  10 f5     djnz l4cb8h
4CC3  b7        or a
4CC4  c9        ret
4CC5  e5        push hl
4CC6  0a        ld a,(bc)
4CC7  b7        or a
4CC8  03        inc bc
4CC9  20 03     jr nz,l4cceh
4CCB  e3        ex (sp),hl
4CCC  e1        pop hl
4CCD  c9        ret
4CCE  be        cp (hl)
4CCF  23        inc hl
4CD0  28 f4     jr z,l4cc6h
4CD2  e1        pop hl
4CD3  18 14     jr l4ce9h
; ------------------------------------------------------------
; Name:       CHKCHR (bei Grosser NEXTC1)
; Funktion:   naechstes Zeichen von (HL) holen und in
;             Abhaengigkeit vom Inhalt Flags setzen
; Input:      HL: Zeiger auf Text (z.B. Input-Buffer)
; Veraendert: --
; Output:     HL, AF (siehe Text)
; ------------------------------------------------------------
4CD5  7e        ld a,(hl)
4CD6  fe 0d     cp 00dh
4CD8  c8        ret z
; ------------------------------------------------------------
; Name:       CHKSEP (bei Grosser NEXTC2)
; Funktion:   naechstes Zeichen von (HL) holen und in
;             Abhaengigkeit vom Inhalt Flags setzen
; Input:      HL: Zeiger auf Text (z.B. Input-Buffer)
; Veraendert: --
; Output:     HL, AF (siehe Text)
; ------------------------------------------------------------
4CD9  7e        ld a,(hl)
4CDA  fe 2c     cp 02ch
4CDC  23        inc hl
4CDD  28 0a     jr z,l4ce9h
4CDF  fe 20     cp 020h
4CE1  2b        dec hl
4CE2  37        scf
4CE3  20 05     jr nz,l4ceah
4CE5  23        inc hl
4CE6  be        cp (hl)
4CE7  28 fc     jr z,l4ce5h
4CE9  b7        or a
4CEA  3e 34     ld a,034h
4CEC  c9        ret
; ------------------------------------------------------------
; Name:       DELAY2
; Funktion:   ca. B * 3.75 ms warten
; Input:      B: Zeitfaktor
; Veraendert: DE, BC, AF
; Output:     --
; ------------------------------------------------------------
4CED  50        ld d,b
4CEE  1e 01     ld e,001h
; UP DELAY2
4CF0  42        ld b,d  ; B (Zeitfaktor) zurueck [ch.3, Seite 3-57]
; ------------------------------------------------------------
; [note]      4CF1h: ch.3 has CALL 0060h. ch.9.4.2 documents
;             CALL 374Bh for the Genie IIIs; this build has
;             ch.3's value, not that one.
; ------------------------------------------------------------
4CF1  cd 60 00  call 00060h  ; Verzoegerung B * 3.75 ms (1.774 MHz)
4CF4  1d        dec e  ; schon SYSTEM BJ mal ? [ch.3, Seite 3-57]
4CF5  20 f9     jr nz,l4cf0h  ; wenn nein [ch.3, Seite 3-57]
4CF7  c9        ret
4CF8  cb a6     res 4,(hl)
4CFA  c8        ret z
4CFB  cb e6     set 4,(hl)
4CFD  c9        ret
4CFE  a4        and h
4CFF  4b        ld c,e
; Initialisierung von SYS0/SYS [ch.3, Seite 3-57]
4D00  a5        and l  ; Stackpointer steht auf 41E0h; Kennung von NEWDOS/80 und GDOS
4D01  ed 56     im 1  ; Interrupts ueber RST 38H
; ------------------------------------------------------------
; [note]      4D03h: CALL 50A8h is not in Grosser -- ch.3 has
;             "LD HL,0FFFFh" here, the start of "Ende des RAM
;             ab FFFFH abwaerts suchen". This build calls a
;             GDOS-2.4-only routine first; see 50A8h. The RAM
;             search resumes at 4D06h either way.
; ------------------------------------------------------------
4D03  cd a8 50  call sub_50a8h
4D06  7e        ld a,(hl)
4D07  2f        cpl
4D08  77        ld (hl),a
4D09  be        cp (hl)
4D0A  2b        dec hl
4D0B  20 f9     jr nz,l4d06h
4D0D  2f        cpl
4D0E  23        inc hl
4D0F  77        ld (hl),a
4D10  22 a9 43  ld (043a9h),hl
4D13  22 49 40  ld (04049h),hl
4D16  21 ab 43  ld hl,043abh
4D19  3e a5     ld a,0a5h
4D1B  be        cp (hl)
4D1C  20 09     jr nz,l4d27h
4D1E  23        inc hl
4D1F  11 41 40  ld de,04041h
4D22  01 06 00  ld bc,00006h
4D25  ed b0     ldir
4D27  fd 21 80 43 ld iy,04380h
4D2B  ed 4b fe 42 ld bc,(042feh)
4D2F  fd 70 f8  ld (iy-008h),b
4D32  fd 71 f3  ld (iy-00dh),c
4D35  3a fd 42  ld a,(042fdh)
4D38  fd 77 f7  ld (iy-009h),a
4D3B  11 80 44  ld de,l4480h
4D3E  cd c4 50  call sub_50c4h
4D41  c2 d3 4d  jp nz,l4dd3h
4D44  3a ef 42  ld a,(042efh)
4D47  fe a5     cp 0a5h
4D49  c2 d1 4d  jp nz,l4dd1h
4D4C  21 f8 42  ld hl,042f8h
4D4F  11 5b 50  ld de,l505bh
4D52  01 08 00  ld bc,00008h
4D55  ed b0     ldir
4D57  2a f0 42  ld hl,(042f0h)
4D5A  22 6c 43  ld (0436ch),hl
4D5D  2a f2 42  ld hl,(042f2h)
4D60  22 6e 43  ld (0436eh),hl
; === The cold start's own drive-count distribution. One configuration byte,
; === 42A0h, goes to two places: 439Fh (dndrv, "Anzahl Drives" -- see
; === history/00-volker-dose-workdisk/SYS29.asm's m439f, and SYS29/SYS's own ceiling check at
; === 4F23h) and 477Ah (the CP nn operand inside DRVSEL at 4779h). Right for
; === stock GDOS, where every drive is a floppy and the two numbers are the
; === same; wrong for this port, which serves drives up to 9. PATCHED as one
; === 12-byte block by run-hdboottest.sh -- see that file for the reasoning.
; === Bytes below are THIS BUILD's; stock is shown per line.
; ------------------------------------------------------------
; [PATCH]     4D63h-4D6Eh
; Stock:      3A A0 42 32 9F 43 32 7A 47 3D FE 04
; This build: 3E 0A 32 9F 43 3A A0 42 32 7A 47 37
; Reason:     Stock takes one configuration byte, 42A0h, and
;             writes it to two places: 439Fh (the drive count)
;             and 477Ah (DRVSEL's own CP operand). Right where
;             every drive is a floppy and the two numbers
;             agree; wrong here. Split into two independent
;             values -- 0Ah, the drives gpar serves, into
;             439Fh, and the floppy count into 477Ah as
;             before. The dropped DEC A / CP 04h guarded a
;             configuration sector read off a floppy; this
;             boot supplies that sector from gcfg, where 42A0h
;             is a fixed 04h, so nothing is left to catch. SCF
;             stops 4D6Fh's JR NC from firing. 12 bytes for
;             12.
; ------------------------------------------------------------
4D63  3e 0a     ld a,00ah
4D65  32 9f 43  ld (0439fh),a
4D68  3a a0 42  ld a,(042a0h)
4D6B  32 7a 47  ld (0477ah),a
4D6E  37        scf
4D6F  30 60     jr nc,l4dd1h
4D71  3a a1 42  ld a,(042a1h)
4D74  32 ba 4a  ld (04abah),a
4D77  3a a2 42  ld a,(042a2h)
4D7A  32 a0 43  ld (043a0h),a
4D7D  3a a3 42  ld a,(042a3h)
4D80  32 a1 43  ld (043a1h),a
4D83  3a a6 42  ld a,(042a6h)
4D86  32 5a 46  ld (0465ah),a
4D89  cd e0 50  call sub_50e0h
4D8C  32 a2 43  ld (043a2h),a
4D8F  32 ef 4c  ld (04cefh),a
4D92  2e 06     ld l,006h
4D94  11 00 24  ld de,02400h
4D97  f5        push af
4D98  cd 92 4c  call sub_4c92h
4D9B  b4        or h
4D9C  20 33     jr nz,l4dd1h
4D9E  7d        ld a,l
4D9F  32 e4 47  ld (sub_47e3h+1),a
4DA2  f1        pop af
4DA3  eb        ex de,hl
4DA4  cd 94 4c  call sub_4c94h
4DA7  b7        or a
4DA8  20 27     jr nz,l4dd1h
4DAA  22 f4 47  ld (047f4h),hl
4DAD  3a a8 42  ld a,(042a8h)
4DB0  32 70 43  ld (04370h),a
4DB3  2a 49 40  ld hl,(04049h)
4DB6  ed 5b d0 42 ld de,(042d0h)
4DBA  7a        ld a,d
4DBB  b3        or e
4DBC  28 06     jr z,l4dc4h
4DBE  b7        or a
4DBF  ed 52     sbc hl,de
4DC1  38 01     jr c,l4dc4h
4DC3  eb        ex de,hl
4DC4  22 49 40  ld (04049h),hl
4DC7  af        xor a
4DC8  11 71 43  ld de,04371h
4DCB  dd 21 00 42 ld ix,04200h
4DCF  18 06     jr l4dd7h
4DD1  3e 27     ld a,027h
4DD3  f5        push af
4DD4  3e 46     ld a,046h
4DD6  ef        rst 28h
4DD7  01 0a 00  ld bc,0000ah
4DDA  f5        push af
4DDB  fe 04     cp 004h
4DDD  00        nop
4DDE  30 05     jr nc,l4de5h
4DE0  dd e5     push ix
4DE2  e1        pop hl
4DE3  ed b0     ldir
4DE5  dd 7e 02  ld a,(ix+002h)
4DE8  e6 1c     and 01ch
4DEA  28 e5     jr z,l4dd1h
4DEC  0e 10     ld c,010h
4DEE  dd 09     add ix,bc
4DF0  f1        pop af
4DF1  3c        inc a
4DF2  fe 0a     cp 00ah
4DF4  38 e1     jr c,l4dd7h
4DF6  3a fa 42  ld a,(042fah)
4DF9  cb 7f     bit 7,a
4DFB  28 05     jr z,l4e02h
4DFD  3e ab     ld a,0abh
4DFF  32 3d 46  ld (sub_463ch+1),a
4E02  ed 4b f8 42 ld bc,(042f8h)
4E06  ed 5b 6c 43 ld de,(0436ch)
4E0A  cb 73     bit 6,e
4E0C  28 08     jr z,l4e16h
4E0E  fd cb e9 d6 set 2,(iy-017h)
4E12  fd cb ed b6 res 6,(iy-013h)
4E16  cb 41     bit 0,c
4E18  28 0e     jr z,l4e28h
4E1A  3e 28     ld a,028h
4E1C  32 4c 45  ld (l454ch),a
4E1F  3a a7 42  ld a,(042a7h)
4E22  32 80 45  ld (04580h),a
4E25  00        nop
4E26  00        nop
4E27  00        nop
4E28  3a a5 42  ld a,(042a5h)
4E2B  b7        or a
4E2C  28 03     jr z,l4e31h
4E2E  32 01 45  ld (04501h),a
4E31  cb 49     bit 1,c
4E33  28 13     jr z,l4e48h
4E35  3a 40 38  ld a,(03840h)
4E38  cb 5f     bit 3,a
4E3A  20 0c     jr nz,l4e48h
4E3C  21 16 45  ld hl,l4516h
4E3F  22 16 40  ld (04016h),hl
4E42  21 05 45  ld hl,l4505h
4E45  22 1e 40  ld (0401eh),hl
4E48  21 ff 3f  ld hl,03fffh
4E4B  3e 61     ld a,061h
4E4D  77        ld (hl),a
4E4E  be        cp (hl)
4E4F  36 20     ld (hl),020h
4E51  20 17     jr nz,l4e6ah
4E53  cb 50     bit 2,b
4E55  28 0a     jr z,l4e61h
4E57  3e 4f     ld a,04fh
4E59  32 93 45  ld (l4593h),a
4E5C  3e 38     ld a,038h
4E5E  32 05 45  ld (l4505h),a
4E61  cb 48     bit 1,b
4E63  20 05     jr nz,l4e6ah
4E65  3e 00     ld a,000h
4E67  32 b4 45  ld (l45b4h),a
4E6A  cb 40     bit 0,b
4E6C  28 05     jr z,l4e73h
4E6E  3e c8     ld a,0c8h
4E70  32 02 45  ld (l4502h),a
4E73  cb 79     bit 7,c
4E75  20 05     jr nz,l4e7ch
4E77  00        nop
4E78  00        nop
4E79  00        nop
4E7A  00        nop
4E7B  00        nop
4E7C  cb 71     bit 6,c
4E7E  28 05     jr z,l4e85h
4E80  3e c0     ld a,0c0h
4E82  32 ee 45  ld (l45eeh),a
4E85  cb 61     bit 4,c
4E87  28 05     jr z,l4e8eh
4E89  3e 20     ld a,020h
4E8B  32 cc 45  ld (l45cch),a
4E8E  cb 51     bit 2,c
4E90  28 04     jr z,l4e96h
4E92  af        xor a
4E93  32 90 45  ld (04590h),a
4E96  cb 69     bit 5,c
4E98  28 05     jr z,l4e9fh
4E9A  3e 20     ld a,020h
4E9C  32 d8 45  ld (l45d8h),a
4E9F  cb 6b     bit 5,e
4EA1  28 04     jr z,l4ea7h
4EA3  fd cb e9 e6 set 4,(iy-017h)
4EA7  21 a8 4f  ld hl,l4fa8h  ; Zeiger auf Tabelle "CLS"
4EAA  cd f0 50  call sub_50f0h  ; Bildschirm loeschen
4EAD  3a f9 42  ld a,(042f9h)  ; SYSTEM AG=Y ? (BREAK-Taste erlaubt), wenn nein
4EB0  cb 6f     bit 5,a
4EB2  28 18     jr z,l4ecch
4EB4  f3        di  ; Interrupts sperren; Zeiger auf 1. RCB; nach 4ADC eintragen
4EB5  21 b2 43  ld hl,043b2h
4EB8  22 dc 4a  ld (04adch),hl
4EBB  11 1d 40  ld de,0401dh  ; DCB der Bildschirm-Routine; in RCB+0 und RCB+1 eintragen
4EBE  73        ld (hl),e
4EBF  23        inc hl
4EC0  72        ld (hl),d
4EC1  23        inc hl
4EC2  1a        ld a,(de)
4EC3  77        ld (hl),a
4EC4  23        inc hl
4EC5  3e c0     ld a,0c0h
4EC7  12        ld (de),a
4EC8  af        xor a
4EC9  77        ld (hl),a
4ECA  23        inc hl
4ECB  77        ld (hl),a
4ECC  fb        ei  ; Interrupts erlauben

; 4ECDh-50A7h
; ------------------------------------------------------------
; [note]      4ECDh: prints the banner string. ch.9.4.2
;             documents a CRT-controller-init insert here
;             instead, which moves the banner print to 4EDBh;
;             this build has neither the insert nor the move.
; ------------------------------------------------------------
4ECD  21 ab 4f  ld hl,l4fabh
4ED0  cd 67 44  call sub_4467h  ; auf Bildschirm ausgeben
; Datum und Uhrzeit abfragen und anzeigen
4ED3  3a ab 43  ld a,(043abh)  ; pruefen, ob NEWDOS/80 oder GDOS
4ED6  fe a5     cp 0a5h  ; schon vor dem RESET aktiv war,
4ED8  3a f9 42  ld a,(042f9h)  ; SYSTEM AY und SYSTEM AZ
4EDB  20 02     jr nz,l4edfh  ; (Datum und Uhrzeit eingeben)
4EDD  cb bf     res 7,a  ; pruefen
4EDF  e6 c0     and 0c0h  ; und
4EE1  c4 3d 4f  call nz,sub_4f3dh  ; ggf. INPUT Datum und Uhrzeit
4EE4  21 89 50  ld hl,l5089h  ; Zeiger auf Buffer fuer Datum + Uhrzeit; Datum im MM/DD/YY-Format
4EE7  e5        push hl
4EE8  cd c2 44  call l44c2h  ; nach 5089-5090 uebertragen
4EEB  21 93 50  ld hl,l5093h  ; Uhrzeit im HH:MM:SS-Format
4EEE  cd a7 44  call l44a7h  ; nach 5093-509A uebertragen
4EF1  e1        pop hl
4EF2  cd 67 44  call sub_4467h  ; Datum und Uhrzeit auf Bildschirm ausgeben
4EF5  af        xor a  ; GAT-Sector von Drive 0 lesen wegen evtl. AUTO-Befehl; Nummer der DIR-Sectors (GAT=0)
4EF6  32 30 49  ld (sub_492fh+1),a
; ------------------------------------------------------------
; [PATCH]     4EF9h-4EFAh
; Stock:      21 05   LD HL,4F05h (first 2 bytes of a 3-byte load)
; This build: 18 0D   JR 4F08h
; Reason:     SYS0's cold start re-reads the GAT sector a second
;             time to pick up a possible AUTO command. It reads
;             whatever drive is current, which at cold start on
;             this port is sysvol -- but this call path goes out
;             through 4642h to this driver's own hook, not a
;             floppy read, and the driver has already placed
;             that same sector at 4200h during ginit. The 3rd
;             byte of the old LD HL (4Fh, now at 4EFBh) is
;             orphaned, not overwritten -- nothing branches into
;             4EFBh-4F07h any more, so it and the
;             PUSH/PUSH/PUSH/LD HL/JP/JP NZ that follow it are
;             dead.
; ------------------------------------------------------------
4EF9  18 0d     jr l4f08h
4EFB  4f        ld c,a
4EFC  e5        push hl
4EFD  d5        push de
4EFE  c5        push bc
4EFF  21 00 42  ld hl,04200h  ; Buffer = 4200
4F02  c3 11 49  jp l4911h  ; GAT-Sector nach 4200 lesen
4F05  c2 d3 4d  jp nz,l4dd3h  ; wenn Error
4F08  11 18 43  ld de,04318h  ; Zeiger auf Input-Buffer des DOS
4F0B  d5        push de
4F0C  c5        push bc
; ------------------------------------------------------------
; [PATCH]     4F0Dh-4F14h
; Stock:      21 E0 42 01 20 00 ED B0   LD HL,42E0h / LD BC,0020h / LDIR --
;             copy 32 bytes out of the GAT sector
;             into the DOS input buffer
; This build: 3E 0D 12 00 00 00 00 00   LD A,0Dh / LD (DE),A / NOP x5 -- DE
;             is already 4318h from 4F08h
; Reason:     4200h is the DOS's shared sector buffer, reused by
;             every disk read between boot and here -- skipping
;             only the GAT re-read (see 4EF9h above) would copy
;             whatever sector was read last into the command
;             buffer and run it as an AUTO command. This port
;             has no AUTO command by design, so it says so
;             directly: a bare CR. Same 8-byte footprint as the
;             LDIR it replaces.
; ------------------------------------------------------------
4F0D  3e 0d     ld a,00dh
4F0F  12        ld (de),a
4F10  00        nop
4F11  00        nop
4F12  00        nop
4F13  00        nop
4F14  00        nop
4F15  21 ab 43  ld hl,043abh  ; vermerken, dass NEWDOS/80 bzw. GDOS initialisiert ist
4F18  36 a5     ld (hl),0a5h
4F1A  c1        pop bc
4F1B  e1        pop hl
4F1C  af        xor a
4F1D  fd cb ec 76 bit 6,(iy-014h)  ; SYSTEM AB=Y ? (RUN-ONLY Modus)
4F21  20 14     jr nz,l4f37h
4F23  3a 5c 50  ld a,(l505ch)
4F26  cb 5f     bit 3,a
4F28  28 0d     jr z,l4f37h
4F2A  3a 40 38  ld a,(03840h)
4F2D  0f        rrca
4F2E  da 00 44  jp c,l4400h
4F31  7e        ld a,(hl)
4F32  fe 0d     cp 00dh
4F34  ca 00 44  jp z,l4400h
4F37  cd 67 44  call sub_4467h
4F3A  c3 05 44  jp l4405h
4F3D  21 63 50  ld hl,l5063h
4F40  cd 64 4f  call sub_4f64h
4F43  01 9c 50  ld bc,l509ch
4F46  11 46 40  ld de,04046h
4F49  3e 2e     ld a,02eh
4F4B  cd 6f 4f  call sub_4f6fh
4F4E  20 ed     jr nz,sub_4f3dh
4F50  21 76 50  ld hl,l5076h
4F53  cd 64 4f  call sub_4f64h
4F56  01 a2 50  ld bc,l50a2h
4F59  11 43 40  ld de,04043h
4F5C  3e 3a     ld a,03ah
4F5E  cd 6f 4f  call sub_4f6fh
4F61  20 ed     jr nz,l4f50h
4F63  c9        ret
4F64  cd 67 44  call sub_4467h
4F67  21 18 43  ld hl,04318h
4F6A  06 09     ld b,009h
4F6C  c3 40 00  jp 00040h
4F6F  32 a0 4f  ld (04fa0h),a
4F72  f3        di
4F73  c5        push bc
4F74  06 03     ld b,003h
4F76  7e        ld a,(hl)
4F77  d6 30     sub 030h
4F79  fe 0a     cp 00ah
4F7B  23        inc hl
4F7C  30 26     jr nc,l4fa4h
4F7E  4f        ld c,a
4F7F  07        rlca
4F80  07        rlca
4F81  81        add a,c
4F82  87        add a,a
4F83  4f        ld c,a
4F84  7e        ld a,(hl)
4F85  d6 30     sub 030h
4F87  fe 0a     cp 00ah
4F89  23        inc hl
4F8A  30 18     jr nc,l4fa4h
4F8C  81        add a,c
4F8D  12        ld (de),a
4F8E  1b        dec de
4F8F  e3        ex (sp),hl
4F90  96        sub (hl)
4F91  23        inc hl
4F92  be        cp (hl)
4F93  23        inc hl
4F94  30 0e     jr nc,l4fa4h
4F96  e3        ex (sp),hl
4F97  10 05     djnz l4f9eh
4F99  c1        pop bc
4F9A  fb        ei
4F9B  c3 d5 4c  jp l4cd5h
4F9E  7e        ld a,(hl)
4F9F  fe 00     cp 000h
4FA1  23        inc hl
4FA2  28 d2     jr z,l4f76h
4FA4  fb        ei
4FA5  f1        pop af
4FA6  b7        or a
4FA7  c9        ret
4FA8  1c        inc e
4FA9  00        nop
4FAA  03        inc bc
4FAB  be        cp (hl)
4FAC  83        add a,e
4FAD  83        add a,e
4FAE  8d        adc a,l
4FAF  80        add a,b
4FB0  bf        cp a
4FB1  83        add a,e
4FB2  83        add a,e
4FB3  83        add a,e
4FB4  80        add a,b
4FB5  bf        cp a
4FB6  ad        xor l
4FB7  90        sub b
4FB8  bf        cp a
4FB9  80        add a,b
4FBA  83        add a,e
4FBB  bf        cp a
4FBC  83        add a,e
4FBD  80        add a,b
4FBE  bf        cp a
4FBF  83        add a,e
4FC0  83        add a,e
4FC1  83        add a,e
4FC2  c5        push bc
4FC3  82        add a,d
4FC4  bf        cp a
4FC5  83        add a,e
4FC6  83        add a,e
4FC7  bd        cp l
4FC8  80        add a,b
4FC9  be        cp (hl)
4FCA  83        add a,e
4FCB  83        add a,e
4FCC  bd        cp l
4FCD  80        add a,b
4FCE  be        cp (hl)
4FCF  83        add a,e
4FD0  83        add a,e
4FD1  8d        adc a,l
4FD2  c6 56     add a,056h
4FD4  45        ld b,l
4FD5  52        ld d,d
4FD6  53        ld d,e
4FD7  49        ld c,c
4FD8  4f        ld c,a
4FD9  4e        ld c,(hl)
4FDA  20 32     jr nz,l500eh
4FDC  2e 34     ld l,034h
4FDE  20 1e     jr nz,l4ffeh
4FE0  0a        ld a,(bc)
4FE1  bf        cp a
4FE2  80        add a,b
4FE3  82        add a,d
4FE4  bf        cp a
4FE5  80        add a,b
4FE6  bf        cp a
4FE7  83        add a,e
4FE8  81        add a,c
4FE9  c2 bf 80  jp nz,080bfh
4FEC  8b        adc a,e
4FED  bf        cp a
4FEE  c2 bf c2  jp nz,0c2bfh
4FF1  bf        cp a
4FF2  83        add a,e
4FF3  81        add a,c
4FF4  c2 83 83  jp nz,08383h
4FF7  83        add a,e
4FF8  c2 bf c2  jp nz,0c2bfh
4FFB  bf        cp a
4FFC  80        add a,b
4FFD  bf        cp a
4FFE  c2 bf 80  jp nz,080bfh
5001  b2        or d
5002  83        add a,e
5003  83        add a,e
5004  bd        cp l
5005  c3 28 43  jp 04328h
5008  29        add hl,hl
5009  20 31     jr nz,l503ch
500B  39        add hl,sp
500C  38 34     jr c,l5042h
500E  20 54     jr nz,l5064h
5010  43        ld b,e
5011  53        ld d,e
5012  2f        cpl
5013  4d        ld c,l
5014  56        ld d,(hl)
5015  43        ld b,e
5016  20 0a     jr nz,l5022h
5018  82        add a,d
5019  83        add a,e
501A  83        add a,e
501B  81        add a,c
501C  80        add a,b
501D  83        add a,e
501E  83        add a,e
501F  83        add a,e
5020  83        add a,e
5021  80        add a,b
5022  83        add a,e
5023  c2 83 80  jp nz,08083h
5026  83        add a,e
5027  83        add a,e
5028  83        add a,e
5029  80        add a,b
502A  83        add a,e
502B  83        add a,e
502C  83        add a,e
502D  83        add a,e
502E  c5        push bc
502F  82        add a,d
5030  83        add a,e
5031  83        add a,e
5032  83        add a,e
5033  81        add a,c
5034  80        add a,b
5035  82        add a,d
5036  83        add a,e
5037  83        add a,e
5038  81        add a,c
5039  80        add a,b
503A  82        add a,d
503B  83        add a,e
503C  83        add a,e
503D  81        add a,c
503E  c6 47     add a,047h
5040  65        ld h,l
5041  6e        ld l,(hl)
5042  69        ld l,c
5043  65        ld h,l
5044  20 49     jr nz,$+75
5046  2f        cpl
5047  49        ld c,c
5048  49        ld c,c
5049  20 20     jr nz,l506bh
504B  1f        rra
504C  0d        dec c
504D  0d        dec c
504E  66        ld h,(hl)
504F  66        ld h,(hl)
5050  66        ld h,(hl)
5051  66        ld h,(hl)
5052  66        ld h,(hl)
5053  66        ld h,(hl)
5054  66        ld h,(hl)
5055  66        ld h,(hl)
5056  66        ld h,(hl)
5057  66        ld h,(hl)
5058  66        ld h,(hl)
5059  66        ld h,(hl)
505A  66        ld h,(hl)
505B  00        nop
505C  00        nop
505D  00        nop
505E  00        nop
505F  00        nop
5060  00        nop
5061  00        nop
5062  00        nop
5063  44        ld b,h
5064  61        ld h,c
5065  74        ld (hl),h
5066  75        ld (hl),l
5067  6d        ld l,l
5068  3f        ccf
5069  20 28     jr nz,l5093h
506B  54        ld d,h
506C  54        ld d,h
506D  2e 4d     ld l,04dh
506F  4d        ld c,l
5070  2e 4a     ld l,04ah
5072  4a        ld c,d
5073  29        add hl,hl
5074  20 03     jr nz,l5079h
5076  5a        ld e,d
5077  65        ld h,l
5078  69        ld l,c
5079  74        ld (hl),h
507A  3f        ccf
507B  20 20     jr nz,$+34
507D  28 48     jr z,l50c7h
507F  48        ld c,b
5080  3a 4d 4d  ld a,(04d4dh)
5083  3a 53 53  ld a,(05353h)
5086  29        add hl,hl
5087  20 03     jr nz,$+5
5089  54        ld d,h
508A  54        ld d,h
508B  2e 4d     ld l,04dh
508D  4d        ld c,l
508E  2e 4a     ld l,04ah
5090  4a        ld c,d
5091  20 20     jr nz,$+34
5093  48        ld c,b
5094  48        ld c,b
5095  3a 4d 4d  ld a,(04d4dh)
5098  3a 53 53  ld a,(05353h)
509B  0d        dec c
509C  01 1f 01  ld bc,0011fh
509F  0c        inc c
50A0  00        nop
50A1  64        ld h,h
50A2  00        nop
50A3  18 00     jr l50a5h
50A5  3c        inc a
50A6  00        nop
50A7  3c        inc a

; 50A8h-5183h -- GDOS 2.4 own routine, not in Grosser (his book covers GDOS 2.1c). Entered via the CALL at 4D03h, before ch.3's own RAM-search resumes at 4D06h.
; ------------------------------------------------------------
; [note]      50A8h: selects one of two BC constants on bit 3
;             of (4266h).
; ------------------------------------------------------------
50A8  3a 66 42  ld a,(04266h)
50AB  01 9e de  ld bc,0de9eh
50AE  cb 5f     bit 3,a
50B0  20 03     jr nz,l50b5h
50B2  01 a6 e6  ld bc,0e6a6h
; ------------------------------------------------------------
; [note]      50B5h: B and C go to (4CFCh)/(46A4h) and
;             (4CF9h): self-modifies DELAY2's own operand and
;             the doubled-disk NOP slot at 46A4h.
; ------------------------------------------------------------
50B5  78        ld a,b
50B6  32 fc 4c  ld (04cfch),a
50B9  32 a4 46  ld (046a4h),a
50BC  79        ld a,c
50BD  32 f9 4c  ld (04cf9h),a
; ------------------------------------------------------------
; [note]      50C0h: returns HL=0FFFFh.
; ------------------------------------------------------------
50C0  21 ff ff  ld hl,0ffffh
50C3  c9        ret
; ------------------------------------------------------------
; [PATCH]     50C4h
; Stock:      CD 36 44   CALL 4436h
; This build: AF 00 00   XOR A / NOP / NOP
; Reason:     SYS0's init reads a configuration sector from
;             drive 0 through the floppy path, four
;             instructions before the driver that could serve
;             it is initialised. The driver plants the same
;             sector at 4200h instead, so the read is
;             redundant and always reports success.
; ------------------------------------------------------------
50C4  af        xor a
50C5  00        nop
50C6  00        nop
50C7  c2 d3 4d  jp nz,l4dd3h
; ------------------------------------------------------------
; [note]      50CAh: if (4307h)=004h: CALL 3209h, the OVL4/SYS
;             bank-switch out. See 3200h.
; ------------------------------------------------------------
50CA  3a 3e 3c  ld a,(03c3eh)
50CD  e6 0f     and 00fh
50CF  32 07 43  ld (04307h),a
50D2  fe 04     cp 004h
50D4  cc 09 32  call z,03209h
; ------------------------------------------------------------
; [note]      50D7h: HL=3300h, DE=3, then JP 4630h.
; ------------------------------------------------------------
50D7  21 00 33  ld hl,03300h
50DA  11 03 00  ld de,00003h
50DD  c3 30 46  jp sub_4630h
; ------------------------------------------------------------
; [note]      50E0h: re-reads (4307h), the /SYS-module byte --
;             see 4315h -- and branches on it.
; ------------------------------------------------------------
50E0  3a 07 43  ld a,(04307h)
50E3  fe 05     cp 005h
50E5  20 01     jr nz,l50e8h
50E7  3d        dec a
50E8  4f        ld c,a
50E9  3a a9 42  ld a,(042a9h)
50EC  b9        cp c
50ED  d0        ret nc
50EE  79        ld a,c
50EF  c9        ret
50F0  3a 07 43  ld a,(04307h)
50F3  fe 01     cp 001h
50F5  28 0c     jr z,l5103h
50F7  3a 40 38  ld a,(03840h)
50FA  cb 6f     bit 5,a
50FC  28 08     jr z,l5106h
50FE  3e 01     ld a,001h
5100  32 07 43  ld (04307h),a
5103  c3 67 44  jp sub_4467h
; ------------------------------------------------------------
; [note]      5106h: copies 200h bytes from 4EADh to 3000h,
;             then JP 3214h: the overlay-open bank-switch. See
;             3200h.
; ------------------------------------------------------------
5106  3a f9 42  ld a,(042f9h)
5109  f5        push af
510A  e5        push hl
510B  21 ad 4e  ld hl,l4eadh
510E  11 00 30  ld de,03000h
5111  01 00 02  ld bc,00200h
5114  ed b0     ldir
5116  c3 14 32  jp 03214h
5119  00        nop
511A  00        nop
511B  00        nop
511C  00        nop
511D  00        nop
511E  00        nop
511F  00        nop
5120  00        nop
5121  00        nop
5122  00        nop
5123  00        nop
5124  00        nop
5125  00        nop
5126  00        nop
5127  00        nop
5128  00        nop
5129  00        nop
512A  00        nop
512B  00        nop
512C  00        nop
512D  00        nop
512E  00        nop
512F  00        nop
5130  00        nop
5131  00        nop
5132  00        nop
5133  00        nop
5134  00        nop
5135  00        nop
5136  00        nop
5137  00        nop
5138  00        nop
5139  00        nop
513A  00        nop
513B  00        nop
513C  00        nop
513D  00        nop
513E  00        nop
513F  00        nop
5140  00        nop
5141  00        nop
5142  00        nop
5143  00        nop
5144  00        nop
5145  00        nop
5146  00        nop
5147  00        nop
5148  00        nop
5149  00        nop
514A  00        nop
514B  00        nop
514C  00        nop
514D  00        nop
514E  00        nop
514F  00        nop
5150  00        nop
5151  00        nop
5152  00        nop
5153  00        nop
5154  00        nop
5155  00        nop
5156  00        nop
5157  00        nop
5158  00        nop
5159  00        nop
515A  00        nop
515B  00        nop
515C  00        nop
515D  00        nop
515E  00        nop
515F  00        nop
5160  00        nop
5161  00        nop
5162  00        nop
5163  00        nop
5164  00        nop
5165  00        nop
5166  00        nop
5167  00        nop
5168  00        nop
5169  00        nop
516A  00        nop
516B  00        nop
516C  00        nop
516D  00        nop
516E  00        nop
516F  00        nop
5170  00        nop
5171  00        nop
5172  00        nop
5173  00        nop
5174  00        nop
5175  00        nop
5176  00        nop
5177  00        nop
5178  00        nop
5179  00        nop
517A  00        nop
517B  00        nop
517C  00        nop
517D  00        nop
517E  00        nop
517F  00        nop
5180  00        nop
5181  00        nop
5182  00        nop
5183  00        nop
