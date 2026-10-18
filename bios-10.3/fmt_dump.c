/* fmt_dump.c		4-format dump		*/
#include "mytypes.h"
#include "main68.h"
#include "ctype.h"

/*
	Copyright (C) 2022 John R Coffman.
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

 enum {fmtB=1, fmtW, fmtC, fmtL};	/* from debug.c */


/* formats are: byte, word, char, long
	a format of 0 is treated as byte
   count is always in bytes, not number of items
*/
#define NCHR 16
#define DELIM "*"
#define range(m,x,M) _inbound(x,m,M)
		

void mid_space(uint32 iaddr)
{
	if ((iaddr & 15) == 8) cprintf(" ");
}


void fmt_dump(int format, uint32 start, uint32 count)
{
	uint32 ibeg, iend, iaddr, inext;
	char chars[NCHR+1];
static const char padL[] = "         ";	/* nine spaces */
#define padW (padL+4)
#define padB (padL+6)
	char *pad;

	word i, inchr;

	ibeg = start;
	iend = ibeg + count;

	if (format==fmtW || format==fmtL)  {
		ibeg &= 0xFFFFFFFE;	/* make it even */
		iend = (iend + 1) & 0xFFFFFFFE;
		count++;
	}
	else format = fmtB;		/* fmtC  has little meaning */

	switch (format) {
		case fmtL:	pad = (char*)padL; break;
		case fmtW:	pad = (char*)padW; break;
		case fmtB:	pad = (char*)padB;
	}
	chars[NCHR] = 0;	/* NULL terminate */
	iaddr = ibeg & -16;			/* align the address */

	do {
		for (i=0; i<NCHR; i++)  chars[i]='.';	/* fill with dots */
		inchr = 0;

	/* begin the line by printing the address */
		cprintf(
#if CPU<68020
			"%06lx: ",
#else
			"%08lx: ",
#endif
				  iaddr);
	inext = iaddr + 16;
	/* is padding needed */
		while (iaddr < ibeg) {
			mid_space(iaddr);
			cprintf(pad);
			for (i=0; i<format; i++) chars[inchr++] = ' ';
			iaddr += format;
		}

	/* now print out the memory dump */
		while (iaddr < inext && iaddr < iend) {
			mid_space(iaddr);
			switch (format) {
			    case fmtL:
				cprintf(" %08lx", *(uint32*)iaddr); break;
			    case fmtW:
				cprintf(" %04hx", *(uint16*)iaddr); break;
			    case fmtB:
				cprintf(" %02hx", (uint16)(*(uint8*)iaddr));
			}
			for (i=0; i<format; i++) {
				uint16 ch = ((uint8*)iaddr)[i];
				if (range(040u, ch, 0176u)) chars[inchr] = ch;
				inchr++;
			}
			iaddr += format;
		}


	/* now pad the end of the line if at end of the memory dump */
		while (iaddr < inext) {
			mid_space(iaddr);
			cprintf(pad);
			for (i=0; i<format; i++) chars[inchr++] = ' ';
			iaddr += format;
		}

		cprintf("  " DELIM "%s" DELIM "\n", chars);		
	} while (iaddr < iend);	



#undef NCHR
}


void print_reg_state(struct STATUS *statep)
{
	short i, j, k;
	char *id;
	long *v = statep->d;
	
	statep->a[7] = (statep->sr & 0x2000u) ? statep->ssp : statep->usp ;

	for (i=0; i<4; ++i) {
		for (j=i; j<16; j += 4) {
			k = j - 8;
			if (j<8) { id = "D";  k = j; } 
			else if (j<12) id = " A";
			else id = "A";
			cprintf("  %s%hd %08lx", id, k, v[j]); 
		}
		cprintf("\n");
	}
}


void print_state(struct STATUS *statep)
{
	print_reg_state(statep);
	cprintf("PC %06lx  SR %04hx  USP %06lx",
			statep->pc, statep->sr, statep->usp  );
	if (statep->frame == 0x0FFF)
		cprintf("\n");	/* invalid frame information, SP's not reliable */
	else {
		cprintf("  SSP %06lx", statep->ssp );
#if CPU>68010		/* 68020 and above */
		cprintf("  ISP %06lx  MSP %06lx", statep->isp, statep->msp );
#endif
		cprintf("\n");
	}
}



