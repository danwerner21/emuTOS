/*
 * SETCLOCK.C - show or set the date and time under EmuTOS
 *
 * Build on the board with Sozobon C:
 *   cc setclock.c -o setclock.ttp
 * Usage:
 *   setclock                          show the date and time
 *   setclock 2026-10-17               set the date
 *   setclock 14:30[:00]               set the time
 *   setclock 2026-10-17 14:30[:00]    set both
 * The date may also be written with slashes (2026/10/17).
 *
 * Uses the GEMDOS calls Tsetdate() and Tsettime(). EmuTOS passes the new
 * date and time on to the BIOS, which writes them to the battery-backed
 * clock (the DS1302 on the Mini-M68k), so they survive a power cycle.
 * GEMDOS keeps seconds in steps of 2.
 */

#include <stdio.h>
#include <osbind.h>

/* parse up to 'max' numbers separated by 'sep1' or 'sep2'; return the count */
static int parse(s, sep1, sep2, num, max)
char *s;
int sep1, sep2;
int num[];
int max;
{
    int n = 0;

    while (n < max) {
        if (*s < '0' || *s > '9')
            return -1;
        num[n] = 0;
        while (*s >= '0' && *s <= '9')
            num[n] = num[n] * 10 + (*s++ - '0');
        n++;
        if (*s == '\0')
            return n;
        if (*s != sep1 && *s != sep2)
            return -1;
        s++;
    }

    return -1;      /* too many fields */
}

static int is_date(s)
char *s;
{
    while (*s) {
        if (*s == '-' || *s == '/')
            return 1;
        s++;
    }
    return 0;
}

static void show()
{
    unsigned int d = Tgetdate();
    unsigned int t = Tgettime();

    printf("%04d-%02d-%02d %02d:%02d:%02d\n",
           (d >> 9) + 1980, (d >> 5) & 0x0f, d & 0x1f,
           t >> 11, (t >> 5) & 0x3f, (t & 0x1f) * 2);
}

main(argc, argv)
int argc;
char *argv[];
{
    int i, n, num[3];

    for (i = 1; i < argc; i++) {
        if (argv[i][0] < '0' || argv[i][0] > '9') {
            printf("usage: setclock [YYYY-MM-DD] [HH:MM[:SS]]\n");
            return 1;
        }
        if (is_date(argv[i])) {
            n = parse(argv[i], '-', '/', num, 3);
            if (n != 3 || num[0] < 1980 || num[0] > 2099
             || num[1] < 1 || num[1] > 12 || num[2] < 1 || num[2] > 31) {
                printf("setclock: bad date '%s' (use YYYY-MM-DD)\n", argv[i]);
                return 1;
            }
            if (Tsetdate(((num[0] - 1980) << 9) | (num[1] << 5) | num[2]) != 0) {
                printf("setclock: date '%s' rejected\n", argv[i]);
                return 1;
            }
        } else {
            n = parse(argv[i], ':', ':', num, 3);
            if (n == 2)
                num[2] = 0;
            if (n < 2 || num[0] > 23 || num[1] > 59 || num[2] > 59) {
                printf("setclock: bad time '%s' (use HH:MM[:SS])\n", argv[i]);
                return 1;
            }
            if (Tsettime((num[0] << 11) | (num[1] << 5) | (num[2] / 2)) != 0) {
                printf("setclock: time '%s' rejected\n", argv[i]);
                return 1;
            }
        }
    }

    show();
    return 0;
}
