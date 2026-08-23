;************************************************************************
;
;	SYS26/SYS from G-DOS 2.4
;
; Disassembled and commented by
; E.H. Schroeer
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
; This is the module as this port patches it, not stock: see the [PATCH]
; notes at 4F3Bh and 50D0h.
;
; [PATCH]  a patch: stock byte vs. this build.
; [note]   read off the disassembly, not from any prior reference.
;
; Request-code dispatch (A on entry, per Grosser's GETSYS convention --
; xxxbbsss, top 3 bits select the function within this module):
;   3Ch -> l4d4ch   5Ch -> l4da1h   7Ch -> l4db9h   9Ch -> l4e76h
;   BCh -> falls through to a RST 28h tone dispatch at 4d1dh
;   anything else (incl. the module's own bare load, xxx=000, A=1Ch) falls
;   to l4fb6h, the default path -- the one this boot's own first
;   load-and-run of the module actually takes.
;
;   z80dasm -g 0x4d00 -l -a -t sys26_flat.bin

	org 04d00h

l4d00h:
	nop			;4d00	00		.
l4d01h:
	nop			;4d01	00		.
	nop			;4d02	00		.
l4d03h:
	nop			;4d03	00		.
	cp 03ch			;4d04	fe 3c		. <
	jp z,l4d4ch		;4d06	ca 4c 4d	. L M
	cp 05ch			;4d09	fe 5c		. \
	jp z,l4da1h		;4d0b	ca a1 4d	. . M
	cp 07ch			;4d0e	fe 7c		. |
	jp z,l4db9h		;4d10	ca b9 4d	. . M
	cp 09ch			;4d13	fe 9c		. .
	jp z,l4e76h		;4d15	ca 76 4e	. v N
	cp 0bch			;4d18	fe bc		. .
	jp nz,l4fb6h		;4d1a	c2 b6 4f	. . O
	ld a,(04307h)		;4d1d	3a 07 43	: . C
	and 00fh		;4d20	e6 0f		. .
	cp 002h			;4d22	fe 02		. .
	jr c,l4d32h		;4d24	38 0c		8 .
	ld b,0f9h		;4d26	06 f9		. .
	jr z,l4d30h		;4d28	28 06		( .
	cp 006h			;4d2a	fe 06		. .
	jr nc,l4d32h		;4d2c	30 04		0 .
	ld b,0fah		;4d2e	06 fa		. .
l4d30h:
	ld a,b			;4d30	78		x
	rst 28h			;4d31	ef		.
l4d32h:
	ld a,02ah		;4d32	3e 2a		> *
l4d34h:
	ei			;4d34	fb		.
	jp 04409h		;4d35	c3 09 44	. . D
l4d38h:
	ld a,02fh		;4d38	3e 2f		> /
	jr l4d34h		;4d3a	18 f8		. .
sub_4d3ch:
	ld a,(04307h)		;4d3c	3a 07 43	: . C
	and 00fh		;4d3f	e6 0f		. .
	cp 002h			;4d41	fe 02		. .
	ret z			;4d43	c8		.
	and 00eh		;4d44	e6 0e		. .
	cp 004h			;4d46	fe 04		. .
	ret z			;4d48	c8		.
	pop af			;4d49	f1		.
	xor a			;4d4a	af		.
	ret			;4d4b	c9		.
l4d4ch:
	call sub_4d3ch		;4d4c	cd 3c 4d	. < M
	ld a,(hl)		;4d4f	7e		~
	cp 00dh			;4d50	fe 0d		. .
	jp z,l4d77h		;4d52	ca 77 4d	. w M
	cp 054h			;4d55	fe 54		. T
	jp z,l4d77h		;4d57	ca 77 4d	. w M
	xor a			;4d5a	af		.
	ret			;4d5b	c9		.
	ld hl,(04020h)		;4d5c	2a 20 40	*   @
	ld a,01ch		;4d5f	3e 1c		> .
	call 00033h		;4d61	cd 33 00	. 3 .
	ld (04020h),hl		;4d64	22 20 40	"   @
	xor a			;4d67	af		.
	call 00033h		;4d68	cd 33 00	. 3 .
	ret			;4d6b	c9		.
sub_4d6ch:
	push hl			;4d6c	e5		.
	ld hl,(037f1h)		;4d6d	2a f1 37	* . 7
	call 04c92h		;4d70	cd 92 4c	. . L
	ld c,l			;4d73	4d		M
	ld b,h			;4d74	44		D
	pop hl			;4d75	e1		.
	ret			;4d76	c9		.
l4d77h:
	ld a,(04023h)		;4d77	3a 23 40	: # @
	or a			;4d7a	b7		.
	jr z,l4d8dh		;4d7b	28 10		( .
	call sub_4d6ch		;4d7d	cd 6c 4d	. l M
	ld hl,(03406h)		;4d80	2a 06 34	* . 4
	or a			;4d83	b7		.
	sbc hl,bc		;4d84	ed 42		. B
	ld de,(03400h)		;4d86	ed 5b 00 34	. [ . 4
	call 03656h		;4d8a	cd 56 36	. V 6
l4d8dh:
	ld a,(04024h)		;4d8d	3a 24 40	: $ @
	or a			;4d90	b7		.
	ret z			;4d91	c8		.
	call sub_4d6ch		;4d92	cd 6c 4d	. l M
	ld hl,(03402h)		;4d95	2a 02 34	* . 4
	ld de,(03406h)		;4d98	ed 5b 06 34	. [ . 4
	call 03656h		;4d9c	cd 56 36	. V 6
	xor a			;4d9f	af		.
	ret			;4da0	c9		.
l4da1h:
	push af			;4da1	f5		.
	push bc			;4da2	c5		.
	push de			;4da3	d5		.
	push hl			;4da4	e5		.
	call l4d77h		;4da5	cd 77 4d	. w M
	pop hl			;4da8	e1		.
	pop de			;4da9	d1		.
	pop bc			;4daa	c1		.
	pop af			;4dab	f1		.
	ret			;4dac	c9		.
sub_4dadh:
	call sub_4db5h		;4dad	cd b5 4d	. . M
	ld a,(hl)		;4db0	7e		~
l4db1h:
	ret			;4db1	c9		.
	jp 03678h		;4db2	c3 78 36	. x 6
sub_4db5h:
	ret			;4db5	c9		.
	jp 03605h		;4db6	c3 05 36	. . 6
l4db9h:
	ld a,(04307h)		;4db9	3a 07 43	: . C
	and 00fh		;4dbc	e6 0f		. .
	cp 002h			;4dbe	fe 02		. .
	ld hl,03c00h		;4dc0	21 00 3c	! . <
	ld de,04000h		;4dc3	11 00 40	. . @
	jr z,l4dd0h		;4dc6	28 08		( .
	res 0,a			;4dc8	cb 87		. .
	cp 004h			;4dca	fe 04		. .
	jr nz,l4e02h		;4dcc	20 34		  4
	ld h,038h		;4dce	26 38		& 8
l4dd0h:
	ex de,hl		;4dd0	eb		.
	ld a,(037fch)		;4dd1	3a fc 37	: . 7
	ld h,a			;4dd4	67		g
	ld a,(037fdh)		;4dd5	3a fd 37	: . 7
	ld l,a			;4dd8	6f		o
	add hl,de		;4dd9	19		.
	push hl			;4dda	e5		.
	ld a,(037f6h)		;4ddb	3a f6 37	: . 7
	ld l,a			;4dde	6f		o
	ld a,(037f8h)		;4ddf	3a f8 37	: . 7
	and 003h		;4de2	e6 03		. .
	cp 003h			;4de4	fe 03		. .
	jr nz,l4deah		;4de6	20 02		  .
	rlc l			;4de8	cb 05		. .
l4deah:
	ld a,(037f1h)		;4dea	3a f1 37	: . 7
	ld (04e1fh),a		;4ded	32 1f 4e	2 . N
	call 04c92h		;4df0	cd 92 4c	. . L
	ex de,hl		;4df3	eb		.
	pop hl			;4df4	e1		.
	ex de,hl		;4df5	eb		.
	add hl,de		;4df6	19		.
	ex de,hl		;4df7	eb		.
	xor a			;4df8	af		.
	ld (sub_4db5h),a	;4df9	32 b5 4d	2 . M
	ld (l4db1h),a		;4dfc	32 b1 4d	2 . M
	ld bc,00000h		;4dff	01 00 00	. . .
l4e02h:
	call 005d1h		;4e02	cd d1 05	. . .
	jr z,l4e0eh		;4e05	28 07		( .
	dec bc			;4e07	0b		.
	ld a,b			;4e08	78		x
	or c			;4e09	b1		.
	jr z,l4e58h		;4e0a	28 4c		( L
	jr l4e02h		;4e0c	18 f4		. .
l4e0eh:
	ex de,hl		;4e0e	eb		.
l4e0fh:
	dec hl			;4e0f	2b		+
	rst 18h			;4e10	df		.
	jr z,l4e1bh		;4e11	28 08		( .
	call sub_4dadh		;4e13	cd ad 4d	. . M
	cp 020h			;4e16	fe 20		.  
	jr z,l4e0fh		;4e18	28 f5		( .
	inc hl			;4e1a	23		#
l4e1bh:
	ex de,hl		;4e1b	eb		.
l4e1ch:
	push de			;4e1c	d5		.
	push hl			;4e1d	e5		.
	ld e,040h		;4e1e	1e 40		. @
	ld d,000h		;4e20	16 00		. .
	add hl,de		;4e22	19		.
	ld b,e			;4e23	43		C
l4e24h:
	dec hl			;4e24	2b		+
	call sub_4dadh		;4e25	cd ad 4d	. . M
	cp 020h			;4e28	fe 20		.  
	jr nz,l4e2fh		;4e2a	20 03		  .
	djnz l4e24h		;4e2c	10 f6		. .
	inc b			;4e2e	04		.
l4e2fh:
	pop hl			;4e2f	e1		.
	ld (04e4fh),hl		;4e30	22 4f 4e	" O N
	pop de			;4e33	d1		.
l4e34h:
	call sub_4dadh		;4e34	cd ad 4d	. . M
	cp 020h			;4e37	fe 20		.  
	jr nc,l4e3dh		;4e39	30 02		0 .
	or 040h			;4e3b	f6 40		. @
l4e3dh:
	call sub_4e5ch		;4e3d	cd 5c 4e	. \ N
	inc hl			;4e40	23		#
	ld a,(03840h)		;4e41	3a 40 38	: @ 8
	and 004h		;4e44	e6 04		. .
	jr nz,l4e5ah		;4e46	20 12		  .
	djnz l4e34h		;4e48	10 ea		. .
	ld a,(04e1fh)		;4e4a	3a 1f 4e	: . N
	ld c,a			;4e4d	4f		O
	ld hl,00000h		;4e4e	21 00 00	! . .
	add hl,bc		;4e51	09		.
	call l4e5ah		;4e52	cd 5a 4e	. Z N
	rst 18h			;4e55	df		.
	jr c,l4e1ch		;4e56	38 c4		8 .
l4e58h:
	xor a			;4e58	af		.
	ret			;4e59	c9		.
l4e5ah:
	ld a,00dh		;4e5a	3e 0d		> .
sub_4e5ch:
	push de			;4e5c	d5		.
	ld e,a			;4e5d	5f		_
	ld a,(04370h)		;4e5e	3a 70 43	: p C
	cp e			;4e61	bb		.
	jr nc,l4e66h		;4e62	30 02		0 .
	ld e,020h		;4e64	1e 20		.  
l4e66h:
	ld a,e			;4e66	7b		{
	call 0003bh		;4e67	cd 3b 00	. ; .
	pop de			;4e6a	d1		.
	ret			;4e6b	c9		.
l4e6ch:
	ld d,b			;4e6c	50		P
	ld c,c			;4e6d	49		I
	ld c,a			;4e6e	4f		O
	jr nz,l4e74h		;4e6f	20 03		  .
l4e71h:
	ld c,(hl)		;4e71	4e		N
	ld c,a			;4e72	4f		O
	ld d,b			;4e73	50		P
l4e74h:
	ld d,d			;4e74	52		R
	dec c			;4e75	0d		.
l4e76h:
	ld a,(04307h)		;4e76	3a 07 43	: . C
	and 007h		;4e79	e6 07		. .
	cp 004h			;4e7b	fe 04		. .
	ld a,02ah		;4e7d	3e 2a		> *
	ret c			;4e7f	d8		.
	ld a,(hl)		;4e80	7e		~
	cp 00dh			;4e81	fe 0d		. .
	jr z,l4e90h		;4e83	28 0b		( .
	cp 050h			;4e85	fe 50		. P
	jr z,l4ebch		;4e87	28 33		( 3
	cp 04eh			;4e89	fe 4e		. N
	jr z,l4ea7h		;4e8b	28 1a		( .
	jp l4d38h		;4e8d	c3 38 4d	. 8 M
l4e90h:
	ld hl,l4e6ch		;4e90	21 6c 4e	! l N
	call 04467h		;4e93	cd 67 44	. g D
	ld hl,l4e71h		;4e96	21 71 4e	! q N
	ld a,(005bdh)		;4e99	3a bd 05	: . .
	cp 0d4h			;4e9c	fe d4		. .
	jr nz,l4ea2h		;4e9e	20 02		  .
	inc hl			;4ea0	23		#
	inc hl			;4ea1	23		#
l4ea2h:
	call 04467h		;4ea2	cd 67 44	. g D
l4ea5h:
	xor a			;4ea5	af		.
	ret			;4ea6	c9		.
l4ea7h:
	ld hl,037e8h		;4ea7	21 e8 37	! . 7
	ld a,032h		;4eaa	3e 32		> 2
	ld (005bbh),a		;4eac	32 bb 05	2 . .
	ld (005bch),hl		;4eaf	22 bc 05	" . .
	ld a,03ah		;4eb2	3e 3a		> :
	ld (005d1h),a		;4eb4	32 d1 05	2 . .
	ld (005d2h),hl		;4eb7	22 d2 05	" . .
	jr l4ea5h		;4eba	18 e9		. .
l4ebch:
	ld a,007h		;4ebc	3e 07		> .
	out (0d6h),a		;4ebe	d3 d6		. .
	out (0d7h),a		;4ec0	d3 d7		. .
	ld a,00fh		;4ec2	3e 0f		> .
	out (0d6h),a		;4ec4	d3 d6		. .
	ld a,0cfh		;4ec6	3e cf		> .
	out (0d7h),a		;4ec8	d3 d7		. .
	ld a,0feh		;4eca	3e fe		> .
	out (0d7h),a		;4ecc	d3 d7		. .
	ld a,001h		;4ece	3e 01		> .
	out (0d5h),a		;4ed0	d3 d5		. .
	ld hl,0d4d3h		;4ed2	21 d3 d4	! . .
	xor a			;4ed5	af		.
	ld (005bbh),a		;4ed6	32 bb 05	2 . .
	ld (005bch),hl		;4ed9	22 bc 05	" . .
	ld (005d1h),a		;4edc	32 d1 05	2 . .
	ld hl,0d5dbh		;4edf	21 db d5	! . .
	ld (005d2h),hl		;4ee2	22 d2 05	" . .
	jr l4ea5h		;4ee5	18 be		. .
l4ee7h:
	ld sp,00000h		;4ee7	31 00 00	1 . .
	or a			;4eea	b7		.
	ret			;4eeb	c9		.
sub_4eech:
; sub_4eech: entry for request code 9Ch (l4e76h leads here). Computes a directory-sector/FPDE address (via sub_4f2ch) after its OWN DRVSEL(0) call below -- a second, independent occurrence of the same idiom patched at 4f34h, reached by a request code this boot path does not exercise. Not patched.
	push hl			;4eec	e5		.
	push de			;4eed	d5		.
	push bc			;4eee	c5		.
	push af			;4eef	f5		.
	ld hl,l4d00h		;4ef0	21 00 4d	! . M
	ld (hl),a		;4ef3	77		w
	and 007h		;4ef4	e6 07		. .
	ld c,a			;4ef6	4f		O
; [note] XOR A / LD (43D8h),A / LD (45BEh),A / CALL 4776h -- same stock idiom as SYS0/SYS's 4BE4h (GETSYS's own module loader) and this file's own 4f34h below: one register clear doing double duty as both DRVSEL's drive-0 argument and the shared FCB's NEXT-field reset. Not yet patched -- this call site is not exercised by the boot path that found the 4f34h bug.
	xor a			;4ef7	af		.
	ld (043d8h),a		;4ef8	32 d8 43	2 . C
	ld (045beh),a		;4efb	32 be 45	2 . E
	call sub_50d5h		;4efe	cd d5 50	. . P
	ld a,(hl)		;4f01	7e		~
	sub c			;4f02	91		.
	rlca			;4f03	07		.
	rlca			;4f04	07		.
	call sub_4f2ch		;4f05	cd 2c 4f	. , O
	jp nz,l4ee7h		;4f08	c2 e7 4e	. . N
	bit 6,(hl)		;4f0b	cb 76		. v
	jr z,l4f26h		;4f0d	28 17		( .
	add a,014h		;4f0f	c6 14		. .
	ld l,a			;4f11	6f		o
	ld a,(hl)		;4f12	7e		~
	ld (l4d03h),a		;4f13	32 03 4d	2 . M
	inc l			;4f16	2c		,
	inc l			;4f17	2c		,
	ld e,(hl)		;4f18	5e		^
	inc hl			;4f19	23		#
	ld d,(hl)		;4f1a	56		V
	ld (043dch),de		;4f1b	ed 53 dc 43	. S . C
	ld hl,043ceh		;4f1f	21 ce 43	! . C
	ld (l4d01h),hl		;4f22	22 01 4d	" . M
	xor a			;4f25	af		.
l4f26h:
	pop bc			;4f26	c1		.
	ld a,b			;4f27	78		x
	pop bc			;4f28	c1		.
	pop de			;4f29	d1		.
	pop hl			;4f2a	e1		.
	ret			;4f2b	c9		.
sub_4f2ch:
; sub_4f2ch: HL = 5100h + (A<<8 adjustment via C), called once from sub_4eech.
	ld l,a			;4f2c	6f		o
	ld a,c			;4f2d	79		y
	add a,051h		;4f2e	c6 51		. Q
	ld h,a			;4f30	67		g
	xor a			;4f31	af		.
	ld a,l			;4f32	7d		}
	ret			;4f33	c9		.
sub_4f34h:
; sub_4f34h: reached from l4fb6h (the default dispatch path) on this module's own first load-and-run (request code = bare module value, A=1Ch). [note] This is the routine whose DRVSEL(0) call fires right after GETSYS's own six DRVSEL(5) module-load calls, and the direct cause of the floppy seek/read (track 41, then track 1) this port had to patch out. Live memory and this static file match byte for byte.
	xor a			;4f34	af		.
; [PATCH] dfcbdv (43D8h, FCB NEXT field) reset to 0 -- unchanged by the patch.
	ld (043d8h),a		;4f35	32 d8 43	2 . C
; [PATCH] a flag at 45BEh reset to 0 -- unchanged by the patch (matches GETSYS's own prologue clearing the same cell).
	ld (045beh),a		;4f38	32 be 45	2 . E
; [PATCH] stock: CALL 4776h (DRVSEL, A still 0 from the XOR A three lines above -- drive 0, hardcoded). Patched: CALL 50D0h, a same-size stub (LD A,05h / JP 4776h) planted in dead space -- see 50d0h below. File size is unchanged; dmk.py --replace has no support for growing a file's on-disk allocation, so an in-place same-footprint fix was required and this 10-byte block (XOR A + two stores + CALL) has no 1-byte way to load A with sysvol.
	call sub_50d0h		;4f3b	cd d0 50	. . P
; original continuation after the DRVSEL call -- unchanged. The patch's stub tail-jumps into 4776h, so DRVSEL's own eventual RET returns here exactly as stock did.
	ld b,008h		;4f3e	06 08		. .
	xor a			;4f40	af		.
; [note] DE=5100h: destination of the 8x256-byte GETFDE/LDIR copy loop below. 5100h-51E7h (all zero in the static file) is genuinely dead/unused space in the file's own image *until* this loop runs -- it is a runtime buffer, not a home for a patch trampoline (checked: this file's only static reference into 50C9h-51E7h is 5100h itself).
	ld de,l5100h		;4f41	11 00 51	. . Q
l4f44h:
	push bc			;4f44	c5		.
	push de			;4f45	d5		.
	push af			;4f46	f5		.
	call 04936h		;4f47	cd 36 49	. 6 I
	jp nz,l4ee7h		;4f4a	c2 e7 4e	. . N
	pop af			;4f4d	f1		.
	pop de			;4f4e	d1		.
	ld bc,00100h		;4f4f	01 00 01	. . .
	ldir			;4f52	ed b0		. .
	inc a			;4f54	3c		<
	pop bc			;4f55	c1		.
	djnz l4f44h		;4f56	10 ec		. .
	ret			;4f58	c9		.
sub_4f59h:
	ld a,(l4d03h)		;4f59	3a 03 4d	: . M
	or a			;4f5c	b7		.
	jr z,l4f76h		;4f5d	28 17		( .
	push af			;4f5f	f5		.
	dec a			;4f60	3d		=
	ld (l4d03h),a		;4f61	32 03 4d	2 . M
	push bc			;4f64	c5		.
	push de			;4f65	d5		.
	push hl			;4f66	e5		.
	ld de,(l4d01h)		;4f67	ed 5b 01 4d	. [ . M
	call 04436h		;4f6b	cd 36 44	. 6 D
	jp nz,l4ee7h		;4f6e	c2 e7 4e	. . N
	pop hl			;4f71	e1		.
	pop de			;4f72	d1		.
	pop bc			;4f73	c1		.
	pop af			;4f74	f1		.
	ret			;4f75	c9		.
l4f76h:
	xor a			;4f76	af		.
	ret			;4f77	c9		.
l4f78h:
	ld (0393bh),sp		;4f78	ed 73 3b 39	. s ; 9
	ld sp,03bfeh		;4f7c	31 fe 3b	1 . ;
	push hl			;4f7f	e5		.
	push de			;4f80	d5		.
	push bc			;4f81	c5		.
	push af			;4f82	f5		.
	ld (0392bh),hl		;4f83	22 2b 39	" + 9
	ld hl,04200h		;4f86	21 00 42	! . B
	ld bc,00100h		;4f89	01 00 01	. . .
	push de			;4f8c	d5		.
	ld de,03a00h		;4f8d	11 00 3a	. . :
	ldir			;4f90	ed b0		. .
	pop de			;4f92	d1		.
	ld hl,03a00h		;4f93	21 00 3a	! . :
	ld bc,00100h		;4f96	01 00 01	. . .
	in a,(0f9h)		;4f99	db f9		. .
	push af			;4f9b	f5		.
	di			;4f9c	f3		.
	and 03eh		;4f9d	e6 3e		. >
	out (0f9h),a		;4f9f	d3 f9		. .
	ld (00000h),de		;4fa1	ed 53 00 00	. S . .
	ld d,e			;4fa5	53		S
	ld e,000h		;4fa6	1e 00		. .
	ldir			;4fa8	ed b0		. .
	pop af			;4faa	f1		.
	out (0f9h),a		;4fab	d3 f9		. .
	ei			;4fad	fb		.
	pop af			;4fae	f1		.
	pop bc			;4faf	c1		.
	pop de			;4fb0	d1		.
	pop hl			;4fb1	e1		.
	ld sp,00000h		;4fb2	31 00 00	1 . .
	ret			;4fb5	c9		.
l4fb6h:
	ld (l4ee7h+1),sp	;4fb6	ed 73 e8 4e	. s . N
	ld a,(03840h)		;4fba	3a 40 38	: @ 8
	bit 6,a			;4fbd	cb 77		. w
	jr nz,l4fcdh		;4fbf	20 0c		  .
	ld a,(04307h)		;4fc1	3a 07 43	: . C
	and 00fh		;4fc4	e6 0f		. .
	cp 003h			;4fc6	fe 03		. .
	jp z,l4fcdh		;4fc8	ca cd 4f	. . O
	cp 004h			;4fcb	fe 04		. .
l4fcdh:
	ld a,000h		;4fcd	3e 00		> .
	ret nz			;4fcf	c0		.
	call sub_4f34h		;4fd0	cd 34 4f	. 4 O
	ld hl,l4f78h		;4fd3	21 78 4f	! x O
	ld de,03900h		;4fd6	11 00 39	. . 9
	ld bc,0003eh		;4fd9	01 3e 00	. > .
	ldir			;4fdc	ed b0		. .
	ld a,001h		;4fde	3e 01		> .
	ld (l4d03h),a		;4fe0	32 03 4d	2 . M
	ld hl,04200h		;4fe3	21 00 42	! . B
	ld de,04201h		;4fe6	11 01 42	. . B
	ld (hl),000h		;4fe9	36 00		6 .
	ld bc,000ffh		;4feb	01 ff 00	. . .
	ldir			;4fee	ed b0		. .
	ld hl,l5071h		;4ff0	21 71 50	! q P
	ld de,04280h		;4ff3	11 80 42	. . B
	ld bc,00013h		;4ff6	01 13 00	. . .
	ldir			;4ff9	ed b0		. .
	ld hl,04000h		;4ffb	21 00 40	! . @
	ld e,040h		;4ffe	1e 40		. @
	call 03900h		;5000	cd 00 39	. . 9
	ld b,01dh		;5003	06 1d		. .
	ld ix,l5084h		;5005	dd 21 84 50	. ! . P
	ld e,041h		;5009	1e 41		. A
l500bh:
	ld h,040h		;500b	26 40		& @
	ld a,(ix+000h)		;500d	dd 7e 00	. ~ .
	add a,002h		;5010	c6 02		. .
	ld l,a			;5012	6f		o
	rlc l			;5013	cb 05		. .
	call sub_4eech		;5015	cd ec 4e	. . N
	jr nz,l5028h		;5018	20 0e		  .
l501ah:
	call sub_4f59h		;501a	cd 59 4f	. Y O
	jr z,l5028h		;501d	28 09		( .
	ld d,a			;501f	57		W
	call 03900h		;5020	cd 00 39	. . 9
	ld l,000h		;5023	2e 00		. .
	inc e			;5025	1c		.
	jr l501ah		;5026	18 f2		. .
l5028h:
	inc ix			;5028	dd 23		. #
	dec b			;502a	05		.
	jr nz,l500bh		;502b	20 de		  .
	ld hl,l50a1h		;502d	21 a1 50	! . P
	ld de,03738h		;5030	11 38 37	. 8 7
	ld bc,00028h		;5033	01 28 00	. ( .
	ldir			;5036	ed b0		. .
	ld hl,l5046h		;5038	21 46 50	! F P
	ld de,04be1h		;503b	11 e1 4b	. . K
	ld bc,0002bh		;503e	01 2b 00	. + .
	ldir			;5041	ed b0		. .
	jp l4f76h		;5043	c3 76 4f	. v O
l5046h:
	ld h,040h		;5046	26 40		& @
	call 03738h		;5048	cd 38 37	. 8 7
	ld a,(04317h)		;504b	3a 17 43	: . C
	rlca			;504e	07		.
	ld l,a			;504f	6f		o
	ld h,03ah		;5050	26 3a		& :
	ld a,(hl)		;5052	7e		~
	ld (03753h),a		;5053	32 53 37	2 S 7
	inc hl			;5056	23		#
	ld a,(hl)		;5057	7e		~
	or a			;5058	b7		.
	jr z,l5073h		;5059	28 18		( .
	ld hl,03751h		;505b	21 51 37	! Q 7
	ld (04c6dh),hl		;505e	22 6d 4c	" m L
	ld de,03affh		;5061	11 ff 3a	. . :
	call 04c2eh		;5064	cd 2e 4c	. . L
	ld (04c1eh),hl		;5067	22 1e 4c	" . L
	ld hl,04436h		;506a	21 36 44	! 6 D
	ld (04c6dh),hl		;506d	22 6d 4c	" m L
	nop			;5070	00		.
l5071h:
	push hl			;5071	e5		.
	push de			;5072	d5		.
l5073h:
	push bc			;5073	c5		.
	push af			;5074	f5		.
	ld l,000h		;5075	2e 00		. .
	ld de,03a00h		;5077	11 00 3a	. . :
	ld bc,00100h		;507a	01 00 01	. . .
	ldir			;507d	ed b0		. .
	pop af			;507f	f1		.
	pop bc			;5080	c1		.
	pop de			;5081	d1		.
	pop hl			;5082	e1		.
	ret			;5083	c9		.
l5084h:
	add hl,de		;5084	19		.
	jr $+31			;5085	18 1d		. .
	rla			;5087	17		.
	ld de,00b10h		;5088	11 10 0b	. . .
	rrca			;508b	0f		.
	ld c,007h		;508c	0e 07		. .
	inc de			;508e	13		.
	ld (de),a		;508f	12		.
	dec c			;5090	0d		.
	ld a,(bc)		;5091	0a		.
	inc d			;5092	14		.
	ld bc,00302h		;5093	01 02 03	. . .
	inc b			;5096	04		.
	ex af,af'		;5097	08		.
	add hl,bc		;5098	09		.
	dec b			;5099	05		.
	ld b,00ch		;509a	06 0c		. .
	dec d			;509c	15		.
	inc e			;509d	1c		.
	ld d,01bh		;509e	16 1b		. .
	ld a,(de)		;50a0	1a		.
l50a1h:
	ld (0374eh),sp		;50a1	ed 73 4e 37	. s N 7
	di			;50a5	f3		.
	ld sp,03bfeh		;50a6	31 fe 3b	1 . ;
	in a,(0f9h)		;50a9	db f9		. .
	push af			;50ab	f5		.
	and 03eh		;50ac	e6 3e		. >
	out (0f9h),a		;50ae	d3 f9		. .
	call 04080h		;50b0	cd 80 40	. . @
	pop af			;50b3	f1		.
	out (0f9h),a		;50b4	d3 f9		. .
	ld sp,00000h		;50b6	31 00 00	1 . .
	ret			;50b9	c9		.
	push hl			;50ba	e5		.
	ld h,000h		;50bb	26 00		& .
	call 03738h		;50bd	cd 38 37	. 8 7
	ld a,h			;50c0	7c		|
	inc a			;50c1	3c		<
	ld (03753h),a		;50c2	32 53 37	2 S 7
	xor a			;50c5	af		.
	ei			;50c6	fb		.
	pop hl			;50c7	e1		.
	ret			;50c8	c9		.
; [note] 50C9h-51E7h: all zero in the stock file. Not slack for a patch -- this is the buffer sub_4f34h's own LDIR loop (above) fills at runtime with 8x256 bytes of directory data.
	nop			;50c9	00		.
	nop			;50ca	00		.
	nop			;50cb	00		.
	nop			;50cc	00		.
	nop			;50cd	00		.
	nop			;50ce	00		.
	nop			;50cf	00		.
sub_50d0h:
; [PATCH] added: LD A,05h / JP 4776h -- the stub 4f3bh now calls. Loads sysvol instead of hardcoded drive 0, then tail-jumps into DRVSEL so its own RET returns to 4f3eh (sub_4f34h's original continuation) exactly as the un-patched CALL 4776h would have. Placed here because it is confirmed dead space (see 50c9h note) that sits *before* the 5100h runtime buffer, so it survives the LDIR loop that follows.
	ld a,005h		;50d0	3e 05		> .
	jp 04776h		;50d2	c3 76 47	. v G
sub_50d5h:
	ld a,005h		;50d5	3e 05		> .
	jp 04776h		;50d7	c3 76 47	. v G
	nop			;50da	00		.
	nop			;50db	00		.
	nop			;50dc	00		.
	nop			;50dd	00		.
	nop			;50de	00		.
	nop			;50df	00		.
	nop			;50e0	00		.
	nop			;50e1	00		.
	nop			;50e2	00		.
	nop			;50e3	00		.
	nop			;50e4	00		.
	nop			;50e5	00		.
	nop			;50e6	00		.
	nop			;50e7	00		.
	nop			;50e8	00		.
	nop			;50e9	00		.
	nop			;50ea	00		.
	nop			;50eb	00		.
	nop			;50ec	00		.
	nop			;50ed	00		.
	nop			;50ee	00		.
	nop			;50ef	00		.
	nop			;50f0	00		.
	nop			;50f1	00		.
	nop			;50f2	00		.
	nop			;50f3	00		.
	nop			;50f4	00		.
	nop			;50f5	00		.
	nop			;50f6	00		.
	nop			;50f7	00		.
	nop			;50f8	00		.
	nop			;50f9	00		.
	nop			;50fa	00		.
	nop			;50fb	00		.
	nop			;50fc	00		.
	nop			;50fd	00		.
	nop			;50fe	00		.
	nop			;50ff	00		.
l5100h:
	nop			;5100	00		.
	nop			;5101	00		.
	nop			;5102	00		.
	nop			;5103	00		.
	nop			;5104	00		.
	nop			;5105	00		.
	nop			;5106	00		.
	nop			;5107	00		.
	nop			;5108	00		.
	nop			;5109	00		.
	nop			;510a	00		.
	nop			;510b	00		.
	nop			;510c	00		.
	nop			;510d	00		.
	nop			;510e	00		.
	nop			;510f	00		.
	nop			;5110	00		.
	nop			;5111	00		.
	nop			;5112	00		.
	nop			;5113	00		.
	nop			;5114	00		.
	nop			;5115	00		.
	nop			;5116	00		.
	nop			;5117	00		.
	nop			;5118	00		.
	nop			;5119	00		.
	nop			;511a	00		.
	nop			;511b	00		.
	nop			;511c	00		.
	nop			;511d	00		.
	nop			;511e	00		.
	nop			;511f	00		.
	nop			;5120	00		.
	nop			;5121	00		.
	nop			;5122	00		.
	nop			;5123	00		.
	nop			;5124	00		.
	nop			;5125	00		.
	nop			;5126	00		.
	nop			;5127	00		.
	nop			;5128	00		.
	nop			;5129	00		.
	nop			;512a	00		.
	nop			;512b	00		.
	nop			;512c	00		.
	nop			;512d	00		.
	nop			;512e	00		.
	nop			;512f	00		.
	nop			;5130	00		.
	nop			;5131	00		.
	nop			;5132	00		.
	nop			;5133	00		.
	nop			;5134	00		.
	nop			;5135	00		.
	nop			;5136	00		.
	nop			;5137	00		.
	nop			;5138	00		.
	nop			;5139	00		.
	nop			;513a	00		.
	nop			;513b	00		.
	nop			;513c	00		.
	nop			;513d	00		.
	nop			;513e	00		.
	nop			;513f	00		.
	nop			;5140	00		.
	nop			;5141	00		.
	nop			;5142	00		.
	nop			;5143	00		.
	nop			;5144	00		.
	nop			;5145	00		.
	nop			;5146	00		.
	nop			;5147	00		.
	nop			;5148	00		.
	nop			;5149	00		.
	nop			;514a	00		.
	nop			;514b	00		.
	nop			;514c	00		.
	nop			;514d	00		.
	nop			;514e	00		.
	nop			;514f	00		.
	nop			;5150	00		.
	nop			;5151	00		.
	nop			;5152	00		.
	nop			;5153	00		.
	nop			;5154	00		.
	nop			;5155	00		.
	nop			;5156	00		.
	nop			;5157	00		.
	nop			;5158	00		.
	nop			;5159	00		.
	nop			;515a	00		.
	nop			;515b	00		.
	nop			;515c	00		.
	nop			;515d	00		.
	nop			;515e	00		.
	nop			;515f	00		.
	nop			;5160	00		.
	nop			;5161	00		.
	nop			;5162	00		.
	nop			;5163	00		.
	nop			;5164	00		.
	nop			;5165	00		.
	nop			;5166	00		.
	nop			;5167	00		.
	nop			;5168	00		.
	nop			;5169	00		.
	nop			;516a	00		.
	nop			;516b	00		.
	nop			;516c	00		.
	nop			;516d	00		.
	nop			;516e	00		.
	nop			;516f	00		.
	nop			;5170	00		.
	nop			;5171	00		.
	nop			;5172	00		.
	nop			;5173	00		.
	nop			;5174	00		.
	nop			;5175	00		.
	nop			;5176	00		.
	nop			;5177	00		.
	nop			;5178	00		.
	nop			;5179	00		.
	nop			;517a	00		.
	nop			;517b	00		.
	nop			;517c	00		.
	nop			;517d	00		.
	nop			;517e	00		.
	nop			;517f	00		.
	nop			;5180	00		.
	nop			;5181	00		.
	nop			;5182	00		.
	nop			;5183	00		.
	nop			;5184	00		.
	nop			;5185	00		.
	nop			;5186	00		.
	nop			;5187	00		.
	nop			;5188	00		.
	nop			;5189	00		.
	nop			;518a	00		.
	nop			;518b	00		.
	nop			;518c	00		.
	nop			;518d	00		.
	nop			;518e	00		.
	nop			;518f	00		.
	nop			;5190	00		.
	nop			;5191	00		.
	nop			;5192	00		.
	nop			;5193	00		.
	nop			;5194	00		.
	nop			;5195	00		.
	nop			;5196	00		.
	nop			;5197	00		.
	nop			;5198	00		.
	nop			;5199	00		.
	nop			;519a	00		.
	nop			;519b	00		.
	nop			;519c	00		.
	nop			;519d	00		.
	nop			;519e	00		.
	nop			;519f	00		.
	nop			;51a0	00		.
	nop			;51a1	00		.
	nop			;51a2	00		.
	nop			;51a3	00		.
	nop			;51a4	00		.
	nop			;51a5	00		.
	nop			;51a6	00		.
	nop			;51a7	00		.
	nop			;51a8	00		.
	nop			;51a9	00		.
	nop			;51aa	00		.
	nop			;51ab	00		.
	nop			;51ac	00		.
	nop			;51ad	00		.
	nop			;51ae	00		.
	nop			;51af	00		.
	nop			;51b0	00		.
	nop			;51b1	00		.
	nop			;51b2	00		.
	nop			;51b3	00		.
	nop			;51b4	00		.
	nop			;51b5	00		.
	nop			;51b6	00		.
	nop			;51b7	00		.
	nop			;51b8	00		.
	nop			;51b9	00		.
	nop			;51ba	00		.
	nop			;51bb	00		.
	nop			;51bc	00		.
	nop			;51bd	00		.
	nop			;51be	00		.
	nop			;51bf	00		.
	nop			;51c0	00		.
	nop			;51c1	00		.
	nop			;51c2	00		.
	nop			;51c3	00		.
	nop			;51c4	00		.
	nop			;51c5	00		.
	nop			;51c6	00		.
	nop			;51c7	00		.
	nop			;51c8	00		.
	nop			;51c9	00		.
	nop			;51ca	00		.
	nop			;51cb	00		.
	nop			;51cc	00		.
	nop			;51cd	00		.
	nop			;51ce	00		.
	nop			;51cf	00		.
	nop			;51d0	00		.
	nop			;51d1	00		.
	nop			;51d2	00		.
	nop			;51d3	00		.
	nop			;51d4	00		.
	nop			;51d5	00		.
	nop			;51d6	00		.
	nop			;51d7	00		.
	nop			;51d8	00		.
	nop			;51d9	00		.
	nop			;51da	00		.
	nop			;51db	00		.
	nop			;51dc	00		.
	nop			;51dd	00		.
	nop			;51de	00		.
	nop			;51df	00		.
	nop			;51e0	00		.
	nop			;51e1	00		.
	nop			;51e2	00		.
	nop			;51e3	00		.
	nop			;51e4	00		.
	nop			;51e5	00		.
	nop			;51e6	00		.
	nop			;51e7	00		.
