/*  fsdos.h  */
/*
	Copyright (C) 2011 John R. Coffman.
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
#ifndef _FSDOS_H
#define _FSDOS_H	1
#include "mytypes.h"

typedef
struct IOCALLS {
	int (read*) (byte* buffer, byte slave);
	int (write*) (byte* buffer, dword LBA, byte slave);
	int (verify*) (dword LBA, byte slave);
	int (reset*) (byte slave);
} T_iocalls;

typedef
struct PARTITION {
	struct PARTITION *parent;
	struct IOCALLS *iocalls;
	dword base;
	dword size;
} T_partition;

typedef
struct FSFAT {
	struct PARTITION *part;
	byte *fat;			/* FAT buffer pointer */
	dword fatbase[2];
	dword dirbase;
	dword database;
	word	cluster;		/* sectors per cluster */
	word	type;			/* FAT12 or FAT16 */
} T_fsfat;

#endif  // _FSDOS_H

