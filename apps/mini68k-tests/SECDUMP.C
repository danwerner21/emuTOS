/*
 * SECDUMP.C - hex dump of one physical sector, for EmuTOS on the Mini-M68k
 *
 * Build on the board with Sozobon C:
 *   cc secdump.c -o secdump.ttp
 * Usage:
 *   secdump <unit> [sector]
 * Units are EmuTOS physical units, as shown at boot ("unit 18 is managed
 * by ..."): 18 = first IDE drive, 20 = second IDE interface, 26 = SD card.
 * The sector defaults to 0 (the MBR or boot sector).
 *
 * The data is shown as the driver delivers it, after any automatic
 * byte swap, so it should match what a PC shows for the same sector.
 */

#include <stdio.h>
#include <osbind.h>

#define RW_NOMEDIACH    2
#define RW_NOTRANSLATE  8

static unsigned char buf[512];

main(argc, argv)
int argc;
char *argv[];
{
    int unit, sector, i, j;
    long rc;

    if (argc < 2) {
        printf("usage: secdump <unit> [sector]\n");
        return 1;
    }
    unit = atoi(argv[1]);
    sector = (argc > 2) ? atoi(argv[2]) : 0;

    rc = Rwabs(RW_NOTRANSLATE | RW_NOMEDIACH, buf, 1, sector, unit);
    if (rc < 0) {
        printf("Rwabs error %ld reading unit %d sector %d\n", rc, unit, sector);
        return 1;
    }

    for (i = 0; i < 512; i += 16) {
        printf("%03x:", i);
        for (j = 0; j < 16; j++)
            printf(" %02x", buf[i + j] & 0xff);
        printf("  ");
        for (j = 0; j < 16; j++) {
            int c = buf[i + j] & 0xff;
            putchar((c >= 0x20 && c < 0x7f) ? c : '.');
        }
        printf("\n");
    }

    if (sector == 0) {
        printf("\nSignature at 0x1fe: %02x %02x\n", buf[0x1fe] & 0xff, buf[0x1ff] & 0xff);
        for (i = 0; i < 4; i++) {
            unsigned char *e = buf + 0x1be + 16 * i;
            printf("Partition %d: type %02x, start %02x%02x%02x%02x, size %02x%02x%02x%02x\n",
                   i + 1, e[4] & 0xff, e[11] & 0xff, e[10] & 0xff, e[9] & 0xff, e[8] & 0xff,
                   e[15] & 0xff, e[14] & 0xff, e[13] & 0xff, e[12] & 0xff);
        }
    }

    return 0;
}
