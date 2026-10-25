# EmuTOS on the Mini-68K: port plan

Oct 11, 2026 · @Dan Werner · updated Oct 17, 2026

The plan is to bring EmuTOS up on the serial console first, then run GEM on the VERA card through a RAM shadow framebuffer, and finally replace the shadow copy with a native VERA driver. The hardware facts below were checked against `BIOS-PORTING-GUIDE.md`, the BIOS 10.2 sources in `bios-10.2/` and tests on the board. Details of the VERA card are still unchecked, because the card has not arrived yet.

## Status

| Phase | State (Oct 17, 2026) |
| --- | --- |
| 0. Groundwork | Done |
| 1. Serial EmuTOS | Done. Exit test passed: Sozobon C built and ran hello-world on the board (about 45 s) |
| 2. Shadow framebuffer | Done: EmuDesk and EmuCON on the VERA, changed-row copying at the VERA VSYNC (Oct 24, 2026) |
| 3. Input | Mouse working on the desktop (Oct 24, 2026); keyboard hardware confirmed with VERATEST (Oct 25, 2026), EmuTOS keyboard being tested |
| 4. Colour and direct | Colour through the shadow copy working (Oct 24, 2026); direct mode working in all three resolutions and the default (Oct 25, 2026) |

## Hardware

Each row is confirmed. The last column says how it shaped the port.

| Item | Confirmed | Effect on the port |
| --- | --- | --- |
| CPU | MC68008FN, 52-pin PLCC, 8 MHz (as the BIOS timing code assumes), 22 address lines (4 MB, mirrored) | Plain 68000 code (`-m68000`, no VBR). Only IPL 2 (the NS32202, which supplies vectors) and IPL 7 (ECB `/NMI`) are wired, so every device interrupt, including a future VERA vsync, has to come through an NS32202 input. |
| RAM | 2 MB SRAM at `0x000000`–`0x1FFFFF`, writable from address 0 after boot | EmuTOS uses `0x000000`–`0x17FFFF` (1.5 MB) as ST-RAM; the top 512 KB holds the EmuTOS image. |
| ROM | BIOS 10.2 plus a ROM disk at `0xFFF80000` | EmuTOS does not go in ROM. The BIOS loads `EMUTOS.ELF` from a FAT volume into RAM. |
| I/O | ECB port *p* at `0xFFFF8000` + *p*, supervisor mode only | Every driver runs in supervisor mode; debug output switches to supervisor mode when called from user code. |
| MMU | None | As expected. |
| Serial | 16550/16C750 at port `0x48`, clocked at 1.8432 MHz | Console driver. The BIOS does not route the UART interrupt to the NS32202, so input is polled from the 200 Hz tick (keeps up with pasted text). |
| Interrupts and timer | NS32202 at port `0x40`; register *r* at `0xFFFF8040` + *r*·`0x100`; reading register 32 (`0xFFFFA040`) is End-Of-Interrupt; vector base 16 | System tick: H-counter routed to IR3 (vector 19), 1.8432 MHz / 4, count 2303 = exactly 200 Hz. Other inputs are masked. |
| Disk | PPIDE: 82C55 at ports `0x44`–`0x47` (A = D0–D7, B = D8–D15, C = address and strobes); DiskIO v2/v3 (also an 82C55) at port `0x20`; Dual-SD (bit-banged SPI) at port `0x08` | Backend under EmuTOS's own IDE driver. Each PPIDE or DiskIO board configured in the BIOS Setup becomes an IDE interface, in Setup order. A Dual-SD board is driven through EmuTOS's SD/MMC driver (socket 0 only). |
| Floppy | SMC FDC9266 (765 compatible) on the DiskIO at ports `0x36`–`0x38` (board port + `0x16`), polled, no DMA; write-only control latch at `0x38` | Driver ported from the SBC-386EX driver for the same board. Data phase in assembly with interrupts masked (16 µs per byte at 500 kbit/s). 1.44 MB and 720 KB disks read and write. |
| Clock | DS1302 bit-banged through a latch at port `0x43`; century in BIOS NVRAM byte `0x22` | RTC driver; keeps the BIOS NVRAM checksum valid when the century changes. |
| Video | VERA card | Ordered; not yet available. |
| Keyboard and mouse | VT82C42 keyboard controller on the VERA card | Phase 3; not yet available. |
| Bus errors | No bus-error timeout: unmapped reads return garbage | All hardware probes are compiled out (`CONF_ATARI_HARDWARE 0`). |

