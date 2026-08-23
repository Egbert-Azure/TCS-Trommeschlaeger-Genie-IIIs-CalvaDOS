;************************************************************************
;
;	SSYS29/SYS, stock GDOS 2.4
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys29-sys-disassembly.asm
;
; Date: 2026/08/20
;
;************************************************************************
;
; Start 4D00h, RAM range 4D00h-51E9h -- from this file's own load records
;
; Two addresses are covered by no load record at all: 4FF0h and 50F1h, which
; fall between the records ...4F00..4FEF, 4FF1..50F0 and 50F2..51E9. Both are
; zero below because nothing loads them. Whether they are padding or are
; written at runtime is not established.
;
;
;   z80dasm -g 0x4d00 -l -a -t sys29_flat.bin
;
; Rewritten from that z80dasm output into readable assembly: names in place
; of z80dasm's lNNNNh/sub_NNNNh, and the module address of each line in the
; right-hand column. Verified by assembling this file with pasmo and
; comparing the result with the module byte for byte.
;
; Parts of every module are data -- message strings and tables -- that
; z80dasm decodes as instructions, because it walks the bytes in order
; rather than following where the code can go. Those stretches read as
; nonsense (LD C,C / LD D,E is the letters I S), and any number in them
; is a data byte, not an address. Only references that land in low RAM,
; the DOS or this module get a symbol; anything else keeps its number,
; which is the signal that it is not a reference at all.

SCROFF  EQU     3641h		;offset of the visible from the physical screen
SCRPUT  EQU     3649h		;put character A on the screen at (HL)
KBDTYP  EQU     4015h		;keyboard DCB: type
KBDDRV  EQU     4016h		;keyboard DCB: driver address
VIDTYP  EQU     401dh		;screen DCB: type
VIDDRV  EQU     401eh		;screen DCB: driver address
VIDCUR  EQU     4020h		;screen DCB: cursor address
VIDTOP  EQU     4023h		;video DCB: number of header lines
VIDBOT  EQU     4024h		;video DCB: number of footer lines
PRTTYP  EQU     4025h		;printer DCB: type
PRTDRV  EQU     4026h		;printer DCB: driver address
m4028   EQU     4028h
m4029   EQU     4029h
HIMEM   EQU     4049h		;HIMEM
HEXDE   EQU     4063h		;write DE as hex ASCII to (HL)
HEXA    EQU     4068h		;write A as hex ASCII to (HL)
DMACH   EQU	4307h		;machine type; 04h is the Genie IIIs
PDRV0   EQU     4371h		;start of the PDRIVE parameters for drive 0
DNDRV   EQU     439fh		;number of drives
m4402   EQU     4402h
DSPLY   EQU     4467h		;display the text at (HL)
m4505   EQU     4505h
CHNTOG  EQU     4516h		;toggle the CHAINING flag in DFLAG0
m4620   EQU     4620h
m4811   EQU     4811h
m4a11   EQU     4a11h
m4be1   EQU     4be1h
CHKCHR  EQU     4cd5h		;test the character at (HL)
m4e6d   EQU     4e6dh		;operand byte inside this module -- self-modified code
m4ebb   EQU     4ebbh		;operand byte inside this module -- self-modified code
m4ecc   EQU     4ecch		;operand byte inside this module -- self-modified code
m4ecf   EQU     4ecfh		;operand byte inside this module -- self-modified code
m4ef6   EQU     4ef6h		;operand byte inside this module -- self-modified code
m4efa   EQU     4efah		;operand byte inside this module -- self-modified code
m5028   EQU     5028h		;operand byte inside this module -- self-modified code
m5123   EQU     5123h		;operand byte inside this module -- self-modified code
m5142   EQU     5142h		;operand byte inside this module -- self-modified code
m5167   EQU     5167h		;operand byte inside this module -- self-modified code
m5177   EQU     5177h		;operand byte inside this module -- self-modified code
m519a   EQU     519ah		;operand byte inside this module -- self-modified code
m51a2   EQU     51a2h		;operand byte inside this module -- self-modified code
        ORG     4d00h
        PUSH    AF                      ;4d00
        PUSH    HL                      ;4d01
        LD      A,(DMACH)               ;4d02
        AND     0FH                     ;4d05
        CP      02H                     ;4d07
        JR      C,m4d21                 ;4d09
        CP      03H                     ;4d0b
        JR      Z,m4d21                 ;4d0d
        CP      06H                     ;4d0f
        JR      NC,m4d21                ;4d11
        LD      HL,0000H                ;4d13
        LD      (m4e8d),HL              ;4d16
        LD      HL,SCROFF               ;4d19
        LD      (m4e6d),HL              ;4d1c
        JR      m4d30                   ;4d1f
