;************************************************************************
;
; SYS1 from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
;************************************************************************
; SYS1/SYS, stock GDOS 2.4. Loads contiguously into 4D00h-51DFh, no gaps,
; entry 4D00h. Grosser ch.7 gives the same extent: "SYS1/SYS -- EOF 4/248,
; RAM 4D00-51DF, Start 4D00".
;
;   z80dasm -g 0x4d00 -l -a -t sys1_flat.bin
;
; each line in the right-hand column. Verified by assembling this file with
; pasmo and comparing the result with the module byte for byte.
; Rewritten from that z80dasm output into readable assembly: every address
; of z80dasm's lNNNNh/sub_NNNNh and the module address of each line on the
; right. Verified by assembling this file with pasmo and comparing the result
; with the module byte for byte.
;
; Parts of every module are data -- message strings and tables -- that
; z80dasm decodes as instructions, because it walks the bytes in order
; rather than following where the code can go. Those stretches read as
; nonsense (LD C,C / LD D,E is the letters I S), and any number in them
; is a data byte, not an address. Only references that land in low RAM,
; the DOS or this module get a symbol; anything else keeps its number,
; which is the signal that it is not a reference at all.

CURFLG  EQU     4022h		;video DCB: cursor on/off
DOSRDY  EQU     402dh		;return to the DOS prompt
DOSSTK  EQU     41e0h		;initial address of the DOS stack
SECBUF  EQU     4200h		;DOS sector buffer
BRKVEC  EQU     4312h		;BREAK vector (RST 28h, A<20h)
m4313   EQU     4313h
DCMDBF  EQU     4318h		;DOS input buffer
DFLAG1  EQU     436ah		;DOS operating-state flags
DFLAG2  EQU     436bh		;flags SYS6 manipulates for CLOSE and EXPAND
DFLAG3  EQU     436ch		;further DOS flags
DFLAG4  EQU     436dh		;further DOS flags
SPSAVE  EQU     439bh		;stack-pointer save slot
SPSAV2  EQU     439dh		;stack-pointer save slot, second
INPCH2  EQU     43a7h		;first two characters of an input
m4400   EQU     4400h
ERRRET  EQU     4408h		;error exit; a plain RET when there is no error
FINIT   EQU     4420h		;INIT: create the file if it does not exist
FOPEN   EQU     4424h		;OPEN: do not create a new file
DSPLY   EQU     4467h		;display the text at (HL)
USRFCB  EQU     4480h		;FCB for loading and starting user programs
CONTLC  EQU     45b0h		;continuation for SYSTEM,BG or the LC command
UPCASE  EQU     45b5h		;convert lower case to upper case
m4900   EQU     4900h
SYSLD   EQU     49d3h		;load a SYS file; exits on error
SYSLD2  EQU     49d6h		;load a SYS file; sets the no-error flag itself
STRCMP  EQU     4cc5h		;compare the strings at (HL) and (BC)
CHKCHR  EQU     4cd5h		;test the character at (HL)
CHKSEP  EQU     4cd9h		;check for a comma or a blank
m51e0   EQU     51e0h
        ORG     4d00h
        CP      23H                     ;4d00
        JP      Z,m4d8a                 ;4d02
        CP      43H                     ;4d05
        JR      Z,m4d7c                 ;4d07
        CP      63H                     ;4d09
        JP      Z,m4e30                 ;4d0b
        CP      83H                     ;4d0e
        JP      Z,m5155                 ;4d10
        CP      0A3H                    ;4d13
        JP      Z,m4f2a                 ;4d15
        CP      0C3H                    ;4d18
        JR      Z,m4d5b                 ;4d1a
        DEC     C                       ;4d1c
        JR      Z,m4d59                 ;4d1d
        DEC     C                       ;4d1f
        JP      Z,m50cf                 ;4d20
        DEC     C                       ;4d23
        JP      Z,m4d32                 ;4d24
        DEC     C                       ;4d27
        JP      Z,m50f3                 ;4d28
        DEC     C                       ;4d2b
        JR      Z,m4d80                 ;4d2c
        DEC     C                       ;4d2e
        JP      Z,m5112                 ;4d2f
m4d32   DEC     C                       ;4d32
        JR      Z,m4d78                 ;4d33
        DEC     C                       ;4d35
        JP      Z,m4e34                 ;4d36
        DEC     C                       ;4d39
        JR      Z,m4d48                 ;4d3a
        DEC     C                       ;4d3c
        DEC     C                       ;4d3d
        JP      Z,m5168                 ;4d3e
        DEC     C                       ;4d41
        JR      Z,m4d80                 ;4d42
m4d44   LD      A,2AH                   ;4d44
        OR      A                       ;4d46
        RET                             ;4d47
