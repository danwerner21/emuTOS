/*
 * mkelf68k.c - wrap a raw EmuTOS image into a minimal static ELF executable
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The RetroBrew Mini-M68k BIOS loads static big-endian m68k ELF
 * executables from a FAT volume: each PT_LOAD segment is copied to its
 * p_paddr, then the BIOS jumps to e_entry.
 *
 * This tool produces the simplest such file: an ELF header, a single
 * PT_LOAD program header, and the raw image. The load address is also
 * the entry point, because an EmuTOS image starts with the OSHEADER,
 * whose first instruction branches to the startup code.
 *
 * Usage: mkelf68k <load-address> <ram-top> <image.img> <output.elf>
 *   load-address and ram-top are C-style numbers (e.g. 0x180000).
 *   ram-top is the first address above usable RAM; the image must fit
 *   below it.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ELF_HEADER_SIZE     52
#define PROGRAM_HEADER_SIZE 32
#define IMAGE_OFFSET        0x100   /* file offset of the raw image */

#define ET_EXEC     2
#define EM_68K      4
#define EV_CURRENT  1
#define PT_LOAD     1
#define PF_RWX      7

static void put16(unsigned char *p, unsigned long v)
{
    p[0] = (unsigned char)(v >> 8);
    p[1] = (unsigned char)v;
}

static void put32(unsigned char *p, unsigned long v)
{
    p[0] = (unsigned char)(v >> 24);
    p[1] = (unsigned char)(v >> 16);
    p[2] = (unsigned char)(v >> 8);
    p[3] = (unsigned char)v;
}

static unsigned long parse_number(const char *s, const char *what)
{
    char *end;
    unsigned long v = strtoul(s, &end, 0);

    if (*s == '\0' || *end != '\0')
    {
        fprintf(stderr, "mkelf68k: invalid %s: %s\n", what, s);
        exit(EXIT_FAILURE);
    }

    return v;
}

int main(int argc, char *argv[])
{
    unsigned long load, ramtop, size;
    unsigned char header[IMAGE_OFFSET];
    unsigned char *ph;
    unsigned char *image;
    FILE *in, *out;
    long len;

    if (argc != 5)
    {
        fprintf(stderr, "usage: mkelf68k <load-address> <ram-top> <image.img> <output.elf>\n");
        return EXIT_FAILURE;
    }

    load = parse_number(argv[1], "load address");
    ramtop = parse_number(argv[2], "RAM top");

    in = fopen(argv[3], "rb");
    if (in == NULL)
    {
        perror(argv[3]);
        return EXIT_FAILURE;
    }
    if (fseek(in, 0, SEEK_END) != 0 || (len = ftell(in)) < 0 || fseek(in, 0, SEEK_SET) != 0)
    {
        perror(argv[3]);
        return EXIT_FAILURE;
    }
    size = (unsigned long)len;

    if (load & 1)
    {
        fprintf(stderr, "mkelf68k: load address 0x%lx must be even\n", load);
        return EXIT_FAILURE;
    }
    if (load < 0x1000)
    {
        fprintf(stderr, "mkelf68k: load address 0x%lx is below 0x1000 (BIOS-owned RAM)\n", load);
        return EXIT_FAILURE;
    }
    if (size == 0)
    {
        fprintf(stderr, "mkelf68k: %s is empty\n", argv[3]);
        return EXIT_FAILURE;
    }
    if (load + size > ramtop)
    {
        fprintf(stderr, "mkelf68k: image of %lu bytes at 0x%lx does not fit below 0x%lx"
                " (%ld bytes too large)\n", size, load, ramtop, (long)(load + size - ramtop));
        return EXIT_FAILURE;
    }

    image = malloc(size);
    if (image == NULL)
    {
        fprintf(stderr, "mkelf68k: out of memory\n");
        return EXIT_FAILURE;
    }
    if (fread(image, 1, size, in) != size)
    {
        perror(argv[3]);
        return EXIT_FAILURE;
    }
    fclose(in);

    memset(header, 0, sizeof header);

    /* ELF header */
    header[0] = 0x7f;
    header[1] = 'E';
    header[2] = 'L';
    header[3] = 'F';
    header[4] = 1;                  /* ELFCLASS32 */
    header[5] = 2;                  /* ELFDATA2MSB (big-endian) */
    header[6] = EV_CURRENT;
    put16(header + 16, ET_EXEC);    /* e_type */
    put16(header + 18, EM_68K);     /* e_machine */
    put32(header + 20, EV_CURRENT); /* e_version */
    put32(header + 24, load);       /* e_entry */
    put32(header + 28, ELF_HEADER_SIZE); /* e_phoff */
    put32(header + 32, 0);          /* e_shoff: no section headers */
    put32(header + 36, 0);          /* e_flags */
    put16(header + 40, ELF_HEADER_SIZE);     /* e_ehsize */
    put16(header + 42, PROGRAM_HEADER_SIZE); /* e_phentsize */
    put16(header + 44, 1);          /* e_phnum */
    put16(header + 46, 0);          /* e_shentsize */
    put16(header + 48, 0);          /* e_shnum */
    put16(header + 50, 0);          /* e_shstrndx */

    /* Single PT_LOAD program header */
    ph = header + ELF_HEADER_SIZE;
    put32(ph + 0, PT_LOAD);         /* p_type */
    put32(ph + 4, IMAGE_OFFSET);    /* p_offset */
    put32(ph + 8, load);            /* p_vaddr */
    put32(ph + 12, load);           /* p_paddr */
    put32(ph + 16, size);           /* p_filesz */
    put32(ph + 20, size);           /* p_memsz: no BSS, EmuTOS BSS is in ST-RAM */
    put32(ph + 24, PF_RWX);         /* p_flags */
    put32(ph + 28, 4);              /* p_align */

    out = fopen(argv[4], "wb");
    if (out == NULL)
    {
        perror(argv[4]);
        return EXIT_FAILURE;
    }
    if (fwrite(header, 1, sizeof header, out) != sizeof header
     || fwrite(image, 1, size, out) != size
     || fclose(out) != 0)
    {
        perror(argv[4]);
        remove(argv[4]);
        return EXIT_FAILURE;
    }

    free(image);

    printf("# %s: %lu bytes loaded at 0x%06lx-0x%06lx, entry 0x%06lx, %lu bytes free below 0x%06lx\n",
           argv[4], size, load, load + size - 1, load, ramtop - load - size, ramtop);

    return EXIT_SUCCESS;
}
