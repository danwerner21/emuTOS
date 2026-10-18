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

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "biosdefs.h"
#include "asm.h"
#include "delay.h"
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

/*
 * Rsconf() support
 */

#define UART_DLL    0   /* divisor latch, low byte (DLAB = 1) */
#define UART_DLM    1   /* divisor latch, high byte (DLAB = 1) */

/* LCR bits */
#define UART_LCR_WLEN   0x03    /* word length - 5 */
#define UART_LCR_STOP2  0x04    /* 2 stop bits (1.5 with 5-bit words) */
#define UART_LCR_PEN    0x08    /* parity enable */
#define UART_LCR_EPS    0x10    /* even parity */

/* MFP-style UCR bits, as used by Rsconf() */
#define UCR_CLK16       0x80    /* clock / 16 */
#define UCR_WLEN_SHIFT  5       /* 0 = 8 bits ... 3 = 5 bits */
#define UCR_STOP_MASK   0x18
#define UCR_STOP1       0x08    /* 1 stop bit; 0x10 = 1.5, 0x18 = 2 */
#define UCR_EVEN        0x04
#define UCR_PARITY      0x02

/*
 * UART divisors for the Rsconf() baud rate codes 0 (19200) to 15 (50).
 * The 16550 on the MF/PIC is clocked at 1.8432 MHz: baud = 115200 / divisor.
 */
static const UWORD uart_divisors[] = {
    6, 12, 24, 32, 48, 58, 64, 96, 192, 384, 576, 768, 857, 1047, 1536, 2304
};

/* Read the divisor latch. Interrupts are masked because the timer
 * interrupt reads the receive buffer, which shares its address with DLL. */
static UWORD uart_get_divisor(void)
{
    WORD old_sr = set_sr(0x2700);
    UBYTE lcr = MINI68K_UART_REG(UART_LCR);
    UBYTE lo, hi;

    MINI68K_UART_REG(UART_LCR) = lcr | UART_LCR_DLAB;
    lo = MINI68K_UART_REG(UART_DLL);
    hi = MINI68K_UART_REG(UART_DLM);
    MINI68K_UART_REG(UART_LCR) = lcr;
    set_sr(old_sr);

    return MAKE_UWORD(hi, lo);
}

/*
 * Return the Rsconf() code of the current baud rate. Rates set in the BIOS
 * Setup that have no code (e.g. 38400) are reported as the nearest code,
 * but left unchanged in the hardware.
 */
WORD mini68k_rs232_get_baudrate(void)
{
    UWORD divisor = uart_get_divisor();
    WORD code;

    for (code = 0; code < (WORD)ARRAY_SIZE(uart_divisors) - 1; code++)
    {
        /* nearest code: stop below the midpoint to the next divisor */
        if (divisor < (uart_divisors[code] + uart_divisors[code + 1]) / 2)
            break;
    }

    KDEBUG(("UART: divisor %u, baud rate code %d\n", divisor, code));

    return code;
}

/*
 * Set the baud rate (if baud is a valid code) and the line format
 * (if ucr >= 0). Return the old line format as an MFP-style UCR value
 * in bits 24-31, as Rsconf() does on Atari hardware.
 */
