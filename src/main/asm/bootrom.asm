; MIT licensed, see LICENSE.
;
; Boot ROM for the Sedna Z80 board. Shadows low memory out of reset; scans the
; block devices in enumeration order and boots the first one where reserved
; tracks carry a boot descriptor (bootdef.inc). The system entry is passed the
; boot disk controller's port in C and its unit in B, and is expected to drop
; the ROM shadow itself.
;
; With no bootable disk the ROM reports NO SYSTEM DISK on the console once and
; keeps scanning, so inserting a disk boots without a reset.
;
; All variables live in high RAM because the shadow area can't store anything.

	cpu	z80
	page	0

	include	"bootdef.inc"
	include	"wd1793.inc"

LSRTHRE	equ	20h			; UART line status: transmit holding register empty

VARS	equ	0C000h
LFDCB	equ	VARS+0		; controller port of the drive being tried
LFUNIT	equ	VARS+1		; unit of that drive on its controller
LUARTF	equ	VARS+2		; console found
LUARTB	equ	VARS+3		; console UART base port
LMSGF	equ	VARS+4		; NO SYSTEM DISK already printed
LIDX	equ	VARS+5		; linear sector index within the reserved tracks
LCNT	equ	VARS+6		; sectors left to read
LDMA	equ	VARS+7		; word: read target, advanced per sector

BUFFER	equ	0C080h		; the boot descriptor is read here
STACK	equ	0E000h

	org	0000h

	di
	ld	sp,STACK
	xor	a
	ld	(LMSGF),a
	ld	(LUARTF),a
	ld	b,0
	ld	c,CLSCHR
	call	DEVFIND
	jr	c,SCAN
	ld	(LUARTB),a
	ld	a,1
	ld	(LUARTF),a

SCAN:	ld	b,0			; block device ordinal
SCAN1:	push	bc
	ld	c,CLSBLK
	call	DEVFIND
	pop	bc
	jr	c,NOSYS
	ld	(LFDCB),a
	in	a,(BATT)
	and	0Fh				; low nibble selects the drive on that controller
	ld	(LFUNIT),a
	push	bc
	call	TRYBOOT		; returns only when this device does not boot
	pop	bc
	inc	b
	jr	SCAN1

NOSYS:	ld	a,(LMSGF)
	or	a
	jr	nz,SCAN
	ld	a,1
	ld	(LMSGF),a
	ld	a,(LUARTF)
	or	a
	jr	z,SCAN
	ld	hl,MSG
	call	PUTS
	jr	SCAN

; Tries to boot the drive in LFDCB/LFUNIT. Does not return on success.
TRYBOOT:
	call	FSEL
	xor	a
	call	FREG
	in	a,(c)
	and	FNRDY
	ret	nz		; nothing in the drive
	ld	hl,BUFFER
	ld	(LDMA),hl
	ld	d,0		; the descriptor is track 0, sector 0; no geometry needed yet
	xor	a
	call	RDTS
	ret	nz
	ld	a,(BUFFER+BOFMAG)
	cp	BMAG0
	ret	nz
	ld	a,(BUFFER+BOFMAG+1)
	cp	BMAG1
	ret	nz
	ld	a,(BUFFER+BOFSPT)	; the load loop divides by this and counts down from that
	or	a
	ret	z
	ld	a,(BUFFER+BOFCNT)
	or	a
	ret	z
	ld	hl,(BUFFER+BOFLOAD)
	ld	(LDMA),hl
	ld	a,(BUFFER+BOFCNT)
	ld	(LCNT),a
	ld	a,BSYS0
	ld	(LIDX),a
TRYB1:	ld	a,(LIDX)
	call	RDSEC
	ret	nz
	ld	hl,LIDX
	inc	(hl)
	ld	hl,LCNT
	dec	(hl)
	jr	nz,TRYB1
	ld	a,(LFUNIT)
	ld	b,a
	ld	a,(LFDCB)
	ld	c,a
	ld	hl,(BUFFER+BOFENT)
	jp	(hl)

	include	"devlib.inc"	; DEVFIND and the enumeration window layout

; ------------------------------------------------------------ disk primitives

; Returns the disk controller register at offset A in C.
FREG:	ld	hl,LFDCB
	add	a,(hl)
	ld	c,a
	ret

; Selects the current drive on its controller, side 0.
FSEL:	ld	a,4
	call	FREG
	ld	a,(LFUNIT)
	out	(c),a
	ret

; Waits for the controller to go idle, then returns its status register in A.
FWAIT:	xor	a
	call	FREG
FW1:	in	a,(c)
	bit	0,a		; FBUSY, tested without disturbing the status
	jr	nz,FW1
	ret

; Reads the 128-byte sector at linear index A within the reserved tracks to (LDMA), which it
; advances. Splits the index by the descriptor's sectors per track, so the descriptor must have
; been read first. Exit Z on success, NZ if the controller reported an error.
RDSEC:	ld	hl,BUFFER+BOFSPT
	ld	d,0
RDSEC1:	cp	(hl)
	jr	c,RDTS
	sub	(hl)
	inc	d
	jr	RDSEC1

; Reads the 128-byte sector at track D, sector A (0-based) to (LDMA), which it advances.
; Exit Z on success, NZ if the controller reported an error.
RDTS:	ld	e,a		; E = sector; FSEL and FREG leave DE alone
	call	FSEL
	ld	a,3
	call	FREG
	out	(c),d		; desired track goes to the data register
	xor	a
	call	FREG
	ld	a,FSEEK
	out	(c),a
	call	FWAIT
	and	FERRI
	ret	nz
	ld	a,2
	call	FREG
	ld	a,e
	inc	a		; the controller numbers sectors from one
	out	(c),a
	xor	a
	call	FREG
	ld	a,FREAD
	out	(c),a
	ld	a,3
	call	FREG
	ld	hl,(LDMA)
	ld	b,128
RDTS1:	in	a,(c)
	ld	(hl),a
	inc	hl
	djnz	RDTS1
	ld	(LDMA),hl
; A failed command leaves the data register holding whatever was last written to it, so without
; this check a read returns 128 copies of the track number and reports success.
	call	FWAIT
	and	FERR
	ret

; ----------------------------------------------------------------- console

PUTS:	ld	a,(hl)
	or	a
	ret	z
	ld	e,a
	push	hl
	ld	a,(LUARTB)
	add	a,5
	ld	c,a
PUTS1:	in	a,(c)
	and	LSRTHRE
	jr	z,PUTS1
	ld	a,(LUARTB)
	ld	c,a
	out	(c),e
	pop	hl
	inc	hl
	jr	PUTS

MSG:	db	13,10,"NO SYSTEM DISK",13,10,0

	if	$ > 0400h
	error	"boot ROM overflows its 1 KiB"
	endif

	end
