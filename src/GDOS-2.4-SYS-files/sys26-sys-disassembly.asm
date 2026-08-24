;************************************************************************
;
;	SYS26/SYS from G-DOS 2.4
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys26-sys-disassembly.asm
;
;************************************************************************
;
; The module GETSYS loads for request code 1Ch (28 decimal; Grosser ch.3,
; "aktuelles /SYS-Modul": code = SYS-number + 2, so 28-2 = SYS26/SYS).
; Loads into 4D00h-51E7h, entry 4D04h.
;
; Grosser's book has no SYS26/SYS entry -- presumably a Genie IIIs 2.4
; extension outside its scope, and not documented elsewhere. Everything
; below is read off the disassembly.
;
; This is the module as this port patches it, not stock: see the
; [PATCH] boxes at 4EFEh, 4F3Bh and 50D0h.
;
; Boxed annotations sit above the line they describe:
;
;   [PATCH]  a departure from stock GDOS 2.4, with the stock bytes,
;            this build's bytes and the reason for the change.
;   [note]   not from Grosser -- either a finding here, or a place
;            GDOS 2.4 diverges from his 2.1c (his ch.9.4.2).
;   Name:    a routine, as Grosser documents it in ch.3.
;
; Request-code dispatch (A on entry, per Grosser's GETSYS convention --
; xxxbbsss, top 3 bits select the function within this module):
;   3Ch -> m4d4c   5Ch -> m4da1   7Ch -> m4db9   9Ch -> m4e76
;   BCh -> falls through to a RST 28h tone dispatch at 4d1dh
;   anything else (incl. the module's own bare load, xxx=000, A=1Ch) falls
;   to m4fb6, the default path -- the one this boot's own first
;   load-and-run of the module actually takes.
;
;   z80dasm -g 0x4d00 -l -a -t sys26_flat.bin
;

m3400   EQU     3400h
m3402   EQU     3402h
m3406   EQU     3406h
m3605   EQU     3605h
m3656   EQU     3656h
m3678   EQU     3678h
m3738   EQU     3738h
m374e   EQU     374eh
m3751   EQU     3751h
m3753   EQU     3753h
m37e8   EQU     37e8h
m37f1   EQU     37f1h
m37f6   EQU     37f6h
m37f8   EQU     37f8h
m37fc   EQU     37fch
m37fd   EQU     37fdh
m3840   EQU     3840h
m3900   EQU     3900h
m392b   EQU     392bh
m393b   EQU     393bh
RSTUB   EQU     3a00h		;low-RAM transfer stub
m3aff   EQU     3affh
m3bfe   EQU     3bfeh
m3c00   EQU     3c00h
m4000   EQU     4000h
VIDCUR  EQU     4020h		;screen DCB: cursor address
VIDTOP  EQU     4023h		;video DCB: number of header lines
VIDBOT  EQU     4024h		;video DCB: number of footer lines
m4080   EQU     4080h
SECBUF  EQU     4200h		;DOS sector buffer
m4201   EQU     4201h
m4280   EQU     4280h
DMACH   EQU     4307h		;machine type; 04h is the Genie IIIs
DMODUL  EQU     4317h		;current /SYS module
m4370   EQU     4370h
m43ce   EQU     43ceh
DFCBDV  EQU     43d8h		;GETSYS FCB: NEXT, low byte
m43dc   EQU     43dch
DOSERR  EQU     4409h		;DOS error exit
READ    EQU     4436h		;read a sector
DSPLY   EQU     4467h		;display the text at (HL)
m45be   EQU     45beh
DRVSEL  EQU     4776h		;select a drive
GETFDE  EQU     4936h		;fetch a file's FDE from the directory, second entry
m4be1   EQU     4be1h
m4c1e   EQU     4c1eh
m4c2e   EQU     4c2eh
m4c6d   EQU     4c6dh
MULHL   EQU     4c92h		;HL * A
m4e1f   EQU     4e1fh		;operand byte inside this module -- self-modified code
m4e4f   EQU     4e4fh		;operand byte inside this module -- self-modified code
        ORG     4d00h
m4d00   NOP                             ;4d00
m4d01   NOP                             ;4d01
        NOP                             ;4d02
m4d03   NOP                             ;4d03
        CP      3CH                     ;4d04
        JP      Z,m4d4c                 ;4d06
        CP      5CH                     ;4d09
        JP      Z,m4da1                 ;4d0b
        CP      7CH                     ;4d0e
        JP      Z,m4db9                 ;4d10
        CP      9CH                     ;4d13
        JP      Z,m4e76                 ;4d15
        CP      0BCH                    ;4d18
        JP      NZ,m4fb6                ;4d1a
        LD      A,(DMACH)               ;4d1d
        AND     0FH                     ;4d20
        CP      02H                     ;4d22
        JR      C,m4d32                 ;4d24
        LD      B,0F9H                  ;4d26
        JR      Z,m4d30                 ;4d28
        CP      06H                     ;4d2a
        JR      NC,m4d32                ;4d2c
        LD      B,0FAH                  ;4d2e
m4d30   LD      A,B                     ;4d30
        RST     28H                     ;4d31
m4d32   LD      A,2AH                   ;4d32
m4d34   EI                              ;4d34
        JP      DOSERR                  ;4d35
m4d38   LD      A,2FH                   ;4d38
        JR      m4d34                   ;4d3a
m4d3c   LD      A,(DMACH)               ;4d3c
        AND     0FH                     ;4d3f
        CP      02H                     ;4d41
        RET     Z                       ;4d43
        AND     0EH                     ;4d44
        CP      04H                     ;4d46
        RET     Z                       ;4d48
        POP     AF                      ;4d49
        XOR     A                       ;4d4a
        RET                             ;4d4b
m4d4c   CALL    m4d3c                   ;4d4c
        LD      A,(HL)                  ;4d4f
        CP      0DH                     ;4d50
        JP      Z,m4d77                 ;4d52
        CP      54H                     ;4d55
        JP      Z,m4d77                 ;4d57
        XOR     A                       ;4d5a
        RET                             ;4d5b
        LD      HL,(VIDCUR)             ;4d5c
        LD      A,1CH                   ;4d5f
        CALL    0033H                   ;4d61
        LD      (VIDCUR),HL             ;4d64
        XOR     A                       ;4d67
        CALL    0033H                   ;4d68
        RET                             ;4d6b
m4d6c   PUSH    HL                      ;4d6c
        LD      HL,(m37f1)              ;4d6d
        CALL    MULHL                   ;4d70
        LD      C,L                     ;4d73
        LD      B,H                     ;4d74
        POP     HL                      ;4d75
        RET                             ;4d76
m4d77   LD      A,(VIDTOP)              ;4d77
        OR      A                       ;4d7a
        JR      Z,m4d8d                 ;4d7b
        CALL    m4d6c                   ;4d7d
        LD      HL,(m3406)              ;4d80
        OR      A                       ;4d83
        SBC     HL,BC                   ;4d84
        LD      DE,(m3400)              ;4d86
        CALL    m3656                   ;4d8a
m4d8d   LD      A,(VIDBOT)              ;4d8d
        OR      A                       ;4d90
        RET     Z                       ;4d91
        CALL    m4d6c                   ;4d92
        LD      HL,(m3402)              ;4d95
        LD      DE,(m3406)              ;4d98
        CALL    m3656                   ;4d9c
        XOR     A                       ;4d9f
        RET                             ;4da0
m4da1   PUSH    AF                      ;4da1
        PUSH    BC                      ;4da2
        PUSH    DE                      ;4da3
        PUSH    HL                      ;4da4
        CALL    m4d77                   ;4da5
        POP     HL                      ;4da8
        POP     DE                      ;4da9
        POP     BC                      ;4daa
        POP     AF                      ;4dab
        RET                             ;4dac
m4dad   CALL    m4db5                   ;4dad
        LD      A,(HL)                  ;4db0
m4db1   RET                             ;4db1
        JP      m3678                   ;4db2
m4db5   RET                             ;4db5
        JP      m3605                   ;4db6
m4db9   LD      A,(DMACH)               ;4db9
        AND     0FH                     ;4dbc
        CP      02H                     ;4dbe
        LD      HL,m3c00                ;4dc0
        LD      DE,m4000                ;4dc3
        JR      Z,m4dd0                 ;4dc6
        RES     0,A                     ;4dc8
        CP      04H                     ;4dca
        JR      NZ,m4e02                ;4dcc
        LD      H,38H                   ;4dce
m4dd0   EX      DE,HL                   ;4dd0
        LD      A,(m37fc)               ;4dd1
        LD      H,A                     ;4dd4
        LD      A,(m37fd)               ;4dd5
        LD      L,A                     ;4dd8
        ADD     HL,DE                   ;4dd9
        PUSH    HL                      ;4dda
        LD      A,(m37f6)               ;4ddb
        LD      L,A                     ;4dde
        LD      A,(m37f8)               ;4ddf
        AND     03H                     ;4de2
        CP      03H                     ;4de4
        JR      NZ,m4dea                ;4de6
        RLC     L                       ;4de8
m4dea   LD      A,(m37f1)               ;4dea
        LD      (m4e1f),A               ;4ded
        CALL    MULHL                   ;4df0
        EX      DE,HL                   ;4df3
        POP     HL                      ;4df4
        EX      DE,HL                   ;4df5
        ADD     HL,DE                   ;4df6
        EX      DE,HL                   ;4df7
        XOR     A                       ;4df8
        LD      (m4db5),A               ;4df9
        LD      (m4db1),A               ;4dfc
        LD      BC,0000H                ;4dff
m4e02   CALL    05D1H                   ;4e02
        JR      Z,m4e0e                 ;4e05
        DEC     BC                      ;4e07
        LD      A,B                     ;4e08
        OR      C                       ;4e09
        JR      Z,m4e58                 ;4e0a
        JR      m4e02                   ;4e0c
m4e0e   EX      DE,HL                   ;4e0e
m4e0f   DEC     HL                      ;4e0f
        RST     18H                     ;4e10
        JR      Z,m4e1b                 ;4e11
        CALL    m4dad                   ;4e13
        CP      20H                     ;4e16
        JR      Z,m4e0f                 ;4e18
        INC     HL                      ;4e1a
m4e1b   EX      DE,HL                   ;4e1b
m4e1c   PUSH    DE                      ;4e1c
        PUSH    HL                      ;4e1d
        LD      E,40H                   ;4e1e
        LD      D,00H                   ;4e20
        ADD     HL,DE                   ;4e22
        LD      B,E                     ;4e23
m4e24   DEC     HL                      ;4e24
        CALL    m4dad                   ;4e25
        CP      20H                     ;4e28
        JR      NZ,m4e2f                ;4e2a
        DJNZ    m4e24                   ;4e2c
        INC     B                       ;4e2e
m4e2f   POP     HL                      ;4e2f
        LD      (m4e4f),HL              ;4e30
        POP     DE                      ;4e33
m4e34   CALL    m4dad                   ;4e34
        CP      20H                     ;4e37
        JR      NC,m4e3d                ;4e39
        OR      40H                     ;4e3b
m4e3d   CALL    m4e5c                   ;4e3d
        INC     HL                      ;4e40
        LD      A,(m3840)               ;4e41
        AND     04H                     ;4e44
        JR      NZ,m4e5a                ;4e46
        DJNZ    m4e34                   ;4e48
        LD      A,(m4e1f)               ;4e4a
        LD      C,A                     ;4e4d
        LD      HL,0000H                ;4e4e
        ADD     HL,BC                   ;4e51
        CALL    m4e5a                   ;4e52
        RST     18H                     ;4e55
        JR      C,m4e1c                 ;4e56
m4e58   XOR     A                       ;4e58
        RET                             ;4e59
m4e5a   LD      A,0DH                   ;4e5a
m4e5c   PUSH    DE                      ;4e5c
        LD      E,A                     ;4e5d
        LD      A,(m4370)               ;4e5e
        CP      E                       ;4e61
        JR      NC,m4e66                ;4e62
        LD      E,20H                   ;4e64
m4e66   LD      A,E                     ;4e66
        CALL    003BH                   ;4e67
        POP     DE                      ;4e6a
        RET                             ;4e6b
m4e6c   LD      D,B                     ;4e6c
        LD      C,C                     ;4e6d
        LD      C,A                     ;4e6e
        JR      NZ,m4e74                ;4e6f
m4e71   LD      C,(HL)                  ;4e71
        LD      C,A                     ;4e72
        LD      D,B                     ;4e73
m4e74   LD      D,D                     ;4e74
        DEC     C                       ;4e75
m4e76   LD      A,(DMACH)               ;4e76
        AND     07H                     ;4e79
        CP      04H                     ;4e7b
        LD      A,2AH                   ;4e7d
        RET     C                       ;4e7f
        LD      A,(HL)                  ;4e80
        CP      0DH                     ;4e81
        JR      Z,m4e90                 ;4e83
        CP      50H                     ;4e85
        JR      Z,m4ebc                 ;4e87
        CP      4EH                     ;4e89
        JR      Z,m4ea7                 ;4e8b
        JP      m4d38                   ;4e8d
m4e90   LD      HL,m4e6c                ;4e90
        CALL    DSPLY                   ;4e93
        LD      HL,m4e71                ;4e96
        LD      A,(05BDH)               ;4e99
        CP      0D4H                    ;4e9c
        JR      NZ,m4ea2                ;4e9e
        INC     HL                      ;4ea0
        INC     HL                      ;4ea1
m4ea2   CALL    DSPLY                   ;4ea2
m4ea5   XOR     A                       ;4ea5
        RET                             ;4ea6
m4ea7   LD      HL,m37e8                ;4ea7
        LD      A,32H                   ;4eaa
        LD      (05BBH),A               ;4eac
        LD      (05BCH),HL              ;4eaf
        LD      A,3AH                   ;4eb2
        LD      (05D1H),A               ;4eb4
        LD      (05D2H),HL              ;4eb7
        JR      m4ea5                   ;4eba
m4ebc   LD      A,07H                   ;4ebc
        OUT     (0D6H),A                ;4ebe
        OUT     (0D7H),A                ;4ec0
        LD      A,0FH                   ;4ec2
        OUT     (0D6H),A                ;4ec4
        LD      A,0CFH                  ;4ec6
        OUT     (0D7H),A                ;4ec8
        LD      A,0FEH                  ;4eca
        OUT     (0D7H),A                ;4ecc
        LD      A,01H                   ;4ece
        OUT     (0D5H),A                ;4ed0
        LD      HL,0D4D3H               ;4ed2
        XOR     A                       ;4ed5
        LD      (05BBH),A               ;4ed6
        LD      (05BCH),HL              ;4ed9
        LD      (05D1H),A               ;4edc
        LD      HL,0D5DBH               ;4edf
        LD      (05D2H),HL              ;4ee2
        JR      m4ea5                   ;4ee5
m4ee7   LD      SP,0000H                ;4ee7
        OR      A                       ;4eea
        RET                             ;4eeb
; ------------------------------------------------------------
; [note]      4EECh: entry, request code 9Ch (from m4e76). Computes
;             dir-sector/FPDE address via 4F2Ch, after its own
;             DRVSEL(sysvol) call -- same idiom as 4F34h below,
;             reached via P/N/<ENTER> prompt (4E76h), not bare load.
; ------------------------------------------------------------
m4eec   PUSH    HL                      ;4eec
        PUSH    DE                      ;4eed
        PUSH    BC                      ;4eee
        PUSH    AF                      ;4eef
        LD      HL,m4d00                ;4ef0
        LD      (HL),A                  ;4ef3
        AND     07H                     ;4ef4
        LD      C,A                     ;4ef6
; ------------------------------------------------------------
; [note]      4EF7h: XOR A/LD (DFCBDV),A/LD (45BEh),A/CALL -- one
;             register clear doubles as DRVSEL's drive arg and the
;             FCB's NEXT-field reset. Same idiom as SYS0/SYS 4BE4h
;             and 4F34h below. CALL is patched, see box below.
; ------------------------------------------------------------
        XOR     A                       ;4ef7
        LD      (DFCBDV),A              ;4ef8
        LD      (m45be),A               ;4efb
; ------------------------------------------------------------
; [PATCH]     4EFEh-4F00h
; Stock:      CD 76 47   CALL DRVSEL (A=0, drive 0)
; This build: CD D0 50   CALL 50D0h stub, shared with 4F3Bh below
; Reason:     Drive 0 hardcoded, sysvol needed. Straddles the
;             4E00h-4EFFh/4F00h-4FFFh load-record boundary (CD at
;             4EFEh, operand at 4EFFh-4F00h) -- 4F3Bh below doesn't.
; ------------------------------------------------------------
        CALL    m50d0                   ;4efe
        LD      A,(HL)                  ;4f01
        SUB     C                       ;4f02
        RLCA                            ;4f03
        RLCA                            ;4f04
        CALL    m4f2c                   ;4f05
        JP      NZ,m4ee7                ;4f08
        BIT     6,(HL)                  ;4f0b
        JR      Z,m4f26                 ;4f0d
        ADD     A,14H                   ;4f0f
        LD      L,A                     ;4f11
        LD      A,(HL)                  ;4f12
        LD      (m4d03),A               ;4f13
        INC     L                       ;4f16
        INC     L                       ;4f17
        LD      E,(HL)                  ;4f18
        INC     HL                      ;4f19
        LD      D,(HL)                  ;4f1a
        LD      (m43dc),DE              ;4f1b
        LD      HL,m43ce                ;4f1f
        LD      (m4d01),HL              ;4f22
        XOR     A                       ;4f25
m4f26   POP     BC                      ;4f26
        LD      A,B                     ;4f27
        POP     BC                      ;4f28
        POP     DE                      ;4f29
        POP     HL                      ;4f2a
        RET                             ;4f2b
m4f2c   LD      L,A                     ;4f2c
        LD      A,C                     ;4f2d
        ADD     A,51H                   ;4f2e
        LD      H,A                     ;4f30
        XOR     A                       ;4f31
        LD      A,L                     ;4f32
        RET                             ;4f33
; ------------------------------------------------------------
; [note]      4F34h: reached from m4fb6, this module's own first
;             load-and-run (bare module value, A=1Ch). DRVSEL(0)
;             call here fires right after GETSYS's own six
;             DRVSEL(5) calls -- direct cause of the floppy
;             seek/read this port had to patch out. XOR A/LD
;             (DFCBDV),A/LD (45BEh),A below: unchanged. Only the
;             CALL after them is patched.
; ------------------------------------------------------------
m4f34   XOR     A                       ;4f34
        LD      (DFCBDV),A              ;4f35
        LD      (m45be),A               ;4f38
; ------------------------------------------------------------
; [PATCH]     4F3Bh
; Stock:      CD 76 47   CALL DRVSEL (A=0, drive 0)
; This build: CD D0 50   CALL 50D0h stub (LD A,05h/JP DRVSEL),
;             shared with 4EFEh above
; Reason:     File can't grow -- 10 bytes (XOR A + 2 stores +
;             CALL), no 1-byte way to load A with sysvol inline.
;             Stub tail-jumps DRVSEL; RET still returns to 4F3Eh.
; ------------------------------------------------------------
        CALL    m50d0                   ;4f3b
        LD      B,08H                   ;4f3e
        XOR     A                       ;4f40
