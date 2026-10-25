/*
 * fdc_mini68k.c - Disk I/O V3 floppy driver for the Mini-M68k
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The ECB Disk I/O V3 board carries an SMC FDC9266 (NEC 765 compatible)
 * floppy controller, without DMA or interrupts. The registers and latch
 * bits come from the SBC-386EX driver for the same board (floppy/diskfdc.h):
 *
 *  board + 0x16: main status register (read)
 *  board + 0x17: data register (commands, results, data)
 *  board + 0x18: control latch (74LS273, write only):
 *      bit 0 TC (terminal count, pulsed), bit 1 MOTOR, bit 2 MINI
 *      (1 = 250 kbit/s, 0 = 500 kbit/s), bit 6 DENSEL (to the drive),
 *      bit 7 /RESET (0 = controller held in reset)
 *
 * With the board at 0x20, these are ports 0x36-0x38, as in diskfdc.h.
 * The latch cannot be read back, so a shadow copy is kept.
 *
 * Commands are the standard 765 ones. Everything is polled: seeks are
 * completed with Sense Interrupt Status, and the data phase is in
 * fdc_mini68k2.S. One sector is transferred per command, and each
 * transfer is ended with a TC pulse.
 */

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "asm.h"
#include "biosdefs.h"
#include "delay.h"
#include "disk.h"
#include "gemerror.h"
#include "mini68k.h"
#include "tosvars.h"

#ifdef MACHINE_MINI68K

/* Controller registers, relative to the Disk I/O board base port */
#define FDC_MSR_OFFSET      0x16
#define FDC_LATCH_OFFSET    0x18

/* Latch bits */
#define L_TC        0x01
#define L_MOTOR     0x02
#define L_MINI      0x04    /* 1 = 250 kbit/s (double density) */
#define L_DENSEL    0x40
#define L_NRESET    0x80

/* Main status register bits */
#define MSR_RQM     0x80
#define MSR_DIO     0x40
#define MSR_BUSY    0x10

/* Commands */
#define CMD_SPECIFY         0x03
#define CMD_SENSE_DRIVE     0x04
#define CMD_WRITE_DATA      0x45    /* MFM */
#define CMD_READ_DATA       0x46    /* MFM */
#define CMD_RECALIBRATE     0x07
#define CMD_SENSE_INT       0x08
#define CMD_READ_ID         0x4a    /* MFM */
#define CMD_SEEK            0x0f
#define CMD_FORMAT_TRACK    0x4d    /* MFM */

/* Status bits */
#define ST0_IC_MASK     0xc0    /* interrupt code */
#define ST0_IC_ABNORMAL 0x40
#define ST0_IC_INVALID  0x80
#define ST0_SE          0x20    /* seek end */
#define ST1_EN          0x80    /* end of cylinder */
#define ST1_NW          0x02    /* not writable */
#define ST3_TRACK0      0x10

/* Drive parameters (from the INT 1Eh tables in floppy/40h_flop.asm) */
#define SPEC_SRT_HUT        0xaf    /* step rate & head unload time */
#define SPEC_HLT_ND         0x03    /* head load time 1, non-DMA mode */
#define GPL_HD              0x1b    /* gap length, 1.44 MB */
#define GPL_DD              0x2a    /* gap length, 720 KB */
#define GPL3_HD             0x6c    /* format gap length, 1.44 MB */
#define GPL3_DD             0x50    /* format gap length, 720 KB */

/* Timings */
#define MOTOR_SPINUP_MSEC   500
#define HEAD_SETTLE_MSEC    15
#define MOTOR_OFF_TICKS     100     /* 50 Hz ticks: 2 seconds */
#define SEEK_TIMEOUT        (3*CLOCKS_PER_SEC)
#define CMD_TIMEOUT         (CLOCKS_PER_SEC/2)
#define RESULT_TIMEOUT      CLOCKS_PER_SEC  /* Read ID can search for 2 revolutions */

#define RETRIES             5   /* an interrupt can still cost one sector an overrun */

