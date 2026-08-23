;************************************************************************
;
; SYS2 from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys2-sys-disassembly.asm
;
; Date: 2026/08/20
;
;************************************************************************
; SYS2/SYS, stock GDOS 2.4. Loads contiguously into 4D00h-51ACh, no gaps,
; entry 4D00h. Grosser ch.7 gives the same extent: "SYS2/SYS -- EOF 4/197,
; RAM 4D00-51AC, Start 4D00".
;
;
;   z80dasm -g 0x4d00 -l -a -t sys2_flat.bin
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

DTABH   EQU     37d6h		;drive table, high bytes
SECBUF  EQU     4200h		;DOS sector buffer
DIRLEN  EQU     421fh		;length of the directory field
DFLAG0  EQU     4369h		;DOS flags: DEBUG, CHAINING, BREAK key, RUN-ONLY (Grosser ch.3)
DSYSAO  EQU     43a1h		;SYSTEM AO: drive for new files
PARMBF  EQU     4403h		;parameter buffer for DOS-CALL, and the start address for LOAD
DOSERR  EQU     4409h		;DOS error exit
m440d   EQU     440dh
UPCASE  EQU     45b5h		;convert lower case to upper case
DRVSLX  EQU     476eh		;DRVSEL with the drive taken from (IX+6)
DRVSEL  EQU     4776h		;select a drive
DDRVSL  EQU     477ch		;DRVSEL entry, hooked by this port's driver
DSKTST  EQU     47ech		;select the drive, motor on, test 'disk in ?'
m486a   EQU     486ah
DIRSEC  EQU     490ah		;read a sector from the directory
m491f   EQU     491fh
FDEGET  EQU     492fh		;fetch a file's FDE from the directory
GETFDE  EQU     4936h		;fetch a file's FDE from the directory, second entry
RDFPDE  EQU     494bh		;load the directory sector holding the FPDE (FCB+7) to 4200h, HL to FPDE+0
m4986   EQU     4986h
ERRXIT  EQU     49cdh		;error exit, via the emergency exit
GSYSCL  EQU     4c20h		;clear the GETSYS-running flag in DFLAG0
SYSLOAD EQU     4c28h		;load a SYS file
CHKCHR  EQU     4cd5h		;test the character at (HL)
m4d6e   EQU     4d6eh		;operand byte inside this module -- self-modified code
m4e0e   EQU     4e0eh		;operand byte inside this module -- self-modified code
m4f24   EQU     4f24h		;operand byte inside this module -- self-modified code
m4f46   EQU     4f46h		;operand byte inside this module -- self-modified code
m4f48   EQU     4f48h		;operand byte inside this module -- self-modified code
m4f56   EQU     4f56h		;operand byte inside this module -- self-modified code
m4f58   EQU     4f58h		;operand byte inside this module -- self-modified code
m4f5e   EQU     4f5eh		;operand byte inside this module -- self-modified code
m505e   EQU     505eh		;operand byte inside this module -- self-modified code
m51ad   EQU     51adh
m51cd   EQU     51cdh
m51d8   EQU     51d8h
m51da   EQU     51dah
m51df   EQU     51dfh
m51e0   EQU     51e0h
        ORG     4d00h
        CP      24H                     ;4d00
        JP      Z,m4e2e                 ;4d02
        CP      44H                     ;4d05
        JP      Z,m4dbd                 ;4d07
        CP      64H                     ;4d0a
        JP      Z,m4f82                 ;4d0c
        CP      84H                     ;4d0f
        JP      Z,m5155                 ;4d11
        CP      0A4H                    ;4d14
        JR      Z,m4d92                 ;4d16
        CP      0C4H                    ;4d18
        JR      Z,m4d80                 ;4d1a
        CP      0E4H                    ;4d1c
        JR      NZ,m4d2e                ;4d1e
        DEC     C                       ;4d20
        JR      Z,m4d32                 ;4d21
        DEC     C                       ;4d23
        JP      Z,m50ca                 ;4d24
        DEC     C                       ;4d27
        JR      Z,m4d7b                 ;4d28
        DEC     C                       ;4d2a
        JP      Z,m4d72                 ;4d2b
