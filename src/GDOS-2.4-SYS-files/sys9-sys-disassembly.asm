;************************************************************************
;
; SYS9/SYS from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys9-sys-disassembly.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
; SYS9/SYS, stock GDOS 2.4. Loads contiguously into 4D00h-51DFh, entry
; 4D00h. Grosser ch.7 gives the same extent: "SYS9/SYS -- EOF 4/248,
; RAM 4D00-51DF, Start 4D00".
;
;   z80dasm -g 0x4d00 -l -a -t sys9_flat.bin
;
; SYS9 carries the commands dispatched with A-EBh: B2, *CONT, *DO, M>,
; PAUSE, STMT and BOOT. The request code arrives in A and the sub-function
; in C, which a DEC C chain walks; ten decrements for C-0Ah lands on BOOT
; at 4DC6h. See docs/reference/GDOS-Genie-IIIs-command-table.md.
;
m37e1   EQU     37e1h
m3840   EQU     3840h
m4000   EQU     4000h
DOSRDY  EQU     402dh		;return to the DOS prompt
ERRORO  EQU     4030h		;DOS error output
m4051   EQU     4051h
DMODUL  EQU     4317h		;current /SYS module
DFLAG0  EQU     4369h		;DOS flags: DEBUG, CHAINING, BREAK key, RUN-ONLY (Grosser ch.3)
DFLAG4  EQU     436dh		;further DOS flags
m4380   EQU     4380h
m43a5   EQU     43a5h
m43e0   EQU     43e0h
m43e1   EQU     43e1h
m43e3   EQU     43e3h
m43e5   EQU     43e5h
m43e9   EQU     43e9h
DOSERR  EQU     4409h		;DOS error exit
m4428   EQU     4428h
READ    EQU     4436h		;read a sector
WRITE   EQU     4439h		;write a sector
m443f   EQU     443fh
m4445   EQU     4445h
DSPLY   EQU     4467h		;display the text at (HL)
USRFCB  EQU     4480h		;FCB for loading and starting user programs
m4483   EQU     4483h
m4488   EQU     4488h
m448c   EQU     448ch
UPCASE  EQU     45b5h		;convert lower case to upper case
SYSLD   EQU     49d3h		;load a SYS file; exits on error
m49dd   EQU     49ddh
CHKCHR  EQU     4cd5h		;test the character at (HL)
m4fab   EQU     4fabh		;operand byte inside this module -- self-modified code
m4fbb   EQU     4fbbh		;operand byte inside this module -- self-modified code
m513a   EQU     513ah		;operand byte inside this module -- self-modified code
m51e0   EQU     51e0h
m51e8   EQU     51e8h
m51ea   EQU     51eah
m51ec   EQU     51ech
        ORG     4d00h
        LD      IY,m4380                ;4d00
        CP      2BH                     ;4d04
        JP      Z,m5067                 ;4d06
        CP      4BH                     ;4d09
        JP      Z,m507e                 ;4d0b
        CP      0CBH                    ;4d0e
        JP      Z,m4e2b                 ;4d10
        CP      0EBH                    ;4d13
        JR      NZ,m4d42                ;4d15
        DEC     C                       ;4d17
        JP      Z,m4de2                 ;4d18
        DEC     C                       ;4d1b
        JP      Z,m4fe0                 ;4d1c
        DEC     C                       ;4d1f
        JP      Z,m4de5                 ;4d20
        DEC     C                       ;4d23
        JP      Z,m4eeb                 ;4d24
        DEC     C                       ;4d27
        JR      Z,m4d72                 ;4d28
        DEC     C                       ;4d2a
        JP      Z,m5051                 ;4d2b
        DEC     C                       ;4d2e
        JP      Z,m508f                 ;4d2f
        DEC     C                       ;4d32
        JR      Z,m4d52                 ;4d33
        DEC     C                       ;4d35
        JR      Z,m4d63                 ;4d36
        DEC     C                       ;4d38
        JP      Z,m4dc6                 ;4d39
        DEC     C                       ;4d3c
        JR      Z,m4dac                 ;4d3d
        DEC     C                       ;4d3f
        JR      Z,m4db1                 ;4d40
