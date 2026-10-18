/* diskfdc.h -- the floppy driver */
#ifndef __DISKFDC_H
#define __DISKFDC_H 1

#include "mytypes.h"

/*
 * Where the controller lives.  Z80 I/O port N reaches the 386EX at
 * 0x400 + N, so the ECB Disk I/O V3 jumpered to 30h-3Fh is here.  30h, 32h,
 * 34h and 36h are four aliases of one register; 36h/37h is the pair the
 * N8VEM convention uses and the pair this driver uses.
 */
#define FDC_MSR		0x436		/* main status, read only	*/
#define FDC_DATA	0x437		/* command and result		*/
#define FDC_LATCH	0x438		/* 74LS273, WRITE ONLY		*/
#define FDC_DIR		0x438		/* digital input, read		*/

/*
 * The latch bits.  It cannot be read back, so bda.motor_status carries a
 * shadow and every write goes through fd_latch() -- writing a bare constant
 * loses the drive select, the data rate and the reset line along with
 * whatever was meant to change.
 */
#define L_TC		0x01		/* terminal count, pulsed	*/
#define L_MOTOR		0x02		/* 1 = motor on			*/
#define L_MINI		0x04		/* 1 = 250 kbps, 0 = 500 kbps	*/
#define L_P2		0x08
#define L_P1		0x10
#define L_P0		0x20
#define L_DENSEL	0x40		/* out to the drive, not the FDC */
#define L_NRESET	0x80		/* 0 = FDC held in reset	*/

/* How long the motor runs after the last access, in 18.2hz ticks. */
#define FD_MOTOR_TIME	37		/* about two seconds		*/

/* MINI for a drive type from "nvram.h": the 5.25 and 3.5 inch high
   density formats are 500 kbps, the double density ones 250. */
byte __cdecl fd_rate( int fdtype );

/* All of these return a BIOS status code from "error.h" -- NO_ERROR, or
   something INT 13h can hand back in AH. */
int  __cdecl fd_reset( void );
int  __cdecl fd_seek( int drive, int head, int cyl );
int  __cdecl fd_rw( int write, int drive, int fdtype,
		int cyl, int head, int sec, byte far *buf );

/* chrn is four bytes a sector -- cylinder, head, record, size -- and nsec
   of them.  gpl and fill come from the INT 1Eh table, which is what a
   FORMAT patches when it wants a layout other than the standard one. */
int  __cdecl fd_format( int drive, int fdtype, int cyl, int head,
		int nsec, int gpl, int fill, byte far *chrn );

/* in fdcpio.asm */
extern int  __cdecl fdc_pio_in ( word base, byte far *buf, word count );
extern int  __cdecl fdc_pio_out( word base, byte far *buf, word count );
extern void FDC_stop_motor( void );

/* in 40h_flop.asm -- point INT 1Eh at drive A's parameter table */
extern void fd_set_1E( void );

#endif	/* __DISKFDC_H */
