/*
 * mini68k.c - RetroBrew Mini-M68k specific functions
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The Mini-M68k is an MC68008 CPU board for the ECB bus. EmuTOS needs
 * the MF/PIC board too, which provides the console UART, the NS32202
 * interrupt controller with the system timer, the DS1302 RTC and the
 * 82C55 PPIDE interface.
 *
 * EmuTOS is started by the board BIOS, which has already initialised
 * the UART (at the baud rate saved in its NVRAM) and the NS32202
 * (vector base 16, counter interrupt on IR3, about 18.96 Hz).
 * EmuTOS takes over all of low RAM, so the BIOS TRAP #8 API is not
 * usable afterwards: every device is driven directly.
 */

#define ENABLE_KDEBUG   /* FIXME: remove when the port is stable */

#include "emutos.h"
#include "biosdefs.h"
#include "mini68k.h"
#include "ikbd.h"
#include "serport.h"
#include "tosvars.h"

#ifdef MACHINE_MINI68K

/******************************************************************************/
/* Console UART (16550 on the MF/PIC)                                         */
/******************************************************************************/

#define UART_LSR_TEMT   0x40    /* transmitter completely empty */
#define UART_LCR_DLAB   0x80    /* divisor latch access */

/* Maximum number of bytes read from the UART per timer tick */
#define UART_POLL_MAX   32

BOOL mini68k_uart_can_write(void)
{
    return (MINI68K_UART_REG(UART_LSR) & UART_LSR_THRE) != 0;
}

void mini68k_uart_write_byte(UBYTE b)
{
    while (!mini68k_uart_can_write())
        ;

    MINI68K_UART_REG(UART_THR) = b;
}

/*
 * The BIOS does not route the UART interrupt to the NS32202, so input
 * is polled from the 200 Hz system timer interrupt instead. With the
 * FIFO enabled, this keeps up with pasted text at usual baud rates.
 */
void mini68k_rs232_poll(void)
{
    int i;

    for (i = 0; i < UART_POLL_MAX; i++)
    {
        UBYTE data;

        if (!(MINI68K_UART_REG(UART_LSR) & UART_LSR_DR))
            break;

        data = MINI68K_UART_REG(UART_RBR);
#if CONF_SERIAL_CONSOLE && !CONF_SERIAL_CONSOLE_POLLING_MODE
        /* Append a new IOREC value into the IKBD buffer */
        push_ascii_ikbdiorec(data);
#else
        /* Append a new IOREC value into the serial buffer */
        push_serial_iorec(data);
#endif
    }
}

static void mini68k_uart_init(void)
{
    /* Keep the baud rate and line settings chosen in the BIOS Setup.
     * We only need the divisor latch to be closed, as the BIOS leaves it. */
    if (MINI68K_UART_REG(UART_LCR) & UART_LCR_DLAB)
    {
        KDEBUG(("UART: divisor latch open, leaving UART alone\n"));
        return;
    }

    /* Let pending debug output drain before resetting the FIFOs */
    while (!(MINI68K_UART_REG(UART_LSR) & UART_LSR_TEMT))
        ;

    MINI68K_UART_REG(UART_IER) = 0x00;  /* no UART interrupts, see above */
    MINI68K_UART_REG(UART_FCR) = UART_FCR_ENABLE | UART_FCR_CLEAR_RX | UART_FCR_CLEAR_TX;
}

/******************************************************************************/
/* System timer (NS32202 counter)                                             */
/******************************************************************************/

/*
 * NS32202 registers used here, as defined in the Mini-M68k BIOS
 * (ns202def.s, ns202.c). 16-bit registers are written low byte first.
 */
#define ICU_IMSK    10  /* interrupt mask (word), 1 = masked */
#define ICU_CIPTR   18  /* counter interrupt pointer */
#define ICU_CCTL    22  /* counter control */
#define ICU_CICTL   23  /* counter interrupt control */
#define ICU_HCSV    26  /* H-counter starting value (word) */
#define ICU_HCCV    30  /* H-counter current value (word) */

/* CCTL: ccon cfnps cout1 cout0 . crunh crunl cdcrh cdcrl */
#define CCTL_STOP   0x00    /* counters stopped, prescaler (/4) in use */
#define CCTL_CRUNH  0x08    /* H-counter running */

/* CICTL: cerh cirh cieh wenh cerl cirl ciel wenl */
#define CICTL_H_ONLY 0x31   /* H-counter interrupt enabled, L disabled */

/*
 * The counter is clocked at 1.8432 MHz / 4 (prescaler in use), and its
 * period is (starting value + 1). The BIOS uses 24299 for 18.96 Hz;
 * 2303 gives exactly 200 Hz.
 */
#define ICU_COUNTER_CLOCK   (1843200UL / 4)
#define ICU_TIMER_COUNT     ((UWORD)(ICU_COUNTER_CLOCK / CLOCKS_PER_SEC - 1))

static void icu_write16(int reg, UWORD value)
{
    MINI68K_ICU_REG(reg) = LOBYTE(value);
    MINI68K_ICU_REG(reg + 1) = HIBYTE(value);
}

void mini68k_init_system_timer(void)
{
    int i;

    KDEBUG(("NS32202: CCTL=0x%02x CICTL=0x%02x CIPTR=0x%02x\n",
        MINI68K_ICU_REG(ICU_CCTL), MINI68K_ICU_REG(ICU_CICTL), MINI68K_ICU_REG(ICU_CIPTR)));

    /* Interrupts are still masked: install our handlers before anything
     * else. vecs_init() pointed the ICU vectors at the panic handler, so
     * make sure that any unexpected ICU input is acknowledged and ignored. */
    for (i = 0; i < 8; i++)
        MINI68K_ICU_VECTOR(i) = mini68k_int_ignore;
    MINI68K_ICU_VECTOR(MINI68K_ICU_TIMER_IR) = mini68k_int_timer;

    /*
     * Reprogram the counter the way the BIOS does in ns202_init2(), but
     * at CLOCKS_PER_SEC. The rest of the ICU setup (vector base 16,
     * triggering modes) is kept from the BIOS.
     */
    MINI68K_ICU_REG(ICU_CCTL) = CCTL_STOP;
    icu_write16(ICU_HCSV, ICU_TIMER_COUNT);
    icu_write16(ICU_HCCV, ICU_TIMER_COUNT);
    /* High nibble: H-counter input (IR3), low nibble: L-counter input
     * (IR7, its interrupt is disabled). The BIOS uses 0x37 too. */
    MINI68K_ICU_REG(ICU_CIPTR) = (MINI68K_ICU_TIMER_IR << 4) | 0x07;
    MINI68K_ICU_REG(ICU_CICTL) = CICTL_H_ONLY;

    /* The BIOS unmasks IR0-IR7. Only the timer is used for now. */
    icu_write16(ICU_IMSK, (UWORD)~(1U << MINI68K_ICU_TIMER_IR));

    MINI68K_ICU_REG(ICU_CCTL) = CCTL_CRUNH;

    KDEBUG(("NS32202: H-counter started, count=%u for %lu Hz\n",
        ICU_TIMER_COUNT, CLOCKS_PER_SEC));

}

/******************************************************************************/
/* Machine                                                                    */
/******************************************************************************/

void mini68k_machine_init(void)
{
    KDEBUG(("mini68k_machine_init()\n"));
    mini68k_uart_init();
}

#endif /* MACHINE_MINI68K */