m4d42   LD      A,2AH                   ;4d42
        JR      m4d4e                   ;4d44
m4d46   LD      A,33H                   ;4d46
        PUSH    AF                      ;4d48
        LD      A,46H                   ;4d49
        RST     28H                     ;4d4b
m4d4c   LD      A,2FH                   ;4d4c
m4d4e   OR      A                       ;4d4e
        JP      DOSERR                  ;4d4f
m4d52   CALL    m4d63                   ;4d52
        LD      HL,m4fbb                ;4d55
        CALL    DSPLY                   ;4d58
m4d5b   CALL    0049H                   ;4d5b
        SUB     0DH                     ;4d5e
        JR      NZ,m4d5b                ;4d60
        RET                             ;4d62
m4d63   LD      BC,(DFLAG0)             ;4d63
        BIT     6,B                     ;4d67
        JR      Z,m4d70                 ;4d69
        BIT     5,C                     ;4d6b
        CALL    Z,DSPLY                 ;4d6d
m4d70   XOR     A                       ;4d70
        RET                             ;4d71
m4d72   LD      A,(m43e0)               ;4d72
        RLCA                            ;4d75
        LD      A,26H                   ;4d76
        JR      NC,m4d4e                ;4d78
        CALL    m4d82                   ;4d7a
        RET     Z                       ;4d7d
        LD      A,34H                   ;4d7e
        JR      m4d4e                   ;4d80
m4d82   LD      BC,(DFLAG0)             ;4d82
        RES     5,C                     ;4d86
        RES     4,B                     ;4d88
        LD      A,(HL)                  ;4d8a
        CALL    UPCASE                  ;4d8b
        CP      4EH                     ;4d8e
        JR      Z,m4da1                 ;4d90
        SET     5,C                     ;4d92
        CP      4AH                     ;4d94
        JR      Z,m4da1                 ;4d96
        CP      44H                     ;4d98
        RET     NZ                      ;4d9a
        BIT     6,B                     ;4d9b
        JR      Z,m4da1                 ;4d9d
        SET     4,B                     ;4d9f
m4da1   INC     HL                      ;4da1
        LD      A,(HL)                  ;4da2
        CP      0DH                     ;4da3
        RET     NZ                      ;4da5
        LD      (DFLAG0),BC             ;4da6
        XOR     A                       ;4daa
        RET                             ;4dab
m4dac   LD      HL,m5113                ;4dac
        JR      m4db4                   ;4daf
m4db1   LD      HL,m5100                ;4db1
m4db4   CALL    DSPLY                   ;4db4
        LD      HL,m5123                ;4db7
        CALL    DSPLY                   ;4dba
m4dbd   CALL    0049H                   ;4dbd
        RES     5,A                     ;4dc0
        CP      52H                     ;4dc2
        JR      NZ,m4dbd                ;4dc4
; ------------------------------------------------------------
; [note]      4DC6h: BOOT command. Reached from DEC C chain at
;             C=0Ah, not through the 'R' prompt (4DBDh, C=0Bh/0Ch).
;             37E1h deselects every floppy drive, only when System
;             Byte 1 bit 0 is low (prompt: C5h, so this write lands
;             in plain RAM). 0060h delay uses B; C is whatever the
;             caller left -- delay length is incidental. Hangs
;             under CalvaDOS -- docs/development/known-issues.md.
; ------------------------------------------------------------
m4dc6   XOR     A                       ;4dc6
        LD      (m37e1),A               ;4dc7
        LD      B,02H                   ;4dca
        JP      m51d3                   ;4dcc
        HALT                            ;4dcf
