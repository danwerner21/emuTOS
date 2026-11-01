/*
 * ym_mini68k.c - YM2149 sound chip emulated on the VERA's PSG
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The Mini-M68k has no YM2149. Its 16 registers are kept in RAM instead,
 * written and read by sound.c (Giaccess, Dosound, the bell and the key
 * click), and every 5 ms the timer interrupt plays them on the VERA's
 * PSG: YM channels A-C on VERA voices 0-2 as square waves, and the YM's
 * noise on voice 3, at the loudest volume of the channels mixing it in.
 * The envelope generator is emulated at the same 200 Hz.
 *
 * Not reproduced: envelopes fast enough to be heard as a tone (buzzer
 * sounds), and samples played by changing the volume quickly; both need
 * updates far more often than 200 times a second.
 *
 * The PSG registers are in VRAM, behind the same ports the screen
 * drivers use. Instead of waiting for them (a large blit holds them for
 * a while), the interrupt saves both VERA address registers and the
 * control register, writes the PSG, and puts them back. Writing an
 * address makes the VERA fetch that byte again, so an interrupted read
 * still gets the right data.
 */

#include "emutos.h"
#include "asm.h"                /* set_sr() */
#include "intmath.h"            /* divu() */
#include "mini68k.h"
#include "vera.h"

#ifdef MACHINE_MINI68K

#define VERA_PSG        0x1f9c0L    /* 16 voices of 4 bytes */
#define PSG_BYTES       16          /* voices 0-3 */

/* YM tone period p at 2 MHz is 125000 / p Hz, and the VERA frequency
 * word is Hz * 2^17 / 48828.125: together, 335544 / p */
#define FREQ_FACTOR     335544UL
#define MIN_PERIOD      6           /* shorter: above 20 kHz, and too big a word */

/* An envelope ramp has 32 steps and lasts 256 * period / 2 MHz, so a
 * 5 ms tick advances it 1250 / period steps: 320000 / period in 1/256 */
#define ENV_FACTOR      320000UL
#define ENV_STEPS       (32 * 256)

/* Valid bits of each YM register */
static const UBYTE reg_mask[16] = {
    0xff, 0x0f, 0xff, 0x0f, 0xff, 0x0f, 0x1f, 0xff,
    0x1f, 0x1f, 0x1f, 0xff, 0xff, 0x0f, 0xff, 0xff
};

static UBYTE ym[16];            /* the YM registers */
static volatile BOOL ym_changed;    /* something to recompute */

/* envelope generator */
static UWORD env_pos;           /* position in the ramp, in 1/256 steps */
static UWORD env_inc;           /* per 5 ms tick */
static BOOL env_attack;         /* rising ramp */
static BOOL env_hold;           /* finished: env_level stays */
static UBYTE env_level;         /* 0-31 */

static UBYTE shown[PSG_BYTES];  /* what the VERA's voices hold */
static BOOL shown_valid;

static void env_restart(void)
{
    env_pos = 0;
    env_attack = (ym[13] & 0x04) != 0;
    env_hold = FALSE;
    env_level = env_attack ? 0 : 31;
}

static void env_set_period(void)
{
    UWORD period = (ym[12] << 8) | ym[11];

    if (period < 5)
        env_inc = 31 * 256;     /* audio-rate envelope: one ramp a tick */
    else
        env_inc = divu(ENV_FACTOR, period);
}

void mini68k_ym_init(void)
{
    WORD old_sr = set_sr(0x2700);
    UWORD i;

    for (i = 0; i < 16; i++)
        ym[i] = 0;
    ym[7] = 0x3f;               /* no tone, no noise */
    env_set_period();
    env_restart();
    shown_valid = FALSE;        /* silence the voices at the next tick */
    ym_changed = TRUE;
    set_sr(old_sr);
}

/* Called with interrupts masked, or from the timer interrupt */
void mini68k_ym_write(UBYTE reg, UBYTE value)
{
    reg &= 0x0f;
    ym[reg] = value & reg_mask[reg];
    if (reg == 11 || reg == 12)
        env_set_period();
    else if (reg == 13)
        env_restart();          /* any write restarts the envelope */
    ym_changed = TRUE;
}

UBYTE mini68k_ym_read(UBYTE reg)
{
    return ym[reg & 0x0f];
}

/* One 5 ms step of the envelope */
static void env_step(void)
{
    UBYTE shape = ym[13];

    if (env_hold)
        return;

    env_pos += env_inc;
    if (env_pos >= ENV_STEPS)   /* end of a ramp */
    {
        if (!(shape & 0x08))    /* shapes 0-7: drop to 0 and stay */
        {
            env_hold = TRUE;
            env_level = 0;
            return;
        }
        if (shape & 0x01)       /* hold at the end of the first ramp */
        {
            env_hold = TRUE;
            env_level = (((shape >> 2) ^ (shape >> 1)) & 1) ? 31 : 0;
            return;
        }
        if (shape & 0x02)       /* alternate */
            env_attack = !env_attack;
        env_pos -= ENV_STEPS;
    }
    env_level = env_attack ? (env_pos >> 8) : 31 - (env_pos >> 8);
}