## How EmuTOS runs on the board

- **Takeover:** the BIOS keeps its vectors, data and heap in `0x000`–`0xFFF`, which overlaps the fixed TOS system variables at `0x400`–`0x800`. So EmuTOS takes over the whole machine, and the BIOS `TRAP #8` calls stop working once it starts. EmuTOS leaves locations `0`–`7` alone, so the RESET button still restarts the BIOS.
- **Build:** `make mini-68k` produces `emutos.elf`. The image is linked as a "ROM" at `0x180000` and wrapped in a minimal ELF file by `tools/mkelf68k.c`. It is about 125 KB of the 512 KB available.
- **Start:** `s emutos` at the BIOS prompt (supervisor mode is required). Alternatively, an `EMUTOS.CMD` file containing `s emutos.elf` lets `emutos` alone work, and `BOOT.CMD` can auto-boot it.
- **Shell:** the default build has no GEM (`WITH_AES=0`) and boots into EmuCON. `make mini-68k WITH_AES=1` includes the desktop.
- **Screen:** a 640×400 monochrome (ST high) screen already exists in RAM below `phystop`, which gives 80 columns for the console. A 50 Hz vertical blank is emulated from every 4th timer tick.
- **Code:** `bios/mini68k.c`, `bios/mini68k.h`, `bios/mini68k2.S`, `bios/ppide.c`, `bios/ppide.h` and `tools/mkelf68k.c`. There are small `MACHINE_MINI68K` hooks in `include/config.h`, `emutos.ld`, `Makefile`, `bios/ide.c`, `bios/clock.c`, `bios/serport.c`, `bios/kprint.c`, `bios/machine.c`, `bios/mfp.c`, `bios/screen.c` and `bios/delay.c`.

## Phase 0: groundwork (done)

- [x] Cross toolchain: `m68k-atari-mint-gcc` on the build server.
- [x] New machine define `MACHINE_MINI68K`, modelled on the Lisa and M548x ports.
- [x] Memory map and I/O ports: see the hardware table.
- [x] Where EmuTOS lives: a RAM image loaded by the BIOS from the CF card (E1). No reflashing is needed during development.
- [x] Early output: polled UART debug output works from the first instruction, using the BIOS's UART setup.
- [x] Interrupt levels: everything goes through the NS32202 at IPL 2; IPL 7 is ECB `/NMI`.
- [x] Bus errors (E2): settled from the schematic and BIOS docs. There is no bus-error timeout, so probes are compiled out.

## Phase 1: EmuTOS on the serial console (done)

**Configuration**

- [x] Every Atari-specific device is disabled (`CONF_ATARI_HARDWARE 0`).
- [x] Serial console enabled, with ANSI translation (`CONF_SERIAL_CONSOLE_ANSI`).
- [x] Hardware probes compiled out.
- [x] Fixed ST-RAM size: the load address, `0x180000`.

**Drivers**

- [x] 16550 UART: polled output; input polled from the timer interrupt into the keyboard buffer; `Rsconf` sets the baud rate and line format. At start-up EmuTOS keeps the baud rate chosen in the BIOS Setup.
- [x] System tick: 200 Hz from the NS32202 H-counter (E3).
- [x] Interrupt glue: vectors 16–23, EOI handling, unused inputs masked and ignored, 50 Hz VBL derived from the tick.
- [x] PPIDE block driver beneath EmuTOS's IDE, partition and FAT layers (E4). Read and write tested.
- [x] RTC: reads the DS1302 at boot. Setting it from EmuTOS is written but untested, because EmuCON has no date or time command.
- [x] Delay loops calibrated against the 200 Hz tick, instead of assuming a 16 MHz 68000.

