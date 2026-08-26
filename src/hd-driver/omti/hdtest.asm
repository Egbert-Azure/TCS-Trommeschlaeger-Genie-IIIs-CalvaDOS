;************************************************************************
;
;	OMTI transport, read-only exercise
;
;
; Written and commented by
; E.H. Schroeer
;
; Name: hdtest.asm
;
; Date: 2026/08/23
;
;************************************************************************
;
;	Read-only exercise for the OMTI transport, to be run under
;	sdltrs-MultiHDC's zbx debugger with an .hdv attached to hard0.
;	Nothing here writes to the disk: the only commands issued are TEST
;	UNIT READY and READ.
;
;	It is deliberately standalone -- no DOS, no banking, no screen. zbx
;	loads it at 5200h, runs it, breaks at `done`, and saves the sector
;	buffers to files that ./verify.py checks two ways: byte for byte
;	against the same sectors read out of the .hdv on the host, and
;	against the controller's own trace of what cylinder, head and sector
;	it decoded out of each CDB. The second check is the one that matters
;	for the address encoding, because a wrong split reads a real sector
;	from the wrong place rather than failing.
;
;	The cases move one CDB field at a time, on the 17-sector, 4-head
;	geometry of the OMTI images in HDV/:
;
;	  logical     0	  cyl   0  head 0  sec 0   the boot sector
;	  logical     5	  cyl   0  head 0  sec 5   sector field
;	  logical    17	  cyl   0  head 1  sec 0   head field
;	  logical   136	  cyl   2  head 0  sec 0   cylinder low byte
;	  logical 20400	  cyl 600  head 0  sec 0   cylinder bits 8-9
;
;	Cylinder bit 10, which lives in CDB1, is not reachable on a 615-
;	cylinder drive and stays untested here.

ncase	EQU	5

	ORG	5200h

stack	EQU	5000h		;RAM below the code; no OS is running

;	The machine must already be in Genie IIIs mode when this runs: the
;	banker port 0F9h decides whether ports 40h-43h reach the OMTI at all,
;	and writing it here would switch the visible RAM bank out from under
;	this code. run-hdtest.sh therefore lets the Sopp boot EPROM run
;	first and only takes over at 4200h, where the EPROM hands control to
;	the boot sector -- the same machine state CalvaDOS's own boot sector
;	will inherit.

start	DI
	LD	SP,stack
	LD	HL,4		;fail fast: the driver's own timeout is minutes
	LD	(hdtmo),HL	;of emulated time, which is no use in a test run
	CALL	hdrel		;known state, whatever the EPROM left behind

	IN	A,(OMTSEL)	;card present?
	LD	(rcard),A

	CALL	hdtst		;TEST UNIT READY
	LD	HL,rtest
	CALL	rslt

	LD	HL,cases
	LD	(cptr),HL
	LD	HL,rread
	LD	(rptr),HL
	LD	B,ncase

next	PUSH	BC
	LD	HL,(cptr)
	LD	E,(HL)		;logical sector
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	C,(HL)		;buffer
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	(cptr),HL
	EX	DE,HL		;HL = logical sector
	LD	E,C
	LD	D,B		;DE = buffer
	CALL	hdrd
	LD	HL,(rptr)
	CALL	rslt
	LD	(rptr),HL
	POP	BC
	DJNZ	next

done	JR	done		;zbx breakpoint sits here

;	Record one outcome at (HL): error code, controller status, and the
;	CDB actually sent -- so a wrong address block shows up in the dump
;	even when the read itself succeeded. Returns HL past the record.

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

cases	DEFW	0,buf0
	DEFW	5,buf1
	DEFW	17,buf2
	DEFW	136,buf3
	DEFW	20400,buf4

cptr	DEFS	2
rptr	DEFS	2

	INCLUDE	'omti.asm'

;	--- results, at fixed addresses so the zbx script can name them ----

	ORG	5400h

rcard	DEFS	1		;port 42h read back: 0FAh = card present
rtest	DEFS	8		;err, status, then the 6 CDB bytes sent
rread	DEFS	8*ncase		;the same, one record per read

	ORG	5600h
buf0	DEFS	512
	ORG	5800h
buf1	DEFS	512
	ORG	5a00h
buf2	DEFS	512
	ORG	5c00h
buf3	DEFS	512
	ORG	5e00h
buf4	DEFS	512
