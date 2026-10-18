/* daytime.c */

#include "bioscall.h"
int cprintf(char const *fmt, ...);


int main(void)
{
	struct REGS reg;
	int i;

	for (i=0; i<=3; i++) {
		reg.D0 = 20;		/* Date & Time call */
		reg.D1 = i;
		bios_call( &reg, &reg );

		cprintf("\nDate & Time format%d: 	%8x  %8x  ::  %10d  %10d\n",
				i, reg.D0, reg.D1, reg.D0, reg.D1);
	}

	return 0;
}