m4d21   LD      HL,m515b                ;4d21
        LD      E,L                     ;4d24
        LD      D,H                     ;4d25
        LD      (HL),20H                ;4d26
        INC     DE                      ;4d28
        PUSH    BC                      ;4d29
        LD      BC,001EH                ;4d2a
        LDIR                            ;4d2d
        POP     BC                      ;4d2f
m4d30   POP     HL                      ;4d30
        CP      03H                     ;4d31
        JR      C,m4d41                 ;4d33
        CP      06H                     ;4d35
        JR      NC,m4d41                ;4d37
        LD      A,0C3H                  ;4d39
        LD      (m4ec9),A               ;4d3b
        LD      (m4ecc),A               ;4d3e
m4d41   POP     AF                      ;4d41
        CP      0FFH                    ;4d42
        JR      NZ,m4d52                ;4d44
        DEC     C                       ;4d46
        JP      Z,m4d5a                 ;4d47
        DEC     C                       ;4d4a
        JP      Z,m4ecf                 ;4d4b
        DEC     C                       ;4d4e
        JP      Z,m4f23                 ;4d4f
m4d52   LD      A,2AH                   ;4d52
        OR      A                       ;4d54
        RET                             ;4d55
m4d56   LD      A,34H                   ;4d56
        OR      A                       ;4d58
        RET                             ;4d59
m4d5a   CALL    CHKCHR                  ;4d5a
        LD      A,(HL)                  ;4d5d
        INC     HL                      ;4d5e
        CP      0DH                     ;4d5f
        JR      Z,m4ddc                 ;4d61
        CP      4DH                     ;4d63
        JR      Z,m4da3                 ;4d65
        CP      44H                     ;4d67
        JR      Z,m4d8e                 ;4d69
        CP      47H                     ;4d6b
        JR      Z,m4d9e                 ;4d6d
        CP      5AH                     ;4d6f
        JR      Z,m4dac                 ;4d71
        CP      54H                     ;4d73
        JR      Z,m4d85                 ;4d75
        CP      53H                     ;4d77
        JR      Z,m4db7                 ;4d79
        CP      48H                     ;4d7b
        JR      Z,m4dd2                 ;4d7d
        CP      4EH                     ;4d7f
        JR      Z,m4dc0                 ;4d81
        JR      m4d56                   ;4d83
m4d85   LD      DE,CHNTOG               ;4d85
        LD      (KBDDRV),DE             ;4d88
        JR      m4d5a                   ;4d8c
m4d8e   LD      DE,m4028                ;4d8e
m4d91   LD      (058FH),DE              ;4d91
        LD      DE,058DH                ;4d95
        LD      (PRTDRV),DE             ;4d98
        JR      m4d5a                   ;4d9c
m4d9e   LD      DE,2318H                ;4d9e
        JR      m4d91                   ;4da1
m4da3   LD      DE,m4505                ;4da3
        LD      (VIDDRV),DE             ;4da6
        JR      m4d5a                   ;4daa
m4dac   XOR     A                       ;4dac
        LD      (m4029),A               ;4dad
        LD      A,48H                   ;4db0
        LD      (m4028),A               ;4db2
        JR      m4d5a                   ;4db5
m4db7   XOR     A                       ;4db7
        LD      (VIDTOP),A              ;4db8
        LD      (VIDBOT),A              ;4dbb
        JR      m4d5a                   ;4dbe
m4dc0   LD      A,(HL)                  ;4dc0
        CP      50H                     ;4dc1
        LD      A,0C9H                  ;4dc3
        JR      Z,m4dcc                 ;4dc5
        LD      (m4de1),A               ;4dc7
        JR      m4d5a                   ;4dca
m4dcc   LD      (m4e82),A               ;4dcc
        INC     HL                      ;4dcf
        JR      m4d5a                   ;4dd0
m4dd2   LD      DE,0FFFFH               ;4dd2
        LD      (HIMEM),DE              ;4dd5
        JP      m4d5a                   ;4dd9
m4ddc   CALL    m4de1                   ;4ddc
        XOR     A                       ;4ddf
        RET                             ;4de0
