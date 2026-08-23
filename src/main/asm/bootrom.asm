; MIT licensed, see LICENSE.
;
; Boot ROM for the sedna Z80 board. Shadows the low 8 KiB out of reset, copies the system image
; into high RAM and enters the CBIOS, which drops the shadow.
;
; Uses no stack: writes below the ROM's length go nowhere while the shadow is up.

	cpu	z80
	page	0

SYSDEST	equ	0E200h
SYSLEN	equ	10000h-SYSDEST
BIOS	equ	0F800h

	org	0000h

	di
	ld	hl,SYSIMG
	ld	de,SYSDEST
	ld	bc,SYSLEN
	ldir
	jp	BIOS

	org	0200h		; the CBIOS re-reads the image from here on warm boot
SYSIMG:
	binclude	"ccp.bin"
	binclude	"bdos.bin"
	binclude	"cbios.bin"
SYSEND:

; p2bin pads silently, so nothing downstream would notice a module changing size; the CBIOS finds
; the image at ROMBASE and copies ROMLEN bytes, and both are hardcoded on the other side.
	if	SYSEND-SYSIMG <> SYSLEN
	error	"system image is not SYSLEN bytes"
	endif
	if	$ > 2000h
	error	"boot ROM overflows its 8 KiB"
	endif

	end
