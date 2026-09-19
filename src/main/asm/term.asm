; MIT licensed, see LICENSE.
;
; TERM -- a dumb terminal on the serial card.
;
	cpu	z80
	page	0

IOBYTE	equ	0003h
BDOS	equ	0005h
DIRECT	equ	6		; direct console i/o, in both directions

QUIT	equ	1Dh		; ctrl-], the way telnet has always done it
GARBLE	equ	'~'

	org	0100h

	ld	b,0
	call	SEROPEN
	jr	c,NOCARD
	ld	a,(IOBYTE)
	and	3		; CON:=TTY: is the card itself
	jr	z,ONCARD

	ld	hl,BANNER
	call	PUTS

LOOP:	call	DRAIN
	call	KEY
	jr	z,LOOP
	cp	QUIT
	jr	z,BYE
	ld	c,a
	call	SEROUT
	jr	LOOP

BYE:	ld	hl,CRLF
	call	PUTS
	jp	0

NOCARD:	ld	hl,NOSER
	call	PUTS
	jp	0

ONCARD:	ld	hl,CONSER
	call	PUTS
	jp	0

DRAIN:	call	SERST
	ret	z
	call	SERIN
	jr	nc,DRAIN1
	ld	a,GARBLE	; disturbed, so this is not what was sent
DRAIN1:	call	ECHO
	jr	DRAIN

; Prints the zero terminated string at HL.
PUTS:	ld	a,(hl)
	or	a
	ret	z
	push	hl
	call	ECHO
	pop	hl
	inc	hl
	jr	PUTS

; Prints A on the console.
ECHO:	push	bc
	push	de
	ld	e,a
	ld	c,DIRECT
	call	BDOS
	pop	de
	pop	bc
	ret

; Reads a key without waiting.
; exit  Z when nothing was typed, otherwise A holds the key
KEY:	push	bc
	push	de
	ld	e,0FFh
	ld	c,DIRECT
	call	BDOS
	pop	de
	pop	bc
	or	a
	ret

BANNER:	db	'TERM -- ctrl-] quits',0Dh,0Ah,0
CRLF:	db	0Dh,0Ah,0
NOSER:	db	'No serial port on this machine.',0Dh,0Ah,0
CONSER:	db	'The console is on the serial port.',0Dh,0Ah,0

	include	"devlib.inc"
	include	"serial.inc"

	end