m4de1   LD      DE,(KBDDRV)             ;4de1
        LD      HL,m5123                ;4de5
        CALL    HEXDE                   ;4de8
        LD      A,(KBDTYP)              ;4deb
        CALL    m4e92                   ;4dee
        LD      DE,(VIDDRV)             ;4df1
        LD      HL,m5152                ;4df5
        CALL    HEXDE                   ;4df8
        LD      A,(VIDTYP)              ;4dfb
        CALL    m4e92                   ;4dfe
        LD      DE,(PRTDRV)             ;4e01
        LD      HL,m5185                ;4e05
        CALL    HEXDE                   ;4e08
        LD      A,(PRTTYP)              ;4e0b
        CALL    m4e92                   ;4e0e
        LD      A,(m4029)               ;4e11
        LD      HL,m519a                ;4e14
        CALL    HEXA                    ;4e17
        LD      A,(m4028)               ;4e1a
        LD      HL,m51a2                ;4e1d
        CALL    HEXA                    ;4e20
        LD      A,(DMACH)               ;4e23
        AND     0FH                     ;4e26
        CP      02H                     ;4e28
        JR      Z,m4e32                 ;4e2a
        AND     0FEH                    ;4e2c
        CP      04H                     ;4e2e
        JR      NZ,m4e44                ;4e30
m4e32   LD      A,(VIDTOP)              ;4e32
        LD      HL,m5167                ;4e35
        CALL    HEXA                    ;4e38
        LD      A,(VIDBOT)              ;4e3b
        LD      HL,m5177                ;4e3e
        CALL    HEXA                    ;4e41
m4e44   LD      DE,(HIMEM)              ;4e44
        LD      HL,m5142                ;4e48
        CALL    HEXDE                   ;4e4b
        LD      A,1CH                   ;4e4e
        CALL    0033H                   ;4e50
        LD      HL,m5101                ;4e53
        LD      A,(1914H)               ;4e56
        CP      40H                     ;4e59
        JR      C,m4e60                 ;4e5b
        INC     HL                      ;4e5d
        JR      NZ,m4e64                ;4e5e
m4e60   XOR     A                       ;4e60
        LD      (m4ebb),A               ;4e61
m4e64   CALL    m4e9a                   ;4e64
        XOR     A                       ;4e67
m4e68   LD      HL,(VIDCUR)             ;4e68
        LD      DE,(m50f2)              ;4e6b
        ADD     HL,DE                   ;4e6f
        LD      B,40H                   ;4e70
m4e72   CALL    m4e8d                   ;4e72
        INC     HL                      ;4e75
        INC     A                       ;4e76
        DJNZ    m4e72                   ;4e77
        PUSH    AF                      ;4e79
        LD      A,0DH                   ;4e7a
        CALL    0033H                   ;4e7c
        POP     AF                      ;4e7f
        JR      NZ,m4e68                ;4e80
m4e82   LD      HL,m51b9                ;4e82
        CALL    m4e9a                   ;4e85
        CALL    m4ed5                   ;4e88
        XOR     A                       ;4e8b
        RET                             ;4e8c
m4e8d   LD      (HL),A                  ;4e8d
        RET                             ;4e8e
        JP      SCRPUT                  ;4e8f
m4e92   BIT     7,A                     ;4e92
        RET     NZ                      ;4e94
        INC     HL                      ;4e95
        INC     HL                      ;4e96
        LD      (HL),8DH                ;4e97
        RET                             ;4e99
m4e9a   LD      A,(HL)                  ;4e9a
        LD      B,01H                   ;4e9b
        BIT     7,A                     ;4e9d
        JR      Z,m4ea5                 ;4e9f
        AND     7FH                     ;4ea1
        LD      B,A                     ;4ea3
        INC     HL                      ;4ea4
m4ea5   LD      A,(HL)                  ;4ea5
        CP      03H                     ;4ea6
        RET     Z                       ;4ea8
        CP      40H                     ;4ea9
        JR      NZ,m4eb6                ;4eab
        PUSH    HL                      ;4ead
        LD      HL,m50f4                ;4eae
        CALL    DSPLY                   ;4eb1
        POP     HL                      ;4eb4
        XOR     A                       ;4eb5
m4eb6   CP      0BH                     ;4eb6
        JR      NZ,m4ebc                ;4eb8
        LD      A,0AH                   ;4eba
m4ebc   PUSH    AF                      ;4ebc
        CALL    0033H                   ;4ebd
        POP     AF                      ;4ec0
        CP      0DH                     ;4ec1
        RET     Z                       ;4ec3
        DJNZ    m4ea5                   ;4ec4
        INC     HL                      ;4ec6
        JR      m4e9a                   ;4ec7
m4ec9   RET                             ;4ec9
        OR      L                       ;4eca
        LD      B,0C9H                  ;4ecb
        CP      (HL)                    ;4ecd
        LD      B,3AH                   ;4ece
        INC     D                       ;4ed0
        ADD     HL,DE                   ;4ed1
        LD      (m4efa),A               ;4ed2