; ------------------------------------------------------------
; [note]      4F41h: DE=5100h, dest of the 8x256-byte GETFDE/LDIR
;             loop below. 5100h-51E7h: zero in the static file,
;             but a runtime buffer -- not a home for a patch.
; ------------------------------------------------------------
        LD      DE,m5100                ;4f41
m4f44   PUSH    BC                      ;4f44
        PUSH    DE                      ;4f45
        PUSH    AF                      ;4f46
        CALL    GETFDE                  ;4f47
        JP      NZ,m4ee7                ;4f4a
        POP     AF                      ;4f4d
        POP     DE                      ;4f4e
        LD      BC,0100H                ;4f4f
        LDIR                            ;4f52
        INC     A                       ;4f54
        POP     BC                      ;4f55
        DJNZ    m4f44                   ;4f56
        RET                             ;4f58
m4f59   LD      A,(m4d03)               ;4f59
        OR      A                       ;4f5c
        JR      Z,m4f76                 ;4f5d
        PUSH    AF                      ;4f5f
        DEC     A                       ;4f60
        LD      (m4d03),A               ;4f61
        PUSH    BC                      ;4f64
        PUSH    DE                      ;4f65
        PUSH    HL                      ;4f66
        LD      DE,(m4d01)              ;4f67
        CALL    READ                    ;4f6b
        JP      NZ,m4ee7                ;4f6e
        POP     HL                      ;4f71
        POP     DE                      ;4f72
        POP     BC                      ;4f73
        POP     AF                      ;4f74
        RET                             ;4f75