/*
 * YM level (0-31, the envelope's scale; a fixed volume v is level
 * 2v + 1) to VERA volume. YM levels are about 1.5 dB apart, and VERA
 * volume steps are taken to be about 0.5 dB, so 3 VERA steps a level.
 */
static UBYTE vera_volume(UBYTE level)
{
    WORD v = 63 - 3 * (31 - level);

    return (level == 0 || v < 0) ? 0 : v;
}

static UWORD freq_word(UWORD period)
{
    return (period < MIN_PERIOD) ? 0 : divu(FREQ_FACTOR, period);
}

/* Build the 4 voices from the YM registers */
static void build_voices(UBYTE *v)
{
    UBYTE noise_vol = 0;
    UWORD ch, word;

    for (ch = 0; ch < 3; ch++, v += 4)
    {
        UBYTE amp = ym[8 + ch];
        UBYTE level = (amp & 0x10) ? env_level : (amp & 0x0f) ? 2 * (amp & 0x0f) + 1 : 0;
        UBYTE vol = vera_volume(level);

        word = freq_word((ym[2 * ch + 1] << 8) | ym[2 * ch]);
        v[0] = LOBYTE(word);
        v[1] = HIBYTE(word);
        v[2] = 0xc0 | ((ym[7] & (1 << ch)) ? 0 : vol);  /* both sides */
        v[3] = 0x3f;                                    /* pulse, 50% */
        if (!(ym[7] & (8 << ch)) && vol > noise_vol)
            noise_vol = vol;
    }

    word = ym[6] ? freq_word(ym[6]) : 0;
    if (word == 0)
        word = 0xffff;          /* fastest noise */
    v[0] = LOBYTE(word);
    v[1] = HIBYTE(word);
    v[2] = 0xc0 | noise_vol;
    v[3] = 0xc0 | 0x3f;         /* noise */
}

/* Write the voices, leaving the VERA's address and control registers
 * as the interrupted code had them */
static void write_voices(const UBYTE *v)
{
    UBYTE ctrl, a0l, a0m, a0h, a1l, a1m, a1h;
    UWORD i;

    ctrl = VERA_REG(VERA_CTRL);
    VERA_REG(VERA_CTRL) = 0;
    a0l = VERA_REG(VERA_ADDR_L);
    a0m = VERA_REG(VERA_ADDR_M);
    a0h = VERA_REG(VERA_ADDR_H);
    VERA_REG(VERA_CTRL) = 1;
    a1l = VERA_REG(VERA_ADDR_L);
    a1m = VERA_REG(VERA_ADDR_M);
    a1h = VERA_REG(VERA_ADDR_H);

    VERA_REG(VERA_ADDR_L) = LOBYTE(VERA_PSG);
    VERA_REG(VERA_ADDR_M) = HIBYTE(VERA_PSG);
    VERA_REG(VERA_ADDR_H) = ((VERA_PSG >> 16) & 1) | VERA_INC1;
    for (i = 0; i < PSG_BYTES; i++)
        VERA_REG(VERA_DATA1) = v[i];

    VERA_REG(VERA_ADDR_L) = a1l;
    VERA_REG(VERA_ADDR_M) = a1m;
    VERA_REG(VERA_ADDR_H) = a1h;
    VERA_REG(VERA_CTRL) = 0;
    VERA_REG(VERA_ADDR_L) = a0l;
    VERA_REG(VERA_ADDR_M) = a0m;
    VERA_REG(VERA_ADDR_H) = a0h;    /* fetches DATA0 again */
    VERA_REG(VERA_CTRL) = ctrl;
}

/* From the 200 Hz timer interrupt, after the Dosound step */
void mini68k_ym_tick(void)
{
    UBYTE v[PSG_BYTES];
    BOOL env_used, same;
    UWORD i;

    if (!mini68k_vera_present())
        return;

    env_used = ((ym[8] | ym[9] | ym[10]) & 0x10) && !env_hold;
    if (env_used)
        env_step();
    if (!ym_changed && !env_used)
        return;
    ym_changed = FALSE;

    build_voices(v);
    same = shown_valid;
    for (i = 0; i < PSG_BYTES && same; i++)
        same = (v[i] == shown[i]);
    if (same)
        return;

    write_voices(v);
    for (i = 0; i < PSG_BYTES; i++)
        shown[i] = v[i];
    shown_valid = TRUE;
}

#endif /* MACHINE_MINI68K */