m4dd0   EXX                             ;4dd0
        LD      BC,0EB01H               ;4dd1
        LD      DE,SYSLD                ;4dd4
        PUSH    BC                      ;4dd7
        PUSH    DE                      ;4dd8
        EXX                             ;4dd9
        OR      A                       ;4dda
        JP      NZ,m49dd                ;4ddb
        EXX                             ;4dde
        PUSH    HL                      ;4ddf
        EXX                             ;4de0
        RET                             ;4de1
m4de2   EX      (SP),HL                 ;4de2
        POP     HL                      ;4de3
        RET                             ;4de4
m4de5   EX      DE,HL                   ;4de5
        LD      DE,m43e0                ;4de6
        LD      BC,0020H                ;4de9
        LDIR                            ;4dec
        LD      HL,m5000                ;4dee
        LD      (m43e3),HL              ;4df1
        POP     AF                      ;4df4
        POP     HL                      ;4df5
        CALL    CHKCHR                  ;4df6
        RET     C                       ;4df9
        CALL    NZ,m4e0f                ;4dfa
        RET     NZ                      ;4dfd
        LD      HL,DFLAG0               ;4dfe
        SET     5,(HL)                  ;4e01
        INC     HL                      ;4e03
        BIT     6,(HL)                  ;4e04
        JR      Z,m4e0a                 ;4e06
        SET     4,(HL)                  ;4e08
m4e0a   XOR     A                       ;4e0a
        LD      (m43a5),A               ;4e0b
        RET                             ;4e0e
m4e0f   LD      B,H                     ;4e0f
        LD      C,L                     ;4e10
m4e11   LD      H,B                     ;4e11
        LD      L,C                     ;4e12
m4e13   CALL    m4f59                   ;4e13
        RET     NZ                      ;4e16
        CP      80H                     ;4e17
        JR      NZ,m4e13                ;4e19
m4e1b   CALL    m4f59                   ;4e1b
        RET     NZ                      ;4e1e
        CALL    UPCASE                  ;4e1f
        CP      (HL)                    ;4e22
        INC     HL                      ;4e23
        JR      NZ,m4e11                ;4e24
        CP      0DH                     ;4e26
        JR      NZ,m4e1b                ;4e28
        RET                             ;4e2a
m4e2b   LD      A,0AH                   ;4e2b
        LD      A,18H                   ;4e2d
        LD      (m4e2b),A               ;4e2f
        LD      HL,m43e1                ;4e32
        SET     5,(HL)                  ;4e35
        LD      A,(DFLAG4)              ;4e37
        BIT     7,A                     ;4e3a
        JR      NZ,m4e60                ;4e3c
        LD      B,0AH                   ;4e3e
        LD      HL,0FFFFH               ;4e40
        ADD     HL,SP                   ;4e43
m4e44   DEC     B                       ;4e44
        JR      Z,m4e84                 ;4e45
        INC     HL                      ;4e47
        LD      A,(HL)                  ;4e48
        CP      0DDH                    ;4e49
        INC     HL                      ;4e4b
        JR      NZ,m4e44                ;4e4c
        LD      A,(HL)                  ;4e4e
        CP      03H                     ;4e4f
        JR      NZ,m4e44                ;4e51
        LD      DE,000CH                ;4e53
        ADD     HL,DE                   ;4e56
        LD      A,(HL)                  ;4e57
        CP      05H                     ;4e58
        DEC     HL                      ;4e5a
        RET     NZ                      ;4e5b
        LD      A,(HL)                  ;4e5c
        CP      0E3H                    ;4e5d
        RET     NZ                      ;4e5f
m4e60   LD      A,(DFLAG4)              ;4e60
        AND     40H                     ;4e63
        JR      Z,m4e6f                 ;4e65
        LD      A,(m3840)               ;4e67
        AND     40H                     ;4e6a
        JP      NZ,m4f0c                ;4e6c