m4d48   LD      HL,m51dd                ;4d48
        JP      DSPLY                   ;4d4b
        EXX                             ;4d4e
        LD      BC,0E301H               ;4d4f
        LD      DE,SYSLD                ;4d52
        PUSH    BC                      ;4d55
        PUSH    DE                      ;4d56
        EXX                             ;4d57
        RST     28H                     ;4d58
m4d59   POP     AF                      ;4d59
        RET                             ;4d5a
m4d5b   CALL    m5143                   ;4d5b
        LD      BC,0000H                ;4d5e
        EX      DE,HL                   ;4d61
        LD      HL,DFLAG1               ;4d62
        BIT     6,(HL)                  ;4d65
        SET     6,(HL)                  ;4d67
        JR      Z,m4d6f                 ;4d69
        LD      BC,(SPSAV2)             ;4d6b
m4d6f   PUSH    BC                      ;4d6f
        LD      (SPSAV2),SP             ;4d70
        EX      DE,HL                   ;4d74
        JP      m4e35                   ;4d75
m4d78   POP     AF                      ;4d78
        POP     AF                      ;4d79
        JR      m4d8b                   ;4d7a
m4d7c   XOR     A                       ;4d7c
        SCF                             ;4d7d
        JR      m4d8b                   ;4d7e
m4d80   LD      HL,DFLAG1               ;4d80
        LD      A,(HL)                  ;4d83
        AND     2FH                     ;4d84
        LD      (HL),A                  ;4d86
        DEC     HL                      ;4d87
        RES     5,(HL)                  ;4d88
m4d8a   XOR     A                       ;4d8a
m4d8b   DI                              ;4d8b
        LD      HL,DFLAG2               ;4d8c
        LD      (HL),00H                ;4d8f
        DEC     HL                      ;4d91
        LD      B,(HL)                  ;4d92
        DEC     HL                      ;4d93
        LD      C,(HL)                  ;4d94
        LD      E,0BH                   ;4d95
        PUSH    AF                      ;4d97
        BIT     2,B                     ;4d98
        JR      NZ,m4dbf                ;4d9a
        POP     AF                      ;4d9c
        PUSH    AF                      ;4d9d
        JR      C,m4da2                 ;4d9e
        JR      Z,m4dac                 ;4da0
m4da2   CP      38H                     ;4da2
        JR      Z,m4dac                 ;4da4
        LD      E,04H                   ;4da6
        BIT     5,C                     ;4da8
        JR      NZ,m4dbf                ;4daa
m4dac   RES     6,(HL)                  ;4dac
        BIT     6,B                     ;4dae
        JR      NZ,m4e10                ;4db0
        LD      A,(DFLAG3)              ;4db2
        BIT     6,A                     ;4db5
        JR      Z,m4dc4                 ;4db7
        BIT     5,C                     ;4db9
        JR      NZ,m4dc4                ;4dbb
        LD      E,0CH                   ;4dbd
m4dbf   LD      D,0EBH                  ;4dbf
        LD      A,D                     ;4dc1
        LD      C,E                     ;4dc2
        RST     28H                     ;4dc3
m4dc4   BIT     7,B                     ;4dc4
        JR      NZ,m4ddc                ;4dc6
        LD      SP,DOSSTK               ;4dc8
        BIT     5,A                     ;4dcb
        LD      HL,CONTLC               ;4dcd
        LD      (m4313),HL              ;4dd0
        LD      A,0C3H                  ;4dd3
        JR      Z,m4dd9                 ;4dd5
        LD      A,0C9H                  ;4dd7
m4dd9   LD      (BRKVEC),A              ;4dd9
m4ddc   LD      HL,m51cd                ;4ddc
        BIT     7,B                     ;4ddf
        JR      Z,m4dea                 ;4de1
        LD      SP,(SPSAVE)             ;4de3
        LD      HL,m51c8                ;4de7
m4dea   EI                              ;4dea
        LD      A,0BH                   ;4deb
        CALL    0033H                   ;4ded
        BIT     5,C                     ;4df0
        CALL    Z,DSPLY                 ;4df2
        LD      HL,DFLAG1               ;4df5
        SET     5,(HL)                  ;4df8
        LD      BC,0E308H               ;4dfa
        LD      DE,SYSLD2               ;4dfd
        PUSH    BC                      ;4e00
        PUSH    DE                      ;4e01
        LD      HL,(DCMDBF)             ;4e02
        LD      (INPCH2),HL             ;4e05
        LD      B,4FH                   ;4e08
        LD      HL,DCMDBF               ;4e0a
        JP      0040H                   ;4e0d
m4e10   POP     DE                      ;4e10
        LD      SP,(SPSAV2)             ;4e11
        BIT     5,C                     ;4e15
        JR      Z,m4e1d                 ;4e17
        BIT     4,B                     ;4e19
        JR      NZ,m4ddc                ;4e1b
