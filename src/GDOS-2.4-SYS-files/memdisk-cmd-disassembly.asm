;************************************************************************
;
; MEMDISK/CMD, stock GDOS 2.4 (G3S-GDOS24-Extract/MEMDISK.CMD)
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: memdisk-cmd-disassembly.asm
;
; Date: 2026/08/21
;
;************************************************************************
;
; CMD to initilize the RAMDISK on drive 4, five 256-byte-ish load records entry at 3000h:
;
;   0x0000  LOAD  256B  3000..30FF
;   0x0104  LOAD  256B  3100..31FF
;   0x0208  LOAD  256B  3200..32FF
;   0x030c  LOAD  254B  3300..33FD
;   0x040e  LOAD   67B  5200..5242
;   0x0455  ENTRY 3000
;
;   z80dasm -g 0x3000 -l -a -t memdisk_flat.bin
;
; MEMDISK reaches deep into the DOS's own low RAM: it installs a resident
; driver at F400h, chains a handler into the dispatch table at F016h, and
; rewrites DPDRV, DPPTR and DNDRV. The addresses it uses are the same ones
; the hard-disk driver at F000h uses, which is why the two have to agree
; about that layout.
;
; Addresses outside this file. Names follow Grosser where he gives one --
; DRVSEL and TIME are his -- and docs/reference/gdos-2.4-addresses.md
; otherwise. An address with no documented meaning keeps its number.

ROMCHR	EQU	0033h		;ROM: put character A on the screen
DBANKS	EQU	36ffh		;banked-RAM size and flag bits
RPDRV	EQU	37cch		;relocated PDRIVE block
DTABH	EQU	37d6h		;drive table, high bytes
DTAB	EQU	37dfh		;drive table
RSTUB	EQU	3a00h		;low-RAM transfer stub
DOSRDY	EQU	402dh		;return to the DOS prompt
SECBUF	EQU	4200h		;DOS sector buffer
DMACH	EQU	4307h		;machine type; 04h is the Genie IIIs
DMASK	EQU	4309h		;drive-select bit pattern for 37E1h
DPDRV	EQU	430ah		;PDRIVE parameters of the current drive
DPPTR	EQU	4399h		;pointer into the PDRIVE table
DNDRV	EQU	439fh		;number of drives
DOSCMD	EQU	4405h		;execute the DOS command at (HL)
DOSERR	EQU	4409h		;DOS error exit
TIME	EQU	446dh		;read the clock
READS	EQU	4630h		;read a physical sector
WRITDS	EQU	463ch		;write a directory sector
WRITES	EQU	4640h		;write a physical sector
DSKMNT	EQU	47efh		;wait for the index hole
CHKCHR	EQU	4cd5h		;test the character at (HL)
GWORK	EQU	0f00dh		;hard-disk driver's work vector
GDISP3	EQU	0f016h		;hard-disk driver's dispatch table, slot 3
GSTK	EQU	0f040h		;hard-disk driver's stack

	ORG	3000h