m4ed5   LD      C,00H                   ;4ed5
        JR      m4edc                   ;4ed7
m4ed9   INC     C                       ;4ed9
        JR      Z,m4f0f                 ;4eda
m4edc   CALL    m4ec9                   ;4edc
        IN      A,(C)                   ;4edf
        CALL    m4ecc                   ;4ee1
        CP      0FFH                    ;4ee4
        JR      Z,m4ed9                 ;4ee6
        LD      HL,m51d1                ;4ee8
        CALL    HEXA                    ;4eeb
        LD      HL,m51cd+1              ;4eee
        LD      A,C                     ;4ef1
        CALL    HEXA                    ;4ef2
        LD      A,00H                   ;4ef5
        ADD     A,07H                   ;4ef7
        CP      40H                     ;4ef9
        JR      C,m4f04                 ;4efb
        LD      A,0DH                   ;4efd
        CALL    0033H                   ;4eff
        LD      A,07H                   ;4f02
m4f04   LD      (m4ef6),A               ;4f04
        LD      HL,m51cd                ;4f07
        CALL    DSPLY                   ;4f0a
        JR      m4ed9                   ;4f0d
m4f0f   LD      A,(m4ef6)               ;4f0f
        OR      A                       ;4f12
        RET     Z                       ;4f13
        LD      A,0DH                   ;4f14
        CALL    0033H                   ;4f16
        XOR     A                       ;4f19
        RET                             ;4f1a
m4f1b   LD      A,20H                   ;4f1b
        OR      A                       ;4f1d
        RET                             ;4f1e
m4f1f   LD      A,39H                   ;4f1f
        OR      A                       ;4f21
        RET                             ;4f22
m4f23   LD      A,(DNDRV)               ;4f23
        LD      B,A                     ;4f26
        LD      A,(HL)                  ;4f27
        SUB     30H                     ;4f28
        JP      C,m4d56                 ;4f2a
        CALL    Z,m4f91                 ;4f2d
        JR      C,m4f1f                 ;4f30
        CP      0AH                     ;4f32
        JP      NC,m4d56                ;4f34
        CP      B                       ;4f37
        JR      NC,m4f1b                ;4f38
        PUSH    AF                      ;4f3a
        INC     HL                      ;4f3b
        LD      A,(HL)                  ;4f3c
        CP      3DH                     ;4f3d
        JR      NZ,m4f58                ;4f3f
        INC     HL                      ;4f41
        LD      C,(HL)                  ;4f42
        INC     HL                      ;4f43
        CALL    CHKCHR                  ;4f44
        JR      NZ,m4f58                ;4f47
        LD      HL,m4ff5                ;4f49
        LD      B,10H                   ;4f4c
m4f4e   LD      A,(HL)                  ;4f4e
        CP      C                       ;4f4f
        JR      Z,m4f5c                 ;4f50
        LD      DE,0010H                ;4f52
        ADD     HL,DE                   ;4f55
        DJNZ    m4f4e                   ;4f56
m4f58   POP     AF                      ;4f58
        JP      m4d56                   ;4f59
m4f5c   POP     AF                      ;4f5c
        LD      C,A                     ;4f5d
        ADD     A,A                     ;4f5e
        ADD     A,A                     ;4f5f
        ADD     A,C                     ;4f60
        ADD     A,A                     ;4f61
        PUSH    IX                      ;4f62
        PUSH    IY                      ;4f64
        LD      IX,PDRV0                ;4f66
        LD      C,A                     ;4f6a
        LD      B,00H                   ;4f6b
        ADD     IX,BC                   ;4f6d
        INC     HL                      ;4f6f
        INC     HL                      ;4f70
        PUSH    HL                      ;4f71
        POP     IY                      ;4f72
        LD      A,(IY+02H)              ;4f74
        AND     0FCH                    ;4f77
        LD      C,A                     ;4f79
        LD      A,(IX+02H)              ;4f7a
        AND     03H                     ;4f7d
        OR      C                       ;4f7f
        LD      (IY+02H),A              ;4f80
        LD      BC,000AH                ;4f83
        PUSH    IX                      ;4f86
        POP     DE                      ;4f88
        LDIR                            ;4f89
        POP     IY                      ;4f8b
        POP     IX                      ;4f8d
        XOR     A                       ;4f8f
        RET                             ;4f90
