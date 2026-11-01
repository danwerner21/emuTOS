# Applications for EmuTOS on the Mini-M68k

This folder holds Atari ST software that has been tested with EmuTOS on the RetroBrew Mini-M68k. This file records, for each package, who wrote it, what licence or distribution terms it carries, and where its source can be found.

**This is not legal advice.** The statuses come from each package's own files, from the terms its authors published, and from Rob Gowin's *BITSY Software Distribution* notes (version 0.9.0, December 23, 2025). Several packages here came from that distribution.

## Abandonware, and removal on request

Some packages are commercial software from the 1980s and 1990s whose publishers no longer sell or support them. They are included as **abandonware**, so that the board can run the tools of its era. No permission has been given, and abandonware is not a licence: the copyrights still belong to their owners.

**If you hold the rights to any package here and want it removed, open an issue on this repository ([github.com/danwerner21/emuTOS](https://github.com/danwerner21/emuTOS/issues)) and it will be removed.**

## Summary

| Package | What it is | Author / owner | Terms | Status |
| --- | --- | --- | --- | --- |
| `SOZOBON/` | Sozobon C compiler, with dLibs | Sozobon Ltd (Johann Ruegg, Tony Andrews, Joe Treat); dLibs by Dale Schumacher | Copyrighted, freely distributable | Free to distribute |
| `STEVIE/` | STEVIE 3.10, a vi clone, with source | Tim Thompson, Tony Andrews | Public domain | Free to distribute |
| `qed/` | qed 5.0.5 text editor | Tom Quellenberg; later Christian Felsch, Heiko Achilles; now FreeMiNT | Public domain from 3.09; no fee may be charged | Free to distribute |
| `UTILITIE/BWBASIC3.TTP` | Bywater BASIC 3.40 interpreter | Ted A. Campbell, Jon B. Volkoff, Howard Wulf, Ken Martin, and others | GNU GPL v2 or later | Free to distribute; source linked below |
| `UTILITIE/ST-GUIDE.*` | ST-Guide hypertext viewer | Holger Weets | Freeware | Free to distribute |
| `UTILITIE/uemacs.tos` | uEmacs 4.2.4, a MicroEMACS variant | Daniel M. Lawrence and others | Non-commercial distribution allowed | Free to distribute (non-commercial) |
| `UTILITIE/zmrx.ttp` | ZMODEM receiver | Jacques Mattheij (Mattheij Computer Service, 1994); CP/M and TOS ports by Rob Gowin, with Andrew Lynch | Free non-commercial use and redistribution | Free to distribute (non-commercial); source linked below |
| `BASICEXA.MPL/*.BAS` | BASIC example programs | Various; Super Star Trek by Mike Mayfield and Bob Leedom, from *Creative Computing* | Public domain | Free to distribute |
| Board utilities | `DISKBNCH`, `FORMAT`, `HELLO`, `SECDUMP`, `SETCLOCK`, `VERATEST`, `ZSMPLAY` (in `UTILITIE/`, sources in `mini68k-tests/`) | Dan Werner | MIT licence (`mini68k-tests/LICENSE`) | Free to distribute |
| `PURE_C/` | Pure C 1.1 compiler (patched for this board) | Pure Software / Application Systems Heidelberg; English edition by Gribnif Software | Commercial | Abandonware; removed on request |
| `DEVPAC31/` | Devpac 3.10 assembler | HiSoft | Commercial | Abandonware; removed on request |
| `HBASIC/`, `BASICEXA.MPL/HBASIC.LIB` | HiSoft BASIC 2.10, and its run-time library | HiSoft | Commercial | Abandonware; removed on request |
| `WRDWRITE/` | Word Writer ST 2.0 (UK) | Timeworks | Commercial | Abandonware; removed on request |
| `ALYCON/` | Atari ST developer kit: Alcyon C, linker, assembler, RCS, GEM bindings, samples | Atari Corp.; tools by Alcyon Corp. and Digital Research | Commercial | Abandonware; removed on request |
| `UTILITIE/lines.app`, `clock.app` | Multitasking demo programs | Atari Corp. (from the MultiTOS distribution) | Commercial | Abandonware; removed on request |

## Free and open packages

### SOZOBON — Sozobon C
- **Terms** (`DOC/SOZOBON.DOC`, section 1.1.2): "The programs and code are copyrighted, but may be freely distributed." No charge may be made beyond reasonable reproduction costs, and modified versions must be clearly marked as such.
- **dLibs** (`DOC/README`): Dale Schumacher asks that modified versions not be distributed under the name "dLibs".
- **Attribution:** the documents in `DOC/` are kept with the package.

### STEVIE
- **Terms** (`doc/README`): "a public domain clone of the UNIX editor 'vi'." Source release by Tony Andrews, 1988, after Tim Thompson's original.
- Henry Spencer's regular-expression library, needed to build it, carries its own permissive licence (`doc/README-regexp`).

### qed
- **Terms** (`readme.txt`): "From version 3.09 qed (including sources) will be in the public domain … Yet Tom has prohibited the charge of a fee of whatever kind."
- **History:** Tom Quellenberg (to 3.09), Christian Felsch (3.20–4.53), Heiko Achilles (5.0 on), and part of FreeMiNT since 2002.
- **Source:** the FreeMiNT project, [github.com/freemint](https://github.com/freemint).

### Bywater BASIC
- **Version:** 3.40. The program's start-up text credits Ted A. Campbell (1993), Jon B. Volkoff (1995–1997), Howard Wulf (2014–2017) and Ken Martin (2019).
- **Licence:** GNU General Public License, version 2 or later. A separate commercial licence is offered by the authors for commercial distribution.
- **Source:** the Bywater BASIC project on SourceForge, [sourceforge.net/projects/bwbasic](https://sourceforge.net/projects/bwbasic/files/bwbasic/), where version 3.40 (`bwbasic-3.40.zip`) was released on October 23, 2025. This satisfies the GPL's requirement that the source be available to anyone who receives the program.

### ST-Guide
- **Author:** Holger Weets, Oldenburg (from the program's own text). Distributed as freeware.

### uEmacs
- **Version:** 4.2.4, a variant of MicroEMACS 3.9 by Daniel M. Lawrence and others.
- **Terms:** MicroEMACS may be copied and distributed for non-commercial purposes.

### zmrx
- **Notice in the program:** "(C) Mattheij Computer Service 1994. CP/M port by Rob Gowin with help from Andrew Lynch. TOS port by Rob Gowin."
- **Terms:** Jacques Mattheij's zmtx/zmrx licence allows free use, modification and redistribution for non-commercial purposes, with the archive kept whole and its version numbers intact; commercial licences were available from the author. (Rob Gowin's notes list zmrx as GPL 2. The original package's own terms are the non-commercial ones described here.)
- **Source:** the modernised zmtx/zmrx with the Atari ST and CP/M ports is on Andrew Lynch's GitHub, [github.com/lynchaj](https://github.com/lynchaj).

### BASIC examples (`BASICEXA.MPL/`)
- **Public domain:**
  - `ASCIIART.BAS`, a Mandelbrot demo;
  - `SPRTREK.BAS`, Super Star Trek by Mike Mayfield, modified by Bob Leedom (1978), from *Creative Computing*;
  - `LINES.BAS`, a HiSoft BASIC window demo.
- `HBASIC.LIB` in the same folder belongs to HiSoft BASIC; see below.

### Board utilities
- `DISKBNCH`, `FORMAT`, `HELLO`, `SECDUMP`, `SETCLOCK`, `VERATEST` and `ZSMPLAY`, written for the Mini-M68k by Dan Werner.
- **Licence:** MIT, in [`mini68k-tests/LICENSE`](mini68k-tests/LICENSE). The built copies in `UTILITIE/` are covered by the same licence.
- `ZSMPLAY` plays Commander X16 ZSM music files. No tunes are included; ZSM files can be made with Furnace, or found in the X16 community's collections, each under its own terms.

## Abandonware

These packages are commercial products, included without permission as abandonware. Each will be removed on request from its rights holder (see the top of this file).

### Pure C (`PURE_C/`)
- **Owner:** Pure C 1.1 (1992), by Pure Software, sold by Application Systems Heidelberg. It is a rebranded Borland Turbo C. The English edition's documentation is "Copyright (c) 1992 by Gribnif Software".
- **Modification:** this copy is patched to run on the Mini-M68k (it probed for an FPU card in a way that crashes the board; see the main README). The unmodified files are in `PURE_C/ORIGINAL/`.

### Devpac (`DEVPAC31/`) and HiSoft BASIC (`HBASIC/`)
- **Owner:** HiSoft (Bedford, England). Devpac 3.10 (1993) and HiSoft BASIC 2.10 (1992), both "Copyright © HiSoft 1992, All Rights Reserved".
- **`BASICEXA.MPL/HBASIC.LIB`** is HiSoft BASIC's run-time library, and has the same status.

### Word Writer ST (`WRDWRITE/`)
- **Owner:** Timeworks. Word Writer ST 2.00 UK, "Copyright (c) Timeworks Inc, 1986".

### Atari ST developer kit (`ALYCON/`)
- **What it is:** the early Atari ST development package, six disks in all (`README.DOC`). It includes:
  - the Alcyon C compiler (`CP68`, `C068`, `C168`), the `AS68` assembler, `LINK68` and `RELMOD`;
  - Digital Research's `SID` debugger and the Resource Construction Set (`RCS`);
  - GEM bindings and headers, sample programs (`DOODLE`, the skeleton applications), Kermit (Columbia University), and Atari's technical notes.
- **Owners:** Atari Corp. (the kit and its documentation), Alcyon Corp. (the compiler), and Digital Research (tools), whose rights later passed to Caldera and Lineo.

### lines, clock (`UTILITIE/`)
- **`lines.app` and `clock.app`** are multitasking demos from Atari's original MultiTOS distribution (per Rob Gowin's notes).