m4f76   XOR     A                       ;4f76
        RET                             ;4f77
m4f78   LD      (m393b),SP              ;4f78
        LD      SP,m3bfe                ;4f7c
        PUSH    HL                      ;4f7f
        PUSH    DE                      ;4f80
        PUSH    BC                      ;4f81
        PUSH    AF                      ;4f82
        LD      (m392b),HL              ;4f83
        LD      HL,SECBUF               ;4f86
        LD      BC,0100H                ;4f89
        PUSH    DE                      ;4f8c
        LD      DE,RSTUB                ;4f8d
        LDIR                            ;4f90
        POP     DE                      ;4f92
        LD      HL,RSTUB                ;4f93
        LD      BC,0100H                ;4f96
        IN      A,(0F9H)                ;4f99
        PUSH    AF                      ;4f9b
        DI                              ;4f9c
        AND     3EH                     ;4f9d
        OUT     (0F9H),A                ;4f9f
        LD      (0000H),DE              ;4fa1
        LD      D,E                     ;4fa5
        LD      E,00H                   ;4fa6
        LDIR                            ;4fa8
        POP     AF                      ;4faa
        OUT     (0F9H),A                ;4fab
        EI                              ;4fad
        POP     AF                      ;4fae
        POP     BC                      ;4faf
        POP     DE                      ;4fb0
        POP     HL                      ;4fb1
        LD      SP,0000H                ;4fb2
        RET                             ;4fb5