**Bring-up order**

1. [x] Banner and early debug output over the UART.
2. [x] Tick interrupt running; EmuTOS reaches the EmuCON prompt.
3. [x] Disk: CF card partition mounted as `C:`; `ls`, `cat`, `cp`, `mkdir` and `rm` work.
4. [x] Tools: Sozobon C (`cc`, `hcc`, `top`, `jas`, `ld`, dLibs) built and ran hello-world on the board in about 45 seconds (the Phase 1 exit test).

**Decisions made**

- **Terminal:** ANSI. EmuTOS translates the VT52 sequences that TOS text programs send into ANSI, so any VT100/ANSI terminal works (E5).
- **Disk layout:** one CF card shared with the BIOS boot files and FUZIX. EmuTOS reads FAT12 and FAT16 partitions (MBR types `01`, `04`, `06`, `0E`). FAT32 partitions get a drive letter but cannot be read. PC-formatted cards are detected as byte-swapped and handled automatically.

**Known gaps**

- Floppy: format works (FORMAT.TTP in mini68k-tests, or XBIOS Flopfmt); about 1 sector in 18 needs a retry because of the timer interrupt, which costs one revolution.
- Dual-SD socket 1: supported by the driver (presence is decided by starting the card, not by card detect), but not tested: socket 1 on this board has a confirmed hardware fault.
- The RTC can be set with SETCLOCK.TTP (mini68k-tests).
- Serial flow control is recorded by `Rsconf` but not implemented.
- Baud rates without an Atari `Rsconf` code (such as 38400) can be set in the BIOS Setup and are kept, but cannot be selected from EmuTOS.
- Disk speed (DISKBNCH, 256 KB, assembly transfer loop in `bios/ppide2.S`): raw sector reads 164 KB/s, GEMDOS file reads 127 KB/s, file writes 69 KB/s. With the earlier C loop the figures were 85, 73 and 50 KB/s. Reads are now close to what the 68008 can move through the 8255; writes are limited mostly by something other than the transfer loop.

## Phase 2: GEM on VERA through a shadow framebuffer

EmuTOS draws into an ordinary one-plane bitmap in RAM, and a copy routine streams changed rows to VERA through its auto-incrementing data port.

**Display mode**

Start at 640×400, one bit per pixel. That is exactly Atari ST high resolution (32,000 bytes, 80 bytes per row), which is what the most monochrome software expects. Keep the height a build constant so 640×480 (38,400 bytes) is a one-line change later.

**Work items**

- [ ] VERA init: one layer in 640-wide 1 bpp bitmap mode, two palette entries, border set for the 400-line area, other layer and sprites off (E7).
- [x] Screen setup: done in Phase 1. EmuTOS already keeps a 640×400 one-plane screen in RAM below `phystop` and reports it to the VDI and Line-A. The copy routine only needs to read it.
- [ ] Copy routine: for each dirty row, set the VERA address once and stream 80 bytes; unrolled loop, written in assembly (E6).
- [x] Vsync as the VBL: the 200 Hz timer polls the VERA VSYNC flag (ISR bit 0) and runs the VBL when it is set, so no interrupt line or jumper is needed. With no VSYNC within 100 ms it falls back to a 50 Hz VBL from the timer. Working on hardware (E8).
- [ ] VERA register discipline: the address and control registers are shared state, so any interrupt code that touches VERA must save and restore them, or all VERA access must happen at one interrupt level.
- [ ] Console switch: move the text console from serial to the screen, keeping serial as a debug channel.
- [ ] Build with `WITH_AES=1` to include the GEM desktop.

**Dirty tracking, in three steps**

1. No tracking: sweep the whole screen round-robin, a fixed number of rows per frame. Slow but proves the path.
2. Coarse tracking (done, working on hardware): the VDI dispatcher (`vdi/vdi_main.c`) and the console output routines (`bios/conout.c`) mark changed rows in a bitmap after drawing; each VBL copies up to 48 marked rows, plus the rows around a moving mouse pointer. A background sweep of 8 rows per idle VBL catches anything that wrote to the screen directly.
3. Exact tracking: have each VDI primitive report the rectangle it actually touched. This is also the first step toward Phase 4.