m4e6f   CALL    m4edc                   ;4e6f
        LD      A,(m43a5)               ;4e72
        OR      A                       ;4e75
        JR      NZ,m4e99                ;4e76
        CALL    m4f59                   ;4e78
        JR      Z,m4e99                 ;4e7b
        CP      1CH                     ;4e7d
        JR      NZ,m4ee9                ;4e7f
m4e81   CALL    m4ece                   ;4e81
m4e84   OR      01H                     ;4e84
        RET                             ;4e86
m4e87   CALL    m4d82                   ;4e87
        JP      NZ,m4f37                ;4e8a
        LD      A,(m43a5)               ;4e8d
        CALL    m513a                   ;4e90
        BIT     5,C                     ;4e93
        JR      Z,m4e84                 ;4e95
        JR      m4e60                   ;4e97
m4e99   LD      B,A                     ;4e99
        LD      C,A                     ;4e9a
        XOR     A                       ;4e9b
        LD      (m43a5),A               ;4e9c
        LD      A,B                     ;4e9f
        SUB     80H                     ;4ea0
        JR      Z,m4e81                 ;4ea2
        CP      04H                     ;4ea4
        JR      C,m4ef7                 ;4ea6
        CP      06H                     ;4ea8
        JP      C,m4f24                 ;4eaa
        CALL    m4f59                   ;4ead
        LD      (m43a5),A               ;4eb0
        JR      NZ,m4eb9                ;4eb3
        CP      80H                     ;4eb5
        JR      m4ebd                   ;4eb7
m4eb9   CP      1CH                     ;4eb9
        JR      NZ,m4ee9                ;4ebb
m4ebd   CALL    Z,m4ece                 ;4ebd
        CP      85H                     ;4ec0
        JP      Z,m4f1f                 ;4ec2
        LD      A,B                     ;4ec5
        CP      A                       ;4ec6
        RET                             ;4ec7
m4ec8   LD      HL,m4fab                ;4ec8
        CALL    m4f4e                   ;4ecb
m4ece   LD      HL,m43e0                ;4ece
        LD      (HL),00H                ;4ed1
        LD      HL,DFLAG0               ;4ed3
        RES     5,(HL)                  ;4ed6
        INC     HL                      ;4ed8
        RES     4,(HL)                  ;4ed9
        RET                             ;4edb
m4edc   LD      A,(m3840)               ;4edc
        AND     08H                     ;4edf
        RET     Z                       ;4ee1
        LD      A,(DFLAG4)              ;4ee2
        AND     40H                     ;4ee5
        RET     Z                       ;4ee7
        XOR     A                       ;4ee8
m4ee9   PUSH    AF                      ;4ee9
        PUSH    AF                      ;4eea
m4eeb   CALL    m4ec8                   ;4eeb
        POP     AF                      ;4eee
        POP     AF                      ;4eef
        OR      A                       ;4ef0
        JP      Z,ERRORO                ;4ef1
        JP      DOSERR                  ;4ef4
m4ef7   CALL    m4f59                   ;4ef7
        JR      NZ,m4ee9                ;4efa
        PUSH    AF                      ;4efc
        BIT     0,B                     ;4efd
        CALL    NZ,0033H                ;4eff
        POP     AF                      ;4f02
        CP      0DH                     ;4f03
        JR      NZ,m4ef7                ;4f05
        LD      A,B                     ;4f07
        CP      81H                     ;4f08
        JR      NZ,m4f1c                ;4f0a
m4f0c   LD      HL,m4fb3                ;4f0c
        CALL    m4f4e                   ;4f0f
m4f12   CALL    m4edc                   ;4f12
        LD      A,(m3840)               ;4f15
        AND     01H                     ;4f18
        JR      Z,m4f12                 ;4f1a
m4f1c   JP      m4e60                   ;4f1c
m4f1f   LD      C,A                     ;4f1f
        LD      A,B                     ;4f20
        LD      (m43a5),A               ;4f21
m4f24   LD      B,20H                   ;4f24
        LD      HL,m4fe0                ;4f26
        PUSH    HL                      ;4f29