m4f91   LD      A,(m4be1)               ;4f91
        CP      0E6H                    ;4f94
        JR      Z,m4f9a                 ;4f96
        XOR     A                       ;4f98
        RET                             ;4f99
m4f9a   PUSH    HL                      ;4f9a
        LD      HL,m4faa                ;4f9b
        CALL    DSPLY                   ;4f9e
        POP     HL                      ;4fa1
        CALL    0049H                   ;4fa2
        SUB     0DH                     ;4fa5
        RET     Z                       ;4fa7
        SCF                             ;4fa8
        RET                             ;4fa9
m4faa   RLCA                            ;4faa
        LD      B,D                     ;4fab
        LD      L,C                     ;4fac
        LD      (HL),H                  ;4fad
        LD      (HL),H                  ;4fae
        LD      H,L                     ;4faf
        JR      NZ,m5005                ;4fb0
        LD      A,C                     ;4fb2
        LD      (HL),E                  ;4fb3
        LD      (HL),H                  ;4fb4
        LD      H,L                     ;4fb5
        LD      L,L                     ;4fb6
        LD      H,H                     ;4fb7
        LD      L,C                     ;4fb8
        LD      (HL),E                  ;4fb9
        LD      L,E                     ;4fba
        LD      H,L                     ;4fbb
        LD      (HL),H                  ;4fbc
        LD      (HL),H                  ;4fbd
        LD      H,L                     ;4fbe
        JR      NZ,$+121                ;4fbf
        LD      H,L                     ;4fc1
        LD      H,E                     ;4fc2
        LD      L,B                     ;4fc3
        LD      (HL),E                  ;4fc4
        LD      H,L                     ;4fc5
        LD      L,H                     ;4fc6
        LD      L,(HL)                  ;4fc7
        LD      A,(BC)                  ;4fc8
        DAA                             ;4fc9
        LD      B,L                     ;4fca
        LD      C,(HL)                  ;4fcb
        LD      D,H                     ;4fcc
        LD      B,L                     ;4fcd
        LD      D,D                     ;4fce
        DAA                             ;4fcf
        JR      NZ,m5041                ;4fd0
        LD      H,H                     ;4fd2
        LD      H,L                     ;4fd3
        LD      (HL),D                  ;4fd4
        JR      NZ,$+67                 ;4fd5
        LD      H,D                     ;4fd7
        LD      H,D                     ;4fd8
        LD      (HL),D                  ;4fd9
        LD      (HL),L                  ;4fda
        LD      H,E                     ;4fdb
        LD      L,B                     ;4fdc
        JR      NZ,m5041                ;4fdd
        LD      H,L                     ;4fdf
        LD      L,H                     ;4fe0
        LD      L,C                     ;4fe1
        LD      H,L                     ;4fe2
        LD      H,D                     ;4fe3
        LD      L,C                     ;4fe4
        LD      H,A                     ;4fe5
        LD      H,L                     ;4fe6
        LD      (HL),D                  ;4fe7
        JR      NZ,m503e                ;4fe8
        LD      H,C                     ;4fea
        LD      (HL),E                  ;4feb
        LD      (HL),H                  ;4fec
        LD      H,L                     ;4fed
        DEC     C                       ;4fee
        NOP                             ;4fef
        NOP                             ;4ff0
        LD      B,H                     ;4ff1
        LD      C,C                     ;4ff2
        LD      D,E                     ;4ff3
        LD      C,E                     ;4ff4
m4ff5   LD      B,C                     ;4ff5
        LD      A,(2814H)               ;4ff6
        RLCA                            ;4ff9
        JR      Z,m5006                 ;4ffa
        LD      (BC),A                  ;4ffc
        NOP                             ;4ffd
        NOP                             ;4ffe
        INC     D                       ;4fff
        LD      (BC),A                  ;5000
        LD      B,H                     ;5001
        LD      C,C                     ;5002
        LD      D,E                     ;5003
        LD      C,E                     ;5004
m5005   LD      B,D                     ;5005
m5006   LD      A,(2814H)               ;5006
        RLCA                            ;5009
        JR      Z,$+22                  ;500a
        INC     B                       ;500c
        NOP                             ;500d
        LD      B,B                     ;500e
        INC     D                       ;500f
        LD      (BC),A                  ;5010
        LD      B,H                     ;5011
        LD      C,C                     ;5012
        LD      D,E                     ;5013
        LD      C,E                     ;5014
        LD      B,E                     ;5015
        LD      A,(3018H)               ;5016
        LD      D,E                     ;5019
        JR      Z,m502e                 ;501a
        INC     BC                      ;501c
        NOP                             ;501d
        INC     BC                      ;501e
        JR      m5023                   ;501f
        LD      B,H                     ;5021
        LD      C,C                     ;5022
