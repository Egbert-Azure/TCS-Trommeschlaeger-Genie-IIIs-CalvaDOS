;************************************************************************
;
;	OMTI transport, write exercise
;
;
; Written and commented by
; E.H. Schroeer
;
; Name: hdwtest.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
;	Write exercise for the OMTI transport, to be run under
;	sdltrs-MultiHDC's zbx debugger with an .hdv attached to hard0.
;
; 	A misaddressed write is a test failure rather than a silent loss 
;   -- which matters because the emulator's OMTI write path 
; 	does not consult the image's
;	write-protect flag at all, so that flag protects nothing here.
;
;	The sequence is: fill five buffers with distinguishable patterns,
;	write each to a scratch sector, then read all five back through the
;	transport into separate buffers. Reading afterwards is not only the
;	round-trip check -- it also forces the emulator to fseek, which
;	flushes the writes to the image file before the run ends.
;
;	The scratch sectors move one CDB field at a time, as the read test's
;	do, and they sit in high cylinders no GDOS volume on these images
;	reaches:
;
;	  logical 40800   cyl 600  head 0  sec 0   base case
;	  logical 40805   cyl 600  head 0  sec 5   sector field
;	  logical 40817   cyl 600  head 1  sec 0   head field
;	  logical 40868   cyl 601  head 0  sec 0   cylinder low byte
;	  logical 23392   cyl 344  head 0  sec 0   cylinder bits 8-9
;
;	The last pair is the sharpest case in either test. 600 is 258h and
;	344 is 158h, so they share a low byte and differ *only* in the two
;	bits hdchs puts in CDB2 bits 6-7 -- the encoding open question 7 is
;	about. If those bits were dropped or misplaced, both writes would
;	land on the same sector and the diff would show one scratch sector
;	changed instead of five.
;
;	Cylinder bit 10 is still unreachable on a 615-cylinder drive and
;	stays untested, as in hdtest.asm.

ncase	EQU	5
reclen	EQU	7		;bytes per case record, see `cases`
taglen	EQU	8

	ORG	5200h

stack	EQU	5000h		;RAM below the code; no OS is running

;	Same banking precondition as the read test: ports 40h-43h only reach
;	the OMTI once the machine is in Genie IIIs mode, and this code cannot
;	put it there itself without switching its own RAM bank out. The runner
;	lets the Sopp EPROM boot and takes over at 4200h.

start	DI
	LD	SP,stack
	LD	HL,4		;fail fast; the driver's own timeout is minutes
	LD	(hdtmo),HL	;of emulated time, which is no use in a test run
	CALL	hdrel		;known state, whatever the EPROM left behind

	IN	A,(OMTSEL)	;card present?
	LD	(rcard),A

	CALL	hdtst		;TEST UNIT READY
	LD	HL,rtest
	CALL	rslt

;	--- write pass ----------------------------------------------------

	LD	HL,cases
	LD	(cptr),HL
	LD	HL,rwrit
	LD	(rptr),HL
	LD	B,ncase

wnext	PUSH	BC
	CALL	getcas
	LD	A,(cseed)
	LD	HL,(cpbuf)
	CALL	mkpat
	LD	HL,(clog)
	LD	DE,(cpbuf)
	CALL	hdwr
	LD	HL,(rptr)
	CALL	rslt
	LD	(rptr),HL
	POP	BC
	DJNZ	wnext

;	--- read-back pass ------------------------------------------------

	LD	HL,cases
	LD	(cptr),HL
	LD	HL,rread
	LD	(rptr),HL
	LD	B,ncase

rnext	PUSH	BC
	CALL	getcas
	LD	HL,(clog)
	LD	DE,(crbuf)
	CALL	hdrd
	LD	HL,(rptr)
	CALL	rslt
	LD	(rptr),HL
	POP	BC
	DJNZ	rnext

done	JR	done		;zbx breakpoint sits here

