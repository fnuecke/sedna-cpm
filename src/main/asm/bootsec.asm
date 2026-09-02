; MIT licensed, see LICENSE.
;
; Boot descriptor sector, written to track 0 sector 1 of a bootable disk.
; Describes where the system image following it loads and starts, so the
; boot ROM needs no hardcoded memory map or disk geometry info.

	cpu	z80
	page	0

	include	"memmap.inc"
	include	"bootdef.inc"
	include	"geometry.inc"

SYSLEN	equ	MEMTOP-CCP
SYSSEC	equ	SYSLEN/DSKLEN

	if	SYSSEC*DSKLEN <> SYSLEN
	error	"system image is not a whole number of sectors"
	endif
	if	(BSYS0+SYSSEC)*DSKLEN > DSKOFF*DSKSEC*DSKLEN
	error	"descriptor and system image overflow the reserved tracks"
	endif

	org	0

	db	BMAG0,BMAG1
	dw	CCP
	dw	BIOS
	db	SYSSEC
	db	DSKSEC

	if	$ > DSKLEN
	error	"boot descriptor overflows its sector"
	endif

	end
