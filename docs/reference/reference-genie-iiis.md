<!-- /docs/reference/reference-genie-iiis.md -->

# Genie IIIs specifics — Grosser chapter 9.4, verbatim

**Provenance.** Extracted from the OCR text layer of Hartmut Grosser,
*Das DOS-Buch für TRS-80, Genie und Colour Genie*, chapter 9.4
("GDOS für Genie IIIs"), pages 9-25 to 9-32. The book's scan is bundled
in the repository (owner-supplied, at
`docs/reference/das_dos-buch_(grosser)_(full_bw_index).pdf`); this file carries only
the technical facts needed for the port, and is a working reference, not a
reproduction of the chapter.

**Stage:** a — stock G-DOS 2.4 on the Genie IIIs.

---

## Port FAh — the System-Port

Named "System-Port" by Grosser at 9-31 and 9-32. Bits established from
his own annotations:

| bit / value | meaning | citation |
| --- | --- | --- |
| bit 0 set | `Video-RAM ausblenden` — video RAM at 3C00h-3FFFh switched **out** | `5101 CB C7 SET 0,A` |
| bit 0 clear | `Video-RAM wieder einblenden` — switched **in** | `510D CB 87 RES 0,A` |
| bit 6 clear | `auf 1.78 MHz umschalten` — slow clock | `50E6 CB B7 RES 6,A` |
| `C4h` | `System-Port auf Normal-Betrieb` — the normal running state | `4212 3E C4`, 9-28 |
| `C5h` | as C4h but video RAM out | `5120 3E C5` |
| `90h` | `EPROM einschalten` | 9-27 |

**`C4h` is correct, normal operation.** Measuring `C4h` on port FAh is
not an anomaly; it is the value the stock boot sector sets at `4212h`
and the value SYS0 restores after each clock-IC access.

## Memory map, normal operation

From 9.3's description of the state the boot sector establishes
(applies to the banking model both machines share):

- EPROM **out**
- Video RAM `3C00h`-`3FFFh` **in**
- Second video RAM `4000h`-`47FFh` **out** — this is the
  high-resolution graphics RAM, two pages; DOS RAM occupies that range
  in normal operation
- FDC and keyboard at `37E0h`-`3BFFh` **in**

## Boot chain, 9-25

1. Boot EPROM copies its loader from `007Ch`-`0199h` to `3800h`-`391Dh`
   and runs it there.
2. The loader reads drive 0 / track 0 / sector 0, single and double
   density alternately, and **stores it nowhere** — it wants only the
   byte at boot-sector offset `E0h`, the disk type: `01h` GDOS, `02h`
   CP/M, `03h` Genie service disk, anything else NEWDOS/80 or GDOS for
   Model I and Genie I/II/IIs.
3. On `01h` it reads the same sector again, this time to `4200h`,
   initialises RAM `4000h`-`405Ch`, and starts at `4200h`.
4. The boot sector loads the BASIC interpreter — appended to SYS0, at
   track 1 sector 20 on double density — into `0000h`-`2FFFh`, plus
   extensions into `3500h`-`4F15h`, and starts it at `4F00h`.
5. That calls the boot sector back **at `420Fh`**, which loads SYS0
   proper (track 1, sector 5) into `400Ch`-`51DEh` and starts it at
   `50E3h` — the clock-IC ZAP — before the normal SYS0 init at `4D00h`.

## Boot sector, 9-28 (differences from NEWDOS/80 Model I marked `>`)

```
4202>30           LUMP# in which the directory begins
4203>36>FF        LD (HL),FF    ;select double density
4206>36>00        LD (HL),00    ;track 0
420A>11>14>01     LD DE,0114    ;track/sector of BASIC
420D>18>03        JR 4212       ;load BASIC from disk
420F>11>05>01     LD DE,0105    ;track/sector of SYS0  <- 2nd entry
4212>3E>C4        LD A,C4       ;System-Port to normal operation
4214>D3>FA        OUT FA
4216>D9           EXX
4249>D5           PUSH DE       ;no SYS0 marker: start at load addr
424A>C0           RET NZ
424B>13           INC DE        ;SYS0 marker: start at load addr + 1
4260 D6>12        SUB 12        ;sectors per track per side
4265 36>11        LD (HL),11    ;select side 1
42AF D6>24        SUB 24        ;sectors per track
42DD              text CLS + "????"  (E0h = 01h, the GDOS type byte)
42E5              text CLS + "GDOS ?"
42C0-42CF         CRT controller initialisation values (see below)
42FD-42FF         PDRIVE parameters for drive 0
```

