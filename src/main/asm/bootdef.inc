; MIT licensed, see LICENSE.
;
; Layout of the boot descriptor sector. The descriptor is the first sector of
; a bootable disk (track 0, sector 1); the system image follows in the
; remaining reserved-track sectors. The boot ROM takes geometry, load address,
; entry point from the descriptor.

BMAG0	equ	'S'		; magic, first byte
BMAG1	equ	'B'		; magic, second byte

BOFMAG	equ	0		; magic, two bytes
BOFLOAD	equ	2		; word: address the system image is read to
BOFENT	equ	4		; word: address the boot ROM jumps to, C = controller port, B = unit
BOFCNT	equ	6		; byte: sectors to read, starting right after this sector
BOFSPT	equ	7		; byte: sectors per track, numbered from one within a track

BSYS0	equ	1		; linear index of the first system sector within the reserved tracks
