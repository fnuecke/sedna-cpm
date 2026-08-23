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
NAME:	in	a,(BNAM)
	or	a
	jr	z,ENDROW
	ld	e,a
	ld	c,CONOUT
	call	BDOS
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
CRLF:	db	0Dh,0Ah,'$'

	include	"devlib.inc"

	end