## SYS0 differences, 9-29 to 9-32 — the load-critical parts

### GETSYS error handling at `4C0Eh`-`4C1Dh`

```
4BDE 28>38        JR Z,4C18   ;if the needed SYS file is already in memory
4C06 CD 28 4C     CALL 4C28   ;load SYS file
4C09 22 1E 4C     LD (4C1E),HL ;SYS file start address -> 4C1E
4C0C 28>0A        JR Z,4C18   ;if no error
                  --- Fehlerbehandlung (error handling) ---
4C0E 3A 17 43     LD A,(4317) ;was SYS4/SYS
4C11 FE 06        CP 06       ;supposed to be loaded?
4C13>28>FE        JR Z,4C13   ;if yes: endless loop
4C15>26>2E        LD H,2E     ;error code "SYSTEM PROGRAM NOT FOUND"
4C17>E3           EX (SP),HL
                  --- SYS-File starten ---
4C18>C1           POP BC
4C19>78           LD A,B
4C1A C1           POP BC
4C1B D1           POP DE
4C1C E1           POP HL
4C1D>CC*00*00     CALL Z,0000 ;if no error: START the SYS file
```

### CRT controller initialisation at `4ECDh` — and the banner

```
4ECD>01>10>00     LD BC,0010  ;initialisation values for the
4ED0>21>C0>42     LD HL,42C0  ;CRT controller, from the
4ED3>11>F0>37     LD DE,37F0  ;PDRIVE sector 42C0-42CF
4ED6>ED>B0        LDIR        ;copied to 37F0
4ED8>CD>B8>37     CALL 37B8   ;initialise the CRT controller with them
4EDB>21>AB>4F     LD HL,4FAB  ;"GENIE DOS 2.1c .. TCS Computer GmbH"
4EDE>CD>67>44     CALL 4467   ;print to screen
4EE1>CD>CD>44     CALL 44CD   ;read clock IC to 4041-4046 if present
```

**The CRT controller is programmed from sixteen bytes at
`42C0h`-`42CFh`**, inside the boot-sector config block. Wrong values
there produce a mis-timed display — a screen of repeating character
pairs is the expected symptom. The banner is printed immediately
afterwards, so no banner means `4ECDh` was not reached or the
controller init left the display unusable.

### Character set selection at `50B0h`

```
50B0 00           NOP
50B1 3E 78        LD A,78     ;code for SYS22/SYS
50B3 18 02        JR 50B7
50B5 3E 38        LD A,38     ;code for SYS22/SYS
50B7 0E 00        LD C,00     ;=> execute DOS command "ZL X"
50BA CD 02 44     CALL 4402   ;load and start SYS22
```

Grosser marks a defect at `4F3Ah`: `JP 50B4` should read `JP 50B5`.

### SYS0 init entry at `50E3h`

```
50E3 DB FA        IN FA       ;System-Port status
50E6 CB B7        RES 6,A     ;switch to 1.78 MHz
50E8 D3 FA        OUT FA
50EA 3E 04        LD A,04     ;test whether a
50EC D3 5B        OUT 5B      ;clock IC
50EE DB 5A        IN 5A       ;is fitted
50F2 D3 FA        OUT FA      ;restore System-Port
5101 CB C7        SET 0,A     ;video RAM out
5103 D3 FA        OUT FA
5105 11 00 3C     LD DE,3C00  ;copy 512D-5178 to 3C00-3C4B
510D CB 87        RES 0,A     ;video RAM back in
510F D3 FA        OUT FA
5111 C3 00 4D     JP 4D00     ;on to SYS0's own initialisation
```

Other IIIs differences of note: verify buffer at `3900h`-`3AFEh`
(`4635`); double-sided handling via `3583h`/`3558h`/`3572h`
(`4699`-`4798`); motor-start delay ~960 ms (`47CA`); comment buffer
`3800h`-`39FEh` (`4C3F`).

