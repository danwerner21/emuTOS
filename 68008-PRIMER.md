# 68008 Primer for 8-bit Assembly Programmers

A quick orientation to the MC68008 CPU, its registers, and the GNU assembler syntax used in this repository. It's written for programmers who already know 6502, 65816, Z80, 8080, 6809 and some 8086.

For board-specific details (memory map, BIOS calls, boot process), see [BIOS-PORTING-GUIDE.md](BIOS-PORTING-GUIDE.md).

The 68008 will feel familiar if you know the 6809, which was Motorola's 8-bit design shortly before the 68000. Coming from the 8080/Z80/8086 side, the biggest change is that there are no I/O instructions and no segments: everything is memory-mapped in one flat address space.

---

## Contents

1. [The 68008](#1-the-68008)
2. [Registers](#2-registers)
3. [Addressing modes](#3-addressing-modes)
4. [Assembler syntax in this repo](#4-assembler-syntax-in-this-repo)
5. [Common instructions](#5-common-instructions)
6. [Assembler directives](#6-assembler-directives)
7. [A real example, decoded](#7-a-real-example-decoded)
8. [Gotchas coming from 8-bit CPUs](#8-gotchas-coming-from-8-bit-cpus)
9. [Further reference](#9-further-reference)

---

## 1. The 68008

The 68008 is a **68000 with an 8-bit data bus**: the same chip internally, with a narrower connection to the outside world.

| | 68000 | 68008 (DIP-48) | 68008 (PLCC-52, the Mini-M68k board) |
|---|---|---|---|
| Internal architecture | 32-bit registers, 16-bit ALU | same | same |
| Data bus | 16-bit | **8-bit** | **8-bit** |
| Address bus | 24-bit (16 MB) | 20-bit (1 MB) | **22-bit (4 MB)** |
| Instruction set | full 68000 | identical | identical |

- **Software can't tell it from a 68000.** It runs the same binaries and you compile with `-m68000`.
- **It's slower than a 68000 at the same clock.** A word access takes two bus cycles and a long takes four, at about 4 clocks per bus cycle. At 8 MHz that's very roughly 0.5–1 MIPS. It's still far more capable per instruction than a Z80, because each instruction does much more.
- **Addresses wrap.** Only A0–A21 reach the pins, so `0xFFF80000` and `0x380000` are the same location. That's why the BIOS uses the `0xFFFF8048` form for I/O.
- **It's big-endian, like the 6809.** The most significant byte is at the lowest address. That's the opposite of the 6502, Z80 and 8086.

---

## 2. Registers

```
 31            16 15      8 7       0
┌────────────────┬─────────┬─────────┐
│                D0                  │  8 data registers, D0–D7
│                ...                 │  (all fully general: arithmetic, logic, shifts, counters)
│                D7                  │
├────────────────────────────────────┤
│                A0                  │  8 address registers, A0–A7
│                ...                 │  (pointers, index bases)
│                A6                  │  A6 = frame pointer by convention
│  A7 = SP  (USP in user mode, SSP in supervisor mode)
├────────────────────────────────────┤
│                PC                  │
└────────────────────────────────────┘
              ┌─────────┬─────────┐
              │ T.S..III│...XNZVC │  SR: system byte + CCR (the flags)
              └─────────┴─────────┘
```

### Data registers vs address registers

They aren't interchangeable, and that's the main thing to absorb:

| | Data registers (Dn) | Address registers (An) |
|---|---|---|
| Operation sizes | `.b`, `.w`, `.l` | `.w` and `.l` only |
| Byte/word writes | Only the low part changes; the upper bits are untouched | A word is **sign-extended to 32 bits** |
| Effect on flags | Arithmetic sets the flags | **No flags** (`movea`, `adda`, `suba`) |
| Use as a pointer | No | Yes: `(An)`, `(An)+`, `-(An)`, `d(An)` |

### A7 is the stack pointer, and there are two of them

In user mode A7 is the **USP**. In supervisor mode it's the **SSP**. Exceptions, interrupts and traps always switch to supervisor mode and the SSP. The 6809's S and U are the closest thing you know, but here the hardware switches between them automatically.

### The status register (SR)

**Low byte, the CCR (condition codes):**

| Flag | Name | Notes |
|---|---|---|
| X | Extend | A copy of carry used for multi-precision arithmetic. `ADDX`/`SUBX` play the role of `ADC`/`SBC`. Plain `ADD` doesn't consume carry; there's no `ADC`. |
| N | Negative | |
| Z | Zero | |
| V | Overflow | |
| C | Carry | |

The 68000 has no half-carry flag. It does have BCD instructions (`ABCD`, `SBCD`).

**High byte, the system byte:**

| Bit(s) | Name | Notes |
|---|---|---|
| T | Trace | Single-step exception after each instruction |
| S | Supervisor | 1 = supervisor mode. It drives the **FC2** pin, which lights the board's red/green LED and gates its memory protection. |
| III | Interrupt mask | 0–7. Interrupts at or below this level are blocked (level 7 is non-maskable). |

`move.w #0x2700,%sr` means "supervisor, all interrupts masked". You'll see it at the top of `_start`. Only supervisor code may write the system byte.

### No special-purpose registers

There's no dedicated accumulator, index register or B/C/DE pair. Any Dn can be an accumulator or a counter. Any An can be an index base. Any register (D or A) can also be an index, e.g. `8(%a0,%d1.w)`.

---

## 3. Addressing modes

Most instructions accept any of these for the source operand, and most for the destination too. The 8-bit chips allow far fewer combinations.

| Mode | GAS syntax (this repo) | Motorola syntax | Nearest 8-bit equivalent |
|---|---|---|---|
| Data register | `%d0` | `D0` | register |
| Address register | `%a0` | `A0` | — |
| Indirect | `(%a0)` | `(A0)` | Z80 `(HL)` |
| Post-increment | `(%a0)+` | `(A0)+` | 6809 `,X+` |
| Pre-decrement | `-(%a0)` | `-(A0)` | 6809 `,-X` |
| Displacement | `8(%a0)` | `8(A0)` | 6809 `8,X`; Z80 `(IX+8)` |
| Indexed | `8(%a0,%d1.w)` | `8(A0,D1.W)` | 6809 `D,X` |
| PC-relative | `label(%pc)` | `label(PC)` | 6809 `label,PCR` |
| PC-relative indexed | `table(%pc,%d0.w)` | `table(PC,D0.W)` | jump tables |
| Absolute short | `(0x8048).w` | `$8048.W` | 6502/6809 direct page, sort of |
| Absolute long | `(0xFFFF8048).l` | `$FFFF8048` | absolute |
| Immediate | `#5` | `#5` | `#5` / `LD A,5` |

**The stack is just a register with pre-decrement/post-increment.** So push and pop are ordinary moves:

```asm
	move.l	%d0,-(%sp)	/* push D0  */
	move.l	(%sp)+,%d0	/* pop D0   */
```

**Absolute short** is a 16-bit address that's **sign-extended**. So `(0x8048).w` reaches `0xFFFF8048`, which is the UART on the Mini-M68k board, using a short encoding.

---

## 4. Assembler syntax in this repo

The BIOS uses **GNU as (GAS) in "MIT/Motorola hybrid" mode**. The author's own comment in the release notes calls it "its horrible syntax". You'll also see plain Motorola syntax in books and other assemblers. The instructions are the same either way.

### 4.1 Operand order is `source, destination`

This is the reverse of Intel 8080/Z80/8086, and the same as the 6809's `TFR`/`EXG`:

```asm
	move.l	%d1,%d0		/* D0 ← D1    (Z80: LD A,B is dest-first!) */
	add.w	#4,%a0		/* A0 ← A0 + 4 */
	sub.l	%d2,%d3		/* D3 ← D3 − D2 */
```

### 4.2 The size goes on the mnemonic

| Suffix | Size |
|---|---|
| `.b` | 8 bits |
| `.w` | 16 bits |
| `.l` | 32 bits |

If you leave it off, most instructions default to `.w`. **Always write it explicitly.**

### 4.3 GAS conventions

| Item | GAS (this repo) | Motorola |
|---|---|---|
| Registers | `%d0`, `%a6`, `%sp`, `%pc`, `%sr`, `%ccr`, `%usp` | `D0`, `A6`, `SP`, `PC`, `SR`, `CCR`, `USP` |
| Immediate | `#5` | `#5` |
| Hex | `0x1F` | `$1F` |
| Comments | `/* … */`, or `#` at the start of a line | `;` or `*` |

### 4.4 CMP subtracts the source from the destination

Read the branch as "destination *cond* source":

```asm
	cmp.l	%d1,%d0		/* flags from D0 − D1  */
	bgt	label		/* taken if D0 > D1 (signed)   */
	bhi	label		/* taken if D0 > D1 (unsigned) */
```

| Comparison | Signed | Unsigned |
|---|---|---|
| > | `bgt` | `bhi` |
| ≥ | `bge` | `bcc` / `bhs` |
| < | `blt` | `bcs` / `blo` |
| ≤ | `ble` | `bls` |
| = / ≠ | `beq` / `bne` (either) | |

---

## 5. Common instructions

These are the instructions you'll see constantly in the BIOS:

| Instruction | Meaning | 8-bit analogue |
|---|---|---|
| `moveq #n,%d0` | Load −128…127 into all 32 bits; fast and short | `LD A,n` |
| `lea 8(%a0),%a1` | Load the *address* computed by the operand, not its contents | 6809 `LEAX`; 8086 `LEA` |
| `pea label` | Push an address | |
| `movem.l %d2-%d7/%a2-%a5,-(%sp)` | Push or pop a list of registers in one instruction (`movm` in this source) | 6809 `PSHS` |
| `dbra %d1,loop` | Decrement D1.w; branch unless it's now **−1** | Z80 `DJNZ` |
| `jsr` / `rts` / `bsr` | Call, return, PC-relative call | `JSR`/`RTS`/`CALL` |
| `jbra` / `jbsr` | GAS pseudo-ops that pick the short or long branch form for you | |
| `link %a6,#-n` / `unlk %a6` | Build or tear down a C stack frame | 8086 `ENTER`/`LEAVE` |
| `trap #8` | Software interrupt; how you call the BIOS | 6809 `SWI`; 8086 `INT` |
| `rte` | Return from exception; restores SR and PC | `RTI` |
| `btst #5,(%a0)` | Test one bit (also `bset`, `bclr`, `bchg`) | Z80 `BIT` |
| `swap %d0` | Exchange the high and low words | |
| `ext.w` / `ext.l` | Sign-extend | 6809 `SEX` |

Because `dbra` stops at −1, you load the count minus one. That's why the BIOS has lines like `move.w #TRY-1,%d4`.

---

## 6. Assembler directives

| Directive | Purpose |
|---|---|
| `.text`, `.data`, `.bss` | Sections |
| `.globl sym` | Export a symbol |
| `.comm name,size,align` | A BSS variable |
| `.long`, `.word`, `.byte` | Data |
| `.ascii`, `.asciz` | Strings (`.asciz` adds a NUL) |
| `.even`, `.align 4` | Alignment |
| `.include "file.s"` | Include a file |
| `.if CPU<68010` … `.endif` | Conditional assembly. The BIOS uses this heavily to build either the Mini or the KISS-68030 version. |
| `name = value` | An equate |
| `1:` with `1f` / `1b` | Numeric local labels, referenced forward or backward |

---

## 7. A real example, decoded

This is the BIOS trap dispatcher from [bios8.s](bios/bios-10.2/bios8.s):

```asm
bios_trap_entry:
	move.l	%a6,-(%sp)		/* push A6 */
	ext.w	%d0			/* sign-extend D0.b → D0.w */
	cmp.w	#bios_vector_lth/4,%d0	/* D0 − table_length */
	jbcc	undefined		/* unsigned D0 ≥ length → bad call */
	lsl.l	#2,%d0			/* D0 *= 4 (longword table entries) */
	move.l	bios_vector_00(%d0.w,%pc),%a6	/* A6 ← table[D0], PC-relative indexed */
	jmp	(%a6)			/* jump through it */
```

On a Z80 that would be about 15 instructions. Here, one PC-relative indexed load does the table lookup.

---

## 8. Gotchas coming from 8-bit CPUs

- **Words and longs must be at even addresses.** A misaligned `move.w`/`move.l` causes an **address error** (exception 3), even on the 8-bit-bus 68008. Byte accesses can go anywhere. That's why the source is full of `.even`.
- **Writing `.b` or `.w` to a data register leaves the upper bits alone.** Clear the register first (`clr.l` or `moveq #0`) if you'll use it as a 32-bit value later.
- **Writing `.w` to an address register sign-extends it**, so `movea.w #0x8000,%a0` gives `0xFFFF8000`.
- **`move` sets N and Z and clears V and C.** That's unlike Z80 `LD`, which doesn't touch the flags. A lot of explicit `tst`/`cp` instructions disappear as a result.
- **There are no I/O instructions.** Peripherals are just memory addresses, and on the Mini-M68k board only supervisor mode can reach them.
- **Exceptions push SR and PC onto the SSP** and fetch the handler address from a vector table at address 0 (on the 68000/68008 there's no movable vector base). That's why §4 of [BIOS-PORTING-GUIDE.md](BIOS-PORTING-GUIDE.md) is mostly about vectors.

---

## 9. Further reference

- Motorola, *M68000 Family Programmer's Reference Manual*: the definitive source for every instruction's sizes, addressing modes and flag effects.
- Motorola, *MC68000 8-/16-/32-Bit Microprocessors User's Manual*: bus timing, exception processing and the 68008 pinout.
- [BIOS-PORTING-GUIDE.md](BIOS-PORTING-GUIDE.md): the Mini-M68k memory map, BIOS calls and boot process.
- [bios/bios-10.2](bios/bios-10.2): real 68000 code to learn from. [startup.s](bios/bios-10.2/startup.s), [bios8.s](bios/bios-10.2/bios8.s) and [serial.s](bios/bios-10.2/serial.s) are good starting points.