m4e1d   POP     BC                      ;4e1d
        LD      A,B                     ;4e1e
        OR      C                       ;4e1f
        JR      NZ,m4e25                ;4e20
        INC     HL                      ;4e22
        RES     6,(HL)                  ;4e23
m4e25   RES     4,(HL)                  ;4e25
        LD      (SPSAV2),BC             ;4e27
        PUSH    DE                      ;4e2b
        POP     AF                      ;4e2c
        JP      m5133                   ;4e2d
m4e30   LD      SP,DOSSTK               ;4e30
        PUSH    AF                      ;4e33
m4e34   POP     AF                      ;4e34
m4e35   LD      BC,DOSRDY               ;4e35
        LD      DE,ERRRET               ;4e38
        PUSH    BC                      ;4e3b
        PUSH    DE                      ;4e3c
        EX      DE,HL                   ;4e3d
        LD      HL,DFLAG1               ;4e3e
        RES     5,(HL)                  ;4e41
        LD      HL,DCMDBF               ;4e43
        LD      B,50H                   ;4e46
        LD      A,(HL)                  ;4e48
        CP      0DH                     ;4e49
        RET     Z                       ;4e4b
        PUSH    HL                      ;4e4c
m4e4d   LD      A,(DE)                  ;4e4d
        INC     DE                      ;4e4e
        CALL    UPCASE                  ;4e4f
        CP      0DH                     ;4e52
        LD      (HL),A                  ;4e54
        INC     HL                      ;4e55
        JR      Z,m4e5f                 ;4e56
        DJNZ    m4e4d                   ;4e58
        POP     AF                      ;4e5a
        LD      A,36H                   ;4e5b
        OR      A                       ;4e5d
        RET                             ;4e5e
m4e5f   LD      A,(DFLAG4)              ;4e5f
        BIT     5,A                     ;4e62
        JR      Z,m4e75                 ;4e64
        LD      HL,(DCMDBF)             ;4e66
        LD      DE,0D52H                ;4e69
        RST     18H                     ;4e6c
        JR      NZ,m4e75                ;4e6d
        LD      HL,(INPCH2)             ;4e6f
        LD      (DCMDBF),HL             ;4e72
m4e75   POP     HL                      ;4e75
        LD      DE,m4f58                ;4e76
m4e79   PUSH    HL                      ;4e79
m4e7a   LD      A,(DE)                  ;4e7a
        CP      (HL)                    ;4e7b
        INC     DE                      ;4e7c
        INC     HL                      ;4e7d
        JR      Z,m4e7a                 ;4e7e
        DEC     HL                      ;4e80
        DEC     DE                      ;4e81
        RLCA                            ;4e82
        JR      NC,m4e8a                ;4e83
        CALL    CHKCHR                  ;4e85
        JR      NC,m4ea7                ;4e88
m4e8a   POP     HL                      ;4e8a
m4e8b   LD      A,(DE)                  ;4e8b
        RLCA                            ;4e8c
        INC     DE                      ;4e8d
        JR      NC,m4e8b                ;4e8e
        INC     DE                      ;4e90
        INC     DE                      ;4e91
        LD      A,(DE)                  ;4e92
        OR      A                       ;4e93
        JR      NZ,m4e79                ;4e94
        LD      BC,0E443H               ;4e96
        LD      D,41H                   ;4e99
        LD      A,(HL)                  ;4e9b
        CP      2AH                     ;4e9c
        JR      NZ,m4eb0                ;4e9e
        LD      A,0EBH                  ;4ea0
        LD      C,07H                   ;4ea2
        RST     28H                     ;4ea4
m4ea5   POP     BC                      ;4ea5
        RET                             ;4ea6
m4ea7   POP     BC                      ;4ea7
        LD      A,(DE)                  ;4ea8
        LD      C,A                     ;4ea9
        INC     DE                      ;4eaa
        LD      A,(DE)                  ;4eab
        LD      B,A                     ;4eac
        INC     DE                      ;4ead
        LD      A,(DE)                  ;4eae
        LD      D,A                     ;4eaf
m4eb0   BIT     6,C                     ;4eb0
        JR      Z,m4ec3                 ;4eb2
        LD      A,(DFLAG1)              ;4eb4
        RLCA                            ;4eb7
        JR      NC,m4ec3                ;4eb8
        AND     80H                     ;4eba
        LD      A,38H                   ;4ebc
        JP      NZ,m4d8b                ;4ebe
        OR      A                       ;4ec1
        RET                             ;4ec2
