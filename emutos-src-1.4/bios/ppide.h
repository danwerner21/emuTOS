/*
 * ppide.h - Parallel port IDE (82C55 PPI) interface
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

#ifndef PPIDE_H
#define PPIDE_H

#ifdef MACHINE_MINI68K

/*
 * IDE registers, encoded as the value driven on PPI port C:
 * bits 0-2 = IDE A0-A2, bit 3 = CS0 (command block), bit 4 = CS1
 * (control block). Port C also drives WR (bit 5), RD (bit 6) and
 * RESET (bit 7); see ppide.c.
 */
#define PPIDE_REG_DATA          0x08
#define PPIDE_REG_ERROR         0x09    /* read: error, write: features */
#define PPIDE_REG_FEATURES      0x09
#define PPIDE_REG_SECTOR_COUNT  0x0a
#define PPIDE_REG_SECTOR_NUMBER 0x0b
#define PPIDE_REG_CYLINDER_LOW  0x0c
#define PPIDE_REG_CYLINDER_HIGH 0x0d
#define PPIDE_REG_HEAD          0x0e
#define PPIDE_REG_STATUS        0x0f    /* read: status, write: command */
#define PPIDE_REG_COMMAND       0x0f
#define PPIDE_REG_ALT_STATUS    0x16    /* read: alt. status, write: control */
#define PPIDE_REG_CONTROL       0x16

UBYTE ppide_read_reg(UBYTE reg);
void ppide_write_reg(UBYTE reg, UBYTE value);

/*
 * Block transfers through the data register. Without byteswap, each
 * 16-bit IDE word is stored big-endian (IDE D15-D8 first), which is what
 * the EmuTOS IDE driver expects from a plain data register read.
 * Defined in ppide2.S.
 */
void ppide_read_data(UBYTE *buffer, ULONG bufferlen, WORD need_byteswap);
void ppide_write_data(const UBYTE *buffer, ULONG bufferlen, WORD need_byteswap);

#endif /* MACHINE_MINI68K */

#endif /* PPIDE_H */
