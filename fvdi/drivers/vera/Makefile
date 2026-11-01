#!make -f
#
# fVDI driver for the VERA video card on the RetroBrew Mini-M68k.
# Build with the rest of fVDI, for the 68000: make CPU=000
#
# This software is licensed under the GNU General Public License.
# Please, see LICENSE.TXT for further information.
#

TARGET = vera.sys

all: $(TARGET)

top_srcdir = ../..

OPTS    = -mshort -O2 -fomit-frame-pointer -std=c99
include $(top_srcdir)/CONFIGVARS
WARNINGS = -Wall -W -Wunused -Wundef -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs
CFLAGS  = $(CPUOPTS) $(OPTS) $(WARNINGS) -I$(top_srcdir)/include -I$(top_srcdir)/drivers/include

SINCSRC = \
	$(top_srcdir)/drivers/bitplane/1_expand.inc

SSRC = \
	../common/c_common.s \
	../common/common.s \
	../common/clip.s

CSRC = \
	../common/colours.c \
	init.c \
	printf.c \
	vera_spec.c \
	vera_io.c \
	vera_pal.c \
	vera_fill.c \
	vera_line.c \
	vera_scr.c \
	vera_blit.c \
	vera_mouse.c \
	vera_xbios.c

# handle DevPac -> gas conversions
# defines SSRC_GNU and SINCSRC_GNU variables
include $(top_srcdir)/utility/conv2gas/RULES

SINCSRC_GNU += \
	$(top_srcdir)/include/types.inc \
	$(top_srcdir)/include/macros.gnu \
	$(top_srcdir)/include/vdi.gnu \
	$(top_srcdir)/drivers/include/pixelmac.gnu

OBJECTS = $(SSRC_GNU:.s=.o)
OBJECTS += $(CSRC:.c=.o)

$(OBJECTS): $(SINCSRC_GNU)

$(TARGET): $(OBJECTS) $(LIBFILES)
	$(AM_V_LD)$(LD) -o $@ $(OBJECTS) $(LDFLAGS) -Map=vera.map $(LIBS)

include $(top_srcdir)/DEPENDENCIES

strip:
	$(STRIP) --strip-all $(TARGET)

clean:: clean_gnu
	$(RM) $(OBJECTS) $(TARGET) vera.map

install::
	mkdir -p $(DESTDIR)/gemsys
	cp -a $(TARGET) $(DESTDIR)/gemsys/$(TARGET)
	cp -a fvdi.sys "$(DESTDIR)/fvdivera.sys"