m4f2a   CALL    m4f59                   ;4f2a
        JR      NZ,m4ee9                ;4f2d
        CP      0DH                     ;4f2f
        LD      (HL),A                  ;4f31
        INC     HL                      ;4f32
        JR      Z,m4f3b                 ;4f33
        DJNZ    m4f2a                   ;4f35
m4f37   LD      A,01H                   ;4f37
        JR      m4ee9                   ;4f39
m4f3b   POP     HL                      ;4f3b
        BIT     0,C                     ;4f3c
        JP      NZ,m4e87                ;4f3e
        LD      DE,m43e0                ;4f41
        CALL    m443f                   ;4f44
        CALL    Z,m4e0f                 ;4f47
        JR      NZ,m4ee9                ;4f4a
        JR      m4f1c                   ;4f4c
m4f4e   PUSH    HL                      ;4f4e
        LD      HL,m4fa1                ;4f4f
        CALL    DSPLY                   ;4f52
        POP     HL                      ;4f55
        JP      DSPLY                   ;4f56
m4f59   CALL    m4f95                   ;4f59
        RET     NZ                      ;4f5c
        PUSH    BC                      ;4f5d
        CP      2FH                     ;4f5e
        LD      B,A                     ;4f60
        LD      A,(m43e5)               ;4f61
        LD      C,A                     ;4f64
        CALL    Z,m4f95                 ;4f65
        JR      NZ,m4f7f                ;4f68
        CP      2EH                     ;4f6a
        CALL    Z,m4f95                 ;4f6c
        JR      NZ,m4f7f                ;4f6f
        CP      B                       ;4f71
        CALL    Z,m4f95                 ;4f72
        JR      NZ,m4f7f                ;4f75
        SUB     30H                     ;4f77
        CP      06H                     ;4f79
        SET     7,A                     ;4f7b
        JR      C,m4f92                 ;4f7d
m4f7f   LD      A,(m43e5)               ;4f7f
        SUB     C                       ;4f82
        LD      (m43e9),A               ;4f83
        CALL    NZ,m4445                ;4f86
        JR      NZ,m4f93                ;4f89
        LD      A,B                     ;4f8b
        CP      86H                     ;4f8c
        JR      C,m4f92                 ;4f8e
        AND     7FH                     ;4f90
m4f92   CP      A                       ;4f92
m4f93   POP     BC                      ;4f93
        RET                             ;4f94
m4f95   LD      DE,m43e0                ;4f95
        CALL    0013H                   ;4f98
        RET     NZ                      ;4f9b
        OR      A                       ;4f9c
        JR      Z,m4f95                 ;4f9d
        CP      A                       ;4f9f
        RET                             ;4fa0
m4fa1   LD      C,D                     ;4fa1
        LD      L,A                     ;4fa2
        LD      H,D                     ;4fa3
        JR      NZ,m500e                ;4fa4
        LD      H,C                     ;4fa6
        LD      (HL),H                  ;4fa7
        JR      NZ,m4fad                ;4fa8
        JR      NZ,$+67                 ;4faa
        LD      H,D                     ;4fac
m4fad   LD      H,D                     ;4fad
        LD      (HL),D                  ;4fae
        LD      (HL),L                  ;4faf
        LD      H,E                     ;4fb0
        LD      L,B                     ;4fb1
        DEC     C                       ;4fb2
