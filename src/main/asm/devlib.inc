; MIT licensed, see LICENSE.
;
; DEVLIB -- find devices through the sedna enumeration window from a CP/M program.
;
; Include this in your own source. The window is the one fixed port on the machine; everything
; else is discovered, so never hardcode a device address.

BUS	equ	0E0h
BVER	equ	BUS+0		; format version
BCNT	equ	BUS+1		; device count
BSEL	equ	BUS+2		; selected index
BCLS	equ	BUS+3		; class
BATT	equ	BUS+4		; class-specific attributes
BPRT	equ	BUS+5		; assigned port base
BINT	equ	BUS+6		; interrupt vector, FFh if polled
BNAM	equ	BUS+7		; name byte stream, 0 ends; any write rewinds
BID	equ	BUS+8		; id byte stream, 0 ends; any write rewinds

CLSBUS	equ	01h
CLSCHR	equ	02h
CLSBLK	equ	03h
CLSRTC	equ	04h
CLSGPIO	equ	05h
CLSSCRN	equ	06h
CLSROM	equ	07h

; DEVFIND -- locate the B'th device of class C (B is 0-based).
; exit  NC, A = port base, E = index
;       CY      no such device
; Use the returned port with IN r,(C) / OUT (C),r; it is not known until run time.
DEVFIND:
	in	a,(BCNT)
	or	a
	scf
	ret	z
	ld	d,a
	ld	e,0
DEVFIND1:
	ld	a,e
	out	(BSEL),a
	in	a,(BCLS)
	cp	c
	jr	nz,DEVFIND2
	ld	a,b
	or	a
	jr	z,DEVFIND3
	dec	b
DEVFIND2:
	inc	e
	ld	a,e
	cp	d
	jr	c,DEVFIND1
	scf
	ret
DEVFIND3:
	in	a,(BPRT)
	or	a
	ret
