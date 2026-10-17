# Mini-M68k BIOS: OS Porting Guide

This guide is for anyone bringing up an operating system, monitor or other standalone program on the **Mini-M68k** CPU board (MC68008 PLCC-52) running **BIOS 10.2**. It covers the hardware memory map, the parts of RAM the BIOS owns, the boot sequence, how the BIOS hands control to your code, and the full `TRAP #8` BIOS API with C and assembler examples.

Everything here comes from the BIOS source in [bios/bios-10.2](bios/bios-10.2), the CP/M-68K port in [bios/cpm68e](bios/cpm68e) and the schematic in [hardware/sbc](hardware/sbc). Where the source and the old release notes disagree, the source wins, and the guide says so.

---

## Contents

1. [Quick reference](#1-quick-reference)
2. [Hardware summary](#2-hardware-summary)
3. [Memory map](#3-memory-map)
4. [Protected and reserved memory](#4-protected-and-reserved-memory)
5. [Boot process](#5-boot-process)
6. [Loading and starting your program](#6-loading-and-starting-your-program)
7. [BIOS calling convention](#7-bios-calling-convention)
8. [BIOS function reference](#8-bios-function-reference)
9. [Example: assembler](#9-example-assembler)
10. [Example: C](#10-example-c)
11. [Interrupts and exceptions](#11-interrupts-and-exceptions)
12. [I/O devices (for direct access)](#12-io-devices-for-direct-access)
13. [Case study: how CP/M-68K is layered on the BIOS](#13-case-study-how-cpm-68k-is-layered-on-the-bios)
14. [Porting checklist](#14-porting-checklist)
15. [Known quirks and gotchas](#15-known-quirks-and-gotchas)
16. [Source file index](#16-source-file-index)

---

## 1. Quick reference

| Item | Value |
|---|---|
| CPU | MC68008, 52-pin PLCC, 22 address lines (4 MB address space), 8-bit data bus |
| RAM | Up to 2 MB SRAM (4 × 512K), `0x000000`–`0x1FFFFF` |
| ROM | `0xFFF80000` (= `0x380000`), 448K visible |
| I/O | `0xFFFF0000`–`0xFFFFFFFF` (= `0x3F0000`), **supervisor only** |
| BIOS entry | `TRAP #8`, function number in **D0** |
| Success / error | Carry clear / carry set on return (N and V follow C) |
| Lowest load address | `0x1000` |
| BIOS-owned RAM | `0x000000`–`0x000FFF` (vectors, BIOS data, BIOS heap) |
| Console | 16550-family UART on the MF/PIC board, ECB port `0x48` |
| Default baud | 9600 until changed in Setup |
| Timer tick | ≈ 18.96 Hz (NS32202 counter, IR3, vector 19) |
| Device interrupt level | IPL 2, vectored by the NS32202 (vectors 16–23) |

---

## 2. Hardware summary

| Function | Part | Location |
|---|---|---|
| CPU | MC68008FN (PLCC-52) | CPU board U29 |
| RAM | 4 × AS6C4008 512K SRAM | CPU board U16, U18, U19, U20 |
| ROM | 29F040 / 27C040 (128K–512K) | CPU board U15 |
| Address decode | 74LS138 on A19/A20/A21 | CPU board U25 |
| Boot ROM overlay | 74LS164 shift register | CPU board U27 |
| Serial console | 16C550/16C750 | MF/PIC board, ECB port 0x48 |
| Interrupt controller and timer | NS32202 ICU | MF/PIC board, ECB port 0x40 |
| Real-time clock and NVRAM | DS1302 | MF/PIC board, ECB port 0x43 |
| Parallel port / PPIDE | 82C55 | MF/PIC board, ECB port 0x44 |
| Mass storage (optional) | PPIDE, Dual-IDE, DiskIO, Dual-SD, floppy | ECB bus |

**The MF/PIC board is required** and must be jumpered to base port **0x40**. The BIOS hard-codes that address ([mfpic.s](bios/bios-10.2/mfpic.s)).

The 68008 only decodes A0–A21, so every address is mirrored every 4 MB. The BIOS uses the sign-extended `0xFFFxxxxx` form for ROM and I/O. This lets you reach I/O with absolute **short** addressing: `move.b (0x8048).w,%d0` reads `0xFFFF8048`.

---

## 3. Memory map

### 3.1 Physical decode

The decoder is the 74LS138 (U25) driven by A19, A20 and A21 (see [select.kicad_sch](hardware/sbc/select.kicad_sch), sheet 8 of [mini-m68k-v2-sch.pdf](hardware/sbc/mini-m68k-v2-sch.pdf)).

| 22-bit address | As seen by software | Size | Selected by | Contents |
|---|---|---|---|---|
| `0x000000`–`0x07FFFF` | same | 512K | `/CSRAM0` (U16) | RAM bank 0 |
| `0x080000`–`0x0FFFFF` | same | 512K | `/CSRAM1` (U18) | RAM bank 1 |
| `0x100000`–`0x17FFFF` | same | 512K | `/CSRAM2` (U19) | RAM bank 2 |
| `0x180000`–`0x1FFFFF` | same | 512K | `/CSRAM3` (U20) | RAM bank 3 |
| `0x200000`–`0x2FFFFF` | same | 1 MB | `MREQ` to ECB bus | External ECB memory (e.g. 4MEM board) |
| `0x300000`–`0x37FFFF` | same | 512K | `MREQ` to ECB bus, **only if J4 is closed** | External ECB memory |
| `0x380000`–`0x3EFFFF` | `0xFFF80000`–`0xFFFEFFFF` | 448K | `/ROM` | ROM |
| `0x3F0000`–`0x3FFFFF` | `0xFFFF0000`–`0xFFFFFFFF` | 64K | `IORQ` (supervisor only) | ECB I/O space |

There is no bus-error timeout. An access to an unpopulated address completes normally and returns garbage. The BIOS sizes RAM by pattern testing, not by catching bus errors.

### 3.2 ROM layout

| Address | Contents |
|---|---|
| `0xFFF80000` | Reset SSP (`0x00070000`) and reset PC (`_start`), then the copyright string and the BIOS code |
| `0xFFF80000 + BIOSSIZE` | ROM disk image (CP/M drive `F:`), whose first file is `CPM.SYS` |

`BIOSSIZE` is **48K** for the retail build (`make RETAIL=1`) and **64K** for the debug build ([makefile](bios/bios-10.2/makefile)). The 512K ROM image is the BIOS followed by the 400K ROM disk (`rom400.bin`). The 128K image is the BIOS followed by the 80K ROM disk (`rom80.bin`). The BIOS stores the ROM-disk offset at RAM location `0x00000000` so that CP/M can find it (see §4.3).

In a 512K part, the top 64K of the ROM lies under the I/O window and can't be read.

### 3.3 RAM layout after boot

```
0x000000 ┌──────────────────────────────┐
         │ Exception vectors 0–63       │  copied from ROM by the BIOS
0x000100 ├──────────────────────────────┤
         │ BIOS .data + .bss            │  0x100 … _end (0xBB8 in shipped map)
         │ BIOS heap (malloc, grows up) │  _end … (disk/floppy descriptors)
0x001000 ├──────────────────────────────┤  ← LOADPOINT: lowest address for programs
         │                              │
         │ Free for the OS / program    │
         │                              │
         │   (BIOS command-processor    │  see §4.4: the monitor's own stack
         │    stack lives in here)      │  is at 0x70000 or 0xC000
         │                              │
h_m_a-0x1000 ├────────────────────────── ┤  initial USP for loaded programs
         │ 4K                           │
h_m_a    ├──────────────────────────────┤  initial SSP for loaded programs
         │ (memory taken by hma_alloc)  │
top RAM  └──────────────────────────────┘  e.g. 0x200000 with 2 MB fitted
```

`h_m_a` ("highest memory address", exclusive) starts at the top of the RAM that `size_ram` finds. It only moves down when someone calls BIOS function 8 (`hma_alloc`).

---

## 4. Protected and reserved memory

### 4.1 Hardware protection

The board has two hardware protection features, both based on the CPU's **FC2** pin (supervisor/user):

| Protection | What it does | Jumper |
|---|---|---|
| **I/O is supervisor-only** | `/IOSPACE` is gated by `SUPV/USER`. A user-mode access to `0xFFFF0000`+ never selects an I/O device. | J9 joins FC2 to `SUPV/USER`. With J9 open, `SUPV/USER` is pulled high, so everything counts as supervisor and **neither protection works**. |
| **Low-memory write protection** | User-mode **writes** to the bottom of bank 0 are blocked (`/USERLOWMEM` gates `/WR`). They can optionally raise **BERR**. Reads are allowed. | J7 and J8 select the size (1K, 4K or 64K). J10 routes the violation to `/BERR`. See [memory.kicad_sch](hardware/sbc/memory.kicad_sch), sheet 5 of the PDF, for the exact jumper settings. |

Configured for 4K, the hardware protects exactly the region the BIOS owns (`0x0000`–`0x0FFF`). If J10 is fitted, a user-mode program that writes below that limit gets a **bus error exception (vector 2)**. Supervisor code is never restricted.

These protections only apply to user mode. An OS running in supervisor mode, which is the normal case, has to protect BIOS memory itself.

### 4.2 Software-reserved RAM (do not overwrite while you use the BIOS)

| Range | Owner | Why it matters |
|---|---|---|
| `0x000000`–`0x000003` | Reset SSP, overwritten by `main68` with `BIOSSIZE` | CP/M reads the ROM-disk offset from here. A hardware RESET also loads SSP from here (see §5.3). |
| `0x000004`–`0x000007` | Reset PC (`_start` in ROM) | **Keep this pointing at the ROM `_start`**, or the RESET button won't restart the BIOS. Only power-on maps ROM to address 0. |
| `0x000008`–`0x00003F` | CPU exception vectors 2–15 | The BIOS fills these with handlers that dump the registers. You can replace them. |
| `0x000040`–`0x00005F` | **Vectors 16–23: NS32202 interrupt vectors** | Vector 19 (`0x4C`) is the BIOS **timer tick**. `BIOS day_time` and the floppy motor timeout depend on it. See §11. |
| `0x000060`–`0x00007F` | Vectors 24–31 (spurious, autovectors 1–7) | Level 7 (NMI, `0x7C`) is wired to the ECB `/NMI` line. |
| `0x000080`–`0x0000BF` | Vectors 32–47 (`TRAP #0`–`#15`) | **`TRAP #8` at `0x0A0` is the BIOS entry. Never overwrite it.** The others are free (CP/M uses #2 and #3). |
| `0x0000C0`–`0x0000FF` | Vectors 48–63 | Free (the BIOS installs a halt handler). |
| `0x000100`–`0x000FFF` | BIOS `.data`, `.bss`, heap | Disk tables, UART type, NVRAM copy, timer counters (`julian_day`, `timer_ticks`), FatFs state. **Overwriting this breaks every BIOS call.** It also means **vectors 64–255 are not available**: their slots overlap BIOS data. |

The BIOS only puts vectors 0–63 in RAM. Don't program any device to deliver vectors ≥ 64.

### 4.3 Location 0

At boot the BIOS copies the ROM's reset SSP (`0x00070000`) and reset PC to RAM `0x0` and `0x4`. Then `main68()` overwrites `0x0` with `BIOSSIZE * 1024` (`0xC000` for retail, `0x10000` for debug):

```c
/* main68.c */
i = 0;
*(long*)i = BIOSSIZE * 1024;	/* tell CPM where the ROM is */
```

So once the BIOS prompt appears, `*(long*)0` is the offset from `0xFFF80000` to the ROM disk.

### 4.4 Stack used by the BIOS itself

The BIOS never sets up its own stack after reset. The command processor (the `C>` prompt) runs on whatever SSP the CPU loaded at reset:

| How the board started | SSP during the BIOS prompt |
|---|---|
| Power-on | `0x00070000` (from the ROM's reset vector) |
| RESET button | Whatever is at RAM `0x0`, which is normally `BIOSSIZE` (`0xC000` retail) |

**When the BIOS loads a program, the program's image must not overlap the region just below that stack.** Otherwise the loader overwrites its own stack in the middle of the load. After control passes to your program, the BIOS stack no longer matters.

---

## 5. Boot process

### 5.1 Hardware: the boot ROM overlay

At **power-on**, `/POClear` clears the 74LS164 (U27), which asserts `/ROMONLY`. While `/ROMONLY` is asserted, the decoder selects **ROM for every address**. U27 is clocked by `/AS` and releases `/ROMONLY` after **8 bus cycles**. That is exactly the 8 byte-wide reads the 68008 needs to fetch its 4-byte reset SSP and 4-byte reset PC from "address 0". After that, RAM appears at 0 and the CPU is running from ROM at `_start`.

The **RESET button** does not trigger the overlay (it isn't a power-on clear). On a button reset the 68008 fetches SSP and PC from **RAM** locations 0 and 4, so those must hold sensible values (see §4.2).

### 5.2 Firmware sequence (`_start` in [startup.s](bios/bios-10.2/startup.s))

1. `SR ← 0x2700` (supervisor mode, interrupts masked).
2. **Find the UART** at `0xFFFF8048` ([uart.s](bios/bios-10.2/uart.s)). If it's missing, the supervisor/user LED **blinks 4 times** and the BIOS carries on without a console.
3. **Test the lowest 32K of RAM.** If it fails, the BIOS prints *"Memory failure between 0..32767; the system is stopped."* and halts.
4. Clear the BIOS `.bss`. Set up the heap (`mem_chain = _end`).
5. **Read the NVRAM** (DS1302) and initialise the UART at the saved baud rate (9600 if the NVRAM is unset).
6. Print the welcome banner.
7. **Size RAM** (`size_ram`, in steps of 1/16 of 2 MB = 128K). Store the result in `h_m_a`.
8. **RESET-during-clear check.** If the `reset_code` flag in RAM shows the previous boot was interrupted by RESET during the memory clear, the BIOS runs the full memory diagnostic (`DRAM_tests` in [memtest3.s](bios/bios-10.2/memtest3.s)). That diagnostic loops until the next reset.
9. **Install the exception vectors** 0–63 into RAM.
10. **Clear RAM** from `_end` up to `h_m_a`. *Press RESET during this step to request the full memory test.*
11. Initialise the NS32202 (timer on IR3, vector base 16). **Enable interrupts** (`SR` IPL ← 0).
12. Read one character from the console. If it's `s`, run the **Setup** menu ([setup.c](bios/bios-10.2/setup.c)): baud rate, boot disks, IDE boards, floppies, auto-boot timeout.
13. `configure()`: build the disk table from the NVRAM settings.
14. `main68()` ([main68.c](bios/bios-10.2/main68.c)):
    * write `BIOSSIZE` to location 0;
    * mount the FAT volumes (lazily);
    * change to the boot disk from the NVRAM (`boot_disk_1`);
    * if auto-boot is enabled and `0:/BOOT.CMD` exists, start an *N*-second countdown (any key cancels it);
    * enter the command prompt.

### 5.3 POST blink codes

| Blinks | Meaning |
|---|---|
| 4 | UART on the MF/PIC board not found (`ERR_UART_NOT_FOUND`). Check the board is installed, jumpered to port 0x40, and has a working 16550. |
| 5, 6, 7 | SRAM tests. These are only built for the 68030 KISS board and never appear on the Mini. |

The `README.txt` lists 5 blinks as the UART error. The source (`startup.s`) uses **4**.

---

## 6. Loading and starting your program

### 6.1 The BIOS command processor

The prompt shows the current FAT directory. The first character shows the mode the next program will run in:

```
-C>     next program runs in USER mode (default)
+C>     next program runs in SUPERVISOR mode
```

| Command | Purpose |
|---|---|
| `help` | List the built-in commands |
| `dir` / `ls [vol:]` | List a directory |
| `cd <dir>` | Change directory |
| `C:` (any drive) | Change drive |
| `supv` / `s` | Switch to supervisor mode. Used as a prefix (`s myos`), it applies to one command only. |
| `user` / `u` | Switch to user mode (prefix or command) |
| `cpm` | Boot CP/M-68K from the ROM disk (always supervisor) |
| `dump <addr> <count>` / `dm` | Hex-dump memory |
| `writemem <addr> [byte …]` / `wm` | Write bytes to memory |
| `execute <addr> [u\|s]` | Jump to an address that's already in memory |
| `today` | Print the date and time |
| `rem` | Comment (for use in `.CMD` files) |
| `<file> [args]` | Load and run a file (see below) |

**An OS normally needs supervisor mode.** Start it with `s myos`, or put `supv` in `BOOT.CMD` before the program name.

### 6.2 Executable formats

A bare filename is tried with the extensions `.CMD`, `.ELF`, `.OUT`, `.68K` and `.SYS`, in that order. The BIOS identifies the format from the first bytes of the file, not from the extension:

| Magic bytes | Format | Loader rules |
|---|---|---|
| `7F 45 4C 46` | **ELF32** big-endian, `EM_68K`, `ET_EXEC`, static | Loads each `PT_LOAD` at `p_paddr` and zero-fills the BSS. A segment at `p_paddr == 0` has its first `0x1000` bytes skipped, so it can't overwrite the vectors or BIOS data. Rejects dynamic executables and ones that need an interpreter. Starts at `e_entry`. |
| `01 50` | **COFF** (GCC a.out/COFF, magic `0x0150`) | Up to 8 sections. Every section with file data must load at ≥ `0x1000`. Starts at `entry_point`. |
| `60 1A` | **CP/M-68K `.68K` / `.SYS`** (contiguous, non-relocatable) | 28-byte header (`struct hdr` in [cout.h](bios/bios-10.2/cout.h)). Text and data load contiguously at **`ch_entry`**, which must be ≥ `0x1000`. **Text + data + bss must end below `0x100000` (1 MB).** May make BIOS calls only, not CP/M calls. |
| printable text | **Command file** (`.CMD`) | Each line is run as a command. Lines starting with `#` are comments. Nesting is limited to 4 levels. |
| anything else | **Flat binary** | `file <hexaddr>` loads it at that address **without running it**. Run it with `execute <addr>`. |

The `.68K` header layout:

```c
struct hdr {                /* 28 bytes, packed, big-endian */
    uint16 ch_magic;        /* 0x601A ("bra .+0x1C") */
    uint32 ch_tsize;        /* text size */
    uint32 ch_dsize;        /* data size */
    uint32 ch_bsize;        /* bss size */
    uint32 ch_ssize;        /* symbol table size */
    uint32 ch_stksize;      /* stack size */
    uint32 ch_entry;        /* load and entry address */
    uint16 ch_rlbflg;       /* relocation bits suppressed */
};
```

### 6.3 Auto-boot

If Setup has a non-zero auto-boot timeout and `0:/BOOT.CMD` exists on the first FAT volume, the BIOS runs `BOOT.CMD` after the timeout. This is the usual way to boot an OS without anyone at the console. Example `BOOT.CMD`:

```
# boot my OS in supervisor mode
supv
myos.elf root=/dev/hda2
```

### 6.4 CPU state on entry to your program

`_run_us_mode()` ([startup.s](bios/bios-10.2/startup.s)) starts every loaded program by building an exception frame and executing `RTE`:

| Register | Value on entry |
|---|---|
| PC | Entry point from the file header |
| SR | `0x2000` (supervisor) or `0x0000` (user). **IPL = 0, so interrupts are enabled.** CCR = 0. |
| SSP | `h_m_a` (top of available RAM) |
| USP | `h_m_a − 0x1000` |
| D0–D7, A0–A6 | All zero |

No arguments are passed in registers or on the stack, and there's no environment block. (For ELF files the BIOS builds a Linux `bootinfo` record only when it detects a Linux kernel, and that path is only used on the 68030 KISS board.)

The CPU starts with interrupts **enabled** and the BIOS timer running. If your OS isn't ready for interrupts, its first instruction should be `move.w #0x2700,%sr` (supervisor only).

### 6.5 Returning to the BIOS

You can't. The BIOS doesn't keep a return frame. Any of these ends the session:

* BIOS function **7** (`cpustop`) prints `Exit code = 0xNN`, then `BIOSystem shutdown.`, and executes `STOP #0x2701`;
* an undefined BIOS function number;
* an exception that lands on `exception_trap`.

After that, only the RESET button gets you back to the BIOS.

---

## 7. BIOS calling convention

### 7.1 Mechanism

The BIOS is called through a **software trap**. Nothing is called directly, and nothing is passed on the stack:

```
D0.b       ← function number
D1, D2, D3 ← integer arguments (see the function table)
A0         ← pointer argument
TRAP #8
           → carry clear: success
           → carry set:   error (N and V are also set)
           → results in D0 and/or D1
```

`TRAP #8` vectors through RAM location `0x0A0` to `bios_trap_entry` ([bios8.s](bios/bios-10.2/bios8.s)):

```asm
bios_trap_entry:
	move.l	%a6,-(%sp)		/* save A6 */
	ext.w	%d0			/* extend byte to word < 128 */
	cmp.w	#bios_vector_lth/4,%d0	/* in range? */
	jbcc	undefined
	lsl.l	#2,%d0			/* multiply by 4 */
	move.l	bios_vector_00(%d0.w,%pc),%a6
	jmp	(%a6)			/* vector to service routine */
```

Handlers exit through `bios_good_return`, which clears N, V and C in the stacked SR, or `bios_error_return`, which sets them. Both then `RTE`, so **the condition codes your code sees after the `TRAP` are the status**.

### 7.2 Rules

| Rule | Details |
|---|---|
| Function number | Only **D0.b** is used, and it's sign-extended. Load it with `move.l #n,%d0` to be safe. |
| Valid numbers | 0–31 are in the table. **An undefined number does not return an error**: it prints `Undefined BIOS call` with D0, D1, D2 and A0, then halts the system. |
| Caller mode | User or supervisor. `TRAP` always enters supervisor mode, so user programs can do I/O through the BIOS even though they can't touch I/O space directly. |
| Stack | The BIOS runs on the **caller's supervisor stack** (SSP). Keep at least ~512 bytes free on the SSP; the disk drivers are C code. |
| Register preservation | Only **A6** is explicitly saved by the dispatcher. Treat **D0, D1, A0, A1** and any register that returns a result as **clobbered**. The disk path also saves and restores D1/A0/A1/A5, and the C drivers follow the GCC m68k ABI (they preserve D2–D7 and A2–A6). Saving D2 and D3 yourself, as the CP/M glue does, is safest. |
| Interrupts | The BIOS doesn't change the interrupt mask. Calls are not re-entrant: don't call the BIOS from an interrupt handler that might have interrupted another BIOS call. |
| Re-entrancy | None. The BIOS is single-threaded. In a multitasking OS, wrap all BIOS calls in a single lock or mask interrupts around them. |

---

## 8. BIOS function reference

Function numbers are defined in [biostrap.s](bios/bios-10.2/biostrap.s). Include that file from assembler; it also defines `BIOS = 8`.

### 8.1 Summary

| D0 | Symbol | Inputs | Outputs | Error |
|---|---|---|---|---|
| 0, 1 | — | — | — | *undefined: halts* |
| 2 | `sioput` | D1.b = character | — | never |
| 3 | `siostr` | A0 = string, D1.b = terminator | D0 = characters sent | never |
| 4 | `sioget` | — | D1 = character (waits), D0 = 0 | never |
| 5 | `siotst` | — | D0 = characters waiting (0 or 1) | never |
| 6 | `cpuhma` | — | D0 = `h_m_a` | never (*obsolete; use 8 with D1 = 0*) |
| 7 | `cpustop` | D1 = exit code | does not return | — |
| 8 | `hma_alloc` | D1 = bytes to allocate | D0 = new `h_m_a` | C set if the result would be negative |
| 10 | `disk_reset` | D1 = disk # | D0 = 0 if OK | C set, D0 ≠ 0 |
| 11 | `disk_info` | D1 = disk #, A0 → 512-byte buffer | buffer = drive ID data | C set, D0 ≠ 0 |
| 12 | `disk_read` | D1 = disk #, D2 = LBA, D3 = sector count, A0 → buffer | D0 = 0 if OK | C set, D0 ≠ 0 |
| 13 | `disk_write` | same as `disk_read` | D0 = 0 if OK | C set, D0 ≠ 0 |
| 14 | `disk_verify` | D1 = disk #, D2 = LBA, D3 = sector count | D0 = 0 if OK | C set, D0 ≠ 0 |
| 15 | `disk_format` | D1 = disk #, A0 → interleave/track info | D0 = 0 if OK | floppies only |
| 20 | `day_time` | D1 = format (0–3) | D0 = date, D1 = time | never |
| 9, 16–19, 21–31 | — | — | — | *undefined: halts* |

### 8.2 Console

The console is polled, with no buffering or interrupts. `siotst` only reports whether the UART's *Data Ready* bit is set, so the most it ever returns is **1**.

**2: `sioput`.** Wait for the transmitter holding register to empty, then send **D1.b**. No newline translation: send `"\r\n"` yourself.

**3: `siostr`.** Send bytes starting at **A0** until a byte equal to **D1.b** (usually `0`). The terminator isn't sent. Returns the number of bytes sent in **D0**.

**4: `sioget`.** Wait until a character arrives. Returns it in **D1** (zero-extended) with **D0 = 0**. There's no echo.

**5: `siotst`.** Returns **D0 = 0** if no character is waiting, **1** if one is. Doesn't consume the character.

### 8.3 Memory

**6: `cpuhma`.** *Obsolete.* Returns `h_m_a` in D0.

**7: `cpustop`.** Prints the exit code from **D1** and stops the CPU. Never returns.

**8: `hma_alloc`.** Takes **D1** bytes from the top of free RAM:

```
D0 = (h_m_a & ~3) - D1, rounded down to a multiple of 4
if D0 < 0 → error (C set), h_m_a unchanged
else      → h_m_a = D0, return D0
```

* With **D1 = 0** it just returns the current top of free memory.
* It **doesn't check** whether the memory is in use (it can't know where your program lives). Call it early.
* An OS that takes over all memory management can call it once with D1 = 0 to learn the RAM size, and then ignore it.

### 8.4 Disk

All disk calls go through a second dispatcher, `bios_disk` ([dualide.s](bios/bios-10.2/dualide.s)). It looks up the per-drive driver from the table that `configure()` built from the NVRAM.

**Disk numbers:**

| D1 | Device |
|---|---|
| 0, 1 | Floppy A, B (WD37C65/8272 on a Dual-IDE board, if configured) |
| 2–7 | Hard-disk units C–H, in the order of the IDE boards configured in Setup (PPIDE, Dual-IDE, DiskIO, Dual-SD; two units per board) |

**Sectors are 512 bytes**, addressed by **LBA** (D2), starting at 0.

**Errors returned by the dispatcher itself** (before any driver runs):

| D0 | Meaning |
|---|---|
| 1 | Disk number out of range (≥ 8) |
| 2 | No device configured for that number |
| 3 | The driver doesn't implement this function |

**Driver errors** come from [error.s](bios/bios-10.2/error.s):

| D0 | Symbol | Meaning |
|---|---|---|
| 65 | `ERR_UNKNOWN` | Unknown call |
| 66 | `ERR_UNIT_NO` | Bad unit number |
| 67 | `ERR_METHOD` | Bad method number |
| 68 | `ERR_ADDRESS` | Address out of range |
| 70 | `ERR_CAPACITY` | LBA beyond the end of the disk |
| 71 | `ERR_NO_MEDIA` | No media in the socket |
| 72 | `ERR_WRONG_MEDIA` | Not SDSC/SDHC |
| 73 | `ERR_WRITE_PROT` | Write protected |
| 133 | `ERR_DISK_IO` | Disk I/O error |
| 134 | `ERR_TIMEOUT` | Timeout |
| 135 | `ERR_CRC16` | CRC error on read |

**10: `disk_reset`.** Resets the device (this may reset the whole controller).

**11: `disk_info`.** Fills the 512-byte buffer at **A0** with the drive's IDENTIFY data, or the equivalent for SD.

**12 / 13: `disk_read` / `disk_write`.** Transfer **D3** sectors starting at LBA **D2**, to or from the buffer at **A0**. The buffer needs room for `D3 × 512` bytes. Word alignment is recommended.

**14: `disk_verify`.** Verify **D3** sectors starting at LBA **D2** without transferring data.

**15: `disk_format`.** Floppies only. A0 points to the interleave/track description.

### 8.5 Date and time

**20: `day_time`.** The time comes from the BIOS's timer-interrupt counters, which are set from the DS1302 at boot. **D1** selects the format:

| D1 | D0 (date) | D1 (time) |
|---|---|---|
| 0 | Julian day number | Timer ticks since midnight (≈ 18.96 Hz; 25 × 65536 ticks per day) |
| 1 | Days since 31 Dec 1900 (1 Jan 1901 = 1) | Seconds since midnight |
| 2 | bits 31–16 year, 15–12 month, 11–4 day, 3–0 day of week | `0x00HHMMSS`, binary, 24-hour |
| 3 | BCD `CC YY MM DD` | BCD `00 hh mm ss` |

The time only advances while interrupts are enabled and vector 19 still points at the BIOS timer handler (§11).

---

## 9. Example: assembler

GNU `as` syntax (`m68k-elf-as -m68000`), as used by the BIOS sources. Include [biostrap.s](bios/bios-10.2/biostrap.s) for the symbols.

### 9.1 Hello world, wait for a key, exit

```asm
	.include "biostrap.s"		/* BIOS = 8, sioput = 2, ... */

	.text
	.globl	start
start:
	lea	hello(%pc),%a0		/* A0 = string */
	clr.l	%d1			/* D1 = terminator (NUL) */
	move.l	#siostr,%d0
	trap	#BIOS			/* D0 = number of chars sent */

	move.l	#sioget,%d0		/* wait for a key */
	trap	#BIOS			/* D1 = character */

	move.l	#sioput,%d0		/* echo it */
	trap	#BIOS

	moveq	#0,%d1			/* exit code 0 */
	move.l	#cpustop,%d0
	trap	#BIOS			/* never returns */

hello:	.asciz	"Hello from the Mini-M68k!\r\n"
```

### 9.2 Read one sector, with error handling

```asm
/* int read_sector(int disk, long lba, void *buf)  -- C callable */
	.globl	read_sector
read_sector:
	link	%a6,#0
	movem.l	%d2-%d3,-(%sp)		/* we load D2/D3, so save them */
	move.l	8(%a6),%d1		/* D1 = disk number */
	move.l	12(%a6),%d2		/* D2 = LBA */
	moveq	#1,%d3			/* D3 = sector count */
	move.l	16(%a6),%a0		/* A0 = buffer (512 bytes) */
	move.l	#disk_read,%d0
	trap	#BIOS
	bcs.s	1f			/* carry set → D0 holds the error code */
	moveq	#0,%d0			/* success */
1:	movem.l	(%sp)+,%d2-%d3
	unlk	%a6
	rts
```

### 9.3 Non-blocking keyboard poll

```asm
poll_key:			/* returns D0 = char, or -1 if none */
	move.l	#siotst,%d0
	trap	#BIOS
	tst.l	%d0
	beq.s	1f
	move.l	#sioget,%d0
	trap	#BIOS
	move.l	%d1,%d0
	rts
1:	moveq	#-1,%d0
	rts
```

### 9.4 Reserve memory at the top of RAM

```asm
	move.l	#64*1024,%d1		/* want 64K */
	move.l	#hma_alloc,%d0
	trap	#BIOS
	bcs	no_memory
	move.l	%d0,%a2			/* A2 = base of the 64K block */
```

---

## 10. Example: C

The BIOS and CP/M were built with `m68k-elf-gcc` 4.1.1 using `-m68000 -nostdlib -Os`. Any m68k GCC that can target the 68000 will do.

### 10.1 Option A: inline-assembly wrappers (recommended)

These need no extra object files. The register variables pin each argument to the register the BIOS expects.

```c
/* bios.h -- Mini-M68k BIOS wrappers for GCC */
#ifndef BIOS_H
#define BIOS_H

#define BIOS_SIOPUT     2
#define BIOS_SIOSTR     3
#define BIOS_SIOGET     4
#define BIOS_SIOTST     5
#define BIOS_CPUSTOP    7
#define BIOS_HMA_ALLOC  8
#define BIOS_DISK_RESET 10
#define BIOS_DISK_INFO  11
#define BIOS_DISK_READ  12
#define BIOS_DISK_WRITE 13
#define BIOS_DISK_VERIFY 14
#define BIOS_DAY_TIME   20

static inline void bios_putc(int c)
{
    register long d0 __asm__("d0") = BIOS_SIOPUT;
    register long d1 __asm__("d1") = c & 0xFF;
    __asm__ volatile ("trap #8"
                      : "+d"(d0), "+d"(d1)
                      :
                      : "a0", "a1", "cc", "memory");
}

static inline int bios_getc(void)          /* blocks */
{
    register long d0 __asm__("d0") = BIOS_SIOGET;
    register long d1 __asm__("d1");
    __asm__ volatile ("trap #8"
                      : "+d"(d0), "=d"(d1)
                      :
                      : "a0", "a1", "cc", "memory");
    return (int)(d1 & 0xFF);
}

static inline int bios_kbhit(void)         /* 0 = nothing waiting */
{
    register long d0 __asm__("d0") = BIOS_SIOTST;
    __asm__ volatile ("trap #8"
                      : "+d"(d0)
                      :
                      : "d1", "a0", "a1", "cc", "memory");
    return (int)d0;
}

static inline long bios_puts(const char *s)   /* NUL-terminated */
{
    register long d0 __asm__("d0") = BIOS_SIOSTR;
    register long d1 __asm__("d1") = 0;        /* terminator */
    register const char *a0 __asm__("a0") = s;
    __asm__ volatile ("trap #8"
                      : "+d"(d0), "+d"(d1), "+a"(a0)
                      :
                      : "a1", "cc", "memory");
    return d0;                                 /* chars sent */
}

/* Returns 0 on success, otherwise a BIOS error code. */
static inline long bios_disk_rw(int fn, int disk, unsigned long lba,
                                int count, void *buf)
{
    register long d0 __asm__("d0") = fn;   /* BIOS_DISK_READ or _WRITE */
    register long d1 __asm__("d1") = disk;
    register long d2 __asm__("d2") = lba;
    register long d3 __asm__("d3") = count;
    register void *a0 __asm__("a0") = buf;
    __asm__ volatile ("trap #8"
                      : "+d"(d0), "+d"(d1), "+d"(d2), "+d"(d3), "+a"(a0)
                      :
                      : "a1", "cc", "memory");
    return d0;
}
#define bios_disk_read(d, lba, n, b)  bios_disk_rw(BIOS_DISK_READ,  d, lba, n, b)
#define bios_disk_write(d, lba, n, b) bios_disk_rw(BIOS_DISK_WRITE, d, lba, n, b)

/* Allocate bytes from the top of RAM; returns new top, or <0 on failure.
   bios_hma_alloc(0) returns the current top of free memory. */
static inline long bios_hma_alloc(unsigned long bytes)
{
    register long d0 __asm__("d0") = BIOS_HMA_ALLOC;
    register long d1 __asm__("d1") = bytes;
    __asm__ volatile ("trap #8"
                      : "+d"(d0), "+d"(d1)
                      :
                      : "a0", "a1", "cc", "memory");
    return d0;
}

/* fmt: 0..3 as described in the BIOS guide; date/time out-params */
static inline void bios_day_time(int fmt, unsigned long *date,
                                 unsigned long *time)
{
    register long d0 __asm__("d0") = BIOS_DAY_TIME;
    register long d1 __asm__("d1") = fmt;
    __asm__ volatile ("trap #8"
                      : "+d"(d0), "+d"(d1)
                      :
                      : "a0", "a1", "cc", "memory");
    *date = d0;
    *time = d1;
}

static inline void bios_exit(int code) __attribute__((noreturn));
static inline void bios_exit(int code)
{
    register long d0 __asm__("d0") = BIOS_CPUSTOP;
    register long d1 __asm__("d1") = code;
    __asm__ volatile ("trap #8" : : "d"(d0), "d"(d1));
    for (;;) ;
}

#endif /* BIOS_H */
```

Using them:

```c
#include "bios.h"

static unsigned char sector[512];

int main(void)
{
    unsigned long date, time;
    long err;

    bios_puts("Mini-M68k OS loader\r\n");

    bios_day_time(2, &date, &time);
    /* date: yyyy:16 mm:4 dd:8 dow:4   time: 0:hh:mm:ss */

    err = bios_disk_read(2, 0, 1, sector);     /* disk 2 = C:, LBA 0 */
    if (err) {
        bios_puts("disk read failed\r\n");
        bios_exit(1);
    }
    if (sector[510] == 0x55 && sector[511] == 0xAA)
        bios_puts("MBR found\r\n");

    bios_exit(0);
}
```

### 10.2 Option B: the generic `bios_call()` helper

The BIOS sources include a generic wrapper, [bioscall.s](bios/bios-10.2/bioscall.s) and [bioscall.h](bios/bios-10.2/bioscall.h). It loads D0–D7 and A0–A5 from a struct, executes `TRAP #8`, and stores every register plus the condition codes in a second struct:

```c
typedef struct REGS {
    unsigned int D0,D1,D2,D3,D4,D5,D6,D7;
    void        *A0,*A1,*A2,*A3,*A4,*A5;
    unsigned unused : 27;
    unsigned X : 1;     /* not valid */
    unsigned N : 1;
    unsigned Z : 1;
    unsigned V : 1;
    unsigned C : 1;     /* 1 = error */
} T_regs;

int bios_call(struct REGS *in, struct REGS *out);
```

```c
#include "bioscall.h"

long read_sector(int disk, unsigned long lba, void *buf)
{
    T_regs in = {0}, out;
    in.D0 = 12;          /* disk_read */
    in.D1 = disk;
    in.D2 = lba;
    in.D3 = 1;
    in.A0 = buf;
    bios_call(&in, &out);
    return out.C ? (long)out.D0 : 0;
}
```

Link `bioscall.o` (built with `--defsym CPU=68000`) into your program.

### 10.3 Minimal C runtime (crt0)

Based on [crt0.s](bios/bios-10.2/crt0.s), which the BIOS tools use for standalone programs:

```asm
	.include "biostrap.s"
	.text
	.globl	begin
begin:				/* link with --entry begin */
	pea	0.l		/* envp */
	pea	0.l		/* argv */
	pea	1.l		/* argc */
	jsr	main
	move.l	%d0,%d1		/* exit code */
	move.l	#cpustop,%d0
	trap	#BIOS		/* never returns */
```

### 10.4 Build commands

```sh
m68k-elf-gcc -m68000 -Os -nostdlib -ffreestanding -c myos.c
m68k-elf-as  -m68000 --defsym CPU=68000 -o crt0.o crt0.s
m68k-elf-ld  -Ttext 0x1000 --entry begin -o myos.elf crt0.o myos.o -lgcc
```

Copy `myos.elf` to the FAT partition and start it from the BIOS prompt with `s myos`.

`-Ttext 0x1000` puts the program at the lowest legal address. If you need a CP/M-style `.68K` file, keep the whole image below 1 MB (§6.2).

---

## 11. Interrupts and exceptions

### 11.1 Interrupt wiring

| Source | CPU level | Vectoring | Vector # | Address |
|---|---|---|---|---|
| ECB `/INT` (from the NS32202 on the MF/PIC) | **2** | Vector number supplied by the NS32202 | **16 + IRn** | `0x40 + 4·n` |
| ECB `/NMI` | **7** | Autovector (VPA) | 31 | `0x7C` |

The BIOS programs the NS32202 with a **vector base of 16** (`svct = 16`, `mf_cfg = 16` in [ns202.c](bios/bios-10.2/ns202.c)). Its 8 interrupt inputs therefore map to vectors 16–23:

| IR | Vector | Address | BIOS use |
|---|---|---|---|
| 0, 1, 2 | 16, 17, 18 | `0x40`, `0x44`, `0x48` | `spurious_return` |
| **3** | **19** | **`0x4C`** | **`interrupt_3_timer`: the system tick** |
| 4, 5, 6, 7 | 20–23 | `0x50`–`0x5C` | `spurious_return` |

### 11.2 The BIOS timer

* The NS32202 counter is clocked at 1.8432 MHz and produces about **18.96 interrupts per second** (25 × 65536 per day).
* `interrupt_3_timer` ([pic202.s](bios/bios-10.2/pic202.s)) increments `timer_ticks`, rolls over `julian_day` at midnight, and counts down the floppy motor `timeout`.
* **Every interrupt handler must send End-Of-Interrupt to the NS32202** by reading the EOI register:

```asm
	move.b	(0xFFFFA040).l,%d0	/* mf_202 + eoi*256  (eoi = 32) */
	rte
```

NS32202 registers are spaced **256 bytes apart**: register *r* is at `0xFFFF8040 + r*256`. The ICU's register-select lines are wired to A8 and up.

### 11.3 Taking over the interrupt system

You have three choices:

1. **Keep the BIOS timer.** Leave vector 19 alone and install your own handlers on the other IRs.
2. **Chain to it.** Install your own tick handler on vector 19 and jump to the original address (read it from `0x4C` before you overwrite it). The BIOS handler finishes with the EOI read and `RTE`.
3. **Replace it completely.** Then `day_time` stops advancing and floppy motor-off timing stops working. Everything else (console, IDE/SD) is polled and keeps working.

### 11.4 Exceptions

| Vectors | BIOS handler | Behaviour |
|---|---|---|
| 2, 3 (bus/address error) | `exception_AB` | Prints the vector number, registers and stack, then halts |
| 4–15 | `exception` | Prints the vector number and registers, then halts |
| 24–31, `TRAP` 0–7 and 9–15, 48–63 | `exception_trap` | **Halts silently** (`STOP #0x2701`) |

Install your own handlers for anything your OS uses before you enable it. In particular: `TRAP` vectors, *Privilege violation* (8) if you run user code, and *Bus error* (2) if J10 is fitted.

---

## 12. I/O devices (for direct access)

I/O is only reachable in supervisor mode. ECB port *p* is at **`0xFFFF8000 + p`**. That's how the BIOS addresses it: `BOARD_BASE_IO = 0xFFFF8000` in [mfpic.s](bios/bios-10.2/mfpic.s).

| Port | Address | Device | Notes |
|---|---|---|---|
| 0x40 | `0xFFFF8040` | NS32202 ICU | Register *r* at `0xFFFF8040 + r·0x100` ([ns202def.s](bios/bios-10.2/ns202def.s)) |
| 0x42 | `0xFFFF8042` | MF/PIC config | Interrupt vector base for 68000 mode (16) |
| 0x43 | `0xFFFF8043` | DS1302 RTC/NVRAM | Bit-banged ([ds1302.s](bios/bios-10.2/ds1302.s)) |
| 0x44–0x47 | `0xFFFF8044` | 82C55 PPI | Port A/B/C/control. Also the PPIDE interface. |
| 0x48–0x4F | `0xFFFF8048` | 16550 UART | Standard 16550 register layout: `THR/RBR` +0, `IER` +1, `IIR/FCR` +2, `LCR` +3, `MCR` +4, `LSR` +5, `MSR` +6, `SCR` +7 |
| other | `0xFFFF8000 + p` | Dual-IDE, DiskIO, Dual-SD, etc. | Port set by the board's jumpers and recorded in the NVRAM |

You don't have to use the BIOS for the console. Polled UART output looks like this:

```asm
UART	=	0xFFFF8048
putc:	btst	#5,(UART+5).l		/* LSR.THRE */
	beq.s	putc
	move.b	%d0,(UART).l
	rts
```

The UART interrupt line isn't routed to an NS32202 input by the BIOS. If you want interrupt-driven serial I/O, check the MF/PIC wiring ([hardware/mfpic](hardware/mfpic)) and program the ICU yourself.

---

## 13. Case study: how CP/M-68K is layered on the BIOS

CP/M-68K, in [bios/cpm68e](bios/cpm68e), is a complete working port and the best reference.

```
 user program ──TRAP #2──▶ BDOS (bdos*.c)
                              │
                              └──TRAP #3──▶ CP/M "CBIOS" (n8bios3.s, n8io.c)
                                                │
                                                └──TRAP #8──▶ ROM BIOS (this guide)
```

1. The BIOS `cpm` command finds `CPM.SYS` at `0xFFF80000 + BIOSSIZE` (ROM disk), checks that its `.68K` header loads between `0x1000` and `0x100000`, copies it, and starts it in **supervisor** mode.
2. [n8bios3.s](bios/cpm68e/n8bios3.s) installs the CP/M BIOS on **`TRAP #3`** (`move.l #bios3_trap_entry,(32+3)*4`). It leaves `TRAP #8` and the timer vector alone.
3. Console functions are forwarded to BIOS 2, 4 and 5.
4. Disk I/O: [n8io.c](bios/cpm68e/n8io.c) handles CP/M's 128-byte logical sectors, the DPBs, partition handling and an LRU buffer cache. It calls the small assembler stubs in [n8iox.s](bios/cpm68e/n8iox.s), which call BIOS 10–13:

```asm
_read_sector:
	link	%a6,#0
	movem.l	%d2-%d3,-(%sp)
	move.l	8(%a6),%d1	/* drive */
	move.l	12(%a6),%d2	/* lba */
	move.l	#1,%d3		/* sector count = 1 */
	move.l	16(%a6),%a0	/* memory address */
	move.l	#disk_read,%d0	/* function code */
	trap	#bios
	movem.l	(%sp)+,%d2-%d3
	unlk	%a6
	rts
```

5. Memory: CP/M calls `hma_alloc` (`_get_hma` / `_halloc` in `n8iox.s`) to find the top of the TPA and to reserve buffer space.
6. The ROM-disk offset is read from location `0x00000000` (§4.3).

---

## 14. Porting checklist

**Build and link**
- [ ] Target `-m68000` (no 68010+ instructions: no `MOVEC`, no `RTD`, no VBR).
- [ ] Link at ≥ `0x1000`. For `.68K` format, keep the whole image below `0x100000`.
- [ ] Make sure the image doesn't overlap the BIOS command-processor stack while it's being loaded (§4.4).
- [ ] Produce ELF, COFF or `.68K` so the BIOS can load it from FAT, or put it in ROM after the BIOS.

**Start-up**
- [ ] Start it in **supervisor** mode (`s myos`, or `supv` in `BOOT.CMD`).
- [ ] Remember that the CPU arrives with **interrupts enabled**, SSP = `h_m_a`, USP = `h_m_a − 0x1000`, and all registers zero.
- [ ] Set up your own stacks. Leave room on the SSP for BIOS calls.
- [ ] Call `hma_alloc(0)` to find the top of RAM.

**Memory**
- [ ] Leave `0x0000`–`0x0FFF` alone while you use the BIOS (vectors 0–63 and the BIOS data and heap).
- [ ] Keep `TRAP #8` (`0x0A0`) pointing at the BIOS.
- [ ] Keep `0x000004` pointing at the ROM `_start` if you want the RESET button to reboot cleanly.
- [ ] Use only vectors 0–63. Vectors 64+ overlap BIOS data.
- [ ] RAM above `_end` (≈ `0x0BB8`) and below `0x1000` belongs to the BIOS heap. Don't use it.

**Interrupts**
- [ ] Decide how to handle the timer on vector 19 (keep, chain or replace).
- [ ] Every NS32202 interrupt handler reads EOI at `0xFFFFA040` before `RTE`.
- [ ] Install handlers for every vector your OS can trigger.
- [ ] Serialise BIOS calls (it's not re-entrant).

**User mode (if your OS has a user/kernel split)**
- [ ] Jumper J9 so FC2 drives `SUPV/USER`. Otherwise user code can touch I/O and low memory.
- [ ] Set the low-memory protection jumpers (J7/J8) to the size you want, and J10 if you want violations to raise a bus error.
- [ ] Provide a vector 2 handler and a privilege-violation (vector 8) handler.

---

## 15. Known quirks and gotchas

| Issue | Effect | Workaround |
|---|---|---|
| Undefined BIOS function number | Prints a message and **halts**; doesn't return an error | Only use the numbers in §8 |
| Programs start in user mode by default | An OS that touches I/O or executes privileged instructions crashes | Use the `s`/`supv` prefix |
| Interrupts are enabled on entry | Interrupts can arrive before your OS is ready | Make the first instruction `move.w #0x2700,%sr` |
| `siotst` returns at most 1 | There's no input FIFO; characters can be lost while you're busy | Poll often, or drive the UART directly |
| No newline translation | `"\n"` alone doesn't return the carriage | Send `"\r\n"` |
| Location 0 is overwritten | After boot, the RESET-time SSP is `BIOSSIZE` (`0xC000`), not `0x70000` | Be aware of it if you rely on RESET; see §4.4 |
| RESET doesn't re-map ROM to 0 | If your OS corrupts RAM `0x0`–`0x7`, RESET jumps to garbage | Keep those 8 bytes, or power-cycle |
| `size_ram` only checks the top of each 128K step | Doesn't catch bank aliasing (e.g. a bad A19/A20 decode) | Run the full RAM test (press RESET during "Testing, sizing, and clearing memory") |
| `README.txt` blink codes | Lists 5 blinks for the UART. The code uses **4**. | Trust §5.3 |
| ELF loader comment | Says "interrupts disabled" on entry. `_run_us_mode` actually enables them. | Trust §6.4 |
| BIOS is single-threaded | Re-entering it from an ISR corrupts state | Lock around all BIOS calls |

---

## 16. Source file index

| File | Contents |
|---|---|
| [bios/bios-10.2/startup.s](bios/bios-10.2/startup.s) | Reset entry, POST, RAM sizing, vector setup, `_run_us_mode`, `_exit`, exception handlers |
| [bios/bios-10.2/bios8.s](bios/bios-10.2/bios8.s) | `TRAP #8` dispatcher and function table, `hma_alloc`, `cpustop` |
| [bios/bios-10.2/biostrap.s](bios/bios-10.2/biostrap.s) | **BIOS function numbers** (include this) |
| [bios/bios-10.2/serial.s](bios/bios-10.2/serial.s) | Console functions 2–5 |
| [bios/bios-10.2/dualide.s](bios/bios-10.2/dualide.s) | Disk dispatcher (`bios_disk`) |
| [bios/bios-10.2/ppide.s](bios/bios-10.2/ppide.s), [dualsd.s](bios/bios-10.2/dualsd.s), [floppy.s](bios/bios-10.2/floppy.s) | Disk drivers |
| [bios/bios-10.2/error.s](bios/bios-10.2/error.s) | Error codes |
| [bios/bios-10.2/pic202.s](bios/bios-10.2/pic202.s) | Timer ISR, EOI, `day_time` |
| [bios/bios-10.2/ns202.c](bios/bios-10.2/ns202.c), [ns202def.s](bios/bios-10.2/ns202def.s) | NS32202 setup and register map |
| [bios/bios-10.2/mfpic.s](bios/bios-10.2/mfpic.s) | I/O base addresses |
| [bios/bios-10.2/main68.c](bios/bios-10.2/main68.c) | Command processor and program loaders (ELF, COFF, `.68K`, `.CMD`, flat) |
| [bios/bios-10.2/setup.c](bios/bios-10.2/setup.c) | NVRAM setup menu |
| [bios/bios-10.2/bioscall.s](bios/bios-10.2/bioscall.s), [bioscall.h](bios/bios-10.2/bioscall.h) | Generic C `bios_call()` |
| [bios/bios-10.2/crt0.s](bios/bios-10.2/crt0.s) | Minimal C runtime for standalone programs |
| [bios/bios-10.2/memtest3.s](bios/bios-10.2/memtest3.s) | Full memory diagnostic |
| [bios/bios-10.2/makefile](bios/bios-10.2/makefile) | Build: `make MINI=1 RETAIL=1` |
| [bios/cpm68e/n8bios3.s](bios/cpm68e/n8bios3.s), [n8iox.s](bios/cpm68e/n8iox.s), [n8io.c](bios/cpm68e/n8io.c) | CP/M-68K port: a worked example of an OS on top of this BIOS |
| [hardware/sbc/mini-m68k-v2-sch.pdf](hardware/sbc/mini-m68k-v2-sch.pdf) | CPU board schematic (decode on sheet 8, memory and protection on sheet 5, interrupts on sheet 3) |