m4d2e   LD      A,2AH                   ;4d2e
m4d30   OR      A                       ;4d30
        RET                             ;4d31
m4d32   PUSH    DE                      ;4d32
        POP     IX                      ;4d33
        INC     DE                      ;4d35
        LD      A,(DE)                  ;4d36
        AND     07H                     ;4d37
        CP      03H                     ;4d39
        LD      A,25H                   ;4d3b
        JR      NC,m4d30                ;4d3d
        LD      HL,m4e75                ;4d3f
        LD      (HL),3EH                ;4d42
        LD      DE,m51e0                ;4d44
        CALL    m4e2c                   ;4d47
        LD      (HL),18H                ;4d4a
        JR      Z,m4d77                 ;4d4c
        CP      18H                     ;4d4e
        CALL    Z,RDFPDE                ;4d50
        RET     NZ                      ;4d53
        LD      A,L                     ;4d54
        ADD     A,05H                   ;4d55
        LD      L,A                     ;4d57
        EX      DE,HL                   ;4d58
        LD      HL,m51cd                ;4d59
        LD      BC,000BH                ;4d5c
        LDIR                            ;4d5f
        CALL    m491f                   ;4d61
        LD      A,01H                   ;4d64
        CALL    Z,DIRSEC                ;4d66
        RET     NZ                      ;4d69
        LD      L,(IX+07H)              ;4d6a
        LD      (HL),00H                ;4d6d
        JP      m491f                   ;4d6f
m4d72   CALL    m4dbd                   ;4d72
        RET     NZ                      ;4d75
        RET     C                       ;4d76
m4d77   LD      A,35H                   ;4d77
        OR      A                       ;4d79
        RET                             ;4d7a
m4d7b   CALL    CHKCHR                  ;4d7b
        RET     C                       ;4d7e
        POP     AF                      ;4d7f
m4d80   EX      (SP),HL                 ;4d80
        CALL    m4d92                   ;4d81
        JP      NZ,DOSERR               ;4d84
        EX      (SP),HL                 ;4d87
        LD      A,(DFLAG0)              ;4d88
        RLCA                            ;4d8b
        JP      C,m440d                 ;4d8c
        JP      GSYSCL                  ;4d8f
m4d92   LD      HL,SECBUF               ;4d92
        CALL    m4e2c                   ;4d95
        JR      Z,m4da0                 ;4d98
        CP      18H                     ;4d9a
        RET     NZ                      ;4d9c
        ADD     A,07H                   ;4d9d
        RET                             ;4d9f
m4da0   EX      DE,HL                   ;4da0
        INC     HL                      ;4da1
        LD      A,(HL)                  ;4da2
        PUSH    AF                      ;4da3
        PUSH    HL                      ;4da4
        AND     07H                     ;4da5
        LD      B,A                     ;4da7
        LD      A,06H                   ;4da8
        CP      B                       ;4daa
        LD      A,25H                   ;4dab
        LD      (HL),2DH                ;4dad
        DEC     HL                      ;4daf
        CALL    NC,SYSLOAD              ;4db0
        LD      (PARMBF),HL             ;4db3
        EX      DE,HL                   ;4db6
        POP     HL                      ;4db7
        POP     BC                      ;4db8
        LD      (HL),B                  ;4db9
        DEC     HL                      ;4dba
        EX      DE,HL                   ;4dbb
        RET                             ;4dbc
m4dbd   CALL    m4e2e                   ;4dbd
        RET     Z                       ;4dc0
        CP      18H                     ;4dc1
        RET     NZ                      ;4dc3
        CALL    m4986                   ;4dc4
        LD      BC,(m4e09+1)            ;4dc7
        LD      A,B                     ;4dcb
        CP      C                       ;4dcc
        JR      Z,m4dd2                 ;4dcd
        LD      A,(DSYSAO)              ;4dcf
m4dd2   LD      (m4e0e),A               ;4dd2
        CALL    DSKTST                  ;4dd5
        JR      NZ,m4de3                ;4dd8
        LD      HL,m4d6e                ;4dda
        LD      B,(HL)                  ;4ddd
        CALL    m50cf                   ;4dde
        JR      Z,m4dea                 ;4de1