m5023   LD      D,E                     ;5023
        LD      C,E                     ;5024
        LD      B,H                     ;5025
        LD      A,(3018H)               ;5026
        LD      D,E                     ;5029
        JR      Z,m5050                 ;502a
        LD      B,00H                   ;502c
m502e   LD      B,E                     ;502e
        JR      m5033                   ;502f
        LD      B,H                     ;5031
        LD      C,C                     ;5032
m5033   LD      D,E                     ;5033
        LD      C,E                     ;5034
        LD      B,L                     ;5035
        LD      A,(2814H)               ;5036
        RLCA                            ;5039
        JR      Z,m5046                 ;503a
        LD      (BC),A                  ;503c
        NOP                             ;503d
m503e   INC     B                       ;503e
        INC     D                       ;503f
        LD      (BC),A                  ;5040
m5041   LD      B,H                     ;5041
        LD      C,C                     ;5042
        LD      D,E                     ;5043
        LD      C,E                     ;5044
        LD      B,(HL)                  ;5045
m5046   LD      A,(2814H)               ;5046
        RLCA                            ;5049
        JR      Z,$+22                  ;504a
        INC     B                       ;504c
        NOP                             ;504d
        LD      B,H                     ;504e
        INC     D                       ;504f
m5050   LD      (BC),A                  ;5050
        LD      B,H                     ;5051
        LD      C,C                     ;5052
        LD      D,E                     ;5053
        LD      C,E                     ;5054
        LD      B,A                     ;5055
        LD      A,(3018H)               ;5056
        LD      D,E                     ;5059
        JR      Z,m506e                 ;505a
        INC     BC                      ;505c
        NOP                             ;505d
        RLCA                            ;505e
        JR      m5063                   ;505f
        LD      B,H                     ;5061
        LD      C,C                     ;5062
m5063   LD      D,E                     ;5063
        LD      C,E                     ;5064
        LD      C,B                     ;5065
        LD      A,(3018H)               ;5066
        LD      D,E                     ;5069
        JR      Z,$+38                  ;506a
        LD      B,00H                   ;506c
m506e   LD      B,L                     ;506e
        JR      m5073                   ;506f
        LD      B,H                     ;5071
        LD      C,C                     ;5072
m5073   LD      D,E                     ;5073
        LD      C,E                     ;5074
        LD      C,C                     ;5075
        LD      A,(m5028)               ;5076
        RLCA                            ;5079
        LD      D,B                     ;507a
        LD      A,(BC)                  ;507b
        LD      (BC),A                  ;507c
        NOP                             ;507d
        NOP                             ;507e
        JR      Z,m5083                 ;507f
        LD      B,H                     ;5081
        LD      C,C                     ;5082
m5083   LD      D,E                     ;5083
        LD      C,E                     ;5084
        LD      C,D                     ;5085
        LD      A,(m5028)               ;5086
        RLCA                            ;5089
        LD      D,B                     ;508a
        INC     D                       ;508b
        INC     B                       ;508c
        NOP                             ;508d
        LD      B,B                     ;508e
        JR      Z,m5095                 ;508f
        LD      B,H                     ;5091
        LD      C,C                     ;5092
        LD      D,E                     ;5093
        LD      C,E                     ;5094
m5095   LD      C,E                     ;5095
        LD      A,(6030H)               ;5096
        LD      D,E                     ;5099
        LD      D,B                     ;509a
        LD      (DE),A                  ;509b
        INC     BC                      ;509c
        NOP                             ;509d
        INC     BC                      ;509e
        JR      NC,m50a4                ;509f
        LD      B,H                     ;50a1
        LD      C,C                     ;50a2
        LD      D,E                     ;50a3
m50a4   LD      C,E                     ;50a4
        LD      C,H                     ;50a5
        LD      A,(6030H)               ;50a6
        LD      D,E                     ;50a9
        LD      D,B                     ;50aa
        INC     H                       ;50ab
        LD      B,00H                   ;50ac
        LD      B,E                     ;50ae
m50af   JR      NC,$+8                  ;50af
        LD      B,H                     ;50b1
        LD      C,C                     ;50b2
        LD      D,E                     ;50b3
        LD      C,E                     ;50b4
        LD      C,L                     ;50b5
        LD      A,(m4811)               ;50b6
        INC     DE                      ;50b9
        JR      Z,m50ce                 ;50ba
        LD      (BC),A                  ;50bc
        NOP                             ;50bd
        DEC     B                       ;50be
        LD      DE,m4402                ;50bf
        LD      C,C                     ;50c2
        LD      D,E                     ;50c3
        LD      C,E                     ;50c4
        LD      C,(HL)                  ;50c5
        LD      A,(9011H)               ;50c6
        LD      D,E                     ;50c9
        LD      D,B                     ;50ca
        LD      (DE),A                  ;50cb
        LD      (BC),A                  ;50cc
        NOP                             ;50cd
