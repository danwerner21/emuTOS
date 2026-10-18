;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 40h_flop.asm -- INT 40h, the floppy disk interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Copyright (C) 2026 Dan Werner.  All rights reserved.
; Provided for hobbyist use on the RetroBrew SBC-386EX board.
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program in the file COPYING in the topmost source
; directory.  If not, see <http://www.gnu.org/licenses/>.
;
;
; INT 13h sends every call with DL below 80h here, through floppy_call in
; 13h_disk.asm -- "int 0x40" and then "retf 2", so the flags this leaves are
; the ones the original caller sees.  The work is done by the driver in
; diskfdc.c; this is the BIOS surface over it.
;
;    Function		Usage
;    ========		=====
;	00	reset the disk system
;	01	get the status of the last operation
;	02	read sectors
;	03	write sectors
;	04	verify sectors
;	08	get drive parameters
;	15	get disk type
;
; Transfers go one sector per call into the driver, and this loops -- the
; same shape as rwv_common in 13h_disk.asm and for the same reason.  A
; multi-sector request that crosses the end of a track has to step the head,
; and the buffer advance has to carry across a 64K segment boundary, neither
; of which a single command handed to the controller can do.
;
; There is nothing to probe for.  A PC floppy interface cannot be asked what
; is attached, or even whether anything is, and JP4 on the Disk I/O board
; ties RDY to ground so the controller always believes a drive is ready.
; bda.floppy_tab[] is the only answer there is, and it comes from SETUP.
;
; Assembly by NASM 2.08 is preferred
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%include "seg_def.inc"
%include "i386ex.inc"
%include "macro.inc"
%include "bda.inc"
%include "stack.inc"
%include "error.inc"

	global	int_40h
	global	disk_base_360
	global	disk_base_1200
	global	disk_base_720
	global	disk_base_1440
	global	fd_param_table
	global	fd_set_1E_

	extern	_fd_reset
	extern	_fd_rw
	extern	_fd_format

segment	_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Geometry, by the drive type in bda.floppy_tab[].  The order matches the
; FD_ enum in "nvram.h", which is the PC/AT CMOS numbering: 1 is 360Kb,
; 2 is 1.2Mb, 3 is 720Kb, 4 is 1.44Mb.  Those numbers are what INT 13h
; function 15h hands back, and software has recognised them since 1984.
;
;	cylinders, heads, sectors per track
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	align	2
fd_geom:
	db	0,  0,  0		; FD_NONE
	db	40, 2,  9		; FD_360
	db	80, 2, 15		; FD_1200
	db	80, 2,  9		; FD_720
	db	80, 2, 18		; FD_1440
FD_TYPES	equ	($-fd_geom)/3

; The same numbering as the enum in "nvram.h", which is the PC/AT CMOS
; coding.  Named here because the tables below are lists of types
; rather than a row per type, and a bare 4 in such a list says nothing.
FD_NONE		equ	0
FD_360		equ	1
FD_1200		equ	2
FD_720		equ	3
FD_1440		equ	4

;
; The INT 1Eh disk base tables, one per type.  They differ in the places
; that matter to a reader: sectors per track, the gap lengths, and the
; motor start time.  INT 13h function 08h hands back the one that belongs
; to the drive being asked about.
;
	align	2
fd_param_table:
	dw	disk_base_none
	dw	disk_base_360
	dw	disk_base_1200
	dw	disk_base_720
	dw	disk_base_1440

disk_base_none:
disk_base_1440:
	db	0xDF		; step rate 0Dh, head unload time Fh
	db	0x02		; head load time 1, DMA used
	db	0x25		; ticks before the motor stops
	db	0x02		; bytes per sector, 2 = 512
	db	18		; sectors per track
	db	0x1B		; gap length between sectors
	db	0xFF		; data length
	db	0x6C		; gap length when formatting
	db	0xF6		; fill byte for formatting
	db	0x0F		; head settle time, milliseconds
	db	0x08		; motor start time, eighths of a second

