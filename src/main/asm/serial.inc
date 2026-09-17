; MIT licensed, see LICENSE.
;
; SERIAL -- talk to a serial card via the enumeration window.
SERLCR	equ	3		; line control register
SERLSR	equ	5		; line status register
SERDLAB	equ	80h		; line control
SERDR	equ	01h		; data register
SERFE	equ	08h		; frame error
SERTHRE	equ	20h		; transmitter is free

; SEROPEN -- find the B'th serial port, counting from zero, past the console.
; exit  NC, A = port base, and SERPRT holds it
;       CY      no such port
SEROPEN:
	push	bc
	push	de
	push	hl
	inc	b		; step over the console
	ld	c,CLSCHR
	call	DEVFIND
	jr	c,SEROP1
	ld	(SERPRT),a
	xor	a
	ld	(SERFLG),a
	ld	a,(SERPRT)
	pop	hl
	pop	de
	pop	bc
	or	a		; clears carry, keeps the port in A
	ret
SEROP1:	pop	hl
	pop	de
	pop	bc
	scf
	ret

; SERBAUD -- set the baud rate from the divisor in HL.
;
; Divisors from the 1.8432 MHz clock: 300 is 384, 1200 is 96, 9600 is 12,
; 19200 is 6, 115200 is 1. Default after reset 9600.
SERBAUD:
	push	bc
	push	de
	ld	d,h
	ld	e,l
	ld	a,(SERPRT)
	add	a,SERLCR
	ld	c,a
	in	a,(c)
	ld	b,a			; the line control value to put back
	or	SERDLAB
	out	(c),a
	ld	a,(SERPRT)
	ld	c,a
	ld	a,e
	out	(c),a		; divisor, low byte
	inc	c
	ld	a,d
	out	(c),a		; divisor, high byte
	ld	a,(SERPRT)
	add	a,SERLCR
	ld	c,a
	ld	a,b
	and	7Fh			; drop the latch again, or the data registers stay hidden
	out	(c),a
	pop	de
	pop	bc
	ret

; SERST -- get status.
; exit  Z when the line is quiet, NZ when a byte is ready
SERST:	push	bc
	ld	a,(SERPRT)
	add	a,SERLSR
	ld	c,a
	in	a,(c)
	push	af
	and	SERFE
	jr	z,SERST1
	ld	a,(SERFLG)
	or	SERFE		; hold on to it; reading the register just cleared it
	ld	(SERFLG),a
SERST1:	pop	af
	and	SERDR
	pop	bc
	ret

; SERIN -- wait for a byte.
; exit  A = the byte, CY when the line was disturbed around it
SERIN:	push	bc
SERIN1:	call	SERST
	jr	z,SERIN1
	ld	a,(SERPRT)
	ld	c,a
	in	a,(c)
	ld	b,a		; hold the byte while the flag is sorted out
	ld	a,(SERFLG)
	and	SERFE
	push	af
	xor	a
	ld	(SERFLG),a
	pop	af		; Z when nothing was latched
	ld	a,b
	pop	bc
	ret	z
	scf
	ret

; SEROUT -- send the byte in C, waiting for the transmitter if it has to.
SEROUT:	push	bc
	ld	b,c		; hold the character; C is about to become a port
	ld	a,(SERPRT)
	add	a,SERLSR
	ld	c,a
SEROU1:	in	a,(c)
	and	SERTHRE
	jr	z,SEROU1
	ld	a,(SERPRT)
	ld	c,a
	out	(c),b
	pop	bc
	ret

SERPRT:	db	0
SERFLG:	db	0