m4fb6   LD      (m4ee7+1),SP            ;4fb6
        LD      A,(m3840)               ;4fba
        BIT     6,A                     ;4fbd
        JR      NZ,m4fcd                ;4fbf
        LD      A,(DMACH)               ;4fc1
        AND     0FH                     ;4fc4
        CP      03H                     ;4fc6
        JP      Z,m4fcd                 ;4fc8
        CP      04H                     ;4fcb
m4fcd   LD      A,00H                   ;4fcd
        RET     NZ                      ;4fcf
        CALL    m4f34                   ;4fd0
        LD      HL,m4f78                ;4fd3
        LD      DE,m3900                ;4fd6
        LD      BC,003EH                ;4fd9
        LDIR                            ;4fdc
        LD      A,01H                   ;4fde
        LD      (m4d03),A               ;4fe0
        LD      HL,SECBUF               ;4fe3
        LD      DE,m4201                ;4fe6
        LD      (HL),00H                ;4fe9
        LD      BC,00FFH                ;4feb
        LDIR                            ;4fee
        LD      HL,m5071                ;4ff0
        LD      DE,m4280                ;4ff3
        LD      BC,0013H                ;4ff6
        LDIR                            ;4ff9
        LD      HL,m4000                ;4ffb
        LD      E,40H                   ;4ffe
        CALL    m3900                   ;5000
        LD      B,1DH                   ;5003
        LD      IX,m5084                ;5005
        LD      E,41H                   ;5009