/* Data phase, in fdc_mini68k2.S: return 0 if all moved, 1 if cut short, 2 on timeout */
WORD fdc_pio_in(volatile UBYTE *msr, UBYTE *buf, UWORD count, WORD windows);
WORD fdc_pio_out(volatile UBYTE *msr, const UBYTE *buf, UWORD count, WORD windows);

/*
 * Interrupt windows (about 1 ms each) while waiting for the first byte.
 * During a format, the next sector ID cannot be requested before the
 * controller has written the gaps and data field of the previous sector:
 * about 678 bytes, 10.8 ms at 500 kbit/s or 20.8 ms at 250 kbit/s.
 * Stopping the windows a few ms before that keeps the timer interrupt
 * away from the moment the ID is wanted.
 */
#define WINDOWS_ALWAYS      1000    /* as long as the wait lasts (1 s) */
#define WINDOWS_FORMAT_HD   7
#define WINDOWS_FORMAT_DD   16

static volatile UBYTE *fdc_msr;     /* NULL if there is no Disk I/O board */
static volatile UBYTE *fdc_data;
static volatile UBYTE *fdc_latch;
static UBYTE latch;                 /* shadow of the write-only latch */
static volatile WORD motor_ticks;   /* 50 Hz ticks until the motor stops */
static WORD cur_track;              /* -1: unknown, recalibrate first */
static BOOL rate_known;             /* data rate determined for this disk */
static UBYTE gpl;                   /* gap length for the current density */
static BOOL formatted;              /* a track was formatted: report a media change */
volatile BOOL mini68k_fdc_active;   /* a transfer is in progress: no screen copying */

/*
 * Latch and motor
 */

static void write_latch(UBYTE set, UBYTE clear)
{
    WORD old_sr = set_sr(0x2700);   /* the motor timeout also writes it */

    latch = (latch | set) & ~clear;
    *fdc_latch = latch;
    set_sr(old_sr);
}

static void delay_msec(UWORD msec)
{
    while (msec--)
        delay_loop(loopcount_1_msec);
}

static void motor_on(void)
{
    BOOL was_on = (latch & L_MOTOR) != 0;

    motor_ticks = MOTOR_OFF_TICKS;  /* (re)start the timeout */
    if (!was_on)
    {
        write_latch(L_MOTOR, 0);
        delay_msec(MOTOR_SPINUP_MSEC);
    }
}

/* Called at 50 Hz from the system timer interrupt */
void mini68k_fdc_motor_tick(void)
{
    if (motor_ticks > 0 && --motor_ticks == 0 && fdc_latch)
    {
        latch &= ~L_MOTOR;
        *fdc_latch = latch;
    }
}

/*
 * Controller command and result phases
 */

static void fdc_reset(void);

/*
 * After a timeout, the controller may be in any state (still executing a
 * command, or holding result bytes nobody read), so it is reset. The
 * guard stops a failing reset sequence from calling itself.
 */
static void fdc_recover(void)
{
    static BOOL resetting;

    if (resetting)
        return;

    resetting = TRUE;
    fdc_reset();
    resetting = FALSE;
}

static int fdc_out(UBYTE value)
{
    LONG end = hz_200 + CMD_TIMEOUT;

    while (hz_200 < end)
    {
        UBYTE msr = *fdc_msr;
        if ((msr & (MSR_RQM | MSR_DIO)) == MSR_RQM)
        {
            *fdc_data = value;
            return 0;
        }
        if ((msr & (MSR_RQM | MSR_DIO)) == (MSR_RQM | MSR_DIO))
            FORCE_READ(*fdc_data);  /* discard a result nobody collected */
    }

    KDEBUG(("fdc_out(0x%02x): timeout, MSR=0x%02x\n", value, *fdc_msr));
    fdc_recover();
    return -1;
}