m4de3   LD      E,1AH                   ;4de3
        CALL    m4e09                   ;4de5
        JR      m4dd2                   ;4de8
m4dea   LD      (m4f56),A               ;4dea
        LD      (HL),10H                ;4ded
        CALL    m4e1f                   ;4def
        LD      A,(m4f5e)               ;4df2
        LD      (HL),A                  ;4df5
        INC     HL                      ;4df6
        EX      DE,HL                   ;4df7
        LD      HL,m51cd                ;4df8
        LD      BC,000FH                ;4dfb
        LDIR                            ;4dfe
        CALL    m491f                   ;4e00
        RET     NZ                      ;4e03
        CALL    m4f2e                   ;4e04
        SCF                             ;4e07
        RET                             ;4e08
m4e09   LD      HL,0000H                ;4e09
        LD      D,A                     ;4e0c
        LD      A,00H                   ;4e0d
        INC     A                       ;4e0f
        CP      L                       ;4e10
        RET     C                       ;4e11
        POP     HL                      ;4e12
        JR      Z,m4e18                 ;4e13
        LD      A,D                     ;4e15
        OR      A                       ;4e16
        RET     NZ                      ;4e17
m4e18   LD      A,E                     ;4e18
        OR      A                       ;4e19
        RET                             ;4e1a
m4e1b   LD      A,20H                   ;4e1b
        OR      A                       ;4e1d
        RET                             ;4e1e
m4e1f   INC     HL                      ;4e1f
        LD      A,(HL)                  ;4e20
        LD      (m4f46),A               ;4e21
        INC     HL                      ;4e24
        INC     HL                      ;4e25
        LD      A,(HL)                  ;4e26
        LD      (m4f58),A               ;4e27
        INC     HL                      ;4e2a
        RET                             ;4e2b
m4e2c   LD      B,00H                   ;4e2c
m4e2e   CALL    m4986                   ;4e2e
        LD      (m4f48),HL              ;4e31
        LD      A,B                     ;4e34
        LD      (m4f5e),A               ;4e35
        LD      HL,m51cd                ;4e38
        DEC     DE                      ;4e3b
        XOR     A                       ;4e3c
        CALL    m5121                   ;4e3d
        CP      2FH                     ;4e40
        LD      B,03H                   ;4e42
        CALL    m5123                   ;4e44
        CP      2EH                     ;4e47
        CALL    m5121                   ;4e49
        LD      B,00H                   ;4e4c
        LD      C,(IY+1FH)              ;4e4e
        CP      3AH                     ;4e51
        JR      NZ,m4e75                ;4e53
        INC     DE                      ;4e55
        LD      A,(DE)                  ;4e56
        SUB     30H                     ;4e57
        CP      0AH                     ;4e59
        JR      NC,m4e1b                ;4e5b
m4e5d   LD      C,A                     ;4e5d
        INC     DE                      ;4e5e
        LD      A,(DE)                  ;4e5f
        SUB     30H                     ;4e60
        CP      0AH                     ;4e62
        JR      NC,m4e74                ;4e64
        LD      L,A                     ;4e66
        LD      A,C                     ;4e67
        LD      B,09H                   ;4e68
m4e6a   ADD     A,C                     ;4e6a
        JR      C,m4e1b                 ;4e6b
        DJNZ    m4e6a                   ;4e6d
        ADD     A,L                     ;4e6f
        JR      NC,m4e5d                ;4e70
        JR      m4e1b                   ;4e72
m4e74   LD      B,C                     ;4e74
m4e75   JR      m4e7f                   ;4e75
        LD      A,C                     ;4e77
        CP      B                       ;4e78
        JR      Z,m4e1b                 ;4e79
        LD      B,(IY-78H)              ;4e7b
        LD      C,B                     ;4e7e