;	Copy the next case record out of the table into the fixed cells the
;	passes read, and advance cptr. Unpacking through memory rather than
;	juggling registers keeps both loops readable, and neither is timed.

getcas	LD	HL,(cptr)
	LD	DE,clog
	LD	BC,reclen
	LDIR
	LD	(cptr),HL
	RET

;	Fill 512 bytes at (HL) with this case's pattern:
;
;	  bytes 0-7    the ASCII tag, so a hex dump of the image later says
;		       where these bytes came from
;	  byte  8      the seed
;	  bytes 9-511  (seed + offset) AND 0FFh
;
;	Distinct seeds make the five patterns differ at every single byte, so
;	a write that lands on another case's sector cannot pass the read-back
;	comparison by coincidence.
;
;	In: A = seed, HL = 512-byte buffer. Out: HL unchanged.

mkpat	PUSH	HL
	PUSH	AF
	LD	D,2		;two rounds of 256
mkpat1	LD	B,0
mkpat2	LD	(HL),A
	INC	A
	INC	HL
	DJNZ	mkpat2
	DEC	D
	JR	NZ,mkpat1
	POP	AF		;seed back
	POP	DE		;buffer start
	PUSH	DE
	LD	HL,tag
	LD	BC,taglen
	LDIR
	LD	(DE),A		;seed lands just past the tag
	POP	HL
	RET

;	Record one outcome at (HL): error code, controller status, and the
;	CDB actually sent -- so a wrong address block shows up in the dump
;	even when the command itself succeeded. Returns HL past the record.

rslt	LD	A,(hdlerr)
	LD	(HL),A
	INC	HL
	LD	A,(hdstat)
	LD	(HL),A
	INC	HL
	EX	DE,HL
	LD	HL,hdcdb
	LD	BC,CDBLEN
	LDIR
	EX	DE,HL
	RET

tag	DEFM	'CalvaDOS'

;	logical sector, pattern buffer, read-back buffer, seed

cases	DEFW	20400
	DEFW	pbuf0
	DEFW	rbuf0
	DEFB	011h
	DEFW	20405
	DEFW	pbuf1
	DEFW	rbuf1
	DEFB	022h
	DEFW	20417
	DEFW	pbuf2
	DEFW	rbuf2
	DEFB	033h
	DEFW	20434
	DEFW	pbuf3
	DEFW	rbuf3
	DEFB	044h
	DEFW	11696
	DEFW	pbuf4
	DEFW	rbuf4
	DEFB	055h

cptr	DEFS	2
rptr	DEFS	2

;	The current case, unpacked. These four must stay contiguous and in
;	this order: getcas LDIRs a whole record onto them.

clog	DEFS	2
cpbuf	DEFS	2
crbuf	DEFS	2
cseed	DEFS	1

	INCLUDE	'omti.asm'

;	--- results, at fixed addresses so the zbx script can name them ----

;	5800h, not hdtest.asm's 5400h: the code plus omti.asm now reaches
;	past 5400h, and an ORG landing inside it is an assembly error.

	ORG	5800h

rcard	DEFS	1		;port 42h read back: 0FAh = card present
rtest	DEFS	8		;err, status, then the 6 CDB bytes sent
rwrit	DEFS	8*ncase		;the same, one record per write
rread	DEFS	8*ncase		;and one per read-back

	ORG	6000h
pbuf0	DEFS	512
	ORG	6200h
pbuf1	DEFS	512
	ORG	6400h
pbuf2	DEFS	512
	ORG	6600h
pbuf3	DEFS	512
	ORG	6800h
pbuf4	DEFS	512

	ORG	6a00h
rbuf0	DEFS	512
	ORG	6c00h
rbuf1	DEFS	512
	ORG	6e00h
rbuf2	DEFS	512
	ORG	7000h
rbuf3	DEFS	512
	ORG	7200h
rbuf4	DEFS	512