m4fb3   LD      D,B                     ;4fb3
        LD      H,C                     ;4fb4
        LD      (HL),L                  ;4fb5
        LD      (HL),E                  ;4fb6
        LD      H,L                     ;4fb7
        LD      L,20H                   ;4fb8
        JR      NZ,m5010                ;4fba
        LD      H,C                     ;4fbc
        LD      (HL),E                  ;4fbd
        LD      (HL),H                  ;4fbe
        LD      H,L                     ;4fbf
        JR      NZ,m4fe9                ;4fc0
        LD      B,L                     ;4fc2
        LD      C,(HL)                  ;4fc3
        LD      D,H                     ;4fc4
        LD      B,L                     ;4fc5
        LD      D,D                     ;4fc6
        DAA                             ;4fc7
        JR      NZ,m5041                ;4fc8
        LD      H,L                     ;4fca
        LD      L,(HL)                  ;4fcb
        LD      L,(HL)                  ;4fcc
        JR      NZ,m5035                ;4fcd
        LD      L,A                     ;4fcf
        LD      (HL),D                  ;4fd0
        LD      (HL),H                  ;4fd1
        LD      H,(HL)                  ;4fd2
        LD      H,C                     ;4fd3
        LD      L,B                     ;4fd4
        LD      (HL),D                  ;4fd5
        LD      H,D                     ;4fd6
        LD      H,L                     ;4fd7
        LD      (HL),D                  ;4fd8
        LD      H,L                     ;4fd9
        LD      L,C                     ;4fda
        LD      (HL),H                  ;4fdb
        JR      NZ,m4fff                ;4fdc
        JR      NZ,$+15                 ;4fde
m4fe0   LD      DE,m51e0                ;4fe0
        LD      HL,m4de5                ;4fe3
        LD      (m4483),HL              ;4fe6
m4fe9   LD      A,44H                   ;4fe9
        CALL    m4dd0                   ;4feb
        LD      A,00H                   ;4fee
        LD      (DMODUL),A              ;4ff0
        LD      HL,(m448c)              ;4ff3
        LD      A,(m4488)               ;4ff6
        OR      A                       ;4ff9
        JR      NZ,m4ffd                ;4ffa
        DEC     HL                      ;4ffc
m4ffd   LD      A,H                     ;4ffd
        AND     L                       ;4ffe
m4fff   INC     A                       ;4fff
m5000   JR      Z,m502f                 ;5000
        LD      (m51ea),HL              ;5002
        EXX                             ;5005
        LD      HL,WRITE                ;5006
        EXX                             ;5009
        XOR     A                       ;500a
        CALL    m4dd0                   ;500b
m500e   LD      A,00H                   ;500e
m5010   LD      (DMODUL),A              ;5010
        CALL    m443f                   ;5013
        RET     NZ                      ;5016
m5017   LD      DE,USRFCB               ;5017
        CALL    READ                    ;501a
        JR      NZ,m5028                ;501d
        LD      DE,m51e0                ;501f
        CALL    WRITE                   ;5022
        RET     NZ                      ;5025
        JR      m5017                   ;5026
m5028   CP      1CH                     ;5028
        JR      Z,m502f                 ;502a
        CP      1DH                     ;502c
        RET     NZ                      ;502e
m502f   LD      HL,(m448c)              ;502f
        LD      (m51ec),HL              ;5032
m5035   LD      A,(m4488)               ;5035
        LD      (m51e8),A               ;5038
        LD      DE,m51e0                ;503b
        CALL    m443f                   ;503e
m5041   RET     NZ                      ;5041
m5042   CALL    READ                    ;5042
        JR      Z,m5042                 ;5045
        CP      1CH                     ;5047
        JR      Z,m504e                 ;5049
        CP      1DH                     ;504b
        RET     NZ                      ;504d
m504e   JP      m4428                   ;504e
m5051   DI                              ;5051
        LD      BC,0036H                ;5052
        LD      DE,m4000                ;5055
        LD      HL,06D2H                ;5058
        LDIR                            ;505b
        EX      DE,HL                   ;505d
        LD      B,27H                   ;505e
m5060   LD      (HL),C                  ;5060
        INC     HL                      ;5061
        DJNZ    m5060                   ;5062
        JP      0075H                   ;5064