m4e7f   LD      (m4e09+1),BC            ;4e7f
        PUSH    BC                      ;4e83
        CALL    m5152                   ;4e84
        LD      (m51d8),HL              ;4e87
        LD      (m51da),HL              ;4e8a
        LD      HL,m51cd                ;4e8d
        LD      B,0BH                   ;4e90
        XOR     A                       ;4e92
m4e93   XOR     (HL)                    ;4e93
        INC     HL                      ;4e94
        RLCA                            ;4e95
        DJNZ    m4e93                   ;4e96
        JR      NZ,m4e9b                ;4e98
        INC     A                       ;4e9a
m4e9b   LD      (m4d6e),A               ;4e9b
        POP     AF                      ;4e9e
m4e9f   LD      (m4e0e),A               ;4e9f
        CALL    m5188                   ;4ea2
        JR      Z,m4eae                 ;4ea5
m4ea7   LD      E,18H                   ;4ea7
        CALL    m4e09                   ;4ea9
        JR      m4e9f                   ;4eac
m4eae   LD      DE,m51ad                ;4eae
        LD      BC,001FH                ;4eb1
m4eb4   LD      A,B                     ;4eb4
        SUB     C                       ;4eb5
        JR      Z,m4ea7                 ;4eb6
        LD      A,01H                   ;4eb8
        CALL    DIRSEC                  ;4eba
        RET     NZ                      ;4ebd
        LD      A,B                     ;4ebe
m4ebf   LD      B,A                     ;4ebf
        LD      (DE),A                  ;4ec0
        LD      L,A                     ;4ec1
        LD      A,E                     ;4ec2
        CP      0CCH                    ;4ec3
        JR      Z,m4edd                 ;4ec5
        LD      A,(m4d6e)               ;4ec7
        CP      (HL)                    ;4eca
        JR      NZ,m4ece                ;4ecb
        INC     DE                      ;4ecd
m4ece   LD      A,B                     ;4ece
        ADD     A,20H                   ;4ecf
        JR      NC,m4ebf                ;4ed1
        INC     A                       ;4ed3
        CP      C                       ;4ed4
        LD      B,A                     ;4ed5
        JR      C,m4ebf                 ;4ed6
m4ed8   LD      A,E                     ;4ed8
        CP      0ADH                    ;4ed9
        JR      Z,m4eb4                 ;4edb
m4edd   DEC     DE                      ;4edd
        LD      A,(DE)                  ;4ede
        LD      (m4f56),A               ;4edf
        CALL    FDEGET                  ;4ee2
        RET     NZ                      ;4ee5
        PUSH    DE                      ;4ee6
        PUSH    BC                      ;4ee7
        LD      A,(HL)                  ;4ee8
        LD      (m4f24),A               ;4ee9
        AND     90H                     ;4eec
        CP      10H                     ;4eee
        JR      NZ,m4f00                ;4ef0
        CALL    m4e1f                   ;4ef2
        LD      DE,m51cd                ;4ef5
        LD      B,0BH                   ;4ef8
m4efa   INC     HL                      ;4efa
        LD      A,(DE)                  ;4efb
        CP      (HL)                    ;4efc
        INC     DE                      ;4efd
        JR      Z,m4f04                 ;4efe
m4f00   POP     BC                      ;4f00
        POP     DE                      ;4f01
        JR      m4ed8                   ;4f02
m4f04   DJNZ    m4efa                   ;4f04
        POP     BC                      ;4f06
        POP     DE                      ;4f07
        INC     HL                      ;4f08
        LD      E,(HL)                  ;4f09
        INC     HL                      ;4f0a
        LD      D,(HL)                  ;4f0b
        INC     HL                      ;4f0c
        LD      C,(HL)                  ;4f0d
        INC     HL                      ;4f0e
        LD      B,(HL)                  ;4f0f
        INC     HL                      ;4f10
        PUSH    HL                      ;4f11
        LD      HL,(m51d8)              ;4f12
        BIT     7,(IY-14H)              ;4f15
        JR      Z,m4f2f                 ;4f19
        OR      A                       ;4f1b
        SBC     HL,DE                   ;4f1c
        JR      Z,m4f2f                 ;4f1e
        ADD     HL,DE                   ;4f20
        LD      A,07H                   ;4f21
        AND     00H                     ;4f23
        SBC     HL,BC                   ;4f25
        JR      Z,m4f30                 ;4f27
        POP     HL                      ;4f29
        LD      A,19H                   ;4f2a
        OR      A                       ;4f2c
        RET                             ;4f2d