disk_base_1200:
	db	0xDF, 0x02, 0x25, 0x02
	db	15
	db	0x1B, 0xFF, 0x54, 0xF6, 0x0F, 0x08

disk_base_720:
	db	0xDF, 0x02, 0x25, 0x02
	db	9
	db	0x2A, 0xFF, 0x50, 0xF6, 0x0F, 0x08

disk_base_360:
	db	0xDF, 0x02, 0x25, 0x02
	db	9
	db	0x2A, 0xFF, 0x50, 0xF6, 0x0F, 0x08


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fd_type -- the configured type of the drive in DL
;
;    Exit with:
;	AL	the FD_ type, 0 if the drive is not configured or not there
;	SI	its entry in fd_geom
;	Carry set if there is no such drive
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The drive comes from the saved frame, not from the live DL.  rw_common
; uses DX as its sectors-completed counter, so by the time fd_next asks for
; the geometry mid-transfer the live DL is a count, not a drive -- which
; fetched the wrong track layout, stepped the head and cylinder wrongly, and
; seeked somewhere that was not there.  The first sector always worked,
; which is why a DIR of a root directory inside one track never showed it.
fd_type:
	push	bx
	push	ds
	get_bda	DS

	movzx	bx,byte [bp+offset_dx]	; BP is SS-relative, so this reads the
					;  caller's DL whatever DS now is
	cmp	bl,2			; two drives is all a PC cable has
	jnb	.bad
	mov	al,[bx+floppy_tab]
	cmp	al,FD_TYPES
	jnb	.bad
	or	al,al
	jz	.bad

	movzx	si,al			; AL * 3 into the geometry table
	mov	bx,si			; BX is already saved
	add	si,si
	add	si,bx			;  -- and AX may have rubbish in AH,
	add	si,fd_geom		;     which is why BX does the adding
	clc
.9:
	pop	ds
	pop	bx
	ret
.bad:
	xor	al,al
	stc
	jmp	short .9


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INT 40h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This was neutralised for a while behind a FLOPPY_INT13 define, bisecting a
; boot failure that turned out to be a corrupt CF image -- the card would not
; boot on another PC either.  The switch is gone; it was chasing a fault that
; was never in this file.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A trace, for watching a boot that hangs with no console left.
;
; INT 14h transmit is polled rather than interrupt driven, so this still
; writes when a hang has taken the interrupts with it -- which is exactly
; the case it is for.  One character in on each call, naming the function,
; and one out saying how it went:
;
;	0 1 2 3 4 8 E	the function: 00, 01, 02, 03, 04, 08, 15h
;	.		returned with no error
;	!		returned an error
;	?		an unsupported function
;
; So a working read is "2." and a drive retrying one for ever is
; "2!2!2!2!..." for as long as you care to watch it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%define FD_TRACE 0

%if FD_TRACE
fd_trace:				; AL = the character to send
	pushm	ax,bx,cx,dx
	mov	ah,1			; INT 14h write, polled
	xor	dx,dx			; COM1
	int	0x14
	popm	ax,bx,cx,dx
	ret


;
; The request, as "[cc hh ss nn ssss:bbbb]" -- cylinder, head, sector (with
; the two high cylinder bits still in its top bits, as INT 13h passes them),
; count, and the caller's buffer.
;
; Entered at the top of int_40h with CX and DX still as the caller set them,
; and BP framing the pushed registers.  Every helper below preserves BX, CX
; and DX so the live request survives being printed a piece at a time.
;
fd_trace_rw:
	pushm	ax,bx,cx,dx
	mov	al,'['
	call	fd_trace
	mov	al,ch			; cylinder, low eight bits
	call	fd_trace_hex
	mov	al,' '
	call	fd_trace
	mov	al,dh			; head
	call	fd_trace_hex
	mov	al,' '
	call	fd_trace
	mov	al,cl			; sector, plus the high cylinder bits
	call	fd_trace_hex
	mov	al,' '
	call	fd_trace
	mov	al,[bp+offset_ax]	; sector count, as it came in
	call	fd_trace_hex
	mov	al,' '
	call	fd_trace
	mov	ax,[bp+offset_es]
	call	fd_trace_hex16
	mov	al,':'
	call	fd_trace
	mov	ax,[bp+offset_bx]
	call	fd_trace_hex16
	mov	al,']'
	call	fd_trace
	popm	ax,bx,cx,dx
	ret

