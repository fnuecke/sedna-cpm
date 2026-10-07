; MIT licensed, see LICENSE.
;
; DEVS -- list the devices the machine reports through the enumeration window.

	cpu	z80
	page	0

BDOS	equ	0005h
CONOUT	equ	2
PSTR	equ	9

	org	0100h

	ld	de,HEADER
	ld	c,PSTR
	call	BDOS

	in	a,(BCNT)
	or	a
	jr	z,DONE
	ld	b,a
	ld	e,0
ROW:	push	bc
	push	de
	ld	a,e
	out	(BSEL),a
	ld	a,e
	call	PHEX
	call	SPACE
	in	a,(BCLS)
	call	PHEX
	call	SPACE
	in	a,(BPRT)
	call	PHEX
	call	SPACE
	in	a,(BATT)
	call	PHEX
	call	SPACE
	xor	a
	out	(BNAM),a	; rewind the name stream
	in	a,(BNAM)
	or	a
	jr	z,ENDROW
NAME:	ld	e,a
	ld	c,CONOUT
	call	BDOS
	in	a,(BNAM)
	or	a
	jr	nz,NAME
	in	a,(BNAM)	; first byte of the next name, 0 when there is none
	or	a
	jr	z,ENDROW
	push	af
	ld	de,SEP
	ld	c,PSTR
	call	BDOS
	pop	af
	jr	NAME
ENDROW:	ld	de,CRLF
	ld	c,PSTR
	call	BDOS
	pop	de
	pop	bc
	inc	e
	djnz	ROW

DONE:	ld	de,FIRSTB
	ld	c,PSTR
	call	BDOS
	ld	c,CLSBLK
	ld	b,0
	ld	hl,0
	call	DEVFIND
	jr	c,NOBLK
	call	PHEX
	jr	TAIL
NOBLK:	ld	de,NONE
	ld	c,PSTR
	call	BDOS
TAIL:	ld	de,CRLF
	ld	c,PSTR
	call	BDOS
	ret

; Prints A as two hex digits.
PHEX:	push	af
	rrca
	rrca
	rrca
	rrca
	call	PNIB
	pop	af
PNIB:	and	0Fh
	add	a,90h
	daa
	adc	a,40h
	daa
	ld	e,a
	ld	c,CONOUT
	jp	BDOS

SPACE:	ld	e,' '
	ld	c,CONOUT
	jp	BDOS

HEADER:	db	'IX CL PT AT NAME',0Dh,0Ah,'$'
FIRSTB:	db	'first block device at port $'
NONE:	db	'(none)$'
SEP:	db	', $'
CRLF:	db	0Dh,0Ah,'$'

	include	"devlib.inc"

	end