m4f2e   PUSH    DE                      ;4f2e
m4f2f   XOR     A                       ;4f2f
m4f30   PUSH    IX                      ;4f30
        POP     HL                      ;4f32
        CALL    m5110                   ;4f33
        LD      (HL),80H                ;4f36
        INC     HL                      ;4f38
        OR      28H                     ;4f39
        LD      (HL),A                  ;4f3b
        LD      A,(m4f5e)               ;4f3c
        OR      A                       ;4f3f
        JR      Z,m4f44                 ;4f40
        SET     7,(HL)                  ;4f42
m4f44   INC     HL                      ;4f44
        LD      (HL),00H                ;4f45
        LD      DE,0000H                ;4f47
        INC     HL                      ;4f4a
        LD      (HL),E                  ;4f4b
        INC     HL                      ;4f4c
        LD      (HL),D                  ;4f4d
        INC     HL                      ;4f4e
        INC     HL                      ;4f4f
        LD      A,(IY-78H)              ;4f50
        LD      (HL),A                  ;4f53
        INC     HL                      ;4f54
        LD      (HL),00H                ;4f55
        LD      A,00H                   ;4f57
        INC     HL                      ;4f59
        OR      A                       ;4f5a
        LD      (HL),A                  ;4f5b
        INC     HL                      ;4f5c
        LD      (HL),00H                ;4f5d
        INC     HL                      ;4f5f
        INC     HL                      ;4f60
        INC     HL                      ;4f61
        POP     DE                      ;4f62
        LD      A,(DE)                  ;4f63
        INC     DE                      ;4f64
        JR      Z,m4f69                 ;4f65
        SUB     01H                     ;4f67
m4f69   LD      (HL),A                  ;4f69
        INC     HL                      ;4f6a
        LD      A,(DE)                  ;4f6b
        SBC     A,00H                   ;4f6c
        LD      (HL),A                  ;4f6e
        INC     DE                      ;4f6f
        INC     HL                      ;4f70
        LD      A,2CH                   ;4f71
        RET     C                       ;4f73
        CALL    m4f79                   ;4f74
        XOR     A                       ;4f77
        RET                             ;4f78
m4f79   EX      DE,HL                   ;4f79
m4f7a   LD      A,08H                   ;4f7a
        LD      C,A                     ;4f7c
        LD      B,00H                   ;4f7d
        LDIR                            ;4f7f
        RET                             ;4f81
m4f82   LD      A,3DH                   ;4f82
        BIT     7,(IX+02H)              ;4f84
        CALL    Z,DRVSLX                ;4f88
        JR      NZ,m4ffb                ;4f8b
        LD      A,(m486a)               ;4f8d
        LD      (m505e),A               ;4f90
        PUSH    AF                      ;4f93
        CALL    GETFDE                  ;4f94
        CALL    m5036                   ;4f97
        INC     DE                      ;4f9a
        PUSH    DE                      ;4f9b
        CALL    m50b4                   ;4f9c
        LD      B,(IY-71H)              ;4f9f
        LD      C,01H                   ;4fa2
        LD      E,(HL)                  ;4fa4
        INC     E                       ;4fa5
        JR      Z,m4fc5                 ;4fa6
        DEC     E                       ;4fa8
        DEC     E                       ;4fa9
        INC     HL                      ;4faa
        LD      A,(HL)                  ;4fab
        AND     1FH                     ;4fac
        LD      D,A                     ;4fae
        INC     D                       ;4faf
        LD      A,(HL)                  ;4fb0
        AND     0E0H                    ;4fb1
        DEC     HL                      ;4fb3
        RLCA                            ;4fb4
        RLCA                            ;4fb5
        RLCA                            ;4fb6
        ADD     A,D                     ;4fb7