fd_trace_hex16:				; AX, as four hex digits
	pushm	ax,bx,cx,dx
	xchg	al,ah
	call	fd_trace_hex
	xchg	al,ah
	call	fd_trace_hex
	popm	ax,bx,cx,dx
	ret

fd_trace_hex:				; AL, as two hex digits
	pushm	ax,bx,cx,dx
	mov	ah,al
	shr	al,4
	call	fd_trace_nyb
	mov	al,ah
	call	fd_trace_nyb
	popm	ax,bx,cx,dx
	ret

fd_trace_nyb:
	and	al,0x0F
	add	al,'0'
	cmp	al,'9'
	jbe	.1
	add	al,7			; 'A' through 'F'
.1:
	jmp	fd_trace		; its RET returns for us
%endif


int_40h:
	sti
	pushm	all,ds,es
	mov	bp,sp
	cld

%if FD_TRACE
	push	ax
	mov	al,ah
	add	al,'0'			; 0-4 and 8 land on digits, 15h on E
	call	fd_trace
	pop	ax

; For the transfer calls, say what was asked for.  Which sectors DOS wants
; is the whole question once the driver is known to return them correctly:
; a request that is itself wrong -- a silly count, a cylinder off the end,
; a buffer in a segment that does not exist -- would be carried out
; faithfully and still wreck the caller.  The one-character trace cannot
; show that, and it is the only thing left that it cannot show.
	cmp	ah,0x02
	jb	.notrw
	cmp	ah,0x05			; 05h formats, and wants the same
	ja	.notrw			;  detail as a transfer
	call	fd_trace_rw
.notrw:
%endif

	cmp	ah,0x00
	je	fn00_reset
	cmp	ah,0x01
	je	fn01_status
	cmp	ah,0x02
	je	fn02_read
	cmp	ah,0x03
	je	fn03_write
	cmp	ah,0x04
	je	fn04_verify
	cmp	ah,0x05
	je	fn05_format
	cmp	ah,0x08
	je	fn08_params
	cmp	ah,0x15
	je	fn15_type
	cmp	ah,0x18
	je	fn18_media

	mov	ah,INVALID_COMMAND
; fall through

;
; Return paths.  AH carries the status and the Carry says whether it is an
; error, which is what floppy_call propagates when it does its RETF 2.
;
fd_error:
	mov	[bp+offset_ax+1],ah
%if FD_TRACE
	mov	al,'!'
	call	fd_trace
%endif
	push	ds
	get_bda	DS
	mov	[fd_status],ah
	pop	ds
	popm	all,ds,es
	stc
	retf	2

fd_good:
	mov	byte [bp+offset_ax+1],0
%if FD_TRACE
	mov	al,'.'
	call	fd_trace
%endif
	push	ds
	get_bda	DS
	mov	byte [fd_status],0
	pop	ds
	popm	all,ds,es
	clc
	retf	2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 00h -- reset.  Pulses the controller's reset line and re-specifies it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fn00_reset:
	push	ds
	mov	ax,DGROUP		; the driver in diskfdc.c reaches the
	mov	ds,ax			;  BDA through bda_ptr, which lives in
	call	_fd_reset		;  DGROUP -- and INT 40h arrives with
	pop	ds			;  whatever DS the caller had
	or	al,al
	jnz	.1
	jmp	fd_good