m500b   LD      H,40H                   ;500b
        LD      A,(IX+00H)              ;500d
        ADD     A,02H                   ;5010
        LD      L,A                     ;5012
        RLC     L                       ;5013
        CALL    m4eec                   ;5015
        JR      NZ,m5028                ;5018
m501a   CALL    m4f59                   ;501a
        JR      Z,m5028                 ;501d
        LD      D,A                     ;501f
        CALL    m3900                   ;5020
        LD      L,00H                   ;5023
        INC     E                       ;5025
        JR      m501a                   ;5026
m5028   INC     IX                      ;5028
        DEC     B                       ;502a
        JR      NZ,m500b                ;502b
        LD      HL,m50a1                ;502d
        LD      DE,m3738                ;5030
        LD      BC,0028H                ;5033
        LDIR                            ;5036
        LD      HL,m5046                ;5038
        LD      DE,m4be1                ;503b
        LD      BC,002BH                ;503e
        LDIR                            ;5041
        JP      m4f76                   ;5043
m5046   LD      H,40H                   ;5046
        CALL    m3738                   ;5048
        LD      A,(DMODUL)              ;504b
        RLCA                            ;504e
        LD      L,A                     ;504f
        LD      H,3AH                   ;5050
        LD      A,(HL)                  ;5052
        LD      (m3753),A               ;5053
        INC     HL                      ;5056
        LD      A,(HL)                  ;5057
        OR      A                       ;5058
        JR      Z,m5073                 ;5059
        LD      HL,m3751                ;505b
        LD      (m4c6d),HL              ;505e
        LD      DE,m3aff                ;5061
        CALL    m4c2e                   ;5064
        LD      (m4c1e),HL              ;5067
        LD      HL,READ                 ;506a
        LD      (m4c6d),HL              ;506d
        NOP                             ;5070
