/* tc2.c for MSC 5.1 */
#include <stdlib.h>
#include <stdio.h>
#include "mytypes.h"

#define OSC_DIV 3
#define BAUD_DIV 75
#define BAUD 9600
#define ENC_BAUD 0x07

byte b_cpu, b_speed, b_baud, b_osc;

int encode(dword value, word divisor)
{
	word rem;
	
	if (!value) return -1;
	rem = value % divisor;
	if (rem) return -1;
	value /= divisor;
	rem = 0;
	if (value % 3 == 0) value /= 3, rem = 0x10;
	if (value & (value-1)) return -1;		/* must be a power of 2 */
	while (value>1) value >>= 1, rem++;
	return (int)rem;
}

dword decode(word value, word divisor)
{
	dword ret;

	ret = (1ul << (value & 0x0F)) * divisor;
	if (value & 0x10) ret *= 3;
	return ret;
}


word valid_speed(byte baud, byte osc)
{
	byte phi = osc;
	int diff;

	if (b_speed == 2) ++phi;
	else if (b_speed == 0) --phi;

	if (b_cpu==3) {
		return ((decode(phi, OSC_DIV) * 1000U / decode(baud, BAUD_DIV) / 2) - 2);
	}

	if (baud & 0x10) {
		if (phi & 0x10) baud &= 0xF;
		else return 0;
	}
	phi &= 0xF;
	diff = (int)phi - (int)baud;
	if (diff >= 2) return (diff-1);	/* 1==valid, SSS=0; 2==valid, SSS=1 */

	return 0;
}


void main(int argc, char *argv[])
{
	word enc;
	
	b_speed = 0;		/* 1/2 osc freq */

	if (argc < 3 || argc >4 ) {
		printf("Usage:  tc2  <osc>  <baud>  [<cpu>]\n");
		return;
	}

	b_osc = encode(atol(argv[1]), OSC_DIV);
	b_baud = encode(atol(argv[2]), BAUD_DIV);
	if (argc==4) b_cpu = atoi(argv[3]);
	printf("osc=0x%02X  baud=0x%02X   ", (int)b_osc, (int)b_baud);
	enc = valid_speed(b_baud, b_osc);
	printf("%svalid   %u\n", !enc?"in":"", enc);

}