/* Read the result phase into result[]: return the byte count, or -1 */
static int fdc_result(UBYTE *result, int max)
{
    LONG end = hz_200 + RESULT_TIMEOUT;
    int n = 0;

    while (hz_200 < end)
    {
        UBYTE msr = *fdc_msr;

        if ((msr & (MSR_RQM | MSR_DIO)) == (MSR_RQM | MSR_DIO))
        {
            UBYTE value = *fdc_data;
            if (n < max)
                result[n++] = value;
        }
        else if ((msr & (MSR_RQM | MSR_BUSY)) == MSR_RQM)
            return n;   /* ready for a new command: the result phase is over */
    }

    KDEBUG(("fdc_result(): timeout, MSR=0x%02x\n", *fdc_msr));
    fdc_recover();
    return -1;
}

static int fdc_command(const UBYTE *cmd, int len)
{
    int i;

    for (i = 0; i < len; i++)
        if (fdc_out(cmd[i]))
            return -1;

    return 0;
}

/*
 * Wait for the end of a seek or recalibrate: poll Sense Interrupt Status
 * until it reports something other than "invalid command" (no interrupt
 * pending). Return ST0, or -1 on timeout.
 */
static int fdc_wait_seek(void)
{
    LONG end = hz_200 + SEEK_TIMEOUT;
    UBYTE result[2];

    while (hz_200 < end)
    {
        if (fdc_out(CMD_SENSE_INT))
            return -1;
        if (fdc_result(result, 2) < 1)
            return -1;
        if ((result[0] & ST0_IC_MASK) != ST0_IC_INVALID)
            return result[0];
    }

    return -1;
}

static void fdc_specify(void)
{
    UBYTE cmd[3];

    cmd[0] = CMD_SPECIFY;
    cmd[1] = SPEC_SRT_HUT;
    cmd[2] = SPEC_HLT_ND;
    fdc_command(cmd, 3);
}

static void fdc_reset(void)
{
    int i;
    UBYTE result[2];

    write_latch(0, L_NRESET);       /* hold the controller in reset */
    delay_loop(loopcount_1_msec / 10);
    write_latch(L_NRESET, 0);
    delay_msec(1);

    /* after a reset, each of the 4 drives reports a status change */
    for (i = 0; i < 4; i++)
    {
        if (fdc_out(CMD_SENSE_INT))
            break;
        fdc_result(result, 2);
    }

    fdc_specify();
    cur_track = -1;
}

/* Recalibrate drive 0. An 80-track drive may need two tries,
 * because the controller gives up after 77 steps. */
static int fdc_recalibrate(void)
{
    UBYTE cmd[2];
    int tries, st0;

    for (tries = 0; tries < 2; tries++)
    {
        cmd[0] = CMD_RECALIBRATE;
        cmd[1] = 0;     /* drive 0 */
        if (fdc_command(cmd, 2))
            return -1;
        st0 = fdc_wait_seek();
        if (st0 >= 0 && (st0 & (ST0_IC_MASK | ST0_SE)) == ST0_SE)
        {
            cur_track = 0;
            return 0;
        }
    }

    cur_track = -1;
    return -1;
}

static int fdc_seek(WORD track, WORD side)
{
    UBYTE cmd[3];
    int st0;

    if (cur_track < 0 && fdc_recalibrate())
        return -1;
    if (track == cur_track)
        return 0;

    cmd[0] = CMD_SEEK;
    cmd[1] = (side << 2);   /* drive 0 */
    cmd[2] = track;
    if (fdc_command(cmd, 3))
        return -1;
    st0 = fdc_wait_seek();
    if (st0 < 0 || (st0 & ST0_IC_MASK) != 0)
    {
        cur_track = -1;
        return -1;
    }

    cur_track = track;
    delay_msec(HEAD_SETTLE_MSEC);
    return 0;
}

/* DENSEL set for high density: checked with 1.44 MB and 720 KB disks */
static void set_rate(BOOL high_density)
{
    if (high_density)
    {
        write_latch(L_DENSEL, L_MINI);  /* 500 kbit/s */
        gpl = GPL_HD;
    }
    else
    {
        write_latch(L_MINI, L_DENSEL);  /* 250 kbit/s */
        gpl = GPL_DD;
    }
}

/* Is there a readable track under the head at the current data rate? */
static BOOL fdc_read_id(WORD side)
{
    UBYTE cmd[2], result[7];

    cmd[0] = CMD_READ_ID;
    cmd[1] = (side << 2);
    if (fdc_command(cmd, 2))
        return FALSE;

    return fdc_result(result, 7) == 7 && (result[0] & ST0_IC_MASK) == 0;
}