m4ec3   LD      A,C                     ;4ec3
        AND     1FH                     ;4ec4
        LD      C,A                     ;4ec6
        PUSH    BC                      ;4ec7
        LD      C,D                     ;4ec8
        LD      A,C                     ;4ec9
        AND     0C0H                    ;4eca
        CALL    NZ,m5165                ;4ecc
        JR      NZ,m4ef1                ;4ecf
        BIT     5,C                     ;4ed1
        JR      Z,m4ef5                 ;4ed3
        CALL    CHKSEP                  ;4ed5
        JR      C,m4ea5                 ;4ed8
        PUSH    BC                      ;4eda
        LD      BC,m51c5                ;4edb
        CALL    STRCMP                  ;4ede
        POP     BC                      ;4ee1
        JR      NZ,m4ee9                ;4ee2
        CALL    CHKSEP                  ;4ee4
        JR      C,m4ea5                 ;4ee7
m4ee9   PUSH    DE                      ;4ee9
        LD      DE,m51e0                ;4eea
        CALL    m5168                   ;4eed
        POP     DE                      ;4ef0
m4ef1   LD      A,30H                   ;4ef1
        JR      NZ,m4ea5                ;4ef3
m4ef5   BIT     4,C                     ;4ef5
        CALL    NZ,CHKCHR               ;4ef7
        JR      NZ,m4ea5                ;4efa
        BIT     3,C                     ;4efc
        JR      Z,m4f02                 ;4efe
        EX      (SP),HL                 ;4f00
        PUSH    HL                      ;4f01
m4f02   LD      A,C                     ;4f02
        AND     07H                     ;4f03
        JR      Z,m4f15                 ;4f05
        PUSH    HL                      ;4f07
        LD      HL,m51bc                ;4f08
m4f0b   INC     HL                      ;4f0b
        INC     HL                      ;4f0c
        INC     HL                      ;4f0d
        DEC     A                       ;4f0e
        JR      NZ,m4f0b                ;4f0f
        CALL    m4f2a                   ;4f11
        POP     HL                      ;4f14
m4f15   LD      A,C                     ;4f15
        LD      BC,SYSLD                ;4f16
        PUSH    BC                      ;4f19
        BIT     7,A                     ;4f1a
        RET     Z                       ;4f1c
        LD      B,00H                   ;4f1d
        LD      HL,SECBUF               ;4f1f
        BIT     6,A                     ;4f22
        JP      Z,FOPEN                 ;4f24
        JP      FINIT                   ;4f27
m4f2a   PUSH    DE                      ;4f2a
        PUSH    BC                      ;4f2b
        LD      BC,091CH                ;4f2c
m4f2f   LD      A,(DE)                  ;4f2f
        CP      3AH                     ;4f30
        JR      Z,m4f3e                 ;4f32
        CP      2FH                     ;4f34
        JR      C,m4f3e                 ;4f36
        JR      Z,m4f55                 ;4f38
        DEC     C                       ;4f3a
        INC     DE                      ;4f3b
        DJNZ    m4f2f                   ;4f3c
m4f3e   INC     HL                      ;4f3e
        INC     HL                      ;4f3f
        PUSH    HL                      ;4f40
        EX      DE,HL                   ;4f41
        LD      B,00H                   ;4f42
        ADD     HL,BC                   ;4f44
        LD      D,H                     ;4f45
        LD      E,L                     ;4f46
        DEC     HL                      ;4f47
        INC     DE                      ;4f48
        INC     DE                      ;4f49
        INC     DE                      ;4f4a
        LDDR                            ;4f4b
        POP     HL                      ;4f4d
        LD      C,03H                   ;4f4e
        LDDR                            ;4f50
        LD      A,2FH                   ;4f52
        LD      (DE),A                  ;4f54
m4f55   POP     BC                      ;4f55
        POP     DE                      ;4f56
        RET                             ;4f57
