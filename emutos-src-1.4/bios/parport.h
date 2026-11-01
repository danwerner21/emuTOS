/*
 * parport.h - limited parallel port support
 *
 * Copyright (C) 2002-2019 The EmuTOS development team
 *
 * Authors:
 *  LVL   Laurent Vogel
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/licence.txt for details.
 */

/* A printer port: the Atari one (PSG and MFP), or the Mini-M68k's LPT */
#if CONF_WITH_PRINTER_PORT || defined(MACHINE_MINI68K)
# define WITH_PRINTER 1
#else
# define WITH_PRINTER 0
#endif

LONG bconin0(void);
LONG bcostat0(void);
LONG bconout0(WORD dev, WORD c);

void parport_init(void);

#if WITH_PRINTER
WORD setprt(WORD config);
#endif