.1:	mov	ah,al
	jmp	fd_error


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 01h -- the status of the last operation.  DOS reads this after a failure.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fn01_status:
	push	ds
	get_bda	DS
	mov	ah,[fd_status]
	pop	ds
	mov	[bp+offset_ax+1],ah
	popm	all,ds,es
	clc
	retf	2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 02h / 03h / 04h -- read, write, verify
;
;  Enter with:
;	AL	sectors to transfer
;	CH	cylinder, CL bits 5:0 sector, bits 7:6 cylinder high
;	DH	head
;	DL	drive
;	ES:BX	buffer
;
;  Exit with:
;	AL	sectors actually transferred
;
; One sector per driver call, stepping the address on afterwards.  Verify
; reads into the same buffer over and over and throws the data away: proving
; the sectors read back is the whole of what verify is for.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fn04_verify:
	xor	di,di			; verify reads; the buffer is not
	jmp	short rw_common		;  advanced, which is what makes it
fn03_write:				;  a verify rather than a read
	mov	di,1
	jmp	short rw_common

;
; Put back the caller's cursor registers.  Used at every exit below that
; can be reached after they have been pushed.
;
%macro	rw_pop 0
	pop	word [bp+offset_dx]
	pop	word [bp+offset_cx]
	pop	word [bp+offset_bx]
	pop	word [bp+offset_es]
%endmacro

fn02_read:
	xor	di,di
rw_common:
	call	fd_type
	jc	.nodrive
	mov	bh,al			; BH = the FD_ type

;
; The caller's CX, DX and ES:BX are this loop's cursor: fd_next steps the
; cylinder, head and sector in the frame, and the buffer walks on by 512 a
; sector.  They have to go back before returning.  INT 13h hands back the
; registers it was called with -- only AH, AL and the Carry mean anything
; on return -- and DOS depends on that: it adds the transfer length to its
; own ES:BX afterwards, so a pointer left walked on gets counted twice.
;
; The doubling is not a slow leak.  It gains a sector for every sector
; transferred, and the moment the offset carries past FFFFh the next read
; lands back at the bottom of the same segment, on top of whatever is
; already living there -- which, when the file being loaded is COMMAND.COM,
; is DOS itself.
;
	push	word [bp+offset_es]
	push	word [bp+offset_bx]
	push	word [bp+offset_cx]
	push	word [bp+offset_dx]

;
; A verify has no buffer of its own, and the pointer handed with one is
; not required to point anywhere.  DOS passes ES:BX = 0000:0000, because
; on a PC function 04h confirms the sectors read back and never moves a
; byte into memory -- there is nothing for a buffer to mean.
;
; Reading a sector there writes the disk straight over the interrupt
; vector table.  FORMAT's verify pass asks for eighteen of them at once,
; so the whole table goes, every vector with it, and the machine is dead
; where it stands -- no console, no tick, nothing left to report with.
;
; Read into the BIOS scratch buffer instead and throw the data away, the
; way the fixed disk path has always done it.  Overwriting the frame here
; is safe because the caller's registers are put back on the way out.
;
	cmp	byte [bp+offset_ax+1],4
	jne	.notverify
	extern	_SecBuffer
    cs	mov	ax,[_SecBuffer]
	mov	[bp+offset_bx],ax
    cs	mov	ax,[_SecBuffer+2]
	mov	[bp+offset_es],ax
.notverify:

	xor	dx,dx			; DX counts up: how many worked
	movzx	cx,byte [bp+offset_ax]	; sectors wanted
	jcxz	.done			; nothing asked for

	mov	si,cx			; SI counts down

.loop:
	pushm	si,di,dx,bx
	push	ds			; restored after the call below

