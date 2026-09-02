; MIT licensed, see LICENSE.
;
; WD1793 command and status bits, shared by the boot ROM and the CBIOS.
; Register offsets from the controller's port base:
; 0 status/command, 1 track, 2 sector, 3 data, 4 drive select.

FSEEK	equ	10h
FREAD	equ	80h
FWRITE	equ	0A0h
FBUSY	equ	01h
FNRDY	equ	80h		; status: nothing in the selected drive
FERRI	equ	90h		; seek errors: not ready | seek error
FERR	equ	0D4h	; transfer errors: not ready | write protected | not found | lost data