m4f58   LD      B,C                     ;4f58
        LD      C,C                     ;4f59
        LD      C,E                     ;4f5a
        ADD     A,B                     ;4f5b
        LD      D,E                     ;4f5c
        NOP                             ;4f5d
        LD      B,C                     ;4f5e
        LD      D,B                     ;4f5f
        LD      D,B                     ;4f60
        LD      B,L                     ;4f61
        LD      C,(HL)                  ;4f62
        LD      B,H                     ;4f63
        RET     NZ                      ;4f64
        LD      L,B                     ;4f65
        NOP                             ;4f66
        LD      B,C                     ;4f67
        LD      D,H                     ;4f68
        LD      D,H                     ;4f69
        LD      D,D                     ;4f6a
        LD      C,C                     ;4f6b
        LD      B,D                     ;4f6c
        ADD     A,L                     ;4f6d
        JP      (HL)                    ;4f6e
        ADC     A,B                     ;4f6f
        LD      B,C                     ;4f70
        LD      D,L                     ;4f71
        LD      D,H                     ;4f72
        LD      C,A                     ;4f73
        ADD     A,H                     ;4f74
        JP      (HL)                    ;4f75
        NOP                             ;4f76
        LD      B,D                     ;4f77
        LD      (0EB86H),A              ;4f78
        NOP                             ;4f7b
        LD      B,D                     ;4f7c
        LD      C,H                     ;4f7d
        ADD     A,C                     ;4f7e
        PUSH    HL                      ;4f7f
        NOP                             ;4f80
        LD      B,D                     ;4f81
        LD      C,A                     ;4f82
        LD      C,A                     ;4f83
        LD      D,H                     ;4f84
        ADC     A,D                     ;4f85
        EX      DE,HL                   ;4f86
        DJNZ    $+68                    ;4f87
        LD      D,D                     ;4f89
        LD      B,L                     ;4f8a
        LD      B,C                     ;4f8b
        LD      C,E                     ;4f8c
        ADD     A,L                     ;4f8d
        PUSH    HL                      ;4f8e
        NOP                             ;4f8f
        LD      B,E                     ;4f90
        LD      C,H                     ;4f91
        LD      D,E                     ;4f92
        ADC     A,C                     ;4f93
        EX      (SP),HL                 ;4f94
        DJNZ    m4fda                   ;4f95
        LD      C,A                     ;4f97
        LD      C,(HL)                  ;4f98
        LD      D,H                     ;4f99
        PUSH    BC                      ;4f9a
        EX      DE,HL                   ;4f9b
        NOP                             ;4f9c
        LD      B,E                     ;4f9d
        LD      C,A                     ;4f9e
        LD      D,B                     ;4f9f
        LD      E,C                     ;4fa0
        RET     NZ                      ;4fa1
        LD      C,B                     ;4fa2
        NOP                             ;4fa3
        LD      B,E                     ;4fa4
        LD      D,D                     ;4fa5
        LD      B,L                     ;4fa6
        LD      B,C                     ;4fa7
        LD      D,H                     ;4fa8
        LD      B,L                     ;4fa9
        ADD     A,D                     ;4faa
        RET     P                       ;4fab
        LD      B,B                     ;4fac
        LD      B,H                     ;4fad
        LD      B,C                     ;4fae
        LD      D,H                     ;4faf
        LD      D,L                     ;4fb0
        LD      C,L                     ;4fb1
        ADC     A,E                     ;4fb2
        JP      (HL)                    ;4fb3
        NOP                             ;4fb4
        LD      B,H                     ;4fb5
        LD      B,H                     ;4fb6
        LD      B,L                     ;4fb7
        ADD     A,C                     ;4fb8
        POP     AF                      ;4fb9
        NOP                             ;4fba
        LD      B,H                     ;4fbb
        LD      C,C                     ;4fbc
        LD      D,D                     ;4fbd
        ADD     A,B                     ;4fbe
        LD      HL,(m4400)              ;4fbf
        LD      C,C                     ;4fc2
        LD      D,E                     ;4fc3
        LD      C,E                     ;4fc4
        ADD     A,E                     ;4fc5
        RST     38H                     ;4fc6
        NOP                             ;4fc7
        LD      B,H                     ;4fc8
        LD      C,A                     ;4fc9
        JP      8AEBH                   ;4fca
        LD      B,H                     ;4fcd
        LD      D,D                     ;4fce
        ADD     A,D                     ;4fcf
        CP      00H                     ;4fd0
        LD      B,H                     ;4fd2
        LD      D,L                     ;4fd3
        LD      C,L                     ;4fd4
        LD      D,B                     ;4fd5
        ADD     A,A                     ;4fd6
        JP      (HL)                    ;4fd7
        RET     Z                       ;4fd8
        LD      B,L                     ;4fd9