m5071   PUSH    HL                      ;5071
        PUSH    DE                      ;5072
m5073   PUSH    BC                      ;5073
        PUSH    AF                      ;5074
        LD      L,00H                   ;5075
        LD      DE,RSTUB                ;5077
        LD      BC,0100H                ;507a
        LDIR                            ;507d
        POP     AF                      ;507f
        POP     BC                      ;5080
        POP     DE                      ;5081
        POP     HL                      ;5082
        RET                             ;5083
m5084   ADD     HL,DE                   ;5084
        JR      $+31                    ;5085
        RLA                             ;5087
        LD      DE,0B10H                ;5088
        RRCA                            ;508b
        LD      C,07H                   ;508c
        INC     DE                      ;508e
        LD      (DE),A                  ;508f
        DEC     C                       ;5090
        LD      A,(BC)                  ;5091
        INC     D                       ;5092
        LD      BC,0302H                ;5093
        INC     B                       ;5096
        EX      AF,AF'                  ;5097
        ADD     HL,BC                   ;5098
        DEC     B                       ;5099
        LD      B,0CH                   ;509a
        DEC     D                       ;509c
        INC     E                       ;509d
        LD      D,1BH                   ;509e
        LD      A,(DE)                  ;50a0
m50a1   LD      (m374e),SP              ;50a1
        DI                              ;50a5
        LD      SP,m3bfe                ;50a6
        IN      A,(0F9H)                ;50a9
        PUSH    AF                      ;50ab
        AND     3EH                     ;50ac
        OUT     (0F9H),A                ;50ae
        CALL    m4080                   ;50b0
        POP     AF                      ;50b3
        OUT     (0F9H),A                ;50b4
        LD      SP,0000H                ;50b6
        RET                             ;50b9
        PUSH    HL                      ;50ba
        LD      H,00H                   ;50bb
        CALL    m3738                   ;50bd
        LD      A,H                     ;50c0
        INC     A                       ;50c1
        LD      (m3753),A               ;50c2
        XOR     A                       ;50c5
        EI                              ;50c6
        POP     HL                      ;50c7
        RET                             ;50c8
