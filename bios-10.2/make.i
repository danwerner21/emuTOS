#
#  Makefile for  Mini-M68k  BIOS
#
# makes COFF linkables unless:
#  make ELF=1 is used
#
TARGET = bios10

#  use 'make RETAIL=1' to remove all of the debugging code and
#  make the "retail" version of the BIOS
ifndef RETAIL
RETAIL=0
endif

BIOSSIZE=48
CPU=68000
BIOSTEXT=0xFFF80000
BIOSDATA=0x0400
#
#



ifdef ELF
# make ELF output with GCC 4.1.1 cross-compiler

CROSSDIR = /usr/cross/m68k-elf
BIN = $(CROSSDIR)/bin
#
CC = $(BIN)/m68k-elf-gcc
#COPT = -O2 -m$(CPU) -Wall -DRETAIL=$(RETAIL)
#COPT = -O2 -malign-int -m$(CPU) -Wall -Werror -DRETAIL=$(RETAIL)
COPT = -O2 -ansi -malign-int -nostdlib -m$(CPU) -Wall -Werror -DRETAIL=$(RETAIL)
# -Wa,-alhms,-L
AS = $(BIN)/m68k-elf-as
AOPT = -m$(CPU) -alhms --defsym RETAIL=$(RETAIL)
LD = $(BIN)/m68k-elf-ld
LOPT = -Ttext $(BIOSTEXT) -Tdata $(BIOSDATA)
UOPT = -Ttext 0x1000 --entry begin
LIB = $(BIN)/m68k-elf-ar
LIBS = -L$(CROSSDIR)/m68k-elf/lib/m68000 -L$(CROSSDIR)/lib/gcc/m68k-elf/4.1.1/m68000 -lc -lgcc

else

#
#	Uses AshWare distro of GCC 2.91
#
CROSSDIR = c:\GccAshWare\gcc-m68k-ashware
BIN = $(CROSSDIR)\bin
#
CC = $(BIN)\m68k-coff-gcc
#COPT = -O2 -m$(CPU) -Wall -DRETAIL=$(RETAIL)
#COPT = -O2 -malign-int -m$(CPU) -Wall -Werror -DRETAIL=$(RETAIL)
COPT = -O2 -ansi -nostdlib -m$(CPU) -Wall -Werror -DRETAIL=$(RETAIL)
#COPT = -O2 -m$(CPU) -Wall -Werror -DRETAIL=$(RETAIL)
# -Wa,-alhms,-L
AS = $(BIN)\m68k-coff-as
AOPT = -m$(CPU) -alhms --defsym RETAIL=$(RETAIL)
LD = $(BIN)\m68k-coff-ld
LOPT = -Ttext $(BIOSTEXT) -Tdata $(BIOSDATA)
UOPT = -Ttext 0x1000 --entry begin
LIB = $(BIN)\m68k-coff-ar
LIBS = -L..\CPM68\Ash-lib -lc -lgcc

endif
ROM = ../cpm68/rom


.SUFFIXES:   .c .s .o .i .out .hex .bin

.c.o:
	$(CC) -c $(COPT) $*.c
.s.o:
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s
.c.s:
	$(CC) -S $(COPT) $*.c

#.out.mod:
#	grep ".text" $*.map | grep -v ".o)" | grep ".o" | \
#		grep -v "set to" | sed "s/.text/     /" > $*.mod
#
#.out.sym:
#	grep "                " $*.map | grep -v "=" | grep -v "(" | \
#		grep -v LONG | grep -v "                 " | sort > $*.sym
#

SFILES = mfpic.s ppi.s allide.s siodef.s memtest.s ns202def.s biostrap.s \
	error.s
HFILES = mytypes.h packer.h mfpic.h ns202.h dosdisk.h ide.h main68.h \
  portab.h coff.h myide.h rtc.h io.h fdc8272.h wd37c65.h debug.h version.h
HSFILES = portab.h optab.h disasm.h
OFILES = main68.o serial.o rtc.o ds1302.o cprintf.o packer.o \
	pic202.o ns202.o ppide.o dualide.o bios8.o strtoul.o malloc.o \
	dualsd.o bioscall.o fdc8272.o wd37c65.o floppy.o setup.o \
	debug.o beetle.o disasm.o
CSFILES = main68.s cprintf.s packer.s ns202.s crc32.s malloc.s setup.s \
	rtc.s strtoul.s fdc8272.s wd37c65.s ppide2.s debug.s disasm.s



TABLES = startup.sym startup.mod
TTABLES = test5.sym test5.mod daytime.sym daytime.mod

LIBFILES = cprintf.o strtoul.o bioscall.o crt0.o


all:	$(TARGET).hex $(TARGET).bin
rom:	mini-512.rom mini-128.rom

test:	test5.bin daytime.bin $(TTABLES)
alles:	all test

ide:	ppide2.o
dt:	daytime.out
fdc:	fdc8272.o wd37c65.o floppy.o



	

mini-512.rom:	$(ROM)/rom400.bin $(TARGET).bin
	cat $(TARGET).bin $(ROM)/rom400.bin >mini-512.rom

