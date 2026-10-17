/* crc32.c */
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
#include "mytypes.h"
#include "crc32.h"

/* accumulate a partial CRC-32 */

static
uint32 crc32partial(byte *cp, int nsize,
			uint32 polynomial, uint32 *accum)
{
   uint32 poly, crc;
   int i;
   byte ch;

   crc = ~*accum;
   while (nsize--) {
      ch = *cp++;
      for (i=0; i<8; i++) {
         if ( ( (crc>>31) ^ (ch>>(7-i)) ) & 1) poly = polynomial;
         else poly = 0UL;
         crc = (crc<<1) ^ poly;
      }
   }
   return (*accum = ~crc);
}


/* calculate a CRC-32 polynomial */

uint32 crc32 (byte *cp, int nsize, uint32 polynomial)
{
    uint32 crc = 0;
    return crc32partial(cp, nsize, polynomial, &crc);
}