m50ce   INC     BC                      ;50ce
        LD      DE,m4402                ;50cf
        LD      C,C                     ;50d2
        LD      D,E                     ;50d3
        LD      C,E                     ;50d4
        LD      C,A                     ;50d5
        LD      A,(2811H)               ;50d6
        INC     DE                      ;50d9
        JR      Z,m50e6                 ;50da
        LD      (BC),A                  ;50dc
        NOP                             ;50dd
        INC     B                       ;50de
        LD      DE,m4402                ;50df
        LD      C,C                     ;50e2
        LD      D,E                     ;50e3
        LD      C,E                     ;50e4
        LD      D,B                     ;50e5
m50e6   LD      A,(m4a11)               ;50e6
        LD      D,B                     ;50e9
        LD      D,D                     ;50ea
        LD      (DE),A                  ;50eb
        INC     B                       ;50ec
        NOP                             ;50ed
        INC     BC                      ;50ee
        LD      DE,0006H                ;50ef
m50f2   NOP                             ;50f2
        NOP                             ;50f3
m50f4   JR      Z,m516b                 ;50f4
        LD      L,L                     ;50f6
        LD      H,A                     ;50f7
        LD      H,L                     ;50f8
        LD      L,H                     ;50f9
        LD      H,L                     ;50fa
        LD      L,C                     ;50fb
        LD      (HL),H                  ;50fc
        LD      H,L                     ;50fd
        LD      (HL),H                  ;50fe
        ADD     HL,HL                   ;50ff
        INC     BC                      ;5100
m5101   DJNZ    m511f                   ;5101
        RRA                             ;5103
        SBC     A,B                     ;5104
        DEC     L                       ;5105
        JR      NZ,m514f                ;5106
        LD      B,L                     ;5108
        LD      C,(HL)                  ;5109
        LD      C,C                     ;510a
        LD      B,L                     ;510b
        DEC     L                       ;510c
        LD      B,H                     ;510d
        LD      C,A                     ;510e
        LD      D,E                     ;510f
        JR      NZ,m515b                ;5110
        LD      C,(HL)                  ;5112
        LD      B,(HL)                  ;5113
        LD      C,A                     ;5114
        JR      NZ,m50af                ;5115
        DEC     L                       ;5117
        DEC     BC                      ;5118
        LD      D,H                     ;5119
        LD      H,C                     ;511a
        LD      (HL),E                  ;511b
        LD      (HL),H                  ;511c
        LD      H,C                     ;511d
        LD      (HL),H                  ;511e
m511f   LD      (HL),L                  ;511f
        LD      (HL),D                  ;5120
        LD      A,(m4620)               ;5121
        LD      B,(HL)                  ;5124
        LD      B,(HL)                  ;5125
        LD      B,(HL)                  ;5126
        LD      C,B                     ;5127
        JR      NZ,m516a                ;5128
        JR      NZ,m514c                ;512a
        LD      D,E                     ;512c
        LD      (HL),B                  ;512d
        LD      H,L                     ;512e
        LD      L,C                     ;512f
        LD      H,E                     ;5130
        LD      L,B                     ;5131
        LD      H,L                     ;5132
        LD      (HL),D                  ;5133
        LD      H,L                     ;5134
        LD      L,(HL)                  ;5135
        LD      H,H                     ;5136
        LD      H,L                     ;5137
        JR      NZ,m5162                ;5138
        LD      C,B                     ;513a
        LD      C,C                     ;513b
        LD      C,L                     ;513c
        LD      B,L                     ;513d
        LD      C,L                     ;513e
        ADD     HL,HL                   ;513f
        LD      A,(m4620)               ;5140
        LD      B,(HL)                  ;5143
        LD      B,(HL)                  ;5144
        LD      B,(HL)                  ;5145
        LD      C,B                     ;5146
        LD      A,(BC)                  ;5147
        LD      C,L                     ;5148
        LD      L,A                     ;5149
        LD      L,(HL)                  ;514a
        LD      L,C                     ;514b
m514c   LD      (HL),H                  ;514c
        LD      L,A                     ;514d
        LD      (HL),D                  ;514e
