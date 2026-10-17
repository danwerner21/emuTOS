/* version.h -- version information for the Mini-M68000 board BIOS */
#ifndef __VERSION_H
#define __VERSION_H	1

#define VERSION_DAY		16
#define VERSION_MONTH 	        May
#define VERSION_MONTH_NUMERIC   5
#define VERSION_YEAR	    	2016

#define VERSION_MAJOR	10
#define VERSION_MINOR	2
#define SUBVERSION	J

#define VER_DAY_MIN (VERSION_DAY+VERSION_MINOR)
#define ROM_SERIAL_NO (((VERSION_MAJOR<<4)+(VER_DAY_MIN<<2)+SUBVERSION)%31)

#define S2(x) #x
#define S(x) S2(x)

#if RETAIL
#define VERSION_STRING S(VERSION_MAJOR) "." S(VERSION_MINOR)
#else
#define VERSION_STRING S(VERSION_MAJOR) "." S(VERSION_MINOR) "-" S(SUBVERSION)
#endif
#define VERSION_DATE S(VERSION_DAY) "-" S(VERSION_MONTH) "-" S(VERSION_YEAR)


#endif	/* __VERSION_H */
/* end version.h */