; ------------------------------------------------------------
; [note]      50C9h-50FFh: dead space (NOPs). 50D0h-50D4h: this
;             port's shared patch stub, boxed below; rest stays
;             NOP. Earlier build gave 4EFEh/4F3Bh a stub apiece
;             (50D0h, 50D5h) -- identical, consolidated to one.
; ------------------------------------------------------------
        NOP                             ;50c9
        NOP                             ;50ca
        NOP                             ;50cb
        NOP                             ;50cc
        NOP                             ;50cd
        NOP                             ;50ce
        NOP                             ;50cf
; ------------------------------------------------------------
; [PATCH]     50D0h-50D4h
; Stock:      00 00 00 00 00   NOP x5 (dead space)
; This build: 3E 05 C3 76 47   LD A,05h / JP DRVSEL -- stub for
;             both 4EFEh and 4F3Bh above
; Reason:     Loads sysvol, tail-jumps DRVSEL -- RET still returns
;             to each call site's own next instruction. Confirmed
;             dead space, before the 5100h runtime buffer (see
;             4F41h note), so the LDIR loop there doesn't touch it.
; ------------------------------------------------------------
m50d0   LD      A,05H                   ;50d0
        JP      DRVSEL                  ;50d2
        NOP                             ;50d5
        NOP                             ;50d6
        NOP                             ;50d7
        NOP                             ;50d8
        NOP                             ;50d9
        NOP                             ;50da
        NOP                             ;50db
        NOP                             ;50dc
        NOP                             ;50dd
        NOP                             ;50de
        NOP                             ;50df
        NOP                             ;50e0
        NOP                             ;50e1
        NOP                             ;50e2
        NOP                             ;50e3
        NOP                             ;50e4
        NOP                             ;50e5
        NOP                             ;50e6
        NOP                             ;50e7
        NOP                             ;50e8
        NOP                             ;50e9
        NOP                             ;50ea
        NOP                             ;50eb
        NOP                             ;50ec
        NOP                             ;50ed
        NOP                             ;50ee
        NOP                             ;50ef
        NOP                             ;50f0
        NOP                             ;50f1
        NOP                             ;50f2
        NOP                             ;50f3
        NOP                             ;50f4
        NOP                             ;50f5
        NOP                             ;50f6
        NOP                             ;50f7
        NOP                             ;50f8
        NOP                             ;50f9
        NOP                             ;50fa
        NOP                             ;50fb
        NOP                             ;50fc
        NOP                             ;50fd
        NOP                             ;50fe
        NOP                             ;50ff