**Budget (estimates to be checked by E6 and E9)**

- One row costs about 1,600 CPU cycles, about 0.2 ms at 8 MHz.
- A full 400-row copy is about 80 ms of solid CPU time.
- A background sweep limited to a quarter of the CPU refreshes the whole screen in roughly a third of a second.

## Phase 3: keyboard and mouse

EmuTOS takes input as Atari keyboard scancodes and relative mouse packets, so the work is a translator from whatever hardware you choose into those two forms.

- [ ] Choose the hardware. Candidates: a PS/2 controller already on one of your ECB video boards, if fitted; a serial mouse on a second UART; or a small microcontroller that presents both devices on one port.
- [ ] Keyboard driver: receive scancodes, translate to Atari scancodes, and feed EmuTOS's keyboard buffer, including shift, control and alternate state.
- [ ] Mouse driver: convert movement and buttons into the relative packets EmuTOS's mouse vector expects. The Amiga port in the EmuTOS source does the same job and is the model to follow.
- [ ] Mouse pointer as a VERA sprite: replace the software cursor's draw and erase with a sprite position update, and convert the 16×16 cursor shape and mask to sprite pixels whenever an application changes it (E10).
- [ ] Fallback for early testing: EmuTOS lets the keyboard move the pointer, so GEM can be tried before the mouse works.

## Phase 4: native VERA driver

**Decision (Oct 24, 2026): colour through the shadow copy instead.** On this card VERA reads do not auto-increment, so every read needs its address set again. A native driver needs reads for XOR drawing, the text cursor, transparent text and scrolling, so in monochrome it would be slower than the shadow copy, and it would break programs that write to screen memory. Colour is done with the shadow method instead:

- [x] EmuTOS draws in ST low (320×200, 16 colours) or ST medium (640×200, 4 colours) in RAM. VERA shows them as 4 bpp at 320 wide or 2 bpp at 640 wide, with lines doubled (VSCALE 64).
- [x] The copy converts Atari bit planes to packed pixels through lookup tables (`bios/vera_mini68k.c`). Byte offsets are the same in RAM and VRAM, so dirty rows and the mouse pointer box map directly.
- [x] Palette: `Setcolor`/`Setpalette` update a shadow palette, written to VERA at the next VBL. Resolution changes are also applied at the VBL, so only the VBL touches the VERA registers.
- [x] The desktop's *Change resolution* offers low, medium and high; the choice is saved in `EMUDESK.INF`.
- [x] Tested on the board: all three resolutions work (Oct 24, 2026).

**Direct mode, first version (Oct 24, 2026; working on the board, feels smoother than the copy).** Now the default build; `VERA_DIRECT=0` selects the shadow copy (colour). ST high only. The VERA bitmap is the screen and nothing is copied at the VBL:

- [x] Port discipline: writes through DATA1/ADDR1; reads through DATA0 with ADDR0 at no increment, writing the address before each read (works whether or not reads auto-increment). Every drawing operation sets a busy flag; the VBL (cursor blink, sprite, palette) waits while it is set.
- [x] Native: rectangle fill (also horizontal lines and polygon spans), byte-aligned text, screen clear, the console (character, cursor, blank, scroll as a VRAM-to-VRAM copy).
- [x] Mouse pointer as VERA sprite 0 (E10). Line-A sprites are still drawn into the screen.
- [x] Read-back fallback for the rest: diagonal and vertical lines, general text, raster copies, pixel read/write, seed fill. The area is read from the VERA into the RAM screen, drawn there by the existing code, and written back.
- [x] Tested on the board: desktop, console and mouse sprite all work.
- [x] Raster copies to the screen only read back the partial edge words when the logic operation ignores the destination (menu and dialog restores, icons in replace mode).
- [ ] Convert the remaining fallback routines to native ones.

