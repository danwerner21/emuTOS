/* ppide2.c		*/
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
#include "myide.h"

const struct OPERATION ppide_operations = {
	ppide_reset,
	ppide_info,
	ppide_read,
	ppide_write,
	ppide_verify,
	NULL
};

int ppide_reset  (struct DISK *i)
{
	return 0;
}

int ppide_info   (struct DISK *i)
{
	return 0;
}


int ppide_read   (struct DISK *i, dword sector, byte *buffer)
{
	return 0;
}

int ppide_write  (struct DISK *i, dword sector, byte *buffer)
{
	return 0;
}

int ppide_verify (struct DISK *i, dword sector)
{
	return 0;
}

int ppide_format (struct DISK *i, byte *interleave)
{
	return 0;
}


