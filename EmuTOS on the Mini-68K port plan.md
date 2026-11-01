# EmuTOS on the Mini-68K: port plan

Oct 11, 2026 · @Dan Werner · updated Nov 1, 2026

The plan was to bring EmuTOS up on the serial console first, then run GEM on the VERA card through a RAM shadow framebuffer, and finally replace the shadow copy with a native VERA driver. All of that is done. GEM now runs on fVDI with a VERA driver (Phase 5), and the open work is listed there. The hardware facts below were checked against `BIOS-PORTING-GUIDE.md`, the BIOS 10.2 sources in `bios-10.2/` and tests on the board, which runs BIOS 10.3.

Phases 2 to 4 were written before the VERA card arrived. Their checklists are kept, marked to show what was done, what changed, and what Phase 5 replaced.

## Status

| Phase | State (Nov 1, 2026) |
| --- | --- |
| 0. Groundwork | Done |
| 1. Serial EmuTOS | Done. Exit test passed: Sozobon C built and ran hello-world on the board (about 45 s) |
| 2. Shadow framebuffer | Done: EmuDesk and EmuCON on the VERA, changed-row copying at the VERA VSYNC (Oct 24, 2026) |
| 3. Input | Mouse working on the desktop (Oct 24, 2026); keyboard working in EmuTOS (Oct 25, 2026) |
| 4. Colour and direct | Colour through the shadow copy working (Oct 24, 2026); direct mode working in all three resolutions and the default (Oct 25, 2026) |
| 5. fVDI | 640×240 and 640×400 at 16 colours working, with the XBIOS palette hook and a first speed pass (Oct 31, 2026). Printer working (Oct 31, 2026). Open: card read fix, more speed work, VERATEST |

## Hardware

Each row is confirmed. The last column says how it shaped the port.

| Item | Confirmed | Effect on the port |
| --- | --- | --- |
| CPU | MC68008FN, 52-pin PLCC, 8 MHz (as the BIOS timing code assumes), 22 address lines (4 MB, mirrored) | Plain 68000 code (`-m68000`, no VBR). Only IPL 2 (the NS32202, which supplies vectors) and IPL 7 (ECB `/NMI`) are wired, so every device interrupt, including a future VERA vsync, has to come through an NS32202 input. |
| RAM | 2 MB SRAM at `0x000000`–`0x1FFFFF`, writable from address 0 after boot | EmuTOS uses `0x000000`–`0x17FFFF` (1.5 MB) as ST-RAM; the top 512 KB holds the EmuTOS image. |
| ROM | BIOS 10.3 (this repository has the 10.2 sources) plus a ROM disk at `0xFFF80000` | EmuTOS does not go in ROM. The BIOS loads `EMUTOS.ELF` from a FAT volume into RAM. |
| I/O | ECB port *p* at `0xFFFF8000` + *p*, supervisor mode only | Every driver runs in supervisor mode; debug output switches to supervisor mode when called from user code. |
| MMU | None | As expected. |
| Serial | 16550/16C750 at port `0x48`, clocked at 1.8432 MHz | Console driver. The BIOS does not route the UART interrupt to the NS32202, so input is polled from the 200 Hz tick (keeps up with pasted text). |
| Interrupts and timer | NS32202 at port `0x40`; register *r* at `0xFFFF8040` + *r*·`0x100`; reading register 32 (`0xFFFFA040`) is End-Of-Interrupt; vector base 16 | System tick: H-counter routed to IR3 (vector 19), 1.8432 MHz / 4, count 2303 = exactly 200 Hz. Other inputs are masked. |
| Disk | PPIDE: 82C55 at ports `0x44`–`0x47` (A = D0–D7, B = D8–D15, C = address and strobes); DiskIO v2/v3 (also an 82C55) at port `0x20`; Dual-SD (bit-banged SPI) at port `0x08` | Backend under EmuTOS's own IDE driver. Each PPIDE or DiskIO board configured in the BIOS Setup becomes an IDE interface, in Setup order. A Dual-SD board is driven through EmuTOS's SD/MMC driver (socket 0 only). |
| Floppy | SMC FDC9266 (765 compatible) on the DiskIO at ports `0x36`–`0x38` (board port + `0x16`), polled, no DMA; write-only control latch at `0x38` | Driver ported from the SBC-386EX driver for the same board. Data phase in assembly with interrupts masked (16 µs per byte at 500 kbit/s). 1.44 MB and 720 KB disks read and write. |
| Clock | DS1302 bit-banged through a latch at port `0x43`; century in BIOS NVRAM byte `0x22` | RTC driver; keeps the BIOS NVRAM checksum valid when the century changes. |
| Video | VERA card: VERA at ports `0x80`–`0x9F`; the firmware version reads 48.156.1, which looks wrong | The screen for EmuTOS (Phases 2 and 4) and fVDI (Phase 5). Reads of the data ports don't auto-increment on this card (see the README), so the address is written before every read. VSYNC is polled from the timer; the VERA IRQ reaches NS32202 IR0 but isn't used. |
| Keyboard and mouse | VT82C42 (8042 compatible) on the VERA card, ports `0xA0`–`0xA1` | PS/2 keyboard and mouse, polled from the timer. The card's interrupt jumpers only offer IR0, which the VERA already has. |
| Printer | PC-style parallel port on the VERA card, ports `0xA4`–`0xA6` | `bios/parport.c`. V1.1 cards need a wire for the strobe (see the README). |
| Bus errors | No bus-error timeout: unmapped reads return garbage | All hardware probes are compiled out (`CONF_ATARI_HARDWARE 0`). |

