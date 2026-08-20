;************************************************************************
;
; SYS1 from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys1-sys-disassembly.asm
;
; Date: 2026/08/20
;
;************************************************************************
; /src/GDOS-2.4-SYS-files/sys1-sys-disassembly.asm
; SYS1/SYS, stock GDOS 2.4
;
; Start 4D00h, RAM range 4D00h-51DFh -- confirmed two independent ways:
; (1) this file's own load records (tools/trsload.py --map against
; DMK/G3S-GDOS24.DMK's SYS1/SYS), perfectly contiguous, no gaps;
; (2) matches src/G3S-GDOS24-Extract/SYS-Files-RAM-RANGES.md exactly
; (Grosser ch.7: "SYS1/SYS -- EOF 4/248, RAM 4D00-51DF, Start 4D00").
;
; z80dasm 1.2.0
; command line: z80dasm -g 0x4d00 -l -a -t -o sys1-sys-disassembly.asm sys1sys_flat.bin
;
; Not yet cross-checked against Grosser (his book has no GDOS-specific
; SYS1/SYS listing -- see the Grosser-verification-rule memory) or
; annotated -- this is raw, unedited z80dasm output.

; z80dasm 1.2.0
; command line: z80dasm -g 0x4d00 -l -a -t -o sys1sys_flat.bin

	org 04d00h

	cp 023h			;4d00	fe 23		. #
	jp z,l4d8ah		;4d02	ca 8a 4d	. . M
	cp 043h			;4d05	fe 43		. C
	jr z,l4d7ch		;4d07	28 73		( s
	cp 063h			;4d09	fe 63		. c
	jp z,l4e30h		;4d0b	ca 30 4e	. 0 N
	cp 083h			;4d0e	fe 83		. .
	jp z,l5155h		;4d10	ca 55 51	. U Q
	cp 0a3h			;4d13	fe a3		. .
	jp z,l4f2ah		;4d15	ca 2a 4f	. * O
	cp 0c3h			;4d18	fe c3		. .
	jr z,l4d5bh		;4d1a	28 3f		( ?
	dec c			;4d1c	0d		.
	jr z,l4d59h		;4d1d	28 3a		( :
	dec c			;4d1f	0d		.
	jp z,l50cfh		;4d20	ca cf 50	. . P
	dec c			;4d23	0d		.
	jp z,l4d32h		;4d24	ca 32 4d	. 2 M
	dec c			;4d27	0d		.
	jp z,l50f3h		;4d28	ca f3 50	. . P
	dec c			;4d2b	0d		.
	jr z,l4d80h		;4d2c	28 52		( R
	dec c			;4d2e	0d		.
	jp z,l5112h		;4d2f	ca 12 51	. . Q
l4d32h:
	dec c			;4d32	0d		.
	jr z,l4d78h		;4d33	28 43		( C
	dec c			;4d35	0d		.
	jp z,l4e34h		;4d36	ca 34 4e	. 4 N
	dec c			;4d39	0d		.
	jr z,l4d48h		;4d3a	28 0c		( .
	dec c			;4d3c	0d		.
	dec c			;4d3d	0d		.
	jp z,l5168h		;4d3e	ca 68 51	. h Q
	dec c			;4d41	0d		.
	jr z,l4d80h		;4d42	28 3c		( <
l4d44h:
	ld a,02ah		;4d44	3e 2a		> *
	or a			;4d46	b7		.
	ret			;4d47	c9		.
l4d48h:
	ld hl,l51ddh		;4d48	21 dd 51	! . Q
	jp 04467h		;4d4b	c3 67 44	. g D
	exx			;4d4e	d9		.
	ld bc,0e301h		;4d4f	01 01 e3	. . .
	ld de,049d3h		;4d52	11 d3 49	. . I
	push bc			;4d55	c5		.
	push de			;4d56	d5		.
	exx			;4d57	d9		.
	rst 28h			;4d58	ef		.
l4d59h:
	pop af			;4d59	f1		.
	ret			;4d5a	c9		.
l4d5bh:
	call sub_5143h		;4d5b	cd 43 51	. C Q
	ld bc,00000h		;4d5e	01 00 00	. . .
	ex de,hl		;4d61	eb		.
	ld hl,0436ah		;4d62	21 6a 43	! j C
	bit 6,(hl)		;4d65	cb 76		. v
	set 6,(hl)		;4d67	cb f6		. .
	jr z,l4d6fh		;4d69	28 04		( .
	ld bc,(0439dh)		;4d6b	ed 4b 9d 43	. K . C
l4d6fh:
	push bc			;4d6f	c5		.
	ld (0439dh),sp		;4d70	ed 73 9d 43	. s . C
	ex de,hl		;4d74	eb		.
	jp l4e35h		;4d75	c3 35 4e	. 5 N
l4d78h:
	pop af			;4d78	f1		.
	pop af			;4d79	f1		.
	jr l4d8bh		;4d7a	18 0f		. .
l4d7ch:
	xor a			;4d7c	af		.
	scf			;4d7d	37		7
	jr l4d8bh		;4d7e	18 0b		. .
l4d80h:
	ld hl,0436ah		;4d80	21 6a 43	! j C
	ld a,(hl)		;4d83	7e		~
	and 02fh		;4d84	e6 2f		. /
	ld (hl),a		;4d86	77		w
	dec hl			;4d87	2b		+
	res 5,(hl)		;4d88	cb ae		. .
l4d8ah:
	xor a			;4d8a	af		.
l4d8bh:
	di			;4d8b	f3		.
	ld hl,0436bh		;4d8c	21 6b 43	! k C
	ld (hl),000h		;4d8f	36 00		6 .
	dec hl			;4d91	2b		+
	ld b,(hl)		;4d92	46		F
	dec hl			;4d93	2b		+
	ld c,(hl)		;4d94	4e		N
	ld e,00bh		;4d95	1e 0b		. .
	push af			;4d97	f5		.
	bit 2,b			;4d98	cb 50		. P
	jr nz,l4dbfh		;4d9a	20 23		  #
	pop af			;4d9c	f1		.
	push af			;4d9d	f5		.
	jr c,l4da2h		;4d9e	38 02		8 .
	jr z,l4dach		;4da0	28 0a		( .
l4da2h:
	cp 038h			;4da2	fe 38		. 8
	jr z,l4dach		;4da4	28 06		( .
	ld e,004h		;4da6	1e 04		. .
	bit 5,c			;4da8	cb 69		. i
	jr nz,l4dbfh		;4daa	20 13		  .
l4dach:
	res 6,(hl)		;4dac	cb b6		. .
	bit 6,b			;4dae	cb 70		. p
	jr nz,l4e10h		;4db0	20 5e		  ^
	ld a,(0436ch)		;4db2	3a 6c 43	: l C
	bit 6,a			;4db5	cb 77		. w
	jr z,l4dc4h		;4db7	28 0b		( .
	bit 5,c			;4db9	cb 69		. i
	jr nz,l4dc4h		;4dbb	20 07		  .
	ld e,00ch		;4dbd	1e 0c		. .
l4dbfh:
	ld d,0ebh		;4dbf	16 eb		. .
	ld a,d			;4dc1	7a		z
	ld c,e			;4dc2	4b		K
	rst 28h			;4dc3	ef		.
l4dc4h:
	bit 7,b			;4dc4	cb 78		. x
	jr nz,l4ddch		;4dc6	20 14		  .
	ld sp,041e0h		;4dc8	31 e0 41	1 . A
	bit 5,a			;4dcb	cb 6f		. o
	ld hl,045b0h		;4dcd	21 b0 45	! . E
	ld (04313h),hl		;4dd0	22 13 43	" . C
	ld a,0c3h		;4dd3	3e c3		> .
	jr z,l4dd9h		;4dd5	28 02		( .
	ld a,0c9h		;4dd7	3e c9		> .
l4dd9h:
	ld (04312h),a		;4dd9	32 12 43	2 . C
l4ddch:
	ld hl,l51cdh		;4ddc	21 cd 51	! . Q
	bit 7,b			;4ddf	cb 78		. x
	jr z,l4deah		;4de1	28 07		( .
	ld sp,(0439bh)		;4de3	ed 7b 9b 43	. { . C
	ld hl,l51c8h		;4de7	21 c8 51	! . Q
l4deah:
	ei			;4dea	fb		.
	ld a,00bh		;4deb	3e 0b		> .
	call 00033h		;4ded	cd 33 00	. 3 .
	bit 5,c			;4df0	cb 69		. i
	call z,04467h		;4df2	cc 67 44	. g D
	ld hl,0436ah		;4df5	21 6a 43	! j C
	set 5,(hl)		;4df8	cb ee		. .
	ld bc,0e308h		;4dfa	01 08 e3	. . .
	ld de,049d6h		;4dfd	11 d6 49	. . I
	push bc			;4e00	c5		.
	push de			;4e01	d5		.
	ld hl,(04318h)		;4e02	2a 18 43	* . C
	ld (043a7h),hl		;4e05	22 a7 43	" . C
	ld b,04fh		;4e08	06 4f		. O
	ld hl,04318h		;4e0a	21 18 43	! . C
	jp 00040h		;4e0d	c3 40 00	. @ .
l4e10h:
	pop de			;4e10	d1		.
	ld sp,(0439dh)		;4e11	ed 7b 9d 43	. { . C
	bit 5,c			;4e15	cb 69		. i
	jr z,l4e1dh		;4e17	28 04		( .
	bit 4,b			;4e19	cb 60		. `
	jr nz,l4ddch		;4e1b	20 bf		  .
l4e1dh:
	pop bc			;4e1d	c1		.
	ld a,b			;4e1e	78		x
	or c			;4e1f	b1		.
	jr nz,l4e25h		;4e20	20 03		  .
	inc hl			;4e22	23		#
	res 6,(hl)		;4e23	cb b6		. .
l4e25h:
	res 4,(hl)		;4e25	cb a6		. .
	ld (0439dh),bc		;4e27	ed 43 9d 43	. C . C
	push de			;4e2b	d5		.
	pop af			;4e2c	f1		.
	jp l5133h		;4e2d	c3 33 51	. 3 Q
l4e30h:
	ld sp,041e0h		;4e30	31 e0 41	1 . A
	push af			;4e33	f5		.
l4e34h:
	pop af			;4e34	f1		.
l4e35h:
	ld bc,0402dh		;4e35	01 2d 40	. - @
	ld de,04408h		;4e38	11 08 44	. . D
	push bc			;4e3b	c5		.
	push de			;4e3c	d5		.
	ex de,hl		;4e3d	eb		.
	ld hl,0436ah		;4e3e	21 6a 43	! j C
	res 5,(hl)		;4e41	cb ae		. .
	ld hl,04318h		;4e43	21 18 43	! . C
	ld b,050h		;4e46	06 50		. P
	ld a,(hl)		;4e48	7e		~
	cp 00dh			;4e49	fe 0d		. .
	ret z			;4e4b	c8		.
	push hl			;4e4c	e5		.
l4e4dh:
	ld a,(de)		;4e4d	1a		.
	inc de			;4e4e	13		.
	call 045b5h		;4e4f	cd b5 45	. . E
	cp 00dh			;4e52	fe 0d		. .
	ld (hl),a		;4e54	77		w
	inc hl			;4e55	23		#
	jr z,l4e5fh		;4e56	28 07		( .
	djnz l4e4dh		;4e58	10 f3		. .
	pop af			;4e5a	f1		.
	ld a,036h		;4e5b	3e 36		> 6
	or a			;4e5d	b7		.
	ret			;4e5e	c9		.
l4e5fh:
	ld a,(0436dh)		;4e5f	3a 6d 43	: m C
	bit 5,a			;4e62	cb 6f		. o
	jr z,l4e75h		;4e64	28 0f		( .
	ld hl,(04318h)		;4e66	2a 18 43	* . C
	ld de,00d52h		;4e69	11 52 0d	. R .
	rst 18h			;4e6c	df		.
	jr nz,l4e75h		;4e6d	20 06		  .
	ld hl,(043a7h)		;4e6f	2a a7 43	* . C
	ld (04318h),hl		;4e72	22 18 43	" . C
l4e75h:
	pop hl			;4e75	e1		.
	ld de,l4f58h		;4e76	11 58 4f	. X O
l4e79h:
	push hl			;4e79	e5		.
l4e7ah:
	ld a,(de)		;4e7a	1a		.
	cp (hl)			;4e7b	be		.
	inc de			;4e7c	13		.
	inc hl			;4e7d	23		#
	jr z,l4e7ah		;4e7e	28 fa		( .
	dec hl			;4e80	2b		+
	dec de			;4e81	1b		.
	rlca			;4e82	07		.
	jr nc,l4e8ah		;4e83	30 05		0 .
	call 04cd5h		;4e85	cd d5 4c	. . L
	jr nc,l4ea7h		;4e88	30 1d		0 .
l4e8ah:
	pop hl			;4e8a	e1		.
l4e8bh:
	ld a,(de)		;4e8b	1a		.
	rlca			;4e8c	07		.
	inc de			;4e8d	13		.
	jr nc,l4e8bh		;4e8e	30 fb		0 .
	inc de			;4e90	13		.
	inc de			;4e91	13		.
	ld a,(de)		;4e92	1a		.
	or a			;4e93	b7		.
	jr nz,l4e79h		;4e94	20 e3		  .
	ld bc,0e443h		;4e96	01 43 e4	. C .
	ld d,041h		;4e99	16 41		. A
	ld a,(hl)		;4e9b	7e		~
	cp 02ah			;4e9c	fe 2a		. *
	jr nz,l4eb0h		;4e9e	20 10		  .
	ld a,0ebh		;4ea0	3e eb		> .
	ld c,007h		;4ea2	0e 07		. .
	rst 28h			;4ea4	ef		.
l4ea5h:
	pop bc			;4ea5	c1		.
	ret			;4ea6	c9		.
l4ea7h:
	pop bc			;4ea7	c1		.
	ld a,(de)		;4ea8	1a		.
	ld c,a			;4ea9	4f		O
	inc de			;4eaa	13		.
	ld a,(de)		;4eab	1a		.
	ld b,a			;4eac	47		G
	inc de			;4ead	13		.
	ld a,(de)		;4eae	1a		.
	ld d,a			;4eaf	57		W
l4eb0h:
	bit 6,c			;4eb0	cb 71		. q
	jr z,l4ec3h		;4eb2	28 0f		( .
	ld a,(0436ah)		;4eb4	3a 6a 43	: j C
	rlca			;4eb7	07		.
	jr nc,l4ec3h		;4eb8	30 09		0 .
	and 080h		;4eba	e6 80		. .
	ld a,038h		;4ebc	3e 38		> 8
	jp nz,l4d8bh		;4ebe	c2 8b 4d	. . M
	or a			;4ec1	b7		.
	ret			;4ec2	c9		.
l4ec3h:
	ld a,c			;4ec3	79		y
	and 01fh		;4ec4	e6 1f		. .
	ld c,a			;4ec6	4f		O
	push bc			;4ec7	c5		.
	ld c,d			;4ec8	4a		J
	ld a,c			;4ec9	79		y
	and 0c0h		;4eca	e6 c0		. .
	call nz,sub_5165h	;4ecc	c4 65 51	. e Q
	jr nz,l4ef1h		;4ecf	20 20		   
	bit 5,c			;4ed1	cb 69		. i
	jr z,l4ef5h		;4ed3	28 20		(  
	call 04cd9h		;4ed5	cd d9 4c	. . L
	jr c,l4ea5h		;4ed8	38 cb		8 .
	push bc			;4eda	c5		.
	ld bc,l51c5h		;4edb	01 c5 51	. . Q
	call 04cc5h		;4ede	cd c5 4c	. . L
	pop bc			;4ee1	c1		.
	jr nz,l4ee9h		;4ee2	20 05		  .
	call 04cd9h		;4ee4	cd d9 4c	. . L
	jr c,l4ea5h		;4ee7	38 bc		8 .
l4ee9h:
	push de			;4ee9	d5		.
	ld de,051e0h		;4eea	11 e0 51	. . Q
	call l5168h		;4eed	cd 68 51	. h Q
	pop de			;4ef0	d1		.
l4ef1h:
	ld a,030h		;4ef1	3e 30		> 0
	jr nz,l4ea5h		;4ef3	20 b0		  .
l4ef5h:
	bit 4,c			;4ef5	cb 61		. a
	call nz,04cd5h		;4ef7	c4 d5 4c	. . L
	jr nz,l4ea5h		;4efa	20 a9		  .
	bit 3,c			;4efc	cb 59		. Y
	jr z,l4f02h		;4efe	28 02		( .
	ex (sp),hl		;4f00	e3		.
	push hl			;4f01	e5		.
l4f02h:
	ld a,c			;4f02	79		y
	and 007h		;4f03	e6 07		. .
	jr z,l4f15h		;4f05	28 0e		( .
	push hl			;4f07	e5		.
	ld hl,l51bch		;4f08	21 bc 51	! . Q
l4f0bh:
	inc hl			;4f0b	23		#
	inc hl			;4f0c	23		#
	inc hl			;4f0d	23		#
	dec a			;4f0e	3d		=
	jr nz,l4f0bh		;4f0f	20 fa		  .
	call l4f2ah		;4f11	cd 2a 4f	. * O
	pop hl			;4f14	e1		.
l4f15h:
	ld a,c			;4f15	79		y
	ld bc,049d3h		;4f16	01 d3 49	. . I
	push bc			;4f19	c5		.
	bit 7,a			;4f1a	cb 7f		. .
	ret z			;4f1c	c8		.
	ld b,000h		;4f1d	06 00		. .
	ld hl,04200h		;4f1f	21 00 42	! . B
	bit 6,a			;4f22	cb 77		. w
	jp z,04424h		;4f24	ca 24 44	. $ D
	jp 04420h		;4f27	c3 20 44	.   D
l4f2ah:
	push de			;4f2a	d5		.
	push bc			;4f2b	c5		.
	ld bc,0091ch		;4f2c	01 1c 09	. . .
l4f2fh:
	ld a,(de)		;4f2f	1a		.
	cp 03ah			;4f30	fe 3a		. :
	jr z,l4f3eh		;4f32	28 0a		( .
	cp 02fh			;4f34	fe 2f		. /
	jr c,l4f3eh		;4f36	38 06		8 .
	jr z,l4f55h		;4f38	28 1b		( .
	dec c			;4f3a	0d		.
	inc de			;4f3b	13		.
	djnz l4f2fh		;4f3c	10 f1		. .
l4f3eh:
	inc hl			;4f3e	23		#
	inc hl			;4f3f	23		#
	push hl			;4f40	e5		.
	ex de,hl		;4f41	eb		.
	ld b,000h		;4f42	06 00		. .
	add hl,bc		;4f44	09		.
	ld d,h			;4f45	54		T
	ld e,l			;4f46	5d		]
	dec hl			;4f47	2b		+
	inc de			;4f48	13		.
	inc de			;4f49	13		.
	inc de			;4f4a	13		.
	lddr			;4f4b	ed b8		. .
	pop hl			;4f4d	e1		.
	ld c,003h		;4f4e	0e 03		. .
	lddr			;4f50	ed b8		. .
	ld a,02fh		;4f52	3e 2f		> /
	ld (de),a		;4f54	12		.
l4f55h:
	pop bc			;4f55	c1		.
	pop de			;4f56	d1		.
	ret			;4f57	c9		.
l4f58h:
	ld b,c			;4f58	41		A
	ld c,c			;4f59	49		I
	ld c,e			;4f5a	4b		K
	add a,b			;4f5b	80		.
	ld d,e			;4f5c	53		S
	nop			;4f5d	00		.
	ld b,c			;4f5e	41		A
	ld d,b			;4f5f	50		P
	ld d,b			;4f60	50		P
	ld b,l			;4f61	45		E
	ld c,(hl)		;4f62	4e		N
	ld b,h			;4f63	44		D
	ret nz			;4f64	c0		.
	ld l,b			;4f65	68		h
	nop			;4f66	00		.
	ld b,c			;4f67	41		A
	ld d,h			;4f68	54		T
	ld d,h			;4f69	54		T
	ld d,d			;4f6a	52		R
	ld c,c			;4f6b	49		I
	ld b,d			;4f6c	42		B
	add a,l			;4f6d	85		.
	jp (hl)			;4f6e	e9		.
	adc a,b			;4f6f	88		.
	ld b,c			;4f70	41		A
	ld d,l			;4f71	55		U
	ld d,h			;4f72	54		T
	ld c,a			;4f73	4f		O
	add a,h			;4f74	84		.
	jp (hl)			;4f75	e9		.
	nop			;4f76	00		.
	ld b,d			;4f77	42		B
	ld (0eb86h),a		;4f78	32 86 eb	2 . .
	nop			;4f7b	00		.
	ld b,d			;4f7c	42		B
	ld c,h			;4f7d	4c		L
	add a,c			;4f7e	81		.
	push hl			;4f7f	e5		.
	nop			;4f80	00		.
	ld b,d			;4f81	42		B
	ld c,a			;4f82	4f		O
	ld c,a			;4f83	4f		O
	ld d,h			;4f84	54		T
	adc a,d			;4f85	8a		.
	ex de,hl		;4f86	eb		.
	djnz $+68		;4f87	10 42		. B
	ld d,d			;4f89	52		R
	ld b,l			;4f8a	45		E
	ld b,c			;4f8b	41		A
	ld c,e			;4f8c	4b		K
	add a,l			;4f8d	85		.
	push hl			;4f8e	e5		.
	nop			;4f8f	00		.
	ld b,e			;4f90	43		C
	ld c,h			;4f91	4c		L
	ld d,e			;4f92	53		S
	adc a,c			;4f93	89		.
	ex (sp),hl		;4f94	e3		.
	djnz l4fdah		;4f95	10 43		. C
	ld c,a			;4f97	4f		O
	ld c,(hl)		;4f98	4e		N
	ld d,h			;4f99	54		T
	push bc			;4f9a	c5		.
	ex de,hl		;4f9b	eb		.
	nop			;4f9c	00		.
	ld b,e			;4f9d	43		C
	ld c,a			;4f9e	4f		O
	ld d,b			;4f9f	50		P
	ld e,c			;4fa0	59		Y
	ret nz			;4fa1	c0		.
	ld c,b			;4fa2	48		H
	nop			;4fa3	00		.
	ld b,e			;4fa4	43		C
	ld d,d			;4fa5	52		R
	ld b,l			;4fa6	45		E
	ld b,c			;4fa7	41		A
	ld d,h			;4fa8	54		T
	ld b,l			;4fa9	45		E
	add a,d			;4faa	82		.
	ret p			;4fab	f0		.
	ld b,b			;4fac	40		@
	ld b,h			;4fad	44		D
	ld b,c			;4fae	41		A
	ld d,h			;4faf	54		T
	ld d,l			;4fb0	55		U
	ld c,l			;4fb1	4d		M
	adc a,e			;4fb2	8b		.
	jp (hl)			;4fb3	e9		.
	nop			;4fb4	00		.
	ld b,h			;4fb5	44		D
	ld b,h			;4fb6	44		D
	ld b,l			;4fb7	45		E
	add a,c			;4fb8	81		.
	pop af			;4fb9	f1		.
	nop			;4fba	00		.
	ld b,h			;4fbb	44		D
	ld c,c			;4fbc	49		I
	ld d,d			;4fbd	52		R
	add a,b			;4fbe	80		.
	ld hl,(04400h)		;4fbf	2a 00 44	* . D
	ld c,c			;4fc2	49		I
	ld d,e			;4fc3	53		S
	ld c,e			;4fc4	4b		K
	add a,e			;4fc5	83		.
	rst 38h			;4fc6	ff		.
	nop			;4fc7	00		.
	ld b,h			;4fc8	44		D
	ld c,a			;4fc9	4f		O
	jp 08aebh		;4fca	c3 eb 8a	. . .
	ld b,h			;4fcd	44		D
	ld d,d			;4fce	52		R
	add a,d			;4fcf	82		.
	cp 000h			;4fd0	fe 00		. .
	ld b,h			;4fd2	44		D
	ld d,l			;4fd3	55		U
	ld c,l			;4fd4	4d		M
	ld d,b			;4fd5	50		P
	add a,a			;4fd6	87		.
	jp (hl)			;4fd7	e9		.
	ret z			;4fd8	c8		.
	ld b,l			;4fd9	45		E
l4fdah:
	add a,a			;4fda	87		.
	ret p			;4fdb	f0		.
	nop			;4fdc	00		.
	ld b,(hl)		;4fdd	46		F
	ld c,a			;4fde	4f		O
	ld d,d			;4fdf	52		R
	ld c,l			;4fe0	4d		M
	adc a,b			;4fe1	88		.
	cp 000h			;4fe2	fe 00		. .
	ld b,(hl)		;4fe4	46		F
	ld d,d			;4fe5	52		R
	ld b,l			;4fe6	45		E
	ld b,l			;4fe7	45		E
	add a,b			;4fe8	80		.
	ld c,d			;4fe9	4a		J
	nop			;4fea	00		.
	ld b,(hl)		;4feb	46		F
	inc hl			;4fec	23		#
	add a,b			;4fed	80		.
	ei			;4fee	fb		.
	nop			;4fef	00		.
	ld c,b			;4ff0	48		H
	ld c,c			;4ff1	49		I
	ld c,l			;4ff2	4d		M
	ld b,l			;4ff3	45		E
	ld c,l			;4ff4	4d		M
	add a,d			;4ff5	82		.
	jp (hl)			;4ff6	e9		.
	nop			;4ff7	00		.
	ld c,c			;4ff8	49		I
	add a,b			;4ff9	80		.
	ld hl,(04900h)		;4ffa	2a 00 49	* . I
	ld c,(hl)		;4ffd	4e		N
	ld b,(hl)		;4ffe	46		F
	ld c,a			;4fff	4f		O
	add a,c			;5000	81		.
	rst 38h			;5001	ff		.
	nop			;5002	00		.
	ld c,d			;5003	4a		J
	ld c,e			;5004	4b		K
	ld c,h			;5005	4c		L
	add a,b			;5006	80		.
	ld a,h			;5007	7c		|
	djnz l5055h		;5008	10 4b		. K
	ld c,c			;500a	49		I
	ld c,h			;500b	4c		L
	ld c,h			;500c	4c		L
	add a,b			;500d	80		.
	ld b,l			;500e	45		E
	sub b			;500f	90		.
	ld c,h			;5010	4c		L
	ld b,e			;5011	43		C
	adc a,b			;5012	88		.
	push hl			;5013	e5		.
	nop			;5014	00		.
	ld c,h			;5015	4c		L
	ld b,(hl)		;5016	46		F
	add a,c			;5017	81		.
	cp 000h			;5018	fe 00		. .
	ld c,h			;501a	4c		L
	ld c,c			;501b	49		I
	ld b,d			;501c	42		B
	add a,d			;501d	82		.
	ex (sp),hl		;501e	e3		.
	nop			;501f	00		.
	ld c,h			;5020	4c		L
	ld c,c			;5021	49		I
	ld d,e			;5022	53		S
	ld d,h			;5023	54		T
l5024h:
	add a,l			;5024	85		.
	ret p			;5025	f0		.
	adc a,b			;5026	88		.
	ld c,h			;5027	4c		L
	ld c,a			;5028	4f		O
	ld b,c			;5029	41		A
	ld b,h			;502a	44		D
	add a,b			;502b	80		.
	and h			;502c	a4		.
	ld d,b			;502d	50		P
	ld c,l			;502e	4d		M
	ld a,082h		;502f	3e 82		> .
	ex de,hl		;5031	eb		.
	or b			;5032	b0		.
	ld c,(hl)		;5033	4e		N
	add a,c			;5034	81		.
	call po,l4eb0h		;5035	e4 b0 4e	. . N
	ld b,h			;5038	44		D
	ld b,(hl)		;5039	46		F
	ret nz			;503a	c0		.
	jr z,l503dh		;503b	28 00		( .
l503dh:
	ld d,b			;503d	50		P
	ld b,c			;503e	41		A
	ld d,l			;503f	55		U
	ld d,e			;5040	53		S
	ld b,l			;5041	45		E
	adc a,b			;5042	88		.
	ex de,hl		;5043	eb		.
	nop			;5044	00		.
	ld d,b			;5045	50		P
	ld b,h			;5046	44		D
	add a,e			;5047	83		.
	jp (hl)			;5048	e9		.
	nop			;5049	00		.
	ld d,b			;504a	50		P
	ld c,c			;504b	49		I
	ld c,a			;504c	4f		O
	add a,b			;504d	80		.
	sbc a,h			;504e	9c		.
	nop			;504f	00		.
	ld d,b			;5050	50		P
	ld c,a			;5051	4f		O
	ld d,d			;5052	52		R
	ld d,h			;5053	54		T
	add a,d			;5054	82		.
l5055h:
	rst 38h			;5055	ff		.
	nop			;5056	00		.
	ld d,b			;5057	50		P
	ld d,d			;5058	52		R
	ld c,c			;5059	49		I
	ld c,(hl)		;505a	4e		N
	ld d,h			;505b	54		T
	add a,(hl)		;505c	86		.
	ret p			;505d	f0		.
	adc a,b			;505e	88		.
	ld d,b			;505f	50		P
	ld d,d			;5060	52		R
	ld c,a			;5061	4f		O
	ld d,h			;5062	54		T
	add a,(hl)		;5063	86		.
	jp (hl)			;5064	e9		.
	nop			;5065	00		.
	ld d,b			;5066	50		P
	ld d,l			;5067	55		U
	ld d,d			;5068	52		R
	ld b,a			;5069	47		G
	ld b,l			;506a	45		E
	adc a,c			;506b	89		.
	jp (hl)			;506c	e9		.
	nop			;506d	00		.
	ld d,d			;506e	52		R
	add a,b			;506f	80		.
	inc hl			;5070	23		#
	nop			;5071	00		.
	ld d,e			;5072	53		S
	add a,c			;5073	81		.
	jp (hl)			;5074	e9		.
	nop			;5075	00		.
	ld d,e			;5076	53		S
	ld c,c			;5077	49		I
	ld c,a			;5078	4f		O
	add a,b			;5079	80		.
	cp h			;507a	bc		.
	nop			;507b	00		.
	ld d,e			;507c	53		S
	ld d,h			;507d	54		T
	ld c,l			;507e	4d		M
	ld d,h			;507f	54		T
	adc a,c			;5080	89		.
	ex de,hl		;5081	eb		.
	nop			;5082	00		.
	ld d,l			;5083	55		U
	ld c,b			;5084	48		H
	ld d,d			;5085	52		R
	add a,d			;5086	82		.
	push hl			;5087	e5		.
	nop			;5088	00		.
	ld d,(hl)		;5089	56		V
	dec hl			;508a	2b		+
	add a,h			;508b	84		.
	push hl			;508c	e5		.
	nop			;508d	00		.
	ld e,d			;508e	5a		Z
	add a,c			;508f	81		.
	ret m			;5090	f8		.
	nop			;5091	00		.
	ld e,d			;5092	5a		Z
	ld b,l			;5093	45		E
	ld c,c			;5094	49		I
	ld d,h			;5095	54		T
	adc a,d			;5096	8a		.
	jp (hl)			;5097	e9		.
	nop			;5098	00		.
	ld e,d			;5099	5a		Z
	ld c,h			;509a	4c		L
	add a,d			;509b	82		.
	ret m			;509c	f8		.
	adc a,b			;509d	88		.
	jr nc,l5024h		;509e	30 84		0 .
	ret p			;50a0	f0		.
	nop			;50a1	00		.
	ld (hl),034h		;50a2	36 34		6 4
	add a,c			;50a4	81		.
	sbc a,b			;50a5	98		.
	nop			;50a6	00		.
	jr c,l50d9h		;50a7	38 30		8 0
	add a,d			;50a9	82		.
	sbc a,b			;50aa	98		.
	nop			;50ab	00		.
	ld hl,0eb83h		;50ac	21 83 eb	! . .
	adc a,d			;50af	8a		.
	inc hl			;50b0	23		#
	inc hl			;50b1	23		#
	add a,e			;50b2	83		.
	sbc a,b			;50b3	98		.
	nop			;50b4	00		.
	ld h,083h		;50b5	26 83		& .
	push hl			;50b7	e5		.
	nop			;50b8	00		.
	ld b,b			;50b9	40		@
	add a,c			;50ba	81		.
	ret p			;50bb	f0		.
	nop			;50bc	00		.
	dec sp			;50bd	3b		;
	add a,(hl)		;50be	86		.
	ex (sp),hl		;50bf	e3		.
	nop			;50c0	00		.
	cpl			;50c1	2f		/
	add a,l			;50c2	85		.
	ex (sp),hl		;50c3	e3		.
	nop			;50c4	00		.
	ld a,0c0h		;50c5	3e c0		> .
	ld c,b			;50c7	48		H
	nop			;50c8	00		.
	ccf			;50c9	3f		?
	add a,d			;50ca	82		.
	ex (sp),hl		;50cb	e3		.
	nop			;50cc	00		.
	nop			;50cd	00		.
	nop			;50ce	00		.
l50cfh:
	ld hl,l4f58h		;50cf	21 58 4f	! X O
l50d2h:
	ld c,040h		;50d2	0e 40		. @
l50d4h:
	ld b,008h		;50d4	06 08		. .
l50d6h:
	ld a,(hl)		;50d6	7e		~
	bit 7,a			;50d7	cb 7f		. .
l50d9h:
	inc hl			;50d9	23		#
	jr nz,l50e1h		;50da	20 05		  .
	call sub_51b7h		;50dc	cd b7 51	. . Q
	djnz l50d6h		;50df	10 f5		. .
l50e1h:
	inc hl			;50e1	23		#
	inc hl			;50e2	23		#
	ld a,(hl)		;50e3	7e		~
	or a			;50e4	b7		.
	jp z,l51b5h		;50e5	ca b5 51	. . Q
	dec c			;50e8	0d		.
	call z,l51b5h		;50e9	cc b5 51	. . Q
	jr z,l50d2h		;50ec	28 e4		( .
	call sub_51adh		;50ee	cd ad 51	. . Q
	jr l50d4h		;50f1	18 e1		. .
l50f3h:
	di			;50f3	f3		.
	call sub_5143h		;50f4	cd 43 51	. C Q
	ld hl,0436ah		;50f7	21 6a 43	! j C
	ld a,(hl)		;50fa	7e		~
	and 0c0h		;50fb	e6 c0		. .
	jr nz,l5132h		;50fd	20 33		  3
	ld a,(04022h)		;50ff	3a 22 40	: " @
	push af			;5102	f5		.
	ld (0439bh),sp		;5103	ed 73 9b 43	. s . C
	set 7,(hl)		;5107	cb fe		. .
	ei			;5109	fb		.
	ld a,00bh		;510a	3e 0b		> .
	call 00033h		;510c	cd 33 00	. 3 .
	jp l4d8ah		;510f	c3 8a 4d	. . M
l5112h:
	ld hl,0436ah		;5112	21 6a 43	! j C
	bit 7,(hl)		;5115	cb 7e		. ~
	jp z,l4d44h		;5117	ca 44 4d	. D M
	ld sp,(0439bh)		;511a	ed 7b 9b 43	. { . C
	ld a,00eh		;511e	3e 0e		> .
	call 00033h		;5120	cd 33 00	. 3 .
	pop af			;5123	f1		.
	or a			;5124	b7		.
	ld b,a			;5125	47		G
	ld a,00fh		;5126	3e 0f		> .
	call z,00033h		;5128	cc 33 00	. 3 .
	ld a,b			;512b	78		x
	ld (04022h),a		;512c	32 22 40	2 " @
	di			;512f	f3		.
	res 7,(hl)		;5130	cb be		. .
l5132h:
	xor a			;5132	af		.
l5133h:
	ex af,af'		;5133	08		.
	pop iy			;5134	fd e1		. .
	pop ix			;5136	dd e1		. .
	pop af			;5138	f1		.
	pop bc			;5139	c1		.
	pop de			;513a	d1		.
	pop hl			;513b	e1		.
	exx			;513c	d9		.
	pop bc			;513d	c1		.
	pop de			;513e	d1		.
	pop hl			;513f	e1		.
	ex af,af'		;5140	08		.
	ei			;5141	fb		.
	ret			;5142	c9		.
sub_5143h:
	pop af			;5143	f1		.
	push hl			;5144	e5		.
	push de			;5145	d5		.
	push bc			;5146	c5		.
	ex af,af'		;5147	08		.
	exx			;5148	d9		.
	push hl			;5149	e5		.
	push de			;514a	d5		.
	push bc			;514b	c5		.
	push af			;514c	f5		.
	push ix			;514d	dd e5		. .
	push iy			;514f	fd e5		. .
	exx			;5151	d9		.
	ex af,af'		;5152	08		.
	push af			;5153	f5		.
	ret			;5154	c9		.
l5155h:
	call l5168h		;5155	cd 68 51	. h Q
	push af			;5158	f5		.
	ld a,(hl)		;5159	7e		~
	sub 003h		;515a	d6 03		. .
	jr z,l5160h		;515c	28 02		( .
	sub 00ah		;515e	d6 0a		. .
l5160h:
	jr z,l5163h		;5160	28 01		( .
	inc hl			;5162	23		#
l5163h:
	pop af			;5163	f1		.
	ret			;5164	c9		.
sub_5165h:
	ld de,04480h		;5165	11 80 44	. . D
l5168h:
	push de			;5168	d5		.
	ld b,020h		;5169	06 20		.  
	call sub_5172h		;516b	cd 72 51	. r Q
	pop de			;516e	d1		.
	ld b,000h		;516f	06 00		. .
	ret			;5171	c9		.
sub_5172h:
	ld a,(hl)		;5172	7e		~
	cp 02ah			;5173	fe 2a		. *
	jr nz,l517bh		;5175	20 04		  .
	ld (de),a		;5177	12		.
	inc de			;5178	13		.
	inc hl			;5179	23		#
	dec b			;517a	05		.
l517bh:
	push hl			;517b	e5		.
	ld a,(hl)		;517c	7e		~
	sub 030h		;517d	d6 30		. 0
	cp 00ah			;517f	fe 0a		. .
	call sub_51a1h		;5181	cd a1 51	. . Q
	jr nc,l519ch		;5184	30 16		0 .
l5186h:
	ld a,(hl)		;5186	7e		~
	sub 02eh		;5187	d6 2e		. .
	cp 00dh			;5189	fe 0d		. .
	call sub_51a1h		;518b	cd a1 51	. . Q
	jr c,l5196h		;518e	38 06		8 .
	ld a,003h		;5190	3e 03		> .
	ld (de),a		;5192	12		.
	pop af			;5193	f1		.
	xor a			;5194	af		.
	ret			;5195	c9		.
l5196h:
	ld a,(hl)		;5196	7e		~
	ld (de),a		;5197	12		.
	inc de			;5198	13		.
	inc hl			;5199	23		#
	djnz l5186h		;519a	10 ea		. .
l519ch:
	or 001h			;519c	f6 01		. .
	pop hl			;519e	e1		.
	ld a,(hl)		;519f	7e		~
	ret			;51a0	c9		.
sub_51a1h:
	ret c			;51a1	d8		.
	ld a,(hl)		;51a2	7e		~
	sub 041h		;51a3	d6 41		. A
	cp 01fh			;51a5	fe 1f		. .
	ret c			;51a7	d8		.
	sub 020h		;51a8	d6 20		.  
	cp 01fh			;51aa	fe 1f		. .
	ret			;51ac	c9		.
sub_51adh:
	ld a,020h		;51ad	3e 20		>  
	call sub_51b7h		;51af	cd b7 51	. . Q
	djnz sub_51adh		;51b2	10 f9		. .
	ret			;51b4	c9		.
l51b5h:
	ld a,00bh		;51b5	3e 0b		> .
sub_51b7h:
	push de			;51b7	d5		.
	push af			;51b8	f5		.
	call 00033h		;51b9	cd 33 00	. 3 .
l51bch:
	pop af			;51bc	f1		.
	pop de			;51bd	d1		.
	ret			;51be	c9		.
	ld b,e			;51bf	43		C
	ld c,l			;51c0	4d		M
	ld b,h			;51c1	44		D
	ld c,d			;51c2	4a		J
	ld c,a			;51c3	4f		O
	ld b,d			;51c4	42		B
l51c5h:
	ld d,h			;51c5	54		T
	ld c,a			;51c6	4f		O
	nop			;51c7	00		.
l51c8h:
	ld c,l			;51c8	4d		M
	ld l,c			;51c9	69		i
	ld l,(hl)		;51ca	6e		n
	ld l,c			;51cb	69		i
	dec l			;51cc	2d		-
l51cdh:
	ld b,d			;51cd	42		B
	ld h,l			;51ce	65		e
	ld h,(hl)		;51cf	66		f
	ld h,l			;51d0	65		e
	ld l,b			;51d1	68		h
	ld l,h			;51d2	6c		l
	ld (hl),e		;51d3	73		s
	ld h,l			;51d4	65		e
	ld l,c			;51d5	69		i
	ld l,(hl)		;51d6	6e		n
	ld h,a			;51d7	67		g
	ld h,c			;51d8	61		a
	ld h,d			;51d9	62		b
	ld h,l			;51da	65		e
	ld e,00dh		;51db	1e 0d		. .
l51ddh:
	inc e			;51dd	1c		.
	rra			;51de	1f		.
	inc bc			;51df	03		.
