; /src/GDOS-2.4-SYS-files/sys26-sys-disassembly.asm
; SYS26/SYS, stock GDOS 2.4 
; What it does:
; the module GETSYS loads for request code 1Ch
; (28 decimal; Grosser ch.3, "aktuelles /SYS-Modul": code = SYS-number + 2,
; so 28-2 = SYS26/SYS). 
;
; Not Grosser: his book has no SYS26/SYS entry -- this is presumably
; a Genie-IIIs-2.4-specific extension outside that book's scope
; and not documented elsewhere. Everything
; below is read off the disassembly (z80dasm 1.2.0)
;
; [PATCH]  this project's file patch: stock byte vs. this build. See
;          docs/development/boot-patch-inventory.md, "Patches to other
;          SYS-files".
; [note]   a fact established this session, not from any prior reference.
;
; Request-code dispatch (A on entry, per Grosser's GETSYS convention --
; xxxbbsss, top 3 bits select the function within this module):
;   3Ch -> l4d4ch   5Ch -> l4da1h   7Ch -> l4db9h   9Ch -> l4e76h
;   BCh -> falls through to a RST 28h tone dispatch at 4d1dh
;   anything else (incl. the module's own bare load, xxx=000, A=1Ch) falls
;   to l4fb6h, the default path -- this is the path this boot's own
;   first-load-and-run of the module actually takes.
;
; Unannotated lines are z80dasm output, unedited.

4d00  nop
4d01  nop
4d02  nop
4d03  nop
4d04  cp 03ch
4d06  jp z,l4d4ch
4d09  cp 05ch
4d0b  jp z,l4da1h
4d0e  cp 07ch
4d10  jp z,l4db9h
4d13  cp 09ch
4d15  jp z,l4e76h
4d18  cp 0bch
4d1a  jp nz,l4fb6h
4d1d  ld a,(04307h)
4d20  and 00fh
4d22  cp 002h
4d24  jr c,l4d32h
4d26  ld b,0f9h
4d28  jr z,l4d30h
4d2a  cp 006h
4d2c  jr nc,l4d32h
4d2e  ld b,0fah
4d30  ld a,b
4d31  rst 28h
4d32  ld a,02ah
4d34  ei
4d35  jp 04409h
4d38  ld a,02fh
4d3a  jr l4d34h
4d3c  ld a,(04307h)
4d3f  and 00fh
4d41  cp 002h
4d43  ret z
4d44  and 00eh
4d46  cp 004h
4d48  ret z
4d49  pop af
4d4a  xor a
4d4b  ret
4d4c  call sub_4d3ch
4d4f  ld a,(hl)
4d50  cp 00dh
4d52  jp z,l4d77h
4d55  cp 054h
4d57  jp z,l4d77h
4d5a  xor a
4d5b  ret
4d5c  ld hl,(04020h)
4d5f  ld a,01ch
4d61  call 00033h
4d64  ld (04020h),hl
4d67  xor a
4d68  call 00033h
4d6b  ret
4d6c  push hl
4d6d  ld hl,(037f1h)
4d70  call 04c92h
4d73  ld c,l
4d74  ld b,h
4d75  pop hl
4d76  ret
4d77  ld a,(04023h)
4d7a  or a
4d7b  jr z,l4d8dh
4d7d  call sub_4d6ch
4d80  ld hl,(03406h)
4d83  or a
4d84  sbc hl,bc
4d86  ld de,(03400h)
4d8a  call 03656h
4d8d  ld a,(04024h)
4d90  or a
4d91  ret z
4d92  call sub_4d6ch
4d95  ld hl,(03402h)
4d98  ld de,(03406h)
4d9c  call 03656h
4d9f  xor a
4da0  ret
4da1  push af
4da2  push bc
4da3  push de
4da4  push hl
4da5  call l4d77h
4da8  pop hl
4da9  pop de
4daa  pop bc
4dab  pop af
4dac  ret
4dad  call sub_4db5h
4db0  ld a,(hl)
4db1  ret
4db2  jp 03678h
4db5  ret
4db6  jp 03605h
4db9  ld a,(04307h)
4dbc  and 00fh
4dbe  cp 002h
4dc0  ld hl,03c00h
4dc3  ld de,04000h
4dc6  jr z,l4dd0h
4dc8  res 0,a
4dca  cp 004h
4dcc  jr nz,l4e02h
4dce  ld h,038h
4dd0  ex de,hl
4dd1  ld a,(037fch)
4dd4  ld h,a
4dd5  ld a,(037fdh)
4dd8  ld l,a
4dd9  add hl,de
4dda  push hl
4ddb  ld a,(037f6h)
4dde  ld l,a
4ddf  ld a,(037f8h)
4de2  and 003h
4de4  cp 003h
4de6  jr nz,l4deah
4de8  rlc l
4dea  ld a,(037f1h)
4ded  ld (04e1fh),a
4df0  call 04c92h
4df3  ex de,hl
4df4  pop hl
4df5  ex de,hl
4df6  add hl,de
4df7  ex de,hl
4df8  xor a
4df9  ld (sub_4db5h),a
4dfc  ld (l4db1h),a
4dff  ld bc,00000h
4e02  call 005d1h
4e05  jr z,l4e0eh
4e07  dec bc
4e08  ld a,b
4e09  or c
4e0a  jr z,l4e58h
4e0c  jr l4e02h
4e0e  ex de,hl
4e0f  dec hl
4e10  rst 18h
4e11  jr z,l4e1bh
4e13  call sub_4dadh
4e16  cp 020h
4e18  jr z,l4e0fh
4e1a  inc hl
4e1b  ex de,hl
4e1c  push de
4e1d  push hl
4e1e  ld e,040h
4e20  ld d,000h
4e22  add hl,de
4e23  ld b,e
4e24  dec hl
4e25  call sub_4dadh
4e28  cp 020h
4e2a  jr nz,l4e2fh
4e2c  djnz l4e24h
4e2e  inc b
4e2f  pop hl
4e30  ld (04e4fh),hl
4e33  pop de
4e34  call sub_4dadh
4e37  cp 020h
4e39  jr nc,l4e3dh
4e3b  or 040h
4e3d  call sub_4e5ch
4e40  inc hl
4e41  ld a,(03840h)
4e44  and 004h
4e46  jr nz,l4e5ah
4e48  djnz l4e34h
4e4a  ld a,(04e1fh)
4e4d  ld c,a
4e4e  ld hl,00000h
4e51  add hl,bc
4e52  call l4e5ah
4e55  rst 18h
4e56  jr c,l4e1ch
4e58  xor a
4e59  ret
4e5a  ld a,00dh
4e5c  push de
4e5d  ld e,a
4e5e  ld a,(04370h)
4e61  cp e
4e62  jr nc,l4e66h
4e64  ld e,020h
4e66  ld a,e
4e67  call 0003bh
4e6a  pop de
4e6b  ret
4e6c  ld d,b
4e6d  ld c,c
4e6e  ld c,a
4e6f  jr nz,l4e74h
4e71  ld c,(hl)
4e72  ld c,a
4e73  ld d,b
4e74  ld d,d
4e75  dec c
4e76  ld a,(04307h)
4e79  and 007h
4e7b  cp 004h
4e7d  ld a,02ah
4e7f  ret c
4e80  ld a,(hl)
4e81  cp 00dh
4e83  jr z,l4e90h
4e85  cp 050h
4e87  jr z,l4ebch
4e89  cp 04eh
4e8b  jr z,l4ea7h
4e8d  jp l4d38h
4e90  ld hl,l4e6ch
4e93  call 04467h
4e96  ld hl,l4e71h
4e99  ld a,(005bdh)
4e9c  cp 0d4h
4e9e  jr nz,l4ea2h
4ea0  inc hl
4ea1  inc hl
4ea2  call 04467h
4ea5  xor a
4ea6  ret
4ea7  ld hl,037e8h
4eaa  ld a,032h
4eac  ld (005bbh),a
4eaf  ld (005bch),hl
4eb2  ld a,03ah
4eb4  ld (005d1h),a
4eb7  ld (005d2h),hl
4eba  jr l4ea5h
4ebc  ld a,007h
4ebe  out (0d6h),a
4ec0  out (0d7h),a
4ec2  ld a,00fh
4ec4  out (0d6h),a
4ec6  ld a,0cfh
4ec8  out (0d7h),a
4eca  ld a,0feh
4ecc  out (0d7h),a
4ece  ld a,001h
4ed0  out (0d5h),a
4ed2  ld hl,0d4d3h
4ed5  xor a
4ed6  ld (005bbh),a
4ed9  ld (005bch),hl
4edc  ld (005d1h),a
4edf  ld hl,0d5dbh
4ee2  ld (005d2h),hl
4ee5  jr l4ea5h
4ee7  ld sp,00000h
4eea  or a
4eeb  ret
; sub_4eech: entry for request code 9Ch (l4e76h leads here). Computes a directory-sector/FPDE address (via sub_4f2ch) after its OWN DRVSEL(0) call below -- a second, independent occurrence of the same idiom patched at 4f34h, reached by a request code this boot path does not exercise. Not patched.
4eec  push hl
4eed  push de
4eee  push bc
4eef  push af
4ef0  ld hl,l4d00h
4ef3  ld (hl),a
4ef4  and 007h
4ef6  ld c,a
; [note] XOR A / LD (43D8h),A / LD (45BEh),A / CALL 4776h -- same stock idiom as SYS0/SYS's 4BE4h (GETSYS's own module loader) and this file's own 4f34h below: one register clear doing double duty as both DRVSEL's drive-0 argument and the shared FCB's NEXT-field reset. Not yet patched -- this call site is not exercised by the boot path that found the 4f34h bug.
4ef7  xor a
4ef8  ld (043d8h),a
4efb  ld (045beh),a
4efe  call 04776h
4f01  ld a,(hl)
4f02  sub c
4f03  rlca
4f04  rlca
4f05  call sub_4f2ch
4f08  jp nz,l4ee7h
4f0b  bit 6,(hl)
4f0d  jr z,l4f26h
4f0f  add a,014h
4f11  ld l,a
4f12  ld a,(hl)
4f13  ld (l4d03h),a
4f16  inc l
4f17  inc l
4f18  ld e,(hl)
4f19  inc hl
4f1a  ld d,(hl)
4f1b  ld (043dch),de
4f1f  ld hl,043ceh
4f22  ld (l4d01h),hl
4f25  xor a
4f26  pop bc
4f27  ld a,b
4f28  pop bc
4f29  pop de
4f2a  pop hl
4f2b  ret
; sub_4f2ch: HL = 5100h + (A<<8 adjustment via C), called once from sub_4eech.
4f2c  ld l,a
4f2d  ld a,c
4f2e  add a,051h
4f30  ld h,a
4f31  xor a
4f32  ld a,l
4f33  ret
; sub_4f34h: reached from l4fb6h (the default dispatch path) on this module's own first load-and-run (request code = bare module value, A=1Ch). [note] Confirmed live 2026-08-18: this is the exact routine whose DRVSEL(0) call fires right after GETSYS's own six DRVSEL(5) module-load calls, and is the direct cause of the floppy seek/read (track 41, then track 1) documented in boot-patch-inventory.md. Byte-for-byte match confirmed between live memory and this static file.
4f34  xor a
; [PATCH] dfcbdv (43D8h, FCB NEXT field) reset to 0 -- unchanged by the patch.
4f35  ld (043d8h),a
; [PATCH] a flag at 45BEh reset to 0 -- unchanged by the patch (matches GETSYS's own prologue clearing the same cell).
4f38  ld (045beh),a
; [PATCH] stock: CALL 4776h (DRVSEL, A still 0 from the XOR A three lines above -- drive 0, hardcoded). Patched: CALL 50D0h, a same-size stub (LD A,05h / JP 4776h) planted in dead space -- see 50d0h below and boot-patch-inventory.md. File size is unchanged; dmk.py --replace has no support for growing a file's on-disk allocation, so an in-place same-footprint fix was required and this 10-byte block (XOR A + two stores + CALL) has no 1-byte way to load A with sysvol.
4f3b  call 04776h
; original continuation after the DRVSEL call -- unchanged. The patch's stub tail-jumps into 4776h, so DRVSEL's own eventual RET returns here exactly as stock did.
4f3e  ld b,008h
4f40  xor a
; [note] DE=5100h: destination of the 8x256-byte GETFDE/LDIR copy loop below. 5100h-51E7h (all zero in the static file) is genuinely dead/unused space in the file's own image *until* this loop runs -- it is a runtime buffer, not a home for a patch trampoline (checked: this file's only static reference into 50C9h-51E7h is 5100h itself).
4f41  ld de,l5100h
4f44  push bc
4f45  push de
4f46  push af
4f47  call 04936h
4f4a  jp nz,l4ee7h
4f4d  pop af
4f4e  pop de
4f4f  ld bc,00100h
4f52  ldir
4f54  inc a
4f55  pop bc
4f56  djnz l4f44h
4f58  ret
4f59  ld a,(l4d03h)
4f5c  or a
4f5d  jr z,l4f76h
4f5f  push af
4f60  dec a
4f61  ld (l4d03h),a
4f64  push bc
4f65  push de
4f66  push hl
4f67  ld de,(l4d01h)
4f6b  call 04436h
4f6e  jp nz,l4ee7h
4f71  pop hl
4f72  pop de
4f73  pop bc
4f74  pop af
4f75  ret
4f76  xor a
4f77  ret
4f78  ld (0393bh),sp
4f7c  ld sp,03bfeh
4f7f  push hl
4f80  push de
4f81  push bc
4f82  push af
4f83  ld (0392bh),hl
4f86  ld hl,04200h
4f89  ld bc,00100h
4f8c  push de
4f8d  ld de,03a00h
4f90  ldir
4f92  pop de
4f93  ld hl,03a00h
4f96  ld bc,00100h
4f99  in a,(0f9h)
4f9b  push af
4f9c  di
4f9d  and 03eh
4f9f  out (0f9h),a
4fa1  ld (00000h),de
4fa5  ld d,e
4fa6  ld e,000h
4fa8  ldir
4faa  pop af
4fab  out (0f9h),a
4fad  ei
4fae  pop af
4faf  pop bc
4fb0  pop de
4fb1  pop hl
4fb2  ld sp,00000h
4fb5  ret
4fb6  ld (l4ee7h+1),sp
4fba  ld a,(03840h)
4fbd  bit 6,a
4fbf  jr nz,l4fcdh
4fc1  ld a,(04307h)
4fc4  and 00fh
4fc6  cp 003h
4fc8  jp z,l4fcdh
4fcb  cp 004h
4fcd  ld a,000h
4fcf  ret nz
4fd0  call sub_4f34h
4fd3  ld hl,l4f78h
4fd6  ld de,03900h
4fd9  ld bc,0003eh
4fdc  ldir
4fde  ld a,001h
4fe0  ld (l4d03h),a
4fe3  ld hl,04200h
4fe6  ld de,04201h
4fe9  ld (hl),000h
4feb  ld bc,000ffh
4fee  ldir
4ff0  ld hl,l5071h
4ff3  ld de,04280h
4ff6  ld bc,00013h
4ff9  ldir
4ffb  ld hl,04000h
4ffe  ld e,040h
5000  call 03900h
5003  ld b,01dh
5005  ld ix,l5084h
5009  ld e,041h
500b  ld h,040h
500d  ld a,(ix+000h)
5010  add a,002h
5012  ld l,a
5013  rlc l
5015  call sub_4eech
5018  jr nz,l5028h
501a  call sub_4f59h
501d  jr z,l5028h
501f  ld d,a
5020  call 03900h
5023  ld l,000h
5025  inc e
5026  jr l501ah
5028  inc ix
502a  dec b
502b  jr nz,l500bh
502d  ld hl,l50a1h
5030  ld de,03738h
5033  ld bc,00028h
5036  ldir
5038  ld hl,l5046h
503b  ld de,04be1h
503e  ld bc,0002bh
5041  ldir
5043  jp l4f76h
5046  ld h,040h
5048  call 03738h
504b  ld a,(04317h)
504e  rlca
504f  ld l,a
5050  ld h,03ah
5052  ld a,(hl)
5053  ld (03753h),a
5056  inc hl
5057  ld a,(hl)
5058  or a
5059  jr z,l5073h
505b  ld hl,03751h
505e  ld (04c6dh),hl
5061  ld de,03affh
5064  call 04c2eh
5067  ld (04c1eh),hl
506a  ld hl,04436h
506d  ld (04c6dh),hl
5070  nop
5071  push hl
5072  push de
5073  push bc
5074  push af
5075  ld l,000h
5077  ld de,03a00h
507a  ld bc,00100h
507d  ldir
507f  pop af
5080  pop bc
5081  pop de
5082  pop hl
5083  ret
5084  add hl,de
5085  jr $+31
5087  rla
5088  ld de,00b10h
508b  rrca
508c  ld c,007h
508e  inc de
508f  ld (de),a
5090  dec c
5091  ld a,(bc)
5092  inc d
5093  ld bc,00302h
5096  inc b
5097  ex af,af'
5098  add hl,bc
5099  dec b
509a  ld b,00ch
509c  dec d
509d  inc e
509e  ld d,01bh
50a0  ld a,(de)
50a1  ld (0374eh),sp
50a5  di
50a6  ld sp,03bfeh
50a9  in a,(0f9h)
50ab  push af
50ac  and 03eh
50ae  out (0f9h),a
50b0  call 04080h
50b3  pop af
50b4  out (0f9h),a
50b6  ld sp,00000h
50b9  ret
50ba  push hl
50bb  ld h,000h
50bd  call 03738h
50c0  ld a,h
50c1  inc a
50c2  ld (03753h),a
50c5  xor a
50c6  ei
50c7  pop hl
50c8  ret
; [note] 50C9h-51E7h: all zero in the stock file. Not slack for a patch -- this is the buffer sub_4f34h's own LDIR loop (above) fills at runtime with 8x256 bytes of directory data.
50c9  nop
50ca  nop
50cb  nop
50cc  nop
50cd  nop
50ce  nop
50cf  nop
; [PATCH] added: LD A,05h / JP 4776h -- the stub 4f3bh now calls. Loads sysvol instead of hardcoded drive 0, then tail-jumps into DRVSEL so its own RET returns to 4f3eh (sub_4f34h's original continuation) exactly as the un-patched CALL 4776h would have. Placed here because it is confirmed dead space (see 50c9h note) that sits *before* the 5100h runtime buffer, so it survives the LDIR loop that follows.
50d0  nop
50d1  nop
50d2  nop
50d3  nop
50d4  nop
50d5  nop
50d6  nop
50d7  nop
50d8  nop
50d9  nop
50da  nop
50db  nop
50dc  nop
50dd  nop
50de  nop
50df  nop
50e0  nop
50e1  nop
50e2  nop
50e3  nop
50e4  nop
50e5  nop
50e6  nop
50e7  nop
50e8  nop
50e9  nop
50ea  nop
50eb  nop
50ec  nop
50ed  nop
50ee  nop
50ef  nop
50f0  nop
50f1  nop
50f2  nop
50f3  nop
50f4  nop
50f5  nop
50f6  nop
50f7  nop
50f8  nop
50f9  nop
50fa  nop
50fb  nop
50fc  nop
50fd  nop
50fe  nop
50ff  nop
5100  nop
5101  nop
5102  nop
5103  nop
5104  nop
5105  nop
5106  nop
5107  nop
5108  nop
5109  nop
510a  nop
510b  nop
510c  nop
510d  nop
510e  nop
510f  nop
5110  nop
5111  nop
5112  nop
5113  nop
5114  nop
5115  nop
5116  nop
5117  nop
5118  nop
5119  nop
511a  nop
511b  nop
511c  nop
511d  nop
511e  nop
511f  nop
5120  nop
5121  nop
5122  nop
5123  nop
5124  nop
5125  nop
5126  nop
5127  nop
5128  nop
5129  nop
512a  nop
512b  nop
512c  nop
512d  nop
512e  nop
512f  nop
5130  nop
5131  nop
5132  nop
5133  nop
5134  nop
5135  nop
5136  nop
5137  nop
5138  nop
5139  nop
513a  nop
513b  nop
513c  nop
513d  nop
513e  nop
513f  nop
5140  nop
5141  nop
5142  nop
5143  nop
5144  nop
5145  nop
5146  nop
5147  nop
5148  nop
5149  nop
514a  nop
514b  nop
514c  nop
514d  nop
514e  nop
514f  nop
5150  nop
5151  nop
5152  nop
5153  nop
5154  nop
5155  nop
5156  nop
5157  nop
5158  nop
5159  nop
515a  nop
515b  nop
515c  nop
515d  nop
515e  nop
515f  nop
5160  nop
5161  nop
5162  nop
5163  nop
5164  nop
5165  nop
5166  nop
5167  nop
5168  nop
5169  nop
516a  nop
516b  nop
516c  nop
516d  nop
516e  nop
516f  nop
5170  nop
5171  nop
5172  nop
5173  nop
5174  nop
5175  nop
5176  nop
5177  nop
5178  nop
5179  nop
517a  nop
517b  nop
517c  nop
517d  nop
517e  nop
517f  nop
5180  nop
5181  nop
5182  nop
5183  nop
5184  nop
5185  nop
	noWarning: Code might not be 8080 compatible!
Warning: Self modifying code detected!
5186  p
5187  nop
5188  nop
5189  nop
518a  nop
518b  nop
518c  nop
518d  nop
518e  nop
518f  nop
5190  nop
5191  nop
5192  nop
5193  nop
5194  nop
5195  nop
5196  nop
5197  nop
5198  nop
5199  nop
519a  nop
519b  nop
519c  nop
519d  nop
519e  nop
519f  nop
51a0  nop
51a1  nop
51a2  nop
51a3  nop
51a4  nop
51a5  nop
51a6  nop
51a7  nop
51a8  nop
51a9  nop
51aa  nop
51ab  nop
51ac  nop
51ad  nop
51ae  nop
51af  nop
51b0  nop
51b1  nop
51b2  nop
51b3  nop
51b4  nop
51b5  nop
51b6  nop
51b7  nop
51b8  nop
51b9  nop
51ba  nop
51bb  nop
51bc  nop
51bd  nop
51be  nop
51bf  nop
51c0  nop
51c1  nop
51c2  nop
51c3  nop
51c4  nop
51c5  nop
51c6  nop
51c7  nop
51c8  nop
51c9  nop
51ca  nop
51cb  nop
51cc  nop
51cd  nop
51ce  nop
51cf  nop
51d0  nop
51d1  nop
51d2  nop
51d3  nop
51d4  nop
51d5  nop
51d6  nop
51d7  nop
51d8  nop
51d9  nop
51da  nop
51db  nop
51dc  nop
51dd  nop
51de  nop
51df  nop
51e0  nop
51e1  nop
51e2  nop
51e3  nop
51e4  nop
51e5  nop
51e6  nop
51e7  nop