m4fda   ADD     A,A                     ;4fda
        RET     P                       ;4fdb
        NOP                             ;4fdc
        LD      B,(HL)                  ;4fdd
        LD      C,A                     ;4fde
        LD      D,D                     ;4fdf
        LD      C,L                     ;4fe0
        ADC     A,B                     ;4fe1
        CP      00H                     ;4fe2
        LD      B,(HL)                  ;4fe4
        LD      D,D                     ;4fe5
        LD      B,L                     ;4fe6
        LD      B,L                     ;4fe7
        ADD     A,B                     ;4fe8
        LD      C,D                     ;4fe9
        NOP                             ;4fea
        LD      B,(HL)                  ;4feb
        INC     HL                      ;4fec
        ADD     A,B                     ;4fed
        EI                              ;4fee
        NOP                             ;4fef
        LD      C,B                     ;4ff0
        LD      C,C                     ;4ff1
        LD      C,L                     ;4ff2
        LD      B,L                     ;4ff3
        LD      C,L                     ;4ff4
        ADD     A,D                     ;4ff5
        JP      (HL)                    ;4ff6
        NOP                             ;4ff7
        LD      C,C                     ;4ff8
        ADD     A,B                     ;4ff9
        LD      HL,(m4900)              ;4ffa
        LD      C,(HL)                  ;4ffd
        LD      B,(HL)                  ;4ffe
        LD      C,A                     ;4fff
        ADD     A,C                     ;5000
        RST     38H                     ;5001
        NOP                             ;5002
        LD      C,D                     ;5003
        LD      C,E                     ;5004
        LD      C,H                     ;5005
        ADD     A,B                     ;5006
        LD      A,H                     ;5007
        DJNZ    m5055                   ;5008
        LD      C,C                     ;500a
        LD      C,H                     ;500b
        LD      C,H                     ;500c
        ADD     A,B                     ;500d
        LD      B,L                     ;500e
        SUB     B                       ;500f
        LD      C,H                     ;5010
        LD      B,E                     ;5011
        ADC     A,B                     ;5012
        PUSH    HL                      ;5013
        NOP                             ;5014
        LD      C,H                     ;5015
        LD      B,(HL)                  ;5016
        ADD     A,C                     ;5017
        CP      00H                     ;5018
        LD      C,H                     ;501a
        LD      C,C                     ;501b
        LD      B,D                     ;501c
        ADD     A,D                     ;501d
        EX      (SP),HL                 ;501e
        NOP                             ;501f
        LD      C,H                     ;5020
        LD      C,C                     ;5021
        LD      D,E                     ;5022
        LD      D,H                     ;5023
m5024   ADD     A,L                     ;5024
        RET     P                       ;5025
        ADC     A,B                     ;5026
        LD      C,H                     ;5027
        LD      C,A                     ;5028
        LD      B,C                     ;5029
        LD      B,H                     ;502a
        ADD     A,B                     ;502b
        AND     H                       ;502c
        LD      D,B                     ;502d
        LD      C,L                     ;502e
        LD      A,82H                   ;502f
        EX      DE,HL                   ;5031
        OR      B                       ;5032
        LD      C,(HL)                  ;5033
        ADD     A,C                     ;5034
        CALL    PO,m4eb0                ;5035
        LD      B,H                     ;5038
        LD      B,(HL)                  ;5039
        RET     NZ                      ;503a
        JR      Z,m503d                 ;503b
m503d   LD      D,B                     ;503d
        LD      B,C                     ;503e
        LD      D,L                     ;503f
        LD      D,E                     ;5040
        LD      B,L                     ;5041
        ADC     A,B                     ;5042
        EX      DE,HL                   ;5043
        NOP                             ;5044
        LD      D,B                     ;5045
        LD      B,H                     ;5046
        ADD     A,E                     ;5047
        JP      (HL)                    ;5048
        NOP                             ;5049
        LD      D,B                     ;504a
        LD      C,C                     ;504b
        LD      C,A                     ;504c
        ADD     A,B                     ;504d
        SBC     A,H                     ;504e
        NOP                             ;504f
        LD      D,B                     ;5050
        LD      C,A                     ;5051
        LD      D,D                     ;5052
        LD      D,H                     ;5053
        ADD     A,D                     ;5054
