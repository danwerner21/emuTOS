/*  size_ram.s  */
/*
    Enter with:
	D7	absolute maximum memory size, 256Mb or 64Mb or 2Mb

    Exit with:
	D0	RAM size
			should be a multiple of 512Kb on the MINI
			or a multiple of 16Mb on the small (x16) KISS
			or a multiple of 64Mb on the large (x64) KISS
*/

PATTERN	   =	0x12EDB748
ROTATE	   =	5		/* should be prime */
TRY	   =	64		/* independent of data cache */

size_ram:
	move.l	%d7,%d1		/* D1 is the increment we'll use */
	lsr.l	#4,%d1		/* increment will be size / 16 */
	clr.l	%d0		/* just in case of total failure */
	move.l	%d1,%a1		/* start testing at first increment */
sr1:	
	jbsr	test_loc	/* test locations below A1 */
	tst.l	%d2		/* were there any errors? */
	jbne	sr9		/* jump if errors */
	move.l	%a1,%d0		/* no errors, memory is present */
	
	cmp.l	%d0,%d7		/* did we test highest possible memory? */
	jbeq	sr9		/* if so, exit */
	add.l	%d1,%a1		/* bump to next address to test */
	jbra	sr1		
sr9:
	rts
	
test_loc:
	clr.l	%d2			/* failure count */
	
	move.l	#PATTERN,%d3
	move.l	%a1,%a2
	move.w	#TRY-1,%d4
tl1:
	move.l	%d3,-(%a2)		/* set a pattern */
	ror.l	#ROTATE,%d3
	dbra	%d4,tl1			/* fill a number of locations */


/* now test for memory errors */
	move.l	#PATTERN,%d3	
	move.l	%a1,%a2
	move.w	#TRY-1,%d4
tl2:
	cmp.l	-(%a2),%d3
	jbeq	tl3
	add.l	#1,%d2
tl3:	ror.l	#ROTATE,%d3
	dbra	%d4,tl2
	
	rts

/* end size_ram.s */
