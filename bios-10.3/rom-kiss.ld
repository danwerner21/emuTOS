/* rom-kiss.ld */

SECTIONS
{
	. = 0xFFF00000;                 /* ROM */
	.text :	  { *(.text) }
	.rodata : { *(.rodata) }
	.data :   { *(.data) }
	. = 0xFFFE0000;                 /* static memory 32k */
	.bss : {
		__bss_start = . ;
		*(.bss)	;
		*(COMMON) ;
		__bss_end = .	;
		_end = .	;
	  }
}