## How EmuTOS runs on the board

- **Takeover:** the BIOS keeps its vectors, data and heap in `0x000`–`0xFFF`, which overlaps the fixed TOS system variables at `0x400`–`0x800`. So EmuTOS takes over the whole machine, and the BIOS `TRAP #8` calls stop working once it starts. EmuTOS leaves locations `0`–`7` alone, so the RESET button still restarts the BIOS.
- **Build:** `make mini-68k` produces `emutos.elf`. The image is linked as a "ROM" at `0x180000` and wrapped in a minimal ELF file by `tools/mkelf68k.c`. It is about 125 KB of the 512 KB available.
- **Start:** `s emutos` at the BIOS prompt (supervisor mode is required). Alternatively, an `EMUTOS.CMD` file containing `s emutos.elf` lets `emutos` alone work, and `BOOT.CMD` can auto-boot it.
- **Shell:** the default build has no GEM (`WITH_AES=0`) and boots into EmuCON. `make mini-68k WITH_AES=1` includes the desktop.
- **Screen:** on the VERA card (Phases 2, 4 and 5). Without one, the 640×400 monochrome screen in RAM below `phystop` gives the console 80 columns, and a 50 Hz vertical blank is emulated from every 4th timer tick.
- **Code:** the README's *What was added to EmuTOS* lists every new file and hook.

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
- Dual-SD socket 1: supported by the driver (presence is decided by starting the card, not by card detect). The socket fault on the test board was repaired, and socket 1 is confirmed working (Oct 25, 2026).
- The RTC can be set with SETCLOCK.TTP (mini68k-tests).
- Serial flow control is recorded by `Rsconf` but not implemented.
- Baud rates without an Atari `Rsconf` code (such as 38400) can be set in the BIOS Setup and are kept, but cannot be selected from EmuTOS.
- Disk speed (DISKBNCH, 256 KB, assembly transfer loop in `bios/ppide2.S`): raw sector reads 164 KB/s, GEMDOS file reads 127 KB/s, file writes 69 KB/s. With the earlier C loop the figures were 85, 73 and 50 KB/s. Reads are now close to what the 68008 can move through the 8255; writes are limited mostly by something other than the transfer loop.

## Phase 2: GEM on VERA through a shadow framebuffer (done)

EmuTOS draws into an ordinary one-plane bitmap in RAM, and a copy routine streams changed rows to VERA through its auto-incrementing data port.

**Display mode**

Start at 640×400, one bit per pixel. That is exactly Atari ST high resolution (32,000 bytes, 80 bytes per row), which is what the most monochrome software expects. Keep the height a build constant so 640×480 (38,400 bytes) is a one-line change later.

**Work items**