m514f   LD      A,(2020H)               ;514f
m5152   LD      B,(HL)                  ;5152
        LD      B,(HL)                  ;5153
        LD      B,(HL)                  ;5154
        LD      B,(HL)                  ;5155
        LD      C,B                     ;5156
        JR      NZ,$+66                 ;5157
        JR      NZ,m517b                ;5159
m515b   LD      C,E                     ;515b
        LD      L,A                     ;515c
        LD      (HL),B                  ;515d
        LD      H,(HL)                  ;515e
        LD      A,D                     ;515f
        LD      H,L                     ;5160
        LD      L,C                     ;5161
m5162   LD      L,H                     ;5162
m5163   LD      H,L                     ;5163
        LD      L,(HL)                  ;5164
        LD      A,(3020H)               ;5165
        JR      NC,m51b2                ;5168
m516a   INC     L                       ;516a
m516b   JR      NZ,m51b3                ;516b
        LD      (HL),L                  ;516d
        LD      A,(HL)                  ;516e
        LD      A,D                     ;516f
        LD      H,L                     ;5170
        LD      L,C                     ;5171
        LD      L,H                     ;5172
        LD      H,L                     ;5173
        LD      L,(HL)                  ;5174
        LD      A,(3020H)               ;5175
        JR      NC,m51c2                ;5178
        LD      A,(BC)                  ;517a
m517b   LD      B,H                     ;517b
        LD      (HL),D                  ;517c
        LD      (HL),L                  ;517d
        LD      H,E                     ;517e
        LD      L,E                     ;517f
        LD      H,L                     ;5180
        LD      (HL),D                  ;5181
        LD      A,(2020H)               ;5182
m5185   LD      B,(HL)                  ;5185
        LD      B,(HL)                  ;5186
        LD      B,(HL)                  ;5187
        LD      B,(HL)                  ;5188
        LD      C,B                     ;5189
        JR      NZ,m51cc                ;518a
        JR      NZ,m51ae                ;518c
        LD      B,H                     ;518e
        LD      (HL),D                  ;518f
        LD      (HL),L                  ;5190
        LD      H,E                     ;5191
        LD      L,E                     ;5192
        LD      A,D                     ;5193
        LD      H,L                     ;5194
        LD      L,C                     ;5195
        LD      L,H                     ;5196
        LD      H,L                     ;5197
        LD      A,(3020H)               ;5198
        JR      NC,m51e5                ;519b
        JR      NZ,$+120                ;519d
        LD      L,A                     ;519f
        LD      L,(HL)                  ;51a0
        JR      NZ,m51d3                ;51a1
        JR      NC,$+74                 ;51a3
        LD      A,(BC)                  ;51a5
        SBC     A,C                     ;51a6
        DEC     L                       ;51a7
        JR      NZ,$+92                 ;51a8
        LD      B,L                     ;51aa
        LD      C,C                     ;51ab
        LD      B,E                     ;51ac
        LD      C,B                     ;51ad
m51ae   LD      B,L                     ;51ae
        LD      C,(HL)                  ;51af
        LD      D,E                     ;51b0
        LD      B,C                     ;51b1
m51b2   LD      D,H                     ;51b2
m51b3   LD      E,D                     ;51b3
        JR      NZ,$-100                ;51b4
        DEC     L                       ;51b6
        DEC     BC                      ;51b7
        INC     BC                      ;51b8
m51b9   SBC     A,C                     ;51b9
        DEC     L                       ;51ba
        JR      NZ,$+67                 ;51bb
        LD      C,E                     ;51bd
        LD      D,H                     ;51be
        LD      C,C                     ;51bf
        LD      D,(HL)                  ;51c0
        LD      B,L                     ;51c1
m51c2   JR      NZ,$+82                 ;51c2
        LD      C,A                     ;51c4
        LD      D,D                     ;51c5
        LD      D,H                     ;51c6
        LD      D,E                     ;51c7
        JR      NZ,m5163                ;51c8
        DEC     L                       ;51ca
        DEC     BC                      ;51cb
m51cc   INC     BC                      ;51cc
m51cd   JR      NZ,$+50                 ;51cd
        JR      NC,$+63                 ;51cf
m51d1   JR      NC,$+50                 ;51d1
m51d3   JR      NZ,m51d8                ;51d3
        NOP                             ;51d5
        NOP                             ;51d6
        NOP                             ;51d7
m51d8   NOP                             ;51d8
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
m51e5   NOP                             ;51e5
        NOP                             ;51e6
        NOP                             ;51e7
        NOP                             ;51e8
        NOP                             ;51e9
        END     4d00h