m5067   CALL    m50c2                   ;5067
        RET     NZ                      ;506a
        DEC     HL                      ;506b
        LD      DE,(m4051)              ;506c
        LD      (HL),D                  ;5070
        DEC     HL                      ;5071
        LD      (HL),E                  ;5072
        LD      D,H                     ;5073
        LD      E,L                     ;5074
        DEC     HL                      ;5075
        LD      (HL),D                  ;5076
        DEC     HL                      ;5077
        LD      (HL),E                  ;5078
        LD      (m4051),HL              ;5079
        XOR     A                       ;507c
        RET                             ;507d
m507e   CALL    m50c2                   ;507e
        JR      Z,m50bd                 ;5081
        XOR     A                       ;5083
        DEC     HL                      ;5084
        LD      (HL),A                  ;5085
        INC     HL                      ;5086
        LD      C,(HL)                  ;5087
        INC     HL                      ;5088
        LD      B,(HL)                  ;5089
        EX      DE,HL                   ;508a
        LD      (HL),C                  ;508b
        INC     HL                      ;508c
        LD      (HL),B                  ;508d
        RET                             ;508e
m508f   LD      DE,m51e0                ;508f
        LD      B,09H                   ;5092
        PUSH    DE                      ;5094
m5095   INC     HL                      ;5095
        CALL    CHKCHR                  ;5096
        JR      NC,m50a2                ;5099
        LD      A,(HL)                  ;509b
        LD      (DE),A                  ;509c
        INC     DE                      ;509d
        DJNZ    m5095                   ;509e
        LD      B,09H                   ;50a0
m50a2   LD      A,B                     ;50a2
        CP      09H                     ;50a3
        JP      Z,m4d4c                 ;50a5
m50a8   LD      A,20H                   ;50a8
        LD      (DE),A                  ;50aa
        INC     DE                      ;50ab
        DJNZ    m50a8                   ;50ac
        EX      (SP),HL                 ;50ae
        CALL    m50cc                   ;50af
        LD      DE,000AH                ;50b2
        ADD     HL,DE                   ;50b5
        POP     DE                      ;50b6
        JR      Z,m50bd                 ;50b7
        EX      (SP),HL                 ;50b9
        PUSH    HL                      ;50ba
        EX      DE,HL                   ;50bb
        RET                             ;50bc
m50bd   LD      A,18H                   ;50bd
        JP      m4d4e                   ;50bf
m50c2   LD      A,H                     ;50c2
        CP      52H                     ;50c3
        JP      C,m4d4c                 ;50c5
        INC     HL                      ;50c8
        INC     HL                      ;50c9
        INC     HL                      ;50ca
        INC     HL                      ;50cb
m50cc   PUSH    HL                      ;50cc
        LD      HL,m4051                ;50cd
        PUSH    HL                      ;50d0
        PUSH    HL                      ;50d1
m50d2   POP     BC                      ;50d2
        POP     HL                      ;50d3
        LD      B,H                     ;50d4
        LD      C,L                     ;50d5
        LD      E,(HL)                  ;50d6
        INC     HL                      ;50d7
        LD      D,(HL)                  ;50d8
        LD      A,D                     ;50d9
        OR      E                       ;50da
        JR      NZ,m50df                ;50db
        POP     HL                      ;50dd
        RET                             ;50de
m50df   EX      DE,HL                   ;50df
        LD      E,(HL)                  ;50e0
        INC     HL                      ;50e1
        LD      D,(HL)                  ;50e2
        INC     HL                      ;50e3
        OR      A                       ;50e4
        SBC     HL,DE                   ;50e5
        POP     HL                      ;50e7
        JP      NZ,m4d46                ;50e8
        PUSH    HL                      ;50eb
        PUSH    DE                      ;50ec
        PUSH    BC                      ;50ed
        INC     DE                      ;50ee
        INC     DE                      ;50ef
        LD      B,08H                   ;50f0
m50f2   LD      A,(DE)                  ;50f2
        SUB     (HL)                    ;50f3
        INC     DE                      ;50f4
        INC     HL                      ;50f5
        JR      NZ,m50d2                ;50f6
        DJNZ    m50f2                   ;50f8
        POP     DE                      ;50fa
        POP     HL                      ;50fb
        POP     BC                      ;50fc
        OR      35H                     ;50fd
        RET                             ;50ff