mini-128.rom:	$(ROM)/rom80.bin $(TARGET).bin
	cat $(TARGET).bin $(ROM)/rom80.bin >mini-128.rom


main68.o:	main68.c $(HFILES)
	$(CC) -S $(COPT) -DBIOSSIZE=$(BIOSSIZE) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

cprintf.o:	cprintf.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

cprintf.i:	cprintf.c
	$(CC) -E $(COPT) $*.c >$*.i

packer.o:	packer.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

crc32.o:	crc32.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

malloc.o:	malloc.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

fdc8272.o:	fdc8272.c fdc8272.h $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

wd37c65.o:	wd37c65.c wd37c65.h $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

ppide2.o:	ppide2.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

setup.o:	setup.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

rtc.o:	rtc.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

ns202.o:	ns202.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

debug.o:	debug.c $(HFILES) $(HSFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

disasm.o:	disasm.c $(HFILES) $(HSFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

strtoul.o:	strtoul.c $(HFILES)
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

startup.out:	startup.o bios.a
	$(LD) $(LOPT) -s -Map startup.map -o startup.out startup.o \
		bios.a $(LIBS)

$(TARGET).hex:	startup.out
	bin2hex -s 0x2000 -o $(TARGET).hex startup.out

$(TARGET).bin:	$(TARGET).hex		# $(TUTOR)
	hex2bin -R $(BIOSSIZE)k $(TARGET).hex   -o $(TARGET).bin

mylib.a:   $(LIBFILES)
	$(LIB) -r $*.a $(LIBFILES)

bios.a:	   $(OFILES)
	$(LIB) -r $*.a $(OFILES)

startup.mod:	startup.out
	grep ".text" $*.map | grep -v ".o)" | grep ".o" | \
		grep -v "set to" | sed "s/.text/     /" > $*.mod

startup.sym:	startup.out
	grep "                " $*.map | grep -v "=" | grep -v "(" | \
		grep -v LONG | grep -v "                 " | sort > $*.sym


test5.out:	test5.o
	$(LD) $(UOPT) $(LIBS) -s -Map test5.map -o test5.out test5.o

test5.bin:	test5.out
	bin2hex -s 0x1000 test5.out -o test5.hex
	hex2bin -R 8k test5.hex -o test5.bin

test5.mod:	test5.out
	grep ".text" $*.map | grep -v ".o)" | grep ".o" | \
		grep -v "set to" | sed "s/.text/     /" > $*.mod

test5.sym:	test5.out
	grep "                " $*.map | grep -v "=" | grep -v "(" | \
		grep -v LONG | grep -v "                 " | sort > $*.sym

#  cat startup.mod startup.sym | sed -e "s/        / /g" | sort >foo

daytime.o:	daytime.c bioscall.h
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

daytime.out:	daytime.o mylib.a
	$(LD) $(UOPT) -s -Map daytime.map -o daytime.out \
		daytime.o mylib.a $(LIBS)
#	bin2hex -s 0x1000 daytime.out -o daytime.hex
#	hex2bin -R 8k daytime.hex -o daytime.bin

daytime.bin:	daytime.out
	bin2hex -s 0x1000 daytime.out -o daytime.hex
	hex2bin -R 8k daytime.hex -o daytime.bin

daytime.sym:	daytime.out
	grep "                " $*.map | grep -v "=" | grep -v "(" | \
		grep -v LONG | grep -v "                 " | sort > $*.sym

daytime.mod:	daytime.out
	grep ".text" $*.map | grep -v ".o)" | grep ".o" | \
		grep -v "set to" | sed "s/.text/     /" > $*.mod


cfdisk.o:	cfdisk.c cfdisk.h mytypes.h portab.h bioscall.h ide.h packer.h
	$(CC) -S $(COPT) $*.c
	$(AS) $(AOPT) -a=$*.lst -o $*.o $*.s

cfdisk.out:	cfdisk.o n8iox.o packer.o mylib.a
	$(LD) $(UOPT) -s -Map cfdisk.map -o cfdisk.out \
		cfdisk.o n8iox.o packer.o mylib.a $(LIBS)


tidy:	
	rm -f startup.out
	rm -f startup.mod
	rm -f startup.sym
	rm -f *.lst *.LST
	rm -f *.map

clean:	tidy
	rm -f *.o
	rm -f *.a
	rm -f *.hex
	rm -f *.bin *.BIN
	rm -f *.rom *.ROM
	rm -f *.out
	rm -f $(CSFILES)


## Dependencies
startup.o:	startup.s $(SFILES)
serial.o:	serial.s  $(SFILES)
dualide.o:	dualide.s $(SFILES)
ppide.o:	ppide.s $(SFILES)
dualsd.o:	dualsd.s $(SFILES)
pic202.o:	pic202.s $(SFILES)
bios8.o:	bios8.s $(SFILES)
bioscall.o:	bioscall.s $(SFILES)
test5.o:	test5.s biostrap.s
ds1302.o:	ds1302.s $(SFILES)
floppy.o:	floppy.s $(SFILES)

foo.o:		foo.c
time.o:		time.c $(HFILES)
crt0.o:		crt0.s

beetle.o:	beetle.s
n8iox.o:	n8iox.s
