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
; /src/GDOS-2.4-SYS-files/sys2-sys-disassembly.asm
; SYS2/SYS, stock GDOS 2.4
;
; Start 4D00h, RAM range 4D00h-51ACh -- confirmed two independent ways:
; (1) this file's own load records (tools/trsload.py --map against
; DMK/G3S-GDOS24.DMK's SYS2/SYS), perfectly contiguous, no gaps;
; (2) matches src/G3S-GDOS24-Extract/SYS-Files-RAM-RANGES.md exactly
; (Grosser ch.7: "SYS2/SYS -- EOF 4/197, RAM 4D00-51AC, Start 4D00").
;
;
; z80dasm 1.2.0
; command line: z80dasm -g 0x4d00 -l -a -t -o sys2-sys-disassembly.asm sys2sys_flat.bin
;
; Not yet cross-checked against Grosser (his book has no GDOS-specific
; SYS2/SYS listing -- see the Grosser-verification-rule memory) or
; annotated -- this is raw, unedited z80dasm output.

; z80dasm 1.2.0
; command line: z80dasm -g 0x4d00 -l -a -t -o sys2sys_disasm.asm sys2sys_flat.bin

	org 04d00h

	cp 024h			;4d00	fe 24		. $
	jp z,l4e2eh		;4d02	ca 2e 4e	. . N
	cp 044h			;4d05	fe 44		. D
	jp z,l4dbdh		;4d07	ca bd 4d	. . M
	cp 064h			;4d0a	fe 64		. d
	jp z,l4f82h		;4d0c	ca 82 4f	. . O
	cp 084h			;4d0f	fe 84		. .
	jp z,l5155h		;4d11	ca 55 51	. U Q
	cp 0a4h			;4d14	fe a4		. .
	jr z,l4d92h		;4d16	28 7a		( z
	cp 0c4h			;4d18	fe c4		. .
	jr z,l4d80h		;4d1a	28 64		( d
	cp 0e4h			;4d1c	fe e4		. .
	jr nz,l4d2eh		;4d1e	20 0e		  .
	dec c			;4d20	0d		.
	jr z,l4d32h		;4d21	28 0f		( .
	dec c			;4d23	0d		.
	jp z,l50cah		;4d24	ca ca 50	. . P
	dec c			;4d27	0d		.
	jr z,l4d7bh		;4d28	28 51		( Q
	dec c			;4d2a	0d		.
	jp z,l4d72h		;4d2b	ca 72 4d	. r M
l4d2eh:
	ld a,02ah		;4d2e	3e 2a		> *
l4d30h:
	or a			;4d30	b7		.
	ret			;4d31	c9		.
l4d32h:
	push de			;4d32	d5		.
	pop ix			;4d33	dd e1		. .
	inc de			;4d35	13		.
	ld a,(de)		;4d36	1a		.
	and 007h		;4d37	e6 07		. .
	cp 003h			;4d39	fe 03		. .
	ld a,025h		;4d3b	3e 25		> %
	jr nc,l4d30h		;4d3d	30 f1		0 .
	ld hl,l4e75h		;4d3f	21 75 4e	! u N
	ld (hl),03eh		;4d42	36 3e		6 >
	ld de,051e0h		;4d44	11 e0 51	. . Q
	call sub_4e2ch		;4d47	cd 2c 4e	. , N
	ld (hl),018h		;4d4a	36 18		6 .
	jr z,l4d77h		;4d4c	28 29		( )
	cp 018h			;4d4e	fe 18		. .
	call z,0494bh		;4d50	cc 4b 49	. K I
	ret nz			;4d53	c0		.
	ld a,l			;4d54	7d		}
	add a,005h		;4d55	c6 05		. .
	ld l,a			;4d57	6f		o
	ex de,hl		;4d58	eb		.
	ld hl,051cdh		;4d59	21 cd 51	! . Q
	ld bc,0000bh		;4d5c	01 0b 00	. . .
	ldir			;4d5f	ed b0		. .
	call 0491fh		;4d61	cd 1f 49	. . I
	ld a,001h		;4d64	3e 01		> .
	call z,0490ah		;4d66	cc 0a 49	. . I
	ret nz			;4d69	c0		.
	ld l,(ix+007h)		;4d6a	dd 6e 07	. n .
	ld (hl),000h		;4d6d	36 00		6 .
	jp 0491fh		;4d6f	c3 1f 49	. . I
l4d72h:
	call l4dbdh		;4d72	cd bd 4d	. . M
	ret nz			;4d75	c0		.
	ret c			;4d76	d8		.
l4d77h:
	ld a,035h		;4d77	3e 35		> 5
	or a			;4d79	b7		.
	ret			;4d7a	c9		.
l4d7bh:
	call 04cd5h		;4d7b	cd d5 4c	. . L
	ret c			;4d7e	d8		.
	pop af			;4d7f	f1		.
l4d80h:
	ex (sp),hl		;4d80	e3		.
	call l4d92h		;4d81	cd 92 4d	. . M
	jp nz,04409h		;4d84	c2 09 44	. . D
	ex (sp),hl		;4d87	e3		.
	ld a,(04369h)		;4d88	3a 69 43	: i C
	rlca			;4d8b	07		.
	jp c,0440dh		;4d8c	da 0d 44	. . D
	jp 04c20h		;4d8f	c3 20 4c	.   L
l4d92h:
	ld hl,04200h		;4d92	21 00 42	! . B
	call sub_4e2ch		;4d95	cd 2c 4e	. , N
	jr z,l4da0h		;4d98	28 06		( .
	cp 018h			;4d9a	fe 18		. .
	ret nz			;4d9c	c0		.
	add a,007h		;4d9d	c6 07		. .
	ret			;4d9f	c9		.
l4da0h:
	ex de,hl		;4da0	eb		.
	inc hl			;4da1	23		#
	ld a,(hl)		;4da2	7e		~
	push af			;4da3	f5		.
	push hl			;4da4	e5		.
	and 007h		;4da5	e6 07		. .
	ld b,a			;4da7	47		G
	ld a,006h		;4da8	3e 06		> .
	cp b			;4daa	b8		.
	ld a,025h		;4dab	3e 25		> %
	ld (hl),02dh		;4dad	36 2d		6 -
	dec hl			;4daf	2b		+
	call nc,04c28h		;4db0	d4 28 4c	. ( L
	ld (04403h),hl		;4db3	22 03 44	" . D
	ex de,hl		;4db6	eb		.
	pop hl			;4db7	e1		.
	pop bc			;4db8	c1		.
	ld (hl),b		;4db9	70		p
	dec hl			;4dba	2b		+
	ex de,hl		;4dbb	eb		.
	ret			;4dbc	c9		.
l4dbdh:
	call l4e2eh		;4dbd	cd 2e 4e	. . N
	ret z			;4dc0	c8		.
	cp 018h			;4dc1	fe 18		. .
	ret nz			;4dc3	c0		.
	call 04986h		;4dc4	cd 86 49	. . I
	ld bc,(sub_4e09h+1)	;4dc7	ed 4b 0a 4e	. K . N
	ld a,b			;4dcb	78		x
	cp c			;4dcc	b9		.
	jr z,l4dd2h		;4dcd	28 03		( .
	ld a,(043a1h)		;4dcf	3a a1 43	: . C
l4dd2h:
	ld (04e0eh),a		;4dd2	32 0e 4e	2 . N
	call 047ech		;4dd5	cd ec 47	. . G
	jr nz,l4de3h		;4dd8	20 09		  .
	ld hl,04d6eh		;4dda	21 6e 4d	! n M
	ld b,(hl)		;4ddd	46		F
	call sub_50cfh		;4dde	cd cf 50	. . P
	jr z,l4deah		;4de1	28 07		( .
l4de3h:
	ld e,01ah		;4de3	1e 1a		. .
	call sub_4e09h		;4de5	cd 09 4e	. . N
	jr l4dd2h		;4de8	18 e8		. .
l4deah:
	ld (04f56h),a		;4dea	32 56 4f	2 V O
	ld (hl),010h		;4ded	36 10		6 .
	call sub_4e1fh		;4def	cd 1f 4e	. . N
	ld a,(04f5eh)		;4df2	3a 5e 4f	: ^ O
	ld (hl),a		;4df5	77		w
	inc hl			;4df6	23		#
	ex de,hl		;4df7	eb		.
	ld hl,051cdh		;4df8	21 cd 51	! . Q
	ld bc,0000fh		;4dfb	01 0f 00	. . .
	ldir			;4dfe	ed b0		. .
	call 0491fh		;4e00	cd 1f 49	. . I
	ret nz			;4e03	c0		.
	call sub_4f2eh		;4e04	cd 2e 4f	. . O
	scf			;4e07	37		7
	ret			;4e08	c9		.
sub_4e09h:
	ld hl,00000h		;4e09	21 00 00	! . .
	ld d,a			;4e0c	57		W
	ld a,000h		;4e0d	3e 00		> .
	inc a			;4e0f	3c		<
	cp l			;4e10	bd		.
	ret c			;4e11	d8		.
	pop hl			;4e12	e1		.
	jr z,l4e18h		;4e13	28 03		( .
	ld a,d			;4e15	7a		z
	or a			;4e16	b7		.
	ret nz			;4e17	c0		.
l4e18h:
	ld a,e			;4e18	7b		{
	or a			;4e19	b7		.
	ret			;4e1a	c9		.
l4e1bh:
	ld a,020h		;4e1b	3e 20		>  
	or a			;4e1d	b7		.
	ret			;4e1e	c9		.
sub_4e1fh:
	inc hl			;4e1f	23		#
	ld a,(hl)		;4e20	7e		~
	ld (04f46h),a		;4e21	32 46 4f	2 F O
	inc hl			;4e24	23		#
	inc hl			;4e25	23		#
	ld a,(hl)		;4e26	7e		~
	ld (04f58h),a		;4e27	32 58 4f	2 X O
	inc hl			;4e2a	23		#
	ret			;4e2b	c9		.
sub_4e2ch:
	ld b,000h		;4e2c	06 00		. .
l4e2eh:
	call 04986h		;4e2e	cd 86 49	. . I
	ld (04f48h),hl		;4e31	22 48 4f	" H O
	ld a,b			;4e34	78		x
	ld (04f5eh),a		;4e35	32 5e 4f	2 ^ O
	ld hl,051cdh		;4e38	21 cd 51	! . Q
	dec de			;4e3b	1b		.
	xor a			;4e3c	af		.
	call sub_5121h		;4e3d	cd 21 51	. ! Q
	cp 02fh			;4e40	fe 2f		. /
	ld b,003h		;4e42	06 03		. .
	call sub_5123h		;4e44	cd 23 51	. # Q
	cp 02eh			;4e47	fe 2e		. .
	call sub_5121h		;4e49	cd 21 51	. ! Q
	ld b,000h		;4e4c	06 00		. .
	ld c,(iy+01fh)		;4e4e	fd 4e 1f	. N .
	cp 03ah			;4e51	fe 3a		. :
	jr nz,l4e75h		;4e53	20 20		   
	inc de			;4e55	13		.
	ld a,(de)		;4e56	1a		.
	sub 030h		;4e57	d6 30		. 0
	cp 00ah			;4e59	fe 0a		. .
	jr nc,l4e1bh		;4e5b	30 be		0 .
l4e5dh:
	ld c,a			;4e5d	4f		O
	inc de			;4e5e	13		.
	ld a,(de)		;4e5f	1a		.
	sub 030h		;4e60	d6 30		. 0
	cp 00ah			;4e62	fe 0a		. .
	jr nc,l4e74h		;4e64	30 0e		0 .
	ld l,a			;4e66	6f		o
	ld a,c			;4e67	79		y
	ld b,009h		;4e68	06 09		. .
l4e6ah:
	add a,c			;4e6a	81		.
	jr c,l4e1bh		;4e6b	38 ae		8 .
	djnz l4e6ah		;4e6d	10 fb		. .
	add a,l			;4e6f	85		.
	jr nc,l4e5dh		;4e70	30 eb		0 .
	jr l4e1bh		;4e72	18 a7		. .
l4e74h:
	ld b,c			;4e74	41		A
l4e75h:
	jr l4e7fh		;4e75	18 08		. .
	ld a,c			;4e77	79		y
	cp b			;4e78	b8		.
	jr z,l4e1bh		;4e79	28 a0		( .
	ld b,(iy-078h)		;4e7b	fd 46 88	. F .
	ld c,b			;4e7e	48		H
l4e7fh:
	ld (sub_4e09h+1),bc	;4e7f	ed 43 0a 4e	. C . N
	push bc			;4e83	c5		.
	call sub_5152h		;4e84	cd 52 51	. R Q
	ld (051d8h),hl		;4e87	22 d8 51	" . Q
	ld (051dah),hl		;4e8a	22 da 51	" . Q
	ld hl,051cdh		;4e8d	21 cd 51	! . Q
	ld b,00bh		;4e90	06 0b		. .
	xor a			;4e92	af		.
l4e93h:
	xor (hl)		;4e93	ae		.
	inc hl			;4e94	23		#
	rlca			;4e95	07		.
	djnz l4e93h		;4e96	10 fb		. .
	jr nz,l4e9bh		;4e98	20 01		  .
	inc a			;4e9a	3c		<
l4e9bh:
	ld (04d6eh),a		;4e9b	32 6e 4d	2 n M
	pop af			;4e9e	f1		.
l4e9fh:
	ld (04e0eh),a		;4e9f	32 0e 4e	2 . N
	call sub_5188h		;4ea2	cd 88 51	. . Q
	jr z,l4eaeh		;4ea5	28 07		( .
l4ea7h:
	ld e,018h		;4ea7	1e 18		. .
	call sub_4e09h		;4ea9	cd 09 4e	. . N
	jr l4e9fh		;4eac	18 f1		. .
l4eaeh:
	ld de,051adh		;4eae	11 ad 51	. . Q
	ld bc,0001fh		;4eb1	01 1f 00	. . .
l4eb4h:
	ld a,b			;4eb4	78		x
	sub c			;4eb5	91		.
	jr z,l4ea7h		;4eb6	28 ef		( .
	ld a,001h		;4eb8	3e 01		> .
	call 0490ah		;4eba	cd 0a 49	. . I
	ret nz			;4ebd	c0		.
	ld a,b			;4ebe	78		x
l4ebfh:
	ld b,a			;4ebf	47		G
	ld (de),a		;4ec0	12		.
	ld l,a			;4ec1	6f		o
	ld a,e			;4ec2	7b		{
	cp 0cch			;4ec3	fe cc		. .
	jr z,l4eddh		;4ec5	28 16		( .
	ld a,(04d6eh)		;4ec7	3a 6e 4d	: n M
	cp (hl)			;4eca	be		.
	jr nz,l4eceh		;4ecb	20 01		  .
	inc de			;4ecd	13		.
l4eceh:
	ld a,b			;4ece	78		x
	add a,020h		;4ecf	c6 20		.  
	jr nc,l4ebfh		;4ed1	30 ec		0 .
	inc a			;4ed3	3c		<
	cp c			;4ed4	b9		.
	ld b,a			;4ed5	47		G
	jr c,l4ebfh		;4ed6	38 e7		8 .
l4ed8h:
	ld a,e			;4ed8	7b		{
	cp 0adh			;4ed9	fe ad		. .
	jr z,l4eb4h		;4edb	28 d7		( .
l4eddh:
	dec de			;4edd	1b		.
	ld a,(de)		;4ede	1a		.
	ld (04f56h),a		;4edf	32 56 4f	2 V O
	call 0492fh		;4ee2	cd 2f 49	. / I
	ret nz			;4ee5	c0		.
	push de			;4ee6	d5		.
	push bc			;4ee7	c5		.
	ld a,(hl)		;4ee8	7e		~
	ld (04f24h),a		;4ee9	32 24 4f	2 $ O
	and 090h		;4eec	e6 90		. .
	cp 010h			;4eee	fe 10		. .
	jr nz,l4f00h		;4ef0	20 0e		  .
	call sub_4e1fh		;4ef2	cd 1f 4e	. . N
	ld de,051cdh		;4ef5	11 cd 51	. . Q
	ld b,00bh		;4ef8	06 0b		. .
l4efah:
	inc hl			;4efa	23		#
	ld a,(de)		;4efb	1a		.
	cp (hl)			;4efc	be		.
	inc de			;4efd	13		.
	jr z,l4f04h		;4efe	28 04		( .
l4f00h:
	pop bc			;4f00	c1		.
	pop de			;4f01	d1		.
	jr l4ed8h		;4f02	18 d4		. .
l4f04h:
	djnz l4efah		;4f04	10 f4		. .
	pop bc			;4f06	c1		.
	pop de			;4f07	d1		.
	inc hl			;4f08	23		#
	ld e,(hl)		;4f09	5e		^
	inc hl			;4f0a	23		#
	ld d,(hl)		;4f0b	56		V
	inc hl			;4f0c	23		#
	ld c,(hl)		;4f0d	4e		N
	inc hl			;4f0e	23		#
	ld b,(hl)		;4f0f	46		F
	inc hl			;4f10	23		#
	push hl			;4f11	e5		.
	ld hl,(051d8h)		;4f12	2a d8 51	* . Q
	bit 7,(iy-014h)		;4f15	fd cb ec 7e	. . . ~
	jr z,l4f2fh		;4f19	28 14		( .
	or a			;4f1b	b7		.
	sbc hl,de		;4f1c	ed 52		. R
	jr z,l4f2fh		;4f1e	28 0f		( .
	add hl,de		;4f20	19		.
	ld a,007h		;4f21	3e 07		> .
	and 000h		;4f23	e6 00		. .
	sbc hl,bc		;4f25	ed 42		. B
	jr z,l4f30h		;4f27	28 07		( .
	pop hl			;4f29	e1		.
	ld a,019h		;4f2a	3e 19		> .
	or a			;4f2c	b7		.
	ret			;4f2d	c9		.
sub_4f2eh:
	push de			;4f2e	d5		.
l4f2fh:
	xor a			;4f2f	af		.
l4f30h:
	push ix			;4f30	dd e5		. .
	pop hl			;4f32	e1		.
	call sub_5110h		;4f33	cd 10 51	. . Q
	ld (hl),080h		;4f36	36 80		6 .
	inc hl			;4f38	23		#
	or 028h			;4f39	f6 28		. (
	ld (hl),a		;4f3b	77		w
	ld a,(04f5eh)		;4f3c	3a 5e 4f	: ^ O
	or a			;4f3f	b7		.
	jr z,l4f44h		;4f40	28 02		( .
	set 7,(hl)		;4f42	cb fe		. .
l4f44h:
	inc hl			;4f44	23		#
	ld (hl),000h		;4f45	36 00		6 .
	ld de,00000h		;4f47	11 00 00	. . .
	inc hl			;4f4a	23		#
	ld (hl),e		;4f4b	73		s
	inc hl			;4f4c	23		#
	ld (hl),d		;4f4d	72		r
	inc hl			;4f4e	23		#
	inc hl			;4f4f	23		#
	ld a,(iy-078h)		;4f50	fd 7e 88	. ~ .
	ld (hl),a		;4f53	77		w
	inc hl			;4f54	23		#
	ld (hl),000h		;4f55	36 00		6 .
	ld a,000h		;4f57	3e 00		> .
	inc hl			;4f59	23		#
	or a			;4f5a	b7		.
	ld (hl),a		;4f5b	77		w
	inc hl			;4f5c	23		#
	ld (hl),000h		;4f5d	36 00		6 .
	inc hl			;4f5f	23		#
	inc hl			;4f60	23		#
	inc hl			;4f61	23		#
	pop de			;4f62	d1		.
	ld a,(de)		;4f63	1a		.
	inc de			;4f64	13		.
	jr z,l4f69h		;4f65	28 02		( .
	sub 001h		;4f67	d6 01		. .
l4f69h:
	ld (hl),a		;4f69	77		w
	inc hl			;4f6a	23		#
	ld a,(de)		;4f6b	1a		.
	sbc a,000h		;4f6c	de 00		. .
	ld (hl),a		;4f6e	77		w
	inc de			;4f6f	13		.
	inc hl			;4f70	23		#
	ld a,02ch		;4f71	3e 2c		> ,
	ret c			;4f73	d8		.
	call sub_4f79h		;4f74	cd 79 4f	. y O
	xor a			;4f77	af		.
	ret			;4f78	c9		.
sub_4f79h:
	ex de,hl		;4f79	eb		.
sub_4f7ah:
	ld a,008h		;4f7a	3e 08		> .
	ld c,a			;4f7c	4f		O
	ld b,000h		;4f7d	06 00		. .
	ldir			;4f7f	ed b0		. .
	ret			;4f81	c9		.
l4f82h:
	ld a,03dh		;4f82	3e 3d		> =
	bit 7,(ix+002h)		;4f84	dd cb 02 7e	. . . ~
	call z,0476eh		;4f88	cc 6e 47	. n G
	jr nz,l4ffbh		;4f8b	20 6e		  n
	ld a,(0486ah)		;4f8d	3a 6a 48	: j H
	ld (0505eh),a		;4f90	32 5e 50	2 ^ P
	push af			;4f93	f5		.
	call 04936h		;4f94	cd 36 49	. 6 I
	call sub_5036h		;4f97	cd 36 50	. 6 P
	inc de			;4f9a	13		.
	push de			;4f9b	d5		.
	call sub_50b4h		;4f9c	cd b4 50	. . P
	ld b,(iy-071h)		;4f9f	fd 46 8f	. F .
	ld c,001h		;4fa2	0e 01		. .
	ld e,(hl)		;4fa4	5e		^
	inc e			;4fa5	1c		.
	jr z,l4fc5h		;4fa6	28 1d		( .
	dec e			;4fa8	1d		.
	dec e			;4fa9	1d		.
	inc hl			;4faa	23		#
	ld a,(hl)		;4fab	7e		~
	and 01fh		;4fac	e6 1f		. .
	ld d,a			;4fae	57		W
	inc d			;4faf	14		.
	ld a,(hl)		;4fb0	7e		~
	and 0e0h		;4fb1	e6 e0		. .
	dec hl			;4fb3	2b		+
	rlca			;4fb4	07		.
	rlca			;4fb5	07		.
	rlca			;4fb6	07		.
	add a,d			;4fb7	82		.
l4fb8h:
	inc e			;4fb8	1c		.
	sub b			;4fb9	90		.
	jr nc,l4fb8h		;4fba	30 fc		0 .
	add a,b			;4fbc	80		.
	jr z,l4fc5h		;4fbd	28 06		( .
l4fbfh:
	rlc c			;4fbf	cb 01		. .
	dec b			;4fc1	05		.
	dec a			;4fc2	3d		=
	jr nz,l4fbfh		;4fc3	20 fa		  .
l4fc5h:
	push hl			;4fc5	e5		.
	xor a			;4fc6	af		.
	call 0490ah		;4fc7	cd 0a 49	. . I
	jr nz,l4ffbh		;4fca	20 2f		  /
	ld l,e			;4fcc	6b		k
	pop de			;4fcd	d1		.
	ld a,001h		;4fce	3e 01		> .
l4fd0h:
	ex af,af'		;4fd0	08		.
	jr l4fe5h		;4fd1	18 12		. .
l4fd3h:
	ld a,(hl)		;4fd3	7e		~
	and c			;4fd4	a1		.
	ld a,(de)		;4fd5	1a		.
	jr z,l4ffdh		;4fd6	28 25		( %
	inc a			;4fd8	3c		<
	jr nz,l504ch		;4fd9	20 71		  q
l4fdbh:
	rlc c			;4fdb	cb 01		. .
	djnz l4fd3h		;4fdd	10 f4		. .
	inc l			;4fdf	2c		,
	ld b,(iy-071h)		;4fe0	fd 46 8f	. F .
	ld c,001h		;4fe3	0e 01		. .
l4fe5h:
	ld a,l			;4fe5	7d		}
	cp (iy-075h)		;4fe6	fd be 8b	. . .
	jr c,l4fd3h		;4fe9	38 e8		8 .
	ex af,af'		;4feb	08		.
	dec a			;4fec	3d		=
	ld l,a			;4fed	6f		o
	jr z,l4fd0h		;4fee	28 e0		( .
	bit 0,(iy-015h)		;4ff0	fd cb eb 46	. . . F
	jr nz,l502ah		;4ff4	20 34		  4
	call sub_508ch		;4ff6	cd 8c 50	. . P
	ld a,01bh		;4ff9	3e 1b		> .
l4ffbh:
	jr l503dh		;4ffb	18 40		. @
l4ffdh:
	inc a			;4ffd	3c		<
	jr nz,l5043h		;4ffe	20 43		  C
	ld a,l			;5000	7d		}
	ld (de),a		;5001	12		.
	inc de			;5002	13		.
	ld a,(iy-071h)		;5003	fd 7e 8f	. ~ .
	sub b			;5006	90		.
	rrca			;5007	0f		.
	rrca			;5008	0f		.
	rrca			;5009	0f		.
	dec a			;500a	3d		=
l500bh:
	inc a			;500b	3c		<
	ld (de),a		;500c	12		.
	dec de			;500d	1b		.
	ld a,(hl)		;500e	7e		~
	or c			;500f	b1		.
	ld (hl),a		;5010	77		w
	ex (sp),hl		;5011	e3		.
	dec hl			;5012	2b		+
	ld a,h			;5013	7c		|
	or l			;5014	b5		.
	ex (sp),hl		;5015	e3		.
	jr nz,l4fdbh		;5016	20 c3		  .
	ld a,(iy-015h)		;5018	fd 7e eb	. ~ .
	and 003h		;501b	e6 03		. .
	jr nz,l502ah		;501d	20 0b		  .
	ex (sp),hl		;501f	e3		.
	inc hl			;5020	23		#
	inc hl			;5021	23		#
	inc hl			;5022	23		#
	ex (sp),hl		;5023	e3		.
	set 0,(iy-015h)		;5024	fd cb eb c6	. . . .
	jr l4fdbh		;5028	18 b1		. .
l502ah:
	res 0,(iy-015h)		;502a	fd cb eb 86	. . . .
	call sub_508ch		;502e	cd 8c 50	. . P
	pop af			;5031	f1		.
	pop af			;5032	f1		.
sub_5033h:
	call 0492fh		;5033	cd 2f 49	. / I
sub_5036h:
	jr nz,l503dh		;5036	20 05		  .
	bit 4,(hl)		;5038	cb 66		. f
	ret nz			;503a	c0		.
	ld a,02ch		;503b	3e 2c		> ,
l503dh:
	call 04c20h		;503d	cd 20 4c	.   L
	jp 049cdh		;5040	c3 cd 49	. . I
l5043h:
	inc de			;5043	13		.
	ld a,(de)		;5044	1a		.
	inc a			;5045	3c		<
	and 01fh		;5046	e6 1f		. .
	ld a,(de)		;5048	1a		.
	jr nz,l500bh		;5049	20 c0		  .
	dec de			;504b	1b		.
l504ch:
	inc de			;504c	13		.
	inc de			;504d	13		.
	ld a,(de)		;504e	1a		.
	inc a			;504f	3c		<
	jr z,l4fd3h		;5050	28 81		( .
	bit 0,(iy-015h)		;5052	fd cb eb 46	. . . F
	jr nz,l502ah		;5056	20 d2		  .
	push hl			;5058	e5		.
	push bc			;5059	c5		.
	call sub_508ch		;505a	cd 8c 50	. . P
	ld b,000h		;505d	06 00		. .
	ld l,b			;505f	68		h
	push bc			;5060	c5		.
	call sub_50cfh		;5061	cd cf 50	. . P
	jr nz,l503dh		;5064	20 d7		  .
	ld c,a			;5066	4f		O
	ld (hl),090h		;5067	36 90		6 .
	inc hl			;5069	23		#
	pop de			;506a	d1		.
	ld (hl),d		;506b	72		r
	call sub_50aeh		;506c	cd ae 50	. . P
	ld a,d			;506f	7a		z
	call sub_5033h		;5070	cd 33 50	. 3 P
	add a,01fh		;5073	c6 1f		. .
	ld l,a			;5075	6f		o
	ld (hl),c		;5076	71		q
	dec hl			;5077	2b		+
	ld (hl),0feh		;5078	36 fe		6 .
	call sub_50aeh		;507a	cd ae 50	. . P
	ld a,c			;507d	79		y
	ld (0505eh),a		;507e	32 5e 50	2 ^ P
	call sub_5033h		;5081	cd 33 50	. 3 P
	call sub_50b4h		;5084	cd b4 50	. . P
	pop bc			;5087	c1		.
	pop de			;5088	d1		.
	jp l4fc5h		;5089	c3 c5 4f	. . O
sub_508ch:
	call sub_50aeh		;508c	cd ae 50	. . P
	ld a,(0505eh)		;508f	3a 5e 50	: ^ P
	call sub_5033h		;5092	cd 33 50	. 3 P
	add a,016h		;5095	c6 16		. .
	bit 7,(hl)		;5097	cb 7e		. ~
	ld l,a			;5099	6f		o
	push hl			;509a	e5		.
	push ix			;509b	dd e5		. .
	pop hl			;509d	e1		.
	ld bc,0000eh		;509e	01 0e 00	. . .
	add hl,bc		;50a1	09		.
	ld de,051adh		;50a2	11 ad 51	. . Q
	push de			;50a5	d5		.
	call z,sub_4f79h	;50a6	cc 79 4f	. y O
	pop hl			;50a9	e1		.
	pop de			;50aa	d1		.
	call sub_4f7ah		;50ab	cd 7a 4f	. z O
sub_50aeh:
	call 0491fh		;50ae	cd 1f 49	. . I
	ret z			;50b1	c8		.
	jr l503dh		;50b2	18 89		. .
sub_50b4h:
	add a,016h		;50b4	c6 16		. .
	ld l,a			;50b6	6f		o
	ld de,051adh		;50b7	11 ad 51	. . Q
	call sub_4f7ah		;50ba	cd 7a 4f	. z O
	ex de,hl		;50bd	eb		.
	ld (hl),0feh		;50be	36 fe		6 .
	rrca			;50c0	0f		.
	ld b,a			;50c1	47		G
l50c2h:
	dec hl			;50c2	2b		+
	dec hl			;50c3	2b		+
	ld a,(hl)		;50c4	7e		~
	inc a			;50c5	3c		<
	ret nz			;50c6	c0		.
	djnz l50c2h		;50c7	10 f9		. .
	ret			;50c9	c9		.
l50cah:
	ld a,d			;50ca	7a		z
	call 04776h		;50cb	cd 76 47	. v G
	ret nz			;50ce	c0		.
sub_50cfh:
	ex de,hl		;50cf	eb		.
	ld a,001h		;50d0	3e 01		> .
	call 0490ah		;50d2	cd 0a 49	. . I
	ret nz			;50d5	c0		.
	ld a,(0421fh)		;50d6	3a 1f 42	: . B
	add a,008h		;50d9	c6 08		. .
	ld c,a			;50db	4f		O
	ld a,b			;50dc	78		x
	and 01fh		;50dd	e6 1f		. .
l50dfh:
	sub c			;50df	91		.
	jr nc,l50dfh		;50e0	30 fd		0 .
	add a,c			;50e2	81		.
l50e3h:
	ld b,a			;50e3	47		G
	ld l,a			;50e4	6f		o
	jr l50f2h		;50e5	18 0b		. .
l50e7h:
	ld a,(hl)		;50e7	7e		~
	or a			;50e8	b7		.
	jr z,l50feh		;50e9	28 13		( .
	ld a,l			;50eb	7d		}
	add a,020h		;50ec	c6 20		.  
	ld l,a			;50ee	6f		o
	jr nc,l50e7h		;50ef	30 f6		0 .
	inc l			;50f1	2c		,
l50f2h:
	ld a,l			;50f2	7d		}
	cp c			;50f3	b9		.
	jr c,l50e7h		;50f4	38 f1		8 .
	xor a			;50f6	af		.
	inc b			;50f7	04		.
	dec b			;50f8	05		.
	jr nz,l50e3h		;50f9	20 e8		  .
	or 01ah			;50fb	f6 1a		. .
	ret			;50fd	c9		.
l50feh:
	ld a,(de)		;50fe	1a		.
	ld (hl),a		;50ff	77		w
	ld c,l			;5100	4d		M
	call 0491fh		;5101	cd 1f 49	. . I
	ret nz			;5104	c0		.
	ld a,c			;5105	79		y
	call 04936h		;5106	cd 36 49	. 6 I
	ret nz			;5109	c0		.
	bit 4,(hl)		;510a	cb 66		. f
	ld a,02ch		;510c	3e 2c		> ,
	ret nz			;510e	c0		.
	ld a,c			;510f	79		y
sub_5110h:
	ld bc,00a16h		;5110	01 16 0a	. . .
	push hl			;5113	e5		.
l5114h:
	ld (hl),000h		;5114	36 00		6 .
	inc hl			;5116	23		#
	dec c			;5117	0d		.
	jr nz,l5114h		;5118	20 fa		  .
l511ah:
	ld (hl),0ffh		;511a	36 ff		6 .
	inc hl			;511c	23		#
	djnz l511ah		;511d	10 fb		. .
	pop hl			;511f	e1		.
	ret			;5120	c9		.
sub_5121h:
	ld b,008h		;5121	06 08		. .
sub_5123h:
	jr nz,l5140h		;5123	20 1b		  .
	call sub_5146h		;5125	cd 46 51	. F Q
	jr c,l513bh		;5128	38 11		8 .
l512ah:
	ld (hl),a		;512a	77		w
	inc hl			;512b	23		#
	call sub_5146h		;512c	cd 46 51	. F Q
	jr nc,l5139h		;512f	30 08		0 .
	cp 030h			;5131	fe 30		. 0
	jr c,l5143h		;5133	38 0e		8 .
	cp 03ah			;5135	fe 3a		. :
	jr nc,l5143h		;5137	30 0a		0 .
l5139h:
	djnz l512ah		;5139	10 ef		. .
l513bh:
	pop af			;513b	f1		.
	ld a,030h		;513c	3e 30		> 0
	or a			;513e	b7		.
	ret			;513f	c9		.
l5140h:
	ld (hl),020h		;5140	36 20		6  
	inc hl			;5142	23		#
l5143h:
	djnz l5140h		;5143	10 fb		. .
	ret			;5145	c9		.
sub_5146h:
	inc de			;5146	13		.
	ld a,(de)		;5147	1a		.
	call 045b5h		;5148	cd b5 45	. . E
	cp 041h			;514b	fe 41		. A
	ret c			;514d	d8		.
	cp 05fh			;514e	fe 5f		. _
	ccf			;5150	3f		?
	ret			;5151	c9		.
sub_5152h:
	ld hl,051dfh		;5152	21 df 51	! . Q
l5155h:
	push de			;5155	d5		.
	push bc			;5156	c5		.
	ld de,0ffffh		;5157	11 ff ff	. . .
	ld b,008h		;515a	06 08		. .
l515ch:
	push bc			;515c	c5		.
	ld a,e			;515d	7b		{
	and 007h		;515e	e6 07		. .
	ld c,a			;5160	4f		O
	ld a,e			;5161	7b		{
	rlca			;5162	07		.
	rlca			;5163	07		.
	rlca			;5164	07		.
	xor c			;5165	a9		.
	rlca			;5166	07		.
	ld c,a			;5167	4f		O
	and 0f0h		;5168	e6 f0		. .
	ld b,a			;516a	47		G
	ld a,c			;516b	79		y
	rlca			;516c	07		.
	and 01fh		;516d	e6 1f		. .
	xor b			;516f	a8		.
	xor d			;5170	aa		.
	ld e,a			;5171	5f		_
	ld a,c			;5172	79		y
	and 00fh		;5173	e6 0f		. .
	ld b,a			;5175	47		G
	ld a,c			;5176	79		y
	rlca			;5177	07		.
	rlca			;5178	07		.
	rlca			;5179	07		.
	rlca			;517a	07		.
	xor b			;517b	a8		.
	pop bc			;517c	c1		.
	xor (hl)		;517d	ae		.
	ld d,a			;517e	57		W
	ld (hl),020h		;517f	36 20		6  
	dec hl			;5181	2b		+
	djnz l515ch		;5182	10 d8		. .
	ex de,hl		;5184	eb		.
	pop bc			;5185	c1		.
	pop de			;5186	d1		.
	ret			;5187	c9		.
sub_5188h:
	push af			;5188	f5		.
	ld a,(0477ch)		;5189	3a 7c 47	: | G
	cp 03eh			;518c	fe 3e		. >
	jr z,l519fh		;518e	28 0f		( .
	ld hl,(sub_4e09h+1)	;5190	2a 0a 4e	* . N
	ld a,h			;5193	7c		|
	cp l			;5194	bd		.
	jr z,l519fh		;5195	28 08		( .
	pop af			;5197	f1		.
	ld hl,037d6h		;5198	21 d6 37	! . 7
	add a,l			;519b	85		.
	ld l,a			;519c	6f		o
	ld a,(hl)		;519d	7e		~
	push af			;519e	f5		.
l519fh:
	pop af			;519f	f1		.
	jp 047ech		;51a0	c3 ec 47	. . G
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
