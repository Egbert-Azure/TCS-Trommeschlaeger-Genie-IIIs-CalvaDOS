;************************************************************************
;
; SYS8 from G-DOS 2.4
;
;
; Disassembled by
; E.H. Schroeer
;
;************************************************************************
; SYS8/SYS, stock GDOS 2.4 -- the DIR, I and FREE commands. Loads
; contiguously into 4D00h-51E7h, no gaps, entry 4D00h -- the extent Grosser
; ch.7 gives: "SYS8/SYS -- EOF 5/0, RAM 4D00-51E7, Start 4D00".
;
; The entry confirms the command table (Grosser ch.5) from the other side:
; DIR and I enter with A=2Ah and FREE with A=4Ah, and 4D04h-4D0Ch is
; "CP 2Ah / JR Z / CP 4Ah / LD A,2Ah / RET NZ" -- DIR taken at 4D06h, FREE
; falling through, anything else rejected.
;
;   z80dasm -g 0x4d00 -l -a -t sys8_flat.bin

	org 04d00h

	ld iy,04380h		;4d00	fd 21 80 43	. ! . C
	cp 02ah			;4d04	fe 2a		. *
	jr z,l4d50h		;4d06	28 48		( H
	cp 04ah			;4d08	fe 4a		. J
	ld a,02ah		;4d0a	3e 2a		> *
	ret nz			;4d0c	c0		.
	call sub_5058h		;4d0d	cd 58 50	. X P
	cp 00dh			;4d10	fe 0d		. .
	jr nz,l4d3dh		;4d12	20 29		  )
	ld c,000h		;4d14	0e 00		. .
	call sub_5086h		;4d16	cd 86 50	. . P
l4d19h:
	ld b,00dh		;4d19	06 0d		. .