---

## Verbatim source extract

Kept for checking anything above against the original OCR.

```
Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-25
9.4 GDOS für Genie IIIs
9.4.1 Initialisierung des DOS
Als erstes wird aus dem BOOT-EPROM der sogenannte Urlader
von 007CH-0199H ins RAM nach 3800H-391DH kopiert und dort
gestartet, um den BOOT-Sector von Diskette (Drive 0, Track
0, Sector 0) in Single oder Double Density (wird abwechselnd probiert) zu lesen. Der BOOT-Sector wird dabei jedoch
nirgendwo im RAM gespeichert, sondern es geht lediglich
darum, das relative Byte EOH des BOOT-Sectors zu erfahren,
welches den Typ der eingelegten Diskette angibt.
GDOS-Disketten haben dort die Kennung 01H, CP/M-Disketten
die Kennung 02H, Genie Service-Disketten die Kennung 03H
und alle übrigen Werte kennzeichnen Disketten für NEWDOS/80
und GDOS auf TRS-80 Model I und Genie I,II,IIs.
Wenn es sich um eine GDOS-Diskette handelt (Kennung 01H)
wird der gleiche BOOT-Sector nochmals von Diskette gelesen,
dieses Mal aber im RAM ab 4200H gespeichert. Vor dem Starten des BOOT-Sectors bei 4200H wird dann noch das RAM im
Bereich 4000H-405CH initialisiert.
Das Programm im BOOT-Sector bewirkt nun, daß erstmal der
BASIC-Interpreter, der an das eigentliche SYS0 angehängt
ist und auf Double Density Disketten ab Track 1, Sector 20D
steht, ins RAM von 0000H bis 2FFFH und einige Erweiterungs-Routinen ins RAM zwischen 3500H und 4F15H geladen und
bei 4F00H gestartet werden.
Von dort wird das Programm im BOOT-Sector erneut aufgerufen, dieses Mal aber bei 420FH, sodaß nun das eigentliche
SYS0, welches auf Double Density Disketten ab Track 1,
Sector 5 steht, ins RAM zwischen 400CH und 51DEH geladen
und bei 50E3H gestartet wird, um für den Fall, daß im Genie
IIIs ein Uhren-IC eingebaut ist, in SYS0 noch einen kleinen
ZAP zu machen.
Für das Format von SYS0 und dessen weitere Initialisierung
bei 4D00H gilt das bereits in Kapitel 2 gesagte.

Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-26
9.4.1.1 Listing des Urladers aus dem BOOT-EPROM
3804 AF XOR A 5
3805 32 95 38 LD (3895),A ;i
3808 3A FF FF LD A,(FFFF) S'
380B CB 47 BIT 0, A ;<
380D 20 52 JR NZ,3861 51
38ÖF CD 68 38 CALL 3868 ;]
V
3812 DD 21 00 00 LD IX,0000
*
3816 7B LD A,E s <
3817 FE 03 CP 03
3819 28 OC JR Z,3827 ;l
381B DD 21 00 FC LD IX,FCOO 5
381F FE 02 CP 02
3821 28 04 JR Z,3827 ;i
3823 DD 21 00 42 LD IX,4200 ;i
3827 3E 02 LD A, 02 5
3829 32 95 38 LD (3895),A ?'
382C CD 68 38 CALL 3868 ; i
382F 31 FE FF LD SP,FFFE ;!
3832 DD E5 PUSH IX ;!
3834 7B LD A,E
3835 FE 03 CP 03 s «
3837 C8 RET Z ;
3838 FE 02 CP 02 S'
383A C8 RET Z 5'
383B F5 PUSH AF Jl
383C E5 PUSH HL
383D 21 E8 38 LD HL,38E8 ; i
3840 11 00 40 LD DE,4000
3843 01 36 00 LD BC,0036
3846 ED BO LDIR
3848 AF XOR A ? l
3849 06 27 LD B, 27
384B 12 LD (DE),A
384C 13 INC DE
384D 10 FC DJNZ 384B
384F El POP HL ;i
3850 Fl POP AF
3851 FE 01 CP 01 5
3853 C8 RET Z 5
B00T-■Sector ggf. nach
3868 21 ED 37 LD HL,37ED 5
386B 36 00 LD (HL),00 5
386D 2B DEC HL j
386E 06 OA LD B, OA 5
3870 36 DO LD (HL),D0 5
3872 CD DF 38 CALL 38DF 5
3875 C5 PUSH BC 5
3876 CD DO 38 CALL 38D0 5
3879 AF XOR A !
387A 32 EE 37 LD (37EE),A ;
387D 32 EF 37 LD (37EF),A 5
3880 36 OB LD (HL),OB 5
Monitor starten
(Genie Service-Diskette)
(BC),A": nächsten Sector
;RAM 4000-4035 initialisieren
;RAM 4036-405C löschen
;Register zurück
Buffer (IX) lesen
Zeiger auf Track-Register des FDC
Track# 00 eintragen
Zeiger auf Kommando/Status-Register
Zähler für Anzahl Versuche
FORCE-INTERRUPT-Kommando an FDC senden
Drive 0 wählen und Motor starten
B retten (Zähler für Anzahl Versuche)
warten, bis der FDC nicht mehr busy ist
Null
ins Sector-Register
und ins Daten-Register schreiben
RESTORE-Kommando an FDC senden

Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-27
3882 CD
3885 36
3887 DD
3889 CI
388A 11
388D CD
3890 18
3892 3A
3895*02
3896 15
3897 C2
389A 5F
389B 03
389C CB
389E C2
38A1 CB
38A3 C2
38A6 CB
38A8 C2
38AB CB
38AD CA
38B0 CB
38B2 C2
38B5 CB
38B7 CA
38BA 7E
38BB 36
38BD CI
38BE E6
38C0 C8
38C1 3E
38C3 BO
38C4 77
38C5 10
38C7 3E
38C9 D3
38CB 3E
38CD C3
38D0 CD
38D3 CB
38D5 20
38D7 7E
38D8 C9
38D9 3E
38DB 3D
38DC 20
38DE C9
38DF 3E
38E1 32
38E4 CD
38E7 C9
DO 38 CALL 38D0 ;warten, bis der FDC nicht mehr busy i
88 LD (HL),88 ;READ-SECTOR-Kommando an FDC senden
E5 PUSH IX ; Bufferadresse
POP BC ;nach BC
00 El LD DE,E100 ;D=Zähler -für E=relatives Byte EOH
D9 38 CALL 38D9 ;ca. 20 us warten
OA JR 389C ;weiter bei 389C
EF 37 LD A,(37EF) ;nächstes Byte vom FDC holen
LD (BC),A ;ggf. in den Buffer schreiben
DEC D 5 Zähler -1
9B 38 JP NZ,389B ;wenn Zähler <> 0
LD E,A ;relatives Byte EOH in E merken
INC BC ;Zeiger auf Buffer +1
4E BIT 1, (HL) ;Data Request ?
92 38 JP NZ, 3892 ;wenn ja
4E BIT 1, (HL) ;Data Request ?
92 38 JP NZ, 3892 ;wenn ja
4E BIT 1,(HL) ;Data Request ?
92 38 JP NZ, 3892 ;wenn ja
46 BIT 0, (HL) ;ist der FDC noch busy ?
BA 38 JP Z, 38BA ;wenn nein
4E BIT 1,(HL) ;Data Request ?
92 38 JP NZ,3892 ;wenn ja
7E BIT 7, (HL) ;sind die Drive-Motoren noch an ?
9C 38 JP Z, 389C ;wenn ja
LD A, (HL) ;Status des FDC lesen
DO LD (HL),D0 ;FORCE-INTERRUPT-Kommando an FDC
POP BC ;B zurück (Zähler für Anzahl Versuche)
FC AND FC ;Error-Bits maskieren
RET Z ;wenn kein Error
Fehlerbehandlung
FE LD A, FE ;bei jedem neuen Versuch
OR B jzwischen Single Density und
LD (HL),A ;Double Density abwechseln
A9 DJNZ 3870 ;noch keine 10D Versuche gemacht ?
90 LD A, 90 ;System-Port:
FA OUT FA ;EPROM einschalten
01 LD A, 01 ;Fehlercode "BOOT ERROR"
6B 00 JP 006B ;weiter im Monitor
Warten, bis der FDC nicht mehr busy ist
D9 38 CALL 38D9 ;ca. 20 us warten
46 BIT 0,(HL) ;Status des FDC lesen
FC JR NZ, 38D3 ;wenn busy: warten
LD A, (HL) ;Status des FDC lesen
RET
ca. 20 us warten (bei 7.2 MHz)
08 LD A, 08 ;Zähler setzen
DEC A ;Zähler -1
FD JR NZ,38DB ;wenn Zähler <> 0
RET
Drive 0 wählen und Motor starten
01 LD A, 01 ;Drive 0 wählen
EO 37 LD (37E0),A ;und Motor starten
D9 38 CALL 38D9 ;ca. 20 us warten
RET

Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-28
9.4.1.2 Unterschiede im BOOT-Sector
Die Stellen, die sich gegenüber dem BOOT-Sector aus NEWD0S/80 Version 2 für
TRS-80 Model I unterscheiden, sind durch ">" markiert:
4200 00
4201 FE
4202>30 {LUMP#, in welcher der Directory beginnt
4203>36>FF LD (HL),FF ;Double Density wählen
4205>23 INC HL ;Zeiger auf Track-Register des FDC
4206>36>00 LD (HL),00 ;Track# 00 eintragen
4208>AF XOR A
4209>AF XOR A
420A>11>14 >01 LD DE,0114 ;DE=Track#,Sector# vom Beginn des BASIC
420D>18>03 JR 4212 ;BASIC-Interpreter von Diskette laden
420F>11>05>01 LD DE,0105 ;DE=Track#,Sector# vom Beginn von SYS0
4212>3E>C4 LD A,C4 ;System-Port auf Normal-Betrieb
4214>D3>FA OUT FA
4216>D9 EXX ;gewünschte Track# und Sector# nach DE’
4217>00 NOP
4249>D5 PUSH DE {wenn keine SYS0-Kennung:
424A>C0 RET NZ {bei Startadresse+O starten
424B>13 INC DE ;wenn SYS0-Kennung:
4240D5 PUSH DE {bei Startadresse+1 starten
424D>C9 RET
424E>00 NOP
4260 D6>12 SUB 12 ;Anzahl Sectoren pro Track pro Seite
4265 36>11 LD (HL),11 ;Seite 1 anwählen
42AF D6>24 SUB 24 {Anzahl Sectoren pro Track
Text CLS + "????"
42DD 1C 1F>3F>01>3F>3F>3F 03 ..?.???.
5bei 42E0 steht die Kennung für GDOS: 01H
Text CLS + "GDOS ?"
42E5 1C 1F>47>44>4F 53>20>3F 03 ..GDOS ?.
Unbenutzt
42EE >64 >7C >32 >39 >7C >FD >75 >35 >FD >CB >34 >C6 >D5 >CD >24
PDRIVE-Parameter für Drive 0
42FD 00 ;PDRIVE+6
42FE>D4 ;PDRIVE+2
42FF>43 ;PDRIVE+7

Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-29
9.4.2 Unterschiede in SYS0/SYS
Die Stellen, die sich
scheiden, sind durch
gegenüber NEWD0S/80 Version 2 für TRS-80 Model I unter-
">" markiert:
44C5 06>2E LD B,2E Trennzeichen für Datum
4500 36>5F LD (HL),5F jCursorzeichen auf Bildschirm
4510 DA>7B 04 JP C,047B ;Fortsetzung der Bildschirm-Routine
454C >C3 >90 >35 JP 3590 ;Fortsetzung der Tastatur-Routine
455B>C3>0E>01 JP 01 OE ;Fortsetzung der Tastatur-Routine
Toggle Flag für Umschaltung Groß/Kleinschrift
4594 >3A >E0 >38 LD A,(38E0) ;Taste LOCK gedrückt ?
4597>E6>08 AND 08
4599>3E>C9 LD A,C9
459B>28>02 JR Z,459F ;wenn nein
459D>EE>C9 X0R C9 ;Toggle Flag
459F>32>B4>45 LD (45B4),A ;neues Flag speichern
45A2>79 LD A, C ;gedrückte Taste
45A3>E6>DF AND DF ;Buchstabe ?
45A5>FE>41 CP 41
45A7>38>05 JR C,45AE ;wenn nein
45A9>FE>5F CP 5F
45AB>79 LD A, C ;gedrückte Taste
45AC >38 >04 JR C,45B2 ;wenn ja: LOCK-Status berücksichtigen
45AE>79
45AF>C9
LD
RET
A, C
45B8 FE>7F CP 7F ;Buchstaben inkl. Umlaute
45FD DC>80>37 CALL C ,3780 ;bei RTC-Interrupts alle definierten
;Interrupt-Routinen bearbeiten
4635 26>39 LD H, 39 ;Veri fy-Buffer = 3900-3AFE
4698>00
Behandlung von
NOP
doppelseitigen Disketten
4699>CD>83>35 CALL 3583 ;Diskette doppelseitig ?
469C CB 09 RRC C ;=> C = Sectors pro Track pro Seite
469E 7B LD A,E ;ist. die gewünschte Sector#
469F 91 SUB C ;auf der Rückseite der Diskette ?
46A0>CD>58>35 CALL 3558 ;Erweiterung: ggf. Bit für Rückseite
46A3>00 NOP ;setzen und bei einem Wechsel der
46A4 >00 NOP ;Disk-Seite ca. 90 ms warten
46A5 CD 67 47 CALL 4767 ;gewünschte Disk-Seite anwählen
4798>CD>72>35 CALL 3572 ;Erweiterung: errechnetes Bit-Muster
;nach 4309 speichern, ohne das Bit für
;die gewählte Disk-Seite zu verändern
47CA 06>FF LD B,FF ;Verzögerung nach dem Starten der
;Drive-Motoren ca. 960 ms

Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-30
47D8 06>18 LD B, 18 Verzögerung für TI=H ca. 90 ms
4BDE 28>38 JR Z,4C18 ;wenn die benötigte SYS-File bereits
;im Speicher steht
SYS-Files laden und starten
4C06 CD 28 4C CALL 4C28 ;SYS-File laden
4C09 22 IE 4C LD (4C1E),HL ;Startadresse der SYS-File nach 4C1E
4C0C 28>0A JR Z,4C1S ;wenn kein Error
Fehlerbehandlung
4C0E 3A 17 43 LD A,(4317) ;sollte SYS4/SYS
4C11 FE 06 CP 06 ;geladen werden ?
4C13>28>FE JR Z,4C13 ;wenn ja: Endlosschleife
4C15>26>2E LD H, 2E ;Fehlercode "SYSTEM PROGRAM NOT FOUND"
4C17>E3 EX (SP),HL ;in den Stack statt gerettetem AF-Wert
SYS-File starten
4C18>C1 POP BC ;BC = ursprünglicher Wert von AF
4C19>78 LD A,B ;A zurück (oder Fehlercode 2E)
4C1A CI POP BC ;BC zurück
4C1B Dl POP DE ;DE zurück
4C1C El POP HL ;HL zurück
4C1D>CC*00*00 CALL Z,0000 ;wenn kein Error: SYS-File starten
********** FEHLER! Nach einem Error beim Laden von SYS-Files **********
********** wird in jedem Fall zum Aufrufer von GETSYS zurück- **********
********** gekehrt, obwohl dieser vielleicht nach DOSRDY **********
********** (402DH), ERR0R0 (4030H) oder DOSCMD (4405H) wollte **********
********** und daher gar nicht mit einer Rückkehr rechnet ! **********
Laden von Programm-Files
4C2E CD 65 4C CALL 4C65
4C31>FE>1F CP 1F
4C33>4F LD C, A
4C34>3E>22 LD A, 22
4C36>D0 RET NC
4C37>CD>65>4C CALL 4C65
4C3A>47 LD B,A
4C3B >CD >65 >4C CALL 4C65
4C3E>6F LD Lj A
4C3F>26>38 LD H,38
4C5B 3E >23 LD A, 23
UP DELAY2
4CF1 CD>4B>37 CALL 374B
4CF4>5F LD E,A
4CF5>C9 RET
4CF6>00 NOP
4CF7 >00 NOP
4D92 2E >08 LD L, 08
;nächstes Byte lesen
;ist das 1. Byte größer als 1EH ?
;C » 1. Byte
;Fehlercode "LOAD FILE FORMAT ERROR"
;wenn ja
;nächstes Byte lesen
;B = 2. Byte
;nächstes Byte lesen
;L = 3. Byte
;HL = Buffer für Kommentare 3800-39FE
;Fehlercode "MEMORY FAULT"
;Verzögerung B * 3.75 ms
5 E-00
;Multiplikations-Faktor für SYSTEM BJ
Test, ob Bildschirm-RAM auf Kleinbuchstaben umgerüstet ist
4E48>00 00>00>00>00>00>00>00>00>00>00 ;gelöscht

Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-31
CRT-Controller initialisieren
4ECD>01>10>00 LD BC,0010 jInitialisierungs-Werte für
4ED0 >21>C0 >42 LD HL,42C0 ;den CRT-Control1 er aus dem
4ED3>11>F0>37 LD DE,37F0 j PDRIVE-Sec t or 42C0-42CF
4ED6>ED>B0 LDIR ;nach 37F0 übertragen
4ED8>CD>B8>37 CALL 37B8 ;CRT-Controller damit initialisieren
4EDB>21>AB>4F LD HL,4FAB ;"GENIE DOS 2.1c .. TCS Computer GmbH"
4EDE>CD>67>44 CALL 4467 •,auf Bildschirm ausgeben
4EE1>CD>CD>44 CALL 44CD 5ggf. Uhren-IC nach 4041-4046 au&lesen
Ende der Initialisierung von SYS0
4F2A 3A 40 38 LD A,(3840) \Tastatur abfragen
4F2D 0F RRCA 5ENTER gedrückt ?
4F2E DA >B0 >50 JP C,50B0 ; wenn ja, weiter bei 50B0
4F31 7E LD A, (HL) ;Zeiger auf AUTO-Befehl
4F32 FE 0D CP OD ;ist ein AUTO-Befehl vorhanden ?
4F34 CA>B0>50 JP Z,50B0 ;wenn nein, weiter bei 50B0
4F37 CD 67 44 CALL 4467 ;AUTO-Befehl auf Bildschirm anzeigen
4F3A C3>B4>50 JP 50B4 ;weiter bei 50B4
********** FEHLER!1 Es muß 50B5 heißen ! **********
4FAB 1B 1B 1B 1B
Text
IB 1B
"GENIE DOS 2.1c ..
BE 8F 8F BD C6 BF
TCS Computer
8F 8F BD C2
GmbH .. GENIE IIIs
4FBB BE 8F 8F BD C2 BE 8F 8F BD C3 BE 8F 8F BD C4 AO
4FCB BE BF C3 20 54 43 53 20 43 6F 6D 70 75 74 65 72 ... TCS Computer
4FDB 20 47 6D 62 48 20 20 OA 00 00 00 00 BF 88 8C BC GmbH .
4FEB 20 45 4E 49 45 20 BF C2 BF C2 BF C2 BF C2 8B 8C ENIE ..
4FFB 8C B4 C4 00 00 00 00 00 00 00 AO 9E 81 C2 80 20
500B 80 80 BF 20 CO 20 20 20 96 83 83 83 84 20 20 20 a t a .
501B 20 C3 20 31 39 38 34 OA AF BC BC 9F C6 BF BC BC . 1984.
502B 9F 20 20 AF BC BC 9F C2 AF BC BC 9F C3 B8 BF BC ...............
503B BC 20 A8 94 20 80 BC BF BC 20 CI 20 A5 BO BO BO ...............
504B 84 80 47 45 4E 49 45 20 49 49 49 20 73 OD 00 00 ..GENIE III s...
Texte -für Datum und Uhrzeit
5063 44>41>54>55>4D>3F 20 28 4D 4D>2E>54>54>2E>4A>4A DATUM? (MM.TT.JJ
5073 29 20 03 ) .
5076>5A>45>49>54 3F 20 20 28 48 48 3A 4D 4D 3A 53 53 ZEIT? (HH:MM:SS
5086 29 20 03 ) .
5089 4D 4D >2E >54 >54 >2E >4A >4A 20 20 48 48 3A 4D 4D 3A MM.TT.JJ HH:MM:
5099 53 53 OD SS.
Neu: Zeichensatz auswählen
50B0 00 NOP 5
50B1 3E 78 LD A, 78 ;Code für SYS22/SYS
50B3 18 02 JR 50B7 ;weiter bei 50B7
50B5 3E 38 LD A, 38 ;Code für SYS22/SYS
50B7 OE 00 LD C,00 ;=> DOS-Befehl "ZL X" ausführen
50B9 F5 PUSH AF ;A retten
50BA CD 02 44 CALL 4402 •SYS22 laden und starten
50BD Fl POP AF ;A zurück
50BE FE 78 CP 78 ;war ein AUTO-Befehl vorhanden ?
50C0 CA 00 44 JP Z,4400 ;wenn nein, Sprung nach DOS READY

Kapitel 9: Andere Betriebssysteme (Genie IIIs) Seite 9-32
50C3 C3 05 44 JP 4405 ; wenn ja, AUTO-Befehl ausführen
Neu: Start der Initialisierung von SYS0/SYS
50E3 DB FA IN FA ;Status des System-Ports
50E5 47 LD B,A ;nach B retten
50E6 CB B7 RES 6,A ;auf 1.78 MHz umschalten
50E8 D3 FA OUT FA
50EA 3E 04 LD A, 04 ;Prüfen,
50EC D3 5B OUT 5B ;ob ein
50EE DB 5A IN 5A ;Uhren-IC
50F0 3C INC A ;eingebaut ist
50F1 78 LD A,B ;alten Zustand des
50F2 D3 FA OUT FA ;System-Ports zurück
50F4 28 1B JR Z,5111 ;wenn kein Uhren-IC vorhanden
ZAP in SYS0 eintragen, wenn Uhren-IC vorhanden
50F6 21 14 51 LD HL,5114 ;5114-512C
50F9 11 CD 44 LD DE,44CD ; nach
50FC 01 19 00 LD BC,0019 ;44CD-44E5
50FF ED BO LDIR ;kopieren
5101 CB C7 SET 0, A ;Video-RAM ausblenden
5103 D3 FA OUT FA
5105 11 00 3C LD DE,3C00 ;512D-5178 nach
5106 01 4C 00 LD BC,004C ;3C00-3C4B
51 OB ED BO LDIR ;kopieren
51OD CB 87 RES 0, A ;Video-RAM wieder einblenden
51 OF D3 FA OUT FA
5111 C3 00 4D JP 4D00 ;zur weiteren Initialisierung von
ZAP für 44CD-44E5: :Interrupt-Routine zum weitersetzen
5114 F3 DI ;Interrupts sperren
5115 21 41 40 LD HL,4041 ;Zeiger auf Datum und Uhrzeit
5118 11 AC 43 LD DE,43AC ;nach 43AC-43B1 kopieren
511B 01 06 00 LD BC,0006
51 IE ED BO LDIR
5120 3E C5 LD A, C5 ;Video-RAM ausblenden
5122 D3 FA OUT FA
5124 CD 00 3C CALL 3C00 ;Uhren-IC nach 4041-4046 lesen
5127 3E C4 LD A,C4 ;Video-RAM wieder einblenden
5129 D3 FA OUT FA
512B FB EI ;Interrrupts wieder erlauben
512C C9 RET
ZAP für 3C00H zum Auslesen des Uhren-IC's
512D DD E5 DD 21 3F 3C 2E 44 OE 02 16 CC 06 03 CD 31
513D 3C 87 5F 87 87 83 5F CD 31 3C 83 77 23 10 EF 16
514D 5C 3E 2B 32 1C 3C 2E 43 OD 20 El DD El AF D3 5B
515D C9 7A D3 5B 16 10 92 57 DD 23 DB 5A DD A6 00 C9
516D OF OF 01 OF 03 OF 03 OF 07 OF 07 OF

```
