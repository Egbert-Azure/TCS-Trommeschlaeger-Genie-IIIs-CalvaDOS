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
; This file's own load records have two 1-byte gaps not covered by any
; record: 4FF0h and 50F1h. Confirmed by tools/trsload.py --map (the record
; boundaries: ...4F00..4FEF, then 4FF1..50F0, then 50F2..51E9 -- 4FF0h and
; 50F1h fall in neither) and by --extract's own warning ("2 addresses in
; range were never loaded (filled with 00), first 4FF0"). Both bytes are
; zero-filled below; their real value, if any, is not established -- may be
; genuine padding/dead bytes, or something written at runtime rather than
; loaded from disk.
;
; z80dasm 1.2.0
; command line: z80dasm -g 0x4d00 -l -a -t -o sys29-sys-disassembly.asm sys29sys_flat.bin
;
; Not annotated -- this is raw, unedited z80dasm output.

; z80dasm 1.2.0
; command line: z80dasm -g 0x4d00 -l -a -t -o /tmp/sys29sys_disasm.asm /tmp/sys29sys_flat.bin

	org 04d00h

	push af			;4d00	f5		.
	push hl			;4d01	e5		.
	ld a,(04307h)		;4d02	3a 07 43	: . C
	and 00fh		;4d05	e6 0f		. .
	cp 002h			;4d07	fe 02		. .
	jr c,l4d21h		;4d09	38 16		8 .
	cp 003h			;4d0b	fe 03		. .
	jr z,l4d21h		;4d0d	28 12		( .
	cp 006h			;4d0f	fe 06		. .
	jr nc,l4d21h		;4d11	30 0e		0 .
	ld hl,00000h		;4d13	21 00 00	! . .
	ld (l4e8dh),hl		;4d16	22 8d 4e	" . N
	ld hl,03641h		;4d19	21 41 36	! A 6
	ld (04e6dh),hl		;4d1c	22 6d 4e	" m N
	jr l4d30h		;4d1f	18 0f		. .
l4d21h:
	ld hl,l515bh		;4d21	21 5b 51	! [ Q
	ld e,l			;4d24	5d		]
	ld d,h			;4d25	54		T
	ld (hl),020h		;4d26	36 20		6  
	inc de			;4d28	13		.
	push bc			;4d29	c5		.
	ld bc,0001eh		;4d2a	01 1e 00	. . .
	ldir			;4d2d	ed b0		. .
	pop bc			;4d2f	c1		.
l4d30h:
	pop hl			;4d30	e1		.
	cp 003h			;4d31	fe 03		. .
	jr c,l4d41h		;4d33	38 0c		8 .
	cp 006h			;4d35	fe 06		. .
	jr nc,l4d41h		;4d37	30 08		0 .
	ld a,0c3h		;4d39	3e c3		> .
	ld (l4ec9h),a		;4d3b	32 c9 4e	2 . N
	ld (04ecch),a		;4d3e	32 cc 4e	2 . N
l4d41h:
	pop af			;4d41	f1		.
	cp 0ffh			;4d42	fe ff		. .
	jr nz,l4d52h		;4d44	20 0c		  .
	dec c			;4d46	0d		.
	jp z,l4d5ah		;4d47	ca 5a 4d	. Z M
	dec c			;4d4a	0d		.
	jp z,04ecfh		;4d4b	ca cf 4e	. . N
	dec c			;4d4e	0d		.
	jp z,l4f23h		;4d4f	ca 23 4f	. # O
l4d52h:
	ld a,02ah		;4d52	3e 2a		> *
	or a			;4d54	b7		.
	ret			;4d55	c9		.
l4d56h:
	ld a,034h		;4d56	3e 34		> 4
	or a			;4d58	b7		.
	ret			;4d59	c9		.
l4d5ah:
	call 04cd5h		;4d5a	cd d5 4c	. . L
	ld a,(hl)		;4d5d	7e		~
	inc hl			;4d5e	23		#
	cp 00dh			;4d5f	fe 0d		. .
	jr z,l4ddch		;4d61	28 79		( y
	cp 04dh			;4d63	fe 4d		. M
	jr z,l4da3h		;4d65	28 3c		( <
	cp 044h			;4d67	fe 44		. D
	jr z,l4d8eh		;4d69	28 23		( #
	cp 047h			;4d6b	fe 47		. G
	jr z,l4d9eh		;4d6d	28 2f		( /
	cp 05ah			;4d6f	fe 5a		. Z
	jr z,l4dach		;4d71	28 39		( 9
	cp 054h			;4d73	fe 54		. T
	jr z,l4d85h		;4d75	28 0e		( .
	cp 053h			;4d77	fe 53		. S
	jr z,l4db7h		;4d79	28 3c		( <
	cp 048h			;4d7b	fe 48		. H
	jr z,l4dd2h		;4d7d	28 53		( S
	cp 04eh			;4d7f	fe 4e		. N
	jr z,l4dc0h		;4d81	28 3d		( =
	jr l4d56h		;4d83	18 d1		. .
l4d85h:
	ld de,04516h		;4d85	11 16 45	. . E
	ld (04016h),de		;4d88	ed 53 16 40	. S . @
	jr l4d5ah		;4d8c	18 cc		. .
l4d8eh:
	ld de,04028h		;4d8e	11 28 40	. ( @
l4d91h:
	ld (0058fh),de		;4d91	ed 53 8f 05	. S . .
	ld de,0058dh		;4d95	11 8d 05	. . .
	ld (04026h),de		;4d98	ed 53 26 40	. S & @
	jr l4d5ah		;4d9c	18 bc		. .
l4d9eh:
	ld de,02318h		;4d9e	11 18 23	. . #
	jr l4d91h		;4da1	18 ee		. .
l4da3h:
	ld de,04505h		;4da3	11 05 45	. . E
	ld (0401eh),de		;4da6	ed 53 1e 40	. S . @
	jr l4d5ah		;4daa	18 ae		. .
l4dach:
	xor a			;4dac	af		.
	ld (04029h),a		;4dad	32 29 40	2 ) @
	ld a,048h		;4db0	3e 48		> H
	ld (04028h),a		;4db2	32 28 40	2 ( @
	jr l4d5ah		;4db5	18 a3		. .
l4db7h:
	xor a			;4db7	af		.
	ld (04023h),a		;4db8	32 23 40	2 # @
	ld (04024h),a		;4dbb	32 24 40	2 $ @
	jr l4d5ah		;4dbe	18 9a		. .
l4dc0h:
	ld a,(hl)		;4dc0	7e		~
	cp 050h			;4dc1	fe 50		. P
	ld a,0c9h		;4dc3	3e c9		> .
	jr z,l4dcch		;4dc5	28 05		( .
	ld (l4de1h),a		;4dc7	32 e1 4d	2 . M
	jr l4d5ah		;4dca	18 8e		. .
l4dcch:
	ld (l4e82h),a		;4dcc	32 82 4e	2 . N
	inc hl			;4dcf	23		#
	jr l4d5ah		;4dd0	18 88		. .
l4dd2h:
	ld de,0ffffh		;4dd2	11 ff ff	. . .
	ld (04049h),de		;4dd5	ed 53 49 40	. S I @
	jp l4d5ah		;4dd9	c3 5a 4d	. Z M
l4ddch:
	call l4de1h		;4ddc	cd e1 4d	. . M
	xor a			;4ddf	af		.
	ret			;4de0	c9		.
l4de1h:
	ld de,(04016h)		;4de1	ed 5b 16 40	. [ . @
	ld hl,05123h		;4de5	21 23 51	! # Q
	call 04063h		;4de8	cd 63 40	. c @
	ld a,(04015h)		;4deb	3a 15 40	: . @
	call sub_4e92h		;4dee	cd 92 4e	. . N
	ld de,(0401eh)		;4df1	ed 5b 1e 40	. [ . @
	ld hl,l5152h		;4df5	21 52 51	! R Q
	call 04063h		;4df8	cd 63 40	. c @
	ld a,(0401dh)		;4dfb	3a 1d 40	: . @
	call sub_4e92h		;4dfe	cd 92 4e	. . N
	ld de,(04026h)		;4e01	ed 5b 26 40	. [ & @
	ld hl,l5185h		;4e05	21 85 51	! . Q
	call 04063h		;4e08	cd 63 40	. c @
	ld a,(04025h)		;4e0b	3a 25 40	: % @
	call sub_4e92h		;4e0e	cd 92 4e	. . N
	ld a,(04029h)		;4e11	3a 29 40	: ) @
	ld hl,0519ah		;4e14	21 9a 51	! . Q
	call 04068h		;4e17	cd 68 40	. h @
	ld a,(04028h)		;4e1a	3a 28 40	: ( @
	ld hl,051a2h		;4e1d	21 a2 51	! . Q
	call 04068h		;4e20	cd 68 40	. h @
	ld a,(04307h)		;4e23	3a 07 43	: . C
	and 00fh		;4e26	e6 0f		. .
	cp 002h			;4e28	fe 02		. .
	jr z,l4e32h		;4e2a	28 06		( .
	and 0feh		;4e2c	e6 fe		. .
	cp 004h			;4e2e	fe 04		. .
	jr nz,l4e44h		;4e30	20 12		  .
l4e32h:
	ld a,(04023h)		;4e32	3a 23 40	: # @
	ld hl,05167h		;4e35	21 67 51	! g Q
	call 04068h		;4e38	cd 68 40	. h @
	ld a,(04024h)		;4e3b	3a 24 40	: $ @
	ld hl,05177h		;4e3e	21 77 51	! w Q
	call 04068h		;4e41	cd 68 40	. h @
l4e44h:
	ld de,(04049h)		;4e44	ed 5b 49 40	. [ I @
	ld hl,05142h		;4e48	21 42 51	! B Q
	call 04063h		;4e4b	cd 63 40	. c @
	ld a,01ch		;4e4e	3e 1c		> .
	call 00033h		;4e50	cd 33 00	. 3 .
	ld hl,l5101h		;4e53	21 01 51	! . Q
	ld a,(01914h)		;4e56	3a 14 19	: . .
	cp 040h			;4e59	fe 40		. @
	jr c,l4e60h		;4e5b	38 03		8 .
	inc hl			;4e5d	23		#
	jr nz,l4e64h		;4e5e	20 04		  .
l4e60h:
	xor a			;4e60	af		.
	ld (04ebbh),a		;4e61	32 bb 4e	2 . N
l4e64h:
	call sub_4e9ah		;4e64	cd 9a 4e	. . N
	xor a			;4e67	af		.
l4e68h:
	ld hl,(04020h)		;4e68	2a 20 40	*   @
	ld de,(l50f2h)		;4e6b	ed 5b f2 50	. [ . P
	add hl,de		;4e6f	19		.
	ld b,040h		;4e70	06 40		. @
l4e72h:
	call l4e8dh		;4e72	cd 8d 4e	. . N
	inc hl			;4e75	23		#
	inc a			;4e76	3c		<
	djnz l4e72h		;4e77	10 f9		. .
	push af			;4e79	f5		.
	ld a,00dh		;4e7a	3e 0d		> .
	call 00033h		;4e7c	cd 33 00	. 3 .
	pop af			;4e7f	f1		.
	jr nz,l4e68h		;4e80	20 e6		  .
l4e82h:
	ld hl,l51b9h		;4e82	21 b9 51	! . Q
	call sub_4e9ah		;4e85	cd 9a 4e	. . N
	call sub_4ed5h		;4e88	cd d5 4e	. . N
	xor a			;4e8b	af		.
	ret			;4e8c	c9		.
l4e8dh:
	ld (hl),a		;4e8d	77		w
	ret			;4e8e	c9		.
	jp 03649h		;4e8f	c3 49 36	. I 6
sub_4e92h:
	bit 7,a			;4e92	cb 7f		. .
	ret nz			;4e94	c0		.
	inc hl			;4e95	23		#
	inc hl			;4e96	23		#
	ld (hl),08dh		;4e97	36 8d		6 .
	ret			;4e99	c9		.
sub_4e9ah:
	ld a,(hl)		;4e9a	7e		~
	ld b,001h		;4e9b	06 01		. .
	bit 7,a			;4e9d	cb 7f		. .
	jr z,l4ea5h		;4e9f	28 04		( .
	and 07fh		;4ea1	e6 7f		. .
	ld b,a			;4ea3	47		G
	inc hl			;4ea4	23		#
l4ea5h:
	ld a,(hl)		;4ea5	7e		~
	cp 003h			;4ea6	fe 03		. .
	ret z			;4ea8	c8		.
	cp 040h			;4ea9	fe 40		. @
	jr nz,l4eb6h		;4eab	20 09		  .
	push hl			;4ead	e5		.
	ld hl,l50f4h		;4eae	21 f4 50	! . P
	call 04467h		;4eb1	cd 67 44	. g D
	pop hl			;4eb4	e1		.
	xor a			;4eb5	af		.
l4eb6h:
	cp 00bh			;4eb6	fe 0b		. .
	jr nz,l4ebch		;4eb8	20 02		  .
	ld a,00ah		;4eba	3e 0a		> .
l4ebch:
	push af			;4ebc	f5		.
	call 00033h		;4ebd	cd 33 00	. 3 .
	pop af			;4ec0	f1		.
	cp 00dh			;4ec1	fe 0d		. .
	ret z			;4ec3	c8		.
	djnz l4ea5h		;4ec4	10 df		. .
	inc hl			;4ec6	23		#
	jr sub_4e9ah		;4ec7	18 d1		. .
l4ec9h:
	ret			;4ec9	c9		.
	or l			;4eca	b5		.
	ld b,0c9h		;4ecb	06 c9		. .
	cp (hl)			;4ecd	be		.
	ld b,03ah		;4ece	06 3a		. :
	inc d			;4ed0	14		.
	add hl,de		;4ed1	19		.
	ld (04efah),a		;4ed2	32 fa 4e	2 . N
sub_4ed5h:
	ld c,000h		;4ed5	0e 00		. .
	jr l4edch		;4ed7	18 03		. .
l4ed9h:
	inc c			;4ed9	0c		.
	jr z,l4f0fh		;4eda	28 33		( 3
l4edch:
	call l4ec9h		;4edc	cd c9 4e	. . N
	in a,(c)		;4edf	ed 78		. x
	call 04ecch		;4ee1	cd cc 4e	. . N
	cp 0ffh			;4ee4	fe ff		. .
	jr z,l4ed9h		;4ee6	28 f1		( .
	ld hl,l51d1h		;4ee8	21 d1 51	! . Q
	call 04068h		;4eeb	cd 68 40	. h @
	ld hl,l51cdh+1		;4eee	21 ce 51	! . Q
	ld a,c			;4ef1	79		y
	call 04068h		;4ef2	cd 68 40	. h @
	ld a,000h		;4ef5	3e 00		> .
	add a,007h		;4ef7	c6 07		. .
	cp 040h			;4ef9	fe 40		. @
	jr c,l4f04h		;4efb	38 07		8 .
	ld a,00dh		;4efd	3e 0d		> .
	call 00033h		;4eff	cd 33 00	. 3 .
	ld a,007h		;4f02	3e 07		> .
l4f04h:
	ld (04ef6h),a		;4f04	32 f6 4e	2 . N
	ld hl,l51cdh		;4f07	21 cd 51	! . Q
	call 04467h		;4f0a	cd 67 44	. g D
	jr l4ed9h		;4f0d	18 ca		. .
l4f0fh:
	ld a,(04ef6h)		;4f0f	3a f6 4e	: . N
	or a			;4f12	b7		.
	ret z			;4f13	c8		.
	ld a,00dh		;4f14	3e 0d		> .
	call 00033h		;4f16	cd 33 00	. 3 .
	xor a			;4f19	af		.
	ret			;4f1a	c9		.
l4f1bh:
	ld a,020h		;4f1b	3e 20		>  
	or a			;4f1d	b7		.
	ret			;4f1e	c9		.
l4f1fh:
	ld a,039h		;4f1f	3e 39		> 9
	or a			;4f21	b7		.
	ret			;4f22	c9		.
l4f23h:
	ld a,(0439fh)		;4f23	3a 9f 43	: . C
	ld b,a			;4f26	47		G
	ld a,(hl)		;4f27	7e		~
	sub 030h		;4f28	d6 30		. 0
	jp c,l4d56h		;4f2a	da 56 4d	. V M
	call z,sub_4f91h	;4f2d	cc 91 4f	. . O
	jr c,l4f1fh		;4f30	38 ed		8 .
	cp 00ah			;4f32	fe 0a		. .
	jp nc,l4d56h		;4f34	d2 56 4d	. V M
	cp b			;4f37	b8		.
	jr nc,l4f1bh		;4f38	30 e1		0 .
	push af			;4f3a	f5		.
	inc hl			;4f3b	23		#
	ld a,(hl)		;4f3c	7e		~
	cp 03dh			;4f3d	fe 3d		. =
	jr nz,l4f58h		;4f3f	20 17		  .
	inc hl			;4f41	23		#
	ld c,(hl)		;4f42	4e		N
	inc hl			;4f43	23		#
	call 04cd5h		;4f44	cd d5 4c	. . L
	jr nz,l4f58h		;4f47	20 0f		  .
	ld hl,l4ff5h		;4f49	21 f5 4f	! . O
	ld b,010h		;4f4c	06 10		. .
l4f4eh:
	ld a,(hl)		;4f4e	7e		~
	cp c			;4f4f	b9		.
	jr z,l4f5ch		;4f50	28 0a		( .
	ld de,00010h		;4f52	11 10 00	. . .
	add hl,de		;4f55	19		.
	djnz l4f4eh		;4f56	10 f6		. .
l4f58h:
	pop af			;4f58	f1		.
	jp l4d56h		;4f59	c3 56 4d	. V M
l4f5ch:
	pop af			;4f5c	f1		.
	ld c,a			;4f5d	4f		O
	add a,a			;4f5e	87		.
	add a,a			;4f5f	87		.
	add a,c			;4f60	81		.
	add a,a			;4f61	87		.
	push ix			;4f62	dd e5		. .
	push iy			;4f64	fd e5		. .
	ld ix,04371h		;4f66	dd 21 71 43	. ! q C
	ld c,a			;4f6a	4f		O
	ld b,000h		;4f6b	06 00		. .
	add ix,bc		;4f6d	dd 09		. .
	inc hl			;4f6f	23		#
	inc hl			;4f70	23		#
	push hl			;4f71	e5		.
	pop iy			;4f72	fd e1		. .
	ld a,(iy+002h)		;4f74	fd 7e 02	. ~ .
	and 0fch		;4f77	e6 fc		. .
	ld c,a			;4f79	4f		O
	ld a,(ix+002h)		;4f7a	dd 7e 02	. ~ .
	and 003h		;4f7d	e6 03		. .
	or c			;4f7f	b1		.
	ld (iy+002h),a		;4f80	fd 77 02	. w .
	ld bc,0000ah		;4f83	01 0a 00	. . .
	push ix			;4f86	dd e5		. .
	pop de			;4f88	d1		.
	ldir			;4f89	ed b0		. .
	pop iy			;4f8b	fd e1		. .
	pop ix			;4f8d	dd e1		. .
	xor a			;4f8f	af		.
	ret			;4f90	c9		.
sub_4f91h:
	ld a,(04be1h)		;4f91	3a e1 4b	: . K
	cp 0e6h			;4f94	fe e6		. .
	jr z,l4f9ah		;4f96	28 02		( .
	xor a			;4f98	af		.
	ret			;4f99	c9		.
l4f9ah:
	push hl			;4f9a	e5		.
	ld hl,l4faah		;4f9b	21 aa 4f	! . O
	call 04467h		;4f9e	cd 67 44	. g D
	pop hl			;4fa1	e1		.
	call 00049h		;4fa2	cd 49 00	. I .
	sub 00dh		;4fa5	d6 0d		. .
	ret z			;4fa7	c8		.
	scf			;4fa8	37		7
	ret			;4fa9	c9		.
l4faah:
	rlca			;4faa	07		.
	ld b,d			;4fab	42		B
	ld l,c			;4fac	69		i
	ld (hl),h		;4fad	74		t
	ld (hl),h		;4fae	74		t
	ld h,l			;4faf	65		e
	jr nz,l5005h		;4fb0	20 53		  S
	ld a,c			;4fb2	79		y
	ld (hl),e		;4fb3	73		s
	ld (hl),h		;4fb4	74		t
	ld h,l			;4fb5	65		e
	ld l,l			;4fb6	6d		m
	ld h,h			;4fb7	64		d
	ld l,c			;4fb8	69		i
	ld (hl),e		;4fb9	73		s
	ld l,e			;4fba	6b		k
	ld h,l			;4fbb	65		e
	ld (hl),h		;4fbc	74		t
	ld (hl),h		;4fbd	74		t
	ld h,l			;4fbe	65		e
	jr nz,$+121		;4fbf	20 77		  w
	ld h,l			;4fc1	65		e
	ld h,e			;4fc2	63		c
	ld l,b			;4fc3	68		h
	ld (hl),e		;4fc4	73		s
	ld h,l			;4fc5	65		e
	ld l,h			;4fc6	6c		l
	ld l,(hl)		;4fc7	6e		n
	ld a,(bc)		;4fc8	0a		.
	daa			;4fc9	27		'
	ld b,l			;4fca	45		E
	ld c,(hl)		;4fcb	4e		N
	ld d,h			;4fcc	54		T
	ld b,l			;4fcd	45		E
	ld d,d			;4fce	52		R
	daa			;4fcf	27		'
	jr nz,l5041h		;4fd0	20 6f		  o
	ld h,h			;4fd2	64		d
	ld h,l			;4fd3	65		e
	ld (hl),d		;4fd4	72		r
	jr nz,$+67		;4fd5	20 41		  A
	ld h,d			;4fd7	62		b
	ld h,d			;4fd8	62		b
	ld (hl),d		;4fd9	72		r
	ld (hl),l		;4fda	75		u
	ld h,e			;4fdb	63		c
	ld l,b			;4fdc	68		h
	jr nz,l5041h		;4fdd	20 62		  b
	ld h,l			;4fdf	65		e
	ld l,h			;4fe0	6c		l
	ld l,c			;4fe1	69		i
	ld h,l			;4fe2	65		e
	ld h,d			;4fe3	62		b
	ld l,c			;4fe4	69		i
	ld h,a			;4fe5	67		g
	ld h,l			;4fe6	65		e
	ld (hl),d		;4fe7	72		r
	jr nz,l503eh		;4fe8	20 54		  T
	ld h,c			;4fea	61		a
	ld (hl),e		;4feb	73		s
	ld (hl),h		;4fec	74		t
	ld h,l			;4fed	65		e
	dec c			;4fee	0d		.
	nop			;4fef	00		.
	nop			;4ff0	00		.
	ld b,h			;4ff1	44		D
	ld c,c			;4ff2	49		I
	ld d,e			;4ff3	53		S
	ld c,e			;4ff4	4b		K
l4ff5h:
	ld b,c			;4ff5	41		A
	ld a,(02814h)		;4ff6	3a 14 28	: . (
	rlca			;4ff9	07		.
	jr z,l5006h		;4ffa	28 0a		( .
	ld (bc),a		;4ffc	02		.
	nop			;4ffd	00		.
	nop			;4ffe	00		.
	inc d			;4fff	14		.
	ld (bc),a		;5000	02		.
	ld b,h			;5001	44		D
	ld c,c			;5002	49		I
	ld d,e			;5003	53		S
	ld c,e			;5004	4b		K
l5005h:
	ld b,d			;5005	42		B
l5006h:
	ld a,(02814h)		;5006	3a 14 28	: . (
	rlca			;5009	07		.
	jr z,$+22		;500a	28 14		( .
	inc b			;500c	04		.
	nop			;500d	00		.
	ld b,b			;500e	40		@
	inc d			;500f	14		.
	ld (bc),a		;5010	02		.
	ld b,h			;5011	44		D
	ld c,c			;5012	49		I
	ld d,e			;5013	53		S
	ld c,e			;5014	4b		K
	ld b,e			;5015	43		C
	ld a,(03018h)		;5016	3a 18 30	: . 0
	ld d,e			;5019	53		S
	jr z,l502eh		;501a	28 12		( .
	inc bc			;501c	03		.
	nop			;501d	00		.
	inc bc			;501e	03		.
	jr l5023h		;501f	18 02		. .
	ld b,h			;5021	44		D
	ld c,c			;5022	49		I
l5023h:
	ld d,e			;5023	53		S
	ld c,e			;5024	4b		K
	ld b,h			;5025	44		D
	ld a,(03018h)		;5026	3a 18 30	: . 0
	ld d,e			;5029	53		S
	jr z,l5050h		;502a	28 24		( $
	ld b,000h		;502c	06 00		. .
l502eh:
	ld b,e			;502e	43		C
	jr l5033h		;502f	18 02		. .
	ld b,h			;5031	44		D
	ld c,c			;5032	49		I
l5033h:
	ld d,e			;5033	53		S
	ld c,e			;5034	4b		K
	ld b,l			;5035	45		E
	ld a,(02814h)		;5036	3a 14 28	: . (
	rlca			;5039	07		.
	jr z,l5046h		;503a	28 0a		( .
	ld (bc),a		;503c	02		.
	nop			;503d	00		.
l503eh:
	inc b			;503e	04		.
	inc d			;503f	14		.
	ld (bc),a		;5040	02		.
l5041h:
	ld b,h			;5041	44		D
	ld c,c			;5042	49		I
	ld d,e			;5043	53		S
	ld c,e			;5044	4b		K
	ld b,(hl)		;5045	46		F
l5046h:
	ld a,(02814h)		;5046	3a 14 28	: . (
	rlca			;5049	07		.
	jr z,$+22		;504a	28 14		( .
	inc b			;504c	04		.
	nop			;504d	00		.
	ld b,h			;504e	44		D
	inc d			;504f	14		.
l5050h:
	ld (bc),a		;5050	02		.
	ld b,h			;5051	44		D
	ld c,c			;5052	49		I
	ld d,e			;5053	53		S
	ld c,e			;5054	4b		K
	ld b,a			;5055	47		G
	ld a,(03018h)		;5056	3a 18 30	: . 0
	ld d,e			;5059	53		S
	jr z,l506eh		;505a	28 12		( .
	inc bc			;505c	03		.
	nop			;505d	00		.
	rlca			;505e	07		.
	jr l5063h		;505f	18 02		. .
	ld b,h			;5061	44		D
	ld c,c			;5062	49		I
l5063h:
	ld d,e			;5063	53		S
	ld c,e			;5064	4b		K
	ld c,b			;5065	48		H
	ld a,(03018h)		;5066	3a 18 30	: . 0
	ld d,e			;5069	53		S
	jr z,$+38		;506a	28 24		( $
	ld b,000h		;506c	06 00		. .
l506eh:
	ld b,l			;506e	45		E
	jr l5073h		;506f	18 02		. .
	ld b,h			;5071	44		D
	ld c,c			;5072	49		I
l5073h:
	ld d,e			;5073	53		S
	ld c,e			;5074	4b		K
	ld c,c			;5075	49		I
	ld a,(05028h)		;5076	3a 28 50	: ( P
	rlca			;5079	07		.
	ld d,b			;507a	50		P
	ld a,(bc)		;507b	0a		.
	ld (bc),a		;507c	02		.
	nop			;507d	00		.
	nop			;507e	00		.
	jr z,l5083h		;507f	28 02		( .
	ld b,h			;5081	44		D
	ld c,c			;5082	49		I
l5083h:
	ld d,e			;5083	53		S
	ld c,e			;5084	4b		K
	ld c,d			;5085	4a		J
	ld a,(05028h)		;5086	3a 28 50	: ( P
	rlca			;5089	07		.
	ld d,b			;508a	50		P
	inc d			;508b	14		.
	inc b			;508c	04		.
	nop			;508d	00		.
	ld b,b			;508e	40		@
	jr z,l5095h		;508f	28 04		( .
	ld b,h			;5091	44		D
	ld c,c			;5092	49		I
	ld d,e			;5093	53		S
	ld c,e			;5094	4b		K
l5095h:
	ld c,e			;5095	4b		K
	ld a,(06030h)		;5096	3a 30 60	: 0 `
	ld d,e			;5099	53		S
	ld d,b			;509a	50		P
	ld (de),a		;509b	12		.
	inc bc			;509c	03		.
	nop			;509d	00		.
	inc bc			;509e	03		.
	jr nc,l50a4h		;509f	30 03		0 .
	ld b,h			;50a1	44		D
	ld c,c			;50a2	49		I
	ld d,e			;50a3	53		S
l50a4h:
	ld c,e			;50a4	4b		K
	ld c,h			;50a5	4c		L
	ld a,(06030h)		;50a6	3a 30 60	: 0 `
	ld d,e			;50a9	53		S
	ld d,b			;50aa	50		P
	inc h			;50ab	24		$
	ld b,000h		;50ac	06 00		. .
	ld b,e			;50ae	43		C
l50afh:
	jr nc,$+8		;50af	30 06		0 .
	ld b,h			;50b1	44		D
	ld c,c			;50b2	49		I
	ld d,e			;50b3	53		S
	ld c,e			;50b4	4b		K
	ld c,l			;50b5	4d		M
	ld a,(04811h)		;50b6	3a 11 48	: . H
	inc de			;50b9	13		.
	jr z,l50ceh		;50ba	28 12		( .
	ld (bc),a		;50bc	02		.
	nop			;50bd	00		.
	dec b			;50be	05		.
	ld de,04402h		;50bf	11 02 44	. . D
	ld c,c			;50c2	49		I
	ld d,e			;50c3	53		S
	ld c,e			;50c4	4b		K
	ld c,(hl)		;50c5	4e		N
	ld a,(09011h)		;50c6	3a 11 90	: . .
	ld d,e			;50c9	53		S
	ld d,b			;50ca	50		P
	ld (de),a		;50cb	12		.
	ld (bc),a		;50cc	02		.
	nop			;50cd	00		.
l50ceh:
	inc bc			;50ce	03		.
	ld de,04402h		;50cf	11 02 44	. . D
	ld c,c			;50d2	49		I
	ld d,e			;50d3	53		S
	ld c,e			;50d4	4b		K
	ld c,a			;50d5	4f		O
	ld a,(02811h)		;50d6	3a 11 28	: . (
	inc de			;50d9	13		.
	jr z,l50e6h		;50da	28 0a		( .
	ld (bc),a		;50dc	02		.
	nop			;50dd	00		.
	inc b			;50de	04		.
	ld de,04402h		;50df	11 02 44	. . D
	ld c,c			;50e2	49		I
	ld d,e			;50e3	53		S
	ld c,e			;50e4	4b		K
	ld d,b			;50e5	50		P
l50e6h:
	ld a,(04a11h)		;50e6	3a 11 4a	: . J
	ld d,b			;50e9	50		P
	ld d,d			;50ea	52		R
	ld (de),a		;50eb	12		.
	inc b			;50ec	04		.
	nop			;50ed	00		.
	inc bc			;50ee	03		.
	ld de,00006h		;50ef	11 06 00	. . .
l50f2h:
	nop			;50f2	00		.
	nop			;50f3	00		.
l50f4h:
	jr z,l516bh		;50f4	28 75		( u
	ld l,l			;50f6	6d		m
	ld h,a			;50f7	67		g
	ld h,l			;50f8	65		e
	ld l,h			;50f9	6c		l
	ld h,l			;50fa	65		e
	ld l,c			;50fb	69		i
	ld (hl),h		;50fc	74		t
	ld h,l			;50fd	65		e
	ld (hl),h		;50fe	74		t
	add hl,hl		;50ff	29		)
	inc bc			;5100	03		.
l5101h:
	djnz l511fh		;5101	10 1c		. .
	rra			;5103	1f		.
	sbc a,b			;5104	98		.
	dec l			;5105	2d		-
	jr nz,l514fh		;5106	20 47		  G
	ld b,l			;5108	45		E
	ld c,(hl)		;5109	4e		N
	ld c,c			;510a	49		I
	ld b,l			;510b	45		E
	dec l			;510c	2d		-
	ld b,h			;510d	44		D
	ld c,a			;510e	4f		O
	ld d,e			;510f	53		S
	jr nz,l515bh		;5110	20 49		  I
	ld c,(hl)		;5112	4e		N
	ld b,(hl)		;5113	46		F
	ld c,a			;5114	4f		O
	jr nz,l50afh		;5115	20 98		  .
	dec l			;5117	2d		-
	dec bc			;5118	0b		.
	ld d,h			;5119	54		T
	ld h,c			;511a	61		a
	ld (hl),e		;511b	73		s
	ld (hl),h		;511c	74		t
	ld h,c			;511d	61		a
	ld (hl),h		;511e	74		t
l511fh:
	ld (hl),l		;511f	75		u
	ld (hl),d		;5120	72		r
	ld a,(04620h)		;5121	3a 20 46	:   F
	ld b,(hl)		;5124	46		F
	ld b,(hl)		;5125	46		F
	ld b,(hl)		;5126	46		F
	ld c,b			;5127	48		H
	jr nz,l516ah		;5128	20 40		  @
	jr nz,l514ch		;512a	20 20		   
	ld d,e			;512c	53		S
	ld (hl),b		;512d	70		p
	ld h,l			;512e	65		e
	ld l,c			;512f	69		i
	ld h,e			;5130	63		c
	ld l,b			;5131	68		h
	ld h,l			;5132	65		e
	ld (hl),d		;5133	72		r
	ld h,l			;5134	65		e
	ld l,(hl)		;5135	6e		n
	ld h,h			;5136	64		d
	ld h,l			;5137	65		e
	jr nz,l5162h		;5138	20 28		  (
	ld c,b			;513a	48		H
	ld c,c			;513b	49		I
	ld c,l			;513c	4d		M
	ld b,l			;513d	45		E
	ld c,l			;513e	4d		M
	add hl,hl		;513f	29		)
	ld a,(04620h)		;5140	3a 20 46	:   F
	ld b,(hl)		;5143	46		F
	ld b,(hl)		;5144	46		F
	ld b,(hl)		;5145	46		F
	ld c,b			;5146	48		H
	ld a,(bc)		;5147	0a		.
	ld c,l			;5148	4d		M
	ld l,a			;5149	6f		o
	ld l,(hl)		;514a	6e		n
	ld l,c			;514b	69		i
l514ch:
	ld (hl),h		;514c	74		t
	ld l,a			;514d	6f		o
	ld (hl),d		;514e	72		r
l514fh:
	ld a,(02020h)		;514f	3a 20 20	:    
l5152h:
	ld b,(hl)		;5152	46		F
	ld b,(hl)		;5153	46		F
	ld b,(hl)		;5154	46		F
	ld b,(hl)		;5155	46		F
	ld c,b			;5156	48		H
	jr nz,$+66		;5157	20 40		  @
	jr nz,l517bh		;5159	20 20		   
l515bh:
	ld c,e			;515b	4b		K
	ld l,a			;515c	6f		o
	ld (hl),b		;515d	70		p
	ld h,(hl)		;515e	66		f
	ld a,d			;515f	7a		z
	ld h,l			;5160	65		e
	ld l,c			;5161	69		i
l5162h:
	ld l,h			;5162	6c		l
l5163h:
	ld h,l			;5163	65		e
	ld l,(hl)		;5164	6e		n
	ld a,(03020h)		;5165	3a 20 30	:   0
	jr nc,l51b2h		;5168	30 48		0 H
l516ah:
	inc l			;516a	2c		,
l516bh:
	jr nz,l51b3h		;516b	20 46		  F
	ld (hl),l		;516d	75		u
	ld a,(hl)		;516e	7e		~
	ld a,d			;516f	7a		z
	ld h,l			;5170	65		e
	ld l,c			;5171	69		i
	ld l,h			;5172	6c		l
	ld h,l			;5173	65		e
	ld l,(hl)		;5174	6e		n
	ld a,(03020h)		;5175	3a 20 30	:   0
	jr nc,l51c2h		;5178	30 48		0 H
	ld a,(bc)		;517a	0a		.
l517bh:
	ld b,h			;517b	44		D
	ld (hl),d		;517c	72		r
	ld (hl),l		;517d	75		u
	ld h,e			;517e	63		c
	ld l,e			;517f	6b		k
	ld h,l			;5180	65		e
	ld (hl),d		;5181	72		r
	ld a,(02020h)		;5182	3a 20 20	:    
l5185h:
	ld b,(hl)		;5185	46		F
	ld b,(hl)		;5186	46		F
	ld b,(hl)		;5187	46		F
	ld b,(hl)		;5188	46		F
	ld c,b			;5189	48		H
	jr nz,l51cch		;518a	20 40		  @
	jr nz,l51aeh		;518c	20 20		   
	ld b,h			;518e	44		D
	ld (hl),d		;518f	72		r
	ld (hl),l		;5190	75		u
	ld h,e			;5191	63		c
	ld l,e			;5192	6b		k
	ld a,d			;5193	7a		z
	ld h,l			;5194	65		e
	ld l,c			;5195	69		i
	ld l,h			;5196	6c		l
	ld h,l			;5197	65		e
	ld a,(03020h)		;5198	3a 20 30	:   0
	jr nc,l51e5h		;519b	30 48		0 H
	jr nz,$+120		;519d	20 76		  v
	ld l,a			;519f	6f		o
	ld l,(hl)		;51a0	6e		n
	jr nz,l51d3h		;51a1	20 30		  0
	jr nc,$+74		;51a3	30 48		0 H
	ld a,(bc)		;51a5	0a		.
	sbc a,c			;51a6	99		.
	dec l			;51a7	2d		-
	jr nz,$+92		;51a8	20 5a		  Z
	ld b,l			;51aa	45		E
	ld c,c			;51ab	49		I
	ld b,e			;51ac	43		C
	ld c,b			;51ad	48		H
l51aeh:
	ld b,l			;51ae	45		E
	ld c,(hl)		;51af	4e		N
	ld d,e			;51b0	53		S
	ld b,c			;51b1	41		A
l51b2h:
	ld d,h			;51b2	54		T
l51b3h:
	ld e,d			;51b3	5a		Z
	jr nz,$-100		;51b4	20 9a		  .
	dec l			;51b6	2d		-
	dec bc			;51b7	0b		.
	inc bc			;51b8	03		.
l51b9h:
	sbc a,c			;51b9	99		.
	dec l			;51ba	2d		-
	jr nz,$+67		;51bb	20 41		  A
	ld c,e			;51bd	4b		K
	ld d,h			;51be	54		T
	ld c,c			;51bf	49		I
	ld d,(hl)		;51c0	56		V
	ld b,l			;51c1	45		E
l51c2h:
	jr nz,$+82		;51c2	20 50		  P
	ld c,a			;51c4	4f		O
	ld d,d			;51c5	52		R
	ld d,h			;51c6	54		T
	ld d,e			;51c7	53		S
	jr nz,l5163h		;51c8	20 99		  .
	dec l			;51ca	2d		-
	dec bc			;51cb	0b		.
l51cch:
	inc bc			;51cc	03		.
l51cdh:
	jr nz,$+50		;51cd	20 30		  0
	jr nc,$+63		;51cf	30 3d		0 =
l51d1h:
	jr nc,$+50		;51d1	30 30		0 0
l51d3h:
	jr nz,l51d8h		;51d3	20 03		  .
	nop			;51d5	00		.
	nop			;51d6	00		.
	nop			;51d7	00		.
l51d8h:
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
l51e5h:
	nop			;51e5	00		.
	nop			;51e6	00		.
	nop			;51e7	00		.
	nop			;51e8	00		.
	nop			;51e9	00		.