m4fb8   INC     E                       ;4fb8
        SUB     B                       ;4fb9
        JR      NC,m4fb8                ;4fba
        ADD     A,B                     ;4fbc
        JR      Z,m4fc5                 ;4fbd
m4fbf   RLC     C                       ;4fbf
        DEC     B                       ;4fc1
        DEC     A                       ;4fc2
        JR      NZ,m4fbf                ;4fc3
m4fc5   PUSH    HL                      ;4fc5
        XOR     A                       ;4fc6
        CALL    DIRSEC                  ;4fc7
        JR      NZ,m4ffb                ;4fca
        LD      L,E                     ;4fcc
        POP     DE                      ;4fcd
        LD      A,01H                   ;4fce
m4fd0   EX      AF,AF'                  ;4fd0
        JR      m4fe5                   ;4fd1
m4fd3   LD      A,(HL)                  ;4fd3
        AND     C                       ;4fd4
        LD      A,(DE)                  ;4fd5
        JR      Z,m4ffd                 ;4fd6
        INC     A                       ;4fd8
        JR      NZ,m504c                ;4fd9
m4fdb   RLC     C                       ;4fdb
        DJNZ    m4fd3                   ;4fdd
        INC     L                       ;4fdf
        LD      B,(IY-71H)              ;4fe0
        LD      C,01H                   ;4fe3
m4fe5   LD      A,L                     ;4fe5
        CP      (IY-75H)                ;4fe6
        JR      C,m4fd3                 ;4fe9
        EX      AF,AF'                  ;4feb
        DEC     A                       ;4fec
        LD      L,A                     ;4fed
        JR      Z,m4fd0                 ;4fee
        BIT     0,(IY-15H)              ;4ff0
        JR      NZ,m502a                ;4ff4
        CALL    m508c                   ;4ff6
        LD      A,1BH                   ;4ff9
m4ffb   JR      m503d                   ;4ffb
m4ffd   INC     A                       ;4ffd
        JR      NZ,m5043                ;4ffe
        LD      A,L                     ;5000
        LD      (DE),A                  ;5001
        INC     DE                      ;5002
        LD      A,(IY-71H)              ;5003
        SUB     B                       ;5006
        RRCA                            ;5007
        RRCA                            ;5008
        RRCA                            ;5009
        DEC     A                       ;500a
m500b   INC     A                       ;500b
        LD      (DE),A                  ;500c
        DEC     DE                      ;500d
        LD      A,(HL)                  ;500e
        OR      C                       ;500f
        LD      (HL),A                  ;5010
        EX      (SP),HL                 ;5011
        DEC     HL                      ;5012
        LD      A,H                     ;5013
        OR      L                       ;5014
        EX      (SP),HL                 ;5015
        JR      NZ,m4fdb                ;5016
        LD      A,(IY-15H)              ;5018
        AND     03H                     ;501b
        JR      NZ,m502a                ;501d
        EX      (SP),HL                 ;501f
        INC     HL                      ;5020
        INC     HL                      ;5021
        INC     HL                      ;5022
        EX      (SP),HL                 ;5023
        SET     0,(IY-15H)              ;5024
        JR      m4fdb                   ;5028
m502a   RES     0,(IY-15H)              ;502a
        CALL    m508c                   ;502e
        POP     AF                      ;5031
        POP     AF                      ;5032
m5033   CALL    FDEGET                  ;5033
m5036   JR      NZ,m503d                ;5036
        BIT     4,(HL)                  ;5038
        RET     NZ                      ;503a
        LD      A,2CH                   ;503b
m503d   CALL    GSYSCL                  ;503d
        JP      ERRXIT                  ;5040
m5043   INC     DE                      ;5043
        LD      A,(DE)                  ;5044
        INC     A                       ;5045
        AND     1FH                     ;5046
        LD      A,(DE)                  ;5048
        JR      NZ,m500b                ;5049
        DEC     DE                      ;504b
