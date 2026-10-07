; MIT licensed, see LICENSE.
;
; DEVLIB -- find devices through the enumeration window device.
;
; Include this in your own source. The window is the one fixed port on the
; machine; everything else is discovered, so never hardcode a device address.

BUS	equ	0E0h
BVER	equ	BUS+0		; format version
BCNT	equ	BUS+1		; device count
BSEL	equ	BUS+2		; selected index
BCLS	equ	BUS+3		; class
BATT	equ	BUS+4		; class-specific attributes
BPRT	equ	BUS+5		; assigned port base
BINT	equ	BUS+6		; interrupt vector, FFh if polled
BNAM	equ	BUS+7		; names, each 0 terminated, an empty one ends; any write rewinds
BID	equ	BUS+8		; id byte stream, 0 ends; any write rewinds

CLSBUS	equ	01h
CLSCHR	equ	02h
CLSBLK	equ	03h
CLSRTC	equ	04h
CLSGPIO	equ	05h
CLSSCRN	equ	06h
CLSROM	equ	07h

; DEVFIND -- locate the B'th device of class C (B is 0-based). With HL other
; than 0, only devices known by the name at HL count (0 terminated; any of a
; device's names matches).
; exit  NC, A = port base, E = index, and the device is selected
;       CY      no such device, A = device count
; Use the returned port with IN r,(C) / OUT (C),r
; It is not known until run time.
DEVFIND:
	in	a,(BCNT)
	ld	d,a
	ld	e,0
DEVFND1:
	ld	a,e
	cp	d
	jr	nc,DEVFND4
	out	(BSEL),a
	in	a,(BCLS)
	cp	c
	jr	nz,DEVFND2
	ld	a,h
	or	l
	call	nz,DEVNAME
	jr	nz,DEVFND2
	inc	b
	dec	b
	jr	z,DEVFND3
	dec	b
DEVFND2:
	inc	e
	jr	DEVFND1
DEVFND3:
	in	a,(BPRT)
	or	a
	ret
DEVFND4:
	ld	a,d
	scf
	ret

; DEVNAME -- check whether the selected device has a name specified at HL (0
; terminated), primary or alias.
; exit  Z       device has the name.
;       NZ      device does not have the name.
; Keeps BC, DE and HL.
DEVNAME:
	push	hl
	xor	a
	out	(BNAM),a	; rewind the name stream
DEVNAM1:
	in	a,(BNAM)	; first byte of the next name
	or	a
	jr	z,DEVNAM4	; no names left
	pop	hl
	push	hl
DEVNAM2:
	cp	(hl)
	jr	nz,DEVNAM3
	or	a		; both ran out at the same place, so it matched
	jr	z,DEVNAM5
	inc	hl
	in	a,(BNAM)
	jr	DEVNAM2
DEVNAM3:
	or	a		; skip the rest of this name
	jr	z,DEVNAM1
	in	a,(BNAM)
	jr	DEVNAM3
DEVNAM4:
	inc	a
DEVNAM5:
	pop	hl
	ret
