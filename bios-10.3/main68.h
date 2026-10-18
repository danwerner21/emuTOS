/* main68.h */
/*
	Copyright (C) 2011,2012 John R. Coffman.
	Licensed for hobbyist use on the N8VEM baby M68k CPU board.
***********************************************************************

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    in the file COPYING in the distribution directory along with this
    program.  If not, see <http://www.gnu.org/licenses/>.

**********************************************************************/
#ifndef _MAIN68_H
#define _MAIN68_H
#include <string.h>
#include "mytypes.h"

#define nelem(x)	(sizeof(x)/sizeof *(x))
#define GETLINE(buf) getline((char*)buf,nelem(buf))
#define GETUCLINE(buf) uc_string(buf,getline(buf,nelem(buf)))
#define EOF (-1)
#define true 1
#define false 0
typedef int bool;
/* see 'cmd_buffer[LINELEN+FUDGE];' in main68.c & debug68.c	*/
#if CPU>68010
#define LINELEN 1024
#else
#define LINELEN 256
#endif
#define FUDGE 4


#pragma pack(2)
typedef
struct NVRAM {
	byte	sio_div_lo;
	byte	sio_div_hi;
	byte	century;			/* in BCD */
	signed boot_disk_1 : 4;
	signed boot_disk_2 : 4;
	byte	nboards;
	struct BOARD {
		byte	port;
		byte	type;
	} board[4];
	struct FLOPPY_NV {
		byte	port;
		byte	type;
	} floppy[2];
	byte	autoboot;		/* autoboot timeout / enable */
} T_nv_struct;

extern uint32 h_m_a;
#if !RETAIL
int16 debug;
#endif


typedef int t_handler(char *argv[], int argc);
#if 0
void handle_any_command(char *argv[], int argc);
#else
t_handler handle_any_command;
int execute_cmd(t_handler *handle_any, char *linebuffer);
#endif

typedef struct
{
    const char *name;
    const int min_args;
    const int max_args;
    void (* function)(char *argv[], int argc);
    const char *helpme;
} cmd_entry_t;


extern
struct STATUS {
	long	d[8];
	long	a[8];		/* saved A7 is SSP after exception frame is pushed */
	long	ssp;		/* A7 == Supervisor SP (probably ISP) */
	long	usp;		/* the USP */
	long	pc;
	word	frame;		/* bit 15 is frame invalid bit */
	word	sr;		/* high word MBZ; low word is SR */
#if CPU>68010
	long	isp;		/* ISP on 68020 */
	long	msp;		/* MSP on 68020 */
#endif
	word	trap_no;	/* trap number save */
} state;


#if !RETAIL
	int lites(byte val);	/* the 8-bit light value is put out */
	int switches();		/* the 8-bit sign-extended value in the switches is read */
#endif

#ifndef strcasecmp
int strcasecmp(const char *s, const char *d);
#endif
#ifndef strncasecmp
int strncasecmp(const char *s, const char *d, size_t n);
#endif
int cprintf(char const *fmt, ...);
int putch(char ch);
int getline(char *line, int linesize);
#if !RETAIL
void prbuf(dword addr, byte *buf, int n);
#endif
void pretty_dump_memory(void *start, int len);
void fmt_dump(int format, uint32 start, uint32 count);
void print_reg_state(struct STATUS *statep);
void print_state(struct STATUS *statep);
qword daytime_c(byte option);	/* in setup.c */
int cpu_cache_disable(void);





#endif  /* _MAIN68_H */

