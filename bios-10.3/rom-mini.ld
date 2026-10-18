/* rom-mini.ld */

OUTPUT_FORMAT("elf32-m68k", "elf32-m68k", "elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_start)

/* Retrobrew ECB Mini-68K CPU Card  * 
MEMORY 
{
    ram    : ORIGIN = 0x00000400, LENGTH = 2M    * leave first 0x100 bytes unused *
    rom    : ORIGIN = 0xFFF80000, LENGTH = 448K
/*  ecbio  : ORIGIN = 0xFFFF0000, LENGTH = 64K   */  /*
}

*/


SECTIONS
{
	. = 0x00400;            /* above 256 vectors */
	.bss : {
		__bss_start = . ;
		*(.bss)	;
		*(COMMON) ;
		__bss_end = .	;
                _end = .        ;
	  } /* >ram */


	. = 0xFFF80000;                 /* ROM */
	.text :	{ 
                     __ROM_start = . ;
                        *(.text)
                }
	.rodata : {
                        *(.rodata) 
                  }
	.data : { 
                        *(.data)
                    __ROM_end = . ;
                }


}