- [x] VERA init: one layer in 640-wide 1 bpp bitmap mode, two palette entries, border set for the 400-line area, other layer and sprites off (E7). Done (Oct 24, 2026); Phase 4 added the colour modes.
- [x] Screen setup: done in Phase 1. EmuTOS already keeps a 640×400 one-plane screen in RAM below `phystop` and reports it to the VDI and Line-A. The copy routine only needs to read it.
- [x] Copy routine: for each dirty row, set the VERA address once and stream 80 bytes; unrolled loop, written in assembly (E6). Done in `bios/vera_mini68k2.S`.
- [x] Vsync as the VBL: the 200 Hz timer polls the VERA VSYNC flag (ISR bit 0) and runs the VBL when it is set, so no interrupt line or jumper is needed. With no VSYNC within 100 ms it falls back to a 50 Hz VBL from the timer. Working on hardware (E8).
- [x] VERA register discipline: the address and control registers are shared state, so any interrupt code that touches VERA must save and restore them, or all VERA access must happen at one interrupt level. Done: at first only the VBL touched the VERA. Since direct mode (Phase 4), every drawing operation sets a busy flag, and the VBL skips its VERA work (cursor blink, sprite, palette) while the flag is set. Under fVDI the flag is shared through the `VERA` cookie.
- [x] Console switch: move the text console from serial to the screen, keeping serial as a debug channel. Done: EmuCON shows on both.
- [x] Build with `WITH_AES=1` to include the GEM desktop. Done.

**Dirty tracking, in three steps**

1. No tracking (done, replaced by step 2): sweep the whole screen round-robin, a fixed number of rows per frame. Slow but proves the path.
2. Coarse tracking (done, working on hardware): the VDI dispatcher (`vdi/vdi_main.c`) and the console output routines (`bios/conout.c`) mark changed rows in a bitmap after drawing; each VBL copies up to 48 marked rows, plus the rows around a moving mouse pointer. A background sweep of 8 rows per idle VBL catches anything that wrote to the screen directly.
3. Exact tracking (not done; direct mode made it unnecessary): have each VDI primitive report the rectangle it actually touched. This is also the first step toward Phase 4.

**Budget (estimates to be checked by E6 and E9)**

- One row costs about 1,600 CPU cycles, about 0.2 ms at 8 MHz.
- A full 400-row copy is about 80 ms of solid CPU time.
- A background sweep limited to a quarter of the CPU refreshes the whole screen in roughly a third of a second.

## Phase 3: keyboard and mouse (done)

EmuTOS takes input as Atari keyboard scancodes and relative mouse packets, so the work is a translator from whatever hardware you choose into those two forms.

- [x] Choose the hardware. Candidates: a PS/2 controller already on one of your ECB video boards, if fitted; a serial mouse on a second UART; or a small microcontroller that presents both devices on one port. Chosen: the VT82C42 PS/2 controller on the VERA card, polled from the 200 Hz timer.
- [x] Keyboard driver: receive scancodes, translate to Atari scancodes, and feed EmuTOS's keyboard buffer, including shift, control and alternate state. Done in `bios/kbd_mini68k.c` (PS/2 set 1 codes); working Oct 25, 2026.
- [x] Mouse driver: convert movement and buttons into the relative packets EmuTOS's mouse vector expects. Done in the same file; working Oct 24, 2026.
- [x] Mouse pointer as a VERA sprite: replace the software cursor's draw and erase with a sprite position update, and convert the 16×16 cursor shape and mask to sprite pixels whenever an application changes it (E10). Done in direct mode (Phase 4) and in the fVDI driver; the shadow copy keeps the software pointer.
- [x] Fallback for early testing: not needed, because the mouse worked first.

## Phase 4: colour and direct drawing (done; planned as a native VERA driver)

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
- [x] Convert the remaining fallback routines to native ones. Replaced by Phase 5: the fVDI driver draws everything itself. EmuTOS's own VDI keeps the read-back fallback.

**Colour in direct mode (Oct 24, 2026; working on the board).** ST low and medium are shown as 4 bpp and 2 bpp VERA bitmaps, as in the shadow copy, and the desktop's *Change resolution* works in direct mode:

- [x] The read-back fallback converts both ways: VERA packed pixels to Atari planes on reading (reverse lookup tables, bits shifted into one plane byte per accumulator lane), and back on writing.
- [x] Native colour versions of rectangle fill (pattern and pixel masks expanded to whole-pixel bit fields), byte-aligned text and the console (cell offsets converted from the planar layout).
- [x] Multi-plane fill patterns, and everything else not native, go through the fallback.
- [x] Resolution changes switch the VERA at once (direct drawing in the new layout starts straight away).
- [x] Tested on the board: all three resolutions work (Oct 25, 2026).
- [ ] Fix the card's read timing, so reads auto-increment and cost half as much. In progress on card V1.1; tracked under Phase 5.

The original native driver plan is kept below for reference. Phase 5 carried it out as option B, an fVDI driver, and each item below says where it ended up.

A native driver replaces the lowest drawing layer so that the VDI, Line-A and the text console write to VERA's memory through its ports, with no RAM copy of the screen.

**What it buys, stated plainly**

VERA has no hardware line, fill or block-copy commands, so in monochrome a native driver is not automatically faster than the shadow copy. Its real gains are color (the driver writes VERA's packed pixels directly, with no planar conversion pass), no dirty scanning, no double writes for simple fills and text, and 32 KB or more of RAM returned. E11 measures this before the work starts.

**Design choice**

| Option | What it is | For | Against |
| --- | --- | --- | --- |
| A. Modify EmuTOS's VDI | Put a small device interface under the existing VDI and Line-A routines, with VERA as its first backend | One code base; console and Line-A covered | A lasting fork of EmuTOS's VDI |
| B. fVDI driver | Write a VERA driver for the open-source replacement VDI | Driver model already exists; EmuTOS untouched | Console and Line-A are not covered; needs checking on a plain 68000 with 2 MB |

Option A was the working assumption because it covers the console and Line-A as well. Phase 5 chose option B: fVDI runs on the 68008 in 2 MB, EmuTOS keeps drawing the console, and fVDI's `lineafix` option keeps the Line-A variables in step with the driver's screen.

**Primitives to implement**

- [x] Set address and stream helpers, including a second pointer for read-then-write. Done in `vera_io.c`: assembly runs, reads through DATA0 and writes through DATA1.
- [x] Horizontal span fill with pattern and the four VDI writing modes; XOR and transparent modes need a read from VERA before each write. Done in `vera_fill.c`.
- [x] Rectangle fill, built on spans. Done in `vera_fill.c`.
- [x] General line, built on pixel and span writes. Done in `vera_line.c`. Vertical lines let the VERA step the address; diagonal lines still go pixel by pixel.
- [x] Block transfer in four directions: memory to screen, screen to memory, screen to screen using VERA's two data ports, and the 16 logic operations. Done in `vera_blit.c`.
- [x] Text: render glyphs through the memory-to-screen path, with a fast case for unstyled system-font text. fVDI draws text through the driver's expand call (`c_expand_area`), which builds whole rows 4 bytes at a time.
- [x] Console: character cell draw, cursor, and scroll as a screen-to-screen copy. Drawn by EmuTOS (`bios/vera_direct.c`) in the screen size the fVDI driver sets.
- [x] Pixel read, and seed fill, which reads heavily and will be slow through ports. The driver has the pixel calls, and fVDI does seed fill on top of them.
- [ ] Line-A entry points mapped onto the same primitives. Not done: Line-A drawing calls still go to EmuTOS's own routines.

**Color**

- [x] Add a 4-color 640-wide mode (2 bits per pixel fits in VERA's memory at 480 lines). Done as ST medium, 640×200 at 2 bpp (Phase 4).
- [x] Test whether 16 colors at 640×400 fits beside the sprite and palette areas (E12). It fits, and works under fVDI.
- [x] Convert Atari planar bitmaps to packed pixels in the memory-to-screen path with lookup tables. Done in EmuTOS (Phase 4). fVDI works in packed pixels and needs no conversion.

**Compatibility**

Programs that write straight to screen memory will show nothing under a native driver. Keep the shadow framebuffer as a build or boot option for those.

**Order of work** (as planned before Phase 5; not followed)

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
| E6 | Stream 32,000 bytes to VERA with several loop variants, time it, then read back and verify all of VERA's memory | Copy speed and bus-timing reliability | Full frame under 150 ms; zero verify errors over repeated passes | Partly run: a C loop took 0.89 s for 32,000 bytes, so the copy was written in assembly. The verify found that reads don't auto-increment (the card read bug). |
| E7 | Set the 640-wide 1 bpp bitmap mode by hand and draw a test card | Register values, bit order within a byte, border and 400 versus 480 lines | Leftmost pixel is the top bit; image stable | Passed (Oct 24, 2026): the leftmost pixel is the top bit and the test card is stable. |
| E8 | Enable VERA's vsync interrupt through the interrupt controller and count frames | Vertical-blank source and acknowledge sequence | 60 interrupts per second, none lost with serial traffic running | Passed: VSYNC is 60 Hz and the VERA IRQ reaches NS32202 IR0 (vector 16). EmuTOS polls the VSYNC flag from the timer instead of taking the interrupt. |
| E9 | Under Phase 2, log rows copied per frame and CPU share while using the desktop | Whether coarse tracking is good enough | Typing and menus feel immediate; idle CPU cost under 25% | Not measured. Coarse tracking felt fast enough on the board, and direct mode replaced it. |
| E10 | Show a 16×16 sprite over the bitmap layer and move it every frame | Mouse pointer design | Pointer visible above the bitmap, no tearing | Passed: sprite 0 is the mouse pointer in direct mode and under fVDI. |
| E11 | Benchmark rectangle fill, a line of text, an XOR box and a full scroll: RAM plus copy versus direct port writes | Whether and where the native driver wins | Decision gate for Phase 4 scope | Not run. Overtaken by the Phase 4 decisions, then by fVDI (Phase 5). |
| E12 | Set 2 bpp at 640×480 and 4 bpp at 640×400 and check memory use against the sprite and palette areas | Which color modes are possible | Mode displays without corrupting sprites or palette | Partly done: 4 bpp at 640×400 works under fVDI. 2 bpp at 640×480 not tried. |
| E13 | Read the VERA firmware version and test any extended write features it has, such as multi-byte cache writes | Extra speed available to the native driver | Measured fill speed-up, if present | Partly done: the version reads 48.156.1, which looks wrong. Extended write features not tested. |

## Risks and open questions

**Open questions**

- [x] 68008 package and clock: 52-pin PLCC; 8 MHz according to the BIOS timing code (not measured).
- [x] Memory map: see the hardware table. Low memory is RAM after boot.
- [x] Loading: the BIOS loads ELF, COFF and CP/M-68K files from FAT; EmuTOS uses ELF.
- [x] Which keyboard and mouse hardware will be used? PS/2, through the VT82C42 on the VERA card.
- [x] Which VERA firmware version is on the card, at which ECB ports, and on which NS32202 input is its interrupt line? Ports `0x80`–`0x9F`; IRQ on IR0 (not used); the version reads 48.156.1, which is probably not a real version number.
- [ ] Should the port aim to be merged into EmuTOS, or stay a fork?
- [ ] Where should the fVDI VERA driver live: in this repository (for now), in Rob Gowin's fVDI fork next to the Xosera driver, or in upstream fVDI? To be discussed with Rob.

**Risks**

| Risk | Effect | Mitigation |
| --- | --- | --- |
| 68008 speed | GEM feels slow even when everything works | Measure early (E6, E9); raise the clock if the board allows; keep the pointer on a sprite |
| Software written for Atari hardware | Programs that touch Atari chips or fixed screen addresses fail | Favor clean GEM and text programs; keep shadow mode for direct screen writers |
| Shared VERA registers across interrupts | Intermittent screen corruption | One access discipline from the first line of code |
| Native driver costs more than it returns in monochrome | Months of work for little visible gain | E11 gate; ship color as the reason for the driver |
| VERA details unverified | Wrong register, port or interrupt assumption in Phase 2 | Checked on the card (E6–E8). The one surprise was the read bug |

## Phase 5: fVDI with a VERA driver

**Decision (Oct 31, 2026).** After looking at Rob Gowin's BITSY MK I (a 68000 board with a Xosera video card, running fVDI under EmuTOS or FreeMiNT), the port moves to [fVDI](https://github.com/freemint/fvdi) for GEM, with a VERA driver. The fVDI driver owns the VERA. The first mode is 640×240 at 16 colours, as on BITSY, then 640×400 at 16 colours.

- [x] fVDI source in `fvdi/`, taken from Rob Gowin's fork (`xosera` branch) and now kept as plain files in this repository, until it is settled where the driver should live (see the open questions). His Xosera driver is the model: like the VERA, Xosera is not memory mapped, so the driver must draw everything itself.
- [x] Driver `fvdi/drivers/vera/`: VERA set-up (4 bpp bitmap, 640 wide, 240 lines doubled or 400), palette, mouse pointer as sprite 0 (applied after the current drawing call when it arrives in an interrupt), fills with patterns and the four writing modes, lines, expand (text, mono icons), blits with the 16 logic operations between the screen and device-format memory forms, pixels. Text and polygons are left to fVDI, which draws them with expand and fill. All drawing is done by the CPU through the ports; the VERA has no blitter.
- [x] EmuTOS: the `VERA` cookie (busy flag, `take_over()`, release hook); after `take_over()` the VBL leaves the VERA alone and the console uses the driver's screen size (17-bit VRAM addresses, long fills and copies). The RAM screen is sized for 640×400 at 16 colours, so nothing drawn there can overrun it.
- [x] Build fVDI and the driver for the 68000 (`make CPU=000`), and test on the board: 640×240 at 16 colours works (2026-10-31). Install: `FVDI_GNU.PRG` in `C:\AUTO\` (the only fVDI there, and before any MiNT loader), `VERA.SYS` in `C:\GEMSYS\`, `FVDI.SYS` in the root of C:. Build with `cd fvdi && make CPU=000`. A Windows checkout needs LF line endings (`fvdi/.gitattributes` sets them), the two upstream symlinks `include/vdi.gnu` and `include/linea.gnu` as plain copies (as they are here), and `engine/setup.c` in lower case.
- [x] Test the 640×400 mode (`640x400` in `FVDI.SYS`): works (2026-10-31).
- [x] XBIOS `Setcolor` and `Setpalette` with fVDI: the driver hooks trap #14 itself (`vera_xbios.c`), since EmuTOS no longer writes the palette after the take-over. The `VERA` cookie stays limited to the busy flag, `take_over()` and the release hook. Works on the board (2026-10-31).
- [x] Speed, first pass (works on the board, 2026-10-31): the port runs (`v_read_run`, `v_write_run`, `v_fill_run`) in assembler, 16 bytes to a loop for writes; fills, text (expand) and blits build each row in a buffer 4 bytes at a time and write it with one run, reading the old row only where it shows through; blit logic operations on longs; vertical lines set the write address once, with the VERA stepping it 320 bytes a pixel.
- [x] EmuTOS's text cursor hidden on the desktop: fVDI's `v_exit_cur` and `v_enter_cur` (`engine/escape.c`) now send the console `ESC f` and `ESC e`, as EmuTOS's own VDI does (Nov 1, 2026). This is the one change to fVDI's engine; everything else is in the driver.
- [x] Printer (EmuTOS, not fVDI): the parallel port on the VERA card, in `bios/parport.c` (`Bconout` device 0, `Bcostat`, `Setprt`). EmuCON's `copy` passes `PRN:`, `AUX:` and `CON:` through. Working on the board after the V1.1 strobe fix (Oct 31, 2026).
- [ ] VERATEST alongside the EmuTOS drivers (written Nov 1, 2026, not yet tested). With the `VERA` cookie present, it holds the busy flag while it uses the VERA ports. It saves VRAM and the display registers before the VRAM test and the test card and restores them afterwards, printing its results only then. It counts EmuTOS's VBLs instead of taking the VSYNC flags. For the keyboard test it borrows the controller through the cookie's new `kbd_hold()` (version 2), and EmuTOS sets up the keyboard and mouse again afterwards. Its keyboard replies skip stale bytes.
- [ ] Speed, second pass (written Nov 1, 2026, not yet tested). Lines of any slope are drawn a byte (two pixels) at a time. Each pixel's change to its byte is kept as an AND mask and an XOR value, so a byte is read only where part of it shows through. The write address is set again only when the next byte isn't where the VERA has stepped to: along the row for flat lines, a row down or up for steep ones (this replaces the separate vertical-line code). The read address's high bytes are only rewritten when the 256-byte page changes. The pixel calls use a 16×16 multiply for the row address instead of the 32-bit library multiply.
- [ ] Card read-timing fix (V1.1 CS stretch), then sequential reads in the driver: `v_read_run` sets the address once instead of per byte, which halves the cost of every read-modify-write.
