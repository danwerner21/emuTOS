;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fdcpio.asm -- the parts of the floppy driver that have to be assembly
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
; The floppy controller is an SMC FDC9266 on an ECB Disk I/O V3, reached at
; 0x430-0x43F -- Z80 I/O 30h-3Fh, which the 386EX sees at 0x400 + N.  There
; is no DMA on that board, so every byte of every sector passes through the
; CPU.  Only two things here need to be assembly; the rest of the driver is
; C, in "diskfdc.c".
;
;   the data phase	because a byte not collected within 16 microseconds
;			is an overrun, and a C loop through io_read() has
;			neither the speed nor the control over interrupts
;
;   FDC_stop_motor	because int_irq0 calls it having saved only BX, CX
;			and DS.  Anything it disturbs beyond those three
;			corrupts whatever the tick interrupted.
;
; Assembly by NASM 2.08 is preferred
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%include "seg_def.inc"
%include "i386ex.inc"
%include "macro.inc"
%include "bda.inc"

FDC_LATCH	equ	0x438		; the 74LS273, write only
FDC_MOTOR	equ	0x02		; its motor bit

	global	_fdc_pio_in
	global	_fdc_pio_out
	global	FDC_stop_motor
	global	FDC_stop_motor_

segment	_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fdc_pio_in -- the data phase of a read
; fdc_pio_out -- the data phase of a write
;
;	int fdc_pio_in (word base, byte far *buf, word count);
;	int fdc_pio_out(word base, byte far *buf, word count);
;
;	0	all of it moved
;	1	the controller stopped asking before the count ran out
;	2	it stopped answering altogether
;
; At 500 kbps a byte arrives every 16 microseconds, and one not collected
; before the next arrives is an overrun -- a silently corrupt sector, which
; reads as bad media rather than as bad timing.  On the way out an underrun
; is worse still: it damages what is on the disk, and no amount of re-reading
; recovers it.  So the burst runs with interrupts off.  The IRQ4 console
; handler saves nine registers, reads two ports, runs kbd_stuff and drains
; again if a second character is waiting -- plausibly 8 to 15 microseconds
; for one and past the budget for two.  It cannot land inside a sector.
;
; But only the burst, not the wait before it.  After the command is accepted
; the controller sits out the rotational latency until the wanted sector
; comes round, and that is up to a full revolution: 200ms at 300 rpm.
; Interrupts off for that long would cost the 18.2hz tick several counts,
; because a latched IRQ0 collapses however many periods it was held through
; into one interrupt, and the clock would lose time on every access.  The
; first byte is therefore waited for with interrupts as the caller left them,
; and CLI happens only once that byte is sitting in the data register.  The
; one exposure left -- an interrupt taken between seeing RQM and reaching
; CLI -- has the same 16 microseconds of slack to be absorbed in.
;
; MSR is matched three bits at a time, and EXEC belongs in the mask:
;
;	E0	RQM, DIO set, EXEC	the read data phase wants collecting
;	A0	RQM, DIO clear, EXEC	the write data phase wants feeding
;	C0	RQM, DIO set, no EXEC	the result phase: the command ended
;	80	RQM, DIO clear, no EXEC	the command phase, not yet handed over
;
; 80 and C0 are the pair that must not be confused with each other or with
; the data phases.  Testing EXEC alone cannot tell "not started" from
; "finished", and masking it away entirely lets a result-phase read pull
; sector data out of the data register and call it status.  Both of those
; were real, and both looked like hardware faults.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_fdc_pio_in:
	push	bp
	mov	bp,sp
	sub	sp,2			; [bp-2] is the result
	pushm	bx,cx,dx,si,di,ds,es

	mov	word [bp-2],2		; assume it never answers
	mov	dx,[bp+4]		; the main status register
	les	di,[bp+6]		; ES:DI -> the caller's buffer
	mov	cx,[bp+10]
	cld
	jcxz	.ok

	mov	ebx,1000000		; about a second: a revolution is 200ms
.wait1:
	in	al,dx
	and	al,0xE0
	cmp	al,0xE0			; a byte to collect
	je	.burst
	cmp	al,0xC0			; result phase: ended without data
	je	.short
	dec	ebx
	jnz	.wait1
	jmp	.9

.burst:
	pushf
	cli
.next:
	inc	dx
	in	al,dx
	dec	dx
	stosb
	dec	cx
	jz	.done

	mov	bx,0			; ~65k tries, far longer than 16us
.wait:
	in	al,dx
	and	al,0xE0
	cmp	al,0xE0
	je	.next
	cmp	al,0xC0
	je	.cut
	dec	bx
	jnz	.wait
	mov	word [bp-2],2
	jmp	short .out
.cut:
	mov	word [bp-2],1
	jmp	short .out
.done:
	mov	word [bp-2],0
.out:
	popf
	jmp	short .9
.short:
	mov	word [bp-2],1
	jmp	short .9
.ok:
	mov	word [bp-2],0
.9:
	popm	bx,cx,dx,si,di,ds,es
	mov	ax,[bp-2]
	mov	sp,bp
	pop	bp
	ret


_fdc_pio_out:
	push	bp
	mov	bp,sp
	sub	sp,2
	pushm	bx,cx,dx,si,di,ds,es

	mov	word [bp-2],2
	mov	dx,[bp+4]
	lds	si,[bp+6]		; DS:SI -> the caller's buffer.  DS,
					;  not ES: the direction differs and
					;  so does the segment register
	mov	cx,[bp+10]
	cld
	jcxz	.ok

	mov	ebx,1000000
.wait1:
	in	al,dx
	and	al,0xE0
	cmp	al,0xA0			; wants a byte fed to it
	je	.burst
	cmp	al,0xC0
	je	.short
	dec	ebx
	jnz	.wait1
	jmp	.9

.burst:
	pushf
	cli
.next:
	lodsb
	inc	dx
	out	dx,al
	dec	dx
	dec	cx
	jz	.done

	mov	bx,0
.wait:
	in	al,dx
	and	al,0xE0
	cmp	al,0xA0
	je	.next
	cmp	al,0xC0
	je	.cut
	dec	bx
	jnz	.wait
	mov	word [bp-2],2
	jmp	short .out
.cut:
	mov	word [bp-2],1
	jmp	short .out
.done:
	mov	word [bp-2],0
.out:
	popf
	jmp	short .9
.short:
	mov	word [bp-2],1
	jmp	short .9
.ok:
	mov	word [bp-2],0
.9:
	popm	bx,cx,dx,si,di,ds,es
	mov	ax,[bp-2]
	mov	sp,bp
	pop	bp
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FDC_stop_motor -- the motor timeout, called from the 18.2hz tick
;
; int_irq0 counts bda.motor_count down and calls this when it reaches zero.
; That call arrives having saved only BX, CX and DS, so everything else this
; touches has to be put back -- a driver that quietly corrupted DX or ES here
; would break whatever the tick happened to interrupt, which is to say
; anything at all, intermittently.
;
; The latch is a 74LS273 and cannot be read, so the motor bit is cleared in
; the shadow at bda.motor_status and the whole byte written back.  Losing
; track of that shadow means losing the drive select, the data rate and the
; reset line along with the motor.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FDC_stop_motor:
FDC_stop_motor_:
	pushm	ax,dx,ds
	pushf

	get_bda	DS
	mov	al,[motor_status]
	and	al,~FDC_MOTOR		; motor off, everything else kept
	mov	[motor_status],al

	mov	dx,FDC_LATCH
	out	dx,al

	popf
	popm	ax,dx,ds
	ret