;
; fd_rw(write, drive, fdtype, cyl, head, sec, buf) -- __cdecl, so every
; argument goes on the stack, rightmost first, and the caller takes them
; off again.  Six words and a far pointer is sixteen bytes.
;
; The arguments are read through BP, which is SS-relative, so they can be
; pushed before DS is changed.  DS has to be DGROUP by the time the call
; happens and cannot be changed before the pushes -- a saved DS sitting
; between the arguments and the return address would be read as the first
; argument.
;
	push	word [bp+offset_es]	; buf: segment first, so the offset
	push	word [bp+offset_bx]	;  lands at the lower address

	movzx	ax,byte [bp+offset_cx]	; CL: sector in bits 5:0
	and	ax,0x3F
	push	ax

	movzx	ax,byte [bp+offset_dx+1]	; DH: head
	push	ax

	mov	cl,[bp+offset_cx]	; the cylinder is split: CH is its
	and	cl,0xC0			;  low eight bits and CL bits 7:6
	movzx	cx,cl			;  are bits 9:8
	shl	cx,2
	movzx	ax,byte [bp+offset_cx+1]
	or	ax,cx
	push	ax

	movzx	ax,bh			; the configured drive type
	push	ax

	movzx	ax,byte [bp+offset_dx]	; DL: drive, 0 or 1
	and	ax,1
	push	ax

	push	di			; write?

	mov	ax,DGROUP
	mov	ds,ax
	call	_fd_rw
	add	sp,16

	pop	ds
	popm	si,di,dx,bx

	or	ax,ax
	jnz	.failed

	inc	dx			; one more done
	dec	si
	jz	.done

	; step to the next sector, wrapping head then cylinder
	call	fd_next
	jc	.badseek

	; A verify has no buffer of its own: it reads each sector over the
	; last one and throws the data away, which is the whole of what
	; verify is.  Everything else advances, carrying across 64K.
	cmp	byte [bp+offset_ax+1],4
	je	.loop

	add	word [bp+offset_bx],512
	jnc	.loop
	add	word [bp+offset_es],0x1000
	jmp	.loop

.done:
	rw_pop
	mov	[bp+offset_ax],dl	; sectors transferred
	jmp	fd_good

.failed:
	mov	ah,al			; the status, before AX is needed again
	rw_pop
	mov	[bp+offset_ax],dl	; how many made it
	jmp	fd_error

.badseek:
	rw_pop
	mov	[bp+offset_ax],dl
	mov	ah,SECTOR_NOT_FOUND
	jmp	fd_error

.nodrive:
	mov	byte [bp+offset_ax],0
	mov	ah,TIME_OUT		; nothing configured there
	jmp	fd_error


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fd_next -- step CH/CL/DH on to the next sector
;
; Sectors count from 1 to the track's last, then the head flips, then the
; cylinder steps.  Carry set if that runs off the end of the disk.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fd_next:
	pushm	ax,bx,cx,si
	call	fd_type
	jc	.bad

    cs	mov	bl,[si+2]		; sectors per track
    cs	mov	bh,[si+1]		; heads
    cs	mov	ch,[si]			; cylinders

	mov	al,[bp+offset_cx]
	mov	ah,al
	and	al,0x3F			; the sector
	inc	al
	cmp	al,bl
	jbe	.putsec

	mov	al,1			; wrap to sector 1
	inc	byte [bp+offset_dx+1]	; next head
	mov	cl,[bp+offset_dx+1]
	cmp	cl,bh
	jb	.putsec

	mov	byte [bp+offset_dx+1],0	; back to head 0
	inc	byte [bp+offset_cx+1]	; next cylinder
	mov	cl,[bp+offset_cx+1]
	cmp	cl,ch
	jnb	.bad			; off the end of the disk
.putsec:
	and	ah,0xC0			; keep the cylinder high bits
	or	ah,al
	mov	[bp+offset_cx],ah
	clc
.9:
	popm	ax,bx,cx,si
	ret
