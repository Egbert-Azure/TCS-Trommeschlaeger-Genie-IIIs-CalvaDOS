;************************************************************************
;
; SYS6 from G-DOS 2.4
;
;
; Disassembled and commented by
; E.H. Schroeer
;
; Name: sys6-sys-disassembly.asm
;
; Date: 2026/08/21
;
;************************************************************************
; SYS6/SYS, stock GDOS 2.4 -- the COPY command (A-48h, C-00h).
;
; Entry 4D00h. Unlike the other SYS modules, SYS6 is not a single
; contiguous 4D00h-51E7h block: it runs to 6FF9h, with one always-zero gap
; at 5186h-51FFh filled with 00h below. Grosser ch.7 agrees: "SYS6/SYS --
; EOF 34/235, RAM 4D00-6FF9*, Start 4D00". The dispatch/logic code
; lives in the first ~1150 bytes (4D00h-5185h, matching every other SYS
; module's usual footprint); the rest, up to 6FF9h, holds more code
; (COPY's own drive-type/PDRIVE resolution helpers, string tables, and
; sector-copy buffering) reached only through calls into that range --
; not a passive data buffer, which is why it's included here rather than
; left out.
;
;               z80dasm -g 0x4d00 -l -a -t -o sys6-sys-disassembly.asm sys6_flat.bin

;
; COPY resolves each drive it's given (source and destination) by calling
; stock DRVSEL (m4776/dgetsl, sub_6e76h at 6E76h) with the raw DOS drive
; digit, then builds an IX pointer into a static per-drive-type table
; (sub_6710h/sub_6713h at 6710h/6713h) -- this table lives in SYS6's own
; data page (59xxh), not dpdrv (430Ah); it has nothing to do with our
; driver's PDRIVE data. Separately, sub_5585h/sub_63ech maintain a status
; bitmask at 5940h/5941h, gated by a per-drive mask byte, that l55b5h/
; l55bdh (55B5h/55BDh) check to decide whether to print "'ENTER', wenn
; ===> Systemdiskette in Laufwerk Nr. 0" and loop.
;
; THE DRIVE-SLOT TABLE (5942h/594Ch/5956h) -- and this port's one patch
; to this file.
;
; Three slots, 10 bytes each: drive number, bit mask, then (at +8) a
; pointer to the name printed when COPY wants that disk mounted. Read
; straight out of the stock binary:
;
;	5942h	drive 00h  mask 01h  -> 5A51h "===> System "  (system diskette)
;	594Ch	drive FFh  mask 02h  -> 5A3Ch "Quelle"         (source)
;	5956h	drive FFh  mask 04h  -> 5A44h "Ziel "          (destination)
;
; FFh means "slot unused, skip it" -- sub_5585h's own guard is
; "LD A,(HL) / INC A / RET Z" at 558Dh. Source and destination start
; unused and are filled in from the command line (4D3Dh/4D40h, then
; sub_6437h's own "LD (BC),A" at 644Eh). sub_5646h walks all three,
; 10 bytes apart, calling sub_5658h -> DRVSEL for each slot still in use.
;
; The system slot is never filled in and never FFh: it is hardcoded to
; drive 0. So COPY verifies drive 0 on EVERY copy -- which is why a file
; copy naming neither drive 0 nor a whole disk ("copy rdldemo/job:5 :4")
; failed exactly like "copy 5 6" on this port. When the verify fails,
; l55ech's "CALL 047ECh / JR NZ,l55c1h" jumps straight back to the prompt,
; producing the repeating "'ENTER', wenn ===> Systemdiskette in Laufwerk
; Nr. 0" the user reported.
;
; PATCHED by run-hdboottest.sh: 5942h, 00h -> 05h (sysvol). Same class of
; hardcoded-drive-0 site already patched in SYS26/SYS (4EFEh, 4F3Bh) and
; OVL4/SYS (32ECh), but the first one found in a DATA table rather than in
; a DRVSEL call -- invisible to every pass that read only code. The patch
; asserts the stock byte is 00h and that both neighbouring slots are still
; FFh, so a wrong address fails loudly. Live-confirmed 2026-08-21.
;
; Two theories were built, shipped and DISPROVEN before this one, recorded
; so they are not retried: (1) ddrvfl (4780h) overwriting dpdrv -- ddrvfl
; is never reached via this driver's handler-return path, since gstk holds
; gexit1, not gexit0; (2) dndrv (439Fh), tried at 4 and at 0Ah, neither of
; which changed anything *here* -- dndrv was separately found to be wrong for
; its own reasons and corrected to 0Ah on 2026-08-21, in SYS0/SYS's own 4D63h
; block rather than in the driver.
;   z80dasm -g 0x4d00 -l -a -t sys6_flat.bin


	org 04d00h

	ld iy,04380h		;4d00	fd 21 80 43	. ! . C
	ld (iy-069h),000h	;4d04	fd 36 97 00	. 6 . .
	cp 068h			;4d08	fe 68		. h
	jp z,l6f4bh		;4d0a	ca 4b 6f	. K o
	set 3,(iy-017h)		;4d0d	fd cb e9 de	. . . .
	cp 028h			;4d11	fe 28		. (
	jp z,l65fah		;4d13	ca fa 65	. . e
	cp 048h			;4d16	fe 48		. H
	jp z,l4d1eh		;4d18	ca 1e 4d	. . M
	jp l5208h		;4d1b	c3 08 52	. . R
l4d1eh:
	ld a,(0436ah)		;4d1e	3a 6a 43	: j C
	bit 6,a			;4d21	cb 77		. w
	jr nz,l4d32h		;4d23	20 0d		  .
	push hl			;4d25	e5		.
	ld hl,l5996h		;4d26	21 96 59	! . Y
	set 5,(hl)		;4d29	cb ee		. .
	ld hl,(04049h)		;4d2b	2a 49 40	* I @
	ld (l593ch),hl		;4d2e	22 3c 59	" < Y
	pop hl			;4d31	e1		.
l4d32h:
	push hl			;4d32	e5		.
	call sub_6ecbh		;4d33	cd cb 6e	. . n
	jp nc,l4d98h		;4d36	d2 98 4d	. . M
	pop de			;4d39	d1		.
	ld (l5aebh),a		;4d3a	32 eb 5a	2 . Z
	ld (l594ch),a		;4d3d	32 4c 59	2 L Y
	ld (l5956h),a		;4d40	32 56 59	2 V Y
	push hl			;4d43	e5		.
	ld de,l64a6h		;4d44	11 a6 64	. . d
	call sub_63a3h		;4d47	cd a3 63	. . c
	call sub_6fe5h		;4d4a	cd e5 6f	. . o
	call sub_6392h		;4d4d	cd 92 63	. . c
	jp nc,l4d8bh		;4d50	d2 8b 4d	. . M
	call sub_63a0h		;4d53	cd a0 63	. . c
	ex (sp),hl		;4d56	e3		.
	ld hl,l6e0ch		;4d57	21 0c 6e	! . n
	call 04467h		;4d5a	cd 67 44	. g D
	pop hl			;4d5d	e1		.
	call sub_6fb8h		;4d5e	cd b8 6f	. . o
	ld b,020h		;4d61	06 20		.  
	call sub_4ea7h		;4d63	cd a7 4e	. . N
	ld hl,l5992h+2		;4d66	21 94 59	! . Y
	ld a,(hl)		;4d69	7e		~
	and 0f9h		;4d6a	e6 f9		. .
	inc hl			;4d6c	23		#
	jr nz,l4d72h		;4d6d	20 03		  .
	ld a,(hl)		;4d6f	7e		~
	and 001h		;4d70	e6 01		. .
l4d72h:
	jr nz,l4d79h		;4d72	20 05		  .
	dec hl			;4d74	2b		+
	ld a,(hl)		;4d75	7e		~
	or 040h			;4d76	f6 40		. @
	ld (hl),a		;4d78	77		w
l4d79h:
	call sub_5c96h		;4d79	cd 96 5c	. . \
	ld hl,l594ch		;4d7c	21 4c 59	! L Y
	call sub_6713h		;4d7f	cd 13 67	. . g
	call sub_6710h		;4d82	cd 10 67	. . g
	call sub_4df3h		;4d85	cd f3 4d	. . M
	jp l6291h		;4d88	c3 91 62	. . b
l4d8bh:
	ld hl,l5940h		;4d8b	21 40 59	! @ Y
	ld (hl),006h		;4d8e	36 06		6 .
	inc hl			;4d90	23		#
	ld (hl),001h		;4d91	36 01		6 .
	pop hl			;4d93	e1		.
	call sub_6ec4h		;4d94	cd c4 6e	. . n
	push hl			;4d97	e5		.
l4d98h:
	pop hl			;4d98	e1		.
	ld a,(hl)		;4d99	7e		~
	cp 024h			;4d9a	fe 24		. $
	jr nz,l4da6h		;4d9c	20 08		  .
	push hl			;4d9e	e5		.
	ld hl,l5940h		;4d9f	21 40 59	! @ Y
	set 0,(hl)		;4da2	cb c6		. .
	pop hl			;4da4	e1		.
	inc hl			;4da5	23		#
l4da6h:
	ld de,04d3eh		;4da6	11 3e 4d	. > M
	push de			;4da9	d5		.
	ld bc,00050h		;4daa	01 50 00	. P .
	ldir			;4dad	ed b0		. .
	pop hl			;4daf	e1		.
	ld de,l5ae5h		;4db0	11 e5 5a	. . Z
	call sub_4e8dh		;4db3	cd 8d 4e	. . N
	call sub_6fe5h		;4db6	cd e5 6f	. . o
	ld a,(hl)		;4db9	7e		~
	cp 03ah			;4dba	fe 3a		. :
	jr z,l4dc6h		;4dbc	28 08		( .
	cp 02eh			;4dbe	fe 2e		. .
	jr z,l4dc6h		;4dc0	28 04		( .
	cp 02fh			;4dc2	fe 2f		. /
	jr nz,l4ddeh		;4dc4	20 18		  .
l4dc6h:
	ld c,a			;4dc6	4f		O
	ld b,000h		;4dc7	06 00		. .
	ld de,l5ae5h		;4dc9	11 e5 5a	. . Z
l4dcch:
	ld a,(de)		;4dcc	1a		.
	cp 003h			;4dcd	fe 03		. .
	jr z,l4ddeh		;4dcf	28 0d		( .
	cp c			;4dd1	b9		.
	jr z,l4dd8h		;4dd2	28 04		( .
	inc de			;4dd4	13		.
	inc b			;4dd5	04		.
	jr l4dcch		;4dd6	18 f4		. .
l4dd8h:
	dec hl			;4dd8	2b		+
	dec de			;4dd9	1b		.
	ld a,(de)		;4dda	1a		.
	ld (hl),a		;4ddb	77		w
	djnz l4dd8h		;4ddc	10 fa		. .
l4ddeh:
	call sub_4e8ah		;4dde	cd 8a 4e	. . N
	push hl			;4de1	e5		.
	ld hl,l5996h		;4de2	21 96 59	! . Y
	set 2,(hl)		;4de5	cb d6		. .
	inc hl			;4de7	23		#
	set 3,(hl)		;4de8	cb de		. .
	pop hl			;4dea	e1		.
	ld b,008h		;4deb	06 08		. .
	call sub_4ea7h		;4ded	cd a7 4e	. . N
	jp l6377h		;4df0	c3 77 63	. w c
sub_4df3h:
	call sub_6424h		;4df3	cd 24 64	. $ d
	ld bc,0000ah		;4df6	01 0a 00	. . .
	ld a,000h		;4df9	3e 00		> .
	rlca			;4dfb	07		.
	rlca			;4dfc	07		.
	rlca			;4dfd	07		.
	rlca			;4dfe	07		.
	add a,c			;4dff	81		.
	ex de,hl		;4e00	eb		.
	ld hl,l59c5h		;4e01	21 c5 59	! . Y
	ldir			;4e04	ed b0		. .
	ld h,d			;4e06	62		b
	ld l,a			;4e07	6f		o
	ld c,006h		;4e08	0e 06		. .
	ldir			;4e0a	ed b0		. .
	ld l,c			;4e0c	69		i
	ld b,001h		;4e0d	06 01		. .
	ld de,l6eb5h		;4e0f	11 b5 6e	. . n
	ldir			;4e12	ed b0		. .
	ld de,00100h		;4e14	11 00 01	. . .
	ld a,(l594ch)		;4e17	3a 4c 59	: L Y
	or a			;4e1a	b7		.
	ld b,a			;4e1b	47		G
	jr nz,l4e22h		;4e1c	20 04		  .
	ld a,e			;4e1e	7b		{
l4e1fh:
	or 003h			;4e1f	f6 03		. .
sub_4e21h:
	ld e,a			;4e21	5f		_
l4e22h:
	ld a,(l5956h)		;4e22	3a 56 59	: V Y
	or a			;4e25	b7		.
	jr nz,l4e2ch		;4e26	20 04		  .
	set 0,e			;4e28	cb c3		. .
	set 2,e			;4e2a	cb d3		. .
l4e2ch:
	cp b			;4e2c	b8		.
	jr nz,l4e3dh		;4e2d	20 0e		  .
	ld a,e			;4e2f	7b		{
	or 006h			;4e30	f6 06		. .
	ld e,a			;4e32	5f		_
	ld a,(0436ah)		;4e33	3a 6a 43	: j C
	bit 6,a			;4e36	cb 77		. w
	ld a,015h		;4e38	3e 15		> .
	jp nz,l521ah		;4e3a	c2 1a 52	. . R
l4e3dh:
	ld a,(l5995h)		;4e3d	3a 95 59	: . Y
	bit 7,a			;4e40	cb 7f		. .
	jr z,l4e4dh		;4e42	28 09		( .
	ld a,e			;4e44	7b		{
	cp 006h			;4e45	fe 06		. .
	jp nc,l5208h		;4e47	d2 08 52	. . R
	ld de,00700h		;4e4a	11 00 07	. . .
l4e4dh:
	ld a,e			;4e4d	7b		{
	cp 003h			;4e4e	fe 03		. .
	ld b,080h		;4e50	06 80		. .
	ld hl,l5a3ch		;4e52	21 3c 5a	! < Z
	call z,sub_4e68h	;4e55	cc 68 4e	. h N
	ld a,e			;4e58	7b		{
	cp 005h			;4e59	fe 05		. .
	ld b,040h		;4e5b	06 40		. @
	ld hl,l5a44h		;4e5d	21 44 5a	! D Z
	call z,sub_4e68h	;4e60	cc 68 4e	. h N
	ld (l5940h),de		;4e63	ed 53 40 59	. S @ Y
	ret			;4e67	c9		.
sub_4e68h:
	dec a			;4e68	3d		=
	or d			;4e69	b2		.
	ld c,a			;4e6a	4f		O
	ld a,(l5997h)		;4e6b	3a 97 59	: . Y
	and b			;4e6e	a0		.
	ret nz			;4e6f	c0		.
	push hl			;4e70	e5		.
	ld hl,l6e22h		;4e71	21 22 6e	! " n
	call 04467h		;4e74	cd 67 44	. g D
	pop hl			;4e77	e1		.
	call 04467h		;4e78	cd 67 44	. g D
	ld hl,l6e33h		;4e7b	21 33 6e	! 3 n
	call sub_58deh		;4e7e	cd de 58	. . X
	ret z			;4e81	c8		.
	ld e,000h		;4e82	1e 00		. .
	ld d,c			;4e84	51		Q
	ret			;4e85	c9		.
	ld a,d			;4e86	7a		z
	or c			;4e87	b1		.
	ld d,a			;4e88	57		W
	ret			;4e89	c9		.
sub_4e8ah:
	ld de,l5b17h		;4e8a	11 17 5b	. . [
sub_4e8dh:
	ld b,020h		;4e8d	06 20		.  
	push de			;4e8f	d5		.
l4e90h:
	call 04cd5h		;4e90	cd d5 4c	. . L
	jr nc,l4ea0h		;4e93	30 0b		0 .
l4e95h:
	ld a,(hl)		;4e95	7e		~
	ld (de),a		;4e96	12		.
	inc de			;4e97	13		.
	inc hl			;4e98	23		#
	djnz l4e90h		;4e99	10 f5		. .
	ld a,030h		;4e9b	3e 30		> 0
	jp l521ah		;4e9d	c3 1a 52	. . R
l4ea0h:
	ld a,003h		;4ea0	3e 03		> .
	ld (de),a		;4ea2	12		.
	pop de			;4ea3	d1		.
	ret z			;4ea4	c8		.
	dec hl			;4ea5	2b		+
	ret			;4ea6	c9		.
sub_4ea7h:
	call sub_6ec0h		;4ea7	cd c0 6e	. . n
	jp nz,l4f1dh		;4eaa	c2 1d 4f	. . O
	ld hl,l5997h		;4ead	21 97 59	! . Y
	ld a,(hl)		;4eb0	7e		~
	and 00ch		;4eb1	e6 0c		. .
	jr nz,l4ecah		;4eb3	20 15		  .
	ld a,(l5995h)		;4eb5	3a 95 59	: . Y
	and 080h		;4eb8	e6 80		. .
	push hl			;4eba	e5		.
	ld hl,l6e3fh		;4ebb	21 3f 6e	! ? n
	call z,sub_58deh	;4ebe	cc de 58	. . X
	pop hl			;4ec1	e1		.
	set 3,(hl)		;4ec2	cb de		. .
	jr z,l4ecah		;4ec4	28 04		( .
	ld a,(hl)		;4ec6	7e		~
	xor 00ch		;4ec7	ee 0c		. .
	ld (hl),a		;4ec9	77		w
l4ecah:
	ld de,(l5996h)		;4eca	ed 5b 96 59	. [ . Y
	ld hl,(l5992h+2)	;4ece	2a 94 59	* . Y
	ld a,d			;4ed1	7a		z
	and 002h		;4ed2	e6 02		. .
	jr z,l4edah		;4ed4	28 04		( .
	ld a,l			;4ed6	7d		}
	or 042h			;4ed7	f6 42		. B
	ld l,a			;4ed9	6f		o
l4edah:
	ld a,e			;4eda	7b		{
	and 013h		;4edb	e6 13		. .
	jr nz,l4ee2h		;4edd	20 03		  .
	ld a,d			;4edf	7a		z
	and 030h		;4ee0	e6 30		. 0
l4ee2h:
	jr nz,l4ee7h		;4ee2	20 03		  .
	ld a,h			;4ee4	7c		|
	and 008h		;4ee5	e6 08		. .
l4ee7h:
	jr z,l4eedh		;4ee7	28 04		( .
	bit 3,e			;4ee9	cb 5b		. [
	jr z,l4f49h		;4eeb	28 5c		( \
l4eedh:
	ld a,h			;4eed	7c		|
	and 006h		;4eee	e6 06		. .
	jr z,l4efah		;4ef0	28 08		( .
	bit 2,d			;4ef2	cb 52		. R
	jr nz,l4efah		;4ef4	20 04		  .
	bit 3,e			;4ef6	cb 5b		. [
	jr z,l4f49h		;4ef8	28 4f		( O
l4efah:
	bit 3,e			;4efa	cb 5b		. [
	jr z,l4f0ch		;4efc	28 0e		( .
	bit 3,d			;4efe	cb 5a		. Z
	jr z,l4f0ch		;4f00	28 0a		( .
	ld a,l			;4f02	7d		}
	and 00dh		;4f03	e6 0d		. .
	jr nz,l4f49h		;4f05	20 42		  B
	ld a,h			;4f07	7c		|
	and 036h		;4f08	e6 36		. 6
	jr nz,l4f49h		;4f0a	20 3d		  =
l4f0ch:
	ld a,h			;4f0c	7c		|
	and 041h		;4f0d	e6 41		. A
	jr z,l4f15h		;4f0f	28 04		( .
	bit 3,e			;4f11	cb 5b		. [
	jr z,l4f49h		;4f13	28 34		( 4
l4f15h:
	ld (l5992h+2),hl	;4f15	22 94 59	" . Y
	ld (l5996h),de		;4f18	ed 53 96 59	. S . Y
	ret			;4f1c	c9		.
l4f1dh:
	push bc			;4f1d	c5		.
	ex de,hl		;4f1e	eb		.
	ld hl,l505ch		;4f1f	21 5c 50	! \ P
l4f22h:
	push de			;4f22	d5		.
l4f23h:
	ld a,(de)		;4f23	1a		.
	cp (hl)			;4f24	be		.
	jr nz,l4f4ch		;4f25	20 25		  %
	inc de			;4f27	13		.
	inc hl			;4f28	23		#
	jr l4f23h		;4f29	18 f8		. .
l4f2bh:
	inc hl			;4f2b	23		#
	bit 7,(hl)		;4f2c	cb 7e		. ~
sub_4f2eh:
	jr z,l4f2bh		;4f2e	28 fb		( .
	ld a,(hl)		;4f30	7e		~
	bit 2,a			;4f31	cb 57		. W
	inc hl			;4f33	23		#
	jr z,l4f3ah		;4f34	28 04		( .
	inc hl			;4f36	23		#
	inc hl			;4f37	23		#
	inc hl			;4f38	23		#
	inc hl			;4f39	23		#
l4f3ah:
	bit 4,a			;4f3a	cb 67		. g
	jr z,l4f40h		;4f3c	28 02		( .
	inc hl			;4f3e	23		#
	inc hl			;4f3f	23		#
l4f40h:
	pop de			;4f40	d1		.
	inc hl			;4f41	23		#
	ld a,(hl)		;4f42	7e		~
	or a			;4f43	b7		.
	jr nz,l4f22h		;4f44	20 dc		  .
	jp l5214h		;4f46	c3 14 52	. . R
l4f49h:
	jp l5218h		;4f49	c3 18 52	. . R
l4f4ch:
	bit 7,(hl)		;4f4c	cb 7e		. ~
	jr z,l4f2bh		;4f4e	28 db		( .
	pop af			;4f50	f1		.
	ld a,b			;4f51	78		x
	and (hl)		;4f52	a6		.
	jr z,l4f49h		;4f53	28 f4		( .
	ld b,(hl)		;4f55	46		F
l4f56h:
	inc hl			;4f56	23		#
	ld c,(hl)		;4f57	4e		N
	inc hl			;4f58	23		#
	push de			;4f59	d5		.
	ld a,b			;4f5a	78		x
	and 003h		;4f5b	e6 03		. .
	ld e,a			;4f5d	5f		_
l4f5eh:
	ld d,000h		;4f5e	16 00		. .
	push hl			;4f60	e5		.
	ld hl,l5992h+2		;4f61	21 94 59	! . Y
	push hl			;4f64	e5		.
	add hl,de		;4f65	19		.
	ld a,(hl)		;4f66	7e		~
	or c			;4f67	b1		.
	ld (hl),a		;4f68	77		w
	pop de			;4f69	d1		.
	pop hl			;4f6a	e1		.
	bit 2,b			;4f6b	cb 50		. P
	jr z,l4f7ah		;4f6d	28 0b		( .
	ld c,004h		;4f6f	0e 04		. .
l4f71h:
	ld a,(de)		;4f71	1a		.
	and (hl)		;4f72	a6		.
	inc de			;4f73	13		.
	inc hl			;4f74	23		#
	jr nz,l4f49h		;4f75	20 d2		  .
	dec c			;4f77	0d		.
	jr nz,l4f71h		;4f78	20 f7		  .
l4f7ah:
	ld e,(hl)		;4f7a	5e		^
	inc hl			;4f7b	23		#
	ld d,(hl)		;4f7c	56		V
	ld (04f85h),de		;4f7d	ed 53 85 4f	. S . O
	pop hl			;4f81	e1		.
	bit 4,b			;4f82	cb 60		. `
	call nz,00000h		;4f84	c4 00 00	. . .
	pop bc			;4f87	c1		.
	jp sub_4ea7h		;4f88	c3 a7 4e	. . N
	ld de,l5970h		;4f8b	11 70 59	. p Y
	jr l4f98h		;4f8e	18 08		. .
	ld de,l5968h		;4f90	11 68 59	. h Y
	jr l4f98h		;4f93	18 03		. .
sub_4f95h:
	ld de,l5983h		;4f95	11 83 59	. . Y
l4f98h:
	call sub_6f8fh		;4f98	cd 8f 6f	. . o
	jr z,l4f49h		;4f9b	28 ac		( .
	ret			;4f9d	c9		.
	ld a,(hl)		;4f9e	7e		~
	sub 032h		;4f9f	d6 32		. 2
	cp 005h			;4fa1	fe 05		. .
	inc hl			;4fa3	23		#
	jr nc,l4fcbh		;4fa4	30 25		0 %
	add a,002h		;4fa6	c6 02		. .
	ld (l64afh),a		;4fa8	32 af 64	2 . d
	ret			;4fab	c9		.
	ld de,04480h		;4fac	11 80 44	. . D
	ld b,020h		;4faf	06 20		.  
l4fb1h:
	ld a,00dh		;4fb1	3e 0d		> .
	ld (de),a		;4fb3	12		.
	call 04cd5h		;4fb4	cd d5 4c	. . L
	ret z			;4fb7	c8		.
	dec hl			;4fb8	2b		+
	ret nc			;4fb9	d0		.
	inc hl			;4fba	23		#
	ld a,(hl)		;4fbb	7e		~
	ld (de),a		;4fbc	12		.
	inc de			;4fbd	13		.
	inc hl			;4fbe	23		#
	djnz l4fb1h		;4fbf	10 f0		. .
	jr l4fcbh		;4fc1	18 08		. .
	call sub_6ee7h		;4fc3	cd e7 6e	. . n
	ld (064ach),a		;4fc6	32 ac 64	2 . d
l4fc9h:
	or a			;4fc9	b7		.
	ret nz			;4fca	c0		.
l4fcbh:
	jp l4f49h		;4fcb	c3 49 4f	. I O
	call sub_6ee2h		;4fce	cd e2 6e	. . n
	ld (068abh),a		;4fd1	32 ab 68	2 . h
	jr l4fc9h		;4fd4	18 f3		. .
	call sub_6ee2h		;4fd6	cd e2 6e	. . n
	ld (068ach),a		;4fd9	32 ac 68	2 . h
	ret			;4fdc	c9		.
	call sub_5025h		;4fdd	cd 25 50	. % P
	ld (l5978h),de		;4fe0	ed 53 78 59	. S x Y
	ret			;4fe4	c9		.
	call sub_5025h		;4fe5	cd 25 50	. % P
	ld (l5981h),de		;4fe8	ed 53 81 59	. S . Y
	ret			;4fec	c9		.
	call sub_5025h		;4fed	cd 25 50	. % P
	ld (l597ah),de		;4ff0	ed 53 7a 59	. S z Y
	ret			;4ff4	c9		.
	ld de,063d6h		;4ff5	11 d6 63	. . c
	call sub_5002h		;4ff8	cd 02 50	. . P
	ld (04dfah),a		;4ffb	32 fa 4d	2 . M
	ret			;4ffe	c9		.
	ld de,063cah		;4fff	11 ca 63	. . c
sub_5002h:
	push de			;5002	d5		.
	call sub_6ee7h		;5003	cd e7 6e	. . n
	cp 00ah			;5006	fe 0a		. .
	jr nc,l4fcbh		;5008	30 c1		0 .
	pop de			;500a	d1		.
	ld (de),a		;500b	12		.
	ret			;500c	c9		.
	ld de,l624ch		;500d	11 4c 62	. L b
	ld b,003h		;5010	06 03		. .
l5012h:
	ld a,(hl)		;5012	7e		~
	sub 030h		;5013	d6 30		. 0
	cp 00ah			;5015	fe 0a		. .
	jr c,l501eh		;5017	38 05		8 .
	sub 011h		;5019	d6 11		. .
	cp 01ah			;501b	fe 1a		. .
	ret nc			;501d	d0		.
l501eh:
	ld a,(hl)		;501e	7e		~
	ld (de),a		;501f	12		.
	inc de			;5020	13		.
	inc hl			;5021	23		#
	djnz l5012h		;5022	10 ee		. .
	ret			;5024	c9		.
sub_5025h:
	ld de,l5960h		;5025	11 60 59	. ` Y
	call sub_6f8fh		;5028	cd 8f 6f	. . o
	push hl			;502b	e5		.
	ex de,hl		;502c	eb		.
	ld de,0ffffh		;502d	11 ff ff	. . .
	ld b,008h		;5030	06 08		. .
l5032h:
	push bc			;5032	c5		.
	ld a,e			;5033	7b		{
	and 007h		;5034	e6 07		. .
	ld c,a			;5036	4f		O
	ld a,e			;5037	7b		{
	rlca			;5038	07		.
	rlca			;5039	07		.
	rlca			;503a	07		.
	xor c			;503b	a9		.
	rlca			;503c	07		.
	ld c,a			;503d	4f		O
	and 0f0h		;503e	e6 f0		. .
	ld b,a			;5040	47		G
	ld a,c			;5041	79		y
	rlca			;5042	07		.
	and 01fh		;5043	e6 1f		. .
	xor b			;5045	a8		.
	xor d			;5046	aa		.
	ld e,a			;5047	5f		_
	ld a,c			;5048	79		y
	and 00fh		;5049	e6 0f		. .
	ld b,a			;504b	47		G
	ld a,c			;504c	79		y
	rlca			;504d	07		.
	rlca			;504e	07		.
	rlca			;504f	07		.
	rlca			;5050	07		.
	xor b			;5051	a8		.
	pop bc			;5052	c1		.
	dec hl			;5053	2b		+
	xor (hl)		;5054	ae		.
	ld d,a			;5055	57		W
	ld (hl),020h		;5056	36 20		6  
	djnz l5032h		;5058	10 d8		. .
	pop hl			;505a	e1		.
	ret			;505b	c9		.
l505ch:
	ld b,(hl)		;505c	46		F
	ld d,d			;505d	52		R
	ld b,c			;505e	41		A
	ld b,a			;505f	47		G
	and c			;5060	a1		.
	ld b,b			;5061	40		@
	ld b,c			;5062	41		A
	ld b,l			;5063	45		E
	ld c,c			;5064	49		I
	ld d,(hl)		;5065	56		V
	dec a			;5066	3d		=
	push af			;5067	f5		.
	ld (bc),a		;5068	02		.
	nop			;5069	00		.
	nop			;506a	00		.
	nop			;506b	00		.
	ld a,(bc)		;506c	0a		.
	sbc a,(hl)		;506d	9e		.
	ld c,a			;506e	4f		O
	ld b,c			;506f	41		A
	ld e,d			;5070	5a		Z
	ld c,e			;5071	4b		K
	ld d,a			;5072	57		W
	dec a			;5073	3d		=
	or l			;5074	b5		.
	ld bc,000c0h		;5075	01 c0 00	. . .
	nop			;5078	00		.
	nop			;5079	00		.
	ld r,a			;507a	ed 4f		. O
	ld c,(hl)		;507c	4e		N
	ld e,d			;507d	5a		Z
	ld c,e			;507e	4b		K
	ld d,a			;507f	57		W
	dec a			;5080	3d		=
	or l			;5081	b5		.
	jr nz,l5086h		;5082	20 02		  .
	nop			;5084	00		.
	nop			;5085	00		.
l5086h:
	nop			;5086	00		.
	push hl			;5087	e5		.
	ld c,a			;5088	4f		O
	ld d,e			;5089	53		S
	ld b,d			;508a	42		B
	ld c,c			;508b	49		I
	ld d,(hl)		;508c	56		V
	dec a			;508d	3d		=
	push af			;508e	f5		.
	inc b			;508f	04		.
	nop			;5090	00		.
	nop			;5091	00		.
	nop			;5092	00		.
	ld a,(bc)		;5093	0a		.
	jp l514fh		;5094	c3 4f 51	. O Q
	ld d,b			;5097	50		P
	ld b,h			;5098	44		D
	ld c,(hl)		;5099	4e		N
	dec a			;509a	3d		=
	cp e			;509b	bb		.
	add a,b			;509c	80		.
	rst 38h			;509d	ff		.
	ld c,a			;509e	4f		O
	ld e,d			;509f	5a		Z
	ld d,b			;50a0	50		P
	ld b,h			;50a1	44		D
	ld c,(hl)		;50a2	4e		N
	dec a			;50a3	3d		=
	ei			;50a4	fb		.
	ld b,b			;50a5	40		@
	push af			;50a6	f5		.
	ld c,a			;50a7	4f		O
	ld d,e			;50a8	53		S
	ld d,b			;50a9	50		P
	ld d,l			;50aa	55		U
	ld d,d			;50ab	52		R
	dec a			;50ac	3d		=
	rst 10h			;50ad	d7		.
	ld (bc),a		;50ae	02		.
	cp c			;50af	b9		.
	add a,(hl)		;50b0	86		.
	nop			;50b1	00		.
	nop			;50b2	00		.
l50b3h:
	sub 04fh		;50b3	d6 4f		. O
	ld d,e			;50b5	53		S
	ld d,h			;50b6	54		T
	ld c,a			;50b7	4f		O
	ld d,b			;50b8	50		P
	dec a			;50b9	3d		=
	out (001h),a		;50ba	d3 01		. .
	adc a,04fh		;50bc	ce 4f		. O
	ld c,(hl)		;50be	4e		N
l50bfh:
	ld e,d			;50bf	5a		Z
	ld c,(hl)		;50c0	4e		N
	dec a			;50c1	3d		=
	or h			;50c2	b4		.
	inc b			;50c3	04		.
	ld a,(bc)		;50c4	0a		.
	nop			;50c5	00		.
	nop			;50c6	00		.
	nop			;50c7	00		.
	sub l			;50c8	95		.
	ld c,a			;50c9	4f		O
	ld b,c			;50ca	41		A
	ld e,d			;50cb	5a		Z
	ld c,(hl)		;50cc	4e		N
	dec a			;50cd	3d		=
	call p,0c010h		;50ce	f4 10 c0	. . .
	nop			;50d1	00		.
	nop			;50d2	00		.
	ld (bc),a		;50d3	02		.
	adc a,e			;50d4	8b		.
	ld c,a			;50d5	4f		O
	ld e,d			;50d6	5a		Z
	ld e,d			;50d7	5a		Z
	ld c,(hl)		;50d8	4e		N
	ld b,h			;50d9	44		D
	call po,0c020h		;50da	e4 20 c0	.   .
	add a,b			;50dd	80		.
	nop			;50de	00		.
	ld (bc),a		;50df	02		.
	ld c,e			;50e0	4b		K
	ld b,h			;50e1	44		D
	ld d,a			;50e2	57		W
	ld b,c			;50e3	41		A
	push hl			;50e4	e5		.
	add a,b			;50e5	80		.
	jr nz,l50e8h		;50e6	20 00		  .
l50e8h:
	nop			;50e8	00		.
	nop			;50e9	00		.
	ld d,c			;50ea	51		Q
	ld c,e			;50eb	4b		K
	ld d,a			;50ec	57		W
	dec a			;50ed	3d		=
	or d			;50ee	b2		.
	ld b,b			;50ef	40		@
	defb 0ddh,04fh,04eh ;illegal sequence	;50f0	dd 4f 4e	. O N
	ld b,(hl)		;50f3	46		F
	ld c,l			;50f4	4d		M
	ld d,h			;50f5	54		T
	and a			;50f6	a7		.
	ex af,af'		;50f7	08		.
	nop			;50f8	00		.
	ld b,000h		;50f9	06 00		. .
	inc b			;50fb	04		.
	ld e,b			;50fc	58		X
	ld b,h			;50fd	44		D
l50feh:
	ld c,h			;50fe	4c		L
	dec a			;50ff	3d		=
l5100h:
	or a			;5100	b7		.
	jr nz,l5103h		;5101	20 00		  .
l5103h:
	nop			;5103	00		.
	nop			;5104	00		.
	djnz l50b3h		;5105	10 ac		. .
	ld c,a			;5107	4f		O
	ld c,c			;5108	49		I
	ld b,h			;5109	44		D
	ld c,h			;510a	4c		L
	dec a			;510b	3d		=
	or a			;510c	b7		.
	djnz l510fh		;510d	10 00		. .
l510fh:
	nop			;510f	00		.
	nop			;5110	00		.
	jr nz,l50bfh		;5111	20 ac		  .
	ld c,a			;5113	4f		O
	ld b,d			;5114	42		B
	ld e,d			;5115	5a		Z
	ld c,(hl)		;5116	4e		N
	call po,0c608h		;5117	e4 08 c6	. . .
	nop			;511a	00		.
	nop			;511b	00		.
	ld (bc),a		;511c	02		.
	ld d,c			;511d	51		Q
	ld c,(hl)		;511e	4e		N
	dec a			;511f	3d		=
	or d			;5120	b2		.
	add a,b			;5121	80		.
	sub b			;5122	90		.
	ld c,a			;5123	4f		O
	ld b,d			;5124	42		B
	ld e,d			;5125	5a		Z
	ld b,h			;5126	44		D
	call po,0c201h		;5127	e4 01 c2	. . .
	djnz l512ch		;512a	10 00		. .
l512ch:
	ld (bc),a		;512c	02		.
	ld d,e			;512d	53		S
	ld d,c			;512e	51		Q
	ld b,h			;512f	44		D
	and l			;5130	a5		.
	djnz l5136h		;5131	10 03		. .
	nop			;5133	00		.
	nop			;5134	00		.
	nop			;5135	00		.
l5136h:
	ld c,c			;5136	49		I
	ld d,(hl)		;5137	56		V
	ld d,l			;5138	55		U
	call po,00c02h		;5139	e4 02 0c	. . .
	jr nc,l5146h		;513c	30 08		0 .
	nop			;513e	00		.
	ld c,d			;513f	4a		J
	ld c,b			;5140	48		H
	ld c,h			;5141	4c		L
	and d			;5142	a2		.
	jr nz,l518ah		;5143	20 45		  E
	ld b,h			;5145	44		D
l5146h:
	ld c,e			;5146	4b		K
	and (hl)		;5147	a6		.
	ex af,af'		;5148	08		.
	ld (bc),a		;5149	02		.
	nop			;514a	00		.
	nop			;514b	00		.
	nop			;514c	00		.
	ld b,d			;514d	42		B
	ld b,l			;514e	45		E
l514fh:
	ld b,c			;514f	41		A
	and d			;5150	a2		.
	ld bc,l5246h		;5151	01 46 52	. F R
	ld b,h			;5154	44		D
	and d			;5155	a2		.
	djnz l51a6h		;5156	10 4e		. N
	ld d,(hl)		;5158	56		V
	ld b,h			;5159	44		D
	and l			;515a	a5		.
	ex af,af'		;515b	08		.
	nop			;515c	00		.
	nop			;515d	00		.
	nop			;515e	00		.
	inc b			;515f	04		.
	ld c,l			;5160	4d		M
	ld b,c			;5161	41		A
	ld b,a			;5162	47		G
	add a,080h		;5163	c6 80		. .
	add hl,bc		;5165	09		.
	ld b,000h		;5166	06 00		. .
	ld (bc),a		;5168	02		.
	ld b,(hl)		;5169	46		F
	ld c,l			;516a	4d		M
	ld d,h			;516b	54		T
	and a			;516c	a7		.
	inc b			;516d	04		.
	nop			;516e	00		.
	ex af,af'		;516f	08		.
	nop			;5170	00		.
	ex af,af'		;5171	08		.
	cpl			;5172	2f		/
	or d			;5173	b2		.
	ld (bc),a		;5174	02		.
	dec c			;5175	0d		.
	ld d,b			;5176	50		P
	ld c,d			;5177	4a		J
	call po,0b940h		;5178	e4 40 b9	. @ .
	ld bc,00000h		;517b	01 00 00	. . .
	ld c,(hl)		;517e	4e		N
	call po,07980h		;517f	e4 80 79	. . y
	ld bc,00200h		;5182	01 00 02	. . .
	nop			;5185	00		.
	nop			;5186	00		.
	nop			;5187	00		.
	nop			;5188	00		.
	nop			;5189	00		.
l518ah:
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
l51a6h:
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
	nop			;51e8	00		.
	nop			;51e9	00		.
	nop			;51ea	00		.
	nop			;51eb	00		.
	nop			;51ec	00		.
	nop			;51ed	00		.
	nop			;51ee	00		.
	nop			;51ef	00		.
	nop			;51f0	00		.
	nop			;51f1	00		.
	nop			;51f2	00		.
	nop			;51f3	00		.
	nop			;51f4	00		.
	nop			;51f5	00		.
	nop			;51f6	00		.
	nop			;51f7	00		.
	nop			;51f8	00		.
	nop			;51f9	00		.
	nop			;51fa	00		.
	nop			;51fb	00		.
	nop			;51fc	00		.
	nop			;51fd	00		.
	nop			;51fe	00		.
l51ffh:
	nop			;51ff	00		.
l5200h:
	ld a,020h		;5200	3e 20		>  
	jr l521ah		;5202	18 16		. .
l5204h:
	ld a,03ch		;5204	3e 3c		> <
	jr l521ah		;5206	18 12		. .
l5208h:
	ld a,02ah		;5208	3e 2a		> *
	jr l521ah		;520a	18 0e		. .
	ld a,02ch		;520c	3e 2c		> ,
	jr l521ah		;520e	18 0a		. .
sub_5210h:
	ld a,(hl)		;5210	7e		~
	cp 00dh			;5211	fe 0d		. .
	ret z			;5213	c8		.
l5214h:
	ld a,034h		;5214	3e 34		> 4
	jr l521ah		;5216	18 02		. .
l5218h:
	ld a,02fh		;5218	3e 2f		> /
l521ah:
	push af			;521a	f5		.
l521bh:
	call sub_5881h		;521b	cd 81 58	. . X
l521eh:
	pop af			;521e	f1		.
	ld hl,04409h		;521f	21 09 44	! . D
l5222h:
	push hl			;5222	e5		.
	push af			;5223	f5		.
	call sub_5582h		;5224	cd 82 55	. . U
	ld a,(l593bh)		;5227	3a 3b 59	: ; Y
	bit 7,a			;522a	cb 7f		. .
	jr z,l5235h		;522c	28 07		( .
	ld b,005h		;522e	06 05		. .
	call sub_5646h		;5230	cd 46 56	. F V
	jr nz,l523ch		;5233	20 07		  .
l5235h:
	ld hl,04369h		;5235	21 69 43	! i C
	res 3,(hl)		;5238	cb 9e		. .
	pop af			;523a	f1		.
	ret			;523b	c9		.
l523ch:
	push af			;523c	f5		.
	ld a,046h		;523d	3e 46		> F
	rst 18h			;523f	df		.
sub_5240h:
	ld hl,l5ac2h		;5240	21 c2 5a	! . Z
l5243h:
	call sub_5881h		;5243	cd 81 58	. . X
l5246h:
	call 04467h		;5246	cd 67 44	. g D
l5249h:
	ld hl,04030h		;5249	21 30 40	! 0 @
	jr l5222h		;524c	18 d4		. .
l524eh:
	ld hl,(l5d14h)		;524e	2a 14 5d	* . ]
	ld de,(l5d12h)		;5251	ed 5b 12 5d	. [ . ]
	or a			;5255	b7		.
	sbc hl,de		;5256	ed 52		. R
	ld b,h			;5258	44		D
	ld c,l			;5259	4d		M
	push de			;525a	d5		.
	ld hl,l5d16h		;525b	21 16 5d	! . ]
	ld (l5d12h),hl		;525e	22 12 5d	" . ]
	push hl			;5261	e5		.
	ex de,hl		;5262	eb		.
	ldir			;5263	ed b0		. .
	ld (l5d14h),de		;5265	ed 53 14 5d	. S . ]
	call sub_5578h		;5269	cd 78 55	. x U
	pop hl			;526c	e1		.
	call sub_56a6h		;526d	cd a6 56	. . V
	jp z,l552dh		;5270	ca 2d 55	. - U
l5273h:
	ld hl,l627bh		;5273	21 7b 62	! { b
	call sub_587eh		;5276	cd 7e 58	. ~ X
l5279h:
	ld hl,(l593ch)		;5279	2a 3c 59	* < Y
	ld de,(l5d14h)		;527c	ed 5b 14 5d	. [ . ]
	or a			;5280	b7		.
	sbc hl,de		;5281	ed 52		. R
	ld de,00102h		;5283	11 02 01	. . .
	ld a,0ffh		;5286	3e ff		> .
l5288h:
	inc a			;5288	3c		<
	or a			;5289	b7		.
	sbc hl,de		;528a	ed 52		. R
	jr nc,l5288h		;528c	30 fa		0 .
	ld (0531ah),a		;528e	32 1a 53	2 . S
l5291h:
	ld hl,l594ch		;5291	21 4c 59	! L Y
	call sub_5538h		;5294	cd 38 55	. 8 U
	xor a			;5297	af		.
	ld hl,(l5d14h)		;5298	2a 14 5d	* . ]
	jr l5316h		;529b	18 79		. y
l529dh:
	push hl			;529d	e5		.
	inc hl			;529e	23		#
	inc hl			;529f	23		#
	ld (l5ae8h),hl		;52a0	22 e8 5a	" . Z
	ld a,080h		;52a3	3e 80		> .
	ld (057ebh),a		;52a5	32 eb 57	2 . W
l52a8h:
	call sub_57c8h		;52a8	cd c8 57	. . W
	jr z,l52cfh		;52ab	28 22		( "
	cp 006h			;52ad	fe 06		. .
	jr z,l52d0h		;52af	28 1f		( .
	cp 01ch			;52b1	fe 1c		. .
	jr z,l52b9h		;52b3	28 04		( .
	cp 01dh			;52b5	fe 1d		. .
	jr nz,l52cah		;52b7	20 11		  .
l52b9h:
	ld hl,00000h		;52b9	21 00 00	! . .
	ld a,(l5996h)		;52bc	3a 96 59	: . Y
	and 008h		;52bf	e6 08		. .
	call nz,sub_56a2h	;52c1	c4 a2 56	. . V
	jp z,l549ch		;52c4	ca 9c 54	. . T
	pop hl			;52c7	e1		.
	jr l529dh		;52c8	18 d3		. .
l52cah:
	call sub_585ah		;52ca	cd 5a 58	. Z X
	jr nz,l52a8h		;52cd	20 d9		  .
l52cfh:
	xor a			;52cf	af		.
l52d0h:
	pop hl			;52d0	e1		.
	ld (hl),0ffh		;52d1	36 ff		6 .
	inc hl			;52d3	23		#
	ld (hl),a		;52d4	77		w
	inc hl			;52d5	23		#
	call sub_571bh		;52d6	cd 1b 57	. . W
	push hl			;52d9	e5		.
	ex de,hl		;52da	eb		.
	ld a,(l5996h)		;52db	3a 96 59	: . Y
	and 00ch		;52de	e6 0c		. .
	jr nz,l5311h		;52e0	20 2f		  /
	ld a,(l5992h+2)		;52e2	3a 94 59	: . Y
	bit 1,a			;52e5	cb 4f		. O
	jr nz,l5311h		;52e7	20 28		  (
	ld hl,(l5aefh)		;52e9	2a ef 5a	* . Z
	dec hl			;52ec	2b		+
	ld a,h			;52ed	7c		|
	or a			;52ee	b7		.
	jr nz,l5311h		;52ef	20 20		   
	ld a,l			;52f1	7d		}
	cp 002h			;52f2	fe 02		. .
	jr nc,l52feh		;52f4	30 08		0 .
	ld hl,l64bah		;52f6	21 ba 64	! . d
	call sub_5c80h		;52f9	cd 80 5c	. . \
	jr l530fh		;52fc	18 11		. .
l52feh:
	jr nz,l5311h		;52fe	20 11		  .
	ld hl,000efh		;5300	21 ef 00	! . .
	add hl,de		;5303	19		.
	ld a,(hl)		;5304	7e		~
	cp 0a5h			;5305	fe a5		. .
	jr nz,l5311h		;5307	20 08		  .
	ld hl,l6eb5h		;5309	21 b5 6e	! . n
	ld bc,00010h		;530c	01 10 00	. . .
l530fh:
	ldir			;530f	ed b0		. .
l5311h:
	pop hl			;5311	e1		.
	inc h			;5312	24		$
	ld a,000h		;5313	3e 00		> .
	inc a			;5315	3c		<
l5316h:
	ld (05314h),a		;5316	32 14 53	2 . S
	cp 00ah			;5319	fe 0a		. .
	jp c,l529dh		;531b	da 9d 52	. . R
	call sub_5324h		;531e	cd 24 53	. $ S
	jp l5291h		;5321	c3 91 52	. . R
sub_5324h:
	call sub_5535h		;5324	cd 35 55	. 5 U
	ld a,(05314h)		;5327	3a 14 53	: . S
	or a			;532a	b7		.
	ret z			;532b	c8		.
	ld hl,(l5d14h)		;532c	2a 14 5d	* . ]
l532fh:
	ld (l544eh+1),hl	;532f	22 4f 54	" O T
	ld de,(l5b21h)		;5332	ed 5b 21 5b	. [ ! [
	ld (05401h),de		;5336	ed 53 01 54	. S . T
	xor a			;533a	af		.
	ld (053ech),a		;533b	32 ec 53	2 . S
l533eh:
	push hl			;533e	e5		.
	ld a,(l5996h)		;533f	3a 96 59	: . Y
	and 00ch		;5342	e6 0c		. .
	jp z,l53d5h		;5344	ca d5 53	. . S
	and 008h		;5347	e6 08		. .
	jr z,l5360h		;5349	28 15		( .
	ld a,(hl)		;534b	7e		~
	cp (ix+007h)		;534c	dd be 07	. . .
	jr z,l5360h		;534f	28 0f		( .
	push af			;5351	f5		.
	call sub_53fbh		;5352	cd fb 53	. . S
	pop af			;5355	f1		.
	ld ix,l5b17h		;5356	dd 21 17 5b	. ! . [
	call sub_56b9h		;535a	cd b9 56	. . V
	pop hl			;535d	e1		.
	jr l532fh		;535e	18 cf		. .
l5360h:
	ld hl,(l5b21h)		;5360	2a 21 5b	* ! [
	ld a,h			;5363	7c		|
	or l			;5364	b5		.
	jr nz,l53d5h		;5365	20 6e		  n
	xor a			;5367	af		.
	ld (053d7h),a		;5368	32 d7 53	2 . S
	ld a,(l5996h)		;536b	3a 96 59	: . Y
	bit 3,a			;536e	cb 5f		. _
	push hl			;5370	e5		.
	ld hl,(l5af1h)		;5371	2a f1 5a	* . Z
	ld a,(l5aedh)		;5374	3a ed 5a	: . Z
	jr z,l537fh		;5377	28 06		( .
	ld hl,(l5b23h)		;5379	2a 23 5b	* # [
	ld a,(l5b1fh)		;537c	3a 1f 5b	: . [
l537fh:
	or a			;537f	b7		.
	jr nz,l5383h		;5380	20 01		  .
	dec hl			;5382	2b		+
l5383h:
	ld a,h			;5383	7c		|
	and l			;5384	a5		.
	inc a			;5385	3c		<
	jr z,l53d1h		;5386	28 49		( I
	ld (l5b21h),hl		;5388	22 21 5b	" ! [
	ld hl,0436bh		;538b	21 6b 43	! k C
	set 1,(hl)		;538e	cb ce		. .
	call sub_57ceh		;5390	cd ce 57	. . W
	res 1,(hl)		;5393	cb 8e		. .
	jr z,l53d1h		;5395	28 3a		( :
	push af			;5397	f5		.
	ld hl,l5995h		;5398	21 95 59	! . Y
	bit 7,(hl)		;539b	cb 7e		. ~
	jr nz,l53adh		;539d	20 0e		  .
	ld hl,l5996h		;539f	21 96 59	! . Y
	bit 2,(hl)		;53a2	cb 56		. V
	jp nz,l521eh		;53a4	c2 1e 52	. . R
	sub 01ah		;53a7	d6 1a		. .
	cp 002h			;53a9	fe 02		. .
	jr c,l53b3h		;53ab	38 06		8 .
l53adh:
	call sub_5868h		;53ad	cd 68 58	. h X
	jp l521eh		;53b0	c3 1e 52	. . R
l53b3h:
	call sub_56ddh		;53b3	cd dd 56	. . V
	inc hl			;53b6	23		#
	inc hl			;53b7	23		#
	inc hl			;53b8	23		#
	xor a			;53b9	af		.
	ld (hl),a		;53ba	77		w
	ld de,00011h		;53bb	11 11 00	. . .
	add hl,de		;53be	19		.
	ld (hl),a		;53bf	77		w
	inc hl			;53c0	23		#
	ld (hl),a		;53c1	77		w
	call sub_5711h		;53c2	cd 11 57	. . W
	pop hl			;53c5	e1		.
	ld hl,l5ad8h		;53c6	21 d8 5a	! . Z
	call sub_586fh		;53c9	cd 6f 58	. o X
	ld a,0ffh		;53cc	3e ff		> .
	ld (053d7h),a		;53ce	32 d7 53	2 . S
l53d1h:
	pop hl			;53d1	e1		.
	ld (l5b21h),hl		;53d2	22 21 5b	" ! [
l53d5h:
	pop hl			;53d5	e1		.
	ld a,000h		;53d6	3e 00		> .
	or a			;53d8	b7		.
	jr z,l53dfh		;53d9	28 04		( .
	call sub_585eh		;53db	cd 5e 58	. ^ X
	dec a			;53de	3d		=
l53dfh:
	call z,sub_546dh	;53df	cc 6d 54	. m T
	inc hl			;53e2	23		#
	jr z,l53e6h		;53e3	28 01		( .
	ld (hl),a		;53e5	77		w
l53e6h:
	inc hl			;53e6	23		#
	inc h			;53e7	24		$
	call sub_571bh		;53e8	cd 1b 57	. . W
	ld a,000h		;53eb	3e 00		> .
	inc a			;53ed	3c		<
	ld (053ech),a		;53ee	32 ec 53	2 . S
	ld a,(05314h)		;53f1	3a 14 53	: . S
	dec a			;53f4	3d		=
	ld (05314h),a		;53f5	32 14 53	2 . S
	jp nz,l533eh		;53f8	c2 3e 53	. > S
sub_53fbh:
	ld a,(053ech)		;53fb	3a ec 53	: . S
	or a			;53fe	b7		.
	ret z			;53ff	c8		.
	ld hl,00000h		;5400	21 00 00	! . .
	ld (l5b21h),hl		;5403	22 21 5b	" ! [
l5406h:
	ld hl,(l5d10h)		;5406	2a 10 5d	* . ]
	ld (l5b1ah),hl		;5409	22 1a 5b	" . [
	ld a,020h		;540c	3e 20		>  
	ld (057ebh),a		;540e	32 eb 57	2 . W
	ld hl,(l544eh+1)	;5411	2a 4f 54	* O T
	inc hl			;5414	23		#
	ld a,(hl)		;5415	7e		~
	inc a			;5416	3c		<
	call z,sub_585eh	;5417	cc 5e 58	. ^ X
	jr z,l544eh		;541a	28 32		( 2
	call sub_57c8h		;541c	cd c8 57	. . W
	jr nz,l5422h		;541f	20 01		  .
	xor a			;5421	af		.
l5422h:
	jr z,l5428h		;5422	28 04		( .
	cp 006h			;5424	fe 06		. .
	jr nz,l5430h		;5426	20 08		  .
l5428h:
	cp (hl)			;5428	be		.
	jr z,l5440h		;5429	28 15		( .
	call sub_5492h		;542b	cd 92 54	. . T
	ld a,031h		;542e	3e 31		> 1
l5430h:
	dec hl			;5430	2b		+
	call sub_585ah		;5431	cd 5a 58	. Z X
	jr z,l544eh		;5434	28 18		( .
	call sub_546dh		;5436	cd 6d 54	. m T
	jr nz,l544eh		;5439	20 13		  .
	call sub_5492h		;543b	cd 92 54	. . T
	jr l5406h		;543e	18 c6		. .
l5440h:
	ld b,000h		;5440	06 00		. .
	ld de,(l5d10h)		;5442	ed 5b 10 5d	. [ . ]
l5446h:
	inc hl			;5446	23		#
	ld a,(de)		;5447	1a		.
	cp (hl)			;5448	be		.
	inc de			;5449	13		.
	jr nz,l5461h		;544a	20 15		  .
	djnz l5446h		;544c	10 f8		. .
l544eh:
	ld hl,00000h		;544e	21 00 00	! . .
	inc hl			;5451	23		#
	inc hl			;5452	23		#
	inc h			;5453	24		$
	ld (l544eh+1),hl	;5454	22 4f 54	" O T
	call sub_571bh		;5457	cd 1b 57	. . W
	ld hl,053ech		;545a	21 ec 53	! . S
	dec (hl)		;545d	35		5
	jr nz,l5406h		;545e	20 a6		  .
	ret			;5460	c9		.
l5461h:
	call sub_5492h		;5461	cd 92 54	. . T
	ld a,03ah		;5464	3e 3a		> :
	call sub_585ah		;5466	cd 5a 58	. Z X
	jr z,l544eh		;5469	28 e3		( .
	jr l5406h		;546b	18 99		. .
sub_546dh:
	push hl			;546d	e5		.
	inc hl			;546e	23		#
	ld a,(hl)		;546f	7e		~
	cp 006h			;5470	fe 06		. .
	inc hl			;5472	23		#
	jr nz,l5479h		;5473	20 04		  .
	set 0,(ix+000h)		;5475	dd cb 00 c6	. . . .
l5479h:
	call sub_5c8eh		;5479	cd 8e 5c	. . \
	ld a,040h		;547c	3e 40		> @
	ld (057ebh),a		;547e	32 eb 57	2 . W
	call sub_57ceh		;5481	cd ce 57	. . W
	res 0,(ix+000h)		;5484	dd cb 00 86	. . . .
	pop hl			;5488	e1		.
	ret z			;5489	c8		.
	call sub_585ah		;548a	cd 5a 58	. Z X
	jr nz,sub_546dh		;548d	20 de		  .
	or 0ffh			;548f	f6 ff		. .
	ret			;5491	c9		.
sub_5492h:
	push hl			;5492	e5		.
	ld hl,(l5b21h)		;5493	2a 21 5b	* ! [
	dec hl			;5496	2b		+
	ld (l5b21h),hl		;5497	22 21 5b	" ! [
	pop hl			;549a	e1		.
	ret			;549b	c9		.
l549ch:
	pop hl			;549c	e1		.
	call sub_5324h		;549d	cd 24 53	. $ S
	ld a,(l5996h)		;54a0	3a 96 59	: . Y
	bit 3,a			;54a3	cb 5f		. _
	jp nz,l552dh		;54a5	c2 2d 55	. - U
	bit 2,a			;54a8	cb 57		. W
	jr z,l54d4h		;54aa	28 28		( (
	ld a,005h		;54ac	3e 05		> .
	call sub_568dh		;54ae	cd 8d 56	. . V
	call sub_5535h		;54b1	cd 35 55	. 5 U
	ld hl,(l5af1h)		;54b4	2a f1 5a	* . Z
	ld (l5b23h),hl		;54b7	22 23 5b	" # [
	ld a,(l5aedh)		;54ba	3a ed 5a	: . Z
	ld (l5b1fh),a		;54bd	32 1f 5b	2 . [
	ld de,l5b17h		;54c0	11 17 5b	. . [
	call 04428h		;54c3	cd 28 44	. ( D
	ld hl,04317h		;54c6	21 17 43	! . C
	ld (hl),005h		;54c9	36 05		6 .
l54cbh:
	jp nz,l521ah		;54cb	c2 1a 52	. . R
l54ceh:
	ld hl,0402dh		;54ce	21 2d 40	! - @
	jp l5222h		;54d1	c3 22 52	. " R
l54d4h:
	jp 0501ch		;54d4	c3 1c 50	. . P
	ld de,(l59c1h)		;54d7	ed 5b c1 59	. [ . Y
	call sub_5784h		;54db	cd 84 57	. . W
	ld bc,(l5992h+2)	;54de	ed 4b 94 59	. K . Y
	bit 1,c			;54e2	cb 49		. I
	jr nz,l552dh		;54e4	20 47		  G
	call sub_56f9h		;54e6	cd f9 56	. . V
	bit 5,b			;54e9	cb 68		. h
	jr z,l54f3h		;54eb	28 06		( .
	ld hl,(l5981h)		;54ed	2a 81 59	* . Y
	ld (042ceh),hl		;54f0	22 ce 42	" . B
l54f3h:
	ld a,c			;54f3	79		y
	and 00ch		;54f4	e6 0c		. .
	ld bc,00010h		;54f6	01 10 00	. . .
	ld de,042d0h		;54f9	11 d0 42	. . B
	ld hl,l5983h		;54fc	21 83 59	! . Y
	jr nz,l5508h		;54ff	20 07		  .
	ld hl,l598bh		;5501	21 8b 59	! . Y
	ld e,0d8h		;5504	1e d8		. .
	ld c,008h		;5506	0e 08		. .
l5508h:
	ldir			;5508	ed b0		. .
	ld hl,(l59d1h)		;550a	2a d1 59	* . Y
	ld de,(l59c3h)		;550d	ed 5b c3 59	. [ . Y
	or a			;5511	b7		.
	sbc hl,de		;5512	ed 52		. R
	ex de,hl		;5514	eb		.
	jr c,l5528h		;5515	38 11		8 .
	jr z,l5528h		;5517	28 0f		( .
	ld hl,(l59c3h)		;5519	2a c3 59	* . Y
	ld a,(l59bch)		;551c	3a bc 59	: . Y
	call 04cb4h		;551f	cd b4 4c	. . L
	ld h,042h		;5522	26 42		& B
	ld c,a			;5524	4f		O
	call sub_5762h		;5525	cd 62 57	. b W
l5528h:
	call 0491fh		;5528	cd 1f 49	. . I
	jr nz,l54cbh		;552b	20 9e		  .
l552dh:
	ld hl,l5a1fh		;552d	21 1f 5a	! . Z
	call 04467h		;5530	cd 67 44	. g D
	jr l54ceh		;5533	18 99		. .
sub_5535h:
	ld hl,l5956h		;5535	21 56 59	! V Y
sub_5538h:
	call sub_5585h		;5538	cd 85 55	. . U
	inc hl			;553b	23		#
	inc hl			;553c	23		#
	ld e,(hl)		;553d	5e		^
	inc hl			;553e	23		#
	ld d,(hl)		;553f	56		V
	push de			;5540	d5		.
	pop ix			;5541	dd e1		. .
	ld a,(de)		;5543	1a		.
	bit 7,a			;5544	cb 7f		. .
	ret nz			;5546	c0		.
	ld b,000h		;5547	06 00		. .
	ld a,017h		;5549	3e 17		> .
	cp e			;554b	bb		.
	jr z,l5556h		;554c	28 08		( .
	call 04424h		;554e	cd 24 44	. $ D
	jr z,l5570h		;5551	28 1d		( .
l5553h:
	jp l521ah		;5553	c3 1a 52	. . R
l5556h:
	call 04420h		;5556	cd 20 44	.   D
	jr nz,l5553h		;5559	20 f8		  .
	ld de,(l5aebh)		;555b	ed 5b eb 5a	. [ . Z
	ld hl,(l5b1dh)		;555f	2a 1d 5b	* . [
	rst 18h			;5562	df		.
	jr nz,l5570h		;5563	20 0b		  .
	ld hl,l5a24h		;5565	21 24 5a	! $ Z
	ld a,(l5940h)		;5568	3a 40 59	: @ Y
	cp 006h			;556b	fe 06		. .
	jp c,l5243h		;556d	da 43 52	. C R
l5570h:
	ld hl,(l593eh)		;5570	2a 3e 59	* > Y
	ld a,(ix+006h)		;5573	dd 7e 06	. ~ .
	ld (hl),a		;5576	77		w
	ret			;5577	c9		.
sub_5578h:
	ld hl,l594ch		;5578	21 4c 59	! L Y
	jr sub_5585h		;557b	18 08		. .
sub_557dh:
	ld hl,l5956h		;557d	21 56 59	! V Y
	jr sub_5585h		;5580	18 03		. .
sub_5582h:
	ld hl,l5942h		;5582	21 42 59	! B Y
sub_5585h:
	ld (l593eh),hl		;5585	22 3e 59	" > Y
	ld a,0ffh		;5588	3e ff		> .
	ld (04930h),a		;558a	32 30 49	2 0 I
	ld a,(hl)		;558d	7e		~
	inc a			;558e	3c		<
	ret z			;558f	c8		.
	push hl			;5590	e5		.
	push de			;5591	d5		.
	push bc			;5592	c5		.
	ld a,(l593bh)		;5593	3a 3b 59	: ; Y
	bit 7,a			;5596	cb 7f		. .
	ld b,000h		;5598	06 00		. .
	call nz,sub_5658h	;559a	c4 58 56	. X V
	ld c,(hl)		;559d	4e		N
	inc hl			;559e	23		#
	ld b,(hl)		;559f	46		F
	ld de,00007h		;55a0	11 07 00	. . .
	add hl,de		;55a3	19		.
	ld e,(hl)		;55a4	5e		^
	inc hl			;55a5	23		#
	ld d,(hl)		;55a6	56		V
	ld hl,l5940h		;55a7	21 40 59	! @ Y
	ld a,(hl)		;55aa	7e		~
	and b			;55ab	a0		.
	ld a,(hl)		;55ac	7e		~
	inc hl			;55ad	23		#
	jr z,l55b5h		;55ae	28 05		( .
	xor b			;55b0	a8		.
	xor 0ffh		;55b1	ee ff		. .
	and (hl)		;55b3	a6		.
	ld (hl),a		;55b4	77		w
l55b5h:
	ld a,c			;55b5	79		y
	call 04776h		;55b6	cd 76 47	. v G
	jp nz,l521ah		;55b9	c2 1a 52	. . R
	push hl			;55bc	e5		.
	ld a,(hl)		;55bd	7e		~
	and b			;55be	a0		.
	jr nz,l55ech		;55bf	20 2b		  +
l55c1h:
	ld hl,l59eeh		;55c1	21 ee 59	! . Y
	call 04467h		;55c4	cd 67 44	. g D
	ld h,d			;55c7	62		b
	ld l,e			;55c8	6b		k
	call 04467h		;55c9	cd 67 44	. g D
	ld a,c			;55cc	79		y
	add a,030h		;55cd	c6 30		. 0
	ld (05a1dh),a		;55cf	32 1d 5a	2 . Z
	ld hl,l5a02h		;55d2	21 02 5a	! . Z
	call 04467h		;55d5	cd 67 44	. g D
	push bc			;55d8	c5		.
	ld bc,08000h		;55d9	01 00 80	. . .
	push de			;55dc	d5		.
	call 04cedh		;55dd	cd ed 4c	. . L
	pop de			;55e0	d1		.
	pop bc			;55e1	c1		.
l55e2h:
	call sub_572bh		;55e2	cd 2b 57	. + W
	cp 00dh			;55e5	fe 0d		. .
	jr nz,l55e2h		;55e7	20 f9		  .
	call sub_5881h		;55e9	cd 81 58	. . X
l55ech:
	ld a,c			;55ec	79		y
	call 047ech		;55ed	cd ec 47	. . G
	jr nz,l55c1h		;55f0	20 cf		  .
	pop hl			;55f2	e1		.
	ld a,(hl)		;55f3	7e		~
	or b			;55f4	b0		.
	ld (hl),a		;55f5	77		w
	ld hl,l5b57h		;55f6	21 57 5b	! W [
	jr l563bh		;55f9	18 40		. @
l55fbh:
	push hl			;55fb	e5		.
	jr z,l560dh		;55fc	28 0f		( .
	ld a,(04317h)		;55fe	3a 17 43	: . C
	cp c			;5601	b9		.
	jr z,l560dh		;5602	28 09		( .
	bit 5,(hl)		;5604	cb 6e		. n
	jr z,l5637h		;5606	28 2f		( /
l5608h:
	ld a,033h		;5608	3e 33		> 3
	jp l521ah		;560a	c3 1a 52	. . R
l560dh:
	ld a,(0430ch)		;560d	3a 0c 43	: . C
	xor (hl)		;5610	ae		.
	and 020h		;5611	e6 20		.  
	jr z,l5637h		;5613	28 22		( "
	xor (hl)		;5615	ae		.
	ld (hl),a		;5616	77		w
	inc hl			;5617	23		#
	ld a,(hl)		;5618	7e		~
	inc hl			;5619	23		#
	ld h,(hl)		;561a	66		f
	ld l,a			;561b	6f		o
	jr l562fh		;561c	18 11		. .
l561eh:
	ld a,(hl)		;561e	7e		~
	or a			;561f	b7		.
	ld b,a			;5620	47		G
	inc hl			;5621	23		#
	ex de,hl		;5622	eb		.
	jr z,l562fh		;5623	28 0a		( .
	ex de,hl		;5625	eb		.
l5626h:
	ld c,(hl)		;5626	4e		N
	ld a,(de)		;5627	1a		.
	ld (hl),a		;5628	77		w
	ld a,c			;5629	79		y
	ld (de),a		;562a	12		.
	inc hl			;562b	23		#
	inc de			;562c	13		.
	djnz l5626h		;562d	10 f7		. .
l562fh:
	ld e,(hl)		;562f	5e		^
	inc hl			;5630	23		#
	ld d,(hl)		;5631	56		V
	inc hl			;5632	23		#
	ld a,d			;5633	7a		z
	or e			;5634	b3		.
	jr nz,l561eh		;5635	20 e7		  .
l5637h:
	pop hl			;5637	e1		.
	inc hl			;5638	23		#
	inc hl			;5639	23		#
	inc hl			;563a	23		#
l563bh:
	ld a,(hl)		;563b	7e		~
	cp 002h			;563c	fe 02		. .
	ld c,a			;563e	4f		O
	inc hl			;563f	23		#
	jr nc,l55fbh		;5640	30 b9		0 .
	pop bc			;5642	c1		.
	pop de			;5643	d1		.
	pop hl			;5644	e1		.
	ret			;5645	c9		.
sub_5646h:
	ld hl,l5942h		;5646	21 42 59	! B Y
	ld c,003h		;5649	0e 03		. .
l564bh:
	ld a,(hl)		;564b	7e		~
	inc a			;564c	3c		<
	call nz,sub_5658h	;564d	c4 58 56	. X V
	ld de,0000ah		;5650	11 0a 00	. . .
	add hl,de		;5653	19		.
	dec c			;5654	0d		.
	jr nz,l564bh		;5655	20 f4		  .
	ret			;5657	c9		.
sub_5658h:
	ld a,(hl)		;5658	7e		~
	push hl			;5659	e5		.
	push de			;565a	d5		.
	call 04776h		;565b	cd 76 47	. v G
	jr nz,l5684h		;565e	20 24		  $
	ld de,00004h		;5660	11 04 00	. . .
	bit 0,b			;5663	cb 40		. @
	jr z,l5669h		;5665	28 02		( .
	inc de			;5667	13		.
	inc de			;5668	13		.
l5669h:
	add hl,de		;5669	19		.
	ld e,(hl)		;566a	5e		^
	inc hl			;566b	23		#
	ld d,(hl)		;566c	56		V
	ld hl,(04399h)		;566d	2a 99 43	* . C
	bit 1,b			;5670	cb 48		. H
	jr nz,l5675h		;5672	20 01		  .
	ex de,hl		;5674	eb		.
l5675h:
	push bc			;5675	c5		.
	ld bc,0000ah		;5676	01 0a 00	. . .
	ldir			;5679	ed b0		. .
	pop bc			;567b	c1		.
	call 04773h		;567c	cd 73 47	. s G
	jr nz,l5684h		;567f	20 03		  .
l5681h:
	pop de			;5681	d1		.
	pop hl			;5682	e1		.
	ret			;5683	c9		.
l5684h:
	bit 2,b			;5684	cb 50		. P
	jr nz,l5681h		;5686	20 f9		  .
	jp l521ah		;5688	c3 1a 52	. . R
sub_568bh:
	ld a,004h		;568b	3e 04		> .
sub_568dh:
	ld c,0ffh		;568d	0e ff		. .
	push af			;568f	f5		.
	call sub_5582h		;5690	cd 82 55	. . U
	pop af			;5693	f1		.
	or a			;5694	b7		.
	ret z			;5695	c8		.
	or 0e0h			;5696	f6 e0		. .
	rst 28h			;5698	ef		.
sub_5699h:
	inc hl			;5699	23		#
	inc hl			;569a	23		#
	inc hl			;569b	23		#
	ld de,(l5d14h)		;569c	ed 5b 14 5d	. [ . ]
	rst 18h			;56a0	df		.
	ret			;56a1	c9		.
sub_56a2h:
	call sub_5699h		;56a2	cd 99 56	. . V
	ret z			;56a5	c8		.
sub_56a6h:
	bit 5,(hl)		;56a6	cb 6e		. n
	jr z,sub_56a2h		;56a8	28 f8		( .
	ld (l52b9h+1),hl	;56aa	22 ba 52	" . R
	inc hl			;56ad	23		#
	ld c,(hl)		;56ae	4e		N
	inc hl			;56af	23		#
	ld a,(hl)		;56b0	7e		~
	ld (052d2h),a		;56b1	32 d2 52	2 . R
	ld ix,l5ae5h		;56b4	dd 21 e5 5a	. ! . Z
	ld a,c			;56b8	79		y
sub_56b9h:
	ld (l4f56h),a		;56b9	32 56 4f	2 V O
	call sub_56f4h		;56bc	cd f4 56	. . V
	xor a			;56bf	af		.
	ld (l4f5eh),a		;56c0	32 5e 4f	2 ^ O
	inc hl			;56c3	23		#
	call sub_4e21h		;56c4	cd 21 4e	. ! N
	ex de,hl		;56c7	eb		.
	ld a,e			;56c8	7b		{
	add a,010h		;56c9	c6 10		. .
	ld e,a			;56cb	5f		_
	call sub_4f2eh		;56cc	cd 2e 4f	. . O
	jr nz,l56feh		;56cf	20 2d		  -
	or 0ffh			;56d1	f6 ff		. .
	ret			;56d3	c9		.
	ld l,a			;56d4	6f		o
	ld h,000h		;56d5	26 00		& .
	ld a,(iy-072h)		;56d7	fd 7e 8e	. ~ .
	jp 04c94h		;56da	c3 94 4c	. . L
sub_56ddh:
	call 0494bh		;56dd	cd 4b 49	. K I
	jr l56fdh		;56e0	18 1b		. .
sub_56e2h:
	push af			;56e2	f5		.
	and 01fh		;56e3	e6 1f		. .
	inc a			;56e5	3c		<
	inc a			;56e6	3c		<
	ld hl,sub_570dh+1	;56e7	21 0e 57	! . W
	cp (hl)			;56ea	be		.
	call nz,sub_570dh	;56eb	c4 0d 57	. . W
	pop af			;56ee	f1		.
sub_56efh:
	call 0492fh		;56ef	cd 2f 49	. / I
	jr l56fdh		;56f2	18 09		. .
sub_56f4h:
	call 04936h		;56f4	cd 36 49	. 6 I
	jr l56fdh		;56f7	18 04		. .
sub_56f9h:
	xor a			;56f9	af		.
sub_56fah:
	call 0490ah		;56fa	cd 0a 49	. . I
l56fdh:
	ret z			;56fd	c8		.
l56feh:
	jp l521ah		;56fe	c3 1a 52	. . R
sub_5701h:
	call 04922h		;5701	cd 22 49	. " I
	jr l56fdh		;5704	18 f7		. .
sub_5706h:
	ld a,(04930h)		;5706	3a 30 49	: 0 I
	ld (sub_570dh+1),a	;5709	32 0e 57	2 . W
	ret			;570c	c9		.
sub_570dh:
	ld a,0ffh		;570d	3e ff		> .
	inc a			;570f	3c		<
	ret z			;5710	c8		.
sub_5711h:
	ld a,0ffh		;5711	3e ff		> .
	ld (sub_570dh+1),a	;5713	32 0e 57	2 . W
	call 0491fh		;5716	cd 1f 49	. . I
	jr l56fdh		;5719	18 e2		. .
sub_571bh:
	call 0022ch		;571b	cd 2c 02	. , .
	nop			;571e	00		.
	nop			;571f	00		.
	nop			;5720	00		.
	nop			;5721	00		.
	nop			;5722	00		.
	nop			;5723	00		.
	nop			;5724	00		.
	nop			;5725	00		.
	nop			;5726	00		.
	nop			;5727	00		.
	nop			;5728	00		.
	jr l5733h		;5729	18 08		. .
sub_572bh:
	push de			;572b	d5		.
	call 0002bh		;572c	cd 2b 00	. + .
	call 045b5h		;572f	cd b5 45	. . E
	pop de			;5732	d1		.
l5733h:
	push af			;5733	f5		.
	ld a,(l5995h)		;5734	3a 95 59	: . Y
	bit 7,a			;5737	cb 7f		. .
	jr nz,l574fh		;5739	20 14		  .
	ld a,(03840h)		;573b	3a 40 38	: @ 8
	and 048h		;573e	e6 48		. H
	jr z,l574fh		;5740	28 0d		( .
l5742h:
	ld a,(03840h)		;5742	3a 40 38	: @ 8
	and 009h		;5745	e6 09		. .
	jr z,l5742h		;5747	28 f9		( .
	rrca			;5749	0f		.
	ld a,039h		;574a	3e 39		> 9
	jp nc,l521ah		;574c	d2 1a 52	. . R
l574fh:
	pop af			;574f	f1		.
	ret			;5750	c9		.
l5751h:
	ld a,l			;5751	7d		}
	cp 060h			;5752	fe 60		. `
	pop bc			;5754	c1		.
	pop de			;5755	d1		.
	pop hl			;5756	e1		.
	ret nc			;5757	d0		.
	ld a,(l59c6h)		;5758	3a c6 59	: . Y
	cp 061h			;575b	fe 61		. a
	ret nc			;575d	d0		.
	ld a,l			;575e	7d		}
	add a,060h		;575f	c6 60		. `
	ld l,a			;5761	6f		o
sub_5762h:
	push hl			;5762	e5		.
	push de			;5763	d5		.
	push bc			;5764	c5		.
l5765h:
	ld a,l			;5765	7d		}
	cp 0c0h			;5766	fe c0		. .
	call nc,sub_5240h	;5768	d4 40 52	. @ R
l576bh:
	inc c			;576b	0c		.
	ld b,c			;576c	41		A
	ld a,07fh		;576d	3e 7f		> .
l576fh:
	rlca			;576f	07		.
	djnz l576fh		;5770	10 fd		. .
	and (hl)		;5772	a6		.
	ld (hl),a		;5773	77		w
	dec de			;5774	1b		.
	ld a,d			;5775	7a		z
	or e			;5776	b3		.
	jr z,l5751h		;5777	28 d8		( .
	ld a,(l59cah)		;5779	3a ca 59	: . Y
	cp c			;577c	b9		.
	jr nz,l576bh		;577d	20 ec		  .
	ld c,000h		;577f	0e 00		. .
	inc l			;5781	2c		,
	jr l5765h		;5782	18 e1		. .
sub_5784h:
	ld a,(0436dh)		;5784	3a 6d 43	: m C
	bit 3,a			;5787	cb 5f		. _
	ret z			;5789	c8		.
	ld a,020h		;578a	3e 20		>  
	ld (057ebh),a		;578c	32 eb 57	2 . W
	ld (l5b21h),de		;578f	ed 53 21 5b	. S ! [
	ld hl,04200h		;5793	21 00 42	! . B
	ld (l5b1ah),hl		;5796	22 1a 5b	" . [
	ld hl,(l59cfh)		;5799	2a cf 59	* . Y
	or a			;579c	b7		.
	sbc hl,de		;579d	ed 52		. R
	ret c			;579f	d8		.
	ret z			;57a0	c8		.
	push hl			;57a1	e5		.
	ld hl,l5a79h		;57a2	21 79 5a	! y Z
	call sub_587eh		;57a5	cd 7e 58	. ~ X
	ld hl,0ffffh		;57a8	21 ff ff	! . .
	ld (l5b23h),hl		;57ab	22 23 5b	" # [
	set 1,(ix+000h)		;57ae	dd cb 00 ce	. . . .
	pop hl			;57b2	e1		.
l57b3h:
	call sub_57c8h		;57b3	cd c8 57	. . W
	jr z,l57bah		;57b6	28 02		( .
	cp 006h			;57b8	fe 06		. .
l57bah:
	call nz,sub_585ah	;57ba	c4 5a 58	. Z X
	jr nz,l57b3h		;57bd	20 f4		  .
	dec hl			;57bf	2b		+
	call sub_571bh		;57c0	cd 1b 57	. . W
	ld a,h			;57c3	7c		|
	or l			;57c4	b5		.
	jr nz,l57b3h		;57c5	20 ec		  .
	ret			;57c7	c9		.
sub_57c8h:
	push ix			;57c8	dd e5		. .
	pop de			;57ca	d1		.
	jp 04436h		;57cb	c3 36 44	. 6 D
sub_57ceh:
	push ix			;57ce	dd e5		. .
	pop de			;57d0	d1		.
	jp l5ce4h		;57d1	c3 e4 5c	. . \
sub_57d4h:
	push ix			;57d4	dd e5		. .
	pop de			;57d6	d1		.
	jp 0443ch		;57d7	c3 3c 44	. < D
sub_57dah:
	push hl			;57da	e5		.
	push de			;57db	d5		.
	push bc			;57dc	c5		.
	push af			;57dd	f5		.
	call sub_5881h		;57de	cd 81 58	. . X
	ld hl,l59d3h		;57e1	21 d3 59	! . Y
	call 04467h		;57e4	cd 67 44	. g D
	ld hl,l5a67h		;57e7	21 67 5a	! g Z
	ld b,000h		;57ea	06 00		. .
	bit 6,b			;57ec	cb 70		. p
	jr z,l57f3h		;57ee	28 03		( .
	ld hl,l5a6eh		;57f0	21 6e 5a	! n Z
l57f3h:
	bit 5,b			;57f3	cb 68		. h
	jr z,l57fah		;57f5	28 03		( .
	ld hl,l5a79h		;57f7	21 79 5a	! y Z
l57fah:
	call 04467h		;57fa	cd 67 44	. g D
	ld hl,l5a44h		;57fd	21 44 5a	! D Z
	ld de,(l5b21h)		;5800	ed 5b 21 5b	. [ ! [
	bit 7,b			;5804	cb 78		. x
	jr z,l580fh		;5806	28 07		( .
	ld hl,l5a3ch		;5808	21 3c 5a	! < Z
	ld de,(l5aefh)		;580b	ed 5b ef 5a	. [ . Z
l580fh:
	call 04467h		;580f	cd 67 44	. g D
	ld hl,l5a5eh		;5812	21 5e 5a	! ^ Z
	call 04467h		;5815	cd 67 44	. g D
	call sub_5909h		;5818	cd 09 59	. . Y
	call sub_5881h		;581b	cd 81 58	. . X
	ld a,(l5996h)		;581e	3a 96 59	: . Y
	bit 2,a			;5821	cb 57		. W
	jp nz,l521eh		;5823	c2 1e 52	. . R
	call sub_5868h		;5826	cd 68 58	. h X
	pop bc			;5829	c1		.
	ld hl,(l593eh)		;582a	2a 3e 59	* > Y
	ld a,(04317h)		;582d	3a 17 43	: . C
	ld c,a			;5830	4f		O
	push hl			;5831	e5		.
	push bc			;5832	c5		.
	call sub_5582h		;5833	cd 82 55	. . U
	ld a,b			;5836	78		x
	call sub_584ah		;5837	cd 4a 58	. J X
	pop bc			;583a	c1		.
	pop de			;583b	d1		.
	push af			;583c	f5		.
	ld a,c			;583d	79		y
	call sub_568dh		;583e	cd 8d 56	. . V
	ex de,hl		;5841	eb		.
	call sub_5585h		;5842	cd 85 55	. . U
	pop af			;5845	f1		.
	pop bc			;5846	c1		.
	pop de			;5847	d1		.
	pop hl			;5848	e1		.
	ret			;5849	c9		.
sub_584ah:
	ld hl,l5995h		;584a	21 95 59	! . Y
	bit 7,(hl)		;584d	cb 7e		. ~
	jp nz,l521ah		;584f	c2 1a 52	. . R
	or 0c0h			;5852	f6 c0		. .
	call 04409h		;5854	cd 09 44	. . D
	jp l58c8h		;5857	c3 c8 58	. . X
sub_585ah:
	call sub_57dah		;585a	cd da 57	. . W
	ret nz			;585d	c0		.
sub_585eh:
	inc (ix+00ah)		;585e	dd 34 0a	. 4 .
	jr nz,l5866h		;5861	20 03		  .
	inc (ix+00bh)		;5863	dd 34 0b	. 4 .
l5866h:
	xor a			;5866	af		.
	ret			;5867	c9		.
sub_5868h:
	xor a			;5868	af		.
	or 000h			;5869	f6 00		. .
	ret z			;586b	c8		.
	ld hl,l59e0h		;586c	21 e0 59	! . Y
sub_586fh:
	call 04467h		;586f	cd 67 44	. g D
	call sub_56ddh		;5872	cd dd 56	. . V
	call sub_58a0h		;5875	cd a0 58	. . X
	call sub_5881h		;5878	cd 81 58	. . X
	or 0ffh			;587b	f6 ff		. .
	ret			;587d	c9		.
sub_587eh:
	call 04467h		;587e	cd 67 44	. g D
sub_5881h:
	ld a,00dh		;5881	3e 0d		> .
	jp l58bdh		;5883	c3 bd 58	. . X
l5886h:
	ld a,(hl)		;5886	7e		~
	cp 020h			;5887	fe 20		.  
	inc hl			;5889	23		#
	jr c,l5890h		;588a	38 04		8 .
	cp 080h			;588c	fe 80		. .
	jr c,l5892h		;588e	38 02		8 .
l5890h:
	ld a,020h		;5890	3e 20		>  
l5892h:
	call l58bdh		;5892	cd bd 58	. . X
	djnz l5886h		;5895	10 ef		. .
	ret			;5897	c9		.
l5898h:
	ld a,020h		;5898	3e 20		>  
	call l58bdh		;589a	cd bd 58	. . X
	djnz l5898h		;589d	10 f9		. .
	ret			;589f	c9		.
sub_58a0h:
	ld a,l			;58a0	7d		}
	add a,005h		;58a1	c6 05		. .
	ld l,a			;58a3	6f		o
	ld b,008h		;58a4	06 08		. .
	call sub_58b3h		;58a6	cd b3 58	. . X
	ld a,(hl)		;58a9	7e		~
	cp 020h			;58aa	fe 20		.  
	ld b,003h		;58ac	06 03		. .
	ld a,02fh		;58ae	3e 2f		> /
	call nz,l58bdh		;58b0	c4 bd 58	. . X
sub_58b3h:
	ld a,(hl)		;58b3	7e		~
	cp 020h			;58b4	fe 20		.  
	inc hl			;58b6	23		#
	call nz,l58bdh		;58b7	c4 bd 58	. . X
	djnz sub_58b3h		;58ba	10 f7		. .
	ret			;58bc	c9		.
l58bdh:
	push de			;58bd	d5		.
	push af			;58be	f5		.
	call 00033h		;58bf	cd 33 00	. 3 .
	pop af			;58c2	f1		.
	pop de			;58c3	d1		.
	ret			;58c4	c9		.
	call 04467h		;58c5	cd 67 44	. g D
l58c8h:
	ld a,(l5995h)		;58c8	3a 95 59	: . Y
	bit 7,a			;58cb	cb 7f		. .
	jp nz,l5249h		;58cd	c2 49 52	. I R
	ld hl,l5a84h		;58d0	21 84 5a	! . Z
	call sub_58e4h		;58d3	cd e4 58	. . X
	cp 001h			;58d6	fe 01		. .
	ret nc			;58d8	d0		.
	ld a,039h		;58d9	3e 39		> 9
	jp l521ah		;58db	c3 1a 52	. . R
sub_58deh:
	call 04467h		;58de	cd 67 44	. g D
	ld hl,l5ab3h		;58e1	21 b3 5a	! . Z
sub_58e4h:
	push bc			;58e4	c5		.
	push hl			;58e5	e5		.
l58e6h:
	ld a,(hl)		;58e6	7e		~
	or a			;58e7	b7		.
	inc hl			;58e8	23		#
	jr nz,l58e6h		;58e9	20 fb		  .
	call 04467h		;58eb	cd 67 44	. g D
l58eeh:
	call sub_572bh		;58ee	cd 2b 57	. + W
	pop hl			;58f1	e1		.
	ld c,0ffh		;58f2	0e ff		. .
	push hl			;58f4	e5		.
l58f5h:
	inc (hl)		;58f5	34		4
	inc c			;58f6	0c		.
	dec (hl)		;58f7	35		5
	jr z,l58eeh		;58f8	28 f4		( .
	cp (hl)			;58fa	be		.
	inc hl			;58fb	23		#
	jr nz,l58f5h		;58fc	20 f7		  .
	call l58bdh		;58fe	cd bd 58	. . X
	call sub_5881h		;5901	cd 81 58	. . X
	ld a,c			;5904	79		y
	or a			;5905	b7		.
	pop hl			;5906	e1		.
	pop bc			;5907	c1		.
	ret			;5908	c9		.
sub_5909h:
	ld bc,00400h		;5909	01 00 04	. . .
	ld hl,l5933h		;590c	21 33 59	! 3 Y
l590fh:
	push bc			;590f	c5		.
	ld c,(hl)		;5910	4e		N
	inc hl			;5911	23		#
	ld b,(hl)		;5912	46		F
	inc hl			;5913	23		#
	ex de,hl		;5914	eb		.
	ld a,02fh		;5915	3e 2f		> /
l5917h:
	inc a			;5917	3c		<
	add hl,bc		;5918	09		.
	jr c,l5917h		;5919	38 fc		8 .
	sbc hl,bc		;591b	ed 42		. B
	pop bc			;591d	c1		.
	ex de,hl		;591e	eb		.
	cp 030h			;591f	fe 30		. 0
	jr nz,l5927h		;5921	20 04		  .
	inc c			;5923	0c		.
	dec c			;5924	0d		.
	jr z,l592bh		;5925	28 04		( .
l5927h:
	inc c			;5927	0c		.
	call l58bdh		;5928	cd bd 58	. . X
l592bh:
	djnz l590fh		;592b	10 e2		. .
	ld a,e			;592d	7b		{
	add a,030h		;592e	c6 30		. 0
	jp l58bdh		;5930	c3 bd 58	. . X
l5933h:
	ret p			;5933	f0		.
	ret c			;5934	d8		.
	jr l5933h		;5935	18 fc		. .
	sbc a,h			;5937	9c		.
	rst 38h			;5938	ff		.
	or 0ffh			;5939	f6 ff		. .
l593bh:
	nop			;593b	00		.
l593ch:
	rst 38h			;593c	ff		.
	ld l,a			;593d	6f		o
l593eh:
	ld b,d			;593e	42		B
	ld e,c			;593f	59		Y
; --- COPY drive-slot status bytes: 5940h = which slots need
; --- attention, 5941h = which are still satisfied. Checked at 55AAh/55BDh.
l5940h:
	nop			;5940	00		.
	rlca			;5941	07		.
; === SLOT 1 of 3: SYSTEM diskette. drive byte (00h stock) / mask 01h
; === / +8 -> 5A51h "===> System ". PATCHED to 05h (sysvol) by
; === run-hdboottest.sh -- see this file's header. Never FFh, so this
; === slot is verified on every COPY.
l5942h:
	nop			;5942	00		.
	ld bc,00000h		;5943	01 00 00	. . .
	sbc a,c			;5946	99		.
	ld e,c			;5947	59		Y
	sbc a,c			;5948	99		.
	ld e,c			;5949	59		Y
	ld d,c			;594a	51		Q
	ld e,d			;594b	5a		Z
; === SLOT 2 of 3: SOURCE ("Quelle"). drive FFh = unused until the
; === command line fills it in at 4D3Dh / sub_6437h. mask 02h.
l594ch:
	rst 38h			;594c	ff		.
	ld (bc),a		;594d	02		.
	push hl			;594e	e5		.
	ld e,d			;594f	5a		Z
	or a			;5950	b7		.
	ld e,c			;5951	59		Y
	and e			;5952	a3		.
	ld e,c			;5953	59		Y
	inc a			;5954	3c		<
	ld e,d			;5955	5a		Z
; === SLOT 3 of 3: DESTINATION ("Ziel"). drive FFh = unused until the
; === command line fills it in at 4D40h / sub_6437h. mask 04h.
l5956h:
	rst 38h			;5956	ff		.
	inc b			;5957	04		.
	rla			;5958	17		.
	ld e,e			;5959	5b		[
	push bc			;595a	c5		.
	ld e,c			;595b	59		Y
	xor l			;595c	ad		.
	ld e,c			;595d	59		Y
	ld b,h			;595e	44		D
	ld e,d			;595f	5a		Z
l5960h:
	jr nz,l5982h		;5960	20 20		   
	jr nz,l5984h		;5962	20 20		   
	jr nz,l5986h		;5964	20 20		   
	jr nz,$+34		;5966	20 20		   
l5968h:
	jr nz,$+34		;5968	20 20		   
	jr nz,l598ch		;596a	20 20		   
	jr nz,$+34		;596c	20 20		   
	jr nz,$+34		;596e	20 20		   
l5970h:
	jr nz,l5992h		;5970	20 20		   
	jr nz,$+34		;5972	20 20		   
	jr nz,l5996h		;5974	20 20		   
	jr nz,l5998h		;5976	20 20		   
l5978h:
	nop			;5978	00		.
	nop			;5979	00		.
l597ah:
	nop			;597a	00		.
	nop			;597b	00		.
l597ch:
	ex af,af'		;597c	08		.
l597dh:
	ex af,af'		;597d	08		.
l597eh:
	add a,d			;597e	82		.
	nop			;597f	00		.
	nop			;5980	00		.
l5981h:
	ld b,a			;5981	47		G
l5982h:
	adc a,h			;5982	8c		.
l5983h:
	ld b,a			;5983	47		G
l5984h:
	ld b,h			;5984	44		D
	ld c,a			;5985	4f		O
l5986h:
	ld d,e			;5986	53		S
	jr nz,l59bbh		;5987	20 32		  2
	ld l,034h		;5989	2e 34		. 4
l598bh:
	inc (hl)		;598b	34		4
l598ch:
	ld a,(0322eh)		;598c	3a 2e 32	: . 2
	ld a,(03a2eh)		;598f	3a 2e 3a	: . :
l5992h:
	ld a,(0000dh)		;5992	3a 0d 00	: . .
l5995h:
	nop			;5995	00		.
l5996h:
	nop			;5996	00		.
l5997h:
	nop			;5997	00		.
l5998h:
	nop			;5998	00		.
	nop			;5999	00		.
	nop			;599a	00		.
	nop			;599b	00		.
	nop			;599c	00		.
	nop			;599d	00		.
	nop			;599e	00		.
	nop			;599f	00		.
	nop			;59a0	00		.
	nop			;59a1	00		.
	nop			;59a2	00		.
	nop			;59a3	00		.
	nop			;59a4	00		.
	nop			;59a5	00		.
	nop			;59a6	00		.
	nop			;59a7	00		.
	nop			;59a8	00		.
	nop			;59a9	00		.
	nop			;59aa	00		.
	nop			;59ab	00		.
	nop			;59ac	00		.
	nop			;59ad	00		.
	nop			;59ae	00		.
	nop			;59af	00		.
	nop			;59b0	00		.
	nop			;59b1	00		.
	nop			;59b2	00		.
	nop			;59b3	00		.
	nop			;59b4	00		.
	nop			;59b5	00		.
	nop			;59b6	00		.
l59b7h:
	nop			;59b7	00		.
	nop			;59b8	00		.
l59b9h:
	nop			;59b9	00		.
	nop			;59ba	00		.
l59bbh:
	nop			;59bb	00		.
l59bch:
	nop			;59bc	00		.
	nop			;59bd	00		.
l59beh:
	nop			;59be	00		.
	nop			;59bf	00		.
l59c0h:
	nop			;59c0	00		.
l59c1h:
	nop			;59c1	00		.
	nop			;59c2	00		.
l59c3h:
	nop			;59c3	00		.
	nop			;59c4	00		.
l59c5h:
	nop			;59c5	00		.
l59c6h:
	nop			;59c6	00		.
l59c7h:
	nop			;59c7	00		.
l59c8h:
	nop			;59c8	00		.
l59c9h:
	nop			;59c9	00		.
l59cah:
	nop			;59ca	00		.
l59cbh:
	nop			;59cb	00		.
l59cch:
	nop			;59cc	00		.
l59cdh:
	nop			;59cd	00		.
l59ceh:
	nop			;59ce	00		.
l59cfh:
	nop			;59cf	00		.
	nop			;59d0	00		.
l59d1h:
	nop			;59d1	00		.
	nop			;59d2	00		.
l59d3h:
	ld b,(hl)		;59d3	46		F
	ld h,l			;59d4	65		e
	ld l,b			;59d5	68		h
	ld l,h			;59d6	6c		l
	ld h,l			;59d7	65		e
	ld (hl),d		;59d8	72		r
	jr nz,l5a3dh		;59d9	20 62		  b
	ld h,l			;59db	65		e
	ld l,c			;59dc	69		i
	ld l,l			;59dd	6d		m
	jr nz,$+5		;59de	20 03		  .
l59e0h:
	ld l,c			;59e0	69		i
	ld l,(hl)		;59e1	6e		n
	jr nz,l5a48h		;59e2	20 64		  d
	ld h,l			;59e4	65		e
	ld (hl),d		;59e5	72		r
	jr nz,l5a2ch		;59e6	20 44		  D
	ld h,c			;59e8	61		a
	ld (hl),h		;59e9	74		t
	ld h,l			;59ea	65		e
	ld l,c			;59eb	69		i
	jr nz,l59f1h		;59ec	20 03		  .
l59eeh:
	rlca			;59ee	07		.
	daa			;59ef	27		'
	ld b,l			;59f0	45		E
l59f1h:
	ld c,(hl)		;59f1	4e		N
	ld d,h			;59f2	54		T
	ld b,l			;59f3	45		E
	ld d,d			;59f4	52		R
	daa			;59f5	27		'
	ret nz			;59f6	c0		.
	ret nz			;59f7	c0		.
	ret nz			;59f8	c0		.
	ret nz			;59f9	c0		.
	inc l			;59fa	2c		,
	jr nz,l5a74h		;59fb	20 77		  w
	ld h,l			;59fd	65		e
	ld l,(hl)		;59fe	6e		n
	ld l,(hl)		;59ff	6e		n
	jr nz,l5a05h		;5a00	20 03		  .
l5a02h:
	ex af,af'		;5a02	08		.
	ld h,h			;5a03	64		d
	ld l,c			;5a04	69		i
l5a05h:
	ld (hl),e		;5a05	73		s
	ld l,e			;5a06	6b		k
	ld h,l			;5a07	65		e
	ld (hl),h		;5a08	74		t
	ld (hl),h		;5a09	74		t
	ld h,l			;5a0a	65		e
	jr nz,l5a76h		;5a0b	20 69		  i
	ld l,(hl)		;5a0d	6e		n
	jr nz,l5a5ch		;5a0e	20 4c		  L
	ld h,c			;5a10	61		a
	ld (hl),l		;5a11	75		u
	ld h,(hl)		;5a12	66		f
	ld (hl),a		;5a13	77		w
	ld h,l			;5a14	65		e
	ld (hl),d		;5a15	72		r
	ld l,e			;5a16	6b		k
	jr nz,l5a67h		;5a17	20 4e		  N
	ld (hl),d		;5a19	72		r
	ld l,020h		;5a1a	2e 20		.  
	jr nz,l5a4eh		;5a1c	20 30		  0
	dec c			;5a1e	0d		.
l5a1fh:
	ld b,l			;5a1f	45		E
	ld c,(hl)		;5a20	4e		N
	ld b,h			;5a21	44		D
	ld b,l			;5a22	45		E
	dec c			;5a23	0d		.
l5a24h:
	ld d,c			;5a24	51		Q
	ld (hl),l		;5a25	75		u
	ld h,l			;5a26	65		e
	ld l,h			;5a27	6c		l
	ld l,h			;5a28	6c		l
	ld h,l			;5a29	65		e
	jr nz,l5a52h		;5a2a	20 26		  &
l5a2ch:
	jr nz,l5a88h		;5a2c	20 5a		  Z
	ld l,c			;5a2e	69		i
	ld h,l			;5a2f	65		e
	ld l,h			;5a30	6c		l
	jr nz,l5a9ch		;5a31	20 69		  i
	ld h,h			;5a33	64		d
	ld h,l			;5a34	65		e
	ld l,(hl)		;5a35	6e		n
	ld (hl),h		;5a36	74		t
	ld l,c			;5a37	69		i
	ld (hl),e		;5a38	73		s
	ld h,e			;5a39	63		c
	ld l,b			;5a3a	68		h
	dec c			;5a3b	0d		.
l5a3ch:
	ld d,c			;5a3c	51		Q
l5a3dh:
	ld (hl),l		;5a3d	75		u
	ld h,l			;5a3e	65		e
	ld l,h			;5a3f	6c		l
	ld l,h			;5a40	6c		l
	ld h,l			;5a41	65		e
	inc bc			;5a42	03		.
	inc bc			;5a43	03		.
l5a44h:
	ld e,d			;5a44	5a		Z
	ld l,c			;5a45	69		i
	ld h,l			;5a46	65		e
	ld l,h			;5a47	6c		l
l5a48h:
	jr nz,l5a4dh		;5a48	20 03		  .
	ld bc,sub_5002h		;5a4a	01 02 50	. . P
l5a4dh:
	nop			;5a4d	00		.
l5a4eh:
	inc de			;5a4e	13		.
	ld bc,03d03h		;5a4f	01 03 3d	. . =
l5a52h:
	dec a			;5a52	3d		=
	dec a			;5a53	3d		=
	ld a,020h		;5a54	3e 20		>  
	ld d,e			;5a56	53		S
	ld a,c			;5a57	79		y
	ld (hl),e		;5a58	73		s
	ld (hl),h		;5a59	74		t
	ld h,l			;5a5a	65		e
	ld l,l			;5a5b	6d		m
l5a5ch:
	jr nz,l5a61h		;5a5c	20 03		  .
l5a5eh:
	ex af,af'		;5a5e	08		.
	ld (hl),e		;5a5f	73		s
	ld h,l			;5a60	65		e
l5a61h:
	ld l,e			;5a61	6b		k
	ld (hl),h		;5a62	74		t
	ld l,a			;5a63	6f		o
	ld (hl),d		;5a64	72		r
	jr nz,l5a6ah		;5a65	20 03		  .
l5a67h:
	ld c,h			;5a67	4c		L
	ld h,l			;5a68	65		e
	ld (hl),e		;5a69	73		s
l5a6ah:
	ld h,l			;5a6a	65		e
	ld l,(hl)		;5a6b	6e		n
	jr nz,l5a71h		;5a6c	20 03		  .
l5a6eh:
	ld d,e			;5a6e	53		S
	ld h,e			;5a6f	63		c
	ld l,b			;5a70	68		h
l5a71h:
	ld (hl),d		;5a71	72		r
	ld h,l			;5a72	65		e
	ld l,c			;5a73	69		i
l5a74h:
	ld h,d			;5a74	62		b
	ld h,l			;5a75	65		e
l5a76h:
	ld l,(hl)		;5a76	6e		n
	jr nz,l5a7ch		;5a77	20 03		  .
l5a79h:
	ld d,b			;5a79	50		P
	ld (hl),d		;5a7a	72		r
	ld a,l			;5a7b	7d		}
l5a7ch:
	ld h,(hl)		;5a7c	66		f
	ld h,l			;5a7d	65		e
	ld l,(hl)		;5a7e	6e		n
	jr nz,l5aa1h		;5a7f	20 20		   
	jr nz,$+34		;5a81	20 20		   
	inc bc			;5a83	03		.
l5a84h:
	ld b,c			;5a84	41		A
	ld b,(hl)		;5a85	46		F
	ld d,a			;5a86	57		W
	nop			;5a87	00		.
l5a88h:
	inc a			;5a88	3c		<
	ld b,c			;5a89	41		A
	ld a,062h		;5a8a	3e 62		> b
	ld h,d			;5a8c	62		b
	ld (hl),d		;5a8d	72		r
	ld (hl),l		;5a8e	75		u
	ld h,e			;5a8f	63		c
	ld l,b			;5a90	68		h
	inc l			;5a91	2c		,
	jr nz,l5ad0h		;5a92	20 3c		  <
	ld d,a			;5a94	57		W
	ld a,069h		;5a95	3e 69		> i
	ld h,l			;5a97	65		e
	ld h,h			;5a98	64		d
	ld h,l			;5a99	65		e
	ld (hl),d		;5a9a	72		r
	ld l,b			;5a9b	68		h
l5a9ch:
	ld l,a			;5a9c	6f		o
	ld l,h			;5a9d	6c		l
	ld (hl),l		;5a9e	75		u
	ld l,(hl)		;5a9f	6e		n
	ld h,a			;5aa0	67		g
l5aa1h:
	inc l			;5aa1	2c		,
	jr nz,l5ae0h		;5aa2	20 3c		  <
	ld b,(hl)		;5aa4	46		F
	ld a,06fh		;5aa5	3e 6f		> o
	ld (hl),d		;5aa7	72		r
	ld (hl),h		;5aa8	74		t
	ld h,(hl)		;5aa9	66		f
	ld h,c			;5aaa	61		a
	ld l,b			;5aab	68		h
	ld (hl),d		;5aac	72		r
	ld h,l			;5aad	65		e
	ld l,(hl)		;5aae	6e		n
	jr nz,l5ad1h		;5aaf	20 20		   
	jr nz,l5ac0h		;5ab1	20 0d		  .
l5ab3h:
	ld c,(hl)		;5ab3	4e		N
	ld c,d			;5ab4	4a		J
	nop			;5ab5	00		.
	jr nz,l5ae0h		;5ab6	20 28		  (
	ld c,d			;5ab8	4a		J
	ld h,c			;5ab9	61		a
	cpl			;5aba	2f		/
	ld c,(hl)		;5abb	4e		N
	ld h,l			;5abc	65		e
	ld l,c			;5abd	69		i
	ld l,(hl)		;5abe	6e		n
	add hl,hl		;5abf	29		)
l5ac0h:
	jr nz,l5ac5h		;5ac0	20 03		  .
l5ac2h:
	ld b,h			;5ac2	44		D
	ld l,c			;5ac3	69		i
	ld (hl),e		;5ac4	73		s
l5ac5h:
	ld l,e			;5ac5	6b		k
	ld h,l			;5ac6	65		e
	ld (hl),h		;5ac7	74		t
	ld (hl),h		;5ac8	74		t
	ld h,l			;5ac9	65		e
	cpl			;5aca	2f		/
	ld b,a			;5acb	47		G
	ld b,c			;5acc	41		A
	ld d,h			;5acd	54		T
	jr nz,l5b4ah		;5ace	20 7a		  z
l5ad0h:
	ld (hl),l		;5ad0	75		u
l5ad1h:
	jr nz,l5b3eh		;5ad1	20 6b		  k
	ld l,h			;5ad3	6c		l
	ld h,l			;5ad4	65		e
	ld l,c			;5ad5	69		i
	ld l,(hl)		;5ad6	6e		n
	dec c			;5ad7	0d		.
l5ad8h:
	ld b,h			;5ad8	44		D
	ld l,c			;5ad9	69		i
	ld (hl),e		;5ada	73		s
	ld l,e			;5adb	6b		k
	jr nz,l5b54h		;5adc	20 76		  v
	ld l,a			;5ade	6f		o
	ld l,h			;5adf	6c		l
l5ae0h:
	ld l,h			;5ae0	6c		l
	jr nz,l5b10h		;5ae1	20 2d		  -
	jr nz,l5ae8h		;5ae3	20 03		  .
l5ae5h:
	add a,d			;5ae5	82		.
	jr nz,l5ae8h		;5ae6	20 00		  .
l5ae8h:
	nop			;5ae8	00		.
	ld b,d			;5ae9	42		B
	nop			;5aea	00		.
l5aebh:
	nop			;5aeb	00		.
	rst 38h			;5aec	ff		.
l5aedh:
	nop			;5aed	00		.
	nop			;5aee	00		.
l5aefh:
	nop			;5aef	00		.
	nop			;5af0	00		.
l5af1h:
	ld e,(hl)		;5af1	5e		^
	ld bc,01f00h		;5af2	01 00 1f	. . .
	rst 38h			;5af5	ff		.
	rst 38h			;5af6	ff		.
	rst 38h			;5af7	ff		.
	rst 38h			;5af8	ff		.
	rst 38h			;5af9	ff		.
	rst 38h			;5afa	ff		.
	rst 38h			;5afb	ff		.
	rst 38h			;5afc	ff		.
	rst 38h			;5afd	ff		.
	rst 38h			;5afe	ff		.
	rst 38h			;5aff	ff		.
	rst 38h			;5b00	ff		.
	rst 38h			;5b01	ff		.
	rst 38h			;5b02	ff		.
	rst 38h			;5b03	ff		.
	rst 38h			;5b04	ff		.
	rst 38h			;5b05	ff		.
	rst 38h			;5b06	ff		.
	rst 38h			;5b07	ff		.
	rst 38h			;5b08	ff		.
	rst 38h			;5b09	ff		.
	rst 38h			;5b0a	ff		.
	rst 38h			;5b0b	ff		.
	rst 38h			;5b0c	ff		.
	rst 38h			;5b0d	ff		.
	rst 38h			;5b0e	ff		.
	rst 38h			;5b0f	ff		.
l5b10h:
	rst 38h			;5b10	ff		.
	rst 38h			;5b11	ff		.
	rst 38h			;5b12	ff		.
	rst 38h			;5b13	ff		.
	rst 38h			;5b14	ff		.
	rst 38h			;5b15	ff		.
	rst 38h			;5b16	ff		.
l5b17h:
	add a,d			;5b17	82		.
	ld h,b			;5b18	60		`
	nop			;5b19	00		.
l5b1ah:
	nop			;5b1a	00		.
	jr c,l5b1dh		;5b1b	38 00		8 .
l5b1dh:
	nop			;5b1d	00		.
l5b1eh:
	rst 38h			;5b1e	ff		.
l5b1fh:
	nop			;5b1f	00		.
	nop			;5b20	00		.
l5b21h:
	nop			;5b21	00		.
	nop			;5b22	00		.
l5b23h:
	rst 38h			;5b23	ff		.
	rst 38h			;5b24	ff		.
	nop			;5b25	00		.
	rra			;5b26	1f		.
	rst 38h			;5b27	ff		.
	rst 38h			;5b28	ff		.
	rst 38h			;5b29	ff		.
	rst 38h			;5b2a	ff		.
	rst 38h			;5b2b	ff		.
	rst 38h			;5b2c	ff		.
	rst 38h			;5b2d	ff		.
	rst 38h			;5b2e	ff		.
	rst 38h			;5b2f	ff		.
	rst 38h			;5b30	ff		.
	rst 38h			;5b31	ff		.
	rst 38h			;5b32	ff		.
	rst 38h			;5b33	ff		.
	rst 38h			;5b34	ff		.
	rst 38h			;5b35	ff		.
	rst 38h			;5b36	ff		.
	rst 38h			;5b37	ff		.
	rst 38h			;5b38	ff		.
	rst 38h			;5b39	ff		.
	rst 38h			;5b3a	ff		.
	rst 38h			;5b3b	ff		.
	rst 38h			;5b3c	ff		.
	rst 38h			;5b3d	ff		.
l5b3eh:
	rst 38h			;5b3e	ff		.
	rst 38h			;5b3f	ff		.
	rst 38h			;5b40	ff		.
	rst 38h			;5b41	ff		.
	rst 38h			;5b42	ff		.
	rst 38h			;5b43	ff		.
	rst 38h			;5b44	ff		.
	rst 38h			;5b45	ff		.
	rst 38h			;5b46	ff		.
	rst 38h			;5b47	ff		.
	rst 38h			;5b48	ff		.
l5b49h:
	add a,d			;5b49	82		.
l5b4ah:
	ld h,b			;5b4a	60		`
	nop			;5b4b	00		.
	nop			;5b4c	00		.
	ld b,d			;5b4d	42		B
	nop			;5b4e	00		.
	nop			;5b4f	00		.
	rst 38h			;5b50	ff		.
	nop			;5b51	00		.
	nop			;5b52	00		.
l5b53h:
	nop			;5b53	00		.
l5b54h:
	nop			;5b54	00		.
	rst 38h			;5b55	ff		.
	rst 38h			;5b56	ff		.
l5b57h:
	ld (bc),a		;5b57	02		.
	nop			;5b58	00		.
	ld h,h			;5b59	64		d
	ld e,e			;5b5a	5b		[
l5b5bh:
	inc b			;5b5b	04		.
	nop			;5b5c	00		.
l5b5dh:
	and e			;5b5d	a3		.
	ld e,e			;5b5e	5b		[
	dec b			;5b5f	05		.
	nop			;5b60	00		.
l5b61h:
	pop hl			;5b61	e1		.
	ld e,e			;5b62	5b		[
	nop			;5b63	00		.
	dec a			;5b64	3d		=
	ld b,(hl)		;5b65	46		F
	ld bc,041a8h		;5b66	01 a8 41	. . A
	ld b,(hl)		;5b69	46		F
	ld bc,037a9h		;5b6a	01 a9 37	. . 7
	ld b,a			;5b6d	47		G
	inc bc			;5b6e	03		.
	jp l5c0bh		;5b6f	c3 0b 5c	. . \
	scf			;5b72	37		7
	ld c,b			;5b73	48		H
	ld bc,0770dh		;5b74	01 0d 77	. . w
	ld c,b			;5b77	48		H
	inc bc			;5b78	03		.
	jp l5c3eh		;5b79	c3 3e 5c	. > \
	sub d			;5b7c	92		.
	ld c,b			;5b7d	48		H
	inc bc			;5b7e	03		.
	jp l5c43h		;5b7f	c3 43 5c	. C \
	xor 048h		;5b82	ee 48		. H
	ld bc,0f400h		;5b84	01 00 f4	. . .
	ld c,b			;5b87	48		H
	ld bc,03801h		;5b88	01 01 38	. . 8
	ld c,c			;5b8b	49		I
	inc bc			;5b8c	03		.
	jp l5c1eh		;5b8d	c3 1e 5c	. . \
	adc a,b			;5b90	88		.
	ld c,h			;5b91	4c		L
	ld bc,0b303h		;5b92	01 03 b3	. . .
	ld c,h			;5b95	4c		L
	ld bc,07f03h		;5b96	01 03 7f	. . .
	ld c,d			;5b99	4a		J
	ld bc,0eb21h		;5b9a	01 21 eb	. ! .
	ld d,(hl)		;5b9d	56		V
	ld bc,000cdh		;5b9e	01 cd 00	. . .
	nop			;5ba1	00		.
	nop			;5ba2	00		.
	or d			;5ba3	b2		.
	ld c,(hl)		;5ba4	4e		N
	ld bc,0d050h		;5ba5	01 50 d0	. P .
	ld c,(hl)		;5ba8	4e		N
	inc bc			;5ba9	03		.
	nop			;5baa	00		.
	nop			;5bab	00		.
	nop			;5bac	00		.
	jr nz,l5bfdh		;5bad	20 4e		  N
	ld bc,l68afh		;5baf	01 af 68	. . h
	ld c,a			;5bb2	4f		O
	ld bc,07b00h		;5bb3	01 00 7b	. . {
	ld c,a			;5bb6	4f		O
	ld bc,0af1ah		;5bb7	01 1a af	. . .
	ld c,a			;5bba	4f		O
	ld bc,00a00h		;5bbb	01 00 0a	. . .
	ld d,b			;5bbe	50		P
	ld bc,06100h		;5bbf	01 00 61	. . a
	ld d,b			;5bc2	50		P
	inc bc			;5bc3	03		.
	ld a,01ah		;5bc4	3e 1a		> .
	or a			;5bc6	b7		.
	sub 050h		;5bc7	d6 50		. P
	inc bc			;5bc9	03		.
	jp l5c5bh		;5bca	c3 5b 5c	. [ \
	ld (de),a		;5bcd	12		.
	ld d,c			;5bce	51		Q
	ld bc,0551ah		;5bcf	01 1a 55	. . U
	ld d,c			;5bd2	51		Q
	inc b			;5bd3	04		.
	ld hl,l5cefh		;5bd4	21 ef 5c	! . \
	ret			;5bd7	c9		.
	rst 28h			;5bd8	ef		.
	ld c,l			;5bd9	4d		M
	inc bc			;5bda	03		.
	call sub_5c71h		;5bdb	cd 71 5c	. q \
	nop			;5bde	00		.
	nop			;5bdf	00		.
	nop			;5be0	00		.
	ld h,c			;5be1	61		a
	ld c,(hl)		;5be2	4e		N
	ld bc,l6c0dh		;5be3	01 0d 6c	. . l
	ld c,(hl)		;5be6	4e		N
	ld bc,0ce00h		;5be7	01 00 ce	. . .
	ld c,(hl)		;5bea	4e		N
	ld bc,0ef18h		;5beb	01 18 ef	. . .
	ld c,(hl)		;5bee	4e		N
	ld (bc),a		;5bef	02		.
	dec (hl)		;5bf0	35		5
	ld d,(hl)		;5bf1	56		V
	jp c,0014eh		;5bf2	da 4e 01	. N .
	cpl			;5bf5	2f		/
	adc a,e			;5bf6	8b		.
	ld c,(hl)		;5bf7	4e		N
	ld bc,07218h		;5bf8	01 18 72	. . r
	ld c,(hl)		;5bfb	4e		N
	inc bc			;5bfc	03		.
l5bfdh:
	jp l5c69h		;5bfd	c3 69 5c	. i \
l5c00h:
	ld (00150h),a		;5c00	32 50 01	2 P .
	nop			;5c03	00		.
	ld b,b			;5c04	40		@
	ld c,(hl)		;5c05	4e		N
	ld bc,00013h		;5c06	01 13 00	. . .
	nop			;5c09	00		.
	nop			;5c0a	00		.
l5c0bh:
	ei			;5c0b	fb		.
	pop bc			;5c0c	c1		.
	jr nz,l5c19h		;5c0d	20 0a		  .
	ld a,(046c4h)		;5c0f	3a c4 46	: . F
	and 020h		;5c12	e6 20		.  
	jr nz,l5c1ch		;5c14	20 06		  .
	add a,006h		;5c16	c6 06		. .
	ret			;5c18	c9		.
l5c19h:
	cp 006h			;5c19	fe 06		. .
	ret nz			;5c1b	c0		.
l5c1ch:
	xor a			;5c1c	af		.
	ret			;5c1d	c9		.
l5c1eh:
	push bc			;5c1e	c5		.
	push hl			;5c1f	e5		.
	ld l,a			;5c20	6f		o
	ld h,000h		;5c21	26 00		& .
	ld a,005h		;5c23	3e 05		> .
	call 04cb4h		;5c25	cd b4 4c	. . L
	ld h,a			;5c28	67		g
	ld a,l			;5c29	7d		}
	ld l,h			;5c2a	6c		l
	ex (sp),hl		;5c2b	e3		.
	inc a			;5c2c	3c		<
	inc a			;5c2d	3c		<
	cp l			;5c2e	bd		.
	call nz,0490ah		;5c2f	c4 0a 49	. . I
	pop hl			;5c32	e1		.
	pop bc			;5c33	c1		.
	ret nz			;5c34	c0		.
	ld a,030h		;5c35	3e 30		> 0
	call 04c92h		;5c37	cd 92 4c	. . L
	ld a,l			;5c3a	7d		}
	jp 04947h		;5c3b	c3 47 49	. G I
l5c3eh:
	ex af,af'		;5c3e	08		.
	dec a			;5c3f	3d		=
	jp nz,04838h		;5c40	c2 38 48	. 8 H
l5c43h:
	pop af			;5c43	f1		.
	pop af			;5c44	f1		.
	pop af			;5c45	f1		.
	ld a,(048bbh)		;5c46	3a bb 48	: . H
	or a			;5c49	b7		.
	jp nz,048b8h		;5c4a	c2 b8 48	. . H
	ld a,(ix+007h)		;5c4d	dd 7e 07	. ~ .
	ld (0486ah),a		;5c50	32 6a 48	2 j H
	ld a,064h		;5c53	3e 64		> d
	call 049ddh		;5c55	cd dd 49	. . I
	jp 04813h		;5c58	c3 13 48	. . H
l5c5bh:
	ld b,050h		;5c5b	06 50		. P
l5c5dh:
	ld a,(hl)		;5c5d	7e		~
	or a			;5c5e	b7		.
	jp z,l50feh		;5c5f	ca fe 50	. . P
	inc hl			;5c62	23		#
	djnz l5c5dh		;5c63	10 f8		. .
	ld a,01ah		;5c65	3e 1a		> .
	or a			;5c67	b7		.
	ret			;5c68	c9		.
l5c69h:
	dec e			;5c69	1d		.
	jp nz,04e62h		;5c6a	c2 62 4e	. b N
	inc hl			;5c6d	23		#
	jp l4e95h		;5c6e	c3 95 4e	. . N
sub_5c71h:
	inc hl			;5c71	23		#
	ld a,(04046h)		;5c72	3a 46 40	: F @
	ld (hl),a		;5c75	77		w
	inc hl			;5c76	23		#
	ld a,(04044h)		;5c77	3a 44 40	: D @
	ld (hl),a		;5c7a	77		w
	dec hl			;5c7b	2b		+
	dec hl			;5c7c	2b		+
	jp l4e1fh		;5c7d	c3 1f 4e	. . N
sub_5c80h:
	ld bc,00100h		;5c80	01 00 01	. . .
	or a			;5c83	b7		.
	ret nz			;5c84	c0		.
	inc de			;5c85	13		.
	inc de			;5c86	13		.
	ld a,(de)		;5c87	1a		.
	ld (064bch),a		;5c88	32 bc 64	2 . d
	dec de			;5c8b	1b		.
	dec de			;5c8c	1b		.
	ret			;5c8d	c9		.
sub_5c8eh:
	ld (l5b1ah),hl		;5c8e	22 1a 5b	" . [
	set 6,(ix+001h)		;5c91	dd cb 01 f6	. . . .
	ret			;5c95	c9		.
sub_5c96h:
	call sub_63b3h		;5c96	cd b3 63	. . c
	ld a,(l59beh)		;5c99	3a be 59	: . Y
	ld b,a			;5c9c	47		G
	ld a,(l59b9h)		;5c9d	3a b9 59	: . Y
	ld c,a			;5ca0	4f		O
	ld a,(l59cch)		;5ca1	3a cc 59	: . Y
	ld d,a			;5ca4	57		W
	ld a,(l59c7h)		;5ca5	3a c7 59	: . Y
	ld e,a			;5ca8	5f		_
	ld a,c			;5ca9	79		y
	and e			;5caa	a3		.
	bit 5,a			;5cab	cb 6f		. o
	jr z,l5cb5h		;5cad	28 06		( .
	ld a,b			;5caf	78		x
	xor d			;5cb0	aa		.
	rrca			;5cb1	0f		.
	jp c,l6747h		;5cb2	da 47 67	. G g
l5cb5h:
	ld a,b			;5cb5	78		x
	bit 5,c			;5cb6	cb 69		. i
	jr nz,l5cbeh		;5cb8	20 04		  .
	bit 5,e			;5cba	cb 6b		. k
	ret z			;5cbc	c8		.
	ld a,d			;5cbd	7a		z
l5cbeh:
	rrca			;5cbe	0f		.
	ret c			;5cbf	d8		.
	ld hl,l5b5bh		;5cc0	21 5b 5b	! [ [
	ld (055f7h),hl		;5cc3	22 f7 55	" . U
	ld hl,05bb1h		;5cc6	21 b1 5b	! . [
	ld (l5b5dh),hl		;5cc9	22 5d 5b	" ] [
	ld hl,l5c00h		;5ccc	21 00 5c	! . \
	ld (l5b61h),hl		;5ccf	22 61 5b	" a [
	xor a			;5cd2	af		.
	ld (l617fh),a		;5cd3	32 7f 61	2 . a
	ld h,a			;5cd6	67		g
	ld l,a			;5cd7	6f		o
	ld (l61bfh),hl		;5cd8	22 bf 61	" . a
	ld (05bb5h),hl		;5cdb	22 b5 5b	" . [
	ld a,018h		;5cde	3e 18		> .
	ld (l612dh),a		;5ce0	32 2d 61	2 - a
	ret			;5ce3	c9		.
l5ce4h:
	ld a,(0430ch)		;5ce4	3a 0c 43	: . C
	bit 5,a			;5ce7	cb 6f		. o
	jr z,l5cefh		;5ce9	28 04		( .
	set 5,(ix+002h)		;5ceb	dd cb 02 ee	. . . .
l5cefh:
	jp 04439h		;5cef	c3 39 44	. 9 D
sub_5cf2h:
	bit 5,(ix+002h)		;5cf2	dd cb 02 6e	. . . n
	jr z,l5cfch		;5cf6	28 04		( .
	bit 0,(ix+007h)		;5cf8	dd cb 07 46	. . . F
l5cfch:
	jp z,04cb2h		;5cfc	ca b2 4c	. . L
	ld a,003h		;5cff	3e 03		> .
	jp 04cb4h		;5d01	c3 b4 4c	. . L
	nop			;5d04	00		.
	nop			;5d05	00		.
	nop			;5d06	00		.
	nop			;5d07	00		.
	nop			;5d08	00		.
	nop			;5d09	00		.
	nop			;5d0a	00		.
	nop			;5d0b	00		.
	nop			;5d0c	00		.
	nop			;5d0d	00		.
	nop			;5d0e	00		.
	nop			;5d0f	00		.
l5d10h:
	nop			;5d10	00		.
	ld b,d			;5d11	42		B
l5d12h:
	ld d,05dh		;5d12	16 5d		. ]
l5d14h:
	ld d,05dh		;5d14	16 5d		. ]
l5d16h:
	call sub_6643h		;5d16	cd 43 66	. C f
	ld hl,l5ae5h		;5d19	21 e5 5a	! . Z
	res 1,(hl)		;5d1c	cb 8e		. .
	ld hl,l5b17h		;5d1e	21 17 5b	! . [
	res 1,(hl)		;5d21	cb 8e		. .
	ld a,(l5997h)		;5d23	3a 97 59	: . Y
	and 030h		;5d26	e6 30		. 0
	jr z,l5d86h		;5d28	28 5c		( \
	call sub_568bh		;5d2a	cd 8b 56	. . V
	ld hl,l6491h		;5d2d	21 91 64	! . d
	ld de,04480h		;5d30	11 80 44	. . D
	ld a,(0448ch)		;5d33	3a 8c 44	: . D
	cp 00bh			;5d36	fe 0b		. .
	jr nc,l5d65h		;5d38	30 2b		0 +
l5d3ah:
	ld b,00dh		;5d3a	06 0d		. .
	call sub_5d71h		;5d3c	cd 71 5d	. q ]
	jr z,l5d3ah		;5d3f	28 f9		( .
	cp 020h			;5d41	fe 20		.  
	jr z,l5d3ah		;5d43	28 f5		( .
	cp 03bh			;5d45	fe 3b		. ;
	jr nz,l5d53h		;5d47	20 0a		  .
l5d49h:
	call sub_5d71h		;5d49	cd 71 5d	. q ]
	jr nz,l5d49h		;5d4c	20 fb		  .
	jr l5d3ah		;5d4e	18 ea		. .
l5d50h:
	call sub_5d71h		;5d50	cd 71 5d	. q ]
l5d53h:
	ld (hl),a		;5d53	77		w
	inc hl			;5d54	23		#
	jr z,l5d3ah		;5d55	28 e3		( .
	sub 02fh		;5d57	d6 2f		. /
	cp 00bh			;5d59	fe 0b		. .
	jr c,l5d63h		;5d5b	38 06		8 .
	sub 012h		;5d5d	d6 12		. .
	cp 01ah			;5d5f	fe 1a		. .
	jr nc,l5d65h		;5d61	30 02		0 .
l5d63h:
	djnz l5d50h		;5d63	10 eb		. .
l5d65h:
	ld a,001h		;5d65	3e 01		> .
l5d67h:
	push af			;5d67	f5		.
	ld hl,l6283h		;5d68	21 83 62	! . b
	call 04467h		;5d6b	cd 67 44	. g D
	jp l521bh		;5d6e	c3 1b 52	. . R
sub_5d71h:
	call 00013h		;5d71	cd 13 00	. . .
	jr nz,l5d7dh		;5d74	20 07		  .
	and 07fh		;5d76	e6 7f		. .
	jr z,sub_5d71h		;5d78	28 f7		( .
	cp 00dh			;5d7a	fe 0d		. .
	ret			;5d7c	c9		.
l5d7dh:
	cp 01ch			;5d7d	fe 1c		. .
	jr nz,l5d67h		;5d7f	20 e6		  .
	ld a,00dh		;5d81	3e 0d		> .
	ld (hl),a		;5d83	77		w
	inc hl			;5d84	23		#
	ld (hl),a		;5d85	77		w
l5d86h:
	call sub_5578h		;5d86	cd 78 55	. x U
	call sub_6162h		;5d89	cd 62 61	. b a
	call sub_6178h		;5d8c	cd 78 61	. x a
	ld (l597ch),a		;5d8f	32 7c 59	2 | Y
	ld a,c			;5d92	79		y
	ld (l59c0h),a		;5d93	32 c0 59	2 . Y
	ld hl,(l593ch)		;5d96	2a 3c 59	* < Y
	ld de,0ffe8h		;5d99	11 e8 ff	. . .
	add hl,de		;5d9c	19		.
	ld (061dbh),hl		;5d9d	22 db 61	" . a
	ld a,(l5997h)		;5da0	3a 97 59	: . Y
	and 030h		;5da3	e6 30		. 0
	jr z,l5e0fh		;5da5	28 68		( h
	and 010h		;5da7	e6 10		. .
	ld c,a			;5da9	4f		O
	jr z,l5db5h		;5daa	28 09		( .
	xor a			;5dac	af		.
	ld b,a			;5dad	47		G
	ld hl,l6291h		;5dae	21 91 62	! . b
l5db1h:
	ld (hl),a		;5db1	77		w
	inc hl			;5db2	23		#
	djnz l5db1h		;5db3	10 fc		. .
l5db5h:
	ld hl,l6491h		;5db5	21 91 64	! . d
l5db8h:
	ld a,(hl)		;5db8	7e		~
	cp 00dh			;5db9	fe 0d		. .
	jr z,l5e07h		;5dbb	28 4a		( J
	ld de,0447fh		;5dbd	11 7f 44	. . D
l5dc0h:
	inc de			;5dc0	13		.
	ld a,(hl)		;5dc1	7e		~
	cp 00dh			;5dc2	fe 0d		. .
	ld (de),a		;5dc4	12		.
	inc hl			;5dc5	23		#
	jr nz,l5dc0h		;5dc6	20 f8		  .
	ex de,hl		;5dc8	eb		.
	ld (hl),03ah		;5dc9	36 3a		6 :
	inc hl			;5dcb	23		#
	ld a,(l594ch)		;5dcc	3a 4c 59	: L Y
	ld b,064h		;5dcf	06 64		. d
	call sub_61cbh		;5dd1	cd cb 61	. . a
	ld b,00ah		;5dd4	06 0a		. .
	call sub_61cbh		;5dd6	cd cb 61	. . a
	add a,030h		;5dd9	c6 30		. 0
	ld (hl),a		;5ddb	77		w
	inc hl			;5ddc	23		#
	ld (hl),00dh		;5ddd	36 0d		6 .
	ex de,hl		;5ddf	eb		.
	ld de,04480h		;5de0	11 80 44	. . D
	call 04424h		;5de3	cd 24 44	. $ D
	jr z,l5df1h		;5de6	28 09		( .
	cp 018h			;5de8	fe 18		. .
	jr z,l5db8h		;5dea	28 cc		( .
	cp 019h			;5dec	fe 19		. .
	jp nz,l521ah		;5dee	c2 1a 52	. . R
l5df1h:
	ld a,(l4f56h)		;5df1	3a 56 4f	: V O
	push hl			;5df4	e5		.
	ld hl,l6291h		;5df5	21 91 62	! . b
	ld e,a			;5df8	5f		_
	ld d,000h		;5df9	16 00		. .
	add hl,de		;5dfb	19		.
	ld a,c			;5dfc	79		y
	or a			;5dfd	b7		.
	jr z,l5e03h		;5dfe	28 03		( .
	ld a,(04d6eh)		;5e00	3a 6e 4d	: n M
l5e03h:
	ld (hl),a		;5e03	77		w
	pop hl			;5e04	e1		.
	jr l5db8h		;5e05	18 b1		. .
l5e07h:
	ld a,005h		;5e07	3e 05		> .
	call sub_568dh		;5e09	cd 8d 56	. . V
	call sub_5578h		;5e0c	cd 78 55	. x U
l5e0fh:
	ld hl,l6491h		;5e0f	21 91 64	! . d
	ld (l5d12h),hl		;5e12	22 12 5d	" . ]
	ld (l5d14h),hl		;5e15	22 14 5d	" . ]
	ld c,000h		;5e18	0e 00		. .
l5e1ah:
	call sub_619dh		;5e1a	cd 9d 61	. . a
	jp nz,l5eaah		;5e1d	c2 aa 5e	. . ^
	call sub_61f6h		;5e20	cd f6 61	. . a
	ld a,(l5996h)		;5e23	3a 96 59	: . Y
	jr nz,l5e32h		;5e26	20 0a		  .
	bit 0,a			;5e28	cb 47		. G
	jr z,l5e32h		;5e2a	28 06		( .
	inc hl			;5e2c	23		#
	bit 5,(hl)		;5e2d	cb 6e		. n
	dec hl			;5e2f	2b		+
	jr z,l5eaah		;5e30	28 78		( x
l5e32h:
	bit 4,a			;5e32	cb 67		. g
	jr z,l5e3eh		;5e34	28 08		( .
	bit 6,(hl)		;5e36	cb 76		. v
	jr nz,l5eaah		;5e38	20 70		  p
	bit 3,(hl)		;5e3a	cb 5e		. ^
	jr nz,l5eaah		;5e3c	20 6c		  l
l5e3eh:
	bit 1,a			;5e3e	cb 4f		. O
	jr z,l5e5bh		;5e40	28 19		( .
	push hl			;5e42	e5		.
	push de			;5e43	d5		.
	push bc			;5e44	c5		.
	ld de,0000dh		;5e45	11 0d 00	. . .
	add hl,de		;5e48	19		.
	ld de,l624ch		;5e49	11 4c 62	. L b
	ld b,003h		;5e4c	06 03		. .
l5e4eh:
	ld a,(de)		;5e4e	1a		.
	cp (hl)			;5e4f	be		.
	inc de			;5e50	13		.
	inc hl			;5e51	23		#
	jr nz,l5e56h		;5e52	20 02		  .
	djnz l5e4eh		;5e54	10 f8		. .
l5e56h:
	pop bc			;5e56	c1		.
	pop de			;5e57	d1		.
	pop hl			;5e58	e1		.
	jr nz,l5eaah		;5e59	20 4f		  O
l5e5bh:
	ld d,(hl)		;5e5b	56		V
	bit 6,d			;5e5c	cb 72		. r
	call nz,sub_61eah	;5e5e	c4 ea 61	. . a
	jr nz,l5eaah		;5e61	20 47		  G
	ld a,(l5995h)		;5e63	3a 95 59	: . Y
	bit 6,a			;5e66	cb 77		. w
	jr z,l5e87h		;5e68	28 1d		( .
	push de			;5e6a	d5		.
	push bc			;5e6b	c5		.
	call sub_58a0h		;5e6c	cd a0 58	. . X
	ld hl,l625ch		;5e6f	21 5c 62	! \ b
	call sub_58e4h		;5e72	cd e4 58	. . X
	pop bc			;5e75	c1		.
	pop de			;5e76	d1		.
	jr nz,l5e81h		;5e77	20 08		  .
	ld hl,l6d5eh		;5e79	21 5e 6d	! ^ m
	call 04467h		;5e7c	cd 67 44	. g D
	jr l5e0fh		;5e7f	18 8e		. .
l5e81h:
	dec a			;5e81	3d		=
	jr z,l5eb3h		;5e82	28 2f		( /
	dec a			;5e84	3d		=
	jr z,l5eaah		;5e85	28 23		( #
l5e87h:
	ld hl,(l5d14h)		;5e87	2a 14 5d	* . ]
	ld (hl),080h		;5e8a	36 80		6 .
	bit 6,d			;5e8c	cb 72		. r
	jr z,l5ea2h		;5e8e	28 12		( .
	ld a,(l5997h)		;5e90	3a 97 59	: . Y
	bit 3,a			;5e93	cb 5f		. _
	jr nz,l5ea2h		;5e95	20 0b		  .
	ld a,c			;5e97	79		y
	cp 080h			;5e98	fe 80		. .
	jr nc,l5ea2h		;5e9a	30 06		0 .
	and 018h		;5e9c	e6 18		. .
	jr nz,l5ea2h		;5e9e	20 02		  .
	set 6,(hl)		;5ea0	cb f6		. .
l5ea2h:
	inc hl			;5ea2	23		#
	ld (hl),c		;5ea3	71		q
	inc hl			;5ea4	23		#
	ld (hl),b		;5ea5	70		p
	inc hl			;5ea6	23		#
	ld (l5d14h),hl		;5ea7	22 14 5d	" . ]
l5eaah:
	ld hl,l597ch		;5eaa	21 7c 59	! | Y
	call sub_61bah		;5ead	cd ba 61	. . a
	jp nc,l5e1ah		;5eb0	d2 1a 5e	. . ^
l5eb3h:
	call sub_6190h		;5eb3	cd 90 61	. . a
	call sub_5699h		;5eb6	cd 99 56	. . V
	jp z,l552dh		;5eb9	ca 2d 55	. - U
l5ebch:
	push hl			;5ebc	e5		.
	call sub_61d6h		;5ebd	cd d6 61	. . a
	jr c,l5eceh		;5ec0	38 0c		8 .
	call sub_5ee4h		;5ec2	cd e4 5e	. . ^
	call sub_5578h		;5ec5	cd 78 55	. x U
	call sub_6190h		;5ec8	cd 90 61	. . a
	pop hl			;5ecb	e1		.
	jr l5ebch		;5ecc	18 ee		. .
l5eceh:
	inc hl			;5ece	23		#
	ld a,(hl)		;5ecf	7e		~
	call sub_56efh		;5ed0	cd ef 56	. . V
	ld bc,00018h		;5ed3	01 18 00	. . .
	ldir			;5ed6	ed b0		. .
	pop hl			;5ed8	e1		.
	set 4,(hl)		;5ed9	cb e6		. .
	call sub_5699h		;5edb	cd 99 56	. . V
	jr nz,l5ebch		;5ede	20 dc		  .
	ld hl,l60bfh		;5ee0	21 bf 60	! . `
	push hl			;5ee3	e5		.
sub_5ee4h:
	call sub_557dh		;5ee4	cd 7d 55	. } U
	call sub_6162h		;5ee7	cd 62 61	. b a
	call sub_6178h		;5eea	cd 78 61	. x a
	ld (l597dh),a		;5eed	32 7d 59	2 } Y
	ld a,c			;5ef0	79		y
	ld (l59ceh),a		;5ef1	32 ce 59	2 . Y
	ld a,(l5997h)		;5ef4	3a 97 59	: . Y
	bit 3,a			;5ef7	cb 5f		. _
	jp z,l5f92h		;5ef9	ca 92 5f	. . _
	ld c,000h		;5efc	0e 00		. .
l5efeh:
	call sub_619dh		;5efe	cd 9d 61	. . a
	jp nz,l5f89h		;5f01	c2 89 5f	. . _
	ld (05f1eh),hl		;5f04	22 1e 5f	" . _
	call sub_6190h		;5f07	cd 90 61	. . a
l5f0ah:
	call sub_5699h		;5f0a	cd 99 56	. . V
	jr z,l5f89h		;5f0d	28 7a		( z
	bit 4,(hl)		;5f0f	cb 66		. f
	jr z,l5f0ah		;5f11	28 f7		( .
	call sub_61d6h		;5f13	cd d6 61	. . a
	bit 5,(hl)		;5f16	cb 6e		. n
	jr nz,l5f0ah		;5f18	20 f0		  .
	push hl			;5f1a	e5		.
	ld b,005h		;5f1b	06 05		. .
	ld hl,00000h		;5f1d	21 00 00	! . .
	push hl			;5f20	e5		.
	push de			;5f21	d5		.
l5f22h:
	inc hl			;5f22	23		#
	inc de			;5f23	13		.
	djnz l5f22h		;5f24	10 fc		. .
	ld b,00bh		;5f26	06 0b		. .
	call sub_6254h		;5f28	cd 54 62	. T b
	pop hl			;5f2b	e1		.
	pop de			;5f2c	d1		.
	jr z,l5f32h		;5f2d	28 03		( .
	pop hl			;5f2f	e1		.
	jr l5f0ah		;5f30	18 d8		. .
l5f32h:
	push de			;5f32	d5		.
	push bc			;5f33	c5		.
	ld bc,00003h		;5f34	01 03 00	. . .
	add hl,bc		;5f37	09		.
	ex de,hl		;5f38	eb		.
	add hl,bc		;5f39	09		.
	ld a,(de)		;5f3a	1a		.
	ld (hl),a		;5f3b	77		w
	inc hl			;5f3c	23		#
	push af			;5f3d	f5		.
	inc de			;5f3e	13		.
	ld a,(de)		;5f3f	1a		.
	ld (hl),a		;5f40	77		w
	ld bc,00010h		;5f41	01 10 00	. . .
	add hl,bc		;5f44	09		.
	ex de,hl		;5f45	eb		.
	add hl,bc		;5f46	09		.
	ld a,(hl)		;5f47	7e		~
	ld (de),a		;5f48	12		.
	inc de			;5f49	13		.
	inc hl			;5f4a	23		#
	ld a,(hl)		;5f4b	7e		~
	ld (de),a		;5f4c	12		.
	dec de			;5f4d	1b		.
	ex de,hl		;5f4e	eb		.
	pop af			;5f4f	f1		.
	call sub_6209h		;5f50	cd 09 62	. . b
	pop bc			;5f53	c1		.
	pop de			;5f54	d1		.
	pop hl			;5f55	e1		.
	set 5,(hl)		;5f56	cb ee		. .
	inc hl			;5f58	23		#
	inc hl			;5f59	23		#
	ld (hl),c		;5f5a	71		q
	ld a,c			;5f5b	79		y
	ld (l5b1eh),a		;5f5c	32 1e 5b	2 . [
	call sub_5711h		;5f5f	cd 11 57	. . W
	ld a,(04317h)		;5f62	3a 17 43	: . C
	cp 005h			;5f65	fe 05		. .
	jp nz,l5608h		;5f67	c2 08 56	. . V
	inc de			;5f6a	13		.
	ld a,(de)		;5f6b	1a		.
	bit 6,a			;5f6c	cb 77		. w
	dec de			;5f6e	1b		.
	jr nz,l5f89h		;5f6f	20 18		  .
	ld hl,0436bh		;5f71	21 6b 43	! k C
	set 2,(hl)		;5f74	cb d6		. .
	push hl			;5f76	e5		.
	ex de,hl		;5f77	eb		.
	ld de,l5b17h		;5f78	11 17 5b	. . [
	call sub_60a9h		;5f7b	cd a9 60	. . `
	jp nz,l521ah		;5f7e	c2 1a 52	. . R
	pop hl			;5f81	e1		.
	res 2,(hl)		;5f82	cb 96		. .
	ld a,005h		;5f84	3e 05		> .
	ld (04317h),a		;5f86	32 17 43	2 . C
l5f89h:
	ld hl,l597dh		;5f89	21 7d 59	! } Y
	call sub_61bah		;5f8c	cd ba 61	. . a
	jp nc,l5efeh		;5f8f	d2 fe 5e	. . ^
l5f92h:
	ld a,(l5995h)		;5f92	3a 95 59	: . Y
	bit 3,a			;5f95	cb 5f		. _
	ret nz			;5f97	c0		.
	call sub_56f9h		;5f98	cd f9 56	. . V
	ld de,06391h		;5f9b	11 91 63	. . c
	call sub_6172h		;5f9e	cd 72 61	. r a
	call sub_6162h		;5fa1	cd 62 61	. b a
	call sub_6190h		;5fa4	cd 90 61	. . a
l5fa7h:
	call sub_5699h		;5fa7	cd 99 56	. . V
	jp z,l6092h		;5faa	ca 92 60	. . `
	bit 4,(hl)		;5fad	cb 66		. f
	jr z,l5fa7h		;5faf	28 f6		( .
	res 4,(hl)		;5fb1	cb a6		. .
	push hl			;5fb3	e5		.
	bit 5,(hl)		;5fb4	cb 6e		. n
	inc hl			;5fb6	23		#
	jp nz,l6083h		;5fb7	c2 83 60	. . `
	call sub_61eah		;5fba	cd ea 61	. . a
	jp nz,l6083h		;5fbd	c2 83 60	. . `
	ld a,(hl)		;5fc0	7e		~
	ld c,a			;5fc1	4f		O
	ld b,000h		;5fc2	06 00		. .
	and 01fh		;5fc4	e6 1f		. .
	ld hl,l597dh		;5fc6	21 7d 59	! } Y
	cp (hl)			;5fc9	be		.
	jp nc,l6083h		;5fca	d2 83 60	. . `
	ld hl,l6291h		;5fcd	21 91 62	! . b
	add hl,bc		;5fd0	09		.
	ld a,(hl)		;5fd1	7e		~
	or a			;5fd2	b7		.
	ex de,hl		;5fd3	eb		.
	jp nz,l6083h		;5fd4	c2 83 60	. . `
	pop hl			;5fd7	e1		.
	set 5,(hl)		;5fd8	cb ee		. .
	push hl			;5fda	e5		.
	inc hl			;5fdb	23		#
	inc hl			;5fdc	23		#
	ld a,(hl)		;5fdd	7e		~
	ld (de),a		;5fde	12		.
	ld a,c			;5fdf	79		y
	ld (hl),a		;5fe0	77		w
	ld (06028h),a		;5fe1	32 28 60	2 ( `
	call sub_56e2h		;5fe4	cd e2 56	. . V
	ex de,hl		;5fe7	eb		.
	ld hl,(061d8h)		;5fe8	2a d8 61	* . a
	ld bc,00016h		;5feb	01 16 00	. . .
	ldir			;5fee	ed b0		. .
	ld c,(hl)		;5ff0	4e		N
	inc hl			;5ff1	23		#
	ld b,(hl)		;5ff2	46		F
	push bc			;5ff3	c5		.
	ld b,00ah		;5ff4	06 0a		. .
	ld (06078h),de		;5ff6	ed 53 78 60	. S x `
l5ffah:
	ld a,0ffh		;5ffa	3e ff		> .
	ld (de),a		;5ffc	12		.
	inc de			;5ffd	13		.
	djnz l5ffah		;5ffe	10 fa		. .
	pop bc			;6000	c1		.
	call sub_5706h		;6001	cd 06 57	. . W
	pop hl			;6004	e1		.
	bit 6,(hl)		;6005	cb 76		. v
	push hl			;6007	e5		.
	jp z,l6083h		;6008	ca 83 60	. . `
	ld a,c			;600b	79		y
	cp 0feh			;600c	fe fe		. .
	jr nc,l6083h		;600e	30 73		0 s
	ld l,a			;6010	6f		o
	ld a,(l59bch)		;6011	3a bc 59	: . Y
	call 04c92h		;6014	cd 92 4c	. . L
	ld a,b			;6017	78		x
	and 01fh		;6018	e6 1f		. .
	ld c,a			;601a	4f		O
	ld a,b			;601b	78		x
	rlca			;601c	07		.
	rlca			;601d	07		.
	rlca			;601e	07		.
	and 007h		;601f	e6 07		. .
	ld e,a			;6021	5f		_
	ld d,000h		;6022	16 00		. .
	add hl,de		;6024	19		.
	ld a,002h		;6025	3e 02		> .
	cp 000h			;6027	fe 00		. .
	jr nz,l6030h		;6029	20 05		  .
	ld hl,00001h		;602b	21 01 00	! . .
	jr l6064h		;602e	18 34		. 4
l6030h:
	ex de,hl		;6030	eb		.
	ld a,(l59b7h)		;6031	3a b7 59	: . Y
	ld l,a			;6034	6f		o
	ld a,(l59bch)		;6035	3a bc 59	: . Y
	call 04c92h		;6038	cd 92 4c	. . L
	ex de,hl		;603b	eb		.
	ld a,(l59c0h)		;603c	3a c0 59	: . Y
	ld b,a			;603f	47		G
	push de			;6040	d5		.
l6041h:
	inc de			;6041	13		.
	djnz l6041h		;6042	10 fd		. .
	or a			;6044	b7		.
	sbc hl,de		;6045	ed 52		. R
	jr c,l6053h		;6047	38 0a		8 .
	pop de			;6049	d1		.
	ld a,(l59ceh)		;604a	3a ce 59	: . Y
	ld e,a			;604d	5f		_
	ld d,000h		;604e	16 00		. .
	add hl,de		;6050	19		.
	jr l6058h		;6051	18 05		. .
l6053h:
	add hl,de		;6053	19		.
	pop de			;6054	d1		.
	or a			;6055	b7		.
	sbc hl,de		;6056	ed 52		. R
l6058h:
	ex de,hl		;6058	eb		.
	ld a,(l59c5h)		;6059	3a c5 59	: . Y
	ld l,a			;605c	6f		o
	ld a,(l59cah)		;605d	3a ca 59	: . Y
	call 04c92h		;6060	cd 92 4c	. . L
	add hl,de		;6063	19		.
l6064h:
	ld d,c			;6064	51		Q
	ld a,(l59cah)		;6065	3a ca 59	: . Y
	call 04cb4h		;6068	cd b4 4c	. . L
	inc h			;606b	24		$
	dec h			;606c	25		%
	call nz,sub_5240h	;606d	c4 40 52	. @ R
	ld b,a			;6070	47		G
	rrca			;6071	0f		.
	rrca			;6072	0f		.
	rrca			;6073	0f		.
	push hl			;6074	e5		.
	or d			;6075	b2		.
	ld h,a			;6076	67		g
	ld (00000h),hl		;6077	22 00 00	" . .
	ld hl,06391h		;607a	21 91 63	! . c
	ld c,d			;607d	4a		J
	pop de			;607e	d1		.
	inc c			;607f	0c		.
	call sub_621ch		;6080	cd 1c 62	. . b
l6083h:
	call sub_61d6h		;6083	cd d6 61	. . a
	pop hl			;6086	e1		.
	bit 5,(hl)		;6087	cb 6e		. n
	jr nz,l608fh		;6089	20 04		  .
	ld a,h			;608b	7c		|
	ld (060c3h),a		;608c	32 c3 60	2 . `
l608fh:
	jp l5fa7h		;608f	c3 a7 5f	. . _
l6092h:
	call sub_570dh		;6092	cd 0d 57	. . W
	ld hl,l6291h		;6095	21 91 62	! . b
	call sub_616fh		;6098	cd 6f 61	. o a
	push hl			;609b	e5		.
	ld a,001h		;609c	3e 01		> .
	call sub_5701h		;609e	cd 01 57	. . W
	pop hl			;60a1	e1		.
	call sub_616fh		;60a2	cd 6f 61	. o a
	xor a			;60a5	af		.
	jp sub_5701h		;60a6	c3 01 57	. . W
sub_60a9h:
	call 04980h		;60a9	cd 80 49	. . I
	xor a			;60ac	af		.
	ld (04fdbh),a		;60ad	32 db 4f	2 . O
	push hl			;60b0	e5		.
	inc l			;60b1	2c		,
	inc l			;60b2	2c		,
	inc l			;60b3	2c		,
	ld a,(hl)		;60b4	7e		~
	ld de,00011h		;60b5	11 11 00	. . .
	add hl,de		;60b8	19		.
	ld e,(hl)		;60b9	5e		^
	inc hl			;60ba	23		#
	ld d,(hl)		;60bb	56		V
	jp l4e3dh		;60bc	c3 3d 4e	. = N
l60bfh:
	call sub_568bh		;60bf	cd 8b 56	. . V
	ld a,000h		;60c2	3e 00		> .
	or a			;60c4	b7		.
	jp z,l6157h		;60c5	ca 57 61	. W a
l60c8h:
	call sub_5578h		;60c8	cd 78 55	. x U
	call sub_6190h		;60cb	cd 90 61	. . a
l60ceh:
	call sub_5699h		;60ce	cd 99 56	. . V
	jr z,l60f1h		;60d1	28 1e		( .
	bit 5,(hl)		;60d3	cb 6e		. n
	jr nz,l60ceh		;60d5	20 f7		  .
	call sub_61d6h		;60d7	cd d6 61	. . a
	jr c,l60e1h		;60da	38 05		8 .
	call sub_60f5h		;60dc	cd f5 60	. . `
	jr l60c8h		;60df	18 e7		. .
l60e1h:
	push hl			;60e1	e5		.
	set 4,(hl)		;60e2	cb e6		. .
	inc hl			;60e4	23		#
	ld a,(hl)		;60e5	7e		~
	call sub_56efh		;60e6	cd ef 56	. . V
	ld bc,00016h		;60e9	01 16 00	. . .
	ldir			;60ec	ed b0		. .
	pop hl			;60ee	e1		.
	jr l60ceh		;60ef	18 dd		. .
l60f1h:
	ld hl,l6157h		;60f1	21 57 61	! W a
	push hl			;60f4	e5		.
sub_60f5h:
	call sub_557dh		;60f5	cd 7d 55	. } U
	call sub_6190h		;60f8	cd 90 61	. . a
l60fbh:
	call sub_5699h		;60fb	cd 99 56	. . V
	ret z			;60fe	c8		.
	bit 4,(hl)		;60ff	cb 66		. f
	jr z,l60fbh		;6101	28 f8		( .
	push hl			;6103	e5		.
	res 4,(hl)		;6104	cb a6		. .
	call sub_61d6h		;6106	cd d6 61	. . a
	inc hl			;6109	23		#
	ld b,(hl)		;610a	46		F
	inc hl			;610b	23		#
	push de			;610c	d5		.
	push hl			;610d	e5		.
	call 050cfh		;610e	cd cf 50	. . P
	jp nz,l521ah		;6111	c2 1a 52	. . R
	ex de,hl		;6114	eb		.
	pop hl			;6115	e1		.
	ld (hl),a		;6116	77		w
	pop hl			;6117	e1		.
	push de			;6118	d5		.
	ld bc,00016h		;6119	01 16 00	. . .
	ldir			;611c	ed b0		. .
	pop de			;611e	d1		.
	call sub_61fch		;611f	cd fc 61	. . a
	jr z,l614fh		;6122	28 2b		( +
	bit 5,a			;6124	cb 6f		. o
	ex de,hl		;6126	eb		.
	ld de,00000h		;6127	11 00 00	. . .
	ld bc,04296h		;612a	01 96 42	. . B
l612dh:
	jr z,l613ah		;612d	28 0b		( .
	ld a,(04044h)		;612f	3a 44 40	: D @
	ld d,a			;6132	57		W
	ld a,(04046h)		;6133	3a 46 40	: F @
	ld e,a			;6136	5f		_
	ld bc,l5cefh		;6137	01 ef 5c	. . \
l613ah:
	inc hl			;613a	23		#
	ld (hl),e		;613b	73		s
	inc hl			;613c	23		#
	ld (hl),d		;613d	72		r
	inc hl			;613e	23		#
	ld a,(hl)		;613f	7e		~
	ld de,0000dh		;6140	11 0d 00	. . .
	add hl,de		;6143	19		.
sub_6144h:
	ld (hl),c		;6144	71		q
	inc hl			;6145	23		#
	ld (hl),b		;6146	70		p
	inc hl			;6147	23		#
	ld (hl),c		;6148	71		q
	inc hl			;6149	23		#
	ld (hl),b		;614a	70		p
	inc hl			;614b	23		#
	call sub_6209h		;614c	cd 09 62	. . b
l614fh:
	call sub_5711h		;614f	cd 11 57	. . W
	pop hl			;6152	e1		.
	set 5,(hl)		;6153	cb ee		. .
	jr l60fbh		;6155	18 a4		. .
l6157h:
	ld a,0ffh		;6157	3e ff		> .
	ld (l5b1eh),a		;6159	32 1e 5b	2 . [
	ld (0586ah),a		;615c	32 6a 58	2 j X
	jp l524eh		;615f	c3 4e 52	. N R
sub_6162h:
	ld a,001h		;6162	3e 01		> .
	call sub_56fah		;6164	cd fa 56	. . V
	ld de,l6291h		;6167	11 91 62	. . b
	call sub_6172h		;616a	cd 72 61	. r a
	dec h			;616d	25		%
	ret			;616e	c9		.
sub_616fh:
	ld de,04200h		;616f	11 00 42	. . B
sub_6172h:
	ld bc,00100h		;6172	01 00 01	. . .
	ldir			;6175	ed b0		. .
	ret			;6177	c9		.
sub_6178h:
	call sub_61f6h		;6178	cd f6 61	. . a
	ld a,010h		;617b	3e 10		> .
	ld c,006h		;617d	0e 06		. .
l617fh:
	ret nz			;617f	c0		.
	ld e,005h		;6180	1e 05		. .
	ld a,(0421fh)		;6182	3a 1f 42	: . B
	add a,008h		;6185	c6 08		. .
	ld b,a			;6187	47		G
	ld c,000h		;6188	0e 00		. .
l618ah:
	inc c			;618a	0c		.
	sub e			;618b	93		.
	jr nc,l618ah		;618c	30 fc		0 .
	ld a,b			;618e	78		x
	ret			;618f	c9		.
sub_6190h:
	ld hl,(l5d14h)		;6190	2a 14 5d	* . ]
	ld (061d8h),hl		;6193	22 d8 61	" . a
	ld hl,(l5d12h)		;6196	2a 12 5d	* . ]
	dec hl			;6199	2b		+
	dec hl			;619a	2b		+
	dec hl			;619b	2b		+
	ret			;619c	c9		.
sub_619dh:
	ld b,000h		;619d	06 00		. .
	ld hl,l6291h		;619f	21 91 62	! . b
	add hl,bc		;61a2	09		.
	ld a,(hl)		;61a3	7e		~
	cp 001h			;61a4	fe 01		. .
	ld b,a			;61a6	47		G
	ret c			;61a7	d8		.
	call sub_61f6h		;61a8	cd f6 61	. . a
	ld a,c			;61ab	79		y
	jr nz,l61b1h		;61ac	20 03		  .
	cp 002h			;61ae	fe 02		. .
	ret c			;61b0	d8		.
l61b1h:
	call sub_56e2h		;61b1	cd e2 56	. . V
	ld a,(hl)		;61b4	7e		~
	and 090h		;61b5	e6 90		. .
	cp 010h			;61b7	fe 10		. .
	ret			;61b9	c9		.
sub_61bah:
	call sub_61f6h		;61ba	cd f6 61	. . a
	ld a,050h		;61bd	3e 50		> P
l61bfh:
	jr nz,l61c7h		;61bf	20 06		  .
	ld a,c			;61c1	79		y
	add a,020h		;61c2	c6 20		.  
	ld c,a			;61c4	4f		O
	ret nc			;61c5	d0		.
	ld a,(hl)		;61c6	7e		~
l61c7h:
	dec a			;61c7	3d		=
	inc c			;61c8	0c		.
	cp c			;61c9	b9		.
	ret			;61ca	c9		.
sub_61cbh:
	cp b			;61cb	b8		.
	ret c			;61cc	d8		.
	ld (hl),02fh		;61cd	36 2f		6 /
l61cfh:
	inc (hl)		;61cf	34		4
	sub b			;61d0	90		.
	jr nc,l61cfh		;61d1	30 fc		0 .
	add a,b			;61d3	80		.
	inc hl			;61d4	23		#
	ret			;61d5	c9		.
sub_61d6h:
	push hl			;61d6	e5		.
	ld hl,00000h		;61d7	21 00 00	! . .
	ld de,00000h		;61da	11 00 00	. . .
	rst 18h			;61dd	df		.
	push af			;61de	f5		.
	ex de,hl		;61df	eb		.
	ld hl,00018h		;61e0	21 18 00	! . .
	add hl,de		;61e3	19		.
	ld (061d8h),hl		;61e4	22 d8 61	" . a
	pop af			;61e7	f1		.
	pop hl			;61e8	e1		.
	ret			;61e9	c9		.
sub_61eah:
	push hl			;61ea	e5		.
	ld hl,l59c7h		;61eb	21 c7 59	! . Y
	ld a,(l59b9h)		;61ee	3a b9 59	: . Y
	or (hl)			;61f1	b6		.
	pop hl			;61f2	e1		.
	and 020h		;61f3	e6 20		.  
	ret			;61f5	c9		.
sub_61f6h:
	ld a,(0430ch)		;61f6	3a 0c 43	: . C
	and 020h		;61f9	e6 20		.  
	ret			;61fb	c9		.
sub_61fch:
	push hl			;61fc	e5		.
	ld hl,l59c7h		;61fd	21 c7 59	! . Y
	ld a,(l59b9h)		;6200	3a b9 59	: . Y
	xor (hl)		;6203	ae		.
	and 020h		;6204	e6 20		.  
	ld a,(hl)		;6206	7e		~
	pop hl			;6207	e1		.
	ret			;6208	c9		.
sub_6209h:
	or a			;6209	b7		.
	call nz,sub_61fch	;620a	c4 fc 61	. . a
	ret z			;620d	c8		.
	ld e,(hl)		;620e	5e		^
	inc hl			;620f	23		#
	ld d,(hl)		;6210	56		V
	inc de			;6211	13		.
	bit 5,a			;6212	cb 6f		. o
	jr z,l6218h		;6214	28 02		( .
	dec de			;6216	1b		.
	dec de			;6217	1b		.
l6218h:
	ld (hl),d		;6218	72		r
	dec hl			;6219	2b		+
	ld (hl),e		;621a	73		s
	ret			;621b	c9		.
sub_621ch:
	ld d,000h		;621c	16 00		. .
	add hl,de		;621e	19		.
	ld d,080h		;621f	16 80		. .
	ld a,b			;6221	78		x
	inc b			;6222	04		.
l6223h:
	rlc d			;6223	cb 02		. .
	djnz l6223h		;6225	10 fc		. .
	ld b,a			;6227	47		G
l6228h:
	ld a,(l59cah)		;6228	3a ca 59	: . Y
	sub b			;622b	90		.
	ld b,a			;622c	47		G
l622dh:
	push hl			;622d	e5		.
	ld hl,l59c6h		;622e	21 c6 59	! . Y
	ld a,e			;6231	7b		{
	cp (hl)			;6232	be		.
	pop hl			;6233	e1		.
	jr nc,l6249h		;6234	30 13		0 .
	ld a,(hl)		;6236	7e		~
	and d			;6237	a2		.
	jr nz,l6249h		;6238	20 0f		  .
	ld a,(hl)		;623a	7e		~
	or d			;623b	b2		.
	ld (hl),a		;623c	77		w
	dec c			;623d	0d		.
	ret z			;623e	c8		.
	rlc d			;623f	cb 02		. .
	djnz l622dh		;6241	10 ea		. .
	ld d,001h		;6243	16 01		. .
	inc hl			;6245	23		#
	inc e			;6246	1c		.
	jr l6228h		;6247	18 df		. .
l6249h:
	call sub_5240h		;6249	cd 40 52	. @ R
l624ch:
	jr nz,l626eh		;624c	20 20		   
	jr nz,l6261h		;624e	20 11		  .
	ret nc			;6250	d0		.
	ld b,d			;6251	42		B
	ld b,008h		;6252	06 08		. .
sub_6254h:
	ld a,(de)		;6254	1a		.
	cp (hl)			;6255	be		.
	ret nz			;6256	c0		.
	inc de			;6257	13		.
	inc hl			;6258	23		#
	djnz sub_6254h		;6259	10 f9		. .
	ret			;625b	c9		.
l625ch:
	ld d,a			;625c	57		W
	ld b,c			;625d	41		A
	ld c,(hl)		;625e	4e		N
	ld c,d			;625f	4a		J
	nop			;6260	00		.
l6261h:
	call nz,sub_6144h	;6261	c4 44 61	. D a
	ld (hl),h		;6264	74		t
	ld h,l			;6265	65		e
	ld l,c			;6266	69		i
	jr nz,$+109		;6267	20 6b		  k
	ld l,a			;6269	6f		o
	ld (hl),b		;626a	70		p
	ld l,c			;626b	69		i
	ld h,l			;626c	65		e
	ld (hl),d		;626d	72		r
l626eh:
	ld h,l			;626e	65		e
	ld l,(hl)		;626f	6e		n
	ccf			;6270	3f		?
	jr nz,$+76		;6271	20 4a		  J
	inc l			;6273	2c		,
	ld c,(hl)		;6274	4e		N
	inc l			;6275	2c		,
	ld b,c			;6276	41		A
	inc l			;6277	2c		,
	ld d,a			;6278	57		W
	jr nz,l627eh		;6279	20 03		  .
l627bh:
	ld c,e			;627b	4b		K
	ld l,a			;627c	6f		o
	ld (hl),b		;627d	70		p
l627eh:
	ld l,c			;627e	69		i
	ld h,l			;627f	65		e
	ld (hl),d		;6280	72		r
	ld h,l			;6281	65		e
	inc bc			;6282	03		.
l6283h:
	ld c,c			;6283	49		I
	ld b,h			;6284	44		D
	ld c,h			;6285	4c		L
	cpl			;6286	2f		/
	ld e,b			;6287	58		X
	ld b,h			;6288	44		D
	ld c,h			;6289	4c		L
	jr nz,l62d0h		;628a	20 44		  D
	ld h,c			;628c	61		a
	ld (hl),h		;628d	74		t
	ld h,l			;628e	65		e
	ld l,c			;628f	69		i
	inc bc			;6290	03		.
l6291h:
	ld a,(l5997h)		;6291	3a 97 59	: . Y
	and 030h		;6294	e6 30		. 0
	ld hl,04200h		;6296	21 00 42	! . B
	ld de,04480h		;6299	11 80 44	. . D
	call nz,04424h		;629c	c4 24 44	. $ D
	jp nz,l5d67h		;629f	c2 67 5d	. g ]
	ld a,(l5996h)		;62a2	3a 96 59	: . Y
	and 008h		;62a5	e6 08		. .
	ld a,0f3h		;62a7	3e f3		> .
	jr z,l62adh		;62a9	28 02		( .
	ld a,0e5h		;62ab	3e e5		> .
l62adh:
	call sub_568dh		;62ad	cd 8d 56	. . V
	call sub_5578h		;62b0	cd 78 55	. x U
	ld a,(0436ch)		;62b3	3a 6c 43	: l C
	and 082h		;62b6	e6 82		. .
	cp 080h			;62b8	fe 80		. .
	jr z,l62c3h		;62ba	28 07		( .
	ld a,(l5992h+2)		;62bc	3a 94 59	: . Y
	and 002h		;62bf	e6 02		. .
	jr nz,l632ch		;62c1	20 69		  i
l62c3h:
	call sub_56f9h		;62c3	cd f9 56	. . V
	ld a,(l5995h)		;62c6	3a 95 59	: . Y
	bit 5,a			;62c9	cb 6f		. o
	jr nz,l62d3h		;62cb	20 06		  .
	ld hl,(042ceh)		;62cd	2a ce 42	* . B
l62d0h:
	ld (l5981h),hl		;62d0	22 81 59	" . Y
l62d3h:
	ld a,(l5992h+2)		;62d3	3a 94 59	: . Y
	bit 2,a			;62d6	cb 57		. W
	jr nz,l62e5h		;62d8	20 0b		  .
	ld hl,042d0h		;62da	21 d0 42	! . B
	ld de,l5983h		;62dd	11 83 59	. . Y
	ld bc,00008h		;62e0	01 08 00	. . .
	ldir			;62e3	ed b0		. .
l62e5h:
	ld a,(l5995h)		;62e5	3a 95 59	: . Y
	bit 4,a			;62e8	cb 67		. g
	jr z,l62f7h		;62ea	28 0b		( .
	ld hl,042d8h		;62ec	21 d8 42	! . B
	ld de,l598bh		;62ef	11 8b 59	. . Y
	ld bc,00008h		;62f2	01 08 00	. . .
	ldir			;62f5	ed b0		. .
l62f7h:
	ld a,(l5996h)		;62f7	3a 96 59	: . Y
	bit 7,a			;62fa	cb 7f		. .
	jr z,l6314h		;62fc	28 16		( .
	ld hl,l5968h		;62fe	21 68 59	! h Y
	call 0624fh		;6301	cd 4f 62	. O b
	jr z,l632ch		;6304	28 26		( &
	ld hl,l5a3ch		;6306	21 3c 5a	! < Z
	call sub_692fh		;6309	cd 2f 69	. / i
	call sub_693bh		;630c	cd 3b 69	. ; i
	call l58c8h		;630f	cd c8 58	. . X
	jr nz,l62c3h		;6312	20 af		  .
l6314h:
	ld a,(0436ch)		;6314	3a 6c 43	: l C
	and 082h		;6317	e6 82		. .
	cp 080h			;6319	fe 80		. .
	jr nz,l632ch		;631b	20 0f		  .
	ld hl,(042ceh)		;631d	2a ce 42	* . B
	ld de,(l5978h)		;6320	ed 5b 78 59	. [ x Y
	or a			;6324	b7		.
	sbc hl,de		;6325	ed 52		. R
	ld a,037h		;6327	3e 37		> 7
	jp nz,l521ah		;6329	c2 1a 52	. . R
l632ch:
	ld hl,l5996h		;632c	21 96 59	! . Y
	res 7,(hl)		;632f	cb be		. .
	ld a,(l5996h)		;6331	3a 96 59	: . Y
	bit 3,a			;6334	cb 5f		. _
	jp nz,l5d16h		;6336	c2 16 5d	. . ]
	ld hl,(l59d1h)		;6339	2a d1 59	* . Y
	ld de,(l59c3h)		;633c	ed 5b c3 59	. [ . Y
	rst 18h			;6340	df		.
	ld a,(l5992h+2)		;6341	3a 94 59	: . Y
	ld c,a			;6344	4f		O
	ld hl,(l59c1h)		;6345	2a c1 59	* . Y
	jr nc,l6352h		;6348	30 08		0 .
	bit 1,c			;634a	cb 49		. I
	jp z,l5204h		;634c	ca 04 52	. . R
	ld hl,(l59cfh)		;634f	2a cf 59	* . Y
l6352h:
	ld (l5af1h),hl		;6352	22 f1 5a	" . Z
	jr z,l6365h		;6355	28 0e		( .
	bit 1,c			;6357	cb 49		. I
	jr nz,l6365h		;6359	20 0a		  .
	ld hl,l59cah		;635b	21 ca 59	! . Y
	ld a,(l59bch)		;635e	3a bc 59	: . Y
	cp (hl)			;6361	be		.
	jp nz,l5204h		;6362	c2 04 52	. . R
l6365h:
	call sub_674dh		;6365	cd 4d 67	. M g
	call sub_67c3h		;6368	cd c3 67	. . g
	ld hl,00000h		;636b	21 00 00	! . .
	ld (l5aefh),hl		;636e	22 ef 5a	" . Z
	ld (l5b21h),hl		;6371	22 21 5b	" ! [
	jp l5273h		;6374	c3 73 52	. s R
l6377h:
	ld bc,l594ch		;6377	01 4c 59	. L Y
	ld de,l5ae5h		;637a	11 e5 5a	. . Z
	call sub_6437h		;637d	cd 37 64	. 7 d
	ld bc,l5956h		;6380	01 56 59	. V Y
	ld de,l5b17h		;6383	11 17 5b	. . [
	call sub_6437h		;6386	cd 37 64	. 7 d
	call sub_5c96h		;6389	cd 96 5c	. . \
	call sub_568bh		;638c	cd 8b 56	. . V
	jp l5279h		;638f	c3 79 52	. y R
sub_6392h:
	call sub_6ecbh		;6392	cd cb 6e	. . n
	ret nc			;6395	d0		.
	ld (l5b1dh),a		;6396	32 1d 5b	2 . [
	ld (l5956h),a		;6399	32 56 59	2 V Y
	ld (04dfah),a		;639c	32 fa 4d	2 . M
	ret			;639f	c9		.
sub_63a0h:
	ld de,l64a9h		;63a0	11 a9 64	. . d
sub_63a3h:
	ld a,(hl)		;63a3	7e		~
	cp 03dh			;63a4	fe 3d		. =
	ret nz			;63a6	c0		.
	push de			;63a7	d5		.
	inc hl			;63a8	23		#
	call sub_6ee7h		;63a9	cd e7 6e	. . n
	pop de			;63ac	d1		.
	or a			;63ad	b7		.
	ld (de),a		;63ae	12		.
	ret nz			;63af	c0		.
	jp l5218h		;63b0	c3 18 52	. . R
sub_63b3h:
	ld b,003h		;63b3	06 03		. .
	call sub_5646h		;63b5	cd 46 56	. F V
	ld b,002h		;63b8	06 02		. .
	ld hl,l593bh		;63ba	21 3b 59	! ; Y
	set 7,(hl)		;63bd	cb fe		. .
	call sub_5646h		;63bf	cd 46 56	. F V
	ld bc,(l594ch)		;63c2	ed 4b 4c 59	. K L Y
	ld hl,l59b7h		;63c6	21 b7 59	! . Y
	ld a,0ffh		;63c9	3e ff		> .
	call sub_63ech		;63cb	cd ec 63	. . c
	ld bc,(l5956h)		;63ce	ed 4b 56 59	. K V Y
	ld hl,l59c5h		;63d2	21 c5 59	! . Y
	ld a,0ffh		;63d5	3e ff		> .
	call sub_63ech		;63d7	cd ec 63	. . c
	ld hl,l64a3h		;63da	21 a3 64	! . d
	ld c,(hl)		;63dd	4e		N
l63deh:
	inc hl			;63de	23		#
	ld e,(hl)		;63df	5e		^
	inc hl			;63e0	23		#
	ld d,(hl)		;63e1	56		V
	inc hl			;63e2	23		#
	ld a,(hl)		;63e3	7e		~
	or a			;63e4	b7		.
	jr z,l63e8h		;63e5	28 01		( .
	ld (de),a		;63e7	12		.
l63e8h:
	dec c			;63e8	0d		.
	jr nz,l63deh		;63e9	20 f3		  .
	ret			;63eb	c9		.
sub_63ech:
	cp 0ffh			;63ec	fe ff		. .
	ret z			;63ee	c8		.
	rlca			;63ef	07		.
	rlca			;63f0	07		.
	rlca			;63f1	07		.
	rlca			;63f2	07		.
	push hl			;63f3	e5		.
	ld hl,l5940h		;63f4	21 40 59	! @ Y
	push af			;63f7	f5		.
	ld a,c			;63f8	79		y
	or a			;63f9	b7		.
	jr nz,l6406h		;63fa	20 0a		  .
	dec a			;63fc	3d		=
	xor b			;63fd	a8		.
	inc hl			;63fe	23		#
	and (hl)		;63ff	a6		.
	ld (hl),a		;6400	77		w
	dec hl			;6401	2b		+
	inc b			;6402	04		.
	ld a,(hl)		;6403	7e		~
	or b			;6404	b0		.
	ld (hl),a		;6405	77		w
l6406h:
	ld a,(l5956h)		;6406	3a 56 59	: V Y
	ld b,a			;6409	47		G
	ld a,(l594ch)		;640a	3a 4c 59	: L Y
	cp b			;640d	b8		.
	jr nz,l6417h		;640e	20 07		  .
	ld a,(hl)		;6410	7e		~
	or 006h			;6411	f6 06		. .
	ld (hl),a		;6413	77		w
	inc hl			;6414	23		#
	ld (hl),001h		;6415	36 01		6 .
l6417h:
	call sub_6424h		;6417	cd 24 64	. $ d
	pop af			;641a	f1		.
	add a,l			;641b	85		.
	ld l,a			;641c	6f		o
	pop de			;641d	d1		.
	ld bc,0000ah		;641e	01 0a 00	. . .
	ldir			;6421	ed b0		. .
	ret			;6423	c9		.
sub_6424h:
	ld hl,00002h		;6424	21 02 00	! . .
	ld (l5b53h),hl		;6427	22 53 5b	" S [
	ld hl,04200h		;642a	21 00 42	! . B
	ld de,l5b49h		;642d	11 49 5b	. I [
	call 04436h		;6430	cd 36 44	. 6 D
	ret z			;6433	c8		.
	jp l521ah		;6434	c3 1a 52	. . R
sub_6437h:
	ld hl,l5940h		;6437	21 40 59	! @ Y
l643ah:
	ld a,(de)		;643a	1a		.
	cp 03ah			;643b	fe 3a		. :
	inc de			;643d	13		.
	jr nz,l6458h		;643e	20 18		  .
	ld a,(hl)		;6440	7e		~
	cp 006h			;6441	fe 06		. .
	jr nc,l6482h		;6443	30 3d		0 =
	push hl			;6445	e5		.
	push bc			;6446	c5		.
	ex de,hl		;6447	eb		.
	call sub_6ed7h		;6448	cd d7 6e	. . n
	pop bc			;644b	c1		.
	pop hl			;644c	e1		.
	or a			;644d	b7		.
	ld (bc),a		;644e	02		.
	ret nz			;644f	c0		.
	inc bc			;6450	03		.
	ld a,(bc)		;6451	0a		.
	bit 0,(hl)		;6452	cb 46		. F
	ret z			;6454	c8		.
	or (hl)			;6455	b6		.
	ld (hl),a		;6456	77		w
	ret			;6457	c9		.
l6458h:
	cp 003h			;6458	fe 03		. .
	jr nz,l643ah		;645a	20 de		  .
	ld a,(hl)		;645c	7e		~
	cp 006h			;645d	fe 06		. .
	jr c,l6474h		;645f	38 13		8 .
	ld a,(bc)		;6461	0a		.
	or a			;6462	b7		.
	inc bc			;6463	03		.
	jr nz,l6468h		;6464	20 02		  .
	set 0,(hl)		;6466	cb c6		. .
l6468h:
	add a,030h		;6468	c6 30		. 0
	ld (de),a		;646a	12		.
	dec de			;646b	1b		.
	ex de,hl		;646c	eb		.
	ld (hl),03ah		;646d	36 3a		6 :
	inc hl			;646f	23		#
	inc hl			;6470	23		#
	ld (hl),003h		;6471	36 03		6 .
	ret			;6473	c9		.
l6474h:
	bit 0,a			;6474	cb 47		. G
	jr nz,l6482h		;6476	20 0a		  .
	ld a,(l5997h)		;6478	3a 97 59	: . Y
	and 0c0h		;647b	e6 c0		. .
	ld h,b			;647d	60		`
	ld l,c			;647e	69		i
	jp z,sub_5538h		;647f	ca 38 55	. 8 U
l6482h:
	jp l5200h		;6482	c3 00 52	. . R
l6485h:
	nop			;6485	00		.
	rst 30h			;6486	f7		.
	nop			;6487	00		.
	nop			;6488	00		.
	nop			;6489	00		.
	nop			;648a	00		.
	nop			;648b	00		.
	nop			;648c	00		.
	nop			;648d	00		.
	nop			;648e	00		.
	nop			;648f	00		.
	nop			;6490	00		.
l6491h:
	nop			;6491	00		.
	nop			;6492	00		.
	nop			;6493	00		.
	nop			;6494	00		.
	nop			;6495	00		.
	nop			;6496	00		.
	nop			;6497	00		.
	nop			;6498	00		.
	nop			;6499	00		.
	nop			;649a	00		.
	nop			;649b	00		.
	nop			;649c	00		.
	nop			;649d	00		.
	nop			;649e	00		.
	nop			;649f	00		.
	nop			;64a0	00		.
	nop			;64a1	00		.
	nop			;64a2	00		.
l64a3h:
	inc b			;64a3	04		.
	cp d			;64a4	ba		.
	ld e,c			;64a5	59		Y
l64a6h:
	nop			;64a6	00		.
	ret z			;64a7	c8		.
	ld e,c			;64a8	59		Y
l64a9h:
	nop			;64a9	00		.
	call 00059h		;64aa	cd 59 00	. Y .
	adc a,059h		;64ad	ce 59		. Y
l64afh:
	nop			;64af	00		.
sub_64b0h:
	ld hl,04200h		;64b0	21 00 42	! . B
	ld b,000h		;64b3	06 00		. .
l64b5h:
	ld (hl),a		;64b5	77		w
	inc hl			;64b6	23		#
	djnz l64b5h		;64b7	10 fc		. .
	ret			;64b9	c9		.
l64bah:
	nop			;64ba	00		.
	cp 011h			;64bb	fe 11		. .
	di			;64bd	f3		.
	ld hl,037ech		;64be	21 ec 37	! . 7
	ld (hl),0feh		;64c1	36 fe		6 .
	ld (hl),0d0h		;64c3	36 d0		6 .
	inc hl			;64c5	23		#
	nop			;64c6	00		.
	nop			;64c7	00		.
	inc hl			;64c8	23		#
	ld (hl),080h		;64c9	36 80		6 .
	ld de,00005h		;64cb	11 05 00	. . .
	exx			;64ce	d9		.
	ld sp,041e0h		;64cf	31 e0 41	1 . A
	ld hl,l51ffh		;64d2	21 ff 51	! . Q
l64d5h:
	call 04252h		;64d5	cd 52 42	. R B
	cp 020h			;64d8	fe 20		.  
	ld b,a			;64da	47		G
	jr nc,l6506h		;64db	30 29		0 )
	ld d,a			;64dd	57		W
	call 04252h		;64de	cd 52 42	. R B
	ld c,a			;64e1	4f		O
	call 04252h		;64e2	cd 52 42	. R B
	ld e,a			;64e5	5f		_
	djnz l64fah		;64e6	10 12		. .
	call 04252h		;64e8	cd 52 42	. R B
	ld d,a			;64eb	57		W
	dec c			;64ec	0d		.
	dec c			;64ed	0d		.
l64eeh:
	inc l			;64ee	2c		,
	call z,04255h		;64ef	cc 55 42	. U B
	ld a,(hl)		;64f2	7e		~
	ld (de),a		;64f3	12		.
	inc de			;64f4	13		.
l64f5h:
	dec c			;64f5	0d		.
	jr nz,l64eeh		;64f6	20 f6		  .
	jr l64d5h		;64f8	18 db		. .
l64fah:
	djnz l64f5h		;64fa	10 f9		. .
	call 04252h		;64fc	cd 52 42	. R B
	ld d,a			;64ff	57		W
	ld a,(de)		;6500	1a		.
	cp 0a5h			;6501	fe a5		. .
	inc de			;6503	13		.
	push de			;6504	d5		.
	ret z			;6505	c8		.
l6506h:
	ld hl,042e5h		;6506	21 e5 42	! . B
	jp 042c3h		;6509	c3 c3 42	. . B
	inc l			;650c	2c		,
	ld a,(hl)		;650d	7e		~
	ret nz			;650e	c0		.
	exx			;650f	d9		.
	ld b,00ah		;6510	06 0a		. .
l6512h:
	ld hl,037e1h		;6512	21 e1 37	! . 7
	ld (hl),001h		;6515	36 01		6 .
	push de			;6517	d5		.
	push bc			;6518	c5		.
	ld a,e			;6519	7b		{
	sub 000h		;651a	d6 00		. .
	jr c,l6521h		;651c	38 03		8 .
	ld e,a			;651e	5f		_
	ld (hl),009h		;651f	36 09		6 .
l6521h:
	ld hl,037ech		;6521	21 ec 37	! . 7
	call 042ceh		;6524	cd ce 42	. . B
	ld (037eeh),de		;6527	ed 53 ee 37	. S . 7
	ld (hl),01bh		;652b	36 1b		6 .
	call 042ceh		;652d	cd ce 42	. . B
	ld (hl),088h		;6530	36 88		6 .
	ld de,037efh		;6532	11 ef 37	. . 7
	ld bc,l5100h		;6535	01 00 51	. . Q
	call 042d7h		;6538	cd d7 42	. . B
	ld a,(hl)		;653b	7e		~
	and 083h		;653c	e6 83		. .
	jp po,04281h		;653e	e2 81 42	. . B
l6541h:
	ld a,(de)		;6541	1a		.
	ld (bc),a		;6542	02		.
	inc bc			;6543	03		.
l6544h:
	bit 1,(hl)		;6544	cb 4e		. N
	jp nz,04287h		;6546	c2 87 42	. . B
	bit 1,(hl)		;6549	cb 4e		. N
	jp nz,04287h		;654b	c2 87 42	. . B
	bit 1,(hl)		;654e	cb 4e		. N
	jr nz,l6541h		;6550	20 ef		  .
	bit 0,(hl)		;6552	cb 46		. F
	jr z,l655eh		;6554	28 08		( .
	bit 1,(hl)		;6556	cb 4e		. N
	jr nz,l6541h		;6558	20 e7		  .
	bit 7,(hl)		;655a	cb 7e		. ~
	jr z,l6544h		;655c	28 e6		( .
l655eh:
	ld a,(hl)		;655e	7e		~
	ld (hl),0d0h		;655f	36 d0		6 .
	pop bc			;6561	c1		.
	pop de			;6562	d1		.
	and 0fch		;6563	e6 fc		. .
	jr nz,l6573h		;6565	20 0c		  .
	inc e			;6567	1c		.
	ld a,e			;6568	7b		{
	sub 000h		;6569	d6 00		. .
	jr nz,l6570h		;656b	20 03		  .
	inc d			;656d	14		.
	ld e,000h		;656e	1e 00		. .
l6570h:
	exx			;6570	d9		.
	ld a,(hl)		;6571	7e		~
	ret			;6572	c9		.
l6573h:
	call 042d7h		;6573	cd d7 42	. . B
	ld (hl),00bh		;6576	36 0b		6 .
	djnz l6512h		;6578	10 98		. .
	ld hl,042ddh		;657a	21 dd 42	! . B
l657dh:
	ld a,(hl)		;657d	7e		~
	cp 003h			;657e	fe 03		. .
	jr z,l657dh		;6580	28 fb		( .
	inc hl			;6582	23		#
	call 00033h		;6583	cd 33 00	. 3 .
	jr l657dh		;6586	18 f5		. .
	call 042d7h		;6588	cd d7 42	. . B
l658bh:
	bit 0,(hl)		;658b	cb 46		. F
	jr nz,l658bh		;658d	20 fc		  .
	ld a,(hl)		;658f	7e		~
	ret			;6590	c9		.
	ld a,012h		;6591	3e 12		> .
l6593h:
	dec a			;6593	3d		=
	jr nz,l6593h		;6594	20 fd		  .
	ret			;6596	c9		.
	inc e			;6597	1c		.
	rra			;6598	1f		.
	ccf			;6599	3f		?
	ld bc,03f3fh		;659a	01 3f 3f	. ? ?
	ccf			;659d	3f		?
	inc bc			;659e	03		.
	inc e			;659f	1c		.
	rra			;65a0	1f		.
	ld b,a			;65a1	47		G
	dec l			;65a2	2d		-
	ld b,h			;65a3	44		D
	ld c,a			;65a4	4f		O
	ld d,e			;65a5	53		S
	ccf			;65a6	3f		?
	inc bc			;65a7	03		.
	nop			;65a8	00		.
	nop			;65a9	00		.
	ld b,b			;65aa	40		@
	daa			;65ab	27		'
	jr c,l65e2h		;65ac	38 34		8 4
	jr nz,l6604h		;65ae	20 54		  T
l65b0h:
	ld b,e			;65b0	43		C
	ld d,e			;65b1	53		S
	ld h,04dh		;65b2	26 4d		& M
	ld d,(hl)		;65b4	56		V
	ld b,e			;65b5	43		C
	nop			;65b6	00		.
l65b7h:
	nop			;65b7	00		.
l65b8h:
	nop			;65b8	00		.
l65b9h:
	nop			;65b9	00		.
l65bah:
	ld e,(hl)		;65ba	5e		^
	nop			;65bb	00		.
	nop			;65bc	00		.
	nop			;65bd	00		.
	nop			;65be	00		.
	ld b,a			;65bf	47		G
	ld b,h			;65c0	44		D
	ld c,a			;65c1	4f		O
	ld d,e			;65c2	53		S
	jr nz,l65e5h		;65c3	20 20		   
	jr nz,l65e7h		;65c5	20 20		   
	ld d,e			;65c7	53		S
	ld e,c			;65c8	59		Y
	ld d,e			;65c9	53		S
	ld h,b			;65ca	60		`
	ld a,a			;65cb	7f		.
	rra			;65cc	1f		.
	or d			;65cd	b2		.
	dec b			;65ce	05		.
	nop			;65cf	00		.
	nop			;65d0	00		.
	nop			;65d1	00		.
	rst 38h			;65d2	ff		.
	rst 38h			;65d3	ff		.
	rst 38h			;65d4	ff		.
	rst 38h			;65d5	ff		.
	rst 38h			;65d6	ff		.
	rst 38h			;65d7	ff		.
	rst 38h			;65d8	ff		.
	rst 38h			;65d9	ff		.
l65dah:
	ld e,l			;65da	5d		]
	nop			;65db	00		.
	nop			;65dc	00		.
	nop			;65dd	00		.
	nop			;65de	00		.
	ld c,c			;65df	49		I
	ld c,(hl)		;65e0	4e		N
	ld c,b			;65e1	48		H
l65e2h:
	ld b,c			;65e2	41		A
	ld c,h			;65e3	4c		L
	ld d,h			;65e4	54		T
l65e5h:
	jr nz,l6607h		;65e5	20 20		   
l65e7h:
	ld d,e			;65e7	53		S
	ld e,c			;65e8	59		Y
	ld d,e			;65e9	53		S
	and a			;65ea	a7		.
	dec e			;65eb	1d		.
	ld sp,hl		;65ec	f9		.
	push hl			;65ed	e5		.
l65eeh:
	ld e,000h		;65ee	1e 00		. .
l65f0h:
	jr nc,l65f7h		;65f0	30 05		0 .
	rst 38h			;65f2	ff		.
	rst 38h			;65f3	ff		.
	rst 38h			;65f4	ff		.
	rst 38h			;65f5	ff		.
	rst 38h			;65f6	ff		.
l65f7h:
	rst 38h			;65f7	ff		.
	rst 38h			;65f8	ff		.
	rst 38h			;65f9	ff		.
l65fah:
	call sub_6392h		;65fa	cd 92 63	. . c
	jp nc,l5218h		;65fd	d2 18 52	. . R
	call sub_63a0h		;6600	cd a0 63	. . c
	push hl			;6603	e5		.
l6604h:
	ld hl,l5997h		;6604	21 97 59	! . Y
l6607h:
	set 2,(hl)		;6607	cb d6		. .
	pop hl			;6609	e1		.
	call l6eb5h		;660a	cd b5 6e	. . n
	call c,sub_4f95h	;660d	dc 95 4f	. . O
	call sub_6fb8h		;6610	cd b8 6f	. . o
	call l6eb5h		;6613	cd b5 6e	. . n
	jr nc,l661fh		;6616	30 07		0 .
	call sub_5025h		;6618	cd 25 50	. % P
	ld (l5981h),de		;661b	ed 53 81 59	. S . Y
l661fh:
	ld b,040h		;661f	06 40		. @
	call sub_4ea7h		;6621	cd a7 4e	. . N
	ld hl,l5992h+2		;6624	21 94 59	! . Y
	ld a,(hl)		;6627	7e		~
	and 0f9h		;6628	e6 f9		. .
	jr nz,l6630h		;662a	20 04		  .
	ld a,(hl)		;662c	7e		~
	or 080h			;662d	f6 80		. .
	ld (hl),a		;662f	77		w
l6630h:
	call sub_63b3h		;6630	cd b3 63	. . c
	ld hl,l6df3h		;6633	21 f3 6d	! . m
	call 04467h		;6636	cd 67 44	. g D
	call sub_6710h		;6639	cd 10 67	. . g
	call sub_4df3h		;663c	cd f3 4d	. . M
	ld hl,l552dh		;663f	21 2d 55	! - U
	push hl			;6642	e5		.
sub_6643h:
	call sub_67c3h		;6643	cd c3 67	. . g
	ld a,(l5997h)		;6646	3a 97 59	: . Y
	bit 3,a			;6649	cb 5f		. _
	ret nz			;664b	c0		.
	ld a,(l5996h)		;664c	3a 96 59	: . Y
	bit 7,a			;664f	cb 7f		. .
	ret nz			;6651	c0		.
	ld de,00000h		;6652	11 00 00	. . .
	call sub_5784h		;6655	cd 84 57	. . W
	ld a,(l5992h+2)		;6658	3a 94 59	: . Y
	bit 1,a			;665b	cb 4f		. O
	ret nz			;665d	c0		.
	ld hl,l6ddah		;665e	21 da 6d	! . m
	call 04467h		;6661	cd 67 44	. g D
	call sub_67aah		;6664	cd aa 67	. . g
	ld de,l6eb5h		;6667	11 b5 6e	. . n
	ld bc,00002h		;666a	01 02 00	. . .
	call z,sub_67b4h	;666d	cc b4 67	. . g
	jp nz,l521ah		;6670	c2 1a 52	. . R
	ld a,0ffh		;6673	3e ff		> .
	call sub_64b0h		;6675	cd b0 64	. . d
	ld de,(l59d1h)		;6678	ed 5b d1 59	. [ . Y
	ld hl,04200h		;667c	21 00 42	! . B
	ld (l5b1ah),hl		;667f	22 1a 5b	" . [
	ld c,l			;6682	4d		M
	push hl			;6683	e5		.
	call sub_5762h		;6684	cd 62 57	. b W
	pop hl			;6687	e1		.
	set 0,(hl)		;6688	cb c6		. .
	ld a,(l59cdh)		;668a	3a cd 59	: . Y
	ld (l59c5h),a		;668d	32 c5 59	2 . Y
	ld hl,(04399h)		;6690	2a 99 43	* . C
	ld (hl),a		;6693	77		w
	ld b,000h		;6694	06 00		. .
	ld e,a			;6696	5f		_
	ld a,(l59ceh)		;6697	3a ce 59	: . Y
	ld c,a			;669a	4f		O
	push de			;669b	d5		.
	ld hl,04200h		;669c	21 00 42	! . B
	call sub_621ch		;669f	cd 1c 62	. . b
	ld hl,l597eh		;66a2	21 7e 59	! ~ Y
	ld de,042cbh		;66a5	11 cb 42	. . B
	ld bc,00016h		;66a8	01 16 00	. . .
	ldir			;66ab	ed b0		. .
	pop hl			;66ad	e1		.
	ld a,(l59cah)		;66ae	3a ca 59	: . Y
	ld h,a			;66b1	67		g
	rlca			;66b2	07		.
	rlca			;66b3	07		.
	add a,h			;66b4	84		.
	call 04c92h		;66b5	cd 92 4c	. . L
	ld (l5b21h),hl		;66b8	22 21 5b	" ! [
	ld c,000h		;66bb	0e 00		. .
	jr l66fbh		;66bd	18 3c		. <
l66bfh:
	push bc			;66bf	c5		.
	xor a			;66c0	af		.
	call sub_64b0h		;66c1	cd b0 64	. . d
	ld a,c			;66c4	79		y
	dec a			;66c5	3d		=
	jr nz,l66e6h		;66c6	20 1e		  .
	ld hl,04200h		;66c8	21 00 42	! . B
	ld (hl),0a1h		;66cb	36 a1		6 .
	inc hl			;66cd	23		#
	ld (hl),0ceh		;66ce	36 ce		6 .
	ld a,(l59ceh)		;66d0	3a ce 59	: . Y
	sub 002h		;66d3	d6 02		. .
	ld c,a			;66d5	4f		O
	rlca			;66d6	07		.
	rlca			;66d7	07		.
	add a,c			;66d8	81		.
	ld (0421fh),a		;66d9	32 1f 42	2 . B
	add a,00ah		;66dc	c6 0a		. .
	ld (l65eeh),a		;66de	32 ee 65	2 . e
	ld (0670ch),a		;66e1	32 0c 67	2 . g
	jr l66fah		;66e4	18 14		. .
l66e6h:
	ld hl,l65bah		;66e6	21 ba 65	! . e
	cp 002h			;66e9	fe 02		. .
	jr c,l66f2h		;66eb	38 05		8 .
	jr nz,l66fah		;66ed	20 0b		  .
	ld hl,l65dah		;66ef	21 da 65	! . e
l66f2h:
	ld de,04200h		;66f2	11 00 42	. . B
	ld bc,00020h		;66f5	01 20 00	.   .
	ldir			;66f8	ed b0		. .
l66fah:
	pop bc			;66fa	c1		.
l66fbh:
	set 0,(ix+000h)		;66fb	dd cb 00 c6	. . . .
	call sub_57d4h		;66ff	cd d4 57	. . W
	res 0,(ix+000h)		;6702	dd cb 00 86	. . . .
	jp nz,l521ah		;6706	c2 1a 52	. . R
	inc c			;6709	0c		.
	ld a,c			;670a	79		y
	cp 00ah			;670b	fe 0a		. .
	jr c,l66bfh		;670d	38 b0		8 .
	ret			;670f	c9		.
sub_6710h:
	ld hl,l5956h		;6710	21 56 59	! V Y
sub_6713h:
	push ix			;6713	dd e5		. .
	call sub_6e76h		;6715	cd 76 6e	. v n
	ld a,(ix+004h)		;6718	dd 7e 04	. ~ .
	ld l,(ix+003h)		;671b	dd 6e 03	. n .
	call 04c92h		;671e	cd 92 4c	. . L
	ld (ix+00ah),l		;6721	dd 75 0a	. u .
	ld (ix+00bh),h		;6724	dd 74 0b	. t .
	call sub_5cf2h		;6727	cd f2 5c	. . \
	ld (ix+00ch),l		;672a	dd 75 0c	. u .
	ld (ix+00dh),h		;672d	dd 74 0d	. t .
	ld a,(ix+005h)		;6730	dd 7e 05	. ~ .
	call 04cb4h		;6733	cd b4 4c	. . L
	or a			;6736	b7		.
	jr z,l673ah		;6737	28 01		( .
	inc hl			;6739	23		#
l673ah:
	ld a,h			;673a	7c		|
	or a			;673b	b7		.
	jr nz,l6747h		;673c	20 09		  .
	ld a,l			;673e	7d		}
	cp 0c1h			;673f	fe c1		. .
	ld (ix+001h),a		;6741	dd 77 01	. w .
	pop ix			;6744	dd e1		. .
	ret c			;6746	d8		.
l6747h:
	ld hl,l6e57h		;6747	21 57 6e	! W n
	jp l5243h		;674a	c3 43 52	. C R
sub_674dh:
	call sub_61eah		;674d	cd ea 61	. . a
	ret z			;6750	c8		.
sub_6751h:
	ld a,(l5992h+2)		;6751	3a 94 59	: . Y
	bit 1,a			;6754	cb 4f		. O
	jr z,l6747h		;6756	28 ef		( .
	ret			;6758	c9		.
sub_6759h:
	ld a,(l59cbh)		;6759	3a cb 59	: . Y
	ld (l65b7h),a		;675c	32 b7 65	2 . e
	ld (064cah),a		;675f	32 ca 64	2 . d
	ld a,(l59cch)		;6762	3a cc 59	: . Y
	ld (l65b9h),a		;6765	32 b9 65	2 . e
	bit 1,a			;6768	cb 4f		. O
	jr z,l6770h		;676a	28 04		( .
	ld hl,064cdh		;676c	21 cd 64	! . d
	inc (hl)		;676f	34		4
l6770h:
	bit 4,a			;6770	cb 67		. g
	jr z,l677dh		;6772	28 09		( .
	ld hl,064cch		;6774	21 cc 64	! . d
	inc (hl)		;6777	34		4
	ld hl,0656fh		;6778	21 6f 65	! o e
	ld (hl),001h		;677b	36 01		6 .
l677dh:
	bit 0,a			;677d	cb 47		. G
	jr z,l6786h		;677f	28 05		( .
	ld hl,064c2h		;6781	21 c2 64	! . d
	set 0,(hl)		;6784	cb c6		. .
l6786h:
	bit 6,a			;6786	cb 77		. w
	ld a,(l59c9h)		;6788	3a c9 59	: . Y
	ld (0656ah),a		;678b	32 6a 65	2 j e
	jr z,l6791h		;678e	28 01		( .
	rrca			;6790	0f		.
l6791h:
	ld (0651bh),a		;6791	32 1b 65	2 . e
	ld a,(l59cdh)		;6794	3a cd 59	: . Y
	ld (064bch),a		;6797	32 bc 64	2 . d
	ld l,a			;679a	6f		o
	ld a,(l59ceh)		;679b	3a ce 59	: . Y
	ld h,a			;679e	67		g
	dec h			;679f	25		%
	ld (l65f0h),hl		;67a0	22 f0 65	" . e
	ld a,(l59c7h)		;67a3	3a c7 59	: . Y
	ld (l65b8h),a		;67a6	32 b8 65	2 . e
	ret			;67a9	c9		.
sub_67aah:
	ld bc,00000h		;67aa	01 00 00	. . .
	call sub_67b1h		;67ad	cd b1 67	. . g
	inc bc			;67b0	03		.
sub_67b1h:
	ld de,l64bah		;67b1	11 ba 64	. . d
sub_67b4h:
	ld (l5b1ah),de		;67b4	ed 53 1a 5b	. S . [
	ld ix,l5b17h		;67b8	dd 21 17 5b	. ! . [
	ld (l5b21h),bc		;67bc	ed 43 21 5b	. C ! [
	jp sub_57d4h		;67c0	c3 d4 57	. . W
sub_67c3h:
	call sub_6759h		;67c3	cd 59 67	. Y g
	ld ix,l5b17h		;67c6	dd 21 17 5b	. ! . [
l67cah:
	call sub_557dh		;67ca	cd 7d 55	. } U
	ld a,(l5992h+2)		;67cd	3a 94 59	: . Y
	ld c,a			;67d0	4f		O
	bit 6,c			;67d1	cb 71		. q
	jp nz,l6886h		;67d3	c2 86 68	. . h
	call sub_57c8h		;67d6	cd c8 57	. . W
	jr z,l67eeh		;67d9	28 13		( .
	cp 005h			;67db	fe 05		. .
	jp nz,l521ah		;67dd	c2 1a 52	. . R
	bit 7,c			;67e0	cb 79		. y
	jp nz,l6886h		;67e2	c2 86 68	. . h
	ld hl,l6d95h		;67e5	21 95 6d	! . m
	call 04467h		;67e8	cd 67 44	. g D
	jp l6880h		;67eb	c3 80 68	. . h
l67eeh:
	xor a			;67ee	af		.
	call 0490ah		;67ef	cd 0a 49	. . I
	jr z,l6806h		;67f2	28 12		( .
	ld l,a			;67f4	6f		o
	ld a,c			;67f5	79		y
	and 019h		;67f6	e6 19		. .
	ld a,l			;67f8	7d		}
	jp nz,l521ah		;67f9	c2 1a 52	. . R
	ld hl,042d0h		;67fc	21 d0 42	! . B
	ld b,010h		;67ff	06 10		. .
l6801h:
	ld (hl),03fh		;6801	36 3f		6 ?
	inc hl			;6803	23		#
	djnz l6801h		;6804	10 fb		. .
l6806h:
	bit 7,c			;6806	cb 79		. y
	jr z,l6812h		;6808	28 08		( .
	ld hl,l6d82h		;680a	21 82 6d	! . m
	call 04467h		;680d	cd 67 44	. g D
	jr l687ah		;6810	18 68		. h
l6812h:
	ld a,(0436ch)		;6812	3a 6c 43	: l C
	and 082h		;6815	e6 82		. .
	cp 080h			;6817	fe 80		. .
	jr nz,l6840h		;6819	20 25		  %
	ld a,(l5996h)		;681b	3a 96 59	: . Y
	bit 3,a			;681e	cb 5f		. _
	jr z,l6840h		;6820	28 1e		( .
	ld a,(l5995h)		;6822	3a 95 59	: . Y
	bit 0,a			;6825	cb 47		. G
	jr z,l6835h		;6827	28 0c		( .
	ld hl,(042ceh)		;6829	2a ce 42	* . B
	ld de,(l597ah)		;682c	ed 5b 7a 59	. [ z Y
	or a			;6830	b7		.
	sbc hl,de		;6831	ed 52		. R
	jr z,l6840h		;6833	28 0b		( .
l6835h:
	ld hl,l5a44h		;6835	21 44 5a	! D Z
	call 04467h		;6838	cd 67 44	. g D
	ld a,037h		;683b	3e 37		> 7
	jp l521ah		;683d	c3 1a 52	. . R
l6840h:
	bit 3,c			;6840	cb 59		. Y
	jr z,l6851h		;6842	28 0d		( .
	push bc			;6844	c5		.
	ld hl,042d0h		;6845	21 d0 42	! . B
	ld de,l5983h		;6848	11 83 59	. . Y
	ld bc,00008h		;684b	01 08 00	. . .
	ldir			;684e	ed b0		. .
	pop bc			;6850	c1		.
l6851h:
	bit 0,c			;6851	cb 41		. A
	jr z,l6862h		;6853	28 0d		( .
	push bc			;6855	c5		.
	ld hl,042d8h		;6856	21 d8 42	! . B
	ld de,l598bh		;6859	11 8b 59	. . Y
	ld bc,00008h		;685c	01 08 00	. . .
	ldir			;685f	ed b0		. .
	pop bc			;6861	c1		.
l6862h:
	bit 4,c			;6862	cb 61		. a
	jr z,l6876h		;6864	28 10		( .
	ld hl,l5970h		;6866	21 70 59	! p Y
	call 0624fh		;6869	cd 4f 62	. O b
	jr z,l6876h		;686c	28 08		( .
	ld hl,l5a44h		;686e	21 44 5a	! D Z
	call sub_692fh		;6871	cd 2f 69	. / i
	jr l687ah		;6874	18 04		. .
l6876h:
	bit 5,c			;6876	cb 69		. i
	jr z,l6886h		;6878	28 0c		( .
l687ah:
	ld hl,l5a44h		;687a	21 44 5a	! D Z
	call sub_693bh		;687d	cd 3b 69	. ; i
l6880h:
	call l58c8h		;6880	cd c8 58	. . X
	jp nz,l67cah		;6883	c2 ca 67	. . g
l6886h:
	ld a,(l5997h)		;6886	3a 97 59	: . Y
	bit 3,a			;6889	cb 5f		. _
	ret nz			;688b	c0		.
	ld a,(l59c7h)		;688c	3a c7 59	: . Y
	bit 5,a			;688f	cb 6f		. o
	call nz,sub_6751h	;6891	c4 51 67	. Q g
	ld hl,l6d61h		;6894	21 61 6d	! a m
	call 04467h		;6897	cd 67 44	. g D
	call 0476eh		;689a	cd 6e 47	. n G
	call z,04745h		;689d	cc 45 47	. E G
	jp nz,l521ah		;68a0	c2 1a 52	. . R
	ld a,(l5997h)		;68a3	3a 97 59	: . Y
	and 002h		;68a6	e6 02		. .
	jr z,l68d0h		;68a8	28 26		( &
	ld de,00001h		;68aa	11 01 00	. . .
	ld a,d			;68ad	7a		z
	add a,e			;68ae	83		.
l68afh:
	ld c,a			;68af	4f		O
	jr c,l68b6h		;68b0	38 04		8 .
	ld a,(l59c8h)		;68b2	3a c8 59	: . Y
	cp c			;68b5	b9		.
l68b6h:
	jp c,l5218h		;68b6	da 18 52	. . R
	bit 1,(iy-06fh)		;68b9	fd cb 91 4e	. . . N
	jr z,l68c0h		;68bd	28 01		( .
	inc d			;68bf	14		.
l68c0h:
	ld a,d			;68c0	7a		z
	ld (06af4h),a		;68c1	32 f4 6a	2 . j
	ld (037efh),a		;68c4	32 ef 37	2 . 7
	ld c,018h		;68c7	0e 18		. .
	call 04747h		;68c9	cd 47 47	. G G
	ld a,d			;68cc	7a		z
	add a,e			;68cd	83		.
	jr l6922h		;68ce	18 52		. R
l68d0h:
	ld a,(l59c8h)		;68d0	3a c8 59	: . Y
	ld hl,l5996h		;68d3	21 96 59	! . Y
	bit 7,(hl)		;68d6	cb 7e		. ~
	jr nz,l6922h		;68d8	20 48		  H
	bit 6,(iy-074h)		;68da	fd cb 8c 76	. . . v
	jr z,l6922h		;68de	28 42		( B
	push ix			;68e0	dd e5		. .
	ld ix,(04399h)		;68e2	dd 2a 99 43	. * . C
	ld a,001h		;68e6	3e 01		> .
	ld e,(iy-06fh)		;68e8	fd 5e 91	. ^ .
	xor e			;68eb	ab		.
	and 0c1h		;68ec	e6 c1		. .
	ld (ix+007h),a		;68ee	dd 77 07	. w .
	ld d,(ix+004h)		;68f1	dd 56 04	. V .
	ld (ix+004h),00ah	;68f4	dd 36 04 0a	. 6 . .
	ex (sp),ix		;68f8	dd e3		. .
	push de			;68fa	d5		.
	ld a,001h		;68fb	3e 01		> .
	call sub_6959h		;68fd	cd 59 69	. Y i
	jr nz,l6905h		;6900	20 03		  .
	call sub_67aah		;6902	cd aa 67	. . g
l6905h:
	pop de			;6905	d1		.
	ex (sp),ix		;6906	dd e3		. .
	push af			;6908	f5		.
	ld (ix+007h),e		;6909	dd 73 07	. s .
	ld (ix+004h),d		;690c	dd 72 04	. r .
	call 04773h		;690f	cd 73 47	. s G
	ex af,af'		;6912	08		.
	pop af			;6913	f1		.
	pop ix			;6914	dd e1		. .
	jr nz,l6925h		;6916	20 0d		  .
	ex af,af'		;6918	08		.
	jr nz,l6925h		;6919	20 0a		  .
	call sub_6cafh		;691b	cd af 6c	. . l
	ld a,(l59c8h)		;691e	3a c8 59	: . Y
	inc a			;6921	3c		<
l6922h:
	call sub_6959h		;6922	cd 59 69	. Y i
l6925h:
	ei			;6925	fb		.
	ret z			;6926	c8		.
	cp 0ffh			;6927	fe ff		. .
	jp nz,l521ah		;6929	c2 1a 52	. . R
	jp l5243h		;692c	c3 43 52	. C R
sub_692fh:
	push hl			;692f	e5		.
	call 04467h		;6930	cd 67 44	. g D
	ld hl,l6dc1h		;6933	21 c1 6d	! . m
	call 04467h		;6936	cd 67 44	. g D
	pop hl			;6939	e1		.
	ret			;693a	c9		.
sub_693bh:
	call 04467h		;693b	cd 67 44	. g D
	ld hl,l6da8h		;693e	21 a8 6d	! . m
	call 04467h		;6941	cd 67 44	. g D
	ld hl,042d0h		;6944	21 d0 42	! . B
	ld b,008h		;6947	06 08		. .
	call l5886h		;6949	cd 86 58	. . X
	ld b,004h		;694c	06 04		. .
	call l5898h		;694e	cd 98 58	. . X
	ld b,008h		;6951	06 08		. .
	call l5886h		;6953	cd 86 58	. . X
	jp sub_5881h		;6956	c3 81 58	. . X
sub_6959h:
	ld (06c75h),a		;6959	32 75 6c	2 u l
	call 04773h		;695c	cd 73 47	. s G
	ret nz			;695f	c0		.
	ld a,(04311h)		;6960	3a 11 43	: . C
	rlca			;6963	07		.
	and 003h		;6964	e6 03		. .
	ld l,01ah		;6966	2e 1a		. .
	call 04c92h		;6968	cd 92 4c	. . L
	ld de,l6cc2h		;696b	11 c2 6c	. . l
	add hl,de		;696e	19		.
	ld a,(hl)		;696f	7e		~
	ld (06b1ch),a		;6970	32 1c 6b	2 . k
	inc hl			;6973	23		#
	ld (l6b82h+1),a		;6974	32 83 6b	2 . k
	ld a,(hl)		;6977	7e		~
	ld (06ad8h),a		;6978	32 d8 6a	2 . j
	inc hl			;697b	23		#
	ld (06b4dh),a		;697c	32 4d 6b	2 M k
	ld a,(hl)		;697f	7e		~
	ld (06b6fh),a		;6980	32 6f 6b	2 o k
	inc hl			;6983	23		#
	ld a,(hl)		;6984	7e		~
	ld (06b76h),a		;6985	32 76 6b	2 v k
	inc hl			;6988	23		#
	ld a,(hl)		;6989	7e		~
	ld (06b8bh),a		;698a	32 8b 6b	2 . k
	inc hl			;698d	23		#
	ld a,(hl)		;698e	7e		~
	ld (06ac8h),a		;698f	32 c8 6a	2 . j
	inc hl			;6992	23		#
	ld a,(hl)		;6993	7e		~
	ld (06b26h),a		;6994	32 26 6b	2 & k
	inc hl			;6997	23		#
	ld a,(hl)		;6998	7e		~
	ld (06b3dh),a		;6999	32 3d 6b	2 = k
	inc hl			;699c	23		#
	ld e,(hl)		;699d	5e		^
	inc hl			;699e	23		#
	ld d,(hl)		;699f	56		V
	inc hl			;69a0	23		#
	ld c,(hl)		;69a1	4e		N
	inc hl			;69a2	23		#
	ld b,(hl)		;69a3	46		F
	ld (069dah),bc		;69a4	ed 43 da 69	. C . i
	inc hl			;69a8	23		#
	ld c,(hl)		;69a9	4e		N
	inc hl			;69aa	23		#
	ld b,(hl)		;69ab	46		F
	ld (l69f1h+1),bc	;69ac	ed 43 f2 69	. C . i
	inc hl			;69b0	23		#
	ld c,(hl)		;69b1	4e		N
	inc hl			;69b2	23		#
	ld b,(hl)		;69b3	46		F
	ld (069d6h),bc		;69b4	ed 43 d6 69	. C . i
	inc hl			;69b8	23		#
	ld a,(hl)		;69b9	7e		~
	ld (l69ffh+1),a		;69ba	32 00 6a	2 . j
	inc hl			;69bd	23		#
	ld a,(hl)		;69be	7e		~
	ld (06a33h),a		;69bf	32 33 6a	2 3 j
	inc hl			;69c2	23		#
	nop			;69c3	00		.
	nop			;69c4	00		.
	nop			;69c5	00		.
	xor a			;69c6	af		.
	ld (l6a01h+1),a		;69c7	32 02 6a	2 . j
	ld (06c63h),a		;69ca	32 63 6c	2 c l
	ex de,hl		;69cd	eb		.
	call sub_6ca4h		;69ce	cd a4 6c	. . l
	ld a,e			;69d1	7b		{
	call 04c94h		;69d2	cd 94 4c	. . L
	ld bc,00000h		;69d5	01 00 00	. . .
	ex de,hl		;69d8	eb		.
	ld hl,00000h		;69d9	21 00 00	! . .
	or a			;69dc	b7		.
	sbc hl,de		;69dd	ed 52		. R
	push hl			;69df	e5		.
	jr nc,l69f1h		;69e0	30 0f		0 .
	add hl,hl		;69e2	29		)
	add hl,hl		;69e3	29		)
	add hl,bc		;69e4	09		.
	jr c,l69eeh		;69e5	38 07		8 .
	pop hl			;69e7	e1		.
	ld hl,l6d6ch		;69e8	21 6c 6d	! l m
	or 0ffh			;69eb	f6 ff		. .
	ret			;69ed	c9		.
l69eeh:
	ld hl,00000h		;69ee	21 00 00	! . .
l69f1h:
	ld de,00000h		;69f1	11 00 00	. . .
	add hl,de		;69f4	19		.
	ld (06bcdh),hl		;69f5	22 cd 6b	" . k
	pop hl			;69f8	e1		.
	add hl,de		;69f9	19		.
	add hl,bc		;69fa	09		.
	add hl,bc		;69fb	09		.
	ld (06bd6h),hl		;69fc	22 d6 6b	" . k
l69ffh:
	ld a,002h		;69ff	3e 02		> .
l6a01h:
	add a,000h		;6a01	c6 00		. .
	call sub_6ca4h		;6a03	cd a4 6c	. . l
	cp e			;6a06	bb		.
	jr c,l6a0ah		;6a07	38 01		8 .
	sub e			;6a09	93		.
l6a0ah:
	ld (l6a01h+1),a		;6a0a	32 02 6a	2 . j
	ld (l6a01h+1),a		;6a0d	32 02 6a	2 . j
	inc a			;6a10	3c		<
	ld d,a			;6a11	57		W
	push de			;6a12	d5		.
	ld hl,l6485h		;6a13	21 85 64	! . d
	ld b,e			;6a16	43		C
l6a17h:
	ld (hl),0ffh		;6a17	36 ff		6 .
	inc hl			;6a19	23		#
	djnz l6a17h		;6a1a	10 fb		. .
	ld d,000h		;6a1c	16 00		. .
	ld b,d			;6a1e	42		B
	jr l6a26h		;6a1f	18 05		. .
l6a21h:
	inc c			;6a21	0c		.
	ld a,c			;6a22	79		y
	cp e			;6a23	bb		.
	jr c,l6a28h		;6a24	38 02		8 .
l6a26h:
	ld c,000h		;6a26	0e 00		. .
l6a28h:
	ld hl,l6485h		;6a28	21 85 64	! . d
	add hl,bc		;6a2b	09		.
	ld a,(hl)		;6a2c	7e		~
	inc a			;6a2d	3c		<
	jr nz,l6a21h		;6a2e	20 f1		  .
	ld (hl),d		;6a30	72		r
	ld a,c			;6a31	79		y
	add a,002h		;6a32	c6 02		. .
	cp e			;6a34	bb		.
	jr c,l6a38h		;6a35	38 01		8 .
	sub e			;6a37	93		.
l6a38h:
	ld c,a			;6a38	4f		O
	inc d			;6a39	14		.
	ld a,d			;6a3a	7a		z
	cp e			;6a3b	bb		.
	jr c,l6a28h		;6a3c	38 ea		8 .
	ld hl,l6a01h+1		;6a3e	21 02 6a	! . j
	ld a,(hl)		;6a41	7e		~
	add a,c			;6a42	81		.
	ld (hl),a		;6a43	77		w
l6a44h:
	pop de			;6a44	d1		.
	dec d			;6a45	15		.
	jr z,l6a58h		;6a46	28 10		( .
	ld c,e			;6a48	4b		K
	push de			;6a49	d5		.
	ld hl,l6482h+2		;6a4a	21 84 64	! . d
	add hl,bc		;6a4d	09		.
	ld d,h			;6a4e	54		T
	ld e,l			;6a4f	5d		]
	dec bc			;6a50	0b		.
	ld a,(hl)		;6a51	7e		~
	dec hl			;6a52	2b		+
	lddr			;6a53	ed b8		. .
	ld (de),a		;6a55	12		.
	jr l6a44h		;6a56	18 ec		. .
l6a58h:
	ld a,(04311h)		;6a58	3a 11 43	: . C
	bit 4,a			;6a5b	cb 67		. g
	jr z,l6a67h		;6a5d	28 08		( .
	ld b,e			;6a5f	43		C
	ld hl,l6485h		;6a60	21 85 64	! . d
l6a63h:
	inc (hl)		;6a63	34		4
	inc hl			;6a64	23		#
	djnz l6a63h		;6a65	10 fc		. .
l6a67h:
	ld a,00ah		;6a67	3e 0a		> .
	ld (l6c94h+1),a		;6a69	32 95 6c	2 . l
l6a6ch:
	call 04773h		;6a6c	cd 73 47	. s G
	ret nz			;6a6f	c0		.
	call l5733h		;6a70	cd 33 57	. 3 W
	ld hl,04309h		;6a73	21 09 43	! . C
	ld b,(iy-06fh)		;6a76	fd 46 91	. F .
	ld a,b			;6a79	78		x
	and 040h		;6a7a	e6 40		. @
	jr z,l6a87h		;6a7c	28 09		( .
	ld a,(06c63h)		;6a7e	3a 63 6c	: c l
	and 001h		;6a81	e6 01		. .
	call 04cf8h		;6a83	cd f8 4c	. . L
	nop			;6a86	00		.
l6a87h:
	ld (06afch),a		;6a87	32 fc 6a	2 . j
	call 04767h		;6a8a	cd 67 47	. g G
	call 04750h		;6a8d	cd 50 47	. P G
	ld de,037efh		;6a90	11 ef 37	. . 7
	ld hl,037ech		;6a93	21 ec 37	! . 7
	ld bc,l6485h		;6a96	01 85 64	. . d
	push hl			;6a99	e5		.
	push de			;6a9a	d5		.
	exx			;6a9b	d9		.
	call sub_6ca4h		;6a9c	cd a4 6c	. . l
	ld c,e			;6a9f	4b		K
	pop de			;6aa0	d1		.
	pop hl			;6aa1	e1		.
	di			;6aa2	f3		.
	call 047e3h		;6aa3	cd e3 47	. . G
	ld (hl),0f4h		;6aa6	36 f4		6 .
	call 047e3h		;6aa8	cd e3 47	. . G
	ld a,001h		;6aab	3e 01		> .
	ex af,af'		;6aad	08		.
	inc c			;6aae	0c		.
	jp l6b82h		;6aaf	c3 82 6b	. . k
l6ab2h:
	ex af,af'		;6ab2	08		.
l6ab3h:
	cp (hl)			;6ab3	be		.
	jr z,l6ab3h		;6ab4	28 fd		( .
	ex af,af'		;6ab6	08		.
	ld (de),a		;6ab7	12		.
l6ab8h:
	ex af,af'		;6ab8	08		.
l6ab9h:
	cp (hl)			;6ab9	be		.
	jr z,l6ab9h		;6aba	28 fd		( .
	ex af,af'		;6abc	08		.
	ld (de),a		;6abd	12		.
	djnz l6ab8h		;6abe	10 f8		. .
	xor a			;6ac0	af		.
	ex af,af'		;6ac1	08		.
l6ac2h:
	cp (hl)			;6ac2	be		.
	jr z,l6ac2h		;6ac3	28 fd		( .
	ex af,af'		;6ac5	08		.
	ld (de),a		;6ac6	12		.
	ld b,001h		;6ac7	06 01		. .
l6ac9h:
	ex af,af'		;6ac9	08		.
l6acah:
	cp (hl)			;6aca	be		.
	jr z,l6acah		;6acb	28 fd		( .
	ex af,af'		;6acd	08		.
	ld (de),a		;6ace	12		.
	djnz l6ac9h		;6acf	10 f8		. .
	ex af,af'		;6ad1	08		.
l6ad2h:
	cp (hl)			;6ad2	be		.
	jr z,l6ad2h		;6ad3	28 fd		( .
	ex af,af'		;6ad5	08		.
	ld (de),a		;6ad6	12		.
	ld a,000h		;6ad7	3e 00		> .
	ex af,af'		;6ad9	08		.
l6adah:
	cp (hl)			;6ada	be		.
	jr z,l6adah		;6adb	28 fd		( .
	ex af,af'		;6add	08		.
	ld (de),a		;6ade	12		.
	ex af,af'		;6adf	08		.
l6ae0h:
	cp (hl)			;6ae0	be		.
	jr z,l6ae0h		;6ae1	28 fd		( .
	ex af,af'		;6ae3	08		.
	ld (de),a		;6ae4	12		.
	ex af,af'		;6ae5	08		.
l6ae6h:
	cp (hl)			;6ae6	be		.
	jr z,l6ae6h		;6ae7	28 fd		( .
	ex af,af'		;6ae9	08		.
	ld (de),a		;6aea	12		.
	ld a,0feh		;6aeb	3e fe		> .
	ex af,af'		;6aed	08		.
l6aeeh:
	cp (hl)			;6aee	be		.
	jr z,l6aeeh		;6aef	28 fd		( .
	ex af,af'		;6af1	08		.
	ld (de),a		;6af2	12		.
	ld a,000h		;6af3	3e 00		> .
	ex af,af'		;6af5	08		.
l6af6h:
	cp (hl)			;6af6	be		.
	jr z,l6af6h		;6af7	28 fd		( .
	ex af,af'		;6af9	08		.
	ld (de),a		;6afa	12		.
	ld a,000h		;6afb	3e 00		> .
	ex af,af'		;6afd	08		.
l6afeh:
	cp (hl)			;6afe	be		.
	jr z,l6afeh		;6aff	28 fd		( .
	ex af,af'		;6b01	08		.
	ld (de),a		;6b02	12		.
	exx			;6b03	d9		.
	ld a,(bc)		;6b04	0a		.
	ex af,af'		;6b05	08		.
l6b06h:
	cp (hl)			;6b06	be		.
	jr z,l6b06h		;6b07	28 fd		( .
	ex af,af'		;6b09	08		.
	ld (de),a		;6b0a	12		.
	ld a,001h		;6b0b	3e 01		> .
	ex af,af'		;6b0d	08		.
l6b0eh:
	cp (hl)			;6b0e	be		.
	jr z,l6b0eh		;6b0f	28 fd		( .
	ex af,af'		;6b11	08		.
	ld (de),a		;6b12	12		.
	ld a,0f7h		;6b13	3e f7		> .
	ex af,af'		;6b15	08		.
l6b16h:
	cp (hl)			;6b16	be		.
	jr z,l6b16h		;6b17	28 fd		( .
	ex af,af'		;6b19	08		.
	ld (de),a		;6b1a	12		.
	ld a,0ffh		;6b1b	3e ff		> .
	ex af,af'		;6b1d	08		.
l6b1eh:
	cp (hl)			;6b1e	be		.
	jr z,l6b1eh		;6b1f	28 fd		( .
	ex af,af'		;6b21	08		.
	ld (de),a		;6b22	12		.
	inc bc			;6b23	03		.
	exx			;6b24	d9		.
	ld b,00ah		;6b25	06 0a		. .
	ex af,af'		;6b27	08		.
l6b28h:
	cp (hl)			;6b28	be		.
	jr z,l6b28h		;6b29	28 fd		( .
	ex af,af'		;6b2b	08		.
	ld (de),a		;6b2c	12		.
l6b2dh:
	ex af,af'		;6b2d	08		.
l6b2eh:
	cp (hl)			;6b2e	be		.
	jr z,l6b2eh		;6b2f	28 fd		( .
	ex af,af'		;6b31	08		.
	ld (de),a		;6b32	12		.
	djnz l6b2dh		;6b33	10 f8		. .
	xor a			;6b35	af		.
	ex af,af'		;6b36	08		.
l6b37h:
	cp (hl)			;6b37	be		.
	jr z,l6b37h		;6b38	28 fd		( .
	ex af,af'		;6b3a	08		.
	ld (de),a		;6b3b	12		.
	ld b,004h		;6b3c	06 04		. .
l6b3eh:
	ex af,af'		;6b3e	08		.
l6b3fh:
	cp (hl)			;6b3f	be		.
	jr z,l6b3fh		;6b40	28 fd		( .
	ex af,af'		;6b42	08		.
	ld (de),a		;6b43	12		.
	djnz l6b3eh		;6b44	10 f8		. .
	ex af,af'		;6b46	08		.
l6b47h:
	cp (hl)			;6b47	be		.
	jr z,l6b47h		;6b48	28 fd		( .
	ex af,af'		;6b4a	08		.
	ld (de),a		;6b4b	12		.
	ld a,000h		;6b4c	3e 00		> .
	ex af,af'		;6b4e	08		.
l6b4fh:
	cp (hl)			;6b4f	be		.
	jr z,l6b4fh		;6b50	28 fd		( .
	ex af,af'		;6b52	08		.
	ld (de),a		;6b53	12		.
	ex af,af'		;6b54	08		.
l6b55h:
	cp (hl)			;6b55	be		.
	jr z,l6b55h		;6b56	28 fd		( .
	ex af,af'		;6b58	08		.
	ld (de),a		;6b59	12		.
	ex af,af'		;6b5a	08		.
l6b5bh:
	cp (hl)			;6b5b	be		.
	jr z,l6b5bh		;6b5c	28 fd		( .
	ex af,af'		;6b5e	08		.
	ld (de),a		;6b5f	12		.
	ld b,080h		;6b60	06 80		. .
	ex af,af'		;6b62	08		.
l6b63h:
	cp (hl)			;6b63	be		.
	jr z,l6b63h		;6b64	28 fd		( .
	ex de,hl		;6b66	eb		.
	ld (hl),0fbh		;6b67	36 fb		6 .
	ex de,hl		;6b69	eb		.
l6b6ah:
	cp (hl)			;6b6a	be		.
	jr z,l6b6ah		;6b6b	28 fd		( .
	ex de,hl		;6b6d	eb		.
	ld (hl),0e5h		;6b6e	36 e5		6 .
	ex de,hl		;6b70	eb		.
l6b71h:
	cp (hl)			;6b71	be		.
	jr z,l6b71h		;6b72	28 fd		( .
	ex de,hl		;6b74	eb		.
	ld (hl),0e5h		;6b75	36 e5		6 .
	ex de,hl		;6b77	eb		.
	djnz l6b6ah		;6b78	10 f0		. .
l6b7ah:
	cp (hl)			;6b7a	be		.
	jr z,l6b7ah		;6b7b	28 fd		( .
	ex de,hl		;6b7d	eb		.
	ld (hl),0f7h		;6b7e	36 f7		6 .
	ex de,hl		;6b80	eb		.
	ex af,af'		;6b81	08		.
l6b82h:
	ld a,0ffh		;6b82	3e ff		> .
	ex af,af'		;6b84	08		.
l6b85h:
	cp (hl)			;6b85	be		.
	jr z,l6b85h		;6b86	28 fd		( .
	ex af,af'		;6b88	08		.
	ld (de),a		;6b89	12		.
	ld b,00ah		;6b8a	06 0a		. .
	dec c			;6b8c	0d		.
	jp nz,l6ab2h		;6b8d	c2 b2 6a	. . j
	ld bc,00001h		;6b90	01 01 00	. . .
	ex af,af'		;6b93	08		.
l6b94h:
	cp (hl)			;6b94	be		.
	jr z,l6b94h		;6b95	28 fd		( .
	ex af,af'		;6b97	08		.
l6b98h:
	ld (de),a		;6b98	12		.
	inc bc			;6b99	03		.
	nop			;6b9a	00		.
l6b9bh:
	bit 1,(hl)		;6b9b	cb 4e		. N
	jp nz,l6b98h		;6b9d	c2 98 6b	. . k
	bit 1,(hl)		;6ba0	cb 4e		. N
	jp nz,l6b98h		;6ba2	c2 98 6b	. . k
	bit 1,(hl)		;6ba5	cb 4e		. N
	jr nz,l6b98h		;6ba7	20 ef		  .
	bit 0,(hl)		;6ba9	cb 46		. F
	jr z,l6bb5h		;6bab	28 08		( .
	bit 1,(hl)		;6bad	cb 4e		. N
	jr nz,l6b98h		;6baf	20 e7		  .
	bit 7,(hl)		;6bb1	cb 7e		. ~
	jr z,l6b9bh		;6bb3	28 e6		( .
l6bb5h:
	ld a,(hl)		;6bb5	7e		~
	ld (hl),0d0h		;6bb6	36 d0		6 .
	ld h,b			;6bb8	60		`
	ld l,c			;6bb9	69		i
	ld b,a			;6bba	47		G
	call 04767h		;6bbb	cd 67 47	. g G
	ld a,(l5996h)		;6bbe	3a 96 59	: . Y
	bit 7,a			;6bc1	cb 7f		. .
	jp nz,l6c5ch		;6bc3	c2 5c 6c	. \ l
	ld a,b			;6bc6	78		x
	and 0fch		;6bc7	e6 fc		. .
	jp nz,l6c89h		;6bc9	c2 89 6c	. . l
	ld bc,00000h		;6bcc	01 00 00	. . .
	or a			;6bcf	b7		.
	sbc hl,bc		;6bd0	ed 42		. B
	jp c,l6c7dh		;6bd2	da 7d 6c	. } l
	ld bc,0007dh		;6bd5	01 7d 00	. } .
	or a			;6bd8	b7		.
	sbc hl,bc		;6bd9	ed 42		. B
	jp nc,l6c82h		;6bdb	d2 82 6c	. . l
	ld a,088h		;6bde	3e 88		> .
	ld (046c4h),a		;6be0	32 c4 46	2 . F
	ld hl,(04649h)		;6be3	2a 49 46	* I F
	ld (046fch),hl		;6be6	22 fc 46	" . F
	ld hl,l6485h		;6be9	21 85 64	! . d
	call sub_6ca4h		;6bec	cd a4 6c	. . l
l6befh:
	inc hl			;6bef	23		#
	ld a,(hl)		;6bf0	7e		~
l6bf1h:
	ld (037eeh),a		;6bf1	32 ee 37	2 . 7
	ld a,(037edh)		;6bf4	3a ed 37	: . 7
	push hl			;6bf7	e5		.
	ld hl,0471ah		;6bf8	21 1a 47	! . G
	ld d,(hl)		;6bfb	56		V
	push de			;6bfc	d5		.
	push hl			;6bfd	e5		.
	ld (hl),0c9h		;6bfe	36 c9		6 .
	push af			;6c00	f5		.
	ld a,(06af4h)		;6c01	3a f4 6a	: . j
	ld (037edh),a		;6c04	32 ed 37	2 . 7
	ld bc,03b00h		;6c07	01 00 3b	. . ;
	call 046bdh		;6c0a	cd bd 46	. . F
l6c0dh:
	ld b,a			;6c0d	47		G
	pop af			;6c0e	f1		.
	ld (037edh),a		;6c0f	32 ed 37	2 . 7
	pop hl			;6c12	e1		.
	pop de			;6c13	d1		.
	ld (hl),d		;6c14	72		r
	pop hl			;6c15	e1		.
	ld a,b			;6c16	78		x
	and 09ch		;6c17	e6 9c		. .
	jr z,l6c51h		;6c19	28 36		( 6
	ld hl,l6c94h+1		;6c1b	21 95 6c	! . l
	dec (hl)		;6c1e	35		5
	jp nz,l6a6ch		;6c1f	c2 6c 6a	. l j
l6c22h:
	ei			;6c22	fb		.
	ld hl,l6eabh		;6c23	21 ab 6e	! . n
	ld a,(06c63h)		;6c26	3a 63 6c	: c l
	or a			;6c29	b7		.
	jr z,l6c2fh		;6c2a	28 03		( .
	ld hl,l6eb0h		;6c2c	21 b0 6e	! . n
l6c2fh:
	ld de,06e96h		;6c2f	11 96 6e	. . n
	ld bc,00005h		;6c32	01 05 00	. . .
	ldir			;6c35	ed b0		. .
	ld hl,l6e89h		;6c37	21 89 6e	! . n
	call 04467h		;6c3a	cd 67 44	. g D
	ld a,(06af4h)		;6c3d	3a f4 6a	: . j
	ld e,a			;6c40	5f		_
	ld d,000h		;6c41	16 00		. .
	call sub_5909h		;6c43	cd 09 59	. . Y
	call sub_5881h		;6c46	cd 81 58	. . X
	call l58c8h		;6c49	cd c8 58	. . X
	jp nz,l6a67h		;6c4c	c2 67 6a	. g j
	jr l6c5ch		;6c4f	18 0b		. .
l6c51h:
	dec e			;6c51	1d		.
	ld a,001h		;6c52	3e 01		> .
	cp e			;6c54	bb		.
	jr c,l6befh		;6c55	38 98		8 .
	ld a,(l6485h)		;6c57	3a 85 64	: . d
	jr z,l6bf1h		;6c5a	28 95		( .
l6c5ch:
	bit 6,(iy-06fh)		;6c5c	fd cb 91 76	. . . v
	jr z,l6c6fh		;6c60	28 0d		( .
	ld a,000h		;6c62	3e 00		> .
	xor 001h		;6c64	ee 01		. .
	ld (06c63h),a		;6c66	32 63 6c	2 c l
	jr z,l6c6fh		;6c69	28 04		( .
	xor a			;6c6b	af		.
	jp l6a01h		;6c6c	c3 01 6a	. . j
l6c6fh:
	ld hl,06af4h		;6c6f	21 f4 6a	! . j
	inc (hl)		;6c72	34		4
	ld a,(hl)		;6c73	7e		~
	cp 023h			;6c74	fe 23		. #
	ret z			;6c76	c8		.
	call sub_6cafh		;6c77	cd af 6c	. . l
	jp l69ffh		;6c7a	c3 ff 69	. . i
l6c7dh:
	ld hl,l6d6ch		;6c7d	21 6c 6d	! l m
	jr l6c85h		;6c80	18 03		. .
l6c82h:
	ld hl,l6d77h		;6c82	21 77 6d	! w m
l6c85h:
	ld b,0ffh		;6c85	06 ff		. .
	jr l6c94h		;6c87	18 0b		. .
l6c89h:
	ld b,011h		;6c89	06 11		. .
l6c8bh:
	dec b			;6c8b	05		.
	rlca			;6c8c	07		.
	jr nc,l6c8bh		;6c8d	30 fc		0 .
	ld a,b			;6c8f	78		x
	cp 00fh			;6c90	fe 0f		. .
	jr z,l6ca2h		;6c92	28 0e		( .
l6c94h:
	ld a,000h		;6c94	3e 00		> .
	dec a			;6c96	3d		=
	ld (l6c94h+1),a		;6c97	32 95 6c	2 . l
	jp nz,l6a6ch		;6c9a	c2 6c 6a	. l j
	ld a,b			;6c9d	78		x
	cp 00bh			;6c9e	fe 0b		. .
	jr z,l6c22h		;6ca0	28 80		( .
l6ca2h:
	or a			;6ca2	b7		.
	ret			;6ca3	c9		.
sub_6ca4h:
	ld e,(iy-072h)		;6ca4	fd 5e 8e	. ^ .
	bit 6,(iy-06fh)		;6ca7	fd cb 91 76	. . . v
	ret z			;6cab	c8		.
	srl e			;6cac	cb 3b		. ;
	ret			;6cae	c9		.
sub_6cafh:
	ld a,(04311h)		;6caf	3a 11 43	: . C
	bit 2,a			;6cb2	cb 57		. W
	call nz,sub_6cb7h	;6cb4	c4 b7 6c	. . l
sub_6cb7h:
	ld bc,00100h		;6cb7	01 00 01	. . .
	call 04cedh		;6cba	cd ed 4c	. . L
	ld c,058h		;6cbd	0e 58		. X
	jp 04747h		;6cbf	c3 47 47	. G G
l6cc2h:
	rst 38h			;6cc2	ff		.
	nop			;6cc3	00		.
	push hl			;6cc4	e5		.
	push hl			;6cc5	e5		.
	add hl,bc		;6cc6	09		.
	ld bc,00109h		;6cc7	01 09 01	. . .
	inc l			;6cca	2c		,
	ld bc,00bech		;6ccb	01 ec 0b	. . .
	dec bc			;6cce	0b		.
	nop			;6ccf	00		.
	ld a,000h		;6cd0	3e 00		> .
	ld (bc),a		;6cd2	02		.
	ld (bc),a		;6cd3	02		.
	nop			;6cd4	00		.
	nop			;6cd5	00		.
	nop			;6cd6	00		.
	nop			;6cd7	00		.
	nop			;6cd8	00		.
	nop			;6cd9	00		.
	nop			;6cda	00		.
	nop			;6cdb	00		.
	rst 38h			;6cdc	ff		.
	nop			;6cdd	00		.
	push hl			;6cde	e5		.
	push hl			;6cdf	e5		.
	ex af,af'		;6ce0	08		.
	ld bc,00109h		;6ce1	01 09 01	. . .
	dec hl			;6ce4	2b		+
	ld bc,013e6h		;6ce5	01 e6 13	. . .
	ld a,(bc)		;6ce8	0a		.
	nop			;6ce9	00		.
	ld l,b			;6cea	68		h
	nop			;6ceb	00		.
	ld (bc),a		;6cec	02		.
	ld (bc),a		;6ced	02		.
	nop			;6cee	00		.
	nop			;6cef	00		.
	nop			;6cf0	00		.
	nop			;6cf1	00		.
	nop			;6cf2	00		.
	nop			;6cf3	00		.
	nop			;6cf4	00		.
	nop			;6cf5	00		.
	ld c,(hl)		;6cf6	4e		N
	push af			;6cf7	f5		.
	ld l,l			;6cf8	6d		m
	or (hl)			;6cf9	b6		.
	ld c,006h		;6cfa	0e 06		. .
	inc d			;6cfc	14		.
	ld a,(bc)		;6cfd	0a		.
	ld c,d			;6cfe	4a		J
	ld bc,017ddh		;6cff	01 dd 17	. . .
	djnz l6d04h		;6d02	10 00		. .
l6d04h:
	ld a,l			;6d04	7d		}
	nop			;6d05	00		.
	ld (bc),a		;6d06	02		.
	ld (bc),a		;6d07	02		.
	nop			;6d08	00		.
	nop			;6d09	00		.
	nop			;6d0a	00		.
	nop			;6d0b	00		.
	nop			;6d0c	00		.
	nop			;6d0d	00		.
	nop			;6d0e	00		.
	nop			;6d0f	00		.
	ld c,(hl)		;6d10	4e		N
	push af			;6d11	f5		.
	ld l,l			;6d12	6d		m
	or (hl)			;6d13	b6		.
	inc de			;6d14	13		.
	ld a,(bc)		;6d15	0a		.
	inc d			;6d16	14		.
	ld a,(bc)		;6d17	0a		.
	ld d,e			;6d18	53		S
	ld bc,027bah		;6d19	01 ba 27	. . '
	ld h,000h		;6d1c	26 00		& .
	ret nc			;6d1e	d0		.
	nop			;6d1f	00		.
	ld (bc),a		;6d20	02		.
	ld (bc),a		;6d21	02		.
	nop			;6d22	00		.
	nop			;6d23	00		.
	nop			;6d24	00		.
	nop			;6d25	00		.
	nop			;6d26	00		.
	nop			;6d27	00		.
	nop			;6d28	00		.
	nop			;6d29	00		.
	nop			;6d2a	00		.
	nop			;6d2b	00		.
	nop			;6d2c	00		.
	nop			;6d2d	00		.
	nop			;6d2e	00		.
	nop			;6d2f	00		.
	nop			;6d30	00		.
	nop			;6d31	00		.
	nop			;6d32	00		.
	nop			;6d33	00		.
	nop			;6d34	00		.
	nop			;6d35	00		.
	nop			;6d36	00		.
	nop			;6d37	00		.
	nop			;6d38	00		.
	nop			;6d39	00		.
	nop			;6d3a	00		.
	nop			;6d3b	00		.
	nop			;6d3c	00		.
	nop			;6d3d	00		.
	nop			;6d3e	00		.
	nop			;6d3f	00		.
	nop			;6d40	00		.
	nop			;6d41	00		.
	nop			;6d42	00		.
	nop			;6d43	00		.
	nop			;6d44	00		.
	nop			;6d45	00		.
	nop			;6d46	00		.
	nop			;6d47	00		.
	nop			;6d48	00		.
	nop			;6d49	00		.
	nop			;6d4a	00		.
	nop			;6d4b	00		.
	nop			;6d4c	00		.
	nop			;6d4d	00		.
	nop			;6d4e	00		.
	nop			;6d4f	00		.
	nop			;6d50	00		.
	nop			;6d51	00		.
	nop			;6d52	00		.
	nop			;6d53	00		.
	nop			;6d54	00		.
	nop			;6d55	00		.
	nop			;6d56	00		.
	nop			;6d57	00		.
	nop			;6d58	00		.
	nop			;6d59	00		.
	nop			;6d5a	00		.
	nop			;6d5b	00		.
	nop			;6d5c	00		.
	nop			;6d5d	00		.
l6d5eh:
	inc e			;6d5e	1c		.
	rra			;6d5f	1f		.
	inc bc			;6d60	03		.
l6d61h:
	ld b,(hl)		;6d61	46		F
	ld l,a			;6d62	6f		o
	ld (hl),d		;6d63	72		r
	ld l,l			;6d64	6d		m
	ld h,c			;6d65	61		a
	ld (hl),h		;6d66	74		t
	ld l,c			;6d67	69		i
	ld h,l			;6d68	65		e
	ld (hl),d		;6d69	72		r
	ld h,l			;6d6a	65		e
	dec c			;6d6b	0d		.
l6d6ch:
	ld a,d			;6d6c	7a		z
	ld (hl),l		;6d6d	75		u
	jr nz,$+117		;6d6e	20 73		  s
	ld h,e			;6d70	63		c
	ld l,b			;6d71	68		h
	ld l,(hl)		;6d72	6e		n
	ld h,l			;6d73	65		e
	ld l,h			;6d74	6c		l
	ld l,h			;6d75	6c		l
	dec c			;6d76	0d		.
l6d77h:
	ld a,d			;6d77	7a		z
	ld (hl),l		;6d78	75		u
	jr nz,$+110		;6d79	20 6c		  l
	ld h,c			;6d7b	61		a
	ld l,(hl)		;6d7c	6e		n
	ld h,a			;6d7d	67		g
	ld (hl),e		;6d7e	73		s
	ld h,c			;6d7f	61		a
	ld l,l			;6d80	6d		m
	dec c			;6d81	0d		.
l6d82h:
	ld b,h			;6d82	44		D
	ld l,c			;6d83	69		i
	ld (hl),e		;6d84	73		s
	ld l,e			;6d85	6b		k
	ld h,l			;6d86	65		e
	ld (hl),h		;6d87	74		t
	ld (hl),h		;6d88	74		t
	ld h,l			;6d89	65		e
	jr nz,l6df4h		;6d8a	20 68		  h
	ld h,c			;6d8c	61		a
	ld (hl),h		;6d8d	74		t
	jr nz,l6dd4h		;6d8e	20 44		  D
	ld h,c			;6d90	61		a
	ld (hl),h		;6d91	74		t
	ld h,l			;6d92	65		e
	ld l,(hl)		;6d93	6e		n
	dec c			;6d94	0d		.
l6d95h:
	ld d,l			;6d95	55		U
	ld l,(hl)		;6d96	6e		n
	ld l,h			;6d97	6c		l
	ld h,l			;6d98	65		e
	ld (hl),e		;6d99	73		s
	ld h,d			;6d9a	62		b
	ld h,c			;6d9b	61		a
	ld (hl),d		;6d9c	72		r
	ld h,l			;6d9d	65		e
	jr nz,l6de4h		;6d9e	20 44		  D
	ld l,c			;6da0	69		i
	ld (hl),e		;6da1	73		s
	ld l,e			;6da2	6b		k
	ld h,l			;6da3	65		e
	ld (hl),h		;6da4	74		t
	ld (hl),h		;6da5	74		t
	ld h,l			;6da6	65		e
	dec c			;6da7	0d		.
l6da8h:
	ex af,af'		;6da8	08		.
	ld h,h			;6da9	64		d
	ld l,c			;6daa	69		i
	ld (hl),e		;6dab	73		s
	ld l,e			;6dac	6b		k
	ld h,l			;6dad	65		e
	ld (hl),h		;6dae	74		t
	ld (hl),h		;6daf	74		t
	ld h,l			;6db0	65		e
	ld l,(hl)		;6db1	6e		n
	ld l,(hl)		;6db2	6e		n
	ld h,c			;6db3	61		a
	ld l,l			;6db4	6d		m
	ld h,l			;6db5	65		e
	inc l			;6db6	2c		,
	jr nz,l6de6h		;6db7	20 2d		  -
	ld h,h			;6db9	64		d
	ld h,c			;6dba	61		a
	ld (hl),h		;6dbb	74		t
	ld (hl),l		;6dbc	75		u
	ld l,l			;6dbd	6d		m
	ld a,(00320h)		;6dbe	3a 20 03	:   .
l6dc1h:
	ex af,af'		;6dc1	08		.
	ld h,h			;6dc2	64		d
	ld l,c			;6dc3	69		i
	ld (hl),e		;6dc4	73		s
	ld l,e			;6dc5	6b		k
	ld h,l			;6dc6	65		e
	ld (hl),h		;6dc7	74		t
	ld (hl),h		;6dc8	74		t
	ld h,l			;6dc9	65		e
	ld l,(hl)		;6dca	6e		n
	ld l,(hl)		;6dcb	6e		n
	ld h,c			;6dcc	61		a
	ld l,l			;6dcd	6d		m
	ld h,l			;6dce	65		e
	jr nz,l6e37h		;6dcf	20 66		  f
	ld h,c			;6dd1	61		a
	ld l,h			;6dd2	6c		l
	ld (hl),e		;6dd3	73		s
l6dd4h:
	ld h,e			;6dd4	63		c
	ld l,b			;6dd5	68		h
	jr nz,l6df8h		;6dd6	20 20		   
	ld a,(bc)		;6dd8	0a		.
	dec c			;6dd9	0d		.
l6ddah:
	ld d,e			;6dda	53		S
	ld h,e			;6ddb	63		c
	ld l,b			;6ddc	68		h
	ld (hl),d		;6ddd	72		r
	ld h,l			;6dde	65		e
	ld l,c			;6ddf	69		i
	ld h,d			;6de0	62		b
	ld h,l			;6de1	65		e
	jr nz,l6e52h		;6de2	20 6e		  n
l6de4h:
	ld (hl),l		;6de4	75		u
	ld l,(hl)		;6de5	6e		n
l6de6h:
	jr nz,l6e3bh		;6de6	20 53		  S
	ld a,c			;6de8	79		y
	ld (hl),e		;6de9	73		s
	ld (hl),h		;6dea	74		t
	ld h,l			;6deb	65		e
	ld l,l			;6dec	6d		m
	ld h,h			;6ded	64		d
	ld h,c			;6dee	61		a
	ld (hl),h		;6def	74		t
	ld h,l			;6df0	65		e
	ld l,(hl)		;6df1	6e		n
	dec c			;6df2	0d		.
l6df3h:
	ld b,h			;6df3	44		D
l6df4h:
	ld l,c			;6df4	69		i
	ld (hl),e		;6df5	73		s
	ld l,e			;6df6	6b		k
	ld h,l			;6df7	65		e
l6df8h:
	ld (hl),h		;6df8	74		t
	ld (hl),h		;6df9	74		t
	ld h,l			;6dfa	65		e
	jr nz,l6e74h		;6dfb	20 77		  w
	ld l,c			;6dfd	69		i
	ld (hl),d		;6dfe	72		r
	ld h,h			;6dff	64		d
	jr nz,l6e68h		;6e00	20 66		  f
	ld l,a			;6e02	6f		o
	ld (hl),d		;6e03	72		r
	ld l,l			;6e04	6d		m
	ld h,c			;6e05	61		a
	ld (hl),h		;6e06	74		t
	ld l,c			;6e07	69		i
	ld h,l			;6e08	65		e
	ld (hl),d		;6e09	72		r
	ld (hl),h		;6e0a	74		t
	dec c			;6e0b	0d		.
l6e0ch:
	ld b,h			;6e0c	44		D
	ld l,c			;6e0d	69		i
	ld (hl),e		;6e0e	73		s
	ld l,e			;6e0f	6b		k
	ld h,l			;6e10	65		e
	ld (hl),h		;6e11	74		t
	ld (hl),h		;6e12	74		t
	ld h,l			;6e13	65		e
	jr nz,l6e8dh		;6e14	20 77		  w
	ld l,c			;6e16	69		i
	ld (hl),d		;6e17	72		r
	ld h,h			;6e18	64		d
	jr nz,l6e86h		;6e19	20 6b		  k
	ld l,a			;6e1b	6f		o
	ld (hl),b		;6e1c	70		p
	ld l,c			;6e1d	69		i
	ld h,l			;6e1e	65		e
	ld (hl),d		;6e1f	72		r
	ld (hl),h		;6e20	74		t
	dec c			;6e21	0d		.
l6e22h:
	ld d,e			;6e22	53		S
	ld l,c			;6e23	69		i
	ld l,(hl)		;6e24	6e		n
	ld h,h			;6e25	64		d
	jr nz,l6e7bh		;6e26	20 53		  S
	ld a,c			;6e28	79		y
	ld (hl),e		;6e29	73		s
	ld (hl),h		;6e2a	74		t
	ld h,l			;6e2b	65		e
	ld l,l			;6e2c	6d		m
	jr nz,l6ea4h		;6e2d	20 75		  u
	ld l,(hl)		;6e2f	6e		n
	ld h,h			;6e30	64		d
	jr nz,l6e36h		;6e31	20 03		  .
l6e33h:
	jr nz,l6e9eh		;6e33	20 69		  i
	ld h,h			;6e35	64		d
l6e36h:
	ld h,l			;6e36	65		e
l6e37h:
	ld l,(hl)		;6e37	6e		n
	ld (hl),h		;6e38	74		t
	ld l,c			;6e39	69		i
	ld (hl),e		;6e3a	73		s
l6e3bh:
	ld h,e			;6e3b	63		c
	ld l,b			;6e3c	68		h
	ccf			;6e3d	3f		?
	inc bc			;6e3e	03		.
l6e3fh:
	ld b,h			;6e3f	44		D
	ld l,c			;6e40	69		i
	ld (hl),e		;6e41	73		s
	ld l,e			;6e42	6b		k
	ld h,l			;6e43	65		e
	ld (hl),h		;6e44	74		t
	ld (hl),h		;6e45	74		t
	ld h,l			;6e46	65		e
	jr nz,l6eafh		;6e47	20 66		  f
	ld l,a			;6e49	6f		o
	ld (hl),d		;6e4a	72		r
	ld l,l			;6e4b	6d		m
	ld h,c			;6e4c	61		a
	ld (hl),h		;6e4d	74		t
	ld l,c			;6e4e	69		i
	ld h,l			;6e4f	65		e
	ld (hl),d		;6e50	72		r
	ld h,l			;6e51	65		e
l6e52h:
	ld l,(hl)		;6e52	6e		n
	ccf			;6e53	3f		?
	inc bc			;6e54	03		.
	jr nz,l6e77h		;6e55	20 20		   
l6e57h:
	ld d,b			;6e57	50		P
	ld h,c			;6e58	61		a
	ld (hl),d		;6e59	72		r
	ld h,c			;6e5a	61		a
	ld l,l			;6e5b	6d		m
	ld h,l			;6e5c	65		e
	ld (hl),h		;6e5d	74		t
	ld h,l			;6e5e	65		e
	ld (hl),d		;6e5f	72		r
	jr nz,l6ed1h		;6e60	20 6f		  o
	ld h,h			;6e62	64		d
	ld h,l			;6e63	65		e
	ld (hl),d		;6e64	72		r
	jr nz,$+82		;6e65	20 50		  P
	ld b,h			;6e67	44		D
l6e68h:
	dec l			;6e68	2d		-
	ld b,h			;6e69	44		D
	ld h,c			;6e6a	61		a
	ld (hl),h		;6e6b	74		t
	ld h,l			;6e6c	65		e
	ld l,(hl)		;6e6d	6e		n
	jr nz,l6ed6h		;6e6e	20 66		  f
	ld h,c			;6e70	61		a
	ld l,h			;6e71	6c		l
	ld (hl),e		;6e72	73		s
	ld h,e			;6e73	63		c
l6e74h:
	ld l,b			;6e74	68		h
	dec c			;6e75	0d		.
sub_6e76h:
	ld a,(hl)		;6e76	7e		~
l6e77h:
	call 04776h		;6e77	cd 76 47	. v G
	inc hl			;6e7a	23		#
l6e7bh:
	inc hl			;6e7b	23		#
	inc hl			;6e7c	23		#
	inc hl			;6e7d	23		#
	ld l,(hl)		;6e7e	6e		n
	push hl			;6e7f	e5		.
	pop ix			;6e80	dd e1		. .
	ret			;6e82	c9		.
	nop			;6e83	00		.
	nop			;6e84	00		.
	nop			;6e85	00		.
l6e86h:
	nop			;6e86	00		.
	nop			;6e87	00		.
	nop			;6e88	00		.
l6e89h:
	ld b,(hl)		;6e89	46		F
	ld l,a			;6e8a	6f		o
	ld (hl),d		;6e8b	72		r
	ld l,l			;6e8c	6d		m
l6e8dh:
	ld h,c			;6e8d	61		a
	ld (hl),h		;6e8e	74		t
	ld h,(hl)		;6e8f	66		f
	ld h,l			;6e90	65		e
	ld l,b			;6e91	68		h
	ld l,h			;6e92	6c		l
	ld h,l			;6e93	65		e
	ld (hl),d		;6e94	72		r
	jr nz,l6eddh		;6e95	20 46		  F
	ld (hl),d		;6e97	72		r
	ld l,a			;6e98	6f		o
	ld l,(hl)		;6e99	6e		n
	ld (hl),h		;6e9a	74		t
	ld (hl),e		;6e9b	73		s
	ld h,l			;6e9c	65		e
	ld l,c			;6e9d	69		i
l6e9eh:
	ld (hl),h		;6e9e	74		t
	ld h,l			;6e9f	65		e
	jr nz,$+120		;6ea0	20 76		  v
	ld l,a			;6ea2	6f		o
	ld l,(hl)		;6ea3	6e		n
l6ea4h:
	jr nz,$+85		;6ea4	20 53		  S
	ld (hl),b		;6ea6	70		p
	ld (hl),l		;6ea7	75		u
	ld (hl),d		;6ea8	72		r
	jr nz,l6eaeh		;6ea9	20 03		  .
l6eabh:
	ld b,(hl)		;6eab	46		F
	ld (hl),d		;6eac	72		r
	ld l,a			;6ead	6f		o
l6eaeh:
	ld l,(hl)		;6eae	6e		n
l6eafh:
	ld (hl),h		;6eaf	74		t
l6eb0h:
	jr nz,l6f04h		;6eb0	20 52		  R
	ld a,l			;6eb2	7d		}
	ld h,e			;6eb3	63		c
	ld l,e			;6eb4	6b		k
l6eb5h:
	call sub_6ec0h		;6eb5	cd c0 6e	. . n
	ret z			;6eb8	c8		.
	call 04cd9h		;6eb9	cd d9 4c	. . L
	ret c			;6ebc	d8		.
	ret z			;6ebd	c8		.
	dec hl			;6ebe	2b		+
	ret			;6ebf	c9		.
sub_6ec0h:
	ld a,(hl)		;6ec0	7e		~
	cp 00dh			;6ec1	fe 0d		. .
	ret z			;6ec3	c8		.
sub_6ec4h:
	call 04cd9h		;6ec4	cd d9 4c	. . L
	ret nc			;6ec7	d0		.
l6ec8h:
	jp l521ah		;6ec8	c3 1a 52	. . R
sub_6ecbh:
	ld a,(hl)		;6ecb	7e		~
	cp 03ah			;6ecc	fe 3a		. :
	jr nz,l6ed1h		;6ece	20 01		  .
	inc hl			;6ed0	23		#
l6ed1h:
	ld a,(hl)		;6ed1	7e		~
	sub 030h		;6ed2	d6 30		. 0
	cp 00ah			;6ed4	fe 0a		. .
l6ed6h:
	ret nc			;6ed6	d0		.
sub_6ed7h:
	call sub_6ee7h		;6ed7	cd e7 6e	. . n
	call 04776h		;6eda	cd 76 47	. v G
l6eddh:
	jr nz,l6ec8h		;6edd	20 e9		  .
	ld a,e			;6edf	7b		{
	scf			;6ee0	37		7
	ret			;6ee1	c9		.
sub_6ee2h:
	call sub_6ef1h		;6ee2	cd f1 6e	. . n
	jr l6eeah		;6ee5	18 03		. .
sub_6ee7h:
	call sub_6f0fh		;6ee7	cd 0f 6f	. . o
l6eeah:
	ld a,d			;6eea	7a		z
	or a			;6eeb	b7		.
	ld a,e			;6eec	7b		{
	ret z			;6eed	c8		.
l6eeeh:
	jp l5218h		;6eee	c3 18 52	. . R
sub_6ef1h:
	push hl			;6ef1	e5		.
	call sub_6f14h		;6ef2	cd 14 6f	. . o
	ld a,(hl)		;6ef5	7e		~
	sub 041h		;6ef6	d6 41		. A
	cp 008h			;6ef8	fe 08		. .
	jr nc,l6f09h		;6efa	30 0d		0 .
	pop hl			;6efc	e1		.
	ld b,001h		;6efd	06 01		. .
	push hl			;6eff	e5		.
	call sub_6f16h		;6f00	cd 16 6f	. . o
	ld a,(hl)		;6f03	7e		~
l6f04h:
	cp 048h			;6f04	fe 48		. H
	inc hl			;6f06	23		#
	jr nz,l6eeeh		;6f07	20 e5		  .
l6f09h:
	bit 1,b			;6f09	cb 48		. H
	pop bc			;6f0b	c1		.
	ret nz			;6f0c	c0		.
	jr l6eeeh		;6f0d	18 df		. .
sub_6f0fh:
	push hl			;6f0f	e5		.
	ld de,l6f09h		;6f10	11 09 6f	. . o
	push de			;6f13	d5		.
sub_6f14h:
	ld b,000h		;6f14	06 00		. .
sub_6f16h:
	ld de,00000h		;6f16	11 00 00	. . .
l6f19h:
	ld a,(hl)		;6f19	7e		~
	sub 030h		;6f1a	d6 30		. 0
	cp 00ah			;6f1c	fe 0a		. .
	jr c,l6f2ah		;6f1e	38 0a		8 .
	bit 0,b			;6f20	cb 40		. @
	ret z			;6f22	c8		.
	sub 011h		;6f23	d6 11		. .
	cp 006h			;6f25	fe 06		. .
	ret nc			;6f27	d0		.
	add a,00ah		;6f28	c6 0a		. .
l6f2ah:
	push hl			;6f2a	e5		.
	ld h,d			;6f2b	62		b
	ld l,e			;6f2c	6b		k
	ld c,a			;6f2d	4f		O
	xor a			;6f2e	af		.
	set 1,b			;6f2f	cb c8		. .
	add hl,hl		;6f31	29		)
	adc a,a			;6f32	8f		.
	add hl,hl		;6f33	29		)
	adc a,a			;6f34	8f		.
	bit 0,b			;6f35	cb 40		. @
	jr z,l6f3ch		;6f37	28 03		( .
	add hl,hl		;6f39	29		)
	jr l6f3dh		;6f3a	18 01		. .
l6f3ch:
	add hl,de		;6f3c	19		.
l6f3dh:
	adc a,a			;6f3d	8f		.
	add hl,hl		;6f3e	29		)
	adc a,a			;6f3f	8f		.
	ld e,c			;6f40	59		Y
	ld d,000h		;6f41	16 00		. .
	add hl,de		;6f43	19		.
	adc a,a			;6f44	8f		.
	ex de,hl		;6f45	eb		.
	pop hl			;6f46	e1		.
	ret nz			;6f47	c0		.
	inc hl			;6f48	23		#
	jr l6f19h		;6f49	18 ce		. .
l6f4bh:
	ld de,l5ae5h		;6f4b	11 e5 5a	. . Z
	call sub_4e8dh		;6f4e	cd 8d 4e	. . N
	call sub_6fe5h		;6f51	cd e5 6f	. . o
	call sub_4e8ah		;6f54	cd 8a 4e	. . N
	call sub_5210h		;6f57	cd 10 52	. . R
	ld hl,l65b0h		;6f5a	21 b0 65	! . e
	ld b,000h		;6f5d	06 00		. .
	call 04424h		;6f5f	cd 24 44	. $ D
	ret nz			;6f62	c0		.
	call 04448h		;6f63	cd 48 44	. H D
	ret nz			;6f66	c0		.
	exx			;6f67	d9		.
	ld hl,sub_64b0h		;6f68	21 b0 64	! . d
	ld b,000h		;6f6b	06 00		. .
	ld de,l5ae5h		;6f6d	11 e5 5a	. . Z
	call 04424h		;6f70	cd 24 44	. $ D
	ret nz			;6f73	c0		.
l6f74h:
	call 00013h		;6f74	cd 13 00	. . .
	jr nz,l6f83h		;6f77	20 0a		  .
	exx			;6f79	d9		.
	call 0001bh		;6f7a	cd 1b 00	. . .
	exx			;6f7d	d9		.
	jr z,l6f74h		;6f7e	28 f4		( .
l6f80h:
	jp l521ah		;6f80	c3 1a 52	. . R
l6f83h:
	cp 01ch			;6f83	fe 1c		. .
	jr z,l6f8bh		;6f85	28 04		( .
	cp 01dh			;6f87	fe 1d		. .
	jr nz,l6f80h		;6f89	20 f5		  .
l6f8bh:
	exx			;6f8b	d9		.
	jp 04428h		;6f8c	c3 28 44	. ( D
sub_6f8fh:
	ld b,008h		;6f8f	06 08		. .
	ld c,000h		;6f91	0e 00		. .
	jr l6f9eh		;6f93	18 09		. .
l6f95h:
	ld a,(hl)		;6f95	7e		~
	cp 03ah			;6f96	fe 3a		. :
	jr nc,l6f9eh		;6f98	30 04		0 .
	cp 030h			;6f9a	fe 30		. 0
	jr nc,l6fa7h		;6f9c	30 09		0 .
l6f9eh:
	ld a,(hl)		;6f9e	7e		~
	cp 05fh			;6f9f	fe 5f		. _
	jr nc,l6fafh		;6fa1	30 0c		0 .
	cp 041h			;6fa3	fe 41		. A
	jr c,l6fafh		;6fa5	38 08		8 .
l6fa7h:
	ld (de),a		;6fa7	12		.
	inc hl			;6fa8	23		#
	inc de			;6fa9	13		.
	inc c			;6faa	0c		.
	djnz l6f95h		;6fab	10 e8		. .
	jr l6fb5h		;6fad	18 06		. .
l6fafh:
	ld a,020h		;6faf	3e 20		>  
	ld (de),a		;6fb1	12		.
	inc de			;6fb2	13		.
	djnz l6fafh		;6fb3	10 fa		. .
l6fb5h:
	ld a,c			;6fb5	79		y
	or a			;6fb6	b7		.
	ret			;6fb7	c9		.
sub_6fb8h:
	ld de,l598bh		;6fb8	11 8b 59	. . Y
	ld c,003h		;6fbb	0e 03		. .
	call l6eb5h		;6fbd	cd b5 6e	. . n
	jr nc,l6fdeh		;6fc0	30 1c		0 .
l6fc2h:
	ld b,002h		;6fc2	06 02		. .
l6fc4h:
	ld a,(hl)		;6fc4	7e		~
	cp 030h			;6fc5	fe 30		. 0
	jr c,l6fdbh		;6fc7	38 12		8 .
	ex de,hl		;6fc9	eb		.
	cp (hl)			;6fca	be		.
	jr nc,l6fdbh		;6fcb	30 0e		0 .
	ld (hl),a		;6fcd	77		w
	ex de,hl		;6fce	eb		.
	inc de			;6fcf	13		.
	inc hl			;6fd0	23		#
	djnz l6fc4h		;6fd1	10 f1		. .
	dec c			;6fd3	0d		.
	ret z			;6fd4	c8		.
	ld a,(de)		;6fd5	1a		.
	cp (hl)			;6fd6	be		.
	inc de			;6fd7	13		.
	inc hl			;6fd8	23		#
	jr z,l6fc2h		;6fd9	28 e7		( .
l6fdbh:
	jp l5218h		;6fdb	c3 18 52	. . R
l6fdeh:
	push hl			;6fde	e5		.
	ex de,hl		;6fdf	eb		.
	call 04470h		;6fe0	cd 70 44	. p D
	pop hl			;6fe3	e1		.
	ret			;6fe4	c9		.
sub_6fe5h:
	call sub_6ec4h		;6fe5	cd c4 6e	. . n
	ld d,h			;6fe8	54		T
	ld e,l			;6fe9	5d		]
	ld bc,l6ff7h		;6fea	01 f7 6f	. . o
	call 04cc5h		;6fed	cd c5 4c	. . L
	ret nz			;6ff0	c0		.
	call 04cd9h		;6ff1	cd d9 4c	. . L
	ret nc			;6ff4	d0		.
	ex de,hl		;6ff5	eb		.
	ret			;6ff6	c9		.
l6ff7h:
	ld d,h			;6ff7	54		T
	ld c,a			;6ff8	4f		O
	nop			;6ff9	00		.