m5055   RST     38H                     ;5055
        NOP                             ;5056
        LD      D,B                     ;5057
        LD      D,D                     ;5058
        LD      C,C                     ;5059
        LD      C,(HL)                  ;505a
        LD      D,H                     ;505b
        ADD     A,(HL)                  ;505c
        RET     P                       ;505d
        ADC     A,B                     ;505e
        LD      D,B                     ;505f
        LD      D,D                     ;5060
        LD      C,A                     ;5061
        LD      D,H                     ;5062
        ADD     A,(HL)                  ;5063
        JP      (HL)                    ;5064
        NOP                             ;5065
        LD      D,B                     ;5066
        LD      D,L                     ;5067
        LD      D,D                     ;5068
        LD      B,A                     ;5069
        LD      B,L                     ;506a
        ADC     A,C                     ;506b
        JP      (HL)                    ;506c
        NOP                             ;506d
        LD      D,D                     ;506e
        ADD     A,B                     ;506f
        INC     HL                      ;5070
        NOP                             ;5071
        LD      D,E                     ;5072
        ADD     A,C                     ;5073
        JP      (HL)                    ;5074
        NOP                             ;5075
        LD      D,E                     ;5076
        LD      C,C                     ;5077
        LD      C,A                     ;5078
        ADD     A,B                     ;5079
        CP      H                       ;507a
        NOP                             ;507b
        LD      D,E                     ;507c
        LD      D,H                     ;507d
        LD      C,L                     ;507e
        LD      D,H                     ;507f
        ADC     A,C                     ;5080
        EX      DE,HL                   ;5081
        NOP                             ;5082
        LD      D,L                     ;5083
        LD      C,B                     ;5084
        LD      D,D                     ;5085
        ADD     A,D                     ;5086
        PUSH    HL                      ;5087
        NOP                             ;5088
        LD      D,(HL)                  ;5089
        DEC     HL                      ;508a
        ADD     A,H                     ;508b
        PUSH    HL                      ;508c
        NOP                             ;508d
        LD      E,D                     ;508e
        ADD     A,C                     ;508f
        RET     M                       ;5090
        NOP                             ;5091
        LD      E,D                     ;5092
        LD      B,L                     ;5093
        LD      C,C                     ;5094
        LD      D,H                     ;5095
        ADC     A,D                     ;5096
        JP      (HL)                    ;5097
        NOP                             ;5098
        LD      E,D                     ;5099
        LD      C,H                     ;509a
        ADD     A,D                     ;509b
        RET     M                       ;509c
        ADC     A,B                     ;509d
        JR      NC,m5024                ;509e
        RET     P                       ;50a0
        NOP                             ;50a1
        LD      (HL),34H                ;50a2
        ADD     A,C                     ;50a4
        SBC     A,B                     ;50a5
        NOP                             ;50a6
        JR      C,m50d9                 ;50a7
        ADD     A,D                     ;50a9
        SBC     A,B                     ;50aa
        NOP                             ;50ab
        LD      HL,0EB83H               ;50ac
        ADC     A,D                     ;50af
        INC     HL                      ;50b0
        INC     HL                      ;50b1
        ADD     A,E                     ;50b2
        SBC     A,B                     ;50b3
        NOP                             ;50b4
        LD      H,83H                   ;50b5
        PUSH    HL                      ;50b7
        NOP                             ;50b8
        LD      B,B                     ;50b9
        ADD     A,C                     ;50ba
        RET     P                       ;50bb
        NOP                             ;50bc
        DEC     SP                      ;50bd
        ADD     A,(HL)                  ;50be
        EX      (SP),HL                 ;50bf
        NOP                             ;50c0
        CPL                             ;50c1
        ADD     A,L                     ;50c2
        EX      (SP),HL                 ;50c3
        NOP                             ;50c4
        LD      A,0C0H                  ;50c5
        LD      C,B                     ;50c7
        NOP                             ;50c8
        CCF                             ;50c9
        ADD     A,D                     ;50ca
        EX      (SP),HL                 ;50cb
        NOP                             ;50cc
        NOP                             ;50cd
        NOP                             ;50ce
m50cf   LD      HL,m4f58                ;50cf
m50d2   LD      C,40H                   ;50d2
m50d4   LD      B,08H                   ;50d4
m50d6   LD      A,(HL)                  ;50d6
        BIT     7,A                     ;50d7
m50d9   INC     HL                      ;50d9
        JR      NZ,m50e1                ;50da
        CALL    m51b7                   ;50dc
        DJNZ    m50d6                   ;50df
m50e1   INC     HL                      ;50e1
        INC     HL                      ;50e2
        LD      A,(HL)                  ;50e3
        OR      A                       ;50e4
        JP      Z,m51b5                 ;50e5
        DEC     C                       ;50e8
        CALL    Z,m51b5                 ;50e9
        JR      Z,m50d2                 ;50ec
        CALL    m51ad                   ;50ee
        JR      m50d4                   ;50f1
m50f3   DI                              ;50f3
        CALL    m5143                   ;50f4
        LD      HL,DFLAG1               ;50f7
        LD      A,(HL)                  ;50fa
        AND     0C0H                    ;50fb
        JR      NZ,m5132                ;50fd
        LD      A,(CURFLG)              ;50ff
        PUSH    AF                      ;5102
        LD      (SPSAVE),SP             ;5103
        SET     7,(HL)                  ;5107
        EI                              ;5109
        LD      A,0BH                   ;510a
        CALL    0033H                   ;510c
        JP      m4d8a                   ;510f
m5112   LD      HL,DFLAG1               ;5112
        BIT     7,(HL)                  ;5115
        JP      Z,m4d44                 ;5117
        LD      SP,(SPSAVE)             ;511a
        LD      A,0EH                   ;511e
        CALL    0033H                   ;5120
        POP     AF                      ;5123
        OR      A                       ;5124
        LD      B,A                     ;5125
        LD      A,0FH                   ;5126
        CALL    Z,0033H                 ;5128
        LD      A,B                     ;512b
        LD      (CURFLG),A              ;512c
        DI                              ;512f
        RES     7,(HL)                  ;5130
