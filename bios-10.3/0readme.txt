			Release Notes
		CP/M-68 release of 22-Jan-2012


ROM images:	
		Two sizes are provided, one for 128k EPROM /
	Flash (CPM68SM.BIN), and one for 512k EPROM / Flash
	(CPM68.BIN).

Minimum Hardware:
	ECB mini-M68k CPU board with 1Mb SRAM; 2Mb preferred.
	ECB MultiFunction/PIC board with 16C550 or 16C750 UART,
		NS32202 interrupt controller, DS1302 nvram/clock.
		The 82C55 is strongly suggested, as it may be
		used as a PP-IDE controller.

Optional Hardware:
	ECB Dual IDE board.
	ECB DiskIO v3 (configured as PPIDE port)

Recommended Hardware:
		Compact Flash card or other IDE disk attached to
	either the MF/PIC PPIDE interface or one of the Dual IDE
	interfaces.

I/O device codes:
		The MF/PIC board must be on base address port
	0x40.  If the PPIDE interface is used, then it will be on
	ECB I/O port 0x44 (MF/PIC-base-port + 4).
		Dual IDE boards may use any convenient port set-
	ting.
		DiskIO v3 boards may use any convenient port
	setting.

Serial console:
		Before the NVRAM setup is completed, the default
	serial bit rate is 9600.  Any convenient rate may be
	selected from the Setup menu.

Nomenclature:
		A disk "device" is an actual piece of hardware,
	and is configured from the Setup menu; e.g., "C:"
		A "drive" is a CP/M-68 term, and is generally
	assigned to a CP/M partition on a physical disk "device";
	e.g., "C>"

History:
		The port of CP/M-68 and the CPU board BIOS were
	cross-compiled using GCC and low-level routines were 
	assembled with GAS (using its horrible syntax).  CP/M-68
	is just another program which runs in supervisor mode
	above the hardware BIOS.  All programs run with interrupts
	enabled, since the day/date timer counter and [future]
	floppy disk BIOS require interrupt capability.
		The hardware BIOS is called using TRAP #8; the
	CP/M-68 'cbios' is called using TRAP #3; and the CP/M-68
	'bdos' is called by user programs using TRAP #2.

CP/M-68 drive assignment:
	A:  reserved for floppy disk [future]
	B:  1Mb RAMdisk (on 2Mb hardware)
	C:  first hard disk partition
	...
	F:  400k ROMdisk (512k ROM)
	...
	P:  last hard disk partition

	Upon boot, CP/M-68 comes up on drive F> as User 0.

Disk Partitioning:
		The BIOS expects a DOS primary partition on the
	first boot device.  This is the way CF cards are distri-
	buted.  In addition, CP/M-68 will attach to any primary
	partition of type 0x52 (CP/M).  The INIT utility (on the
	ROMdisk) may be used to write a blank directory.
		Partitioning may be done with Linux 'fdisk' or 
	with CP/M-68 'cfdisk' [to be posted].

Low level programs:
		GCC compiled and linked programs in the COFF for-
	mat may be booted from the DOS partition on the boot
	device.  (CP/M-68 boots from ROM.)  This is primarily
	a convenience in checking out updates to CP/M-68 without
	the necessity of burning a new ROM.
		The first release of 'cfdisk' is likely to be
	in the form of a COFF a.out file to boot from the DOS
	partition.

Disk partitioning suggestions:
		DOS disk volumes may have 1 to 4 primary par-
	titions.  Normally, a CF card has a partition table and
	a single primary partition 1 which occupies the entire
	remainder of card.  I have noted that Windows seems to
	require that a DOS (FAT16) partition must be the first
	partition on the card.  Partitions 2, 3, and 4 are 
	ignored.
		For CP/M-68 usage a CF card may be partitioned
	as DOS(1) and CPM(2); or DOS(1), CPM(2), and CPM(3); &c.
	Just remember, when you change partitoning, the DOS
	partition will have to be reformatted.  Likewise, the
	CPM partitions will have to be reformatted by running
	CP/M-68 'init'.

 N.B.:  CP/M-68 supports partition sizes up to 512Mb.  The disk
	caching strategy employed in the current release only
	works well with partitions up to 16Mb, however.  Just
	remember, CP/M-80 allows partitons in absolute locations
	up to 8Mb in size.  CP/M-80 and CP/M-68 partitions of
	8Mb should be inter-operable, as long as the partitions
	are properly located on the CF card or hard disk.

CP/M-68 utilities:
		The utilities are from version 1.3 of CP/M-68.
	The actual operating system source code is 1.2.  The
	README.TXT file on the ROMdisk indicates the bug fixes
	that went into version 1.3.  Fixes seem to be mostly
	to the utilities.




John Coffman <johninsd@gmail.com>

(end)