**Colour in direct mode (Oct 24, 2026; working on the board).** ST low and medium are shown as 4 bpp and 2 bpp VERA bitmaps, as in the shadow copy, and the desktop's *Change resolution* works in direct mode:

- [x] The read-back fallback converts both ways: VERA packed pixels to Atari planes on reading (reverse lookup tables, bits shifted into one plane byte per accumulator lane), and back on writing.
- [x] Native colour versions of rectangle fill (pattern and pixel masks expanded to whole-pixel bit fields), byte-aligned text and the console (cell offsets converted from the planar layout).
- [x] Multi-plane fill patterns, and everything else not native, go through the fallback.
- [x] Resolution changes switch the VERA at once (direct drawing in the new layout starts straight away).
- [x] Tested on the board: all three resolutions work (Oct 25, 2026).
- [ ] Fix the card's read timing, so reads auto-increment and cost half as much.

The original native driver plan is kept below for reference.

A native driver replaces the lowest drawing layer so that the VDI, Line-A and the text console write to VERA's memory through its ports, with no RAM copy of the screen.

**What it buys, stated plainly**

VERA has no hardware line, fill or block-copy commands, so in monochrome a native driver is not automatically faster than the shadow copy. Its real gains are color (the driver writes VERA's packed pixels directly, with no planar conversion pass), no dirty scanning, no double writes for simple fills and text, and 32 KB or more of RAM returned. E11 measures this before the work starts.

**Design choice**

| Option | What it is | For | Against |
| --- | --- | --- | --- |
| A. Modify EmuTOS's VDI | Put a small device interface under the existing VDI and Line-A routines, with VERA as its first backend | One code base; console and Line-A covered | A lasting fork of EmuTOS's VDI |
| B. fVDI driver | Write a VERA driver for the open-source replacement VDI | Driver model already exists; EmuTOS untouched | Console and Line-A are not covered; needs checking on a plain 68000 with 2 MB |

Option A is the working assumption because it covers the console and Line-A as well.

**Primitives to implement**

- [ ] Set address and stream helpers, including a second pointer for read-then-write.
- [ ] Horizontal span fill with pattern and the four VDI writing modes; XOR and transparent modes need a read from VERA before each write.
- [ ] Rectangle fill, built on spans.
- [ ] General line, built on pixel and span writes.
- [ ] Block transfer in four directions: memory to screen, screen to memory, screen to screen using VERA's two data ports, and the 16 logic operations.
- [ ] Text: render glyphs through the memory-to-screen path, with a fast case for unstyled system-font text.
- [ ] Console: character cell draw, cursor, and scroll as a screen-to-screen copy.
- [ ] Pixel read, and seed fill, which reads heavily and will be slow through ports.
- [ ] Line-A entry points mapped onto the same primitives.

**Color**

- [ ] Add a 4-color 640-wide mode (2 bits per pixel fits in VERA's memory at 480 lines).
- [ ] Test whether 16 colors at 640×400 fits beside the sprite and palette areas (E12).
- [ ] Convert Atari planar bitmaps to packed pixels in the memory-to-screen path with lookup tables.

**Compatibility**

Programs that write straight to screen memory will show nothing under a native driver. Keep the shadow framebuffer as a build or boot option for those.

**Order of work**

1. Finish exact dirty rectangles in Phase 2; this identifies every place the VDI touches the screen.
2. Introduce the device interface with the RAM bitmap as its only backend and confirm nothing regresses.
3. Add the VERA backend one primitive at a time, falling back to shadow drawing for the rest.
4. Move the console, then remove the shadow buffer from the default build.
5. Add color modes.

## Experiments

Most of these are small standalone programs that run under the existing monitor or CP/M-68K, so they can start before any EmuTOS code is written. The Result column records what is settled.

| ID | Experiment | What it settles | Pass mark | Result |
| --- | --- | --- | --- | --- |
| E1 | Load a test image into RAM from the monitor or CP/M-68K and jump to it | Whether development can avoid reflashing | Image runs from its link address and prints over serial | Passed: the BIOS loads `EMUTOS.ELF` from FAT into RAM and jumps to it. |
| E2 | Read an unmapped address with a bus-error handler installed | Whether EmuTOS hardware probes can stay enabled | Handler is entered; if the board hangs, probes are compiled out | Settled from the BIOS docs: no bus-error timeout, so probes are compiled out. |
| E3 | Program the interrupt controller's counter for 200 Hz and count ticks against a stopwatch | Tick source and interrupt glue | Within 1% over 10 minutes | Partly done: the 3-second boot countdown looks right. The 10-minute stopwatch check is still to do. |
| E4 | Read sectors through PPIDE; check byte order and timing; read a FAT16 partition made on a PC | Disk driver design and disk layout | Boot sector reads correctly; note KB per second | Passed: MBR and FAT read and written correctly; byte swap detected automatically. Speed with the assembly loop: raw reads 164 KB/s, file reads 127 KB/s, file writes 69 KB/s (`mini68k-tests/DISKBNCH.C`). |
| E5 | Run a VT52 test pattern through the terminal, with and without ANSI translation | Terminal setup for Phase 1 | Cursor addressing and clear-screen work | Partly done: the ANSI console works with EmuCON. A full VT52 test pattern is still to do. |
| E6 | Stream 32,000 bytes to VERA with several loop variants, time it, then read back and verify all of VERA's memory | Copy speed and bus-timing reliability | Full frame under 150 ms; zero verify errors over repeated passes | Not yet run |
| E7 | Set the 640-wide 1 bpp bitmap mode by hand and draw a test card | Register values, bit order within a byte, border and 400 versus 480 lines | Leftmost pixel is the top bit; image stable | Not yet run |
| E8 | Enable VERA's vsync interrupt through the interrupt controller and count frames | Vertical-blank source and acknowledge sequence | 60 interrupts per second, none lost with serial traffic running | Not yet run |
| E9 | Under Phase 2, log rows copied per frame and CPU share while using the desktop | Whether coarse tracking is good enough | Typing and menus feel immediate; idle CPU cost under 25% | Not yet run |
| E10 | Show a 16×16 sprite over the bitmap layer and move it every frame | Mouse pointer design | Pointer visible above the bitmap, no tearing | Not yet run |
| E11 | Benchmark rectangle fill, a line of text, an XOR box and a full scroll: RAM plus copy versus direct port writes | Whether and where the native driver wins | Decision gate for Phase 4 scope | Not yet run |
| E12 | Set 2 bpp at 640×480 and 4 bpp at 640×400 and check memory use against the sprite and palette areas | Which color modes are possible | Mode displays without corrupting sprites or palette | Not yet run |
| E13 | Read the VERA firmware version and test any extended write features it has, such as multi-byte cache writes | Extra speed available to the native driver | Measured fill speed-up, if present | Not yet run |

## Risks and open questions

**Open questions**

- [x] 68008 package and clock: 52-pin PLCC; 8 MHz according to the BIOS timing code (not measured).
- [x] Memory map: see the hardware table. Low memory is RAM after boot.
- [x] Loading: the BIOS loads ELF, COFF and CP/M-68K files from FAT; EmuTOS uses ELF.
- [ ] Which keyboard and mouse hardware will be used?
- [ ] Which VERA firmware version is on the card, at which ECB ports, and on which NS32202 input is its interrupt line?
- [ ] Should the port aim to be merged into EmuTOS, or stay a fork?

**Risks**

| Risk | Effect | Mitigation |
| --- | --- | --- |
| 68008 speed | GEM feels slow even when everything works | Measure early (E6, E9); raise the clock if the board allows; keep the pointer on a sprite |
| Software written for Atari hardware | Programs that touch Atari chips or fixed screen addresses fail | Favor clean GEM and text programs; keep shadow mode for direct screen writers |
| Shared VERA registers across interrupts | Intermittent screen corruption | One access discipline from the first line of code |
| Native driver costs more than it returns in monochrome | Months of work for little visible gain | E11 gate; ship color as the reason for the driver |
| VERA details unverified | Wrong register, port or interrupt assumption in Phase 2 | Check against the card and the VERA reference before coding (E6–E8) |
