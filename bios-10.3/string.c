/* mystring.c */
/*
	Copyright (C) 2016-2021 John R Coffman.
	Licensed for hobbyist use only.
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
#include "string.h"
#include "ctype.h"

int my_strcasecmp(const char *s, const char *d)
{
   for(;;)
   {
      if( *s != *d )
      {
	 if( tolower(*s) != tolower(*d) )
	    return *s - *d;
      }
      else if( *s == '\0' ) break;
      s++; d++;
   }
   return 0;
}

int my_strncasecmp(const char *s, const char *d, size_t l)
{
   while(l>0)
   {
      if( *s != *d )
      {
	 if( tolower(*s) != tolower(*d) )
	    return *s - *d;
      }
      else
	 if( *s == '\0' ) return 0;
      s++; d++; l--;
   }
   return 0;
}

