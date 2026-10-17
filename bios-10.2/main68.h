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


int cprintf(char const *fmt, ...);
int putch(char ch);
int getline(char *line, int linesize);
#if !RETAIL
void prbuf(dword addr, byte *buf, int n);
#endif
void pretty_dump_memory(void *start, int len);
qword daytime_c(byte option);	/* in setup.c */
int cpu_cache_disable(void);
void handle_any_command(char *argv[], int argc);


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




#endif  /* _MAIN68_H */

