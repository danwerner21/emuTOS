/*
 * FORMAT.C - format a floppy disk under EmuTOS (Mini-M68k or any TOS)
 *
 * Build on the board with Sozobon C:
 *   cc format.c -o format.ttp
 * Usage:
 *   format a:         1.44 MB (80 tracks, 2 sides, 18 sectors)
 *   format a: dd      720 KB  (80 tracks, 2 sides, 9 sectors)
 *
 * Uses only standard XBIOS calls: Flopfmt() for each track, Protobt()
 * to build the boot sector, and Flopwr() to write the boot sector and
 * empty FATs and root directory. The result is a standard TOS FAT12 disk.
 */

#include <stdio.h>
#include <osbind.h>

#define TRACKS      80
#define SIDES       2
#define MAGIC       0x87654321L
#define VIRGIN      0xe5e5      /* data written into every new sector */

#define TYPE_DD     3           /* Protobt() type: 720 KB */
#define TYPE_HD     4           /* Protobt() type: 1.44 MB */

static char buf[16384];         /* Flopfmt() work buffer */
static char sector[512];

/* write one logical sector, numbered from 0 */
static int write_sector(dev, lsec, spt, data)
int dev, lsec, spt;
char *data;
{
    int track = lsec / (spt * SIDES);
    int side = (lsec / spt) % SIDES;
    int sec = lsec % spt + 1;

    return (int)Flopwr(data, 0L, dev, sec, track, side, 1);
}

static int word_at(p)
char *p;
{
    return (p[0] & 0xff) | ((p[1] & 0xff) << 8);
}

main(argc, argv)
int argc;
char *argv[];
{
    int dev, spt, type, track, side, i, res, nfats, spf, rootsecs, lsec;
    long rc;
    char answer[8];

    if (argc < 2 || argv[1][1] != ':') {
        printf("usage: format a: [dd]\n");
        return 1;
    }
    dev = (argv[1][0] | 0x20) - 'a';
    if (dev < 0 || dev > 1) {
        printf("format: only floppy drives A: and B:\n");
        return 1;
    }
    if (argc > 2 && (argv[2][0] | 0x20) == 'd') {
        spt = 9;
        type = TYPE_DD;
    } else {
        spt = 18;
        type = TYPE_HD;
    }

    printf("Format %c: as %s? All data will be lost (y/n) ", 'A' + dev,
           type == TYPE_HD ? "1.44 MB" : "720 KB");
    fgets(answer, sizeof answer, stdin);
    if ((answer[0] | 0x20) != 'y')
        return 1;

    /* low-level format, with verify */
    for (track = 0; track < TRACKS; track++) {
        for (side = 0; side < SIDES; side++) {
            printf("\rTrack %2d side %d", track, side);
            fflush(stdout);
            rc = Flopfmt(buf, 0L, dev, spt, track, side, 1, MAGIC, VIRGIN);
            if (rc != 0) {
                printf("\nFormat error %ld on track %d side %d\n", rc, track, side);
                if (rc == -16) {    /* bad sectors: Flopfmt() lists them */
                    int *bad = (int *)buf;
                    printf("Bad sectors:");
                    while (*bad)
                        printf(" %d", *bad++);
                    printf("\n");
                }
                return 1;
            }
        }
    }
    printf("\n");

    /* boot sector */
    for (i = 0; i < 512; i++)
        sector[i] = 0;
    sector[0] = 0xeb;   /* x86 jump, so that PCs accept the disk too */
    sector[1] = 0x34;
    sector[2] = 0x90;
    Protobt(sector, 0x01000000L, type, 0);  /* random serial, not executable */
    if (write_sector(dev, 0, spt, sector) != 0) {
        printf("Error writing the boot sector\n");
        return 1;
    }

    /* empty FATs and root directory, using the layout Protobt() chose */
    res = word_at(sector + 14);
    nfats = sector[16] & 0xff;
    spf = word_at(sector + 22);
    rootsecs = (word_at(sector + 17) * 32 + 511) / 512;

    for (i = 0; i < 512; i++)
        sector[i] = 0;
    for (lsec = res; lsec < res + nfats * spf + rootsecs; lsec++) {
        if (write_sector(dev, lsec, spt, sector) != 0) {
            printf("Error writing sector %d\n", lsec);
            return 1;
        }
    }

    /* first FAT entries: media byte, then 0xff */
    sector[0] = (type == TYPE_HD) ? 0xf0 : 0xf9;
    sector[1] = 0xff;
    sector[2] = 0xff;
    for (i = 0; i < nfats; i++) {
        if (write_sector(dev, res + i * spf, spt, sector) != 0) {
            printf("Error writing FAT %d\n", i + 1);
            return 1;
        }
    }

    printf("Done.\n");
    return 0;
}