m504c   INC     DE                      ;504c
        INC     DE                      ;504d
        LD      A,(DE)                  ;504e
        INC     A                       ;504f
        JR      Z,m4fd3                 ;5050
        BIT     0,(IY-15H)              ;5052
        JR      NZ,m502a                ;5056
        PUSH    HL                      ;5058
        PUSH    BC                      ;5059
        CALL    m508c                   ;505a
        LD      B,00H                   ;505d
        LD      L,B                     ;505f
        PUSH    BC                      ;5060
        CALL    m50cf                   ;5061
        JR      NZ,m503d                ;5064
        LD      C,A                     ;5066
        LD      (HL),90H                ;5067
        INC     HL                      ;5069
        POP     DE                      ;506a
        LD      (HL),D                  ;506b
        CALL    m50ae                   ;506c
        LD      A,D                     ;506f
        CALL    m5033                   ;5070
        ADD     A,1FH                   ;5073
        LD      L,A                     ;5075
        LD      (HL),C                  ;5076
        DEC     HL                      ;5077
        LD      (HL),0FEH               ;5078
        CALL    m50ae                   ;507a
        LD      A,C                     ;507d
        LD      (m505e),A               ;507e
        CALL    m5033                   ;5081
        CALL    m50b4                   ;5084
        POP     BC                      ;5087
        POP     DE                      ;5088
        JP      m4fc5                   ;5089
m508c   CALL    m50ae                   ;508c
        LD      A,(m505e)               ;508f
        CALL    m5033                   ;5092
        ADD     A,16H                   ;5095
        BIT     7,(HL)                  ;5097
        LD      L,A                     ;5099
        PUSH    HL                      ;509a
        PUSH    IX                      ;509b
        POP     HL                      ;509d
        LD      BC,000EH                ;509e
        ADD     HL,BC                   ;50a1
        LD      DE,m51ad                ;50a2
        PUSH    DE                      ;50a5
        CALL    Z,m4f79                 ;50a6
        POP     HL                      ;50a9
        POP     DE                      ;50aa
        CALL    m4f7a                   ;50ab
m50ae   CALL    m491f                   ;50ae
        RET     Z                       ;50b1
        JR      m503d                   ;50b2
m50b4   ADD     A,16H                   ;50b4
        LD      L,A                     ;50b6
        LD      DE,m51ad                ;50b7
        CALL    m4f7a                   ;50ba
        EX      DE,HL                   ;50bd
        LD      (HL),0FEH               ;50be
        RRCA                            ;50c0
        LD      B,A                     ;50c1
m50c2   DEC     HL                      ;50c2
        DEC     HL                      ;50c3
        LD      A,(HL)                  ;50c4
        INC     A                       ;50c5
        RET     NZ                      ;50c6
        DJNZ    m50c2                   ;50c7
        RET                             ;50c9
m50ca   LD      A,D                     ;50ca
        CALL    DRVSEL                  ;50cb
        RET     NZ                      ;50ce
m50cf   EX      DE,HL                   ;50cf
        LD      A,01H                   ;50d0
        CALL    DIRSEC                  ;50d2
        RET     NZ                      ;50d5
        LD      A,(DIRLEN)              ;50d6
        ADD     A,08H                   ;50d9
        LD      C,A                     ;50db
        LD      A,B                     ;50dc
        AND     1FH                     ;50dd
m50df   SUB     C                       ;50df
        JR      NC,m50df                ;50e0
        ADD     A,C                     ;50e2
m50e3   LD      B,A                     ;50e3
        LD      L,A                     ;50e4
        JR      m50f2                   ;50e5
m50e7   LD      A,(HL)                  ;50e7
        OR      A                       ;50e8
        JR      Z,m50fe                 ;50e9
        LD      A,L                     ;50eb
        ADD     A,20H                   ;50ec
        LD      L,A                     ;50ee
        JR      NC,m50e7                ;50ef
        INC     L                       ;50f1
m50f2   LD      A,L                     ;50f2
        CP      C                       ;50f3
        JR      C,m50e7                 ;50f4
        XOR     A                       ;50f6
        INC     B                       ;50f7
        DEC     B                       ;50f8
        JR      NZ,m50e3                ;50f9
        OR      1AH                     ;50fb
        RET                             ;50fd