.bad:
	stc
	jmp	short .9


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 05h -- format a track
;
;  Enter with:
;	AL	sectors per track
;	CH	cylinder, CL bits 7:6 its high bits
;	DH	head
;	DL	drive
;	ES:BX	the address field table: four bytes a sector, C H R N
;
; The gap and the filler byte come from the table INT 1Eh points at, not
; from anything here.  That is where a FORMAT puts them when it wants a
; layout other than the standard one, and taking them from the built-in
; table instead would quietly ignore it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fn05_format:
	call	fd_type
	jc	.nodrive
	mov	bh,al			; BH = the FD_ type

	push	word [bp+offset_es]	; the care rw_common takes, for the
	push	word [bp+offset_bx]	;  same reason: the caller's cursor
	push	word [bp+offset_cx]	;  registers have to go back
	push	word [bp+offset_dx]

	push	ds			; restored after the call below

	push	word [bp+offset_es]	; chrn: segment first, so the offset
	push	word [bp+offset_bx]	;  lands at the lower address

; The format gap and the filler, out of the INT 1Eh table.
	push	ds
	xor	ax,ax
	mov	ds,ax
	cnop
	lds	si,[0x1E*4]		; DS:SI -> the disk base table
	mov	di,[si+7]		; low half the gap, high half the filler
	pop	ds
	cnop

	mov	ax,di
	shr	ax,8
	push	ax			; fill
	mov	ax,di
	xor	ah,ah
	push	ax			; gpl

	movzx	ax,byte [bp+offset_ax]	; AL: sectors per track
	push	ax

	movzx	ax,byte [bp+offset_dx+1]	; DH: head
	push	ax

	mov	cl,[bp+offset_cx]	; the cylinder is split the same way
	and	cl,0xC0			;  a read splits it
	movzx	cx,cl
	shl	cx,2
	movzx	ax,byte [bp+offset_cx+1]
	or	ax,cx
	push	ax

	movzx	ax,bh			; the configured drive type
	push	ax

	movzx	ax,byte [bp+offset_dx]	; DL: drive, 0 or 1
	and	ax,1
	push	ax

	mov	ax,DGROUP
	mov	ds,ax
	call	_fd_format
	add	sp,18

	pop	ds

	or	ax,ax
	jnz	.bad
	rw_pop
	jmp	fd_good
.bad:
	mov	ah,al			; the status, before AX is wanted again
	rw_pop
	jmp	fd_error

.nodrive:
	mov	ah,TIME_OUT		; nothing configured there
	jmp	fd_error


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 18h -- set media type for format
;
;  Enter with:
;	CH	last cylinder, CL bits 7:6 its high bits, bits 5:0 sectors
;	DL	drive
;
;  Exit with:
;	ES:DI	the parameter table describing that format
;	AH	0, or 0Ch if this drive cannot be asked for it
;
; Nothing is programmed here and nothing needs to be.  DOS asks this
; before formatting to find out whether a layout is possible at all and
; to be given the table for it; the rate and the geometry are settled
; when 05h runs.  Answering it is what lets a FORMAT proceed -- a drive
; that returns "invalid command" here is one DOS will not format.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fn18_media:
	call	fd_type
	jc	.nomedia
	movzx	bx,al			; the configured drive type
	add	bx,bx
    cs	mov	si,[bx+fd_media_tab]

; The geometry being asked for.
	mov	al,[bp+offset_cx]
	mov	ah,al
	and	al,0x3F			; sectors per track
	and	ah,0xC0
	movzx	cx,ah
	shl	cx,2
	movzx	dx,byte [bp+offset_cx+1]
	or	dx,cx
	inc	dx			; cylinders, counted from the last

.try:
    cs	movzx	bx,byte [si]
	or	bx,bx
	jz	.nomedia		; the list ran out
	inc	si

	mov	di,bx			; fd_geom runs three bytes an entry
	add	di,di
	add	di,bx
    cs	cmp	byte [di+fd_geom],dl	; cylinders
	jne	.try
    cs	cmp	byte [di+fd_geom+2],al	; sectors per track
	jne	.try

	add	bx,bx
    cs	mov	di,[bx+fd_param_table]
	mov	[bp+offset_di],di
	mov	ax,cs
	mov	[bp+offset_es],ax
	jmp	fd_good

