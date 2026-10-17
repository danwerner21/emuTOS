/*
 * mini68k.h - RetroBrew Mini-M68k specific functions
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

#ifndef MINI68K_H
#define MINI68K_H

#ifdef MACHINE_MINI68K

/*
 * ECB I/O space. Port p is at 0xffff8000 + p, supervisor mode only.
 * The 68008 only decodes A0-A21, so this is the sign-extended form of
 * 0x3f8000 + p.
 */
#define MINI68K_ECB_IO(port)    (0xffff8000UL + (port))

/* MF/PIC board, jumpered to base port 0x40 (required by the BIOS) */
#define MINI68K_MFPIC_PORT      0x40

/*
 * NS32202 interrupt control unit on the MF/PIC.
 * Its register-select lines are wired to A8 and up, so register r
 * is at base + r * 0x100. Reading "register 32" is the End-Of-Interrupt
 * cycle, which every handler of an ICU interrupt must perform.
 */
#define MINI68K_ICU_REG(r)  (*(volatile UBYTE *)(MINI68K_ECB_IO(MINI68K_MFPIC_PORT) + ((ULONG)(r) << 8)))
#define MINI68K_ICU_EOI     32

/*
 * The BIOS programs the ICU vector base to 16, so input IRn raises
 * vector 16 + n at CPU level 2. IR3 is the ICU counter (system timer).
 */
#define MINI68K_ICU_VECTOR_BASE 16
#define MINI68K_ICU_TIMER_IR    3
#define MINI68K_ICU_VECTOR(n)   (*(volatile PFVOID *)(((MINI68K_ICU_VECTOR_BASE) + (n)) * 4L))

/* 16550 UART on the MF/PIC (console), ports 0x48-0x4f */
#define MINI68K_UART_PORT   0x48
#define MINI68K_UART_REG(r) (*(volatile UBYTE *)(MINI68K_ECB_IO(MINI68K_UART_PORT) + (r)))

#define UART_RBR    0   /* receive buffer (read) */
#define UART_THR    0   /* transmit holding (write) */
#define UART_IER    1   /* interrupt enable */
#define UART_FCR    2   /* FIFO control (write) */
#define UART_LCR    3   /* line control */
#define UART_MCR    4   /* modem control */
#define UART_LSR    5   /* line status */

#define UART_LSR_DR     0x01    /* receive data ready */
#define UART_LSR_THRE   0x20    /* transmit holding register empty */

#define UART_FCR_ENABLE     0x01
#define UART_FCR_CLEAR_RX   0x02
#define UART_FCR_CLEAR_TX   0x04

/* Machine */
void mini68k_machine_init(void);
void mini68k_init_system_timer(void);

/* Interrupts */
void mini68k_int_timer(void);   /* Raw ICU timer handler, defined in mini68k2.S */
void mini68k_int_ignore(void);  /* Raw handler for unused ICU inputs, defined in mini68k2.S */

/* Real-time clock (DS1302): BIOS addresses, 0x00-0x08 clock, 0x20-0x3e RAM */
UBYTE mini68k_rtc_read(UBYTE address);
void mini68k_rtc_write(UBYTE address, UBYTE value);

/* Console UART */
BOOL mini68k_uart_can_write(void);
void mini68k_uart_write_byte(UBYTE b);
void mini68k_rs232_poll(void);  /* Called from the timer interrupt */
WORD mini68k_rs232_get_baudrate(void);
ULONG mini68k_rs232_config(WORD baud, WORD ucr);

#endif /* MACHINE_MINI68K */

#endif /* MINI68K_H */