m5132   XOR     A                       ;5132
m5133   EX      AF,AF'                  ;5133
        POP     IY                      ;5134
        POP     IX                      ;5136
        POP     AF                      ;5138
        POP     BC                      ;5139
        POP     DE                      ;513a
        POP     HL                      ;513b
        EXX                             ;513c
        POP     BC                      ;513d
        POP     DE                      ;513e
        POP     HL                      ;513f
        EX      AF,AF'                  ;5140
        EI                              ;5141
        RET                             ;5142
m5143   POP     AF                      ;5143
        PUSH    HL                      ;5144
        PUSH    DE                      ;5145
        PUSH    BC                      ;5146
        EX      AF,AF'                  ;5147
        EXX                             ;5148
        PUSH    HL                      ;5149
        PUSH    DE                      ;514a
        PUSH    BC                      ;514b
        PUSH    AF                      ;514c
        PUSH    IX                      ;514d
        PUSH    IY                      ;514f
        EXX                             ;5151
        EX      AF,AF'                  ;5152
        PUSH    AF                      ;5153
        RET                             ;5154
m5155   CALL    m5168                   ;5155
        PUSH    AF                      ;5158
        LD      A,(HL)                  ;5159
        SUB     03H                     ;515a
        JR      Z,m5160                 ;515c
        SUB     0AH                     ;515e
m5160   JR      Z,m5163                 ;5160
        INC     HL                      ;5162
m5163   POP     AF                      ;5163
        RET                             ;5164
m5165   LD      DE,USRFCB               ;5165
m5168   PUSH    DE                      ;5168
        LD      B,20H                   ;5169
        CALL    m5172                   ;516b
        POP     DE                      ;516e
        LD      B,00H                   ;516f
        RET                             ;5171
m5172   LD      A,(HL)                  ;5172
        CP      2AH                     ;5173
        JR      NZ,m517b                ;5175
        LD      (DE),A                  ;5177
        INC     DE                      ;5178
        INC     HL                      ;5179
        DEC     B                       ;517a
m517b   PUSH    HL                      ;517b
        LD      A,(HL)                  ;517c
        SUB     30H                     ;517d
        CP      0AH                     ;517f
        CALL    m51a1                   ;5181
        JR      NC,m519c                ;5184
m5186   LD      A,(HL)                  ;5186
        SUB     2EH                     ;5187
        CP      0DH                     ;5189
        CALL    m51a1                   ;518b
        JR      C,m5196                 ;518e
        LD      A,03H                   ;5190
        LD      (DE),A                  ;5192
        POP     AF                      ;5193
        XOR     A                       ;5194
        RET                             ;5195
m5196   LD      A,(HL)                  ;5196
        LD      (DE),A                  ;5197
        INC     DE                      ;5198
        INC     HL                      ;5199
        DJNZ    m5186                   ;519a
m519c   OR      01H                     ;519c
        POP     HL                      ;519e
        LD      A,(HL)                  ;519f
        RET                             ;51a0
m51a1   RET     C                       ;51a1
        LD      A,(HL)                  ;51a2
        SUB     41H                     ;51a3
        CP      1FH                     ;51a5
        RET     C                       ;51a7
        SUB     20H                     ;51a8
        CP      1FH                     ;51aa
        RET                             ;51ac
m51ad   LD      A,20H                   ;51ad
        CALL    m51b7                   ;51af
        DJNZ    m51ad                   ;51b2
        RET                             ;51b4
m51b5   LD      A,0BH                   ;51b5
m51b7   PUSH    DE                      ;51b7
        PUSH    AF                      ;51b8
        CALL    0033H                   ;51b9
m51bc   POP     AF                      ;51bc
        POP     DE                      ;51bd
        RET                             ;51be
        LD      B,E                     ;51bf
        LD      C,L                     ;51c0
        LD      B,H                     ;51c1
        LD      C,D                     ;51c2
        LD      C,A                     ;51c3
        LD      B,D                     ;51c4
m51c5   LD      D,H                     ;51c5
        LD      C,A                     ;51c6
        NOP                             ;51c7
m51c8   LD      C,L                     ;51c8
        LD      L,C                     ;51c9
        LD      L,(HL)                  ;51ca
        LD      L,C                     ;51cb
        DEC     L                       ;51cc
m51cd   LD      B,D                     ;51cd
        LD      H,L                     ;51ce
        LD      H,(HL)                  ;51cf
        LD      H,L                     ;51d0
        LD      L,B                     ;51d1
        LD      L,H                     ;51d2
        LD      (HL),E                  ;51d3
        LD      H,L                     ;51d4
        LD      L,C                     ;51d5
        LD      L,(HL)                  ;51d6
        LD      H,A                     ;51d7
        LD      H,C                     ;51d8
        LD      H,D                     ;51d9
        LD      H,L                     ;51da
        LD      E,0DH                   ;51db
m51dd   INC     E                       ;51dd
        RRA                             ;51de
        INC     BC                      ;51df
        END     4d00h
