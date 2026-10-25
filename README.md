# EmuTOS for the RetroBrew Mini-M68k

This repository is a port of [EmuTOS](https://emutos.sourceforge.io/) 1.4, the free, open-source TOS-compatible operating system, to the [RetroBrew Computers](https://www.retrobrewcomputers.org/) **Mini-M68k**, an MC68008 CPU board for the ECB bus.

EmuTOS boots on the board from a CF card, runs the EmuCON command shell over the serial console, and reads and writes FAT disks on the CF, SD and floppy boards listed below. Text-mode TOS programs run, including the Sozobon C compiler, which builds programs on the board itself.

The GEM desktop needs a display. That comes next, with the VERA video card (see [Plans](#plans)).

## Supported hardware

| Board / device | Chip | ECB ports | Status |
| --- | --- | --- | --- |
| Mini-M68k CPU board | MC68008 (52-pin PLCC), 2 MB SRAM | — | Working |
| MF/PIC: console | 16550-family UART | `0x48`–`0x4F` | Working. Keeps the baud rate set in the BIOS Setup; `Rsconf` can change it |
| MF/PIC: system timer | NS32202 interrupt controller | `0x40` | Working: 200 Hz tick on IR3 |
| MF/PIC: real-time clock | DS1302 | `0x43` | Working: date and time are read at boot and can be set |
| MF/PIC: IDE | 82C55 parallel-port IDE (PPIDE) | `0x44`–`0x47` | Working: about 164 KB/s raw read |
| DiskIO v2/v3: IDE | 82C55 parallel-port IDE | set in BIOS Setup (e.g. `0x20`) | Working |
| DiskIO v3: floppy | SMC FDC9266 (765 compatible), polled | DiskIO port + `0x16` (e.g. `0x36`–`0x38`) | Working: 1.44 MB and 720 KB read, write and format |
| Dual-SD | bit-banged SPI | set in BIOS Setup (e.g. `0x08`) | Socket 0 working. Socket 1 is supported but untested, because of a hardware fault on the test board |
| Dual DMA IDE | — | — | Not supported |

The MF/PIC board is required, at base port `0x40`.

Disk boards are taken from the board list saved in the **BIOS Setup** (BIOS 10.3), so EmuTOS sees the same disks, in the same order, as the BIOS. Changing the board configuration doesn't require a rebuild.

**Disk formats:** EmuTOS reads and writes FAT12 and FAT16 partitions (MBR types `01`, `04`, `06` and `0E`) up to 2 GB. FAT32 and exFAT partitions can't be used. Cards formatted on a PC are recognised automatically.

## Building and booting

You need the `m68k-atari-mint` GCC cross toolchain. From `emutos-src-1.4`:

```sh
make clean
make mini-68k
```

This produces `emutos.elf`, about 137 KB, as a single-language (English) image.

To boot:
1. Copy `emutos.elf` to a FAT partition that the board BIOS can read.
2. At the BIOS prompt, start it in **supervisor mode**:
   ```
   s emutos
   ```
   The `s` is required: without it, the BIOS starts programs in user mode and EmuTOS stops at its first instruction.

To start it with just `emutos`, put a file called `EMUTOS.CMD` next to it containing `s emutos.elf`. The same line in `BOOT.CMD` makes the BIOS auto-boot EmuTOS.

The console uses the baud rate set in the BIOS Setup and expects an ANSI or VT100 terminal. EmuTOS translates the VT52 codes that TOS programs send.

Build options:
- `make mini-68k WITH_AES=1` includes the GEM desktop, which needs the VERA card.
- By default the VDI and the console draw straight into the VERA, in ST low, medium or high, with the mouse pointer as a VERA sprite. `VERA_DIRECT=0` draws into a RAM screen that is copied to the VERA at each vertical blank instead, which also shows programs that write to screen memory themselves.
- `MINI68K_LOAD` and `MINI68K_RAM_TOP` change the load address (default `0x180000`) and the top of RAM (default `0x200000`).

## How it works

- **EmuTOS replaces the board BIOS.** The BIOS keeps its data at `0x000`–`0xFFF`, which overlaps the fixed TOS system variables at `0x400`–`0x800`. So EmuTOS takes over the whole machine and drives every device directly, and the BIOS `TRAP #8` calls are no longer available. Memory locations `0`–`7` are left alone, so the RESET button still returns to the BIOS.
- **It runs from RAM as if it were ROM.** The image is linked at `0x180000` and wrapped in a minimal ELF file, which the BIOS loads from FAT. The 1.5 MB below that is ST-RAM.
- **Screen:** by default the VERA bitmap is the screen (1, 2 or 4 bits per pixel for ST high, medium and low), and the VDI and the console draw into it through the VERA ports, converting to and from Atari bit planes where needed. Drawing code not yet converted runs on a RAM copy of the area it touches, read back from the VERA. The mouse pointer is a VERA sprite. With `VERA_DIRECT=0`, EmuTOS draws into its usual Atari screen in RAM (ST low, medium or high) and each vertical blank copies the changed rows to the VERA, converting Atari bit planes to VERA pixels in the colour modes. Either way, the vertical blank follows the VERA's 60 Hz VSYNC, polled from the 200 Hz timer.
- **Serial input:** the BIOS doesn't route the UART interrupt to the NS32202, so input is polled from the timer interrupt. It keeps up with pasted text.
- **Floppy timing:** at 500 kbit/s the floppy controller needs a byte every 16 µs, which is 128 cycles of the 8 MHz 68008. The data phase is therefore in assembly and runs with interrupts masked, with short interrupt windows while waiting so the clock keeps time. A sector that still collides with the timer interrupt is retried.

## What was added to EmuTOS

All changes are inside `MACHINE_MINI68K` conditionals, so other EmuTOS targets build as before.

New files in `emutos-src-1.4`:

| File | Purpose |
| --- | --- |
| `bios/mini68k.c`, `bios/mini68k.h` | Machine support: UART console, NS32202 timer, DS1302 RTC, the BIOS NVRAM board list, `Rsconf` |
| `bios/mini68k2.S` | Timer interrupt: 200 Hz tick, UART and PS/2 polling, VBL (on VERA VSYNC), floppy motor timeout |
| `bios/ppide.c`, `bios/ppide.h`, `bios/ppide2.S` | 82C55 PPIDE back-end under EmuTOS's IDE driver (MF/PIC and DiskIO); assembly sector transfers |
| `bios/spi_mini68k.c` | Dual-SD SPI back-end for EmuTOS's SD/MMC driver, two sockets |
| `bios/fdc_mini68k.c`, `bios/fdc_mini68k2.S` | DiskIO floppy driver: polled 765 commands, read, write and format; assembly data phase |
| `bios/vera_mini68k.c`, `bios/vera_mini68k2.S`, `bios/vera.h` | VERA card: mode set-up, palette, changed-row copy with colour conversion, VSYNC, mouse sprite |
| `bios/vera_direct.c`, `vdi/vdi_vera.c` | Direct mode (the default): console and VDI drawing into the VERA |
| `bios/kbd_mini68k.c` | PS/2 keyboard and mouse through the VT82C42 on the VERA card |
| `tools/mkelf68k.c` | Host tool that wraps `emutos.img` in an ELF file for the BIOS loader |

Hooks in existing files:
- **Build:** `include/config.h` (machine defaults), `emutos.ld` (link address), `Makefile` (the `mini-68k` target).
- **Drivers:** `bios/ide.c` (register access through the 8255; one interface per board), `bios/sd.c` (two cards), `bios/floppy.c` (machine hooks, verify and format).
- **System:** `bios/clock.c` (RTC), `bios/serport.c` (console UART and `Rsconf`), `bios/delay.c` (delay loops calibrated against the 200 Hz timer), `bios/screen.c` (80-column screen).
- **Machine set-up and debug output:** `bios/kprint.c`, `bios/machine.c` and `bios/mfp.c`.

## Utilities

`mini68k-tests/` holds small programs to compile on the board with Sozobon C, for example `cc setclock.c -o setclock.ttp`:

| Program | Purpose |
| --- | --- |
| `SETCLOCK.C` | Show or set the date and time: `setclock 2026-10-17 14:30`. Written to the DS1302 |
| `FORMAT.C` | Format a floppy: `format a:` (1.44 MB) or `format a: dd` (720 KB) |
| `DISKBNCH.C` | Disk speed test: raw sector reads, file write and file read |
| `SECDUMP.C` | Hex dump of a physical sector, with its partition table: `secdump 26` |
| `VERATEST.C` | VERA card test: registers, VRAM, a 640x400 test card, vertical blank, keyboard and mouse, parallel port |

## Known limitations

- Programs that use Atari hardware directly (sound chip, shifter registers, blitter) don't work.
- Floppy reads retry about 1 sector in 18, because of the timer interrupt. Each retry costs one disk revolution.
- Dual-SD transfers are slow, because the SPI is bit-banged.
- Serial flow control is recorded by `Rsconf` but not implemented. Baud rates without an Atari code, such as 38400, can be set in the BIOS Setup but not from EmuTOS.
- Only one floppy drive (`A:`) is supported.

## Plans

The detailed plan, with checklists and experiments, is in [EmuTOS on the Mini-68K port plan.md](EmuTOS%20on%20the%20Mini-68K%20port%20plan.md).

| Phase | Goal | Status |
| --- | --- | --- |
| 0. Groundwork | Toolchain, machine target, load-and-test loop | Done |
| 1. Serial EmuTOS | EmuTOS with disks on the serial console; build a C program on the board | Done |
| 2. GEM on VERA | GEM desktop shown on the VERA card | Working: desktop shown with changed-row copying at the VERA VSYNC (`make mini-68k WITH_AES=1`) |
| 3. Keyboard and mouse | Input through the VT82C42 controller on the VERA card | Mouse working; keyboard hardware confirmed with VERATEST, EmuTOS keyboard driver being tested |
| 4. Colour and direct drawing | ST low and medium on the VERA; experimental direct drawing into the VERA | Direct mode working and the default; colour working with `VERA_DIRECT=0`, colour in direct mode written, not yet tested |

- **Phase 2** copies changed rows of the existing 640×400 monochrome RAM screen to VERA's 1-bit bitmap mode. The console and the VDI mark the rows they draw on, and each VBL copies up to 48 of them. The VBL follows the VERA VSYNC (60 Hz), polled from the 200 Hz timer, so no interrupt line is needed.
- **Phase 3** converts the VT82C42's PC keyboard and mouse data into the Atari keyboard codes and mouse packets that EmuTOS expects. It also shows the mouse pointer as a VERA sprite.
- **Phase 4** adds colour by keeping the RAM screen: EmuTOS draws in ST low or medium, and the VBL copy converts Atari bit planes to VERA packed pixels (2 or 4 bits per pixel) through lookup tables. The desktop's *Change resolution* offers low, medium and high. A native driver writing straight to VERA was set aside: VERA reads do not auto-increment on this card, so the reads it needs (XOR drawing, cursor, scrolling) would make it slower than the copy, and it would break programs that write to screen memory.

## Repository layout

| Path | Contents |
| --- | --- |
| `emutos-src-1.4/` | EmuTOS 1.4 source, with the Mini-M68k port |
| `mini68k-tests/` | Utilities and test programs for the board (Sozobon C) |
| `BIOS-PORTING-GUIDE.md` | The Mini-M68k BIOS, memory map, boot process and I/O devices |
| `EmuTOS on the Mini-68K port plan.md` | Port plan and status; the `.pdf` is an older export |
| `bios-10.2/`, `bios-10.3/` | Mini-M68k BIOS sources, used as the hardware reference. The board runs 10.3 |
| `floppy/` | The SBC-386EX floppy driver for the DiskIO board, the reference for the floppy driver |
| `bin/` | Official EmuTOS 1.4 binaries for other machines |
| `README.txt` | EmuTOS 1.4 release notes |

## Credits and licence

- **EmuTOS:** by the EmuTOS development team. It and this port are distributed under the GNU General Public License, version 2 or later; see `emutos-src-1.4/doc/license.txt`.
- **Mini-M68k BIOS:** by John R. Coffman. Its sources here are under the GNU GPL version 3 or later.
- **SBC-386EX floppy driver:** by Dan Werner.
