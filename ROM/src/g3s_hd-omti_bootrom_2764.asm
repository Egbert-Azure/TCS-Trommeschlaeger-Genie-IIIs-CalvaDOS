;----------------------------------------------------------------------
; Genie IIIs OMTI Boot ROM (1986)
; (c) Arnulf Sopp  
; Annotated disassembly of the OMTI hard-disk boot EPROM.
;
; Source:
;   ROM/g3s_hd-omti_bootrom_2764.bin
;   Size: 8192 bytes
;   Address range: 0000h-1FFFh
;
; Generated with:
;   z80dasm --org 0 --start 0
;
; Notes
; -----
; • Addresses, instruction bytes, and mnemonics are unchanged.
; • Labels have been renamed for readability only.
; • Comments describe observed behavior and inferred function.
; • Inferred behavior is identified explicitly where applicable.
;
; Routine index
; -------------
; 0000h  coldstart           Power-on entry
; 0004h  waitf9idle          Wait for F9h ready
; 0031h  banner_and_reloc2   Display banner and relocate dispatch code
; 0042h  hkcompare           Hotkey dispatch
; 0056h  floppyforce         Force floppy boot
; 0057h  relocfloppy         Relocate floppy path
; 0068h  devdispatch         Device dispatch
; 0079h  ixselect            Select boot target
; 008Eh  devinit             Device initialization
; 00CFh  fdcinit_partial     Floppy initialization (partial analysis)
; 0185h  bannerclr           Clear screen and display banner
; 1100h  omtidetect          OMTI controller probe and boot
;----------------------------------------------------------------------

