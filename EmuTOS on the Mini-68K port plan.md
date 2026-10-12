# EmuTOS on the Mini-68K: port plan

Oct 11, 2026 · @Dan Werner

The plan is to bring EmuTOS up on the serial console first, then run GEM on the VERA card through a RAM shadow framebuffer, and finally replace the shadow copy with a native VERA driver. Hardware and EmuTOS details here are from memory and are approximate until checked against the board, the VERA reference and the EmuTOS source.

## Hardware assumptions

The plan assumes the board below; each row marked "confirm" changes the work if it is wrong.

| Item | Assumed | Why it matters |
| --- | --- | --- |
| CPU | 68008, about 8 MHz (confirm clock and package) | The 48-pin part has a 1 MB address space and only interrupt levels 2, 5 and 7; the 52-pin part has 4 MB and all seven levels. |
| RAM | About 2 MB, starting at address 0 and writable (confirm) | EmuTOS needs writable exception vectors and system variables in low memory. |
| ROM | Flash large enough for a 256 KB image (confirm size and address) | If it is smaller, EmuTOS must be loaded from disk into RAM. |
| MMU | None | Fine for EmuTOS; rules out trapping screen writes. |
| Serial | 16550 UART on the MF/PIC card | Console for Phase 1; needs a new EmuTOS driver. |
| Interrupts and timer | NS32202 on the MF/PIC card (confirm) | Source of the 200 Hz system tick and the route for VERA's vsync interrupt. |
| Disk | IDE through an 8255 (PPIDE) on the MF/PIC card (confirm) | EmuTOS's IDE driver expects memory-mapped registers, so the low-level access must be rewritten. |
| Clock | Battery RTC on the MF/PIC card (confirm chip) | Optional; file timestamps only. |
| Video | VERA, port accessed, working under existing software | GEM display from Phase 2 on. |
| Keyboard and mouse | Not yet decided | See Phase 3. |
| Bus errors | Unknown whether unmapped addresses raise a bus error | EmuTOS probes for hardware this way; without it the probes must be compiled out. |

## Phases at a glance

Each phase ends in something you can use, and nothing above the BIOS layer changes when the display path is swapped in Phase 4.

| Phase | Deliverable | Exit test | Experiments first |
| --- | --- | --- | --- |
| 0. Groundwork | Cross toolchain, EmuTOS fork, fast load-and-test loop | A stub image loads and prints over serial | E1, E2 |
| 1. Serial EmuTOS | EmuTOS boots to the EmuCON shell with a FAT disk | Sozobon C compiles and runs hello-world on the board | E3, E4, E5 |
| 2. Shadow framebuffer | GEM desktop displayed on VERA | EmuDesk opens windows and menus; full redraw under about 0.3 s | E6, E7, E8, E9 |
| 3. Input | Keyboard and mouse driving GEM | A GEM application is usable without the serial terminal | E10 |
| 4. Native driver | VDI and console draw to VERA directly | Shadow buffer removed in the default build; color mode works | E11, E12, E13 |

## Phase 0: groundwork

The goal is a loop where a rebuilt image is running on the board within a minute or two, without reflashing.

- [ ] Install the `m68k-atari-mint` GCC cross toolchain on a PC and build an unmodified EmuTOS target to prove the toolchain.
- [ ] Fork EmuTOS and add a new machine define for the Mini-68K, modelled on how the Amiga and ColdFire board ports are separated from the Atari code.
- [ ] Write down the board's memory map: RAM range, ROM range, I/O port addresses for the UART, interrupt controller, PPIDE, RTC and VERA.
- [ ] Decide where EmuTOS lives. Preferred during development: a RAM-loadable image started from the existing monitor or CP/M-68K (E1). Later: flash.
- [ ] Build a stub that sets the stack, initialises the UART and prints a banner, using the same link address and load path the real image will use.
- [ ] Settle interrupt levels for the system tick, the UART and VERA vsync, given the levels your 68008 package provides.
- [ ] Run the bus-error test (E2) and record the result for Phase 1.

## Phase 1: EmuTOS on the serial console

This phase is a conventional BIOS port: four small drivers and a configuration with all Atari hardware switched off.

**Configuration**

- [ ] Disable every Atari-specific device in the build configuration: MFP, keyboard ACIA, sound chip, video shifter, floppy, ACSI, blitter, NVRAM.
- [ ] Enable EmuTOS's serial-console option so the shell and text programs use the UART.
- [ ] Compile out hardware probes if E2 shows the board does not raise bus errors.
- [ ] Replace memory sizing with a fixed or simple test-based RAM size.

**Drivers to write**

- [ ] 16550 UART: character in, character out, status, and receive interrupt into EmuTOS's serial buffer.
- [ ] System tick: a 200 Hz interrupt from the interrupt controller's counter, wired to EmuTOS's timer handler (E3).
- [ ] Interrupt glue: vectors and acknowledge sequence for the NS32202, and an interim 50 or 60 Hz vertical-blank tick derived from the 200 Hz timer until VERA supplies a real one.
- [ ] PPIDE block driver: sector read and write through the 8255, plugged in beneath EmuTOS's existing disk and partition layer (E4).
- [ ] RTC read and set (optional; can wait).

**Bring-up order**

1. Banner and early debug output over the UART.
2. Tick interrupt running; EmuTOS reaches the EmuCON prompt with no disk.
3. Disk: mount a FAT16 partition, list files, run a `.TOS` program.
4. Tools: copy Sozobon C, a make and an editor to the disk and build something on the board.

**Decisions**

