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
; than 0, only devices known by all names in the list at HL count (each 0
; terminated, an empty one ends the list).
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

; DEVNAME -- check whether the selected device has every name in the list at
; HL (each 0 terminated, an empty one ends the list), primary or alias.
; exit  Z       device has all names.
;       NZ      device lacks one.
; Keeps BC, DE and HL.
DEVNAME:
	push	hl
DEVNAM1:
	ld	a,(hl)
	or	a
	jr	z,DEVNAM3	; end of the list, all matched
	call	DEVHAS
	jr	nz,DEVNAM3
DEVNAM2:
	ld	a,(hl)		; skip to the next name
	inc	hl
	or	a
	jr	nz,DEVNAM2
	jr	DEVNAM1
DEVNAM3:
	pop	hl
	ret

; DEVHAS -- check whether the selected device has the name at HL (0
; terminated), primary or alias.
; exit  Z       device has the name.
;       NZ      device does not have the name.
; Keeps BC, DE and HL.
DEVHAS:
	push	hl
	xor	a
	out	(BNAM),a	; rewind the name stream
DEVHAS1:
	in	a,(BNAM)	; first byte of the next name
	or	a
	jr	z,DEVHAS4	; no names left
	pop	hl
	push	hl
DEVHAS2:
	cp	(hl)
	jr	nz,DEVHAS3
	or	a		; both ran out at the same place, so it matched
	jr	z,DEVHAS5
	inc	hl
	in	a,(BNAM)
	jr	DEVHAS2
DEVHAS3:
	or	a		; skip the rest of this name
	jr	z,DEVHAS1
	in	a,(BNAM)
	jr	DEVHAS3
DEVHAS4:
	inc	a
DEVHAS5:
	pop	hl
	ret
