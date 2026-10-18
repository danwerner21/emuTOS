/* formerly 'rom-common.ld' but found to be unusable */

OUTPUT_FORMAT("elf32-m68k", "elf32-m68k", "elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_start)

SECTIONS
{
    .text : { 
        text_start = .;
        *(.text) 
        text_end = .;
    } >rom
    text_size = SIZEOF(.text);

    /* .rodata : AT(text_end) { */
    .rodata : { 
        rodata_start = .;
        *(.rodata) 
        rodata_end = .;
    } >rom /* AT>rom */
    rodata_size = SIZEOF(.rodata);

    /* .data : AT(rodata_end) {  */
    .data : { 
        data_start = .;
        *(.data) 
        data_end = .;
    } >ram /* AT>rom */
    data_size = SIZEOF(.data);
    data_load_start = LOADADDR(.data);

    .bss : { 
        bss_start = .;
        *(COMMON)
        *(.bss) 
        bss_end = .;
    } >ram
}