0000  F3          coldstart    DI
0001  31 00 3C             LD	SP,3c00h
; waitf9idle -- poll port F9h (the Genie III banker/mode-select port,
; same port used for F0xx bank switching; see gdos-omti.asm's dbank)
; until it reads back 20h. Then arms the bank/mode registers D6h/D7h:
; 0Fh to both, then 0 to both.
0004  3E 20       waitf9idle    LD	A,20h
0006  D3 F9                OUT	(0f9h),A
0008  DB F9                IN	A,(0f9h)
000A  FE 20                CP	20h
000C  20 F6                JR	NZ,waitf9idle
000E  3E 0F                LD	A,0fh
0010  D3 D6                OUT	(0d6h),A
0012  D3 D7                OUT	(0d7h),A
0014  AF                   XOR	A
0015  D3 D6                OUT	(0d6h),A
0017  D3 D7                OUT	(0d7h),A
; Read ONE byte of the keyboard matrix (38A0h, one specific row) and
; latch it at FFFFh for the rest of the boot -- the hotkey mechanism.
; Referenced by hkcompare (0042h) and hkforcefloppy (0070h).
; F1 may enter the Monitor; F2 is likely the 'force floppy' key.
0019  3A A0 38             LD	A,(38a0h)
001C  32 FF FF             LD	(0ffffh),A
; Bank-select 10h, then relocate ROM[019Eh..058Ch] (0x3EF bytes) to
; RAM 3800h and jump there. This first relocated copy is NOT the
; device-dispatch code (that is the second copy, from 0031h/0068h) --
; not independently disassembled at its RAM location this pass; it
; jumps back into ROM at banner_and_reloc2 (0031h) when done.
001F  3E 10                LD	A,10h
0021  D3 FA                OUT	(0fah),A
0023  21 9E 01             LD	HL,019eh
0026  11 00 38             LD	DE,3800h
0029  01 EF 03             LD	BC,03efh
002C  ED B0                LDIR
002E  C3 00 38             JP	3800h
; =====================================================================
; banner_and_reloc2 -- draws the boot banner (CALL bannerclr, 0185h),
; then relocates ROM[0068h..014Eh] (0xE7 bytes) to RAM 3800h a SECOND
; time, overwriting the first copy -- this is the device-dispatch body
; (devdispatch/ixselect/devinit and their floppy-controller-init
; continuation at fdcinit_partial). Falls into omtidetect (1100h),
; the OMTI hard-disk probe, which is where this file's own analysis
; concentrates.
; =====================================================================
0031  CD 85 01    banner_and_reloc2    CALL	bannerclr
0034  21 68 00             LD	HL,devdispatch
0037  11 00 38             LD	DE,3800h
003A  01 E7 00             LD	BC,00e7h
003D  ED B0                LDIR
003F  C3 00 11             JP	omtidetect
; =====================================================================
; hkcompare -- a SECOND, independent test of the same hotkey byte
; latched at 001Fh. CP B2h: on a match, this is the actual device
; dispatch -- bank out (OUT F9h,0), set mode E4h, JP (IX) to whatever
; omtidetect/ixselect left in IX (4200h on OMTI success, FC00h or
; 0000h for the base loader's other disk types, see ixselect below).
; B2h matches the base loader's 'foreign-standard-disk-format'
; compatibility signature (checked at 2FFFh there, not FFFFh).
; It is unclear whether the ROM reuses this value for the same
; compatibility check or for another purpose.
; =====================================================================
0042  3A FF FF    hkcompare    LD	A,(0ffffh)
0045  FE B2                CP	0b2h
0047  20 09                JR	NZ,hknomatch
; Device dispatch: JP (IX) hands off to the selected device's boot sector.
; Expected conditions for this dispatch path:
;   port F9h = 00h (bank 0)
;   port FAh = E4h (system/mode register)
;   SP = 3C00h
;   interrupts disabled
; For OMTI, the device boot sector address is 4200h (m4200 in SYS1.asm).
0049  AF                   XOR	A
004A  D3 F9                OUT	(0f9h),A
004C  3E E4                LD	A,0e4h
004E  D3 FA                OUT	(0fah),A
0050  DD E9                JP	(IX)
0052  3E 55       hknomatch    LD	A,55h
0054  18 01                JR	relocfloppy
; floppyforce -- the explicit 'abandon hard-disk boot, force floppy'
; landing. Reached from hkforcefloppy (00C8h, hotkey override) and
; from omtiretry's own give-up path (1105h/1130h, JP 3800h lands back
; here via the relocated copy). XOR A clears the hotkey latch, then
; falls into relocfloppy.
0056  AF          floppyforce    XOR	A
; relocfloppy -- relocate ROM[064Dh..] (0x871 bytes) to RAM F700h and
; jump there: the floppy boot path's own body. Not analysed here.
0057  32 FF FF    relocfloppy    LD	(0ffffh),A
005A  21 4D 06             LD	HL,064dh
005D  11 00 F7             LD	DE,0f700h
0060  01 71 08             LD	BC,0871h
0063  ED B0                LDIR
0065  C3 00 F7             JP	0f700h
; =====================================================================
; devdispatch -- entry into the (twice-relocated) device-dispatch
; body, reached via JP 382Eh-equivalent RAM jumps from omtidetect's
; success path (113Dh/1141h) and from other device-selection paths.
; Sets mode D4h, clears a flag at 3894h, then tests the hotkey byte's
; bit 0 (RRCA / JR C) which implements the floppy-override hotkey.
; =====================================================================
0068  3E D4       devdispatch    LD	A,0d4h
006A  D3 FA                OUT	(0fah),A
006C  AF                   XOR	A
006D  32 94 38             LD	(3894h),A
0070  3A FF FF             LD	A,(0ffffh)
0073  0F                   RRCA
0074  38 52                JR	C,hkforcefloppy
0076  CD 67 38             CALL	3867h
; 'LD IX,0000h' loads the literal 0000h; not a control-flow reference.
; ixselect -- disk-type dispatch. E selects boot device:
;   E=1 -> IX=4200h (hard disk/OMTI)
;   E=2 -> IX=FC00h (CP/M floppy)
;   E=3 -> IX=0000h (service disk)
; The loader uses the byte-at-offset-E0h-of-track0/sector0 convention.
0079  DD 21 00 00 ixselect    LD	IX,coldstart
007D  7B                   LD	A,E
007E  FE 03                CP	3
0080  28 0C                JR	Z,devinit
0082  DD 21 00 FC          LD	IX,0fc00h
0086  FE 02                CP	2
0088  28 04                JR	Z,devinit
008A  DD 21 00 42          LD	IX,4200h
; devinit -- further per-device init: clears 0x36 bytes at 4000h,
; 0x27 bytes after DE, then flag-dependent jumps back to hkcompare
; (0042h, normal dispatch) or hkforcefloppy's own target (0056h).
; Continues past 00CCh into fdcinit_partial (00CFh) -- floppy controller
; register init (37EDh-37EFh). Not analysed in depth here.
;
; The routine has two entry paths. ixselect's JR Z,devinit (0080h/0088h)
; enters at 008Eh and executes a two-instruction preamble first.
; omtidetect's success path (1141h: JP 382Eh) enters at RAM 382Eh,
; which maps to ROM 0096h (382Eh - 3800h = 2Eh; 0068h + 2Eh = 0096h),
; skipping 008Eh-0093h.
008E  3E 02       devinit    LD	A,2
0090  32 94 38             LD	(3894h),A
0093  CD 67 38             CALL	3867h
; *** E=1/OMTI ENTRY POINT (RAM 382Eh). *** PUSH IX here (IX=4200h)
; is not a normal save/restore — paired with RET Z at 00BAh it functions
; as a jump to 4200h (RET pops the pushed IX value into PC). On this
; path SP becomes 0FFFEh and ports F9/FA are set earlier during coldstart.
; The hkcompare/0049h path describes a different dispatch case.
0096  31 FE FF             LD	SP,0fffeh
0099  DD E5                PUSH	IX
009B  7B                   LD	A,E
009C  FE 03                CP	3
009E  C8                   RET	Z
009F  FE 02                CP	2
00A1  C8                   RET	Z
00A2  F5                   PUSH	AF
00A3  E5                   PUSH	HL
; Copies 0x36 bytes from RAM 38E7h to 4000h, then clears the following
; 0x27 bytes (4036h-405Ch). The source overlaps data from the earlier
; ROM relocation (ROM 019Eh -> RAM 3800h) and maps to ROM 0285h onward.
; The second relocation (banner_and_reloc2/0031h: ROM 0068h -> RAM 3800h)
; The second relocation (0xE7 bytes) overwrites 3800h-38E6h, leaving
; byte 38E7h untouched. As a result, the copy copies data from the
; earlier relocation into 4000h-4035h. This appears to be incidental
; carry-over rather than deliberate payload.
00A4  21 E7 38             LD	HL,38e7h
00A7  11 00 40             LD	DE,4000h
00AA  01 36 00             LD	BC,0036h
00AD  ED B0                LDIR
00AF  AF                   XOR	A
00B0  06 27                LD	B,27h
00B2  12          clearloop    LD	(DE),A
00B3  13                   INC	DE
00B4  10 FC                DJNZ	clearloop
00B6  E1                   POP	HL
00B7  F1                   POP	AF
; *** THE ACTUAL E=1/OMTI HAND-OFF. *** CP 1 / RET Z: for E=1, this
; RET pops the IX value PUSHed at 0099h (AF/HL are pushed/popped around
; it but the stack content holding IX is unchanged), yielding a net
; effect equivalent to JP 4200h without executing JP (IX) at hkcompare/0050h.
; See the note at 0096h for the resulting state at 4200h.
00B8  FE 01                CP	1
00BA  C8                   RET	Z
00BB  3A FF 2F             LD	A,(2fffh)
00BE  32 FF FF             LD	(0ffffh),A
00C1  3E 90                LD	A,90h
00C3  D3 FA                OUT	(0fah),A
00C5  C3 42 00             JP	hkcompare
00C8  3E 90       hkforcefloppy    LD	A,90h
00CA  D3 FA                OUT	(0fah),A
00CC  C3 56 00             JP	floppyforce
; fdcinit_partial -- floppy-controller-adjacent init (37EDh-37EFh),
; reached as fall-through from devinit. This is inside the same
; relocated copy as devdispatch (RAM 3800h+), and the CALLs visible
; here (38DEh, 38CFh, 38D8h etc.) reference other parts of that
; relocated body. Not analysed here (floppy-path detail).
00CF  21 ED 37    fdcinit_partial    LD	HL,37edh
00D2  36 00                LD	(HL),0
00D4  2B                   DEC	HL
00D5  06 0A                LD	B,0ah
00D7  36 D0       fdcinit_partial_loop    LD	(HL),0d0h
00D9  CD DE 38             CALL	38deh
00DC  C5                   PUSH	BC
00DD  CD CF 38             CALL	38cfh
00E0  AF                   XOR	A
00E1  32 EE 37             LD	(37eeh),A
00E4  32 EF 37             LD	(37efh),A
00E7  36 0B                LD	(HL),0bh
00E9  CD CF 38             CALL	38cfh
00EC  36 88                LD	(HL),88h
00EE  DD E5                PUSH	IX
00F0  C1                   POP	BC
00F1  11 00 E1             LD	DE,0e100h
00F4  CD D8 38             CALL	38d8h
00F7  18 0A                JR	fdcinit_partial_poll
00F9  3A EF 37             LD	A,(37efh)
00FC  02                   LD	(BC),A
00FD  15                   DEC	D
00FE  C2 9A 38             JP	NZ,389ah
0101  5F                   LD	E,A
0102  03                   INC	BC
0103  CB 4E       fdcinit_partial_poll    BIT	1,(HL)
0105  C2 91 38             JP	NZ,3891h
0108  CB 4E                BIT	1,(HL)
010A  C2 91 38             JP	NZ,3891h
010D  CB 4E                BIT	1,(HL)
010F  C2 91 38             JP	NZ,3891h
0112  CB 46                BIT	0,(HL)
0114  CA B9 38             JP	Z,38b9h
0117  CB 4E                BIT	1,(HL)
0119  C2 91 38             JP	NZ,3891h
011C  CB 7E                BIT	7,(HL)
011E  CA 9B 38             JP	Z,389bh
0121  7E                   LD	A,(HL)
0122  36 D0                LD	(HL),0d0h
0124  C1                   POP	BC
0125  E6 FC                AND	0fch
0127  C8                   RET	Z
0128  3E FE                LD	A,0feh
012A  B0                   OR	B
012B  77                   LD	(HL),A
012C  10 A9                DJNZ	fdcinit_partial_loop
012E  3E 90                LD	A,90h
0130  D3 FA                OUT	(0fah),A
0132  3E 01                LD	A,1
0134  C3 57 00             JP	relocfloppy
0137                       DEFB	0cdh,0d8h,38h,0cbh,46h,20h,0fch,7eh,0c9h,3eh,08h,3dh,20h,0fdh,0c9h,3eh	;..8.F .~.>.= ..>
0147                       DEFB	01h,32h,0e0h,37h,0cdh,0d8h,38h,0c9h,0c3h,96h,1ch,0c3h,78h,1dh,0c3h,90h	;.2.7..8.....x...
0157                       DEFB	1ch,0c3h,0d9h,25h,0c9h,00h,00h,0c9h,00h,00h,0fbh,0c9h,00h,01h,0e3h,03h	;...%............
0167                       DEFB	00h,00h,00h,4bh,49h,07h,58h,04h,00h,3ch,00h,44h,4fh,06h,8dh,05h	;...KI.X..<.DO...
0177                       DEFB	43h,00h,00h,50h,52h,0c3h,00h,50h,0c7h,00h,00h,3eh,00h,0c9h	;C..PR..P...>..
; =====================================================================
; bannerclr -- clear video RAM 3C00h-3FFEh to spaces, then copy 0xC0
; bytes of banner text from ROM 058Dh to 3C00h. Called once, from
; banner_and_reloc2 (0031h).
; =====================================================================
0185  21 00 3C    bannerclr    LD	HL,3c00h
0188  11 01 3C             LD	DE,3c01h
018B  01 FF 03             LD	BC,03ffh
018E  36 20                LD	(HL),20h
0190  ED B0                LDIR
0192  21 8D 05             LD	HL,058dh
0195  11 00 3C             LD	DE,3c00h
0198  01 C0 00             LD	BC,00c0h
019B  ED B0                LDIR
019D  C9                   RET
019E                       DEFB	21h,0dfh,3bh,01h,0f7h,10h,0afh,0d3h,0f6h,3ch,0edh,0a3h,20h,0f9h,21h,0ffh	;!.;......<.. .!.
01AE                       DEFB	0ffh,3eh,5ch,0d3h,0fah,46h,3eh,0aah,77h,3eh,54h,0d3h,0fah,78h,0feh,0aah	;.>\..F>.w>T..x..
01BE                       DEFB	20h,06h,0cbh,7eh,20h,02h,0cbh,46h,0c4h,32h,38h,3eh,10h,0d3h,0fah,0c3h	; ..~ ..F.28>....
01CE                       DEFB	31h,00h,21h,00h,40h,11h,01h,40h,01h,0ffh,0fh,75h,0edh,0b0h,21h,02h	;1.!.@..@...u..!.
01DE                       DEFB	40h,44h,0e5h,11h,0f1h,38h,0cdh,7ch,38h,0ebh,0e3h,01h,0b0h,01h,0edh,0b0h	;@D...8.|8.......
01EE                       DEFB	0ebh,0d1h,06h,25h,0cdh,7ch,38h,21h,0c9h,42h,06h,16h,1ah,77h,13h,1ah	;...%.|8!.B...w..
01FE                       DEFB	13h,85h,6fh,30h,01h,24h,10h,0f4h,0cdh,8bh,38h,21h,00h,44h,11h,00h	;..o0.$....8!.D..
020E                       DEFB	4ch,7eh,2fh,12h,23h,13h,0cbh,64h,28h,0f7h,18h,4dh,0c5h,01h,09h,07h	;L~/.#..d(..M....
021E                       DEFB	1ah,77h,13h,23h,10h,0fah,09h,0c1h,10h,0f2h,0c9h,21h,00h,48h,11h,0ch	;.w.#.......!.H..
022E                       DEFB	00h,01h,01h,10h,0cdh,0a6h,38h,21h,04h,48h,01h,04h,04h,0cdh,0a6h,38h	;......8!.H.....8
023E                       DEFB	21h,08h,48h,01h,10h,01h,0afh,0cdh,0bch,38h,3eh,0fh,0cdh,0bch,38h,3eh	;!.H......8>...8>
024E                       DEFB	0f0h,0cdh,0bch,38h,3eh,0ffh,0cdh,0bch,38h,10h,0ebh,0c9h,0c5h,06h,04h,77h	;...8>...8......w
025E                       DEFB	23h,10h,0fch,19h,0dh,20h,0f6h,0c1h,0c9h,11h,00h,40h,0dbh,0f9h,4fh,0f6h	;#.... .....@..O.
026E                       DEFB	02h,0d3h,0f9h,0afh,47h,32h,00h,3ch,0c5h,0f5h,21h,00h,84h,06h,10h,1ah	;....G2.<..!.....
027E                       DEFB	77h,13h,3eh,08h,84h,67h,10h,0f7h,0f1h,3ch,0c1h,10h,0e8h,79h,0d3h,0f9h	;w.>..g...<...y..
028E                       DEFB	0c9h,1ch,22h,20h,2ch,2ah,2ah,1ch,08h,14h,22h,22h,3eh,22h,22h,1eh	;.." ,**..."">"".
029E                       DEFB	22h,22h,1eh,22h,22h,1eh,1ch,22h,02h,02h,02h,22h,1ch,1eh,22h,22h	;""."".."..."..""
02AE                       DEFB	22h,22h,22h,1eh,3eh,02h,02h,0eh,02h,02h,3eh,3eh,02h,02h,0eh,02h	;""".>.....>>....
02BE                       DEFB	02h,02h,1ch,22h,02h,3ah,22h,22h,1ch,22h,22h,22h,3eh,22h,22h,22h	;...".:"".""">"""
02CE                       DEFB	1ch,08h,08h,08h,08h,08h,1ch,3ch,20h,20h,20h,20h,22h,1ch,22h,12h	;.......<    ".".
02DE                       DEFB	0ah,06h,0ah,12h,22h,02h,02h,02h,02h,02h,02h,3eh,22h,36h,2ah,2ah	;...."......>"6**
02EE                       DEFB	22h,22h,22h,22h,22h,26h,2ah,32h,22h,22h,1ch,22h,22h,22h,22h,22h	;"""""&*2""."""""
02FE                       DEFB	1ch,1eh,22h,22h,1eh,02h,02h,02h,1ch,22h,22h,22h,2ah,12h,2ch,1eh	;..""....."""*.,.
030E                       DEFB	22h,22h,1eh,0ah,12h,22h,1ch,22h,02h,1ch,20h,22h,1ch,7fh,08h,08h	;""...".".. "....
031E                       DEFB	08h,08h,08h,08h,22h,22h,22h,22h,22h,22h,1ch,22h,22h,22h,22h,22h	;....""""""."""""
032E                       DEFB	14h,08h,22h,22h,22h,2ah,2ah,36h,22h,22h,22h,14h,08h,14h,22h,22h	;.."""**6"""...""
033E                       DEFB	22h,22h,14h,08h,08h,08h,08h,3eh,20h,10h,08h,04h,02h,3eh,08h,1ch	;"".....> ....>..
034E                       DEFB	2ah,08h,08h,08h,08h,08h,08h,08h,08h,2ah,1ch,08h,00h,08h,04h,3eh	;*........*.....>
035E                       DEFB	04h,08h,00h,00h,08h,10h,3eh,10h,08h,00h,00h,00h,00h,00h,00h,00h	;......>.........
036E                       DEFB	3eh,00h,00h,00h,00h,00h,00h,00h,08h,08h,08h,08h,08h,00h,08h,14h	;>...............
037E                       DEFB	14h,14h,00h,00h,00h,00h,14h,14h,3eh,14h,3eh,14h,14h,08h,3ch,0ah	;........>.>...<.
038E                       DEFB	1ch,28h,1eh,08h,46h,26h,10h,08h,04h,62h,61h,04h,0ah,0ah,04h,2ah	;.(..F&...ba....*
039E                       DEFB	1ah,24h,18h,18h,08h,04h,00h,00h,00h,10h,08h,04h,04h,04h,08h,10h	;.$..............
03AE                       DEFB	08h,10h,20h,20h,20h,10h,08h,00h,08h,2ah,1ch,2ah,08h,00h,00h,08h	;..   ....*.*....
03BE                       DEFB	08h,7fh,08h,08h,00h,00h,00h,00h,00h,00h,18h,18h,00h,00h,00h,3eh	;...............>
03CE                       DEFB	00h,00h,00h,00h,00h,00h,00h,00h,0ch,0ch,40h,20h,10h,08h,04h,02h	;..........@ ....
03DE                       DEFB	01h,1ch,22h,32h,2ah,26h,22h,1ch,08h,0ch,0ah,08h,08h,08h,1ch,1ch	;.."2*&".........
03EE                       DEFB	22h,20h,10h,08h,04h,3eh,1ch,22h,20h,18h,20h,22h,1ch,10h,18h,14h	;" ...>." . "....
03FE                       DEFB	12h,3eh,10h,10h,3eh,02h,1eh,20h,20h,22h,1ch,18h,04h,02h,1eh,22h	;.>..>..  "....."
040E                       DEFB	22h,1ch,3eh,20h,20h,10h,08h,08h,08h,1ch,22h,22h,1ch,22h,22h,1ch	;".>  .....""."".
041E                       DEFB	1ch,22h,22h,3ch,20h,20h,1ch,00h,00h,18h,18h,00h,18h,18h,00h,00h	;.""<  ..........
042E                       DEFB	18h,18h,00h,18h,18h,10h,08h,04h,02h,04h,08h,10h,00h,00h,3eh,00h	;..............>.
043E                       DEFB	3eh,00h,00h,04h,08h,10h,20h,10h,08h,04h,1ch,22h,20h,10h,08h,00h	;>..... ...." ...
044E                       DEFB	08h,08h,14h,22h,22h,3eh,22h,22h,1ch,22h,22h,22h,22h,22h,1ch,00h	;..."">""."""""..
045E                       DEFB	22h,22h,22h,22h,22h,1ch,08h,14h,22h,00h,00h,00h,00h,00h,00h,00h	;"""""...".......
046E                       DEFB	00h,00h,00h,3eh,22h,02h,1ch,22h,1ch,20h,22h,00h,00h,1ch,20h,3ch	;...>"..". "... <
047E                       DEFB	22h,3ch,02h,02h,1ah,26h,22h,26h,1ah,00h,00h,1ch,22h,02h,22h,1ch	;"<...&"&....".".
048E                       DEFB	20h,20h,2ch,32h,22h,32h,2ch,00h,00h,1ch,22h,3eh,02h,1ch,18h,24h	;  ,2"2,...">...$
049E                       DEFB	04h,0eh,04h,04h,04h,00h,00h,1ch,22h,22h,22h,3ch,02h,02h,1ah,26h	;........"""<...&
04AE                       DEFB	22h,22h,22h,0ch,00h,0ch,08h,08h,08h,1ch,30h,00h,38h,20h,20h,20h	;""".......0.8   
04BE                       DEFB	20h,02h,02h,22h,12h,0eh,12h,22h,0ch,08h,08h,08h,08h,08h,1ch,00h	; .."..."........
04CE                       DEFB	00h,16h,2ah,2ah,2ah,2ah,00h,00h,1ah,26h,22h,22h,22h,00h,00h,1ch	;..****...&"""...
04DE                       DEFB	22h,22h,22h,1ch,00h,00h,1ah,26h,22h,26h,1ah,00h,00h,2ch,32h,22h	;"""....&"&...,2"
04EE                       DEFB	32h,2ch,00h,00h,1ah,26h,02h,02h,02h,00h,00h,3ch,02h,1ch,20h,1eh	;2,...&.....<.. .
04FE                       DEFB	04h,04h,0eh,04h,04h,24h,18h,00h,00h,22h,22h,22h,32h,2ch,00h,00h	;.....$..."""2,..
050E                       DEFB	22h,22h,22h,14h,08h,00h,00h,22h,22h,2ah,2ah,14h,00h,00h,22h,14h	;"""....""**...".
051E                       DEFB	08h,14h,22h,00h,00h,22h,22h,22h,22h,3ch,00h,00h,3eh,10h,08h,04h	;.."..""""<..>...
052E                       DEFB	3eh,22h,00h,1ch,20h,3ch,22h,3ch,22h,00h,1ch,22h,22h,22h,1ch,22h	;>".. <"<".."""."
053E                       DEFB	00h,22h,22h,22h,32h,2ch,1ch,22h,22h,3ah,42h,42h,32h,55h,0aah,55h	;."""2,."":BB2U.U
054E                       DEFB	0aah,55h,0aah,55h,08h,01h,04h,0efh,08h,01h,04h,0ffh,00h,0f8h,22h,10h	;.U.U..........".
055E                       DEFB	22h,10h,22h,30h,1ch,08h,1ch,70h,20h,01h,1eh,2fh,22h,01h,1ch,5fh	;"."0...p ../".._
056E                       DEFB	02h,01h,02h,0fh,20h,01h,20h,7fh,20h,01h,1eh,4fh,02h,01h,02h,6eh	;.... . . ..O...n
057E                       DEFB	40h,50h,0ah,1ah,05h,10h,16h,02h,0bh,6ah,0ah,04h,00h,04h,00h,0beh	;@P.......j......
058E                       DEFB	83h,83h,8dh,80h,0bfh,83h,83h,80h,0bfh,90h,0aah,95h,82h,0abh,97h,81h	;................
059E                       DEFB	0aah,97h,83h,81h,80h,80h,82h,0abh,97h,0abh,97h,0abh,97h,81h,80h,80h	;................
05AE                       DEFB	0a0h,9ch,0ach,90h,20h,20h,20h,28h,52h,29h,20h,20h,31h,39h,38h,34h	;....   (R)  1984
05BE                       DEFB	20h,54h,43h,53h,20h,23h,38h,36h,30h,31h,30h,30h,33h,20h,20h,0bfh	; TCS #8601003  .
05CE                       DEFB	80h,88h,0bch,80h,0bfh,8ch,84h,80h,0bfh,8bh,0beh,95h,80h,0aah,95h,80h	;................
05DE                       DEFB	0aah,9dh,8ch,80h,80h,80h,80h,0aah,95h,0aah,95h,0aah,95h,80h,80h,80h	;................
05EE                       DEFB	0aah,95h,8eh,0b5h,20h,20h,20h,28h,43h,29h,20h,20h,31h,39h,38h,34h	;....   (C)  1984
05FE                       DEFB	20h,55h,77h,65h,20h,42h,7ch,6bh,65h,72h,20h,20h,20h,20h,20h,8bh	; Uwe B|ker     .
060E                       DEFB	8ch,8ch,87h,80h,8fh,8ch,8ch,80h,8fh,80h,8ah,85h,88h,8eh,8dh,84h	;................
061E                       DEFB	8ah,8dh,8ch,84h,80h,80h,88h,8eh,8dh,8eh,8dh,8eh,8dh,84h,80h,80h	;................
062E                       DEFB	0aah,95h,88h,87h,20h,20h,20h,6dh,6fh,64h,2eh,20h,31h,39h,38h,36h	;....   mod. 1986
063E                       DEFB	20h,41h,72h,6eh,75h,6ch,66h,20h,53h,6fh,70h,70h,20h,20h,20h,0f3h	; Arnulf Sopp   .
064E                       DEFB	31h,0feh,0ffh,21h,00h,03h,22h,63h,0ffh,65h,22h,65h,0ffh,22h,67h,0ffh	;1..!.."c.e"e."g.
065E                       DEFB	22h,69h,0ffh,3eh,01h,0d3h,0f9h,3eh,0c4h,0d3h,0fah,0cdh,8dh,0feh,3ah,0ffh	;"i.>...>......:.
066E                       DEFB	0ffh,0feh,01h,0cah,77h,0fbh,0feh,02h,0cah,86h,0fbh,0feh,55h,0cah,8dh,0fbh	;....w.......U...
067E                       DEFB	3eh,01h,0cdh,62h,0f8h,0cdh,93h,0f9h,0feh,0dh,20h,0f6h,0cdh,0c6h,0f8h,36h	;>..b...... ....6
068E                       DEFB	80h,2ah,5fh,0ffh,0cdh,4ch,0f8h,0cah,0dah,0f7h,0e6h,0dfh,0feh,49h,0cah,4dh	;.*_..L.......I.M
069E                       DEFB	0fah,0feh,54h,0cah,65h,0fah,0feh,42h,0cah,0ceh,0fah,0feh,44h,0cah,0dah,0fbh	;..T.e..B....D...
06AE                       DEFB	0feh,4bh,0cah,0eh,0fdh,0feh,43h,0cah,0eh,0fdh,0feh,4dh,0cah,8fh,0fdh,0feh	;.K....C....M....
06BE                       DEFB	55h,28h,16h,0feh,50h,28h,17h,0f5h,0cdh,0cbh,0fbh,0f1h,0e5h,0feh,47h,0c8h	;U(..P(........G.
06CE                       DEFB	0feh,45h,20h,36h,21h,0dah,0f7h,0e3h,0e9h,0cdh,9ch,0feh,18h,4bh,0cdh,0a8h	;.E 6!........K..
06DE                       DEFB	0fch,0dah,0c2h,0f7h,0afh,0b0h,0cah,0bbh,0f7h,0feh,03h,0d2h,0c2h,0f7h,3ah,65h	;..............:e
06EE                       DEFB	0ffh,4fh,05h,28h,07h,3ah,67h,0ffh,0edh,79h,18h,2dh,3eh,0ah,0c5h,0cdh	;.O.(.:g..y.->...
06FE                       DEFB	62h,0f8h,0c1h,0edh,78h,0cdh,7dh,0fch,18h,1fh,21h,0dah,0feh,06h,0bh,18h	;b...x.}...!.....
070E                       DEFB	0ch,21h,12h,0ffh,06h,11h,18h,05h,21h,0e5h,0feh,06h,18h,0e5h,0c5h,3eh	;.!......!......>
071E                       DEFB	0ah,0cdh,62h,0f8h,0c1h,0e1h,0cdh,3ch,0fah,31h,0feh,0ffh,0c3h,31h,0f7h,06h	;..b....<.1...1..
072E                       DEFB	16h,21h,0b5h,0feh,0cdh,3ch,0fah,3ah,63h,0ffh,3ch,32h,63h,0ffh,01h,20h	;.!...<.:c.<2c.. 
073E                       DEFB	30h,0dbh,0f9h,0f5h,3eh,01h,0d3h,0f9h,0c5h,3eh,0c5h,0d3h,0fah,0cdh,25h,0f8h	;0...>....>....%.
074E                       DEFB	0c1h,0a4h,28h,18h,0c5h,3eh,0c4h,0d3h,0fah,78h,0cdh,62h,0f8h,0c1h,0c5h,0cdh	;..(..>...x.b....
075E                       DEFB	67h,0f8h,0c1h,04h,0dbh,0f9h,0c6h,40h,0feh,01h,20h,0dah,0f1h,0d3h,0f9h,3eh	;g......@.. ....>
076E                       DEFB	0c4h,0d3h,0fah,0c9h,21h,00h,00h,46h,36h,00h,7eh,0b7h,0c0h,70h,46h,36h	;....!..F6.~..pF6
077E                       DEFB	55h,7eh,0feh,55h,20h,05h,36h,0aah,7eh,0feh,0aah,70h,28h,06h,3eh,01h	;U~.U .6.~..p(.>.
078E                       DEFB	0d3h,0f9h,18h,11h,23h,7ch,0feh,0e0h,20h,0e4h,0c9h,7eh,0feh,80h,0c8h,0feh	;....#|.. ..~....
079E                       DEFB	20h,0c0h,23h,18h,0f6h,3eh,0c4h,0d3h,0fah,06h,0fh,21h,0cbh,0feh,0c3h,0d7h	; .#..>.....!....
07AE                       DEFB	0f7h,0feh,20h,38h,77h,4fh,21h,5dh,0ffh,3eh,0f7h,0beh,0d8h,34h,79h,0feh	;.. 8wO!].>...4y.
07BE                       DEFB	40h,38h,06h,3ah,70h,0ffh,0e6h,0c0h,81h,0cdh,0c6h,0f8h,77h,2ah,63h,0ffh	;@8.:p.......w*c.
07CE                       DEFB	2ch,3eh,3fh,0bdh,30h,09h,0afh,6fh,24h,3eh,0fh,0bch,0dch,0ach,0f8h,22h	;,>?.0..o$>....."
07DE                       DEFB	63h,0ffh,0cdh,0c6h,0f8h,0f5h,3eh,0eh,0d3h,0f6h,7ch,0d6h,38h,0d3h,0f7h,3eh	;c.....>...|.8..>
07EE                       DEFB	0fh,0d3h,0f6h,7dh,0d3h,0f7h,0f1h,36h,20h,37h,0c9h,11h,00h,3ch,21h,40h	;...}...6 7...<!@
07FE                       DEFB	3ch,01h,0c0h,03h,0edh,0b0h,0ebh,11h,0c1h,3fh,01h,3fh,00h,36h,20h,0edh	;<........?.?.6 .
080E                       DEFB	0b0h,21h,00h,0fh,0c9h,0f5h,0afh,2ah,64h,0ffh,67h,06h,06h,29h,10h,0fdh	;.!.....*d.g..)..
081E                       DEFB	57h,3ah,63h,0ffh,5fh,19h,11h,00h,3ch,19h,0f1h,0c9h,0feh,0dh,28h,1dh	;W:c._...<.....(.
082E                       DEFB	0feh,08h,28h,4fh,0feh,09h,0cah,52h,0f9h,0feh,0ah,28h,2fh,0feh,1fh,0cah	;..(O...R...(/...
083E                       DEFB	66h,0f9h,0feh,01h,28h,18h,0feh,18h,0cah,76h,0f9h,0afh,0c9h,0cdh,0c6h,0f8h	;f...(....v......
084E                       DEFB	36h,20h,2ah,63h,0ffh,0cdh,87h,0f8h,3eh,2ah,0cdh,62h,0f8h,0c9h,0cdh,0feh	;6 *c....>*.b....
085E                       DEFB	0f8h,0afh,32h,5dh,0ffh,0cdh,0c6h,0f8h,22h,5fh,0ffh,0c9h,0cdh,0fh,0f9h,36h	;..2]...."_.....6
086E                       DEFB	20h,2ah,5fh,0ffh,2bh,22h,5fh,0ffh,2ah,63h,0ffh,2eh,00h,22h,63h,0ffh	; *_.+"_.*c..."c.
087E                       DEFB	0c3h,90h,0f8h,3ah,5dh,0ffh,0b7h,0c8h,3dh,32h,5dh,0ffh,0cdh,0c6h,0f8h,36h	;...:]...=2]....6
088E                       DEFB	20h,2ah,63h,0ffh,3eh,0ffh,2dh,0bdh,0c2h,90h,0f8h,2eh,3fh,25h,0c3h,90h	; *c.>.-.....?%..
089E                       DEFB	0f8h,3ah,63h,0ffh,0e6h,07h,4fh,3eh,08h,91h,47h,0c5h,3eh,20h,0cdh,62h	;.:c...O>..G.> .b
08AE                       DEFB	0f8h,0c1h,10h,0f7h,0c9h,21h,00h,3ch,22h,5fh,0ffh,0cdh,7ch,0f9h,0afh,32h	;.....!.<"_..|..2
08BE                       DEFB	5dh,0ffh,0c3h,90h,0f8h,0cdh,34h,0f9h,38h,0fbh,0c9h,21h,00h,3ch,11h,01h	;].....4.8..!.<..
08CE                       DEFB	3ch,01h,0ffh,03h,36h,20h,0edh,0b0h,21h,00h,00h,22h,63h,0ffh,0afh,0d3h	;<...6 ..!.."c...
08DE                       DEFB	0ffh,0c9h,0cdh,9ah,0f9h,0b7h,0c0h,18h,0f9h,21h,56h,0ffh,01h,01h,38h,0ah	;.........!V...8.
08EE                       DEFB	5fh,0aeh,73h,0a3h,20h,07h,23h,0cbh,01h,0f2h,0a0h,0f9h,0c9h,5fh,0cdh,2fh	;_.s. .#......_./
08FE                       DEFB	0fah,0ah,0a3h,0c8h,79h,0feh,10h,38h,24h,0feh,40h,38h,15h,21h,46h,0ffh	;....y..8$.@8.!F.
090E                       DEFB	0cdh,0f7h,0f9h,0cbh,01h,06h,00h,09h,3ah,80h,38h,0fh,30h,01h,23h,4eh	;........:.8.0.#N
091E                       DEFB	18h,1fh,0cdh,0eh,0fah,30h,1ah,79h,0eeh,10h,4fh,18h,14h,0cdh,0ffh,0f9h	;.....0.y..O.....
092E                       DEFB	30h,0fh,79h,0eeh,20h,4fh,3ah,40h,38h,0e6h,10h,28h,04h,79h,0e6h,1fh	;0.y. O:@8..(.y..
093E                       DEFB	4fh,79h,0cdh,2fh,0fah,0c9h,0eh,00h,0cbh,0bh,0d8h,0ch,18h,0fah,0cdh,1bh	;Oy./............
094E                       DEFB	0fah,0feh,60h,20h,02h,0d6h,20h,4fh,3ah,80h,38h,0fh,0c9h,0cdh,1bh,0fah	;..` .. O:.8.....
095E                       DEFB	0d6h,50h,0feh,3ch,38h,0f1h,0d6h,10h,18h,0edh,0c5h,0cdh,0f7h,0f9h,79h,0c1h	;.P.<8.........y.
096E                       DEFB	59h,0cdh,0f7h,0f9h,0cbh,01h,0cbh,01h,0cbh,01h,81h,0c6h,60h,0c9h,0f5h,0c5h	;Y...........`...
097E                       DEFB	01h,00h,04h,0bh,78h,0b1h,20h,0fbh,0c1h,0f1h,0c9h,7eh,0e5h,0c5h,0cdh,62h	;....x. ....~...b
098E                       DEFB	0f8h,0c1h,0e1h,23h,10h,0f5h,0cdh,0c6h,0f8h,36h,20h,0c9h,23h,0cdh,4ch,0f8h	;...#.....6 .#.L.
099E                       DEFB	0c2h,0bbh,0f7h,3eh,00h,0d3h,0fah,0dbh,0f9h,0e6h,31h,0d3h,0f9h,0dbh,0fbh,0e6h	;...>......1.....
09AE                       DEFB	0fch,0d3h,0fbh,0c7h,23h,0cdh,4ch,0f8h,06h,01h,28h,10h,0e6h,0dfh,0feh,41h	;....#.L...(....A
09BE                       DEFB	0c2h,0bbh,0f7h,0dbh,0fbh,0f5h,0e6h,0fch,06h,04h,18h,03h,0dbh,0fbh,0f5h,0c5h	;................
09CE                       DEFB	0d3h,0fbh,0e6h,03h,0c6h,41h,32h,0c8h,0feh,3eh,0ah,0cdh,62h,0f8h,0cdh,0e0h	;.....A2..>..b...
09DE                       DEFB	0f7h,0c1h,0dbh,0fbh,3ch,10h,0e8h,0f1h,0d3h,0fbh,0cdh,0bbh,0fah,0c3h,0dah,0f7h	;....<...........
09EE                       DEFB	0c3h,0c9h,0f7h,0cdh,4ch,0f8h,20h,0f8h,79h,0e6h,03h,0fh,0fh,3ch,4fh,0dbh	;....L. .y....<O.
09FE                       DEFB	0f9h,0e6h,3fh,0b1h,0d3h,0f9h,21h,0dah,0f7h,0e5h,0dbh,0f9h,0e6h,0c0h,07h,07h	;..?...!.........
0A0E                       DEFB	0f6h,30h,32h,05h,0ffh,06h,15h,21h,0fdh,0feh,0c3h,3ch,0fah,23h,0cdh,4ch	;.02....!...<.#.L
0A1E                       DEFB	0f8h,28h,0e3h,7eh,4fh,23h,0feh,30h,38h,0c6h,0feh,34h,38h,0c5h,0e6h,0dfh	;.(.~O#.08..48...
0A2E                       DEFB	0feh,41h,38h,16h,0feh,45h,30h,0b8h,32h,0c8h,0feh,32h,03h,0ffh,0d6h,41h	;.A8..E0.2..2...A
0A3E                       DEFB	4fh,0dbh,0fbh,0e6h,0fch,0b1h,0d3h,0fbh,18h,0d4h,0cdh,4ch,0f8h,28h,0a1h,0cdh	;O..........L.(..
0A4E                       DEFB	0b1h,0fbh,79h,0feh,35h,0cah,94h,0fbh,0feh,38h,20h,94h,0dbh,0fbh,0e6h,0fch	;..y.5....8 .....
0A5E                       DEFB	0d3h,0fbh,3eh,0c0h,32h,0eeh,37h,2ah,65h,0ffh,22h,6bh,0ffh,21h,0ech,37h	;..>.2.7*e."k.!.7
0A6E                       DEFB	36h,0feh,36h,0d0h,23h,36h,00h,2bh,06h,0ah,0cdh,99h,0fbh,0c5h,0cdh,0a2h	;6.6.#6.+........
0A7E                       DEFB	0fbh,11h,00h,00h,0edh,53h,0eeh,37h,36h,1bh,0cdh,0a2h,0fbh,36h,88h,0edh	;.....S.76....6..
0A8E                       DEFB	4bh,65h,0ffh,11h,0efh,37h,0cdh,0abh,0fbh,18h,03h,1ah,02h,03h,0cbh,4eh	;Ke...7.........N
0A9E                       DEFB	20h,0f9h,0cbh,4eh,20h,0f5h,0cbh,4eh,20h,0f1h,0cbh,46h,28h,08h,0cbh,4eh	; ..N ..N ..F(..N
0AAE                       DEFB	20h,0e9h,0cbh,7eh,28h,0e8h,7eh,36h,0d0h,0c1h,0e6h,0fch,0cah,0dah,0f7h,0cdh	; ..~(.~6........
0ABE                       DEFB	0abh,0fbh,36h,0bh,10h,0b4h,21h,23h,0ffh,06h,0ch,0cdh,3ch,0fah,0afh,32h	;..6...!#....<..2
0ACE                       DEFB	0ffh,0ffh,0c3h,0dah,0f7h,21h,2fh,0ffh,06h,0ch,18h,0efh,21h,3bh,0ffh,06h	;.....!/.....!;..
0ADE                       DEFB	0bh,18h,0e8h,3eh,80h,0c3h,15h,0fbh,3eh,01h,32h,0e0h,37h,3eh,0ffh,18h	;...>....>.2.7>..
0AEE                       DEFB	0bh,0cdh,0abh,0fbh,0cbh,46h,20h,0fch,7eh,0c9h,3eh,18h,3dh,20h,0fdh,0c9h	;.....F .~.>.= ..
0AFE                       DEFB	0c5h,2bh,0cdh,0b8h,0fbh,0c1h,0c9h,0cdh,0a8h,0fch,0dah,0c9h,0f7h,3eh,01h,0b8h	;.+...........>..
0B0E                       DEFB	0dah,0c2h,0f7h,0cdh,4ch,0f8h,0c2h,0c9h,0f7h,0c9h,0edh,5bh,6bh,0ffh,0edh,53h	;....L......[k..S
0B1E                       DEFB	65h,0ffh,0cdh,0b8h,0fbh,2ah,65h,0ffh,0c9h,0cdh,0a8h,0fch,0dah,0c9h,0f7h,3eh	;e....*e........>
0B2E                       DEFB	02h,0b8h,0dah,0c2h,0f7h,0cdh,4ch,0f8h,0c2h,0c9h,0f7h,2ah,65h,0ffh,3eh,01h	;......L....*e.>.
0B3E                       DEFB	0b8h,38h,07h,11h,70h,00h,19h,22h,67h,0ffh,0edh,5bh,67h,0ffh,0cdh,0a2h	;.8..p.."g..[g...
0B4E                       DEFB	0fch,0dah,0c2h,0f7h,3eh,0ah,0cdh,62h,0f8h,0cdh,40h,0fch,2ah,65h,0ffh,0edh	;....>..b..@.*e..
0B5E                       DEFB	5bh,67h,0ffh,0cdh,0a2h,0fch,38h,0ah,0a4h,20h,0e9h,0b5h,0feh,0fh,28h,02h	;[g....8.. ....(.
0B6E                       DEFB	30h,0e2h,22h,67h,0ffh,0c3h,0dah,0f7h,2ah,65h,0ffh,7ch,0cdh,7dh,0fch,7dh	;0."g....*e.|.}.}
0B7E                       DEFB	0cdh,7dh,0fch,01h,20h,02h,0c5h,79h,0cdh,62h,0f8h,0c1h,10h,0f8h,0c9h,0cdh	;.}.. ..y.b......
0B8E                       DEFB	29h,0fch,01h,20h,08h,2ah,65h,0ffh,0c5h,0cdh,73h,0fch,79h,0e5h,0cdh,62h	;).. .*e...s.y..b
0B9E                       DEFB	0f8h,0e1h,0c1h,10h,0f3h,79h,0cdh,62h,0f8h,2ah,65h,0ffh,06h,10h,7eh,0b9h	;.....y.b.*e...~.
0BAE                       DEFB	30h,02h,3eh,2eh,0e5h,0c5h,0cdh,62h,0f8h,0c1h,0e1h,23h,10h,0f0h,22h,65h	;0.>....b...#.."e
0BBE                       DEFB	0ffh,0c9h,06h,02h,7eh,0cdh,7dh,0fch,23h,10h,0f9h,0c9h,0e5h,0c5h,0cdh,85h	;....~.}.#.......
0BCE                       DEFB	0fch,0c1h,0e1h,0c9h,06h,02h,0c5h,01h,00h,04h,17h,0cbh,11h,10h,0fbh,0f5h	;................
0BDE                       DEFB	79h,0c6h,30h,0feh,3ah,38h,02h,0c6h,07h,0cdh,62h,0f8h,0f1h,0c1h,10h,0e6h	;y.0.:8....b.....
0BEE                       DEFB	0c9h,7ah,0bch,0c0h,7bh,0bdh,0c9h,23h,06h,00h,0cdh,4ch,0f8h,0c8h,0cdh,0d3h	;.z..{..#...L....
0BFE                       DEFB	0fch,0d8h,0edh,53h,65h,0ffh,04h,0cdh,4ch,0f8h,0c8h,0cdh,0d3h,0fch,0d8h,0edh	;...Se...L.......
0C0E                       DEFB	53h,67h,0ffh,04h,0cdh,4ch,0f8h,0c8h,0cdh,0d3h,0fch,0d8h,0edh,53h,69h,0ffh	;Sg...L.......Si.
0C1E                       DEFB	04h,0c9h,0c5h,06h,04h,11h,00h,00h,7eh,0feh,80h,28h,2eh,0feh,20h,28h	;........~..(.. (
0C2E                       DEFB	2ah,0feh,30h,38h,26h,0feh,3ah,38h,08h,0e6h,0dfh,0feh,41h,38h,1ch,0d6h	;*.08&.:8....A8..
0C3E                       DEFB	07h,0d6h,30h,0feh,10h,3fh,38h,13h,07h,07h,07h,07h,0c5h,06h,04h,07h	;..0..?8.........
0C4E                       DEFB	0cbh,13h,0cbh,12h,10h,0f9h,0c1h,23h,10h,0ceh,0afh,0c1h,0c9h,32h,5eh,0ffh	;.......#.....2^.
0C5E                       DEFB	0cdh,0a8h,0fch,3eh,02h,0b8h,0d2h,0c2h,0f7h,0cdh,4ch,0f8h,0c2h,0c9h,0f7h,2ah	;...>......L....*
0C6E                       DEFB	67h,0ffh,0edh,5bh,65h,0ffh,0cdh,0a2h,0fch,0f5h,3ah,5eh,0ffh,0feh,4bh,28h	;g..[e.....:^..K(
0C7E                       DEFB	2ah,0edh,4bh,69h,0ffh,78h,0b1h,0cah,0c9h,0f7h,0f1h,38h,0ch,0ebh,2ah,65h	;*.Ki.x.....8..*e
0C8E                       DEFB	0ffh,0edh,53h,65h,0ffh,0edh,0b0h,18h,0fh,09h,2bh,0ebh,2ah,65h,0ffh,09h	;..Se......+.*e..
0C9E                       DEFB	2bh,0edh,0b8h,13h,0edh,53h,65h,0ffh,0c3h,0dah,0f7h,0f1h,38h,01h,0ebh,0d5h	;+....Se.....8...
0CAE                       DEFB	0e5h,0afh,0edh,52h,0e5h,0c1h,0e1h,11h,0ffh,0f6h,0cdh,0a2h,0fch,0e1h,0dah,0c9h	;...R............
0CBE                       DEFB	0f7h,22h,65h,0ffh,2ah,69h,0ffh,0a4h,0c2h,0c9h,0f7h,7dh,2ah,65h,0ffh,0edh	;."e.*i.....}*e..
0CCE                       DEFB	5bh,65h,0ffh,13h,77h,78h,0b1h,28h,02h,0edh,0b0h,0c3h,0dah,0f7h,0cdh,0a8h	;[e..wx.(........
0CDE                       DEFB	0fch,0dah,0c9h,0f7h,3eh,01h,0b8h,0dah,0c2h,0f7h,0cdh,4ch,0f8h,0c2h,0c9h,0f7h	;....>......L....
0CEE                       DEFB	2ah,65h,0ffh,22h,67h,0ffh,3eh,0ah,0cdh,62h,0f8h,0cdh,29h,0fch,3eh,08h	;*e."g.>..b..).>.
0CFE                       DEFB	32h,69h,0ffh,2ah,65h,0ffh,7eh,23h,22h,65h,0ffh,0cdh,7dh,0fch,3eh,3dh	;2i.*e.~#"e..}.>=
0D0E                       DEFB	0cdh,62h,0f8h,0cdh,0dh,0feh,38h,1ch,71h,21h,5eh,0ffh,3eh,01h,86h,47h	;.b....8.q!^.>..G
0D1E                       DEFB	0c5h,3eh,20h,0cdh,62h,0f8h,0c1h,10h,0f7h,3ah,69h,0ffh,3dh,32h,69h,0ffh	;.> .b....:i.=2i.
0D2E                       DEFB	28h,0c4h,18h,0cfh,2ah,67h,0ffh,22h,65h,0ffh,0c3h,0dah,0f7h,0cdh,93h,0f9h	;(...*g."e.......
0D3E                       DEFB	0feh,08h,0c8h,0feh,0dh,0c8h,0feh,2eh,0c8h,0feh,30h,38h,0f0h,0feh,3ah,38h	;..........08..:8
0D4E                       DEFB	0ah,0e6h,0dfh,0feh,41h,38h,0e6h,0feh,47h,30h,0e2h,0c9h,3eh,02h,32h,5eh	;....A8..G0..>.2^
0D5E                       DEFB	0ffh,0cdh,0eeh,0fdh,0feh,2eh,20h,02h,37h,0c9h,0feh,08h,28h,21h,0feh,0dh	;...... .7...(!..
0D6E                       DEFB	28h,33h,4fh,3ah,5eh,0ffh,0b7h,28h,0e8h,0f5h,0c5h,79h,0cdh,62h,0f8h,0c1h	;(3O:^..(...y.b..
0D7E                       DEFB	0f1h,5fh,16h,00h,3dh,32h,5eh,0ffh,21h,6dh,0ffh,19h,71h,18h,0d2h,3ah	;._..=2^.!m..q..:
0D8E                       DEFB	5eh,0ffh,0feh,02h,28h,0cbh,3eh,08h,0cdh,62h,0f8h,3ah,5eh,0ffh,3ch,3ch	;^...(.>..b.:^.<<
0D9E                       DEFB	5fh,0eh,30h,18h,0ddh,2ah,65h,0ffh,2bh,4eh,3ah,5eh,0ffh,0feh,02h,0c8h	;_.0..*e.+N:^....
0DAE                       DEFB	0feh,01h,3eh,00h,20h,06h,0f5h,3ah,6fh,0ffh,18h,0eh,3ah,6fh,0ffh,0cdh	;..>. ..:o...:o..
0DBE                       DEFB	84h,0feh,07h,07h,07h,07h,0f5h,3ah,6eh,0ffh,0cdh,84h,0feh,4fh,0f1h,81h	;.......:n....O..
0DCE                       DEFB	4fh,0afh,0c9h,0feh,3ah,38h,02h,0d6h,07h,0d6h,30h,0c9h,3eh,0ach,0d3h,5bh	;O...:8....0.>..[
0DDE                       DEFB	0dbh,5ah,3ch,0c4h,9ch,0feh,3eh,0ah,0c3h,62h,0f8h,21h,71h,0ffh,36h,0ah	;.Z<...>..b.!q.6.
0DEE                       DEFB	23h,0dbh,0fah,0f5h,0e6h,0fbh,0d3h,0fah,0cdh,00h,10h,0f1h,0d3h,0fah,06h,17h	;#...............
0DFE                       DEFB	2bh,0c3h,3ch,0fah,53h,70h,65h,69h,63h,68h,65h,72h,74h,65h,73h,74h	;+.<.Speichertest
0E0E                       DEFB	20h,42h,61h,6eh,6bh,3ah,20h,41h,20h,2fh,53h,70h,65h,69h,63h,68h	; Bank: A /Speich
0E1E                       DEFB	65h,72h,20h,64h,65h,66h,65h,6bh,74h,6bh,65h,69h,6eh,20h,42h,65h	;er defektkein Be
0E2E                       DEFB	66h,65h,68h,6ch,66h,61h,6ch,73h,63h,68h,65h,72h,20h,46h,75h,6eh	;fehlfalscher Fun
0E3E                       DEFB	6bh,74h,69h,6fh,6eh,73h,61h,75h,66h,72h,75h,66h,0ah,42h,61h,6eh	;ktionsaufruf.Ban
0E4E                       DEFB	6bh,20h,41h,2fh,30h,20h,73h,65h,6ch,65h,6bh,74h,69h,65h,72h,74h	;k A/0 selektiert
0E5E                       DEFB	20h,66h,61h,6ch,73h,63h,68h,65h,73h,20h,41h,72h,67h,75h,6dh,65h	; falsches Argume
0E6E                       DEFB	6eh,74h,0ah,42h,6fh,6fh,74h,2dh,46h,65h,68h,6ch,65h,72h,0ah,6bh	;nt.Boot-Fehler.k
0E7E                       DEFB	65h,69h,6eh,20h,53h,79h,73h,74h,65h,6dh,0ah,6bh,65h,69h,6eh,20h	;ein System.kein 
0E8E                       DEFB	42h,41h,53h,49h,43h,0dh,0dh,1fh,1fh,01h,01h,5bh,1bh,0ah,00h,08h	;BASIC......[....
0E9E                       DEFB	18h,09h,19h,20h,20h,00h,00h,00h,00h,00h,00h,01h,0eh,43h,41h,3dh	;...  ........CA=
0EAE                       DEFB	00h,00h,0fh,05h,00h,87h,00h,87h,00h,08h,00h,00h,00h,30h,30h,00h	;.............00.
0EBE                       DEFB	55h,77h,65h,20h,42h,7ch,6bh,65h,72h,20h,20h,20h,31h,39h,38h,34h	;Uwe B|ker   1984
0ECE                       DEFB	41h,72h,6eh,75h,6ch,66h,20h,53h,6fh,70h,70h,20h,31h,39h,38h,36h	;Arnulf Sopp 1986
0EDE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0EEE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0EFE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F0E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F1E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F2E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F3E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F4E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F5E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F6E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F7E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F8E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0F9E                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0FAE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0FBE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0FCE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0FDE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0FEE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
0FFE                       DEFB	0ffh,0ffh,0e5h,0fdh,21h,5bh,10h,3eh,6ch,0cdh,4ah,10h,0e6h,0fh,07h,11h	;....![.>l.J.....
100E                       DEFB	68h,10h,83h,5fh,2bh,0ebh,0edh,0a0h,0edh,0a0h,0ebh,0cdh,3fh,10h,01h,4ch	;h.._+.......?..L
101E                       DEFB	03h,11h,2eh,40h,0cdh,34h,10h,01h,5ch,03h,11h,3ah,00h,0cdh,34h,10h	;...@.4..\..:..4.
102E                       DEFB	2bh,2bh,36h,0dh,0e1h,0c9h,79h,82h,4fh,0cdh,46h,10h,73h,23h,10h,0f6h	;++6...y.O.F.s#..
103E                       DEFB	2bh,36h,2ch,23h,36h,20h,23h,0c9h,0cdh,49h,10h,79h,0d3h,5bh,0d6h,10h	;+6,#6 #..I.y.[..
104E                       DEFB	4fh,0dbh,5ah,0fdh,0a6h,00h,0f6h,30h,77h,23h,0fdh,23h,0c9h,07h,03h,0fh	;O.Z....0w#.#....
105E                       DEFB	01h,0fh,0fh,0fh,03h,0fh,07h,0fh,07h,0fh,4dh,6fh,44h,69h,4dh,69h	;..........MoDiMi
106E                       DEFB	44h,6fh,46h,72h,53h,61h,53h,6fh,0c5h,0d5h,0ebh,21h,00h,00h,1ah,13h	;DoFrSaSo...!....
107E                       DEFB	0feh,30h,38h,12h,0feh,3ah,30h,0eh,29h,44h,4dh,29h,29h,09h,0d6h,30h	;.08..:0.)DM))..0
108E                       DEFB	4fh,06h,00h,09h,18h,0e8h,0d1h,0c1h,0c9h,0fdh,0e5h,0d5h,0c5h,0f5h,0fdh,21h	;O..............!
109E                       DEFB	0dah,10h,0eh,00h,0ebh,0d5h,3eh,30h,0fdh,5eh,00h,0fdh,56h,01h,0b7h,0edh	;......>0.^..V...
10AE                       DEFB	52h,38h,03h,3ch,18h,0f8h,19h,0fdh,23h,0fdh,23h,0feh,30h,20h,08h,0ch	;R8.<....#.#.0 ..
10BE                       DEFB	0dh,20h,05h,3eh,20h,18h,01h,4fh,1dh,0d1h,12h,13h,20h,0d7h,0ch,0dh	;. .> ..O.... ...
10CE                       DEFB	20h,04h,1bh,3eh,30h,12h,0f1h,0c1h,0d1h,0fdh,0e1h,0c9h,10h,27h,0e8h,03h	; ..>0........'..
10DE                       DEFB	64h,00h,0ah,00h,01h,00h,1ah,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;d...............
10EE                       DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;................
10FE                       DEFB	0ffh,0ffh	;..
; =====================================================================
; omtidetect -- OMTI hard-disk detect/init/boot entry.
; This routine performs the controller probe and boot sequence and
; makes four accesses to port 41h (D3 41h/DB 41h) within its call tree.
; Sequence overview:
;   1. hotkey bits 0-1 set -> abandon to floppyforce (via omtiretry)
;   2. poll port 42h for FAh ('card present')
;   3. reset the bus (XOR A / OUT 41h,A / OUT 43h,A) -- BEFORE the
;      first command, never as a bare release with nothing following
;   4. TEST UNIT READY probe, up to 32 retries (turloop)
;   5. on success: SET DRIVE CHARACTERISTICS + verify (omtiverify ->
;      setdrivechar -> loadverify)
;   6. boot-sector READ, one block, cyl/head/sec 0/0/0, into 4200h
;      (bootsecload)
;   7. E=1, IX=4200h, JP back into the relocated device-dispatch body
; =====================================================================
1100  3A FF FF    omtidetect    LD	A,(0ffffh)
1103  E6 03                AND	3
; omtiretry -- hotkey-abort landing (falls through from the AND 3
; test above) and the presence-poll's own retry loop (JR NZ,
; omtiretry from 110Ch below).
1105  C2 00 38    omtiretry    JP	NZ,3800h
1108  DB 42                IN	A,(42h)
110A  FE FA                CP	0fah
110C  20 F7                JR	NZ,omtiretry
; PORT 41h WRITE (site 1 of 2): XOR A / OUT 41h / OUT 43h -- unconditional
; bus reset, issued after confirming card presence and before the
; first command (TEST UNIT READY). The routine then proceeds to send
; the TEST UNIT READY command and handle retries as necessary.
110E  AF                   XOR	A
110F  D3 41                OUT	(41h),A
1111  D3 43                OUT	(43h),A
; D=20h (32 retries). HL=TEST-UNIT-READY CDB template (at the DEFB
; block just before cdbsend's own definition, 11BCh: opcode C=00h is
; supplied by the caller via BC below, NOT read from this template --
; the template supplies only CDB bytes 1-5, via OTIR inside cdbsend).
1113  16 20                LD	D,20h
; turloop -- BC=0500h: C=00h is CDB byte 0 (TEST_UNIT_READY opcode,
; matches TRS_OMTI_TEST_UNIT_READY=0x00 in trs_omti.h exactly), B=05h
; is the OTIR count for the remaining 5 bytes cdbsend bursts from HL
; (11BCh). CALL cdbsend (select + send CDB), CALL waitreq, then poll
; port 40h bit 5 for the result; on failure (nonzero), retry via
; delay65536-style spin (CALL 11DCh helper) up to D=32
; times, else give up to floppyforce (JP 3800h, via the relocated
; copy).
1115  21 BC 11    turloop    LD	HL,11bch
1118  01 00 05             LD	BC,0500h
111B  D5                   PUSH	DE
111C  CD 75 11             CALL	cdbsend
111F  CD 85 11             CALL	waitreq
1122  D1                   POP	DE
1123  DB 40                IN	A,(40h)
1125  CB AF                RES	5,A
1127  B7                   OR	A
1128  28 09                JR	Z,omtiverify
112A  CD DC 11             CALL	delay65536
112D  15                   DEC	D
112E  20 E5                JR	NZ,turloop
1130  C3 00 38             JP	3800h
; omtiverify -- on TEST UNIT READY success: CALL setdrivechar (issues
; SET DRIVE CHARACTERISTICS, 1191h), CALL loadverify (issues the boot-
; sector READ and validates it, 1144h). NZ from either -> retry the
; whole sequence from omtiretry (1105h).
1133  CD 91 11    omtiverify    CALL	setdrivechar
1136  CD 44 11             CALL	loadverify
1139  20 CA                JR	NZ,omtiretry
; *** Success. *** E=01h (hard-disk boot-device selector), IX=4200h
; (the hand-off address). JP 382Eh follows; 382Eh is RAM mapping to
; ROM 0096h (mid-devinit) and is the entry used for the OMTI hand-off.
113B  1E 01                LD	E,1
113D  DD 21 00 42          LD	IX,4200h
1141  C3 2E 38             JP	382eh
; =====================================================================
; loadverify -- issues the boot-sector READ CDB (opcode C=08h =
; TRS_OMTI_READ, BC=0508h; remaining 5 bytes from the DEFB block at
; 118Ch: 00 00 00 01 02 -> LUN 0, cyl 0, head 0, sec 0, BLOCK COUNT
; 01h -- one sector, matching bootsec.asm's header comment.
; CALL cdbsend, CALL waitreq, then *** PORT 41h READ, SITE 2 of 2
; MEANINGFUL READS *** (site 3 below is inside waitreq itself, called
; everywhere): IN A,41h / BIT 2,A tests the C/D phase bit (matches
; the omtcd) after the CDB -- if the controller has already gone to
; status instead of data (JP NZ,transferexit, 1174h), something is
; wrong; otherwise falls into bootsecload to
; actually stream the sector.
; =====================================================================
1144  21 8C 11    loadverify    LD	HL,118ch
1147  01 08 05             LD	BC,0508h
114A  CD 75 11             CALL	cdbsend
114D  CD 85 11             CALL	waitreq
1150  DB 41                IN	A,(41h)
1152  CB 57                BIT	2,A
1154  C2 74 11             JP	NZ,transferexit
; bootsecload -- HL=4200h, BC=0040h. This is NOT "64 bytes per INI" --
; 01 40 00 loads B=00h, C=40h: C is the I/O port (40h), matching
; cdbsend's LD C,40h; B=00h is INI's block counter and is treated as
; 256 by INI/OTIR-family instructions (B decrements from 00h to FFh).
; D=2 runs that 256-byte pass twice (256 x 2 = 512 bytes total), so
; the sector is streamed into 4200h via INI (block input).
; *** 4200h is the buffer used for the boot sector (m4200 / 'DOS-Sektorpuffer').
; The ROM's first disk read lands at 4200h, so it is used as a shared
; buffer rather than a private scratch area. See bootsec.asm lines 210-226 for context.
1157  21 00 42    bootsecload    LD	HL,4200h
115A  01 40 00             LD	BC,0040h
115D  16 02                LD	D,2
; bootsecload_loop -- CALL waitreq, INI, retry until D exhausted;
; then CALL waitreq once more, read the final status byte (port 40h,
; not 41h -- this matches the hdend read of phase=STATUS), BIT 1,A
; tests for error, JP NZ,transferexit on failure else XOR A (success)
; and fall into transferexit.
115F  CD 85 11    bootsecload_loop    CALL	waitreq
1162  ED A2                INI
1164  20 F9                JR	NZ,bootsecload_loop
1166  15                   DEC	D
1167  20 F6                JR	NZ,bootsecload_loop
1169  CD 85 11             CALL	waitreq
116C  DB 40                IN	A,(40h)
116E  CB 4F                BIT	1,A
1170  C2 74 11             JP	NZ,transferexit
1173  AF                   XOR	A
; transferexit -- shared RET, success (A=0) or failure (A<>0,
; carried from whichever caller jumped here) alike; the caller's own
; JR NZ/JR Z after CALLing into this region is what actually branches
; on the outcome.
1174  C9          transferexit    RET
; =====================================================================
; cdbsend -- combined SELECT-strobe + CDB routine.
;   OUT 42h,A       -- SELECT strobe (A = caller's LUN/select value)
;   CALL waitreq    -- wait for REQ
;   LD A,C / OUT 40h,A -- CDB byte 0 (opcode), from C
;   LD C,40h
;   CALL waitreq    -- wait for REQ again
;   OTIR            -- burst the remaining B bytes from (HL) (no per-byte REQ check)
; =====================================================================
1175  D3 42       cdbsend    OUT	(42h),A
1177  CD 85 11             CALL	waitreq
117A  79                   LD	A,C
117B  D3 40                OUT	(40h),A
117D  0E 40                LD	C,40h
117F  CD 85 11             CALL	waitreq
1182  ED B3                OTIR
1184  C9                   RET
; =====================================================================
; waitreq -- *** PORT 41h READ, the constant-polling site (3rd of 4
; total accesses, but by far the most frequently executed -- every
; CDB send and every burst waits here). *** IN A,41h / BIT 0,A / JR
; Z,waitreq -- spins until REQ (bit 0) is set. Direct structural
; equivalent of hdreq (omti.asm:126-151), except this ROM version has
; no timeout (an unbounded spin) while hdreq implements a bounded
; DE/BC countdown — a notable difference.
; =====================================================================
1185  DB 41       waitreq    IN	A,(41h)
1187  CB 47                BIT	0,A
1189  28 FA                JR	Z,waitreq
118B  C9                   RET
118C                       DEFB	00h,00h,00h,01h,02h	;.....
; =====================================================================
; setdrivechar -- issues SET DRIVE CHARACTERISTICS (opcode 0Ch,
; matches TRS_OMTI_SET_CHARACTERISTICS). *** PORT 41h WRITE, SITE 2
; of 2 in the whole ROM. *** XOR A / OUT 41h,A / OUT 43h,A --
; unconditional reset, issued immediately BEFORE this command's own
; CDB is sent (CALL cdbsend at 119Fh) -- same shape as site 1 (110Eh):
; reset then command, never reset alone.
; CDB: opcode C=0Ch, BC=050Ch, 5 more bytes from 11BCh (the SAME
; template turloop's own TEST UNIT READY used for its own 5 bytes --
; reused, not a separate template).
; PAYLOAD (8-byte OTIR from 11B5h, B=8): 02 64 02 00 00 01 2C 00.
; Decoded per TRS_OMTI_CHAR_CYLHI/CYLLO/HEADS (trs_omti.h):
;   cylinder count = 0264h = 612
;   head count     = 02h   = 2
;   precomp cyl    = 012Ch = 300
; This is a 612 x 2 x 17 = 20,808-sector characteristics block.
; That total also matches a 306 x 4 x 17 configuration, which is a
; valid jumper-selectable alternative on Tandon drives such as the TM252.
; The ROM payload encodes the 612-cylinder, 2-head variant, however, so
; total-sector coincidence alone is not proof that it is using the 306x4
; physical geometry. 
; It differs from the ST225 model used by the
; current .hdv images (615/4/17, 41,820 sectors). See repository
; documentation for the drive-geometry discussion.
; After the payload: CALL reqsense_maybe (11AEh) -- a follow-up check,
; not fully characterised this session.
; =====================================================================
1191  AF          setdrivechar    XOR	A
1192  D3 41                OUT	(41h),A
1194  D3 43                OUT	(43h),A
1196  E5                   PUSH	HL
1197  D5                   PUSH	DE
1198  C5                   PUSH	BC
1199  21 BC 11             LD	HL,11bch
119C  01 0C 05             LD	BC,050ch
119F  CD 75 11             CALL	cdbsend
11A2  06 08                LD	B,8
11A4  21 B5 11             LD	HL,11b5h
11A7  0E 40                LD	C,40h
11A9  CD 85 11             CALL	waitreq
11AC  ED B3                OTIR
11AE  CD C2 11             CALL	reqsense_maybe
11B1  C1                   POP	BC
11B2  D1                   POP	DE
11B3  E1                   POP	HL
11B4  C9                   RET
11B5                       DEFB	02h,64h,02h,00h,00h,01h,2ch,00h,00h,00h,00h,00h,01h	;.d....,......
; reqsense_maybe -- CALL waitreq, IN A,40h, BIT 1,A: if clear, falls
; through to reqsense_clean (XOR A/RET, success). If set, sends a
; THIRD CDB (BC=0503h, opcode C=03h = TRS_OMTI_REQUEST_SENSE, 3 more
; bytes from 11BDh -- note: NOT 11BCh, one byte further into the same
; template block, so this reuses bytes 1-3 of the TEST-UNIT-READY/SET-
; CHARACTERISTICS template rather than a distinct one) via cdbsend.
; Name is a best-guess from the opcode and the bit-1-set trigger
; (the SASI convention of following an error indication with REQUEST
; SENSE); not confirmed against a REQUEST SENSE payload.
11C2  CD 85 11    reqsense_maybe    CALL	waitreq
11C5  DB 40                IN	A,(40h)
11C7  CB 4F                BIT	1,A
11C9  28 0F                JR	Z,reqsense_clean
11CB  E5                   PUSH	HL
11CC  D5                   PUSH	DE
11CD  C5                   PUSH	BC
11CE  21 BD 11             LD	HL,11bdh
11D1  01 03 05             LD	BC,0503h
11D4  CD 75 11             CALL	cdbsend
11D7  C1                   POP	BC
11D8  D1                   POP	DE
11D9  E1                   POP	HL
; reqsense_clean -- XOR A / RET: success exit for reqsense_maybe when
; the checked bit was already clear.
11DA  AF          reqsense_clean    XOR	A
11DB  C9                   RET
; NOTE: 'LD BC,coldstart' below is the same naming coincidence flagged
; at ixselect (0079h) -- this is 'LD BC,0000h', an immediate value
; (65536 as an unsigned 16-bit countdown), not a jump/reference to the
; coldstart routine.
; delay65536 -- BC=0000h, decrement to 0 (65536 iterations), a plain
; busy-wait. No confirmed caller in the traced flow; may be unused
; (the ROM immediately past it, from 11E5h, is a run of 0xFF bytes
; consistent with unused space).
11DC  01 00 00    delay65536    LD	BC,coldstart
11DF  0B          delay65536_loop    DEC	BC
11E0  78                   LD	A,B
11E1  B1                   OR	C
11E2  C8                   RET	Z
11E3  18 FA                JR	delay65536_loop
11E5  FF                   RST	38h
11E6  FF                   RST	38h
11E7  FF                   RST	38h
11E8  FF                   RST	38h
11E9  FF                   RST	38h
11EA  FF                   RST	38h
11EB  FF                   RST	38h
11EC  FF                   RST	38h
11ED  FF                   RST	38h
11EE  FF                   RST	38h
11EF  FF                   RST	38h
11F0  FF                   RST	38h
11F1  FF                   RST	38h
11F2  FF                   RST	38h
11F3  FF                   RST	38h
11F4  FF                   RST	38h
11F5  FF                   RST	38h
11F6  FF                   RST	38h
11F7  FF                   RST	38h
11F8  FF                   RST	38h
11F9  FF                   RST	38h
11FA  FF                   RST	38h
11FB  FF                   RST	38h
11FC  FF                   RST	38h
11FD  FF                   RST	38h
11FE  FF                   RST	38h
11FF  FF                   RST	38h
1200  FF                   RST	38h
1201  FF                   RST	38h
1202  FF                   RST	38h
1203  FF                   RST	38h
1204  FF                   RST	38h
1205  FF                   RST	38h
1206  FF                   RST	38h
1207  FF                   RST	38h
1208  FF                   RST	38h
1209  FF                   RST	38h
120A  FF                   RST	38h
120B  FF                   RST	38h
120C  FF                   RST	38h
120D  FF                   RST	38h
120E  FF                   RST	38h
120F  FF                   RST	38h
1210  FF                   RST	38h
1211  FF                   RST	38h
1212  FF                   RST	38h
1213  FF                   RST	38h
1214  FF                   RST	38h
1215  FF                   RST	38h
1216  FF                   RST	38h
1217  FF                   RST	38h
1218  FF                   RST	38h
1219  FF                   RST	38h
121A  FF                   RST	38h
121B  FF                   RST	38h
121C  FF                   RST	38h
121D  FF                   RST	38h
121E  FF                   RST	38h
121F  FF                   RST	38h
1220  FF                   RST	38h
1221  FF                   RST	38h
1222  FF                   RST	38h
1223  FF                   RST	38h
1224  FF                   RST	38h
1225  FF                   RST	38h
1226  FF                   RST	38h
1227  FF                   RST	38h
1228  FF                   RST	38h
1229  FF                   RST	38h
122A  FF                   RST	38h
122B  FF                   RST	38h
122C  FF                   RST	38h
122D  FF                   RST	38h
122E  FF                   RST	38h
122F  FF                   RST	38h
1230  FF                   RST	38h
1231  FF                   RST	38h
1232  FF                   RST	38h
1233  FF                   RST	38h
1234  FF                   RST	38h
1235  FF                   RST	38h
1236  FF                   RST	38h
1237  FF                   RST	38h
1238  FF                   RST	38h
1239  FF                   RST	38h
123A  FF                   RST	38h
123B  FF                   RST	38h
123C  FF                   RST	38h
123D  FF                   RST	38h
123E  FF                   RST	38h
123F  FF                   RST	38h
1240  FF                   RST	38h
1241  FF                   RST	38h
1242  FF                   RST	38h
1243  FF                   RST	38h
1244  FF                   RST	38h
1245  FF                   RST	38h
1246  FF                   RST	38h
1247  FF                   RST	38h
1248  FF                   RST	38h
1249  FF                   RST	38h
124A  FF                   RST	38h
124B  FF                   RST	38h
124C  FF                   RST	38h
124D  FF                   RST	38h
124E  FF                   RST	38h
124F  FF                   RST	38h
1250  FF                   RST	38h
1251  FF                   RST	38h
1252  FF                   RST	38h
1253  FF                   RST	38h
1254  FF                   RST	38h
1255  FF                   RST	38h
1256  FF                   RST	38h
1257  FF                   RST	38h
1258  FF                   RST	38h
1259  FF                   RST	38h
125A  FF                   RST	38h
125B  FF                   RST	38h
125C  FF                   RST	38h
125D  FF                   RST	38h
125E  FF                   RST	38h
125F  FF                   RST	38h
1260  FF                   RST	38h
1261  FF                   RST	38h
1262  FF                   RST	38h
1263  FF                   RST	38h
1264  FF                   RST	38h
1265  FF                   RST	38h
1266  FF                   RST	38h
1267  FF                   RST	38h
1268  FF                   RST	38h
1269  FF                   RST	38h
126A  FF                   RST	38h
126B  FF                   RST	38h
126C  FF                   RST	38h
126D  FF                   RST	38h
126E  FF                   RST	38h
126F  FF                   RST	38h
1270  FF                   RST	38h
1271  FF                   RST	38h
1272  FF                   RST	38h
1273  FF                   RST	38h
1274  FF                   RST	38h
1275  FF                   RST	38h
1276  FF                   RST	38h
1277  FF                   RST	38h
1278  FF                   RST	38h
1279  FF                   RST	38h
127A  FF                   RST	38h
127B  FF                   RST	38h
127C  FF                   RST	38h
127D  FF                   RST	38h
127E  FF                   RST	38h
127F  FF                   RST	38h
1280  FF                   RST	38h
1281  FF                   RST	38h
1282  FF                   RST	38h
1283  FF                   RST	38h
1284  FF                   RST	38h
1285  FF                   RST	38h
1286  FF                   RST	38h
1287  FF                   RST	38h
1288  FF                   RST	38h
1289  FF                   RST	38h
128A  FF                   RST	38h
128B  FF                   RST	38h
128C  FF                   RST	38h
128D  FF                   RST	38h
128E  FF                   RST	38h
128F  FF                   RST	38h
1290  FF                   RST	38h
1291  FF                   RST	38h
1292  FF                   RST	38h
1293  FF                   RST	38h
1294  FF                   RST	38h
1295  FF                   RST	38h
1296  FF                   RST	38h
1297  FF                   RST	38h
1298  FF                   RST	38h
1299  FF                   RST	38h
129A  FF                   RST	38h
129B  FF                   RST	38h
129C  FF                   RST	38h
129D  FF                   RST	38h
129E  FF                   RST	38h
129F  FF                   RST	38h
12A0  FF                   RST	38h
12A1  FF                   RST	38h
12A2  FF                   RST	38h
12A3  FF                   RST	38h
12A4  FF                   RST	38h
12A5  FF                   RST	38h
12A6  FF                   RST	38h
12A7  FF                   RST	38h
12A8  FF                   RST	38h
12A9  FF                   RST	38h
12AA  FF                   RST	38h
12AB  FF                   RST	38h
12AC  FF                   RST	38h
12AD  FF                   RST	38h
12AE  FF                   RST	38h
12AF  FF                   RST	38h
12B0  FF                   RST	38h
12B1  FF                   RST	38h
12B2  FF                   RST	38h
12B3  FF                   RST	38h
12B4  FF                   RST	38h
12B5  FF                   RST	38h
12B6  FF                   RST	38h
12B7  FF                   RST	38h
12B8  FF                   RST	38h
12B9  FF                   RST	38h
12BA  FF                   RST	38h
12BB  FF                   RST	38h
12BC  FF                   RST	38h
12BD  FF                   RST	38h
12BE  FF                   RST	38h
12BF  FF                   RST	38h
12C0  FF                   RST	38h
12C1  FF                   RST	38h
12C2  FF                   RST	38h
12C3  FF                   RST	38h
12C4  FF                   RST	38h
12C5  FF                   RST	38h
12C6  FF                   RST	38h
12C7  FF                   RST	38h
12C8  FF                   RST	38h
12C9  FF                   RST	38h
12CA  FF                   RST	38h
12CB  FF                   RST	38h
12CC  FF                   RST	38h
12CD  FF                   RST	38h
12CE  FF                   RST	38h
12CF  FF                   RST	38h
12D0  FF                   RST	38h
12D1  FF                   RST	38h
12D2  FF                   RST	38h
12D3  FF                   RST	38h
12D4  FF                   RST	38h
12D5  FF                   RST	38h
12D6  FF                   RST	38h
12D7  FF                   RST	38h
12D8  FF                   RST	38h
12D9  FF                   RST	38h
12DA  FF                   RST	38h
12DB  FF                   RST	38h
12DC  FF                   RST	38h
12DD  FF                   RST	38h
12DE  FF                   RST	38h
12DF  FF                   RST	38h
12E0  FF                   RST	38h
12E1  FF                   RST	38h
12E2  FF                   RST	38h
12E3  FF                   RST	38h
12E4  FF                   RST	38h
12E5  FF                   RST	38h
12E6  FF                   RST	38h
12E7  FF                   RST	38h
12E8  FF                   RST	38h
12E9  FF                   RST	38h
12EA  FF                   RST	38h
12EB  FF                   RST	38h
12EC  FF                   RST	38h
12ED  FF                   RST	38h
12EE  FF                   RST	38h
12EF  FF                   RST	38h
12F0  FF                   RST	38h
12F1  FF                   RST	38h
12F2  FF                   RST	38h
12F3  FF                   RST	38h
12F4  FF                   RST	38h
12F5  FF                   RST	38h
12F6  FF                   RST	38h
12F7  FF                   RST	38h
12F8  FF                   RST	38h
12F9  FF                   RST	38h
12FA  FF                   RST	38h
12FB  FF                   RST	38h
12FC  FF                   RST	38h
12FD  FF                   RST	38h
12FE  FF                   RST	38h
12FF  FF                   RST	38h
1300  FF                   RST	38h
1301  FF                   RST	38h
1302  FF                   RST	38h
1303  FF                   RST	38h
1304  FF                   RST	38h
1305  FF                   RST	38h
1306  FF                   RST	38h
1307  FF                   RST	38h
1308  FF                   RST	38h
1309  FF                   RST	38h
130A  FF                   RST	38h
130B  FF                   RST	38h
130C  FF                   RST	38h
130D  FF                   RST	38h
130E  FF                   RST	38h
130F  FF                   RST	38h
1310  FF                   RST	38h
1311  FF                   RST	38h
1312  FF                   RST	38h
1313  FF                   RST	38h
1314  FF                   RST	38h
1315  FF                   RST	38h
1316  FF                   RST	38h
1317  FF                   RST	38h
1318  FF                   RST	38h
1319  FF                   RST	38h
131A  FF                   RST	38h
131B  FF                   RST	38h
131C  FF                   RST	38h
131D  FF                   RST	38h
131E  FF                   RST	38h
131F  FF                   RST	38h
1320  FF                   RST	38h
1321  FF                   RST	38h
1322  FF                   RST	38h
1323  FF                   RST	38h
1324  FF                   RST	38h
1325  FF                   RST	38h
1326  FF                   RST	38h
1327  FF                   RST	38h
1328  FF                   RST	38h
1329  FF                   RST	38h
132A  FF                   RST	38h
132B  FF                   RST	38h
132C  FF                   RST	38h
132D  FF                   RST	38h
132E  FF                   RST	38h
132F  FF                   RST	38h
1330  FF                   RST	38h
1331  FF                   RST	38h
1332  FF                   RST	38h
1333  FF                   RST	38h
1334  FF                   RST	38h
1335  FF                   RST	38h
1336  FF                   RST	38h
1337  FF                   RST	38h
1338  FF                   RST	38h
1339  FF                   RST	38h
133A  FF                   RST	38h
133B  FF                   RST	38h
133C  FF                   RST	38h
133D  FF                   RST	38h
133E  FF                   RST	38h
133F  FF                   RST	38h
1340  FF                   RST	38h
1341  FF                   RST	38h
1342  FF                   RST	38h
1343  FF                   RST	38h
1344  FF                   RST	38h
1345  FF                   RST	38h
1346  FF                   RST	38h
1347  FF                   RST	38h
1348  FF                   RST	38h
1349  FF                   RST	38h
134A  FF                   RST	38h
134B  FF                   RST	38h
134C  FF                   RST	38h
134D  FF                   RST	38h
134E  FF                   RST	38h
134F  FF                   RST	38h
1350  FF                   RST	38h
1351  FF                   RST	38h
1352  FF                   RST	38h
1353  FF                   RST	38h
1354  FF                   RST	38h
1355  FF                   RST	38h
1356  FF                   RST	38h
1357  FF                   RST	38h
1358  FF                   RST	38h
1359  FF                   RST	38h
135A  FF                   RST	38h
135B  FF                   RST	38h
135C  FF                   RST	38h
135D  FF                   RST	38h
135E  FF                   RST	38h
135F  FF                   RST	38h
1360  FF                   RST	38h
1361  FF                   RST	38h
1362  FF                   RST	38h
1363  FF                   RST	38h
1364  FF                   RST	38h
1365  FF                   RST	38h
1366  FF                   RST	38h
1367  FF                   RST	38h
1368  FF                   RST	38h
1369  FF                   RST	38h
136A  FF                   RST	38h
136B  FF                   RST	38h
136C  FF                   RST	38h
136D  FF                   RST	38h
136E  FF                   RST	38h
136F  FF                   RST	38h
1370  FF                   RST	38h
1371  FF                   RST	38h
1372  FF                   RST	38h
1373  FF                   RST	38h
1374  FF                   RST	38h
1375  FF                   RST	38h
1376  FF                   RST	38h
1377  FF                   RST	38h
1378  FF                   RST	38h
1379  FF                   RST	38h
137A  FF                   RST	38h
137B  FF                   RST	38h
137C  FF                   RST	38h
137D  FF                   RST	38h
137E  FF                   RST	38h
137F  FF                   RST	38h
1380  FF                   RST	38h
1381  FF                   RST	38h
1382  FF                   RST	38h
1383  FF                   RST	38h
1384  FF                   RST	38h
1385  FF                   RST	38h
1386  FF                   RST	38h
1387  FF                   RST	38h
1388  FF                   RST	38h
1389  FF                   RST	38h
138A  FF                   RST	38h
138B  FF                   RST	38h
138C  FF                   RST	38h
138D  FF                   RST	38h
138E  FF                   RST	38h
138F  FF                   RST	38h
1390  FF                   RST	38h
1391  FF                   RST	38h
1392  FF                   RST	38h
1393  FF                   RST	38h
1394  FF                   RST	38h
1395  FF                   RST	38h
1396  FF                   RST	38h
1397  FF                   RST	38h
1398  FF                   RST	38h
1399  FF                   RST	38h
139A  FF                   RST	38h
139B  FF                   RST	38h
139C  FF                   RST	38h
139D  FF                   RST	38h
139E  FF                   RST	38h
139F  FF                   RST	38h
13A0  FF                   RST	38h
13A1  FF                   RST	38h
13A2  FF                   RST	38h
13A3  FF                   RST	38h
13A4  FF                   RST	38h
13A5  FF                   RST	38h
13A6  FF                   RST	38h
13A7  FF                   RST	38h
13A8  FF                   RST	38h
13A9  FF                   RST	38h
13AA  FF                   RST	38h
13AB  FF                   RST	38h
13AC  FF                   RST	38h
13AD  FF                   RST	38h
13AE  FF                   RST	38h
13AF  FF                   RST	38h
13B0  FF                   RST	38h
13B1  FF                   RST	38h
13B2  FF                   RST	38h
13B3  FF                   RST	38h
13B4  FF                   RST	38h
13B5  FF                   RST	38h
13B6  FF                   RST	38h
13B7  FF                   RST	38h
13B8  FF                   RST	38h
13B9  FF                   RST	38h
13BA  FF                   RST	38h
13BB  FF                   RST	38h
13BC  FF                   RST	38h
13BD  FF                   RST	38h
13BE  FF                   RST	38h
13BF  FF                   RST	38h
13C0  FF                   RST	38h
13C1  FF                   RST	38h
13C2  FF                   RST	38h
13C3  FF                   RST	38h
13C4  FF                   RST	38h
13C5  FF                   RST	38h
13C6  FF                   RST	38h
13C7  FF                   RST	38h
13C8  FF                   RST	38h
13C9  FF                   RST	38h
13CA  FF                   RST	38h
13CB  FF                   RST	38h
13CC  FF                   RST	38h
13CD  FF                   RST	38h
13CE  FF                   RST	38h
13CF  FF                   RST	38h
13D0  FF                   RST	38h
13D1  FF                   RST	38h
13D2  FF                   RST	38h
13D3  FF                   RST	38h
13D4  FF                   RST	38h
13D5  FF                   RST	38h
13D6  FF                   RST	38h
13D7  FF                   RST	38h
13D8  FF                   RST	38h
13D9  FF                   RST	38h
13DA  FF                   RST	38h
13DB  FF                   RST	38h
13DC  FF                   RST	38h
13DD  FF                   RST	38h
13DE  FF                   RST	38h
13DF  FF                   RST	38h
13E0  FF                   RST	38h
13E1  FF                   RST	38h
13E2  FF                   RST	38h
13E3  FF                   RST	38h
13E4  FF                   RST	38h
13E5  FF                   RST	38h
13E6  FF                   RST	38h
13E7  FF                   RST	38h
13E8  FF                   RST	38h
13E9  FF                   RST	38h
13EA  FF                   RST	38h
13EB  FF                   RST	38h
13EC  FF                   RST	38h
13ED  FF                   RST	38h
13EE  FF                   RST	38h
13EF  FF                   RST	38h
13F0  FF                   RST	38h
13F1  FF                   RST	38h
13F2  FF                   RST	38h
13F3  FF                   RST	38h
13F4  FF                   RST	38h
13F5  FF                   RST	38h
13F6  FF                   RST	38h
13F7  FF                   RST	38h
13F8  FF                   RST	38h
13F9  FF                   RST	38h
13FA  FF                   RST	38h
13FB  FF                   RST	38h
13FC  FF                   RST	38h
13FD  FF                   RST	38h
13FE  FF                   RST	38h
13FF  FF                   RST	38h
1400  FF                   RST	38h
1401  FF                   RST	38h
1402  FF                   RST	38h
1403  FF                   RST	38h
1404  FF                   RST	38h
1405  FF                   RST	38h
1406  FF                   RST	38h
1407  FF                   RST	38h
1408  FF                   RST	38h
1409  FF                   RST	38h
140A  FF                   RST	38h
140B  FF                   RST	38h
140C  FF                   RST	38h
140D  FF                   RST	38h
140E  FF                   RST	38h
140F  FF                   RST	38h
1410  FF                   RST	38h
1411  FF                   RST	38h
1412  FF                   RST	38h
1413  FF                   RST	38h
1414  FF                   RST	38h
1415  FF                   RST	38h
1416  FF                   RST	38h
1417  FF                   RST	38h
1418  FF                   RST	38h
1419  FF                   RST	38h
141A  FF                   RST	38h
141B  FF                   RST	38h
141C  FF                   RST	38h
141D  FF                   RST	38h
141E  FF                   RST	38h
141F  FF                   RST	38h
1420  FF                   RST	38h
1421  FF                   RST	38h
1422  FF                   RST	38h
1423  FF                   RST	38h
1424  FF                   RST	38h
1425  FF                   RST	38h
1426  FF                   RST	38h
1427  FF                   RST	38h
1428  FF                   RST	38h
1429  FF                   RST	38h
142A  FF                   RST	38h
142B  FF                   RST	38h
142C  FF                   RST	38h
142D  FF                   RST	38h
142E  FF                   RST	38h
142F  FF                   RST	38h
1430  FF                   RST	38h
1431  FF                   RST	38h
1432  FF                   RST	38h
1433  FF                   RST	38h
1434  FF                   RST	38h
1435  FF                   RST	38h
1436  FF                   RST	38h
1437  FF                   RST	38h
1438  FF                   RST	38h
1439  FF                   RST	38h
143A  FF                   RST	38h
143B  FF                   RST	38h
143C  FF                   RST	38h
143D  FF                   RST	38h
143E  FF                   RST	38h
143F  FF                   RST	38h
1440  FF                   RST	38h
1441  FF                   RST	38h
1442  FF                   RST	38h
1443  FF                   RST	38h
1444  FF                   RST	38h
1445  FF                   RST	38h
1446  FF                   RST	38h
1447  FF                   RST	38h
1448  FF                   RST	38h
1449  FF                   RST	38h
144A  FF                   RST	38h
144B  FF                   RST	38h
144C  FF                   RST	38h
144D  FF                   RST	38h
144E  FF                   RST	38h
144F  FF                   RST	38h
1450  FF                   RST	38h
1451  FF                   RST	38h
1452  FF                   RST	38h
1453  FF                   RST	38h
1454  FF                   RST	38h
1455  FF                   RST	38h
1456  FF                   RST	38h
1457  FF                   RST	38h
1458  FF                   RST	38h
1459  FF                   RST	38h
145A  FF                   RST	38h
145B  FF                   RST	38h
145C  FF                   RST	38h
145D  FF                   RST	38h
145E  FF                   RST	38h
145F  FF                   RST	38h
1460  FF                   RST	38h
1461  FF                   RST	38h
1462  FF                   RST	38h
1463  FF                   RST	38h
1464  FF                   RST	38h
1465  FF                   RST	38h
1466  FF                   RST	38h
1467  FF                   RST	38h
1468  FF                   RST	38h
1469  FF                   RST	38h
146A  FF                   RST	38h
146B  FF                   RST	38h
146C  FF                   RST	38h
146D  FF                   RST	38h
146E  FF                   RST	38h
146F  FF                   RST	38h
1470  FF                   RST	38h
1471  FF                   RST	38h
1472  FF                   RST	38h
1473  FF                   RST	38h
1474  FF                   RST	38h
1475  FF                   RST	38h
1476  FF                   RST	38h
1477  FF                   RST	38h
1478  FF                   RST	38h
1479  FF                   RST	38h
147A  FF                   RST	38h
147B  FF                   RST	38h
147C  FF                   RST	38h
147D  FF                   RST	38h
147E  FF                   RST	38h
147F  FF                   RST	38h
1480  FF                   RST	38h
1481  FF                   RST	38h
1482  FF                   RST	38h
1483  FF                   RST	38h
1484  FF                   RST	38h
1485  FF                   RST	38h
1486  FF                   RST	38h
1487  FF                   RST	38h
1488  FF                   RST	38h
1489  FF                   RST	38h
148A  FF                   RST	38h
148B  FF                   RST	38h
148C  FF                   RST	38h
148D  FF                   RST	38h
148E  FF                   RST	38h
148F  FF                   RST	38h
1490  FF                   RST	38h
1491  FF                   RST	38h
1492  FF                   RST	38h
1493  FF                   RST	38h
1494  FF                   RST	38h
1495  FF                   RST	38h
1496  FF                   RST	38h
1497  FF                   RST	38h
1498  FF                   RST	38h
1499  FF                   RST	38h
149A  FF                   RST	38h
149B  FF                   RST	38h
149C  FF                   RST	38h
149D  FF                   RST	38h
149E  FF                   RST	38h
149F  FF                   RST	38h
14A0  FF                   RST	38h
14A1  FF                   RST	38h
14A2  FF                   RST	38h
14A3  FF                   RST	38h
14A4  FF                   RST	38h
14A5  FF                   RST	38h
14A6  FF                   RST	38h
14A7  FF                   RST	38h
14A8  FF                   RST	38h
14A9  FF                   RST	38h
14AA  FF                   RST	38h
14AB  FF                   RST	38h
14AC  FF                   RST	38h
14AD  FF                   RST	38h
14AE  FF                   RST	38h
14AF  FF                   RST	38h
14B0  FF                   RST	38h
14B1  FF                   RST	38h
14B2  FF                   RST	38h
14B3  FF                   RST	38h
14B4  FF                   RST	38h
14B5  FF                   RST	38h
14B6  FF                   RST	38h
14B7  FF                   RST	38h
14B8  FF                   RST	38h
14B9  FF                   RST	38h
14BA  FF                   RST	38h
14BB  FF                   RST	38h
14BC  FF                   RST	38h
14BD  FF                   RST	38h
14BE  FF                   RST	38h
14BF  FF                   RST	38h
14C0  FF                   RST	38h
14C1  FF                   RST	38h
14C2  FF                   RST	38h
14C3  FF                   RST	38h
14C4  FF                   RST	38h
14C5  FF                   RST	38h
14C6  FF                   RST	38h
14C7  FF                   RST	38h
14C8  FF                   RST	38h
14C9  FF                   RST	38h
14CA  FF                   RST	38h
14CB  FF                   RST	38h
14CC  FF                   RST	38h
14CD  FF                   RST	38h
14CE  FF                   RST	38h
14CF  FF                   RST	38h
14D0  FF                   RST	38h
14D1  FF                   RST	38h
14D2  FF                   RST	38h
14D3  FF                   RST	38h
14D4  FF                   RST	38h
14D5  FF                   RST	38h
14D6  FF                   RST	38h
14D7  FF                   RST	38h
14D8  FF                   RST	38h
14D9  FF                   RST	38h
14DA  FF                   RST	38h
14DB  FF                   RST	38h
14DC  FF                   RST	38h
14DD  FF                   RST	38h
14DE  FF                   RST	38h
14DF  FF                   RST	38h
14E0  FF                   RST	38h
14E1  FF                   RST	38h
14E2  FF                   RST	38h
14E3  FF                   RST	38h
14E4  FF                   RST	38h
14E5  FF                   RST	38h
14E6  FF                   RST	38h
14E7  FF                   RST	38h
14E8  FF                   RST	38h
14E9  FF                   RST	38h
14EA  FF                   RST	38h
14EB  FF                   RST	38h
14EC  FF                   RST	38h
14ED  FF                   RST	38h
14EE  FF                   RST	38h
14EF  FF                   RST	38h
14F0  FF                   RST	38h
14F1  FF                   RST	38h
14F2  FF                   RST	38h
14F3  FF                   RST	38h
14F4  FF                   RST	38h
14F5  FF                   RST	38h
14F6  FF                   RST	38h
14F7  FF                   RST	38h
14F8  FF                   RST	38h
14F9  FF                   RST	38h
14FA  FF                   RST	38h
14FB  FF                   RST	38h
14FC  FF                   RST	38h
14FD  FF                   RST	38h
14FE  FF                   RST	38h
14FF  FF                   RST	38h
1500  FF                   RST	38h
1501  FF                   RST	38h
1502  FF                   RST	38h
1503  FF                   RST	38h
1504  FF                   RST	38h
1505  FF                   RST	38h
1506  FF                   RST	38h
1507  FF                   RST	38h
1508  FF                   RST	38h
1509  FF                   RST	38h
150A  FF                   RST	38h
150B  FF                   RST	38h
150C  FF                   RST	38h
150D  FF                   RST	38h
150E  FF                   RST	38h
150F  FF                   RST	38h
1510  FF                   RST	38h
1511  FF                   RST	38h
1512  FF                   RST	38h
1513  FF                   RST	38h
1514  FF                   RST	38h
1515  FF                   RST	38h
1516  FF                   RST	38h
1517  FF                   RST	38h
1518  FF                   RST	38h
1519  FF                   RST	38h
151A  FF                   RST	38h
151B  FF                   RST	38h
151C  FF                   RST	38h
151D  FF                   RST	38h
151E  FF                   RST	38h
151F  FF                   RST	38h
1520  FF                   RST	38h
1521  FF                   RST	38h
1522  FF                   RST	38h
1523  FF                   RST	38h
1524  FF                   RST	38h
1525  FF                   RST	38h
1526  FF                   RST	38h
1527  FF                   RST	38h
1528  FF                   RST	38h
1529  FF                   RST	38h
152A  FF                   RST	38h
152B  FF                   RST	38h
152C  FF                   RST	38h
152D  FF                   RST	38h
152E  FF                   RST	38h
152F  FF                   RST	38h
1530  FF                   RST	38h
1531  FF                   RST	38h
1532  FF                   RST	38h
1533  FF                   RST	38h
1534  FF                   RST	38h
1535  FF                   RST	38h
1536  FF                   RST	38h
1537  FF                   RST	38h
1538  FF                   RST	38h
1539  FF                   RST	38h
153A  FF                   RST	38h
153B  FF                   RST	38h
153C  FF                   RST	38h
153D  FF                   RST	38h
153E  FF                   RST	38h
153F  FF                   RST	38h
1540  FF                   RST	38h
1541  FF                   RST	38h
1542  FF                   RST	38h
1543  FF                   RST	38h
1544  FF                   RST	38h
1545  FF                   RST	38h
1546  FF                   RST	38h
1547  FF                   RST	38h
1548  FF                   RST	38h
1549  FF                   RST	38h
154A  FF                   RST	38h
154B  FF                   RST	38h
154C  FF                   RST	38h
154D  FF                   RST	38h
154E  FF                   RST	38h
154F  FF                   RST	38h
1550  FF                   RST	38h
1551  FF                   RST	38h
1552  FF                   RST	38h
1553  FF                   RST	38h
1554  FF                   RST	38h
1555  FF                   RST	38h
1556  FF                   RST	38h
1557  FF                   RST	38h
1558  FF                   RST	38h
1559  FF                   RST	38h
155A  FF                   RST	38h
155B  FF                   RST	38h
155C  FF                   RST	38h
155D  FF                   RST	38h
155E  FF                   RST	38h
155F  FF                   RST	38h
1560  FF                   RST	38h
1561  FF                   RST	38h
1562  FF                   RST	38h
1563  FF                   RST	38h
1564  FF                   RST	38h
1565  FF                   RST	38h
1566  FF                   RST	38h
1567  FF                   RST	38h
1568  FF                   RST	38h
1569  FF                   RST	38h
156A  FF                   RST	38h
156B  FF                   RST	38h
156C  FF                   RST	38h
156D  FF                   RST	38h
156E  FF                   RST	38h
156F  FF                   RST	38h
1570  FF                   RST	38h
1571  FF                   RST	38h
1572  FF                   RST	38h
1573  FF                   RST	38h
1574  FF                   RST	38h
1575  FF                   RST	38h
1576  FF                   RST	38h
1577  FF                   RST	38h
1578  FF                   RST	38h
1579  FF                   RST	38h
157A  FF                   RST	38h
157B  FF                   RST	38h
157C  FF                   RST	38h
157D  FF                   RST	38h
157E  FF                   RST	38h
157F  FF                   RST	38h
1580  FF                   RST	38h
1581  FF                   RST	38h
1582  FF                   RST	38h
1583  FF                   RST	38h
1584  FF                   RST	38h
1585  FF                   RST	38h
1586  FF                   RST	38h
1587  FF                   RST	38h
1588  FF                   RST	38h
1589  FF                   RST	38h
158A  FF                   RST	38h
158B  FF                   RST	38h
158C  FF                   RST	38h
158D  FF                   RST	38h
158E  FF                   RST	38h
158F  FF                   RST	38h
1590  FF                   RST	38h
1591  FF                   RST	38h
1592  FF                   RST	38h
1593  FF                   RST	38h
1594  FF                   RST	38h
1595  FF                   RST	38h
1596  FF                   RST	38h
1597  FF                   RST	38h
1598  FF                   RST	38h
1599  FF                   RST	38h
159A  FF                   RST	38h
159B  FF                   RST	38h
159C  FF                   RST	38h
159D  FF                   RST	38h
159E  FF                   RST	38h
159F  FF                   RST	38h
15A0  FF                   RST	38h
15A1  FF                   RST	38h
15A2  FF                   RST	38h
15A3  FF                   RST	38h
15A4  FF                   RST	38h
15A5  FF                   RST	38h
15A6  FF                   RST	38h
15A7  FF                   RST	38h
15A8  FF                   RST	38h
15A9  FF                   RST	38h
15AA  FF                   RST	38h
15AB  FF                   RST	38h
15AC  FF                   RST	38h
15AD  FF                   RST	38h
15AE  FF                   RST	38h
15AF  FF                   RST	38h
15B0  FF                   RST	38h
15B1  FF                   RST	38h
15B2  FF                   RST	38h
15B3  FF                   RST	38h
15B4  FF                   RST	38h
15B5  FF                   RST	38h
15B6  FF                   RST	38h
15B7  FF                   RST	38h
15B8  FF                   RST	38h
15B9  FF                   RST	38h
15BA  FF                   RST	38h
15BB  FF                   RST	38h
15BC  FF                   RST	38h
15BD  FF                   RST	38h
15BE  FF                   RST	38h
15BF  FF                   RST	38h
15C0  FF                   RST	38h
15C1  FF                   RST	38h
15C2  FF                   RST	38h
15C3  FF                   RST	38h
15C4  FF                   RST	38h
15C5  FF                   RST	38h
15C6  FF                   RST	38h
15C7  FF                   RST	38h
15C8  FF                   RST	38h
15C9  FF                   RST	38h
15CA  FF                   RST	38h
15CB  FF                   RST	38h
15CC  FF                   RST	38h
15CD  FF                   RST	38h
15CE  FF                   RST	38h
15CF  FF                   RST	38h
15D0  FF                   RST	38h
15D1  FF                   RST	38h
15D2  FF                   RST	38h
15D3  FF                   RST	38h
15D4  FF                   RST	38h
15D5  FF                   RST	38h
15D6  FF                   RST	38h
15D7  FF                   RST	38h
15D8  FF                   RST	38h
15D9  FF                   RST	38h
15DA  FF                   RST	38h
15DB  FF                   RST	38h
15DC  FF                   RST	38h
15DD  FF                   RST	38h
15DE  FF                   RST	38h
15DF  FF                   RST	38h
15E0  FF                   RST	38h
15E1  FF                   RST	38h
15E2  FF                   RST	38h
15E3  FF                   RST	38h
15E4  FF                   RST	38h
15E5  FF                   RST	38h
15E6  FF                   RST	38h
15E7  FF                   RST	38h
15E8  FF                   RST	38h
15E9  FF                   RST	38h
15EA  FF                   RST	38h
15EB  FF                   RST	38h
15EC  FF                   RST	38h
15ED  FF                   RST	38h
15EE  FF                   RST	38h
15EF  FF                   RST	38h
15F0  FF                   RST	38h
15F1  FF                   RST	38h
15F2  FF                   RST	38h
15F3  FF                   RST	38h
15F4  FF                   RST	38h
15F5  FF                   RST	38h
15F6  FF                   RST	38h
15F7  FF                   RST	38h
15F8  FF                   RST	38h
15F9  FF                   RST	38h
15FA  FF                   RST	38h
15FB  FF                   RST	38h
15FC  FF                   RST	38h
15FD  FF                   RST	38h
15FE  FF                   RST	38h
15FF  FF                   RST	38h
1600  FF                   RST	38h
1601  FF                   RST	38h
1602  FF                   RST	38h
1603  FF                   RST	38h
1604  FF                   RST	38h
1605  FF                   RST	38h
1606  FF                   RST	38h
1607  FF                   RST	38h
1608  FF                   RST	38h
1609  FF                   RST	38h
160A  FF                   RST	38h
160B  FF                   RST	38h
160C  FF                   RST	38h
160D  FF                   RST	38h
160E  FF                   RST	38h
160F  FF                   RST	38h
1610  FF                   RST	38h
1611  FF                   RST	38h
1612  FF                   RST	38h
1613  FF                   RST	38h
1614  FF                   RST	38h
1615  FF                   RST	38h
1616  FF                   RST	38h
1617  FF                   RST	38h
1618  FF                   RST	38h
1619  FF                   RST	38h
161A  FF                   RST	38h
161B  FF                   RST	38h
161C  FF                   RST	38h
161D  FF                   RST	38h
161E  FF                   RST	38h
161F  FF                   RST	38h
1620  FF                   RST	38h
1621  FF                   RST	38h
1622  FF                   RST	38h
1623  FF                   RST	38h
1624  FF                   RST	38h
1625  FF                   RST	38h
1626  FF                   RST	38h
1627  FF                   RST	38h
1628  FF                   RST	38h
1629  FF                   RST	38h
162A  FF                   RST	38h
162B  FF                   RST	38h
162C  FF                   RST	38h
162D  FF                   RST	38h
162E  FF                   RST	38h
162F  FF                   RST	38h
1630  FF                   RST	38h
1631  FF                   RST	38h
1632  FF                   RST	38h
1633  FF                   RST	38h
1634  FF                   RST	38h
1635  FF                   RST	38h
1636  FF                   RST	38h
1637  FF                   RST	38h
1638  FF                   RST	38h
1639  FF                   RST	38h
163A  FF                   RST	38h
163B  FF                   RST	38h
163C  FF                   RST	38h
163D  FF                   RST	38h
163E  FF                   RST	38h
163F  FF                   RST	38h
1640  FF                   RST	38h
1641  FF                   RST	38h
1642  FF                   RST	38h
1643  FF                   RST	38h
1644  FF                   RST	38h
1645  FF                   RST	38h
1646  FF                   RST	38h
1647  FF                   RST	38h
1648  FF                   RST	38h
1649  FF                   RST	38h
164A  FF                   RST	38h
164B  FF                   RST	38h
164C  FF                   RST	38h
164D  FF                   RST	38h
164E  FF                   RST	38h
164F  FF                   RST	38h
1650  FF                   RST	38h
1651  FF                   RST	38h
1652  FF                   RST	38h
1653  FF                   RST	38h
1654  FF                   RST	38h
1655  FF                   RST	38h
1656  FF                   RST	38h
1657  FF                   RST	38h
1658  FF                   RST	38h
1659  FF                   RST	38h
165A  FF                   RST	38h
165B  FF                   RST	38h
165C  FF                   RST	38h
165D  FF                   RST	38h
165E  FF                   RST	38h
165F  FF                   RST	38h
1660  FF                   RST	38h
1661  FF                   RST	38h
1662  FF                   RST	38h
1663  FF                   RST	38h
1664  FF                   RST	38h
1665  FF                   RST	38h
1666  FF                   RST	38h
1667  FF                   RST	38h
1668  FF                   RST	38h
1669  FF                   RST	38h
166A  FF                   RST	38h
166B  FF                   RST	38h
166C  FF                   RST	38h
166D  FF                   RST	38h
166E  FF                   RST	38h
166F  FF                   RST	38h
1670  FF                   RST	38h
1671  FF                   RST	38h
1672  FF                   RST	38h
1673  FF                   RST	38h
1674  FF                   RST	38h
1675  FF                   RST	38h
1676  FF                   RST	38h
1677  FF                   RST	38h
1678  FF                   RST	38h
1679  FF                   RST	38h
167A  FF                   RST	38h
167B  FF                   RST	38h
167C  FF                   RST	38h
167D  FF                   RST	38h
167E  FF                   RST	38h
167F  FF                   RST	38h
1680  FF                   RST	38h
1681  FF                   RST	38h
1682  FF                   RST	38h
1683  FF                   RST	38h
1684  FF                   RST	38h
1685  FF                   RST	38h
1686  FF                   RST	38h
1687  FF                   RST	38h
1688  FF                   RST	38h
1689  FF                   RST	38h
168A  FF                   RST	38h
168B  FF                   RST	38h
168C  FF                   RST	38h
168D  FF                   RST	38h
168E  FF                   RST	38h
168F  FF                   RST	38h
1690  FF                   RST	38h
1691  FF                   RST	38h
1692  FF                   RST	38h
1693  FF                   RST	38h
1694  FF                   RST	38h
1695  FF                   RST	38h
1696  FF                   RST	38h
1697  FF                   RST	38h
1698  FF                   RST	38h
1699  FF                   RST	38h
169A  FF                   RST	38h
169B  FF                   RST	38h
169C  FF                   RST	38h
169D  FF                   RST	38h
169E  FF                   RST	38h
169F  FF                   RST	38h
16A0  FF                   RST	38h
16A1  FF                   RST	38h
16A2  FF                   RST	38h
16A3  FF                   RST	38h
16A4  FF                   RST	38h
16A5  FF                   RST	38h
16A6  FF                   RST	38h
16A7  FF                   RST	38h
16A8  FF                   RST	38h
16A9  FF                   RST	38h
16AA  FF                   RST	38h
16AB  FF                   RST	38h
16AC  FF                   RST	38h
16AD  FF                   RST	38h
16AE  FF                   RST	38h
16AF  FF                   RST	38h
16B0  FF                   RST	38h
16B1  FF                   RST	38h
16B2  FF                   RST	38h
16B3  FF                   RST	38h
16B4  FF                   RST	38h
16B5  FF                   RST	38h
16B6  FF                   RST	38h
16B7  FF                   RST	38h
16B8  FF                   RST	38h
16B9  FF                   RST	38h
16BA  FF                   RST	38h
16BB  FF                   RST	38h
16BC  FF                   RST	38h
16BD  FF                   RST	38h
16BE  FF                   RST	38h
16BF  FF                   RST	38h
16C0  FF                   RST	38h
16C1  FF                   RST	38h
16C2  FF                   RST	38h
16C3  FF                   RST	38h
16C4  FF                   RST	38h
16C5  FF                   RST	38h
16C6  FF                   RST	38h
16C7  FF                   RST	38h
16C8  FF                   RST	38h
16C9  FF                   RST	38h
16CA  FF                   RST	38h
16CB  FF                   RST	38h
16CC  FF                   RST	38h
16CD  FF                   RST	38h
16CE  FF                   RST	38h
16CF  FF                   RST	38h
16D0  FF                   RST	38h
16D1  FF                   RST	38h
16D2  FF                   RST	38h
16D3  FF                   RST	38h
16D4  FF                   RST	38h
16D5  FF                   RST	38h
16D6  FF                   RST	38h
16D7  FF                   RST	38h
16D8  FF                   RST	38h
16D9  FF                   RST	38h
16DA  FF                   RST	38h
16DB  FF                   RST	38h
16DC  FF                   RST	38h
16DD  FF                   RST	38h
16DE  FF                   RST	38h
16DF  FF                   RST	38h
16E0  FF                   RST	38h
16E1  FF                   RST	38h
16E2  FF                   RST	38h
16E3  FF                   RST	38h
16E4  FF                   RST	38h
16E5  FF                   RST	38h
16E6  FF                   RST	38h
16E7  FF                   RST	38h
16E8  FF                   RST	38h
16E9  FF                   RST	38h
16EA  FF                   RST	38h
16EB  FF                   RST	38h
16EC  FF                   RST	38h
16ED  FF                   RST	38h
16EE  FF                   RST	38h
16EF  FF                   RST	38h
16F0  FF                   RST	38h
16F1  FF                   RST	38h
16F2  FF                   RST	38h
16F3  FF                   RST	38h
16F4  FF                   RST	38h
16F5  FF                   RST	38h
16F6  FF                   RST	38h
16F7  FF                   RST	38h
16F8  FF                   RST	38h
16F9  FF                   RST	38h
16FA  FF                   RST	38h
16FB  FF                   RST	38h
16FC  FF                   RST	38h
16FD  FF                   RST	38h
16FE  FF                   RST	38h
16FF  FF                   RST	38h
1700  FF                   RST	38h
1701  FF                   RST	38h
1702  FF                   RST	38h
1703  FF                   RST	38h
1704  FF                   RST	38h
1705  FF                   RST	38h
1706  FF                   RST	38h
1707  FF                   RST	38h
1708  FF                   RST	38h
1709  FF                   RST	38h
170A  FF                   RST	38h
170B  FF                   RST	38h
170C  FF                   RST	38h
170D  FF                   RST	38h
170E  FF                   RST	38h
170F  FF                   RST	38h
1710  FF                   RST	38h
1711  FF                   RST	38h
1712  FF                   RST	38h
1713  FF                   RST	38h
1714  FF                   RST	38h
1715  FF                   RST	38h
1716  FF                   RST	38h
1717  FF                   RST	38h
1718  FF                   RST	38h
1719  FF                   RST	38h
171A  FF                   RST	38h
171B  FF                   RST	38h
171C  FF                   RST	38h
171D  FF                   RST	38h
171E  FF                   RST	38h
171F  FF                   RST	38h
1720  FF                   RST	38h
1721  FF                   RST	38h
1722  FF                   RST	38h
1723  FF                   RST	38h
1724  FF                   RST	38h
1725  FF                   RST	38h
1726  FF                   RST	38h
1727  FF                   RST	38h
1728  FF                   RST	38h
1729  FF                   RST	38h
172A  FF                   RST	38h
172B  FF                   RST	38h
172C  FF                   RST	38h
172D  FF                   RST	38h
172E  FF                   RST	38h
172F  FF                   RST	38h
1730  FF                   RST	38h
1731  FF                   RST	38h
1732  FF                   RST	38h
1733  FF                   RST	38h
1734  FF                   RST	38h
1735  FF                   RST	38h
1736  FF                   RST	38h
1737  FF                   RST	38h
1738  FF                   RST	38h
1739  FF                   RST	38h
173A  FF                   RST	38h
173B  FF                   RST	38h
173C  FF                   RST	38h
173D  FF                   RST	38h
173E  FF                   RST	38h
173F  FF                   RST	38h
1740  FF                   RST	38h
1741  FF                   RST	38h
1742  FF                   RST	38h
1743  FF                   RST	38h
1744  FF                   RST	38h
1745  FF                   RST	38h
1746  FF                   RST	38h
1747  FF                   RST	38h
1748  FF                   RST	38h
1749  FF                   RST	38h
174A  FF                   RST	38h
174B  FF                   RST	38h
174C  FF                   RST	38h
174D  FF                   RST	38h
174E  FF                   RST	38h
174F  FF                   RST	38h
1750  FF                   RST	38h
1751  FF                   RST	38h
1752  FF                   RST	38h
1753  FF                   RST	38h
1754  FF                   RST	38h
1755  FF                   RST	38h
1756  FF                   RST	38h
1757  FF                   RST	38h
1758  FF                   RST	38h
1759  FF                   RST	38h
175A  FF                   RST	38h
175B  FF                   RST	38h
175C  FF                   RST	38h
175D  FF                   RST	38h
175E  FF                   RST	38h
175F  FF                   RST	38h
1760  FF                   RST	38h
1761  FF                   RST	38h
1762  FF                   RST	38h
1763  FF                   RST	38h
1764  FF                   RST	38h
1765  FF                   RST	38h
1766  FF                   RST	38h
1767  FF                   RST	38h
1768  FF                   RST	38h
1769  FF                   RST	38h
176A  FF                   RST	38h
176B  FF                   RST	38h
176C  FF                   RST	38h
176D  FF                   RST	38h
176E  FF                   RST	38h
176F  FF                   RST	38h
1770  FF                   RST	38h
1771  FF                   RST	38h
1772  FF                   RST	38h
1773  FF                   RST	38h
1774  FF                   RST	38h
1775  FF                   RST	38h
1776  FF                   RST	38h
1777  FF                   RST	38h
1778  FF                   RST	38h
1779  FF                   RST	38h
177A  FF                   RST	38h
177B  FF                   RST	38h
177C  FF                   RST	38h
177D  FF                   RST	38h
177E  FF                   RST	38h
177F  FF                   RST	38h
1780  FF                   RST	38h
1781  FF                   RST	38h
1782  FF                   RST	38h
1783  FF                   RST	38h
1784  FF                   RST	38h
1785  FF                   RST	38h
1786  FF                   RST	38h
1787  FF                   RST	38h
1788  FF                   RST	38h
1789  FF                   RST	38h
178A  FF                   RST	38h
178B  FF                   RST	38h
178C  FF                   RST	38h
178D  FF                   RST	38h
178E  FF                   RST	38h
178F  FF                   RST	38h
1790  FF                   RST	38h
1791  FF                   RST	38h
1792  FF                   RST	38h
1793  FF                   RST	38h
1794  FF                   RST	38h
1795  FF                   RST	38h
1796  FF                   RST	38h
1797  FF                   RST	38h
1798  FF                   RST	38h
1799  FF                   RST	38h
179A  FF                   RST	38h
179B  FF                   RST	38h
179C  FF                   RST	38h
179D  FF                   RST	38h
179E  FF                   RST	38h
179F  FF                   RST	38h
17A0  FF                   RST	38h
17A1  FF                   RST	38h
17A2  FF                   RST	38h
17A3  FF                   RST	38h
17A4  FF                   RST	38h
17A5  FF                   RST	38h
17A6  FF                   RST	38h
17A7  FF                   RST	38h
17A8  FF                   RST	38h
17A9  FF                   RST	38h
17AA  FF                   RST	38h
17AB  FF                   RST	38h
17AC  FF                   RST	38h
17AD  FF                   RST	38h
17AE  FF                   RST	38h
17AF  FF                   RST	38h
17B0  FF                   RST	38h
17B1  FF                   RST	38h
17B2  FF                   RST	38h
17B3  FF                   RST	38h
17B4  FF                   RST	38h
17B5  FF                   RST	38h
17B6  FF                   RST	38h
17B7  FF                   RST	38h
17B8  FF                   RST	38h
17B9  FF                   RST	38h
17BA  FF                   RST	38h
17BB  FF                   RST	38h
17BC  FF                   RST	38h
17BD  FF                   RST	38h
17BE  FF                   RST	38h
17BF  FF                   RST	38h
17C0  FF                   RST	38h
17C1  FF                   RST	38h
17C2  FF                   RST	38h
17C3  FF                   RST	38h
17C4  FF                   RST	38h
17C5  FF                   RST	38h
17C6  FF                   RST	38h
17C7  FF                   RST	38h
17C8  FF                   RST	38h
17C9  FF                   RST	38h
17CA  FF                   RST	38h
17CB  FF                   RST	38h
17CC  FF                   RST	38h
17CD  FF                   RST	38h
17CE  FF                   RST	38h
17CF  FF                   RST	38h
17D0  FF                   RST	38h
17D1  FF                   RST	38h
17D2  FF                   RST	38h
17D3  FF                   RST	38h
17D4  FF                   RST	38h
17D5  FF                   RST	38h
17D6  FF                   RST	38h
17D7  FF                   RST	38h
17D8  FF                   RST	38h
17D9  FF                   RST	38h
17DA  FF                   RST	38h
17DB  FF                   RST	38h
17DC  FF                   RST	38h
17DD  FF                   RST	38h
17DE  FF                   RST	38h
17DF  FF                   RST	38h
17E0  FF                   RST	38h
17E1  FF                   RST	38h
17E2  FF                   RST	38h
17E3  FF                   RST	38h
17E4  FF                   RST	38h
17E5  FF                   RST	38h
17E6  FF                   RST	38h
17E7  FF                   RST	38h
17E8  FF                   RST	38h
17E9  FF                   RST	38h
17EA  FF                   RST	38h
17EB  FF                   RST	38h
17EC  FF                   RST	38h
17ED  FF                   RST	38h
17EE  FF                   RST	38h
17EF  FF                   RST	38h
17F0  FF                   RST	38h
17F1  FF                   RST	38h
17F2  FF                   RST	38h
17F3  FF                   RST	38h
17F4  FF                   RST	38h
17F5  FF                   RST	38h
17F6  FF                   RST	38h
17F7  FF                   RST	38h
17F8  FF                   RST	38h
17F9  FF                   RST	38h
17FA  FF                   RST	38h
17FB  FF                   RST	38h
17FC  FF                   RST	38h
17FD  FF                   RST	38h
17FE  FF                   RST	38h
17FF  FF                   RST	38h
1800  FF                   RST	38h
1801  FF                   RST	38h
1802  FF                   RST	38h
1803  FF                   RST	38h
1804  FF                   RST	38h
1805  FF                   RST	38h
1806  FF                   RST	38h
1807  FF                   RST	38h
1808  FF                   RST	38h
1809  FF                   RST	38h
180A  FF                   RST	38h
180B  FF                   RST	38h
180C  FF                   RST	38h
180D  FF                   RST	38h
180E  FF                   RST	38h
180F  FF                   RST	38h
1810  FF                   RST	38h
1811  FF                   RST	38h
1812  FF                   RST	38h
1813  FF                   RST	38h
1814  FF                   RST	38h
1815  FF                   RST	38h
1816  FF                   RST	38h
1817  FF                   RST	38h
1818  FF                   RST	38h
1819  FF                   RST	38h
181A  FF                   RST	38h
181B  FF                   RST	38h
181C  FF                   RST	38h
181D  FF                   RST	38h
181E  FF                   RST	38h
181F  FF                   RST	38h
1820  FF                   RST	38h
1821  FF                   RST	38h
1822  FF                   RST	38h
1823  FF                   RST	38h
1824  FF                   RST	38h
1825  FF                   RST	38h
1826  FF                   RST	38h
1827  FF                   RST	38h
1828  FF                   RST	38h
1829  FF                   RST	38h
182A  FF                   RST	38h
182B  FF                   RST	38h
182C  FF                   RST	38h
182D  FF                   RST	38h
182E  FF                   RST	38h
182F  FF                   RST	38h
1830  FF                   RST	38h
1831  FF                   RST	38h
1832  FF                   RST	38h
1833  FF                   RST	38h
1834  FF                   RST	38h
1835  FF                   RST	38h
1836  FF                   RST	38h
1837  FF                   RST	38h
1838  FF                   RST	38h
1839  FF                   RST	38h
183A  FF                   RST	38h
183B  FF                   RST	38h
183C  FF                   RST	38h
183D  FF                   RST	38h
183E  FF                   RST	38h
183F  FF                   RST	38h
1840  FF                   RST	38h
1841  FF                   RST	38h
1842  FF                   RST	38h
1843  FF                   RST	38h
1844  FF                   RST	38h
1845  FF                   RST	38h
1846  FF                   RST	38h
1847  FF                   RST	38h
1848  FF                   RST	38h
1849  FF                   RST	38h
184A  FF                   RST	38h
184B  FF                   RST	38h
184C  FF                   RST	38h
184D  FF                   RST	38h
184E  FF                   RST	38h
184F  FF                   RST	38h
1850  FF                   RST	38h
1851  FF                   RST	38h
1852  FF                   RST	38h
1853  FF                   RST	38h
1854  FF                   RST	38h
1855  FF                   RST	38h
1856  FF                   RST	38h
1857  FF                   RST	38h
1858  FF                   RST	38h
1859  FF                   RST	38h
185A  FF                   RST	38h
185B  FF                   RST	38h
185C  FF                   RST	38h
185D  FF                   RST	38h
185E  FF                   RST	38h
185F  FF                   RST	38h
1860  FF                   RST	38h
1861  FF                   RST	38h
1862  FF                   RST	38h
1863  FF                   RST	38h
1864  FF                   RST	38h
1865  FF                   RST	38h
1866  FF                   RST	38h
1867  FF                   RST	38h
1868  FF                   RST	38h
1869  FF                   RST	38h
186A  FF                   RST	38h
186B  FF                   RST	38h
186C  FF                   RST	38h
186D  FF                   RST	38h
186E  FF                   RST	38h
186F  FF                   RST	38h
1870  FF                   RST	38h
1871  FF                   RST	38h
1872  FF                   RST	38h
1873  FF                   RST	38h
1874  FF                   RST	38h
1875  FF                   RST	38h
1876  FF                   RST	38h
1877  FF                   RST	38h
1878  FF                   RST	38h
1879  FF                   RST	38h
187A  FF                   RST	38h
187B  FF                   RST	38h
187C  FF                   RST	38h
187D  FF                   RST	38h
187E  FF                   RST	38h
187F  FF                   RST	38h
1880  FF                   RST	38h
1881  FF                   RST	38h
1882  FF                   RST	38h
1883  FF                   RST	38h
1884  FF                   RST	38h
1885  FF                   RST	38h
1886  FF                   RST	38h
1887  FF                   RST	38h
1888  FF                   RST	38h
1889  FF                   RST	38h
188A  FF                   RST	38h
188B  FF                   RST	38h
188C  FF                   RST	38h
188D  FF                   RST	38h
188E  FF                   RST	38h
188F  FF                   RST	38h
1890  FF                   RST	38h
1891  FF                   RST	38h
1892  FF                   RST	38h
1893  FF                   RST	38h
1894  FF                   RST	38h
1895  FF                   RST	38h
1896  FF                   RST	38h
1897  FF                   RST	38h
1898  FF                   RST	38h
1899  FF                   RST	38h
189A  FF                   RST	38h
189B  FF                   RST	38h
189C  FF                   RST	38h
189D  FF                   RST	38h
189E  FF                   RST	38h
189F  FF                   RST	38h
18A0  FF                   RST	38h
18A1  FF                   RST	38h
18A2  FF                   RST	38h
18A3  FF                   RST	38h
18A4  FF                   RST	38h
18A5  FF                   RST	38h
18A6  FF                   RST	38h
18A7  FF                   RST	38h
18A8  FF                   RST	38h
18A9  FF                   RST	38h
18AA  FF                   RST	38h
18AB  FF                   RST	38h
18AC  FF                   RST	38h
18AD  FF                   RST	38h
18AE  FF                   RST	38h
18AF  FF                   RST	38h
18B0  FF                   RST	38h
18B1  FF                   RST	38h
18B2  FF                   RST	38h
18B3  FF                   RST	38h
18B4  FF                   RST	38h
18B5  FF                   RST	38h
18B6  FF                   RST	38h
18B7  FF                   RST	38h
18B8  FF                   RST	38h
18B9  FF                   RST	38h
18BA  FF                   RST	38h
18BB  FF                   RST	38h
18BC  FF                   RST	38h
18BD  FF                   RST	38h
18BE  FF                   RST	38h
18BF  FF                   RST	38h
18C0  FF                   RST	38h
18C1  FF                   RST	38h
18C2  FF                   RST	38h
18C3  FF                   RST	38h
18C4  FF                   RST	38h
18C5  FF                   RST	38h
18C6  FF                   RST	38h
18C7  FF                   RST	38h
18C8  FF                   RST	38h
18C9  FF                   RST	38h
18CA  FF                   RST	38h
18CB  FF                   RST	38h
18CC  FF                   RST	38h
18CD  FF                   RST	38h
18CE  FF                   RST	38h
18CF  FF                   RST	38h
18D0  FF                   RST	38h
18D1  FF                   RST	38h
18D2  FF                   RST	38h
18D3  FF                   RST	38h
18D4  FF                   RST	38h
18D5  FF                   RST	38h
18D6  FF                   RST	38h
18D7  FF                   RST	38h
18D8  FF                   RST	38h
18D9  FF                   RST	38h
18DA  FF                   RST	38h
18DB  FF                   RST	38h
18DC  FF                   RST	38h
18DD  FF                   RST	38h
18DE  FF                   RST	38h
18DF  FF                   RST	38h
18E0  FF                   RST	38h
18E1  FF                   RST	38h
18E2  FF                   RST	38h
18E3  FF                   RST	38h
18E4  FF                   RST	38h
18E5  FF                   RST	38h
18E6  FF                   RST	38h
18E7  FF                   RST	38h
18E8  FF                   RST	38h
18E9  FF                   RST	38h
18EA  FF                   RST	38h
18EB  FF                   RST	38h
18EC  FF                   RST	38h
18ED  FF                   RST	38h
18EE  FF                   RST	38h
18EF  FF                   RST	38h
18F0  FF                   RST	38h
18F1  FF                   RST	38h
18F2  FF                   RST	38h
18F3  FF                   RST	38h
18F4  FF                   RST	38h
18F5  FF                   RST	38h
18F6  FF                   RST	38h
18F7  FF                   RST	38h
18F8  FF                   RST	38h
18F9  FF                   RST	38h
18FA  FF                   RST	38h
18FB  FF                   RST	38h
18FC  FF                   RST	38h
18FD  FF                   RST	38h
18FE  FF                   RST	38h
18FF  FF                   RST	38h
1900  FF                   RST	38h
1901  FF                   RST	38h
1902  FF                   RST	38h
1903  FF                   RST	38h
1904  FF                   RST	38h
1905  FF                   RST	38h
1906  FF                   RST	38h
1907  FF                   RST	38h
1908  FF                   RST	38h
1909  FF                   RST	38h
190A  FF                   RST	38h
190B  FF                   RST	38h
190C  FF                   RST	38h
190D  FF                   RST	38h
190E  FF                   RST	38h
190F  FF                   RST	38h
1910  FF                   RST	38h
1911  FF                   RST	38h
1912  FF                   RST	38h
1913  FF                   RST	38h
1914  FF                   RST	38h
1915  FF                   RST	38h
1916  FF                   RST	38h
1917  FF                   RST	38h
1918  FF                   RST	38h
1919  FF                   RST	38h
191A  FF                   RST	38h
191B  FF                   RST	38h
191C  FF                   RST	38h
191D  FF                   RST	38h
191E  FF                   RST	38h
191F  FF                   RST	38h
1920  FF                   RST	38h
1921  FF                   RST	38h
1922  FF                   RST	38h
1923  FF                   RST	38h
1924  FF                   RST	38h
1925  FF                   RST	38h
1926  FF                   RST	38h
1927  FF                   RST	38h
1928  FF                   RST	38h
1929  FF                   RST	38h
192A  FF                   RST	38h
192B  FF                   RST	38h
192C  FF                   RST	38h
192D  FF                   RST	38h
192E  FF                   RST	38h
192F  FF                   RST	38h
1930  FF                   RST	38h
1931  FF                   RST	38h
1932  FF                   RST	38h
1933  FF                   RST	38h
1934  FF                   RST	38h
1935  FF                   RST	38h
1936  FF                   RST	38h
1937  FF                   RST	38h
1938  FF                   RST	38h
1939  FF                   RST	38h
193A  FF                   RST	38h
193B  FF                   RST	38h
193C  FF                   RST	38h
193D  FF                   RST	38h
193E  FF                   RST	38h
193F  FF                   RST	38h
1940  FF                   RST	38h
1941  FF                   RST	38h
1942  FF                   RST	38h
1943  FF                   RST	38h
1944  FF                   RST	38h
1945  FF                   RST	38h
1946  FF                   RST	38h
1947  FF                   RST	38h
1948  FF                   RST	38h
1949  FF                   RST	38h
194A  FF                   RST	38h
194B  FF                   RST	38h
194C  FF                   RST	38h
194D  FF                   RST	38h
194E  FF                   RST	38h
194F  FF                   RST	38h
1950  FF                   RST	38h
1951  FF                   RST	38h
1952  FF                   RST	38h
1953  FF                   RST	38h
1954  FF                   RST	38h
1955  FF                   RST	38h
1956  FF                   RST	38h
1957  FF                   RST	38h
1958  FF                   RST	38h
1959  FF                   RST	38h
195A  FF                   RST	38h
195B  FF                   RST	38h
195C  FF                   RST	38h
195D  FF                   RST	38h
195E  FF                   RST	38h
195F  FF                   RST	38h
1960  FF                   RST	38h
1961  FF                   RST	38h
1962  FF                   RST	38h
1963  FF                   RST	38h
1964  FF                   RST	38h
1965  FF                   RST	38h
1966  FF                   RST	38h
1967  FF                   RST	38h
1968  FF                   RST	38h
1969  FF                   RST	38h
196A  FF                   RST	38h
196B  FF                   RST	38h
196C  FF                   RST	38h
196D  FF                   RST	38h
196E  FF                   RST	38h
196F  FF                   RST	38h
1970  FF                   RST	38h
1971  FF                   RST	38h
1972  FF                   RST	38h
1973  FF                   RST	38h
1974  FF                   RST	38h
1975  FF                   RST	38h
1976  FF                   RST	38h
1977  FF                   RST	38h
1978  FF                   RST	38h
1979  FF                   RST	38h
197A  FF                   RST	38h
197B  FF                   RST	38h
197C  FF                   RST	38h
197D  FF                   RST	38h
197E  FF                   RST	38h
197F  FF                   RST	38h
1980  FF                   RST	38h
1981  FF                   RST	38h
1982  FF                   RST	38h
1983  FF                   RST	38h
1984  FF                   RST	38h
1985  FF                   RST	38h
1986  FF                   RST	38h
1987  FF                   RST	38h
1988  FF                   RST	38h
1989  FF                   RST	38h
198A  FF                   RST	38h
198B  FF                   RST	38h
198C  FF                   RST	38h
198D  FF                   RST	38h
198E  FF                   RST	38h
198F  FF                   RST	38h
1990  FF                   RST	38h
1991  FF                   RST	38h
1992  FF                   RST	38h
1993  FF                   RST	38h
1994  FF                   RST	38h
1995  FF                   RST	38h
1996  FF                   RST	38h
1997  FF                   RST	38h
1998  FF                   RST	38h
1999  FF                   RST	38h
199A  FF                   RST	38h
199B  FF                   RST	38h
199C  FF                   RST	38h
199D  FF                   RST	38h
199E  FF                   RST	38h
199F  FF                   RST	38h
19A0  FF                   RST	38h
19A1  FF                   RST	38h
19A2  FF                   RST	38h
19A3  FF                   RST	38h
19A4  FF                   RST	38h
19A5  FF                   RST	38h
19A6  FF                   RST	38h
19A7  FF                   RST	38h
19A8  FF                   RST	38h
19A9  FF                   RST	38h
19AA  FF                   RST	38h
19AB  FF                   RST	38h
19AC  FF                   RST	38h
19AD  FF                   RST	38h
19AE  FF                   RST	38h
19AF  FF                   RST	38h
19B0  FF                   RST	38h
19B1  FF                   RST	38h
19B2  FF                   RST	38h
19B3  FF                   RST	38h
19B4  FF                   RST	38h
19B5  FF                   RST	38h
19B6  FF                   RST	38h
19B7  FF                   RST	38h
19B8  FF                   RST	38h
19B9  FF                   RST	38h
19BA  FF                   RST	38h
19BB  FF                   RST	38h
19BC  FF                   RST	38h
19BD  FF                   RST	38h
19BE  FF                   RST	38h
19BF  FF                   RST	38h
19C0  FF                   RST	38h
19C1  FF                   RST	38h
19C2  FF                   RST	38h
19C3  FF                   RST	38h
19C4  FF                   RST	38h
19C5  FF                   RST	38h
19C6  FF                   RST	38h
19C7  FF                   RST	38h
19C8  FF                   RST	38h
19C9  FF                   RST	38h
19CA  FF                   RST	38h
19CB  FF                   RST	38h
19CC  FF                   RST	38h
19CD  FF                   RST	38h
19CE  FF                   RST	38h
19CF  FF                   RST	38h
19D0  FF                   RST	38h
19D1  FF                   RST	38h
19D2  FF                   RST	38h
19D3  FF                   RST	38h
19D4  FF                   RST	38h
19D5  FF                   RST	38h
19D6  FF                   RST	38h
19D7  FF                   RST	38h
19D8  FF                   RST	38h
19D9  FF                   RST	38h
19DA  FF                   RST	38h
19DB  FF                   RST	38h
19DC  FF                   RST	38h
19DD  FF                   RST	38h
19DE  FF                   RST	38h
19DF  FF                   RST	38h
19E0  FF                   RST	38h
19E1  FF                   RST	38h
19E2  FF                   RST	38h
19E3  FF                   RST	38h
19E4  FF                   RST	38h
19E5  FF                   RST	38h
19E6  FF                   RST	38h
19E7  FF                   RST	38h
19E8  FF                   RST	38h
19E9  FF                   RST	38h
19EA  FF                   RST	38h
19EB  FF                   RST	38h
19EC  FF                   RST	38h
19ED  FF                   RST	38h
19EE  FF                   RST	38h
19EF  FF                   RST	38h
19F0  FF                   RST	38h
19F1  FF                   RST	38h
19F2  FF                   RST	38h
19F3  FF                   RST	38h
19F4  FF                   RST	38h
19F5  FF                   RST	38h
19F6  FF                   RST	38h
19F7  FF                   RST	38h
19F8  FF                   RST	38h
19F9  FF                   RST	38h
19FA  FF                   RST	38h
19FB  FF                   RST	38h
19FC  FF                   RST	38h
19FD  FF                   RST	38h
19FE  FF                   RST	38h
19FF  FF                   RST	38h
1A00  FF                   RST	38h
1A01  FF                   RST	38h
1A02  FF                   RST	38h
1A03  FF                   RST	38h
1A04  FF                   RST	38h
1A05  FF                   RST	38h
1A06  FF                   RST	38h
1A07  FF                   RST	38h
1A08  FF                   RST	38h
1A09  FF                   RST	38h
1A0A  FF                   RST	38h
1A0B  FF                   RST	38h
1A0C  FF                   RST	38h
1A0D  FF                   RST	38h
1A0E  FF                   RST	38h
1A0F  FF                   RST	38h
1A10  FF                   RST	38h
1A11  FF                   RST	38h
1A12  FF                   RST	38h
1A13  FF                   RST	38h
1A14  FF                   RST	38h
1A15  FF                   RST	38h
1A16  FF                   RST	38h
1A17  FF                   RST	38h
1A18  FF                   RST	38h
1A19  FF                   RST	38h
1A1A  FF                   RST	38h
1A1B  FF                   RST	38h
1A1C  FF                   RST	38h
1A1D  FF                   RST	38h
1A1E  FF                   RST	38h
1A1F  FF                   RST	38h
1A20  FF                   RST	38h
1A21  FF                   RST	38h
1A22  FF                   RST	38h
1A23  FF                   RST	38h
1A24  FF                   RST	38h
1A25  FF                   RST	38h
1A26  FF                   RST	38h
1A27  FF                   RST	38h
1A28  FF                   RST	38h
1A29  FF                   RST	38h
1A2A  FF                   RST	38h
1A2B  FF                   RST	38h
1A2C  FF                   RST	38h
1A2D  FF                   RST	38h
1A2E  FF                   RST	38h
1A2F  FF                   RST	38h
1A30  FF                   RST	38h
1A31  FF                   RST	38h
1A32  FF                   RST	38h
1A33  FF                   RST	38h
1A34  FF                   RST	38h
1A35  FF                   RST	38h
1A36  FF                   RST	38h
1A37  FF                   RST	38h
1A38  FF                   RST	38h
1A39  FF                   RST	38h
1A3A  FF                   RST	38h
1A3B  FF                   RST	38h
1A3C  FF                   RST	38h
1A3D  FF                   RST	38h
1A3E  FF                   RST	38h
1A3F  FF                   RST	38h
1A40  FF                   RST	38h
1A41  FF                   RST	38h
1A42  FF                   RST	38h
1A43  FF                   RST	38h
1A44  FF                   RST	38h
1A45  FF                   RST	38h
1A46  FF                   RST	38h
1A47  FF                   RST	38h
1A48  FF                   RST	38h
1A49  FF                   RST	38h
1A4A  FF                   RST	38h
1A4B  FF                   RST	38h
1A4C  FF                   RST	38h
1A4D  FF                   RST	38h
1A4E  FF                   RST	38h
1A4F  FF                   RST	38h
1A50  FF                   RST	38h
1A51  FF                   RST	38h
1A52  FF                   RST	38h
1A53  FF                   RST	38h
1A54  FF                   RST	38h
1A55  FF                   RST	38h
1A56  FF                   RST	38h
1A57  FF                   RST	38h
1A58  FF                   RST	38h
1A59  FF                   RST	38h
1A5A  FF                   RST	38h
1A5B  FF                   RST	38h
1A5C  FF                   RST	38h
1A5D  FF                   RST	38h
1A5E  FF                   RST	38h
1A5F  FF                   RST	38h
1A60  FF                   RST	38h
1A61  FF                   RST	38h
1A62  FF                   RST	38h
1A63  FF                   RST	38h
1A64  FF                   RST	38h
1A65  FF                   RST	38h
1A66  FF                   RST	38h
1A67  FF                   RST	38h
1A68  FF                   RST	38h
1A69  FF                   RST	38h
1A6A  FF                   RST	38h
1A6B  FF                   RST	38h
1A6C  FF                   RST	38h
1A6D  FF                   RST	38h
1A6E  FF                   RST	38h
1A6F  FF                   RST	38h
1A70  FF                   RST	38h
1A71  FF                   RST	38h
1A72  FF                   RST	38h
1A73  FF                   RST	38h
1A74  FF                   RST	38h
1A75  FF                   RST	38h
1A76  FF                   RST	38h
1A77  FF                   RST	38h
1A78  FF                   RST	38h
1A79  FF                   RST	38h
1A7A  FF                   RST	38h
1A7B  FF                   RST	38h
1A7C  FF                   RST	38h
1A7D  FF                   RST	38h
1A7E  FF                   RST	38h
1A7F  FF                   RST	38h
1A80  FF                   RST	38h
1A81  FF                   RST	38h
1A82  FF                   RST	38h
1A83  FF                   RST	38h
1A84  FF                   RST	38h
1A85  FF                   RST	38h
1A86  FF                   RST	38h
1A87  FF                   RST	38h
1A88  FF                   RST	38h
1A89  FF                   RST	38h
1A8A  FF                   RST	38h
1A8B  FF                   RST	38h
1A8C  FF                   RST	38h
1A8D  FF                   RST	38h
1A8E  FF                   RST	38h
1A8F  FF                   RST	38h
1A90  FF                   RST	38h
1A91  FF                   RST	38h
1A92  FF                   RST	38h
1A93  FF                   RST	38h
1A94  FF                   RST	38h
1A95  FF                   RST	38h
1A96  FF                   RST	38h
1A97  FF                   RST	38h
1A98  FF                   RST	38h
1A99  FF                   RST	38h
1A9A  FF                   RST	38h
1A9B  FF                   RST	38h
1A9C  FF                   RST	38h
1A9D  FF                   RST	38h
1A9E  FF                   RST	38h
1A9F  FF                   RST	38h
1AA0  FF                   RST	38h
1AA1  FF                   RST	38h
1AA2  FF                   RST	38h
1AA3  FF                   RST	38h
1AA4  FF                   RST	38h
1AA5  FF                   RST	38h
1AA6  FF                   RST	38h
1AA7  FF                   RST	38h
1AA8  FF                   RST	38h
1AA9  FF                   RST	38h
1AAA  FF                   RST	38h
1AAB  FF                   RST	38h
1AAC  FF                   RST	38h
1AAD  FF                   RST	38h
1AAE  FF                   RST	38h
1AAF  FF                   RST	38h
1AB0  FF                   RST	38h
1AB1  FF                   RST	38h
1AB2  FF                   RST	38h
1AB3  FF                   RST	38h
1AB4  FF                   RST	38h
1AB5  FF                   RST	38h
1AB6  FF                   RST	38h
1AB7  FF                   RST	38h
1AB8  FF                   RST	38h
1AB9  FF                   RST	38h
1ABA  FF                   RST	38h
1ABB  FF                   RST	38h
1ABC  FF                   RST	38h
1ABD  FF                   RST	38h
1ABE  FF                   RST	38h
1ABF  FF                   RST	38h
1AC0  FF                   RST	38h
1AC1  FF                   RST	38h
1AC2  FF                   RST	38h
1AC3  FF                   RST	38h
1AC4  FF                   RST	38h
1AC5  FF                   RST	38h
1AC6  FF                   RST	38h
1AC7  FF                   RST	38h
1AC8  FF                   RST	38h
1AC9  FF                   RST	38h
1ACA  FF                   RST	38h
1ACB  FF                   RST	38h
1ACC  FF                   RST	38h
1ACD  FF                   RST	38h
1ACE  FF                   RST	38h
1ACF  FF                   RST	38h
1AD0  FF                   RST	38h
1AD1  FF                   RST	38h
1AD2  FF                   RST	38h
1AD3  FF                   RST	38h
1AD4  FF                   RST	38h
1AD5  FF                   RST	38h
1AD6  FF                   RST	38h
1AD7  FF                   RST	38h
1AD8  FF                   RST	38h
1AD9  FF                   RST	38h
1ADA  FF                   RST	38h
1ADB  FF                   RST	38h
1ADC  FF                   RST	38h
1ADD  FF                   RST	38h
1ADE  FF                   RST	38h
1ADF  FF                   RST	38h
1AE0  FF                   RST	38h
1AE1  FF                   RST	38h
1AE2  FF                   RST	38h
1AE3  FF                   RST	38h
1AE4  FF                   RST	38h
1AE5  FF                   RST	38h
1AE6  FF                   RST	38h
1AE7  FF                   RST	38h
1AE8  FF                   RST	38h
1AE9  FF                   RST	38h
1AEA  FF                   RST	38h
1AEB  FF                   RST	38h
1AEC  FF                   RST	38h
1AED  FF                   RST	38h
1AEE  FF                   RST	38h
1AEF  FF                   RST	38h
1AF0  FF                   RST	38h
1AF1  FF                   RST	38h
1AF2  FF                   RST	38h
1AF3  FF                   RST	38h
1AF4  FF                   RST	38h
1AF5  FF                   RST	38h
1AF6  FF                   RST	38h
1AF7  FF                   RST	38h
1AF8  FF                   RST	38h
1AF9  FF                   RST	38h
1AFA  FF                   RST	38h
1AFB  FF                   RST	38h
1AFC  FF                   RST	38h
1AFD  FF                   RST	38h
1AFE  FF                   RST	38h
1AFF  FF                   RST	38h
1B00  FF                   RST	38h
1B01  FF                   RST	38h
1B02  FF                   RST	38h
1B03  FF                   RST	38h
1B04  FF                   RST	38h
1B05  FF                   RST	38h
1B06  FF                   RST	38h
1B07  FF                   RST	38h
1B08  FF                   RST	38h
1B09  FF                   RST	38h
1B0A  FF                   RST	38h
1B0B  FF                   RST	38h
1B0C  FF                   RST	38h
1B0D  FF                   RST	38h
1B0E  FF                   RST	38h
1B0F  FF                   RST	38h
1B10  FF                   RST	38h
1B11  FF                   RST	38h
1B12  FF                   RST	38h
1B13  FF                   RST	38h
1B14  FF                   RST	38h
1B15  FF                   RST	38h
1B16  FF                   RST	38h
1B17  FF                   RST	38h
1B18  FF                   RST	38h
1B19  FF                   RST	38h
1B1A  FF                   RST	38h
1B1B  FF                   RST	38h
1B1C  FF                   RST	38h
1B1D  FF                   RST	38h
1B1E  FF                   RST	38h
1B1F  FF                   RST	38h
1B20  FF                   RST	38h
1B21  FF                   RST	38h
1B22  FF                   RST	38h
1B23  FF                   RST	38h
1B24  FF                   RST	38h
1B25  FF                   RST	38h
1B26  FF                   RST	38h
1B27  FF                   RST	38h
1B28  FF                   RST	38h
1B29  FF                   RST	38h
1B2A  FF                   RST	38h
1B2B  FF                   RST	38h
1B2C  FF                   RST	38h
1B2D  FF                   RST	38h
1B2E  FF                   RST	38h
1B2F  FF                   RST	38h
1B30  FF                   RST	38h
1B31  FF                   RST	38h
1B32  FF                   RST	38h
1B33  FF                   RST	38h
1B34  FF                   RST	38h
1B35  FF                   RST	38h
1B36  FF                   RST	38h
1B37  FF                   RST	38h
1B38  FF                   RST	38h
1B39  FF                   RST	38h
1B3A  FF                   RST	38h
1B3B  FF                   RST	38h
1B3C  FF                   RST	38h
1B3D  FF                   RST	38h
1B3E  FF                   RST	38h
1B3F  FF                   RST	38h
1B40  FF                   RST	38h
1B41  FF                   RST	38h
1B42  FF                   RST	38h
1B43  FF                   RST	38h
1B44  FF                   RST	38h
1B45  FF                   RST	38h
1B46  FF                   RST	38h
1B47  FF                   RST	38h
1B48  FF                   RST	38h
1B49  FF                   RST	38h
1B4A  FF                   RST	38h
1B4B  FF                   RST	38h
1B4C  FF                   RST	38h
1B4D  FF                   RST	38h
1B4E  FF                   RST	38h
1B4F  FF                   RST	38h
1B50  FF                   RST	38h
1B51  FF                   RST	38h
1B52  FF                   RST	38h
1B53  FF                   RST	38h
1B54  FF                   RST	38h
1B55  FF                   RST	38h
1B56  FF                   RST	38h
1B57  FF                   RST	38h
1B58  FF                   RST	38h
1B59  FF                   RST	38h
1B5A  FF                   RST	38h
1B5B  FF                   RST	38h
1B5C  FF                   RST	38h
1B5D  FF                   RST	38h
1B5E  FF                   RST	38h
1B5F  FF                   RST	38h
1B60  FF                   RST	38h
1B61  FF                   RST	38h
1B62  FF                   RST	38h
1B63  FF                   RST	38h
1B64  FF                   RST	38h
1B65  FF                   RST	38h
1B66  FF                   RST	38h
1B67  FF                   RST	38h
1B68  FF                   RST	38h
1B69  FF                   RST	38h
1B6A  FF                   RST	38h
1B6B  FF                   RST	38h
1B6C  FF                   RST	38h
1B6D  FF                   RST	38h
1B6E  FF                   RST	38h
1B6F  FF                   RST	38h
1B70  FF                   RST	38h
1B71  FF                   RST	38h
1B72  FF                   RST	38h
1B73  FF                   RST	38h
1B74  FF                   RST	38h
1B75  FF                   RST	38h
1B76  FF                   RST	38h
1B77  FF                   RST	38h
1B78  FF                   RST	38h
1B79  FF                   RST	38h
1B7A  FF                   RST	38h
1B7B  FF                   RST	38h
1B7C  FF                   RST	38h
1B7D  FF                   RST	38h
1B7E  FF                   RST	38h
1B7F  FF                   RST	38h
1B80  FF                   RST	38h
1B81  FF                   RST	38h
1B82  FF                   RST	38h
1B83  FF                   RST	38h
1B84  FF                   RST	38h
1B85  FF                   RST	38h
1B86  FF                   RST	38h
1B87  FF                   RST	38h
1B88  FF                   RST	38h
1B89  FF                   RST	38h
1B8A  FF                   RST	38h
1B8B  FF                   RST	38h
1B8C  FF                   RST	38h
1B8D  FF                   RST	38h
1B8E  FF                   RST	38h
1B8F  FF                   RST	38h
1B90  FF                   RST	38h
1B91  FF                   RST	38h
1B92  FF                   RST	38h
1B93  FF                   RST	38h
1B94  FF                   RST	38h
1B95  FF                   RST	38h
1B96  FF                   RST	38h
1B97  FF                   RST	38h
1B98  FF                   RST	38h
1B99  FF                   RST	38h
1B9A  FF                   RST	38h
1B9B  FF                   RST	38h
1B9C  FF                   RST	38h
1B9D  FF                   RST	38h
1B9E  FF                   RST	38h
1B9F  FF                   RST	38h
1BA0  FF                   RST	38h
1BA1  FF                   RST	38h
1BA2  FF                   RST	38h
1BA3  FF                   RST	38h
1BA4  FF                   RST	38h
1BA5  FF                   RST	38h
1BA6  FF                   RST	38h
1BA7  FF                   RST	38h
1BA8  FF                   RST	38h
1BA9  FF                   RST	38h
1BAA  FF                   RST	38h
1BAB  FF                   RST	38h
1BAC  FF                   RST	38h
1BAD  FF                   RST	38h
1BAE  FF                   RST	38h
1BAF  FF                   RST	38h
1BB0  FF                   RST	38h
1BB1  FF                   RST	38h
1BB2  FF                   RST	38h
1BB3  FF                   RST	38h
1BB4  FF                   RST	38h
1BB5  FF                   RST	38h
1BB6  FF                   RST	38h
1BB7  FF                   RST	38h
1BB8  FF                   RST	38h
1BB9  FF                   RST	38h
1BBA  FF                   RST	38h
1BBB  FF                   RST	38h
1BBC  FF                   RST	38h
1BBD  FF                   RST	38h
1BBE  FF                   RST	38h
1BBF  FF                   RST	38h
1BC0  FF                   RST	38h
1BC1  FF                   RST	38h
1BC2  FF                   RST	38h
1BC3  FF                   RST	38h
1BC4  FF                   RST	38h
1BC5  FF                   RST	38h
1BC6  FF                   RST	38h
1BC7  FF                   RST	38h
1BC8  FF                   RST	38h
1BC9  FF                   RST	38h
1BCA  FF                   RST	38h
1BCB  FF                   RST	38h
1BCC  FF                   RST	38h
1BCD  FF                   RST	38h
1BCE  FF                   RST	38h
1BCF  FF                   RST	38h
1BD0  FF                   RST	38h
1BD1  FF                   RST	38h
1BD2  FF                   RST	38h
1BD3  FF                   RST	38h
1BD4  FF                   RST	38h
1BD5  FF                   RST	38h
1BD6  FF                   RST	38h
1BD7  FF                   RST	38h
1BD8  FF                   RST	38h
1BD9  FF                   RST	38h
1BDA  FF                   RST	38h
1BDB  FF                   RST	38h
1BDC  FF                   RST	38h
1BDD  FF                   RST	38h
1BDE  FF                   RST	38h
1BDF  FF                   RST	38h
1BE0  FF                   RST	38h
1BE1  FF                   RST	38h
1BE2  FF                   RST	38h
1BE3  FF                   RST	38h
1BE4  FF                   RST	38h
1BE5  FF                   RST	38h
1BE6  FF                   RST	38h
1BE7  FF                   RST	38h
1BE8  FF                   RST	38h
1BE9  FF                   RST	38h
1BEA  FF                   RST	38h
1BEB  FF                   RST	38h
1BEC  FF                   RST	38h
1BED  FF                   RST	38h
1BEE  FF                   RST	38h
1BEF  FF                   RST	38h
1BF0  FF                   RST	38h
1BF1  FF                   RST	38h
1BF2  FF                   RST	38h
1BF3  FF                   RST	38h
1BF4  FF                   RST	38h
1BF5  FF                   RST	38h
1BF6  FF                   RST	38h
1BF7  FF                   RST	38h
1BF8  FF                   RST	38h
1BF9  FF                   RST	38h
1BFA  FF                   RST	38h
1BFB  FF                   RST	38h
1BFC  FF                   RST	38h
1BFD  FF                   RST	38h
1BFE  FF                   RST	38h
1BFF  FF                   RST	38h
1C00  FF                   RST	38h
1C01  FF                   RST	38h
1C02  FF                   RST	38h
1C03  FF                   RST	38h
1C04  FF                   RST	38h
1C05  FF                   RST	38h
1C06  FF                   RST	38h
1C07  FF                   RST	38h
1C08  FF                   RST	38h
1C09  FF                   RST	38h
1C0A  FF                   RST	38h
1C0B  FF                   RST	38h
1C0C  FF                   RST	38h
1C0D  FF                   RST	38h
1C0E  FF                   RST	38h
1C0F  FF                   RST	38h
1C10  FF                   RST	38h
1C11  FF                   RST	38h
1C12  FF                   RST	38h
1C13  FF                   RST	38h
1C14  FF                   RST	38h
1C15  FF                   RST	38h
1C16  FF                   RST	38h
1C17  FF                   RST	38h
1C18  FF                   RST	38h
1C19  FF                   RST	38h
1C1A  FF                   RST	38h
1C1B  FF                   RST	38h
1C1C  FF                   RST	38h
1C1D  FF                   RST	38h
1C1E  FF                   RST	38h
1C1F  FF                   RST	38h
1C20  FF                   RST	38h
1C21  FF                   RST	38h
1C22  FF                   RST	38h
1C23  FF                   RST	38h
1C24  FF                   RST	38h
1C25  FF                   RST	38h
1C26  FF                   RST	38h
1C27  FF                   RST	38h
1C28  FF                   RST	38h
1C29  FF                   RST	38h
1C2A  FF                   RST	38h
1C2B  FF                   RST	38h
1C2C  FF                   RST	38h
1C2D  FF                   RST	38h
1C2E  FF                   RST	38h
1C2F  FF                   RST	38h
1C30  FF                   RST	38h
1C31  FF                   RST	38h
1C32  FF                   RST	38h
1C33  FF                   RST	38h
1C34  FF                   RST	38h
1C35  FF                   RST	38h
1C36  FF                   RST	38h
1C37  FF                   RST	38h
1C38  FF                   RST	38h
1C39  FF                   RST	38h
1C3A  FF                   RST	38h
1C3B  FF                   RST	38h
1C3C  FF                   RST	38h
1C3D  FF                   RST	38h
1C3E  FF                   RST	38h
1C3F  FF                   RST	38h
1C40  FF                   RST	38h
1C41  FF                   RST	38h
1C42  FF                   RST	38h
1C43  FF                   RST	38h
1C44  FF                   RST	38h
1C45  FF                   RST	38h
1C46  FF                   RST	38h
1C47  FF                   RST	38h
1C48  FF                   RST	38h
1C49  FF                   RST	38h
1C4A  FF                   RST	38h
1C4B  FF                   RST	38h
1C4C  FF                   RST	38h
1C4D  FF                   RST	38h
1C4E  FF                   RST	38h
1C4F  FF                   RST	38h
1C50  FF                   RST	38h
1C51  FF                   RST	38h
1C52  FF                   RST	38h
1C53  FF                   RST	38h
1C54  FF                   RST	38h
1C55  FF                   RST	38h
1C56  FF                   RST	38h
1C57  FF                   RST	38h
1C58  FF                   RST	38h
1C59  FF                   RST	38h
1C5A  FF                   RST	38h
1C5B  FF                   RST	38h
1C5C  FF                   RST	38h
1C5D  FF                   RST	38h
1C5E  FF                   RST	38h
1C5F  FF                   RST	38h
1C60  FF                   RST	38h
1C61  FF                   RST	38h
1C62  FF                   RST	38h
1C63  FF                   RST	38h
1C64  FF                   RST	38h
1C65  FF                   RST	38h
1C66  FF                   RST	38h
1C67  FF                   RST	38h
1C68  FF                   RST	38h
1C69  FF                   RST	38h
1C6A  FF                   RST	38h
1C6B  FF                   RST	38h
1C6C  FF                   RST	38h
1C6D  FF                   RST	38h
1C6E  FF                   RST	38h
1C6F  FF                   RST	38h
1C70  FF                   RST	38h
1C71  FF                   RST	38h
1C72  FF                   RST	38h
1C73  FF                   RST	38h
1C74  FF                   RST	38h
1C75  FF                   RST	38h
1C76  FF                   RST	38h
1C77  FF                   RST	38h
1C78  FF                   RST	38h
1C79  FF                   RST	38h
1C7A  FF                   RST	38h
1C7B  FF                   RST	38h
1C7C  FF                   RST	38h
1C7D  FF                   RST	38h
1C7E  FF                   RST	38h
1C7F  FF                   RST	38h
1C80  FF                   RST	38h
1C81  FF                   RST	38h
1C82  FF                   RST	38h
1C83  FF                   RST	38h
1C84  FF                   RST	38h
1C85  FF                   RST	38h
1C86  FF                   RST	38h
1C87  FF                   RST	38h
1C88  FF                   RST	38h
1C89  FF                   RST	38h
1C8A  FF                   RST	38h
1C8B  FF                   RST	38h
1C8C  FF                   RST	38h
1C8D  FF                   RST	38h
1C8E  FF                   RST	38h
1C8F  FF                   RST	38h
1C90  FF                   RST	38h
1C91  FF                   RST	38h
1C92  FF                   RST	38h
1C93  FF                   RST	38h
1C94  FF                   RST	38h
1C95  FF                   RST	38h
1C96  FF                   RST	38h
1C97  FF                   RST	38h
1C98  FF                   RST	38h
1C99  FF                   RST	38h
1C9A  FF                   RST	38h
1C9B  FF                   RST	38h
1C9C  FF                   RST	38h
1C9D  FF                   RST	38h
1C9E  FF                   RST	38h
1C9F  FF                   RST	38h
1CA0  FF                   RST	38h
1CA1  FF                   RST	38h
1CA2  FF                   RST	38h
1CA3  FF                   RST	38h
1CA4  FF                   RST	38h
1CA5  FF                   RST	38h
1CA6  FF                   RST	38h
1CA7  FF                   RST	38h
1CA8  FF                   RST	38h
1CA9  FF                   RST	38h
1CAA  FF                   RST	38h
1CAB  FF                   RST	38h
1CAC  FF                   RST	38h
1CAD  FF                   RST	38h
1CAE  FF                   RST	38h
1CAF  FF                   RST	38h
1CB0  FF                   RST	38h
1CB1  FF                   RST	38h
1CB2  FF                   RST	38h
1CB3  FF                   RST	38h
1CB4  FF                   RST	38h
1CB5  FF                   RST	38h
1CB6  FF                   RST	38h
1CB7  FF                   RST	38h
1CB8  FF                   RST	38h
1CB9  FF                   RST	38h
1CBA  FF                   RST	38h
1CBB  FF                   RST	38h
1CBC  FF                   RST	38h
1CBD  FF                   RST	38h
1CBE  FF                   RST	38h
1CBF  FF                   RST	38h
1CC0  FF                   RST	38h
1CC1  FF                   RST	38h
1CC2  FF                   RST	38h
1CC3  FF                   RST	38h
1CC4  FF                   RST	38h
1CC5  FF                   RST	38h
1CC6  FF                   RST	38h
1CC7  FF                   RST	38h
1CC8  FF                   RST	38h
1CC9  FF                   RST	38h
1CCA  FF                   RST	38h
1CCB  FF                   RST	38h
1CCC  FF                   RST	38h
1CCD  FF                   RST	38h
1CCE  FF                   RST	38h
1CCF  FF                   RST	38h
1CD0  FF                   RST	38h
1CD1  FF                   RST	38h
1CD2  FF                   RST	38h
1CD3  FF                   RST	38h
1CD4  FF                   RST	38h
1CD5  FF                   RST	38h
1CD6  FF                   RST	38h
1CD7  FF                   RST	38h
1CD8  FF                   RST	38h
1CD9  FF                   RST	38h
1CDA  FF                   RST	38h
1CDB  FF                   RST	38h
1CDC  FF                   RST	38h
1CDD  FF                   RST	38h
1CDE  FF                   RST	38h
1CDF  FF                   RST	38h
1CE0  FF                   RST	38h
1CE1  FF                   RST	38h
1CE2  FF                   RST	38h
1CE3  FF                   RST	38h
1CE4  FF                   RST	38h
1CE5  FF                   RST	38h
1CE6  FF                   RST	38h
1CE7  FF                   RST	38h
1CE8  FF                   RST	38h
1CE9  FF                   RST	38h
1CEA  FF                   RST	38h
1CEB  FF                   RST	38h
1CEC  FF                   RST	38h
1CED  FF                   RST	38h
1CEE  FF                   RST	38h
1CEF  FF                   RST	38h
1CF0  FF                   RST	38h
1CF1  FF                   RST	38h
1CF2  FF                   RST	38h
1CF3  FF                   RST	38h
1CF4  FF                   RST	38h
1CF5  FF                   RST	38h
1CF6  FF                   RST	38h
1CF7  FF                   RST	38h
1CF8  FF                   RST	38h
1CF9  FF                   RST	38h
1CFA  FF                   RST	38h
1CFB  FF                   RST	38h
1CFC  FF                   RST	38h
1CFD  FF                   RST	38h
1CFE  FF                   RST	38h
1CFF  FF                   RST	38h
1D00  FF                   RST	38h
1D01  FF                   RST	38h
1D02  FF                   RST	38h
1D03  FF                   RST	38h
1D04  FF                   RST	38h
1D05  FF                   RST	38h
1D06  FF                   RST	38h
1D07  FF                   RST	38h
1D08  FF                   RST	38h
1D09  FF                   RST	38h
1D0A  FF                   RST	38h
1D0B  FF                   RST	38h
1D0C  FF                   RST	38h
1D0D  FF                   RST	38h
1D0E  FF                   RST	38h
1D0F  FF                   RST	38h
1D10  FF                   RST	38h
1D11  FF                   RST	38h
1D12  FF                   RST	38h
1D13  FF                   RST	38h
1D14  FF                   RST	38h
1D15  FF                   RST	38h
1D16  FF                   RST	38h
1D17  FF                   RST	38h
1D18  FF                   RST	38h
1D19  FF                   RST	38h
1D1A  FF                   RST	38h
1D1B  FF                   RST	38h
1D1C  FF                   RST	38h
1D1D  FF                   RST	38h
1D1E  FF                   RST	38h
1D1F  FF                   RST	38h
1D20  FF                   RST	38h
1D21  FF                   RST	38h
1D22  FF                   RST	38h
1D23  FF                   RST	38h
1D24  FF                   RST	38h
1D25  FF                   RST	38h
1D26  FF                   RST	38h
1D27  FF                   RST	38h
1D28  FF                   RST	38h
1D29  FF                   RST	38h
1D2A  FF                   RST	38h
1D2B  FF                   RST	38h
1D2C  FF                   RST	38h
1D2D  FF                   RST	38h
1D2E  FF                   RST	38h
1D2F  FF                   RST	38h
1D30  FF                   RST	38h
1D31  FF                   RST	38h
1D32  FF                   RST	38h
1D33  FF                   RST	38h
1D34  FF                   RST	38h
1D35  FF                   RST	38h
1D36  FF                   RST	38h
1D37  FF                   RST	38h
1D38  FF                   RST	38h
1D39  FF                   RST	38h
1D3A  FF                   RST	38h
1D3B  FF                   RST	38h
1D3C  FF                   RST	38h
1D3D  FF                   RST	38h
1D3E  FF                   RST	38h
1D3F  FF                   RST	38h
1D40  FF                   RST	38h
1D41  FF                   RST	38h
1D42  FF                   RST	38h
1D43  FF                   RST	38h
1D44  FF                   RST	38h
1D45  FF                   RST	38h
1D46  FF                   RST	38h
1D47  FF                   RST	38h
1D48  FF                   RST	38h
1D49  FF                   RST	38h
1D4A  FF                   RST	38h
1D4B  FF                   RST	38h
1D4C  FF                   RST	38h
1D4D  FF                   RST	38h
1D4E  FF                   RST	38h
1D4F  FF                   RST	38h
1D50  FF                   RST	38h
1D51  FF                   RST	38h
1D52  FF                   RST	38h
1D53  FF                   RST	38h
1D54  FF                   RST	38h
1D55  FF                   RST	38h
1D56  FF                   RST	38h
1D57  FF                   RST	38h
1D58  FF                   RST	38h
1D59  FF                   RST	38h
1D5A  FF                   RST	38h
1D5B  FF                   RST	38h
1D5C  FF                   RST	38h
1D5D  FF                   RST	38h
1D5E  FF                   RST	38h
1D5F  FF                   RST	38h
1D60  FF                   RST	38h
1D61  FF                   RST	38h
1D62  FF                   RST	38h
1D63  FF                   RST	38h
1D64  FF                   RST	38h
1D65  FF                   RST	38h
1D66  FF                   RST	38h
1D67  FF                   RST	38h
1D68  FF                   RST	38h
1D69  FF                   RST	38h
1D6A  FF                   RST	38h
1D6B  FF                   RST	38h
1D6C  FF                   RST	38h
1D6D  FF                   RST	38h
1D6E  FF                   RST	38h
1D6F  FF                   RST	38h
1D70  FF                   RST	38h
1D71  FF                   RST	38h
1D72  FF                   RST	38h
1D73  FF                   RST	38h
1D74  FF                   RST	38h
1D75  FF                   RST	38h
1D76  FF                   RST	38h
1D77  FF                   RST	38h
1D78  FF                   RST	38h
1D79  FF                   RST	38h
1D7A  FF                   RST	38h
1D7B  FF                   RST	38h
1D7C  FF                   RST	38h
1D7D  FF                   RST	38h
1D7E  FF                   RST	38h
1D7F  FF                   RST	38h
1D80  FF                   RST	38h
1D81  FF                   RST	38h
1D82  FF                   RST	38h
1D83  FF                   RST	38h
1D84  FF                   RST	38h
1D85  FF                   RST	38h
1D86  FF                   RST	38h
1D87  FF                   RST	38h
1D88  FF                   RST	38h
1D89  FF                   RST	38h
1D8A  FF                   RST	38h
1D8B  FF                   RST	38h
1D8C  FF                   RST	38h
1D8D  FF                   RST	38h
1D8E  FF                   RST	38h
1D8F  FF                   RST	38h
1D90  FF                   RST	38h
1D91  FF                   RST	38h
1D92  FF                   RST	38h
1D93  FF                   RST	38h
1D94  FF                   RST	38h
1D95  FF                   RST	38h
1D96  FF                   RST	38h
1D97  FF                   RST	38h
1D98  FF                   RST	38h
1D99  FF                   RST	38h
1D9A  FF                   RST	38h
1D9B  FF                   RST	38h
1D9C  FF                   RST	38h
1D9D  FF                   RST	38h
1D9E  FF                   RST	38h
1D9F  FF                   RST	38h
1DA0  FF                   RST	38h
1DA1  FF                   RST	38h
1DA2  FF                   RST	38h
1DA3  FF                   RST	38h
1DA4  FF                   RST	38h
1DA5  FF                   RST	38h
1DA6  FF                   RST	38h
1DA7  FF                   RST	38h
1DA8  FF                   RST	38h
1DA9  FF                   RST	38h
1DAA  FF                   RST	38h
1DAB  FF                   RST	38h
1DAC  FF                   RST	38h
1DAD  FF                   RST	38h
1DAE  FF                   RST	38h
1DAF  FF                   RST	38h
1DB0  FF                   RST	38h
1DB1  FF                   RST	38h
1DB2  FF                   RST	38h
1DB3  FF                   RST	38h
1DB4  FF                   RST	38h
1DB5  FF                   RST	38h
1DB6  FF                   RST	38h
1DB7  FF                   RST	38h
1DB8  FF                   RST	38h
1DB9  FF                   RST	38h
1DBA  FF                   RST	38h
1DBB  FF                   RST	38h
1DBC  FF                   RST	38h
1DBD  FF                   RST	38h
1DBE  FF                   RST	38h
1DBF  FF                   RST	38h
1DC0  FF                   RST	38h
1DC1  FF                   RST	38h
1DC2  FF                   RST	38h
1DC3  FF                   RST	38h
1DC4  FF                   RST	38h
1DC5  FF                   RST	38h
1DC6  FF                   RST	38h
1DC7  FF                   RST	38h
1DC8  FF                   RST	38h
1DC9  FF                   RST	38h
1DCA  FF                   RST	38h
1DCB  FF                   RST	38h
1DCC  FF                   RST	38h
1DCD  FF                   RST	38h
1DCE  FF                   RST	38h
1DCF  FF                   RST	38h
1DD0  FF                   RST	38h
1DD1  FF                   RST	38h
1DD2  FF                   RST	38h
1DD3  FF                   RST	38h
1DD4  FF                   RST	38h
1DD5  FF                   RST	38h
1DD6  FF                   RST	38h
1DD7  FF                   RST	38h
1DD8  FF                   RST	38h
1DD9  FF                   RST	38h
1DDA  FF                   RST	38h
1DDB  FF                   RST	38h
1DDC  FF                   RST	38h
1DDD  FF                   RST	38h
1DDE  FF                   RST	38h
1DDF  FF                   RST	38h
1DE0  FF                   RST	38h
1DE1  FF                   RST	38h
1DE2  FF                   RST	38h
1DE3  FF                   RST	38h
1DE4  FF                   RST	38h
1DE5  FF                   RST	38h
1DE6  FF                   RST	38h
1DE7  FF                   RST	38h
1DE8  FF                   RST	38h
1DE9  FF                   RST	38h
1DEA  FF                   RST	38h
1DEB  FF                   RST	38h
1DEC  FF                   RST	38h
1DED  FF                   RST	38h
1DEE  FF                   RST	38h
1DEF  FF                   RST	38h
1DF0  FF                   RST	38h
1DF1  FF                   RST	38h
1DF2  FF                   RST	38h
1DF3  FF                   RST	38h
1DF4  FF                   RST	38h
1DF5  FF                   RST	38h
1DF6  FF                   RST	38h
1DF7  FF                   RST	38h
1DF8  FF                   RST	38h
1DF9  FF                   RST	38h
1DFA  FF                   RST	38h
1DFB  FF                   RST	38h
1DFC  FF                   RST	38h
1DFD  FF                   RST	38h
1DFE  FF                   RST	38h
1DFF  FF                   RST	38h
1E00  FF                   RST	38h
1E01  FF                   RST	38h
1E02  FF                   RST	38h
1E03  FF                   RST	38h
1E04  FF                   RST	38h
1E05  FF                   RST	38h
1E06  FF                   RST	38h
1E07  FF                   RST	38h
1E08  FF                   RST	38h
1E09  FF                   RST	38h
1E0A  FF                   RST	38h
1E0B  FF                   RST	38h
1E0C  FF                   RST	38h
1E0D  FF                   RST	38h
1E0E  FF                   RST	38h
1E0F  FF                   RST	38h
1E10  FF                   RST	38h
1E11  FF                   RST	38h
1E12  FF                   RST	38h
1E13  FF                   RST	38h
1E14  FF                   RST	38h
1E15  FF                   RST	38h
1E16  FF                   RST	38h
1E17  FF                   RST	38h
1E18  FF                   RST	38h
1E19  FF                   RST	38h
1E1A  FF                   RST	38h
1E1B  FF                   RST	38h
1E1C  FF                   RST	38h
1E1D  FF                   RST	38h
1E1E  FF                   RST	38h
1E1F  FF                   RST	38h
1E20  FF                   RST	38h
1E21  FF                   RST	38h
1E22  FF                   RST	38h
1E23  FF                   RST	38h
1E24  FF                   RST	38h
1E25  FF                   RST	38h
1E26  FF                   RST	38h
1E27  FF                   RST	38h
1E28  FF                   RST	38h
1E29  FF                   RST	38h
1E2A  FF                   RST	38h
1E2B  FF                   RST	38h
1E2C  FF                   RST	38h
1E2D  FF                   RST	38h
1E2E  FF                   RST	38h
1E2F  FF                   RST	38h
1E30  FF                   RST	38h
1E31  FF                   RST	38h
1E32  FF                   RST	38h
1E33  FF                   RST	38h
1E34  FF                   RST	38h
1E35  FF                   RST	38h
1E36  FF                   RST	38h
1E37  FF                   RST	38h
1E38  FF                   RST	38h
1E39  FF                   RST	38h
1E3A  FF                   RST	38h
1E3B  FF                   RST	38h
1E3C  FF                   RST	38h
1E3D  FF                   RST	38h
1E3E  FF                   RST	38h
1E3F  FF                   RST	38h
1E40  FF                   RST	38h
1E41  FF                   RST	38h
1E42  FF                   RST	38h
1E43  FF                   RST	38h
1E44  FF                   RST	38h
1E45  FF                   RST	38h
1E46  FF                   RST	38h
1E47  FF                   RST	38h
1E48  FF                   RST	38h
1E49  FF                   RST	38h
1E4A  FF                   RST	38h
1E4B  FF                   RST	38h
1E4C  FF                   RST	38h
1E4D  FF                   RST	38h
1E4E  FF                   RST	38h
1E4F  FF                   RST	38h
1E50  FF                   RST	38h
1E51  FF                   RST	38h
1E52  FF                   RST	38h
1E53  FF                   RST	38h
1E54  FF                   RST	38h
1E55  FF                   RST	38h
1E56  FF                   RST	38h
1E57  FF                   RST	38h
1E58  FF                   RST	38h
1E59  FF                   RST	38h
1E5A  FF                   RST	38h
1E5B  FF                   RST	38h
1E5C  FF                   RST	38h
1E5D  FF                   RST	38h
1E5E  FF                   RST	38h
1E5F  FF                   RST	38h
1E60  FF                   RST	38h
1E61  FF                   RST	38h
1E62  FF                   RST	38h
1E63  FF                   RST	38h
1E64  FF                   RST	38h
1E65  FF                   RST	38h
1E66  FF                   RST	38h
1E67  FF                   RST	38h
1E68  FF                   RST	38h
1E69  FF                   RST	38h
1E6A  FF                   RST	38h
1E6B  FF                   RST	38h
1E6C  FF                   RST	38h
1E6D  FF                   RST	38h
1E6E  FF                   RST	38h
1E6F  FF                   RST	38h
1E70  FF                   RST	38h
1E71  FF                   RST	38h
1E72  FF                   RST	38h
1E73  FF                   RST	38h
1E74  FF                   RST	38h
1E75  FF                   RST	38h
1E76  FF                   RST	38h
1E77  FF                   RST	38h
1E78  FF                   RST	38h
1E79  FF                   RST	38h
1E7A  FF                   RST	38h
1E7B  FF                   RST	38h
1E7C  FF                   RST	38h
1E7D  FF                   RST	38h
1E7E  FF                   RST	38h
1E7F  FF                   RST	38h
1E80  FF                   RST	38h
1E81  FF                   RST	38h
1E82  FF                   RST	38h
1E83  FF                   RST	38h
1E84  FF                   RST	38h
1E85  FF                   RST	38h
1E86  FF                   RST	38h
1E87  FF                   RST	38h
1E88  FF                   RST	38h
1E89  FF                   RST	38h
1E8A  FF                   RST	38h
1E8B  FF                   RST	38h
1E8C  FF                   RST	38h
1E8D  FF                   RST	38h
1E8E  FF                   RST	38h
1E8F  FF                   RST	38h
1E90  FF                   RST	38h
1E91  FF                   RST	38h
1E92  FF                   RST	38h
1E93  FF                   RST	38h
1E94  FF                   RST	38h
1E95  FF                   RST	38h
1E96  FF                   RST	38h
1E97  FF                   RST	38h
1E98  FF                   RST	38h
1E99  FF                   RST	38h
1E9A  FF                   RST	38h
1E9B  FF                   RST	38h
1E9C  FF                   RST	38h
1E9D  FF                   RST	38h
1E9E  FF                   RST	38h
1E9F  FF                   RST	38h
1EA0  FF                   RST	38h
1EA1  FF                   RST	38h
1EA2  FF                   RST	38h
1EA3  FF                   RST	38h
1EA4  FF                   RST	38h
1EA5  FF                   RST	38h
1EA6  FF                   RST	38h
1EA7  FF                   RST	38h
1EA8  FF                   RST	38h
1EA9  FF                   RST	38h
1EAA  FF                   RST	38h
1EAB  FF                   RST	38h
1EAC  FF                   RST	38h
1EAD  FF                   RST	38h
1EAE  FF                   RST	38h
1EAF  FF                   RST	38h
1EB0  FF                   RST	38h
1EB1  FF                   RST	38h
1EB2  FF                   RST	38h
1EB3  FF                   RST	38h
1EB4  FF                   RST	38h
1EB5  FF                   RST	38h
1EB6  FF                   RST	38h
1EB7  FF                   RST	38h
1EB8  FF                   RST	38h
1EB9  FF                   RST	38h
1EBA  FF                   RST	38h
1EBB  FF                   RST	38h
1EBC  FF                   RST	38h
1EBD  FF                   RST	38h
1EBE  FF                   RST	38h
1EBF  FF                   RST	38h
1EC0  FF                   RST	38h
1EC1  FF                   RST	38h
1EC2  FF                   RST	38h
1EC3  FF                   RST	38h
1EC4  FF                   RST	38h
1EC5  FF                   RST	38h
1EC6  FF                   RST	38h
1EC7  FF                   RST	38h
1EC8  FF                   RST	38h
1EC9  FF                   RST	38h
1ECA  FF                   RST	38h
1ECB  FF                   RST	38h
1ECC  FF                   RST	38h
1ECD  FF                   RST	38h
1ECE  FF                   RST	38h
1ECF  FF                   RST	38h
1ED0  FF                   RST	38h
1ED1  FF                   RST	38h
1ED2  FF                   RST	38h
1ED3  FF                   RST	38h
1ED4  FF                   RST	38h
1ED5  FF                   RST	38h
1ED6  FF                   RST	38h
1ED7  FF                   RST	38h
1ED8  FF                   RST	38h
1ED9  FF                   RST	38h
1EDA  FF                   RST	38h
1EDB  FF                   RST	38h
1EDC  FF                   RST	38h
1EDD  FF                   RST	38h
1EDE  FF                   RST	38h
1EDF  FF                   RST	38h
1EE0  FF                   RST	38h
1EE1  FF                   RST	38h
1EE2  FF                   RST	38h
1EE3  FF                   RST	38h
1EE4  FF                   RST	38h
1EE5  FF                   RST	38h
1EE6  FF                   RST	38h
1EE7  FF                   RST	38h
1EE8  FF                   RST	38h
1EE9  FF                   RST	38h
1EEA  FF                   RST	38h
1EEB  FF                   RST	38h
1EEC  FF                   RST	38h
1EED  FF                   RST	38h
1EEE  FF                   RST	38h
1EEF  FF                   RST	38h
1EF0  FF                   RST	38h
1EF1  FF                   RST	38h
1EF2  FF                   RST	38h
1EF3  FF                   RST	38h
1EF4  FF                   RST	38h
1EF5  FF                   RST	38h
1EF6  FF                   RST	38h
1EF7  FF                   RST	38h
1EF8  FF                   RST	38h
1EF9  FF                   RST	38h
1EFA  FF                   RST	38h
1EFB  FF                   RST	38h
1EFC  FF                   RST	38h
1EFD  FF                   RST	38h
1EFE  FF                   RST	38h
1EFF  FF                   RST	38h
1F00  FF                   RST	38h
1F01  FF                   RST	38h
1F02  FF                   RST	38h
1F03  FF                   RST	38h
1F04  FF                   RST	38h
1F05  FF                   RST	38h
1F06  FF                   RST	38h
1F07  FF                   RST	38h
1F08  FF                   RST	38h
1F09  FF                   RST	38h
1F0A  FF                   RST	38h
1F0B  FF                   RST	38h
1F0C  FF                   RST	38h
1F0D  FF                   RST	38h
1F0E  FF                   RST	38h
1F0F  FF                   RST	38h
1F10  FF                   RST	38h
1F11  FF                   RST	38h
1F12  FF                   RST	38h
1F13  FF                   RST	38h
1F14  FF                   RST	38h
1F15  FF                   RST	38h
1F16  FF                   RST	38h
1F17  FF                   RST	38h
1F18  FF                   RST	38h
1F19  FF                   RST	38h
1F1A  FF                   RST	38h
1F1B  FF                   RST	38h
1F1C  FF                   RST	38h
1F1D  FF                   RST	38h
1F1E  FF                   RST	38h
1F1F  FF                   RST	38h
1F20  FF                   RST	38h
1F21  FF                   RST	38h
1F22  FF                   RST	38h
1F23  FF                   RST	38h
1F24  FF                   RST	38h
1F25  FF                   RST	38h
1F26  FF                   RST	38h
1F27  FF                   RST	38h
1F28  FF                   RST	38h
1F29  FF                   RST	38h
1F2A  FF                   RST	38h
1F2B  FF                   RST	38h
1F2C  FF                   RST	38h
1F2D  FF                   RST	38h
1F2E  FF                   RST	38h
1F2F  FF                   RST	38h
1F30  FF                   RST	38h
1F31  FF                   RST	38h
1F32  FF                   RST	38h
1F33  FF                   RST	38h
1F34  FF                   RST	38h
1F35  FF                   RST	38h
1F36  FF                   RST	38h
1F37  FF                   RST	38h
1F38  FF                   RST	38h
1F39  FF                   RST	38h
1F3A  FF                   RST	38h
1F3B  FF                   RST	38h
1F3C  FF                   RST	38h
1F3D  FF                   RST	38h
1F3E  FF                   RST	38h
1F3F  FF                   RST	38h
1F40  FF                   RST	38h
1F41  FF                   RST	38h
1F42  FF                   RST	38h
1F43  FF                   RST	38h
1F44  FF                   RST	38h
1F45  FF                   RST	38h
1F46  FF                   RST	38h
1F47  FF                   RST	38h
1F48  FF                   RST	38h
1F49  FF                   RST	38h
1F4A  FF                   RST	38h
1F4B  FF                   RST	38h
1F4C  FF                   RST	38h
1F4D  FF                   RST	38h
1F4E  FF                   RST	38h
1F4F  FF                   RST	38h
1F50  FF                   RST	38h
1F51  FF                   RST	38h
1F52  FF                   RST	38h
1F53  FF                   RST	38h
1F54  FF                   RST	38h
1F55  FF                   RST	38h
1F56  FF                   RST	38h
1F57  FF                   RST	38h
1F58  FF                   RST	38h
1F59  FF                   RST	38h
1F5A  FF                   RST	38h
1F5B  FF                   RST	38h
1F5C  FF                   RST	38h
1F5D  FF                   RST	38h
1F5E  FF                   RST	38h
1F5F  FF                   RST	38h
1F60  FF                   RST	38h
1F61  FF                   RST	38h
1F62  FF                   RST	38h
1F63  FF                   RST	38h
1F64  FF                   RST	38h
1F65  FF                   RST	38h
1F66  FF                   RST	38h
1F67  FF                   RST	38h
1F68  FF                   RST	38h
1F69  FF                   RST	38h
1F6A  FF                   RST	38h
1F6B  FF                   RST	38h
1F6C  FF                   RST	38h
1F6D  FF                   RST	38h
1F6E  FF                   RST	38h
1F6F  FF                   RST	38h
1F70  FF                   RST	38h
1F71  FF                   RST	38h
1F72  FF                   RST	38h
1F73  FF                   RST	38h
1F74  FF                   RST	38h
1F75  FF                   RST	38h
1F76  FF                   RST	38h
1F77  FF                   RST	38h
1F78  FF                   RST	38h
1F79  FF                   RST	38h
1F7A  FF                   RST	38h
1F7B  FF                   RST	38h
1F7C  FF                   RST	38h
1F7D  FF                   RST	38h
1F7E  FF                   RST	38h
1F7F  FF                   RST	38h
1F80  FF                   RST	38h
1F81  FF                   RST	38h
1F82  FF                   RST	38h
1F83  FF                   RST	38h
1F84  FF                   RST	38h
1F85  FF                   RST	38h
1F86  FF                   RST	38h
1F87  FF                   RST	38h
1F88  FF                   RST	38h
1F89  FF                   RST	38h
1F8A  FF                   RST	38h
1F8B  FF                   RST	38h
1F8C  FF                   RST	38h
1F8D  FF                   RST	38h
1F8E  FF                   RST	38h
1F8F  FF                   RST	38h
1F90  FF                   RST	38h
1F91  FF                   RST	38h
1F92  FF                   RST	38h
1F93  FF                   RST	38h
1F94  FF                   RST	38h
1F95  FF                   RST	38h
1F96  FF                   RST	38h
1F97  FF                   RST	38h
1F98  FF                   RST	38h
1F99  FF                   RST	38h
1F9A  FF                   RST	38h
1F9B  FF                   RST	38h
1F9C  FF                   RST	38h
1F9D  FF                   RST	38h
1F9E  FF                   RST	38h
1F9F  FF                   RST	38h
1FA0  FF                   RST	38h
1FA1  FF                   RST	38h
1FA2  FF                   RST	38h
1FA3  FF                   RST	38h
1FA4  FF                   RST	38h
1FA5  FF                   RST	38h
1FA6  FF                   RST	38h
1FA7  FF                   RST	38h
1FA8  FF                   RST	38h
1FA9  FF                   RST	38h
1FAA  FF                   RST	38h
1FAB  FF                   RST	38h
1FAC  FF                   RST	38h
1FAD  FF                   RST	38h
1FAE  FF                   RST	38h
1FAF  FF                   RST	38h
1FB0  FF                   RST	38h
1FB1  FF                   RST	38h
1FB2  FF                   RST	38h
1FB3  FF                   RST	38h
1FB4  FF                   RST	38h
1FB5  FF                   RST	38h
1FB6  FF                   RST	38h
1FB7  FF                   RST	38h
1FB8  FF                   RST	38h
1FB9  FF                   RST	38h
1FBA  FF                   RST	38h
1FBB  FF                   RST	38h
1FBC  FF                   RST	38h
1FBD  FF                   RST	38h
1FBE  FF                   RST	38h
1FBF  FF                   RST	38h
1FC0  FF                   RST	38h
1FC1  FF                   RST	38h
1FC2  FF                   RST	38h
1FC3  FF                   RST	38h
1FC4  FF                   RST	38h
1FC5  FF                   RST	38h
1FC6  FF                   RST	38h
1FC7  FF                   RST	38h
1FC8  FF                   RST	38h
1FC9  FF                   RST	38h
1FCA  FF                   RST	38h
1FCB  FF                   RST	38h
1FCC  FF                   RST	38h
1FCD  FF                   RST	38h
1FCE  FF                   RST	38h
1FCF  FF                   RST	38h
1FD0  FF                   RST	38h
1FD1  FF                   RST	38h
1FD2  FF                   RST	38h
1FD3  FF                   RST	38h
1FD4  FF                   RST	38h
1FD5  FF                   RST	38h
1FD6  FF                   RST	38h
1FD7  FF                   RST	38h
1FD8  FF                   RST	38h
1FD9  FF                   RST	38h
1FDA  FF                   RST	38h
1FDB  FF                   RST	38h
1FDC  FF                   RST	38h
1FDD  FF                   RST	38h
1FDE  FF                   RST	38h
1FDF  FF                   RST	38h
1FE0  FF                   RST	38h
1FE1  FF                   RST	38h
1FE2  FF                   RST	38h
1FE3  FF                   RST	38h
1FE4  FF                   RST	38h
1FE5  FF                   RST	38h
1FE6  FF                   RST	38h
1FE7  FF                   RST	38h
1FE8  FF                   RST	38h
1FE9  FF                   RST	38h
1FEA  FF                   RST	38h
1FEB  FF                   RST	38h
1FEC  FF                   RST	38h
1FED  FF                   RST	38h
1FEE  FF                   RST	38h
1FEF  FF                   RST	38h
1FF0  FF                   RST	38h
1FF1  FF                   RST	38h
1FF2  FF                   RST	38h
1FF3  FF                   RST	38h
1FF4  FF                   RST	38h
1FF5  FF                   RST	38h
1FF6  FF                   RST	38h
1FF7  FF                   RST	38h
1FF8  FF                   RST	38h
1FF9  FF                   RST	38h
1FFA  FF                   RST	38h
1FFB  FF                   RST	38h
1FFC  FF                   RST	38h
1FFD  FF                   RST	38h
1FFE  FF                   RST	38h
1FFF  FF                   RST	38h