ULONG mini68k_rs232_config(WORD baud, WORD ucr)
{
    UBYTE lcr = MINI68K_UART_REG(UART_LCR) & ~UART_LCR_DLAB;
    UBYTE old_ucr;
    WORD old_sr;

    old_ucr = UCR_CLK16
            | ((3 - (lcr & UART_LCR_WLEN)) << UCR_WLEN_SHIFT)
            | ((lcr & UART_LCR_STOP2) ? 0x18 : UCR_STOP1)
            | ((lcr & UART_LCR_EPS) ? UCR_EVEN : 0)
            | ((lcr & UART_LCR_PEN) ? UCR_PARITY : 0);

    if (ucr >= 0)
    {
        lcr = (3 - ((ucr >> UCR_WLEN_SHIFT) & 3))
            | (((ucr & UCR_STOP_MASK) > UCR_STOP1) ? UART_LCR_STOP2 : 0)
            | ((ucr & UCR_EVEN) ? UART_LCR_EPS : 0)
            | ((ucr & UCR_PARITY) ? UART_LCR_PEN : 0);
    }

    /* Let the character being sent finish before changing the format */
    while (!(MINI68K_UART_REG(UART_LSR) & UART_LSR_TEMT))
        ;

    old_sr = set_sr(0x2700);
    if (baud >= 0 && baud < (WORD)ARRAY_SIZE(uart_divisors))
    {
        UWORD divisor = uart_divisors[baud];

        MINI68K_UART_REG(UART_LCR) = lcr | UART_LCR_DLAB;
        MINI68K_UART_REG(UART_DLL) = LOBYTE(divisor);
        MINI68K_UART_REG(UART_DLM) = HIBYTE(divisor);
    }
    MINI68K_UART_REG(UART_LCR) = lcr;
    set_sr(old_sr);

    return (ULONG)old_ucr << 24;
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
/* Real-time clock (DS1302 on the MF/PIC)                                     */
/******************************************************************************/

/*
 * The DS1302 is bit-banged through a latch at port 0x43, as in the BIOS
 * (ds1302.s). The DS1302 shifts data LSB first; data out of the chip is
 * valid after each falling clock edge.
 */
#define MINI68K_RTC_PORT    0x43
#define RTC_LATCH   (*(volatile UBYTE *)MINI68K_ECB_IO(MINI68K_RTC_PORT))

#define RTC_DATA    0x01    /* data in/out */
#define RTC_WREN    0x02    /* drive the data line (write) */
#define RTC_CLK     0x04    /* serial clock */
#define RTC_NRST    0x08    /* 1 = chip enable inactive (idle) */

#define RTC_CMD_WRITE   0x80
#define RTC_CMD_READ    0x81

/* The BIOS waits at least 9 us after each latch change */
static void rtc_out(UBYTE value)
{
    RTC_LATCH = value;
    delay_loop((loopcount_1_msec + 99) / 100);  /* at least 10 us */
}

static void rtc_start(void)
{
    rtc_out(RTC_NRST);
    rtc_out(0);                 /* chip enable active */
}

static void rtc_stop(void)
{
    rtc_out(0);
    rtc_out(RTC_NRST);          /* chip enable inactive */
}

static void rtc_write_byte(UBYTE value)
{
    int i;

    for (i = 0; i < 8; i++, value >>= 1)
    {
        UBYTE bit = RTC_WREN | (value & RTC_DATA);

        rtc_out(bit);
        rtc_out(bit | RTC_CLK); /* the DS1302 samples on the rising edge */
    }
}

static UBYTE rtc_read_byte(void)
{
    UBYTE value = 0;
    int i;

    for (i = 0; i < 8; i++)
    {
        rtc_out(0);             /* falling edge: the DS1302 outputs a bit */
        value >>= 1;
        if (RTC_LATCH & RTC_DATA)
            value |= 0x80;
        rtc_out(RTC_CLK);
    }

    return value;
}

/*
 * Read or write a DS1302 location. Addresses are those of the BIOS:
 * 0x00-0x08 for the clock registers, 0x20-0x3e for the battery-backed RAM.
 */
UBYTE mini68k_rtc_read(UBYTE address)
{
    UBYTE value;

    rtc_start();
    rtc_write_byte(RTC_CMD_READ | (address << 1));
    value = rtc_read_byte();
    rtc_stop();

    return value;
}

void mini68k_rtc_write(UBYTE address, UBYTE value)
{
    rtc_start();
    rtc_write_byte(RTC_CMD_WRITE | (address << 1));
    rtc_write_byte(value);
    rtc_stop();
}

/******************************************************************************/
/* BIOS NVRAM (DS1302 RAM)                                                    */
/******************************************************************************/

/*
 * The BIOS Setup saves its configuration in the DS1302 RAM at 0x20-0x3e
 * (struct NVRAM in bios-10.2/main68.h; offsets checked against the
 * compiled setup.c, and confirmed with BIOS 10.3 on the board).
 * The bytes are valid when they add up to 0xa2.
 */
#define NVRAM_START     0x20
#define NVRAM_SIZE      31
#define NVRAM_CHECK     0xa2
#define NVRAM_NBOARDS   4       /* number of disk boards */
#define NVRAM_BOARDS    5       /* then { port, type } for each board */

/*
 * Fill boards[MINI68K_MAX_BOARDS] with the disk boards configured in the
 * BIOS Setup, in BIOS order, and return how many there are. If the NVRAM
 * is not valid, use the BIOS default: the PPIDE on the MF/PIC.
 */
int mini68k_get_disk_boards(struct mini68k_board *boards)
{
    /* The NVRAM is read once, then remembered */
    static struct mini68k_board known_boards[MINI68K_MAX_BOARDS];
    static int known_count;
    static BOOL known;
    int i;

    if (!known)
    {
        UBYTE nvram[NVRAM_SIZE];
        UBYTE sum = 0;

        for (i = 0; i < NVRAM_SIZE; i++)
        {
            nvram[i] = mini68k_rtc_read(NVRAM_START + i);
            sum += nvram[i];
        }

        if (sum != NVRAM_CHECK)
        {
            KINFO(("BIOS NVRAM not valid: using the MF/PIC PPIDE only\n"));
            known_boards[0].type = MINI68K_BOARD_PPIDE;
            known_boards[0].port = MINI68K_MFPIC_PPIDE_PORT;
            known_count = 1;
        }
        else
        {
            known_count = nvram[NVRAM_NBOARDS];
            if (known_count > MINI68K_MAX_BOARDS)
                known_count = MINI68K_MAX_BOARDS;

            for (i = 0; i < known_count; i++)
            {
                known_boards[i].port = nvram[NVRAM_BOARDS + 2 * i];
                known_boards[i].type = nvram[NVRAM_BOARDS + 2 * i + 1];
                KDEBUG(("BIOS disk board %d: type %d at port 0x%02x\n",
                        i, known_boards[i].type, known_boards[i].port));
            }
        }

        known = TRUE;
    }

    for (i = 0; i < known_count; i++)
        boards[i] = known_boards[i];

    return known_count;
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