m5100   DAA                             ;5100
        LD      D,D                     ;5101
        LD      D,L                     ;5102
        LD      C,(HL)                  ;5103
        JR      NZ,m5155                ;5104
        LD      C,(HL)                  ;5106
        LD      C,H                     ;5107
        LD      E,C                     ;5108
        DAA                             ;5109
        JR      NZ,m514d                ;510a
        LD      B,D                     ;510c
        LD      B,D                     ;510d
        LD      D,D                     ;510e
        LD      D,L                     ;510f
        LD      B,E                     ;5110
        LD      C,B                     ;5111
        INC     BC                      ;5112
m5113   LD      B,H                     ;5113
        LD      L,A                     ;5114
        LD      (HL),E                  ;5115
        LD      H,(HL)                  ;5116
        LD      H,L                     ;5117
        LD      L,B                     ;5118
        LD      L,H                     ;5119
        LD      H,L                     ;511a
        LD      (HL),D                  ;511b
        JR      NZ,m5184                ;511c
        LD      H,C                     ;511e
        LD      (HL),H                  ;511f
        LD      H,C                     ;5120
        LD      L,H                     ;5121
        INC     BC                      ;5122
m5123   LD      HL,2021H                ;5123
        JR      NZ,m517a                ;5126
        LD      B,L                     ;5128
        LD      D,E                     ;5129
        LD      B,L                     ;512a
        LD      D,H                     ;512b
        JR      NZ,m519b                ;512c
        LD      L,C                     ;512e
        LD      (HL),H                  ;512f
        JR      NZ,m5186                ;5130
        LD      H,C                     ;5132
        LD      (HL),E                  ;5133
        LD      (HL),H                  ;5134
        LD      H,L                     ;5135
        JR      NZ,m518a                ;5136
        LD      HL,0B70DH               ;5138
        JP      NZ,m4e99                ;513b
        LD      A,B                     ;513e
        AND     50H                     ;513f
        CP      40H                     ;5141
        JP      Z,DOSRDY                ;5143
        RET                             ;5146
        NOP                             ;5147
        NOP                             ;5148
        NOP                             ;5149
        NOP                             ;514a
        NOP                             ;514b
        NOP                             ;514c
m514d   NOP                             ;514d
        NOP                             ;514e
        NOP                             ;514f
        NOP                             ;5150
        NOP                             ;5151
        NOP                             ;5152
        NOP                             ;5153
        NOP                             ;5154
m5155   NOP                             ;5155
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
m517a   NOP                             ;517a
        NOP                             ;517b
        NOP                             ;517c
        NOP                             ;517d
        NOP                             ;517e
        NOP                             ;517f
        NOP                             ;5180
        NOP                             ;5181
        NOP                             ;5182
        NOP                             ;5183
m5184   NOP                             ;5184
        NOP                             ;5185
m5186   NOP                             ;5186
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
m519b   NOP                             ;519b
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
; ------------------------------------------------------------
; [note]      51D3h: BOOT's tail. 0060h: DEC BC/LD A,B/OR C delay
;             loop in ROM, then JP 0000h re-enters the boot ROM.
;             0000h = 76h (HALT), ROM 0000h-2FFFh verified
;             byte-identical to a stock floppy boot (12288 bytes).
;             HALT resumes on interrupt, falls to 0001h XOR A/JP
;             0674h (reset). IFF1=0 on both systems at the prompt,
;             so HALT should never resume on either.
; ------------------------------------------------------------
m51d3   CALL    0060H                   ;51d3
        JP      0000H                   ;51d6
        PUSH    AF                      ;51d9
        OUT     (0FAH),A                ;51da
        XOR     A                       ;51dc
        JP      0000H                   ;51dd
        END     4d00h