/* Find the data rate of the disk: high density first, then double */
static int fdc_find_rate(void)
{
    set_rate(TRUE);
    if (fdc_read_id(0))
        return 0;
    set_rate(FALSE);
    if (fdc_read_id(0))
        return 0;
    set_rate(TRUE);
    return -1;
}

/*
 * Transfer one sector. Return 0, or an error code for EmuTOS.
 */
static WORD fdc_rw_sector(UBYTE *buf, WORD rw, WORD track, WORD side, WORD sect)
{
    UBYTE cmd[9], result[7];
    int rc, n;

    cmd[0] = rw ? CMD_WRITE_DATA : CMD_READ_DATA;
    cmd[1] = (side << 2);   /* drive 0 */
    cmd[2] = track;
    cmd[3] = side;
    cmd[4] = sect;
    cmd[5] = 2;             /* 512 bytes */
    cmd[6] = sect;          /* end of track: this sector only */
    cmd[7] = gpl;
    cmd[8] = 0xff;
    if (fdc_command(cmd, 9))
        return rw ? EWRITF : EREADF;

    rc = rw ? fdc_pio_out(fdc_msr, buf, SECTOR_SIZE, WINDOWS_ALWAYS)
            : fdc_pio_in(fdc_msr, buf, SECTOR_SIZE, WINDOWS_ALWAYS);

    /* end the command now: the data has been transferred */
    write_latch(L_TC, 0);
    write_latch(0, L_TC);

    n = fdc_result(result, 7);
    KDEBUG(("fdc_rw_sector(%d,%d,%d,%d): pio=%d ST0=%02x ST1=%02x ST2=%02x\n",
            rw, track, side, sect, rc, result[0], result[1], result[2]));
    if (n < 7)      /* fdc_result() has reset the controller */
        return rw ? EWRITF : EREADF;

    if (rw && (result[1] & ST1_NW))
        return EWRPRO;

    /* success, possibly with "end of cylinder" because of the TC pulse */
    if (rc == 0 && ((result[0] & ST0_IC_MASK) == 0
     || ((result[0] & ST0_IC_MASK) == ST0_IC_ABNORMAL && result[1] == ST1_EN)))
        return 0;

    return rw ? EWRITF : EREADF;
}

/*
 * EmuTOS floppy hooks (see floppy.c)
 */

void mini68k_floppy_init(void)
{
    struct mini68k_board boards[MINI68K_MAX_BOARDS];
    int n, i;

    fdc_msr = NULL;
    n = mini68k_get_disk_boards(boards);
    for (i = 0; i < n; i++)
    {
        if (boards[i].type == MINI68K_BOARD_DISKIO)
        {
            UBYTE port = boards[i].port;

            fdc_msr = (volatile UBYTE *)MINI68K_ECB_IO(port + FDC_MSR_OFFSET);
            fdc_data = fdc_msr + 1;
            fdc_latch = (volatile UBYTE *)MINI68K_ECB_IO(port + FDC_LATCH_OFFSET);
            break;
        }
    }

    if (!fdc_msr)
        return;

    latch = L_NRESET;
    cur_track = -1;
    set_rate(TRUE);
    fdc_reset();
}

/* Only drive 0 (A:) is supported */
BOOL mini68k_flop_detect_drive(WORD dev)
{
    UBYTE cmd[2], result[1];
    BOOL present;

    if (!fdc_msr || dev != 0)
        return FALSE;

    motor_on();
    present = (fdc_recalibrate() == 0);
    if (present)
    {
        cmd[0] = CMD_SENSE_DRIVE;
        cmd[1] = 0;
        present = fdc_command(cmd, 2) == 0 && fdc_result(result, 1) == 1
               && (result[0] & ST3_TRACK0);
    }

    KDEBUG(("mini68k_flop_detect_drive(%d): %s\n", dev, present ? "present" : "absent"));
    return present;
}