; Entry. A machine-type gate, then dispatch on the first byte of whatever
; command-tail argument follows "MEMDISK" (HL points at it on entry, per
; the same convention as SYS8/SYS's own DIR argument parsing).

	LD	A,(DMACH)	;3000  machine type
	CP	004h		;3003  must be Genie IIIs
	LD	A,02ah		;3005
	JP	NZ,DOSERR	;3007  wrong machine -> DOSERR, error 2Ah
	LD	(030feh),SP	;300a  save caller's SP
	LD	A,(HL)		;300e
	CP	04eh		;300f  'N'
	JP	Z,05200h	;3011  MEMDISK N -- uninstall, see below
	DEC	HL		;3014
l3015h:
	INC	HL		;3015  (DEC/INC HL above is a net no-op the
				;first time through; l3015h is also the loop
				;head other branches below rejoin at)
	CALL	CHKCHR		;3016  shared end-of-parameter/delimiter
				;scanner (same routine SYS17/SYS's own
				;argument parsing uses -- see that file's own
				;comment). Z = nothing more on the line.
	JR	Z,l3042h	;3019  bare "MEMDISK", no argument -> l3042h,
				;the default-install path
	LD	A,(HL)		;301b
	CP	049h		;301c  'I'
	JR	Z,l3034h	;301e  MEMDISK I
	CP	048h		;3020  'H'
	JR	Z,l302dh	;3022  MEMDISK H
	CP	046h		;3024  'F'
	JR	Z,l303dh	;3026  MEMDISK F
	LD	A,034h		;3028  unrecognised letter
	JP	DOSERR		;302a  DOSERR, error 34h ("schlechte
				;Parameter" per SYS17/SYS's own comment on
				;this same 4CD5h routine's error convention)
l302dh:				;MEMDISK H
	LD	A,03eh		;302d
	LD	(l3068h),A	;302f  patches a byte inside the low-RAM
				;stub template at l315ah
	JR	l3015h		;3032  back for another argument character
l3034h:				;MEMDISK I
	LD	DE,DOSRDY	;3034
	LD	(0339dh),DE	;3037  patches a stored address inside the
				;3300h load record's own data
	JR	l3015h		;303b
l303dh:				;MEMDISK F
	LD	(032e2h),HL	;303d  stores HL (mid-command-tail pointer)
				;at 32e2h
	JR	l3015h		;3040

; Default install (no argument). 477Ah holds the floppy count -- SYS0/SYS's
; init writes it there, into DRVSEL's own CP operand. MEMDISK takes it as
; the target drive number and probes it through DRVSEL before doing
; anything else. With four floppies
; configured that means "install as the drive after the last floppy" -- a
; computed drive number, not a hardcoded 4.

l3042h:
	LD	A,(0477ah)	;3042  the floppy count, as DRVSEL's own
				;CP operand holds it
	LD	(l32d9h+1),A	;3045  self-modifies l32d9h's own "LD A,002h"
				;immediate operand -- l32d9h (below) re-probes
				;the SAME drive number later with its own,
				;separately-reached DRVSEL(2) call becoming
				;DRVSEL(floppy count) once this patch lands
	OR	030h		;3048  -> ASCII digit
	LD	(033a3h),A	;304a  patches a drive-number digit into a
				;message/table byte at 33a3h (inside the
				;3300h load record's own data)
	AND	00fh		;304d  back to the raw digit
	CALL	0445bh		;304f  the DRVSEL vector: JP 4776h. The
				;hard-disk driver hooks 477Ch inside that
				;routine, so this call runs through its
				;dispatch table
	JP	Z,l32d9h	;3052  DRVSEL succeeded -> l32d9h, the shared
				;verify+install continuation (also reached
				;from elsewhere, see below)
	LD	HL,DBANKS	;3055  the banked-RAM size byte the
				;hard-disk driver's ginit sizes at boot
	BIT	2,(HL)		;3058
	JR	Z,l3061h	;305a
	LD	A,03bh		;305c
	JP	DOSERR		;305e  DOSERR, error 3Bh -- the leading
				;candidate for "Bauteil nicht erreichbar",
				;reached if that DRVSEL failed AND DBANKS
				;bit 2 is clear
l3061h:
	BIT	3,(HL)		;3061  DBANKS bit 3
	LD	A,002h		;3063
	JR	Z,l3068h	;3065
	DEC	A		;3067
l3068h:
	CP	001h		;3068
	LD	(030a7h),A	;306a  stores into the 3000h load record's
				;own data area
	LD	C,0fbh		;306d
	SET	2,(HL)		;306f  DBANKS bit 2 set (marks it "sized",
				;consistent with ginit's own use of this bit)
	DEC	A		;3071
	JR	Z,l3078h	;3072
	SET	3,(HL)		;3074
	RES	3,C		;3076
l3078h:

; DNDRV increment, an F9h bit-0 bank switch, and the copy that matters:
; 360 bytes of MEMDISK's own resident code to F400h, inside the hard-disk
; driver's F000h-F5EAh span. The driver lays ginit and gcfg across
; F3A6h-F585h for exactly this reason -- both are finished once the boot
; ends, so the range MEMDISK overwrites holds no live code by then.

	LD	A,(0477ah)	;3078  the floppy count again
	LD	B,A		;307b
	LD	HL,DNDRV	;307c
	INC	(HL)		;307f  MEMDISK increments DNDRV by 1
	DI			;3080
	IN	A,(0f9h)	;3081
	AND	03eh		;3083
	OR	001h		;3085  bit 0 only
	OUT	(0f9h),A	;3087
	LD	(l315ah),BC	;3089  BC into the low-RAM stub template's
				;own leading bytes (see l315ah below)
	LD	HL,l315ah	;308d
	LD	DE,0f400h	;3090  the resident driver's home
	LD	BC,00168h	;3093  360 bytes
	LDIR			;3096  copies MEMDISK's own resident driver,
				;below, to F400h
	LD	A,(l32d9h+1)	;3098  the self-modified floppy-count-as-drive-digit
				;byte, patched in at 3045h above
	LD	L,A		;309b
	LD	H,0f0h		;309c
	LD	(HL),030h	;309e  writes ASCII '0' at F0xxh, x = the
				;drive digit
	LD	HL,0f4a3h	;30a0
	LD	(GDISP3),HL	;30a3  chains MEMDISK's own handler into the
				;hard-disk driver's dispatch table, whose
				;slots run F010h-F01Fh. This is what claims
				;the drive: until it runs, that slot rejects
	LD	A,000h		;30a6
	LD	B,A		;30a8
	CP	002h		;30a9
	LD	HL,001fah	;30ab
	JR	Z,l30beh	;30ae
	LD	HL,000fdh	;30b0
	LD	A,032h		;30b3
	LD	(0f405h),A	;30b5
	LD	(0f403h),A	;30b8
	LD	(0331eh),A	;30bb
l30beh:
	LD	(0f42bh),HL	;30be
	LD	HL,DTAB-1	;30c1  dtab region (the OMTI driver's
				;own dtab EQU 37dfh is one byte higher)
	LD	DE,DTAB	;30c4
	LD	BC,00009h	;30c7
	LDDR			;30ca
	LD	A,(l32d9h+1)	;30cc  the floppy-count-as-drive digit again
	LD	(DTABH),A	;30cf
	LD	SP,03400h	;30d2

; A banked-RAM-sizing loop: read, complement and compare each bank to find
; how much RAM is actually there. The hard-disk driver's ginit does the
; same job the same way.

	IN	A,(0f9h)	;30d5
	AND	03eh		;30d7
	OR	080h		;30d9
	OUT	(0f9h),A	;30db
l30ddh:
	PUSH	BC		;30dd
	LD	HL,l3103h	;30de
	LD	DE,04000h	;30e1
	LD	BC,00057h	;30e4
	LDIR			;30e7
	IN	A,(0f9h)	;30e9
	AND	03eh		;30eb
	OR	0c0h		;30ed
	OUT	(0f9h),A	;30ef
	POP	BC		;30f1
	DJNZ	l30ddh		;30f2
	IN	A,(0f9h)	;30f4
	AND	03eh		;30f6
	OR	040h		;30f8
	OUT	(0f9h),A	;30fa
	EI			;30fc
	LD	SP,00000h	;30fd
	JP	l32d9h		;3100  on to the shared verify+install tail

; Two bank-aware LDIR helpers, 256 bytes each way across the F9h bank
; switch. l3103h is copied to 4000h by the sizing loop above and runs from
; there; nothing in this range calls l312dh.

l3103h:
	PUSH	HL		;3103
	BIT	7,H		;3104
	JR	Z,l310eh	;3106
	IN	A,(0f9h)	;3108
	RES	0,A		;310a
	OUT	(0f9h),A	;310c
l310eh:
	LD	DE,04100h	;310e
	LD	BC,00100h	;3111
	LDIR			;3114
	LD	H,041h		;3116
	IN	A,(0f9h)	;3118
	RES	0,A		;311a
	OUT	(0f9h),A	;311c
	INC	B		;311e
	LD	DE,03900h	;311f
	LDIR			;3122
	DI			;3124
	IN	A,(0f9h)	;3125
	SET	0,A		;3127
	OUT	(0f9h),A	;3129
	POP	HL		;312b
	RET			;312c
l312dh:
	PUSH	HL		;312d
	EX	DE,HL		;312e
	LD	BC,00100h	;312f
	LD	HL,03900h	;3132
	IN	A,(0f9h)	;3135
	RES	0,A		;3137
	OUT	(0f9h),A	;3139
	LD	A,D		;313b
	LD	D,041h		;313c
	LDIR			;313e
	LD	H,041h		;3140
	LD	D,A		;3142
	BIT	7,D		;3143
	JR	NZ,l314eh	;3145
	DI			;3147
	IN	A,(0f9h)	;3148
	SET	0,A		;314a
	OUT	(0f9h),A	;314c
l314eh:
	INC	B		;314e
	LDIR			;314f
	DI			;3151
	IN	A,(0f9h)	;3152
	SET	0,A		;3154
	OUT	(0f9h),A	;3156
	POP	HL		;3158
	RET			;3159

; The low-RAM resident stub copied to F400h at 3096h above -- MEMDISK's
; own equivalent of the OMTI driver's gstub (gdos-omti.asm). Not
; traced instruction-by-instruction against gstub; the
; opening bank-select-and-dispatch-on-C shape is visibly the same idea.

l315ah:
	NOP			;315a
	NOP			;315b		;BC gets stored over these two
					;bytes by 3089h above (LD(l315ah),BC)
	LD	BC,00465h	;315c
	LD	H,L		;315f
	DEC	B		;3160
	LD	BC,00080h	;3161
	LD	BC,0c502h	;3164
	LD	C,000h		;3167
	JR	l3178h		;3169
	PUSH	BC		;316b
	LD	C,040h		;316c
	JR	l3178h		;316e
	PUSH	BC		;3170
	LD	C,080h		;3171
	JR	l3178h		;3173
	PUSH	BC		;3175
	LD	C,0c0h		;3176
l3178h:
	PUSH	AF		;3178
	IN	A,(0f9h)	;3179
	AND	03fh		;317b
	OR	C		;317d
	OUT	(0f9h),A	;317e
	POP	AF		;3180
	POP	BC		;3181
	RET			;3182

; A geometry/divide helper: the same double-divide-and-clamp shape that
; bootrd.asm's divhl and omti.asm's hddiv use to build a CHS address.

	EX	DE,HL		;3183
	LD	DE,00000h	;3184
	OR	A		;3187
	PUSH	HL		;3188
	SBC	HL,DE		;3189
	POP	HL		;318b
	LD	A,014h		;318c
	JR	NC,l31aeh	;318e
	LD	DE,000fdh	;3190
	OR	A		;3193
	PUSH	HL		;3194
	SBC	HL,DE		;3195
	POP	HL		;3197
	JR	NC,l319fh	;3198
	CALL	0f416h		;319a
	JR	l31a4h		;319d
l319fh:
	CALL	0f41bh		;319f
	SBC	HL,DE		;31a2
l31a4h:
	LD	A,L		;31a4
	CP	040h		;31a5
	JR	C,l31abh	;31a7
	ADD	A,003h		;31a9
l31abh:
	LD	H,A		;31ab
	XOR	A		;31ac
	LD	L,A		;31ad
l31aeh:
	OR	A		;31ae
	RET			;31af

	XOR	A		;31b0
	LD	E,H		;31b1
	LD	H,041h		;31b2
l31b4h:
	ADD	A,(HL)		;31b4
	INC	L		;31b5
	JR	NZ,l31b4h	;31b6
	AND	07fh		;31b8
	LD	D,042h		;31ba
	EX	DE,HL		;31bc
	BIT	7,(HL)		;31bd
	JR	Z,l31c3h	;31bf
	OR	080h		;31c1
l31c3h:
	CP	(HL)		;31c3
	LD	(HL),A		;31c4
	EX	DE,HL		;31c5
	RET			;31c6

; DRVSEL and transfer hook handlers -- MEMDISK's counterpart to the
; hard-disk driver's ghook, gdrvsl and gxfhk. These decide whether a drive
; belongs to the RAM disk, and hand it back when it does not.

	CALL	0f429h		;31c7
	JR	NZ,l31dfh	;31ca
	CALL	04000h		;31cc
	CALL	0f456h		;31cf
	LD	C,004h		;31d2
	JR	NZ,l31deh	;31d4
	BIT	7,A		;31d6
	LD	C,006h		;31d8
	JR	NZ,l31deh	;31da
	LD	C,000h		;31dc
l31deh:
	LD	A,C		;31de
l31dfh:
	CALL	0f40ch		;31df
	RET			;31e2
	LD	A,080h		;31e3
	CP	0afh		;31e5
	LD	(0f49eh),A	;31e7
	CALL	0f429h		;31ea
	JR	NZ,l31dfh	;31ed
	CALL	0402ah		;31ef
	CALL	0f456h		;31f2
	AND	07fh		;31f5
	OR	000h		;31f7
	LD	(DE),A		;31f9
	XOR	A		;31fa
	JR	l31dfh		;31fb

; Install: makes DSKMNT return immediately, clears DMASK, points the
; driver's work vector GWORK+1 at its own handler, copies eight bytes of
; PDRIVE parameters to DPDRV and repoints DPPTR at RPDRV.
;
; Every one of those addresses is one the hard-disk driver at F000h also
; uses -- GWORK+1 is three bytes past its ginit entry. MEMDISK is written
; against this low-RAM layout, not the stock Xebec driver's.

	LD	A,0c9h		;31fd
	LD	(DSKMNT),A	;31ff
	XOR	A		;3202
	LD	(DMASK),A	;3203
	LD	HL,0f4d7h	;3206
	LD	(GWORK+1),HL	;3209
	LD	HL,0f402h	;320c
	LD	DE,DPDRV	;320f
	LD	BC,00008h	;3212
	LDIR			;3215
	LD	HL,0f402h	;3217
	LD	DE,RPDRV	;321a
	LD	(DPPTR),DE	;321d
	LD	BC,0000ah	;3221
	DI			;3224
	IN	A,(0f9h)	;3225
	AND	03eh		;3227
	OR	001h		;3229
	OUT	(0f9h),A	;322b
	LDIR			;322d
	XOR	A		;322f
	RET			;3230

; Entry trampoline: a self-modified SP save and restore, then 107 bytes of
; stub copied from F4FDh down to RSTUB. The hard-disk driver's gbank,
; gexit0 and gexit1 do the same job with a stub of a different size.

	EX	AF,AF'		;3231
	DI			;3232
	IN	A,(0f9h)	;3233
	AND	03eh		;3235
	OR	001h		;3237
	OUT	(0f9h),A	;3239
	EX	AF,AF'		;323b
	LD	SP,03640h	;323c
	CALL	006a0h		;323f
	PUSH	BC		;3242
	PUSH	DE		;3243
	PUSH	HL		;3244
	LD	HL,0f4fdh	;3245
	LD	DE,RSTUB	;3248
	LD	BC,0006bh	;324b
	LDIR			;324e
	POP	HL		;3250
	POP	DE		;3251
	PUSH	DE		;3252
	PUSH	HL		;3253
	JP	RSTUB		;3254
	LD	(03a36h),SP	;3257
	LD	SP,GSTK	;325b
	BIT	5,A		;325e
	JR	Z,l32a9h	;3260
	PUSH	DE		;3262
	PUSH	AF		;3263
	IN	A,(0f9h)	;3264
	AND	03eh		;3266
	OR	040h		;3268
	OUT	(0f9h),A	;326a
	LD	DE,03900h	;326c
	LD	BC,00100h	;326f
	LDIR			;3272
	DI			;3274
	IN	A,(0f9h)	;3275
	AND	03eh		;3277
	OR	001h		;3279
	OUT	(0f9h),A	;327b
	POP	AF		;327d
	POP	DE		;327e
	BIT	0,A		;327f
	JR	Z,l3288h	;3281
	CALL	0f489h		;3283
	JR	l328bh		;3286
l3288h:
	CALL	0f48ch		;3288
l328bh:
	LD	B,A		;328b
	LD	SP,00000h	;328c
	DI			;328f
	IN	A,(0f9h)	;3290
	AND	03eh		;3292
	OR	001h		;3294
	OUT	(0f9h),A	;3296
	LD	A,B		;3298
	OR	A		;3299
	POP	HL		;329a
	POP	DE		;329b
	POP	BC		;329c
	LD	SP,GSTK	;329d
	PUSH	AF		;32a0
	IN	A,(0fah)	;32a1
	RES	0,A		;32a3
	OUT	(0fah),A	;32a5
	POP	AF		;32a7
	RET			;32a8
l32a9h:
	PUSH	HL		;32a9
	CALL	0f46dh		;32aa
	POP	DE		;32ad
	LD	B,A		;32ae
	IN	A,(0f9h)	;32af
	AND	03eh		;32b1
	OR	040h		;32b3
	OUT	(0f9h),A	;32b5
	LD	A,B		;32b7
	LD	HL,03900h	;32b8
	LD	BC,00100h	;32bb
	LDIR			;32be
	JR	l328bh		;32c0

; Transfer helpers: loop a DOS read or write through WRITES/WRITDS B times,
; advancing DE each time.

l32c2h:
	CALL	WRITES		;32c2
	INC	DE		;32c5
	DJNZ	l32c2h		;32c6
	RET			;32c8
l32c9h:
	CALL	WRITDS		;32c9
	INC	DE		;32cc
	DJNZ	l32c9h		;32cd
	RET			;32cf

; Zero-fill the 256-byte config sector at 4200h -- the same address this
; project's own driver's ginit copies gcfg to (gdos-omti.asm).

sub_32d0h:
	LD	HL,SECBUF	;32d0
l32d3h:
	LD	(HL),000h	;32d3
	INC	L		;32d5
	JR	NZ,l32d3h	;32d6
	RET			;32d8

; Shared verify+install continuation, and the bulk of the work: it lays a
; GAT, a directory header and two directory entries onto the new drive, then
; hands "DIR 4" to DOSCMD.
;
; Reached from l3042h, which has already primed A by self-modifying this
; routine's first instruction -- but it re-probes DRVSEL itself rather than
; trusting the caller. It ends at DOSCMD, not DOSERR: the RAM disk is built,
; so the command line runs.

l32d9h:
	LD	A,002h		;32d9  self-modified to the floppy count by 3045h above,
				;when reached via the default-install path
	CALL	0445bh		;32db  DRVSEL(floppy count) -- re-probes the same
				;drive this path already probed once at 304Fh
	JP	NZ,DOSERR	;32de  DOSERR if the re-probe itself fails
	LD	HL,00000h	;32e1
	LD	A,(HL)		;32e4
	CP	046h		;32e5  'F'
	JR	Z,l32f7h	;32e7
	LD	DE,00005h	;32e9
	LD	HL,SECBUF	;32ec
	CALL	READS		;32ef  dxfer (the OMTI driver's EQU)
	CP	006h		;32f2
	JP	Z,l3399h	;32f4
l32f7h:
	CALL	sub_32d0h	;32f7  zero 4200h
	EX	DE,HL		;32fa
	LD	HL,l33a5h	;32fb  data table, see below
	LD	BC,00003h	;32fe
	LDIR			;3301
	LD	HL,SECBUF	;3303
	LD	DE,00000h	;3306
	LD	B,002h		;3309
	CALL	l32c2h		;330b
	CALL	sub_32d0h	;330e
	LD	B,003h		;3311
	CALL	l32c2h		;3313
	LD	B,003h		;3316
l3318h:
	LD	(HL),0ffh	;3318
	INC	HL		;331a
	DJNZ	l3318h		;331b
	LD	A,065h		;331d
	SUB	003h		;331f
	LD	B,A		;3321
l3322h:
	LD	(HL),0feh	;3322
	INC	HL		;3324
	DJNZ	l3322h		;3325
l3327h:
	LD	(HL),0ffh	;3327
	INC	L		;3329
	JR	NZ,l3327h	;332a
	LD	HL,l33b5h	;332c
	CALL	TIME		;332f
	LD	HL,02020h	;3332
	LD	(l33bah),HL	;3335
	LD	(l33bah+1),HL	;3338
	LD	HL,l33a8h	;333b
	LD	DE,SECBUF+0cbh	;333e
	LD	BC,00022h	;3341
	LDIR			;3344
	LD	HL,SECBUF	;3346
	LD	DE,00005h	;3349
	CALL	WRITDS		;334c
	CALL	sub_32d0h	;334f
	LD	BC,0cea1h	;3352
	LD	(SECBUF),BC	;3355
	INC	DE		;3359
	CALL	WRITDS		;335a
	EX	DE,HL		;335d
	LD	HL,l33beh	;335e
	LD	BC,00020h	;3361
	LDIR			;3364
	LD	DE,00007h	;3366
	LD	HL,SECBUF	;3369
	CALL	WRITDS		;336c
	EX	DE,HL		;336f
	LD	HL,l33deh	;3370
	LD	BC,00020h	;3373
	LDIR			;3376
	LD	DE,00008h	;3378
	LD	HL,SECBUF	;337b
	CALL	WRITDS		;337e
	CALL	sub_32d0h	;3381
	LD	B,006h		;3384
	INC	DE		;3386
	CALL	l32c9h		;3387
l338ah:
	CALL	READS		;338a
	CP	014h		;338d
	JP	Z,l3399h	;338f
	OR	A		;3392
	CALL	NZ,WRITES	;3393
	INC	DE		;3396
	JR	l338ah		;3397
l3399h:
	LD	HL,l339fh	;3399
	JP	DOSCMD		;339c

; --- data from here to the end of the record at 33FDh. Not code: the RST 38h
; runs and nonsense LD sequences a linear disassembler produces here come from
; data bytes that are never executed.

; The DOS command MEMDISK hands to DOSCMD at 339Ch once the RAM disk is built.
l339fh:
	DEFB	044h,049h,052h,020h,034h,00dh	;339f  DIR 4.
					;33a3 is the drive digit, written by
					;304Ah from the floppy-count-derived number

; Three bytes LDIR'd into SECBUF at 3301h.
l33a5h:
	DEFB	000h,0feh,001h	;33a5  ...

; 34 bytes copied to SECBUF+0cbh at 3344h: the RAM disk's own directory header --
; 47h 8Ch is the master password, then the disk name, then the date field
; that TIME fills in at 332Fh (l33b5h) and 3335h/3338h blank to spaces first.
l33a8h:
	DEFB	052h,000h,000h,047h,08ch,04dh,045h,04dh	;33a8  R..G.MEM
	DEFB	044h,049h,053h,04bh,020h	;33b0  DISK
l33b5h:
	DEFB	020h,020h,020h,020h,020h	;33b5
l33bah:
	DEFB	020h,020h,020h,00dh	;33ba     .

; Two 32-byte directory entries, written to the new disk at 3364h and 3376h:
; GDOS/SYS and INHALT/SYS.
l33beh:
	DEFB	05eh,000h,000h,000h,000h,047h,044h,04fh	;33be  ^....GDO
	DEFB	053h,020h,020h,020h,020h,053h,059h,053h	;33c6  S    SYS
	DEFB	060h,07fh,01fh,0b2h,005h,000h,000h,000h	;33ce  `.......
	DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;33d6  ........
l33deh:
	DEFB	05dh,000h,000h,000h,000h,049h,04eh,048h	;33de  ]....INH
	DEFB	041h,04ch,054h,020h,020h,053h,059h,053h	;33e6  ALT  SYS
	DEFB	0a7h,01dh,0f9h,0e2h,00ah,000h,001h,001h	;33ee  ........
	DEFB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;33f6  ........

; --- separate load record, 5200h-5242h, reached from 3011h ("MEMDISK N").
; Uninstall: DRVSEL(0) -- always succeeds, via stock DRVSEL's A<1 fast path
; -- then bank-switch, decrement DNDRV, and restore DTABH from the backup
; copy at DTABH+1.

	ORG	5200h

	XOR	A		;5200
	CALL	0445bh		;5201  DRVSEL(0)
	DI			;5204
	IN	A,(0f9h)	;5205
	SET	0,A		;5207
	OUT	(0f9h),A	;5209
	LD	A,(0f401h)	;520b
	LD	L,A		;520e
	LD	H,0f0h		;520f
	LD	A,(HL)		;5211
	CP	030h		;5212
	JR	NZ,l5238h	;5214
	LD	(HL),L		;5216
	LD	A,(0f400h)	;5217
	LD	C,A		;521a
	IN	A,(0f9h)	;521b
	AND	03eh		;521d
	OR	040h		;521f
	OUT	(0f9h),A	;5221
	LD	HL,DNDRV	;5223
	DEC	(HL)		;5226
	LD	HL,DBANKS	;5227
	LD	A,C		;522a
	AND	(HL)		;522b
	LD	(HL),A		;522c
	LD	HL,DTABH+1	;522d
	LD	DE,DTABH	;5230
	LD	BC,00009h	;5233
	LDIR			;5236
l5238h:
	IN	A,(0f9h)	;5238
	AND	03eh		;523a
	OR	040h		;523c
	OUT	(0f9h),A	;523e
	JP	DOSRDY		;5240  DOSRDY, per Grosser's own DOSERR
				;comment ("...ein Sprung nach DOSRDY (402DH)")