m50fe   LD      A,(DE)                  ;50fe
        LD      (HL),A                  ;50ff
        LD      C,L                     ;5100
        CALL    m491f                   ;5101
        RET     NZ                      ;5104
        LD      A,C                     ;5105
        CALL    GETFDE                  ;5106
        RET     NZ                      ;5109
        BIT     4,(HL)                  ;510a
        LD      A,2CH                   ;510c
        RET     NZ                      ;510e
        LD      A,C                     ;510f
m5110   LD      BC,0A16H                ;5110
        PUSH    HL                      ;5113
m5114   LD      (HL),00H                ;5114
        INC     HL                      ;5116
        DEC     C                       ;5117
        JR      NZ,m5114                ;5118
m511a   LD      (HL),0FFH               ;511a
        INC     HL                      ;511c
        DJNZ    m511a                   ;511d
        POP     HL                      ;511f
        RET                             ;5120
m5121   LD      B,08H                   ;5121
m5123   JR      NZ,m5140                ;5123
        CALL    m5146                   ;5125
        JR      C,m513b                 ;5128
m512a   LD      (HL),A                  ;512a
        INC     HL                      ;512b
        CALL    m5146                   ;512c
        JR      NC,m5139                ;512f
        CP      30H                     ;5131
        JR      C,m5143                 ;5133
        CP      3AH                     ;5135
        JR      NC,m5143                ;5137
m5139   DJNZ    m512a                   ;5139
m513b   POP     AF                      ;513b
        LD      A,30H                   ;513c
        OR      A                       ;513e
        RET                             ;513f
m5140   LD      (HL),20H                ;5140
        INC     HL                      ;5142
m5143   DJNZ    m5140                   ;5143
        RET                             ;5145
m5146   INC     DE                      ;5146
        LD      A,(DE)                  ;5147
        CALL    UPCASE                  ;5148
        CP      41H                     ;514b
        RET     C                       ;514d
        CP      5FH                     ;514e
        CCF                             ;5150
        RET                             ;5151
m5152   LD      HL,m51df                ;5152
m5155   PUSH    DE                      ;5155
        PUSH    BC                      ;5156
        LD      DE,0FFFFH               ;5157
        LD      B,08H                   ;515a
m515c   PUSH    BC                      ;515c
        LD      A,E                     ;515d
        AND     07H                     ;515e
        LD      C,A                     ;5160
        LD      A,E                     ;5161
        RLCA                            ;5162
        RLCA                            ;5163
        RLCA                            ;5164
        XOR     C                       ;5165
        RLCA                            ;5166
        LD      C,A                     ;5167
        AND     0F0H                    ;5168
        LD      B,A                     ;516a
        LD      A,C                     ;516b
        RLCA                            ;516c
        AND     1FH                     ;516d
        XOR     B                       ;516f
        XOR     D                       ;5170
        LD      E,A                     ;5171
        LD      A,C                     ;5172
        AND     0FH                     ;5173
        LD      B,A                     ;5175
        LD      A,C                     ;5176
        RLCA                            ;5177
        RLCA                            ;5178
        RLCA                            ;5179
        RLCA                            ;517a
        XOR     B                       ;517b
        POP     BC                      ;517c
        XOR     (HL)                    ;517d
        LD      D,A                     ;517e
        LD      (HL),20H                ;517f
        DEC     HL                      ;5181
        DJNZ    m515c                   ;5182
        EX      DE,HL                   ;5184
        POP     BC                      ;5185
        POP     DE                      ;5186
        RET                             ;5187
m5188   PUSH    AF                      ;5188
        LD      A,(DDRVSL)              ;5189
        CP      3EH                     ;518c
        JR      Z,m519f                 ;518e
        LD      HL,(m4e09+1)            ;5190
        LD      A,H                     ;5193
        CP      L                       ;5194
        JR      Z,m519f                 ;5195
        POP     AF                      ;5197
        LD      HL,DTABH                ;5198
        ADD     A,L                     ;519b
        LD      L,A                     ;519c
        LD      A,(HL)                  ;519d
        PUSH    AF                      ;519e
m519f   POP     AF                      ;519f
        JP      DSKTST                  ;51a0
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
        END     4d00h