m5100   NOP                             ;5100
        NOP                             ;5101
        NOP                             ;5102
        NOP                             ;5103
        NOP                             ;5104
        NOP                             ;5105
        NOP                             ;5106
        NOP                             ;5107
        NOP                             ;5108
        NOP                             ;5109
        NOP                             ;510a
        NOP                             ;510b
        NOP                             ;510c
        NOP                             ;510d
        NOP                             ;510e
        NOP                             ;510f
        NOP                             ;5110
        NOP                             ;5111
        NOP                             ;5112
        NOP                             ;5113
        NOP                             ;5114
        NOP                             ;5115
        NOP                             ;5116
        NOP                             ;5117
        NOP                             ;5118
        NOP                             ;5119
        NOP                             ;511a
        NOP                             ;511b
        NOP                             ;511c
        NOP                             ;511d
        NOP                             ;511e
        NOP                             ;511f
        NOP                             ;5120
        NOP                             ;5121
        NOP                             ;5122
        NOP                             ;5123
        NOP                             ;5124
        NOP                             ;5125
        NOP                             ;5126
        NOP                             ;5127
        NOP                             ;5128
        NOP                             ;5129
        NOP                             ;512a
        NOP                             ;512b
        NOP                             ;512c
        NOP                             ;512d
        NOP                             ;512e
        NOP                             ;512f
        NOP                             ;5130
        NOP                             ;5131
        NOP                             ;5132
        NOP                             ;5133
        NOP                             ;5134
        NOP                             ;5135
        NOP                             ;5136
        NOP                             ;5137
        NOP                             ;5138
        NOP                             ;5139
        NOP                             ;513a
        NOP                             ;513b
        NOP                             ;513c
        NOP                             ;513d
        NOP                             ;513e
        NOP                             ;513f
        NOP                             ;5140
        NOP                             ;5141
        NOP                             ;5142
        NOP                             ;5143
        NOP                             ;5144
        NOP                             ;5145
        NOP                             ;5146
        NOP                             ;5147
        NOP                             ;5148
        NOP                             ;5149
        NOP                             ;514a
        NOP                             ;514b
        NOP                             ;514c
        NOP                             ;514d
        NOP                             ;514e
        NOP                             ;514f
        NOP                             ;5150
        NOP                             ;5151
        NOP                             ;5152
        NOP                             ;5153
        NOP                             ;5154
        NOP                             ;5155
        NOP                             ;5156
        NOP                             ;5157
        NOP                             ;5158
        NOP                             ;5159
        NOP                             ;515a
        NOP                             ;515b
        NOP                             ;515c
        NOP                             ;515d
        NOP                             ;515e
        NOP                             ;515f
        NOP                             ;5160
        NOP                             ;5161
        NOP                             ;5162
        NOP                             ;5163
        NOP                             ;5164
        NOP                             ;5165
        NOP                             ;5166
        NOP                             ;5167
        NOP                             ;5168
        NOP                             ;5169
        NOP                             ;516a
        NOP                             ;516b
        NOP                             ;516c
        NOP                             ;516d
        NOP                             ;516e
        NOP                             ;516f
        NOP                             ;5170
        NOP                             ;5171
        NOP                             ;5172
        NOP                             ;5173
        NOP                             ;5174
        NOP                             ;5175
        NOP                             ;5176
        NOP                             ;5177
        NOP                             ;5178
        NOP                             ;5179
        NOP                             ;517a
        NOP                             ;517b
        NOP                             ;517c
        NOP                             ;517d
        NOP                             ;517e
        NOP                             ;517f
        NOP                             ;5180
        NOP                             ;5181
        NOP                             ;5182
        NOP                             ;5183
        NOP                             ;5184
        NOP                             ;5185
        NOP                             ;5186
        NOP                             ;5187
        NOP                             ;5188
        NOP                             ;5189
        NOP                             ;518a
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
        NOP                             ;51a6
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
        END     4d00h