WORD mini68k_floprw(UBYTE *buf, WORD rw, WORD dev, WORD sect, WORD track, WORD side, WORD count)
{
    WORD i, err = 0, retry;

    if (!fdc_msr || dev != 0)
        return EUNDEV;

    mini68k_fdc_active = TRUE;
    motor_on();

    for (i = 0; i < count; i++, sect++, buf += SECTOR_SIZE)
    {
        for (retry = 0; retry < RETRIES; retry++)
        {
            if (fdc_seek(track, side))
            {
                err = ESECNF;
                continue;
            }
            if (!rate_known)
            {
                if (fdc_find_rate())
                {
                    err = EREADF;
                    cur_track = -1;
                    continue;
                }
                rate_known = TRUE;
            }
            err = fdc_rw_sector(buf, rw, track, side, sect);
            if (err == 0 || err == EWRPRO)
                break;
            cur_track = -1;     /* recalibrate before retrying */
            rate_known = FALSE;
        }
        if (err)
            break;
        motor_ticks = MOTOR_OFF_TICKS;
    }

    mini68k_fdc_active = FALSE;
    return err;
}

/*
 * Format one track. ids holds the ID of each sector as 4 bytes:
 * cylinder, head, sector number, size code. The controller writes the
 * gaps, address marks and CRCs itself, and fills the data fields with
 * 'fill'. The caller verifies the track afterwards.
 */
WORD mini68k_flopfmt(const UBYTE *ids, WORD dev, WORD track, WORD side,
                     WORD spt, BOOL high_density, UBYTE fill)
{
    UBYTE cmd[6], result[7];
    WORD retry, err = EWRITF;
    int i, rc, n;

    if (!fdc_msr || dev != 0)
        return EUNDEV;

    mini68k_fdc_active = TRUE;
    motor_on();
    set_rate(high_density);
    rate_known = TRUE;

    for (retry = 0; retry < RETRIES; retry++)
    {
        if (fdc_seek(track, side))
            continue;

        cmd[0] = CMD_FORMAT_TRACK;
        cmd[1] = (side << 2);   /* drive 0 */
        cmd[2] = 2;             /* 512 bytes */
        cmd[3] = spt;
        cmd[4] = high_density ? GPL3_HD : GPL3_DD;
        cmd[5] = fill;
        if (fdc_command(cmd, 6))
            continue;   /* fdc_out() has reset the controller */

        /* the controller asks for each sector ID as it reaches it */
        for (i = 0, rc = 0; i < spt && rc == 0; i++)
            rc = fdc_pio_out(fdc_msr, ids + 4 * i, 4,
                             (i == 0) ? WINDOWS_ALWAYS     /* waits for the index hole */
                             : high_density ? WINDOWS_FORMAT_HD : WINDOWS_FORMAT_DD);

        /* the command ends by itself at the index hole */
        n = fdc_result(result, 7);
        KDEBUG(("mini68k_flopfmt(%d,%d): pio=%d ST0=%02x ST1=%02x ST2=%02x\n",
                track, side, rc, result[0], result[1], result[2]));
        if (n < 7)
            continue;   /* fdc_result() has reset the controller */
        if (result[1] & ST1_NW)
        {
            err = EWRPRO;
            break;
        }
        if (rc == 0 && (result[0] & ST0_IC_MASK) == 0)
        {
            formatted = TRUE;
            err = 0;
            break;
        }
        cur_track = -1;     /* recalibrate before retrying */
    }

    motor_ticks = MOTOR_OFF_TICKS;
    mini68k_fdc_active = FALSE;
    return err;
}

/*
 * There is no disk change line, so after the motor has stopped,
 * the disk may have been changed: EmuTOS then compares the boot sector.
 */
LONG mini68k_flop_mediach(WORD dev)
{
    if (formatted)      /* the disk has just been reformatted */
    {
        formatted = FALSE;
        rate_known = FALSE;
        return MEDIACHANGE;
    }

    if (latch & L_MOTOR)
        return MEDIANOCHANGE;

    rate_known = FALSE;
    return MEDIAMAYCHANGE;
}

#endif /* MACHINE_MINI68K */
