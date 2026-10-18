/* ctype.h -- replacing <ctype.h> */
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
#ifndef _CTYPE_H
#define _CTYPE_H 1

/* "_inbound" is true if "a <= c <= b", false otherwise;
    i.e., if 'c' is within the closed interval "[a..b]"
    Explanation:  the comparison is UNSIGNED.  If C is less than A,
    the expression "(c)-a" will be negative, which means it
    has an extremely high unsigned value which is greater than "b-a".
    'a' and 'b' are assumed to be constants, usually character values.	*/

#define _inbound(c,a,b) (((unsigned)(c)-(a))<=((b)-(a)) )


#define isupper(c) _inbound((c),'A','Z')
#define islower(c) _inbound((c),'a','z')
#define isdigit(c) _inbound((c),'0','9')
#define tolower(c) (isupper(c)?(c)^('a'-'A'):(c))
#define toupper(c) (islower(c)?(c)^('a'-'A'):(c))
#define isprint(c) _inbound((c),' ','~')
#define isgraph(c) _inbound((c),'!','~'
#define isspace(c) ((c)==' '||(c)=='\t')
#define isalpha(c) (islower(c)||isupper(c))
#define isalnum(c) (isalpha(c)||isdigit(c))
#define isxdigit(c) (isdigit(c)||_inbound((c),'a','f')||_inbound((c),'A','F'))
#define iscntrl(c) (_inbound((c),'\0','\037')||((c)==0377u))
#define isascii(c) _inbound((c),000,0177)
#define ispunct(c) \
	 (_inbound((c),'!','@')||_inbound((c),'[','`')||_inbound((c),'{','~'))

#endif