.nomedia:
	mov	ah,MEDIA_TYPE_NOT_FOUND
	jmp	fd_error


;
; Which formats a drive of each type may be asked to write, zero ended.
; A high density drive can also write the double density format of its
; own size; nothing can write a format its heads cannot reach, and a
; 720Kb drive asked for 1.44Mb has to be told no rather than left to
; produce a disk that reads back as noise.
;
fd_media_tab:
	dw	fd_media_none
	dw	fd_media_360
	dw	fd_media_1200
	dw	fd_media_720
	dw	fd_media_1440

fd_media_none:	db	0
fd_media_360:	db	FD_360, 0
fd_media_1200:	db	FD_1200, FD_360, 0
fd_media_720:	db	FD_720, 0
fd_media_1440:	db	FD_1440, FD_720, 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 08h -- get drive parameters
;
;  Exit with:
;	CH	last cylinder, CL bits 5:0 sectors per track
;	DH	last head
;	DL	number of floppy drives configured
;	BL	the drive type
;	ES:DI	the disk base table for it
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fn08_params:
	call	fd_type
	jc	.nodrive

	mov	[bp+offset_bx],al	; BL = the type
	movzx	bx,al

    cs	mov	ah,[si]			; cylinders
	dec	ah
	mov	[bp+offset_cx+1],ah	; CH = last cylinder
    cs	mov	al,[si+2]		; sectors per track
	mov	[bp+offset_cx],al	; CL, and no cylinder above 255 here
    cs	mov	al,[si+1]		; heads
	dec	al
	mov	[bp+offset_dx+1],al	; DH = last head

	add	bx,bx
    cs	mov	di,[bx+fd_param_table]
	mov	[bp+offset_di],di
	mov	ax,cs
	mov	[bp+offset_es],ax

	call	fd_count
	mov	[bp+offset_dx],al
	jmp	fd_good

.nodrive:
	mov	word [bp+offset_cx],0
	mov	byte [bp+offset_dx+1],0
	call	fd_count
	mov	[bp+offset_dx],al
	mov	byte [bp+offset_bx],0
	mov	ah,TIME_OUT
	jmp	fd_error


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 15h -- get disk type
;
;	AH	0 none, 1 no change line, 2 change line supported
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fn15_type:
	call	fd_type
	mov	ah,1			; a drive with no change line
	jnc	.1
	xor	ah,ah			; nothing configured there
.1:
	mov	[bp+offset_ax+1],ah
	popm	all,ds,es
	clc
	retf	2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fd_count -- how many floppy drives are configured, in AL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fd_set_1E -- point INT 1Eh at the table for drive A's configured type
;
;	void fd_set_1E(void);
;
; POST calls this once the SETUP configuration is known.  The vector is
; built from page0vectors pointing at the 1.44Mb table, which is the wrong
; answer for a 720Kb or 360Kb drive: it claims 18 sectors a track where
; there are 9, and DOS copies the table and works from the copy.
;
; Drive A decides it, because there is only one vector and INT 13h function
; 08h hands out the right table per drive anyway.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fd_set_1E_:
	pushm	ax,bx,ds,es

	get_bda	DS
	movzx	bx,byte [floppy_tab]	; drive A's type
	cmp	bx,FD_TYPES
	jnb	.9			; nothing sensible configured
	add	bx,bx
    cs	mov	ax,[bx+fd_param_table]

	get_loc0 ES
    es	mov	[0x1E*4],ax		; offset
	mov	ax,cs
    es	mov	[0x1E*4+2],ax		; segment
.9:
	popm	ax,bx,ds,es
	ret


fd_count:
	push	ds
	get_bda	DS
	xor	al,al
	cmp	byte [floppy_tab],0
	je	.1
	inc	al
.1:
	cmp	byte [floppy_tab+1],0
	je	.2
	inc	al
.2:
	pop	ds
	ret
