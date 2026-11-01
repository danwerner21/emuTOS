# EmuTOS for the RetroBrew Mini-M68k

This repository is a port of [EmuTOS](https://emutos.sourceforge.io/) 1.4, the free, open-source TOS-compatible operating system, to the [RetroBrew Computers](https://www.retrobrewcomputers.org/) **Mini-M68k**, an MC68008 CPU board for the ECB bus.

EmuTOS boots on the board from a CF card and runs the GEM desktop on a VERA video card, with a PS/2 mouse and keyboard. The desktop runs in all three Atari ST resolutions, or at 640×400 in 16 colours with [fVDI](#fvdi-the-desktop-at-640400-in-16-colours). Without the desktop it runs the EmuCON command shell over the serial console. It reads and writes FAT disks on the CF, SD and floppy boards listed below. TOS programs that use GEM or the console run, including the Sozobon C compiler, which builds programs on the board itself.

![EmuDesk in ST medium (640×200, 4 colours) on the VERA card, with a window open on C:\UTILITIE](images\pic2a.jpg)

*The EmuTOS desktop in ST medium resolution on the Mini-M68k's VERA card.*

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
| Dual-SD | bit-banged SPI | set in BIOS Setup (e.g. `0x08`) | Working: both sockets |
| VERA card: video | VERA (FPGA) | `0x80`–`0x9F` | Working: ST high (640×400, 2 colours), ST medium (640×200, 4 colours), ST low (320×200, 16 colours); mouse pointer as a VERA sprite. See [VERA card read bug](#vera-card-read-bug) |
| VERA card: sound | VERA PSG | (through the VERA) | Working: an emulated YM2149 played on the PSG, for the bell, key click, `Dosound` and `Giaccess`; `ZSMPLAY` plays chiptunes on all 16 voices |
| VERA card: keyboard and mouse | VT82C42 (8042 compatible), polled | `0xA0`–`0xA1` | Working: keyboard and mouse |
| VERA card: parallel port | PC-style printer port | `0xA4`–`0xA6` | Working (`bios/parport.c`); V1.1 cards need the strobe wire (see below) |
| Dual DMA IDE | — | — | Not supported |

The MF/PIC board is required, at base port `0x40`. The VERA card is needed for the desktop.

Disk boards are taken from the board list saved in the **BIOS Setup** (BIOS 10.3), so EmuTOS sees the same disks, in the same order, as the BIOS. Changing the board configuration doesn't require a rebuild.

**Disk formats:** EmuTOS reads and writes FAT12 and FAT16 partitions (MBR types `01`, `04`, `06` and `0E`) up to 2 GB. FAT32 and exFAT partitions can't be used. Cards formatted on a PC are recognised automatically.

## Getting started, step by step

This section takes you from a working Mini-M68k to the EmuTOS desktop. If your board already boots its BIOS and you can talk to it over serial, you're ready to start.

### 1. What you need

- **The Mini-M68k CPU board** with BIOS 10.3, and the **MF/PIC board** at base port `0x40`. The MF/PIC provides the serial console, the timer, the clock and the CF card interface, and EmuTOS needs all four.
- **A CF card** in the MF/PIC's IDE socket. Any size works, but EmuTOS can only use partitions up to 2 GB.
- **A serial terminal:** a USB-to-serial adapter on the MF/PIC console port, and a terminal program on your PC (PuTTY, Tera Term, minicom). Use the same baud rate as the BIOS, and VT100 or ANSI emulation.
- **For the desktop (optional but recommended):** the VERA video card, a VGA monitor, and a PS/2 keyboard and mouse plugged into the VERA card.
- **A Linux PC (or WSL on Windows)** to build EmuTOS. There are no ready-built images in this repository.

### 2. Install the cross compiler

EmuTOS is built with the `m68k-atari-mint` GCC toolchain. On Ubuntu or Debian (including WSL), Vincent Rivière's packages are the easiest:

```sh
sudo add-apt-repository ppa:vriviere/ppa
sudo apt update
sudo apt install cross-mint-essential git make gcc
```

For other systems, see [Vincent Rivière's m68k-atari-mint page](http://vincent.riviere.free.fr/soft/m68k-atari-mint/). Check the install with `m68k-atari-mint-gcc --version`. The host `gcc` is also needed, for the small tools the build runs on your PC.

### 3. Get the source and build EmuTOS

```sh
git clone https://github.com/danwerner21/emuTOS.git
cd emuTOS/emutos-src-1.4
make clean
make mini-68k WITH_AES=1
```

After a minute or two this produces **`emutos.elf`** in `emutos-src-1.4`. That's the whole operating system, about 290 KB, with the GEM desktop included.

### 4. Prepare the CF card

EmuTOS and the board BIOS both read FAT, so one partition serves both.

1. Put the CF card in a card reader on your PC.
2. Create a **FAT16** partition of 2 GB or less. FAT32 won't work.
   - **Windows:** use Disk Management to make a partition of 2 GB or less, then format it with the file system **FAT** (not FAT32 or exFAT).
   - **Linux:** for example `sudo mkfs.fat -F 16 /dev/sdX1`, where `sdX1` is the card's partition. Check the device name carefully first.
3. Copy `emutos.elf` to the root of that partition.
4. Optionally, create a text file `EMUTOS.CMD` in the root containing the single line `s emutos.elf`. That lets you start EmuTOS by typing just `emutos`.
5. Optionally, put the same line in `BOOT.CMD`, and the BIOS starts EmuTOS on its own at power-on.

If the card already holds other systems, such as FUZIX, keep them on other partitions. EmuTOS gives every FAT12 or FAT16 partition a drive letter, starting at `C:`.

### 5. Boot EmuTOS

1. Put the CF card back in the MF/PIC, connect the terminal, and power on. You should see the BIOS prompt.
2. Type:
   ```
   s emutos
   ```
   and press Return. The **`s`** matters: it starts the program in supervisor mode. Without it, EmuTOS stops at its first instruction.
3. EmuTOS prints its banner on the terminal, then a 3-second countdown, and starts.
   - **With a VERA card:** the GEM desktop appears on the monitor, and the PS/2 mouse and keyboard work. The terminal stays connected as a second console.
   - **Without a VERA card:** EmuTOS starts the EmuCON command shell on the terminal. Type `help` for its commands; `dir`, `type`, `copy`, `cd` and `mkdir` work as you'd expect.

Pressing the board's RESET button always returns you to the BIOS.

### 6. First steps on the desktop

- **Drives:** the CF card is `C:`. Further partitions and other disk boards follow, in the order the BIOS Setup lists them. A floppy drive on a DiskIO board is `A:`.
- **Resolution:** *Options → Change resolution* offers Low (320×200, 16 colours), Medium (640×200, 4 colours) and High (640×400, 2 colours). *Options → Save desktop* keeps the choice for the next boot.
- **Running programs:** double-click a `.PRG` (GEM program), `.TOS` (text program) or `.TTP` (text program that asks for parameters).
- **Command line:** EmuCON is built in. Choose *File → Execute EmuCON* on the desktop; type `exit` to come back.
- **Date and time:** EmuTOS reads the clock on the MF/PIC at boot. Set it with `SETCLOCK.TTP` from `mini68k-tests/` (see [Utilities](#utilities)).

### 7. Optional: 640×400 in 16 colours with fVDI

Once the desktop works, you can add fVDI for 16 colours at 640×400. See [fVDI](#fvdi-the-desktop-at-640400-in-16-colours) for how to build it and which three files to copy to the card.

### 8. Optional: a C compiler on the board

`PURE_C/` contains the Pure C compiler, patched to run on this board. Copy the whole folder to the CF card and start `PC.PRG`. The small test programs in `mini68k-tests/` can also be built on the board with the Sozobon C compiler.

### If something goes wrong

| What you see | Likely cause |
| --- | --- |
| The BIOS loads the file, then nothing happens | You typed `emutos` without the `s`; EmuTOS must start in supervisor mode |
| The BIOS can't find `emutos` | The file isn't in the root of a FAT partition the BIOS can read |
| EmuTOS starts, but there's no `C:` drive | The partition is FAT32 or exFAT, or larger than 2 GB; use FAT16 |
| Garbled characters on the terminal | The terminal's baud rate doesn't match the BIOS Setup, or the terminal isn't in VT100/ANSI mode |
| EmuCON instead of the desktop, with a VERA card fitted | EmuTOS was built without `WITH_AES=1` |
| A "Panic: Address Error" with misc=0000 when starting a program | The program probes for Atari hardware; see [Known bugs](#known-bugs-and-limitations) |

### Build options

- `WITH_AES=1` includes the GEM desktop. Without it, EmuTOS starts the EmuCON shell on the serial console, and the image is smaller.
- `VERA_DIRECT=0` uses the shadow-copy screen instead of direct drawing (see [How it works](#how-it-works)). Use it for programs that write to screen memory themselves. fVDI needs the default direct build.
- `MINI68K_LOAD` and `MINI68K_RAM_TOP` change the load address (default `0x180000`) and the top of RAM (default `0x200000`).

The serial console uses the baud rate set in the BIOS Setup and expects an ANSI or VT100 terminal. EmuTOS translates the VT52 codes that TOS programs send. With a VERA card, EmuCON also appears on the VERA screen.

## fVDI: the desktop at 640×400 in 16 colours

[fVDI](https://github.com/freemint/fvdi) is a replacement VDI for TOS. With the VERA driver in `fvdi/drivers/vera/`, it runs the GEM desktop at 640×240 or 640×400 in 16 colours, where EmuTOS's own VDI offers the three ST resolutions. The idea and the starting point came from Rob Gowin's BITSY MK I, a 68000 board that runs fVDI under EmuTOS with a Xosera video card. The `fvdi/` tree is taken from his fVDI fork, and the VERA driver is modelled on his Xosera driver.

**Building.** fVDI uses the same `m68k-atari-mint` toolchain:

```sh
cd fvdi
make CPU=000
```

This builds `engine/fvdi_gnu.prg` (fVDI itself) and `drivers/vera/vera.sys` (the driver). The tree must have LF line endings, even on a Windows checkout; `fvdi/.gitattributes` makes sure of that.

**Installing,** on drive C:
- `fvdi_gnu.prg` goes in `C:\AUTO\` as `FVDI_GNU.PRG`. It must be the only fVDI there, and it must come before any MiNT loader.
- `vera.sys` goes in `C:\GEMSYS\` as `VERA.SYS`.
- `drivers/vera/fvdi.sys` goes in the root of C: as `FVDI.SYS`. fVDI looks for it only in the current folder, `C:\` and `A:\`. The driver starts at 640×240; adding `640x400` after `vera.sys` on the driver line selects 640×400.

fVDI needs the default (direct) EmuTOS build.

**How it works.**
- **Drawing:** the driver draws everything with the CPU through the VERA ports: fills, lines, text and mono icons, blits with all 16 logic operations, and pixels. The VERA has no blitter. Rows are built in RAM 4 bytes at a time and written with assembly loops; the old screen is read only where it shows through.
- **Pointer and palette:** the mouse pointer is a VERA sprite. The driver hooks XBIOS `Setcolor` and `Setpalette`, so programs that set colours through the XBIOS still work.
- **Sharing the card with EmuTOS:** EmuTOS publishes a `VERA` cookie. The driver tells EmuTOS through it when it takes the VERA over. EmuTOS's VBL then leaves the mode, palette and sprites alone, and its text console switches to the new screen size. They also share a busy flag, so they never use the VERA ports at the same time. VERATEST uses the same cookie to run alongside both of them.
- **Text cursor and text mode:** fVDI's engine (`engine/escape.c`) has two small additions:
  - It hides EmuTOS's console cursor while the desktop is shown, as EmuTOS's own VDI does.
  - It tells EmuTOS, through the cookie, when GEM enters and leaves text mode. In text mode, EmuTOS puts the console on a VERA tile layer instead of fVDI's bitmap. A character is then 2 bytes in a tile map, and scrolling the whole screen moves the layer's scroll register. In the 16-colour bitmap, each scroll copied about 120 KB through the ports, close to a second a line. The map and font use part of the bitmap's VRAM, which fVDI clears on entering and leaving text mode, so graphics drawn by a TOS program while in text mode don't show.

## How it works

- **EmuTOS replaces the board BIOS.** The BIOS keeps its data at `0x000`–`0xFFF`, which overlaps the fixed TOS system variables at `0x400`–`0x800`. So EmuTOS takes over the whole machine and drives every device directly, and the BIOS `TRAP #8` calls are no longer available. Memory locations `0`–`7` are left alone, so the RESET button still returns to the BIOS.
- **It runs from RAM as if it were ROM.** The image is linked at `0x180000` and wrapped in a minimal ELF file, which the BIOS loads from FAT. The 1.5 MB below that is ST-RAM.
- **Screen (default, direct mode):** the VERA bitmap is the screen, at 1, 2 or 4 bits per pixel for ST high, medium and low. The console and the VDI draw into it through the VERA ports. Rectangle fills, byte-aligned text, screen clear and the whole console are written straight to the VERA. Other drawing (lines, other text, raster copies such as icons and menus, pixel access and seed fill) runs on a RAM copy of the area it touches: the area is read back from the VERA, converted to Atari bit planes, drawn by the standard EmuTOS code, and written back. The mouse pointer is a VERA sprite, so it never touches the screen.
- **Screen (`VERA_DIRECT=0`, shadow copy):** EmuTOS draws into its usual Atari screen in RAM, and each vertical blank copies the changed rows to the VERA, converting Atari bit planes to VERA pixels in the colour modes. Programs that write to screen memory themselves work in this mode.
- **Vertical blank:** it follows the VERA's 60 Hz VSYNC, which the 200 Hz timer interrupt polls, so no interrupt line is needed. Without a VERA it falls back to 50 Hz from the timer.
- **Keyboard and mouse:** the VT82C42 is polled from the timer interrupt. PS/2 keyboard codes (PC set 1) are translated to Atari scancodes, and PS/2 mouse packets to Atari mouse packets. The mouse runs at 8 counts per mm with the mouse's own 2:1 acceleration.
- **Serial input:** the BIOS doesn't route the UART interrupt to the NS32202, so input is polled from the timer interrupt. It keeps up with pasted text.
- **Sound:** there's no YM2149, so its registers are kept in RAM, written by EmuTOS's sound code: the bell, the key click, `Dosound` and `Giaccess`. Every 5 ms the timer interrupt plays them on the VERA's PSG. YM channels A–C become square waves on voices 0–2, and the noise goes to voice 3, with the YM envelope emulated in software. The interrupt doesn't wait for the screen drivers: it saves the VERA's address and control registers, writes the PSG, and puts them back. Envelopes fast enough to be heard as a tone, and samples played by changing the volume, are beyond 200 updates a second.
- **Floppy timing:** at 500 kbit/s the floppy controller needs a byte every 16 µs, which is 128 cycles of the 8 MHz 68008. The data phase is therefore in assembly and runs with interrupts masked, with short interrupt windows while waiting so the clock keeps time. A sector that still collides with the timer interrupt is retried.

## VERA card read bug

On the current VERA card, **reads of the VERA data ports don't auto-increment the VRAM address.** Reads return the correct byte, and writes auto-increment normally.

- **Cause (suspected):** at the VERA's header, CS and RD rise at the same moment. CS comes from the U18 74LS688 address decoder, which includes /IORQ, and RD comes through U7 (74LS244). Both end with the 68008's bus strobes. The VERA handles the end of a read a few of its own 25 MHz clocks later, and seems to need CS still low, and possibly the address still valid, when it does. On the X16, the VERA's home system, the strobe ends while CS and the address are still valid.
- **Effect on EmuTOS:** the driver writes the VRAM address before every read, so a read costs 2 port accesses instead of 1. Everything works, but whatever reads the screen is slower than it needs to be: console scrolling, saving the screen behind menus and dialogs, transparent and XOR drawing, and the read-back fallback in general. Writes are unaffected.
- **Fix in progress (card V1.1):** a rework stretches the VERA's CS 50–70 ns past RD using spare gates on the card. The `VERA` decoder output goes through U9B, U9A, U2C, U4C and U4D as a delay chain, and U2D combines the delayed and undelayed signals into the new `VERASEL`, which goes to J1 pin 11. The data buffer enable (U2A) stays on the original signal. If that isn't enough, the next step is to latch A0–A4 with a 74HCT573, enabled by `VERASEL`, so the address stays valid until CS rises.
- **Testing:** VERATEST test 7 (VRAM access diagnostic) and test 2 (VRAM test) show whether reads auto-increment. EmuTOS needs no change to test the card; once the fix works, the driver will switch to plain sequential reads.

Earlier faults on the card, all fixed in V1.1: VERA header address lines A3 and A4 were undriven, the printer port's 74LS138 decoders had a select input grounded, and U1 needed open-collector inverters (74LS06) for the PS/2 lines.

Printer strobe (found 2026-10-31): on V1.1 the strobe driver net (U11 O0 → U8C → R9, with C28) had no `STROBE` label, so it never reached P5 pin 1 (DB-25 pin 1); the pin only saw the RR2 pull-up and the printer never got a strobe. Fixed in the schematic by labelling that net `STROBE`; on V1.1 boards, a wire from the R9/C28 end to P5 pin 1. With it, VERATEST test 8 shows the printer answering every byte with PC polarity. Control bit 5 enables the data outputs (U10 /OE), as on a PC, so software must keep it 0.

## What was added and changed

All changes to EmuTOS are inside `MACHINE_MINI68K` (or `CONF_WITH_VERA_DIRECT`) conditionals, so other EmuTOS targets build as before. The tables compare `emutos-src-1.4` with the unmodified EmuTOS 1.4 source in this repository's first commit.

### New files in `emutos-src-1.4`

| File | Purpose |
| --- | --- |
| `bios/mini68k.c`, `bios/mini68k.h` | Machine support: UART console, NS32202 timer, DS1302 RTC, the BIOS NVRAM board list, `Rsconf` |
| `bios/mini68k2.S` | Timer interrupt: 200 Hz tick, UART and PS/2 polling, VBL (on VERA VSYNC), floppy motor timeout |
| `bios/ppide.c`, `bios/ppide.h`, `bios/ppide2.S` | 82C55 PPIDE back-end under EmuTOS's IDE driver (MF/PIC and DiskIO); assembly sector transfers |
| `bios/spi_mini68k.c` | Dual-SD SPI back-end for EmuTOS's SD/MMC driver, two sockets |
| `bios/fdc_mini68k.c`, `bios/fdc_mini68k2.S` | DiskIO floppy driver: polled 765 commands, read, write and format; assembly data phase |
| `bios/vera_mini68k.c`, `bios/vera_mini68k2.S`, `bios/vera.h` | VERA card: mode set-up, palette, VSYNC, mouse sprite, plane/pixel conversion, shadow-copy screen, assembly port loops |
| `bios/vera_direct.c` | Direct mode: port access, console drawing, screen clear, the read-back fallback |
| `vdi/vdi_vera.c` | Direct mode: VDI rectangle fill and fast text, in 1, 2 and 4 bits per pixel |
| `bios/kbd_mini68k.c` | PS/2 keyboard and mouse through the VT82C42 on the VERA card |
| `bios/ym_mini68k.c` | Emulated YM2149 registers, played on the VERA's PSG |
| `tools/mkelf68k.c` | Host tool that wraps `emutos.img` in an ELF file for the BIOS loader |

### Modified EmuTOS files

| File | Change |
| --- | --- |
| **Build** | |
| `Makefile` | The `mini-68k` target, its options (`VERA_DIRECT`, `MINI68K_LOAD`, `MINI68K_RAM_TOP`), the new source files, and the ELF wrapping step |
| `emutos.ld` | Link address for the Mini-M68k (`0x180000`, run from RAM as a "ROM") |
| `include/config.h` | Machine defaults: Atari hardware off, serial console, IDE and SD on, YM2149 emulation on, `CONF_WITH_VERA_DIRECT`, ST-RAM size |
| **System** | |
| `bios/machine.c` | Machine set-up call and the machine name ("RetroBrew Mini-M68k") |
| `bios/mfp.c` | Starts the NS32202 system timer instead of the MFP's |
| `bios/delay.c` | Delay loops calibrated against the 200 Hz timer |
| `bios/clock.c` | Date and time from the DS1302 on the MF/PIC |
| `bios/kprint.c` | Debug output straight to the MF/PIC UART |
| `bios/serport.c` | Console UART and `Rsconf` on the MF/PIC's 16550 |
| **Disks** | |
| `bios/ide.c` | IDE register access through the 82C55 (PPIDE); one interface per MF/PIC or DiskIO board, from the BIOS board list |
| `bios/sd.c` | Two cards (Dual-SD sockets 0 and 1); longer start-up timeout |
| `bios/floppy.c` | Hooks for the DiskIO floppy driver, read-back verify, and format |
| **Keyboard, printer, sound** | |
| `bios/ikbd.c` | Starts the PS/2 keyboard and mouse driver |
| `bios/parport.c`, `bios/parport.h` | Printer port on the VERA card (`Bconout` device 0, `Bcostat`, `Setprt`) |
| `bios/xbios.c` | `Setprt` available when the printer port is present |
| `bios/sound.c` | YM2149 register access through the emulated registers (bell, key click, `Dosound`, `Giaccess`) |
| **Screen and console** | |
| `bios/screen.c` | Resolution, palette and screen address on the VERA; resolution changes |
| `bios/conout.c` | Console drawing and scrolling through the VERA (direct mode); changed rows for the shadow copy |
| `bios/vt52.c` | The cursor blink waits while the VERA is busy |
| **VDI (direct mode)** | |
| `vdi/vdi_defs.h` | Declarations for drawing into the VERA, and the read-back wrappers |
| `vdi/vdi_main.c` | Changed rows for the shadow copy |
| `vdi/vdi_control.c` | Screen clear in the VERA |
| `vdi/vdi_fill.c`, `vdi/vdi_line.c`, `vdi/vdi_raster.c`, `vdi/vdi_textblit.c` | Native VERA drawing where it exists, and the read-back fallback around the rest |
| `vdi/vdi_mouse.c` | The mouse pointer as a VERA sprite |
| **Desktop and shell** | |
| `aes/geminit.c`, `desk/deskmain.c` | Resolution handling enabled for the Mini-M68k |
| `desk/deskrez.c` | The Low/Medium/High resolution choice |
| `cli/cmdint.c` | EmuCON's `copy` accepts the devices `PRN:`, `AUX:` and `CON:` |

### Changes in the fVDI tree (`fvdi/`)

Compared with Rob Gowin's fVDI fork (`xosera` branch):

| File | Change |
| --- | --- |
| `drivers/vera/` (new) | The VERA driver: `vera_spec.c` (set-up, mode), `vera_io.c` (port access, assembly runs), `vera_pal.c` (palette), `vera_fill.c`, `vera_line.c`, `vera_blit.c`, `vera_scr.c` (drawing), `vera_mouse.c` (pointer sprite), `vera_xbios.c` (`Setcolor`/`Setpalette` hook), `vera.h`, `Makefile`, `fvdi.sys` |
| `drivers/Makefile` | Builds the `vera` driver |
| `engine/escape.c` | Hides EmuTOS's console cursor on the desktop, and tells EmuTOS (through the `VERA` cookie) when GEM enters and leaves text mode |
| `.gitattributes` (new) | Keeps LF line endings, as the build needs |
| `include/vdi.gnu`, `include/linea.gnu` | Plain copies instead of symbolic links, so a Windows checkout builds |
| `engine/setup.c` | Renamed from `SETUP.C` (lower case, as the Makefile expects) |

## Utilities

`mini68k-tests/` holds small programs to compile on the board with Sozobon C, for example `cc setclock.c -o setclock.ttp`:

| Program | Purpose |
| --- | --- |
| `SETCLOCK.C` | Show or set the date and time: `setclock 2026-10-17 14:30`. Written to the DS1302 |
| `ZSMPLAY.C` | Chiptune player for ZSM files, the Commander X16's music format: `zsmplay tune.zsm`, or `zsmplay -l tune.zsm` to loop. Writes straight to the VERA's PSG, so tunes get all 16 voices and every waveform. The X16's YM2151 FM parts are skipped, so choose PSG-only tunes. Runs alongside EmuTOS and fVDI, using the `VERA` cookie's busy flag |
| `FORMAT.C` | Format a floppy: `format a:` (1.44 MB) or `format a: dd` (720 KB) |
| `DISKBNCH.C` | Disk speed test: raw sector reads, file write and file read |
| `SECDUMP.C` | Hex dump of a physical sector, with its partition table: `secdump 26` |
| `VERATEST.C` | VERA card test: registers, VRAM, a 640x400 test card, vertical blank, keyboard and mouse, parallel port, VRAM access diagnostic. Runs under EmuTOS, with or without fVDI: it saves and restores the screen around the tests that overwrite it, and borrows the keyboard controller for the keyboard test |

## Known bugs and limitations

- **VERA reads don't auto-increment** on the current card. EmuTOS works around it at some cost in speed; see [VERA card read bug](#vera-card-read-bug).
- **Direct mode doesn't show programs that write to screen memory themselves** (many games and some Line-A programs). Build with `VERA_DIRECT=0` for those.
- **Colour drawing is slower than mono**, because each byte holds fewer pixels and the read-back fallback converts between bit planes and VERA pixels both ways. Icons and menus in ST low show it most.
- **Programs that use Atari hardware directly** (sound chip, shifter registers, blitter) don't work. Sound through the XBIOS (`Dosound`, `Giaccess`) does; SNDH music files don't, because they write to the YM2149 directly.
- **Programs that probe for hardware by catching a bus error** find it "present", because the Mini never raises a bus error. Their test write then lands in the ECB I/O space. An Atari address `$FFFFxx40` is the NS32202 (A8 and up select its register), and upsetting it makes the next timer tick arrive as vector 3. That shows as a bogus "Address Error" panic with misc=0000 and the user program's PC in the addr field. Pure C does this at startup to look for an SFP004 maths coprocessor (`move.w #3,$FFFFFA42`). The copies in `PURE_C/` are patched to skip the probe and report no coprocessor (`31fc 0003 fa42` replaced by `6000 0014 4e71`, a branch to the probe's own no-coprocessor exit), in all its tools and in `PCSTDLIB.LIB` and `PCSTART.PRG`, so programs built with it are fixed too. The unpatched files are in `PURE_C/ORIGINAL/`.
- **Floppy:** reads retry about 1 sector in 18, because of the timer interrupt, and each retry costs one disk revolution. Only one drive (`A:`) is supported.
- **Dual-SD** transfers are slow, because the SPI is bit-banged.
- **Serial:** flow control is recorded by `Rsconf` but not implemented. Baud rates without an Atari code, such as 38400, can be set in the BIOS Setup but not from EmuTOS.

## Plans

The detailed plan, with checklists and experiments, is in [EmuTOS on the Mini-68K port plan.md](EmuTOS%20on%20the%20Mini-68K%20port%20plan.md).

| Phase | Goal | Status |
| --- | --- | --- |
| 0. Groundwork | Toolchain, machine target, load-and-test loop | Done |
| 1. Serial EmuTOS | EmuTOS with disks on the serial console; build a C program on the board | Done |
| 2. GEM on VERA | GEM desktop on the VERA card | Done: shadow copy of changed rows at the VERA VSYNC |
| 3. Keyboard and mouse | Input through the VT82C42 on the VERA card | Done: keyboard and mouse working |
| 4. Colour and direct drawing | ST low and medium colour; drawing straight into the VERA | Done: direct mode is the default, in all three resolutions; shadow copy kept as an option |
| 5. fVDI | fVDI with a VERA driver: 640×240 at 16 colours, then 640×400 | Working on the board: 640×240 and 640×400 at 16 colours, XBIOS palette calls, mouse pointer as a sprite |

Phase 5 is described under [fVDI](#fvdi-the-desktop-at-640400-in-16-colours).

Next steps:
1. **Card read fix:** finish the V1.1 CS-stretch rework, and the address latch if needed. Then switch the fVDI driver and the EmuTOS read loops to sequential reads, which halves the cost of every screen read.

## Repository layout

| Path | Contents |
| --- | --- |
| `emutos-src-1.4/` | EmuTOS 1.4 source, with the Mini-M68k port |
| `mini68k-tests/` | Utilities and test programs for the board (Sozobon C) |
| `PURE_C/` | The Pure C compiler, patched to run on the board (see [Known bugs](#known-bugs-and-limitations)); the unpatched files are in `PURE_C/ORIGINAL/` |
| `fvdi/` | fVDI source (from Rob Gowin's fork, `xosera` branch), with the Mini-M68k VERA driver in `fvdi/drivers/vera/`; see [fVDI](#fvdi-the-desktop-at-640400-in-16-colours) |
| `EmuTOS on the Mini-68K port plan.md` | Port plan and status; the `.pdf` is an older export |
| `X16 Reference - 09 - VERA Programmer's Reference.md` | The VERA programmer's reference, used for the video driver |
| `pic2a.jpg` | Photo of the desktop running on the board |
| `bin/` | Official EmuTOS 1.4 binaries for other machines |
| `README.txt` | EmuTOS 1.4 release notes |

## Credits and licence

- **EmuTOS:** by the EmuTOS development team. It and this port are distributed under the GNU General Public License, version 2 or later; see `emutos-src-1.4/doc/license.txt`.
- **Mini-M68k BIOS:** by John R. Coffman. The port follows its hardware set-up and BIOS 10.3 board numbering.
- **fVDI:** by Johan Klockars, with later work by the FreeMiNT project and others. Distributed under the GNU General Public License, apart from the parts that its `readme.now` lists as not yet covered.
- **Rob Gowin:** his 'BITSY MK I' showed that EmuTOS with fVDI works well on a plain 68000 with a video card that isn't memory mapped. The VERA driver is based on his Xosera fVDI driver (written with Daniel Cliche and Xark), and `fvdi/` comes from his fVDI fork.
- **Floppy driver:** based on Dan Werner's floppy driver for the SBC-386EX.
- **VERA:** the video FPGA from the Commander X16 project; the programmer's reference is from the X16 documentation.
