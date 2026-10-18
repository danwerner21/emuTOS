/*
 * spi_mini68k.c - SPI interface for the RetroBrew Dual-SD board
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The Dual-SD board on the Mini-M68k ECB bus bit-bangs SPI through two
 * registers, as in the BIOS driver (bios-10.2/dualsd.s):
 *
 *  operation register (base port):
 *      write: bit 0 = data out (MOSI), bit 1 = clock, bit 2 = chip select
 *      read:  bit 0 = data in (MISO), bit 4 = write protect,
 *             bit 5 = card detect (of the selected socket)
 *  select register (base port + 1):
 *      bit 0 = socket (0 or 1); both sockets are used, as SD units 0 and 1
 *
 * Bytes are sent MSB first, in SPI mode 0: data changes while the clock
 * is low, and is sampled on the rising edge. The bit-banged clock is far
 * below 400 kHz, so the clock speed functions have nothing to do.
 *
 * The board is found in the BIOS NVRAM configuration. Without one, the
 * SD/MMC driver reports no device (see mini68k_dualsd_present()).
 */

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "spi.h"
#include "mini68k.h"

#if defined(MACHINE_MINI68K) && CONF_WITH_SDMMC

#define DSD_OPERATION   0
#define DSD_SELECT      1

#define DSD_DATA        0x01    /* write: data out, read: data in */
#define DSD_CLK         0x02
#define DSD_CS          0x04
#define DSD_CD          0x20    /* read: card detect */

#define DSD_SOCKETS     2

static volatile UBYTE *dsd;     /* operation register, or NULL if no board */
static UBYTE dsd_cs;            /* DSD_CS while chip select is asserted */
static UBYTE dsd_socket;        /* the socket the SD/MMC driver is using */

/*
 * Find the first Dual-SD board configured in the BIOS Setup.
 * Return the address of its operation register, or NULL if there is none.
 */
static volatile UBYTE *find_dualsd(void)
{
    struct mini68k_board boards[MINI68K_MAX_BOARDS];
    int n, i;

    n = mini68k_get_disk_boards(boards);
    for (i = 0; i < n; i++)
    {
        if (boards[i].type == MINI68K_BOARD_DUALSD)
            return (volatile UBYTE *)MINI68K_ECB_IO(boards[i].port);
    }

    return NULL;
}

/*
 * Does this socket exist? The card detect switch is not used to decide
 * whether a card is present, because it is not reliable on every board
 * (one socket reported no card with a working card inserted). Instead,
 * the SD/MMC driver tries to initialise the card, and reports no device
 * when that fails (see sd_ioctl()).
 */
BOOL mini68k_dualsd_present(UWORD socket)
{
    volatile UBYTE *op = find_dualsd();

    return op != NULL && socket < DSD_SOCKETS;
}

/*
 * Switch to another socket (called by the SD/MMC driver)
 */
void mini68k_dualsd_select(UWORD socket)
{
    spi_cs_unassert();
    dsd_socket = socket;
    if (dsd)
        dsd[DSD_SELECT] = socket;
}

/*
 *  initialise spi for memory card
 */
void spi_initialise(void)
{
    dsd = find_dualsd();
    if (!dsd)
        return;

    dsd[DSD_SELECT] = dsd_socket;
    spi_cs_unassert();

    KDEBUG(("Dual-SD at %p, socket %d: card %s (operation register 0x%02x)\n",
            dsd, dsd_socket, (dsd[DSD_OPERATION] & DSD_CD) ? "present" : "absent",
            dsd[DSD_OPERATION]));
}

void spi_clock_sd(void)
{
}

void spi_clock_mmc(void)
{
}

void spi_clock_ident(void)
{
}

void spi_cs_assert(void)
{
    dsd_cs = DSD_CS;
    if (dsd)
        dsd[DSD_OPERATION] = DSD_CS | DSD_DATA;     /* clock low */
}

void spi_cs_unassert(void)
{
    dsd_cs = 0;
    if (dsd)
        dsd[DSD_OPERATION] = DSD_DATA;              /* clock low */
}

void spi_send_byte(UBYTE c)
{
    volatile UBYTE *op = dsd;
    UBYTE cs = dsd_cs;
    int i;

    if (!op)
        return;

    for (i = 0; i < 8; i++, c <<= 1)
    {
        UBYTE bit = cs | ((c & 0x80) ? DSD_DATA : 0);

        *op = bit;              /* data out, clock low */
        *op = bit | DSD_CLK;    /* rising edge: the card samples */
    }
}

UBYTE spi_recv_byte(void)
{
    volatile UBYTE *op = dsd;
    UBYTE idle = dsd_cs | DSD_DATA;     /* keep MOSI high while reading */
    UBYTE c = 0;
    int i;

    if (!op)
        return 0xff;

    for (i = 0; i < 8; i++)
    {
        *op = idle;             /* falling edge: the card shifts out a bit */
        c = (c << 1) | (*op & DSD_DATA);
        *op = idle | DSD_CLK;
    }

    return c;
}

#endif /* MACHINE_MINI68K && CONF_WITH_SDMMC */
