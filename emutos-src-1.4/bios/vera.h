/*
 * vera.h - VERA video card registers on the Mini-M68k
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

#ifndef VERA_H
#define VERA_H

#ifdef MACHINE_MINI68K

/* The VERA's 32 registers at ECB ports 0x80-0x9f */
#define VERA_REG(r)     (*(volatile UBYTE *)MINI68K_ECB_IO(MINI68K_VERA_PORT + (r)))

#define VERA_ADDR_L     0x00
#define VERA_ADDR_M     0x01
#define VERA_ADDR_H     0x02    /* bit 0: address bit 16, bits 7-4: increment */
#define VERA_DATA0      0x03
#define VERA_DATA1      0x04
#define VERA_CTRL       0x05    /* bits 6-1: DCSEL, bit 0: ADDRSEL */
#define VERA_IEN        0x06
#define VERA_ISR        0x07    /* bit 0: VSYNC, write 1 to clear */
#define VERA_DC0        0x09    /* 0x09-0x0c depend on DCSEL */
#define VERA_DC1        0x0a
#define VERA_DC2        0x0b
#define VERA_DC3        0x0c
#define VERA_L0_CONFIG  0x0d
#define VERA_L0_TILEBASE 0x0f
#define VERA_L0_HSCROLL_H 0x11
#define VERA_L0_VSCROLL_L 0x12
#define VERA_L0_VSCROLL_H 0x13

/* Address increments, in VERA_ADDR_H */
#define VERA_INC0       0x00
#define VERA_INC1       0x10
#define VERA_INC80      0xc0    /* next row of a 640-pixel 1 bpp bitmap */

#define VERA_PALETTE    0x1fa00L
#define VERA_SPRITES    0x1fc00L    /* sprite attributes, 8 bytes each */

#endif /* MACHINE_MINI68K */

#endif /* VERA_H */
