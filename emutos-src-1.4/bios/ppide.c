/*
 * ppide.c - Parallel port IDE (82C55 PPI) interface
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * Low-level access to an IDE device wired to an 82C55 PPI, as on the
 * RetroBrew MF/PIC board. The bus cycles follow the Mini-M68k BIOS
 * driver (ppide.s):
 *  - port A carries IDE D0-D7, port B carries IDE D8-D15
 *  - port C drives the IDE address, chip selects and strobes
 *  - the PPI is switched to input mode (ports A/B in) for reads, and to
 *    output mode (all ports out) for writes. Setting a PPI mode clears
 *    all output latches, so port C starts with every strobe inactive.
 *
 * The ATA protocol itself is handled by ide.c. The data register block
 * transfers are in ppide2.S.
 */

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "mini68k.h"
#include "ppide.h"

#ifdef MACHINE_MINI68K

/* 82C55 on the MF/PIC, ports 0x44-0x47 */
#define PPIDE_PPI_PORT  0x44
#define PPI_REG(r)      (*(volatile UBYTE *)(MINI68K_ECB_IO(PPIDE_PPI_PORT) + (r)))
#define PPI_A           PPI_REG(0)
#define PPI_B           PPI_REG(1)
#define PPI_C           PPI_REG(2)
#define PPI_CTRL        PPI_REG(3)

/* PPI mode words */
#define PPI_MODE_READ   0x92    /* mode 0, A and B in, C out */
#define PPI_MODE_WRITE  0x80    /* mode 0, all ports out */

/* Strobes on port C, in addition to the register address */
#define PPIDE_WR        0x20
#define PPIDE_RD        0x40

UBYTE ppide_read_reg(UBYTE reg)
{
    UBYTE value;

    PPI_CTRL = PPI_MODE_READ;
    PPI_C = reg;                /* address and chip select first */
    PPI_C = reg | PPIDE_RD;     /* then assert RD */
    value = PPI_A;
    PPI_C = reg;                /* release RD */
    PPI_C = 0;                  /* release the bus */

    return value;
}

void ppide_write_reg(UBYTE reg, UBYTE value)
{
    PPI_CTRL = PPI_MODE_WRITE;
    PPI_A = value;
    PPI_B = 0;
    PPI_C = reg;                /* address and chip select first */
    PPI_C = reg | PPIDE_WR;     /* pulse WR */
    PPI_C = reg;
    PPI_C = 0;                  /* release the bus */
}

#endif /* MACHINE_MINI68K */