- Terminal emulation: use a VT52 terminal, or enable the console's ANSI translation if it works well enough (E5).
- Disk layout: a separate CompactFlash for EmuTOS is simplest. Sharing one disk with CP/M-68K needs a partition table both systems accept.

## Phase 2: GEM on VERA through a shadow framebuffer

EmuTOS draws into an ordinary one-plane bitmap in RAM, and a copy routine streams changed rows to VERA through its auto-incrementing data port.

**Display mode**

Start at 640×400, one bit per pixel. That is exactly Atari ST high resolution (32,000 bytes, 80 bytes per row), which is what the most monochrome software expects. Keep the height a build constant so 640×480 (38,400 bytes) is a one-line change later.

**Work items**

- [ ] VERA init: one layer in 640-wide 1 bpp bitmap mode, two palette entries, border set for the 400-line area, other layer and sprites off (E7).
- [ ] Screen setup: allocate the shadow buffer, point EmuTOS's screen base at it, and report 640×400, one plane, to the VDI and Line-A variables.
- [ ] Copy routine: for each dirty row, set the VERA address once and stream 80 bytes; unrolled loop, written in assembly (E6).
- [ ] Vsync interrupt: route VERA's vertical-blank interrupt through the interrupt controller and make it EmuTOS's vertical-blank tick (E8).
- [ ] VERA register discipline: the address and control registers are shared state, so any interrupt code that touches VERA must save and restore them, or all VERA access must happen at one interrupt level.
- [ ] Console switch: move the text console from serial to the screen, keeping serial as a debug channel.

**Dirty tracking, in three steps**

1. No tracking: sweep the whole screen round-robin, a fixed number of rows per frame. Slow but proves the path.
2. Coarse tracking: hook the VDI trap and the console output routine, and mark the rows inside the current clip rectangle or text line. Keep a slow background sweep for anything that wrote to the screen directly.
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

Most of these are small standalone programs that run under the existing monitor or CP/M-68K, so they can start before any EmuTOS code is written.

| ID | Experiment | What it settles | Pass mark |
| --- | --- | --- | --- |
| E1 | Load a test image into RAM from the monitor or CP/M-68K and jump to it | Whether development can avoid reflashing | Image runs from its link address and prints over serial |
| E2 | Read an unmapped address with a bus-error handler installed | Whether EmuTOS hardware probes can stay enabled | Handler is entered; if the board hangs, probes are compiled out |
| E3 | Program the interrupt controller's counter for 200 Hz and count ticks against a stopwatch | Tick source and interrupt glue | Within 1% over 10 minutes |
| E4 | Read sectors through PPIDE; check byte order and timing; read a FAT16 partition made on a PC | Disk driver design and disk layout | Boot sector reads correctly; note KB per second |
| E5 | Run a VT52 test pattern through the terminal, with and without ANSI translation | Terminal setup for Phase 1 | Cursor addressing and clear-screen work |
| E6 | Stream 32,000 bytes to VERA with several loop variants, time it, then read back and verify all of VERA's memory | Copy speed and bus-timing reliability | Full frame under 150 ms; zero verify errors over repeated passes |
| E7 | Set the 640-wide 1 bpp bitmap mode by hand and draw a test card | Register values, bit order within a byte, border and 400 versus 480 lines | Leftmost pixel is the top bit; image stable |
| E8 | Enable VERA's vsync interrupt through the interrupt controller and count frames | Vertical-blank source and acknowledge sequence | 60 interrupts per second, none lost with serial traffic running |
| E9 | Under Phase 2, log rows copied per frame and CPU share while using the desktop | Whether coarse tracking is good enough | Typing and menus feel immediate; idle CPU cost under 25% |
| E10 | Show a 16×16 sprite over the bitmap layer and move it every frame | Mouse pointer design | Pointer visible above the bitmap, no tearing |
| E11 | Benchmark rectangle fill, a line of text, an XOR box and a full scroll: RAM plus copy versus direct port writes | Whether and where the native driver wins | Decision gate for Phase 4 scope |
| E12 | Set 2 bpp at 640×480 and 4 bpp at 640×400 and check memory use against the sprite and palette areas | Which color modes are possible | Mode displays without corrupting sprites or palette |
| E13 | Read the VERA firmware version and test any extended write features it has, such as multi-byte cache writes | Extra speed available to the native driver | Measured fill speed-up, if present |

## Risks and open questions

**Open questions**

- [ ] Which 68008 package is fitted, and at what clock speed?
- [ ] What is the full memory map, and is low memory RAM after reset?
- [ ] How large is the flash, and can the monitor load an image from disk or serial?
- [ ] Which keyboard and mouse hardware will be used?
- [ ] Which VERA firmware version is on the card, and at which port addresses?
- [ ] Should the port aim to be merged into EmuTOS, or stay a fork?

**Risks**

| Risk | Effect | Mitigation |
| --- | --- | --- |
| 68008 speed | GEM feels slow even when everything works | Measure early (E6, E9); raise the clock if the board allows; keep the pointer on a sprite |
| Software written for Atari hardware | Programs that touch Atari chips or fixed screen addresses fail | Favor clean GEM and text programs; keep shadow mode for direct screen writers |
| Shared VERA registers across interrupts | Intermittent screen corruption | One access discipline from the first line of code |
| Native driver costs more than it returns in monochrome | Months of work for little visible gain | E11 gate; ship color as the reason for the driver |
| Facts in this plan recalled from memory | Wrong register, option name or board detail | Check each against the board schematic, the VERA reference and the EmuTOS source before coding |
