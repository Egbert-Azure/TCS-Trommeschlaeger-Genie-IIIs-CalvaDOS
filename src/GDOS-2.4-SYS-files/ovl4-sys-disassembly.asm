;************************************************************************
;
; OVL4/SYS from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: ovl4-sys-disassembly.asm
;
;************************************************************************
; OVL4/SYS, stock GDOS 2.4 -- the Genie IIIs machine overlay.
;
; Opened by SYS0/SYS's own bank-switch at 3200h-32FBh when the on-disk
; filename template "OVLx/SYS:0" is read with 'x'='4' (SYS0/SYS 3278h,
; patched at 327Eh to open drive 5 instead of drive 0). See
; sys0-sys-disassembly.asm.
;
; Grosser coverage: none (floppy only, GDOS 2.1c)
;
; Entry 4D41h. 58 load records, not contiguous, 0056h-5107h. Two are
; substantial: 32C0h-32FDh (62 bytes, inside SYS0/SYS's bank-switch
; window) and 4D3Ch-5107h (972 bytes, this file's own body). Each
; record keeps its own ORG below, in address order.
;
;   z80dasm -l -a -t, one run per record
;
; This is the module as this port patches it, not stock: see the
; [PATCH] boxes at 32ECh and 4D30h.
;
; Boxed annotations sit above the line they describe:
;
;   [PATCH]  a departure from stock GDOS 2.4, with the stock bytes,
;            this build's bytes and the reason for the change.
;   [note]   not from Grosser -- either a finding here, or a place
;            GDOS 2.4 diverges from his 2.1c (his ch.9.4.2).



m3637   EQU     3637h
m37a0   EQU     37a0h
m37f0   EQU     37f0h
m37f1   EQU     37f1h
m37f6   EQU     37f6h
m37f8   EQU     37f8h
m37f9   EQU     37f9h
m37fa   EQU     37fah
m37fc   EQU     37fch
m37fe   EQU     37feh
m37ff   EQU     37ffh
m3800   EQU     3800h
m3840   EQU     3840h
m3860   EQU     3860h
m3880   EQU     3880h
m38e0   EQU     38e0h
m3c00   EQU     3c00h
m3d00   EQU     3d00h
m3d09   EQU     3d09h
m3d10   EQU     3d10h
m3d76   EQU     3d76h
m3d7e   EQU     3d7eh
m3d8c   EQU     3d8ch
m3d99   EQU     3d99h
m3db5   EQU     3db5h
m3db9   EQU     3db9h
m3dbc   EQU     3dbch
m3dca   EQU     3dcah
m3dd2   EQU     3dd2h
m3dd3   EQU     3dd3h
m3ddd   EQU     3dddh
m3e10   EQU     3e10h
m3e24   EQU     3e24h
m3e35   EQU     3e35h
m3e54   EQU     3e54h
m3e75   EQU     3e75h
m3e7b   EQU     3e7bh
m3e88   EQU     3e88h
m3e97   EQU     3e97h
m3ebc   EQU     3ebch
m3ed4   EQU     3ed4h
m3ef5   EQU     3ef5h
m3f0a   EQU     3f0ah
m3f19   EQU     3f19h
m3f2c   EQU     3f2ch
m3f39   EQU     3f39h
m3f3f   EQU     3f3fh
m3ff0   EQU     3ff0h
m4000   EQU     4000h
m4019   EQU     4019h
m401a   EQU     401ah
VIDCUR  EQU     4020h		;screen DCB: cursor address
CURFLG  EQU     4022h		;video DCB: cursor on/off
VIDTOP  EQU     4023h		;video DCB: number of header lines
m403d   EQU     403dh
m4041   EQU     4041h
m409d   EQU     409dh
m409f   EQU     409fh
SECBUF  EQU     4200h		;DOS sector buffer
DFLAG0  EQU     4369h		;DOS flags: DEBUG, CHAINING, BREAK key, RUN-ONLY (Grosser ch.3)
m436e   EQU     436eh
m4402   EQU     4402h
m441c   EQU     441ch
m4423   EQU     4423h
USRFCB  EQU     4480h		;FCB for loading and starting user programs
m44a7   EQU     44a7h
m44cc   EQU     44cch
m44d9   EQU     44d9h
m4501   EQU     4501h
m4502   EQU     4502h
m4505   EQU     4505h
m4529   EQU     4529h
m4548   EQU     4548h
m454a   EQU     454ah
m454f   EQU     454fh
m4555   EQU     4555h
m455e   EQU     455eh
m4588   EQU     4588h
m45b4   EQU     45b4h
m45be   EQU     45beh
m45bf   EQU     45bfh
m4698   EQU     4698h
m469a   EQU     469ah
m46a5   EQU     46a5h
DRVSEL  EQU     4776h		;select a drive
m4798   EQU     4798h
m4799   EQU     4799h
MULOV   EQU     4c94h		;HL * A, overflow
m4cb4   EQU     4cb4h
m4cef   EQU     4cefh
m4cf9   EQU     4cf9h
m068f   EQU     068fh		;operand byte inside this module -- self-modified code
m069b   EQU     069bh		;operand byte inside this module -- self-modified code
m3402   EQU     3402h		;operand byte inside this module -- self-modified code
m354c   EQU     354ch		;operand byte inside this module -- self-modified code
m357d   EQU     357dh		;operand byte inside this module -- self-modified code
m361b   EQU     361bh		;operand byte inside this module -- self-modified code
m3626   EQU     3626h		;operand byte inside this module -- self-modified code
        ORG     0056h
        DEC     BC                      ;0056
        ORG     00fch
        NOP                             ;00fc
        NOP                             ;00fd
        NOP                             ;00fe
        ORG     010ch
m010c   CALL    m06b5                   ;010c
        CALL    0060H                   ;010f
        JP      m06be                   ;0112
m0115   CALL    m010c                   ;0115
m0118   CALL    m06a0                   ;0118
        CALL    m3ddd                   ;011b
m011e   JP      m06ab                   ;011e
m0121   IN      A,(0FAH)                ;0121
        RES     0,A                     ;0123
        OUT     (0FAH),A                ;0125
        LD      A,(BC)                  ;0127
        JP      m06a0                   ;0128
        ORG     015bh
        OR      A                       ;015b
        RRA                             ;015c
        LD      E,A                     ;015d
m015e   LD      A,C                     ;015e
        ADC     A,A                     ;015f
        INC     A                       ;0160
        LD      B,A                     ;0161
        XOR     A                       ;0162
        SCF                             ;0163
m0164   ADC     A,A                     ;0164
        DJNZ    m0164                   ;0165
        LD      C,A                     ;0167
        JP      m36b0                   ;0168
m016b   EX      DE,HL                   ;016b
        CALL    m3643                   ;016c
        BIT     7,A                     ;016f
        JR      NZ,m0175                ;0171
        LD      A,80H                   ;0173
m0175   LD      B,A                     ;0175
        POP     AF                      ;0176
        OR      A                       ;0177
        LD      A,B                     ;0178
        JR      Z,m0192                 ;0179
        CALL    m3649                   ;017b
        JP      M,m018f                 ;017e
        LD      A,C                     ;0181
        CPL                             ;0182
        LD      C,A                     ;0183
        CALL    m3643                   ;0184
        AND     C                       ;0187
m0188   CALL    m3649                   ;0188
m018b   EX      DE,HL                   ;018b
        RST     8                       ;018c
        ADD     HL,HL                   ;018d
        RET                             ;018e
m018f   OR      C                       ;018f
        JR      m0188                   ;0190
m0192   AND     C                       ;0192
        ADD     A,0FFH                  ;0193
        SBC     A,A                     ;0195
        PUSH    HL                      ;0196
        CALL    098DH                   ;0197
        POP     HL                      ;019a
        JR      m018b                   ;019b
        ORG     022ch
        JP      m36cb                   ;022c
        ORG     0348h
        PUSH    HL                      ;0348
        PUSH    DE                      ;0349
        LD      HL,(VIDCUR)             ;034a
        CALL    m3681                   ;034d
        POP     DE                      ;0350
        POP     HL                      ;0351
        RET                             ;0352
        ORG     044fh
        CALL    m0115                   ;044f
        NOP                             ;0452
        ORG     045eh
        LD      DE,(m3641)              ;045e
        PUSH    AF                      ;0462
        ADD     HL,DE                   ;0463
        POP     AF                      ;0464
        JP      m3442                   ;0465
        ORG     0480h
        PUSH    HL                      ;0480
        LD      DE,(m3641)              ;0481
        OR      A                       ;0485
        SBC     HL,DE                   ;0486
        LD      (IX+04H),H              ;0488
        LD      (IX+03H),L              ;048b
        POP     HL                      ;048e
        LD      A,(IX+05H)              ;048f
        OR      A                       ;0492
        LD      B,20H                   ;0493
        JP      Z,m347e                 ;0495
        CALL    m3643                   ;0498
        OR      A                       ;049b
        JR      NZ,m049f                ;049c
        INC     A                       ;049e
m049f   LD      (IX+05H),A              ;049f
        JP      m3465                   ;04a2
        ORG     04b8h
        LD      A,0AFH                  ;04b8
        LD      (IX+05H),A              ;04ba
        RET                             ;04bd
        NOP                             ;04be
        NOP                             ;04bf
m04c0   CALL    m3491                   ;04c0
        ORG     04ceh
m04ce   CALL    m3540                   ;04ce
        CALL    NZ,m04d4                ;04d1
m04d4   DEC     HL                      ;04d4
        JP      m34cd                   ;04d5
        NOP                             ;04d8
        NOP                             ;04d9
        CALL    m3540                   ;04da
        CALL    NZ,m04e0                ;04dd
m04e0   PUSH    HL                      ;04e0
        CALL    m355b                   ;04e1
        EX      DE,HL                   ;04e4
        POP     HL                      ;04e5
        RST     18H                     ;04e6
        DEC     HL                      ;04e7
        RET     NZ                      ;04e8
        JP      m34e8                   ;04e9
        JP      m34d7                   ;04ec
        JP      m34fb                   ;04ef
        ORG     0501h
        RES     0,L                     ;0501
        JP      m3514                   ;0503
        ORG     050ah
        JP      m340d                   ;050a
        NOP                             ;050d
        ORG     0515h
        JR      Z,$-93                  ;0515
        CP      0FH                     ;0517
        JR      Z,$-96                  ;0519
        ORG     0521h
        JR      Z,$-71                  ;0521
        CP      19H                     ;0523
        JR      Z,$-57                  ;0525
        CP      1AH                     ;0527
        JR      Z,$-64                  ;0529
        CP      1BH                     ;052b
        JR      Z,$-62                  ;052d
        ORG     0536h
        LD      E,E                     ;0536
        DEC     (HL)                    ;0537
        ORG     053ah
        JR      Z,$+49                  ;053a
        CP      1FH                     ;053c
        JR      Z,$+53                  ;053e
        ORG     0541h
        LD      C,A                     ;0541
        LD      A,(m340a)               ;0542
        XOR     C                       ;0545
        CALL    m3649                   ;0546
        INC     HL                      ;0549
        CALL    m3540                   ;054a
        JR      Z,m0553                 ;054d
        CALL    m364f                   ;054f
        INC     HL                      ;0552
m0553   LD      DE,(m3406)              ;0553
        RST     18H                     ;0557
        RET     C                       ;0558
        LD      BC,(m340b)              ;0559
        LD      B,00H                   ;055d
        SBC     HL,BC                   ;055f
        JP      m351f                   ;0561
m0564   CALL    m3562                   ;0564
        CALL    m0553                   ;0567
        RET     Z                       ;056a
m056b   CALL    m3562                   ;056b
        JR      m0577                   ;056e
m0570   CALL    m04c0                   ;0570
        EX      DE,HL                   ;0573
        LD      HL,(m3406)              ;0574
m0577   OR      A                       ;0577
        SBC     HL,DE                   ;0578
        LD      C,L                     ;057a
        LD      B,H                     ;057b
        LD      L,E                     ;057c
        LD      H,D                     ;057d
        RET     C                       ;057e
        RET     Z                       ;057f
        CALL    m364f                   ;0580
        INC     DE                      ;0583
        DEC     BC                      ;0584
        LD      A,B                     ;0585
        OR      C                       ;0586
        RET     Z                       ;0587
        BIT     7,B                     ;0588
        JP      m3539                   ;058a
        ORG     0591h
        CP      0CH                     ;0591
        JR      Z,m05a1                 ;0593
        CP      0BH                     ;0595
        JR      NZ,$+29                 ;0597
        BIT     7,(IX-08H)              ;0599
        LD      A,0DH                   ;059d
        JR      NZ,$+21                 ;059f
m05a1   LD      A,(IX+03H)              ;05a1
        SUB     (IX+04H)                ;05a4
        LD      B,A                     ;05a7
m05a8   LD      A,0AH                   ;05a8
        CALL    05B4H                   ;05aa
        DJNZ    m05a8                   ;05ad
        JR      $+29                    ;05af
        ORG     068eh
m068e   RES     4,(HL)                  ;068e
        BIT     6,B                     ;0690
        RET     NZ                      ;0692
        POP     AF                      ;0693
        JP      m46a5                   ;0694
m0697   LD      L,09H                   ;0697
        LD      E,A                     ;0699
        LD      A,10H                   ;069a
        AND     (HL)                    ;069c
        OR      E                       ;069d
        LD      (HL),A                  ;069e
        RET                             ;069f
m06a0   PUSH    AF                      ;06a0
        NOP                             ;06a1
        IN      A,(0FAH)                ;06a2
        SET     0,A                     ;06a4
        DI                              ;06a6
        OUT     (0FAH),A                ;06a7
        POP     AF                      ;06a9
        RET                             ;06aa
m06ab   PUSH    AF                      ;06ab
        IN      A,(0FAH)                ;06ac
        RES     0,A                     ;06ae
        OUT     (0FAH),A                ;06b0
        POP     AF                      ;06b2
        EI                              ;06b3
        RET                             ;06b4
m06b5   PUSH    AF                      ;06b5
        IN      A,(0FAH)                ;06b6
        RES     6,A                     ;06b8
        OUT     (0FAH),A                ;06ba
        POP     AF                      ;06bc
        RET                             ;06bd
m06be   PUSH    AF                      ;06be
        IN      A,(0FAH)                ;06bf
        SET     6,A                     ;06c1
        OUT     (0FAH),A                ;06c3
        POP     AF                      ;06c5
        RET                             ;06c6
        ORG     2000h
        ADC     A,E                     ;2000
        ORG     2079h
        PUSH    HL                      ;2079
        JP      m369b                   ;207a
        ORG     2086h
        CALL    m3681                   ;2086
        ORG     213ah
        AND     0FFH                    ;213a
        ORG     32c0h
; ------------------------------------------------------------
; [note]      32C0h: loads into SYS0/SYS's own bank-switch window
;             (3200h-32FBh), active only while SYS0/SYS has that
;             window bank-switched in. Not OVL4/SYS's own body
;             (that's 4D3Ch, entry 4D41h). 32C3h-32CEh: ASCII
;             "STD:0 \r". What writes 32C0h-32C2h before 32F5h's
;             print loop reads them: unknown.
; ------------------------------------------------------------
m32c0   DJNZ    m32c2                   ;32c0
m32c2   NOP                             ;32c2
m32c3   LD      D,E                     ;32c3
        LD      D,H                     ;32c4
        LD      B,H                     ;32c5
        LD      A,(2030H)               ;32c6
        JR      NZ,$+34                 ;32c9
        JR      NZ,$+34                 ;32cb
        JR      NZ,m32dc                ;32cd
m32cf   LD      HL,m32c3                ;32cf
        LD      DE,USRFCB               ;32d2
        CALL    m441c                   ;32d5
        EXX                             ;32d8
        LD      DE,USRFCB               ;32d9
m32dc   LD      HL,SECBUF               ;32dc
        LD      B,00H                   ;32df
        CALL    m4423                   ;32e1
        JR      NZ,m32ec                ;32e4
        EXX                             ;32e6
        LD      A,78H                   ;32e7
        CALL    m4402                   ;32e9
; ------------------------------------------------------------
; [PATCH]     32ECh
; Stock:      AF CD 76 47   XOR A / CALL DRVSEL (drive 0)
; This build: CD 30 4D 00   CALL 4D30h stub / NOP
; Reason:     Drive 0 doesn't exist here. 4 bytes, no room for
;             LD A,05h+CALL inline -- stub redirect. SYS26/SYS's
;             stub (50D0h) unreachable: inside 4D00h-51E7h, which
;             OVL4/SYS overwrites while resident.
; ------------------------------------------------------------
m32ec   CALL    m4d30                   ;32ec
        NOP                             ;32ef
        LD      B,03H                   ;32f0
        LD      HL,m32c0                ;32f2
m32f5   LD      A,(HL)                  ;32f5
        CALL    0033H                   ;32f6
        INC     HL                      ;32f9
        DJNZ    m32f5                   ;32fa
        XOR     A                       ;32fc
        RET                             ;32fd
        ORG     3400h
m3400   NOP                             ;3400
        JR      C,m3403                 ;3401
m3403   NOP                             ;3403
m3404   NOP                             ;3404
        NOP                             ;3405
m3406   NOP                             ;3406
        NOP                             ;3407
m3408   NOP                             ;3408
        NOP                             ;3409
m340a   NOP                             ;340a
m340b   LD      B,B                     ;340b
        NOP                             ;340c
m340d   CP      07H                     ;340d
        JP      Z,m3575                 ;340f
        CP      08H                     ;3412
        JP      Z,m04ce                 ;3414
        CP      09H                     ;3417
        JP      Z,m3587                 ;3419
        CP      0BH                     ;341c
        JP      Z,m356d                 ;341e
        CP      10H                     ;3421
        JP      Z,m34a1                 ;3423
        CP      11H                     ;3426
        JP      Z,m34a6                 ;3428
        CP      12H                     ;342b
        JP      Z,m3497                 ;342d
        CP      13H                     ;3430
        JP      Z,m349c                 ;3432
        CP      15H                     ;3435
        JP      Z,m354c                 ;3437
        CP      16H                     ;343a
        JP      Z,m3546                 ;343c
        JP      050EH                   ;343f
m3442   JP      C,m3643                 ;3442
        LD      DE,(m3406)              ;3445
        RST     18H                     ;3449
        JR      C,m3450                 ;344a
        EX      DE,HL                   ;344c
        DEC     HL                      ;344d
        JR      m3458                   ;344e
m3450   LD      DE,(m3402)              ;3450
        RST     18H                     ;3454
        JR      NC,m3458                ;3455
        EX      DE,HL                   ;3457
m3458   PUSH    BC                      ;3458
        CALL    m3540                   ;3459
        JR      Z,m3461                 ;345c
        INC     HL                      ;345e
        RES     0,L                     ;345f
m3461   LD      A,C                     ;3461
        JP      0468H                   ;3462
m3465   LD      DE,m3800                ;3465
        OR      A                       ;3468
        SBC     HL,DE                   ;3469
        LD      A,H                     ;346b
        LD      (m37fe),A               ;346c
        LD      A,L                     ;346f
        LD      (m37ff),A               ;3470
        LD      B,00H                   ;3473
        LD      A,(m4502)               ;3475
        CP      0C9H                    ;3478
        JR      Z,m347e                 ;347a
        LD      B,60H                   ;347c
m347e   LD      HL,m37fa                ;347e
        LD      A,(HL)                  ;3481
        AND     0FH                     ;3482
        OR      B                       ;3484
        LD      (HL),A                  ;3485
        LD      A,0AH                   ;3486
        LD      B,06H                   ;3488
        CALL    m3551                   ;348a
        POP     BC                      ;348d
        XOR     A                       ;348e
        LD      A,C                     ;348f
        RET                             ;3490
m3491   CALL    m06a0                   ;3491
        JP      m3f3f                   ;3494
m3497   LD      HL,m3790                ;3497
        JR      m34a9                   ;349a
m349c   LD      HL,m3760                ;349c
        JR      m34a9                   ;349f
m34a1   LD      HL,m3770                ;34a1
        JR      m34a9                   ;34a4
m34a6   LD      HL,m3780                ;34a6
m34a9   LD      DE,m37f0                ;34a9
        LD      BC,0010H                ;34ac
        LDIR                            ;34af
        XOR     A                       ;34b1
        LD      (IX+06H),A              ;34b2
        LD      (IX+07H),A              ;34b5
        LD      (m340a),A               ;34b8
        CALL    m0570                   ;34bb
        LD      A,(2FFBH)               ;34be
        AND     01H                     ;34c1
        RET     NZ                      ;34c3
        LD      A,(DFLAG0)              ;34c4
        BIT     6,A                     ;34c7
        RET     NZ                      ;34c9
        LD      A,38H                   ;34ca
        RST     28H                     ;34cc
m34cd   LD      DE,(m3402)              ;34cd
        RST     18H                     ;34d1
        JP      NC,m364f                ;34d2
        INC     HL                      ;34d5
        RET                             ;34d6
m34d7   CALL    m3540                   ;34d7
        CALL    NZ,m34dd                ;34da
m34dd   INC     HL                      ;34dd
        PUSH    HL                      ;34de
        CALL    m355b                   ;34df
        EX      DE,HL                   ;34e2
        POP     HL                      ;34e3
        RST     18H                     ;34e4
        JR      Z,m34fb                 ;34e5
        RET                             ;34e7
m34e8   LD      DE,(m340b)              ;34e8
        ADD     HL,DE                   ;34ec
        LD      DE,(m3406)              ;34ed
        RST     18H                     ;34f1
        RET     C                       ;34f2
        CALL    m3681                   ;34f3
        LD      HL,(m3402)              ;34f6
        ADD     HL,DE                   ;34f9
        RET                             ;34fa
m34fb   LD      DE,(m340b)              ;34fb
        XOR     A                       ;34ff
        SBC     HL,DE                   ;3500
        LD      DE,(m3402)              ;3502
        RST     18H                     ;3506
        RET     NC                      ;3507
        LD      A,(1916H)               ;3508
        LD      B,A                     ;350b
m350c   PUSH    BC                      ;350c
        CALL    m34e8                   ;350d
        POP     BC                      ;3510
        DJNZ    m350c                   ;3511
        RET                             ;3513
m3514   LD      A,(m340b)               ;3514
        RRA                             ;3517
        LD      (m409d),A               ;3518
        LD      (1914H),A               ;351b
        RET                             ;351e
m351f   PUSH    HL                      ;351f
        LD      HL,(m3402)              ;3520
        PUSH    HL                      ;3523
        ADD     HL,BC                   ;3524
        EX      DE,HL                   ;3525
        OR      A                       ;3526
        SBC     HL,DE                   ;3527
        LD      C,L                     ;3529
        LD      B,H                     ;352a
        EX      DE,HL                   ;352b
        POP     DE                      ;352c
        LD      A,B                     ;352d
        OR      C                       ;352e
        CALL    NZ,m3656                ;352f
        EX      DE,HL                   ;3532
        CALL    m056b                   ;3533
        POP     HL                      ;3536
        XOR     A                       ;3537
        RET                             ;3538
m3539   RET     NZ                      ;3539
        PUSH    HL                      ;353a
        CALL    m3656                   ;353b
        POP     HL                      ;353e
        RET                             ;353f
m3540   LD      A,(m403d)               ;3540
        AND     08H                     ;3543
        RET                             ;3545
m3546   LD      A,(m340a)               ;3546
        XOR     80H                     ;3549
        CP      0AFH                    ;354b
        LD      (m340a),A               ;354d
        RET                             ;3550
m3551   LD      C,0F7H                  ;3551
m3553   OUT     (0F6H),A                ;3553
        INC     A                       ;3555
        OUTI                            ;3556
        JR      NZ,m3553                ;3558
        RET                             ;355a
m355b   CALL    m367b                   ;355b
        OR      A                       ;355e
        SBC     HL,DE                   ;355f
        RET                             ;3561
m3562   PUSH    HL                      ;3562
        CALL    m355b                   ;3563
        LD      DE,(m340b)              ;3566
        ADD     HL,DE                   ;356a
        POP     DE                      ;356b
        RET                             ;356c
m356d   CALL    m367b                   ;356d
        OR      A                       ;3570
        RET     Z                       ;3571
        JP      m0564                   ;3572
m3575   DI                              ;3575
        LD      B,0FFH                  ;3576
m3578   PUSH    BC                      ;3578
        LD      A,(m3860)               ;3579
        LD      BC,0000H                ;357c
        CALL    0060H                   ;357f
        POP     BC                      ;3582
        DJNZ    m3578                   ;3583
        EI                              ;3585
        RET                             ;3586
m3587   CALL    m367b                   ;3587
        LD      E,A                     ;358a
        AND     0F8H                    ;358b
        ADD     A,08H                   ;358d
        SUB     E                       ;358f
        POP     DE                      ;3590
        JP      04ACH                   ;3591
m3594   LD      HL,m3637                ;3594
        CALL    m44a7                   ;3597
        LD      HL,(m3400)              ;359a
        LD      DE,(m340b)              ;359d
        ADD     HL,DE                   ;35a1
        LD      DE,000BH                ;35a2
        SBC     HL,DE                   ;35a5
        EX      DE,HL                   ;35a7
        LD      BC,0008H                ;35a8
        XOR     A                       ;35ab
        LD      (m3628),A               ;35ac
        LD      HL,m3637                ;35af
        CALL    m3656                   ;35b2
        LD      A,0FBH                  ;35b5
        LD      (m3628),A               ;35b7
        RET                             ;35ba
        LD      E,B                     ;35bb
        LD      E,B                     ;35bc
        LD      E,B                     ;35bd
        LD      E,B                     ;35be
        LD      E,B                     ;35bf
        LD      E,B                     ;35c0
        LD      E,B                     ;35c1
        LD      E,B                     ;35c2
        LD      E,B                     ;35c3
        LD      E,B                     ;35c4
        LD      E,B                     ;35c5
        LD      E,B                     ;35c6
        LD      E,B                     ;35c7
        LD      E,B                     ;35c8
        LD      E,B                     ;35c9
        LD      E,B                     ;35ca
        LD      E,B                     ;35cb
        LD      E,B                     ;35cc
        LD      E,B                     ;35cd
        LD      E,B                     ;35ce
        LD      E,B                     ;35cf
        LD      E,B                     ;35d0
        LD      E,B                     ;35d1
        LD      E,B                     ;35d2
        LD      E,B                     ;35d3
        LD      E,B                     ;35d4
        LD      E,B                     ;35d5
        LD      E,B                     ;35d6
        LD      E,B                     ;35d7
        LD      E,B                     ;35d8
        LD      E,B                     ;35d9
        LD      E,B                     ;35da
        LD      E,B                     ;35db
        LD      E,B                     ;35dc
        LD      E,B                     ;35dd
        LD      E,B                     ;35de
        LD      E,B                     ;35df
        LD      E,B                     ;35e0
        LD      E,B                     ;35e1
        LD      E,B                     ;35e2
        LD      E,B                     ;35e3
        LD      E,B                     ;35e4
        LD      E,B                     ;35e5
        LD      E,B                     ;35e6
        LD      E,B                     ;35e7
        LD      E,B                     ;35e8
        LD      E,B                     ;35e9
        LD      E,B                     ;35ea
        LD      E,B                     ;35eb
        LD      E,B                     ;35ec
        LD      E,B                     ;35ed
        LD      E,B                     ;35ee
        LD      E,B                     ;35ef
        LD      E,B                     ;35f0
        LD      E,B                     ;35f1
        LD      E,B                     ;35f2
        LD      E,B                     ;35f3
        LD      E,B                     ;35f4
        LD      E,B                     ;35f5
        LD      E,B                     ;35f6
        LD      E,B                     ;35f7
        LD      E,B                     ;35f8
        LD      E,B                     ;35f9
        LD      E,B                     ;35fa
        LD      E,B                     ;35fb
        LD      E,B                     ;35fc
        LD      E,B                     ;35fd
        LD      E,B                     ;35fe
        LD      E,B                     ;35ff
        DEFB    0C4H,0D4H               ;3600
        ORG     3605h
m3605   DI                              ;3605
        EX      (SP),HL                 ;3606
        LD      (m361b),HL              ;3607
        POP     HL                      ;360a
        LD      (m3626),SP              ;360b
        LD      SP,m3641                ;360f
        PUSH    AF                      ;3612
        IN      A,(0FAH)                ;3613
        SET     4,A                     ;3615
        OUT     (0FAH),A                ;3617
        POP     AF                      ;3619
        JP      0000H                   ;361a
m361d   PUSH    AF                      ;361d
        IN      A,(0FAH)                ;361e
        RES     4,A                     ;3620
        OUT     (0FAH),A                ;3622
        POP     AF                      ;3624
        LD      SP,0000H                ;3625
m3628   EI                              ;3628
        RET                             ;3629
        ORG     3641h
m3641   NOP                             ;3641
        NOP                             ;3642
m3643   CALL    m3605                   ;3643
        LD      A,(HL)                  ;3646
        JR      m3678                   ;3647
m3649   CALL    m3605                   ;3649
        LD      (HL),A                  ;364c
        JR      m3678                   ;364d
m364f   CALL    m3605                   ;364f
        LD      (HL),20H                ;3652
        JR      m3678                   ;3654
m3656   CALL    m3605                   ;3656
        LDIR                            ;3659
        JR      m3678                   ;365b
        CALL    m3605                   ;365d
        LDDR                            ;3660
        JR      m3678                   ;3662
        CALL    m3605                   ;3664
        INC     (HL)                    ;3667
        JR      m3678                   ;3668
        CALL    m3605                   ;366a
        CPIR                            ;366d
        JR      m3678                   ;366f
        CALL    m3605                   ;3671
        CPDR                            ;3674
        JR      m3678                   ;3676
m3678   JP      m361d                   ;3678
m367b   LD      DE,(m3402)              ;367b
        JR      m3684                   ;367f
m3681   LD      DE,m3c00                ;3681
m3684   PUSH    HL                      ;3684
        XOR     A                       ;3685
        SBC     HL,DE                   ;3686
        LD      DE,(m340b)              ;3688
m368c   OR      A                       ;368c
        SBC     HL,DE                   ;368d
        JR      NC,m368c                ;368f
        ADD     HL,DE                   ;3691
        EX      DE,HL                   ;3692
        POP     HL                      ;3693
        CALL    m3540                   ;3694
        LD      A,E                     ;3697
        RET     Z                       ;3698
        RRA                             ;3699
        RET                             ;369a
m369b   PUSH    DE                      ;369b
        LD      HL,(m3406)              ;369c
        LD      DE,(m3400)              ;369f
        INC     DE                      ;36a3
        OR      A                       ;36a4
        SBC     HL,DE                   ;36a5
        POP     DE                      ;36a7
        RST     18H                     ;36a8
        POP     HL                      ;36a9
        JP      C,1E4AH                 ;36aa
        JP      207EH                   ;36ad
m36b0   PUSH    HL                      ;36b0
        PUSH    DE                      ;36b1
        LD      HL,(m3400)              ;36b2
        LD      B,D                     ;36b5
        INC     B                       ;36b6
        DEC     B                       ;36b7
        JR      Z,m36c3                 ;36b8
        LD      A,(m409d)               ;36ba
        LD      D,00H                   ;36bd
        LD      E,A                     ;36bf
m36c0   ADD     HL,DE                   ;36c0
        DJNZ    m36c0                   ;36c1
m36c3   POP     DE                      ;36c3
        LD      D,B                     ;36c4
        ADD     HL,DE                   ;36c5
        EX      DE,HL                   ;36c6
        POP     HL                      ;36c7
        JP      m016b                   ;36c8
m36cb   PUSH    HL                      ;36cb
        PUSH    DE                      ;36cc
        LD      HL,(m3400)              ;36cd
        LD      DE,(m340b)              ;36d0
        ADD     HL,DE                   ;36d4
        DEC     HL                      ;36d5
        CALL    m3643                   ;36d6
        CP      2AH                     ;36d9
        JR      Z,$+5                   ;36db
        LD      A,2AH                   ;36dd
        LD      DE,203EH                ;36df
        CALL    m3649                   ;36e2
        POP     DE                      ;36e5
        POP     HL                      ;36e6
        RET                             ;36e7
        ORG     3760h
m3760   LD      L,(HL)                  ;3760
        LD      D,B                     ;3761
        LD      D,(HL)                  ;3762
        INC     C                       ;3763
        RRA                             ;3764
        LD      (BC),A                  ;3765
        ADD     HL,DE                   ;3766
        INC     E                       ;3767
        LD      (BC),A                  ;3768
        ADD     HL,BC                   ;3769
m376a   ADD     HL,HL                   ;376a
        ADD     HL,BC                   ;376b
        NOP                             ;376c
        NOP                             ;376d
        NOP                             ;376e
        NOP                             ;376f
m3770   LD      L,(HL)                  ;3770
        LD      B,B                     ;3771
        LD      D,B                     ;3772
        LD      A,(BC)                  ;3773
        INC     D                       ;3774
        LD      B,10H                   ;3775
        LD      (DE),A                  ;3777
        LD      (BC),A                  ;3778
        LD      C,29H                   ;3779
        ADD     HL,BC                   ;377b
        INC     B                       ;377c
        NOP                             ;377d
        NOP                             ;377e
        NOP                             ;377f
m3780   LD      L,(HL)                  ;3780
        LD      B,B                     ;3781
        LD      D,B                     ;3782
        LD      A,(BC)                  ;3783
        DEC     DE                      ;3784
        ADD     HL,BC                   ;3785
        JR      $+28                    ;3786
        LD      (BC),A                  ;3788
        LD      A,(BC)                  ;3789
        ADD     HL,HL                   ;378a
        ADD     HL,BC                   ;378b
        LD      (BC),A                  ;378c
        NOP                             ;378d
        NOP                             ;378e
        NOP                             ;378f
m3790   LD      L,(HL)                  ;3790
        LD      B,B                     ;3791
        LD      D,B                     ;3792
        LD      A,(BC)                  ;3793
        INC     DE                      ;3794
        LD      (BC),A                  ;3795
        DJNZ    $+19                    ;3796
        INC     BC                      ;3798
        RRCA                            ;3799
        CPL                             ;379a
        RRCA                            ;379b
        NOP                             ;379c
        NOP                             ;379d
        NOP                             ;379e
m379f   NOP                             ;379f
        ORG     44a2h
        DEFB    30H                     ;44a2
        ORG     44a4h
        JP      m3594                   ;44a4
        ORG     44cbh
        DEFB    30H                     ;44cb
        ORG     44fbh
        RET                             ;44fb
        ORG     4506h
        NOP                             ;4506
        PUSH    AF                      ;4507
        LD      A,(m4505)               ;4508
        XOR     20H                     ;450b
        LD      (0473H),A               ;450d
        POP     AF                      ;4510
        NOP                             ;4511
        NOP                             ;4512
        ORG     4523h
        CALL    m06a0                   ;4523
        JP      m3d10                   ;4526
        ORG     4531h
        CALL    m0121                   ;4531
        ORG     4544h
        JP      m3d8c                   ;4544
        ORG     4551h
        JP      m3db9                   ;4551
        NOP                             ;4554
        ORG     4569h
        CALL    m0121                   ;4569
        ORG     457bh
        CALL    m3e10                   ;457b
        ORG     4581h
        CALL    m3dd2                   ;4581
        ORG     4589h
        CALL    m3d09                   ;4589
        CALL    m06a0                   ;458c
        ORG     4598h
        CP      1DH                     ;4598
        ORG     459bh
        PUSH    AF                      ;459b
        LD      BC,m38e0                ;459c
        CALL    m0121                   ;459f
        SUB     08H                     ;45a2
        JR      Z,m45a8                 ;45a4
        LD      A,0C9H                  ;45a6
m45a8   LD      (m45b4),A               ;45a8
        POP     AF                      ;45ab
        RET     NC                      ;45ac
        JR      $+5                     ;45ad
        ORG     4cf1h
        CALL    m010c                   ;4cf1
        XOR     A                       ;4cf4
        LD      E,A                     ;4cf5
        RET                             ;4cf6
        NOP                             ;4cf7
        ORG     4d00h
; ------------------------------------------------------------
; [note]      4D00h: keyboard char-substitution table, 48 bytes.
;             Copied to 37A0h by 4DB4h (LD HL,4D00h/DE,37A0h/
;             BC,30h/LDIR). Walked by 3DDDh, called from 011Bh
;             (scancode->ASCII). Stock: 5Eh->7Eh, 7Eh->7Fh,
;             7Fh->5Eh, 00h terminator at 4D06h, 00h pad to
;             4D2Fh -- stub goes in the pad, see [PATCH] below.
; ------------------------------------------------------------
m4d00   LD      E,(HL)                  ;4d00
        LD      A,(HL)                  ;4d01
        LD      A,(HL)                  ;4d02
        LD      A,A                     ;4d03
        LD      A,A                     ;4d04
        LD      E,(HL)                  ;4d05
        NOP                             ;4d06
        NOP                             ;4d07
        NOP                             ;4d08
        NOP                             ;4d09
        NOP                             ;4d0a
        NOP                             ;4d0b
        NOP                             ;4d0c
        NOP                             ;4d0d
        NOP                             ;4d0e
        NOP                             ;4d0f
        NOP                             ;4d10
        NOP                             ;4d11
        NOP                             ;4d12
        NOP                             ;4d13
        NOP                             ;4d14
        NOP                             ;4d15
        NOP                             ;4d16
        NOP                             ;4d17
        NOP                             ;4d18
        NOP                             ;4d19
        NOP                             ;4d1a
        NOP                             ;4d1b
        NOP                             ;4d1c
        NOP                             ;4d1d
        NOP                             ;4d1e
        NOP                             ;4d1f
        NOP                             ;4d20
        NOP                             ;4d21
        NOP                             ;4d22
        NOP                             ;4d23
        NOP                             ;4d24
        NOP                             ;4d25
        NOP                             ;4d26
        NOP                             ;4d27
        NOP                             ;4d28
        NOP                             ;4d29
        NOP                             ;4d2a
        NOP                             ;4d2b
        NOP                             ;4d2c
        NOP                             ;4d2d
        NOP                             ;4d2e
        NOP                             ;4d2f
; ------------------------------------------------------------
; [PATCH]     4D30h-4D34h
; Stock:      00 00 00 00 00   NOP x5, padding past the table's terminator
; This build: 3E 05 C3 76 47   LD A,05h / JP DRVSEL -- 32ECh's stub
; Reason:     Dead space, before entry point 4D41h. Earlier build
;             put this stub at 4D06h instead, inside the table --
;             3Eh overwrote the 00h terminator, walker read 3
;             bogus pairs off the stub's own bytes, one mapped
;             'G' (47h) to 00h. Every unshifted g: no keypress.
; ------------------------------------------------------------
m4d30   LD      A,05H                   ;4d30
        JP      DRVSEL                  ;4d32
        NOP                             ;4d35
        NOP                             ;4d36
        NOP                             ;4d37
        NOP                             ;4d38
        NOP                             ;4d39
        NOP                             ;4d3a
        NOP                             ;4d3b
; ------------------------------------------------------------
; [note]      4D3Ch: "IIIs " -- machine-name suffix, "Genie I/II"
;             -> "Genie IIIs" in the boot banner (SYS0/SYS's own
;             banner-patch note). Entry point 4D41h: 5 bytes in.
; ------------------------------------------------------------
        LD      C,C                     ;4d3c
        LD      C,C                     ;4d3d
        LD      C,C                     ;4d3e
        LD      (HL),E                  ;4d3f
        JR      NZ,$+35                 ;4d40
        INC     A                       ;4d42
        LD      C,L                     ;4d43
        LD      BC,0005H                ;4d44
        LDIR                            ;4d47
        CALL    m06b5                   ;4d49
        LD      A,04H                   ;4d4c
        OUT     (5BH),A                 ;4d4e
        IN      A,(5AH)                 ;4d50
        INC     A                       ;4d52
        CALL    m06be                   ;4d53
        JR      Z,m4d72                 ;4d56
        DI                              ;4d58
        LD      HL,0005H                ;4d59
        ADD     HL,SP                   ;4d5c
        LD      A,(HL)                  ;4d5d
        AND     3FH                     ;4d5e
        LD      (HL),A                  ;4d60
        LD      HL,m4dff                ;4d61
        LD      DE,m44d9                ;4d64
        LD      BC,0012H                ;4d67
        LDIR                            ;4d6a
        LD      A,01H                   ;4d6c
        LD      (m44cc),A               ;4d6e
        EI                              ;4d71
m4d72   LD      A,(m4cef)               ;4d72
        LD      HL,0028H                ;4d75
        CALL    MULOV                   ;4d78
        LD      (m357d),HL              ;4d7b
        LD      HL,m4e11                ;4d7e
        LD      DE,m3d00                ;4d81
        LD      BC,0300H                ;4d84
        CALL    m06a0                   ;4d87
        LDIR                            ;4d8a
        CALL    m06ab                   ;4d8c
        LD      HL,3300H                ;4d8f
        LD      DE,m3c00                ;4d92
        LD      BC,0100H                ;4d95
        CALL    m06a0                   ;4d98
        LDIR                            ;4d9b
        LD      A,(m4cef)               ;4d9d
        PUSH    AF                      ;4da0
        LD      HL,001EH                ;4da1
        CALL    MULOV                   ;4da4
        LD      (m3dca),HL              ;4da7
        POP     AF                      ;4daa
        LD      HL,m015e                ;4dab
        CALL    MULOV                   ;4dae
        LD      (m3dd3),HL              ;4db1
        LD      HL,m4d00                ;4db4
        LD      DE,m37a0                ;4db7
        LD      BC,0030H                ;4dba
        LDIR                            ;4dbd
        CALL    m06ab                   ;4dbf
        LD      HL,0CD00H               ;4dc2
        LD      (m4698),HL              ;4dc5
        LD      HL,m068e                ;4dc8
        LD      (m469a),HL              ;4dcb
        LD      A,0CDH                  ;4dce
        LD      (m4798),A               ;4dd0
        LD      HL,m0697                ;4dd3
        LD      (m4799),HL              ;4dd6
        LD      A,(m4cf9)               ;4dd9
        LD      (m068f),A               ;4ddc
        CP      0A6H                    ;4ddf
        JR      Z,m4de8                 ;4de1
        LD      A,08H                   ;4de3
        LD      (m069b),A               ;4de5
m4de8   LD      A,(m4501)               ;4de8
        CP      5FH                     ;4deb
        JR      Z,m4dfc                 ;4ded
        LD      HL,m376a                ;4def
        LD      DE,0010H                ;4df2
        LD      B,04H                   ;4df5
m4df7   LD      (HL),20H                ;4df7
        ADD     HL,DE                   ;4df9
        DJNZ    m4df7                   ;4dfa
m4dfc   JP      m32cf                   ;4dfc
m4dff   POP     HL                      ;4dff
        CALL    m06a0                   ;4e00
        CALL    m3ed4                   ;4e03
        JR      m4e0e                   ;4e06
        CALL    m06a0                   ;4e08
        CALL    m3e97                   ;4e0b
m4e0e   JP      m06ab                   ;4e0e
m4e11   PUSH    BC                      ;4e11
        LD      BC,m3880                ;4e12
        CALL    m0121                   ;4e15
        POP     BC                      ;4e18
        RET                             ;4e19
        LD      HL,m45bf                ;4e1a
        PUSH    HL                      ;4e1d
        JP      m06ab                   ;4e1e
        LD      HL,m06ab                ;4e21
        PUSH    HL                      ;4e24
        CALL    m3d7e                   ;4e25
        JR      Z,m4e3d                 ;4e28
        LD      A,(m4019)               ;4e2a
        OR      A                       ;4e2d
        JR      Z,m4e3d                 ;4e2e
        DEC     A                       ;4e30
        LD      (m4019),A               ;4e31
        LD      HL,(m401a)              ;4e34
        LD      A,(HL)                  ;4e37
        INC     HL                      ;4e38
        LD      (m401a),HL              ;4e39
        RET                             ;4e3c
m4e3d   LD      HL,m45be                ;4e3d
        LD      (HL),0C9H               ;4e40
        PUSH    HL                      ;4e42
        LD      HL,m011e                ;4e43
        LD      (HL),0C9H               ;4e46
        PUSH    HL                      ;4e48
        CALL    m4529                   ;4e49
        POP     HL                      ;4e4c
        LD      (HL),0C3H               ;4e4d
        POP     HL                      ;4e4f
        LD      (HL),00H                ;4e50
        OR      A                       ;4e52
        RET     Z                       ;4e53
        LD      C,A                     ;4e54
        CP      7BH                     ;4e55
        JR      NZ,m4e63                ;4e57
        CALL    m3d00                   ;4e59
        AND     0C2H                    ;4e5c
        LD      A,C                     ;4e5e
        RET     Z                       ;4e5f
        LD      A,5BH                   ;4e60
        RET                             ;4e62
m4e63   CP      80H                     ;4e63
        RET     C                       ;4e65
        CP      88H                     ;4e66
        RET     NC                      ;4e68
        INC     C                       ;4e69
        CALL    m3d00                   ;4e6a
        AND     41H                     ;4e6d
        LD      A,C                     ;4e6f
        JR      Z,m4e74                 ;4e70
        ADD     A,08H                   ;4e72
m4e74   CALL    m3d7e                   ;4e74
        RET     Z                       ;4e77
        AND     7FH                     ;4e78
        LD      B,A                     ;4e7a
        LD      HL,m3c00                ;4e7b
m4e7e   LD      A,(HL)                  ;4e7e
        INC     HL                      ;4e7f
        DEC     B                       ;4e80
        JR      Z,m4e87                 ;4e81
        ADD     A,L                     ;4e83
        LD      L,A                     ;4e84
        JR      m4e7e                   ;4e85
m4e87   LD      (m4019),A               ;4e87
        LD      (m401a),HL              ;4e8a
        XOR     A                       ;4e8d
        RET                             ;4e8e
        LD      C,A                     ;4e8f
        LD      A,(CURFLG)              ;4e90
        OR      A                       ;4e93
        LD      A,C                     ;4e94
        RET     Z                       ;4e95
        LD      A,(m436e)               ;4e96
        BIT     0,A                     ;4e99
        LD      A,C                     ;4e9b
        RET                             ;4e9c
        CALL    m3d99                   ;4e9d
        LD      BC,(m4548)              ;4ea0
        CALL    m0121                   ;4ea4
        JP      m454a                   ;4ea7
        LD      HL,m3db5                ;4eaa
m4ead   CALL    m0121                   ;4ead
        LD      E,A                     ;4eb0
        XOR     (HL)                    ;4eb1
        LD      (HL),E                  ;4eb2
        AND     E                       ;4eb3
        JR      NZ,m4ec2                ;4eb4
        LD      A,D                     ;4eb6
        ADD     A,08H                   ;4eb7
        LD      D,A                     ;4eb9
        INC     HL                      ;4eba
        LD      A,C                     ;4ebb
        ADD     A,20H                   ;4ebc
        LD      C,A                     ;4ebe
        JR      NZ,m4ead                ;4ebf
        RET                             ;4ec1
m4ec2   POP     HL                      ;4ec2
        JP      m455e                   ;4ec3
        NOP                             ;4ec6
        NOP                             ;4ec7
        NOP                             ;4ec8
        NOP                             ;4ec9
        JR      Z,m4eda                 ;4eca
        LD      HL,0000H                ;4ecc
        DEC     HL                      ;4ecf
        LD      (m3dbc),HL              ;4ed0
        LD      A,H                     ;4ed3
        OR      L                       ;4ed4
        LD      A,00H                   ;4ed5
        JP      NZ,m4588                ;4ed7
m4eda   LD      HL,0000H                ;4eda
        LD      (m3dbc),HL              ;4edd
        JP      m4555                   ;4ee0
        LD      HL,0000H                ;4ee3
        LD      (m3dbc),HL              ;4ee6
        LD      (m454f),A               ;4ee9
        XOR     A                       ;4eec
        RET                             ;4eed
        LD      HL,m379f                ;4eee
        LD      A,D                     ;4ef1
m4ef2   INC     HL                      ;4ef2
        INC     (HL)                    ;4ef3
        DEC     (HL)                    ;4ef4
        JR      Z,m4efc                 ;4ef5
        CPI                             ;4ef7
        JR      NZ,m4ef2                ;4ef9
        LD      A,(HL)                  ;4efb
m4efc   CP      0BH                     ;4efc
        JR      Z,m4f06                 ;4efe
        CP      41H                     ;4f00
        RET     C                       ;4f02
        CP      5FH                     ;4f03
        RET     NC                      ;4f05
m4f06   LD      C,A                     ;4f06
        CALL    m3d00                   ;4f07
        AND     42H                     ;4f0a
        LD      A,C                     ;4f0c
        RET     Z                       ;4f0d
        AND     1FH                     ;4f0e
        CP      0BH                     ;4f10
        RET     NZ                      ;4f12
        LD      BC,m3840                ;4f13
        CALL    m0121                   ;4f16
        AND     08H                     ;4f19
        LD      A,0BH                   ;4f1b
        RET     Z                       ;4f1d
        LD      A,5BH                   ;4f1e
        RET                             ;4f20
        SUB     38H                     ;4f21
        JR      C,m4f9e                 ;4f23
        RET     Z                       ;4f25
        DEC     A                       ;4f26
        RET     Z                       ;4f27
        LD      HL,m0118                ;4f28
        LD      (HL),0C9H               ;4f2b
        PUSH    HL                      ;4f2d
        CALL    m3e24                   ;4f2e
        POP     HL                      ;4f31
        LD      (HL),0CDH               ;4f32
        RET                             ;4f34
        CP      07H                     ;4f35
        JR      NC,m4f4b                ;4f37
        RLCA                            ;4f39
        LD      C,A                     ;4f3a
        CALL    m3d00                   ;4f3b
        RRCA                            ;4f3e
        LD      A,C                     ;4f3f
        JR      NC,m4f43                ;4f40
        INC     A                       ;4f42
m4f43   LD      HL,m3e7b                ;4f43
        CALL    0446H                   ;4f46
        LD      A,D                     ;4f49
        RET                             ;4f4a
m4f4b   ADD     A,79H                   ;4f4b
        CP      88H                     ;4f4d
        RET     C                       ;4f4f
        AND     7FH                     ;4f50
        CP      12H                     ;4f52
        JR      NC,m4f5d                ;4f54
        ADD     A,28H                   ;4f56
m4f58   CALL    044BH                   ;4f58
        LD      A,D                     ;4f5b
        RET                             ;4f5c
m4f5d   JR      NZ,m4f6e                ;4f5d
        LD      A,01H                   ;4f5f
        LD      (m4019),A               ;4f61
        LD      A,30H                   ;4f64
        LD      HL,m3e54                ;4f66
        LD      (m401a),HL              ;4f69
        JR      m4f58                   ;4f6c
m4f6e   SUB     13H                     ;4f6e
        RET     Z                       ;4f70
        LD      HL,m3e88                ;4f71
        CALL    m3e35                   ;4f74
        CP      3FH                     ;4f77
        RET     NZ                      ;4f79
        CALL    m3d7e                   ;4f7a
        RET     Z                       ;4f7d
        LD      A,06H                   ;4f7e
        LD      HL,m3e75                ;4f80
        JP      m3d76                   ;4f83
        LD      D,B                     ;4f86
        LD      D,D                     ;4f87
        LD      C,C                     ;4f88
        LD      C,(HL)                  ;4f89
        LD      D,H                     ;4f8a
        JR      NZ,m4f8d                ;4f8b
m4f8d   NOP                             ;4f8d
        DEC     DE                      ;4f8e
        DEC     DE                      ;4f8f
        LD      A,(BC)                  ;4f90
        LD      A,(DE)                  ;4f91
        DEC     BC                      ;4f92
        DEC     DE                      ;4f93
        DEC     HL                      ;4f94
        DEC     HL                      ;4f95
        NOP                             ;4f96
        NOP                             ;4f97
        NOP                             ;4f98
        NOP                             ;4f99
        INC     L                       ;4f9a
        DEC     L                       ;4f9b
        LD      L,3FH                   ;4f9c
m4f9e   XOR     A                       ;4f9e
        LD      (0421H),A               ;4f9f
        CALL    m3d00                   ;4fa2
        JP      040EH                   ;4fa5
        CALL    m06b5                   ;4fa8
        LD      HL,m4041                ;4fab
        LD      C,02H                   ;4fae
        LD      A,23H                   ;4fb0
        LD      (m3ebc),A               ;4fb2
        LD      D,0AH                   ;4fb5
m4fb7   LD      B,03H                   ;4fb7
m4fb9   LD      A,(HL)                  ;4fb9
        EXX                             ;4fba
        LD      L,A                     ;4fbb
        LD      H,00H                   ;4fbc
        LD      A,0AH                   ;4fbe
        CALL    m4cb4                   ;4fc0
        EXX                             ;4fc3
        CALL    m3f19                   ;4fc4
        EXX                             ;4fc7
        LD      A,L                     ;4fc8
        EXX                             ;4fc9
        CALL    m3f19                   ;4fca
        INC     HL                      ;4fcd
        DJNZ    m4fb9                   ;4fce
        LD      D,7AH                   ;4fd0
        LD      A,2BH                   ;4fd2
        LD      (m3ebc),A               ;4fd4
        LD      L,46H                   ;4fd7
        DEC     C                       ;4fd9
        JR      NZ,m4fb7                ;4fda
        XOR     A                       ;4fdc
        LD      D,0AH                   ;4fdd
        CALL    m3f19                   ;4fdf
        CALL    m06be                   ;4fe2
        PUSH    IX                      ;4fe5
        LD      IX,m3f2c                ;4fe7
        LD      L,44H                   ;4feb
        LD      C,02H                   ;4fed
        LD      A,23H                   ;4fef
        LD      (m3ef5),A               ;4ff1
        LD      D,0CCH                  ;4ff4
m4ff6   LD      B,03H                   ;4ff6
m4ff8   CALL    m3f0a                   ;4ff8
        ADD     A,A                     ;4ffb
        LD      E,A                     ;4ffc
        ADD     A,A                     ;4ffd
        ADD     A,A                     ;4ffe
        ADD     A,E                     ;4fff
        LD      E,A                     ;5000
        CALL    m3f0a                   ;5001
        ADD     A,E                     ;5004
        LD      (HL),A                  ;5005
        INC     HL                      ;5006
        DJNZ    m4ff8                   ;5007
        LD      D,5CH                   ;5009
        LD      A,2BH                   ;500b
        LD      (m3ef5),A               ;500d
        LD      L,43H                   ;5010
        DEC     C                       ;5012
        JR      NZ,m4ff6                ;5013
        POP     IX                      ;5015
        XOR     A                       ;5017
        OUT     (5BH),A                 ;5018
        RET                             ;501a
        LD      A,D                     ;501b
        OUT     (5BH),A                 ;501c
        LD      D,10H                   ;501e
        SUB     D                       ;5020
        LD      D,A                     ;5021
        INC     IX                      ;5022
        IN      A,(5AH)                 ;5024
        AND     (IX+00H)                ;5026
        RET                             ;5029
        LD      E,A                     ;502a
        LD      A,D                     ;502b
        OUT     (5BH),A                 ;502c
        LD      D,10H                   ;502e
        ADD     A,D                     ;5030
        LD      D,A                     ;5031
        AND     0F0H                    ;5032
        CP      60H                     ;5034
        LD      A,E                     ;5036
        JR      NZ,m503b                ;5037
        SET     3,A                     ;5039
m503b   OUT     (5AH),A                 ;503b
        RET                             ;503d
        RRCA                            ;503e
        RRCA                            ;503f
        LD      BC,030FH                ;5040
        RRCA                            ;5043
        INC     BC                      ;5044
        RRCA                            ;5045
        RLCA                            ;5046
        RRCA                            ;5047
        RLCA                            ;5048
        RRCA                            ;5049
        LD      HL,0000H                ;504a
        LD      (VIDTOP),HL             ;504d
m5050   LD      HL,(VIDTOP)             ;5050
        LD      C,H                     ;5053
        LD      B,L                     ;5054
        LD      A,(m37f8)               ;5055
        AND     03H                     ;5058
        CP      03H                     ;505a
        LD      A,(m37f6)               ;505c
        JR      NZ,m5062                ;505f
        ADD     A,A                     ;5061
m5062   SUB     B                       ;5062
        SUB     C                       ;5063
        CP      01H                     ;5064
        JP      M,m3f39                 ;5066
        PUSH    AF                      ;5069
        LD      HL,(m37fc)              ;506a
        LD      D,L                     ;506d
        LD      E,H                     ;506e
        LD      HL,m3800                ;506f
        ADD     HL,DE                   ;5072
        LD      (m3400),HL              ;5073
        LD      A,(m37f1)               ;5076
        LD      (m340b),A               ;5079
        LD      E,A                     ;507c
        LD      D,00H                   ;507d
        LD      (m409d),A               ;507f
        LD      (1914H),A               ;5082
        ADD     A,A                     ;5085
        LD      (0141H),A               ;5086
        CALL    m3ff0                   ;5089
        LD      (m3402),HL              ;508c
        POP     AF                      ;508f
        PUSH    HL                      ;5090
        LD      (1916H),A               ;5091
        LD      HL,0000H                ;5094
        LD      B,A                     ;5097
        CALL    m3ff0                   ;5098
        LD      (m3408),HL              ;509b
        EX      DE,HL                   ;509e
        EX      (SP),HL                 ;509f
        ADD     HL,DE                   ;50a0
        LD      (m3406),HL              ;50a1
        POP     DE                      ;50a4
        LD      B,C                     ;50a5
        CALL    m3ff0                   ;50a6
        LD      (m3404),HL              ;50a9
        LD      B,E                     ;50ac
        EX      DE,HL                   ;50ad
        LD      HL,m4000                ;50ae
        RST     18H                     ;50b1
        JR      NC,m50cb                ;50b2
        LD      HL,m37fc                ;50b4
        LD      A,(HL)                  ;50b7
        INC     HL                      ;50b8
        OR      (HL)                    ;50b9
        JR      Z,m50c5                 ;50ba
        LD      A,(HL)                  ;50bc
        SUB     B                       ;50bd
        LD      (HL),A                  ;50be
        JR      NC,m5050                ;50bf
        DEC     HL                      ;50c1
        DEC     (HL)                    ;50c2
        JR      m5050                   ;50c3
m50c5   LD      HL,m37f6                ;50c5
        DEC     (HL)                    ;50c8
        JR      m5050                   ;50c9
m50cb   LD      HL,m37fa                ;50cb
        LD      A,(HL)                  ;50ce
        AND     1FH                     ;50cf
        LD      B,A                     ;50d1
        LD      A,(m37f9)               ;50d2
        CP      B                       ;50d5
        JR      NC,m50da                ;50d6
        DEC     A                       ;50d8
        LD      (HL),A                  ;50d9
m50da   LD      HL,(m3400)              ;50da
        LD      DE,m3c00                ;50dd
        OR      A                       ;50e0
        SBC     HL,DE                   ;50e1
        LD      (m3641),HL              ;50e3
        LD      A,(1916H)               ;50e6
        LD      (m409f),A               ;50e9
        LD      C,A                     ;50ec
        ADD     A,A                     ;50ed
        ADD     A,C                     ;50ee
        LD      (014CH),A               ;50ef
        LD      HL,m37f0                ;50f2
        LD      B,10H                   ;50f5
        XOR     A                       ;50f7
        CALL    m3551                   ;50f8
        LD      HL,(m3402)              ;50fb
        JP      m06ab                   ;50fe
        INC     B                       ;5101
        DEC     B                       ;5102
        RET     Z                       ;5103
m5104   ADD     HL,DE                   ;5104
        DJNZ    m5104                   ;5105
        RET                             ;5107
        END     0056h
