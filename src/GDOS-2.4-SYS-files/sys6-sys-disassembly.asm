;************************************************************************
;
; SYS6 from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys6-sys-disassembly.asm
;
;************************************************************************
; SYS6/SYS, stock GDOS 2.4 -- the COPY command (A-48h, C-00h).
;
; Entry 4D00h. Unlike the other SYS modules, SYS6 is not a single
; contiguous 4D00h-51E7h block: it runs to 6FF9h, with two always-zero
; gaps -- 5186h-51FFh and 6487h-64A2h -- filled with 00h below. Grosser
; ch.7 agrees: "SYS6/SYS --
; EOF 34/235, RAM 4D00-6FF9*, Start 4D00". The dispatch/logic code
; lives in the first ~1150 bytes (4D00h-5185h, matching every other SYS
; module's usual footprint); the rest, up to 6FF9h, holds more code
; (COPY's own drive-type/PDRIVE resolution helpers, string tables, and
; sector-copy buffering) reached only through calls into that range --
; not a passive data buffer, which is why it's included here rather than
; left out.
;
;	z80dasm -g 0x4d00 -l -a -t sys6_flat.bin
;
; COPY resolves each drive it's given (source and destination) by calling
; stock DRVSEL (m4776/dgetsl, m6e76 at 6E76h) with the raw DOS drive
; digit, then builds an IX pointer into a static per-drive-type table
; (m6710/m6713 at 6710h/6713h) -- this table lives in SYS6's own
; data page (59xxh), not dpdrv (430Ah); it has nothing to do with our
; driver's PDRIVE data. Separately, m5585/m63ec maintain a status
; bitmask at 5940h/5941h, gated by a per-drive mask byte, that 55B5h/
; 55BDh check to decide whether to print "'ENTER', wenn
; ===> Systemdiskette in Laufwerk Nr. 0" and loop.
;
; THE DRIVE-SLOT TABLE (5942h/594Ch/5956h) -- and this port's one patch
; to this file, boxed at 5942h below.
;
; Boxed annotations sit above the line they describe:
;
;   [PATCH]  a departure from stock GDOS 2.4, with the stock bytes,
;            this build's bytes and the reason for the change.
;   [note]   not from Grosser -- either a finding here, or a place
;            GDOS 2.4 diverges from his 2.1c (his ch.9.4.2).
;   Name:    a routine, as Grosser documents it in ch.3.
;
; Three slots, 10 bytes each: drive number, bit mask, then (at +8) a
; pointer to the name printed when COPY wants that disk mounted. Read
; straight out of the stock binary:
;
;	5942h	drive 00h  mask 01h  -> 5A51h "===> System "  (system diskette)
;	594Ch	drive FFh  mask 02h  -> 5A3Ch "Quelle"         (source)
;	5956h	drive FFh  mask 04h  -> 5A44h "Ziel "          (destination)
;
; FFh means "slot unused, skip it" -- m5585's own guard is
; "LD A,(HL) / INC A / RET Z" at 558Dh. Source and destination start
; unused and are filled in from the command line (4D3Dh/4D40h, then
; m6437's own "LD (BC),A" at 644Eh). m5646 walks all three,
; 10 bytes apart, calling m5658 -> DRVSEL for each slot still in use.
;
; The system slot is never filled in and never FFh: it is hardcoded to
; drive 0. So COPY verifies drive 0 on EVERY copy -- which is why a file
; copy naming neither drive 0 nor a whole disk ("copy rdldemo/job:5 :4")
; fails exactly like "copy 5 6" on this port. When the verify fails,
; m55ec's "CALL 047ECh / JR NZ,m55c1" jumps straight back to the prompt,
; producing a repeating "'ENTER', wenn ===> Systemdiskette in Laufwerk
; Nr. 0".
;
; PATCHED: 5942h, 00h -> 05h (sysvol) -- see the [PATCH] box at 5942h
; below.

m37a9   EQU     37a9h
m37e1   EQU     37e1h
m37ec   EQU     37ech
m37ed   EQU     37edh
m37ee   EQU     37eeh
m37ef   EQU     37efh
m3801   EQU     3801h
m3840   EQU     3840h
m3a2e   EQU     3a2eh
m3b00   EQU     3b00h
m3d03   EQU     3d03h
m3f3f   EQU     3f3fh
DOSRDY  EQU     402dh		;return to the DOS prompt
ERRORO  EQU     4030h		;DOS error output
m4044   EQU     4044h
m4046   EQU     4046h
HIMEM   EQU     4049h		;HIMEM
m41a8   EQU     41a8h
DOSSTK  EQU     41e0h		;initial address of the DOS stack
SECBUF  EQU     4200h		;DOS sector buffer
DIRLEN  EQU     421fh		;length of the directory field
m4252   EQU     4252h
m4255   EQU     4255h
m4281   EQU     4281h
m4287   EQU     4287h
m4296   EQU     4296h
m42c3   EQU     42c3h
m42cb   EQU     42cbh
m42ce   EQU     42ceh
m42d0   EQU     42d0h
m42d7   EQU     42d7h
m42d8   EQU     42d8h
m42dd   EQU     42ddh
m42e5   EQU     42e5h
DMASK   EQU     4309h		;drive-select bit pattern for 37E1h
m430c   EQU     430ch
m4311   EQU     4311h
DMODUL  EQU     4317h		;current /SYS module
DFLAG0  EQU     4369h		;DOS flags: DEBUG, CHAINING, BREAK key, RUN-ONLY (Grosser ch.3)
DFLAG1  EQU     436ah		;DOS operating-state flags
DFLAG2  EQU     436bh		;flags SYS6 manipulates for CLOSE and EXPAND
DFLAG3  EQU     436ch		;further DOS flags
DFLAG4  EQU     436dh		;further DOS flags
m4380   EQU     4380h
DPPTR   EQU     4399h		;pointer into the PDRIVE table
DOSERR  EQU     4409h		;DOS error exit
FINIT   EQU     4420h		;INIT: create the file if it does not exist
FOPEN   EQU     4424h		;OPEN: do not create a new file
m4428   EQU     4428h
READ    EQU     4436h		;read a sector
WRITE   EQU     4439h		;write a sector
VERIFY  EQU     443ch		;verify a sector
m4448   EQU     4448h
DSPLY   EQU     4467h		;display the text at (HL)
m4470   EQU     4470h
m447f   EQU     447fh
USRFCB  EQU     4480h		;FCB for loading and starting user programs
m448c   EQU     448ch
UPCASE  EQU     45b5h		;convert lower case to upper case
m4649   EQU     4649h
m46bd   EQU     46bdh
DCMD    EQU     46c4h		;last FDC command
m46fc   EQU     46fch
m471a   EQU     471ah
m4745   EQU     4745h
m4747   EQU     4747h
m4750   EQU     4750h
m4767   EQU     4767h
DRVSLX  EQU     476eh		;DRVSEL with the drive taken from (IX+6)
m4773   EQU     4773h
DRVSEL  EQU     4776h		;select a drive
m47e3   EQU     47e3h
DSKTST  EQU     47ech		;select the drive, motor on, test 'disk in ?'
m4813   EQU     4813h
m4838   EQU     4838h
m486a   EQU     486ah
m48b8   EQU     48b8h
m48bb   EQU     48bbh
DIRSEC  EQU     490ah		;read a sector from the directory
m491f   EQU     491fh
m4922   EQU     4922h
FDEGET  EQU     492fh		;fetch a file's FDE from the directory
m4930   EQU     4930h
GETFDE  EQU     4936h		;fetch a file's FDE from the directory, second entry
m4947   EQU     4947h
RDFPDE  EQU     494bh		;load the directory sector holding the FPDE (FCB+7) to 4200h, HL to FPDE+0
m4980   EQU     4980h
m49dd   EQU     49ddh
MULHL   EQU     4c92h		;HL * A
MULOV   EQU     4c94h		;HL * A, overflow
m4cb2   EQU     4cb2h
m4cb4   EQU     4cb4h
STRCMP  EQU     4cc5h		;compare the strings at (HL) and (BC)
CHKCHR  EQU     4cd5h		;test the character at (HL)
CHKSEP  EQU     4cd9h		;check for a comma or a blank
m4ced   EQU     4cedh
m4cf8   EQU     4cf8h
m4d3e   EQU     4d3eh		;operand byte inside this module -- self-modified code
m4d6e   EQU     4d6eh		;operand byte inside this module -- self-modified code
m4dfa   EQU     4dfah		;operand byte inside this module -- self-modified code
m4e62   EQU     4e62h		;operand byte inside this module -- self-modified code
m4f85   EQU     4f85h		;operand byte inside this module -- self-modified code
m4fdb   EQU     4fdbh		;operand byte inside this module -- self-modified code
m501c   EQU     501ch		;operand byte inside this module -- self-modified code
m50cf   EQU     50cfh		;operand byte inside this module -- self-modified code
        ORG     4d00h
        LD      IY,m4380                ;4d00
        LD      (IY-69H),00H            ;4d04
        CP      68H                     ;4d08
        JP      Z,m6f4b                 ;4d0a
        SET     3,(IY-17H)              ;4d0d
        CP      28H                     ;4d11
        JP      Z,m65fa                 ;4d13
        CP      48H                     ;4d16
        JP      Z,m4d1e                 ;4d18
        JP      m5208                   ;4d1b
m4d1e   LD      A,(DFLAG1)              ;4d1e
        BIT     6,A                     ;4d21
        JR      NZ,m4d32                ;4d23
        PUSH    HL                      ;4d25
        LD      HL,m5996                ;4d26
        SET     5,(HL)                  ;4d29
        LD      HL,(HIMEM)              ;4d2b
        LD      (m593c),HL              ;4d2e
        POP     HL                      ;4d31
m4d32   PUSH    HL                      ;4d32
        CALL    m6ecb                   ;4d33
        JP      NC,m4d98                ;4d36
        POP     DE                      ;4d39
        LD      (m5aeb),A               ;4d3a
        LD      (m594c),A               ;4d3d
        LD      (m5956),A               ;4d40
        PUSH    HL                      ;4d43
        LD      DE,m64a6                ;4d44
        CALL    m63a3                   ;4d47
        CALL    m6fe5                   ;4d4a
        CALL    m6392                   ;4d4d
        JP      NC,m4d8b                ;4d50
        CALL    m63a0                   ;4d53
        EX      (SP),HL                 ;4d56
        LD      HL,m6e0c                ;4d57
        CALL    DSPLY                   ;4d5a
        POP     HL                      ;4d5d
        CALL    m6fb8                   ;4d5e
        LD      B,20H                   ;4d61
        CALL    m4ea7                   ;4d63
        LD      HL,m5992+2              ;4d66
        LD      A,(HL)                  ;4d69
        AND     0F9H                    ;4d6a
        INC     HL                      ;4d6c
        JR      NZ,m4d72                ;4d6d
        LD      A,(HL)                  ;4d6f
        AND     01H                     ;4d70
m4d72   JR      NZ,m4d79                ;4d72
        DEC     HL                      ;4d74
        LD      A,(HL)                  ;4d75
        OR      40H                     ;4d76
        LD      (HL),A                  ;4d78
m4d79   CALL    m5c96                   ;4d79
        LD      HL,m594c                ;4d7c
        CALL    m6713                   ;4d7f
        CALL    m6710                   ;4d82
        CALL    m4df3                   ;4d85
        JP      m6291                   ;4d88
m4d8b   LD      HL,m5940                ;4d8b
        LD      (HL),06H                ;4d8e
        INC     HL                      ;4d90
        LD      (HL),01H                ;4d91
        POP     HL                      ;4d93
        CALL    m6ec4                   ;4d94
        PUSH    HL                      ;4d97
m4d98   POP     HL                      ;4d98
        LD      A,(HL)                  ;4d99
        CP      24H                     ;4d9a
        JR      NZ,m4da6                ;4d9c
        PUSH    HL                      ;4d9e
        LD      HL,m5940                ;4d9f
        SET     0,(HL)                  ;4da2
        POP     HL                      ;4da4
        INC     HL                      ;4da5
m4da6   LD      DE,m4d3e                ;4da6
        PUSH    DE                      ;4da9
        LD      BC,0050H                ;4daa
        LDIR                            ;4dad
        POP     HL                      ;4daf
        LD      DE,m5ae5                ;4db0
        CALL    m4e8d                   ;4db3
        CALL    m6fe5                   ;4db6
        LD      A,(HL)                  ;4db9
        CP      3AH                     ;4dba
        JR      Z,m4dc6                 ;4dbc
        CP      2EH                     ;4dbe
        JR      Z,m4dc6                 ;4dc0
        CP      2FH                     ;4dc2
        JR      NZ,m4dde                ;4dc4
m4dc6   LD      C,A                     ;4dc6
        LD      B,00H                   ;4dc7
        LD      DE,m5ae5                ;4dc9
m4dcc   LD      A,(DE)                  ;4dcc
        CP      03H                     ;4dcd
        JR      Z,m4dde                 ;4dcf
        CP      C                       ;4dd1
        JR      Z,m4dd8                 ;4dd2
        INC     DE                      ;4dd4
        INC     B                       ;4dd5
        JR      m4dcc                   ;4dd6
m4dd8   DEC     HL                      ;4dd8
        DEC     DE                      ;4dd9
        LD      A,(DE)                  ;4dda
        LD      (HL),A                  ;4ddb
        DJNZ    m4dd8                   ;4ddc
m4dde   CALL    m4e8a                   ;4dde
        PUSH    HL                      ;4de1
        LD      HL,m5996                ;4de2
        SET     2,(HL)                  ;4de5
        INC     HL                      ;4de7
        SET     3,(HL)                  ;4de8
        POP     HL                      ;4dea
        LD      B,08H                   ;4deb
        CALL    m4ea7                   ;4ded
        JP      m6377                   ;4df0
m4df3   CALL    m6424                   ;4df3
        LD      BC,000AH                ;4df6
        LD      A,00H                   ;4df9
        RLCA                            ;4dfb
        RLCA                            ;4dfc
        RLCA                            ;4dfd
        RLCA                            ;4dfe
        ADD     A,C                     ;4dff
        EX      DE,HL                   ;4e00
        LD      HL,m59c5                ;4e01
        LDIR                            ;4e04
        LD      H,D                     ;4e06
        LD      L,A                     ;4e07
        LD      C,06H                   ;4e08
        LDIR                            ;4e0a
        LD      L,C                     ;4e0c
        LD      B,01H                   ;4e0d
        LD      DE,m6eb5                ;4e0f
        LDIR                            ;4e12
        LD      DE,0100H                ;4e14
        LD      A,(m594c)               ;4e17
        OR      A                       ;4e1a
        LD      B,A                     ;4e1b
        JR      NZ,m4e22                ;4e1c
        LD      A,E                     ;4e1e
m4e1f   OR      03H                     ;4e1f
m4e21   LD      E,A                     ;4e21
m4e22   LD      A,(m5956)               ;4e22
        OR      A                       ;4e25
        JR      NZ,m4e2c                ;4e26
        SET     0,E                     ;4e28
        SET     2,E                     ;4e2a
m4e2c   CP      B                       ;4e2c
        JR      NZ,m4e3d                ;4e2d
        LD      A,E                     ;4e2f
        OR      06H                     ;4e30
        LD      E,A                     ;4e32
        LD      A,(DFLAG1)              ;4e33
        BIT     6,A                     ;4e36
        LD      A,15H                   ;4e38
        JP      NZ,m521a                ;4e3a
m4e3d   LD      A,(m5995)               ;4e3d
        BIT     7,A                     ;4e40
        JR      Z,m4e4d                 ;4e42
        LD      A,E                     ;4e44
        CP      06H                     ;4e45
        JP      NC,m5208                ;4e47
        LD      DE,0700H                ;4e4a
m4e4d   LD      A,E                     ;4e4d
        CP      03H                     ;4e4e
        LD      B,80H                   ;4e50
        LD      HL,m5a3c                ;4e52
        CALL    Z,m4e68                 ;4e55
        LD      A,E                     ;4e58
        CP      05H                     ;4e59
        LD      B,40H                   ;4e5b
        LD      HL,m5a44                ;4e5d
        CALL    Z,m4e68                 ;4e60
        LD      (m5940),DE              ;4e63
        RET                             ;4e67
m4e68   DEC     A                       ;4e68
        OR      D                       ;4e69
        LD      C,A                     ;4e6a
        LD      A,(m5997)               ;4e6b
        AND     B                       ;4e6e
        RET     NZ                      ;4e6f
        PUSH    HL                      ;4e70
        LD      HL,m6e22                ;4e71
        CALL    DSPLY                   ;4e74
        POP     HL                      ;4e77
        CALL    DSPLY                   ;4e78
        LD      HL,m6e33                ;4e7b
        CALL    m58de                   ;4e7e
        RET     Z                       ;4e81
        LD      E,00H                   ;4e82
        LD      D,C                     ;4e84
        RET                             ;4e85
        LD      A,D                     ;4e86
        OR      C                       ;4e87
        LD      D,A                     ;4e88
        RET                             ;4e89
m4e8a   LD      DE,m5b17                ;4e8a
m4e8d   LD      B,20H                   ;4e8d
        PUSH    DE                      ;4e8f
m4e90   CALL    CHKCHR                  ;4e90
        JR      NC,m4ea0                ;4e93
m4e95   LD      A,(HL)                  ;4e95
        LD      (DE),A                  ;4e96
        INC     DE                      ;4e97
        INC     HL                      ;4e98
        DJNZ    m4e90                   ;4e99
        LD      A,30H                   ;4e9b
        JP      m521a                   ;4e9d
m4ea0   LD      A,03H                   ;4ea0
        LD      (DE),A                  ;4ea2
        POP     DE                      ;4ea3
        RET     Z                       ;4ea4
        DEC     HL                      ;4ea5
        RET                             ;4ea6
m4ea7   CALL    m6ec0                   ;4ea7
        JP      NZ,m4f1d                ;4eaa
        LD      HL,m5997                ;4ead
        LD      A,(HL)                  ;4eb0
        AND     0CH                     ;4eb1
        JR      NZ,m4eca                ;4eb3
        LD      A,(m5995)               ;4eb5
        AND     80H                     ;4eb8
        PUSH    HL                      ;4eba
        LD      HL,m6e3f                ;4ebb
        CALL    Z,m58de                 ;4ebe
        POP     HL                      ;4ec1
        SET     3,(HL)                  ;4ec2
        JR      Z,m4eca                 ;4ec4
        LD      A,(HL)                  ;4ec6
        XOR     0CH                     ;4ec7
        LD      (HL),A                  ;4ec9
m4eca   LD      DE,(m5996)              ;4eca
        LD      HL,(m5992+2)            ;4ece
        LD      A,D                     ;4ed1
        AND     02H                     ;4ed2
        JR      Z,m4eda                 ;4ed4
        LD      A,L                     ;4ed6
        OR      42H                     ;4ed7
        LD      L,A                     ;4ed9
m4eda   LD      A,E                     ;4eda
        AND     13H                     ;4edb
        JR      NZ,m4ee2                ;4edd
        LD      A,D                     ;4edf
        AND     30H                     ;4ee0
m4ee2   JR      NZ,m4ee7                ;4ee2
        LD      A,H                     ;4ee4
        AND     08H                     ;4ee5
m4ee7   JR      Z,m4eed                 ;4ee7
        BIT     3,E                     ;4ee9
        JR      Z,m4f49                 ;4eeb
m4eed   LD      A,H                     ;4eed
        AND     06H                     ;4eee
        JR      Z,m4efa                 ;4ef0
        BIT     2,D                     ;4ef2
        JR      NZ,m4efa                ;4ef4
        BIT     3,E                     ;4ef6
        JR      Z,m4f49                 ;4ef8
m4efa   BIT     3,E                     ;4efa
        JR      Z,m4f0c                 ;4efc
        BIT     3,D                     ;4efe
        JR      Z,m4f0c                 ;4f00
        LD      A,L                     ;4f02
        AND     0DH                     ;4f03
        JR      NZ,m4f49                ;4f05
        LD      A,H                     ;4f07
        AND     36H                     ;4f08
        JR      NZ,m4f49                ;4f0a
m4f0c   LD      A,H                     ;4f0c
        AND     41H                     ;4f0d
        JR      Z,m4f15                 ;4f0f
        BIT     3,E                     ;4f11
        JR      Z,m4f49                 ;4f13
m4f15   LD      (m5992+2),HL            ;4f15
        LD      (m5996),DE              ;4f18
        RET                             ;4f1c
m4f1d   PUSH    BC                      ;4f1d
        EX      DE,HL                   ;4f1e
        LD      HL,m505c                ;4f1f
m4f22   PUSH    DE                      ;4f22
m4f23   LD      A,(DE)                  ;4f23
        CP      (HL)                    ;4f24
        JR      NZ,m4f4c                ;4f25
        INC     DE                      ;4f27
        INC     HL                      ;4f28
        JR      m4f23                   ;4f29
m4f2b   INC     HL                      ;4f2b
        BIT     7,(HL)                  ;4f2c
m4f2e   JR      Z,m4f2b                 ;4f2e
        LD      A,(HL)                  ;4f30
        BIT     2,A                     ;4f31
        INC     HL                      ;4f33
        JR      Z,m4f3a                 ;4f34
        INC     HL                      ;4f36
        INC     HL                      ;4f37
        INC     HL                      ;4f38
        INC     HL                      ;4f39
m4f3a   BIT     4,A                     ;4f3a
        JR      Z,m4f40                 ;4f3c
        INC     HL                      ;4f3e
        INC     HL                      ;4f3f
m4f40   POP     DE                      ;4f40
        INC     HL                      ;4f41
        LD      A,(HL)                  ;4f42
        OR      A                       ;4f43
        JR      NZ,m4f22                ;4f44
        JP      m5214                   ;4f46
m4f49   JP      m5218                   ;4f49
m4f4c   BIT     7,(HL)                  ;4f4c
        JR      Z,m4f2b                 ;4f4e
        POP     AF                      ;4f50
        LD      A,B                     ;4f51
        AND     (HL)                    ;4f52
        JR      Z,m4f49                 ;4f53
        LD      B,(HL)                  ;4f55
m4f56   INC     HL                      ;4f56
        LD      C,(HL)                  ;4f57
        INC     HL                      ;4f58
        PUSH    DE                      ;4f59
        LD      A,B                     ;4f5a
        AND     03H                     ;4f5b
        LD      E,A                     ;4f5d
m4f5e   LD      D,00H                   ;4f5e
        PUSH    HL                      ;4f60
        LD      HL,m5992+2              ;4f61
        PUSH    HL                      ;4f64
        ADD     HL,DE                   ;4f65
        LD      A,(HL)                  ;4f66
        OR      C                       ;4f67
        LD      (HL),A                  ;4f68
        POP     DE                      ;4f69
        POP     HL                      ;4f6a
        BIT     2,B                     ;4f6b
        JR      Z,m4f7a                 ;4f6d
        LD      C,04H                   ;4f6f
m4f71   LD      A,(DE)                  ;4f71
        AND     (HL)                    ;4f72
        INC     DE                      ;4f73
        INC     HL                      ;4f74
        JR      NZ,m4f49                ;4f75
        DEC     C                       ;4f77
        JR      NZ,m4f71                ;4f78
m4f7a   LD      E,(HL)                  ;4f7a
        INC     HL                      ;4f7b
        LD      D,(HL)                  ;4f7c
        LD      (m4f85),DE              ;4f7d
        POP     HL                      ;4f81
        BIT     4,B                     ;4f82
        CALL    NZ,0000H                ;4f84
        POP     BC                      ;4f87
        JP      m4ea7                   ;4f88
        LD      DE,m5970                ;4f8b
        JR      m4f98                   ;4f8e
        LD      DE,m5968                ;4f90
        JR      m4f98                   ;4f93
m4f95   LD      DE,m5983                ;4f95
m4f98   CALL    m6f8f                   ;4f98
        JR      Z,m4f49                 ;4f9b
        RET                             ;4f9d
        LD      A,(HL)                  ;4f9e
        SUB     32H                     ;4f9f
        CP      05H                     ;4fa1
        INC     HL                      ;4fa3
        JR      NC,m4fcb                ;4fa4
        ADD     A,02H                   ;4fa6
        LD      (m64af),A               ;4fa8
        RET                             ;4fab
        LD      DE,USRFCB               ;4fac
        LD      B,20H                   ;4faf
m4fb1   LD      A,0DH                   ;4fb1
        LD      (DE),A                  ;4fb3
        CALL    CHKCHR                  ;4fb4
        RET     Z                       ;4fb7
        DEC     HL                      ;4fb8
        RET     NC                      ;4fb9
        INC     HL                      ;4fba
        LD      A,(HL)                  ;4fbb
        LD      (DE),A                  ;4fbc
        INC     DE                      ;4fbd
        INC     HL                      ;4fbe
        DJNZ    m4fb1                   ;4fbf
        JR      m4fcb                   ;4fc1
        CALL    m6ee7                   ;4fc3
        LD      (64ACH),A               ;4fc6
m4fc9   OR      A                       ;4fc9
        RET     NZ                      ;4fca
m4fcb   JP      m4f49                   ;4fcb
        CALL    m6ee2                   ;4fce
        LD      (68ABH),A               ;4fd1
        JR      m4fc9                   ;4fd4
        CALL    m6ee2                   ;4fd6
        LD      (68ACH),A               ;4fd9
        RET                             ;4fdc
        CALL    m5025                   ;4fdd
        LD      (m5978),DE              ;4fe0
        RET                             ;4fe4
        CALL    m5025                   ;4fe5
        LD      (m5981),DE              ;4fe8
        RET                             ;4fec
        CALL    m5025                   ;4fed
        LD      (m597a),DE              ;4ff0
        RET                             ;4ff4
        LD      DE,63D6H                ;4ff5
        CALL    m5002                   ;4ff8
        LD      (m4dfa),A               ;4ffb
        RET                             ;4ffe
        LD      DE,63CAH                ;4fff
m5002   PUSH    DE                      ;5002
        CALL    m6ee7                   ;5003
        CP      0AH                     ;5006
        JR      NC,m4fcb                ;5008
        POP     DE                      ;500a
        LD      (DE),A                  ;500b
        RET                             ;500c
        LD      DE,m624c                ;500d
        LD      B,03H                   ;5010
m5012   LD      A,(HL)                  ;5012
        SUB     30H                     ;5013
        CP      0AH                     ;5015
        JR      C,m501e                 ;5017
        SUB     11H                     ;5019
        CP      1AH                     ;501b
        RET     NC                      ;501d
m501e   LD      A,(HL)                  ;501e
        LD      (DE),A                  ;501f
        INC     DE                      ;5020
        INC     HL                      ;5021
        DJNZ    m5012                   ;5022
        RET                             ;5024
m5025   LD      DE,m5960                ;5025
        CALL    m6f8f                   ;5028
        PUSH    HL                      ;502b
        EX      DE,HL                   ;502c
        LD      DE,0FFFFH               ;502d
        LD      B,08H                   ;5030
m5032   PUSH    BC                      ;5032
        LD      A,E                     ;5033
        AND     07H                     ;5034
        LD      C,A                     ;5036
        LD      A,E                     ;5037
        RLCA                            ;5038
        RLCA                            ;5039
        RLCA                            ;503a
        XOR     C                       ;503b
        RLCA                            ;503c
        LD      C,A                     ;503d
        AND     0F0H                    ;503e
        LD      B,A                     ;5040
        LD      A,C                     ;5041
        RLCA                            ;5042
        AND     1FH                     ;5043
        XOR     B                       ;5045
        XOR     D                       ;5046
        LD      E,A                     ;5047
        LD      A,C                     ;5048
        AND     0FH                     ;5049
        LD      B,A                     ;504b
        LD      A,C                     ;504c
        RLCA                            ;504d
        RLCA                            ;504e
        RLCA                            ;504f
        RLCA                            ;5050
        XOR     B                       ;5051
        POP     BC                      ;5052
        DEC     HL                      ;5053
        XOR     (HL)                    ;5054
        LD      D,A                     ;5055
        LD      (HL),20H                ;5056
        DJNZ    m5032                   ;5058
        POP     HL                      ;505a
        RET                             ;505b
m505c   LD      B,(HL)                  ;505c
        LD      D,D                     ;505d
        LD      B,C                     ;505e
        LD      B,A                     ;505f
        AND     C                       ;5060
        LD      B,B                     ;5061
        LD      B,C                     ;5062
        LD      B,L                     ;5063
        LD      C,C                     ;5064
        LD      D,(HL)                  ;5065
        DEC     A                       ;5066
        PUSH    AF                      ;5067
        LD      (BC),A                  ;5068
        NOP                             ;5069
        NOP                             ;506a
        NOP                             ;506b
        LD      A,(BC)                  ;506c
        SBC     A,(HL)                  ;506d
        LD      C,A                     ;506e
        LD      B,C                     ;506f
        LD      E,D                     ;5070
        LD      C,E                     ;5071
        LD      D,A                     ;5072
        DEC     A                       ;5073
        OR      L                       ;5074
        LD      BC,00C0H                ;5075
        NOP                             ;5078
        NOP                             ;5079
        LD      R,A                     ;507a
        LD      C,(HL)                  ;507c
        LD      E,D                     ;507d
        LD      C,E                     ;507e
        LD      D,A                     ;507f
        DEC     A                       ;5080
        OR      L                       ;5081
        JR      NZ,m5086                ;5082
        NOP                             ;5084
        NOP                             ;5085
m5086   NOP                             ;5086
        PUSH    HL                      ;5087
        LD      C,A                     ;5088
        LD      D,E                     ;5089
        LD      B,D                     ;508a
        LD      C,C                     ;508b
        LD      D,(HL)                  ;508c
        DEC     A                       ;508d
        PUSH    AF                      ;508e
        INC     B                       ;508f
        NOP                             ;5090
        NOP                             ;5091
        NOP                             ;5092
        LD      A,(BC)                  ;5093
        JP      m514f                   ;5094
        LD      D,B                     ;5097
        LD      B,H                     ;5098
        LD      C,(HL)                  ;5099
        DEC     A                       ;509a
        CP      E                       ;509b
        ADD     A,B                     ;509c
        RST     38H                     ;509d
        LD      C,A                     ;509e
        LD      E,D                     ;509f
        LD      D,B                     ;50a0
        LD      B,H                     ;50a1
        LD      C,(HL)                  ;50a2
        DEC     A                       ;50a3
        EI                              ;50a4
        LD      B,B                     ;50a5
        PUSH    AF                      ;50a6
        LD      C,A                     ;50a7
        LD      D,E                     ;50a8
        LD      D,B                     ;50a9
        LD      D,L                     ;50aa
        LD      D,D                     ;50ab
        DEC     A                       ;50ac
        RST     10H                     ;50ad
        LD      (BC),A                  ;50ae
        CP      C                       ;50af
        ADD     A,(HL)                  ;50b0
        NOP                             ;50b1
        NOP                             ;50b2
m50b3   SUB     4FH                     ;50b3
        LD      D,E                     ;50b5
        LD      D,H                     ;50b6
        LD      C,A                     ;50b7
        LD      D,B                     ;50b8
        DEC     A                       ;50b9
        OUT     (01H),A                 ;50ba
        ADC     A,4FH                   ;50bc
        LD      C,(HL)                  ;50be
m50bf   LD      E,D                     ;50bf
        LD      C,(HL)                  ;50c0
        DEC     A                       ;50c1
        OR      H                       ;50c2
        INC     B                       ;50c3
        LD      A,(BC)                  ;50c4
        NOP                             ;50c5
        NOP                             ;50c6
        NOP                             ;50c7
        SUB     L                       ;50c8
        LD      C,A                     ;50c9
        LD      B,C                     ;50ca
        LD      E,D                     ;50cb
        LD      C,(HL)                  ;50cc
        DEC     A                       ;50cd
        CALL    P,0C010H                ;50ce
        NOP                             ;50d1
        NOP                             ;50d2
        LD      (BC),A                  ;50d3
        ADC     A,E                     ;50d4
        LD      C,A                     ;50d5
        LD      E,D                     ;50d6
        LD      E,D                     ;50d7
        LD      C,(HL)                  ;50d8
        LD      B,H                     ;50d9
        CALL    PO,0C020H               ;50da
        ADD     A,B                     ;50dd
        NOP                             ;50de
        LD      (BC),A                  ;50df
        LD      C,E                     ;50e0
        LD      B,H                     ;50e1
        LD      D,A                     ;50e2
        LD      B,C                     ;50e3
        PUSH    HL                      ;50e4
        ADD     A,B                     ;50e5
        JR      NZ,m50e8                ;50e6
m50e8   NOP                             ;50e8
        NOP                             ;50e9
        LD      D,C                     ;50ea
        LD      C,E                     ;50eb
        LD      D,A                     ;50ec
        DEC     A                       ;50ed
        OR      D                       ;50ee
        LD      B,B                     ;50ef
        DEFB    0DDH,4FH,4EH            ;50f0
        LD      B,(HL)                  ;50f3
        LD      C,L                     ;50f4
        LD      D,H                     ;50f5
        AND     A                       ;50f6
        EX      AF,AF'                  ;50f7
        NOP                             ;50f8
        LD      B,00H                   ;50f9
        INC     B                       ;50fb
        LD      E,B                     ;50fc
        LD      B,H                     ;50fd
m50fe   LD      C,H                     ;50fe
        DEC     A                       ;50ff
m5100   OR      A                       ;5100
        JR      NZ,m5103                ;5101
m5103   NOP                             ;5103
        NOP                             ;5104
        DJNZ    m50b3                   ;5105
        LD      C,A                     ;5107
        LD      C,C                     ;5108
        LD      B,H                     ;5109
        LD      C,H                     ;510a
        DEC     A                       ;510b
        OR      A                       ;510c
        DJNZ    m510f                   ;510d
m510f   NOP                             ;510f
        NOP                             ;5110
        JR      NZ,m50bf                ;5111
        LD      C,A                     ;5113
        LD      B,D                     ;5114
        LD      E,D                     ;5115
        LD      C,(HL)                  ;5116
        CALL    PO,0C608H               ;5117
        NOP                             ;511a
        NOP                             ;511b
        LD      (BC),A                  ;511c
        LD      D,C                     ;511d
        LD      C,(HL)                  ;511e
        DEC     A                       ;511f
        OR      D                       ;5120
        ADD     A,B                     ;5121
        SUB     B                       ;5122
        LD      C,A                     ;5123
        LD      B,D                     ;5124
        LD      E,D                     ;5125
        LD      B,H                     ;5126
        CALL    PO,0C201H               ;5127
        DJNZ    m512c                   ;512a
m512c   LD      (BC),A                  ;512c
        LD      D,E                     ;512d
        LD      D,C                     ;512e
        LD      B,H                     ;512f
        AND     L                       ;5130
        DJNZ    m5136                   ;5131
        NOP                             ;5133
        NOP                             ;5134
        NOP                             ;5135
m5136   LD      C,C                     ;5136
        LD      D,(HL)                  ;5137
        LD      D,L                     ;5138
        CALL    PO,0C02H                ;5139
        JR      NC,m5146                ;513c
        NOP                             ;513e
        LD      C,D                     ;513f
        LD      C,B                     ;5140
        LD      C,H                     ;5141
        AND     D                       ;5142
        JR      NZ,m518a                ;5143
        LD      B,H                     ;5145
m5146   LD      C,E                     ;5146
        AND     (HL)                    ;5147
        EX      AF,AF'                  ;5148
        LD      (BC),A                  ;5149
        NOP                             ;514a
        NOP                             ;514b
        NOP                             ;514c
        LD      B,D                     ;514d
        LD      B,L                     ;514e
m514f   LD      B,C                     ;514f
        AND     D                       ;5150
        LD      BC,m5246                ;5151
        LD      B,H                     ;5154
        AND     D                       ;5155
        DJNZ    m51a6                   ;5156
        LD      D,(HL)                  ;5158
        LD      B,H                     ;5159
        AND     L                       ;515a
        EX      AF,AF'                  ;515b
        NOP                             ;515c
        NOP                             ;515d
        NOP                             ;515e
        INC     B                       ;515f
        LD      C,L                     ;5160
        LD      B,C                     ;5161
        LD      B,A                     ;5162
        ADD     A,80H                   ;5163
        ADD     HL,BC                   ;5165
        LD      B,00H                   ;5166
        LD      (BC),A                  ;5168
        LD      B,(HL)                  ;5169
        LD      C,L                     ;516a
        LD      D,H                     ;516b
        AND     A                       ;516c
        INC     B                       ;516d
        NOP                             ;516e
        EX      AF,AF'                  ;516f
        NOP                             ;5170
        EX      AF,AF'                  ;5171
        CPL                             ;5172
        OR      D                       ;5173
        LD      (BC),A                  ;5174
        DEC     C                       ;5175
        LD      D,B                     ;5176
        LD      C,D                     ;5177
        CALL    PO,0B940H               ;5178
        LD      BC,0000H                ;517b
        LD      C,(HL)                  ;517e
        CALL    PO,7980H                ;517f
        LD      BC,0200H                ;5182
        NOP                             ;5185
        NOP                             ;5186
        NOP                             ;5187
        NOP                             ;5188
        NOP                             ;5189
m518a   NOP                             ;518a
        NOP                             ;518b
        NOP                             ;518c
        NOP                             ;518d
        NOP                             ;518e
        NOP                             ;518f
        NOP                             ;5190
        NOP                             ;5191
        NOP                             ;5192
        NOP                             ;5193
        NOP                             ;5194
        NOP                             ;5195
        NOP                             ;5196
        NOP                             ;5197
        NOP                             ;5198
        NOP                             ;5199
        NOP                             ;519a
        NOP                             ;519b
        NOP                             ;519c
        NOP                             ;519d
        NOP                             ;519e
        NOP                             ;519f
        NOP                             ;51a0
        NOP                             ;51a1
        NOP                             ;51a2
        NOP                             ;51a3
        NOP                             ;51a4
        NOP                             ;51a5
m51a6   NOP                             ;51a6
        NOP                             ;51a7
        NOP                             ;51a8
        NOP                             ;51a9
        NOP                             ;51aa
        NOP                             ;51ab
        NOP                             ;51ac
        NOP                             ;51ad
        NOP                             ;51ae
        NOP                             ;51af
        NOP                             ;51b0
        NOP                             ;51b1
        NOP                             ;51b2
        NOP                             ;51b3
        NOP                             ;51b4
        NOP                             ;51b5
        NOP                             ;51b6
        NOP                             ;51b7
        NOP                             ;51b8
        NOP                             ;51b9
        NOP                             ;51ba
        NOP                             ;51bb
        NOP                             ;51bc
        NOP                             ;51bd
        NOP                             ;51be
        NOP                             ;51bf
        NOP                             ;51c0
        NOP                             ;51c1
        NOP                             ;51c2
        NOP                             ;51c3
        NOP                             ;51c4
        NOP                             ;51c5
        NOP                             ;51c6
        NOP                             ;51c7
        NOP                             ;51c8
        NOP                             ;51c9
        NOP                             ;51ca
        NOP                             ;51cb
        NOP                             ;51cc
        NOP                             ;51cd
        NOP                             ;51ce
        NOP                             ;51cf
        NOP                             ;51d0
        NOP                             ;51d1
        NOP                             ;51d2
        NOP                             ;51d3
        NOP                             ;51d4
        NOP                             ;51d5
        NOP                             ;51d6
        NOP                             ;51d7
        NOP                             ;51d8
        NOP                             ;51d9
        NOP                             ;51da
        NOP                             ;51db
        NOP                             ;51dc
        NOP                             ;51dd
        NOP                             ;51de
        NOP                             ;51df
        NOP                             ;51e0
        NOP                             ;51e1
        NOP                             ;51e2
        NOP                             ;51e3
        NOP                             ;51e4
        NOP                             ;51e5
        NOP                             ;51e6
        NOP                             ;51e7
        NOP                             ;51e8
        NOP                             ;51e9
        NOP                             ;51ea
        NOP                             ;51eb
        NOP                             ;51ec
        NOP                             ;51ed
        NOP                             ;51ee
        NOP                             ;51ef
        NOP                             ;51f0
        NOP                             ;51f1
        NOP                             ;51f2
        NOP                             ;51f3
        NOP                             ;51f4
        NOP                             ;51f5
        NOP                             ;51f6
        NOP                             ;51f7
        NOP                             ;51f8
        NOP                             ;51f9
        NOP                             ;51fa
        NOP                             ;51fb
        NOP                             ;51fc
        NOP                             ;51fd
        NOP                             ;51fe
m51ff   NOP                             ;51ff
m5200   LD      A,20H                   ;5200
        JR      m521a                   ;5202
m5204   LD      A,3CH                   ;5204
        JR      m521a                   ;5206
m5208   LD      A,2AH                   ;5208
        JR      m521a                   ;520a
        LD      A,2CH                   ;520c
        JR      m521a                   ;520e
m5210   LD      A,(HL)                  ;5210
        CP      0DH                     ;5211
        RET     Z                       ;5213
m5214   LD      A,34H                   ;5214
        JR      m521a                   ;5216
m5218   LD      A,2FH                   ;5218
m521a   PUSH    AF                      ;521a
m521b   CALL    m5881                   ;521b
m521e   POP     AF                      ;521e
        LD      HL,DOSERR               ;521f
m5222   PUSH    HL                      ;5222
        PUSH    AF                      ;5223
        CALL    m5582                   ;5224
        LD      A,(m593b)               ;5227
        BIT     7,A                     ;522a
        JR      Z,m5235                 ;522c
        LD      B,05H                   ;522e
        CALL    m5646                   ;5230
        JR      NZ,m523c                ;5233
m5235   LD      HL,DFLAG0               ;5235
        RES     3,(HL)                  ;5238
        POP     AF                      ;523a
        RET                             ;523b
m523c   PUSH    AF                      ;523c
        LD      A,46H                   ;523d
        RST     18H                     ;523f
m5240   LD      HL,m5ac2                ;5240
m5243   CALL    m5881                   ;5243
m5246   CALL    DSPLY                   ;5246
m5249   LD      HL,ERRORO               ;5249
        JR      m5222                   ;524c
m524e   LD      HL,(m5d14)              ;524e
        LD      DE,(m5d12)              ;5251
        OR      A                       ;5255
        SBC     HL,DE                   ;5256
        LD      B,H                     ;5258
        LD      C,L                     ;5259
        PUSH    DE                      ;525a
        LD      HL,m5d16                ;525b
        LD      (m5d12),HL              ;525e
        PUSH    HL                      ;5261
        EX      DE,HL                   ;5262
        LDIR                            ;5263
        LD      (m5d14),DE              ;5265
        CALL    m5578                   ;5269
        POP     HL                      ;526c
        CALL    m56a6                   ;526d
        JP      Z,m552d                 ;5270
m5273   LD      HL,m627b                ;5273
        CALL    m587e                   ;5276
m5279   LD      HL,(m593c)              ;5279
        LD      DE,(m5d14)              ;527c
        OR      A                       ;5280
        SBC     HL,DE                   ;5281
        LD      DE,0102H                ;5283
        LD      A,0FFH                  ;5286
m5288   INC     A                       ;5288
        OR      A                       ;5289
        SBC     HL,DE                   ;528a
        JR      NC,m5288                ;528c
        LD      (531AH),A               ;528e
m5291   LD      HL,m594c                ;5291
        CALL    m5538                   ;5294
        XOR     A                       ;5297
        LD      HL,(m5d14)              ;5298
        JR      m5316                   ;529b
m529d   PUSH    HL                      ;529d
        INC     HL                      ;529e
        INC     HL                      ;529f
        LD      (m5ae8),HL              ;52a0
        LD      A,80H                   ;52a3
        LD      (57EBH),A               ;52a5
m52a8   CALL    m57c8                   ;52a8
        JR      Z,m52cf                 ;52ab
        CP      06H                     ;52ad
        JR      Z,m52d0                 ;52af
        CP      1CH                     ;52b1
        JR      Z,m52b9                 ;52b3
        CP      1DH                     ;52b5
        JR      NZ,m52ca                ;52b7
m52b9   LD      HL,0000H                ;52b9
        LD      A,(m5996)               ;52bc
        AND     08H                     ;52bf
        CALL    NZ,m56a2                ;52c1
        JP      Z,m549c                 ;52c4
        POP     HL                      ;52c7
        JR      m529d                   ;52c8
m52ca   CALL    m585a                   ;52ca
        JR      NZ,m52a8                ;52cd
m52cf   XOR     A                       ;52cf
m52d0   POP     HL                      ;52d0
        LD      (HL),0FFH               ;52d1
        INC     HL                      ;52d3
        LD      (HL),A                  ;52d4
        INC     HL                      ;52d5
        CALL    m571b                   ;52d6
        PUSH    HL                      ;52d9
        EX      DE,HL                   ;52da
        LD      A,(m5996)               ;52db
        AND     0CH                     ;52de
        JR      NZ,m5311                ;52e0
        LD      A,(m5992+2)             ;52e2
        BIT     1,A                     ;52e5
        JR      NZ,m5311                ;52e7
        LD      HL,(m5aef)              ;52e9
        DEC     HL                      ;52ec
        LD      A,H                     ;52ed
        OR      A                       ;52ee
        JR      NZ,m5311                ;52ef
        LD      A,L                     ;52f1
        CP      02H                     ;52f2
        JR      NC,m52fe                ;52f4
        LD      HL,m64ba                ;52f6
        CALL    m5c80                   ;52f9
        JR      m530f                   ;52fc
m52fe   JR      NZ,m5311                ;52fe
        LD      HL,00EFH                ;5300
        ADD     HL,DE                   ;5303
        LD      A,(HL)                  ;5304
        CP      0A5H                    ;5305
        JR      NZ,m5311                ;5307
        LD      HL,m6eb5                ;5309
        LD      BC,0010H                ;530c
m530f   LDIR                            ;530f
m5311   POP     HL                      ;5311
        INC     H                       ;5312
        LD      A,00H                   ;5313
        INC     A                       ;5315
m5316   LD      (5314H),A               ;5316
        CP      0AH                     ;5319
        JP      C,m529d                 ;531b
        CALL    m5324                   ;531e
        JP      m5291                   ;5321
m5324   CALL    m5535                   ;5324
        LD      A,(5314H)               ;5327
        OR      A                       ;532a
        RET     Z                       ;532b
        LD      HL,(m5d14)              ;532c
m532f   LD      (m544e+1),HL            ;532f
        LD      DE,(m5b21)              ;5332
        LD      (5401H),DE              ;5336
        XOR     A                       ;533a
        LD      (53ECH),A               ;533b
m533e   PUSH    HL                      ;533e
        LD      A,(m5996)               ;533f
        AND     0CH                     ;5342
        JP      Z,m53d5                 ;5344
        AND     08H                     ;5347
        JR      Z,m5360                 ;5349
        LD      A,(HL)                  ;534b
        CP      (IX+07H)                ;534c
        JR      Z,m5360                 ;534f
        PUSH    AF                      ;5351
        CALL    m53fb                   ;5352
        POP     AF                      ;5355
        LD      IX,m5b17                ;5356
        CALL    m56b9                   ;535a
        POP     HL                      ;535d
        JR      m532f                   ;535e
m5360   LD      HL,(m5b21)              ;5360
        LD      A,H                     ;5363
        OR      L                       ;5364
        JR      NZ,m53d5                ;5365
        XOR     A                       ;5367
        LD      (53D7H),A               ;5368
        LD      A,(m5996)               ;536b
        BIT     3,A                     ;536e
        PUSH    HL                      ;5370
        LD      HL,(m5af1)              ;5371
        LD      A,(m5aed)               ;5374
        JR      Z,m537f                 ;5377
        LD      HL,(m5b23)              ;5379
        LD      A,(m5b1f)               ;537c
m537f   OR      A                       ;537f
        JR      NZ,m5383                ;5380
        DEC     HL                      ;5382
m5383   LD      A,H                     ;5383
        AND     L                       ;5384
        INC     A                       ;5385
        JR      Z,m53d1                 ;5386
        LD      (m5b21),HL              ;5388
        LD      HL,DFLAG2               ;538b
        SET     1,(HL)                  ;538e
        CALL    m57ce                   ;5390
        RES     1,(HL)                  ;5393
        JR      Z,m53d1                 ;5395
        PUSH    AF                      ;5397
        LD      HL,m5995                ;5398
        BIT     7,(HL)                  ;539b
        JR      NZ,m53ad                ;539d
        LD      HL,m5996                ;539f
        BIT     2,(HL)                  ;53a2
        JP      NZ,m521e                ;53a4
        SUB     1AH                     ;53a7
        CP      02H                     ;53a9
        JR      C,m53b3                 ;53ab
m53ad   CALL    m5868                   ;53ad
        JP      m521e                   ;53b0
m53b3   CALL    m56dd                   ;53b3
        INC     HL                      ;53b6
        INC     HL                      ;53b7
        INC     HL                      ;53b8
        XOR     A                       ;53b9
        LD      (HL),A                  ;53ba
        LD      DE,0011H                ;53bb
        ADD     HL,DE                   ;53be
        LD      (HL),A                  ;53bf
        INC     HL                      ;53c0
        LD      (HL),A                  ;53c1
        CALL    m5711                   ;53c2
        POP     HL                      ;53c5
        LD      HL,m5ad8                ;53c6
        CALL    m586f                   ;53c9
        LD      A,0FFH                  ;53cc
        LD      (53D7H),A               ;53ce
m53d1   POP     HL                      ;53d1
        LD      (m5b21),HL              ;53d2
m53d5   POP     HL                      ;53d5
        LD      A,00H                   ;53d6
        OR      A                       ;53d8
        JR      Z,m53df                 ;53d9
        CALL    m585e                   ;53db
        DEC     A                       ;53de
m53df   CALL    Z,m546d                 ;53df
        INC     HL                      ;53e2
        JR      Z,m53e6                 ;53e3
        LD      (HL),A                  ;53e5
m53e6   INC     HL                      ;53e6
        INC     H                       ;53e7
        CALL    m571b                   ;53e8
        LD      A,00H                   ;53eb
        INC     A                       ;53ed
        LD      (53ECH),A               ;53ee
        LD      A,(5314H)               ;53f1
        DEC     A                       ;53f4
        LD      (5314H),A               ;53f5
        JP      NZ,m533e                ;53f8
m53fb   LD      A,(53ECH)               ;53fb
        OR      A                       ;53fe
        RET     Z                       ;53ff
        LD      HL,0000H                ;5400
        LD      (m5b21),HL              ;5403
m5406   LD      HL,(m5d10)              ;5406
        LD      (m5b1a),HL              ;5409
        LD      A,20H                   ;540c
        LD      (57EBH),A               ;540e
        LD      HL,(m544e+1)            ;5411
        INC     HL                      ;5414
        LD      A,(HL)                  ;5415
        INC     A                       ;5416
        CALL    Z,m585e                 ;5417
        JR      Z,m544e                 ;541a
        CALL    m57c8                   ;541c
        JR      NZ,m5422                ;541f
        XOR     A                       ;5421
m5422   JR      Z,m5428                 ;5422
        CP      06H                     ;5424
        JR      NZ,m5430                ;5426
m5428   CP      (HL)                    ;5428
        JR      Z,m5440                 ;5429
        CALL    m5492                   ;542b
        LD      A,31H                   ;542e
m5430   DEC     HL                      ;5430
        CALL    m585a                   ;5431
        JR      Z,m544e                 ;5434
        CALL    m546d                   ;5436
        JR      NZ,m544e                ;5439
        CALL    m5492                   ;543b
        JR      m5406                   ;543e
m5440   LD      B,00H                   ;5440
        LD      DE,(m5d10)              ;5442
m5446   INC     HL                      ;5446
        LD      A,(DE)                  ;5447
        CP      (HL)                    ;5448
        INC     DE                      ;5449
        JR      NZ,m5461                ;544a
        DJNZ    m5446                   ;544c
m544e   LD      HL,0000H                ;544e
        INC     HL                      ;5451
        INC     HL                      ;5452
        INC     H                       ;5453
        LD      (m544e+1),HL            ;5454
        CALL    m571b                   ;5457
        LD      HL,53ECH                ;545a
        DEC     (HL)                    ;545d
        JR      NZ,m5406                ;545e
        RET                             ;5460
m5461   CALL    m5492                   ;5461
        LD      A,3AH                   ;5464
        CALL    m585a                   ;5466
        JR      Z,m544e                 ;5469
        JR      m5406                   ;546b
m546d   PUSH    HL                      ;546d
        INC     HL                      ;546e
        LD      A,(HL)                  ;546f
        CP      06H                     ;5470
        INC     HL                      ;5472
        JR      NZ,m5479                ;5473
        SET     0,(IX+00H)              ;5475
m5479   CALL    m5c8e                   ;5479
        LD      A,40H                   ;547c
        LD      (57EBH),A               ;547e
        CALL    m57ce                   ;5481
        RES     0,(IX+00H)              ;5484
        POP     HL                      ;5488
        RET     Z                       ;5489
        CALL    m585a                   ;548a
        JR      NZ,m546d                ;548d
        OR      0FFH                    ;548f
        RET                             ;5491
m5492   PUSH    HL                      ;5492
        LD      HL,(m5b21)              ;5493
        DEC     HL                      ;5496
        LD      (m5b21),HL              ;5497
        POP     HL                      ;549a
        RET                             ;549b
m549c   POP     HL                      ;549c
        CALL    m5324                   ;549d
        LD      A,(m5996)               ;54a0
        BIT     3,A                     ;54a3
        JP      NZ,m552d                ;54a5
        BIT     2,A                     ;54a8
        JR      Z,m54d4                 ;54aa
        LD      A,05H                   ;54ac
        CALL    m568d                   ;54ae
        CALL    m5535                   ;54b1
        LD      HL,(m5af1)              ;54b4
        LD      (m5b23),HL              ;54b7
        LD      A,(m5aed)               ;54ba
        LD      (m5b1f),A               ;54bd
        LD      DE,m5b17                ;54c0
        CALL    m4428                   ;54c3
        LD      HL,DMODUL               ;54c6
        LD      (HL),05H                ;54c9
m54cb   JP      NZ,m521a                ;54cb
m54ce   LD      HL,DOSRDY               ;54ce
        JP      m5222                   ;54d1
m54d4   JP      m501c                   ;54d4
        LD      DE,(m59c1)              ;54d7
        CALL    m5784                   ;54db
        LD      BC,(m5992+2)            ;54de
        BIT     1,C                     ;54e2
        JR      NZ,m552d                ;54e4
        CALL    m56f9                   ;54e6
        BIT     5,B                     ;54e9
        JR      Z,m54f3                 ;54eb
        LD      HL,(m5981)              ;54ed
        LD      (m42ce),HL              ;54f0
m54f3   LD      A,C                     ;54f3
        AND     0CH                     ;54f4
        LD      BC,0010H                ;54f6
        LD      DE,m42d0                ;54f9
        LD      HL,m5983                ;54fc
        JR      NZ,m5508                ;54ff
        LD      HL,m598b                ;5501
        LD      E,0D8H                  ;5504
        LD      C,08H                   ;5506
m5508   LDIR                            ;5508
        LD      HL,(m59d1)              ;550a
        LD      DE,(m59c3)              ;550d
        OR      A                       ;5511
        SBC     HL,DE                   ;5512
        EX      DE,HL                   ;5514
        JR      C,m5528                 ;5515
        JR      Z,m5528                 ;5517
        LD      HL,(m59c3)              ;5519
        LD      A,(m59bc)               ;551c
        CALL    m4cb4                   ;551f
        LD      H,42H                   ;5522
        LD      C,A                     ;5524
        CALL    m5762                   ;5525
m5528   CALL    m491f                   ;5528
        JR      NZ,m54cb                ;552b
m552d   LD      HL,m5a1f                ;552d
        CALL    DSPLY                   ;5530
        JR      m54ce                   ;5533
m5535   LD      HL,m5956                ;5535
m5538   CALL    m5585                   ;5538
        INC     HL                      ;553b
        INC     HL                      ;553c
        LD      E,(HL)                  ;553d
        INC     HL                      ;553e
        LD      D,(HL)                  ;553f
        PUSH    DE                      ;5540
        POP     IX                      ;5541
        LD      A,(DE)                  ;5543
        BIT     7,A                     ;5544
        RET     NZ                      ;5546
        LD      B,00H                   ;5547
        LD      A,17H                   ;5549
        CP      E                       ;554b
        JR      Z,m5556                 ;554c
        CALL    FOPEN                   ;554e
        JR      Z,m5570                 ;5551
m5553   JP      m521a                   ;5553
m5556   CALL    FINIT                   ;5556
        JR      NZ,m5553                ;5559
        LD      DE,(m5aeb)              ;555b
        LD      HL,(m5b1d)              ;555f
        RST     18H                     ;5562
        JR      NZ,m5570                ;5563
        LD      HL,m5a24                ;5565
        LD      A,(m5940)               ;5568
        CP      06H                     ;556b
        JP      C,m5243                 ;556d
m5570   LD      HL,(m593e)              ;5570
        LD      A,(IX+06H)              ;5573
        LD      (HL),A                  ;5576
        RET                             ;5577
m5578   LD      HL,m594c                ;5578
        JR      m5585                   ;557b
m557d   LD      HL,m5956                ;557d
        JR      m5585                   ;5580
m5582   LD      HL,m5942                ;5582
m5585   LD      (m593e),HL              ;5585
        LD      A,0FFH                  ;5588
        LD      (m4930),A               ;558a
        LD      A,(HL)                  ;558d
        INC     A                       ;558e
        RET     Z                       ;558f
        PUSH    HL                      ;5590
        PUSH    DE                      ;5591
        PUSH    BC                      ;5592
        LD      A,(m593b)               ;5593
        BIT     7,A                     ;5596
        LD      B,00H                   ;5598
        CALL    NZ,m5658                ;559a
        LD      C,(HL)                  ;559d
        INC     HL                      ;559e
        LD      B,(HL)                  ;559f
        LD      DE,0007H                ;55a0
        ADD     HL,DE                   ;55a3
        LD      E,(HL)                  ;55a4
        INC     HL                      ;55a5
        LD      D,(HL)                  ;55a6
        LD      HL,m5940                ;55a7
        LD      A,(HL)                  ;55aa
        AND     B                       ;55ab
        LD      A,(HL)                  ;55ac
        INC     HL                      ;55ad
        JR      Z,m55b5                 ;55ae
        XOR     B                       ;55b0
        XOR     0FFH                    ;55b1
        AND     (HL)                    ;55b3
        LD      (HL),A                  ;55b4
m55b5   LD      A,C                     ;55b5
        CALL    DRVSEL                  ;55b6
        JP      NZ,m521a                ;55b9
        PUSH    HL                      ;55bc
        LD      A,(HL)                  ;55bd
        AND     B                       ;55be
        JR      NZ,m55ec                ;55bf
m55c1   LD      HL,m59ee                ;55c1
        CALL    DSPLY                   ;55c4
        LD      H,D                     ;55c7
        LD      L,E                     ;55c8
        CALL    DSPLY                   ;55c9
        LD      A,C                     ;55cc
        ADD     A,30H                   ;55cd
        LD      (5A1DH),A               ;55cf
        LD      HL,m5a02                ;55d2
        CALL    DSPLY                   ;55d5
        PUSH    BC                      ;55d8
        LD      BC,8000H                ;55d9
        PUSH    DE                      ;55dc
        CALL    m4ced                   ;55dd
        POP     DE                      ;55e0
        POP     BC                      ;55e1
m55e2   CALL    m572b                   ;55e2
        CP      0DH                     ;55e5
        JR      NZ,m55e2                ;55e7
        CALL    m5881                   ;55e9
m55ec   LD      A,C                     ;55ec
        CALL    DSKTST                  ;55ed
        JR      NZ,m55c1                ;55f0
        POP     HL                      ;55f2
        LD      A,(HL)                  ;55f3
        OR      B                       ;55f4
        LD      (HL),A                  ;55f5
        LD      HL,m5b57                ;55f6
        JR      m563b                   ;55f9
m55fb   PUSH    HL                      ;55fb
        JR      Z,m560d                 ;55fc
        LD      A,(DMODUL)              ;55fe
        CP      C                       ;5601
        JR      Z,m560d                 ;5602
        BIT     5,(HL)                  ;5604
        JR      Z,m5637                 ;5606
m5608   LD      A,33H                   ;5608
        JP      m521a                   ;560a
m560d   LD      A,(m430c)               ;560d
        XOR     (HL)                    ;5610
        AND     20H                     ;5611
        JR      Z,m5637                 ;5613
        XOR     (HL)                    ;5615
        LD      (HL),A                  ;5616
        INC     HL                      ;5617
        LD      A,(HL)                  ;5618
        INC     HL                      ;5619
        LD      H,(HL)                  ;561a
        LD      L,A                     ;561b
        JR      m562f                   ;561c
m561e   LD      A,(HL)                  ;561e
        OR      A                       ;561f
        LD      B,A                     ;5620
        INC     HL                      ;5621
        EX      DE,HL                   ;5622
        JR      Z,m562f                 ;5623
        EX      DE,HL                   ;5625
m5626   LD      C,(HL)                  ;5626
        LD      A,(DE)                  ;5627
        LD      (HL),A                  ;5628
        LD      A,C                     ;5629
        LD      (DE),A                  ;562a
        INC     HL                      ;562b
        INC     DE                      ;562c
        DJNZ    m5626                   ;562d
m562f   LD      E,(HL)                  ;562f
        INC     HL                      ;5630
        LD      D,(HL)                  ;5631
        INC     HL                      ;5632
        LD      A,D                     ;5633
        OR      E                       ;5634
        JR      NZ,m561e                ;5635
m5637   POP     HL                      ;5637
        INC     HL                      ;5638
        INC     HL                      ;5639
        INC     HL                      ;563a
m563b   LD      A,(HL)                  ;563b
        CP      02H                     ;563c
        LD      C,A                     ;563e
        INC     HL                      ;563f
        JR      NC,m55fb                ;5640
        POP     BC                      ;5642
        POP     DE                      ;5643
        POP     HL                      ;5644
        RET                             ;5645
m5646   LD      HL,m5942                ;5646
        LD      C,03H                   ;5649
m564b   LD      A,(HL)                  ;564b
        INC     A                       ;564c
        CALL    NZ,m5658                ;564d
        LD      DE,000AH                ;5650
        ADD     HL,DE                   ;5653
        DEC     C                       ;5654
        JR      NZ,m564b                ;5655
        RET                             ;5657
m5658   LD      A,(HL)                  ;5658
        PUSH    HL                      ;5659
        PUSH    DE                      ;565a
        CALL    DRVSEL                  ;565b
        JR      NZ,m5684                ;565e
        LD      DE,0004H                ;5660
        BIT     0,B                     ;5663
        JR      Z,m5669                 ;5665
        INC     DE                      ;5667
        INC     DE                      ;5668
m5669   ADD     HL,DE                   ;5669
        LD      E,(HL)                  ;566a
        INC     HL                      ;566b
        LD      D,(HL)                  ;566c
        LD      HL,(DPPTR)              ;566d
        BIT     1,B                     ;5670
        JR      NZ,m5675                ;5672
        EX      DE,HL                   ;5674
m5675   PUSH    BC                      ;5675
        LD      BC,000AH                ;5676
        LDIR                            ;5679
        POP     BC                      ;567b
        CALL    m4773                   ;567c
        JR      NZ,m5684                ;567f
m5681   POP     DE                      ;5681
        POP     HL                      ;5682
        RET                             ;5683
m5684   BIT     2,B                     ;5684
        JR      NZ,m5681                ;5686
        JP      m521a                   ;5688
m568b   LD      A,04H                   ;568b
m568d   LD      C,0FFH                  ;568d
        PUSH    AF                      ;568f
        CALL    m5582                   ;5690
        POP     AF                      ;5693
        OR      A                       ;5694
        RET     Z                       ;5695
        OR      0E0H                    ;5696
        RST     28H                     ;5698
m5699   INC     HL                      ;5699
        INC     HL                      ;569a
        INC     HL                      ;569b
        LD      DE,(m5d14)              ;569c
        RST     18H                     ;56a0
        RET                             ;56a1
m56a2   CALL    m5699                   ;56a2
        RET     Z                       ;56a5
m56a6   BIT     5,(HL)                  ;56a6
        JR      Z,m56a2                 ;56a8
        LD      (m52b9+1),HL            ;56aa
        INC     HL                      ;56ad
        LD      C,(HL)                  ;56ae
        INC     HL                      ;56af
        LD      A,(HL)                  ;56b0
        LD      (52D2H),A               ;56b1
        LD      IX,m5ae5                ;56b4
        LD      A,C                     ;56b8
m56b9   LD      (m4f56),A               ;56b9
        CALL    m56f4                   ;56bc
        XOR     A                       ;56bf
        LD      (m4f5e),A               ;56c0
        INC     HL                      ;56c3
        CALL    m4e21                   ;56c4
        EX      DE,HL                   ;56c7
        LD      A,E                     ;56c8
        ADD     A,10H                   ;56c9
        LD      E,A                     ;56cb
        CALL    m4f2e                   ;56cc
        JR      NZ,m56fe                ;56cf
        OR      0FFH                    ;56d1
        RET                             ;56d3
        LD      L,A                     ;56d4
        LD      H,00H                   ;56d5
        LD      A,(IY-72H)              ;56d7
        JP      MULOV                   ;56da
m56dd   CALL    RDFPDE                  ;56dd
        JR      m56fd                   ;56e0
m56e2   PUSH    AF                      ;56e2
        AND     1FH                     ;56e3
        INC     A                       ;56e5
        INC     A                       ;56e6
        LD      HL,m570d+1              ;56e7
        CP      (HL)                    ;56ea
        CALL    NZ,m570d                ;56eb
        POP     AF                      ;56ee
m56ef   CALL    FDEGET                  ;56ef
        JR      m56fd                   ;56f2
m56f4   CALL    GETFDE                  ;56f4
        JR      m56fd                   ;56f7
m56f9   XOR     A                       ;56f9
m56fa   CALL    DIRSEC                  ;56fa
m56fd   RET     Z                       ;56fd
m56fe   JP      m521a                   ;56fe
m5701   CALL    m4922                   ;5701
        JR      m56fd                   ;5704
m5706   LD      A,(m4930)               ;5706
        LD      (m570d+1),A             ;5709
        RET                             ;570c
m570d   LD      A,0FFH                  ;570d
        INC     A                       ;570f
        RET     Z                       ;5710
m5711   LD      A,0FFH                  ;5711
        LD      (m570d+1),A             ;5713
        CALL    m491f                   ;5716
        JR      m56fd                   ;5719
m571b   CALL    022CH                   ;571b
        NOP                             ;571e
        NOP                             ;571f
        NOP                             ;5720
        NOP                             ;5721
        NOP                             ;5722
        NOP                             ;5723
        NOP                             ;5724
        NOP                             ;5725
        NOP                             ;5726
        NOP                             ;5727
        NOP                             ;5728
        JR      m5733                   ;5729
m572b   PUSH    DE                      ;572b
        CALL    002BH                   ;572c
        CALL    UPCASE                  ;572f
        POP     DE                      ;5732
m5733   PUSH    AF                      ;5733
        LD      A,(m5995)               ;5734
        BIT     7,A                     ;5737
        JR      NZ,m574f                ;5739
        LD      A,(m3840)               ;573b
        AND     48H                     ;573e
        JR      Z,m574f                 ;5740
m5742   LD      A,(m3840)               ;5742
        AND     09H                     ;5745
        JR      Z,m5742                 ;5747
        RRCA                            ;5749
        LD      A,39H                   ;574a
        JP      NC,m521a                ;574c
m574f   POP     AF                      ;574f
        RET                             ;5750
m5751   LD      A,L                     ;5751
        CP      60H                     ;5752
        POP     BC                      ;5754
        POP     DE                      ;5755
        POP     HL                      ;5756
        RET     NC                      ;5757
        LD      A,(m59c6)               ;5758
        CP      61H                     ;575b
        RET     NC                      ;575d
        LD      A,L                     ;575e
        ADD     A,60H                   ;575f
        LD      L,A                     ;5761
m5762   PUSH    HL                      ;5762
        PUSH    DE                      ;5763
        PUSH    BC                      ;5764
m5765   LD      A,L                     ;5765
        CP      0C0H                    ;5766
        CALL    NC,m5240                ;5768
m576b   INC     C                       ;576b
        LD      B,C                     ;576c
        LD      A,7FH                   ;576d
m576f   RLCA                            ;576f
        DJNZ    m576f                   ;5770
        AND     (HL)                    ;5772
        LD      (HL),A                  ;5773
        DEC     DE                      ;5774
        LD      A,D                     ;5775
        OR      E                       ;5776
        JR      Z,m5751                 ;5777
        LD      A,(m59ca)               ;5779
        CP      C                       ;577c
        JR      NZ,m576b                ;577d
        LD      C,00H                   ;577f
        INC     L                       ;5781
        JR      m5765                   ;5782
m5784   LD      A,(DFLAG4)              ;5784
        BIT     3,A                     ;5787
        RET     Z                       ;5789
        LD      A,20H                   ;578a
        LD      (57EBH),A               ;578c
        LD      (m5b21),DE              ;578f
        LD      HL,SECBUF               ;5793
        LD      (m5b1a),HL              ;5796
        LD      HL,(m59cf)              ;5799
        OR      A                       ;579c
        SBC     HL,DE                   ;579d
        RET     C                       ;579f
        RET     Z                       ;57a0
        PUSH    HL                      ;57a1
        LD      HL,m5a79                ;57a2
        CALL    m587e                   ;57a5
        LD      HL,0FFFFH               ;57a8
        LD      (m5b23),HL              ;57ab
        SET     1,(IX+00H)              ;57ae
        POP     HL                      ;57b2
m57b3   CALL    m57c8                   ;57b3
        JR      Z,m57ba                 ;57b6
        CP      06H                     ;57b8
m57ba   CALL    NZ,m585a                ;57ba
        JR      NZ,m57b3                ;57bd
        DEC     HL                      ;57bf
        CALL    m571b                   ;57c0
        LD      A,H                     ;57c3
        OR      L                       ;57c4
        JR      NZ,m57b3                ;57c5
        RET                             ;57c7
m57c8   PUSH    IX                      ;57c8
        POP     DE                      ;57ca
        JP      READ                    ;57cb
m57ce   PUSH    IX                      ;57ce
        POP     DE                      ;57d0
        JP      m5ce4                   ;57d1
m57d4   PUSH    IX                      ;57d4
        POP     DE                      ;57d6
        JP      VERIFY                  ;57d7
m57da   PUSH    HL                      ;57da
        PUSH    DE                      ;57db
        PUSH    BC                      ;57dc
        PUSH    AF                      ;57dd
        CALL    m5881                   ;57de
        LD      HL,m59d3                ;57e1
        CALL    DSPLY                   ;57e4
        LD      HL,m5a67                ;57e7
        LD      B,00H                   ;57ea
        BIT     6,B                     ;57ec
        JR      Z,m57f3                 ;57ee
        LD      HL,m5a6e                ;57f0
m57f3   BIT     5,B                     ;57f3
        JR      Z,m57fa                 ;57f5
        LD      HL,m5a79                ;57f7
m57fa   CALL    DSPLY                   ;57fa
        LD      HL,m5a44                ;57fd
        LD      DE,(m5b21)              ;5800
        BIT     7,B                     ;5804
        JR      Z,m580f                 ;5806
        LD      HL,m5a3c                ;5808
        LD      DE,(m5aef)              ;580b
m580f   CALL    DSPLY                   ;580f
        LD      HL,m5a5e                ;5812
        CALL    DSPLY                   ;5815
        CALL    m5909                   ;5818
        CALL    m5881                   ;581b
        LD      A,(m5996)               ;581e
        BIT     2,A                     ;5821
        JP      NZ,m521e                ;5823
        CALL    m5868                   ;5826
        POP     BC                      ;5829
        LD      HL,(m593e)              ;582a
        LD      A,(DMODUL)              ;582d
        LD      C,A                     ;5830
        PUSH    HL                      ;5831
        PUSH    BC                      ;5832
        CALL    m5582                   ;5833
        LD      A,B                     ;5836
        CALL    m584a                   ;5837
        POP     BC                      ;583a
        POP     DE                      ;583b
        PUSH    AF                      ;583c
        LD      A,C                     ;583d
        CALL    m568d                   ;583e
        EX      DE,HL                   ;5841
        CALL    m5585                   ;5842
        POP     AF                      ;5845
        POP     BC                      ;5846
        POP     DE                      ;5847
        POP     HL                      ;5848
        RET                             ;5849
m584a   LD      HL,m5995                ;584a
        BIT     7,(HL)                  ;584d
        JP      NZ,m521a                ;584f
        OR      0C0H                    ;5852
        CALL    DOSERR                  ;5854
        JP      m58c8                   ;5857
m585a   CALL    m57da                   ;585a
        RET     NZ                      ;585d
m585e   INC     (IX+0AH)                ;585e
        JR      NZ,m5866                ;5861
        INC     (IX+0BH)                ;5863
m5866   XOR     A                       ;5866
        RET                             ;5867
m5868   XOR     A                       ;5868
        OR      00H                     ;5869
        RET     Z                       ;586b
        LD      HL,m59e0                ;586c
m586f   CALL    DSPLY                   ;586f
        CALL    m56dd                   ;5872
        CALL    m58a0                   ;5875
        CALL    m5881                   ;5878
        OR      0FFH                    ;587b
        RET                             ;587d
m587e   CALL    DSPLY                   ;587e
m5881   LD      A,0DH                   ;5881
        JP      m58bd                   ;5883
m5886   LD      A,(HL)                  ;5886
        CP      20H                     ;5887
        INC     HL                      ;5889
        JR      C,m5890                 ;588a
        CP      80H                     ;588c
        JR      C,m5892                 ;588e
m5890   LD      A,20H                   ;5890
m5892   CALL    m58bd                   ;5892
        DJNZ    m5886                   ;5895
        RET                             ;5897
m5898   LD      A,20H                   ;5898
        CALL    m58bd                   ;589a
        DJNZ    m5898                   ;589d
        RET                             ;589f
m58a0   LD      A,L                     ;58a0
        ADD     A,05H                   ;58a1
        LD      L,A                     ;58a3
        LD      B,08H                   ;58a4
        CALL    m58b3                   ;58a6
        LD      A,(HL)                  ;58a9
        CP      20H                     ;58aa
        LD      B,03H                   ;58ac
        LD      A,2FH                   ;58ae
        CALL    NZ,m58bd                ;58b0
m58b3   LD      A,(HL)                  ;58b3
        CP      20H                     ;58b4
        INC     HL                      ;58b6
        CALL    NZ,m58bd                ;58b7
        DJNZ    m58b3                   ;58ba
        RET                             ;58bc
m58bd   PUSH    DE                      ;58bd
        PUSH    AF                      ;58be
        CALL    0033H                   ;58bf
        POP     AF                      ;58c2
        POP     DE                      ;58c3
        RET                             ;58c4
        CALL    DSPLY                   ;58c5
m58c8   LD      A,(m5995)               ;58c8
        BIT     7,A                     ;58cb
        JP      NZ,m5249                ;58cd
        LD      HL,m5a84                ;58d0
        CALL    m58e4                   ;58d3
        CP      01H                     ;58d6
        RET     NC                      ;58d8
        LD      A,39H                   ;58d9
        JP      m521a                   ;58db
m58de   CALL    DSPLY                   ;58de
        LD      HL,m5ab3                ;58e1
m58e4   PUSH    BC                      ;58e4
        PUSH    HL                      ;58e5
m58e6   LD      A,(HL)                  ;58e6
        OR      A                       ;58e7
        INC     HL                      ;58e8
        JR      NZ,m58e6                ;58e9
        CALL    DSPLY                   ;58eb
m58ee   CALL    m572b                   ;58ee
        POP     HL                      ;58f1
        LD      C,0FFH                  ;58f2
        PUSH    HL                      ;58f4
m58f5   INC     (HL)                    ;58f5
        INC     C                       ;58f6
        DEC     (HL)                    ;58f7
        JR      Z,m58ee                 ;58f8
        CP      (HL)                    ;58fa
        INC     HL                      ;58fb
        JR      NZ,m58f5                ;58fc
        CALL    m58bd                   ;58fe
        CALL    m5881                   ;5901
        LD      A,C                     ;5904
        OR      A                       ;5905
        POP     HL                      ;5906
        POP     BC                      ;5907
        RET                             ;5908
m5909   LD      BC,0400H                ;5909
        LD      HL,m5933                ;590c
m590f   PUSH    BC                      ;590f
        LD      C,(HL)                  ;5910
        INC     HL                      ;5911
        LD      B,(HL)                  ;5912
        INC     HL                      ;5913
        EX      DE,HL                   ;5914
        LD      A,2FH                   ;5915
m5917   INC     A                       ;5917
        ADD     HL,BC                   ;5918
        JR      C,m5917                 ;5919
        SBC     HL,BC                   ;591b
        POP     BC                      ;591d
        EX      DE,HL                   ;591e
        CP      30H                     ;591f
        JR      NZ,m5927                ;5921
        INC     C                       ;5923
        DEC     C                       ;5924
        JR      Z,m592b                 ;5925
m5927   INC     C                       ;5927
        CALL    m58bd                   ;5928
m592b   DJNZ    m590f                   ;592b
        LD      A,E                     ;592d
        ADD     A,30H                   ;592e
        JP      m58bd                   ;5930
m5933   RET     P                       ;5933
        RET     C                       ;5934
        JR      m5933                   ;5935
        SBC     A,H                     ;5937
        RST     38H                     ;5938
        OR      0FFH                    ;5939
m593b   NOP                             ;593b
m593c   RST     38H                     ;593c
        LD      L,A                     ;593d
m593e   LD      B,D                     ;593e
        LD      E,C                     ;593f
; ------------------------------------------------------------
; [note]      5940h: COPY drive-slot status bytes. 5940h = which
;             slots need attention, 5941h = which are still
;             satisfied. Checked at 55AAh/55BDh.
; ------------------------------------------------------------
m5940   NOP                             ;5940
        RLCA                            ;5941
; ------------------------------------------------------------
; [note]      5942h: SLOT 1 of 3, the SYSTEM diskette: drive
;             byte / mask 01h / +8 -> 5A51h "===> System ".
;             Never FFh, so this slot is verified on every COPY.
; ------------------------------------------------------------
; [PATCH]     5942h
; Stock:      00   drive 0, hardcoded
; This build: 05   sysvol
; Reason:     Same class of hardcoded-drive-0 site already
;             patched in SYS26/SYS (4EFEh, 4F3Bh) and OVL4/SYS
;             (32ECh), but the first found in a DATA table
;             rather than in a DRVSEL call -- invisible to every
;             pass that read only code. run-hdboottest.sh's
;             patch asserts the stock byte is 00h and that both
;             neighbouring slots are still FFh, so a wrong
;             address fails loudly.
; ------------------------------------------------------------
m5942   DEC     B                       ;5942
        LD      BC,0000H                ;5943
        SBC     A,C                     ;5946
        LD      E,C                     ;5947
        SBC     A,C                     ;5948
        LD      E,C                     ;5949
        LD      D,C                     ;594a
        LD      E,D                     ;594b
; ------------------------------------------------------------
; [note]      594Ch: SLOT 2 of 3, the SOURCE ("Quelle"). drive
;             FFh = unused until the command line fills it in at
;             4D3Dh / 6437h. mask 02h.
; ------------------------------------------------------------
m594c   RST     38H                     ;594c
        LD      (BC),A                  ;594d
        PUSH    HL                      ;594e
        LD      E,D                     ;594f
        OR      A                       ;5950
        LD      E,C                     ;5951
        AND     E                       ;5952
        LD      E,C                     ;5953
        INC     A                       ;5954
        LD      E,D                     ;5955
; ------------------------------------------------------------
; [note]      5956h: SLOT 3 of 3, the DESTINATION ("Ziel").
;             drive FFh = unused until the command line fills it
;             in at 4D40h / 6437h. mask 04h.
; ------------------------------------------------------------
m5956   RST     38H                     ;5956
        INC     B                       ;5957
        RLA                             ;5958
        LD      E,E                     ;5959
        PUSH    BC                      ;595a
        LD      E,C                     ;595b
        XOR     L                       ;595c
        LD      E,C                     ;595d
        LD      B,H                     ;595e
        LD      E,D                     ;595f
m5960   JR      NZ,m5982                ;5960
        JR      NZ,m5984                ;5962
        JR      NZ,m5986                ;5964
        JR      NZ,$+34                 ;5966
m5968   JR      NZ,$+34                 ;5968
        JR      NZ,m598c                ;596a
        JR      NZ,$+34                 ;596c
        JR      NZ,$+34                 ;596e
m5970   JR      NZ,m5992                ;5970
        JR      NZ,$+34                 ;5972
        JR      NZ,m5996                ;5974
        JR      NZ,m5998                ;5976
m5978   NOP                             ;5978
        NOP                             ;5979
m597a   NOP                             ;597a
        NOP                             ;597b
m597c   EX      AF,AF'                  ;597c
m597d   EX      AF,AF'                  ;597d
m597e   ADD     A,D                     ;597e
        NOP                             ;597f
        NOP                             ;5980
m5981   LD      B,A                     ;5981
m5982   ADC     A,H                     ;5982
m5983   LD      B,A                     ;5983
m5984   LD      B,H                     ;5984
        LD      C,A                     ;5985
m5986   LD      D,E                     ;5986
        JR      NZ,m59bb                ;5987
        LD      L,34H                   ;5989
m598b   INC     (HL)                    ;598b
m598c   LD      A,(322EH)               ;598c
        LD      A,(m3a2e)               ;598f
m5992   LD      A,(000DH)               ;5992
m5995   NOP                             ;5995
m5996   NOP                             ;5996
m5997   NOP                             ;5997
m5998   NOP                             ;5998
        NOP                             ;5999
        NOP                             ;599a
        NOP                             ;599b
        NOP                             ;599c
        NOP                             ;599d
        NOP                             ;599e
        NOP                             ;599f
        NOP                             ;59a0
        NOP                             ;59a1
        NOP                             ;59a2
        NOP                             ;59a3
        NOP                             ;59a4
        NOP                             ;59a5
        NOP                             ;59a6
        NOP                             ;59a7
        NOP                             ;59a8
        NOP                             ;59a9
        NOP                             ;59aa
        NOP                             ;59ab
        NOP                             ;59ac
        NOP                             ;59ad
        NOP                             ;59ae
        NOP                             ;59af
        NOP                             ;59b0
        NOP                             ;59b1
        NOP                             ;59b2
        NOP                             ;59b3
        NOP                             ;59b4
        NOP                             ;59b5
        NOP                             ;59b6
m59b7   NOP                             ;59b7
        NOP                             ;59b8
m59b9   NOP                             ;59b9
        NOP                             ;59ba
m59bb   NOP                             ;59bb
m59bc   NOP                             ;59bc
        NOP                             ;59bd
m59be   NOP                             ;59be
        NOP                             ;59bf
m59c0   NOP                             ;59c0
m59c1   NOP                             ;59c1
        NOP                             ;59c2
m59c3   NOP                             ;59c3
        NOP                             ;59c4
m59c5   NOP                             ;59c5
m59c6   NOP                             ;59c6
m59c7   NOP                             ;59c7
m59c8   NOP                             ;59c8
m59c9   NOP                             ;59c9
m59ca   NOP                             ;59ca
m59cb   NOP                             ;59cb
m59cc   NOP                             ;59cc
m59cd   NOP                             ;59cd
m59ce   NOP                             ;59ce
m59cf   NOP                             ;59cf
        NOP                             ;59d0
m59d1   NOP                             ;59d1
        NOP                             ;59d2
m59d3   LD      B,(HL)                  ;59d3
        LD      H,L                     ;59d4
        LD      L,B                     ;59d5
        LD      L,H                     ;59d6
        LD      H,L                     ;59d7
        LD      (HL),D                  ;59d8
        JR      NZ,m5a3d                ;59d9
        LD      H,L                     ;59db
        LD      L,C                     ;59dc
        LD      L,L                     ;59dd
        JR      NZ,$+5                  ;59de
m59e0   LD      L,C                     ;59e0
        LD      L,(HL)                  ;59e1
        JR      NZ,m5a48                ;59e2
        LD      H,L                     ;59e4
        LD      (HL),D                  ;59e5
        JR      NZ,m5a2c                ;59e6
        LD      H,C                     ;59e8
        LD      (HL),H                  ;59e9
        LD      H,L                     ;59ea
        LD      L,C                     ;59eb
        JR      NZ,m59f1                ;59ec
m59ee   RLCA                            ;59ee
        DAA                             ;59ef
        LD      B,L                     ;59f0
m59f1   LD      C,(HL)                  ;59f1
        LD      D,H                     ;59f2
        LD      B,L                     ;59f3
        LD      D,D                     ;59f4
        DAA                             ;59f5
        RET     NZ                      ;59f6
        RET     NZ                      ;59f7
        RET     NZ                      ;59f8
        RET     NZ                      ;59f9
        INC     L                       ;59fa
        JR      NZ,m5a74                ;59fb
        LD      H,L                     ;59fd
        LD      L,(HL)                  ;59fe
        LD      L,(HL)                  ;59ff
        JR      NZ,m5a05                ;5a00
m5a02   EX      AF,AF'                  ;5a02
        LD      H,H                     ;5a03
        LD      L,C                     ;5a04
m5a05   LD      (HL),E                  ;5a05
        LD      L,E                     ;5a06
        LD      H,L                     ;5a07
        LD      (HL),H                  ;5a08
        LD      (HL),H                  ;5a09
        LD      H,L                     ;5a0a
        JR      NZ,m5a76                ;5a0b
        LD      L,(HL)                  ;5a0d
        JR      NZ,m5a5c                ;5a0e
        LD      H,C                     ;5a10
        LD      (HL),L                  ;5a11
        LD      H,(HL)                  ;5a12
        LD      (HL),A                  ;5a13
        LD      H,L                     ;5a14
        LD      (HL),D                  ;5a15
        LD      L,E                     ;5a16
        JR      NZ,m5a67                ;5a17
        LD      (HL),D                  ;5a19
        LD      L,20H                   ;5a1a
        JR      NZ,m5a4e                ;5a1c
        DEC     C                       ;5a1e
m5a1f   LD      B,L                     ;5a1f
        LD      C,(HL)                  ;5a20
        LD      B,H                     ;5a21
        LD      B,L                     ;5a22
        DEC     C                       ;5a23
m5a24   LD      D,C                     ;5a24
        LD      (HL),L                  ;5a25
        LD      H,L                     ;5a26
        LD      L,H                     ;5a27
        LD      L,H                     ;5a28
        LD      H,L                     ;5a29
        JR      NZ,m5a52                ;5a2a
m5a2c   JR      NZ,m5a88                ;5a2c
        LD      L,C                     ;5a2e
        LD      H,L                     ;5a2f
        LD      L,H                     ;5a30
        JR      NZ,m5a9c                ;5a31
        LD      H,H                     ;5a33
        LD      H,L                     ;5a34
        LD      L,(HL)                  ;5a35
        LD      (HL),H                  ;5a36
        LD      L,C                     ;5a37
        LD      (HL),E                  ;5a38
        LD      H,E                     ;5a39
        LD      L,B                     ;5a3a
        DEC     C                       ;5a3b
m5a3c   LD      D,C                     ;5a3c
m5a3d   LD      (HL),L                  ;5a3d
        LD      H,L                     ;5a3e
        LD      L,H                     ;5a3f
        LD      L,H                     ;5a40
        LD      H,L                     ;5a41
        INC     BC                      ;5a42
        INC     BC                      ;5a43
m5a44   LD      E,D                     ;5a44
        LD      L,C                     ;5a45
        LD      H,L                     ;5a46
        LD      L,H                     ;5a47
m5a48   JR      NZ,m5a4d                ;5a48
        LD      BC,m5002                ;5a4a
m5a4d   NOP                             ;5a4d
m5a4e   INC     DE                      ;5a4e
        LD      BC,m3d03                ;5a4f
m5a52   DEC     A                       ;5a52
        DEC     A                       ;5a53
        LD      A,20H                   ;5a54
        LD      D,E                     ;5a56
        LD      A,C                     ;5a57
        LD      (HL),E                  ;5a58
        LD      (HL),H                  ;5a59
        LD      H,L                     ;5a5a
        LD      L,L                     ;5a5b
m5a5c   JR      NZ,m5a61                ;5a5c
m5a5e   EX      AF,AF'                  ;5a5e
        LD      (HL),E                  ;5a5f
        LD      H,L                     ;5a60
m5a61   LD      L,E                     ;5a61
        LD      (HL),H                  ;5a62
        LD      L,A                     ;5a63
        LD      (HL),D                  ;5a64
        JR      NZ,m5a6a                ;5a65
m5a67   LD      C,H                     ;5a67
        LD      H,L                     ;5a68
        LD      (HL),E                  ;5a69
m5a6a   LD      H,L                     ;5a6a
        LD      L,(HL)                  ;5a6b
        JR      NZ,m5a71                ;5a6c
m5a6e   LD      D,E                     ;5a6e
        LD      H,E                     ;5a6f
        LD      L,B                     ;5a70
m5a71   LD      (HL),D                  ;5a71
        LD      H,L                     ;5a72
        LD      L,C                     ;5a73
m5a74   LD      H,D                     ;5a74
        LD      H,L                     ;5a75
m5a76   LD      L,(HL)                  ;5a76
        JR      NZ,m5a7c                ;5a77
m5a79   LD      D,B                     ;5a79
        LD      (HL),D                  ;5a7a
        LD      A,L                     ;5a7b
m5a7c   LD      H,(HL)                  ;5a7c
        LD      H,L                     ;5a7d
        LD      L,(HL)                  ;5a7e
        JR      NZ,m5aa1                ;5a7f
        JR      NZ,$+34                 ;5a81
        INC     BC                      ;5a83
m5a84   LD      B,C                     ;5a84
        LD      B,(HL)                  ;5a85
        LD      D,A                     ;5a86
        NOP                             ;5a87
m5a88   INC     A                       ;5a88
        LD      B,C                     ;5a89
        LD      A,62H                   ;5a8a
        LD      H,D                     ;5a8c
        LD      (HL),D                  ;5a8d
        LD      (HL),L                  ;5a8e
        LD      H,E                     ;5a8f
        LD      L,B                     ;5a90
        INC     L                       ;5a91
        JR      NZ,m5ad0                ;5a92
        LD      D,A                     ;5a94
        LD      A,69H                   ;5a95
        LD      H,L                     ;5a97
        LD      H,H                     ;5a98
        LD      H,L                     ;5a99
        LD      (HL),D                  ;5a9a
        LD      L,B                     ;5a9b
m5a9c   LD      L,A                     ;5a9c
        LD      L,H                     ;5a9d
        LD      (HL),L                  ;5a9e
        LD      L,(HL)                  ;5a9f
        LD      H,A                     ;5aa0
m5aa1   INC     L                       ;5aa1
        JR      NZ,m5ae0                ;5aa2
        LD      B,(HL)                  ;5aa4
        LD      A,6FH                   ;5aa5
        LD      (HL),D                  ;5aa7
        LD      (HL),H                  ;5aa8
        LD      H,(HL)                  ;5aa9
        LD      H,C                     ;5aaa
        LD      L,B                     ;5aab
        LD      (HL),D                  ;5aac
        LD      H,L                     ;5aad
        LD      L,(HL)                  ;5aae
        JR      NZ,m5ad1                ;5aaf
        JR      NZ,m5ac0                ;5ab1
m5ab3   LD      C,(HL)                  ;5ab3
        LD      C,D                     ;5ab4
        NOP                             ;5ab5
        JR      NZ,m5ae0                ;5ab6
        LD      C,D                     ;5ab8
        LD      H,C                     ;5ab9
        CPL                             ;5aba
        LD      C,(HL)                  ;5abb
        LD      H,L                     ;5abc
        LD      L,C                     ;5abd
        LD      L,(HL)                  ;5abe
        ADD     HL,HL                   ;5abf
m5ac0   JR      NZ,m5ac5                ;5ac0
m5ac2   LD      B,H                     ;5ac2
        LD      L,C                     ;5ac3
        LD      (HL),E                  ;5ac4
m5ac5   LD      L,E                     ;5ac5
        LD      H,L                     ;5ac6
        LD      (HL),H                  ;5ac7
        LD      (HL),H                  ;5ac8
        LD      H,L                     ;5ac9
        CPL                             ;5aca
        LD      B,A                     ;5acb
        LD      B,C                     ;5acc
        LD      D,H                     ;5acd
        JR      NZ,m5b4a                ;5ace
m5ad0   LD      (HL),L                  ;5ad0
m5ad1   JR      NZ,m5b3e                ;5ad1
        LD      L,H                     ;5ad3
        LD      H,L                     ;5ad4
        LD      L,C                     ;5ad5
        LD      L,(HL)                  ;5ad6
        DEC     C                       ;5ad7
m5ad8   LD      B,H                     ;5ad8
        LD      L,C                     ;5ad9
        LD      (HL),E                  ;5ada
        LD      L,E                     ;5adb
        JR      NZ,m5b54                ;5adc
        LD      L,A                     ;5ade
        LD      L,H                     ;5adf
m5ae0   LD      L,H                     ;5ae0
        JR      NZ,m5b10                ;5ae1
        JR      NZ,m5ae8                ;5ae3
m5ae5   ADD     A,D                     ;5ae5
        JR      NZ,m5ae8                ;5ae6
m5ae8   NOP                             ;5ae8
        LD      B,D                     ;5ae9
        NOP                             ;5aea
m5aeb   NOP                             ;5aeb
        RST     38H                     ;5aec
m5aed   NOP                             ;5aed
        NOP                             ;5aee
m5aef   NOP                             ;5aef
        NOP                             ;5af0
m5af1   LD      E,(HL)                  ;5af1
        LD      BC,1F00H                ;5af2
        RST     38H                     ;5af5
        RST     38H                     ;5af6
        RST     38H                     ;5af7
        RST     38H                     ;5af8
        RST     38H                     ;5af9
        RST     38H                     ;5afa
        RST     38H                     ;5afb
        RST     38H                     ;5afc
        RST     38H                     ;5afd
        RST     38H                     ;5afe
        RST     38H                     ;5aff
        RST     38H                     ;5b00
        RST     38H                     ;5b01
        RST     38H                     ;5b02
        RST     38H                     ;5b03
        RST     38H                     ;5b04
        RST     38H                     ;5b05
        RST     38H                     ;5b06
        RST     38H                     ;5b07
        RST     38H                     ;5b08
        RST     38H                     ;5b09
        RST     38H                     ;5b0a
        RST     38H                     ;5b0b
        RST     38H                     ;5b0c
        RST     38H                     ;5b0d
        RST     38H                     ;5b0e
        RST     38H                     ;5b0f
m5b10   RST     38H                     ;5b10
        RST     38H                     ;5b11
        RST     38H                     ;5b12
        RST     38H                     ;5b13
        RST     38H                     ;5b14
        RST     38H                     ;5b15
        RST     38H                     ;5b16
m5b17   ADD     A,D                     ;5b17
        LD      H,B                     ;5b18
        NOP                             ;5b19
m5b1a   NOP                             ;5b1a
        JR      C,m5b1d                 ;5b1b
m5b1d   NOP                             ;5b1d
m5b1e   RST     38H                     ;5b1e
m5b1f   NOP                             ;5b1f
        NOP                             ;5b20
m5b21   NOP                             ;5b21
        NOP                             ;5b22
m5b23   RST     38H                     ;5b23
        RST     38H                     ;5b24
        NOP                             ;5b25
        RRA                             ;5b26
        RST     38H                     ;5b27
        RST     38H                     ;5b28
        RST     38H                     ;5b29
        RST     38H                     ;5b2a
        RST     38H                     ;5b2b
        RST     38H                     ;5b2c
        RST     38H                     ;5b2d
        RST     38H                     ;5b2e
        RST     38H                     ;5b2f
        RST     38H                     ;5b30
        RST     38H                     ;5b31
        RST     38H                     ;5b32
        RST     38H                     ;5b33
        RST     38H                     ;5b34
        RST     38H                     ;5b35
        RST     38H                     ;5b36
        RST     38H                     ;5b37
        RST     38H                     ;5b38
        RST     38H                     ;5b39
        RST     38H                     ;5b3a
        RST     38H                     ;5b3b
        RST     38H                     ;5b3c
        RST     38H                     ;5b3d
m5b3e   RST     38H                     ;5b3e
        RST     38H                     ;5b3f
        RST     38H                     ;5b40
        RST     38H                     ;5b41
        RST     38H                     ;5b42
        RST     38H                     ;5b43
        RST     38H                     ;5b44
        RST     38H                     ;5b45
        RST     38H                     ;5b46
        RST     38H                     ;5b47
        RST     38H                     ;5b48
m5b49   ADD     A,D                     ;5b49
m5b4a   LD      H,B                     ;5b4a
        NOP                             ;5b4b
        NOP                             ;5b4c
        LD      B,D                     ;5b4d
        NOP                             ;5b4e
        NOP                             ;5b4f
        RST     38H                     ;5b50
        NOP                             ;5b51
        NOP                             ;5b52
m5b53   NOP                             ;5b53
m5b54   NOP                             ;5b54
        RST     38H                     ;5b55
        RST     38H                     ;5b56
m5b57   LD      (BC),A                  ;5b57
        NOP                             ;5b58
        LD      H,H                     ;5b59
        LD      E,E                     ;5b5a
m5b5b   INC     B                       ;5b5b
        NOP                             ;5b5c
m5b5d   AND     E                       ;5b5d
        LD      E,E                     ;5b5e
        DEC     B                       ;5b5f
        NOP                             ;5b60
m5b61   POP     HL                      ;5b61
        LD      E,E                     ;5b62
        NOP                             ;5b63
        DEC     A                       ;5b64
        LD      B,(HL)                  ;5b65
        LD      BC,m41a8                ;5b66
        LD      B,(HL)                  ;5b69
        LD      BC,m37a9                ;5b6a
        LD      B,A                     ;5b6d
        INC     BC                      ;5b6e
        JP      m5c0b                   ;5b6f
        SCF                             ;5b72
        LD      C,B                     ;5b73
        LD      BC,770DH                ;5b74
        LD      C,B                     ;5b77
        INC     BC                      ;5b78
        JP      m5c3e                   ;5b79
        SUB     D                       ;5b7c
        LD      C,B                     ;5b7d
        INC     BC                      ;5b7e
        JP      m5c43                   ;5b7f
        XOR     48H                     ;5b82
        LD      BC,0F400H               ;5b84
        LD      C,B                     ;5b87
        LD      BC,m3801                ;5b88
        LD      C,C                     ;5b8b
        INC     BC                      ;5b8c
        JP      m5c1e                   ;5b8d
        ADC     A,B                     ;5b90
        LD      C,H                     ;5b91
        LD      BC,0B303H               ;5b92
        LD      C,H                     ;5b95
        LD      BC,7F03H                ;5b96
        LD      C,D                     ;5b99
        LD      BC,0EB21H               ;5b9a
        LD      D,(HL)                  ;5b9d
        LD      BC,00CDH                ;5b9e
        NOP                             ;5ba1
        NOP                             ;5ba2
        OR      D                       ;5ba3
        LD      C,(HL)                  ;5ba4
        LD      BC,0D050H               ;5ba5
        LD      C,(HL)                  ;5ba8
        INC     BC                      ;5ba9
        NOP                             ;5baa
        NOP                             ;5bab
        NOP                             ;5bac
        JR      NZ,m5bfd                ;5bad
        LD      BC,m68af                ;5baf
        LD      C,A                     ;5bb2
        LD      BC,7B00H                ;5bb3
        LD      C,A                     ;5bb6
        LD      BC,0AF1AH               ;5bb7
        LD      C,A                     ;5bba
        LD      BC,0A00H                ;5bbb
        LD      D,B                     ;5bbe
        LD      BC,6100H                ;5bbf
        LD      D,B                     ;5bc2
        INC     BC                      ;5bc3
        LD      A,1AH                   ;5bc4
        OR      A                       ;5bc6
        SUB     50H                     ;5bc7
        INC     BC                      ;5bc9
        JP      m5c5b                   ;5bca
        LD      (DE),A                  ;5bcd
        LD      D,C                     ;5bce
        LD      BC,551AH                ;5bcf
        LD      D,C                     ;5bd2
        INC     B                       ;5bd3
        LD      HL,m5cef                ;5bd4
        RET                             ;5bd7
        RST     28H                     ;5bd8
        LD      C,L                     ;5bd9
        INC     BC                      ;5bda
        CALL    m5c71                   ;5bdb
        NOP                             ;5bde
        NOP                             ;5bdf
        NOP                             ;5be0
        LD      H,C                     ;5be1
        LD      C,(HL)                  ;5be2
        LD      BC,m6c0d                ;5be3
        LD      C,(HL)                  ;5be6
        LD      BC,0CE00H               ;5be7
        LD      C,(HL)                  ;5bea
        LD      BC,0EF18H               ;5beb
        LD      C,(HL)                  ;5bee
        LD      (BC),A                  ;5bef
        DEC     (HL)                    ;5bf0
        LD      D,(HL)                  ;5bf1
        JP      C,014EH                 ;5bf2
        CPL                             ;5bf5
        ADC     A,E                     ;5bf6
        LD      C,(HL)                  ;5bf7
        LD      BC,7218H                ;5bf8
        LD      C,(HL)                  ;5bfb
        INC     BC                      ;5bfc
m5bfd   JP      m5c69                   ;5bfd
m5c00   LD      (0150H),A               ;5c00
        NOP                             ;5c03
        LD      B,B                     ;5c04
        LD      C,(HL)                  ;5c05
        LD      BC,0013H                ;5c06
        NOP                             ;5c09
        NOP                             ;5c0a
m5c0b   EI                              ;5c0b
        POP     BC                      ;5c0c
        JR      NZ,m5c19                ;5c0d
        LD      A,(DCMD)                ;5c0f
        AND     20H                     ;5c12
        JR      NZ,m5c1c                ;5c14
        ADD     A,06H                   ;5c16
        RET                             ;5c18
m5c19   CP      06H                     ;5c19
        RET     NZ                      ;5c1b
m5c1c   XOR     A                       ;5c1c
        RET                             ;5c1d
m5c1e   PUSH    BC                      ;5c1e
        PUSH    HL                      ;5c1f
        LD      L,A                     ;5c20
        LD      H,00H                   ;5c21
        LD      A,05H                   ;5c23
        CALL    m4cb4                   ;5c25
        LD      H,A                     ;5c28
        LD      A,L                     ;5c29
        LD      L,H                     ;5c2a
        EX      (SP),HL                 ;5c2b
        INC     A                       ;5c2c
        INC     A                       ;5c2d
        CP      L                       ;5c2e
        CALL    NZ,DIRSEC               ;5c2f
        POP     HL                      ;5c32
        POP     BC                      ;5c33
        RET     NZ                      ;5c34
        LD      A,30H                   ;5c35
        CALL    MULHL                   ;5c37
        LD      A,L                     ;5c3a
        JP      m4947                   ;5c3b
m5c3e   EX      AF,AF'                  ;5c3e
        DEC     A                       ;5c3f
        JP      NZ,m4838                ;5c40
m5c43   POP     AF                      ;5c43
        POP     AF                      ;5c44
        POP     AF                      ;5c45
        LD      A,(m48bb)               ;5c46
        OR      A                       ;5c49
        JP      NZ,m48b8                ;5c4a
        LD      A,(IX+07H)              ;5c4d
        LD      (m486a),A               ;5c50
        LD      A,64H                   ;5c53
        CALL    m49dd                   ;5c55
        JP      m4813                   ;5c58
m5c5b   LD      B,50H                   ;5c5b
m5c5d   LD      A,(HL)                  ;5c5d
        OR      A                       ;5c5e
        JP      Z,m50fe                 ;5c5f
        INC     HL                      ;5c62
        DJNZ    m5c5d                   ;5c63
        LD      A,1AH                   ;5c65
        OR      A                       ;5c67
        RET                             ;5c68
m5c69   DEC     E                       ;5c69
        JP      NZ,m4e62                ;5c6a
        INC     HL                      ;5c6d
        JP      m4e95                   ;5c6e
m5c71   INC     HL                      ;5c71
        LD      A,(m4046)               ;5c72
        LD      (HL),A                  ;5c75
        INC     HL                      ;5c76
        LD      A,(m4044)               ;5c77
        LD      (HL),A                  ;5c7a
        DEC     HL                      ;5c7b
        DEC     HL                      ;5c7c
        JP      m4e1f                   ;5c7d
m5c80   LD      BC,0100H                ;5c80
        OR      A                       ;5c83
        RET     NZ                      ;5c84
        INC     DE                      ;5c85
        INC     DE                      ;5c86
        LD      A,(DE)                  ;5c87
        LD      (64BCH),A               ;5c88
        DEC     DE                      ;5c8b
        DEC     DE                      ;5c8c
        RET                             ;5c8d
m5c8e   LD      (m5b1a),HL              ;5c8e
        SET     6,(IX+01H)              ;5c91
        RET                             ;5c95
m5c96   CALL    m63b3                   ;5c96
        LD      A,(m59be)               ;5c99
        LD      B,A                     ;5c9c
        LD      A,(m59b9)               ;5c9d
        LD      C,A                     ;5ca0
        LD      A,(m59cc)               ;5ca1
        LD      D,A                     ;5ca4
        LD      A,(m59c7)               ;5ca5
        LD      E,A                     ;5ca8
        LD      A,C                     ;5ca9
        AND     E                       ;5caa
        BIT     5,A                     ;5cab
        JR      Z,m5cb5                 ;5cad
        LD      A,B                     ;5caf
        XOR     D                       ;5cb0
        RRCA                            ;5cb1
        JP      C,m6747                 ;5cb2
m5cb5   LD      A,B                     ;5cb5
        BIT     5,C                     ;5cb6
        JR      NZ,m5cbe                ;5cb8
        BIT     5,E                     ;5cba
        RET     Z                       ;5cbc
        LD      A,D                     ;5cbd
m5cbe   RRCA                            ;5cbe
        RET     C                       ;5cbf
        LD      HL,m5b5b                ;5cc0
        LD      (55F7H),HL              ;5cc3
        LD      HL,5BB1H                ;5cc6
        LD      (m5b5d),HL              ;5cc9
        LD      HL,m5c00                ;5ccc
        LD      (m5b61),HL              ;5ccf
        XOR     A                       ;5cd2
        LD      (m617f),A               ;5cd3
        LD      H,A                     ;5cd6
        LD      L,A                     ;5cd7
        LD      (m61bf),HL              ;5cd8
        LD      (5BB5H),HL              ;5cdb
        LD      A,18H                   ;5cde
        LD      (m612d),A               ;5ce0
        RET                             ;5ce3
m5ce4   LD      A,(m430c)               ;5ce4
        BIT     5,A                     ;5ce7
        JR      Z,m5cef                 ;5ce9
        SET     5,(IX+02H)              ;5ceb
m5cef   JP      WRITE                   ;5cef
m5cf2   BIT     5,(IX+02H)              ;5cf2
        JR      Z,m5cfc                 ;5cf6
        BIT     0,(IX+07H)              ;5cf8
m5cfc   JP      Z,m4cb2                 ;5cfc
        LD      A,03H                   ;5cff
        JP      m4cb4                   ;5d01
        NOP                             ;5d04
        NOP                             ;5d05
        NOP                             ;5d06
        NOP                             ;5d07
        NOP                             ;5d08
        NOP                             ;5d09
        NOP                             ;5d0a
        NOP                             ;5d0b
        NOP                             ;5d0c
        NOP                             ;5d0d
        NOP                             ;5d0e
        NOP                             ;5d0f
m5d10   NOP                             ;5d10
        LD      B,D                     ;5d11
m5d12   LD      D,5DH                   ;5d12
m5d14   LD      D,5DH                   ;5d14
m5d16   CALL    m6643                   ;5d16
        LD      HL,m5ae5                ;5d19
        RES     1,(HL)                  ;5d1c
        LD      HL,m5b17                ;5d1e
        RES     1,(HL)                  ;5d21
        LD      A,(m5997)               ;5d23
        AND     30H                     ;5d26
        JR      Z,m5d86                 ;5d28
        CALL    m568b                   ;5d2a
        LD      HL,m6491                ;5d2d
        LD      DE,USRFCB               ;5d30
        LD      A,(m448c)               ;5d33
        CP      0BH                     ;5d36
        JR      NC,m5d65                ;5d38
m5d3a   LD      B,0DH                   ;5d3a
        CALL    m5d71                   ;5d3c
        JR      Z,m5d3a                 ;5d3f
        CP      20H                     ;5d41
        JR      Z,m5d3a                 ;5d43
        CP      3BH                     ;5d45
        JR      NZ,m5d53                ;5d47
m5d49   CALL    m5d71                   ;5d49
        JR      NZ,m5d49                ;5d4c
        JR      m5d3a                   ;5d4e
m5d50   CALL    m5d71                   ;5d50
m5d53   LD      (HL),A                  ;5d53
        INC     HL                      ;5d54
        JR      Z,m5d3a                 ;5d55
        SUB     2FH                     ;5d57
        CP      0BH                     ;5d59
        JR      C,m5d63                 ;5d5b
        SUB     12H                     ;5d5d
        CP      1AH                     ;5d5f
        JR      NC,m5d65                ;5d61
m5d63   DJNZ    m5d50                   ;5d63
m5d65   LD      A,01H                   ;5d65
m5d67   PUSH    AF                      ;5d67
        LD      HL,m6283                ;5d68
        CALL    DSPLY                   ;5d6b
        JP      m521b                   ;5d6e
m5d71   CALL    0013H                   ;5d71
        JR      NZ,m5d7d                ;5d74
        AND     7FH                     ;5d76
        JR      Z,m5d71                 ;5d78
        CP      0DH                     ;5d7a
        RET                             ;5d7c
m5d7d   CP      1CH                     ;5d7d
        JR      NZ,m5d67                ;5d7f
        LD      A,0DH                   ;5d81
        LD      (HL),A                  ;5d83
        INC     HL                      ;5d84
        LD      (HL),A                  ;5d85
m5d86   CALL    m5578                   ;5d86
        CALL    m6162                   ;5d89
        CALL    m6178                   ;5d8c
        LD      (m597c),A               ;5d8f
        LD      A,C                     ;5d92
        LD      (m59c0),A               ;5d93
        LD      HL,(m593c)              ;5d96
        LD      DE,0FFE8H               ;5d99
        ADD     HL,DE                   ;5d9c
        LD      (61DBH),HL              ;5d9d
        LD      A,(m5997)               ;5da0
        AND     30H                     ;5da3
        JR      Z,m5e0f                 ;5da5
        AND     10H                     ;5da7
        LD      C,A                     ;5da9
        JR      Z,m5db5                 ;5daa
        XOR     A                       ;5dac
        LD      B,A                     ;5dad
        LD      HL,m6291                ;5dae
m5db1   LD      (HL),A                  ;5db1
        INC     HL                      ;5db2
        DJNZ    m5db1                   ;5db3
m5db5   LD      HL,m6491                ;5db5
m5db8   LD      A,(HL)                  ;5db8
        CP      0DH                     ;5db9
        JR      Z,m5e07                 ;5dbb
        LD      DE,m447f                ;5dbd
m5dc0   INC     DE                      ;5dc0
        LD      A,(HL)                  ;5dc1
        CP      0DH                     ;5dc2
        LD      (DE),A                  ;5dc4
        INC     HL                      ;5dc5
        JR      NZ,m5dc0                ;5dc6
        EX      DE,HL                   ;5dc8
        LD      (HL),3AH                ;5dc9
        INC     HL                      ;5dcb
        LD      A,(m594c)               ;5dcc
        LD      B,64H                   ;5dcf
        CALL    m61cb                   ;5dd1
        LD      B,0AH                   ;5dd4
        CALL    m61cb                   ;5dd6
        ADD     A,30H                   ;5dd9
        LD      (HL),A                  ;5ddb
        INC     HL                      ;5ddc
        LD      (HL),0DH                ;5ddd
        EX      DE,HL                   ;5ddf
        LD      DE,USRFCB               ;5de0
        CALL    FOPEN                   ;5de3
        JR      Z,m5df1                 ;5de6
        CP      18H                     ;5de8
        JR      Z,m5db8                 ;5dea
        CP      19H                     ;5dec
        JP      NZ,m521a                ;5dee
m5df1   LD      A,(m4f56)               ;5df1
        PUSH    HL                      ;5df4
        LD      HL,m6291                ;5df5
        LD      E,A                     ;5df8
        LD      D,00H                   ;5df9
        ADD     HL,DE                   ;5dfb
        LD      A,C                     ;5dfc
        OR      A                       ;5dfd
        JR      Z,m5e03                 ;5dfe
        LD      A,(m4d6e)               ;5e00
m5e03   LD      (HL),A                  ;5e03
        POP     HL                      ;5e04
        JR      m5db8                   ;5e05
m5e07   LD      A,05H                   ;5e07
        CALL    m568d                   ;5e09
        CALL    m5578                   ;5e0c
m5e0f   LD      HL,m6491                ;5e0f
        LD      (m5d12),HL              ;5e12
        LD      (m5d14),HL              ;5e15
        LD      C,00H                   ;5e18
m5e1a   CALL    m619d                   ;5e1a
        JP      NZ,m5eaa                ;5e1d
        CALL    m61f6                   ;5e20
        LD      A,(m5996)               ;5e23
        JR      NZ,m5e32                ;5e26
        BIT     0,A                     ;5e28
        JR      Z,m5e32                 ;5e2a
        INC     HL                      ;5e2c
        BIT     5,(HL)                  ;5e2d
        DEC     HL                      ;5e2f
        JR      Z,m5eaa                 ;5e30
m5e32   BIT     4,A                     ;5e32
        JR      Z,m5e3e                 ;5e34
        BIT     6,(HL)                  ;5e36
        JR      NZ,m5eaa                ;5e38
        BIT     3,(HL)                  ;5e3a
        JR      NZ,m5eaa                ;5e3c
m5e3e   BIT     1,A                     ;5e3e
        JR      Z,m5e5b                 ;5e40
        PUSH    HL                      ;5e42
        PUSH    DE                      ;5e43
        PUSH    BC                      ;5e44
        LD      DE,000DH                ;5e45
        ADD     HL,DE                   ;5e48
        LD      DE,m624c                ;5e49
        LD      B,03H                   ;5e4c
m5e4e   LD      A,(DE)                  ;5e4e
        CP      (HL)                    ;5e4f
        INC     DE                      ;5e50
        INC     HL                      ;5e51
        JR      NZ,m5e56                ;5e52
        DJNZ    m5e4e                   ;5e54
m5e56   POP     BC                      ;5e56
        POP     DE                      ;5e57
        POP     HL                      ;5e58
        JR      NZ,m5eaa                ;5e59
m5e5b   LD      D,(HL)                  ;5e5b
        BIT     6,D                     ;5e5c
        CALL    NZ,m61ea                ;5e5e
        JR      NZ,m5eaa                ;5e61
        LD      A,(m5995)               ;5e63
        BIT     6,A                     ;5e66
        JR      Z,m5e87                 ;5e68
        PUSH    DE                      ;5e6a
        PUSH    BC                      ;5e6b
        CALL    m58a0                   ;5e6c
        LD      HL,m625c                ;5e6f
        CALL    m58e4                   ;5e72
        POP     BC                      ;5e75
        POP     DE                      ;5e76
        JR      NZ,m5e81                ;5e77
        LD      HL,m6d5e                ;5e79
        CALL    DSPLY                   ;5e7c
        JR      m5e0f                   ;5e7f
m5e81   DEC     A                       ;5e81
        JR      Z,m5eb3                 ;5e82
        DEC     A                       ;5e84
        JR      Z,m5eaa                 ;5e85
m5e87   LD      HL,(m5d14)              ;5e87
        LD      (HL),80H                ;5e8a
        BIT     6,D                     ;5e8c
        JR      Z,m5ea2                 ;5e8e
        LD      A,(m5997)               ;5e90
        BIT     3,A                     ;5e93
        JR      NZ,m5ea2                ;5e95
        LD      A,C                     ;5e97
        CP      80H                     ;5e98
        JR      NC,m5ea2                ;5e9a
        AND     18H                     ;5e9c
        JR      NZ,m5ea2                ;5e9e
        SET     6,(HL)                  ;5ea0
m5ea2   INC     HL                      ;5ea2
        LD      (HL),C                  ;5ea3
        INC     HL                      ;5ea4
        LD      (HL),B                  ;5ea5
        INC     HL                      ;5ea6
        LD      (m5d14),HL              ;5ea7
m5eaa   LD      HL,m597c                ;5eaa
        CALL    m61ba                   ;5ead
        JP      NC,m5e1a                ;5eb0
m5eb3   CALL    m6190                   ;5eb3
        CALL    m5699                   ;5eb6
        JP      Z,m552d                 ;5eb9
m5ebc   PUSH    HL                      ;5ebc
        CALL    m61d6                   ;5ebd
        JR      C,m5ece                 ;5ec0
        CALL    m5ee4                   ;5ec2
        CALL    m5578                   ;5ec5
        CALL    m6190                   ;5ec8
        POP     HL                      ;5ecb
        JR      m5ebc                   ;5ecc
m5ece   INC     HL                      ;5ece
        LD      A,(HL)                  ;5ecf
        CALL    m56ef                   ;5ed0
        LD      BC,0018H                ;5ed3
        LDIR                            ;5ed6
        POP     HL                      ;5ed8
        SET     4,(HL)                  ;5ed9
        CALL    m5699                   ;5edb
        JR      NZ,m5ebc                ;5ede
        LD      HL,m60bf                ;5ee0
        PUSH    HL                      ;5ee3
m5ee4   CALL    m557d                   ;5ee4
        CALL    m6162                   ;5ee7
        CALL    m6178                   ;5eea
        LD      (m597d),A               ;5eed
        LD      A,C                     ;5ef0
        LD      (m59ce),A               ;5ef1
        LD      A,(m5997)               ;5ef4
        BIT     3,A                     ;5ef7
        JP      Z,m5f92                 ;5ef9
        LD      C,00H                   ;5efc
m5efe   CALL    m619d                   ;5efe
        JP      NZ,m5f89                ;5f01
        LD      (5F1EH),HL              ;5f04
        CALL    m6190                   ;5f07
m5f0a   CALL    m5699                   ;5f0a
        JR      Z,m5f89                 ;5f0d
        BIT     4,(HL)                  ;5f0f
        JR      Z,m5f0a                 ;5f11
        CALL    m61d6                   ;5f13
        BIT     5,(HL)                  ;5f16
        JR      NZ,m5f0a                ;5f18
        PUSH    HL                      ;5f1a
        LD      B,05H                   ;5f1b
        LD      HL,0000H                ;5f1d
        PUSH    HL                      ;5f20
        PUSH    DE                      ;5f21
m5f22   INC     HL                      ;5f22
        INC     DE                      ;5f23
        DJNZ    m5f22                   ;5f24
        LD      B,0BH                   ;5f26
        CALL    m6254                   ;5f28
        POP     HL                      ;5f2b
        POP     DE                      ;5f2c
        JR      Z,m5f32                 ;5f2d
        POP     HL                      ;5f2f
        JR      m5f0a                   ;5f30
m5f32   PUSH    DE                      ;5f32
        PUSH    BC                      ;5f33
        LD      BC,0003H                ;5f34
        ADD     HL,BC                   ;5f37
        EX      DE,HL                   ;5f38
        ADD     HL,BC                   ;5f39
        LD      A,(DE)                  ;5f3a
        LD      (HL),A                  ;5f3b
        INC     HL                      ;5f3c
        PUSH    AF                      ;5f3d
        INC     DE                      ;5f3e
        LD      A,(DE)                  ;5f3f
        LD      (HL),A                  ;5f40
        LD      BC,0010H                ;5f41
        ADD     HL,BC                   ;5f44
        EX      DE,HL                   ;5f45
        ADD     HL,BC                   ;5f46
        LD      A,(HL)                  ;5f47
        LD      (DE),A                  ;5f48
        INC     DE                      ;5f49
        INC     HL                      ;5f4a
        LD      A,(HL)                  ;5f4b
        LD      (DE),A                  ;5f4c
        DEC     DE                      ;5f4d
        EX      DE,HL                   ;5f4e
        POP     AF                      ;5f4f
        CALL    m6209                   ;5f50
        POP     BC                      ;5f53
        POP     DE                      ;5f54
        POP     HL                      ;5f55
        SET     5,(HL)                  ;5f56
        INC     HL                      ;5f58
        INC     HL                      ;5f59
        LD      (HL),C                  ;5f5a
        LD      A,C                     ;5f5b
        LD      (m5b1e),A               ;5f5c
        CALL    m5711                   ;5f5f
        LD      A,(DMODUL)              ;5f62
        CP      05H                     ;5f65
        JP      NZ,m5608                ;5f67
        INC     DE                      ;5f6a
        LD      A,(DE)                  ;5f6b
        BIT     6,A                     ;5f6c
        DEC     DE                      ;5f6e
        JR      NZ,m5f89                ;5f6f
        LD      HL,DFLAG2               ;5f71
        SET     2,(HL)                  ;5f74
        PUSH    HL                      ;5f76
        EX      DE,HL                   ;5f77
        LD      DE,m5b17                ;5f78
        CALL    m60a9                   ;5f7b
        JP      NZ,m521a                ;5f7e
        POP     HL                      ;5f81
        RES     2,(HL)                  ;5f82
        LD      A,05H                   ;5f84
        LD      (DMODUL),A              ;5f86
m5f89   LD      HL,m597d                ;5f89
        CALL    m61ba                   ;5f8c
        JP      NC,m5efe                ;5f8f
m5f92   LD      A,(m5995)               ;5f92
        BIT     3,A                     ;5f95
        RET     NZ                      ;5f97
        CALL    m56f9                   ;5f98
        LD      DE,6391H                ;5f9b
        CALL    m6172                   ;5f9e
        CALL    m6162                   ;5fa1
        CALL    m6190                   ;5fa4
m5fa7   CALL    m5699                   ;5fa7
        JP      Z,m6092                 ;5faa
        BIT     4,(HL)                  ;5fad
        JR      Z,m5fa7                 ;5faf
        RES     4,(HL)                  ;5fb1
        PUSH    HL                      ;5fb3
        BIT     5,(HL)                  ;5fb4
        INC     HL                      ;5fb6
        JP      NZ,m6083                ;5fb7
        CALL    m61ea                   ;5fba
        JP      NZ,m6083                ;5fbd
        LD      A,(HL)                  ;5fc0
        LD      C,A                     ;5fc1
        LD      B,00H                   ;5fc2
        AND     1FH                     ;5fc4
        LD      HL,m597d                ;5fc6
        CP      (HL)                    ;5fc9
        JP      NC,m6083                ;5fca
        LD      HL,m6291                ;5fcd
        ADD     HL,BC                   ;5fd0
        LD      A,(HL)                  ;5fd1
        OR      A                       ;5fd2
        EX      DE,HL                   ;5fd3
        JP      NZ,m6083                ;5fd4
        POP     HL                      ;5fd7
        SET     5,(HL)                  ;5fd8
        PUSH    HL                      ;5fda
        INC     HL                      ;5fdb
        INC     HL                      ;5fdc
        LD      A,(HL)                  ;5fdd
        LD      (DE),A                  ;5fde
        LD      A,C                     ;5fdf
        LD      (HL),A                  ;5fe0
        LD      (6028H),A               ;5fe1
        CALL    m56e2                   ;5fe4
        EX      DE,HL                   ;5fe7
        LD      HL,(61D8H)              ;5fe8
        LD      BC,0016H                ;5feb
        LDIR                            ;5fee
        LD      C,(HL)                  ;5ff0
        INC     HL                      ;5ff1
        LD      B,(HL)                  ;5ff2
        PUSH    BC                      ;5ff3
        LD      B,0AH                   ;5ff4
        LD      (6078H),DE              ;5ff6
m5ffa   LD      A,0FFH                  ;5ffa
        LD      (DE),A                  ;5ffc
        INC     DE                      ;5ffd
        DJNZ    m5ffa                   ;5ffe
        POP     BC                      ;6000
        CALL    m5706                   ;6001
        POP     HL                      ;6004
        BIT     6,(HL)                  ;6005
        PUSH    HL                      ;6007
        JP      Z,m6083                 ;6008
        LD      A,C                     ;600b
        CP      0FEH                    ;600c
        JR      NC,m6083                ;600e
        LD      L,A                     ;6010
        LD      A,(m59bc)               ;6011
        CALL    MULHL                   ;6014
        LD      A,B                     ;6017
        AND     1FH                     ;6018
        LD      C,A                     ;601a
        LD      A,B                     ;601b
        RLCA                            ;601c
        RLCA                            ;601d
        RLCA                            ;601e
        AND     07H                     ;601f
        LD      E,A                     ;6021
        LD      D,00H                   ;6022
        ADD     HL,DE                   ;6024
        LD      A,02H                   ;6025
        CP      00H                     ;6027
        JR      NZ,m6030                ;6029
        LD      HL,0001H                ;602b
        JR      m6064                   ;602e
m6030   EX      DE,HL                   ;6030
        LD      A,(m59b7)               ;6031
        LD      L,A                     ;6034
        LD      A,(m59bc)               ;6035
        CALL    MULHL                   ;6038
        EX      DE,HL                   ;603b
        LD      A,(m59c0)               ;603c
        LD      B,A                     ;603f
        PUSH    DE                      ;6040
m6041   INC     DE                      ;6041
        DJNZ    m6041                   ;6042
        OR      A                       ;6044
        SBC     HL,DE                   ;6045
        JR      C,m6053                 ;6047
        POP     DE                      ;6049
        LD      A,(m59ce)               ;604a
        LD      E,A                     ;604d
        LD      D,00H                   ;604e
        ADD     HL,DE                   ;6050
        JR      m6058                   ;6051
m6053   ADD     HL,DE                   ;6053
        POP     DE                      ;6054
        OR      A                       ;6055
        SBC     HL,DE                   ;6056
m6058   EX      DE,HL                   ;6058
        LD      A,(m59c5)               ;6059
        LD      L,A                     ;605c
        LD      A,(m59ca)               ;605d
        CALL    MULHL                   ;6060
        ADD     HL,DE                   ;6063
m6064   LD      D,C                     ;6064
        LD      A,(m59ca)               ;6065
        CALL    m4cb4                   ;6068
        INC     H                       ;606b
        DEC     H                       ;606c
        CALL    NZ,m5240                ;606d
        LD      B,A                     ;6070
        RRCA                            ;6071
        RRCA                            ;6072
        RRCA                            ;6073
        PUSH    HL                      ;6074
        OR      D                       ;6075
        LD      H,A                     ;6076
        LD      (0000H),HL              ;6077
        LD      HL,6391H                ;607a
        LD      C,D                     ;607d
        POP     DE                      ;607e
        INC     C                       ;607f
        CALL    m621c                   ;6080
m6083   CALL    m61d6                   ;6083
        POP     HL                      ;6086
        BIT     5,(HL)                  ;6087
        JR      NZ,m608f                ;6089
        LD      A,H                     ;608b
        LD      (60C3H),A               ;608c
m608f   JP      m5fa7                   ;608f
m6092   CALL    m570d                   ;6092
        LD      HL,m6291                ;6095
        CALL    m616f                   ;6098
        PUSH    HL                      ;609b
        LD      A,01H                   ;609c
        CALL    m5701                   ;609e
        POP     HL                      ;60a1
        CALL    m616f                   ;60a2
        XOR     A                       ;60a5
        JP      m5701                   ;60a6
m60a9   CALL    m4980                   ;60a9
        XOR     A                       ;60ac
        LD      (m4fdb),A               ;60ad
        PUSH    HL                      ;60b0
        INC     L                       ;60b1
        INC     L                       ;60b2
        INC     L                       ;60b3
        LD      A,(HL)                  ;60b4
        LD      DE,0011H                ;60b5
        ADD     HL,DE                   ;60b8
        LD      E,(HL)                  ;60b9
        INC     HL                      ;60ba
        LD      D,(HL)                  ;60bb
        JP      m4e3d                   ;60bc
m60bf   CALL    m568b                   ;60bf
        LD      A,00H                   ;60c2
        OR      A                       ;60c4
        JP      Z,m6157                 ;60c5
m60c8   CALL    m5578                   ;60c8
        CALL    m6190                   ;60cb
m60ce   CALL    m5699                   ;60ce
        JR      Z,m60f1                 ;60d1
        BIT     5,(HL)                  ;60d3
        JR      NZ,m60ce                ;60d5
        CALL    m61d6                   ;60d7
        JR      C,m60e1                 ;60da
        CALL    m60f5                   ;60dc
        JR      m60c8                   ;60df
m60e1   PUSH    HL                      ;60e1
        SET     4,(HL)                  ;60e2
        INC     HL                      ;60e4
        LD      A,(HL)                  ;60e5
        CALL    m56ef                   ;60e6
        LD      BC,0016H                ;60e9
        LDIR                            ;60ec
        POP     HL                      ;60ee
        JR      m60ce                   ;60ef
m60f1   LD      HL,m6157                ;60f1
        PUSH    HL                      ;60f4
m60f5   CALL    m557d                   ;60f5
        CALL    m6190                   ;60f8
m60fb   CALL    m5699                   ;60fb
        RET     Z                       ;60fe
        BIT     4,(HL)                  ;60ff
        JR      Z,m60fb                 ;6101
        PUSH    HL                      ;6103
        RES     4,(HL)                  ;6104
        CALL    m61d6                   ;6106
        INC     HL                      ;6109
        LD      B,(HL)                  ;610a
        INC     HL                      ;610b
        PUSH    DE                      ;610c
        PUSH    HL                      ;610d
        CALL    m50cf                   ;610e
        JP      NZ,m521a                ;6111
        EX      DE,HL                   ;6114
        POP     HL                      ;6115
        LD      (HL),A                  ;6116
        POP     HL                      ;6117
        PUSH    DE                      ;6118
        LD      BC,0016H                ;6119
        LDIR                            ;611c
        POP     DE                      ;611e
        CALL    m61fc                   ;611f
        JR      Z,m614f                 ;6122
        BIT     5,A                     ;6124
        EX      DE,HL                   ;6126
        LD      DE,0000H                ;6127
        LD      BC,m4296                ;612a
m612d   JR      Z,m613a                 ;612d
        LD      A,(m4044)               ;612f
        LD      D,A                     ;6132
        LD      A,(m4046)               ;6133
        LD      E,A                     ;6136
        LD      BC,m5cef                ;6137
m613a   INC     HL                      ;613a
        LD      (HL),E                  ;613b
        INC     HL                      ;613c
        LD      (HL),D                  ;613d
        INC     HL                      ;613e
        LD      A,(HL)                  ;613f
        LD      DE,000DH                ;6140
        ADD     HL,DE                   ;6143
m6144   LD      (HL),C                  ;6144
        INC     HL                      ;6145
        LD      (HL),B                  ;6146
        INC     HL                      ;6147
        LD      (HL),C                  ;6148
        INC     HL                      ;6149
        LD      (HL),B                  ;614a
        INC     HL                      ;614b
        CALL    m6209                   ;614c
m614f   CALL    m5711                   ;614f
        POP     HL                      ;6152
        SET     5,(HL)                  ;6153
        JR      m60fb                   ;6155
m6157   LD      A,0FFH                  ;6157
        LD      (m5b1e),A               ;6159
        LD      (586AH),A               ;615c
        JP      m524e                   ;615f
m6162   LD      A,01H                   ;6162
        CALL    m56fa                   ;6164
        LD      DE,m6291                ;6167
        CALL    m6172                   ;616a
        DEC     H                       ;616d
        RET                             ;616e
m616f   LD      DE,SECBUF               ;616f
m6172   LD      BC,0100H                ;6172
        LDIR                            ;6175
        RET                             ;6177
m6178   CALL    m61f6                   ;6178
        LD      A,10H                   ;617b
        LD      C,06H                   ;617d
m617f   RET     NZ                      ;617f
        LD      E,05H                   ;6180
        LD      A,(DIRLEN)              ;6182
        ADD     A,08H                   ;6185
        LD      B,A                     ;6187
        LD      C,00H                   ;6188
m618a   INC     C                       ;618a
        SUB     E                       ;618b
        JR      NC,m618a                ;618c
        LD      A,B                     ;618e
        RET                             ;618f
m6190   LD      HL,(m5d14)              ;6190
        LD      (61D8H),HL              ;6193
        LD      HL,(m5d12)              ;6196
        DEC     HL                      ;6199
        DEC     HL                      ;619a
        DEC     HL                      ;619b
        RET                             ;619c
m619d   LD      B,00H                   ;619d
        LD      HL,m6291                ;619f
        ADD     HL,BC                   ;61a2
        LD      A,(HL)                  ;61a3
        CP      01H                     ;61a4
        LD      B,A                     ;61a6
        RET     C                       ;61a7
        CALL    m61f6                   ;61a8
        LD      A,C                     ;61ab
        JR      NZ,m61b1                ;61ac
        CP      02H                     ;61ae
        RET     C                       ;61b0
m61b1   CALL    m56e2                   ;61b1
        LD      A,(HL)                  ;61b4
        AND     90H                     ;61b5
        CP      10H                     ;61b7
        RET                             ;61b9
m61ba   CALL    m61f6                   ;61ba
        LD      A,50H                   ;61bd
m61bf   JR      NZ,m61c7                ;61bf
        LD      A,C                     ;61c1
        ADD     A,20H                   ;61c2
        LD      C,A                     ;61c4
        RET     NC                      ;61c5
        LD      A,(HL)                  ;61c6
m61c7   DEC     A                       ;61c7
        INC     C                       ;61c8
        CP      C                       ;61c9
        RET                             ;61ca
m61cb   CP      B                       ;61cb
        RET     C                       ;61cc
        LD      (HL),2FH                ;61cd
m61cf   INC     (HL)                    ;61cf
        SUB     B                       ;61d0
        JR      NC,m61cf                ;61d1
        ADD     A,B                     ;61d3
        INC     HL                      ;61d4
        RET                             ;61d5
m61d6   PUSH    HL                      ;61d6
        LD      HL,0000H                ;61d7
        LD      DE,0000H                ;61da
        RST     18H                     ;61dd
        PUSH    AF                      ;61de
        EX      DE,HL                   ;61df
        LD      HL,0018H                ;61e0
        ADD     HL,DE                   ;61e3
        LD      (61D8H),HL              ;61e4
        POP     AF                      ;61e7
        POP     HL                      ;61e8
        RET                             ;61e9
m61ea   PUSH    HL                      ;61ea
        LD      HL,m59c7                ;61eb
        LD      A,(m59b9)               ;61ee
        OR      (HL)                    ;61f1
        POP     HL                      ;61f2
        AND     20H                     ;61f3
        RET                             ;61f5
m61f6   LD      A,(m430c)               ;61f6
        AND     20H                     ;61f9
        RET                             ;61fb
m61fc   PUSH    HL                      ;61fc
        LD      HL,m59c7                ;61fd
        LD      A,(m59b9)               ;6200
        XOR     (HL)                    ;6203
        AND     20H                     ;6204
        LD      A,(HL)                  ;6206
        POP     HL                      ;6207
        RET                             ;6208
m6209   OR      A                       ;6209
        CALL    NZ,m61fc                ;620a
        RET     Z                       ;620d
        LD      E,(HL)                  ;620e
        INC     HL                      ;620f
        LD      D,(HL)                  ;6210
        INC     DE                      ;6211
        BIT     5,A                     ;6212
        JR      Z,m6218                 ;6214
        DEC     DE                      ;6216
        DEC     DE                      ;6217
m6218   LD      (HL),D                  ;6218
        DEC     HL                      ;6219
        LD      (HL),E                  ;621a
        RET                             ;621b
m621c   LD      D,00H                   ;621c
        ADD     HL,DE                   ;621e
        LD      D,80H                   ;621f
        LD      A,B                     ;6221
        INC     B                       ;6222
m6223   RLC     D                       ;6223
        DJNZ    m6223                   ;6225
        LD      B,A                     ;6227
m6228   LD      A,(m59ca)               ;6228
        SUB     B                       ;622b
        LD      B,A                     ;622c
m622d   PUSH    HL                      ;622d
        LD      HL,m59c6                ;622e
        LD      A,E                     ;6231
        CP      (HL)                    ;6232
        POP     HL                      ;6233
        JR      NC,m6249                ;6234
        LD      A,(HL)                  ;6236
        AND     D                       ;6237
        JR      NZ,m6249                ;6238
        LD      A,(HL)                  ;623a
        OR      D                       ;623b
        LD      (HL),A                  ;623c
        DEC     C                       ;623d
        RET     Z                       ;623e
        RLC     D                       ;623f
        DJNZ    m622d                   ;6241
        LD      D,01H                   ;6243
        INC     HL                      ;6245
        INC     E                       ;6246
        JR      m6228                   ;6247
m6249   CALL    m5240                   ;6249
m624c   JR      NZ,m626e                ;624c
        JR      NZ,m6261                ;624e
        RET     NC                      ;6250
        LD      B,D                     ;6251
        LD      B,08H                   ;6252
m6254   LD      A,(DE)                  ;6254
        CP      (HL)                    ;6255
        RET     NZ                      ;6256
        INC     DE                      ;6257
        INC     HL                      ;6258
        DJNZ    m6254                   ;6259
        RET                             ;625b
m625c   LD      D,A                     ;625c
        LD      B,C                     ;625d
        LD      C,(HL)                  ;625e
        LD      C,D                     ;625f
        NOP                             ;6260
m6261   CALL    NZ,m6144                ;6261
        LD      (HL),H                  ;6264
        LD      H,L                     ;6265
        LD      L,C                     ;6266
        JR      NZ,$+109                ;6267
        LD      L,A                     ;6269
        LD      (HL),B                  ;626a
        LD      L,C                     ;626b
        LD      H,L                     ;626c
        LD      (HL),D                  ;626d
m626e   LD      H,L                     ;626e
        LD      L,(HL)                  ;626f
        CCF                             ;6270
        JR      NZ,$+76                 ;6271
        INC     L                       ;6273
        LD      C,(HL)                  ;6274
        INC     L                       ;6275
        LD      B,C                     ;6276
        INC     L                       ;6277
        LD      D,A                     ;6278
        JR      NZ,m627e                ;6279
m627b   LD      C,E                     ;627b
        LD      L,A                     ;627c
        LD      (HL),B                  ;627d
m627e   LD      L,C                     ;627e
        LD      H,L                     ;627f
        LD      (HL),D                  ;6280
        LD      H,L                     ;6281
        INC     BC                      ;6282
m6283   LD      C,C                     ;6283
        LD      B,H                     ;6284
        LD      C,H                     ;6285
        CPL                             ;6286
        LD      E,B                     ;6287
        LD      B,H                     ;6288
        LD      C,H                     ;6289
        JR      NZ,m62d0                ;628a
        LD      H,C                     ;628c
        LD      (HL),H                  ;628d
        LD      H,L                     ;628e
        LD      L,C                     ;628f
        INC     BC                      ;6290
m6291   LD      A,(m5997)               ;6291
        AND     30H                     ;6294
        LD      HL,SECBUF               ;6296
        LD      DE,USRFCB               ;6299
        CALL    NZ,FOPEN                ;629c
        JP      NZ,m5d67                ;629f
        LD      A,(m5996)               ;62a2
        AND     08H                     ;62a5
        LD      A,0F3H                  ;62a7
        JR      Z,m62ad                 ;62a9
        LD      A,0E5H                  ;62ab
m62ad   CALL    m568d                   ;62ad
        CALL    m5578                   ;62b0
        LD      A,(DFLAG3)              ;62b3
        AND     82H                     ;62b6
        CP      80H                     ;62b8
        JR      Z,m62c3                 ;62ba
        LD      A,(m5992+2)             ;62bc
        AND     02H                     ;62bf
        JR      NZ,m632c                ;62c1
m62c3   CALL    m56f9                   ;62c3
        LD      A,(m5995)               ;62c6
        BIT     5,A                     ;62c9
        JR      NZ,m62d3                ;62cb
        LD      HL,(m42ce)              ;62cd
m62d0   LD      (m5981),HL              ;62d0
m62d3   LD      A,(m5992+2)             ;62d3
        BIT     2,A                     ;62d6
        JR      NZ,m62e5                ;62d8
        LD      HL,m42d0                ;62da
        LD      DE,m5983                ;62dd
        LD      BC,0008H                ;62e0
        LDIR                            ;62e3
m62e5   LD      A,(m5995)               ;62e5
        BIT     4,A                     ;62e8
        JR      Z,m62f7                 ;62ea
        LD      HL,m42d8                ;62ec
        LD      DE,m598b                ;62ef
        LD      BC,0008H                ;62f2
        LDIR                            ;62f5
m62f7   LD      A,(m5996)               ;62f7
        BIT     7,A                     ;62fa
        JR      Z,m6314                 ;62fc
        LD      HL,m5968                ;62fe
        CALL    624FH                   ;6301
        JR      Z,m632c                 ;6304
        LD      HL,m5a3c                ;6306
        CALL    m692f                   ;6309
        CALL    m693b                   ;630c
        CALL    m58c8                   ;630f
        JR      NZ,m62c3                ;6312
m6314   LD      A,(DFLAG3)              ;6314
        AND     82H                     ;6317
        CP      80H                     ;6319
        JR      NZ,m632c                ;631b
        LD      HL,(m42ce)              ;631d
        LD      DE,(m5978)              ;6320
        OR      A                       ;6324
        SBC     HL,DE                   ;6325
        LD      A,37H                   ;6327
        JP      NZ,m521a                ;6329
m632c   LD      HL,m5996                ;632c
        RES     7,(HL)                  ;632f
        LD      A,(m5996)               ;6331
        BIT     3,A                     ;6334
        JP      NZ,m5d16                ;6336
        LD      HL,(m59d1)              ;6339
        LD      DE,(m59c3)              ;633c
        RST     18H                     ;6340
        LD      A,(m5992+2)             ;6341
        LD      C,A                     ;6344
        LD      HL,(m59c1)              ;6345
        JR      NC,m6352                ;6348
        BIT     1,C                     ;634a
        JP      Z,m5204                 ;634c
        LD      HL,(m59cf)              ;634f
m6352   LD      (m5af1),HL              ;6352
        JR      Z,m6365                 ;6355
        BIT     1,C                     ;6357
        JR      NZ,m6365                ;6359
        LD      HL,m59ca                ;635b
        LD      A,(m59bc)               ;635e
        CP      (HL)                    ;6361
        JP      NZ,m5204                ;6362
m6365   CALL    m674d                   ;6365
        CALL    m67c3                   ;6368
        LD      HL,0000H                ;636b
        LD      (m5aef),HL              ;636e
        LD      (m5b21),HL              ;6371
        JP      m5273                   ;6374
m6377   LD      BC,m594c                ;6377
        LD      DE,m5ae5                ;637a
        CALL    m6437                   ;637d
        LD      BC,m5956                ;6380
        LD      DE,m5b17                ;6383
        CALL    m6437                   ;6386
        CALL    m5c96                   ;6389
        CALL    m568b                   ;638c
        JP      m5279                   ;638f
m6392   CALL    m6ecb                   ;6392
        RET     NC                      ;6395
        LD      (m5b1d),A               ;6396
        LD      (m5956),A               ;6399
        LD      (m4dfa),A               ;639c
        RET                             ;639f
m63a0   LD      DE,m64a9                ;63a0
m63a3   LD      A,(HL)                  ;63a3
        CP      3DH                     ;63a4
        RET     NZ                      ;63a6
        PUSH    DE                      ;63a7
        INC     HL                      ;63a8
        CALL    m6ee7                   ;63a9
        POP     DE                      ;63ac
        OR      A                       ;63ad
        LD      (DE),A                  ;63ae
        RET     NZ                      ;63af
        JP      m5218                   ;63b0
m63b3   LD      B,03H                   ;63b3
        CALL    m5646                   ;63b5
        LD      B,02H                   ;63b8
        LD      HL,m593b                ;63ba
        SET     7,(HL)                  ;63bd
        CALL    m5646                   ;63bf
        LD      BC,(m594c)              ;63c2
        LD      HL,m59b7                ;63c6
        LD      A,0FFH                  ;63c9
        CALL    m63ec                   ;63cb
        LD      BC,(m5956)              ;63ce
        LD      HL,m59c5                ;63d2
        LD      A,0FFH                  ;63d5
        CALL    m63ec                   ;63d7
        LD      HL,m64a3                ;63da
        LD      C,(HL)                  ;63dd
m63de   INC     HL                      ;63de
        LD      E,(HL)                  ;63df
        INC     HL                      ;63e0
        LD      D,(HL)                  ;63e1
        INC     HL                      ;63e2
        LD      A,(HL)                  ;63e3
        OR      A                       ;63e4
        JR      Z,m63e8                 ;63e5
        LD      (DE),A                  ;63e7
m63e8   DEC     C                       ;63e8
        JR      NZ,m63de                ;63e9
        RET                             ;63eb
m63ec   CP      0FFH                    ;63ec
        RET     Z                       ;63ee
        RLCA                            ;63ef
        RLCA                            ;63f0
        RLCA                            ;63f1
        RLCA                            ;63f2
        PUSH    HL                      ;63f3
        LD      HL,m5940                ;63f4
        PUSH    AF                      ;63f7
        LD      A,C                     ;63f8
        OR      A                       ;63f9
        JR      NZ,m6406                ;63fa
        DEC     A                       ;63fc
        XOR     B                       ;63fd
        INC     HL                      ;63fe
        AND     (HL)                    ;63ff
        LD      (HL),A                  ;6400
        DEC     HL                      ;6401
        INC     B                       ;6402
        LD      A,(HL)                  ;6403
        OR      B                       ;6404
        LD      (HL),A                  ;6405
m6406   LD      A,(m5956)               ;6406
        LD      B,A                     ;6409
        LD      A,(m594c)               ;640a
        CP      B                       ;640d
        JR      NZ,m6417                ;640e
        LD      A,(HL)                  ;6410
        OR      06H                     ;6411
        LD      (HL),A                  ;6413
        INC     HL                      ;6414
        LD      (HL),01H                ;6415
m6417   CALL    m6424                   ;6417
        POP     AF                      ;641a
        ADD     A,L                     ;641b
        LD      L,A                     ;641c
        POP     DE                      ;641d
        LD      BC,000AH                ;641e
        LDIR                            ;6421
        RET                             ;6423
m6424   LD      HL,0002H                ;6424
        LD      (m5b53),HL              ;6427
        LD      HL,SECBUF               ;642a
        LD      DE,m5b49                ;642d
        CALL    READ                    ;6430
        RET     Z                       ;6433
        JP      m521a                   ;6434
m6437   LD      HL,m5940                ;6437
m643a   LD      A,(DE)                  ;643a
        CP      3AH                     ;643b
        INC     DE                      ;643d
        JR      NZ,m6458                ;643e
        LD      A,(HL)                  ;6440
        CP      06H                     ;6441
        JR      NC,m6482                ;6443
        PUSH    HL                      ;6445
        PUSH    BC                      ;6446
        EX      DE,HL                   ;6447
        CALL    m6ed7                   ;6448
        POP     BC                      ;644b
        POP     HL                      ;644c
        OR      A                       ;644d
        LD      (BC),A                  ;644e
        RET     NZ                      ;644f
        INC     BC                      ;6450
        LD      A,(BC)                  ;6451
        BIT     0,(HL)                  ;6452
        RET     Z                       ;6454
        OR      (HL)                    ;6455
        LD      (HL),A                  ;6456
        RET                             ;6457
m6458   CP      03H                     ;6458
        JR      NZ,m643a                ;645a
        LD      A,(HL)                  ;645c
        CP      06H                     ;645d
        JR      C,m6474                 ;645f
        LD      A,(BC)                  ;6461
        OR      A                       ;6462
        INC     BC                      ;6463
        JR      NZ,m6468                ;6464
        SET     0,(HL)                  ;6466
m6468   ADD     A,30H                   ;6468
        LD      (DE),A                  ;646a
        DEC     DE                      ;646b
        EX      DE,HL                   ;646c
        LD      (HL),3AH                ;646d
        INC     HL                      ;646f
        INC     HL                      ;6470
        LD      (HL),03H                ;6471
        RET                             ;6473
m6474   BIT     0,A                     ;6474
        JR      NZ,m6482                ;6476
        LD      A,(m5997)               ;6478
        AND     0C0H                    ;647b
        LD      H,B                     ;647d
        LD      L,C                     ;647e
        JP      Z,m5538                 ;647f
m6482   JP      m5200                   ;6482
m6485   NOP                             ;6485
        RST     30H                     ;6486
        NOP                             ;6487
        NOP                             ;6488
        NOP                             ;6489
        NOP                             ;648a
        NOP                             ;648b
        NOP                             ;648c
        NOP                             ;648d
        NOP                             ;648e
        NOP                             ;648f
        NOP                             ;6490
m6491   NOP                             ;6491
        NOP                             ;6492
        NOP                             ;6493
        NOP                             ;6494
        NOP                             ;6495
        NOP                             ;6496
        NOP                             ;6497
        NOP                             ;6498
        NOP                             ;6499
        NOP                             ;649a
        NOP                             ;649b
        NOP                             ;649c
        NOP                             ;649d
        NOP                             ;649e
        NOP                             ;649f
        NOP                             ;64a0
        NOP                             ;64a1
        NOP                             ;64a2
m64a3   INC     B                       ;64a3
        CP      D                       ;64a4
        LD      E,C                     ;64a5
m64a6   NOP                             ;64a6
        RET     Z                       ;64a7
        LD      E,C                     ;64a8
m64a9   NOP                             ;64a9
        CALL    0059H                   ;64aa
        ADC     A,59H                   ;64ad
m64af   NOP                             ;64af
m64b0   LD      HL,SECBUF               ;64b0
        LD      B,00H                   ;64b3
m64b5   LD      (HL),A                  ;64b5
        INC     HL                      ;64b6
        DJNZ    m64b5                   ;64b7
        RET                             ;64b9
m64ba   NOP                             ;64ba
        CP      11H                     ;64bb
        DI                              ;64bd
        LD      HL,m37ec                ;64be
        LD      (HL),0FEH               ;64c1
        LD      (HL),0D0H               ;64c3
        INC     HL                      ;64c5
        NOP                             ;64c6
        NOP                             ;64c7
        INC     HL                      ;64c8
        LD      (HL),80H                ;64c9
        LD      DE,0005H                ;64cb
        EXX                             ;64ce
        LD      SP,DOSSTK               ;64cf
        LD      HL,m51ff                ;64d2
m64d5   CALL    m4252                   ;64d5
        CP      20H                     ;64d8
        LD      B,A                     ;64da
        JR      NC,m6506                ;64db
        LD      D,A                     ;64dd
        CALL    m4252                   ;64de
        LD      C,A                     ;64e1
        CALL    m4252                   ;64e2
        LD      E,A                     ;64e5
        DJNZ    m64fa                   ;64e6
        CALL    m4252                   ;64e8
        LD      D,A                     ;64eb
        DEC     C                       ;64ec
        DEC     C                       ;64ed
m64ee   INC     L                       ;64ee
        CALL    Z,m4255                 ;64ef
        LD      A,(HL)                  ;64f2
        LD      (DE),A                  ;64f3
        INC     DE                      ;64f4
m64f5   DEC     C                       ;64f5
        JR      NZ,m64ee                ;64f6
        JR      m64d5                   ;64f8
m64fa   DJNZ    m64f5                   ;64fa
        CALL    m4252                   ;64fc
        LD      D,A                     ;64ff
        LD      A,(DE)                  ;6500
        CP      0A5H                    ;6501
        INC     DE                      ;6503
        PUSH    DE                      ;6504
        RET     Z                       ;6505
m6506   LD      HL,m42e5                ;6506
        JP      m42c3                   ;6509
        INC     L                       ;650c
        LD      A,(HL)                  ;650d
        RET     NZ                      ;650e
        EXX                             ;650f
        LD      B,0AH                   ;6510
m6512   LD      HL,m37e1                ;6512
        LD      (HL),01H                ;6515
        PUSH    DE                      ;6517
        PUSH    BC                      ;6518
        LD      A,E                     ;6519
        SUB     00H                     ;651a
        JR      C,m6521                 ;651c
        LD      E,A                     ;651e
        LD      (HL),09H                ;651f
m6521   LD      HL,m37ec                ;6521
        CALL    m42ce                   ;6524
        LD      (m37ee),DE              ;6527
        LD      (HL),1BH                ;652b
        CALL    m42ce                   ;652d
        LD      (HL),88H                ;6530
        LD      DE,m37ef                ;6532
        LD      BC,m5100                ;6535
        CALL    m42d7                   ;6538
        LD      A,(HL)                  ;653b
        AND     83H                     ;653c
        JP      PO,m4281                ;653e
m6541   LD      A,(DE)                  ;6541
        LD      (BC),A                  ;6542
        INC     BC                      ;6543
m6544   BIT     1,(HL)                  ;6544
        JP      NZ,m4287                ;6546
        BIT     1,(HL)                  ;6549
        JP      NZ,m4287                ;654b
        BIT     1,(HL)                  ;654e
        JR      NZ,m6541                ;6550
        BIT     0,(HL)                  ;6552
        JR      Z,m655e                 ;6554
        BIT     1,(HL)                  ;6556
        JR      NZ,m6541                ;6558
        BIT     7,(HL)                  ;655a
        JR      Z,m6544                 ;655c
m655e   LD      A,(HL)                  ;655e
        LD      (HL),0D0H               ;655f
        POP     BC                      ;6561
        POP     DE                      ;6562
        AND     0FCH                    ;6563
        JR      NZ,m6573                ;6565
        INC     E                       ;6567
        LD      A,E                     ;6568
        SUB     00H                     ;6569
        JR      NZ,m6570                ;656b
        INC     D                       ;656d
        LD      E,00H                   ;656e
m6570   EXX                             ;6570
        LD      A,(HL)                  ;6571
        RET                             ;6572
m6573   CALL    m42d7                   ;6573
        LD      (HL),0BH                ;6576
        DJNZ    m6512                   ;6578
        LD      HL,m42dd                ;657a
m657d   LD      A,(HL)                  ;657d
        CP      03H                     ;657e
        JR      Z,m657d                 ;6580
        INC     HL                      ;6582
        CALL    0033H                   ;6583
        JR      m657d                   ;6586
        CALL    m42d7                   ;6588
m658b   BIT     0,(HL)                  ;658b
        JR      NZ,m658b                ;658d
        LD      A,(HL)                  ;658f
        RET                             ;6590
        LD      A,12H                   ;6591
m6593   DEC     A                       ;6593
        JR      NZ,m6593                ;6594
        RET                             ;6596
        INC     E                       ;6597
        RRA                             ;6598
        CCF                             ;6599
        LD      BC,m3f3f                ;659a
        CCF                             ;659d
        INC     BC                      ;659e
        INC     E                       ;659f
        RRA                             ;65a0
        LD      B,A                     ;65a1
        DEC     L                       ;65a2
        LD      B,H                     ;65a3
        LD      C,A                     ;65a4
        LD      D,E                     ;65a5
        CCF                             ;65a6
        INC     BC                      ;65a7
        NOP                             ;65a8
        NOP                             ;65a9
        LD      B,B                     ;65aa
        DAA                             ;65ab
        JR      C,m65e2                 ;65ac
        JR      NZ,m6604                ;65ae
m65b0   LD      B,E                     ;65b0
        LD      D,E                     ;65b1
        LD      H,4DH                   ;65b2
        LD      D,(HL)                  ;65b4
        LD      B,E                     ;65b5
        NOP                             ;65b6
m65b7   NOP                             ;65b7
m65b8   NOP                             ;65b8
m65b9   NOP                             ;65b9
m65ba   LD      E,(HL)                  ;65ba
        NOP                             ;65bb
        NOP                             ;65bc
        NOP                             ;65bd
        NOP                             ;65be
        LD      B,A                     ;65bf
        LD      B,H                     ;65c0
        LD      C,A                     ;65c1
        LD      D,E                     ;65c2
        JR      NZ,m65e5                ;65c3
        JR      NZ,m65e7                ;65c5
        LD      D,E                     ;65c7
        LD      E,C                     ;65c8
        LD      D,E                     ;65c9
        LD      H,B                     ;65ca
        LD      A,A                     ;65cb
        RRA                             ;65cc
        OR      D                       ;65cd
        DEC     B                       ;65ce
        NOP                             ;65cf
        NOP                             ;65d0
        NOP                             ;65d1
        RST     38H                     ;65d2
        RST     38H                     ;65d3
        RST     38H                     ;65d4
        RST     38H                     ;65d5
        RST     38H                     ;65d6
        RST     38H                     ;65d7
        RST     38H                     ;65d8
        RST     38H                     ;65d9
m65da   LD      E,L                     ;65da
        NOP                             ;65db
        NOP                             ;65dc
        NOP                             ;65dd
        NOP                             ;65de
        LD      C,C                     ;65df
        LD      C,(HL)                  ;65e0
        LD      C,B                     ;65e1
m65e2   LD      B,C                     ;65e2
        LD      C,H                     ;65e3
        LD      D,H                     ;65e4
m65e5   JR      NZ,m6607                ;65e5
m65e7   LD      D,E                     ;65e7
        LD      E,C                     ;65e8
        LD      D,E                     ;65e9
        AND     A                       ;65ea
        DEC     E                       ;65eb
        LD      SP,HL                   ;65ec
        PUSH    HL                      ;65ed
m65ee   LD      E,00H                   ;65ee
m65f0   JR      NC,m65f7                ;65f0
        RST     38H                     ;65f2
        RST     38H                     ;65f3
        RST     38H                     ;65f4
        RST     38H                     ;65f5
        RST     38H                     ;65f6
m65f7   RST     38H                     ;65f7
        RST     38H                     ;65f8
        RST     38H                     ;65f9
m65fa   CALL    m6392                   ;65fa
        JP      NC,m5218                ;65fd
        CALL    m63a0                   ;6600
        PUSH    HL                      ;6603
m6604   LD      HL,m5997                ;6604
m6607   SET     2,(HL)                  ;6607
        POP     HL                      ;6609
        CALL    m6eb5                   ;660a
        CALL    C,m4f95                 ;660d
        CALL    m6fb8                   ;6610
        CALL    m6eb5                   ;6613
        JR      NC,m661f                ;6616
        CALL    m5025                   ;6618
        LD      (m5981),DE              ;661b
m661f   LD      B,40H                   ;661f
        CALL    m4ea7                   ;6621
        LD      HL,m5992+2              ;6624
        LD      A,(HL)                  ;6627
        AND     0F9H                    ;6628
        JR      NZ,m6630                ;662a
        LD      A,(HL)                  ;662c
        OR      80H                     ;662d
        LD      (HL),A                  ;662f
m6630   CALL    m63b3                   ;6630
        LD      HL,m6df3                ;6633
        CALL    DSPLY                   ;6636
        CALL    m6710                   ;6639
        CALL    m4df3                   ;663c
        LD      HL,m552d                ;663f
        PUSH    HL                      ;6642
m6643   CALL    m67c3                   ;6643
        LD      A,(m5997)               ;6646
        BIT     3,A                     ;6649
        RET     NZ                      ;664b
        LD      A,(m5996)               ;664c
        BIT     7,A                     ;664f
        RET     NZ                      ;6651
        LD      DE,0000H                ;6652
        CALL    m5784                   ;6655
        LD      A,(m5992+2)             ;6658
        BIT     1,A                     ;665b
        RET     NZ                      ;665d
        LD      HL,m6dda                ;665e
        CALL    DSPLY                   ;6661
        CALL    m67aa                   ;6664
        LD      DE,m6eb5                ;6667
        LD      BC,0002H                ;666a
        CALL    Z,m67b4                 ;666d
        JP      NZ,m521a                ;6670
        LD      A,0FFH                  ;6673
        CALL    m64b0                   ;6675
        LD      DE,(m59d1)              ;6678
        LD      HL,SECBUF               ;667c
        LD      (m5b1a),HL              ;667f
        LD      C,L                     ;6682
        PUSH    HL                      ;6683
        CALL    m5762                   ;6684
        POP     HL                      ;6687
        SET     0,(HL)                  ;6688
        LD      A,(m59cd)               ;668a
        LD      (m59c5),A               ;668d
        LD      HL,(DPPTR)              ;6690
        LD      (HL),A                  ;6693
        LD      B,00H                   ;6694
        LD      E,A                     ;6696
        LD      A,(m59ce)               ;6697
        LD      C,A                     ;669a
        PUSH    DE                      ;669b
        LD      HL,SECBUF               ;669c
        CALL    m621c                   ;669f
        LD      HL,m597e                ;66a2
        LD      DE,m42cb                ;66a5
        LD      BC,0016H                ;66a8
        LDIR                            ;66ab
        POP     HL                      ;66ad
        LD      A,(m59ca)               ;66ae
        LD      H,A                     ;66b1
        RLCA                            ;66b2
        RLCA                            ;66b3
        ADD     A,H                     ;66b4
        CALL    MULHL                   ;66b5
        LD      (m5b21),HL              ;66b8
        LD      C,00H                   ;66bb
        JR      m66fb                   ;66bd
m66bf   PUSH    BC                      ;66bf
        XOR     A                       ;66c0
        CALL    m64b0                   ;66c1
        LD      A,C                     ;66c4
        DEC     A                       ;66c5
        JR      NZ,m66e6                ;66c6
        LD      HL,SECBUF               ;66c8
        LD      (HL),0A1H               ;66cb
        INC     HL                      ;66cd
        LD      (HL),0CEH               ;66ce
        LD      A,(m59ce)               ;66d0
        SUB     02H                     ;66d3
        LD      C,A                     ;66d5
        RLCA                            ;66d6
        RLCA                            ;66d7
        ADD     A,C                     ;66d8
        LD      (DIRLEN),A              ;66d9
        ADD     A,0AH                   ;66dc
        LD      (m65ee),A               ;66de
        LD      (670CH),A               ;66e1
        JR      m66fa                   ;66e4
m66e6   LD      HL,m65ba                ;66e6
        CP      02H                     ;66e9
        JR      C,m66f2                 ;66eb
        JR      NZ,m66fa                ;66ed
        LD      HL,m65da                ;66ef
m66f2   LD      DE,SECBUF               ;66f2
        LD      BC,0020H                ;66f5
        LDIR                            ;66f8
m66fa   POP     BC                      ;66fa
m66fb   SET     0,(IX+00H)              ;66fb
        CALL    m57d4                   ;66ff
        RES     0,(IX+00H)              ;6702
        JP      NZ,m521a                ;6706
        INC     C                       ;6709
        LD      A,C                     ;670a
        CP      0AH                     ;670b
        JR      C,m66bf                 ;670d
        RET                             ;670f
m6710   LD      HL,m5956                ;6710
m6713   PUSH    IX                      ;6713
        CALL    m6e76                   ;6715
        LD      A,(IX+04H)              ;6718
        LD      L,(IX+03H)              ;671b
        CALL    MULHL                   ;671e
        LD      (IX+0AH),L              ;6721
        LD      (IX+0BH),H              ;6724
        CALL    m5cf2                   ;6727
        LD      (IX+0CH),L              ;672a
        LD      (IX+0DH),H              ;672d
        LD      A,(IX+05H)              ;6730
        CALL    m4cb4                   ;6733
        OR      A                       ;6736
        JR      Z,m673a                 ;6737
        INC     HL                      ;6739
m673a   LD      A,H                     ;673a
        OR      A                       ;673b
        JR      NZ,m6747                ;673c
        LD      A,L                     ;673e
        CP      0C1H                    ;673f
        LD      (IX+01H),A              ;6741
        POP     IX                      ;6744
        RET     C                       ;6746
m6747   LD      HL,m6e57                ;6747
        JP      m5243                   ;674a
m674d   CALL    m61ea                   ;674d
        RET     Z                       ;6750
m6751   LD      A,(m5992+2)             ;6751
        BIT     1,A                     ;6754
        JR      Z,m6747                 ;6756
        RET                             ;6758
m6759   LD      A,(m59cb)               ;6759
        LD      (m65b7),A               ;675c
        LD      (64CAH),A               ;675f
        LD      A,(m59cc)               ;6762
        LD      (m65b9),A               ;6765
        BIT     1,A                     ;6768
        JR      Z,m6770                 ;676a
        LD      HL,64CDH                ;676c
        INC     (HL)                    ;676f
m6770   BIT     4,A                     ;6770
        JR      Z,m677d                 ;6772
        LD      HL,64CCH                ;6774
        INC     (HL)                    ;6777
        LD      HL,656FH                ;6778
        LD      (HL),01H                ;677b
m677d   BIT     0,A                     ;677d
        JR      Z,m6786                 ;677f
        LD      HL,64C2H                ;6781
        SET     0,(HL)                  ;6784
m6786   BIT     6,A                     ;6786
        LD      A,(m59c9)               ;6788
        LD      (656AH),A               ;678b
        JR      Z,m6791                 ;678e
        RRCA                            ;6790
m6791   LD      (651BH),A               ;6791
        LD      A,(m59cd)               ;6794
        LD      (64BCH),A               ;6797
        LD      L,A                     ;679a
        LD      A,(m59ce)               ;679b
        LD      H,A                     ;679e
        DEC     H                       ;679f
        LD      (m65f0),HL              ;67a0
        LD      A,(m59c7)               ;67a3
        LD      (m65b8),A               ;67a6
        RET                             ;67a9
m67aa   LD      BC,0000H                ;67aa
        CALL    m67b1                   ;67ad
        INC     BC                      ;67b0
m67b1   LD      DE,m64ba                ;67b1
m67b4   LD      (m5b1a),DE              ;67b4
        LD      IX,m5b17                ;67b8
        LD      (m5b21),BC              ;67bc
        JP      m57d4                   ;67c0
m67c3   CALL    m6759                   ;67c3
        LD      IX,m5b17                ;67c6
m67ca   CALL    m557d                   ;67ca
        LD      A,(m5992+2)             ;67cd
        LD      C,A                     ;67d0
        BIT     6,C                     ;67d1
        JP      NZ,m6886                ;67d3
        CALL    m57c8                   ;67d6
        JR      Z,m67ee                 ;67d9
        CP      05H                     ;67db
        JP      NZ,m521a                ;67dd
        BIT     7,C                     ;67e0
        JP      NZ,m6886                ;67e2
        LD      HL,m6d95                ;67e5
        CALL    DSPLY                   ;67e8
        JP      m6880                   ;67eb
m67ee   XOR     A                       ;67ee
        CALL    DIRSEC                  ;67ef
        JR      Z,m6806                 ;67f2
        LD      L,A                     ;67f4
        LD      A,C                     ;67f5
        AND     19H                     ;67f6
        LD      A,L                     ;67f8
        JP      NZ,m521a                ;67f9
        LD      HL,m42d0                ;67fc
        LD      B,10H                   ;67ff
m6801   LD      (HL),3FH                ;6801
        INC     HL                      ;6803
        DJNZ    m6801                   ;6804
m6806   BIT     7,C                     ;6806
        JR      Z,m6812                 ;6808
        LD      HL,m6d82                ;680a
        CALL    DSPLY                   ;680d
        JR      m687a                   ;6810
m6812   LD      A,(DFLAG3)              ;6812
        AND     82H                     ;6815
        CP      80H                     ;6817
        JR      NZ,m6840                ;6819
        LD      A,(m5996)               ;681b
        BIT     3,A                     ;681e
        JR      Z,m6840                 ;6820
        LD      A,(m5995)               ;6822
        BIT     0,A                     ;6825
        JR      Z,m6835                 ;6827
        LD      HL,(m42ce)              ;6829
        LD      DE,(m597a)              ;682c
        OR      A                       ;6830
        SBC     HL,DE                   ;6831
        JR      Z,m6840                 ;6833
m6835   LD      HL,m5a44                ;6835
        CALL    DSPLY                   ;6838
        LD      A,37H                   ;683b
        JP      m521a                   ;683d
m6840   BIT     3,C                     ;6840
        JR      Z,m6851                 ;6842
        PUSH    BC                      ;6844
        LD      HL,m42d0                ;6845
        LD      DE,m5983                ;6848
        LD      BC,0008H                ;684b
        LDIR                            ;684e
        POP     BC                      ;6850
m6851   BIT     0,C                     ;6851
        JR      Z,m6862                 ;6853
        PUSH    BC                      ;6855
        LD      HL,m42d8                ;6856
        LD      DE,m598b                ;6859
        LD      BC,0008H                ;685c
        LDIR                            ;685f
        POP     BC                      ;6861
m6862   BIT     4,C                     ;6862
        JR      Z,m6876                 ;6864
        LD      HL,m5970                ;6866
        CALL    624FH                   ;6869
        JR      Z,m6876                 ;686c
        LD      HL,m5a44                ;686e
        CALL    m692f                   ;6871
        JR      m687a                   ;6874
m6876   BIT     5,C                     ;6876
        JR      Z,m6886                 ;6878
m687a   LD      HL,m5a44                ;687a
        CALL    m693b                   ;687d
m6880   CALL    m58c8                   ;6880
        JP      NZ,m67ca                ;6883
m6886   LD      A,(m5997)               ;6886
        BIT     3,A                     ;6889
        RET     NZ                      ;688b
        LD      A,(m59c7)               ;688c
        BIT     5,A                     ;688f
        CALL    NZ,m6751                ;6891
        LD      HL,m6d61                ;6894
        CALL    DSPLY                   ;6897
        CALL    DRVSLX                  ;689a
        CALL    Z,m4745                 ;689d
        JP      NZ,m521a                ;68a0
        LD      A,(m5997)               ;68a3
        AND     02H                     ;68a6
        JR      Z,m68d0                 ;68a8
        LD      DE,0001H                ;68aa
        LD      A,D                     ;68ad
        ADD     A,E                     ;68ae
m68af   LD      C,A                     ;68af
        JR      C,m68b6                 ;68b0
        LD      A,(m59c8)               ;68b2
        CP      C                       ;68b5
m68b6   JP      C,m5218                 ;68b6
        BIT     1,(IY-6FH)              ;68b9
        JR      Z,m68c0                 ;68bd
        INC     D                       ;68bf
m68c0   LD      A,D                     ;68c0
        LD      (6AF4H),A               ;68c1
        LD      (m37ef),A               ;68c4
        LD      C,18H                   ;68c7
        CALL    m4747                   ;68c9
        LD      A,D                     ;68cc
        ADD     A,E                     ;68cd
        JR      m6922                   ;68ce
m68d0   LD      A,(m59c8)               ;68d0
        LD      HL,m5996                ;68d3
        BIT     7,(HL)                  ;68d6
        JR      NZ,m6922                ;68d8
        BIT     6,(IY-74H)              ;68da
        JR      Z,m6922                 ;68de
        PUSH    IX                      ;68e0
        LD      IX,(DPPTR)              ;68e2
        LD      A,01H                   ;68e6
        LD      E,(IY-6FH)              ;68e8
        XOR     E                       ;68eb
        AND     0C1H                    ;68ec
        LD      (IX+07H),A              ;68ee
        LD      D,(IX+04H)              ;68f1
        LD      (IX+04H),0AH            ;68f4
        EX      (SP),IX                 ;68f8
        PUSH    DE                      ;68fa
        LD      A,01H                   ;68fb
        CALL    m6959                   ;68fd
        JR      NZ,m6905                ;6900
        CALL    m67aa                   ;6902
m6905   POP     DE                      ;6905
        EX      (SP),IX                 ;6906
        PUSH    AF                      ;6908
        LD      (IX+07H),E              ;6909
        LD      (IX+04H),D              ;690c
        CALL    m4773                   ;690f
        EX      AF,AF'                  ;6912
        POP     AF                      ;6913
        POP     IX                      ;6914
        JR      NZ,m6925                ;6916
        EX      AF,AF'                  ;6918
        JR      NZ,m6925                ;6919
        CALL    m6caf                   ;691b
        LD      A,(m59c8)               ;691e
        INC     A                       ;6921
m6922   CALL    m6959                   ;6922
m6925   EI                              ;6925
        RET     Z                       ;6926
        CP      0FFH                    ;6927
        JP      NZ,m521a                ;6929
        JP      m5243                   ;692c
m692f   PUSH    HL                      ;692f
        CALL    DSPLY                   ;6930
        LD      HL,m6dc1                ;6933
        CALL    DSPLY                   ;6936
        POP     HL                      ;6939
        RET                             ;693a
m693b   CALL    DSPLY                   ;693b
        LD      HL,m6da8                ;693e
        CALL    DSPLY                   ;6941
        LD      HL,m42d0                ;6944
        LD      B,08H                   ;6947
        CALL    m5886                   ;6949
        LD      B,04H                   ;694c
        CALL    m5898                   ;694e
        LD      B,08H                   ;6951
        CALL    m5886                   ;6953
        JP      m5881                   ;6956
m6959   LD      (6C75H),A               ;6959
        CALL    m4773                   ;695c
        RET     NZ                      ;695f
        LD      A,(m4311)               ;6960
        RLCA                            ;6963
        AND     03H                     ;6964
        LD      L,1AH                   ;6966
        CALL    MULHL                   ;6968
        LD      DE,m6cc2                ;696b
        ADD     HL,DE                   ;696e
        LD      A,(HL)                  ;696f
        LD      (6B1CH),A               ;6970
        INC     HL                      ;6973
        LD      (m6b82+1),A             ;6974
        LD      A,(HL)                  ;6977
        LD      (6AD8H),A               ;6978
        INC     HL                      ;697b
        LD      (6B4DH),A               ;697c
        LD      A,(HL)                  ;697f
        LD      (6B6FH),A               ;6980
        INC     HL                      ;6983
        LD      A,(HL)                  ;6984
        LD      (6B76H),A               ;6985
        INC     HL                      ;6988
        LD      A,(HL)                  ;6989
        LD      (6B8BH),A               ;698a
        INC     HL                      ;698d
        LD      A,(HL)                  ;698e
        LD      (6AC8H),A               ;698f
        INC     HL                      ;6992
        LD      A,(HL)                  ;6993
        LD      (6B26H),A               ;6994
        INC     HL                      ;6997
        LD      A,(HL)                  ;6998
        LD      (6B3DH),A               ;6999
        INC     HL                      ;699c
        LD      E,(HL)                  ;699d
        INC     HL                      ;699e
        LD      D,(HL)                  ;699f
        INC     HL                      ;69a0
        LD      C,(HL)                  ;69a1
        INC     HL                      ;69a2
        LD      B,(HL)                  ;69a3
        LD      (69DAH),BC              ;69a4
        INC     HL                      ;69a8
        LD      C,(HL)                  ;69a9
        INC     HL                      ;69aa
        LD      B,(HL)                  ;69ab
        LD      (m69f1+1),BC            ;69ac
        INC     HL                      ;69b0
        LD      C,(HL)                  ;69b1
        INC     HL                      ;69b2
        LD      B,(HL)                  ;69b3
        LD      (69D6H),BC              ;69b4
        INC     HL                      ;69b8
        LD      A,(HL)                  ;69b9
        LD      (m69ff+1),A             ;69ba
        INC     HL                      ;69bd
        LD      A,(HL)                  ;69be
        LD      (6A33H),A               ;69bf
        INC     HL                      ;69c2
        NOP                             ;69c3
        NOP                             ;69c4
        NOP                             ;69c5
        XOR     A                       ;69c6
        LD      (m6a01+1),A             ;69c7
        LD      (6C63H),A               ;69ca
        EX      DE,HL                   ;69cd
        CALL    m6ca4                   ;69ce
        LD      A,E                     ;69d1
        CALL    MULOV                   ;69d2
        LD      BC,0000H                ;69d5
        EX      DE,HL                   ;69d8
        LD      HL,0000H                ;69d9
        OR      A                       ;69dc
        SBC     HL,DE                   ;69dd
        PUSH    HL                      ;69df
        JR      NC,m69f1                ;69e0
        ADD     HL,HL                   ;69e2
        ADD     HL,HL                   ;69e3
        ADD     HL,BC                   ;69e4
        JR      C,m69ee                 ;69e5
        POP     HL                      ;69e7
        LD      HL,m6d6c                ;69e8
        OR      0FFH                    ;69eb
        RET                             ;69ed
m69ee   LD      HL,0000H                ;69ee
m69f1   LD      DE,0000H                ;69f1
        ADD     HL,DE                   ;69f4
        LD      (6BCDH),HL              ;69f5
        POP     HL                      ;69f8
        ADD     HL,DE                   ;69f9
        ADD     HL,BC                   ;69fa
        ADD     HL,BC                   ;69fb
        LD      (6BD6H),HL              ;69fc
m69ff   LD      A,02H                   ;69ff
m6a01   ADD     A,00H                   ;6a01
        CALL    m6ca4                   ;6a03
        CP      E                       ;6a06
        JR      C,m6a0a                 ;6a07
        SUB     E                       ;6a09
m6a0a   LD      (m6a01+1),A             ;6a0a
        LD      (m6a01+1),A             ;6a0d
        INC     A                       ;6a10
        LD      D,A                     ;6a11
        PUSH    DE                      ;6a12
        LD      HL,m6485                ;6a13
        LD      B,E                     ;6a16
m6a17   LD      (HL),0FFH               ;6a17
        INC     HL                      ;6a19
        DJNZ    m6a17                   ;6a1a
        LD      D,00H                   ;6a1c
        LD      B,D                     ;6a1e
        JR      m6a26                   ;6a1f
m6a21   INC     C                       ;6a21
        LD      A,C                     ;6a22
        CP      E                       ;6a23
        JR      C,m6a28                 ;6a24
m6a26   LD      C,00H                   ;6a26
m6a28   LD      HL,m6485                ;6a28
        ADD     HL,BC                   ;6a2b
        LD      A,(HL)                  ;6a2c
        INC     A                       ;6a2d
        JR      NZ,m6a21                ;6a2e
        LD      (HL),D                  ;6a30
        LD      A,C                     ;6a31
        ADD     A,02H                   ;6a32
        CP      E                       ;6a34
        JR      C,m6a38                 ;6a35
        SUB     E                       ;6a37
m6a38   LD      C,A                     ;6a38
        INC     D                       ;6a39
        LD      A,D                     ;6a3a
        CP      E                       ;6a3b
        JR      C,m6a28                 ;6a3c
        LD      HL,m6a01+1              ;6a3e
        LD      A,(HL)                  ;6a41
        ADD     A,C                     ;6a42
        LD      (HL),A                  ;6a43
m6a44   POP     DE                      ;6a44
        DEC     D                       ;6a45
        JR      Z,m6a58                 ;6a46
        LD      C,E                     ;6a48
        PUSH    DE                      ;6a49
        LD      HL,m6482+2              ;6a4a
        ADD     HL,BC                   ;6a4d
        LD      D,H                     ;6a4e
        LD      E,L                     ;6a4f
        DEC     BC                      ;6a50
        LD      A,(HL)                  ;6a51
        DEC     HL                      ;6a52
        LDDR                            ;6a53
        LD      (DE),A                  ;6a55
        JR      m6a44                   ;6a56
m6a58   LD      A,(m4311)               ;6a58
        BIT     4,A                     ;6a5b
        JR      Z,m6a67                 ;6a5d
        LD      B,E                     ;6a5f
        LD      HL,m6485                ;6a60
m6a63   INC     (HL)                    ;6a63
        INC     HL                      ;6a64
        DJNZ    m6a63                   ;6a65
m6a67   LD      A,0AH                   ;6a67
        LD      (m6c94+1),A             ;6a69
m6a6c   CALL    m4773                   ;6a6c
        RET     NZ                      ;6a6f
        CALL    m5733                   ;6a70
        LD      HL,DMASK                ;6a73
        LD      B,(IY-6FH)              ;6a76
        LD      A,B                     ;6a79
        AND     40H                     ;6a7a
        JR      Z,m6a87                 ;6a7c
        LD      A,(6C63H)               ;6a7e
        AND     01H                     ;6a81
        CALL    m4cf8                   ;6a83
        NOP                             ;6a86
m6a87   LD      (6AFCH),A               ;6a87
        CALL    m4767                   ;6a8a
        CALL    m4750                   ;6a8d
        LD      DE,m37ef                ;6a90
        LD      HL,m37ec                ;6a93
        LD      BC,m6485                ;6a96
        PUSH    HL                      ;6a99
        PUSH    DE                      ;6a9a
        EXX                             ;6a9b
        CALL    m6ca4                   ;6a9c
        LD      C,E                     ;6a9f
        POP     DE                      ;6aa0
        POP     HL                      ;6aa1
        DI                              ;6aa2
        CALL    m47e3                   ;6aa3
        LD      (HL),0F4H               ;6aa6
        CALL    m47e3                   ;6aa8
        LD      A,01H                   ;6aab
        EX      AF,AF'                  ;6aad
        INC     C                       ;6aae
        JP      m6b82                   ;6aaf
m6ab2   EX      AF,AF'                  ;6ab2
m6ab3   CP      (HL)                    ;6ab3
        JR      Z,m6ab3                 ;6ab4
        EX      AF,AF'                  ;6ab6
        LD      (DE),A                  ;6ab7
m6ab8   EX      AF,AF'                  ;6ab8
m6ab9   CP      (HL)                    ;6ab9
        JR      Z,m6ab9                 ;6aba
        EX      AF,AF'                  ;6abc
        LD      (DE),A                  ;6abd
        DJNZ    m6ab8                   ;6abe
        XOR     A                       ;6ac0
        EX      AF,AF'                  ;6ac1
m6ac2   CP      (HL)                    ;6ac2
        JR      Z,m6ac2                 ;6ac3
        EX      AF,AF'                  ;6ac5
        LD      (DE),A                  ;6ac6
        LD      B,01H                   ;6ac7
m6ac9   EX      AF,AF'                  ;6ac9
m6aca   CP      (HL)                    ;6aca
        JR      Z,m6aca                 ;6acb
        EX      AF,AF'                  ;6acd
        LD      (DE),A                  ;6ace
        DJNZ    m6ac9                   ;6acf
        EX      AF,AF'                  ;6ad1
m6ad2   CP      (HL)                    ;6ad2
        JR      Z,m6ad2                 ;6ad3
        EX      AF,AF'                  ;6ad5
        LD      (DE),A                  ;6ad6
        LD      A,00H                   ;6ad7
        EX      AF,AF'                  ;6ad9
m6ada   CP      (HL)                    ;6ada
        JR      Z,m6ada                 ;6adb
        EX      AF,AF'                  ;6add
        LD      (DE),A                  ;6ade
        EX      AF,AF'                  ;6adf
m6ae0   CP      (HL)                    ;6ae0
        JR      Z,m6ae0                 ;6ae1
        EX      AF,AF'                  ;6ae3
        LD      (DE),A                  ;6ae4
        EX      AF,AF'                  ;6ae5
m6ae6   CP      (HL)                    ;6ae6
        JR      Z,m6ae6                 ;6ae7
        EX      AF,AF'                  ;6ae9
        LD      (DE),A                  ;6aea
        LD      A,0FEH                  ;6aeb
        EX      AF,AF'                  ;6aed
m6aee   CP      (HL)                    ;6aee
        JR      Z,m6aee                 ;6aef
        EX      AF,AF'                  ;6af1
        LD      (DE),A                  ;6af2
        LD      A,00H                   ;6af3
        EX      AF,AF'                  ;6af5
m6af6   CP      (HL)                    ;6af6
        JR      Z,m6af6                 ;6af7
        EX      AF,AF'                  ;6af9
        LD      (DE),A                  ;6afa
        LD      A,00H                   ;6afb
        EX      AF,AF'                  ;6afd
m6afe   CP      (HL)                    ;6afe
        JR      Z,m6afe                 ;6aff
        EX      AF,AF'                  ;6b01
        LD      (DE),A                  ;6b02
        EXX                             ;6b03
        LD      A,(BC)                  ;6b04
        EX      AF,AF'                  ;6b05
m6b06   CP      (HL)                    ;6b06
        JR      Z,m6b06                 ;6b07
        EX      AF,AF'                  ;6b09
        LD      (DE),A                  ;6b0a
        LD      A,01H                   ;6b0b
        EX      AF,AF'                  ;6b0d
m6b0e   CP      (HL)                    ;6b0e
        JR      Z,m6b0e                 ;6b0f
        EX      AF,AF'                  ;6b11
        LD      (DE),A                  ;6b12
        LD      A,0F7H                  ;6b13
        EX      AF,AF'                  ;6b15
m6b16   CP      (HL)                    ;6b16
        JR      Z,m6b16                 ;6b17
        EX      AF,AF'                  ;6b19
        LD      (DE),A                  ;6b1a
        LD      A,0FFH                  ;6b1b
        EX      AF,AF'                  ;6b1d
m6b1e   CP      (HL)                    ;6b1e
        JR      Z,m6b1e                 ;6b1f
        EX      AF,AF'                  ;6b21
        LD      (DE),A                  ;6b22
        INC     BC                      ;6b23
        EXX                             ;6b24
        LD      B,0AH                   ;6b25
        EX      AF,AF'                  ;6b27
m6b28   CP      (HL)                    ;6b28
        JR      Z,m6b28                 ;6b29
        EX      AF,AF'                  ;6b2b
        LD      (DE),A                  ;6b2c
m6b2d   EX      AF,AF'                  ;6b2d
m6b2e   CP      (HL)                    ;6b2e
        JR      Z,m6b2e                 ;6b2f
        EX      AF,AF'                  ;6b31
        LD      (DE),A                  ;6b32
        DJNZ    m6b2d                   ;6b33
        XOR     A                       ;6b35
        EX      AF,AF'                  ;6b36
m6b37   CP      (HL)                    ;6b37
        JR      Z,m6b37                 ;6b38
        EX      AF,AF'                  ;6b3a
        LD      (DE),A                  ;6b3b
        LD      B,04H                   ;6b3c
m6b3e   EX      AF,AF'                  ;6b3e
m6b3f   CP      (HL)                    ;6b3f
        JR      Z,m6b3f                 ;6b40
        EX      AF,AF'                  ;6b42
        LD      (DE),A                  ;6b43
        DJNZ    m6b3e                   ;6b44
        EX      AF,AF'                  ;6b46
m6b47   CP      (HL)                    ;6b47
        JR      Z,m6b47                 ;6b48
        EX      AF,AF'                  ;6b4a
        LD      (DE),A                  ;6b4b
        LD      A,00H                   ;6b4c
        EX      AF,AF'                  ;6b4e
m6b4f   CP      (HL)                    ;6b4f
        JR      Z,m6b4f                 ;6b50
        EX      AF,AF'                  ;6b52
        LD      (DE),A                  ;6b53
        EX      AF,AF'                  ;6b54
m6b55   CP      (HL)                    ;6b55
        JR      Z,m6b55                 ;6b56
        EX      AF,AF'                  ;6b58
        LD      (DE),A                  ;6b59
        EX      AF,AF'                  ;6b5a
m6b5b   CP      (HL)                    ;6b5b
        JR      Z,m6b5b                 ;6b5c
        EX      AF,AF'                  ;6b5e
        LD      (DE),A                  ;6b5f
        LD      B,80H                   ;6b60
        EX      AF,AF'                  ;6b62
m6b63   CP      (HL)                    ;6b63
        JR      Z,m6b63                 ;6b64
        EX      DE,HL                   ;6b66
        LD      (HL),0FBH               ;6b67
        EX      DE,HL                   ;6b69
m6b6a   CP      (HL)                    ;6b6a
        JR      Z,m6b6a                 ;6b6b
        EX      DE,HL                   ;6b6d
        LD      (HL),0E5H               ;6b6e
        EX      DE,HL                   ;6b70
m6b71   CP      (HL)                    ;6b71
        JR      Z,m6b71                 ;6b72
        EX      DE,HL                   ;6b74
        LD      (HL),0E5H               ;6b75
        EX      DE,HL                   ;6b77
        DJNZ    m6b6a                   ;6b78
m6b7a   CP      (HL)                    ;6b7a
        JR      Z,m6b7a                 ;6b7b
        EX      DE,HL                   ;6b7d
        LD      (HL),0F7H               ;6b7e
        EX      DE,HL                   ;6b80
        EX      AF,AF'                  ;6b81
m6b82   LD      A,0FFH                  ;6b82
        EX      AF,AF'                  ;6b84
m6b85   CP      (HL)                    ;6b85
        JR      Z,m6b85                 ;6b86
        EX      AF,AF'                  ;6b88
        LD      (DE),A                  ;6b89
        LD      B,0AH                   ;6b8a
        DEC     C                       ;6b8c
        JP      NZ,m6ab2                ;6b8d
        LD      BC,0001H                ;6b90
        EX      AF,AF'                  ;6b93
m6b94   CP      (HL)                    ;6b94
        JR      Z,m6b94                 ;6b95
        EX      AF,AF'                  ;6b97
m6b98   LD      (DE),A                  ;6b98
        INC     BC                      ;6b99
        NOP                             ;6b9a
m6b9b   BIT     1,(HL)                  ;6b9b
        JP      NZ,m6b98                ;6b9d
        BIT     1,(HL)                  ;6ba0
        JP      NZ,m6b98                ;6ba2
        BIT     1,(HL)                  ;6ba5
        JR      NZ,m6b98                ;6ba7
        BIT     0,(HL)                  ;6ba9
        JR      Z,m6bb5                 ;6bab
        BIT     1,(HL)                  ;6bad
        JR      NZ,m6b98                ;6baf
        BIT     7,(HL)                  ;6bb1
        JR      Z,m6b9b                 ;6bb3
m6bb5   LD      A,(HL)                  ;6bb5
        LD      (HL),0D0H               ;6bb6
        LD      H,B                     ;6bb8
        LD      L,C                     ;6bb9
        LD      B,A                     ;6bba
        CALL    m4767                   ;6bbb
        LD      A,(m5996)               ;6bbe
        BIT     7,A                     ;6bc1
        JP      NZ,m6c5c                ;6bc3
        LD      A,B                     ;6bc6
        AND     0FCH                    ;6bc7
        JP      NZ,m6c89                ;6bc9
        LD      BC,0000H                ;6bcc
        OR      A                       ;6bcf
        SBC     HL,BC                   ;6bd0
        JP      C,m6c7d                 ;6bd2
        LD      BC,007DH                ;6bd5
        OR      A                       ;6bd8
        SBC     HL,BC                   ;6bd9
        JP      NC,m6c82                ;6bdb
        LD      A,88H                   ;6bde
        LD      (DCMD),A                ;6be0
        LD      HL,(m4649)              ;6be3
        LD      (m46fc),HL              ;6be6
        LD      HL,m6485                ;6be9
        CALL    m6ca4                   ;6bec
m6bef   INC     HL                      ;6bef
        LD      A,(HL)                  ;6bf0
m6bf1   LD      (m37ee),A               ;6bf1
        LD      A,(m37ed)               ;6bf4
        PUSH    HL                      ;6bf7
        LD      HL,m471a                ;6bf8
        LD      D,(HL)                  ;6bfb
        PUSH    DE                      ;6bfc
        PUSH    HL                      ;6bfd
        LD      (HL),0C9H               ;6bfe
        PUSH    AF                      ;6c00
        LD      A,(6AF4H)               ;6c01
        LD      (m37ed),A               ;6c04
        LD      BC,m3b00                ;6c07
        CALL    m46bd                   ;6c0a
m6c0d   LD      B,A                     ;6c0d
        POP     AF                      ;6c0e
        LD      (m37ed),A               ;6c0f
        POP     HL                      ;6c12
        POP     DE                      ;6c13
        LD      (HL),D                  ;6c14
        POP     HL                      ;6c15
        LD      A,B                     ;6c16
        AND     9CH                     ;6c17
        JR      Z,m6c51                 ;6c19
        LD      HL,m6c94+1              ;6c1b
        DEC     (HL)                    ;6c1e
        JP      NZ,m6a6c                ;6c1f
m6c22   EI                              ;6c22
        LD      HL,m6eab                ;6c23
        LD      A,(6C63H)               ;6c26
        OR      A                       ;6c29
        JR      Z,m6c2f                 ;6c2a
        LD      HL,m6eb0                ;6c2c
m6c2f   LD      DE,6E96H                ;6c2f
        LD      BC,0005H                ;6c32
        LDIR                            ;6c35
        LD      HL,m6e89                ;6c37
        CALL    DSPLY                   ;6c3a
        LD      A,(6AF4H)               ;6c3d
        LD      E,A                     ;6c40
        LD      D,00H                   ;6c41
        CALL    m5909                   ;6c43
        CALL    m5881                   ;6c46
        CALL    m58c8                   ;6c49
        JP      NZ,m6a67                ;6c4c
        JR      m6c5c                   ;6c4f
m6c51   DEC     E                       ;6c51
        LD      A,01H                   ;6c52
        CP      E                       ;6c54
        JR      C,m6bef                 ;6c55
        LD      A,(m6485)               ;6c57
        JR      Z,m6bf1                 ;6c5a
m6c5c   BIT     6,(IY-6FH)              ;6c5c
        JR      Z,m6c6f                 ;6c60
        LD      A,00H                   ;6c62
        XOR     01H                     ;6c64
        LD      (6C63H),A               ;6c66
        JR      Z,m6c6f                 ;6c69
        XOR     A                       ;6c6b
        JP      m6a01                   ;6c6c
m6c6f   LD      HL,6AF4H                ;6c6f
        INC     (HL)                    ;6c72
        LD      A,(HL)                  ;6c73
        CP      23H                     ;6c74
        RET     Z                       ;6c76
        CALL    m6caf                   ;6c77
        JP      m69ff                   ;6c7a
m6c7d   LD      HL,m6d6c                ;6c7d
        JR      m6c85                   ;6c80
m6c82   LD      HL,m6d77                ;6c82
m6c85   LD      B,0FFH                  ;6c85
        JR      m6c94                   ;6c87
m6c89   LD      B,11H                   ;6c89
m6c8b   DEC     B                       ;6c8b
        RLCA                            ;6c8c
        JR      NC,m6c8b                ;6c8d
        LD      A,B                     ;6c8f
        CP      0FH                     ;6c90
        JR      Z,m6ca2                 ;6c92
m6c94   LD      A,00H                   ;6c94
        DEC     A                       ;6c96
        LD      (m6c94+1),A             ;6c97
        JP      NZ,m6a6c                ;6c9a
        LD      A,B                     ;6c9d
        CP      0BH                     ;6c9e
        JR      Z,m6c22                 ;6ca0
m6ca2   OR      A                       ;6ca2
        RET                             ;6ca3
m6ca4   LD      E,(IY-72H)              ;6ca4
        BIT     6,(IY-6FH)              ;6ca7
        RET     Z                       ;6cab
        SRL     E                       ;6cac
        RET                             ;6cae
m6caf   LD      A,(m4311)               ;6caf
        BIT     2,A                     ;6cb2
        CALL    NZ,m6cb7                ;6cb4
m6cb7   LD      BC,0100H                ;6cb7
        CALL    m4ced                   ;6cba
        LD      C,58H                   ;6cbd
        JP      m4747                   ;6cbf
m6cc2   RST     38H                     ;6cc2
        NOP                             ;6cc3
        PUSH    HL                      ;6cc4
        PUSH    HL                      ;6cc5
        ADD     HL,BC                   ;6cc6
        LD      BC,0109H                ;6cc7
        INC     L                       ;6cca
        LD      BC,0BECH                ;6ccb
        DEC     BC                      ;6cce
        NOP                             ;6ccf
        LD      A,00H                   ;6cd0
        LD      (BC),A                  ;6cd2
        LD      (BC),A                  ;6cd3
        NOP                             ;6cd4
        NOP                             ;6cd5
        NOP                             ;6cd6
        NOP                             ;6cd7
        NOP                             ;6cd8
        NOP                             ;6cd9
        NOP                             ;6cda
        NOP                             ;6cdb
        RST     38H                     ;6cdc
        NOP                             ;6cdd
        PUSH    HL                      ;6cde
        PUSH    HL                      ;6cdf
        EX      AF,AF'                  ;6ce0
        LD      BC,0109H                ;6ce1
        DEC     HL                      ;6ce4
        LD      BC,13E6H                ;6ce5
        LD      A,(BC)                  ;6ce8
        NOP                             ;6ce9
        LD      L,B                     ;6cea
        NOP                             ;6ceb
        LD      (BC),A                  ;6cec
        LD      (BC),A                  ;6ced
        NOP                             ;6cee
        NOP                             ;6cef
        NOP                             ;6cf0
        NOP                             ;6cf1
        NOP                             ;6cf2
        NOP                             ;6cf3
        NOP                             ;6cf4
        NOP                             ;6cf5
        LD      C,(HL)                  ;6cf6
        PUSH    AF                      ;6cf7
        LD      L,L                     ;6cf8
        OR      (HL)                    ;6cf9
        LD      C,06H                   ;6cfa
        INC     D                       ;6cfc
        LD      A,(BC)                  ;6cfd
        LD      C,D                     ;6cfe
        LD      BC,17DDH                ;6cff
        DJNZ    m6d04                   ;6d02
m6d04   LD      A,L                     ;6d04
        NOP                             ;6d05
        LD      (BC),A                  ;6d06
        LD      (BC),A                  ;6d07
        NOP                             ;6d08
        NOP                             ;6d09
        NOP                             ;6d0a
        NOP                             ;6d0b
        NOP                             ;6d0c
        NOP                             ;6d0d
        NOP                             ;6d0e
        NOP                             ;6d0f
        LD      C,(HL)                  ;6d10
        PUSH    AF                      ;6d11
        LD      L,L                     ;6d12
        OR      (HL)                    ;6d13
        INC     DE                      ;6d14
        LD      A,(BC)                  ;6d15
        INC     D                       ;6d16
        LD      A,(BC)                  ;6d17
        LD      D,E                     ;6d18
        LD      BC,27BAH                ;6d19
        LD      H,00H                   ;6d1c
        RET     NC                      ;6d1e
        NOP                             ;6d1f
        LD      (BC),A                  ;6d20
        LD      (BC),A                  ;6d21
        NOP                             ;6d22
        NOP                             ;6d23
        NOP                             ;6d24
        NOP                             ;6d25
        NOP                             ;6d26
        NOP                             ;6d27
        NOP                             ;6d28
        NOP                             ;6d29
        NOP                             ;6d2a
        NOP                             ;6d2b
        NOP                             ;6d2c
        NOP                             ;6d2d
        NOP                             ;6d2e
        NOP                             ;6d2f
        NOP                             ;6d30
        NOP                             ;6d31
        NOP                             ;6d32
        NOP                             ;6d33
        NOP                             ;6d34
        NOP                             ;6d35
        NOP                             ;6d36
        NOP                             ;6d37
        NOP                             ;6d38
        NOP                             ;6d39
        NOP                             ;6d3a
        NOP                             ;6d3b
        NOP                             ;6d3c
        NOP                             ;6d3d
        NOP                             ;6d3e
        NOP                             ;6d3f
        NOP                             ;6d40
        NOP                             ;6d41
        NOP                             ;6d42
        NOP                             ;6d43
        NOP                             ;6d44
        NOP                             ;6d45
        NOP                             ;6d46
        NOP                             ;6d47
        NOP                             ;6d48
        NOP                             ;6d49
        NOP                             ;6d4a
        NOP                             ;6d4b
        NOP                             ;6d4c
        NOP                             ;6d4d
        NOP                             ;6d4e
        NOP                             ;6d4f
        NOP                             ;6d50
        NOP                             ;6d51
        NOP                             ;6d52
        NOP                             ;6d53
        NOP                             ;6d54
        NOP                             ;6d55
        NOP                             ;6d56
        NOP                             ;6d57
        NOP                             ;6d58
        NOP                             ;6d59
        NOP                             ;6d5a
        NOP                             ;6d5b
        NOP                             ;6d5c
        NOP                             ;6d5d
m6d5e   INC     E                       ;6d5e
        RRA                             ;6d5f
        INC     BC                      ;6d60
m6d61   LD      B,(HL)                  ;6d61
        LD      L,A                     ;6d62
        LD      (HL),D                  ;6d63
        LD      L,L                     ;6d64
        LD      H,C                     ;6d65
        LD      (HL),H                  ;6d66
        LD      L,C                     ;6d67
        LD      H,L                     ;6d68
        LD      (HL),D                  ;6d69
        LD      H,L                     ;6d6a
        DEC     C                       ;6d6b
m6d6c   LD      A,D                     ;6d6c
        LD      (HL),L                  ;6d6d
        JR      NZ,$+117                ;6d6e
        LD      H,E                     ;6d70
        LD      L,B                     ;6d71
        LD      L,(HL)                  ;6d72
        LD      H,L                     ;6d73
        LD      L,H                     ;6d74
        LD      L,H                     ;6d75
        DEC     C                       ;6d76
m6d77   LD      A,D                     ;6d77
        LD      (HL),L                  ;6d78
        JR      NZ,$+110                ;6d79
        LD      H,C                     ;6d7b
        LD      L,(HL)                  ;6d7c
        LD      H,A                     ;6d7d
        LD      (HL),E                  ;6d7e
        LD      H,C                     ;6d7f
        LD      L,L                     ;6d80
        DEC     C                       ;6d81
m6d82   LD      B,H                     ;6d82
        LD      L,C                     ;6d83
        LD      (HL),E                  ;6d84
        LD      L,E                     ;6d85
        LD      H,L                     ;6d86
        LD      (HL),H                  ;6d87
        LD      (HL),H                  ;6d88
        LD      H,L                     ;6d89
        JR      NZ,m6df4                ;6d8a
        LD      H,C                     ;6d8c
        LD      (HL),H                  ;6d8d
        JR      NZ,m6dd4                ;6d8e
        LD      H,C                     ;6d90
        LD      (HL),H                  ;6d91
        LD      H,L                     ;6d92
        LD      L,(HL)                  ;6d93
        DEC     C                       ;6d94
m6d95   LD      D,L                     ;6d95
        LD      L,(HL)                  ;6d96
        LD      L,H                     ;6d97
        LD      H,L                     ;6d98
        LD      (HL),E                  ;6d99
        LD      H,D                     ;6d9a
        LD      H,C                     ;6d9b
        LD      (HL),D                  ;6d9c
        LD      H,L                     ;6d9d
        JR      NZ,m6de4                ;6d9e
        LD      L,C                     ;6da0
        LD      (HL),E                  ;6da1
        LD      L,E                     ;6da2
        LD      H,L                     ;6da3
        LD      (HL),H                  ;6da4
        LD      (HL),H                  ;6da5
        LD      H,L                     ;6da6
        DEC     C                       ;6da7
m6da8   EX      AF,AF'                  ;6da8
        LD      H,H                     ;6da9
        LD      L,C                     ;6daa
        LD      (HL),E                  ;6dab
        LD      L,E                     ;6dac
        LD      H,L                     ;6dad
        LD      (HL),H                  ;6dae
        LD      (HL),H                  ;6daf
        LD      H,L                     ;6db0
        LD      L,(HL)                  ;6db1
        LD      L,(HL)                  ;6db2
        LD      H,C                     ;6db3
        LD      L,L                     ;6db4
        LD      H,L                     ;6db5
        INC     L                       ;6db6
        JR      NZ,m6de6                ;6db7
        LD      H,H                     ;6db9
        LD      H,C                     ;6dba
        LD      (HL),H                  ;6dbb
        LD      (HL),L                  ;6dbc
        LD      L,L                     ;6dbd
        LD      A,(0320H)               ;6dbe
m6dc1   EX      AF,AF'                  ;6dc1
        LD      H,H                     ;6dc2
        LD      L,C                     ;6dc3
        LD      (HL),E                  ;6dc4
        LD      L,E                     ;6dc5
        LD      H,L                     ;6dc6
        LD      (HL),H                  ;6dc7
        LD      (HL),H                  ;6dc8
        LD      H,L                     ;6dc9
        LD      L,(HL)                  ;6dca
        LD      L,(HL)                  ;6dcb
        LD      H,C                     ;6dcc
        LD      L,L                     ;6dcd
        LD      H,L                     ;6dce
        JR      NZ,m6e37                ;6dcf
        LD      H,C                     ;6dd1
        LD      L,H                     ;6dd2
        LD      (HL),E                  ;6dd3
m6dd4   LD      H,E                     ;6dd4
        LD      L,B                     ;6dd5
        JR      NZ,m6df8                ;6dd6
        LD      A,(BC)                  ;6dd8
        DEC     C                       ;6dd9
m6dda   LD      D,E                     ;6dda
        LD      H,E                     ;6ddb
        LD      L,B                     ;6ddc
        LD      (HL),D                  ;6ddd
        LD      H,L                     ;6dde
        LD      L,C                     ;6ddf
        LD      H,D                     ;6de0
        LD      H,L                     ;6de1
        JR      NZ,m6e52                ;6de2
m6de4   LD      (HL),L                  ;6de4
        LD      L,(HL)                  ;6de5
m6de6   JR      NZ,m6e3b                ;6de6
        LD      A,C                     ;6de8
        LD      (HL),E                  ;6de9
        LD      (HL),H                  ;6dea
        LD      H,L                     ;6deb
        LD      L,L                     ;6dec
        LD      H,H                     ;6ded
        LD      H,C                     ;6dee
        LD      (HL),H                  ;6def
        LD      H,L                     ;6df0
        LD      L,(HL)                  ;6df1
        DEC     C                       ;6df2
m6df3   LD      B,H                     ;6df3
m6df4   LD      L,C                     ;6df4
        LD      (HL),E                  ;6df5
        LD      L,E                     ;6df6
        LD      H,L                     ;6df7
m6df8   LD      (HL),H                  ;6df8
        LD      (HL),H                  ;6df9
        LD      H,L                     ;6dfa
        JR      NZ,m6e74                ;6dfb
        LD      L,C                     ;6dfd
        LD      (HL),D                  ;6dfe
        LD      H,H                     ;6dff
        JR      NZ,m6e68                ;6e00
        LD      L,A                     ;6e02
        LD      (HL),D                  ;6e03
        LD      L,L                     ;6e04
        LD      H,C                     ;6e05
        LD      (HL),H                  ;6e06
        LD      L,C                     ;6e07
        LD      H,L                     ;6e08
        LD      (HL),D                  ;6e09
        LD      (HL),H                  ;6e0a
        DEC     C                       ;6e0b
m6e0c   LD      B,H                     ;6e0c
        LD      L,C                     ;6e0d
        LD      (HL),E                  ;6e0e
        LD      L,E                     ;6e0f
        LD      H,L                     ;6e10
        LD      (HL),H                  ;6e11
        LD      (HL),H                  ;6e12
        LD      H,L                     ;6e13
        JR      NZ,m6e8d                ;6e14
        LD      L,C                     ;6e16
        LD      (HL),D                  ;6e17
        LD      H,H                     ;6e18
        JR      NZ,m6e86                ;6e19
        LD      L,A                     ;6e1b
        LD      (HL),B                  ;6e1c
        LD      L,C                     ;6e1d
        LD      H,L                     ;6e1e
        LD      (HL),D                  ;6e1f
        LD      (HL),H                  ;6e20
        DEC     C                       ;6e21
m6e22   LD      D,E                     ;6e22
        LD      L,C                     ;6e23
        LD      L,(HL)                  ;6e24
        LD      H,H                     ;6e25
        JR      NZ,m6e7b                ;6e26
        LD      A,C                     ;6e28
        LD      (HL),E                  ;6e29
        LD      (HL),H                  ;6e2a
        LD      H,L                     ;6e2b
        LD      L,L                     ;6e2c
        JR      NZ,m6ea4                ;6e2d
        LD      L,(HL)                  ;6e2f
        LD      H,H                     ;6e30
        JR      NZ,m6e36                ;6e31
m6e33   JR      NZ,m6e9e                ;6e33
        LD      H,H                     ;6e35
m6e36   LD      H,L                     ;6e36
m6e37   LD      L,(HL)                  ;6e37
        LD      (HL),H                  ;6e38
        LD      L,C                     ;6e39
        LD      (HL),E                  ;6e3a
m6e3b   LD      H,E                     ;6e3b
        LD      L,B                     ;6e3c
        CCF                             ;6e3d
        INC     BC                      ;6e3e
m6e3f   LD      B,H                     ;6e3f
        LD      L,C                     ;6e40
        LD      (HL),E                  ;6e41
        LD      L,E                     ;6e42
        LD      H,L                     ;6e43
        LD      (HL),H                  ;6e44
        LD      (HL),H                  ;6e45
        LD      H,L                     ;6e46
        JR      NZ,m6eaf                ;6e47
        LD      L,A                     ;6e49
        LD      (HL),D                  ;6e4a
        LD      L,L                     ;6e4b
        LD      H,C                     ;6e4c
        LD      (HL),H                  ;6e4d
        LD      L,C                     ;6e4e
        LD      H,L                     ;6e4f
        LD      (HL),D                  ;6e50
        LD      H,L                     ;6e51
m6e52   LD      L,(HL)                  ;6e52
        CCF                             ;6e53
        INC     BC                      ;6e54
        JR      NZ,m6e77                ;6e55
m6e57   LD      D,B                     ;6e57
        LD      H,C                     ;6e58
        LD      (HL),D                  ;6e59
        LD      H,C                     ;6e5a
        LD      L,L                     ;6e5b
        LD      H,L                     ;6e5c
        LD      (HL),H                  ;6e5d
        LD      H,L                     ;6e5e
        LD      (HL),D                  ;6e5f
        JR      NZ,m6ed1                ;6e60
        LD      H,H                     ;6e62
        LD      H,L                     ;6e63
        LD      (HL),D                  ;6e64
        JR      NZ,$+82                 ;6e65
        LD      B,H                     ;6e67
m6e68   DEC     L                       ;6e68
        LD      B,H                     ;6e69
        LD      H,C                     ;6e6a
        LD      (HL),H                  ;6e6b
        LD      H,L                     ;6e6c
        LD      L,(HL)                  ;6e6d
        JR      NZ,m6ed6                ;6e6e
        LD      H,C                     ;6e70
        LD      L,H                     ;6e71
        LD      (HL),E                  ;6e72
        LD      H,E                     ;6e73
m6e74   LD      L,B                     ;6e74
        DEC     C                       ;6e75
m6e76   LD      A,(HL)                  ;6e76
m6e77   CALL    DRVSEL                  ;6e77
        INC     HL                      ;6e7a
m6e7b   INC     HL                      ;6e7b
        INC     HL                      ;6e7c
        INC     HL                      ;6e7d
        LD      L,(HL)                  ;6e7e
        PUSH    HL                      ;6e7f
        POP     IX                      ;6e80
        RET                             ;6e82
        NOP                             ;6e83
        NOP                             ;6e84
        NOP                             ;6e85
m6e86   NOP                             ;6e86
        NOP                             ;6e87
        NOP                             ;6e88
m6e89   LD      B,(HL)                  ;6e89
        LD      L,A                     ;6e8a
        LD      (HL),D                  ;6e8b
        LD      L,L                     ;6e8c
m6e8d   LD      H,C                     ;6e8d
        LD      (HL),H                  ;6e8e
        LD      H,(HL)                  ;6e8f
        LD      H,L                     ;6e90
        LD      L,B                     ;6e91
        LD      L,H                     ;6e92
        LD      H,L                     ;6e93
        LD      (HL),D                  ;6e94
        JR      NZ,m6edd                ;6e95
        LD      (HL),D                  ;6e97
        LD      L,A                     ;6e98
        LD      L,(HL)                  ;6e99
        LD      (HL),H                  ;6e9a
        LD      (HL),E                  ;6e9b
        LD      H,L                     ;6e9c
        LD      L,C                     ;6e9d
m6e9e   LD      (HL),H                  ;6e9e
        LD      H,L                     ;6e9f
        JR      NZ,$+120                ;6ea0
        LD      L,A                     ;6ea2
        LD      L,(HL)                  ;6ea3
m6ea4   JR      NZ,$+85                 ;6ea4
        LD      (HL),B                  ;6ea6
        LD      (HL),L                  ;6ea7
        LD      (HL),D                  ;6ea8
        JR      NZ,m6eae                ;6ea9
m6eab   LD      B,(HL)                  ;6eab
        LD      (HL),D                  ;6eac
        LD      L,A                     ;6ead
m6eae   LD      L,(HL)                  ;6eae
m6eaf   LD      (HL),H                  ;6eaf
m6eb0   JR      NZ,m6f04                ;6eb0
        LD      A,L                     ;6eb2
        LD      H,E                     ;6eb3
        LD      L,E                     ;6eb4
m6eb5   CALL    m6ec0                   ;6eb5
        RET     Z                       ;6eb8
        CALL    CHKSEP                  ;6eb9
        RET     C                       ;6ebc
        RET     Z                       ;6ebd
        DEC     HL                      ;6ebe
        RET                             ;6ebf
m6ec0   LD      A,(HL)                  ;6ec0
        CP      0DH                     ;6ec1
        RET     Z                       ;6ec3
m6ec4   CALL    CHKSEP                  ;6ec4
        RET     NC                      ;6ec7
m6ec8   JP      m521a                   ;6ec8
m6ecb   LD      A,(HL)                  ;6ecb
        CP      3AH                     ;6ecc
        JR      NZ,m6ed1                ;6ece
        INC     HL                      ;6ed0
m6ed1   LD      A,(HL)                  ;6ed1
        SUB     30H                     ;6ed2
        CP      0AH                     ;6ed4
m6ed6   RET     NC                      ;6ed6
m6ed7   CALL    m6ee7                   ;6ed7
        CALL    DRVSEL                  ;6eda
m6edd   JR      NZ,m6ec8                ;6edd
        LD      A,E                     ;6edf
        SCF                             ;6ee0
        RET                             ;6ee1
m6ee2   CALL    m6ef1                   ;6ee2
        JR      m6eea                   ;6ee5
m6ee7   CALL    m6f0f                   ;6ee7
m6eea   LD      A,D                     ;6eea
        OR      A                       ;6eeb
        LD      A,E                     ;6eec
        RET     Z                       ;6eed
m6eee   JP      m5218                   ;6eee
m6ef1   PUSH    HL                      ;6ef1
        CALL    m6f14                   ;6ef2
        LD      A,(HL)                  ;6ef5
        SUB     41H                     ;6ef6
        CP      08H                     ;6ef8
        JR      NC,m6f09                ;6efa
        POP     HL                      ;6efc
        LD      B,01H                   ;6efd
        PUSH    HL                      ;6eff
        CALL    m6f16                   ;6f00
        LD      A,(HL)                  ;6f03
m6f04   CP      48H                     ;6f04
        INC     HL                      ;6f06
        JR      NZ,m6eee                ;6f07
m6f09   BIT     1,B                     ;6f09
        POP     BC                      ;6f0b
        RET     NZ                      ;6f0c
        JR      m6eee                   ;6f0d
m6f0f   PUSH    HL                      ;6f0f
        LD      DE,m6f09                ;6f10
        PUSH    DE                      ;6f13
m6f14   LD      B,00H                   ;6f14
m6f16   LD      DE,0000H                ;6f16
m6f19   LD      A,(HL)                  ;6f19
        SUB     30H                     ;6f1a
        CP      0AH                     ;6f1c
        JR      C,m6f2a                 ;6f1e
        BIT     0,B                     ;6f20
        RET     Z                       ;6f22
        SUB     11H                     ;6f23
        CP      06H                     ;6f25
        RET     NC                      ;6f27
        ADD     A,0AH                   ;6f28
m6f2a   PUSH    HL                      ;6f2a
        LD      H,D                     ;6f2b
        LD      L,E                     ;6f2c
        LD      C,A                     ;6f2d
        XOR     A                       ;6f2e
        SET     1,B                     ;6f2f
        ADD     HL,HL                   ;6f31
        ADC     A,A                     ;6f32
        ADD     HL,HL                   ;6f33
        ADC     A,A                     ;6f34
        BIT     0,B                     ;6f35
        JR      Z,m6f3c                 ;6f37
        ADD     HL,HL                   ;6f39
        JR      m6f3d                   ;6f3a
m6f3c   ADD     HL,DE                   ;6f3c
m6f3d   ADC     A,A                     ;6f3d
        ADD     HL,HL                   ;6f3e
        ADC     A,A                     ;6f3f
        LD      E,C                     ;6f40
        LD      D,00H                   ;6f41
        ADD     HL,DE                   ;6f43
        ADC     A,A                     ;6f44
        EX      DE,HL                   ;6f45
        POP     HL                      ;6f46
        RET     NZ                      ;6f47
        INC     HL                      ;6f48
        JR      m6f19                   ;6f49
m6f4b   LD      DE,m5ae5                ;6f4b
        CALL    m4e8d                   ;6f4e
        CALL    m6fe5                   ;6f51
        CALL    m4e8a                   ;6f54
        CALL    m5210                   ;6f57
        LD      HL,m65b0                ;6f5a
        LD      B,00H                   ;6f5d
        CALL    FOPEN                   ;6f5f
        RET     NZ                      ;6f62
        CALL    m4448                   ;6f63
        RET     NZ                      ;6f66
        EXX                             ;6f67
        LD      HL,m64b0                ;6f68
        LD      B,00H                   ;6f6b
        LD      DE,m5ae5                ;6f6d
        CALL    FOPEN                   ;6f70
        RET     NZ                      ;6f73
m6f74   CALL    0013H                   ;6f74
        JR      NZ,m6f83                ;6f77
        EXX                             ;6f79
        CALL    001BH                   ;6f7a
        EXX                             ;6f7d
        JR      Z,m6f74                 ;6f7e
m6f80   JP      m521a                   ;6f80
m6f83   CP      1CH                     ;6f83
        JR      Z,m6f8b                 ;6f85
        CP      1DH                     ;6f87
        JR      NZ,m6f80                ;6f89
m6f8b   EXX                             ;6f8b
        JP      m4428                   ;6f8c
m6f8f   LD      B,08H                   ;6f8f
        LD      C,00H                   ;6f91
        JR      m6f9e                   ;6f93
m6f95   LD      A,(HL)                  ;6f95
        CP      3AH                     ;6f96
        JR      NC,m6f9e                ;6f98
        CP      30H                     ;6f9a
        JR      NC,m6fa7                ;6f9c
m6f9e   LD      A,(HL)                  ;6f9e
        CP      5FH                     ;6f9f
        JR      NC,m6faf                ;6fa1
        CP      41H                     ;6fa3
        JR      C,m6faf                 ;6fa5
m6fa7   LD      (DE),A                  ;6fa7
        INC     HL                      ;6fa8
        INC     DE                      ;6fa9
        INC     C                       ;6faa
        DJNZ    m6f95                   ;6fab
        JR      m6fb5                   ;6fad
m6faf   LD      A,20H                   ;6faf
        LD      (DE),A                  ;6fb1
        INC     DE                      ;6fb2
        DJNZ    m6faf                   ;6fb3
m6fb5   LD      A,C                     ;6fb5
        OR      A                       ;6fb6
        RET                             ;6fb7
m6fb8   LD      DE,m598b                ;6fb8
        LD      C,03H                   ;6fbb
        CALL    m6eb5                   ;6fbd
        JR      NC,m6fde                ;6fc0
m6fc2   LD      B,02H                   ;6fc2
m6fc4   LD      A,(HL)                  ;6fc4
        CP      30H                     ;6fc5
        JR      C,m6fdb                 ;6fc7
        EX      DE,HL                   ;6fc9
        CP      (HL)                    ;6fca
        JR      NC,m6fdb                ;6fcb
        LD      (HL),A                  ;6fcd
        EX      DE,HL                   ;6fce
        INC     DE                      ;6fcf
        INC     HL                      ;6fd0
        DJNZ    m6fc4                   ;6fd1
        DEC     C                       ;6fd3
        RET     Z                       ;6fd4
        LD      A,(DE)                  ;6fd5
        CP      (HL)                    ;6fd6
        INC     DE                      ;6fd7
        INC     HL                      ;6fd8
        JR      Z,m6fc2                 ;6fd9
m6fdb   JP      m5218                   ;6fdb
m6fde   PUSH    HL                      ;6fde
        EX      DE,HL                   ;6fdf
        CALL    m4470                   ;6fe0
        POP     HL                      ;6fe3
        RET                             ;6fe4
m6fe5   CALL    m6ec4                   ;6fe5
        LD      D,H                     ;6fe8
        LD      E,L                     ;6fe9
        LD      BC,m6ff7                ;6fea
        CALL    STRCMP                  ;6fed
        RET     NZ                      ;6ff0
        CALL    CHKSEP                  ;6ff1
        RET     NC                      ;6ff4
        EX      DE,HL                   ;6ff5
        RET                             ;6ff6
m6ff7   LD      D,H                     ;6ff7
        LD      C,A                     ;6ff8
        NOP                             ;6ff9
        END     4d00h

