/*
 * DISKBNCH.C - disk speed test for EmuTOS on the Mini-M68k
 *
 * Build on the board with Sozobon C:
 *   cc diskbnch.c -o diskbnch.ttp
 * Run from the root of the drive to test:
 *   diskbnch
 *
 * Measures, with the 200 Hz system timer:
 *   1. raw sector reads through the BIOS (Rwabs): driver speed only
 *   2. writing a 256 KB file through GEMDOS
 *   3. reading it back through GEMDOS
 * The test file DISKBNCH.DAT is deleted at the end.
 */

#include <stdio.h>
#include <osbind.h>

#define BUFSIZE 16384
#define TOTAL   262144L     /* bytes per test */
#define DRIVE   2           /* C: */

static char buf[BUFSIZE];

static long ticks()
{
    long ssp, t;

    ssp = Super(0L);
    t = *(long *)0x4baL;    /* _hz_200 */
    Super(ssp);

    return t;
}

static void report(name, bytes, start, end)
char *name;
long bytes, start, end;
{
    long dt = end - start;

    if (dt <= 0)
        dt = 1;
    printf("%-22s %7ld bytes in %4ld.%02ld s = %4ld KB/s\n", name, bytes,
           dt / 200, (dt % 200) / 2, (bytes * 200L / dt) / 1024L);
}

main()
{
    short *bpb;
    int recsiz, count, rec, fd;
    long done, t0, t1;

    bpb = (short *)Getbpb(DRIVE);
    if (bpb == 0) {
        printf("Getbpb failed\n");
        return 1;
    }
    recsiz = bpb[0];
    count = BUFSIZE / recsiz;
    printf("Logical sector size %d bytes, %d sectors per transfer\n", recsiz, count);

    /* 1. raw sector reads */
    t0 = ticks();
    for (done = 0, rec = 0; done < TOTAL; done += BUFSIZE, rec += count) {
        if (Rwabs(0, buf, count, rec, DRIVE) < 0) {
            printf("Rwabs read error at sector %d\n", rec);
            return 1;
        }
    }
    t1 = ticks();
    report("Raw read (Rwabs):", done, t0, t1);

    /* 2. file write */
    fd = Fcreate("DISKBNCH.DAT", 0);
    if (fd < 0) {
        printf("Fcreate failed: %d\n", fd);
        return 1;
    }
    t0 = ticks();
    for (done = 0; done < TOTAL; done += BUFSIZE) {
        if (Fwrite(fd, (long)BUFSIZE, buf) != BUFSIZE) {
            printf("Fwrite failed\n");
            Fclose(fd);
            return 1;
        }
    }
    Fclose(fd);
    t1 = ticks();
    report("File write (GEMDOS):", done, t0, t1);

    /* 3. file read */
    fd = Fopen("DISKBNCH.DAT", 0);
    if (fd < 0) {
        printf("Fopen failed: %d\n", fd);
        return 1;
    }
    t0 = ticks();
    for (done = 0; done < TOTAL; done += BUFSIZE) {
        if (Fread(fd, (long)BUFSIZE, buf) != BUFSIZE) {
            printf("Fread failed\n");
            Fclose(fd);
            return 1;
        }
    }
    Fclose(fd);
    t1 = ticks();
    report("File read (GEMDOS):", done, t0, t1);

    Fdelete("DISKBNCH.DAT");
    return 0;
}
