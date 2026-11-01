#!make -f
#
# This software is licensed under the GNU General Public License.
# Please, see LICENSE.TXT for further information.
#

TARGET = xosera.sys

all: $(TARGET)

top_srcdir = ../..

OPTS    = -mshort -O2 -fomit-frame-pointer -std=c99
include $(top_srcdir)/CONFIGVARS
WARNINGS = -Wall -W -Wunused -Wundef -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs
CFLAGS  = $(CPUOPTS) $(OPTS) $(WARNINGS) -I$(top_srcdir)/include -I$(top_srcdir)/drivers/include -I$(XOSERA_M68K_API)
# don't include rosco firmware I/O in API, also define a few things that rosco_m68k toolchain normally defines to quiet warnings
CFLAGS +=  -DXOSERA_API_MINIMAL -D_XOPEN_SOURCE=700 -D_FORTIFY_SOURCE=0 -DROSCO_M68K=1

SINCSRC = \
	$(top_srcdir)/drivers/bitplane/1_expand.inc

SSRC = \
	../common/c_common.s \
	../common/common.s \
	../common/clip.s \
        timerb_intr.s

CSRC = \
    ../common/colours.c \
	xosera.c \
	init.c \
	printf.c \
	xosera_spec.c \
	xosera_scr.c \
	xosera_pal.c \
	xosera_line.c \
	xosera_fill.c \
	xosera_mouse.c \
	xosera_blit.c \
        local_xosera_m68k_api.c

# handle DevPac -> gas conversions
# defines SSRC_GNU and SINCSRC_GNU variables
include $(top_srcdir)/utility/conv2gas/RULES

SINCSRC_GNU += \
	$(top_srcdir)/include/types.inc \
	$(top_srcdir)/include/macros.gnu \
	$(top_srcdir)/include/vdi.gnu \
	$(top_srcdir)/drivers/include/pixelmac.gnu

# Engine binary objects
ifeq ($(CPU),v4e)
OBJECTS = $(SSRC_GNU_CF:.s=.o)
else
OBJECTS = $(SSRC_GNU:.s=.o)
endif
OBJECTS += $(CSRC:.c=.o)

$(OBJECTS): $(SINCSRC_GNU)

$(TARGET): $(OBJECTS) $(LIBFILES)
	$(AM_V_LD)$(LD) -o $@ $(OBJECTS) $(LDFLAGS) -Map=xosera.map $(LIBS)

include $(top_srcdir)/DEPENDENCIES

strip:
	$(STRIP) --strip-all $(TARGET)

clean:: clean_gnu
	$(RM) $(OBJECTS) $(TARGET) xosera.map

install::
	mkdir -p $(DESTDIR)/gemsys
	cp -a $(TARGET) $(DESTDIR)/gemsys/$(TARGET)
	cp -a fvdi.sys "$(DESTDIR)/fvdixos.sys"