l4d1bh:
	call sub_4fdbh		;4d1b	cd db 4f	. . O
	jr z,l4d2ah		;4d1e	28 0a		( .
	cp 020h			;4d20	fe 20		.  
	jp z,l4fb8h		;4d22	ca b8 4f	. . O
	cp 008h			;4d25	fe 08		. .
	jr nz,l4d43h		;4d27	20 1a		  .
	inc b			;4d29	04		.
l4d2ah:
	inc c			;4d2a	0c		.
	djnz l4d1bh		;4d2b	10 ee		. .
	call sub_506bh		;4d2d	cd 6b 50	. k P
	jr l4d19h		;4d30	18 e7		. .
sub_4d32h:
	ld a,000h		;4d32	3e 00		> .
sub_4d34h:
	ld (sub_4d32h+1),a	;4d34	32 33 4d	2 3 M
sub_4d37h:
	call 0492fh		;4d37	cd 2f 49	. / I
	ret z			;4d3a	c8		.
	jr l4d43h		;4d3b	18 06		. .
l4d3dh:
	ld a,034h		;4d3d	3e 34		> 4
	jr l4d43h		;4d3f	18 02		. .
	ld a,02fh		;4d41	3e 2f		> /
l4d43h:
	push af			;4d43	f5		.
	ld hl,l513dh		;4d44	21 3d 51	! = Q
l4d47h:
	ld hl,l4f96h		;4d47	21 96 4f	! . O
	pop af			;4d4a	f1		.
	or a			;4d4b	b7		.
	ret z			;4d4c	c8		.
	jp 04409h		;4d4d	c3 09 44	. . D
l4d50h:
	ld a,(043a0h)		;4d50	3a a0 43	: . C
	ld c,a			;4d53	4f		O
	ld b,000h		;4d54	06 00		. .
	ld a,(hl)		;4d56	7e		~
	cp 03ah			;4d57	fe 3a		. :
	jr nz,l4d5ch		;4d59	20 01		  .
	inc hl			;4d5b	23		#
l4d5ch:
	ld a,(hl)		;4d5c	7e		~
	cp 024h			;4d5d	fe 24		. $
	jr nz,l4d64h		;4d5f	20 03		  .
	set 6,b			;4d61	cb f0		. .
	inc hl			;4d63	23		#
l4d64h:
	ld a,(hl)		;4d64	7e		~
	sub 030h		;4d65	d6 30		. 0
	cp 00ah			;4d67	fe 0a		. .
	jr nc,l4d89h		;4d69	30 1e		0 .
l4d6bh:
	ld c,a			;4d6b	4f		O
	inc hl			;4d6c	23		#
	ld a,(hl)		;4d6d	7e		~
	sub 030h		;4d6e	d6 30		. 0
	cp 00ah			;4d70	fe 0a		. .
	jr nc,l4d85h		;4d72	30 11		0 .
	ld e,a			;4d74	5f		_
	ld a,c			;4d75	79		y
	ld d,009h		;4d76	16 09		. .
l4d78h:
	add a,c			;4d78	81		.
	jr c,l4d81h		;4d79	38 06		8 .
	dec d			;4d7b	15		.
	jr nz,l4d78h		;4d7c	20 fa		  .
	add a,e			;4d7e	83		.
	jr nc,l4d6bh		;4d7f	30 ea		0 .
l4d81h:
	ld a,020h		;4d81	3e 20		>  
	jr l4d43h		;4d83	18 be		. .
l4d85h:
	call 04cd5h		;4d85	cd d5 4c	. . L
	ret c			;4d88	d8		.
l4d89h:
	call sub_5058h		;4d89	cd 58 50	. X P
	jr z,l4d85h		;4d8c	28 f7		( .
	cp 00dh			;4d8e	fe 0d		. .
	jr z,l4dd5h		;4d90	28 43		( C
	cp 041h			;4d92	fe 41		. A
	jr nz,l4d9ah		;4d94	20 04		  .
	set 0,b			;4d96	cb c0		. .
	jr l4d85h		;4d98	18 eb		. .
l4d9ah:
	cp 053h			;4d9a	fe 53		. S
	jr nz,l4da2h		;4d9c	20 04		  .
	set 1,b			;4d9e	cb c8		. .
	jr l4d85h		;4da0	18 e3		. .
l4da2h:
	cp 049h			;4da2	fe 49		. I
	jr nz,l4daah		;4da4	20 04		  .
	set 2,b			;4da6	cb d0		. .
	jr l4d85h		;4da8	18 db		. .
l4daah:
	cp 042h			;4daa	fe 42		. B
	jr nz,l4db2h		;4dac	20 04		  .
	set 5,b			;4dae	cb e8		. .
	jr l4d85h		;4db0	18 d3		. .
l4db2h:
	cp 02fh			;4db2	fe 2f		. /
	jp nz,l4d3dh		;4db4	c2 3d 4d	. = M
	set 4,b			;4db7	cb e0		. .
	push bc			;4db9	c5		.
	ld b,003h		;4dba	06 03		. .
	ld de,l4e0eh		;4dbc	11 0e 4e	. . N
l4dbfh:
	ld a,(hl)		;4dbf	7e		~
	sub 030h		;4dc0	d6 30		. 0
	cp 00ah			;4dc2	fe 0a		. .
	jr c,l4dcch		;4dc4	38 06		8 .
	sub 011h		;4dc6	d6 11		. .
	cp 01ah			;4dc8	fe 1a		. .
	jr nc,l4dd2h		;4dca	30 06		0 .
l4dcch:
	ld a,(hl)		;4dcc	7e		~
	ld (de),a		;4dcd	12		.
	inc de			;4dce	13		.
	inc hl			;4dcf	23		#
	djnz l4dbfh		;4dd0	10 ed		. .
l4dd2h:
	pop bc			;4dd2	c1		.
	jr l4d85h		;4dd3	18 b0		. .
l4dd5h:
	bit 3,b			;4dd5	cb 58		. X
	ld hl,l514bh		;4dd7	21 4b 51	! K Q
	call z,sub_508fh	;4dda	cc 8f 50	. . P
	bit 6,b			;4ddd	cb 70		. p
	jr z,l4df6h		;4ddf	28 15		( .
	ld a,c			;4de1	79		y
	or a			;4de2	b7		.
	jr nz,l4deah		;4de3	20 05		  .
	ld a,0cdh		;4de5	3e cd		> .
l4de7h:
	ld (l4d47h),a		;4de7	32 47 4d	2 G M
l4deah:
	ld a,c			;4dea	79		y
	add a,030h		;4deb	c6 30		. 0
	ld (l5133h),a		;4ded	32 33 51	2 3 Q
	ld hl,l5144h		;4df0	21 44 51	! D Q
	call l4f96h		;4df3	cd 96 4f	. . O
l4df6h:
	call sub_4fdbh		;4df6	cd db 4f	. . O
	jp nz,l4d43h		;4df9	c2 43 4d	. C M
	xor a			;4dfc	af		.
	call sub_4d34h		;4dfd	cd 34 4d	. 4 M
	call sub_5086h		;4e00	cd 86 50	. . P
	ld d,00dh		;4e03	16 0d		. .
	call sub_4fc7h		;4e05	cd c7 4f	. . O
	push de			;4e08	d5		.
	ld c,005h		;4e09	0e 05		. .
	jp l4f3bh		;4e0b	c3 3b 4f	. ; O
l4e0eh:
	jr nz,$+34		;4e0e	20 20		   
	jr nz,l4de7h		;4e10	20 d5		  .
	push bc			;4e12	c5		.
	push hl			;4e13	e5		.
	ex de,hl		;4e14	eb		.
	ld hl,051afh		;4e15	21 af 51	! . Q
	ld b,00bh		;4e18	06 0b		. .
	push hl			;4e1a	e5		.
l4e1bh:
	ld (hl),02eh		;4e1b	36 2e		6 .
	inc hl			;4e1d	23		#
	djnz l4e1bh		;4e1e	10 fb		. .
	ld a,(de)		;4e20	1a		.
	and 007h		;4e21	e6 07		. .
	add a,030h		;4e23	c6 30		. 0
	ld (hl),a		;4e25	77		w
	pop hl			;4e26	e1		.
	ld a,(de)		;4e27	1a		.
	bit 6,a			;4e28	cb 77		. w
	jr z,l4e2eh		;4e2a	28 02		( .
	ld (hl),053h		;4e2c	36 53		6 S
l4e2eh:
	inc hl			;4e2e	23		#
	bit 3,a			;4e2f	cb 5f		. _
	jr z,l4e35h		;4e31	28 02		( .
	ld (hl),049h		;4e33	36 49		6 I
l4e35h:
	inc hl			;4e35	23		#
	inc de			;4e36	13		.
	ld a,(de)		;4e37	1a		.
	bit 5,a			;4e38	cb 6f		. o
	jr z,l4e3eh		;4e3a	28 02		( .
	ld (hl),042h		;4e3c	36 42		6 B
l4e3eh:
	inc hl			;4e3e	23		#
	bit 7,a			;4e3f	cb 7f		. .
	jr z,l4e45h		;4e41	28 02		( .
	ld (hl),045h		;4e43	36 45		6 E
l4e45h:
	inc hl			;4e45	23		#
	bit 6,a			;4e46	cb 77		. w
	jr z,l4e4ch		;4e48	28 02		( .
	ld (hl),046h		;4e4a	36 46		6 F
l4e4ch:
	ld hl,00004h		;4e4c	21 04 00	! . .
	add hl,de		;4e4f	19		.
	ld c,00fh		;4e50	0e 0f		. .
	ld b,008h		;4e52	06 08		. .
	call sub_509ah		;4e54	cd 9a 50	. . P
	ld a,(hl)		;4e57	7e		~
	cp 020h			;4e58	fe 20		.  
	ld a,02fh		;4e5a	3e 2f		> /
	call nz,sub_50a4h	;4e5c	c4 a4 50	. . P
	ld b,003h		;4e5f	06 03		. .
	call sub_509ah		;4e61	cd 9a 50	. . P
	ld b,c			;4e64	41		A
	call sub_5092h		;4e65	cd 92 50	. . P
	ld e,(hl)		;4e68	5e		^
	inc hl			;4e69	23		#
	ld d,(hl)		;4e6a	56		V
	push de			;4e6b	d5		.
	inc hl			;4e6c	23		#
	ld e,(hl)		;4e6d	5e		^
	inc hl			;4e6e	23		#
	ld d,(hl)		;4e6f	56		V
	ld hl,04296h		;4e70	21 96 42	! . B
	rst 18h			;4e73	df		.
	jr z,l4e7bh		;4e74	28 05		( .
	ld a,042h		;4e76	3e 42		> B
	ld (l51b9h),a		;4e78	32 b9 51	2 . Q
l4e7bh:
	pop de			;4e7b	d1		.
	rst 18h			;4e7c	df		.
	jr z,l4e84h		;4e7d	28 05		( .
	ld a,048h		;4e7f	3e 48		> H
	ld (l51b8h),a		;4e81	32 b8 51	2 . Q
l4e84h:
	pop hl			;4e84	e1		.
	pop bc			;4e85	c1		.
	bit 0,b			;4e86	cb 40		. @
	jp z,l4f28h		;4e88	ca 28 4f	. ( O
	ld c,001h		;4e8b	0e 01		. .
	push bc			;4e8d	c5		.
	push hl			;4e8e	e5		.
	inc hl			;4e8f	23		#
	inc hl			;4e90	23		#
	inc hl			;4e91	23		#
	ld e,(hl)		;4e92	5e		^
	ld d,000h		;4e93	16 00		. .
	inc hl			;4e95	23		#
	ld b,d			;4e96	42		B
	ld c,(hl)		;4e97	4e		N
	set 4,l			;4e98	cb e5		. .
	ld a,(hl)		;4e9a	7e		~
	inc hl			;4e9b	23		#
	push hl			;4e9c	e5		.
	ld h,(hl)		;4e9d	66		f
	ld l,a			;4e9e	6f		o
	ld a,e			;4e9f	7b		{
	or a			;4ea0	b7		.
	jr z,l4ea4h		;4ea1	28 01		( .
	dec hl			;4ea3	2b		+
l4ea4h:
	inc c			;4ea4	0c		.
	dec c			;4ea5	0d		.
	jr nz,l4eaah		;4ea6	20 02		  .
	ld b,001h		;4ea8	06 01		. .
l4eaah:
	push de			;4eaa	d5		.
	push hl			;4eab	e5		.
	push bc			;4eac	c5		.
	jr nz,l4eb2h		;4ead	20 03		  .
	ld e,l			;4eaf	5d		]
	ld l,h			;4eb0	6c		l
	ld h,d			;4eb1	62		b
l4eb2h:
	call nz,sub_50adh	;4eb2	c4 ad 50	. . P
	or a			;4eb5	b7		.
	jr z,l4ebch		;4eb6	28 04		( .
	inc e			;4eb8	1c		.
	jr nz,l4ebch		;4eb9	20 01		  .
	inc hl			;4ebb	23		#
l4ebch:
	ld a,h			;4ebc	7c		|
	ld b,l			;4ebd	45		E
	ld c,e			;4ebe	4b		K
	ld hl,0519bh		;4ebf	21 9b 51	! . Q
	ld de,l5109h		;4ec2	11 09 51	. . Q
	call sub_50c8h		;4ec5	cd c8 50	. . P
	pop bc			;4ec8	c1		.
	ld hl,05197h		;4ec9	21 97 51	! . Q
	call sub_50bfh		;4ecc	cd bf 50	. . P
	pop bc			;4ecf	c1		.
	ld hl,l518ch		;4ed0	21 8c 51	! . Q
	ld de,0510ch		;4ed3	11 0c 51	. . Q
	call sub_50c7h		;4ed6	cd c7 50	. . P
	ld (hl),030h		;4ed9	36 30		6 0
	pop bc			;4edb	c1		.
	push hl			;4edc	e5		.
	call sub_50bfh		;4edd	cd bf 50	. . P
	pop hl			;4ee0	e1		.
	ld (hl),02fh		;4ee1	36 2f		6 /
	pop hl			;4ee3	e1		.
	inc hl			;4ee4	23		#
	ld bc,00000h		;4ee5	01 00 00	. . .
	ld d,b			;4ee8	50		P
	ld e,c			;4ee9	59		Y
l4eeah:
	ld a,(hl)		;4eea	7e		~
	cp 0feh			;4eeb	fe fe		. .
	inc hl			;4eed	23		#
	jr nc,l4f04h		;4eee	30 14		0 .
	inc de			;4ef0	13		.
	ld a,(hl)		;4ef1	7e		~
	and 01fh		;4ef2	e6 1f		. .
	inc hl			;4ef4	23		#
	inc a			;4ef5	3c		<
	add a,c			;4ef6	81		.
	ld c,a			;4ef7	4f		O
	jr nc,l4efbh		;4ef8	30 01		0 .
	inc b			;4efa	04		.
l4efbh:
	bit 4,l			;4efb	cb 65		. e
	jr nz,l4eeah		;4efd	20 eb		  .
	ld a,02ch		;4eff	3e 2c		> ,
	jp l4d43h		;4f01	c3 43 4d	. C M
l4f04h:
	jr nz,l4f0fh		;4f04	20 09		  .
	ld a,(hl)		;4f06	7e		~
	call sub_4d37h		;4f07	cd 37 4d	. 7 M
	add a,016h		;4f0a	c6 16		. .
	ld l,a			;4f0c	6f		o
	jr l4eeah		;4f0d	18 db		. .
l4f0fh:
	call sub_4d32h		;4f0f	cd 32 4d	. 2 M
	push de			;4f12	d5		.
	ld hl,051a3h		;4f13	21 a3 51	! . Q
	call sub_50c4h		;4f16	cd c4 50	. . P
	pop bc			;4f19	c1		.
	ld hl,l51a8h+1		;4f1a	21 a9 51	! . Q
	call sub_50bfh		;4f1d	cd bf 50	. . P
	ld hl,l518ch		;4f20	21 8c 51	! . Q
	call sub_508fh		;4f23	cd 8f 50	. . P
	pop hl			;4f26	e1		.
	pop bc			;4f27	c1		.
l4f28h:
	ld a,l			;4f28	7d		}
	add a,020h		;4f29	c6 20		.  
	ld l,a			;4f2b	6f		o
	jr nc,l4f3bh		;4f2c	30 0d		0 .
	ld a,(sub_4d32h+1)	;4f2e	3a 33 4d	: 3 M
	and 01fh		;4f31	e6 1f		. .
	inc a			;4f33	3c		<
	cp 000h			;4f34	fe 00		. .
	jr z,l4fafh		;4f36	28 77		( w
	call sub_4d34h		;4f38	cd 34 4d	. 4 M
l4f3bh:
	ld a,(hl)		;4f3b	7e		~
	and 090h		;4f3c	e6 90		. .
	cp 010h			;4f3e	fe 10		. .
	jr nz,l4f28h		;4f40	20 e6		  .
	ld a,b			;4f42	78		x
	and 030h		;4f43	e6 30		. 0
	jr nz,l4f58h		;4f45	20 11		  .
	bit 6,(hl)		;4f47	cb 76		. v
	jr z,l4f4fh		;4f49	28 04		( .
	bit 1,b			;4f4b	cb 48		. H
	jr l4f55h		;4f4d	18 06		. .
l4f4fh:
	bit 3,(hl)		;4f4f	cb 5e		. ^
	jr z,l4f58h		;4f51	28 05		( .
	bit 2,b			;4f53	cb 50		. P
l4f55h:
	jp z,l4f28h		;4f55	ca 28 4f	. ( O
l4f58h:
	bit 4,b			;4f58	cb 60		. `
	jr z,l4f73h		;4f5a	28 17		( .
	push hl			;4f5c	e5		.
	push bc			;4f5d	c5		.
	ld de,0000dh		;4f5e	11 0d 00	. . .
	add hl,de		;4f61	19		.
	ld de,l4e0eh		;4f62	11 0e 4e	. . N
	ld b,003h		;4f65	06 03		. .
l4f67h:
	ld a,(de)		;4f67	1a		.
	cp (hl)			;4f68	be		.
	inc de			;4f69	13		.
	inc hl			;4f6a	23		#
	jr nz,l4f6fh		;4f6b	20 02		  .
	djnz l4f67h		;4f6d	10 f8		. .
l4f6fh:
	pop bc			;4f6f	c1		.
	pop hl			;4f70	e1		.
	jr nz,l4f28h		;4f71	20 b5		  .
l4f73h:
	bit 5,b			;4f73	cb 68		. h
	jr z,l4f7dh		;4f75	28 06		( .
	inc hl			;4f77	23		#
	bit 5,(hl)		;4f78	cb 6e		. n
	dec hl			;4f7a	2b		+
	jr z,l4f28h		;4f7b	28 ab		( .
l4f7dh:
	pop de			;4f7d	d1		.
	dec c			;4f7e	0d		.
	jr nz,l4f93h		;4f7f	20 12		  .
	ld c,004h		;4f81	0e 04		. .
	call sub_5086h		;4f83	cd 86 50	. . P
	dec d			;4f86	15		.
	jr nz,l4f93h		;4f87	20 0a		  .
	call sub_506bh		;4f89	cd 6b 50	. k P
	ld d,00fh		;4f8c	16 0f		. .
	bit 3,b			;4f8e	cb 58		. X
	call z,sub_4fc7h	;4f90	cc c7 4f	. . O
l4f93h:
	jp 04e11h		;4f93	c3 11 4e	. . N
l4f96h:
	push hl			;4f96	e5		.
	ld hl,l5118h		;4f97	21 18 51	! . Q
	call 04467h		;4f9a	cd 67 44	. g D
	pop hl			;4f9d	e1		.
	call 04467h		;4f9e	cd 67 44	. g D
	ld hl,l511fh		;4fa1	21 1f 51	! . Q
	call 04467h		;4fa4	cd 67 44	. g D
l4fa7h:
	call 00049h		;4fa7	cd 49 00	. I .
	cp 00dh			;4faa	fe 0d		. .
	jr nz,l4fa7h		;4fac	20 f9		  .
	ret			;4fae	c9		.
l4fafh:
	call sub_5086h		;4faf	cd 86 50	. . P
	pop af			;4fb2	f1		.
	cp 004h			;4fb3	fe 04		. .
	call c,sub_506bh	;4fb5	dc 6b 50	. k P
l4fb8h:
	ld a,(050a8h)		;4fb8	3a a8 50	: . P
	cp 03bh			;4fbb	fe 3b		. ;
	call z,sub_5086h	;4fbd	cc 86 50	. . P
	call z,sub_5086h	;4fc0	cc 86 50	. . P
	xor a			;4fc3	af		.
	jp l4d43h		;4fc4	c3 43 4d	. C M
sub_4fc7h:
	bit 0,b			;4fc7	cb 40		. @
	ret z			;4fc9	c8		.
	push hl			;4fca	e5		.
	push bc			;4fcb	c5		.
	dec d			;4fcc	15		.
	ld b,014h		;4fcd	06 14		. .
	call sub_5092h		;4fcf	cd 92 50	. . P
	ld hl,l51bch		;4fd2	21 bc 51	! . Q
	call sub_508fh		;4fd5	cd 8f 50	. . P
	pop bc			;4fd8	c1		.
	pop hl			;4fd9	e1		.
	ret			;4fda	c9		.
sub_4fdbh:
	ld a,c			;4fdb	79		y
	call 047ech		;4fdc	cd ec 47	. . G
	ret nz			;4fdf	c0		.
	push bc			;4fe0	c5		.
	ld b,000h		;4fe1	06 00		. .
	ld hl,l5153h		;4fe3	21 53 51	! S Q
	call sub_50bfh		;4fe6	cd bf 50	. . P
	ld a,(0430dh)		;4fe9	3a 0d 43	: . C
	ld c,a			;4fec	4f		O
	ld b,000h		;4fed	06 00		. .
	ld hl,l516bh		;4fef	21 6b 51	! k Q
	call sub_50bfh		;4ff2	cd bf 50	. . P
	xor a			;4ff5	af		.
	call 0490ah		;4ff6	cd 0a 49	. . I
	jr nz,l5056h		;4ff9	20 5b		  [
	ld bc,00000h		;4ffb	01 00 00	. . .
l4ffeh:
	ld e,(iy-071h)		;4ffe	fd 5e 8f	. ^ .
	ld a,(hl)		;5001	7e		~
	inc hl			;5002	23		#
l5003h:
	rrca			;5003	0f		.
	jr c,l5007h		;5004	38 01		8 .
	inc bc			;5006	03		.
l5007h:
	dec e			;5007	1d		.
	jr nz,l5003h		;5008	20 f9		  .
	ld a,l			;500a	7d		}
	cp (iy-075h)		;500b	fd be 8b	. . .
	jr c,l4ffeh		;500e	38 ee		8 .
	ld hl,l5180h		;5010	21 80 51	! . Q
	call sub_50c4h		;5013	cd c4 50	. . P
	ld hl,042d0h		;5016	21 d0 42	! . B
	ld de,l5159h		;5019	11 59 51	. Y Q
	ld bc,00008h		;501c	01 08 00	. . .
	ldir			;501f	ed b0		. .
	ld de,l5163h		;5021	11 63 51	. c Q
	ld c,008h		;5024	0e 08		. .
	ldir			;5026	ed b0		. .
	ld a,001h		;5028	3e 01		> .
	call 0490ah		;502a	cd 0a 49	. . I
	jr nz,l5056h		;502d	20 27		  '
l502fh:
	ld a,(0421fh)		;502f	3a 1f 42	: . B
	add a,008h		;5032	c6 08		. .
	ld e,a			;5034	5f		_
	ld (04f35h),a		;5035	32 35 4f	2 5 O
l5038h:
	ld a,(hl)		;5038	7e		~
	or a			;5039	b7		.
	inc hl			;503a	23		#
	jr nz,l503eh		;503b	20 01		  .
	inc bc			;503d	03		.
l503eh:
	dec e			;503e	1d		.
	jr nz,l5038h		;503f	20 f7		  .
	ld a,l			;5041	7d		}
	add a,01fh		;5042	c6 1f		. .
	and 0e0h		;5044	e6 e0		. .
	ld l,a			;5046	6f		o
	jr nz,l502fh		;5047	20 e6		  .
	ld hl,l5176h		;5049	21 76 51	! v Q
	call sub_50bfh		;504c	cd bf 50	. . P
	ld hl,l514eh		;504f	21 4e 51	! N Q
	call sub_508fh		;5052	cd 8f 50	. . P
	xor a			;5055	af		.
l5056h:
	pop bc			;5056	c1		.
	ret			;5057	c9		.
sub_5058h:
	ld a,(hl)		;5058	7e		~
	cp 050h			;5059	fe 50		. P
	inc hl			;505b	23		#
	ret nz			;505c	c0		.
	ld a,03bh		;505d	3e 3b		> ;
	ld (050a8h),a		;505f	32 a8 50	2 . P
	ld a,06ah		;5062	3e 6a		> j
	ld (sub_508fh+1),a	;5064	32 90 50	2 . P
	set 3,b			;5067	cb d8		. .
	ld a,(hl)		;5069	7e		~
	ret			;506a	c9		.
sub_506bh:
	bit 5,(iy-017h)		;506b	fd cb e9 6e	. . . n
	ret nz			;506f	c0		.
	ld a,(050a8h)		;5070	3a a8 50	: . P
	cp 033h			;5073	fe 33		. 3
	ret nz			;5075	c0		.
	ld a,03fh		;5076	3e 3f		> ?
	call sub_50a5h		;5078	cd a5 50	. . P
l507bh:
	call 00049h		;507b	cd 49 00	. I .
	dec a			;507e	3d		=
	jp z,0402dh		;507f	ca 2d 40	. - @
	cp 00ch			;5082	fe 0c		. .
	jr nz,l507bh		;5084	20 f5		  .
sub_5086h:
	ld a,020h		;5086	3e 20		>  
	call sub_50a5h		;5088	cd a5 50	. . P
	ld a,00dh		;508b	3e 0d		> .
	jr sub_50a5h		;508d	18 16		. .
sub_508fh:
	jp 04467h		;508f	c3 67 44	. g D
sub_5092h:
	ld a,020h		;5092	3e 20		>  
	call sub_50a5h		;5094	cd a5 50	. . P
	djnz sub_5092h		;5097	10 f9		. .
	ret			;5099	c9		.
sub_509ah:
	ld a,(hl)		;509a	7e		~
	cp 020h			;509b	fe 20		.  
	inc hl			;509d	23		#
	call nz,sub_50a4h	;509e	c4 a4 50	. . P
	djnz sub_509ah		;50a1	10 f7		. .
	ret			;50a3	c9		.
sub_50a4h:
	dec c			;50a4	0d		.
sub_50a5h:
	push de			;50a5	d5		.
	push af			;50a6	f5		.
	call 00033h		;50a7	cd 33 00	. 3 .
	pop af			;50aa	f1		.
	pop de			;50ab	d1		.
	ret			;50ac	c9		.
sub_50adh:
	ld b,018h		;50ad	06 18		. .
	xor a			;50af	af		.
l50b0h:
	sla e			;50b0	cb 23		. #
	adc hl,hl		;50b2	ed 6a		. j
	rla			;50b4	17		.
	jr c,l50bah		;50b5	38 03		8 .
	cp c			;50b7	b9		.
	jr c,l50bch		;50b8	38 02		8 .
l50bah:
	sub c			;50ba	91		.
	inc e			;50bb	1c		.
l50bch:
	djnz l50b0h		;50bc	10 f2		. .
	ret			;50be	c9		.
sub_50bfh:
	ld de,l5112h		;50bf	11 12 51	. . Q
	jr sub_50c7h		;50c2	18 03		. .
sub_50c4h:
	ld de,l510fh		;50c4	11 0f 51	. . Q
sub_50c7h:
	xor a			;50c7	af		.
sub_50c8h:
	push de			;50c8	d5		.
	push hl			;50c9	e5		.
	push bc			;50ca	c5		.
	ex de,hl		;50cb	eb		.
	ld e,(hl)		;50cc	5e		^
	inc hl			;50cd	23		#
	ld d,(hl)		;50ce	56		V
	inc hl			;50cf	23		#
	ld c,(hl)		;50d0	4e		N
	ld b,02fh		;50d1	06 2f		. /
	pop hl			;50d3	e1		.
l50d4h:
	inc b			;50d4	04		.
	add hl,de		;50d5	19		.
	adc a,c			;50d6	89		.
	jr c,l50d4h		;50d7	38 fb		8 .
	or a			;50d9	b7		.
	sbc hl,de		;50da	ed 52		. R
	sbc a,c			;50dc	99		.
	ex (sp),hl		;50dd	e3		.
	push af			;50de	f5		.
	ld a,(hl)		;50df	7e		~
	sub 030h		;50e0	d6 30		. 0
	cp 00ah			;50e2	fe 0a		. .
	inc hl			;50e4	23		#
	ld (hl),b		;50e5	70		p
	jr c,l50efh		;50e6	38 07		8 .
	ld a,b			;50e8	78		x
	cp 030h			;50e9	fe 30		. 0
	jr nz,l50efh		;50eb	20 02		  .
	ld (hl),020h		;50ed	36 20		6  
l50efh:
	ld a,e			;50ef	7b		{
	cp 0f6h			;50f0	fe f6		. .
	jr z,l50fch		;50f2	28 08		( .
	pop af			;50f4	f1		.
	pop bc			;50f5	c1		.
	pop de			;50f6	d1		.
	inc de			;50f7	13		.
	inc de			;50f8	13		.
	inc de			;50f9	13		.
	jr sub_50c8h		;50fa	18 cc		. .
l50fch:
	pop de			;50fc	d1		.
	pop bc			;50fd	c1		.
	pop de			;50fe	d1		.
	inc hl			;50ff	23		#
	ld a,c			;5100	79		y
	add a,030h		;5101	c6 30		. 0
	ld (hl),a		;5103	77		w
	inc hl			;5104	23		#
	ret			;5105	c9		.
	pop af			;5106	f1		.
	pop af			;5107	f1		.
	ret			;5108	c9		.
l5109h:
	and b			;5109	a0		.
	add a,(hl)		;510a	86		.
	ld bc,0d8f0h		;510b	01 f0 d8	. . .
	rst 38h			;510e	ff		.
l510fh:
	jr $-2			;510f	18 fc		. .
	rst 38h			;5111	ff		.
l5112h:
	sbc a,h			;5112	9c		.
	rst 38h			;5113	ff		.
	rst 38h			;5114	ff		.
	or 0ffh			;5115	f6 ff		. .
	rst 38h			;5117	ff		.
l5118h:
	ld b,d			;5118	42		B
	ld l,c			;5119	69		i
	ld (hl),h		;511a	74		t
	ld (hl),h		;511b	74		t
	ld h,l			;511c	65		e
	jr nz,l5122h		;511d	20 03		  .
l511fh:
	ret nz			;511f	c0		.
	ld h,h			;5120	64		d
	ld l,c			;5121	69		i
l5122h:
	ld (hl),e		;5122	73		s
	ld l,e			;5123	6b		k
	ld h,l			;5124	65		e
	ld (hl),h		;5125	74		t
	ld (hl),h		;5126	74		t
	ld h,l			;5127	65		e
	jr nz,$+107		;5128	20 69		  i
	ld l,(hl)		;512a	6e		n
	jr nz,$+78		;512b	20 4c		  L
	ld h,c			;512d	61		a
	ld (hl),l		;512e	75		u
	ld h,(hl)		;512f	66		f
	ld (hl),a		;5130	77		w
	ld l,020h		;5131	2e 20		.  
l5133h:
	jr nc,l5155h		;5133	30 20		0  
	jr z,l517ch		;5135	28 45		( E
	ld c,(hl)		;5137	4e		N
	ld d,h			;5138	54		T
	ld b,l			;5139	45		E
	ld d,d			;513a	52		R
	add hl,hl		;513b	29		)
	dec c			;513c	0d		.
l513dh:
	ld d,e			;513d	53		S
	ld a,c			;513e	79		y
	ld (hl),e		;513f	73		s
	ld (hl),h		;5140	74		t
	ld h,l			;5141	65		e
	ld l,l			;5142	6d		m
	inc bc			;5143	03		.
l5144h:
	ld e,d			;5144	5a		Z
	ld l,c			;5145	69		i
	ld h,l			;5146	65		e
	ld l,h			;5147	6c		l
	rlca			;5148	07		.
	rlca			;5149	07		.
	inc bc			;514a	03		.
l514bh:
	dec e			;514b	1d		.
	rra			;514c	1f		.
	inc bc			;514d	03		.
l514eh:
	ld c,h			;514e	4c		L
	ld h,c			;514f	61		a
	ld (hl),l		;5150	75		u
	ld h,(hl)		;5151	66		f
	ld (hl),a		;5152	77		w
l5153h:
	ld l,030h		;5153	2e 30		. 0
l5155h:
	jr nc,l5187h		;5155	30 30		0 0
	jr nz,$+34		;5157	20 20		   
l5159h:
	ld e,b			;5159	58		X
	ld e,b			;515a	58		X
	ld e,b			;515b	58		X
	ld e,b			;515c	58		X
	ld e,b			;515d	58		X
	ld e,b			;515e	58		X
	ld e,b			;515f	58		X
	ld e,b			;5160	58		X
	jr nz,$+34		;5161	20 20		   
l5163h:
	ld d,h			;5163	54		T
	ld d,h			;5164	54		T
	ld l,04dh		;5165	2e 4d		. M
	ld c,l			;5167	4d		M
	ld l,04ah		;5168	2e 4a		. J
	ld c,d			;516a	4a		J
l516bh:
	jr nz,$+34		;516b	20 20		   
	jr nc,$+50		;516d	30 30		0 0
	jr nz,l51c4h		;516f	20 53		  S
	ld (hl),b		;5171	70		p
	ld (hl),l		;5172	75		u
	ld (hl),d		;5173	72		r
	ld h,l			;5174	65		e
	ld l,(hl)		;5175	6e		n
l5176h:
	jr nz,l51a8h		;5176	20 30		  0
	jr nc,l51aah		;5178	30 30		0 0
	jr nz,l51c2h		;517a	20 46		  F
l517ch:
	ld (hl),d		;517c	72		r
	ld l,050h		;517d	2e 50		. P
	ld l,h			;517f	6c		l
l5180h:
	ld l,030h		;5180	2e 30		. 0
	jr nc,l51b4h		;5182	30 30		0 0
	jr nc,l51a6h		;5184	30 20		0  
	ld b,l			;5186	45		E
l5187h:
	ld l,c			;5187	69		i
	ld l,(hl)		;5188	6e		n
	ld l,b			;5189	68		h
	ld l,00dh		;518a	2e 0d		. .
l518ch:
	jr nz,l51beh		;518c	20 30		  0
	jr nc,l51c0h		;518e	30 30		0 0
	jr nc,l51c2h		;5190	30 30		0 0
	jr nc,l51c4h		;5192	30 30		0 0
	jr nc,l51c6h		;5194	30 30		0 0
	jr nz,l51b8h		;5196	20 20		   
	jr nc,l51cah		;5198	30 30		0 0
	jr nc,l51bch		;519a	30 20		0  
	jr nc,l51ceh		;519c	30 30		0 0
	jr nc,l51d0h		;519e	30 30		0 0
	jr nc,l51d2h		;51a0	30 30		0 0
	jr nz,l51c4h		;51a2	20 20		   
	jr nc,l51d6h		;51a4	30 30		0 0
l51a6h:
	jr nc,$+50		;51a6	30 30		0 0
l51a8h:
	jr nz,l51cah		;51a8	20 20		   
l51aah:
	jr nc,l51dch		;51aa	30 30		0 0
	jr nc,l51ceh		;51ac	30 20		0  
	jr nz,$+85		;51ae	20 53		  S
	ld c,c			;51b0	49		I
	ld b,d			;51b1	42		B
	ld b,l			;51b2	45		E
	ld b,(hl)		;51b3	46		F
l51b4h:
	ld l,02eh		;51b4	2e 2e		. .
	ld l,02eh		;51b6	2e 2e		. .
l51b8h:
	ld c,b			;51b8	48		H
l51b9h:
	ld b,d			;51b9	42		B
	ld d,e			;51ba	53		S
	inc bc			;51bb	03		.
l51bch:
	ld b,l			;51bc	45		E
	ld l,(hl)		;51bd	6e		n
l51beh:
	ld h,h			;51be	64		d
	ld h,l			;51bf	65		e
l51c0h:
	jr nz,$+34		;51c0	20 20		   
l51c2h:
	jr nz,$+110		;51c2	20 6c		  l
l51c4h:
	ld l,a			;51c4	6f		o
	ld h,a			;51c5	67		g
l51c6h:
	jr nz,$+34		;51c6	20 20		   
	jr nz,$+67		;51c8	20 41		  A
l51cah:
	ld l,(hl)		;51ca	6e		n
	ld a,d			;51cb	7a		z
	ld l,020h		;51cc	2e 20		.  
l51ceh:
	ld b,l			;51ce	45		E
	ld l,c			;51cf	69		i
l51d0h:
	ld l,(hl)		;51d0	6e		n
	ld l,b			;51d1	68		h
l51d2h:
	ld l,020h		;51d2	2e 20		.  
	ld b,l			;51d4	45		E
	ld (hl),d		;51d5	72		r
l51d6h:
	ld (hl),a		;51d6	77		w
	ld l,020h		;51d7	2e 20		.  
	jr nz,$+85		;51d9	20 53		  S
	ld c,c			;51db	49		I
l51dch:
	ld b,d			;51dc	42		B
	ld b,l			;51dd	45		E
	ld b,(hl)		;51de	46		F
	ld l,02eh		;51df	2e 2e		. .
	ld l,02eh		;51e1	2e 2e		. .
	ld c,b			;51e3	48		H
	ld b,d			;51e4	42		B
	ld d,e			;51e5	53		S
	dec c			;51e6	0d		.
	nop			;51e7	00		.
